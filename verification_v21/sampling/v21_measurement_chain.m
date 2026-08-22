function measured=v21_measurement_chain(base,p,cfg)
%V21_MEASUREMENT_CHAIN AFE, anti-alias, S/H, ADC and timing in one chain.

if nargin<3, cfg=struct(); end
fsAdc=opt(cfg,"fsAdcHz",5e6); Ta=1/fsAdc;
phase=opt(cfg,"samplePhase",0); seed=opt(cfg,"seed",1); rng(seed,"twister");
tStart=max(base.t(1)+p.Ts,base.t(1)+phase*Ta);
t=(tStart:Ta:base.t(end)-Ta)';
useBase=opt(cfg,"useBaseTerminalVoltage",true);
if useBase, vAnalog=base.vT; else, vAnalog=base.vC+p.ESR*base.iC; end
i1Analog=base.i1; i2Analog=base.i2;
order=opt(cfg,"afeOrder",2); fcV=opt(cfg,"afeFcVHz",2e6);
fcI1=opt(cfg,"afeFcI1Hz",1e6); fcI2=opt(cfg,"afeFcI2Hz",fcI1);
vFiltered=analog_lpf(vAnalog,base.dt,fcV,order);
i1Filtered=analog_lpf(i1Analog,base.dt,fcI1,order);
i2Filtered=analog_lpf(i2Analog,base.dt,fcI2,order);
aperture=opt(cfg,"adcApertureS",.1*Ta);
if aperture>0
    nAperture=max(1,round(aperture/base.dt));
    vFiltered=movmean(vFiltered,nAperture,"Endpoints","shrink");
    i1Filtered=movmean(i1Filtered,nAperture,"Endpoints","shrink");
    i2Filtered=movmean(i2Filtered,nAperture,"Endpoints","shrink");
end

jitter=opt(cfg,"jitterRmsNs",0)*1e-9; mode=string(opt(cfg,"jitterMode","independent"));
common=jitter*randn(size(t));
if mode=="common"
    jV=common; jI1=common; jI2=common;
elseif mode=="pwm"
    jV=zeros(size(t)); jI1=jV; jI2=jV;
else
    jV=jitter*randn(size(t)); jI1=jitter*randn(size(t));
    jI2=jitter*randn(size(t));
end
dV=opt(cfg,"voltageDelayNs",0)*1e-9;
dI1=opt(cfg,"i1DelayNs",0)*1e-9; dI2=opt(cfg,"i2DelayNs",0)*1e-9;
vSample=interp1(base.t,vFiltered,t-dV+jV,"linear","extrap");
i1Sample=interp1(base.t,i1Filtered,t-dI1+jI1,"linear","extrap");
i2Sample=interp1(base.t,i2Filtered,t-dI2+jI2,"linear","extrap");

sigmaV=opt(cfg,"sigmaVmV",0)*1e-3; sigmaI=opt(cfg,"sigmaImA",0)*1e-3;
vSample=vSample+sigmaV*randn(size(t));
i1Sample=i1Sample+sigmaI*randn(size(t)); i2Sample=i2Sample+sigmaI*randn(size(t));
bits=opt(cfg,"adcBits",16);
vFullScale=opt(cfg,"voltageFullScaleV",100);
iFullScale=opt(cfg,"currentFullScaleA",40);
vLsb=vFullScale/(2^bits-1); iLsb=iFullScale/(2^bits-1);
vSaturation=mean(vSample<0 | vSample>vFullScale);
iSaturation=mean(abs(i1Sample)>iFullScale/2 | abs(i2Sample)>iFullScale/2);
vSample=quantize(vSample,bits,0,vFullScale);
i1Sample=quantize(i1Sample,bits,-iFullScale/2,iFullScale/2);
i2Sample=quantize(i2Sample,bits,-iFullScale/2,iFullScale/2);
u=double(mod(t,p.Ts)<p.D*p.Ts); iC=(1-u).*i1Sample-u.*i2Sample;
rising=find(diff(base.u)>.5)+1; edgeTimes=base.t(rising);
edgeTimes=edgeTimes(edgeTimes>=t(1)+p.Ts & edgeTimes<=t(end)-p.Ts);
pwmOffset=opt(cfg,"commonPwmOffsetNs",0)*1e-9;
if mode=="pwm" && jitter>0, edgeTimes=edgeTimes+pwmOffset+jitter*randn(size(edgeTimes));
else, edgeTimes=edgeTimes+pwmOffset; end

truthVC=interp1(base.t,base.vC,t,"linear","extrap");
truthC=interp1(base.t,base.Ctrue,t,"previous","extrap");
truthR=interp1(base.t,base.ESRtrue,t,"previous","extrap");
aliasV=alias_ratio(vFiltered,base.dt,fsAdc,p.Ts);
aliasI1=alias_ratio(i1Filtered,base.dt,fsAdc,p.Ts);
aliasI2=alias_ratio(i2Filtered,base.dt,fsAdc,p.Ts);
measured=struct("t",t,"dt",Ta,"samplesPerCycle",fsAdc/p.fs, ...
    "vT",vSample,"i1",i1Sample,"i2",i2Sample,"iC",iC,"u",u, ...
    "edgeTimes",edgeTimes,"sigmaV",hypot(sigmaV,vLsb/sqrt(12)), ...
    "sigmaI",hypot(sigmaI,iLsb/sqrt(12)),"adcBits",bits,"cfg",cfg, ...
    "Ctrue",p.C1,"ESRtrue",p.ESR,"truthVC",truthVC,"truthC",truthC, ...
    "truthESR",truthR,"aliasRatioVdB",aliasV,"aliasRatioI1dB",aliasI1, ...
    "aliasRatioI2dB",aliasI2,"aliasRatioWorstdB",max([aliasV,aliasI1,aliasI2]), ...
    "afeOrder",order,"afeFcVHz",fcV,"afeFcI1Hz",fcI1,"afeFcI2Hz",fcI2, ...
    "adcApertureS",aperture,"channelActualTimeV",t-dV+jV, ...
    "channelActualTimeI1",t-dI1+jI1,"channelActualTimeI2",t-dI2+jI2, ...
    "voltageFullScaleV",vFullScale,"currentFullScaleA",iFullScale, ...
    "voltageSaturationFraction",vSaturation,"currentSaturationFraction",iSaturation);
end

function y=analog_lpf(x,dt,fc,order)
if ~isfinite(fc), y=x; return; end
fs=1/dt; x=x(:);
if order==1
    a=1-exp(-2*pi*fc*dt); y=filter(a,[1,a-1],x,x(1)*(1-a)); return;
end
k=tan(pi*min(fc,.45*fs)/fs); den=1+sqrt(2)*k+k^2;
b=[k^2,2*k^2,k^2]/den;
a=[1,2*(k^2-1)/den,(1-sqrt(2)*k+k^2)/den];
nPad=max(4,ceil(10*fs/fc)); z=filter(b,a,[repmat(x(1),nPad,1);x]);
y=z(nPad+1:end);
end

function ratioDb=alias_ratio(x,dt,fsAdc,Ts)
nCycle=max(4,floor((numel(x)*dt)/Ts)-2); n=min(numel(x),round(nCycle*Ts/dt));
z=x(end-n+1:end); z=z-mean(z); nfft=2^nextpow2(n);
spec=abs(fft(z,nfft)).^2/nfft^2; f=(0:nfft/2)'/(nfft*dt);
spec=spec(1:nfft/2+1); base=sum(spec(f<=fsAdc/2)); above=sum(spec(f>fsAdc/2));
ratioDb=10*log10(max(above,eps)/max(base,eps));
end

function y=quantize(x,bits,lo,hi)
levels=2^bits-1; code=round((x-lo)/(hi-lo)*levels);
code=min(max(code,0),levels); y=lo+code/levels*(hi-lo);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
