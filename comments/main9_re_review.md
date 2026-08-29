# main(9) 论文第四轮复审意见
## ——电力电子与在线参数辨识专家视角

### 总体结论
**当前稿件的理论与论文叙事已经基本稳定。若目标为 IEEE TPEL / TIE / JESTPE，下一阶段的决定性工作应是硬件验证，而不是继续增加算法或大规模仿真。**

本轮修改已经基本解决上一轮提出的主要 P0 问题，因此建议从“继续改理论”转入“投稿前收口 + 硬件验证准备”。

---

# 1. 本轮修改中已经解决的问题

## 1.1 Abstract 的 feasibility 措辞已经修正

上一版摘要中的 “confirm feasibility” 证据强度偏高。当前版本已经改为：

> support device-realistic feasibility under the modeled DSP constraints

这与正文明确承认 F28379D 部分仍为 simulation 的边界一致。

## 1.2 Contribution 3 的 CRLB 口径已经统一

当前 contribution list 已改为：

> a conditional Cramér–Rao benchmark and sensitivity analysis

与正文 “Conditional CRLB Benchmark” 一致，不再使用容易引起“接近理论最优效率”误解的 efficiency analysis。

## 1.3 传感器需求表述已经更加准确

当前版本直接说明方法需要：

- terminal voltage；
- both inductor-current measurements；
- switching state；
- synchronized timestamps。

这比“commonly available”更严谨，避免泛化。

## 1.4 Section IV-A 的 conditional identifiability 已经补充完整

现在已经明确：

> Conditional on the accepted reconstructed regressors and the fixed calibration coefficient, \((\bar\alpha,r_C)\) is jointly locally identifiable from the raw observation model.

同时补充了 raw-observation covariance \(R_k\) 为 finite positive-definite 的条件。

当前 raw-pair identifiability 论证已经达到可以投稿的严谨程度。

## 1.5 O0 已正确定位为 generic baseline

当前版本明确写成：

> generic mixed-observation baseline (O0)

并说明：

> O0 is not claimed as a reproduction of any single published method.

这一点很好，避免了审稿人追问“O0 到底复现了哪篇文献”。

---

# 2. 上一轮两个时间定义问题已经解决

## 2.1 internal settling 与 report interval 已分开

当前版本已经明确：

\[
1.52~\text{ms},\quad 0.48~\text{ms},\quad 1.20~\text{ms}
\]

是 native-cycle internal settling，且均：

> well within one 20.48-ms external reporting interval

同时说明外部 report cadence 下，由于 step–report alignment，不同情况下会在第一或第二个 reported sample 观察到恢复。

这一表述现在是正确的。

## 2.2 257 cycles 与 64.72 ms 已解释清楚

当前版本明确区分：

- 257 post-step cycles（约 5.1 ms）的短冻结检查；
- full-horizon settling time；
- Table VI 的 settling time 从 health-change instant 起按 native per-cycle cadence 计时。

因此 TS-SLTVKE 的 capacitance step 在 64.72 ms 后才满足收敛判据，而 ESR 和 joint step 仍不恢复，逻辑已经自洽。

---

# 3. 新增 TS-SRKE 闭环验证非常有价值

上一版的一个明显缺口是：

> TS-SRKE 被称为 primary realization，但 closed-loop supplement 主要只验证 TS-D-RLS。

当前版本已经增加 supervised realization under feedback。

结果包括：

- nominal、load-step、reference-step 条件下 supervisor 不误触发；
- false-health peak < 0.50%；
- \(r_C\rightarrow2r_C\) 时 supervisor 触发一次并在 0.20 ms 内恢复；
- \(C\rightarrow0.8C\) 时触发一次并在 0.28 ms 内恢复；
- unsupervised parent 在 30 ms horizon 内仍不能恢复；
- supervised tail errors ≤ 0.26%。

这很好地回答了一个潜在审稿问题：

> controller transient 会不会被 supervisor 错判为 health change？

同时论文仍然承认 one noise seed、simple PI 和 controller-interaction breadth 未展开，这个边界是合理的。

---

# 4. 当前仍建议修改的理论细节

## 4.1 Proposition 1 的标题仍建议调整

Section IV-A 已经真正完成：

> Joint Identifiability from the Raw Observation Pair

而 Section IV-B 的 Proposition 1 仍叫：

> Operating-condition-induced finite-window identifiability

但这一部分实际处理的是 ESR-compensated sequential stream：

\[
z_C=\Delta v_T-\hat r_C\Delta i_C
\]

其中仍存在：

\[
(r_C-\hat r_C)\Delta i_C
\]

作为 bounded model mismatch。

因此更准确的定位应是：

> **sequential implementation 在两个参数方向上保持正的 finite-window information**

建议将 Proposition 1 标题改为：

> **Direction-wise finite-window information positivity**

或者：

> **Finite-window information bound for the sequential implementation**

这样理论层次最清楚：

- Section IV-A：identifiability；
- Section IV-B：information positivity；
- Section IV-D：covariance boundedness。

这是我目前唯一还强烈建议改的理论措辞。

---

# 5. 统计措辞建议再收紧一点

当前仍有：

> calibrated 88.93% joint coverage

论文已经说明 marginal 95% intervals 在近似独立情况下 simultaneous benchmark 为：

\[
0.95^2\approx90.25\%
\]

因此 88.93% 是接近 benchmark 的。

但 “calibrated” 在统计语境中有时会被理解成严格达到 nominal target。

建议 Discussion / Conclusion 中优先使用：

> **88.93% simultaneous coverage against the approximately 90.25% independence benchmark**

或者：

> **near-nominal simultaneous coverage**

Abstract 中保留 88.93% joint coverage 没问题。

---

# 6. 当前最大科学短板已经只剩硬件

现在论文已经包含：

- topology mechanism；
- raw-pair identifiability；
- sequential information bounds；
- covariance contraction；
- O0/O1 factorial；
- RLS / EKF / structured Kalman comparison；
- abrupt recovery；
- slow degradation；
- operating-point transient；
- closed-loop TS-D-RLS；
- closed-loop TS-SRKE；
- light-load availability；
- conditional CRLB benchmark；
- F28379D device-realistic acquisition；
- Monte Carlo；
- complexity analysis。

继续增加 UKF、particle filter、AI estimator 或更多 synthetic ramp，已经不会显著提高论文层级。

真正缺少的是：

> **真实 switching hardware 上，边沿 ESR 信息是否能够可靠重构。**

---

# 7. 为什么硬件对这篇论文尤其重要

本文最核心的 ESR 信息：

\[
z_R=\hat v_T^- - \hat v_T^+
\]

直接来自 switching edge。

真实系统中的：

- MOSFET \(dv/dt\)；
- diode reverse recovery；
- capacitor ESL；
- PCB stray inductance；
- ringing；
- common-mode transient；
- differential amplifier recovery；
- ADC aperture；
- trigger jitter；
- probing delay；
- ground bounce；

都会直接作用于该特征。

因此硬件实验不是普通意义上的“再增加一组结果”，而是在验证本文最核心的物理观测是否真的能从实际开关波形中提取。

---

# 8. 推荐的最小硬件验证集

不建议等待长期老化，先做 controlled C/ESR network。

## 样机建议

- \(V_{\rm in}=24~V\)；
- \(f_s=50~kHz\)；
- Ćuk converter；
- F28379D；
- 参数尽量与论文一致。

## C 档位

例如：

- 100 µF；
- 90 µF；
- 80 µF。

## ESR 档位

例如：

- 50 mΩ；
- 75 mΩ；
- 100 mΩ；
- 125 mΩ。

使用低感精密串联电阻。

## Ground truth

采用：

- LCR meter；
- impedance analyzer。

## 最值得展示的硬件图

1. 真实 \(v_T\) switching-edge waveform + safe windows + fitted lines；
2. \(\hat v_T^-\)、\(\hat v_T^+\)、\(z_R\) 的重构过程；
3. \(\hat C\) 与 LCR truth 对比；
4. \(\hat r_C\) 与 LCR truth 对比；
5. load / duty variation 下的误差。

这一组实验已经足够显著提升论文可信度。

---

# 9. 当前投稿判断

## IEEE TPEL

当前无硬件版本可以尝试投稿，但仍有明显被要求实验甚至直接拒稿的风险。

最可能的核心意见是：

> The proposed ESR observation relies on switching-edge voltage reconstruction, but all evidence remains simulation based.

补充最小硬件后，我认为 TPEL 就具有比较合理的投稿价值。

## IEEE JESTPE

与本文的 topology-aware monitoring、digital implementation、power-electronics reliability 比较契合。

补硬件后是很适合的目标。

## IEEE TIE

也可考虑，但 TIE 通常更强调：

- experimental validation；
- industrial implementation；
- real-time deployment。

因此也建议先补硬件。

---

# 10. 当前稿件评分

| 项目 | main(8) | main(9) |
|---|---:|---:|
| 电力电子物理创新 | 8.0 | **8.0** |
| 参数辨识理论 | 8.6 | **8.8** |
| 理论表述严谨性 | 8.6 | **9.0** |
| 创新叙事合理性 | 8.5 | **8.8** |
| 仿真验证完整性 | 8.7 | **9.1** |
| 闭环验证 | 7.0 | **8.5** |
| 统计严谨性 | 8.4 | **8.6** |
| 工程实现论证 | 7.6 | **8.0** |
| 硬件验证 | 3.0 | **3.0** |
| IEEE 写作成熟度 | 9.1 | **9.3** |

---

# 11. 下一步修改优先级

## P0：投稿前建议完成

1. 将 Section IV-B Proposition 1 从“再次证明 identifiability”调整为“sequential information positivity / information bound”；
2. 全文检查 “calibrated coverage” 的统计措辞；
3. 最终统一 figure/table cross-reference 和编号；
4. 做一次纯 LaTeX / IEEE 风格终检。

## P1：若目标 TPEL / TIE / JESTPE，强烈建议

5. 增加真实 Ćuk 硬件实验。

## P2：硬件阶段顺手补充

6. measured WCET；
7. 实测 AFE CMRR / edge ringing；
8. 温度实验；
9. \(k_R\) ±1% / ±2% sensitivity table。

---

# 12. 最终复审结论

这一版已经基本进入：

> **论文理论与仿真内容可以冻结，开始转硬件验证**

的阶段。

前几轮反复修改的主要问题——可辨识性、O0 公平性、CRLB 口径、时间定义、TS-SRKE 闭环验证——现在基本都已经解决。

从电力电子专家角度，不建议再通过增加算法来提高“创新性”。

这篇论文真正有价值的核心已经很明确：

> **Ćuk 传能电容的 \(+i_{L1}\leftrightarrow-i_{L2}\) 固有换流本身就是一个无需外加扰动的参数激励源；通过 topology-synchronous edge reconstruction 与 in-state charge balance，可以分别构造 ESR-dominant 和 capacitance-dominant observations。**

当前论文已经把：

> 电路物理  
> → 可辨识性  
> → 在线估计  
> → 统计验证  
> → 闭环验证  
> → DSP 可实现性

基本讲完整。

现在唯一缺失的关键链条是：

> **真实开关硬件验证。**

补上这一环以后，论文整体档次会明显提升。
