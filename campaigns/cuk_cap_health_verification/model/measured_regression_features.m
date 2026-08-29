function features = measured_regression_features(data, options)
%MEASURED_REGRESSION_FEATURES Build T17 rows only from sampled measurements.

if nargin < 2, options = struct(); end
startTime = get_option(options,"startTime",data.t(1));
endTime = get_option(options,"endTime",data.t(end));
rising = find(diff(data.u)>0.5)+1;
falling = find(diff(data.u)<-0.5)+1;
rising = rising(data.t(rising)>=startTime & data.t(rising)<=endTime);
n = max(numel(rising)-1,0);
Phi = zeros(4*n,2);
z = zeros(4*n,1);
rowTime = zeros(4*n,1);
rowType = strings(4*n,1);
row = 0;
for c=1:n
    kr=rising(c); kr2=rising(c+1);
    kf=falling(find(falling>kr & falling<kr2,1));
    if isempty(kf), continue; end
    on=kr:kf-1;
    off=kf:kr2-1;
    row=row+1; Phi(row,:)=[0,data.iC(kr)-data.iC(kr-1)];
    z(row)=data.vT(kr)-data.vT(kr-1); rowTime(row)=data.t(kr); rowType(row)="rising_edge";
    row=row+1; Phi(row,:)=[trapz(data.t(on),data.iC(on)),data.iC(on(end))-data.iC(on(1))];
    z(row)=data.vT(on(end))-data.vT(on(1)); rowTime(row)=data.t(on(end)); rowType(row)="on_interval";
    row=row+1; Phi(row,:)=[0,data.iC(kf)-data.iC(kf-1)];
    z(row)=data.vT(kf)-data.vT(kf-1); rowTime(row)=data.t(kf); rowType(row)="falling_edge";
    row=row+1; Phi(row,:)=[trapz(data.t(off),data.iC(off)),data.iC(off(end))-data.iC(off(1))];
    z(row)=data.vT(off(end))-data.vT(off(1)); rowTime(row)=data.t(off(end)); rowType(row)="off_interval";
end
features = struct("Phi",Phi(1:row,:),"z",z(1:row), ...
    "time",rowTime(1:row),"type",rowType(1:row),"rankPhi",rank(Phi(1:row,:)));
end

function value=get_option(options,name,defaultValue)
if isfield(options,name), value=options.(name); else, value=defaultValue; end
end
