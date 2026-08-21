function result=tr_ts_ltvkf(m,p,cfg,locked)
%TR_TS_LTVKF Asynchronous timing-robust topology-synchronous LTV Kalman filter.

if nargin<3, cfg=struct(); end
if nargin<4, locked=default_locked(); end
alphaScale=1e-4;
cfg.RRFloor=locked.RRFloor; cfg.RCFloor=locked.RCFloor;
edges=v2_edge_estimates(m,p,cfg);
cfg.ESRPrior=p.ESR;
charges=v2_charge_estimates(m,p,cfg);
n=numel(m.t); Cinit=opt(cfg,"Cinit",p.C1); ESRinit=opt(cfg,"ESRinit",p.ESR);
x=[m.vT(1)-ESRinit*m.iC(1);alphaScale/Cinit;ESRinit];
P=diag([.5^2,.2^2,(.5*p.ESR)^2]); I=eye(3);
xHist=zeros(n,3); preHist=zeros(n,3); pDiag=zeros(n,3); ccm=true(n,1);
nisV=nan(n,1); gateV=false(n,1);
nisC=nan(height(charges),1); gateC=false(height(charges),1);
nisR=nan(height(edges),1); gateR=false(height(edges),1);
ec=1; er=1;
cycleId=floor(m.t/p.Ts+1e-9);
cycleValues=unique(cycleId); cycleEnabled=false(size(cycleId)); streak=0;
resumeCycles=opt(locked,"resumeCycles",2);
for ic=1:numel(cycleValues)
    inCycle=cycleId==cycleValues(ic);
    rawCcm=min(m.i1(inCycle))>locked.ccmCurrentThreshold && ...
        min(m.i2(inCycle))>locked.ccmCurrentThreshold;
    if rawCcm, streak=streak+1; else, streak=0; end
    cycleEnabled(inCycle)=streak>=resumeCycles;
end
for k=1:n
    if k>1
        q=.5*(m.iC(k-1)+m.iC(k))*(m.t(k)-m.t(k-1));
        F=[1,q/alphaScale,0;0,1,0;0,0,1]; x=F*x;
        P=F*P*F'+locked.Q;
    end
    healthEnabled=cycleEnabled(k);
    ccm(k)=healthEnabled;
    phase=mod(m.t(k),p.Ts);
    stable=phase>locked.stableGuard && abs(phase-p.D*p.Ts)>locked.stableGuard && ...
        phase<p.Ts-locked.stableGuard;
    if stable
        H=[1,0,m.iC(k)];
        [x,P,nisV(k),gateV(k)]=update(x,P,m.vT(k),H,locked.RV, ...
            locked.gateV,I,healthEnabled,[true,false,false]);
    end
    while er<=height(edges) && edges.edge_time_s(er)+ ...
            1e-6*(opt(cfg,"edgeGuardUs",.5)+opt(cfg,"edgeWindowUs",1.5))<=m.t(k)
        H=[0,0,edges.i_sum_A(er)];
        pre=x;
        [x,P,nisR(er),gateR(er)]=update(x,P,edges.y_R_V(er),H, ...
            max(edges.R_R(er),locked.RRFloor),locked.gateR,I,healthEnabled, ...
            [false,false,healthEnabled]);
        if ~healthEnabled, x=pre; end
        er=er+1;
    end
    while ec<=height(charges) && charges.end_time_s(ec)<=m.t(k)
        yC=charges.delta_vT_V(ec)-x(3)*charges.delta_iC_A(ec);
        H=[0,charges.q_C(ec)/alphaScale,0];
        [x,P,nisC(ec),gateC(ec)]=update(x,P,yC,H, ...
            max(charges.R_C(ec),locked.RCFloor),locked.gateC,I, ...
            healthEnabled&&charges.valid(ec),[false,healthEnabled,false]);
        ec=ec+1;
    end
    preHist(k,:)=x';
    C=alphaScale/max(x(2),eps); C=min(max(C,.5*p.C1),1.5*p.C1);
    x(2)=alphaScale/C; x(3)=min(max(x(3),.1*p.ESR),4*p.ESR);
    P=.5*(P+P'); xHist(k,:)=x'; pDiag(k,:)=diag(P)';
end
tail=max(1,floor(.8*n)):n;
Cseries=alphaScale./xHist(:,2); Rseries=xHist(:,3);
preCSeries=alphaScale./preHist(:,2); preRSeries=preHist(:,3);
[~,preCIndex]=max(abs(preCSeries/p.C1-1),[],"omitnan");
[~,preRIndex]=max(abs(preRSeries/p.ESR-1),[],"omitnan");
result=struct("t",m.t,"vC",xHist(:,1),"C",Cseries,"ESR",Rseries, ...
    "preProjectionC",preCSeries,"preProjectionESR",preRSeries, ...
    "CpreFinal",preCSeries(preCIndex), ...
    "ESRpreFinal",preRSeries(preRIndex), ...
    "CpreTailMedian",median(preCSeries(tail),"omitnan"), ...
    "ESRpreTailMedian",median(preRSeries(tail),"omitnan"), ...
    "ccmHealthEnabled",ccm, ...
    "Cfinal",median(Cseries(tail)),"ESRfinal",median(Rseries(tail)), ...
    "CMape",100*abs(median(Cseries(tail))/p.C1-1), ...
    "ESRMape",100*abs(median(Rseries(tail))/p.ESR-1), ...
    "nisV",nisV,"nisC",nisC,"nisR",nisR,"gateV",gateV, ...
    "gateC",gateC,"gateR",gateR,"edges",edges,"charges",charges, ...
    "P",P,"Pdiag",pDiag,"locked",locked);
end

function [x,P,nis,accepted]=update(x,P,y,H,R,gate,I,enabled,freeRows)
innovation=y-H*x; S=H*P*H'+R; nis=innovation^2/max(S,eps);
accepted=enabled&&isfinite(nis)&&nis<=gate;
if accepted
    K=P*H'/S; K(~freeRows')=0; x=x+K*innovation;
    A=I-K*H; P=A*P*A'+K*R*K';
end
end

function locked=default_locked()
locked=struct("Q",diag([1e-9,1e-10,1e-10]),"RV",1e-5, ...
    "RRFloor",1e-6,"RCFloor",1e-6,"gateV",9,"gateC",9,"gateR",9, ...
    "stableGuard",.3e-6,"ccmCurrentThreshold",0,"resumeSamples",20, ...
    "resumeCycles",2);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
