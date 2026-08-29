# Manuscript — 导航

**最新英文论文 = 本目录 `main.pdf`；最新中文稿 = `chinese\main_zh.pdf`。**
这两份由 `build.ps1` 在每次构建后自动刷新——不要手工编辑它们。

```
manuscript\
├── main.pdf                  ← 最新英文编译稿（自动刷新，要找"最新论文"就是它）
├── main.tex                  ← LaTeX 入口（+ macros.tex, references.bib）
├── build.ps1                 ← 唯一构建入口：编译中英双稿并刷新两份"当前 PDF"
├── SCIENTIFIC_CHECKSUM_V06.csv ← 当前版本的冻结数字清单（编辑纪律）
├── sections\                 ← 英文正文各章节 01–10 + 附录
├── chinese\                  ← 中文稿（main_zh.tex 源 + main_zh.pdf 当前稿）
│                                英文稿是唯一 master，中文只收已定稿章节
├── figures\                  ← 图件 PDF + TikZ 源 + 出图脚本
│                                generate_manuscript_figures_v06.m + FIGURE_STANDARD.md
├── supplementary\            ← 补充材料 Note S1/S3 等
├── tables\ / source_traceability\ ← 表格与数字溯源矩阵
├── releases\                 ← 冻结的历史版本快照（只增不改）
│     main_v031_baseline.pdf    优化前基线（11 页）
│     main_v051.pdf             v0.5 排版版（13 页）
│     main_v060_integration.pdf v0.6 整合里程碑（14 页，2026-08-26）
│     letter_v01.pdf            已废弃的伴随信稿
├── audits\                   ← 全部审计/变更记录（V06_INTEGRATION_CHANGELOG.md
│                                的逐版 addenda 是当前工作的流水账）
└── build\ , chinese\build\   ← LaTeX 编译缓存（gitignore，可删）
```

## 构建（唯一正确方式）

```powershell
powershell -File build.ps1     # 在 manuscript\ 目录下
```

脚本做四件事：latexmk 编译英文稿 → 刷新 `main.pdf` → latexmk/xdvipdfmx
编译中文稿 → 刷新 `chinese\main_zh.pdf`。禁止只跑 latexmk 而不跑脚本，
否则根目录"当前 PDF"会悄悄过期（2026-08-27 曾因此过期一整轮修改）。

## 版本纪律

每轮版本收尾三件事：往 `releases\` 落一个**带版本号的冻结快照**
（命名 main_vXYZ_<里程碑>.pdf，落地后不再更新）、在 `audits\` 的
changelog 加 addendum、打 git 标签 `manuscript-vX.Y`。
`releases\` 里不放任何会变化的"current"文件——当前稿只有根目录
`main.pdf` 一处。
