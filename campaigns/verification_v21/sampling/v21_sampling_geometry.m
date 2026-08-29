function geometry=v21_sampling_geometry()
%V21_SAMPLING_GEOMETRY Enumerate phase-aware edge-window feasibility.

fsw=50e3; Ts=1/fsw;
duties=[.25,.35,.40,.45,.55,.65]; guardsUs=[.2,.5,1.0];
points=[3,4,5,6]; windowsUs=[1,1.5,2,2.5,3,5,6];
ratesMHz=[.4,.6,.8,1,1.25,1.6,2,2.5,3.2,5,10];
nRows=numel(duties)*numel(guardsUs)*numel(points)*numel(windowsUs)*numel(ratesMHz);
rows=cell(nRows,21); row=0; phaseFractions=(0:63)/64;
for D=duties
    for guardUs=guardsUs
        for Nw=points
            for windowUs=windowsUs
                for rateMHz=ratesMHz
                    Ta=1/(rateMHz*1e6); g=guardUs*1e-6; W=windowUs*1e-6;
                    marginOn=D*Ts-g-W; marginOff=(1-D)*Ts-g-W;
                    countWorst=zeros(numel(phaseFractions),1);
                    countPre=zeros(numel(phaseFractions),1);
                    countPost=countPre;
                    for ip=1:numel(phaseFractions)
                        phi=phaseFractions(ip)*Ta;
                        % Rising-edge windows; falling-edge phase is shifted by D*Ts.
                        cRisePre=count_grid(-g-W,-g,Ta,phi);
                        cRisePost=count_grid(g,g+W,Ta,phi);
                        phiFall=mod(phi-D*Ts,Ta);
                        cFallPre=count_grid(-g-W,-g,Ta,phiFall);
                        cFallPost=count_grid(g,g+W,Ta,phiFall);
                        countPre(ip)=min(cRisePre,cFallPre);
                        countPost(ip)=min(cRisePost,cFallPost);
                        countWorst(ip)=min([cRisePre,cRisePost,cFallPre,cFallPost]);
                    end
                    feasiblePhase=countWorst>=Nw & marginOn>=-eps & marginOff>=-eps;
                    row=row+1; rows(row,:)={row,D,guardUs,Nw,windowUs,rateMHz*1e6, ...
                        Ta,mean(countPre),mean(countPost),min(countPre),min(countPost), ...
                        min(countWorst),max(countWorst),mean(feasiblePhase), ...
                        mean(feasiblePhase)>=.5,mean(feasiblePhase)>=.95, ...
                        all(feasiblePhase),any(feasiblePhase),marginOn*1e6, ...
                        marginOff*1e6,W>=(Nw-1)*Ta-eps};
                end
            end
        end
    end
end
geometry=cell2table(rows,"VariableNames",["test_id","D","guard_us", ...
    "points_required_per_side","window_us","fs_adc_Hz","adc_interval_s", ...
    "mean_points_pre","mean_points_post","worst_points_pre", ...
    "worst_points_post","worst_phase_available_points", ...
    "designed_phase_max_points","phase_feasible_fraction", ...
    "mean_feasible","phase95_feasible","phase100_feasible", ...
    "designed_phase_feasible","duty_on_margin_us","duty_off_margin_us", ...
    "A1_window_span_feasible"]);
end

function count=count_grid(a,b,Ta,phi)
n0=ceil((a-phi)/Ta-1e-12); n1=floor((b-phi)/Ta+1e-12);
count=max(0,n1-n0+1);
end
