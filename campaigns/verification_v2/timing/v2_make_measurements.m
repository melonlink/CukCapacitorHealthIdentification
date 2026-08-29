function measured=v2_make_measurements(base,p,cfg)
%V2_MAKE_MEASUREMENTS Sample converter signals with independent timing errors.

if nargin<3, cfg=struct(); end
Ns=opt(cfg,"samplesPerCycle",80);
phase=opt(cfg,"phaseFraction",0);
seed=opt(cfg,"seed",1); rng(seed,"twister");
dt=p.Ts/Ns;
t0=base.t(1)+phase*dt;
t=(t0:dt:base.t(end))';

if opt(cfg,"useBaseTerminalVoltage",false)
    v=base.vT;
else
    v=base.vC+p.ESR*base.iC;
    esl=opt(cfg,"ESL_H",p.ESL);
    if esl>0, v=add_esl_ringing(base,v,esl); end
end
i1=base.i1; i2=base.i2;
fcV=opt(cfg,"voltageFrontendFcHz",Inf);
fcI1=opt(cfg,"i1FrontendFcHz",Inf);
fcI2=opt(cfg,"i2FrontendFcHz",Inf);
v=front_end(v,base.dt,fcV); i1=front_end(i1,base.dt,fcI1);
i2=front_end(i2,base.dt,fcI2);

jitterRms=1e-9*opt(cfg,"jitterRmsNs",0);
aperture=1e-9*opt(cfg,"adcApertureNs",0);
jitterMode=string(opt(cfg,"jitterMode","independent"));
jCommon=jitterRms*randn(size(t));
if aperture>0, jCommon=jCommon+aperture*(rand(size(t))-.5); end
switch jitterMode
    case "common"
        jV=jCommon; jI1=jCommon; jI2=jCommon;
    case "pwm"
        jV=zeros(size(t)); jI1=jV; jI2=jV;
    otherwise
        jV=jitterRms*randn(size(t));
        jI1=jitterRms*randn(size(t)); jI2=jitterRms*randn(size(t));
        if aperture>0
            jV=jV+aperture*(rand(size(t))-.5);
            jI1=jI1+aperture*(rand(size(t))-.5);
            jI2=jI2+aperture*(rand(size(t))-.5);
        end
end
delayV=1e-9*opt(cfg,"voltageDelayNs",0);
delayI1=1e-9*opt(cfg,"i1DelayNs",0);
delayI2=1e-9*opt(cfg,"i2DelayNs",0);
vSample=interp1(base.t,v,t-delayV+jV,"linear","extrap");
i1Sample=interp1(base.t,i1,t-delayI1+jI1,"linear","extrap");
i2Sample=interp1(base.t,i2,t-delayI2+jI2,"linear","extrap");

sigmaV=1e-3*opt(cfg,"sigmaVmV",0);
sigmaI=1e-3*opt(cfg,"sigmaImA",0);
vSample=vSample+sigmaV*randn(size(t));
i1Sample=i1Sample+sigmaI*randn(size(t));
i2Sample=i2Sample+sigmaI*randn(size(t));
bits=opt(cfg,"adcBits",Inf);
if isfinite(bits)
    vSample=quantize(vSample,bits,0,100);
    i1Sample=quantize(i1Sample,bits,-5,5);
    i2Sample=quantize(i2Sample,bits,-5,5);
end

u=double(mod(t,p.Ts)<p.D*p.Ts);
iC=(1-u).*i1Sample-u.*i2Sample;
rising=find(diff(base.u)>.5)+1;
edgeTimes=base.t(rising);
edgeTimes=edgeTimes(edgeTimes>=t(1)+p.Ts & edgeTimes<=t(end)-p.Ts);
pwmOffset=1e-9*opt(cfg,"commonPwmOffsetNs",0);
if jitterMode=="pwm" && jitterRms>0
    edgeTimes=edgeTimes+pwmOffset+jitterRms*randn(size(edgeTimes));
else
    edgeTimes=edgeTimes+pwmOffset;
end

measured=struct("t",t,"dt",dt,"samplesPerCycle",Ns,"vT",vSample, ...
    "i1",i1Sample,"i2",i2Sample,"iC",iC,"u",u, ...
    "edgeTimes",edgeTimes,"sigmaV",sigmaV,"sigmaI",sigmaI, ...
    "adcBits",bits,"cfg",cfg,"Ctrue",p.C1,"ESRtrue",p.ESR, ...
    "channelActualTimeV",t-delayV+jV,"channelActualTimeI1",t-delayI1+jI1, ...
    "channelActualTimeI2",t-delayI2+jI2);
end

function y=front_end(x,dt,fc)
if ~isfinite(fc), y=x; return; end
tau=1/(2*pi*fc); a=1-exp(-dt/tau);
y=filter(a,[1,a-1],x,x(1)*(1-a));
end

function v=add_esl_ringing(base,v,esl)
di=[0;diff(base.iC)]/base.dt;
v=v+esl*di;
edges=find(abs(diff(base.u))>.5)+1;
nRing=round(2e-6/base.dt);
for k=reshape(edges,1,[])
    last=min(numel(v),k+nRing); tau=(0:last-k)'*base.dt;
    impulse=esl*(base.iC(k)-base.iC(k-1))/base.dt;
    ring=.65*impulse*exp(-tau/.35e-6).*cos(2*pi*2.2e6*tau);
    v(k:last)=v(k:last)+ring;
end
end

function y=quantize(x,bits,lo,hi)
levels=2^bits-1; code=round((x-lo)/(hi-lo)*levels);
code=min(max(code,0),levels); y=lo+code/levels*(hi-lo);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
