function features = extract_cycle_features(data, options)
%EXTRACT_CYCLE_FEATURES Extract same-time edge and charge-domain rows.

if nargin < 2
    options = struct();
end
nCycles = get_option(options, "nCycles", 150);
rising = find(diff(data.u) > 0.5) + 1;
falling = find(diff(data.u) < -0.5) + 1;
rising = rising(rising > 2 & rising < numel(data.t)-2);
if numel(rising) > nCycles + 1
    rising = rising(end-nCycles:end);
end

edgeRows = zeros(numel(rising)-1, 9);
capRows = zeros(numel(rising)-1, 8);
Phi = zeros(4*(numel(rising)-1), 2);
z = zeros(size(Phi, 1), 1);
row = 0;

for c = 1:numel(rising)-1
    kr = rising(c);
    krNext = rising(c+1);
    kfCandidates = falling(falling > kr & falling < krNext);
    if isempty(kfCandidates)
        continue;
    end
    kf = kfCandidates(1);
    r = data.ESRtrue(kr);

    % Same-time left/right limits at the 0->1 edge.
    vMinus = data.vC(kr) + r * data.i1(kr);
    vPlus = data.vC(kr) - r * data.i2(kr);
    deltaV = vMinus - vPlus;
    currentSum = data.i1(kr) + data.i2(kr);
    rEdge = deltaV / currentSum;
    edgeRows(c, :) = [c, data.t(kr), vMinus, vPlus, deltaV, ...
        data.i1(kr), data.i2(kr), rEdge, r];

    onIdx = kr:kf;
    offIdx = kf:krNext;
    qOnPositive = trapz(data.t(onIdx), data.i2(onIdx));
    qOff = trapz(data.t(offIdx), data.i1(offIdx));
    dVcOn = data.vC(kf) - data.vC(kr);
    dVcOff = data.vC(krNext) - data.vC(kf);
    cOn = qOnPositive / (-dVcOn);
    cOff = qOff / dVcOff;
    capRows(c, :) = [c, data.t(kr), cOff, cOn, qOff, qOnPositive, ...
        data.Ctrue(kr), data.ESRtrue(kr)];

    % Rising edge row: zero charge, current commutation.
    row = row + 1;
    Phi(row, :) = [0, -data.i2(kr)-data.i1(kr)];
    z(row) = vPlus - vMinus;

    % ON subinterval row.
    qOn = -qOnPositive;
    iCStart = -data.i2(kr);
    iCEnd = -data.i2(kf);
    vTStart = data.vC(kr) + r*iCStart;
    vTEnd = data.vC(kf) + r*iCEnd;
    row = row + 1;
    Phi(row, :) = [qOn, iCEnd-iCStart];
    z(row) = vTEnd-vTStart;

    % Falling edge row.
    iCBefore = -data.i2(kf);
    iCAfter = data.i1(kf);
    row = row + 1;
    Phi(row, :) = [0, iCAfter-iCBefore];
    z(row) = r * (iCAfter-iCBefore);

    % OFF subinterval row.
    iCStart = data.i1(kf);
    iCEnd = data.i1(krNext);
    vTStart = data.vC(kf) + r*iCStart;
    vTEnd = data.vC(krNext) + r*iCEnd;
    row = row + 1;
    Phi(row, :) = [qOff, iCEnd-iCStart];
    z(row) = vTEnd-vTStart;
end

validEdge = edgeRows(:, 1) ~= 0;
validCap = capRows(:, 1) ~= 0;
Phi = Phi(1:row, :);
z = z(1:row);
edgeTable = array2table(edgeRows(validEdge, :), "VariableNames", ...
    ["cycle","time_s","vT_minus_V","vT_plus_V","delta_v_edge_V", ...
     "i1_A","i2_A","ESR_edge_Ohm","ESR_true_Ohm"]);
capTable = array2table(capRows(validCap, :), "VariableNames", ...
    ["cycle","time_s","C_OFF_F","C_ON_F","Q_OFF_C","Q_ON_C", ...
     "C_true_F","ESR_true_Ohm"]);

columnScale = max(vecnorm(Phi, 2, 1), eps);
PhiNormalized = Phi ./ columnScale;
gram = Phi' * Phi;
gramNormalized = PhiNormalized' * PhiNormalized;
features = struct("edgeTable", edgeTable, "capTable", capTable, ...
    "Phi", Phi, "z", z, "rankPhi", rank(Phi), ...
    "lambdaMin", min(eig(gram)), "condGram", cond(gram), ...
    "condGramNormalized", cond(gramNormalized));
end

function value = get_option(options, name, defaultValue)
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end

