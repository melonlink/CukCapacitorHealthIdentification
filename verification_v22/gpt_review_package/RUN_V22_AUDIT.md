# Run v2.2 Audit

- MATLAB: R2023b Update 1, direct MCP session
- Model: `cuk_simscape_circuit_model_v2.slx`
- Structural model check: healthy
- Model B baselines: 4/4 CCM; low-margin point corrected to Rload=30 Ω
- Target DSP search: no part number found; `TARGET_DSP_NOT_FIXED`
- Parameterized profile rows: 4
- Health budget rows: 36
- Geometry rows / selected modes: 960 / 8
- ADC code-utilization rows: 432
- Nonideal sensitivity rows: 29
- Multi-cycle rows: 324
- kR robustness rows: 1296
- Blind ADC/path rows: 216
- Mandatory tables: 12
- Mandatory figures: 12 PNG plus 12 FIG
- Native 12-bit V2 blind point-accuracy pass: 27.8%
- Native 16-bit V2 blind point-accuracy pass: 100%
- Final decision: `NATIVE_HIGH_RESOLUTION_MODE_REQUIRED`
- Statistical confidence: PARTIAL

- Code Analyzer: 8/8 authored MATLAB files, zero issues
- Output audit: PASS
- Class-based MATLAB tests: 5 passed, 0 failed, 0 incomplete
