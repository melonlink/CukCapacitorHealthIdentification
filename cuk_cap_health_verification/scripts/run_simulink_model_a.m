function outData = run_simulink_model_a(rootDir)
%RUN_SIMULINK_MODEL_A Execute audited Simulink Model A using SimulationInput.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
addpath(genpath(rootDir));
p = model_parameters();
modelFile = fullfile(rootDir, "model", "cuk_switched_equation_model.slx");
modelName = "cuk_switched_equation_model";
idealDir = fullfile(rootDir, "results", "ideal");
if ~isfolder(idealDir), mkdir(idealDir); end

in = Simulink.SimulationInput(modelName);
in = in.setModelParameter("StopTime", "0.02", "SolverType", "Fixed-step", ...
    "Solver", "ode4", "FixedStep", "Ts/200");
names = ["Vin","D","Ts","L1","L2","C1","ESR","Co","Rload"];
values = {p.Vin,p.D,p.Ts,p.L1,p.L2,p.C1,p.ESR,p.Co,p.Rload};
vOut0 = p.D/(1-p.D)*p.Vin;
names = [names,"I1_init","I2_init","VC_init","VO_init"];
values = [values,{p.D/(1-p.D)*(vOut0/p.Rload),vOut0/p.Rload, ...
    p.Vin/(1-p.D),vOut0}];
for k = 1:numel(names)
    in = in.setVariable(names(k), values{k});
end
in = in.setModelParameter("SimulationMode", "normal");
out = sim(in);

signalNames = string(out.logsout.getElementNames);
outData = struct("modelFile", modelFile, "signalNames", signalNames);
for k = 1:numel(signalNames)
    valuesTs = out.logsout.get(signalNames(k)).Values;
    outData.(signalNames(k)) = valuesTs.Data;
    outData.t = valuesTs.Time;
end
save(fullfile(idealDir,"simulink_model_a.mat"),"outData");
end
