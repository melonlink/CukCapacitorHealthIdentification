function result=v2_observability_information(m,p,cfg,locked,windows)
%V2_OBSERVABILITY_INFORMATION Normalized O and noise-weighted information.

if nargin<5, windows=[3,5,10,20]; end
edges=v2_edge_estimates(m,p,cfg);
charges=v2_charge_estimates(m,p,cfg);
sets=["stable_only","stable_plus_C","stable_plus_R","full_TR"];
rows=cell(numel(windows)*numel(sets),14); row=0;
for iw=1:numel(windows)
    N=windows(iw); tEnd=m.edgeTimes(end); tStart=tEnd-N*p.Ts;
    sample=find(m.t>=tStart & m.t<=tEnd);
    keep=sample(1:max(1,round(numel(sample)/(8*N))):end);
    qCum=cumtrapz(m.t(sample),m.iC(sample));
    stableRows=zeros(numel(keep),3); stableR=locked.RV*ones(numel(keep),1);
    for k=1:numel(keep)
        idx=keep(k); q=interp1(m.t(sample),qCum,m.t(idx));
        stableRows(k,:)=[1,q,m.iC(idx)];
    end
    Csel=charges.end_time_s>=tStart & charges.end_time_s<=tEnd & charges.valid;
    CRows=[zeros(sum(Csel),1),charges.q_C(Csel),zeros(sum(Csel),1)];
    CR=charges.R_C(Csel);
    Rsel=edges.edge_time_s>=tStart & edges.edge_time_s<=tEnd;
    RRows=[zeros(sum(Rsel),2),edges.i_sum_A(Rsel)]; RR=edges.R_R(Rsel);
    S=diag([p.Vin/(1-p.D),1/p.C1,p.ESR]);
    for is=1:numel(sets)
        O=stableRows; Rv=stableR;
        if sets(is)=="stable_plus_C" || sets(is)=="full_TR"
            O=[O;CRows]; Rv=[Rv;CR]; %#ok<AGROW>
        end
        if sets(is)=="stable_plus_R" || sets(is)=="full_TR"
            O=[O;RRows]; Rv=[Rv;RR]; %#ok<AGROW>
        end
        On=O*S; sv=svd(On); rankO=rank(On);
        condO=sv(1)/max(sv(end),eps);
        info=On'*(On./max(Rv,eps)); eigInfo=eig((info+info')/2);
        row=row+1; rows(row,:)={N,sets(is),rankO,sv(1),sv(end),condO, ...
            min(eigInfo),max(eigInfo),max(eigInfo)/max(min(eigInfo),eps), ...
            size(stableRows,1),size(CRows,1),size(RRows,1), ...
            locked.RV,median([CR;RR],"omitnan")};
    end
end
result=cell2table(rows,"VariableNames",["window_cycles","observation_set", ...
    "rank_Obs_normalized","max_sv_Obs_normalized","min_sv_Obs_normalized", ...
    "cond_Obs_normalized","info_min_eig","info_max_eig","info_cond", ...
    "stable_measurements","C_pseudo_measurements","R_pseudo_measurements", ...
    "R_V","median_pseudo_R"]);
end
