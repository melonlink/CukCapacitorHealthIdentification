# GPT 审核资料包

建议首先上传 `RESULT_FOR_CHATGPT.md`，并将以下数据文件和图片作为附件：

- `result_metrics.csv`：统一格式的全部验证指标，共 216 行。
- `table_sync_error.csv`：PWM 同步偏差测试结果。
- `table_ltv_observability.csv`：LTV 有限窗可观测性结果。
- `fig_08_sync_error.png`：同步误差结果图。
- `RESULT_SUMMARY.md`：面向人工阅读的简要结论。

这些文件是审核副本。权威生成结果仍位于：

- `../results/tables/`
- `../results/figures/`

完整结果可通过 `../scripts/run_all.m` 重新生成。
