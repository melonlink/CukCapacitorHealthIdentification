function base=run_simscape_model_b_v2(v2Root,LESL,stopTime)
%RUN_SIMSCAPE_MODEL_B_V2 Run the independent circuit with physical C1 ESL.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
if nargin<2, LESL=0; end
if nargin<3, stopTime=.003; end
repoRoot=fileparts(v2Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(fullfile(v1Root,"model"),fullfile(v2Root,"model"));
p=model_parameters();
modelName="cuk_simscape_circuit_model_v2";
if LESL==0, modelLESL=1e-9; else, modelLESL=LESL; end
vOut0=p.D/(1-p.D)*p.Vin;
variables=struct("Vin",p.Vin,"D",p.D,"Ts",p.Ts,"L1",p.L1, ...
    "L2",p.L2,"C1",p.C1,"ESR",p.ESR,"LESL",modelLESL,"Co",p.Co, ...
    "Rload",p.Rload,"I1_init",p.D/(1-p.D)*(vOut0/p.Rload), ...
    "I2_init",vOut0/p.Rload,"VC_init",p.Vin/(1-p.D),"VO_init",vOut0);
in=Simulink.SimulationInput(modelName);
in=in.setModelParameter("StopTime",num2str(stopTime,17),"SolverType", ...
    "Variable-step","Solver","ode23t","MaxStep","Ts/400", ...
    "RelTol","1e-6","SimulationMode","normal");
names=fieldnames(variables);
for k=1:numel(names), in=in.setVariable(names{k},variables.(names{k})); end
out=sim(in);
signalNames=string(out.logsout.getElementNames); raw=struct();
for k=1:numel(signalNames)
    signal=out.logsout.get(signalNames(k)).Values;
    raw.(signalNames(k))=signal.Data; raw.(signalNames(k)+"_time")=signal.Time;
end
t0=max([raw.u_time(1),raw.i1_time(1),raw.i2_time(1),raw.iC_time(1),raw.vT_time(1)]);
t1=min([raw.u_time(end),raw.i1_time(end),raw.i2_time(end),raw.iC_time(end),raw.vT_time(end)]);
dt=p.Ts/400; t=(t0:dt:t1)';
base=struct("t",t,"dt",dt,"samplesPerPeriod",400, ...
    "u",interp1(raw.u_time,raw.u,t,"previous","extrap"), ...
    "i1",interp1(raw.i1_time,raw.i1,t,"linear","extrap"), ...
    "i2",interp1(raw.i2_time,raw.i2,t,"linear","extrap"), ...
    "iC",interp1(raw.iC_time,raw.iC,t,"linear","extrap"), ...
    "vT",interp1(raw.vT_time,raw.vT,t,"linear","extrap"), ...
    "vo",interp1(raw.vo_time,raw.vo,t,"linear","extrap"));
di=[0;diff(base.iC)]/dt;
base.vC=base.vT-p.ESR*base.iC-modelLESL*di;
base.modelLESL=modelLESL;
base.Ctrue=p.C1*ones(size(t)); base.ESRtrue=p.ESR*ones(size(t));
base.Rload=p.Rload*ones(size(t)); base.Vin=p.Vin*ones(size(t));
fprintf('Model B v2: physical ESL %.3g nH, %d regularized samples.\n', ...
    modelLESL/1e-9,numel(t));
end
