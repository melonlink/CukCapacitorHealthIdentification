# main(7) 论文复审意见（电力电子专家视角）

## 一、总体判断

相较上一版，当前 `main(7)` 已经完成了一轮非常有效的针对性修改。上一轮评审中最重要的理论与表述问题，大部分已经得到实质性解决，而不是简单增加说明文字。

**当前建议：Major Revision → 接近“有条件可投稿”的状态。**

如果目标是 IEEE TPEL / TIE / JESTPE 一类高水平电力电子期刊，我认为当前版本最大的剩余问题已经从“理论结构不够严谨”转变为：

> **缺少真实 Ćuk 硬件实验。**

也就是说，这一版的论文主线、理论组织和贡献层级已经明显更成熟；下一阶段不建议继续大幅扩展算法，而应把精力集中到硬件验证和少量理论措辞修正上。

---

# 二、上一轮主要意见的落实情况

## 1. 原始联合观测下的可辨识性 —— 已基本解决

上一版最大的理论问题，是先使用 \(\hat r_C\) 对 charge row 做 ESR 补偿，再利用“已解耦”的观测证明 C–ESR 可辨识，存在一定循环论证风险。

当前版本新增了：

> **Joint Identifiability from the Raw Observation Pair**

直接将未经 ESR 补偿的 charge relation 与 edge relation 写成联合矩阵：

\[
\begin{bmatrix}
\Delta v_T\\
z_R
\end{bmatrix}
=
\begin{bmatrix}
q/C_b & \Delta i_C\\
0 & k_R I_\Sigma
\end{bmatrix}
\begin{bmatrix}
\bar\alpha\\
r_C
\end{bmatrix}
+\nu
\]

并由：

\[
\det H_k
=
(q/C_b) k_R I_\Sigma
\]

讨论矩阵满秩，再将后续 sequential decoupled implementation 与原始联合可辨识性区分开。

这是正确的修改方向，也明显增强了论文理论完整性。

### 仍需做一个小修正

当前文字中有一句：

> whenever \(q\neq 0\), \(I_\Sigma\neq0\), and \(k_R\neq0\)—exactly the conditions enforced by the validity gates (17)

这里 **“exactly the conditions enforced by the validity gates” 不够严格**。

原因是：

- \(I_\Sigma\ge I_{\Sigma,\mathrm{gate}}\) 确实由 gate 数值约束；
- 但 charge gate 当前仅为 \(n_C>0\)，论文自己明确说明 **没有 numerical \(q_{\rm gate}\)**；
- \(k_R\neq0\) 也不是 gate 条件，而是 calibration/model assumption。

因此建议改成类似：

> These conditions are satisfied over the evaluated valid-CCM envelope: the edge-current condition is enforced explicitly by (17), whereas nonzero accepted charge follows from the sign-invariant CCM charge windows used in the evaluated envelope, and \(k_R\neq0\) is a fixed calibration assumption.

或者更简洁：

> Under the valid-CCM and calibrated operating envelope considered here, these conditions are satisfied for every complete accepted pair.

这个地方建议投稿前一定修改，否则严格的参数辨识审稿人可能会抓住。

---

## 2. \(k_R\) 标定误差 —— 已明显改善

当前版本新增了 residual calibration error 的解析讨论。

论文现在明确指出：

若估计器使用：

\[
\hat k_R=(1+\delta)k_R
\]

则在无噪声条件下：

\[
\hat r_C
=
\frac{r_C}{1+\delta}
\]

即固定的 \(k_R\) 相对误差会映射为 ESR 的乘性偏差：

\[
-\frac{\delta}{1+\delta}
\]

同时也分析了该误差通过：

\[
(r_C-\hat r_C)\Delta i_C
\]

传播到 capacitance row 的机制，并指出固定比例误差在健康趋势比值中可以部分抵消。

这是很好的修改。

### 建议

如果篇幅允许，仍然建议补一个很小的 numerical sensitivity table：

| \(\delta k_R\) | ESR bias | C bias |
|---:|---:|---:|
| -2% | ... | ... |
| -1% | ... | ... |
| +1% | ... | ... |
| +2% | ... | ... |

这不是必须重新跑庞大实验，只需用已有模型验证解析关系即可。

这样会比仅给解析式更直观。

---

## 3. O0 baseline 不透明 —— 已基本解决

当前版本已经明确写出 O0：

\[
\Delta v_T
=
(q/C_b)\bar\alpha+\Delta i_Cr_C+\nu
\]

并说明：

- 使用 generic within-cycle samples；
- 不进行 edge timestamp reconstruction；
- 保留 acquisition-lag contribution；
- C 与 ESR 共用 coupled regression；
- O0/O1 使用相同 sensors、seeds 和 estimator-family hyperparameters。

这已经能够明显缓解“人为构造弱基线”的质疑。

### 仍可增强

如果版面允许，可以在 supplementary 中增加一个 O0/O1 表：

| 项目 | O0 | O1 |
|---|---|---|
| Observation | mixed row | edge + charge |
| Timestamp alignment | No | Yes |
| ESR direction | coupled | edge-dominant |
| C direction | coupled | charge-dominant |
| Sensors | same | same |

正文目前已经足够，不一定必须增加。

---

## 4. Bootstrap 独立性 —— 已处理得比较成熟

新版本明确承认：

> rows sharing a base plant case are not independent

并将 bootstrap interval 的解释限制为：

> uncertainty over the evaluated grid rather than over an independent population of converters

这个修改非常好。

虽然从统计学上 cluster bootstrap 会更加理想，但当前论文已经不再过度解释结果，因此从审稿角度可以接受。

如果后续数据处理成本不高，再做 cluster bootstrap 会更漂亮；如果不做，也已经不构成严重问题。

---

## 5. 88.93% joint coverage —— 已解决定义歧义

当前版本已经明确说明：

- C 和 ESR 分别使用 marginal 95% interval；
- joint coverage 是二者同时覆盖真值的比例；
- 在近似独立条件下 benchmark 为：

\[
0.95^2=90.25\%
\]

因此 88.93% 的含义现在清楚得多。

这一项基本可以认为解决。

---

## 6. CRLB 用语过强 —— 已解决

上一版“near-CRLB efficiency”的措辞略强。

当前版本已经改成：

> **conditional information benchmark**

并明确指出：

- commissioned configuration 下 noise-driven error 处于 lower bound 的小倍数范围；
- 偏离 calibrated AFE/timing configuration 后，主要体现为 bias，而不是 estimator inefficiency。

这是更严谨的表述，建议保留当前版本。

---

## 7. TS-SRKE 创新层级过高 —— 已明显改善

当前贡献排序已经调整为：

1. topology-synchronous observation；
2. raw-pair joint identifiability；
3. observation–estimator factorial；
4. TS-SRKE supervised-reset extension。

这一顺序比上一版明显合理。

Discussion 中进一步把：

- TS-D-RLS 定位为 lightweight practical estimator；
- TS-SRKE 定位为 uncertainty-aware abrupt-change extension。

这个定位符合实际结果，因为论文数据显示：

- TS-D-RLS 的静态 ESR 精度更好；
- smooth ramp tracking 更好；
- 成本最低；
- TS-SRKE 主要解决 gated Kalman 在 abrupt change 后冻结的问题。

这一项已经基本解决。

---

## 8. 温度影响 —— 表述边界已经解决，但实验仍未解决

当前版本明确写出：

> temperature-induced ESR variation can exceed the identification error reported here

并指出实际部署需要：

- thermally matched comparisons；
- 或映射到参考温度 \(r_C(T_{\rm ref})\)。

这使论文的结论边界更加诚实。

但是，需要区分：

### 写作问题
已经解决。

### 科学验证问题
仍未解决。

如果继续使用：

> capacitor condition monitoring

作为论文主题，这一点仍可能被审稿人要求增加实验。

如果没有温度实验，当前版本至少已经通过 limitations 避免了过度声称，因此不是致命问题。

---

# 三、当前版本仍然存在的主要问题

## 1. 最关键问题仍然是真实硬件验证

这一点没有发生根本变化。

当前 F28379D 部分仍然是 device-realistic simulation，论文也明确承认：

- bench AFE verification 尚未完成；
- target compilation/WCET 未完成；
- edge ringing 未实际验证；
- common-mode rejection 未实测；
- production calibration 未验证。

对于本文尤其重要，因为 ESR 信息恰恰来自：

> **switching edge**

而真实硬件开关边沿会受到：

- MOSFET dv/dt；
- diode reverse recovery；
- capacitor ESL；
- PCB stray inductance；
- ringing；
- ADC sample-and-hold；
- differential amplifier settling；
- common-mode transient；
- trigger jitter；
- probing parasitic；

影响。

这些因素很难通过纯 Simscape/device-realistic model 完全证明。

### 我的判断

如果投：

- IEEE TPEL；
- IEEE TIE；
- IEEE JESTPE；

**真实硬件实验仍然是最需要补的一项。**

而且现在论文理论和叙事已经比较完整，继续大量增加仿真边际收益很低。

---

## 2. Closed-loop 中仍没有验证 TS-SRKE

当前论文已经诚实地将：

- closed-loop；
- light-load；

实验限定在 TS-D-RLS，并明确把：

> supervised estimator under feedback

列为 limitation。

这样的写法逻辑上没有错误。

但如果最终仍将 TS-SRKE 称为：

> Primary Realization

审稿人仍可能问：

> 为什么 primary estimator 没有在闭环主场景下验证？

### 建议

如果已有代码，建议增加一个最小闭环补充：

- nominal closed-loop；
- load step；
- 一个 abrupt ESR 或 C step；

只需证明 supervisor 在 feedback 下不会因控制动作误触发，并能在健康突变后正常 reset。

如果实现工作量较大，也可以保留当前写法，但投稿风险略高。

---

## 3. “Condition monitoring”与“parameter estimation”的边界仍需控制

论文现在已经非常明确地说：

- abrupt step 不是 aging；
- ramp 不是 run-to-failure；
- ESR 是 effective condition indicator；
- temperature correction 尚未建立；
- hardware/accelerated-aging still open。

因此从文字上已经比较严谨。

但严格来说，当前主要证据仍然证明：

> **C–ESR online parameter estimation / tracking**

而不是完整证明：

> **real capacitor aging health diagnosis**

所以建议摘要、结论和 title 全文避免出现：

- lifetime prediction；
- aging diagnosis；
- remaining useful life；
- experimentally validated health diagnosis；

一类更强措辞。

当前标题的 “Monitoring” 是可以接受的，建议不要进一步强化为 diagnosis/prognostics。

---

# 四、一个新增的理论细节建议

## Joint Gramian 的表述建议进一步严谨

当前写法：

> The joint Gramian \(\sum_k H_k^T R_k^{-1}H_k\) is therefore positive definite for any window containing at least one complete accepted pair.

在 \(H_k\) 本身满列秩且 \(R_k\succ0\) 的情况下，这个结论当然成立。

但这里要确保所谓：

> complete accepted pair

在实现中确实意味着同一可定义窗口内具有：

- 非零 charge information；
- accepted edge information；

而不是来自两个彼此不对应的 asynchronous records。

后文 sequential information bound 已经允许 \(m_C\) 和 \(m_R\) 分开计数，所以建议在 Section IV-A 中明确：

> The stacked raw pair is an identifiability construction; the online implementation need not process the two rows simultaneously.

这样可以避免读者误以为实际 DSP 必须在每一周期形成严格同步的 2×2 measurement update。

---

# 五、当前稿件质量重新评分

| 项目 | 上一版 | 当前版 |
|---|---:|---:|
| 电力电子物理创新 | 8.0 | **8.0** |
| 参数辨识理论 | 7.0 | **8.2** |
| 创新叙事合理性 | 6.5 | **8.3** |
| 仿真验证 | 8.5 | **8.7** |
| 统计严谨性 | 7.0 | **8.3** |
| 工程可实现性论证 | 7.0 | **7.5** |
| 硬件验证 | 3.0 | **3.0** |
| 写作成熟度 | 8.5 | **9.0** |

---

# 六、投稿判断

## 如果现在直接投 TPEL

我认为：

**可以尝试，但仍属于风险较高投稿。**

风险已经不是理论逻辑，而主要是：

> Reviewer: “The entire method relies on switching-edge voltage reconstruction. Where is the experimental validation?”

这个问题很难仅用更多仿真回答。

---

## 如果增加最小硬件验证后投 TPEL/JESTPE

如果增加：

1. 一套 Ćuk 实验样机；
2. 3 个 C 档位；
3. 3–4 个 ESR 档位；
4. LCR/impedance analyzer ground truth；
5. edge waveform 与 reconstructed ESR step；
6. 2–3 个负载/占空比；

我认为论文整体竞争力会显著提高。

此时论文的核心链条将完整：

> topology mechanism  
> → joint identifiability  
> → decoupled implementation  
> → blind simulation  
> → DSP feasibility  
> → real switching-hardware validation

这会非常像一篇完整的 TPEL/JESTPE 风格论文。

---

# 七、当前建议的修改优先级

## P0：建议现在就改

1. 修正 Section IV-A 中 “exactly the conditions enforced by the validity gates” 的表述；
2. 明确 raw 2×2 pair 是 identifiability construction，不要求 DSP 同时做矩阵更新。

## P1：投稿高水平期刊前强烈建议

3. 补真实 Ćuk 样机；
4. 最好补一组 TS-SRKE closed-loop verification。

## P2：有条件再做

5. \(k_R\) ±1%/±2% 数值敏感度小表；
6. 温度实验；
7. cluster bootstrap；
8. measured WCET。

---

# 八、最终复审结论

这一版本已经比上一版明显成熟。

特别是以下问题已经实质性解决：

- 原始联合观测可辨识性；
- \(k_R\) calibration bias 的理论解释；
- O0 baseline 明确定义；
- bootstrap 解释边界；
- 95% marginal / joint coverage 定义；
- CRLB 措辞；
- TS-D-RLS 与 TS-SRKE 的定位；
- temperature confounding 的 limitations。

因此，我不再认为当前论文的主要问题是“理论结构不够扎实”。

**现在最重要的工作已经非常清楚：停止继续堆叠仿真和算法，转向硬件。**

如果暂时不做硬件，这一版已经可以作为一篇较强的 simulation-based methodology manuscript 尝试投稿；但如果目标是 IEEE TPEL / TIE / JESTPE，我仍建议优先完成真实 Ćuk 样机的 C–ESR 可控实验。

从电力电子专家视角看，这篇论文现在真正值得保住的核心已经很稳定：

> **利用 Ćuk 传能电容固有双向换流，将正常 PWM 开关过程本身转化为无需诊断注入的 C–ESR 健康观测激励。**

这应继续作为全文第一主线。
