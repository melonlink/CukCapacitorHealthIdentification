# Codex 仿真验证任务书：Ćuk 能量传递电容 C–ESR 在线健康辨识

> **任务性质**：理论独立验证 + 开关级仿真 + 参数辨识算法验证  
> **执行主体**：Codex（调用本机已安装的 MCP / MATLAB / Simulink / Simscape Electrical 等可用工具）  
> **验证对象**：Ćuk 变换器能量传递电容 \(C_1\) 的电容量 \(C_1\) 与 ESR \(r_C\) 联合在线辨识方案  
> **主算法**：Topology-Synchronous LTV Kalman Filter（TS-LTVKF）  
> **基线算法**：Topology-RLS / Weighted RLS  
> **理论母稿**：`Cuk_energy_transfer_capacitor_health_theory_v0.2.md`  
> **最终目的**：判断以下论文主张是否成立，并生成可供 ChatGPT 二次评审的完整结果包。
>
> 1. Ćuk 拓扑可由 \(i_{L1},i_{L2},u\) 重构能量传递电容电流；
> 2. PWM 换相边沿可形成 ESR 主导特征；
> 3. 子区间电荷增量可形成电容量主导特征；
> 4. \(C_1\) 与 ESR 在 CCM 条件下具有可辨识性；
> 5. 利用 \(\alpha=1/C_1\) 可构造线性时变增广模型，无需 EKF；
> 6. TS-LTVKF 可在多工况、测量噪声和有限非理想因素下稳定估计 \(C_1\) 与 ESR；
> 7. 该方案是否具有足够稳定性与工程可实现性，能够支撑一篇论文。

---

# 0. Codex 执行原则

Codex 必须遵守以下规则。

## 0.1 必须真实执行，不得只写分析

必须：

- 调用本机可用 MCP；
- 实际创建 MATLAB / Simulink / Python 仿真文件；
- 实际运行；
- 实际生成数据、图、日志和结果报告；
- 不能只给“理论上应该成立”的结论。

## 0.2 不允许为了得到预期结果而修改目标方程

如果理论方程与独立电路模型结果不一致：

- 记录不一致；
- 定位符号、采样、ESR 定义、开关状态、极性或模型假设问题；
- 给出修正建议；
- **不得偷偷修改仿真输出或选择性删除失败工况。**

## 0.3 优先使用本机 MATLAB/Simulink

首先检查：

1. MATLAB；
2. Simulink；
3. Simscape Electrical；
4. Control System Toolbox / Signal Processing Toolbox 等可用工具。

若 Simscape Electrical 不可用：

- 仍必须完成“分段开关状态方程”的 MATLAB/Simulink 验证；
- 不得因此终止整个任务。

若 MATLAB MCP 不可用，但本地 Python 可执行：

- 可以用 NumPy / SciPy 完成独立验证；
- 但必须明确记录环境限制。

## 0.4 两套模型必须尽可能独立

为了避免“用同一组公式验证同一组公式”造成循环论证，本任务分为：

### Model A：理论分段状态方程模型

直接根据本任务书给出的两状态微分方程实现。

### Model B：电路级模型

若 Simscape Electrical / PLECS 可用，使用：

- MOSFET / ideal switch；
- diode；
- \(L_1\)；
- \(L_2\)；
- \(C_1+r_C\)；
- \(C_o\)；
- \(R\)；

按真实拓扑连接。

**Model B 不允许直接调用 Model A 的状态方程作为内部实现。**

---

# 1. 工作目录与交付目录

在当前 Codex 工作目录下创建：

```text
cuk_cap_health_verification/
├─ README.md
├─ THEORY_CHECK.md
├─ environment/
│  └─ environment_report.md
├─ model/
│  ├─ switched_equation_model.*
│  ├─ circuit_model.*              # 如果可用
│  └─ model_parameters.*
├─ algorithms/
│  ├─ topology_rls.*
│  ├─ ts_ltvkf.*
│  └─ helper_functions.*
├─ scripts/
│  ├─ run_ideal_validation.*
│  ├─ run_parameter_sweep.*
│  ├─ run_noise_tests.*
│  ├─ run_dynamic_tests.*
│  ├─ run_nonideal_tests.*
│  └─ run_all.*
├─ results/
│  ├─ ideal/
│  ├─ sweep/
│  ├─ noise/
│  ├─ dynamic/
│  ├─ nonideal/
│  ├─ tables/
│  └─ figures/
├─ logs/
├─ RESULT_SUMMARY.md
├─ RESULT_FOR_CHATGPT.md
└─ result_metrics.csv
```

文件扩展名根据实际环境确定，例如 `.m`、`.mlx`、`.slx`、`.py`。

---

# 2. 环境自检

执行前生成：

`environment/environment_report.md`

内容必须包括：

- OS；
- MATLAB 版本；
- Simulink 是否存在；
- Simscape Electrical 是否存在；
- MATLAB MCP 是否正常；
- Python 版本（如使用）；
- 可用相关工具箱；
- 最终实际采用的仿真路径；
- 未能使用的组件及原因。

不得因为某个非必须工具缺失而停止整个验证。

---

# 3. 第一阶段：独立核对理论方程

在开始仿真前，Codex 必须对以下理论关系进行一次独立符号/电路逻辑检查。

定义：

- \(u=1\)：主开关导通；
- \(u=0\)：主开关关断，二极管导通；
- \(i_1=i_{L1}>0\)；
- \(i_2=i_{L2}>0\)；
- \(v_C\)：理想电容内部电压；
- \(v_T\)：\(C_1+ESR\) 组件外部端口电压；
- \(v_o>0\)：反相输出的幅值。

目标关系：

\[
\boxed{
i_C=(1-u)i_1-u i_2
}
\tag{T1}
\]

\[
\boxed{
v_T=v_C+r_Ci_C
}
\tag{T2}
\]

\[
\boxed{
\dot v_C=\frac{i_C}{C_1}
}
\tag{T3}
\]

两个状态：

### \(u=1\)

\[
\dot i_1=\frac{V_{in}}{L_1}
\tag{T4}
\]

\[
\dot i_2=
\frac{v_C-r_Ci_2-v_o}{L_2}
\tag{T5}
\]

\[
\dot v_C=-\frac{i_2}{C_1}
\tag{T6}
\]

\[
\dot v_o=
\frac{i_2}{C_o}-\frac{v_o}{RC_o}
\tag{T7}
\]

### \(u=0\)

\[
\dot i_1=
\frac{V_{in}-v_C-r_Ci_1}{L_1}
\tag{T8}
\]

\[
\dot i_2=-\frac{v_o}{L_2}
\tag{T9}
\]

\[
\dot v_C=\frac{i_1}{C_1}
\tag{T10}
\]

\[
\dot v_o=
\frac{i_2}{C_o}-\frac{v_o}{RC_o}
\tag{T11}
\]

如果 Codex 认为其中任一符号或拓扑定义有问题：

1. 不要直接继续；
2. 在 `THEORY_CHECK.md` 中明确指出；
3. 给出自己的独立推导；
4. 同时保留“原理论模型”和“修正模型”各运行一遍；
5. 比较哪个与独立电路级 Model B 一致。

---

# 4. 基准仿真参数

如果用户当前工程中没有既有 Ćuk 参数，则使用以下默认值作为第一套基准。

| 参数 | 默认值 |
|---|---:|
| \(V_{in}\) | 24 V |
| \(D\) | 0.40 |
| \(f_s\) | 50 kHz |
| \(T_s\) | 20 µs |
| \(L_1\) | 500 µH |
| \(L_2\) | 500 µH |
| \(C_1\) | 100 µF |
| \(r_C\) | 50 mΩ |
| \(C_o\) | 470 µF |
| \(R\) | 10 Ω |

理想稳态理论参考：

\[
|V_o|
=
\frac{D}{1-D}V_{in}
=
16\text{ V}
\]

\[
V_C
=
\frac{V_{in}}{1-D}
=
40\text{ V}
\]

\[
I_2\approx\frac{V_o}{R}=1.6\text{ A}
\]

\[
I_1
=
\frac{D}{1-D}I_2
\approx1.067\text{ A}
\]

该参数仅用于建立第一个可重复基准。

如果 Codex 判断此参数导致某些仿真模型明显不合理，可以调整，但必须：

- 保持 CCM；
- 给出调整原因；
- 在报告中记录新参数；
- 仍保留默认参数测试结果，除非默认参数导致仿真本身无法运行。

---

# 5. 数值仿真要求

## 5.1 开关级仿真

不得只使用平均模型。

必须使用：

- 实际 PWM 二值 \(u(t)\)；
- 两个拓扑状态交替；
- 直接积分状态方程。

推荐：

\[
\Delta t_{\mathrm{sim}}
\le
\frac{T_s}{100}
\]

最好：

\[
\Delta t_{\mathrm{sim}}
=
\frac{T_s}{200}
\]

如采用变步长求解器，必须保证换相点被准确处理。

## 5.2 运行至稳态

每个静态工况必须先运行至稳态，再开始参数估计。

稳态判定建议同时满足：

\[
\frac{|V_o(k)-V_o(k-N)|}{V_{o,\mathrm{nom}}}<10^{-3}
\]

且：

\[
\frac{|I_1(k)-I_1(k-N)|}{I_{1,\mathrm{nom}}}<10^{-3}
\]

至少维持若干周期。

不得使用尚未稳定的启动过程计算 Eq. (T12)–(T17) 的稳态误差。

---

# 6. 核心理论验证 1：电容电流重构

从仿真真实支路获取：

\[
i_{C,\mathrm{true}}
\]

再通过：

\[
\boxed{
i_{C,\mathrm{rec}}
=
(1-u)i_1-ui_2
}
\tag{T12}
\]

重构。

计算：

- RMSE；
- 最大绝对误差；
- NRMSE；
- 在两个开关状态下分别统计。

理想模型目标：

\[
\mathrm{NRMSE}<10^{-3}
\]

若 Model B 存在器件寄生，则记录误差，但应解释来源。

输出图：

`fig_01_cap_current_reconstruction.*`

---

# 7. 核心理论验证 2：ESR 换相边沿关系

在理想无 ESL 模型中验证：

当：

\[
u:0\rightarrow1
\]

时：

\[
\boxed{
v_T^- - v_T^+
=
r_C(i_1^-+i_2^+)
}
\tag{T13}
\]

定义：

\[
r_{edge}
=
\frac{
v_T^- - v_T^+
}{
i_1^-+i_2^+
}
\tag{T14}
\]

要求至少提取：

\[
N\ge100
\]

个稳定 PWM 周期边沿。

统计：

- mean；
- std；
- bias；
- MAPE。

理想 Model A 目标：

\[
\mathrm{MAPE}_{ESR,edge}<1\%
\]

并绘图：

1. \(\Delta v_{edge}\) vs \(r_C(i_1+i_2)\)；
2. 拟合直线；
3. \(R^2\)。

目标：

\[
R^2>0.995
\]

输出：

- `fig_02_edge_relation.*`
- `table_edge_esr.csv`

---

# 8. 核心理论验证 3：子区间电容量关系

在 \(u=0\) 区间：

\[
v_C=v_T-r_Ci_1
\]

验证：

\[
\boxed{
C_1
=
\frac{
\int i_1dt
}{
[v_T(t_b)-r_Ci_1(t_b)]
-
[v_T(t_a)-r_Ci_1(t_a)]
}
}
\tag{T15}
\]

在 \(u=1\) 区间：

\[
v_C=v_T+r_Ci_2
\]

验证：

\[
\boxed{
C_1
=
\frac{
\int i_2dt
}{
-
\{
[v_T(t_b)+r_Ci_2(t_b)]
-
[v_T(t_a)+r_Ci_2(t_a)]
\}
}
}
\tag{T16}
\]

要求：

- 分别得到 \(\hat C_{OFF}\)；
- \(\hat C_{ON}\)；
- 统计至少 100 个周期。

理想 Model A 目标：

\[
\mathrm{MAPE}_{C,OFF}<1\%
\]

\[
\mathrm{MAPE}_{C,ON}<1\%
\]

输出：

- `fig_03_capacitance_charge_relation.*`
- `table_capacitance_subinterval.csv`

---

# 9. 核心理论验证 4：统一积分回归

验证：

\[
\boxed{
\Delta v_T
=
q\alpha
+
r_C\Delta i_C
}
\tag{T17}
\]

其中：

\[
\alpha=\frac{1}{C_1}
\]

\[
q=\int i_Cdt
\]

构造：

\[
\Phi=
\begin{bmatrix}
q_1&\Delta i_{C,1}\\
q_2&\Delta i_{C,2}\\
\vdots&\vdots
\end{bmatrix}
\]

计算：

\[
\mathrm{rank}(\Phi)
\]

\[
\lambda_{\min}(\Phi^T\Phi)
\]

\[
\kappa(\Phi^T\Phi)
\]

必须验证：

\[
\boxed{
\mathrm{rank}(\Phi)=2
}
\tag{T18}
\]

并生成：

- 不同负载；
- 不同 D；
- 不同 \(C_1\)；
- 不同 ESR；

下的信息矩阵指标。

输出：

`table_identifiability.csv`

---

# 10. 核心理论验证 5：灵敏度正交性

构造二维参数矩阵：

\[
C/C_0=
[1.00,0.95,0.90,0.85,0.80]
\]

\[
r/r_0=
[1.00,1.25,1.50,1.75,2.00]
\]

共：

\[
25
\]

个组合。

对每个组合提取：

### ESR 特征

\[
F_R=
\frac{\Delta v_{edge}}{i_1+i_2}
\]

### C 特征

\[
F_C=
\frac{Q}{\Delta v_C}
\]

生成两个 5×5 heatmap。

理想预期：

- \(F_R\) 随 ESR 改变，对 C 变化不敏感；
- \(F_C\) 随 C 改变，对 ESR 变化不敏感。

必须量化交叉敏感度：

\[
S_{R,C}
=
\left|
\frac{\partial F_R}{\partial C}
\right|
\]

\[
S_{C,R}
=
\left|
\frac{\partial F_C}{\partial r_C}
\right|
\]

同时计算主敏感度。

输出：

- `fig_04_esr_feature_heatmap.*`
- `fig_05_c_feature_heatmap.*`
- `table_cross_sensitivity.csv`

---

# 11. 实现 Topology-RLS 基线

参数：

\[
\theta=
\begin{bmatrix}
\alpha\\
r_C
\end{bmatrix}
\]

模型：

\[
z_k=\phi_k^T\theta+\varepsilon_k
\]

其中：

\[
z_k=\Delta v_T
\]

\[
\phi_k=
\begin{bmatrix}
q_k\\
\Delta i_{C,k}
\end{bmatrix}
\]

实现：

- 普通 RLS；
- forgetting factor RLS；
- projected RLS。

建议初始：

\[
\lambda=0.995
\]

但允许通过小范围验证调整。

物理投影：

\[
C_{\min}<\hat C<C_{\max}
\]

\[
r_{\min}<\hat r_C<r_{\max}
\]

输出：

- \(\hat C(t)\)；
- \(\hat r_C(t)\)；
- 收敛时间；
- 稳态 MAPE。

---

# 12. 实现 TS-LTVKF 主算法

定义：

\[
\alpha=\frac{1}{C_1}
\]

状态：

\[
\boxed{
x_k=
\begin{bmatrix}
v_{C,k}\\
\alpha_k\\
r_{C,k}
\end{bmatrix}
}
\tag{K1}
\]

电荷增量：

\[
q_k=
\int_{t_k}^{t_{k+1}}i_C(t)dt
\]

状态方程：

\[
\boxed{
x_{k+1}
=
F_kx_k+w_k
}
\tag{K2}
\]

\[
\boxed{
F_k=
\begin{bmatrix}
1&q_k&0\\
0&1&0\\
0&0&1
\end{bmatrix}
}
\tag{K3}
\]

测量：

\[
y_k=v_{T,k}
\]

观测矩阵：

\[
\boxed{
H_k=
\begin{bmatrix}
1&0&i_{C,k}
\end{bmatrix}
}
\tag{K4}
\]

观测方程：

\[
\boxed{
y_k=H_kx_k+\nu_k
}
\tag{K5}
\]

必须实现：

1. prediction；
2. innovation；
3. Kalman gain；
4. Joseph covariance update；
5. parameter projection；
6. update gating；
7. parameter confidence。

输出：

\[
\hat v_C
\]

\[
\hat C_1=\frac{1}{\hat\alpha}
\]

\[
\hat r_C
\]

\[
\sigma_C
\]

\[
\sigma_r
\]

---

# 13. TS-LTVKF 可观测性验证

构造有限窗口可观测矩阵：

\[
\mathcal O_{k,N}
=
\begin{bmatrix}
H_k\\
H_{k+1}\Phi(k+1,k)\\
\cdots
\end{bmatrix}
\]

要求至少计算：

\[
N=3,5,10
\]

的：

- rank；
- minimum singular value；
- condition number。

必须检查：

\[
\boxed{
\mathrm{rank}(\mathcal O_{k,N})=3
}
\tag{K6}
\]

在不同：

- D；
- load；
- switching phase；
- CCM margin；

下的变化。

重点验证：

> 轻载时 ESR 可观测性是否下降。

输出：

`table_ltv_observability.csv`

和：

`fig_06_observability_vs_load.*`

---

# 14. LTV-KF 初始化鲁棒性

真实参数：

\[
C=C_0
\]

\[
r=r_0
\]

至少测试以下初值：

### Set A

\[
\hat C_0=0.7C_0
\]

\[
\hat r_0=0.5r_0
\]

### Set B

\[
\hat C_0=1.3C_0
\]

\[
\hat r_0=1.5r_0
\]

### Set C

随机初始化 20 次：

\[
\hat C_0\in[0.6,1.4]C_0
\]

\[
\hat r_0\in[0.5,2.0]r_0
\]

评价：

- 是否收敛；
- 收敛时间；
- 最终偏差；
- 是否出现非物理解。

输出：

`table_initialization_robustness.csv`

---

# 15. 多工况参数扫描

至少包含：

## 15.1 输入电压

\[
V_{in}/V_{nom}
=
[0.8,1.0,1.2]
\]

## 15.2 占空比

建议：

\[
D=[0.25,0.35,0.45,0.55,0.65]
\]

若某些点不能保持 CCM，记录并剔除，而不是强行运行。

## 15.3 负载

使用功率或电阻调整，使输出负载覆盖约：

\[
P/P_{nom}
=
[0.1,0.25,0.5,0.75,1.0]
\]

在每个工况下统计：

- \(C\) MAPE；
- ESR MAPE；
- LTVKF convergence time；
- observability metric；
- RLS vs LTVKF。

输出：

`result_operating_sweep.csv`

---

# 16. 噪声鲁棒性测试

向测量量加入可控噪声。

至少：

\[
SNR=
[20,30,40,50]\text{ dB}
\]

分别对：

- \(v_T\)；
- \(i_1\)；
- \(i_2\)；

加入噪声。

必须使用固定随机种子集，例如：

\[
seed=1\ldots20
\]

每个 SNR 统计 Monte Carlo：

- median MAPE；
- mean MAPE；
- 95th percentile；
- failure rate。

重点比较：

- RLS；
- LTVKF。

输出：

- `table_noise_monte_carlo.csv`
- `fig_07_error_vs_snr.*`

建议鲁棒性目标，不是预设结论：

在：

\[
SNR\ge30\text{ dB}
\]

时希望达到：

\[
\mathrm{MAPE}_C<3\%
\]

\[
\mathrm{MAPE}_{ESR}<5\%
\]

若达不到，必须如实报告。

---

# 17. ADC 量化与采样率测试

测试 ADC：

- 12 bit；
- 14 bit；
- 16 bit。

测试有效参数采样点数：

\[
N_s=
[4,8,16,32]
\]

points / switching period。

评估：

- C error；
- ESR error；
- convergence；
- edge feature stability。

输出：

`table_adc_sampling.csv`

目的：

> 判断该算法是否需要过高采样率，是否具有嵌入式实现价值。

---

# 18. PWM 同步误差测试

人为引入电压、电流采样相对于真实 PWM 边沿的时序偏差：

\[
\Delta t=
[
0,
0.01T_s,
0.02T_s,
0.05T_s
]
\]

如有必要进一步细化。

评估：

- edge ESR error；
- RLS error；
- LTVKF error。

输出：

`fig_08_sync_error.*`

以及：

`table_sync_error.csv`

重点结论：

> ESR 估计对 PWM 同步误差有多敏感？

---

# 19. 动态参数变化测试

为了模拟退化参数切换，而不是只做稳态估计：

## 19.1 C 阶跃

在稳定运行后：

\[
C:
C_0\rightarrow0.9C_0
\]

以及：

\[
C:
C_0\rightarrow0.8C_0
\]

保持 ESR 不变。

## 19.2 ESR 阶跃

\[
r:
r_0\rightarrow1.5r_0
\]

以及：

\[
r:
r_0\rightarrow2r_0
\]

保持 C 不变。

## 19.3 联合变化

\[
C:
C_0\rightarrow0.85C_0
\]

同时：

\[
r:
r_0\rightarrow1.75r_0
\]

比较：

- RLS；
- LTVKF。

统计：

- 10–90% tracking time；
- overshoot；
- steady-state bias；
- false coupling。

“false coupling” 定义：

例如仅 ESR 变化时，C 估计不应出现长期显著漂移。

输出：

- `fig_09_dynamic_C_step.*`
- `fig_10_dynamic_ESR_step.*`
- `fig_11_dynamic_joint_step.*`
- `table_dynamic_tracking.csv`

---

# 20. 负载瞬变解耦测试

保持：

\[
C_1,r_C
\]

完全不变。

施加负载阶跃：

\[
P:
25\%\rightarrow75\%
\]

\[
P:
100\%\rightarrow50\%
\]

观察算法是否错误判定健康参数变化。

评价：

\[
\Delta \hat C_{\mathrm{false}}
\]

\[
\Delta \hat r_{\mathrm{false}}
\]

建议目标：

稳定后：

\[
|\Delta \hat C|<2\%
\]

\[
|\Delta \hat r|<5\%
\]

如果瞬态短时间超出但能快速回归，应单独记录 transient peak 和 settled bias。

---

# 21. 输入电压瞬变解耦测试

保持健康参数不变：

\[
V_{in}:0.8pu\rightarrow1.2pu
\]

以及反向变化。

验证：

- C estimate；
- ESR estimate；

是否能回归真实值。

---

# 22. 非理想模型测试

完成理想验证后逐项加入以下非理想因素。

不要一次全部加入，否则无法定位误差来源。

---

## 22.1 电感绕组电阻

加入：

\[
r_{L1},r_{L2}
\]

建议起始：

\[
r_{L1}=r_{L2}=50m\Omega
\]

若已有实际参数可使用真实值。

---

## 22.2 MOSFET 导通电阻

例如：

\[
R_{DS(on)}=20\sim50m\Omega
\]

---

## 22.3 二极管压降 / 导通电阻

使用合理模型。

---

## 22.4 C1 ESL

扩展：

\[
v_T=
v_C+r_Ci_C+L_{ESL}\frac{di_C}{dt}
\]

建议：

\[
L_{ESL}
=
[0,5,10,20]\text{ nH}
\]

如果 Model A 难以稳定表示理想电流跳变和 ESL，优先使用电路级 Model B。

---

# 23. 边沿振铃与边沿外推

如果加入 ESL / 寄生后，开关边沿存在尖峰，不允许直接使用最大峰值作为 ESR 特征。

实现：

### pre-edge safe window

在边沿前选择稳定点；

### post-edge safe window

跳过振铃后选择稳定点；

分别线性拟合，再外推至切换时刻：

\[
\tilde v_T^-
\]

\[
\tilde v_T^+
\]

计算：

\[
\boxed{
\hat r_C
=
\frac{
\tilde v_T^-
-
\tilde v_T^+
}{
\tilde i_1^-+\tilde i_2^+
}
}
\tag{N1}
\]

比较：

1. naive peak method；
2. safe-window method；
3. extrapolation method。

输出：

`fig_12_edge_extrapolation.*`

和：

`table_edge_method_comparison.csv`

---

# 24. 温度因素的第一阶段处理

本轮不要求建立完整热模型。

但必须在报告中明确区分：

\[
r_C
\]

作为“当前仿真温度下的等效 ESR”，而不是直接等同于 aging-only ESR。

如果本机模型可方便加入温度依赖，可额外测试：

\[
r_C(T)
\]

但不是本任务硬性要求。

---

# 25. Model A 与 Model B 的交叉验证

如果 Simscape Electrical / PLECS Model B 成功建立，必须比较：

- \(i_1\)；
- \(i_2\)；
- \(v_T\)；
- \(v_C\)（若可读取）；
- \(v_o\)；
- edge relation；
- C estimate；
- ESR estimate。

允许存在：

- 开关器件非理想；
- 数值求解；
- 寄生；

造成的小差异。

但如果核心极性或公式方向完全相反，应判定理论模型存在问题。

输出：

`table_model_cross_validation.csv`

---

# 26. 算法比较指标

RLS 和 TS-LTVKF 必须使用同一测试集。

至少比较：

| 指标 | RLS | TS-LTVKF |
|---|---:|---:|
| \(C\) MAPE | | |
| ESR MAPE | | |
| convergence time | | |
| noise 30 dB \(C\) error | | |
| noise 30 dB ESR error | | |
| load transient false \(C\) drift | | |
| load transient false ESR drift | | |
| parameter step tracking | | |
| computation time/update | | |
| memory estimate | | |
| confidence interval | No / optional | Yes |

不能只挑 LTVKF 有优势的指标。

---

# 27. 初始验收标准

以下标准用于判断方案是否值得继续，并不是为了强迫仿真得到这些值。

## Gate A：理论一致性

必须满足：

- T12 电流重构正确；
- T13 ESR 边沿关系正确；
- T15/T16 子区间 C 关系正确；
- T17 积分回归正确。

理想模型中若任一基础关系系统性失败：

\[
\boxed{\text{核心理论暂不通过}}
\]

必须停止往“论文有效”方向下结论，并定位原因。

---

## Gate B：结构可辨识

至少在中等负载、典型 D、CCM 下：

\[
\mathrm{rank}(\Phi)=2
\]

且：

\[
\mathrm{rank}(\mathcal O)=3
\]

若不满足：

\[
\boxed{\text{LTV-KF 参数联合估计理论不成立}}
\]

---

## Gate C：理想算法精度

建议：

\[
\mathrm{MAPE}_C<2\%
\]

\[
\mathrm{MAPE}_{ESR}<3\%
\]

如果在理想无噪声模型中仍明显达不到，必须判定算法或采样设计存在问题。

---

## Gate D：工程噪声鲁棒性

在：

\[
SNR\ge30dB
\]

时，建议达到：

\[
\mathrm{MAPE}_C<3\%
\]

\[
\mathrm{MAPE}_{ESR}<5\%
\]

若略超出，可以继续研究；若误差明显失控，则需要修改采样或观测方案。

---

## Gate E：工况解耦

健康参数不变的负载/输入电压变化后，稳定估计不应持续漂移。

建议：

\[
|\Delta C|<2\%
\]

\[
|\Delta ESR|<5\%
\]

---

# 28. 结果判定等级

Codex 最终不得只输出“成功/失败”。

必须给出以下五级之一：

### A — Strongly Supported

- 理论方程全部通过；
- 可辨识条件成立；
- LTVKF 稳定；
- 多工况和噪声下表现良好；
- 有明确硬件实现价值。

### B — Supported with Engineering Constraints

- 理论成立；
- 算法有效；
- 但对采样率、PWM 同步、负载、ESL 等有明显约束。

### C — Partially Supported

- 核心部分成立；
- 某一参数，例如 ESR，在实际非理想下较难稳定估计；
- 需要改变测量或估计算法。

### D — Weakly Supported

- 理想模型可行；
- 加入合理非理想因素后明显失效；
- 暂不足以支撑论文核心结论。

### F — Rejected

- 基础方程、极性、可辨识性或算法本身存在根本问题。

---

# 29. 强制输出图

至少生成下列图。

1. `fig_01_cap_current_reconstruction`
2. `fig_02_edge_relation`
3. `fig_03_capacitance_charge_relation`
4. `fig_04_esr_feature_heatmap`
5. `fig_05_c_feature_heatmap`
6. `fig_06_observability_vs_load`
7. `fig_07_error_vs_snr`
8. `fig_08_sync_error`
9. `fig_09_dynamic_C_step`
10. `fig_10_dynamic_ESR_step`
11. `fig_11_dynamic_joint_step`
12. `fig_12_edge_extrapolation`
13. `fig_13_rls_vs_ltvkf_C`
14. `fig_14_rls_vs_ltvkf_ESR`
15. `fig_15_load_transient_decoupling`

所有图：

- 坐标轴；
- 单位；
- legend；
- title；
- 参数说明；

必须完整。

---

# 30. 强制输出表

至少：

1. `table_edge_esr.csv`
2. `table_capacitance_subinterval.csv`
3. `table_identifiability.csv`
4. `table_cross_sensitivity.csv`
5. `table_ltv_observability.csv`
6. `table_initialization_robustness.csv`
7. `result_operating_sweep.csv`
8. `table_noise_monte_carlo.csv`
9. `table_adc_sampling.csv`
10. `table_sync_error.csv`
11. `table_dynamic_tracking.csv`
12. `table_edge_method_comparison.csv`
13. `table_model_cross_validation.csv`
14. `result_metrics.csv`

---

# 31. result_metrics.csv 的固定字段

必须至少包含：

```text
test_id
model_type
Vin
D
load_percent
fs_Hz
C_true_F
ESR_true_Ohm
noise_SNR_dB
adc_bits
samples_per_cycle
sync_error_s
ESL_H
method
C_est_F
C_MAPE_percent
ESR_est_Ohm
ESR_MAPE_percent
convergence_time_s
rank_Phi
cond_Phi
rank_Obs
cond_Obs
min_singular_Obs
status
notes
```

这样 ChatGPT 后续可以直接进行二次统计和评估。

---

# 32. RESULT_FOR_CHATGPT.md 的固定结构

最终必须生成一个专门供 ChatGPT 审核的文件：

`RESULT_FOR_CHATGPT.md`

必须严格按以下结构。

---

## 1. Executive Result

- 最终等级：A/B/C/D/F
- 50~150 字摘要

## 2. Environment

- MATLAB / Simulink / Simscape 信息
- 实际使用模型

## 3. Theory Check

逐项写：

- T12：PASS/FAIL
- T13：PASS/FAIL
- T15：PASS/FAIL
- T16：PASS/FAIL
- T17：PASS/FAIL

若 FAIL，说明原因。

## 4. Identifiability

- rank(\(\Phi\))
- rank(\(\mathcal O\))
- 最差工况
- 轻载情况

## 5. Ideal Accuracy

表格：

- RLS C MAPE
- RLS ESR MAPE
- LTVKF C MAPE
- LTVKF ESR MAPE

## 6. Operating-Condition Robustness

- input variation
- duty variation
- load variation

## 7. Noise Robustness

至少给：

- 20 dB
- 30 dB
- 40 dB
- 50 dB

## 8. Sampling Requirements

明确回答：

- 12-bit 是否够？
- 需要多少 points/cycle？
- PWM 同步容许误差大约多少？

## 9. Nonideal Effects

- rL
- MOSFET
- diode
- ESL
- ringing

分别给结论。

## 10. RLS vs TS-LTVKF

明确回答：

> 哪一个更适合作为论文主算法？为什么？

## 11. Failure Cases

不得省略失败工况。

## 12. Scientific Assessment

明确回答：

1. “edge → ESR” 是否真正成立？
2. “charge → C” 是否真正成立？
3. C/ESR 是否真正可解耦？
4. LTVKF 是否比 EKF 更自然？
5. 方案是否值得进入硬件实验？
6. 哪一条论文创新最强？
7. 哪一条论文主张需要降低表述？

## 13. Recommended Next Step

给出 3–8 条具体下一步。

## 14. File Index

列出所有关键结果路径。

---

# 33. RESULT_SUMMARY.md 的用途

`RESULT_SUMMARY.md` 面向人阅读，简洁一些。

但：

`RESULT_FOR_CHATGPT.md`

必须完整，不能只给摘要。

---

# 34. Codex 的停止条件

只有以下所有内容完成后才可以结束任务：

- [ ] 环境自检完成
- [ ] 理论独立核对完成
- [ ] Model A 运行完成
- [ ] Model B 已运行，或明确证明本机缺少相关工具
- [ ] T12/T13/T15/T16/T17 已逐项验证
- [ ] 二维 C–ESR 灵敏度验证完成
- [ ] RLS 完成
- [ ] TS-LTVKF 完成
- [ ] LTV 可观测性完成
- [ ] 多工况完成
- [ ] 噪声 Monte Carlo 完成
- [ ] ADC / sampling test 完成
- [ ] sync error test 完成
- [ ] 动态参数变化完成
- [ ] load/input transient decoupling 完成
- [ ] 至少一组 nonideal test 完成
- [ ] 结果表输出
- [ ] 图输出
- [ ] `RESULT_FOR_CHATGPT.md` 输出
- [ ] `result_metrics.csv` 输出

如果某一步因工具、license 或模型不稳定无法完成：

- 不能假装完成；
- 必须写成 `BLOCKED`；
- 说明原因；
- 继续完成其余可完成内容。

---

# 35. 最终要求给 Codex 的一句话

**不要试图证明我们的理论是对的；要试图把它推翻。只有在独立模型、不同工况、噪声、时序误差和合理非理想因素下仍然成立，才把它判定为支持。**

---

# 36. 给 ChatGPT 回传的最小文件集合

Codex 完成后，用户至少应把以下文件交回 ChatGPT：

```text
RESULT_FOR_CHATGPT.md
result_metrics.csv
table_identifiability.csv
table_ltv_observability.csv
table_noise_monte_carlo.csv
table_dynamic_tracking.csv
table_model_cross_validation.csv   # 若有 Model B
fig_02_edge_relation.png
fig_04_esr_feature_heatmap.png
fig_05_c_feature_heatmap.png
fig_07_error_vs_snr.png
fig_09_dynamic_C_step.png
fig_10_dynamic_ESR_step.png
fig_15_load_transient_decoupling.png
```

如果方便，最好直接把整个：

```text
cuk_cap_health_verification/
```

目录压缩为 ZIP 后一并提供。

ChatGPT 将根据这些数据重点重新评估：

1. 理论方程是否有符号或建模错误；
2. \(C\)-ESR 可辨识性是否真正成立；
3. LTV-KF 的可观测性证明与实际数据是否一致；
4. 论文是否应该以 RLS 还是 TS-LTVKF 为主；
5. 是否需要增加电容端电压传感器；
6. 采样频率是否具有硬件可实现性；
7. ESR 边沿方法是否被 ESL/振铃破坏；
8. 当前结果能支持什么级别的论文创新表述；
9. 下一阶段硬件实验应该如何设计。

---

## 任务版本

- Version: v1.0
- Date: 2026-08-20
- Objective: Verify the topology-embedded C–ESR identifiability and TS-LTVKF health estimation framework for the Ćuk energy-transfer capacitor.
