# Manuscript Final Author Patch
# Ćuk Energy-Transfer Capacitor C–ESR Identification
# v0.31 后最终作者级小修改

> **输入版本**：当前 `main(6).tex / main(6).pdf`  
> **任务性质**：最终作者级文字/图注小补丁  
> **科学状态**：
>
> \[
> \boxed{\text{THEORY / ALGORITHM / SIMULATION RESULTS FROZEN}}
> \]
>
> **禁止事项**：
>
> - 不修改任何公式；
> - 不修改 Proposition 1 / Proposition 2；
> - 不修改 TS-D-RLS / TS-SLTVKE；
> - 不修改 \(k_R\)、\(\lambda\)、Q/R、gate 数值；
> - 不重新运行仿真；
> - 不修改任何性能结果；
> - 不修改算法主次结论；
> - 不新增 novelty claim；
> - 不新增硬件实验主张；
> - 不创建新的 scientific verification 版本。

---

# 1. 修改 TS-D-RLS 小节中的 gating 表述

## 当前问题

Section V-A 当前存在类似表述：

```text
Gating rejects weak rows, and projection enforces
predeclared physical intervals.
```

该表述容易让审稿人误解为 C 通道存在一个未报告的数值幅值 gate。

但当前真实实现中：

- ESR 通道存在预先锁定：
  \[
  I_{\Sigma,\mathrm{gate}}=0.12\ \mathrm{A}
  \]
- C 通道没有独立数值 \(q_{\rm gate}\)；
- C observation 的有效性由：
  - CCM；
  - safe-window validity；
  - timestamp/topology validity；
  - accepted charge observation；
  等规则确定。

---

## 1.1 建议修改

将：

```text
Gating rejects weak rows, and projection enforces
predeclared physical intervals.
```

改为：

```text
Gating rejects invalid or insufficiently qualified edge/charge
observations, while projection enforces predeclared physical
parameter intervals.
```

或者更简洁：

```text
Validity gating rejects observations that fail the predeclared
edge/charge acceptance rules, while projection enforces the
physical parameter intervals.
```

---

## 1.2 要求

全文搜索：

```text
weak rows
weak charge row
weak edge
```

如果这些表述暗示存在未定义的 numeric C-channel threshold，应统一改成：

```text
invalid observation
insufficiently qualified observation
failed acceptance rule
```

但不要改变 Section III-D 已经冻结的 gate 定义。

---

# 2. 在 Limitations 中补 sensing applicability 边界

## 当前事实

方法需要：

\[
v_T,\quad i_1,\quad i_2,\quad \text{PWM state/timestamp}
\]

Table I 已经如实列出 sensing burden。

方法不需要 transfer-capacitor branch 的专用电流传感器，因为：

\[
i_C=(1-u)i_1-ui_2.
\]

但是如果实际 Cuk 控制器没有同时测量：

\[
i_1,\quad i_2,
\]

则当前方法不能直接部署而无需额外处理。

---

## 2.1 建议补充位置

放在 Section IX-C `Limitations` 的第 1 项之后，或并入第 1 项。

---

## 2.2 推荐英文

建议加入：

```text
The method is most directly applicable when both inductor
currents are already measured. Otherwise, an additional current
measurement or a separately validated current-reconstruction
scheme is required before applying (2).
```

---

## 2.3 如果希望更紧凑

可以写：

```text
The method assumes availability of both inductor currents;
applications lacking one of these measurements require an
additional sensor or an independently validated current
reconstruction.
```

---

## 2.4 注意

不要写：

```text
requires no additional sensors
sensorless
current-sensorless
```

因为本文并不是完全 current-sensorless 方法。

正确表述应保持：

> no dedicated capacitor-branch current sensor

而不是：

> no current sensors.

---

# 3. 修改 Fig. 8 的纵坐标命名

## 当前图

Fig. 8 使用：

\[
\frac{\mathrm{MAPE}_C+\mathrm{MAPE}_{ESR}}{2}
\]

作为可视化 Pareto summary。

当前 caption 已经说明：

> it is not a weighted selection score.

这个处理基本正确。

---

## 3.1 建议修改 y-axis label

将较公式化或容易被误解为“统一性能指标”的纵轴改成：

```text
Mean of C/ESR MAPE (%)
```

或：

```text
Arithmetic mean of C and ESR MAPE (%)
```

推荐第一种，图上更简洁。

---

## 3.2 Caption 建议

修改为：

```text
Accuracy–complexity tradeoff under the common operation-count
model. The ordinate is the arithmetic mean of the capacitance
and ESR mean MAPE values and is used only as a visual summary
for Pareto comparison, not as the estimator-selection objective.
```

---

## 3.3 Discussion / Results 中的使用

不要写：

```text
the lowest overall score
the best combined metric
```

只写：

```text
visual Pareto summary
accuracy–complexity tradeoff
aggregate comparison
```

算法选择仍基于多指标科学判断，而不是 Fig. 8 的单一纵坐标。

---

# 4. Scientific checksum

执行修改后，以下冻结数字必须完全不变：

```text
TS-D-RLS C MAPE = 0.3727%
TS-D-RLS ESR MAPE = 0.2233%
TS-D-RLS convergence = 13.21 cycles

TS-SLTVKE C MAPE = 0.3011%
TS-SLTVKE ESR MAPE = 0.6446%

Dual EKF C MAPE = 0.3043%
Dual EKF ESR MAPE = 1.1938%

mu_C = 0.217943
mu_R = 880.008

k_R manuscript display = 0.9772
k_R full precision = 0.97719802594550731

I_Sigma,gate = 0.12 A

T_w,C = 2.0 us
T_w,R = 2.2 us

F28379D p95 C = 1.6425%
F28379D p95 ESR = 2.6109%
```

如任何科学数字发生变化：

```text
STOP_AND_REPORT_NUMERIC_DRIFT
```

不得继续。

---

# 5. 不再修改的内容

以下全部冻结：

- Title；
- Abstract 的科学数字；
- Introduction contribution structure；
- Eq. (1)–(40)；
- \(k_R\) calibration formulation；
- online gate / evaluated PE lower-bound distinction；
- Proposition 1 wording：
  ```text
  locally identifiable over the accepted finite window
  ```
- Proposition 2；
- TS-D-RLS / TS-SLTVKE roles；
- factorial results；
- static comparison；
- timing/noise results；
- degradation-ramp results；
- F28379D device-realistic results；
- Appendix A/B；
- reference set，除非发现明确 bibliographic error。

---

# 6. 最终视觉检查

修改后重新编译 PDF，并检查：

- [ ] Fig. 8 y-axis 新名称正确；
- [ ] Fig. 8 caption 与正文一致；
- [ ] Limitations 新 sensing 条款没有导致页面明显溢出；
- [ ] Section V-A gating 表述与 Section III-D 一致；
- [ ] 无 overfull equation/table；
- [ ] Ćuk accent 仍正常；
- [ ] 所有 figure/table references 正常；
- [ ] 总页数变化合理。

---

# 7. 输出建议

可以直接覆盖作者清理分支，或建立：

```text
manuscript_final_author_patch/
```

至少保存：

```text
main.tex
main.pdf
FINAL_AUTHOR_PATCH_CHANGELOG.md
FINAL_AUTHOR_PATCH_AUDIT.md
```

---

# 8. FINAL_AUTHOR_PATCH_CHANGELOG.md

记录三项修改：

```text
P1  Section V-A gating wording
P2  Limitations sensing applicability
P3  Fig. 8 Pareto-axis wording
```

所有项：

```text
Scientific content changed? NO
Frozen number changed? NO
```

---

# 9. 最终验收

全部完成后输出：

```text
FINAL_AUTHOR_PATCH_PASS
```

该状态表示：

\[
\boxed{
\text{论文理论、算法、仿真、作者级科学措辞全部冻结}
}
\]

下一阶段不再创建 manuscript scientific revision。

后续只允许：

1. 作者署名/单位；
2. 目标期刊模板适配；
3. 硬件实验结果插入；
4. 投稿前 bibliographic check；
5. cover letter / highlights；
6. 根据真实 reviewer comments 做 revision。

---

# 10. Codex 执行指令

**以当前 `main(6).tex/pdf` 为基础完成最终作者级小补丁，不修改任何冻结公式、算法和性能数字。第一，将 TS-D-RLS 小节中类似 `Gating rejects weak rows` 的表述改为 `Validity gating rejects observations that fail the predeclared edge/charge acceptance rules` 或等价准确表述，避免暗示存在未报告的 numeric q-gate。第二，在 Limitations 中明确该方法最直接适用于已测量 \(i_1\) 和 \(i_2\) 的 Cuk 系统；若缺少其中一路，需要增加电流测量或经过独立验证的 current-reconstruction 方法，同时保持 `no dedicated capacitor-branch current sensor` 的准确主张。第三，将 Fig. 8 纵坐标改为 `Mean of C/ESR MAPE (%)`，并在 caption 中明确该量只用于 visual Pareto summary，不是 estimator-selection objective。修改后执行 scientific checksum，任何冻结数值变化均立即停止。重新编译并完成最终视觉审计，通过后输出 `FINAL_AUTHOR_PATCH_PASS`。**

---

## Status

- Scientific theory: **FROZEN**
- Algorithms: **FROZEN**
- Simulation results: **FROZEN**
- Author wording: **FINAL PATCH**
