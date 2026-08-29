function outData = run_simscape_model_b(rootDir, stopTime)
%RUN_SIMSCAPE_MODEL_B Run the independently connected Simscape circuit.

if nargin < 1
    rootDir = fileparts(fileparts(mfilename("fullpath")));
end
if nargin < 2, stopTime = 0.01; end
addpath(genpath(rootDir));
p = model_parameters();
modelName = "cuk_simscape_circuit_model";
modelFile = fullfile(rootDir,"model",modelName+".slx");
crossDir = fullfile(rootDir,"results","model_b");
if ~isfolder(crossDir), mkdir(crossDir); end

vOut0 = p.D/(1-p.D)*p.Vin;
variables = struct("Vin",p.Vin,"D",p.D,"Ts",p.Ts,"L1",p.L1, ...
    "L2",p.L2,"C1",p.C1,"ESR",p.ESR,"Co",p.Co, ...
    "Rload",p.Rload,"I1_init",p.D/(1-p.D)*(vOut0/p.Rload), ...
    "I2_init",vOut0/p.Rload,"VC_init",p.Vin/(1-p.D), ...
    "VO_init",vOut0);
in = Simulink.SimulationInput(modelName);
in = in.setModelParameter("StopTime",num2str(stopTime,17), ...
    "SolverType","Variable-step","Solver","ode23t", ...
    "MaxStep","Ts/200","RelTol","1e-6","SimulationMode","normal");
names = fieldnames(variables);
for k = 1:numel(names)
    in = in.setVariable(names{k},variables.(names{k}));
end
out = sim(in);
signalNames = string(out.logsout.getElementNames);
outData = struct("modelFile",modelFile,"signalNames",signalNames);
for k = 1:numel(signalNames)
    signal = out.logsout.get(signalNames(k)).Values;
    outData.(signalNames(k)) = signal.Data;
    outData.(signalNames(k)+"_time") = signal.Time;
end
save(fullfile(crossDir,"simscape_model_b.mat"),"outData","p");
fprintf('Model B completed with %d logged signals.\n',numel(signalNames));
end

