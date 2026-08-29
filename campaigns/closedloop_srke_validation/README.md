# closedloop_srke_validation — TS-SRKE 最小闭环验证

回答复审问题："primary realization 为什么没有在闭环下验证？"
两个验证目标：(1) 调节器瞬态不得误触发监督器；(2) 反馈下的健康突变
仍能正常重置并恢复。

## 设计

- 复用 `closedloop_dcm_validation` 的冻结管线：同一 Model-A 逐周期
  RK4 对象、同一离散 PI 调节器（Kp=3e-4, Ki=2.5, 0.5% 占空比量化边界
  行为）、同一 O1 特征构造与有效性门控、同一冻结闭环边沿增益
  k_R^cl = 0.998665（从姊妹 campaign 的 CSV 读取，不重标定）。
- 估计器换为方向式标量 LTV/Joseph 核 + 冻结双时间尺度监督器
  （Q=diag[2e-9,5e-9]、P0_α=0.0144、P0_r=(0.45·r_true)²、NIS 9、
  a_f=1/16、a_s=1/128、τ=2.5、clip 6、warmup/holdoff 32）。
- 盲例（种子 43001–43005，阶跃在第 1500 周期 = 30 ms）：
  CLS-1 额定反馈；CLS-2 1.45× 负载阶跃；CLS-3 16→12 V 基准阶跃；
  CLS-4 r_C→2r_C 突变；CLS-5 C→0.8C 突变。
  CLS-4/5 同时运行无监督母体（同种子同噪声流，仅估计器不同）。

## 冻结结论（2026-08-28）

- CLS-1/2/3：监督器零触发；尾部误差 ≤0.260%；虚假健康峰 ≤0.492%。
- CLS-4：监督器在阶跃后 10 周期（第 1510 周期）触发一次，0.20 ms 整定；
  母体在 1500 周期（30 ms）阶跃后时程内不恢复，尾部 ESR 误差 49.95%
  （经补偿项诱发 7.69% 容值误差）。
- CLS-5：触发一次（第 1512 周期），0.28 ms 整定；母体尾部容值误差 19.70%。
- 每案例单噪声种子；仍为仿真验证。

## 文件

- `scripts/run_srke_closedloop_validation.m` — 运行入口。
- `scripts/simulate_cuk_cycles_srke.m` — 对象+调节器+特征与姊妹
  campaign 相同，估计器为 TS-SRKE（`supervisorEnabled=false` 即母体）。
- `results/tables/table_srke_closedloop.csv` — 指标表（冻结）。
- `results/tables/table_srke_closedloop_history.csv` — 降采样轨迹
  （稿件图 fig_srke_closedloop 的唯一数据源）。
