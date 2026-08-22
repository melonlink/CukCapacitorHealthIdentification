function base=run_modelB_v21(v21Root,p,LESL,stopTime)
%RUN_MODELB_V21 Run the read-only v2 Simscape circuit using SimulationInput.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
v2Root=fullfile(repoRoot,"verification_v2");
addpath(fullfile(v1Root,"model"),fullfile(v2Root,"model"));
if nargin<2 || isempty(p), p=model_parameters(); end
if nargin<3, LESL=1e-9; end
if nargin<4, stopTime=.003; end
modelName="cuk_simscape_circuit_model_v2";
vOut0=p.D/(1-p.D)*p.Vin;
variables=struct("Vin",p.Vin,"D",p.D,"Ts",p.Ts,"L1",p.L1, ...
    "L2",p.L2,"C1",p.C1,"ESR",p.ESR,"LESL",LESL,"Co",p.Co, ...
    "Rload",p.Rload,"I1_init",p.D/(1-p.D)*(vOut0/p.Rload), ...
    "I2_init",vOut0/p.Rload,"VC_init",p.Vin/(1-p.D),"VO_init",vOut0);
in=Simulink.SimulationInput(modelName);
in=in.setModelParameter("StopTime",num2str(stopTime,17),"SolverType", ...
    "Variable-step","Solver","ode23t","MaxStep","Ts/400", ...
    "RelTol","1e-6","SimulationMode","normal");
names=fieldnames(variables);
for k=1:numel(names), in=in.setVariable(names{k},variables.(names{k})); end
out=sim(in); signalNames=string(out.logsout.getElementNames); raw=struct();
for k=1:numel(signalNames)
    signal=out.logsout.get(signalNames(k)).Values;
    raw.(signalNames(k))=signal.Data; raw.(signalNames(k)+"_time")=signal.Time;
end
required=["u","i1","i2","iC","vT","vo"];
t0=-inf; t1=inf;
for name=required
    t0=max(t0,raw.(name+"_time")(1));
    t1=min(t1,raw.(name+"_time")(end));
end
dt=p.Ts/400; t=(t0:dt:t1)';
base=struct("t",t,"dt",dt,"samplesPerPeriod",400);
base.u=interp1(raw.u_time,raw.u,t,"previous","extrap");
for name=["i1","i2","iC","vT","vo"]
    base.(name)=interp1(raw.(name+"_time"),raw.(name),t,"linear","extrap");
end
di=[0;diff(base.iC)]/dt;
base.vC=base.vT-p.ESR*base.iC-LESL*di;
base.modelLESL=LESL; base.Ctrue=p.C1*ones(size(t));
base.ESRtrue=p.ESR*ones(size(t)); base.Rload=p.Rload*ones(size(t));
base.Vin=p.Vin*ones(size(t));
fprintf("Model B v2.1: D=%.2f, R=%.3g Ohm, ESL=%.3g nH, %d samples.\n", ...
    p.D,p.Rload,LESL/1e-9,numel(t));
end
