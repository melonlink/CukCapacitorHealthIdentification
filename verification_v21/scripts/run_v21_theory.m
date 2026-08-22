function summary=run_v21_theory(v21Root)
%RUN_V21_THEORY Sampling geometry, edge variance and C information studies.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); addpath(genpath(fullfile(repoRoot,"cuk_cap_health_verification")), ...
    genpath(fullfile(repoRoot,"verification_v2")),genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
for folder={tableDir,figureDir,rawDir}, if ~isfolder(folder{1}), mkdir(folder{1}); end, end

%% Task A: complete phase-aware sampling geometry.
geometry=v21_sampling_geometry();
writetable(geometry,fullfile(tableDir,"table_sampling_geometry_v21.csv"));
Ts=20e-6; Dgrid=linspace(.2,.8,301); configs=[3,.5;4,.5;3,1.0];
fig=figure("Visible","off","Color","w"); hold on;
for k=1:size(configs,1)
    denominator=min(Dgrid,1-Dgrid)*Ts-configs(k,2)*1e-6;
    fmin=(configs(k,1)-1)./denominator;
    plot(Dgrid,fmin/1e6,"LineWidth",1.2,"DisplayName",sprintf( ...
        'Nw=%d, g=%.1f us',configs(k,1),configs(k,2)));
end
grid on; ylim([0,3]); xlabel("Duty ratio D"); ylabel("A4 minimum ADC rate (MS/s)");
title("Sampling geometry lower bound — fsw=50 kHz"); legend("Location","best");
save_verification_figure(fig,figureDir,"fig_v21_01_sampling_feasible_region");
q=geometry(geometry.D==.4 & geometry.guard_us==.5 & ...
    geometry.points_required_per_side==3,:);
rates=unique(q.fs_adc_Hz)/1e6; widths=unique(q.window_us); map=nan(numel(widths),numel(rates));
for iw=1:numel(widths)
    for ir=1:numel(rates)
        z=q(q.window_us==widths(iw)&q.fs_adc_Hz==rates(ir)*1e6,:);
        map(iw,ir)=z.phase_feasible_fraction;
    end
end
fig=figure("Visible","off","Color","w"); imagesc(rates,widths,100*map); axis xy; colorbar;
xlabel("ADC rate (MS/s)"); ylabel("Window width (us)");
title("Phase feasibility (%) — D=0.4, Nw=3, guard=0.5 us");
save_verification_figure(fig,figureDir,"fig_v21_02_phase_point_availability");

%% Task B: theoretical edge variance versus actual Monte Carlo error.
p=model_parameters(); base=simulate_switched_equation(p,struct("duration",.0012, ...
    "samplesPerPeriod",800));
ratesMHz=[.8,1.6,2.5,5,10]; windowsUs=[1,1.5,2,2.5,3,5,6];
guardsUs=[.5,1]; points=[3,4]; sigmaV=2e-3; sigmaI=1e-3; nMc=12;
rows=cell(numel(ratesMHz)*numel(windowsUs)*numel(guardsUs)*numel(points),19); row=0;
for rate=ratesMHz
    for W=windowsUs
        for g=guardsUs
            for Nw=points
                cfg=struct("fsAdcHz",rate*1e6,"adcBits",24,"afeOrder",1, ...
                    "afeFcVHz",Inf,"afeFcI1Hz",Inf,"afeFcI2Hz",Inf, ...
                    "sigmaVmV",0,"sigmaImA",0,"edgeGuardUs",g, ...
                    "edgeWindowUs",W,"edgePointsPerSide",Nw,"seed",1);
                m0=v21_measurement_chain(base,p,cfg); e0=v2_edge_estimates(m0,p,cfg);
                if isempty(e0)
                    bias=NaN; actualSigma=NaN; actualRmse=NaN; predictedSigma=NaN;
                    predVar=NaN; empVar=NaN; fitRmse=NaN; available=0; status="INFEASIBLE";
                else
                    bias=median(e0.ESR_raw_Ohm-p.ESR,"omitnan"); samples=[]; predicted=[];
                    fitRmse=median(e0.edge_fit_rmse_V,"omitnan"); available=min( ...
                        [e0.pre_points;e0.post_points],[],"all");
                    for seed=1:nMc
                        cfg.seed=9000+seed; cfg.samplePhase=(seed-1)/nMc;
                        cfg.sigmaVmV=1e3*sigmaV; cfg.sigmaImA=1e3*sigmaI;
                        m=v21_measurement_chain(base,p,cfg); e=v2_edge_estimates(m,p,cfg);
                        if isempty(e), continue; end
                        samples=[samples;e.ESR_raw_Ohm]; %#ok<AGROW>
                        for ie=1:height(e)
                            tpre=m.t(e.pre_first_index(ie):e.pre_last_index(ie))-e.edge_time_s(ie);
                            tpost=m.t(e.post_first_index(ie):e.post_last_index(ie))-e.edge_time_s(ie);
                            vv=sigmaV^2*(prediction_factor(tpre)+prediction_factor(tpost));
                            iSum=max(abs(e.i_sum_A(ie)),eps);
                            predicted(end+1,1)=sqrt(vv/iSum^2+p.ESR^2*(2*sigmaI^2)/iSum^2); %#ok<AGROW>
                        end
                    end
                    actualSigma=std(samples,"omitnan"); empVar=actualSigma^2;
                    actualRmse=sqrt(mean((samples-p.ESR).^2,"omitnan"));
                    predictedSigma=median(predicted,"omitnan"); predVar=predictedSigma^2;
                    if isfinite(actualRmse), status="VALID"; else, status="INFEASIBLE"; end
                end
                geom=geometry(geometry.D==p.D&geometry.guard_us==g& ...
                    geometry.points_required_per_side==Nw&geometry.window_us==W& ...
                    geometry.fs_adc_Hz==rate*1e6,:);
                row=row+1; rows(row,:)={row,rate*1e6,1/(rate*1e6),g,W,Nw, ...
                    available,geom.phase_feasible_fraction,geom.phase95_feasible,bias, ...
                    bias^2,predVar,empVar,predictedSigma,actualSigma,actualRmse, ...
                    fitRmse,nMc,status};
            end
        end
    end
end
edgeTable=cell2table(rows,"VariableNames",["test_id","fs_adc_Hz","adc_interval_s", ...
    "edge_guard_us","edge_window_us","edge_points_per_side", ...
    "minimum_points_observed","phase_feasible_fraction","phase95_feasible", ...
    "simulation_bias_Ohm","simulation_bias2_Ohm2","edge_predicted_variance_Ohm2", ...
    "edge_empirical_variance_Ohm2","esr_predicted_sigma_Ohm", ...
    "esr_empirical_sigma_Ohm","esr_actual_RMSE_Ohm","edge_fit_rmse_V", ...
    "monte_carlo_seeds","status"]);
writetable(edgeTable,fullfile(tableDir,"table_edge_bias_variance_v21.csv"));
valid=edgeTable.status=="VALID";
fig=figure("Visible","off","Color","w"); scatter(edgeTable.edge_window_us(valid), ...
    1e6*edgeTable.simulation_bias2_Ohm2(valid),30, ...
    log10(edgeTable.edge_predicted_variance_Ohm2(valid)),"filled"); colorbar; grid on;
xlabel("Window width (us)"); ylabel("Squared bias (mOhm^2)");
title("Edge extrapolation bias-variance tradeoff — Model A");
save_verification_figure(fig,figureDir,"fig_v21_03_edge_bias_variance");
fig=figure("Visible","off","Color","w"); loglog(edgeTable.esr_predicted_sigma_Ohm(valid), ...
    edgeTable.esr_empirical_sigma_Ohm(valid),"o"); hold on; lim=[1e-5,1e-2];
plot(lim,lim,"k--"); xlim(lim); ylim(lim); grid on;
xlabel("Predicted ESR sigma (Ohm)"); ylabel("Empirical ESR sigma (Ohm)");
title("Predicted versus actual edge uncertainty — 12 phase/noise runs");
save_verification_figure(fig,figureDir,"fig_v21_04_predicted_vs_actual_esr_sigma");

%% Task C: charge-pseudo information by duty and load.
duties=[.25,.35,.4,.45,.55,.65]; loads=[.25,.5,1]; rows=cell(18,15); row=0;
for D=duties
    for loadFraction=loads
        p=model_parameters(); p.D=D; p.Rload=p.Rload/loadFraction;
        base=simulate_switched_equation(p,struct("duration",.0015,"samplesPerPeriod",800));
        cfg=struct("fsAdcHz",5e6,"adcBits",16,"afeOrder",2, ...
            "afeFcVHz",2e6,"afeFcI1Hz",1e6,"afeFcI2Hz",1e6, ...
            "sigmaVmV",10,"sigmaImA",5,"edgeGuardUs",.5,"edgeWindowUs",2, ...
            "edgePointsPerSide",3,"dataPolicy","disjoint","seed",42);
        m=v21_measurement_chain(base,p,cfg); policy=v21_data_policy(m,p,cfg);
        info=[]; rc=[]; qvals=[]; pRR=(.05*p.ESR)^2;
        for k=1:height(policy.charges)
            qC=policy.charges.q_C(k); dI=policy.charges.delta_iC_A(k);
            idx=policy.charges.sample_indices{k}; Rdi=2*m.sigmaI^2;
            Rq=max(numel(idx)-1,1)*mean(diff(m.t(idx)))^2*m.sigmaI^2;
            R=2*m.sigmaV^2+dI^2*pRR+p.ESR^2*Rdi+(1/p.C1)^2*Rq;
            info(end+1,1)=(qC/p.C1)^2/R; rc(end+1,1)=R; qvals(end+1,1)=qC; %#ok<AGROW>
        end
        information=sum(info); sigmaAlphaBar=1/sqrt(max(information,eps));
        crlbC=p.C1*sigmaAlphaBar; ccm=min([base.i1;base.i2])>0;
        row=row+1; rows(row,:)={row,p.Vin,D,loadFraction,p.Rload,ccm, ...
            min([base.i1;base.i2]),height(policy.charges),median(abs(qvals)), ...
            median(rc),median(info),information,crlbC,100*crlbC/p.C1, ...
            m.aliasRatioWorstdB};
    end
end
cInfo=cell2table(rows,"VariableNames",["test_id","Vin_V","D","load_fraction", ...
    "Rload_Ohm","is_CCM","minimum_inductor_current_A","C_pseudo_count", ...
    "median_abs_q_C","median_R_C_V2","median_C_information", ...
    "total_C_information","CRLB_C_F","CRLB_C_percent","alias_ratio_dB"]);
writetable(cInfo,fullfile(tableDir,"table_C_information_v21.csv"));
M=reshape(cInfo.total_C_information,numel(loads),numel(duties));
fig=figure("Visible","off","Color","w"); imagesc(duties,100*loads,log10(M));
axis xy; colorbar; xlabel("Duty ratio D"); ylabel("Load (%)");
title("log10 C pseudo information — disjoint policy, Model A");
save_verification_figure(fig,figureDir,"fig_v21_05_C_information_vs_load_duty");

summary=struct("geometryRows",height(geometry),"phase95Rows",sum(geometry.phase95_feasible), ...
    "edgeRows",height(edgeTable),"edgeValidRows",sum(valid),"CInfoRows",height(cInfo), ...
    "v2ConflictConfirmed",~any(geometry.phase95_feasible(geometry.D==.4 & ...
    geometry.guard_us==.5 & geometry.points_required_per_side==3 & ...
    geometry.window_us==2 & geometry.fs_adc_Hz==.8e6)));
save(fullfile(rawDir,"theory_summary.mat"),"summary","-v7.3");
fprintf('v2.1 theory: %d geometry rows, %d valid edge rows; v2 0.8MS/s/2us conflict=%d.\n', ...
    height(geometry),sum(valid),summary.v2ConflictConfirmed);
end

function factor=prediction_factor(t)
t=t(:); N=numel(t); factor=1/N+mean(t)^2/max(sum((t-mean(t)).^2),eps);
end
