# Ćuk 拓扑能量传递电容健康度在线建模：理论推导与论文技术路线

> **文档定位**：本文档不是最终论文正文，而是用于论文立项、理论证明、仿真建模和后续实验设计的“理论母稿”。  
> **研究对象**：经典非隔离 Ćuk 变换器在连续导通模式（CCM）下的能量传递电容 \(C_1\)。  
> **健康参数**：等效电容量 \(C_1\) 与等效串联电阻 \(r_C=\mathrm{ESR}\)。  
> **核心目标**：利用 Ćuk 拓扑自身的 PWM 换相与能量传递规律，在不串接专用电容电流传感器的条件下，实现 \(C_1\) 与 ESR 的在线联合辨识，并构建连续健康指标。  
> **核心理论结论**：Ćuk 的能量传递电容在每个 PWM 周期中天然经历“正向充电—反向放电”的电流换向。理想电容内部电压在开关换相瞬间连续，而 ESR 压降随电流瞬时改变，因此：
>
> 1. **开关换相边沿的电容端电压跳变量主要由 ESR 决定；**
> 2. **稳定子区间内，扣除 ESR 压降后的电压增量/斜率主要由 \(C_1\) 决定；**
> 3. 两种特征在参数灵敏度上近似正交，可构造满秩的 \(C_1\)-ESR 可辨识性证明；
> 4. 进一步可以把模型写成对 \(\alpha=1/C_1\) 与 \(r_C\) 线性的积分回归问题，从而使用 RLS、加权最小二乘或线性时变 Kalman Filter，而不必一开始采用黑箱神经网络。

---

## 1. 研究问题与论文理论主线

### 1.1 为什么 Ćuk 的 \(C_1\) 特别重要

经典 Ćuk 变换器包含输入电感 \(L_1\)、能量传递电容 \(C_1\)、输出电感 \(L_2\)、输出电容 \(C_o\)、开关器件 \(S\)、二极管 \(D\) 和负载 \(R\)。

与 Buck、Boost 等拓扑中的普通输出滤波电容不同，Ćuk 的 \(C_1\) 位于**主能量传递链路**中。其主要作用不是仅仅滤除纹波，而是在两个开关子区间中交替完成输入侧到输出侧的能量转移。

严格来说，经典非隔离 Ćuk 并不提供安全意义上的 galvanic isolation。\(C_1\) 能够实现直流阻断和交流/开关能量耦合，因此论文中建议使用：

- **energy-transfer capacitor**
- **coupling capacitor**
- **energy-transfer/coupling capacitor**

而不建议直接称为 galvanic isolation capacitor。

### 1.2 论文真正需要解决的问题

本文不把问题定义成：

> “判断 Ćuk 电容是否故障”。

而定义为：

\[
\boxed{
\text{在线估计 }\hat C_1(t),\quad \widehat{\mathrm{ESR}}(t)
}
\]

进一步构造：

\[
\boxed{
\mathrm{SOH}(t)
=
f\!\left(
\hat C_1,\widehat{\mathrm{ESR}},T_C,\text{operating condition}
\right)
}
\]

关键科学问题是：

1. \(C_1\) 和 ESR 在 Ćuk 拓扑中是否结构可辨识？
2. 最少需要哪些电压、电流和 PWM 信息？
3. 如何利用 Ćuk 的天然开关激励，把 \(C_1\) 与 ESR 从同一个端电压波形中解耦？
4. 如何避免负载、输入电压、占空比和温度变化被误判为老化？
5. 如何构造适合嵌入式实现的递推估计器？

---

# 2. 拓扑、符号与基本假设

## 2.1 状态变量

定义状态向量：

\[
x=
\begin{bmatrix}
i_1 & i_2 & v_C & v_o
\end{bmatrix}^{T}
\]

其中：

- \(i_1=i_{L1}>0\)：输入电感电流；
- \(i_2=i_{L2}>0\)：输出电感电流；
- \(v_C\)：\(C_1\) 中**理想电容元件**两端的内部电压；
- \(v_o>0\)：输出电压幅值。经典反相 Ćuk 的物理输出极性相对于输入参考地为负，但本文为简化推导，统一使用其正幅值；
- \(v_T\)：能量传递电容组件 \(C_1+\mathrm{ESR}\) 的**外部端口电压**。

因此：

\[
v_{\text{out,physical}}=-v_o
\]

## 2.2 开关函数

定义：

\[
u(t)\in\{0,1\}
\]

其中：

- \(u=1\)：主开关 \(S\) 导通；
- \(u=0\)：主开关关断，二极管导通。

占空比定义为：

\[
D=\frac{1}{T_s}\int_{kT_s}^{(k+1)T_s}u(t)\,dt
\]

开关周期：

\[
T_s=\frac{1}{f_s}
\]

## 2.3 第一阶段理论假设

为了首先把 \(C_1\)-ESR 的可辨识性做清楚，采用以下基本假设：

1. 变换器工作于 CCM；
2. 第一阶段忽略 \(L_1,L_2\) 的绕组电阻、MOSFET 导通电阻和二极管压降；
3. 输出电容视为理想，负载为 \(R\)；
4. \(C_1\) 使用一阶串联模型：
   \[
   Z_C(s)=r_C+\frac{1}{sC_1}
   \]
5. 暂不包含 ESL；
6. 在一个辨识窗口内 \(C_1\) 与 \(r_C\) 变化极慢，可视为常数；
7. PWM 状态 \(u(t)\) 已知；
8. 电感电流在 CCM 下方向不改变。

后续第 13 节再讨论寄生参数、ESL、温度与 DCM。

---

# 3. 理想 Ćuk 的分段开关模型

经典 Ćuk 在 CCM 下有两个主要拓扑状态。

## 3.1 状态 A：\(u=1\)，主开关导通

此时：

- 输入电感 \(L_1\) 由输入源充电；
- 能量传递电容向输出侧释放能量；
- \(C_1\) 电流方向与 \(i_2\) 相反。

理想模型为：

\[
\frac{di_1}{dt}
=
\frac{V_{in}}{L_1}
\tag{1}
\]

\[
\frac{di_2}{dt}
=
\frac{v_C-v_o}{L_2}
\tag{2}
\]

\[
\frac{dv_C}{dt}
=
-\frac{i_2}{C_1}
\tag{3}
\]

\[
\frac{dv_o}{dt}
=
\frac{i_2}{C_o}
-\frac{v_o}{RC_o}
\tag{4}
\]

因此该状态下：

\[
\boxed{i_C=-i_2}
\tag{5}
\]

---

## 3.2 状态 B：\(u=0\)，主开关关断

此时输入侧通过 \(C_1\) 向其充电，并完成能量重新分配。

理想模型：

\[
\frac{di_1}{dt}
=
\frac{V_{in}-v_C}{L_1}
\tag{6}
\]

\[
\frac{di_2}{dt}
=
-\frac{v_o}{L_2}
\tag{7}
\]

\[
\frac{dv_C}{dt}
=
\frac{i_1}{C_1}
\tag{8}
\]

\[
\frac{dv_o}{dt}
=
\frac{i_2}{C_o}
-\frac{v_o}{RC_o}
\tag{9}
\]

因此：

\[
\boxed{i_C=i_1}
\tag{10}
\]

---

## 3.3 统一的电容电流表达式

将两个状态合并：

\[
\boxed{
i_C=(1-u)i_1-u i_2
}
\tag{11}
\]

这是后续论文最重要的拓扑关系之一。

其意义是：

> 只要开关状态 \(u\) 与两个电感电流可获得，就不必在 \(C_1\) 支路中串入专用电流传感器。

进一步：

\[
\boxed{
\frac{dv_C}{dt}
=
\frac{(1-u)i_1-u i_2}{C_1}
}
\tag{12}
\]

---

# 4. 引入 \(C_1\) 的 ESR 后的精确电容端口关系

把能量传递电容建模为理想电容 \(C_1\) 与 ESR \(r_C\) 串联。

按照被动符号约定：

\[
\boxed{
v_T=v_C+r_C i_C
}
\tag{13}
\]

并且：

\[
\boxed{
\dot v_C=\frac{i_C}{C_1}
}
\tag{14}
\]

将式 (11) 代入：

\[
\boxed{
v_T
=
v_C
+
r_C\left[(1-u)i_1-u i_2\right]
}
\tag{15}
\]

这是整个健康辨识模型的第二个核心方程。

---

# 5. 含 ESR 的两状态模型

## 5.1 \(u=1\)

此时：

\[
i_C=-i_2
\]

故：

\[
v_T=v_C-r_C i_2
\tag{16}
\]

输出侧电感两端电压：

\[
L_2\dot i_2=v_T-v_o
\]

所以：

\[
\boxed{
\dot i_2
=
\frac{v_C-r_Ci_2-v_o}{L_2}
}
\tag{17}
\]

其余：

\[
\dot i_1=\frac{V_{in}}{L_1}
\tag{18}
\]

\[
\dot v_C=-\frac{i_2}{C_1}
\tag{19}
\]

\[
\dot v_o
=
\frac{i_2}{C_o}
-
\frac{v_o}{RC_o}
\tag{20}
\]

状态矩阵可写为：

\[
\dot x=A_1x+B_1V_{in}
\tag{21}
\]

其中：

\[
A_1=
\begin{bmatrix}
0&0&0&0\\
0&-\frac{r_C}{L_2}&\frac{1}{L_2}&-\frac{1}{L_2}\\
0&-\frac{1}{C_1}&0&0\\
0&\frac{1}{C_o}&0&-\frac{1}{RC_o}
\end{bmatrix}
\tag{22}
\]

\[
B_1=
\begin{bmatrix}
\frac{1}{L_1}\\
0\\
0\\
0
\end{bmatrix}
\tag{23}
\]

---

## 5.2 \(u=0\)

此时：

\[
i_C=i_1
\]

故：

\[
v_T=v_C+r_Ci_1
\tag{24}
\]

输入侧：

\[
L_1\dot i_1
=
V_{in}-v_T
\]

因此：

\[
\boxed{
\dot i_1
=
\frac{V_{in}-v_C-r_Ci_1}{L_1}
}
\tag{25}
\]

其余：

\[
\dot i_2=-\frac{v_o}{L_2}
\tag{26}
\]

\[
\dot v_C=\frac{i_1}{C_1}
\tag{27}
\]

\[
\dot v_o
=
\frac{i_2}{C_o}
-
\frac{v_o}{RC_o}
\tag{28}
\]

即：

\[
\dot x=A_0x+B_0V_{in}
\tag{29}
\]

\[
A_0=
\begin{bmatrix}
-\frac{r_C}{L_1}&0&-\frac{1}{L_1}&0\\
0&0&0&-\frac{1}{L_2}\\
\frac{1}{C_1}&0&0&0\\
0&\frac{1}{C_o}&0&-\frac{1}{RC_o}
\end{bmatrix}
\tag{30}
\]

\[
B_0=B_1
\tag{31}
\]

---

# 6. 统一混杂模型

利用二值开关变量 \(u\)：

\[
\boxed{
\dot i_1
=
\frac{
V_{in}
-(1-u)v_C
-r_C(1-u)i_1
}{L_1}
}
\tag{32}
\]

\[
\boxed{
\dot i_2
=
\frac{
uv_C-v_o-r_Cu i_2
}{L_2}
}
\tag{33}
\]

\[
\boxed{
\dot v_C
=
\frac{(1-u)i_1-u i_2}{C_1}
}
\tag{34}
\]

\[
\boxed{
\dot v_o
=
\frac{i_2}{C_o}
-\frac{v_o}{RC_o}
}
\tag{35}
\]

输出方程：

\[
\boxed{
v_T
=
v_C+
r_C[(1-u)i_1-u i_2]
}
\tag{36}
\]

这组方程构成后续 Simulink、PLECS、MATLAB 参数辨识以及实验实现的统一理论模型。

---

# 7. 状态空间平均模型与稳态关系

用 \(D\) 代替一个周期内 \(u\) 的平均值，有：

\[
\dot i_1
=
\frac{
V_{in}
-(1-D)v_C
-r_C(1-D)i_1
}{L_1}
\tag{37}
\]

\[
\dot i_2
=
\frac{
Dv_C-v_o-r_CD i_2
}{L_2}
\tag{38}
\]

\[
\dot v_C
=
\frac{
(1-D)i_1-Di_2
}{C_1}
\tag{39}
\]

\[
\dot v_o
=
\frac{i_2}{C_o}
-
\frac{v_o}{RC_o}
\tag{40}
\]

其平均状态矩阵：

\[
A(D)=
\begin{bmatrix}
-\frac{r_C(1-D)}{L_1}&0&-\frac{1-D}{L_1}&0\\
0&-\frac{r_CD}{L_2}&\frac{D}{L_2}&-\frac{1}{L_2}\\
\frac{1-D}{C_1}&-\frac{D}{C_1}&0&0\\
0&\frac{1}{C_o}&0&-\frac{1}{RC_o}
\end{bmatrix}
\tag{41}
\]

---

## 7.1 电荷平衡

稳态：

\[
\dot v_C=0
\]

因此：

\[
\boxed{
(1-D)I_1=DI_2
}
\tag{42}
\]

即：

\[
\boxed{
\frac{I_1}{I_2}
=
\frac{D}{1-D}
}
\tag{43}
\]

---

## 7.2 理想情况下的 \(C_1\) 电压应力

先令 \(r_C=0\)。

由 \(\dot i_1=0\)：

\[
V_{in}=(1-D)V_C
\]

故：

\[
\boxed{
V_C=\frac{V_{in}}{1-D}
}
\tag{44}
\]

由 \(\dot i_2=0\)：

\[
V_o=DV_C
\]

因此：

\[
\boxed{
\frac{V_o}{V_{in}}
=
\frac{D}{1-D}
}
\tag{45}
\]

物理输出电压：

\[
\boxed{
\frac{V_{\text{out,physical}}}{V_{in}}
=
-\frac{D}{1-D}
}
\tag{46}
\]

式 (44) 表明，\(C_1\) 承受的平均电压通常显著高于输入电压。

---

# 8. \(C_1\) 的 RMS 电流与 ESR 热应力

在电感纹波相对较小时，可以近似：

\[
i_C=
\begin{cases}
I_1,& u=0\\
-I_2,& u=1
\end{cases}
\tag{47}
\]

因此：

\[
I_{C,\mathrm{rms}}^2
=
(1-D)I_1^2
+
DI_2^2
\tag{48}
\]

利用式 (43)：

\[
I_1=\frac{D}{1-D}I_2
\]

得到：

\[
\boxed{
I_{C,\mathrm{rms}}
=
I_2\sqrt{\frac{D}{1-D}}
}
\tag{49}
\]

或者：

\[
\boxed{
I_{C,\mathrm{rms}}
=
I_1\sqrt{\frac{1-D}{D}}
}
\tag{50}
\]

ESR 损耗：

\[
\boxed{
P_{ESR}
=
r_C I_{C,\mathrm{rms}}^2
}
\tag{51}
\]

因此：

\[
\boxed{
P_{ESR}
=
r_C I_2^2\frac{D}{1-D}
}
\tag{52}
\]

这是建立“健康参数 \(\rightarrow\) 热应力 \(\rightarrow\) 寿命”的基础。

当 \(r_C\) 因老化升高时，即使控制器仍维持相同输出，电容内部损耗也会上升，从而造成更高热点温度和进一步加速老化，形成正反馈。

---

# 9. 为什么仅靠平均稳态量难以估计 \(C_1\)

这是论文需要明确指出的一个理论事实。

在稳态平均模型中：

\[
0=
\frac{(1-D)I_1-DI_2}{C_1}
\]

分子本身必须为零，因此：

\[
(1-D)I_1-DI_2=0
\]

此时 \(C_1\) 从稳态方程中消失。

也就是说：

\[
\boxed{
\text{纯 DC 稳态工作点不能提供 }C_1\text{ 的直接可辨识信息}
}
\tag{53}
\]

因此，若只采集低带宽平均量，如：

- 平均输入电流；
- 平均输出电压；
- 平均占空比；

则难以准确识别 \(C_1\)。

**真正包含 \(C_1\) 健康信息的是：**

1. 开关周期内的充放电斜率；
2. 负载/占空比瞬态；
3. PWM 固有谐波；
4. 开关换相前后的端口电压变化。

这也是本文选择“拓扑同步、开关尺度参数辨识”的理论原因。

---

# 10. 电容端口方程：把问题化为线性参数辨识

从：

\[
v_T=v_C+r_C i_C
\]

和：

\[
\dot v_C=\frac{i_C}{C_1}
\]

定义：

\[
\alpha=\frac{1}{C_1}
\tag{54}
\]

则：

\[
\dot v_C=\alpha i_C
\tag{55}
\]

对任意区间 \([t_a,t_b]\) 积分：

\[
v_C(t_b)-v_C(t_a)
=
\alpha
\int_{t_a}^{t_b}i_C(\tau)d\tau
\tag{56}
\]

定义：

\[
q_{ab}
=
\int_{t_a}^{t_b}i_C(\tau)d\tau
\tag{57}
\]

端电压差：

\[
v_T(t_b)-v_T(t_a)
=
v_C(t_b)-v_C(t_a)
+
r_C[i_C(t_b)-i_C(t_a)]
\]

于是：

\[
\boxed{
\Delta v_T
=
\alpha q_{ab}
+
r_C\Delta i_C
}
\tag{58}
\]

其中：

\[
\Delta v_T=v_T(t_b)-v_T(t_a)
\]

\[
\Delta i_C=i_C(t_b)-i_C(t_a)
\]

式 (58) 是本文最重要的**参数辨识方程**。

它有四个非常关键的性质：

1. 对 \(\alpha=1/C_1\) 与 \(r_C\) **严格线性**；
2. 不需要对测量电压求导；
3. \(i_C\) 可以由 Ćuk 拓扑关系式 (11) 重构；
4. 区间既可以位于单个开关状态内，也可以跨越换相边沿。

定义：

\[
z_j=\Delta v_{T,j}
\]

\[
\phi_j=
\begin{bmatrix}
q_j & \Delta i_{C,j}
\end{bmatrix}
\]

\[
\theta=
\begin{bmatrix}
\alpha\\
r_C
\end{bmatrix}
\]

则：

\[
\boxed{
z_j=\phi_j\theta+\varepsilon_j
}
\tag{59}
\]

堆叠 \(N\) 个区间：

\[
Z=\Phi\theta+E
\tag{60}
\]

因此最小二乘解：

\[
\boxed{
\hat\theta
=
(\Phi^T W\Phi)^{-1}
\Phi^TWZ
}
\tag{61}
\]

最后：

\[
\boxed{
\hat C_1=\frac{1}{\hat\alpha}
}
\tag{62}
\]

\[
\boxed{
\widehat{ESR}=\hat r_C
}
\tag{63}
\]

---

# 11. 离散采样模型

如果相邻采样时刻间隔为 \(T_a\)，采用梯形积分：

\[
q_k
\approx
\frac{T_a}{2}
(i_{C,k}+i_{C,k-1})
\tag{64}
\]

则：

\[
v_{T,k}-v_{T,k-1}
=
\frac{T_a}{2C_1}(i_{C,k}+i_{C,k-1})
+
r_C(i_{C,k}-i_{C,k-1})
\tag{65}
\]

定义：

\[
\beta_1
=
r_C+\frac{T_a}{2C_1}
\tag{66}
\]

\[
\beta_2
=
\frac{T_a}{2C_1}-r_C
\tag{67}
\]

得到：

\[
\boxed{
v_{T,k}
=
v_{T,k-1}
+
\beta_1 i_{C,k}
+
\beta_2 i_{C,k-1}
}
\tag{68}
\]

反解：

\[
\boxed{
r_C=\frac{\beta_1-\beta_2}{2}
}
\tag{69}
\]

\[
\boxed{
C_1=
\frac{T_a}{\beta_1+\beta_2}
}
\tag{70}
\]

这与近年来 Boost/DC-link 电容在线参数估计所使用的离散电容模型具有一致的物理基础，但在 Ćuk 中，\(i_C\) 的生成机制具有明显拓扑特异性。

---

# 12. Ćuk 最关键的特异性：开关换相造成天然电流反向

在 CCM 下：

\[
i_1>0,\qquad i_2>0
\]

但 \(C_1\) 的电流：

\[
i_C=
\begin{cases}
+i_1,&u=0\\
-i_2,&u=1
\end{cases}
\]

因此，在 \(u:0\rightarrow1\) 的换相瞬间：

\[
i_C^- = i_1^-
\]

\[
i_C^+ = -i_2^+
\]

所以：

\[
\boxed{
\Delta i_C
=
i_C^+-i_C^-
=
-(i_1^-+i_2^+)
}
\tag{71}
\]

理想电容内部电压不能瞬间变化：

\[
\boxed{
v_C^+=v_C^-
}
\tag{72}
\]

换相前：

\[
v_T^-=v_C+r_C i_1^-
\]

换相后：

\[
v_T^+=v_C-r_C i_2^+
\]

于是：

\[
\boxed{
v_T^- - v_T^+
=
r_C(i_1^-+i_2^+)
}
\tag{73}
\]

从而：

\[
\boxed{
r_C
=
\frac{
v_T^- - v_T^+
}{
i_1^-+i_2^+
}
}
\tag{74}
\]

同理，在 \(u:1\rightarrow0\) 的边沿：

\[
\boxed{
v_T^+ - v_T^-
=
r_C(i_1^+ + i_2^-)
}
\tag{75}
\]

## 12.1 这一公式的意义

式 (74) 非常重要：

> **在理想一阶 ESR 模型下，开关边沿的端电压跳变与 \(C_1\) 无关，只由 ESR 与电流跳变量决定。**

因此，Ćuk 的自然换相本身就相当于每个 PWM 周期自动执行一次 ESR 激励实验。

不需要：

- 额外注入扰动；
- 改变正常控制器；
- 增加串联电容电流传感器。

这可以成为论文第一理论创新点。

---

# 13. 在子区间内用电荷增量估计 \(C_1\)

## 13.1 \(u=0\) 区间

此时：

\[
i_C=i_1
\]

内部电容电压：

\[
v_C=v_T-r_C i_1
\tag{76}
\]

在一个 OFF 区间 \([t_a,t_b]\) 内：

\[
v_C(t_b)-v_C(t_a)
=
\frac{1}{C_1}
\int_{t_a}^{t_b}i_1(t)\,dt
\]

因此：

\[
\boxed{
C_1
=
\frac{
\int_{t_a}^{t_b}i_1(t)\,dt
}{
[v_T(t_b)-r_Ci_1(t_b)]
-
[v_T(t_a)-r_Ci_1(t_a)]
}
}
\tag{77}
\]

---

## 13.2 \(u=1\) 区间

此时：

\[
i_C=-i_2
\]

内部电容电压：

\[
v_C=v_T+r_C i_2
\tag{78}
\]

所以：

\[
\boxed{
C_1
=
\frac{
\int_{t_a}^{t_b}i_2(t)\,dt
}{
-
\left\{
[v_T(t_b)+r_Ci_2(t_b)]
-
[v_T(t_a)+r_Ci_2(t_a)]
\right\}
}
}
\tag{79}
\]

这样可以分别得到：

\[
\hat C_{OFF}
\]

和：

\[
\hat C_{ON}
\]

最终融合：

\[
\boxed{
\hat C_1
=
w_0\hat C_{OFF}
+
w_1\hat C_{ON}
}
\tag{80}
\]

权重可以根据：

- 区间电荷量；
- 电压变化幅度；
- 测量噪声；
- 当前估计方差；

动态确定。

---

# 14. 近似稳态下的纹波闭式关系

若一个周期内 \(i_1,i_2\) 纹波较小，则 OFF 期间：

\[
\Delta v_{C,OFF}
\approx
\frac{I_1(1-D)T_s}{C_1}
\tag{81}
\]

ON 期间：

\[
|\Delta v_{C,ON}|
\approx
\frac{I_2DT_s}{C_1}
\tag{82}
\]

由于电荷平衡：

\[
I_1(1-D)=I_2D
\]

所以：

\[
\boxed{
\Delta v_C
\approx
\frac{I_1(1-D)}{C_1f_s}
=
\frac{I_2D}{C_1f_s}
}
\tag{83}
\]

与此同时，ESR 换相跳变约为：

\[
\boxed{
\Delta v_{ESR}
\approx
r_C(I_1+I_2)
}
\tag{84}
\]

利用：

\[
I_1+I_2=\frac{I_1}{D}
\]

得到：

\[
\Delta v_{ESR}
\approx
\frac{r_C I_1}{D}
\tag{85}
\]

两个特征之比：

\[
\rho
=
\frac{\Delta v_{ESR}}{\Delta v_C}
\]

可化为：

\[
\boxed{
\rho
\approx
\frac{
r_CC_1f_s
}{
D(1-D)
}
}
\tag{86}
\]

这个式子解释了为什么仅使用“总纹波幅值”无法区分：

- \(C_1\) 减小；
- ESR 增大。

因为两者都会增大端电压纹波。

论文必须做的不是“测纹波”，而是：

\[
\boxed{
\text{把 edge jump 与 intra-state ramp 分开}
}
\]

---

# 15. \(C_1\)-ESR 的拓扑解耦与可辨识性定理

这是建议写进论文理论部分的核心命题。

## 命题 1：基于换相边沿和子区间电荷的局部结构可辨识性

设 Ćuk 工作于 CCM，满足：

\[
0<D<1
\]

\[
i_1>0,\qquad i_2>0
\]

并且在换相邻域忽略 ESL 和高频寄生振铃。

定义 ESR 特征：

\[
f_R
=
v_T^- - v_T^+
\]

则：

\[
f_R
=
r_C(i_1+i_2)
\tag{87}
\]

定义 OFF 期间扣除 ESR 后的电容增量：

\[
f_C
=
[v_T(t_b)-r_Ci_1(t_b)]
-
[v_T(t_a)-r_Ci_1(t_a)]
\]

则：

\[
f_C
=
\frac{Q_0}{C_1}
\tag{88}
\]

其中：

\[
Q_0=\int_{t_a}^{t_b}i_1(t)dt>0
\]

对参数：

\[
p=
\begin{bmatrix}
C_1\\
r_C
\end{bmatrix}
\]

定义特征映射：

\[
F(p)=
\begin{bmatrix}
f_R\\
f_C
\end{bmatrix}
\]

其灵敏度矩阵：

\[
J
=
\frac{\partial F}{\partial p}
=
\begin{bmatrix}
0&i_1+i_2\\
-\frac{Q_0}{C_1^2}&0
\end{bmatrix}
\tag{89}
\]

其行列式：

\[
\boxed{
\det(J)
=
\frac{
(i_1+i_2)Q_0
}{
C_1^2
}
>0
}
\tag{90}
\]

因此：

\[
\boxed{
\mathrm{rank}(J)=2
}
\tag{91}
\]

即 \(C_1\) 与 \(r_C\) 在该特征集下局部可辨识。

### 物理解释

灵敏度矩阵近似反对角：

- \(f_R\) 对 ESR 高灵敏，对 \(C_1\) 的瞬时变化近似不敏感；
- \(f_C\) 在 ESR 被补偿后只由 \(1/C_1\) 决定。

因此，Ćuk 拓扑天然提供了两种时间尺度不同、参数作用机制不同的观测。

---

# 16. 更一般的全窗口可辨识条件

使用积分回归：

\[
z_j=q_j\alpha+\Delta i_{C,j}r_C
\]

定义：

\[
\Phi=
\begin{bmatrix}
q_1&\Delta i_{C,1}\\
q_2&\Delta i_{C,2}\\
\vdots&\vdots\\
q_N&\Delta i_{C,N}
\end{bmatrix}
\]

\(C_1\) 与 ESR 可唯一估计的基本条件为：

\[
\boxed{
\mathrm{rank}(\Phi)=2
}
\tag{92}
\]

等价地：

\[
\boxed{
\det(\Phi^T\Phi)>0
}
\tag{93}
\]

展开：

\[
\boxed{
\left(\sum q_j^2\right)
\left(\sum \Delta i_{C,j}^2\right)
-
\left(\sum q_j\Delta i_{C,j}\right)^2
>0
}
\tag{94}
\]

这说明：

> 如果所有数据中的电荷增量 \(q_j\) 与电流变化 \(\Delta i_{C,j}\) 完全成比例，则两个参数会耦合；只要 PWM 子区间和换相边沿同时提供不同方向的激励，矩阵就容易保持满秩。

Ćuk 的优势就在于：

- 子区间提供较大的 \(q_j\)；
- 换相边沿提供很大的 \(\Delta i_C\)；
- 二者天然不同。

---

# 17. 一个严格的参数唯一性证明

假设同一已知 \(i_C(t)\) 下存在两组参数：

\[
(C_a,r_a)
\]

和：

\[
(C_b,r_b)
\]

产生完全相同的端口电压。

定义：

\[
\alpha_a=\frac{1}{C_a}
\]

\[
\alpha_b=\frac{1}{C_b}
\]

由积分关系：

\[
\Delta v_T
=
\alpha q+r\Delta i_C
\]

若两组参数对任意采样区间产生相同输出，则：

\[
(\alpha_a-\alpha_b)q
+
(r_a-r_b)\Delta i_C
=
0
\tag{95}
\]

对两个线性无关区间：

\[
\begin{bmatrix}
q_1&\Delta i_1\\
q_2&\Delta i_2
\end{bmatrix}
\begin{bmatrix}
\alpha_a-\alpha_b\\
r_a-r_b
\end{bmatrix}
=
0
\tag{96}
\]

若：

\[
q_1\Delta i_2-q_2\Delta i_1\neq0
\]

则唯一解：

\[
\alpha_a=\alpha_b
\]

\[
r_a=r_b
\]

即：

\[
\boxed{
C_a=C_b,\qquad r_a=r_b
}
\tag{97}
\]

因此，在持续激励条件成立时，\(C_1\) 和 ESR 具有结构唯一性。

---

# 18. 推荐算法一：拓扑同步加权 RLS

从：

\[
z_k=\phi_k^T\theta+\varepsilon_k
\]

其中：

\[
\theta=
\begin{bmatrix}
\alpha&r_C
\end{bmatrix}^{T}
\]

采用遗忘因子 RLS：

\[
K_k
=
\frac{
P_{k-1}\phi_k
}{
\lambda+\phi_k^TP_{k-1}\phi_k
}
\tag{98}
\]

\[
e_k
=
z_k-\phi_k^T\hat\theta_{k-1}
\tag{99}
\]

\[
\hat\theta_k
=
\hat\theta_{k-1}
+
K_ke_k
\tag{100}
\]

\[
P_k
=
\frac{1}{\lambda}
\left(
P_{k-1}
-
K_k\phi_k^TP_{k-1}
\right)
\tag{101}
\]

其中：

\[
0<\lambda\le1
\]

参数物理约束：

\[
\alpha>0,\qquad r_C>0
\]

因此建议加入投影：

\[
\boxed{
\hat\theta_k
=
\Pi_{\Omega}
\left(
\hat\theta_{k-1}+K_ke_k
\right)
}
\tag{102}
\]

其中：

\[
\Omega=
\left\{
\alpha_{\min}\le\alpha\le\alpha_{\max},
\;
r_{\min}\le r_C\le r_{\max}
\right\}
\]

最后：

\[
\hat C_1=\frac{1}{\hat\alpha}
\]

### 建议

第一篇论文的主算法优先考虑：

\[
\boxed{
\text{Topology-Synchronous Weighted/Projected RLS}
}
\]

原因：

- 理论透明；
- 计算量小；
- 很容易嵌入 MCU/DSP；
- 能突出拓扑机理，而不是突出算法复杂度。

---

# 19. 推荐算法二：线性时变增广 Kalman Filter（LTV-KF）

本节给出一套可直接用于论文方法章节的完整 LTV Kalman Filter 推导。

---

## 19.1 为什么这里可以使用 LTV-KF，而不需要 EKF

若直接把电容量 \(C_1\) 作为状态，则：

\[
\dot v_C=\frac{i_C}{C_1}
\]

中存在：

\[
\frac{1}{C_1}
\]

非线性项。

为避免这一非线性，定义参数：

\[
\boxed{
\alpha=\frac{1}{C_1}
}
\tag{103}
\]

于是：

\[
\dot v_C=\alpha i_C
\tag{104}
\]

在每个采样区间 \([t_k,t_{k+1}]\) 内定义电荷增量：

\[
\boxed{
q_k=
\int_{t_k}^{t_{k+1}}i_C(\tau)\,d\tau
}
\tag{105}
\]

则：

\[
v_{C,k+1}
=
v_{C,k}
+
q_k\alpha_k
\tag{106}
\]

若在一个较短估计窗口内认为 \(C_1\) 与 ESR 变化缓慢，可用随机游走描述：

\[
\alpha_{k+1}
=
\alpha_k+w_{\alpha,k}
\tag{107}
\]

\[
r_{C,k+1}
=
r_{C,k}+w_{r,k}
\tag{108}
\]

因此，把：

\[
x_k=
\begin{bmatrix}
v_{C,k}\\
\alpha_k\\
r_{C,k}
\end{bmatrix}
\tag{109}
\]

作为增广状态，可以得到严格的线性时变状态方程：

\[
\boxed{
x_{k+1}=F_kx_k+w_k
}
\tag{110}
\]

其中：

\[
\boxed{
F_k=
\begin{bmatrix}
1&q_k&0\\
0&1&0\\
0&0&1
\end{bmatrix}
}
\tag{111}
\]

由于 \(q_k\) 随 PWM 状态、负载和电感电流变化，因此 \(F_k\) 是时变量，但对状态 \(x_k\) 仍保持线性。

这就是本文能够使用 **LTV Kalman Filter 而非 EKF** 的数学根源。

---

## 19.2 时变观测方程

能量传递电容的外部端口电压：

\[
v_T=v_C+r_C i_C
\]

离散化后：

\[
v_{T,k}
=
v_{C,k}
+
i_{C,k}r_{C,k}
+
\nu_k
\tag{112}
\]

其中：

\[
\nu_k
\sim
\mathcal N(0,R_k)
\]

表示电压采样噪声和未建模高频扰动。

因此观测方程：

\[
\boxed{
y_k=H_kx_k+\nu_k
}
\tag{113}
\]

其中：

\[
y_k=v_{T,k}
\]

\[
\boxed{
H_k=
\begin{bmatrix}
1&0&i_{C,k}
\end{bmatrix}
}
\tag{114}
\]

因为 \(i_{C,k}\) 由：

\[
i_{C,k}
=
(1-u_k)i_{1,k}
-u_ki_{2,k}
\tag{115}
\]

实时重构，所以 \(H_k\) 完全已知，但随开关状态变化。

因此整个估计系统是：

\[
\boxed{
\begin{aligned}
x_{k+1}&=F_kx_k+w_k\\
y_k&=H_kx_k+\nu_k
\end{aligned}
}
\tag{116}
\]

属于标准的 **Linear Time-Varying State-Space Model**。

---

## 19.3 状态与参数的物理含义

三维增广状态分别为：

\[
x_1=v_C
\]

\[
x_2=\alpha=\frac{1}{C_1}
\]

\[
x_3=r_C
\]

估计结果：

\[
\boxed{
\hat C_{1,k}
=
\frac{1}{\hat\alpha_k}
}
\tag{117}
\]

\[
\boxed{
\widehat{ESR}_k=\hat r_{C,k}
}
\tag{118}
\]

因此 LTV-KF 同时完成：

1. 内部理想电容电压 \(v_C\) 的状态估计；
2. 电容量 \(C_1\) 的慢参数估计；
3. ESR 的慢参数估计。

与 RLS 不同，LTV-KF 不需要先通过端点差分消除 \(v_C\)，而是把 \(v_C\) 一并纳入状态。

---

## 19.4 标准 LTV Kalman Filter 递推

### 预测步骤

状态预测：

\[
\boxed{
\hat x_{k|k-1}
=
F_{k-1}\hat x_{k-1|k-1}
}
\tag{119}
\]

协方差预测：

\[
\boxed{
P_{k|k-1}
=
F_{k-1}P_{k-1|k-1}F_{k-1}^{T}
+
Q_{k-1}
}
\tag{120}
\]

其中：

\[
Q_k=
\begin{bmatrix}
q_v&0&0\\
0&q_\alpha&0\\
0&0&q_r
\end{bmatrix}
\tag{121}
\]

为过程噪声协方差。

---

### 更新步骤

创新：

\[
\boxed{
e_k
=
y_k
-
H_k\hat x_{k|k-1}
}
\tag{122}
\]

创新协方差：

\[
\boxed{
S_k
=
H_kP_{k|k-1}H_k^T
+
R_k
}
\tag{123}
\]

Kalman 增益：

\[
\boxed{
K_k
=
P_{k|k-1}H_k^TS_k^{-1}
}
\tag{124}
\]

状态更新：

\[
\boxed{
\hat x_{k|k}
=
\hat x_{k|k-1}
+
K_ke_k
}
\tag{125}
\]

协方差更新建议采用 Joseph 形式：

\[
\boxed{
P_{k|k}
=
(I-K_kH_k)
P_{k|k-1}
(I-K_kH_k)^T
+
K_kR_kK_k^T
}
\tag{126}
\]

相比：

\[
P=(I-KH)P^-
\]

Joseph 形式在嵌入式有限精度计算中具有更好的数值稳定性和半正定保持能力。

---

# 20. LTV-KF 的可观测性与参数可辨识性

仅仅把 \(C_1\) 与 ESR 加入状态，并不意味着参数一定能被估计。

必须研究：

\[
(F_k,H_k)
\]

组成的时变系统是否在有限时间窗口内具有充分可观测性。

---

## 20.1 单个时刻为什么不可完全观测

单时刻观测矩阵：

\[
H_k=
\begin{bmatrix}
1&0&i_{C,k}
\end{bmatrix}
\]

只包含一个标量测量，因此显然无法瞬间恢复三个状态。

参数信息必须通过：

\[
q_k
\]

和：

\[
i_{C,k}
\]

随时间的变化逐步累积。

---

## 20.2 两步状态转移矩阵

有：

\[
F_k=
\begin{bmatrix}
1&q_k&0\\
0&1&0\\
0&0&1
\end{bmatrix}
\]

因此：

\[
F_{k+1}F_k
=
\begin{bmatrix}
1&q_k+q_{k+1}&0\\
0&1&0\\
0&0&1
\end{bmatrix}
\tag{127}
\]

一般地，从时刻 \(k\) 到 \(k+m\)：

\[
\Phi(k+m,k)
=
\begin{bmatrix}
1&
\displaystyle\sum_{j=k}^{k+m-1}q_j
&
0\\
0&1&0\\
0&0&1
\end{bmatrix}
\tag{128}
\]

---

## 20.3 有限窗口可观测矩阵

定义窗口长度 \(N\)，则时变可观测矩阵可写为：

\[
\mathcal O_{k,N}
=
\begin{bmatrix}
H_k\\
H_{k+1}\Phi(k+1,k)\\
H_{k+2}\Phi(k+2,k)\\
\vdots\\
H_{k+N-1}\Phi(k+N-1,k)
\end{bmatrix}
\tag{129}
\]

每一行为：

\[
\boxed{
\begin{bmatrix}
1&
Q_{k,j}
&
i_{C,j}
\end{bmatrix}
}
\tag{130}
\]

其中：

\[
Q_{k,j}
=
\sum_{\ell=k}^{j-1}q_\ell
\tag{131}
\]

代表从窗口起点到当前时刻的累计电荷。

于是，系统在窗口内完全可观测的条件是：

\[
\boxed{
\mathrm{rank}
(\mathcal O_{k,N})
=3
}
\tag{132}
\]

其物理意义是：

- 常数列 \(1\) 用于识别初始内部电压 \(v_C\)；
- 累计电荷列 \(Q_{k,j}\) 用于识别 \(\alpha=1/C_1\)；
- 电容电流列 \(i_{C,j}\) 用于识别 ESR。

只要：

\[
Q_{k,j}
\]

和：

\[
i_{C,j}
\]

在时间窗口内不是彼此仿射相关，三个状态即可被区分。

---

## 20.4 三采样点的显式满秩条件

若取三个采样点：

\[
j=0,1,2
\]

可观测矩阵可写成：

\[
\mathcal O_3
=
\begin{bmatrix}
1&Q_0&i_0\\
1&Q_1&i_1\\
1&Q_2&i_2
\end{bmatrix}
\tag{133}
\]

其行列式：

\[
\det(\mathcal O_3)
=
(Q_1-Q_0)(i_2-i_0)
-
(Q_2-Q_0)(i_1-i_0)
\tag{134}
\]

所以：

\[
\boxed{
\det(\mathcal O_3)\neq0
}
\tag{135}
\]

即可保证三状态在该三点窗口内可观测。

这一条件说明：

> 如果累计电荷变化和电流变化具有不同的时间轨迹，则 \(v_C\)、\(1/C_1\) 与 ESR 可以被同时分离。

Ćuk 每个 PWM 周期内：

\[
+i_{L1}
\longleftrightarrow
-i_{L2}
\]

的电流换向使 \(i_C\) 出现显著变化，而累计电荷 \(Q\) 则连续演化，因此天然有利于满足式 (135)。

---

# 21. LTV-KF 为什么特别适合 Ćuk 的 PWM 天然激励

在普通近恒流工作区间：

\[
i_C\approx \mathrm{const.}
\]

则：

\[
H_k
\]

变化很小，ESR 可观测性会下降。

而 Ćuk 的 \(i_C\) 每个 PWM 周期都经历：

\[
+i_{L1}
\rightarrow
-i_{L2}
\rightarrow
+i_{L1}
\]

因此：

\[
H_k
=
[1,0,i_{C,k}]
\]

在两个拓扑状态之间发生显著变化。

与此同时：

\[
F_k
\]

中的：

\[
q_k
=
\int i_Cdt
\]

也随拓扑状态改变符号。

因此每一个完整 PWM 周期都在周期性改变：

\[
F_k,\quad H_k
\]

这相当于一个**天然周期时变激励系统**。

可以把这一点概括为：

\[
\boxed{
\text{PWM switching}
\Rightarrow
\text{time-varying observability}
}
\]

这是 LTV-KF 在该问题中成立且优于静态参数滤波的重要原因。

---

# 22. 采样策略：逐点 KF 与子区间 KF

LTV-KF 有两种实现方式。

---

## 22.1 高频逐点采样

在每个 PWM 周期内采多个 ADC 点。

例如：

\[
N_s=8\sim32
\]

个采样点/周期。

每个小区间：

\[
q_k
\approx
\frac{T_a}{2}
(i_{C,k}+i_{C,k+1})
\]

优点：

- 信息利用充分；
- 动态跟踪快；
- 可直接分析开关子区间。

缺点：

- 对同步误差敏感；
- 对振铃和噪声更敏感；
- 计算量较大。

---

## 22.2 子区间积分采样

每个 PWM 周期只构造两个或四个“有效测量”。

例如：

### OFF 区间

\[
q_{OFF}
=
\int_{OFF}i_1dt
\]

### ON 区间

\[
q_{ON}
=
-\int_{ON}i_2dt
\]

并对端口电压取安全窗口平均/外推值。

优点：

- 抗高频噪声；
- 更适合 MCU/DSP；
- 与理论“edge + ramp”解耦完全一致。

建议第一篇硬件实现优先使用：

\[
\boxed{
\text{switching-synchronous subinterval LTV-KF}
}
\]

而不是盲目追求极高 ADC 采样率。

---

# 23. 过程噪声 \(Q_k\) 的设计

由于：

\[
C_1
\]

和：

\[
r_C
\]

属于缓慢退化参数，其变化时间尺度远慢于：

\[
v_C
\]

因此一般满足：

\[
q_v\gg q_\alpha,\;q_r
\]

可以设：

\[
Q_k
=
\mathrm{diag}
(q_v,q_\alpha,q_r)
\]

其中：

### \(q_v\)

主要吸收：

- 电流积分误差；
- 未建模高频动态；
- 开关死区；
- ADC 同步误差；
- 轻微参数失配。

### \(q_\alpha\)

控制 \(C_1\) 参数允许的跟踪速度。

如果太大：

- \(\hat C_1\) 抖动增加；
- 容易把噪声解释为容量变化。

如果太小：

- 参数切换实验时收敛很慢；
- 无法及时跟踪真实退化。

### \(q_r\)

控制 ESR 的变化速度。

实际老化中：

\[
r_C
\]

一般也非常缓慢，因此真实在线监测时：

\[
q_r
\]

应很小。

但在实验“切换 ESR”验证阶段，可临时放大 \(q_r\) 以展示动态跟踪性能。

---

# 24. 自适应过程噪声设计

固定 \(Q\) 往往难以同时兼顾：

- 稳态低噪声；
- 参数突变快速跟踪。

可以设计：

\[
Q_k=
\begin{cases}
Q_{\mathrm{steady}},&|e_k|<\gamma\\
Q_{\mathrm{fast}},&|e_k|\ge\gamma
\end{cases}
\tag{136}
\]

其中：

\[
Q_{\mathrm{fast}}
>
Q_{\mathrm{steady}}
\]

即检测到创新突然增大时，暂时提高参数过程噪声，让滤波器快速适应。

更平滑的方案：

\[
\boxed{
q_{\alpha,k}
=
q_{\alpha,0}
+
k_\alpha e_k^2
}
\tag{137}
\]

\[
\boxed{
q_{r,k}
=
q_{r,0}
+
k_re_k^2
}
\tag{138}
\]

但第一篇论文不建议让自适应机制过度复杂，可以先使用固定 \(Q\) + parameter-change test。

---

# 25. 测量噪声 \(R_k\) 的设计

如果仅使用：

\[
v_T
\]

作为 KF 观测量，则：

\[
R_k=\sigma_{v_T}^2
\]

但真实开关波形的噪声不是严格平稳白噪声。

靠近开关边沿时通常：

\[
R_{\mathrm{edge}}
>
R_{\mathrm{mid}}
\]

因此可以采用拓扑同步的时变测量噪声：

\[
\boxed{
R_k=
\begin{cases}
R_{\mathrm{edge}},&
t_k\in\mathcal W_{\mathrm{edge}}\\
R_{\mathrm{mid}},&
t_k\in\mathcal W_{\mathrm{stable}}
\end{cases}
}
\tag{139}
\]

其中：

\[
R_{\mathrm{edge}}
\gg
R_{\mathrm{mid}}
\]

如果已经使用边沿外推和安全窗口采样，则可以显著降低：

\[
R_{\mathrm{edge}}
\]

这一设计与实际电力电子开关噪声特性一致。

---

# 26. 把电流测量误差并入 LTV-KF

标准模型默认：

\[
i_C
\]

已知准确。

实际：

\[
\tilde i_C=i_C+n_i
\]

而：

\[
i_C
\]

同时进入：

\[
F_k
\]

中的 \(q_k\) 和：

\[
H_k
\]

中的 \(i_{C,k}\)。

因此电流噪声属于“矩阵不确定性”，严格来说不完全符合标准 KF 假设。

第一阶段可采用一阶等效：

\[
R_{\mathrm{eff}}
=
R_v
+
\hat r_C^2\sigma_i^2
\tag{140}
\]

因为观测方程：

\[
v_T=v_C+r_Ci_C
\]

对电流噪声的敏感度为：

\[
\frac{\partial v_T}{\partial i_C}=r_C
\]

所以：

\[
\boxed{
R_{\mathrm{eff},k}
=
\sigma_v^2
+
\hat r_{C,k}^2\sigma_i^2
}
\tag{141}
\]

同时，\(q_k\) 的积分误差可以通过增加：

\[
q_v
\]

来吸收。

若后续追求更严格的随机建模，可以进一步研究：

- Total Kalman Filter；
- Errors-in-Variables；
- Unscented KF；
- Augmented noise model。

第一篇不必展开。

---

# 27. 参数物理约束与投影

标准 KF 是无约束的，因此数值上可能暂时出现：

\[
\hat\alpha\le0
\]

或：

\[
\hat r_C<0
\]

这在物理上不允许。

定义物理集合：

\[
\Omega=
\left\{
\alpha_{\min}\le\alpha\le\alpha_{\max},
\;
r_{\min}\le r_C\le r_{\max}
\right\}
\tag{142}
\]

每次更新后执行：

\[
\boxed{
\hat x_{k|k}
\leftarrow
\Pi_{\Omega}
(\hat x_{k|k})
}
\tag{143}
\]

例如：

\[
\alpha_{\min}
=
\frac{1}{C_{\max}}
\]

\[
\alpha_{\max}
=
\frac{1}{C_{\min}}
\]

投影后：

\[
\hat C_1=\frac{1}{\hat\alpha}
\]

该方法可称为：

\[
\boxed{
\text{Projected LTV-KF}
}
\]

---

# 28. 参数更新门控

并不是每一个 PWM 周期都适合更新健康参数。

建议定义更新条件：

\[
g_k=
\begin{cases}
1,&\mathcal C_k=\mathrm{true}\\
0,&\text{otherwise}
\end{cases}
\]

其中：

\[
\mathcal C_k:
\]

1. CCM 条件满足：
   \[
   i_1>I_{1,\min},\quad i_2>I_{2,\min}
   \]

2. 有足够边沿激励：
   \[
   |i_1+i_2|>I_{\Sigma,\min}
   \]

3. 有足够电荷：
   \[
   |q_k|>Q_{\min}
   \]

4. 当前不处于明显硬开关振铃窗口；

5. 可观测性条件足够好：
   \[
   \sigma_{\min}(\mathcal O_{k,N})
   >
   \sigma_{\min,th}
   \]

或：

\[
\kappa(\mathcal O_{k,N})
<
\kappa_{\max}
\]

当：

\[
g_k=0
\]

时：

- 仍可更新 \(v_C\)；
- 但冻结 \(\alpha,r_C\)。

这一点对轻载、启动和模式切换尤其重要。

---

# 29. 参数冻结的矩阵实现

若当前不允许健康参数更新，可以把 Kalman 增益的参数分量置零。

令：

\[
K_k=
\begin{bmatrix}
K_v\\
K_\alpha\\
K_r
\end{bmatrix}
\]

当：

\[
g_k=0
\]

时：

\[
\boxed{
K_\alpha=0,\qquad K_r=0
}
\tag{144}
\]

只更新：

\[
v_C
\]

这样可以避免不良工况下参数漂移。

---

# 30. 基于协方差的健康估计置信区间

LTV-KF 相比 RLS 的一个重要优势是直接给出：

\[
P_k
\]

其中：

\[
P_{\alpha\alpha}
\]

和：

\[
P_{rr}
\]

分别对应：

\[
\alpha
\]

和 ESR 的估计不确定度。

有：

\[
\sigma_\alpha
=
\sqrt{P_{\alpha\alpha}}
\]

\[
\sigma_r
=
\sqrt{P_{rr}}
\]

因为：

\[
C_1=\frac{1}{\alpha}
\]

利用一阶误差传播：

\[
\frac{dC}{d\alpha}
=
-\frac{1}{\alpha^2}
\]

所以：

\[
\boxed{
\sigma_C
\approx
\frac{\sigma_\alpha}{\hat\alpha^2}
}
\tag{145}
\]

于是可以输出：

\[
\boxed{
\hat C_1\pm1.96\sigma_C
}
\tag{146}
\]

和：

\[
\boxed{
\hat r_C\pm1.96\sigma_r
}
\tag{147}
\]

作为约 95% 置信区间。

这使健康监测结果从“一个数”升级为：

\[
\boxed{
\text{parameter estimate + uncertainty}
}
\]

这对于实际维护决策非常有价值。

---

# 31. LTV-KF 与 RLS 的理论关系

RLS 和 LTV-KF 并不是两个完全独立的方法。

对于线性参数模型：

\[
z_k=\phi_k^T\theta+\varepsilon_k
\]

若：

- 参数状态满足随机游走；
- 过程噪声为零或很小；
- 测量噪声高斯；

Kalman Filter 与递归最小二乘在数学上具有很强的等价性。

区别在于本文两种建模方式不同：

## RLS

通过端点差分消除：

\[
v_C
\]

直接估计：

\[
\theta=
[\alpha,r_C]^T
\]

模型：

\[
\Delta v_T
=
q\alpha+\Delta i_Cr_C
\]

## LTV-KF

保留：

\[
v_C
\]

并估计：

\[
x=
[v_C,\alpha,r_C]^T
\]

模型：

\[
x_{k+1}=F_kx_k
\]

\[
v_T=H_kx_k
\]

因此：

\[
\boxed{
\text{RLS: parameter-only identification}
}
\]

\[
\boxed{
\text{LTV-KF: joint state-parameter estimation}
}
\]

---

# 32. RLS 与 LTV-KF 的预期优缺点

| 项目 | Topology-RLS | LTV-KF |
|---|---|---|
| 内部电容电压估计 | 不直接提供 | 提供 |
| 参数 C/ESR | 提供 | 提供 |
| 参数协方差 | 可扩展 | 天然提供 |
| 推导复杂度 | 低 | 中 |
| 嵌入式计算量 | 很低 | 低~中 |
| 对模型噪声处理 | 一般 | 更自然 |
| 参数突变跟踪 | 由遗忘因子决定 | 由 Q 决定 |
| 物理约束 | 投影 RLS | 投影 KF |
| 可观测性分析 | rank(\(\Phi\)) | rank(\(\mathcal O\)) |
| 对差分/端点误差 | 较敏感 | 较平滑 |
| 对初值敏感 | 中等 | 可通过 P0 调节 |
| 理论展示价值 | 高 | 很高 |

建议论文中：

\[
\boxed{
\text{RLS 作为低复杂度基线}
}
\]

\[
\boxed{
\text{LTV-KF 作为主估计器}
}
\]

如果实验表明两者精度接近，则反过来也可以：

- RLS 主方法；
- LTV-KF 作为验证与扩展。

---

# 33. 推荐的 LTV-KF 初始化

## 33.1 状态初值

可以用额定值：

\[
\hat C_{1,0}=C_{nom}
\]

\[
\hat r_{C,0}=r_{nom}
\]

因此：

\[
\hat\alpha_0=\frac{1}{C_{nom}}
\]

内部电容电压初值可由稳态关系：

\[
\hat v_{C,0}
\approx
\frac{V_{in}}{1-D}
\tag{148}
\]

或者直接使用：

\[
\hat v_{C,0}
=
v_{T,0}
-
\hat r_{C,0}i_{C,0}
\tag{149}
\]

---

## 33.2 初始协方差

\[
P_0=
\mathrm{diag}
(
\sigma_{v0}^2,
\sigma_{\alpha0}^2,
\sigma_{r0}^2
)
\tag{150}
\]

如果对额定参数比较确信：

\[
\sigma_{\alpha0},\sigma_{r0}
\]

可以较小。

如果希望快速从未知参数收敛：

\[
\sigma_{\alpha0},\sigma_{r0}
\]

设置较大。

---

# 34. 推荐的双时间尺度 LTV-KF

真实健康退化时间尺度远慢于 PWM，因此可以显式做双时间尺度设计。

### 快状态

\[
v_C
\]

每个有效采样点更新。

### 慢参数

\[
\alpha,\quad r_C
\]

每：

\[
M
\]

个 PWM 周期更新一次。

例如：

\[
M=10\sim100
\]

这样：

- 降低参数抖动；
- 降低 MCU 运算负担；
- 更符合真实老化速度。

可称为：

\[
\boxed{
\text{Dual-Time-Scale LTV Kalman Filter}
}
\]

这一命名与本文前面的“双时间尺度物理特征”具有一致性。

---

# 35. 周期级 LTV-KF 模型

如果每个 PWM 周期只进行一次参数更新，可以把整个周期电荷平衡嵌入模型。

由于理想稳态下：

\[
\int_{kT_s}^{(k+1)T_s}i_Cdt\approx0
\]

因此完整周期并不适合估计 \(C_1\)。

所以周期级 KF 不应仅使用“整周期净电荷”，而应至少保留：

\[
q_{OFF}
\]

和：

\[
q_{ON}
\]

两个子区间。

因此一个周期可以执行两个 KF measurement updates：

\[
\boxed{
OFF\ update
\rightarrow
ON\ update
}
\]

这种方式保留了：

\[
+Q
\]

与：

\[
-Q
\]

的参数信息，而不会因整周期电荷平衡相互抵消。

---

# 36. 边沿增强型 LTV-KF

可以进一步利用开关边沿的 ESR 高灵敏特征。

在普通稳定采样点：

\[
H_k=
[1,0,i_{C,k}]
\]

在经过边沿外推后，还可以额外构造“伪测量”：

\[
y_{R,k}
=
v_T^- - v_T^+
\]

模型：

\[
\boxed{
y_{R,k}
=
(i_1+i_2)r_C
+
\nu_{R,k}
}
\tag{151}
\]

对应观测矩阵：

\[
\boxed{
H_{R,k}
=
\begin{bmatrix}
0&0&i_1+i_2
\end{bmatrix}
}
\tag{152}
\]

此伪测量直接只观测 ESR。

类似地，在子区间构造容量伪测量：

\[
y_{C,k}
=
\Delta v_T
-
\hat r_C\Delta i_C
\]

理论上：

\[
y_{C,k}
=
q_k\alpha
+
\nu_{C,k}
\]

对应：

\[
\boxed{
H_{C,k}
=
\begin{bmatrix}
0&q_k&0
\end{bmatrix}
}
\tag{153}
\]

这样就形成一个：

\[
\boxed{
\text{multi-rate / multi-measurement LTV-KF}
}
\]

分别使用：

1. 原始端口电压测量；
2. 边沿 ESR 伪测量；
3. 子区间电荷伪测量。

这一版本可进一步提高参数解耦能力。

第一篇如果实验足够扎实，可以把这个作为增强版算法。

---

# 37. 多测量 LTV-KF 的统一表达

定义测量向量：

\[
Y_k=
\begin{bmatrix}
v_{T,k}\\
\Delta v_{edge,k}\\
\Delta v_{charge,k}
\end{bmatrix}
\tag{154}
\]

则：

\[
\boxed{
Y_k
=
\mathcal H_kx_k+V_k
}
\tag{155}
\]

其中：

\[
\mathcal H_k=
\begin{bmatrix}
1&0&i_{C,k}\\
0&0&i_{1,k}+i_{2,k}\\
0&q_k&0
\end{bmatrix}
\tag{156}
\]

这个矩阵有一个非常漂亮的结构：

\[
\mathcal H_k=
\begin{bmatrix}
\text{state}&0&\text{ESR}\\
0&0&\text{ESR}\\
0&\text{C}&0
\end{bmatrix}
\]

在：

\[
q_k\neq0
\]

和：

\[
i_1+i_2\neq0
\]

时，其列空间天然分离。

这正是前面理论“edge + charge”物理解耦在 Kalman Filter 中的矩阵化表达。

---

# 38. LTV-KF 的论文级伪代码

```text
Algorithm: Topology-Synchronous LTV Kalman Filter

Input:
    PWM state uk
    measured iL1,k, iL2,k
    measured vT,k
    sampling interval Δt

Initialization:
    α0 = 1/Cnom
    r0 = ESRnom
    vC,0 = vT,0 - r0*iC,0
    choose P0, Q, R

For each valid sample k:

1. Reconstruct capacitor current
       iC,k = (1-uk)iL1,k - uk iL2,k

2. Calculate charge increment
       qk = ∫ iC dt
   using trapezoidal or subinterval integration

3. Form LTV state matrix
       Fk = [[1, qk, 0],
             [0, 1,  0],
             [0, 0,  1]]

4. Prediction
       x^- = Fk-1 x^+
       P^- = Fk-1 P^+ Fk-1^T + Q

5. Form observation matrix
       Hk = [1, 0, iC,k]

6. Evaluate update gate
       CCM?
       |qk| > Qmin?
       |iL1+iL2| > Imin?
       observability metric acceptable?

7. Measurement update
       ek = vT,k - Hk x^-
       Sk = Hk P^- Hk^T + R
       Kk = P^- Hk^T Sk^-1
       x^+ = x^- + Kk ek

8. Parameter projection
       αmin <= α <= αmax
       rmin <= r <= rmax

9. Parameter output
       Ĉ1,k = 1/αk
       ESR_hat,k = rk

10. Confidence output
       σC,k ≈ sqrt(Pαα)/αk^2
       σr,k = sqrt(Prr)

End
```

---

# 39. LTV-KF 的仿真验证项目

在原 RLS 验证基础上，应额外增加：

## Test 1：状态估计精度

比较：

\[
\hat v_C
\]

与 Simulink 内部真实：

\[
v_C
\]

计算：

\[
RMSE_{v_C}
\]

---

## Test 2：参数收敛

从错误初值启动，例如：

\[
\hat C_0=0.7C_{true}
\]

\[
\hat r_0=1.5r_{true}
\]

测试收敛。

---

## Test 3：多初值鲁棒性

随机：

\[
C_0
\]

和：

\[
r_0
\]

验证最终估计的一致性。

---

## Test 4：可观测性退化

逐步降低负载：

\[
100\%
\rightarrow
5\%
\]

观察：

\[
\sigma_{\min}(\mathcal O)
\]

与：

\[
P_{\alpha\alpha},P_{rr}
\]

是否同步恶化。

如果理论正确，轻载下：

\[
P_{rr}
\]

应显著增大。

---

## Test 5：参数阶跃

人为切换：

\[
C_1: C_a\rightarrow C_b
\]

和：

\[
r_C:r_a\rightarrow r_b
\]

比较：

- RLS；
- LTV-KF；
- adaptive LTV-KF。

---

## Test 6：噪声敏感性

分别加入：

\[
SNR=20,30,40,50\,dB
\]

比较参数误差。

---

## Test 7：采样相位误差

人为设置 ADC 相对于 PWM：

\[
\Delta t_{sync}
\]

观察 ESR 估计误差。

这是非常重要的工程测试，因为 ESR 边沿信息对时序误差尤其敏感。

---

# 40. LTV-KF 的硬件实现复杂度

状态维数只有：

\[
n=3
\]

观测维数：

\[
m=1
\]

标准 KF 的核心矩阵仅为：

- \(3\times3\)；
- \(1\times3\)；
- 标量创新协方差。

因此实时运算量很低。

对于 Cortex-M4/M7、TI C2000、STM32H7 等 MCU/DSP，一般不存在计算能力瓶颈。

真正困难的部分不是 KF 运算，而是：

1. PWM 同步 ADC；
2. 电容端口电压的共模/差模测量；
3. 边沿振铃抑制；
4. 电流采样误差；
5. 温度补偿；
6. 时序标定。

因此论文中不应把“复杂 Kalman Filter”作为卖点，而应强调：

\[
\boxed{
\text{simple estimator enabled by topology physics}
}
\]

---

# 41. 推荐的论文方法命名

如果最终采用 LTV-KF 作为主算法，可以使用：

### 名称 1

**Topology-Synchronous LTV Kalman Filter**

简称：

\[
\boxed{
TS-LTVKF
}
\]

### 名称 2

**Switching-Embedded LTV Kalman Filter**

\[
\boxed{
SE-LTVKF
}
\]

### 名称 3

如果强调快慢状态：

**Dual-Time-Scale Topology-Synchronous Kalman Filter**

\[
\boxed{
DTS-TSKF
}
\]

第一篇建议使用最朴素、最易理解的：

\[
\boxed{
TS-LTVKF
}
\]

---

# 42. 推荐论文算法对比结构

建议最终至少比较：

1. **Closed-form edge/charge estimator**
2. **Topology-RLS**
3. **Topology-Synchronous LTV-KF**

如果篇幅允许，再加入：

4. conventional EKF；
5. generic capacitor estimator。

最关键的对比不是让 LTV-KF 一定比 RLS 高很多，而是证明：

- RLS 已经说明线性参数模型成立；
- LTV-KF 在噪声、内部状态估计、参数置信区间方面更完整；
- 两者都建立在同一个 topology-embedded physics 上。

---

# 43. LTV-KF 可以形成的独立理论贡献

加入 LTV-KF 后，论文理论贡献可以进一步明确为：

### Contribution A

通过变量变换：

\[
\alpha=1/C_1
\]

把原本含：

\[
1/C_1
\]

的非线性参数问题严格转化为一个：

\[
\boxed{
\text{3-state LTV linear system}
}
\]

因此无需 EKF 线性化。

### Contribution B

证明：

\[
F_k
\]

由子区间电荷：

\[
q_k
\]

调制，而：

\[
H_k
\]

由拓扑重构电流：

\[
i_{C,k}
\]

调制。

因此 PWM 本身周期性改变系统可观测结构。

### Contribution C

给出有限窗口可观测条件：

\[
\boxed{
\mathrm{rank}(\mathcal O_{k,N})=3
}
\]

并将其与：

\[
q_k
\]

及：

\[
i_{C,k}
\]

的物理变化直接联系起来。

### Contribution D

利用：

\[
P_{\alpha\alpha}
\]

与：

\[
P_{rr}
\]

构建在线健康参数置信区间，实现：

\[
\boxed{
\text{SOH estimate + confidence}
}
\]

---

# 44. 建议论文中对 LTV-KF 的核心表述

英文可以写成：

> By parameterizing the capacitance as \(\alpha=1/C_1\), the capacitor-port dynamics become linear with respect to the augmented state \([v_C,\alpha,r_C]^T\). Since the state-transition matrix is modulated by the capacitor charge increment while the observation matrix is modulated by the topology-reconstructed capacitor current, the resulting estimator is a linear time-varying Kalman filter rather than an extended Kalman filter. The inherent bidirectional current commutation of the Ćuk converter periodically excites both matrices, thereby improving finite-window observability of the capacitance and ESR states.

中文：

> 通过定义 \(\alpha=1/C_1\)，能量传递电容端口模型可关于增广状态 \([v_C,\alpha,r_C]^T\) 线性化为严格的线性时变系统。其中状态转移矩阵由电容电荷增量调制，观测矩阵由拓扑重构电容电流调制，因此无需使用扩展 Kalman 滤波。Ćuk 变换器固有的双向电流换相周期性改变状态转移和观测结构，从而提高有限时间窗口内对电容量和 ESR 的可观测性。

---

# 45. LTV-KF 最终推荐结构

第一篇论文建议最终采用：

\[
\boxed{
u,i_1,i_2,v_T
}
\]

作为输入。

先计算：

\[
i_C
=
(1-u)i_1-ui_2
\]

再计算：

\[
q_k=\int i_Cdt
\]

构造：

\[
F_k=
\begin{bmatrix}
1&q_k&0\\
0&1&0\\
0&0&1
\end{bmatrix}
\]

\[
H_k=
\begin{bmatrix}
1&0&i_C
\end{bmatrix}
\]

运行：

\[
\boxed{
\text{Projected Topology-Synchronous LTV-KF}
}
\]

输出：

\[
\boxed{
\hat v_C,\quad
\hat C_1,\quad
\widehat{ESR},\quad
\sigma_C,\quad
\sigma_R
}
\]

这样论文从“参数辨识算法”进一步提升为：

\[
\boxed{
\text{joint state-parameter health observer}
}
\]

这比单纯的 C/ESR RLS 更接近控制理论论文的表达方式。

---

# 46. 为什么不建议第一篇直接使用 PINN/CNN/LSTM

理论上，可以进一步采用 Physics-Informed Neural Network：

\[
\mathcal L
=
\mathcal L_{data}
+
\lambda_0\mathcal L_{u=0}
+
\lambda_1\mathcal L_{u=1}
+
\lambda_c\mathcal L_{continuity}
+
\lambda_p\mathcal L_{parameter}
\]

但是第一篇若直接采用深度模型，有两个问题：

1. 会弱化 Ćuk 拓扑本身的创新；
2. 审稿人可能认为只是把已有电容健康监测算法迁移到新拓扑。

更合理的路线是：

### 第一篇

\[
\boxed{
\text{Topology physics}
+
\text{identifiability}
+
\text{RLS/LTV-KF}
+
\text{hardware}
}
\]

### 第二篇

再扩展到：

\[
\boxed{
\text{Physics-informed learning}
+
\text{temperature}
+
\text{domain adaptation}
+
\text{RUL}
}
\]

---

# 47. 最少传感器方案分析

## 21.1 方案 A：理论基准方案

测量：

\[
v_T,\quad i_1,\quad i_2,\quad u
\]

由：

\[
i_C=(1-u)i_1-ui_2
\]

直接重构电容电流。

优点：

- 理论最干净；
- 不依赖其他元件参数；
- 可直接验证式 (58)、(74)、(77)、(79)。

建议第一阶段仿真和实验必须保留此方案作为 ground truth architecture。

---

## 21.2 方案 B：单侧电感电流 + 电容电压

只使用：

\[
v_T,\quad i_1,\quad u
\]

在 \(u=0\) 的子区间：

\[
i_C=i_1
\]

因此仍可利用：

\[
\Delta v_T
=
\frac{1}{C_1}\int i_1dt
+
r_C\Delta i_1
\tag{110}
\]

理论上即可同时估计 \(C_1\) 与 ESR。

也就是说：

\[
\boxed{
v_T+i_1+u
}
\]

在理想条件下已经可以实现参数辨识。

但由于单个 OFF 子区间很短，\(\Delta i_1\) 和 \(\Delta v_T\) 可能较小，因此数值条件不一定理想。

---

## 21.3 方案 C：去掉专用 \(C_1\) 电压传感器

在 \(u=0\) 时：

\[
v_T
=
V_{in}
-
L_1\frac{di_1}{dt}
\tag{111}
\]

若进一步考虑 \(L_1\) 绕组电阻：

\[
v_T
\approx
V_{in}
-
L_1\dot i_1
-
r_{L1}i_1
-
v_{\text{path}}
\tag{112}
\]

这意味着理论上可以通过：

\[
V_{in},i_1,u
\]

重构 \(v_T\)。

但这一方案会引入：

- 电感值误差；
- 电流求导噪声；
- MOSFET/二极管压降；
- 走线寄生电阻；

因此更适合作为第二阶段的“无专用传感器”扩展，而不是第一篇论文一开始就使用。

---

# 48. 采样与开关同步设计

若要使用式 (74) 的 ESR 边沿特征，直接在开关瞬间采样并不可行，因为实际电路还存在：

- 电容 ESL；
- PCB 寄生电感；
- MOSFET \(C_{oss}\)；
- 二极管结电容；
- 反向恢复；
- EMI 振铃；
- ADC 建立时间。

因此不建议使用“真实瞬时电压尖峰”。

推荐：

## 22.1 边沿外推法

在换相前选择一个安全窗口：

\[
[t_s-\tau_2,\;t_s-\tau_1]
\]

换相后选择：

\[
[t_s+\tau_1,\;t_s+\tau_2]
\]

满足：

\[
\tau_1>\tau_{\text{ring}}
\]

对两侧稳定波形分别线性/低阶拟合：

\[
v_T^-(t)=a_-t+b_-
\]

\[
v_T^+(t)=a_+t+b_+
\]

再外推到：

\[
t=t_s
\]

获得：

\[
\tilde v_T^-
\]

\[
\tilde v_T^+
\]

使用：

\[
\boxed{
\hat r_C
=
\frac{
\tilde v_T^--\tilde v_T^+
}{
\tilde i_1^-+\tilde i_2^+
}
}
\tag{113}
\]

这样可以大幅降低 ESL 和振铃影响。

---

# 49. ESR 边沿估计的误差传播

令：

\[
I_\Sigma=i_1+i_2
\]

\[
\Delta V=v_T^- - v_T^+
\]

则：

\[
r_C=\frac{\Delta V}{I_\Sigma}
\]

一阶误差传播：

\[
\frac{\partial r_C}{\partial \Delta V}
=
\frac{1}{I_\Sigma}
\]

\[
\frac{\partial r_C}{\partial I_\Sigma}
=
-\frac{\Delta V}{I_\Sigma^2}
=
-\frac{r_C}{I_\Sigma}
\]

若两类误差独立：

\[
\boxed{
\sigma_r^2
\approx
\frac{\sigma_V^2}{I_\Sigma^2}
+
\frac{r_C^2\sigma_I^2}{I_\Sigma^2}
}
\tag{114}
\]

因此：

\[
\boxed{
I_\Sigma\rightarrow0
\quad\Rightarrow\quad
\sigma_r\rightarrow\infty
}
\tag{115}
\]

也就是说：

> 轻载下 ESR 估计天然更困难。

因此算法必须设置：

\[
I_\Sigma>I_{\min}
\]

才更新 ESR。

---

# 50. 电容量估计的误差传播

由：

\[
C_1=\frac{Q}{\Delta v_C}
\]

有：

\[
\frac{dC_1}{C_1}
=
\frac{dQ}{Q}
-
\frac{d(\Delta v_C)}{\Delta v_C}
\]

所以近似：

\[
\boxed{
\left(
\frac{\sigma_C}{C_1}
\right)^2
\approx
\left(
\frac{\sigma_Q}{Q}
\right)^2
+
\left(
\frac{\sigma_{\Delta v}}{\Delta v_C}
\right)^2
}
\tag{116}
\]

当：

- \(C_1\) 很大；
- \(f_s\) 很高；
- 负载很轻；

会导致：

\[
\Delta v_C
\]

很小，电容量估计的信噪比下降。

因此可以设计“辨识可信度门控”：

\[
Q>Q_{\min}
\]

\[
|\Delta v_C|>\Delta V_{\min}
\]

\[
\kappa(\Phi^T\Phi)<\kappa_{\max}
\]

只有条件满足时才更新健康参数。

---

# 51. 条件数与在线置信度

定义信息矩阵：

\[
\mathcal I
=
\Phi^TW\Phi
\tag{117}
\]

最小特征值：

\[
\lambda_{\min}(\mathcal I)
\]

可作为可辨识程度指标。

定义条件数：

\[
\kappa
=
\frac{
\lambda_{\max}(\mathcal I)
}{
\lambda_{\min}(\mathcal I)
}
\tag{118}
\]

则：

- \(\lambda_{\min}\) 大：激励充分；
- \(\kappa\) 小：参数解耦良好；
- \(\kappa\) 很大：参数估计病态。

可以设计健康估计可信度：

\[
\boxed{
Conf
=
g(
\lambda_{\min},
\kappa,
I_\Sigma,
Q,
SNR
)
}
\tag{119}
\]

最终系统同时输出：

\[
\hat C_1,\quad \hat r_C,\quad Conf
\]

而不是只输出两个参数值。

---

# 52. 工况变化为什么不应该被误判成老化

传统特征方法常直接使用：

- 输出电压 RMS；
- 输出纹波；
- FFT 峰值；
- 小波能量；
- 峰峰值。

但这些特征会随：

\[
V_{in},D,P_o,T,f_s
\]

显著变化。

本文的关键优势是通过物理归一化消除这些因素。

例如 ESR：

\[
\hat r_C
=
\frac{\Delta v_{edge}}{i_1+i_2}
\]

负载增大时：

\[
\Delta v_{edge}\uparrow
\]

但：

\[
i_1+i_2\uparrow
\]

二者相除后理论上仍回到同一个 \(r_C\)。

对于电容量：

\[
\hat C_1
=
\frac{Q}{\Delta v_C}
\]

工况改变会同时改变 \(Q\) 与 \(\Delta v_C\)，其比值仍对应 \(C_1\)。

因此本文的基本思想是：

\[
\boxed{
\text{Feature normalization by physical law}
}
\]

而不是：

\[
\boxed{
\text{Operating-condition-specific classification}
}
\]

---

# 53. 参数灵敏度分析

电容端口关系：

\[
v_T=v_C+r_Ci_C
\]

\[
\dot v_C=\frac{i_C}{C_1}
\]

在电流波形固定的条件下：

\[
\boxed{
\frac{\partial v_T}{\partial r_C}
=
i_C
}
\tag{120}
\]

\[
\boxed{
\frac{\partial \dot v_C}{\partial C_1}
=
-\frac{i_C}{C_1^2}
}
\tag{121}
\]

换相边沿：

\[
\boxed{
\frac{\partial \Delta v_{edge}}{\partial r_C}
=
i_1+i_2
}
\tag{122}
\]

且一阶近似：

\[
\boxed{
\frac{\partial \Delta v_{edge}}{\partial C_1}
\approx0
}
\tag{123}
\]

子区间扣除 ESR 后：

\[
\Delta v_C=\frac{Q}{C_1}
\]

所以：

\[
\boxed{
\frac{\partial \Delta v_C}{\partial C_1}
=
-\frac{Q}{C_1^2}
}
\tag{124}
\]

而：

\[
\boxed{
\frac{\partial \Delta v_C}{\partial r_C}
=0
}
\tag{125}
\]

这就是前面满秩灵敏度矩阵的来源。

---

# 54. 参数退化的小扰动表达

定义初始健康状态：

\[
C_1=C_0
\]

\[
r_C=r_0
\]

定义归一化退化：

\[
C_1=C_0(1-\delta_C)
\tag{126}
\]

\[
r_C=r_0(1+\delta_R)
\tag{127}
\]

其中：

\[
0\le\delta_C<1
\]

\[
\delta_R\ge0
\]

则：

\[
\frac{1}{C_1}
=
\frac{1}{C_0(1-\delta_C)}
\]

当退化较小时：

\[
\boxed{
\frac{1}{C_1}
\approx
\frac{1}{C_0}(1+\delta_C)
}
\tag{128}
\]

所以电容电压斜率：

\[
\dot v_C
\approx
\frac{i_C}{C_0}(1+\delta_C)
\tag{129}
\]

即：

\[
C_1\downarrow
\Rightarrow
|\dot v_C|\uparrow
\]

同时：

\[
r_C\uparrow
\Rightarrow
|\Delta v_{edge}|\uparrow
\]

因此两种退化在波形上分别表现为：

\[
\boxed{
C_1\downarrow
\Rightarrow
\text{ramp slope 增大}
}
\]

\[
\boxed{
ESR\uparrow
\Rightarrow
\text{edge step 增大}
}
\]

这是论文图形表达中非常重要的一张概念图。

---

# 55. 温度补偿

ESR 不是仅由老化决定，它还显著依赖：

\[
T_C,\quad f
\]

因此论文中应明确：

\[
r_C=r_C(T_C,f_s,\mathrm{aging})
\]

建议将实际估计值归一到参考温度：

\[
\boxed{
r_{ref}
=
\frac{\hat r_C}{g_R(T_C,f_s)}
}
\tag{130}
\]

其中 \(g_R\) 由：

- 器件数据手册；
- 环境箱标定；
- 初始健康样品多温度实验；

得到。

电容量也可写为：

\[
\boxed{
C_{ref}
=
\frac{\hat C_1}{g_C(T_C)}
}
\tag{131}
\]

通常 \(C\) 的温度敏感性小于 ESR，但不能默认忽略。

论文中应区分：

\[
\boxed{
\text{measured ESR}
}
\]

与：

\[
\boxed{
\text{temperature-normalized health ESR}
}
\]

---

# 56. 健康指标构造

定义初始参数：

\[
C_0,\quad r_0
\]

定义寿命终点参考：

\[
C_{EOL},\quad r_{EOL}
\]

这些阈值必须根据具体电容技术和制造商规范确定，不应在理论部分写死为某个统一百分比。

定义电容量退化度：

\[
D_C
=
\mathrm{clip}
\left(
\frac{
C_0-\hat C_{ref}
}{
C_0-C_{EOL}
},
0,1
\right)
\tag{132}
\]

ESR 退化度：

\[
D_R
=
\mathrm{clip}
\left(
\frac{
\hat r_{ref}-r_0
}{
r_{EOL}-r_0
},
0,1
\right)
\tag{133}
\]

可以采用加权健康度：

\[
\boxed{
SOH
=
100\%
\left[
1-
(w_CD_C+w_RD_R)
\right]
}
\tag{134}
\]

其中：

\[
w_C+w_R=1
\]

也可以采用更保守的“短板原则”：

\[
\boxed{
SOH
=
100\%
\left[
1-\max(D_C,D_R)
\right]
}
\tag{135}
\]

第一篇论文建议重点报告：

\[
\hat C_1,\quad \hat r_C
\]

SOH 作为工程展示，不必让 SOH 公式成为论文核心创新。

---

# 57. 从健康监测进一步连接到健康感知控制

一旦获得：

\[
\hat r_C
\]

就可以估计：

\[
\hat P_{ESR}
=
\hat r_C I_{C,\mathrm{rms}}^2
\tag{136}
\]

进一步：

\[
\Delta T_C
\approx
R_{\theta}\hat P_{ESR}
\tag{137}
\]

形成：

\[
\boxed{
(C_1,r_C)
\rightarrow
P_{ESR}
\rightarrow
T_C
\rightarrow
Lifetime
}
\]

后续可以在控制层使用：

\[
J
=
J_{regulation}
+
\lambda_hJ_{health}
\]

例如：

\[
J_{health}
=
I_{C,\mathrm{rms}}^2\hat r_C
\tag{138}
\]

从而在电容老化后主动降低其电流应力。

但该内容建议作为第二篇或第一篇 Discussion/Future Work，而不是抢占主线。

---

# 58. 实际 ESR 频率依赖问题

一阶 ESR 模型中的：

\[
r_C
\]

严格来说应解释为：

\[
\boxed{
r_C(f_s,T_C)
}
\]

即在当前开关频率及其主要谐波附近的等效串联电阻。

若电容类型为：

- 铝电解；
- 聚合物；
- 薄膜；

其频率与温度特性会不同。

因此实验中必须固定或记录：

\[
f_s
\]

若改变 \(f_s\)，应建立：

\[
r_C(f,T)
\]

补偿模型，否则“ESR 变化”可能只是频率变化造成的。

---

# 59. ESL 与开关尖峰的扩展模型

真实电容可以扩展为：

\[
\boxed{
v_T
=
v_C
+
r_Ci_C
+
L_{ESL}\frac{di_C}{dt}
}
\tag{139}
\]

换相瞬间：

\[
\frac{di_C}{dt}
\]

很大，因此 ESL 会产生尖峰。

这说明：

> 不能简单把示波器换相瞬间的最大峰值当成 ESR 压降。

有三个处理方向：

### 方法 1：边沿稳定窗口外推

推荐第一篇采用。

### 方法 2：低通/带限电压重构

去除明显高于有效 ESR 频带的振铃。

### 方法 3：三参数辨识

进一步估计：

\[
C_1,\quad r_C,\quad L_{ESL}
\]

但这会显著增加论文复杂度，建议不作为第一篇主目标。

---

# 60. 其他寄生参数对核心方法的影响

如果直接测量：

\[
v_T,i_1,i_2,u
\]

则核心电容端口关系：

\[
v_T=v_C+r_Ci_C
\]

与：

\[
\dot v_C=i_C/C_1
\]

并不显式包含：

- \(r_{L1}\)；
- \(r_{L2}\)；
- \(r_{DS(on)}\)；
- 二极管导通压降；

这些寄生参数会改变 \(i_1,i_2\) 的实际波形，但如果电流被真实测量，影响已经包含在实测 \(i_C\) 中。

因此：

\[
\boxed{
\text{直接基于 capacitor-port equation 的方法，比完整变换器参数反演更容易解耦寄生参数}
}
\]

这是该理论路线的一项重要工程优势。

只有当我们进一步删除 \(v_T\) 或某个电流传感器，转而通过 KVL/observer 重构这些信号时，其他寄生参数才会显著进入辨识方程。

---

# 61. DCM、轻载与模式变化

当前全部核心推导建立在 CCM 下。

在 DCM 中可能出现：

- \(i_1=0\)；
- \(i_2=0\)；
- 第三拓扑状态；
- 二极管提前关断；
- 电容电流关系改变。

因此第一篇建议明确限定：

\[
\boxed{
\text{CCM operation}
}
\]

并在实验中设置模式检测：

\[
\min(i_1,i_2)>I_{\mathrm{CCM,min}}
\]

只有满足 CCM 条件时更新参数。

后续论文可以研究：

\[
\boxed{
\text{Hybrid CCM/DCM capacitor health observer}
}
\]

这本身也可能形成新的研究点。

---

# 62. 推荐的论文核心方法框架

建议第一篇论文把方法命名为类似：

> **Topology-Synchronous Dual-Time-Scale Estimation**

或者：

> **Switching-Embedded C–ESR Identification**

整体流程：

```text
PWM state u(t)
      │
      ├──────────────┐
      │              │
   iL1(t)          iL2(t)
      │              │
      └──────┬───────┘
             │
             ▼
 iC=(1-u)iL1-u iL2
             │
      ┌──────┴──────────┐
      │                 │
      ▼                 ▼
 switching edge      subinterval
 ΔiC / ΔvT           charge q
      │                 │
      ▼                 ▼
  ESR-sensitive      C-sensitive
    feature            feature
      │                 │
      └──────┬──────────┘
             ▼
    Weighted RLS / LTV-KF
             │
             ▼
       Ĉ1 , ESR_hat
             │
             ▼
 temperature normalization
             │
             ▼
          SOH + confidence
```

---

# 63. 建议论文的三个层次的算法

## Level 1：闭式边沿/斜率估计器

目的：

- 理论解释；
- 展示参数解耦；
- 给 RLS/KF 初始化。

输出：

\[
\hat r_{edge}
\]

\[
\hat C_{OFF}
\]

\[
\hat C_{ON}
\]

---

## Level 2：全窗口积分 RLS

利用：

\[
\Delta v_T
=
q\alpha
+
\Delta i_Cr_C
\]

优点：

- 不求导；
- 可融合多个周期；
- 自动使用边沿与区间信息；
- 易做遗忘因子和置信度。

建议作为第一篇主算法。

---

## Level 3：LTV-KF

状态：

\[
[v_C,\alpha,r_C]^T
\]

优点：

- 输出参数协方差；
- 便于健康置信度；
- 可加入随机游走退化模型；
- 适合以后扩展温度与老化过程模型。

建议作为高阶版本或对比算法。

---

# 64. 论文中建议明确提出的理论贡献

## Contribution 1：Ćuk 特异的电容电流重构

证明：

\[
\boxed{
i_C=(1-u)i_{L1}-ui_{L2}
}
\]

从而不需要专用电容电流传感器。

---

## Contribution 2：PWM 自激励下的双时间尺度参数解耦

证明：

\[
\boxed{
\Delta v_{edge}
=
r_C(i_1+i_2)
}
\]

与：

\[
\boxed{
\Delta v_C
=
Q/C_1
}
\]

分别对应 ESR 与电容量。

---

## Contribution 3：\(C_1\)-ESR 的结构可辨识性证明

利用：

\[
\det J
=
\frac{(i_1+i_2)Q}{C_1^2}
>0
\]

证明在 CCM 和非零能量传递条件下，两个参数局部可辨识。

进一步用：

\[
\mathrm{rank}(\Phi)=2
\]

给出全窗口持续激励条件。

---

## Contribution 4：线性参数化的在线递推估计

引入：

\[
\alpha=1/C_1
\]

把原始非线性参数问题变成：

\[
\Delta v_T
=
q\alpha+\Delta i_Cr_C
\]

可使用低复杂度 RLS 或 LTV-KF。

---

## Contribution 5：工况归一化与在线健康度

通过物理参数而不是原始纹波特征构建 SOH，从机制上减弱：

\[
V_{in},D,P_o
\]

变化造成的误判。

---

# 65. 第一篇论文最重要的实验验证命题

建议不要只报告“准确率”。

必须逐个验证以下理论命题。

## H1：ESR 线性边沿关系

验证：

\[
\Delta v_{edge}
\propto
r_C(i_1+i_2)
\]

对多个：

\[
D,V_{in},P_o,r_C
\]

拟合。

目标：

\[
R^2>0.98
\]

---

## H2：电容量电荷关系

验证：

\[
\Delta v_C
=
Q/C_1
\]

在不同工况下成立。

---

## H3：ESR 与 \(C_1\) 可解耦

固定 \(C_1\)，改变 ESR：

- edge feature 显著变化；
- corrected ramp 基本不变。

固定 ESR，改变 \(C_1\)：

- corrected ramp 显著变化；
- edge feature 基本不变。

这张二维交叉实验图非常重要。

---

## H4：多工况参数不变性

例如：

\[
V_{in}=0.8,1.0,1.2\,pu
\]

\[
P_o=0.1\sim1.0\,pu
\]

\[
D=D_{\min}\sim D_{\max}
\]

理论上估计出的：

\[
\hat C_1,\hat r_C
\]

应该保持一致。

---

## H5：动态跟踪能力

做硬件可切换参数：

\[
C_a\rightarrow C_b
\]

\[
r_a\rightarrow r_b
\]

测试：

- 收敛时间；
- 超调；
- 稳态误差；
- 误检；
- 参数切换瞬态。

---

# 66. 仿真参数扫频/扫工况矩阵建议

至少覆盖：

## 电容量退化

\[
C/C_0=
100\%,95\%,90\%,85\%,80\%
\]

## ESR 退化

\[
r/r_0=
1.0,1.25,1.5,1.75,2.0
\]

形成完整二维组合，而不是分别单独变化。

总组合数：

\[
5\times5=25
\]

再乘：

### 输入电压

\[
V_{in}/V_{nom}=
0.8,1.0,1.2
\]

### 负载

\[
P/P_{nom}=
0.1,0.25,0.5,0.75,1.0
\]

### 温度

例如：

\[
T=
25^\circ C,
45^\circ C,
65^\circ C
\]

基础组合：

\[
25\times3\times5\times3
=
1125
\]

不一定全部做硬件，但可以先在仿真中批量完成。

---

# 67. 硬件退化模拟建议

第一阶段不需要真实老化数千小时。

可以通过：

### 电容量

多个并联/串联可切换电容构造：

\[
C_0,C_1,C_2,\ldots
\]

### ESR

使用低感精密功率电阻：

\[
r_0+\Delta r
\]

模拟：

\[
1.25r_0,\;1.5r_0,\;2r_0
\]

注意额外电阻必须：

- 低 ESL；
- 足够功率；
- Kelvin 测量；
- 温漂可控。

最终再使用真实老化电容做外部验证。

---

# 68. 与已有通用电容方法的理论区别

已有很多电容健康方法已经能够估计：

\[
C,\quad ESR
\]

所以论文不能宣称“首次联合估计 C 和 ESR”。

真正应该强调的是：

\[
\boxed{
\text{Ćuk topology-specific natural bidirectional excitation}
}
\]

具体区别：

1. Ćuk 的 \(C_1\) 不是普通 DC-link/output capacitor，而是能量传递元件；
2. \(i_C\) 在每个周期天然在：
   \[
   +i_{L1}
   \leftrightarrow
   -i_{L2}
   \]
   之间切换；
3. 这种电流反向产生很强的 ESR 边沿激励；
4. 同一周期的子区间又提供 \(C_1\) 的积分电荷信息；
5. 不需要人为注入额外扰动；
6. 可构造拓扑特异的满秩可辨识性证明。

---

# 69. 当前创新边界

当前检索已经发现：

1. 已有针对 Ćuk 变换器参数故障的机器学习分类研究；
2. 通用 DC/DC、Boost、DC-link 电容的 \(C+\mathrm{ESR}\) 在线估计已有大量工作；
3. 2025 年已有利用 PWM 与拓扑交互产生的 inherent signals 进行 DC-link 参数估计的研究；
4. 2025–2026 年 Physics-Informed 参数估计和健康监测已经快速发展。

因此论文应避免以下表述：

> “首次研究 Ćuk 电容故障。”

> “首次在线估计电容 C 和 ESR。”

建议的创新表述方向：

> **A topology-embedded, switching-synchronous C–ESR identification framework is developed specifically for the energy-transfer capacitor of the Ćuk converter. The natural bidirectional capacitor-current commutation is exploited to generate two physically decoupled signatures for ESR and capacitance without external excitation.**

最终是否能使用 “first” 必须在正式投稿前再做系统检索确认。

---

# 70. 推荐论文题目

## 版本 A：最稳健

**Online C–ESR Estimation of the Energy-Transfer Capacitor in Ćuk Converters Using Topology-Synchronous Natural Excitation**

## 版本 B：突出非侵入

**Non-Invasive Health Monitoring of the Energy-Transfer Capacitor in Ćuk Converters via Switching-Embedded C–ESR Identification**

## 版本 C：突出理论

**Topology-Embedded Identifiability and Online Health Estimation of the Energy-Transfer Capacitor in Ćuk Converters**

## 版本 D：如果后面证明最少传感器

**Minimal-Sensing Online C–ESR Identification for the Energy-Transfer Capacitor of Ćuk Converters**

---

# 71. 推荐论文理论章节结构

## II. Modeling and Degradation Mechanism

### A. Switched Model of the Ćuk Converter

推导：

\[
i_C=(1-u)i_1-ui_2
\]

### B. Non-Ideal Energy-Transfer Capacitor Model

推导：

\[
v_T=v_C+r_Ci_C
\]

### C. Degradation Signatures

分析：

\[
C\downarrow
\]

和：

\[
ESR\uparrow
\]

对波形的不同影响。

---

## III. Topology-Embedded C–ESR Identifiability

### A. Switching-Edge ESR Signature

推导：

\[
\Delta v_{edge}=r_C(i_1+i_2)
\]

### B. Charge-Domain Capacitance Signature

推导：

\[
\Delta v_C=Q/C_1
\]

### C. Identifiability Proof

给出：

\[
\det J\neq0
\]

和：

\[
\mathrm{rank}(\Phi)=2
\]

---

## IV. Online Parameter Estimator

### A. Capacitor Current Reconstruction

### B. Integral Regression

### C. Weighted/Projected RLS

### D. Confidence and Update Gating

---

## V. Temperature and Operating-Condition Compensation

---

## VI. Simulation Verification

---

## VII. Experimental Validation

---

# 72. 当前建议优先做的理论仿真

按优先级：

## Task 1：验证式 (73)

在理想 Simulink/PLECS 中输出：

- \(v_C\)；
- \(v_T\)；
- \(i_C\)；
- \(i_1\)；
- \(i_2\)；
- PWM。

验证：

\[
v_T^- -v_T^+
=
r_C(i_1+i_2)
\]

---

## Task 2：验证式 (77)、(79)

分别在两个开关子区间积分。

---

## Task 3：二维参数解耦

构造：

\[
C/C_0
\]

与：

\[
r/r_0
\]

二维矩阵，观察：

- edge feature；
- corrected charge feature。

理想情况下应呈现近似正交变化。

---

## Task 4：计算信息矩阵

在线计算：

\[
\lambda_{\min}(\Phi^T\Phi)
\]

\[
\kappa(\Phi^T\Phi)
\]

寻找最适合辨识的：

\[
D,\;P,\;f_s
\]

区域。

---

## Task 5：加入测量噪声

加入：

- ADC 量化；
- 电压噪声；
- 电流噪声；
- 采样相位误差；

评估理论误差。

---

## Task 6：加入 ESL 和开关振铃

验证边沿外推法能否恢复 ESR。

---

# 73. 可以进一步形成的新理论：辨识友好工作区

因为：

\[
\sigma_r
\propto
\frac{1}{i_1+i_2}
\]

而：

\[
\sigma_C
\propto
\frac{1}{|\Delta v_C|}
\]

可定义辨识性能指标：

\[
J_{id}
=
w_R
\frac{1}{I_\Sigma^2}
+
w_C
\frac{1}{Q^2}
+
w_\kappa\kappa
\tag{140}
\]

寻找：

\[
\boxed{
(D,P,f_s)
}
\]

使：

\[
J_{id}
\]

最小。

这意味着系统可以在正常控制运行中选择更有利于健康估计的数据窗口，而不必持续更新。

例如只在：

- 中高负载；
- 合适占空比；
- CCM；
- 稳定温度；

时更新参数。

这个“**opportunistic identification**”也可以作为论文中的工程增强点。

---

# 74. 理论结论总结

本文推导得到以下关键结果。

### 结论 1

Ćuk 能量传递电容电流可以由拓扑直接重构：

\[
\boxed{
i_C=(1-u)i_{L1}-ui_{L2}
}
\]

### 结论 2

电容健康参数可由统一端口方程描述：

\[
\boxed{
\Delta v_T
=
\frac{q}{C_1}
+
r_C\Delta i_C
}
\]

### 结论 3

换相边沿天然提供 ESR 激励：

\[
\boxed{
\Delta v_{edge}
=
r_C(i_1+i_2)
}
\]

### 结论 4

子区间电荷提供电容量信息：

\[
\boxed{
\Delta v_C
=
Q/C_1
}
\]

### 结论 5

两个特征形成满秩参数灵敏度：

\[
\boxed{
\det J
=
\frac{(i_1+i_2)Q}{C_1^2}
>0
}
\]

因此：

\[
\boxed{
C_1,\;ESR
\text{ 在 CCM 与有效能量传递条件下结构可辨识}
}
\]

### 结论 6

通过：

\[
\alpha=1/C_1
\]

可将问题变为线性参数回归：

\[
\boxed{
z=q\alpha+\Delta i_Cr_C
}
\]

因此可采用：

\[
\boxed{
RLS / WLS / LTV-KF
}
\]

而无需首先采用黑箱机器学习。

---

# 75. 我认为最值得作为论文“核心创新句”的理论表达

> **The energy-transfer capacitor of a Ćuk converter experiences an inherent bidirectional current commutation between \(+i_{L1}\) and \(-i_{L2}\) during every switching cycle. By exploiting the continuity of the internal capacitor voltage and the discontinuity of the ESR voltage drop at topology transitions, ESR-sensitive switching-edge features and capacitance-sensitive charge-domain features can be physically decoupled. This yields a full-rank C–ESR identifiability condition without external signal injection.**

对应中文：

> **Ćuk 变换器能量传递电容在每个开关周期内天然经历由 \(+i_{L1}\) 到 \(-i_{L2}\) 的双向电流换相。利用拓扑切换瞬间理想电容内部电压连续、而 ESR 压降随电流突变的物理特性，可分别构造 ESR 敏感的换相边沿特征和电容量敏感的电荷域特征，从而在无需外部激励的条件下建立满秩的 C–ESR 可辨识关系。**

这应当是第一篇论文的理论主轴。

---

# 76. 下一阶段执行顺序

建议严格按以下顺序推进：

1. **搭建完全理想的开关级 Ćuk 模型；**
2. **只加入 \(C_1\) ESR；**
3. 验证式 (73)、(77)、(79)；
4. 建立积分 WLS/RLS；
5. 做 \(C\)-ESR 二维参数矩阵；
6. 做多输入电压、多负载、多占空比；
7. 再加入 \(L_1/L_2\) ESR 和器件导通损耗；
8. 加入 ADC 与采样误差；
9. 加入 ESL 与开关振铃；
10. 实现边沿外推；
11. 加入温度补偿；
12. 完成实验硬件；
13. 最后再决定是否需要 LTV-KF、MHE 或 Physics-Informed 方法。

如果第 3–6 步不能得到稳定而清晰的参数解耦，则不应继续堆叠复杂 AI；应首先回到采样、可辨识条件或传感器配置重新设计。

---

# 参考文献与检索锚点

> 下列文献用于理论建模、创新边界和方法比较。正式投稿前应重新通过 IEEE Xplore / Scopus / Web of Science 完成系统性检索并统一为目标期刊格式。

1. **Simplified Nonlinear Current-Mode Control of DC-DC Cuk Converter for Low-Cost Industrial Applications.** *Sensors*, 2023.  
   该文给出了经典 Ćuk CCM 的开关模型，并明确将 \(C_1\) 作为 energy transfer capacitor。  
   https://pmc.ncbi.nlm.nih.gov/articles/PMC9919027/

2. **Wang, X.; Qiu, B.; Wang, H. Comparisons of Modeling Methods for Fractional-Order Cuk Converter.** *Electronics*, 2021, 10, 710.  
   DOI: 10.3390/electronics10060710.

3. **Prathiba, R. V.; Saravanan, M. Machine Learning based Parametric Fault Diagnosis of Cuk Converter.** 2023 International Conference on Energy, Materials and Communication Engineering (ICEMCE).  
   DOI: 10.1109/ICEMCE57940.2023.10434223.  
   该文说明“Ćuk 参数故障诊断”本身已经不是空白。

4. **Nathan, L. P. A.; et al. Review of condition monitoring methods for capacitors used in power converters.** *Microelectronics Reliability*, 2023, 145, 115003.  
   DOI: 10.1016/j.microrel.2023.115003.

5. **Online condition monitoring for DC-link capacitors of three-level NPC converters using noninvasive signal injection.** *Computers & Electrical Engineering*, 2024, 119, 109577.  
   DOI: 10.1016/j.compeleceng.2024.109577.

6. **Ribeiro, R. L. A.; de Sousa, R. P. R.; Oliveira, A. C.; Lima, A. M. N.; Han, Q.-L. Online Estimation of DC-link Capacitor Parameters of Three-Level NPC Converters Using Inherent Signals Analysis.** *IEEE/CAA Journal of Automatica Sinica*, 2025, 12(7), 1434–1444.  
   DOI: 10.1109/JAS.2025.125159.  
   该文利用 PWM 与拓扑交互产生的 inherent signals，说明“利用变换器自身激励而非额外注入”是当前明确研究趋势。

7. **Capacitor State Monitoring Based on Haar Wavelet Transform and Enhanced Kalman Filter.** *Electronics*, 2025, 14, 4671.  
   DOI: 10.3390/electronics14234671.  
   该文通过电感电流重构电容电流并联合估计 C 与 ESR，可作为算法对照，但研究对象并非 Ćuk 的能量传递电容。

8. **Xiang, Y.; Lin, H.; Chung, H. S.-H. Extended Physics-Informed Neural Networks for Parameter Identification of Switched Mode Power Converters with Undetermined Topological Durations.** *IEEE Transactions on Power Electronics*, 2025, 40(1), 2235–2247.  
   DOI: 10.1109/TPEL.2024.3481158.

9. **Fassi, Y.; Zhao, S.; Heiries, V.; Boutet, J.; Boisseau, S.; Wang, H. Physics-Informed Simulation-to-Hardware Alignement for DC-Link Capacitor Condition Monitoring.** *IEEE Transactions on Power Electronics*, 2026, 41(7), 11388–11399.  
   DOI: 10.1109/TPEL.2026.3663772.

---

## 文档版本

- 版本：v0.2
- 日期：2026-08-20
- 目标：作为 Ćuk 能量传递电容健康监测论文的理论推导母稿；v0.2 新增完整 LTV-KF 增广状态、有限窗口可观测性、协方差设计、门控与多测量扩展
- 下一步：建立开关级 Simulink/PLECS 模型并逐式验证 Eq. (73)、Eq. (77)、Eq. (79)、Eq. (90) 与积分 RLS。
