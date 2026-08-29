# V1–V2 Comparison

## 1. v1 的 20 ns cliff 到底是什么？

结论：**sample association artifact 与 parameter projection artifact 的组合，主因是前者，不是 physical timing limit。**

在复现的细密扫描中，±2 ns、±4 ns 仍保持正确的 PWM 状态配对；到 ±10 ns 时整数源样本索引改变，pre/post 两点落入同一 PWM 状态，原始 ESR 误差从 0.1535% 跳到约 100%。全部 15 个偏移的 `rank(Phi)` 始终为 2，因此结构可辨识性没有消失。参数投影把已经错误的原始结果显示成固定的 90% ESR 误差平台；最大投影前/后 ESR MAPE 分别为 99.4744%/90%。详细证据见 `BASELINE_REPRODUCTION.md` 和 `table_v1_edge_assignment_diagnostics.csv`。

## 2. v2 是否消除了 cliff？

是，**在支持范围内消除了无物理解释的瞬时断崖**。timestamped linear extrapolation 的 ESR MAPE 随 common PWM timestamp offset 连续变化：0 ns 为 0.0946%，±50 ns 约 0.83%–1.03%，±100 ns 约 1.88%–2.08%，±200 ns 约 3.97%–4.17%；到 ±500 ns 才跨过 5% 目标。robust polynomial 在 ±200 ns 内相近，没有稳定优于线性法，因此最终采用线性外推。

v2 并未把任意偏移都变成可用：±500 ns 时边沿外推与安全电荷窗口开始跨越不适合的波形区间，误差快速但可解释地增加；±1 µs 明确失败。这是窗口/波形模型边界，不再是单一样本索引翻转。

## 3. 真正可支持的 timing tolerance 是多少？

- **Common PWM timestamp offset**：Model A 在 ±200 ns 内 C<3%、ESR<5%；±500 ns 失败。
- **Channel skew**：单电压通道在 ±200 ns 内通过，±500 ns 起失败；单个 i1 或 i2 通道在测试到 ±1 µs 时仍通过。电压与电流相反方向的组合是主导风险。±1 µs 三通道 LHS 的总体通过率仅 23%，所以不能把单电流通道结果外推为三通道容差。
- **Random jitter**：common、independent、PWM 三种模式在 ≤100 ns RMS 的 50-seed 测试中均 100% 通过；200 ns RMS 为 98%–100%；500 ns RMS 仅 46%–74%。工程推荐仍取 ≤50 ns RMS，以保留 ESL/前端裕量。
- **Analog group delay**：一阶 matched front end 在 1 MHz 与 2 MHz 截止频率通过；100/250/500 kHz 失败。电压通道至少 1 MHz 是本模型中更强的限制；数字时间戳不能消除幅相失真，必须标定群延迟并在需要时反卷积。

因此 v2 达到任务书的 Preferred timing 级别，但没有可靠达到 ±500 ns Stretch 级别。

## 4. ADC 最低要求是否改变？

改变。结论不再是“16-bit、16 points/cycle 首次通过”。在 16 个未知 sampling phase 上：

- 12-bit 的所有 samples/cycle 配置通过率仅 0%–25%；
- 14-bit 的 8、12、16、24、32 samples/cycle 全部为 100% phase pass；
- 16-bit 的全部测试配置也为 100% phase pass。

因此在**只含量化与相位扫描**的 Model A 证据下，最低支持配置为 14-bit、8 samples/cycle（400 kS/s@50 kHz）。这不是最终硬件推荐：考虑模拟噪声、前端和时序联合裕量，建议实物使用 16-bit、至少 16 samples/cycle，并优先同步采样。

## 5. ESL + timing 联合下是否仍可估计 ESR？

结论是**部分支持，模型间存在必须保留的差异**。

- 独立 Simscape Model B：1 nH nominal 的 C/ESR MAPE 为 0.00119%/0.0611%；20 nH + 200 ns opposed delay + 20 ns RMS jitter 为 0.0384%/4.257%，通过；20 nH + 500 ns + 50 ns RMS jitter 为 0.2508%/11.025%，失败。
- Model A 的解析 ESL/ringing 注入在 5 nH 起就使多数 C/ESR 结果失败，Stress A/B/C 的 20-seed 通过率均为 0%。这些失败的投影前极值已经保留，不能用限幅值解释成稳定估计。

Model B 支持 Preferred 点，但 Model A 的激进振铃模型不支持。当前证据只允许声称“在物理 Simscape Model B 的 20 nH、200 ns、20 ns RMS 点可估计”，不能声称对所有寄生振铃都鲁棒。

## 6. 归一化后的可观测性最差工况是什么？

全部 64 个归一化观测矩阵行的 rank 均为 3。最大 condition number 为约 2282，出现在 mid-load、3-cycle、stable-only；该行最小奇异值为约 0.0876。全表最小奇异值约 0.0592，condition number 范围约 557–2282。结果表明满秩成立，但短窗口和仅 stable observation 的数值信息较弱，不能只用 `rank(O)=3` 宣称估计质量。

## 7. C pseudo / ESR pseudo 各自增加多少信息？

在 nominal、20-cycle 窗口中，归一化 information minimum eigenvalue 从 stable-only 的约 2.0094e5 变为：

- +C pseudo：约 2.0107e5，增加约 0.06%；
- +ESR pseudo：约 2.2882e5，增加约 13.9%；
- full TR：约 2.2898e5，增加约 14.0%。

C pseudo 对全局最小特征值增量小，但它直接约束 alpha 方向，并使 C 不依赖边沿样本；ESR pseudo 对最弱信息方向的改善更明显。两者的价值不能只由一个标量增幅判断，应结合方向性和多速率解耦解释。

## 8. 协方差机制是否实现跨工况泛化？

是，但属于**保守泛化**。Q/R 只由 nominal、high-D、noisy 三个训练集确定一次：`R_V=2.9521e-6`、`R_C floor=5.3297e-6`、`R_R floor=7.8075e-6`，健康参数过程噪声为 1e-10，NIS gates 均为 9。`Q_vC=5.032e-6` 由训练集一步传播残差的 97.5th percentile 锁定，用于覆盖跨开关点的离散传播误差。

51 个 blind CCM 工况没有逐点调参并全部通过。跨工况的 median NIS p95 约为 V=1.215、C=0.00107、R=0.0147；C/R 通道明显保守。V 通道平均 rejection fraction 约 11.1%，最坏个别工况更高；C/R 平均约 1.1%。因此机制避免了 v1 的过度自信，但下一轮应按测量类型进一步分解模型误差和传感器噪声，而不是继续增大统一 floor。

## 9. v2 是否值得替代 v1 算法？

值得替代作为**后续硬件实验的主候选算法**。v2 去掉了对相邻边沿样本的依赖，明确分离 C 安全窗口电荷观测和 ESR 时间戳边沿观测，能处理异步更新，并在 51 个 CCM 工况中保持 100% 通过：C median/max MAPE=0.000914%/0.0661%，ESR median/max=0.143%/1.227%。CCM→DCM→CCM 中 DCM 段参数跨度约 C=0.000733%、ESR=0.120%，恢复 CCM 后重新更新。

替代的范围应写清：v2 是仿真与实物验证候选，不是已经完成硬件确认的生产算法；ESL/ringing 与前端模型差异仍需实验解决。

## 10. 论文主张应该如何更新？

建议把主张从“相邻边沿采样可在线辨识 C–ESR，时序必须小于 20 ns”改为：

> A timestamp-aware, multi-rate topology-synchronous LTV Kalman framework separates safe-window charge information for capacitance from window-extrapolated switching-edge information for ESR, retaining full normalized observability and sub-target error across blind CCM conditions under calibrated sub-200-ns channel timing and phase-independent ADC sampling in simulation.

同时必须附加限制：Simscape Model B 支持 20 nH/200 ns/20 ns RMS 压力点，但 Model A 的激进振铃注入不支持同一泛化主张；进入实物前需要同步采样、前端传递函数标定和受控寄生参数实验。
