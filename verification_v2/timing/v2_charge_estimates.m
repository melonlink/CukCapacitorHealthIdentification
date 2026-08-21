function chargeTable=v2_charge_estimates(m,p,cfg)
%V2_CHARGE_ESTIMATES Build C pseudo measurements in edge-guarded intervals.

if nargin<3, cfg=struct(); end
guard=1e-6*opt(cfg,"chargeGuardUs",.5);
qMin=opt(cfg,"qMinC",1e-7);
rPrior=opt(cfg,"ESRPrior",p.ESR);
RCFloor=opt(cfg,"RCFloor",1e-8);
rows=cell(2*max(numel(m.edgeTimes)-1,0),14); row=0;
for k=1:numel(m.edgeTimes)-1
    tr=m.edgeTimes(k); tf=tr+p.D*p.Ts; tn=m.edgeTimes(k+1);
    intervals={"ON",tr+guard,tf-guard;"OFF",tf+guard,tn-guard};
    for q=1:2
        idx=find(m.t>=intervals{q,2} & m.t<=intervals{q,3});
        if numel(idx)<3, continue; end
        charge=trapz(m.t(idx),m.iC(idx));
        dVT=m.vT(idx(end))-m.vT(idx(1));
        dIC=m.iC(idx(end))-m.iC(idx(1));
        yC=dVT-rPrior*dIC;
        valid=abs(charge)>=qMin && abs(yC)>eps;
        if valid, cRaw=charge/yC; else, cRaw=NaN; end
        RC=2*m.sigmaV^2+2*rPrior^2*m.sigmaI^2+RCFloor;
        row=row+1; rows(row,:)={row,k,string(intervals{q,1}),m.t(idx(1)), ...
            m.t(idx(end)),m.t(idx(end))-m.t(idx(1)),numel(idx),charge,dVT, ...
            dIC,yC,cRaw,valid,RC};
    end
end
chargeTable=cell2table(rows(1:row,:),"VariableNames",["measurement_id", ...
    "cycle","topology","start_time_s","end_time_s","integration_time_s", ...
    "sample_count","q_C","delta_vT_V","delta_iC_A","y_C_V", ...
    "C_raw_F","valid","R_C"]);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
