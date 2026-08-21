function reviewDir=package_v2_for_gpt(v2Root)
%PACKAGE_V2_FOR_GPT Collect reports, tables and PNG figures for external review.

if nargin<1, v2Root=fileparts(fileparts(mfilename("fullpath"))); end
reviewDir=fullfile(v2Root,"gpt_review_package");
tableOut=fullfile(reviewDir,"tables"); figureOut=fullfile(reviewDir,"figures");
for folder={reviewDir,tableOut,figureOut}
    if ~isfolder(folder{1}), mkdir(folder{1}); end
end

topFiles=["README_V2.md","BASELINE_REPRODUCTION.md", ...
    "V1_V2_COMPARISON.md","RESULT_V2_FOR_CHATGPT.md","result_metrics_v2.csv"];
for file=topFiles
    source=fullfile(v2Root,file); if isfile(source), copyfile(source,reviewDir,"f"); end
end

auditFile=fullfile(v2Root,"logs","RUN_V2_AUDIT.md");
if isfile(auditFile), copyfile(auditFile,reviewDir,"f"); end

tables=dir(fullfile(v2Root,"results","tables","*.csv"));
for k=1:numel(tables), copyfile(fullfile(tables(k).folder,tables(k).name),tableOut,"f"); end
figures=dir(fullfile(v2Root,"results","figures","fig_v2_*.png"));
for k=1:numel(figures), copyfile(fullfile(figures(k).folder,figures(k).name),figureOut,"f"); end

taskFile=fullfile(fileparts(v2Root),"docs", ...
    "Codex_Cuk_Capacitor_Health_Verification_Task_v2.0.md");
if isfile(taskFile), copyfile(taskFile,reviewDir,"f"); end
fprintf('GPT review package: %s (%d tables, %d figures).\n', ...
    reviewDir,numel(tables),numel(figures));
end
