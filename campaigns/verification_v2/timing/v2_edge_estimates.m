function edgeTable=v2_edge_estimates(m,p,cfg)
%V2_EDGE_ESTIMATES Timestamped adjacent/linear/robust edge observations.

if nargin<3, cfg=struct(); end
method=string(opt(cfg,"edgeMethod","timestamped_linear"));
guard=1e-6*opt(cfg,"edgeGuardUs",.5);
width=1e-6*opt(cfg,"edgeWindowUs",1.5);
minPoints=opt(cfg,"edgePointsPerSide",3);
order=opt(cfg,"edgeFitOrder",double(method=="robust_polynomial")+1);
rows=cell(numel(m.edgeTimes),21); row=0;
for k=1:numel(m.edgeTimes)
    te=m.edgeTimes(k);
    pre=find(m.t>=te-guard-width & m.t<=te-guard);
    post=find(m.t>=te+guard & m.t<=te+guard+width);
    if method=="adjacent"
        iPre=find(m.t<te,1,"last"); iPost=find(m.t>=te,1,"first");
        if isempty(iPre)||isempty(iPost), continue; end
        pre=iPre; post=iPost;
    elseif numel(pre)<minPoints || numel(post)<minPoints
        continue;
    end
    if method=="adjacent"
        vm=m.vT(pre); vp=m.vT(post); i1m=m.i1(pre); i2p=m.i2(post);
        varVm=m.sigmaV^2; varVp=m.sigmaV^2; varI=2*m.sigmaI^2;
        rmse=0; usedPre=1; usedPost=1;
    else
        robust=method=="robust_polynomial";
        [vm,varVm,rmseM,usedPre]=fit_at_edge(m.t(pre)-te,m.vT(pre),order,robust);
        [vp,varVp,rmseP,usedPost]=fit_at_edge(m.t(post)-te,m.vT(post),order,robust);
        [i1m,varI1]=fit_at_edge(m.t(pre)-te,m.i1(pre),order,robust);
        [i2p,varI2]=fit_at_edge(m.t(post)-te,m.i2(post),order,robust);
        varI=varI1+varI2; rmse=sqrt(.5*(rmseM^2+rmseP^2));
    end
    iSum=i1m+i2p; yR=vm-vp; rawR=yR/iSum;
    RR=varVm+varVp+p.ESR^2*varI+opt(cfg,"RRFloor",1e-8);
    row=row+1;
    rows(row,:)={row,te,method,pre(1),pre(end),post(1),post(end), ...
        numel(pre),numel(post),usedPre,usedPost,vm,vp,yR,i1m,i2p,iSum, ...
        rawR,rmse,varVm+varVp,RR};
end
edgeTable=cell2table(rows(1:row,:),"VariableNames",["edge_id","edge_time_s", ...
    "edge_method","pre_first_index","pre_last_index","post_first_index", ...
    "post_last_index","pre_points","post_points","pre_points_used", ...
    "post_points_used","v_minus_V","v_plus_V","y_R_V","i1_minus_A", ...
    "i2_plus_A","i_sum_A","ESR_raw_Ohm","edge_fit_rmse_V", ...
    "edge_fit_variance_V2","R_R"]);
end

function [prediction,predictionVar,rmse,nUsed]=fit_at_edge(x,y,order,robust)
x=x(:); y=y(:); X=zeros(numel(x),order+1);
for q=0:order, X(:,q+1)=x.^q; end
w=ones(size(y));
for iter=1:double(robust)*5+1
    W=diag(w); beta=(X'*W*X)\(X'*W*y); residual=y-X*beta;
    if robust
        scale=1.4826*median(abs(residual-median(residual)))+eps;
        z=abs(residual)/(1.345*scale); w=ones(size(z));
        w(z>1)=1./z(z>1);
    end
end
dof=max(sum(w>.2)-size(X,2),1);
s2=sum(w.*residual.^2)/dof; covB=s2*pinv(X'*W*X);
prediction=beta(1); predictionVar=max(covB(1,1),0);
rmse=sqrt(mean(residual.^2)); nUsed=sum(w>.2);
end

function value=opt(s,name,defaultValue)
if isfield(s,name), value=s.(name); else, value=defaultValue; end
end

