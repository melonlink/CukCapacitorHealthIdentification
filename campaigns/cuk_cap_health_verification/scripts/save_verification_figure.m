function save_verification_figure(fig, figureDir, baseName)
%SAVE_VERIFICATION_FIGURE Export a verification figure to PNG and FIG.

if ~isfolder(figureDir), mkdir(figureDir); end
exportgraphics(fig, fullfile(figureDir, baseName + ".png"), "Resolution", 180);
savefig(fig, fullfile(figureDir, baseName + ".fig"));
close(fig);
end

