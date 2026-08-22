function policy=v21_data_policy(m,p,cfg)
%V21_DATA_POLICY Build disjoint or overlapping raw-sample assignments.

mode=string(opt(cfg,"dataPolicy","disjoint"));
g=opt(cfg,"edgeGuardUs",.5)*1e-6; W=opt(cfg,"edgeWindowUs",2)*1e-6;
chargeGuard=opt(cfg,"chargeGuardUs",.5)*1e-6;
n=numel(m.t); edgeMask=false(n,1);
for te=reshape(m.edgeTimes,1,[])
    edgeMask=edgeMask | (m.t>=te-g-W & m.t<=te-g) | ...
        (m.t>=te+g & m.t<=te+g+W);
end
stableMask=false(n,1); rows={}; row=0;
for k=1:max(numel(m.edgeTimes)-1,0)
    tr=m.edgeTimes(k); tf=tr+p.D*p.Ts; tn=m.edgeTimes(k+1);
    intervals={"ON",tr+chargeGuard,tf-chargeGuard; ...
        "OFF",tf+chargeGuard,tn-chargeGuard};
    for q=1:2
        idx=find(m.t>=intervals{q,2} & m.t<=intervals{q,3} & ~edgeMask);
        if mode=="disjoint"
            split=max(3,floor(.55*numel(idx))); cIdx=idx(1:min(split,numel(idx)));
            vIdx=idx(min(split+1,numel(idx)+1):end); stableMask(vIdx)=true;
        else
            cIdx=idx; stableMask(idx)=true;
        end
        if numel(cIdx)<3, continue; end
        charge=trapz(m.t(cIdx),m.iC(cIdx));
        dV=m.vT(cIdx(end))-m.vT(cIdx(1));
        dI=m.iC(cIdx(end))-m.iC(cIdx(1));
        row=row+1; rows(row,:)={row,k,string(intervals{q,1}),cIdx(1),cIdx(end), ...
            {cIdx},m.t(cIdx(1)),m.t(cIdx(end)),charge,dV,dI,numel(cIdx)}; %#ok<AGROW>
    end
end
if mode=="overlap"
    phase=mod(m.t,p.Ts); stableGuard=opt(cfg,"stableGuardUs",.3)*1e-6;
    stableMask=phase>stableGuard & abs(phase-p.D*p.Ts)>stableGuard & ...
        phase<p.Ts-stableGuard;
end
charges=cell2table(rows,"VariableNames",["measurement_id","cycle","topology", ...
    "first_index","last_index","sample_indices","start_time_s","end_time_s", ...
    "q_C","delta_vT_V","delta_iC_A","sample_count"]);
policy=struct("name",mode,"stableMask",stableMask,"edgeMask",edgeMask, ...
    "charges",charges,"overlapStableCharge",mode=="overlap", ...
    "stableCount",sum(stableMask),"chargeSampleCount",sum(cellfun(@numel, ...
    charges.sample_indices)));
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end
