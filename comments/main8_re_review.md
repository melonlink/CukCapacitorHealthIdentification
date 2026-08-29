# main(8) 论文第三轮复审意见
## ——电力电子与在线参数辨识专家视角

### 论文题目
*Topology-Synchronous Decoupled Observations and Supervised-Reset Estimation for Online C–ESR Monitoring of the Ćuk Energy-Transfer Capacitor*

### 总体建议
**若目标为 IEEE TPEL / TIE / JESTPE：Major Revision，主要原因已经不是理论，而是缺少真实硬件验证。**

---

# 1. 总体评价

当前 `main(8)` 相比上一版又有实质进步。上一轮提出的两个 P0 理论问题已经按正确方向修改：

1. 不再把 \(q\neq0\)、\(I_\Sigma\neq0\)、\(k_R\neq0\) 简单写成全部由 validity gate “exactly enforced”；
2. 已明确 raw \(2\times2\) observation pair 只是 **identifiability construction**，实际 DSP 在线实现不需要同时做联合矩阵更新。

目前 Section IV-A 的逻辑已经基本成立：

\[
\begin{bmatrix}
\Delta v_T\\
z_R
\end{bmatrix}
=
\begin{bmatrix}
q/C_b & \Delta i_C\\
0 & k_RI_\Sigma
\end{bmatrix}
\begin{bmatrix}
\bar\alpha\\
r_C
\end{bmatrix}
+\nu
\]

并明确区分：

- raw-pair joint identifiability；
- sequential online implementation；
- per-direction information bounds。

因此，本轮不建议继续大规模重构理论。现在论文真正的限制已经集中在**实验等级和少数内部一致性问题**。

---

# 2. 上一轮两项 P0 修改检查

## 2.1 Validity-gate 表述 —— 已解决

当前版本已改为：

- edge-current condition 由 (17) 显式约束；
- nonzero accepted charge 来自 evaluated valid-CCM envelope 内的 sign-invariant charge windows；
- \(k_R\neq0\) 是 calibration assumption，而不是 online gate。

这是正确写法。

## 2.2 Raw pair 与 sequential implementation 的关系 —— 已解决

当前版本已经明确说明：

> the stacked pair is an identifiability construction only; the online implementation need not process the two rows simultaneously

并允许后续分别统计：

\[
m_C,\qquad m_R
\]

这消除了“理论上联合、实现上是否必须同步矩阵更新”的歧义。

---

# 3. 当前仍值得修改的理论细节

## 3.1 建议把 raw-pair identifiability 明确限定为 conditional regression identifiability

当前 \(H_k\) 中：

\[
q,\qquad \Delta i_C,\qquad I_\Sigma
\]

实际上均来自测量或重构信号，因此严格来说存在 **errors-in-variables** 问题。

论文后面对这些误差已经通过：

- \(R_q\)；
- \(R_{\Delta i}\)；
- conditional covariance；

进行了处理，因此不需要重新建立 EIV 理论。

但 Section IV-A 最好增加一个限定：

> conditional on the accepted reconstructed regressors and the fixed calibration coefficient.

推荐将类似：

> \((\bar\alpha,r_C)\) is jointly locally identifiable from the raw observations

改成：

> Conditional on the accepted reconstructed regressors and fixed calibration coefficient, \((\bar\alpha,r_C)\) is jointly locally identifiable from the raw observation model.

这样会更符合本文后面的 conditional CRLB / conditional covariance 框架。

---

## 3.2 Proposition 1 的名称仍可进一步优化

Section IV-A 已经完成了真正的 joint identifiability proof。

Section IV-B 的 Proposition 1 则是在 ESR-compensated sequential stream 上建立：

\[
G_{\theta,N}\succeq
\operatorname{diag}(\mu_C,\mu_R)\succ0
\]

由于 charge pseudo-measurement 中仍然存在：

\[
(r_C-\hat r_C)\Delta i_C
\]

这一 bounded model mismatch，因此 Section IV-B 最严谨的定位其实不是再次“证明可辨识性”，而是证明：

> sequential implementation retains positive finite-window information in both parameter directions.

建议把 Proposition 1 的标题由：

> Operating-condition-induced finite-window identifiability

改成例如：

> **Finite-window information positivity of the sequential implementation**

或者：

> **Direction-wise finite-window information bound**

然后把真正的 identifiability claim 完全交给 Section IV-A。

这样理论层次更干净：

**Raw pair → identifiability**

**Sequential pair → information positivity / covariance contraction**

这是一个小改动，但会明显提升理论表达的专业程度。

---

## 3.3 建议在 joint Gramian 处补一句 \(R_k\succ0\)

当前写：

\[
\sum_k H_k^TR_k^{-1}H_k
\]

positive definite。

数学上隐含要求：

\[
R_k\succ0.
\]

建议正文直接增加：

> for finite positive-definite raw-observation covariance \(R_k\).

避免严谨型审稿人追问 \(R_k^{-1}\) 的存在条件。

---

# 4. 当前最值得注意的内部一致性问题

## 4.1 1.52 ms / 0.48 ms 与 “one to two external report frames” 存在明显量纲矛盾

论文定义：

\[
f_s=50~\text{kHz},
\qquad
1024\ \text{cycles}=20.48~\text{ms}
\]

即一个 external report interval 为：

\[
20.48~\text{ms}.
\]

但 abrupt recovery 部分写：

- C settling = 1.52 ms；
- ESR settling = 0.48 ms；
- joint = 1.20 ms；

随后又写：

> one to two external report frames

这两组描述不能直接等价。

因为：

\[
1.52~\text{ms}<20.48~\text{ms}
\]

\[
0.48~\text{ms}<20.48~\text{ms}.
\]

### 建议修改

改成：

> TS-SRKE settles internally in 1.52, 0.48, and 1.20 ms, all well within one 20.48-ms external reporting interval.

如果 Fig. 9 的 report-cadence visualization 确实表现为第一或第二个显示点进入误差带，则另外写：

> At the external reporting cadence, the recovery is visible within the first one or two reported samples, depending on step/report alignment.

**不要把 internal settling time 与 report frame 数直接用破折号等同。**

这是本轮我认为最应该立即修掉的文字问题之一。

---

## 4.2 TS-SLTVKE 的 “257 post-step cycles” 与 Table VI 的 64.72 ms 需要核对

正文写道：

> the unsupervised TS-SLTVKE does not satisfy the convergence criterion within 257 post-step cycles for either health step

但 Table VI 又给出：

\[
C\rightarrow0.8C:\quad 64.72~\text{ms}
\]

而 ESR 和 joint 写为：

> no recovery

这里容易产生疑问：

- 257 cycles 在 50 kHz 下只有约 5.14 ms；
- 64.72 ms 到底是 post-step settling delay？
- 还是 simulation absolute timestamp？
- 还是某种 horizon-assigned value？
- 为什么 C step 有 64.72 ms，而文字说两类 health step 均未在 257 cycles 内满足条件？

### 建议

必须把 Table VI 与正文中的时间定义完全统一。

最好 Table caption 或正文明确：

> settling time is measured from the health-change instant

或：

> values are absolute simulation timestamps rather than post-step delays

二者只能选一个明确口径。

如果 64.72 ms 实际不是“恢复时间”，不要放在 settling-time table 中。

这一点容易被审稿人认为结果定义不一致，建议投稿前认真核对代码输出。

---

# 5. 摘要与贡献措辞仍可再收紧

## 5.1 Abstract 中 “confirm feasibility” 仍略强

摘要目前用最坏 p95 误差说明：

> confirm feasibility within a constrained DSP budget

但正文又明确承认：

- measured WCET 未完成；
- firmware compilation/linker placement 未验证；
- bench AFE 未验证；
- hardware switching edge 未验证。

因此 “confirm feasibility” 稍显超出证据。

推荐改成：

> **support device-realistic feasibility within a constrained simulated DSP architecture**

或者简洁一点：

> **support device-realistic implementation feasibility under the modeled DSP constraints**

这样与 Section VIII 的边界一致。

---

## 5.2 Contribution 3 中 “CRLB efficiency analysis” 建议与正文统一

正文已经把 CRLB 很好地降格为：

> conditional information benchmark

但 contribution list 仍使用：

> Cramér–Rao lower bound efficiency analysis

“efficiency” 容易让人理解为 estimator efficiency 接近 CRLB。

建议统一改为：

> **conditional CRLB benchmark and sensitivity analysis**

这样全文口径一致。

---

# 6. O0 baseline 还有一个措辞风险

当前 O0 已经定义清楚，这是明显进步。

但如果 O0 并不是某篇具体文献的直接算法实现，而是作者构造的 generic mixed observation baseline，那么：

> conventional mixed observation set

仍可能被审稿人理解成“已有文献公认基线”。

建议改为：

> **generic mixed-observation baseline (O0)**

并明确：

> O0 is not claimed as a reproduction of any single published method; it represents the generic coupled within-cycle observation that discards topology-synchronous edge reconstruction.

这样更透明，也更难被质疑“挑了一个弱 baseline”。

---

# 7. 传感器需求表述建议再保守一点

正文现在说：

> measurements commonly available in a digitally controlled converter

包括：

- terminal voltage；
- both inductor currents；
- switching state；
- timestamp。

对于很多 Ćuk 产品，两路电感电流并不一定都已经配置传感器。

建议删除 “commonly available” 这一泛化表述。

更稳妥：

> The method uses the terminal voltage, both inductor-current measurements, the switching state, and synchronized timestamps, without requiring a dedicated capacitor-branch current sensor or diagnostic injection.

这样只陈述方法需要什么，不推断所有数字电源都已经具备。

---

# 8. TS-SRKE 闭环验证仍是一个次要缺口

当前 closed-loop supplement 仍使用 TS-D-RLS。

论文已经明确说明：

> supervised operation under feedback remains open

因此逻辑上不存在隐瞒。

但是，只要 TS-SRKE 仍称：

> **Primary Realization**

审稿人仍可能追问：

> Why is the primary realization not tested under feedback?

如果代码已经成熟，建议只增加一个非常小的 closed-loop TS-SRKE test：

1. nominal feedback；
2. load/reference transient；
3. 一个 abrupt ESR change。

核心只验证两件事：

- controller transient 不会错误触发 supervisor；
- health change 在 feedback 下仍可正确 reset/recover。

不需要再做大矩阵。

---

# 9. 硬件实验仍然是决定投稿层级的核心

这一点没有变化，而且现在更加突出。

因为理论与论文结构已经基本完成，所以继续增加大量 simulation 的收益已经很低。

本文核心观测量：

\[
z_R=\hat v_T^- - \hat v_T^+
\]

来自 switching edge。

真实硬件中的：

- dv/dt；
- common-mode transient；
- diode recovery；
- capacitor ESL；
- PCB stray inductance；
- ringing；
- probe delay；
- differential amplifier settling；
- ADC trigger jitter；

都直接作用于这个最关键的 ESR feature。

因此：

### 若投 TPEL / TIE / JESTPE

建议下一步优先做真实样机，而不是继续堆算法。

最低实验集仍然建议：

- 24 V / 50 kHz Ćuk；
- 3 个 C 档位；
- 3–4 个 ESR 档位；
- LCR/impedance analyzer ground truth；
- 至少 2–3 个 load/duty operating points；
- 实际 edge waveform；
- reconstructed edge intercept；
- online \(\hat C,\hat r_C\)。

这一组实验就能让论文证据链发生质变。

---

# 10. 当前稿件重新评分

| 项目 | main(7) | main(8) |
|---|---:|---:|
| 电力电子物理创新 | 8.0 | **8.0** |
| 参数辨识理论 | 8.2 | **8.6** |
| 理论表述严谨性 | 8.0 | **8.6** |
| 创新叙事合理性 | 8.3 | **8.5** |
| 仿真验证完整性 | 8.7 | **8.7** |
| 统计严谨性 | 8.3 | **8.4** |
| 工程实现论证 | 7.5 | **7.6** |
| 硬件验证 | 3.0 | **3.0** |
| IEEE 写作成熟度 | 9.0 | **9.1** |

---

# 11. 当前修改优先级

## P0：投稿前建议立即修正

1. 修正 internal settling time 与 external report frame 的矛盾；
2. 核对 “257 post-step cycles” 与 Table VI 64.72 ms 的定义；
3. 将 Section IV-A identifiability 明确为 conditional on reconstructed regressors；
4. 给 \(R_k\) 增加 positive-definite 条件；
5. 将 CRLB “efficiency analysis” 与正文 benchmark 口径统一；
6. 弱化 abstract 中 “confirm feasibility”。

## P1：高水平期刊强烈建议

7. 真实 Ćuk 硬件实验；
8. 最小 TS-SRKE closed-loop verification。

## P2：有条件再做

9. \(k_R\) 数值 sensitivity 小表；
10. 温度实验；
11. measured WCET；
12. cluster bootstrap。

---

# 12. 最终复审结论

`main(8)` 已经基本解决了前两轮评审中最主要的理论结构问题。

特别是 Section IV 现在形成了比较清晰的逻辑：

> raw observation pair  
> → joint finite-window identifiability  
> → sequential direction-decoupled implementation  
> → finite-window information bounds  
> → covariance contraction

这是目前论文最成熟的部分之一。

当前不建议继续大幅修改算法主线。真正需要做的是两件事：

### 第一
把目前剩余的几个**定义和措辞一致性问题**修干净，尤其是 settling time / report cadence 和 Table VI 的时间定义。

### 第二
如果目标是 TPEL / TIE / JESTPE，转向**真实硬件验证**。

从电力电子论文价值判断，这篇稿件现在最重要、最稳定的贡献依然是：

> **利用 Ćuk 传能电容固有的 \(+i_{L1}\leftrightarrow-i_{L2}\) 换流，把正常 PWM 过程本身转化为无需诊断注入的 C–ESR 参数健康观测激励，并通过 topology-synchronous edge reconstruction 与 in-state charge balance 实现参数方向分离。**

这个核心已经足够，不需要再叠加新的复杂算法来“增加创新点”。
