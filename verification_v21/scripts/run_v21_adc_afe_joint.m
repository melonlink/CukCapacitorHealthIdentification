function summary=run_v21_adc_afe_joint(v21Root)
%RUN_V21_ADC_AFE_JOINT Joint AFE, anti-alias, S/H, ADC and estimator sweep.

if nargin<1, v21Root=fileparts(fileparts(mfilename("fullpath"))); end
repoRoot=fileparts(v21Root); v1Root=fullfile(repoRoot,"cuk_cap_health_verification");
addpath(genpath(v1Root),genpath(fullfile(repoRoot,"verification_v2")), ...
    genpath(v21Root));
tableDir=fullfile(v21Root,"results","tables"); figureDir=fullfile(v21Root,"results","figures");
rawDir=fullfile(v21Root,"results","raw");
L=load(fullfile(rawDir,"locked_covariance_v21.mat"),"locked"); locked=L.locked;
p=model_parameters(); base=simulate_switched_equation(p, ...
    struct("duration",.0025,"samplesPerPeriod",400)); cfg0=v21_default_config();
rates=1e6*[.4,.8,1,1.6,2.5,5,10]; bits=[14,16];
fcV=1e6*[.25,.5,1,1.5,2,3]; fcI=1e6*[.25,.5,1,2];
orders=[1,2]; phases=[.13,.67]; nRows=numel(rates)*numel(bits)* ...
    numel(fcV)*numel(fcI)*numel(orders)*numel(phases);
rows=cell(nRows,32); row=0;
for fsAdc=rates
    for adcBits=bits
        for fv=fcV
            for fi=fcI
                for order=orders
                    for phase=phases
                        cfg=cfg0; cfg.fsAdcHz=fsAdc; cfg.adcBits=adcBits;
                        cfg.afeFcVHz=fv; cfg.afeFcI1Hz=fi; cfg.afeFcI2Hz=fi;
                        cfg.afeOrder=order; cfg.samplePhase=phase;
                        cfg.seed=40000+row; m=v21_measurement_chain(base,p,cfg);
                        r=structured_ltv_estimator_v21(m,p,cfg,locked);
                        if isempty(r.edges)
                            pre=0; post=0; actualW=0; predictedVar=NaN;
                        else
                            pre=min(r.edges.pre_points); post=min(r.edges.post_points);
                            actualW=(max(r.edges.pre_points)-1)/fsAdc*1e6;
                            predictedVar=median(r.edges.edge_fit_variance_V2,"omitnan");
                        end
                        [attV,gdV,gdEdgeV]=frontend_metrics(order,fv,p.fs);
                        [attI,gdI,gdEdgeI]=frontend_metrics(order,fi,p.fs);
                        geometry=pre>=3 && post>=3;
                        pass=r.CMape<3 && r.ESRMape<5 && geometry && ...
                            m.voltageSaturationFraction==0 && m.currentSaturationFraction==0;
                        robustPass=pass && m.aliasRatioWorstdB<=-20;
                        row=row+1; rows(row,:)={row,fsAdc,1/fsAdc,adcBits,phase, ...
                            2,actualW,pre,post,geometry,order,fv,fi,fi, ...
                            attV,gdV,gdEdgeV,attI,gdI,gdEdgeI, ...
                            m.aliasRatioWorstdB,r.CMape,r.ESRMape, ...
                            mean(r.nisV,"omitnan"),mean(r.nisC,"omitnan"), ...
                            mean(r.nisR,"omitnan"),predictedVar, ...
                            m.voltageSaturationFraction,m.currentSaturationFraction, ...
                            pass,robustPass,"nominal_fsw"};
                    end
                end
            end
        end
    end
    fprintf("v2.1 joint ADC/AFE: completed fsADC %.3g MS/s.\n",fsAdc/1e6);
end
names=["test_id","fs_adc_Hz","adc_interval_s","adc_bits","sample_phase", ...
    "window_requested_us","window_actual_us","points_available_pre", ...
    "points_available_post","sampling_geometry_feasible","afe_order", ...
    "afe_fc_v_Hz","afe_fc_i1_Hz","afe_fc_i2_Hz","attenuation_v_at_fsw_dB", ...
    "group_delay_v_at_fsw_s","group_delay_v_edge_band_s", ...
    "attenuation_i_at_fsw_dB","group_delay_i_at_fsw_s", ...
    "group_delay_i_edge_band_s","alias_ratio_dB","C_MAPE_percent", ...
    "ESR_MAPE_percent","NIS_V_mean","NIS_C_mean","NIS_R_mean", ...
    "edge_predicted_variance_V2","voltage_saturation_fraction", ...
    "current_saturation_fraction","accuracy_geometry_pass","robust_alias_pass", ...
    "perturbation"];
jointTable=cell2table(rows,"VariableNames",names);

%% Explicit asynchronous checks at candidate and intentionally undersampled points.
stress=cell(0,numel(names)); stressId=row;
for fsAdc=1e6*[.8,1.6,2.5,5]
    for fv=1e6*[1,2]
        for delta=[-.01,.01]
            pp=p; pp.fs=p.fs*(1+delta); pp.Ts=1/pp.fs; pp.D=p.D;
            bb=simulate_switched_equation(pp,struct("duration",.0025, ...
                "samplesPerPeriod",400)); cfg=cfg0; cfg.fsAdcHz=fsAdc;
            cfg.afeFcVHz=fv; cfg.afeFcI1Hz=1e6; cfg.afeFcI2Hz=1e6;
            cfg.samplePhase=.41; cfg.seed=50000+stressId;
            m=v21_measurement_chain(bb,pp,cfg); r=structured_ltv_estimator_v21(m,pp,cfg,locked);
            if isempty(r.edges), pre=0; post=0; actualW=0; predictedVar=NaN;
            else
                pre=min(r.edges.pre_points); post=min(r.edges.post_points);
                actualW=(max(r.edges.pre_points)-1)/fsAdc*1e6;
                predictedVar=median(r.edges.edge_fit_variance_V2,"omitnan");
            end
            [attV,gdV,gdEdgeV]=frontend_metrics(2,fv,pp.fs);
            [attI,gdI,gdEdgeI]=frontend_metrics(2,1e6,pp.fs);
            geometry=pre>=3 && post>=3; pass=r.CMape<3 && r.ESRMape<5 && geometry;
            robustPass=pass && m.aliasRatioWorstdB<=-20; stressId=stressId+1;
            stress(end+1,:)={stressId,fsAdc,1/fsAdc,16,.41,2,actualW,pre,post, ...
                geometry,2,fv,1e6,1e6,attV,gdV,gdEdgeV,attI,gdI,gdEdgeI, ...
                m.aliasRatioWorstdB,r.CMape,r.ESRMape,mean(r.nisV,"omitnan"), ...
                mean(r.nisC,"omitnan"),mean(r.nisR,"omitnan"),predictedVar, ...
                m.voltageSaturationFraction,m.currentSaturationFraction,pass, ...
                robustPass,"fsw_"+compose("%+.0f",100*delta)+"pct_async"}; %#ok<AGROW>
        end
    end
end
stressTable=cell2table(stress,"VariableNames",names);
jointTable=[jointTable;stressTable];
writetable(jointTable,fullfile(tableDir,"table_adc_afe_joint_v21.csv"));

nominal=jointTable(jointTable.perturbation=="nominal_fsw",:);
keys=unique(nominal(:,["fs_adc_Hz","adc_bits","afe_order","afe_fc_v_Hz", ...
    "afe_fc_i1_Hz"]),"rows");
designRows=cell(height(keys),11);
for k=1:height(keys)
    z=nominal(nominal.fs_adc_Hz==keys.fs_adc_Hz(k) & ...
        nominal.adc_bits==keys.adc_bits(k) & nominal.afe_order==keys.afe_order(k) & ...
        nominal.afe_fc_v_Hz==keys.afe_fc_v_Hz(k) & ...
        nominal.afe_fc_i1_Hz==keys.afe_fc_i1_Hz(k),:);
    designRows(k,:)={keys.fs_adc_Hz(k),keys.adc_bits(k),keys.afe_order(k), ...
        keys.afe_fc_v_Hz(k),keys.afe_fc_i1_Hz(k),mean(z.accuracy_geometry_pass), ...
        mean(z.robust_alias_pass),max(z.C_MAPE_percent),max(z.ESR_MAPE_percent), ...
        max(z.alias_ratio_dB),min(z.points_available_pre)};
end
designTable=cell2table(designRows,"VariableNames",["fs_adc_Hz","adc_bits", ...
    "afe_order","afe_fc_v_Hz","afe_fc_i_Hz","phase_accuracy_pass_fraction", ...
    "phase_robust_alias_pass_fraction","worst_C_MAPE_percent", ...
    "worst_ESR_MAPE_percent","worst_alias_ratio_dB","minimum_points_per_side"]);
writetable(designTable,fullfile(tableDir,"table_final_design_region_v21.csv"));

fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
q=groupsummary(nominal,["fs_adc_Hz","afe_fc_v_Hz"],"mean","robust_alias_pass");
M=nan(numel(fcV),numel(rates));
for k=1:height(q)
    ii=fcV==q.afe_fc_v_Hz(k); jj=rates==q.fs_adc_Hz(k);
    M(ii,jj)=q.mean_robust_alias_pass(k);
end
nexttile; imagesc(rates/1e6,fcV/1e6,100*M); axis xy; colorbar; clim([0,100]);
xlabel("ADC rate (MS/s/channel)"); ylabel("Voltage AFE cutoff (MHz)");
title("Joint robust pass fraction (%)");
nexttile; good=nominal.robust_alias_pass;
scatter(nominal.fs_adc_Hz/1e6,nominal.afe_fc_v_Hz/1e6,18,good,"filled");
grid on; xlabel("ADC rate (MS/s/channel)"); ylabel("Voltage AFE cutoff (MHz)");
title("All bits/order/current-AFE/phase cases");
save_verification_figure(fig,figureDir,"fig_v21_09_adc_afe_pass_region");

fig=figure("Visible","off","Color","w"); tiledlayout(1,2);
nexttile; scatter(nominal.alias_ratio_dB,nominal.C_MAPE_percent,14, ...
    nominal.fs_adc_Hz/1e6,"filled"); yline(3,"k:"); grid on;
xlabel("Alias ratio (dB)"); ylabel("C MAPE (%)"); colorbar;
title("Aliasing and C error; color=MS/s");
nexttile; scatter(nominal.alias_ratio_dB,nominal.ESR_MAPE_percent,14, ...
    nominal.fs_adc_Hz/1e6,"filled"); yline(5,"k:"); grid on;
xlabel("Alias ratio (dB)"); ylabel("ESR MAPE (%)"); colorbar;
title("Aliasing and ESR error; color=MS/s");
save_verification_figure(fig,figureDir,"fig_v21_10_alias_error_correlation");

fig=figure("Visible","off","Color","w"); good=designTable.phase_robust_alias_pass_fraction==1;
scatter3(designTable.fs_adc_Hz/1e6,designTable.afe_fc_v_Hz/1e6, ...
    designTable.afe_fc_i_Hz/1e6,40,good,"filled"); grid on; view(35,25);
xlabel("ADC rate (MS/s)"); ylabel("Voltage AFE (MHz)"); zlabel("Current AFE (MHz)");
title("Final joint design region: all tested phases pass + AR <= -20 dB");
save_verification_figure(fig,figureDir,"fig_v21_15_final_design_region");

summary=struct("jointRows",height(jointTable),"designRows",height(designTable), ...
    "robustRows",sum(designTable.phase_robust_alias_pass_fraction==1), ...
    "minimumRobustRateHz",min(designTable.fs_adc_Hz( ...
    designTable.phase_robust_alias_pass_fraction==1),[],"omitnan"));
save(fullfile(rawDir,"adc_afe_joint_v21.mat"),"summary","jointTable","designTable","-v7.3");
end

function [attenuationDb,groupDelayFsw,groupDelayEdge]=frontend_metrics(order,fc,fsw)
attenuationDb=20*log10(abs(analog_response(order,fc,fsw)));
groupDelayFsw=group_delay(order,fc,fsw);
groupDelayEdge=group_delay(order,fc,250e3);
end

function H=analog_response(order,fc,f)
s=1i*2*pi*f; wn=2*pi*fc;
if order==1, H=wn./(s+wn);
else, H=wn^2./(s.^2+sqrt(2)*wn*s+wn^2); end
end

function gd=group_delay(order,fc,f)
df=max(10,1e-4*f); phase=unwrap(angle([analog_response(order,fc,f-df), ...
    analog_response(order,fc,f+df)]));
gd=-(phase(2)-phase(1))/(2*pi*2*df);
end
