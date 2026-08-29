function exportVector(f, path)
%EXPORTVECTOR Vector-only export at authored size (rule G1/G3).
exportgraphics(f, path, "ContentType", "vector", ...
    "BackgroundColor", "white");
close(f);
end
