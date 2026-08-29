function result=structured_ltv_estimator_v21(m,p,cfg,locked)
%STRUCTURED_LTV_ESTIMATOR_V21 Compare masked, full and conditional variants.

if nargin<3, cfg=struct(); end
if nargin<4, locked=default_locked(); end
variant=string(opt(cfg,"estimatorVariant","conditional_structured"));
Cb=p.C1; n=numel(m.t); I=eye(3);
cfg.edgeMethod="timestamped_linear"; cfg.RRFloor=0;
edges=v2_edge_estimates(m,p,cfg); policy=v21_data_policy(m,p,cfg);
charges=policy.charges;
Cinit=opt(cfg,"Cinit",.9*p.C1); Rinit=opt(cfg,"ESRinit",.8*p.ESR);
x=[m.vT(1)-Rinit*m.iC(1);Cb/Cinit;Rinit];
% The health envelope is specified as C=80--100% and ESR=1--2x nominal.
% Use a prior broad enough that the 3-sigma gate does not reject that envelope.
P=diag([.5^2,.2^2,(.8*p.ESR)^2]);
xHist=zeros(n,3); PHist=zeros(3,3,n); nisV=nan(n,1);
nisC=nan(height(charges),1); nisR=nan(height(edges),1);
gateV=false(n,1); gateC=false(height(charges),1); gateR=false(height(edges),1);
ec=1; er=1; Ri=m.sigmaI^2; Rv=m.sigmaV^2;
for k=1:n
    if k>1
        q=.5*(m.iC(k-1)+m.iC(k))*(m.t(k)-m.t(k-1));
        dt=m.t(k)-m.t(k-1);
        F=[1,q/Cb,0;0,1,0;0,0,1];
        x=F*x; P=F*P*F'+locked.Q*dt;
    end
    if policy.stableMask(k)
        if variant=="conditional_structured"
            y=m.vT(k)-x(3)*m.iC(k); H=[1,0,0];
            R=Rv+x(3)^2*Ri+locked.voltageVarianceScale*m.iC(k)^2*P(3,3);
            R=max(locked.RVFloor,R);
            mask=[true,true,true];
        else
            y=m.vT(k); H=[1,0,m.iC(k)];
            R=max(locked.RVFloor,Rv+x(3)^2*Ri);
            if variant=="masked_v2", mask=[true,false,false];
            else, mask=[true,true,true]; end
        end
        [x,P,nisV(k),gateV(k)]=scalar_update(x,P,y,H,R,locked.gateV,I,mask);
    end
    while er<=height(edges) && edges.edge_time_s(er)+ ...
            (opt(cfg,"edgeGuardUs",.5)+opt(cfg,"edgeWindowUs",2))*1e-6<=m.t(k)
        H=[0,0,locked.edgeGainCorrection*edges.i_sum_A(er)];
        R=edge_observation_variance(m,edges,er,x(3),locked);
        [x,P,nisR(er),gateR(er)]=scalar_update(x,P,edges.y_R_V(er),H,R, ...
            locked.gateR,I,[true,true,true]); er=er+1;
    end
    while ec<=height(charges) && charges.end_time_s(ec)<=m.t(k)
        q=charges.q_C(ec); dI=charges.delta_iC_A(ec);
        y=charges.delta_vT_V(ec)-x(3)*dI; H=[0,q/Cb,0];
        idx=charges.sample_indices{ec};
        Rdi=2*Ri; Rq=max(numel(idx)-1,1)*(mean(diff(m.t(idx)))^2)*Ri;
        alpha=x(2)/Cb;
        R=2*Rv+dI^2*P(3,3)+x(3)^2*Rdi+alpha^2*Rq;
        R=max(locked.RCFloor,locked.chargeVarianceScale*R);
        [x,P,nisC(ec),gateC(ec)]=scalar_update(x,P,y,H,R,locked.gateC,I, ...
            [true,true,true]); ec=ec+1;
    end
    P=.5*(P+P'); xHist(k,:)=x'; PHist(:,:,k)=P;
end
Cseries=Cb./xHist(:,2); Rseries=xHist(:,3); tail=max(1,floor(.8*n)):n;
Cfinal=median(Cseries(tail),"omitnan"); Rfinal=median(Rseries(tail),"omitnan");
CtruthFinal=median(m.truthC(tail),"omitnan");
RtruthFinal=median(m.truthESR(tail),"omitnan");
neesFull=nan(n,1); neesParam=nan(n,1); neesC=nan(n,1); neesR=nan(n,1);
if opt(cfg,"computeNeesHistory",true), neesIndices=1:n; else, neesIndices=n; end
for k=neesIndices
    truth=[m.truthVC(k);Cb/m.truthC(k);m.truthESR(k)]; e=xHist(k,:)'-truth;
    neesFull(k)=e'*(pinv(PHist(:,:,k))*e);
    ep=e(2:3); Pp=PHist(2:3,2:3,k); neesParam(k)=ep'*(pinv(Pp)*ep);
    neesC(k)=e(2)^2/max(PHist(2,2,k),eps); neesR(k)=e(3)^2/max(PHist(3,3,k),eps);
end
alphaFinal=Cb/Cfinal; Ptail=median(PHist(:,:,tail),3);
sigmaC=Cb/max(alphaFinal^2,eps)*sqrt(max(Ptail(2,2),0));
sigmaR=sqrt(max(Ptail(3,3),0));
result=struct("variant",variant,"dataPolicy",policy.name,"gainMaskUsed", ...
    variant=="masked_v2","x",xHist,"P",PHist,"t",m.t,"C",Cseries, ...
    "ESR",Rseries,"Cfinal",Cfinal,"ESRfinal",Rfinal, ...
    "CtruthFinal",CtruthFinal,"ESRtruthFinal",RtruthFinal, ...
    "CMape",100*abs(Cfinal/CtruthFinal-1), ...
    "ESRMape",100*abs(Rfinal/RtruthFinal-1), ...
    "nisV",nisV,"nisC",nisC,"nisR",nisR,"gateV",gateV,"gateC",gateC, ...
    "gateR",gateR,"neesFull",neesFull,"neesParam",neesParam,"neesC",neesC, ...
    "neesR",neesR,"sigmaC",sigmaC,"sigmaESR",sigmaR, ...
    "CI_C_contains_true",abs(Cfinal-CtruthFinal)<=1.96*sigmaC, ...
    "CI_ESR_contains_true",abs(Rfinal-RtruthFinal)<=1.96*sigmaR, ...
    "edges",edges,"charges",charges,"policy",policy,"locked",locked);
end

function R=edge_observation_variance(m,edges,row,rhat,locked)
te=edges.edge_time_s(row);
pre=edges.pre_first_index(row):edges.pre_last_index(row);
post=edges.post_first_index(row):edges.post_last_index(row);
fPre=intercept_factor(m.t(pre)-te); fPost=intercept_factor(m.t(post)-te);
factor=fPre+fPost;
knownVoltage=m.sigmaV^2*factor;
knownCurrent=rhat^2*m.sigmaI^2*factor;
curvature=max(edges.edge_fit_variance_V2(row)-knownVoltage,0);
R=max(locked.RRFloor,knownVoltage+knownCurrent+ ...
    locked.edgeVarianceScale*curvature);
end

function factor=intercept_factor(t)
t=1e6*t(:); X=[ones(numel(t),1),t];
factor=[1,0]*pinv(X'*X)*[1;0];
end

function [x,P,nis,accepted]=scalar_update(x,P,y,H,R,gate,I,mask)
innovation=y-H*x; S=H*P*H'+R; nis=innovation^2/max(S,eps);
accepted=isfinite(nis)&&nis<=gate;
if accepted
    K=P*H'/S; K(~mask')=0; x=x+K*innovation;
    A=I-K*H; P=A*P*A'+K*R*K';
end
end

function locked=default_locked()
locked=struct("Q",diag([25,.5,.001]),"RVFloor",1e-8, ...
    "RCFloor",1e-10,"RRFloor",1e-10,"edgeVarianceScale",1, ...
    "chargeVarianceScale",1,"voltageVarianceScale",1, ...
    "edgeGainCorrection",1, ...
    "gateV",9,"gateC",9,"gateR",9);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
