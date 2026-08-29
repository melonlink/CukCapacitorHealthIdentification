# Algorithm-selection protocol

- Frozen observation: O1 topology-decoupled C/ESR stream.
- Frozen algorithm SHA-256: `0BE967962E86D0EBB429825A08806E1161FE9697C06E7CC67A9B4BAE52790FD9`.
- M1 forgetting factor: 0.9975.
- Health reporting cadence: 1024 cycles = 0.02048 s.
- Static: inherited 48 cases x 4 noise x 4 skew from v1.2.
- Dynamic: M1/M2/M3 receive the exact same observation struct.
- Main ramps: TRACE_DERIVED_OBSERVATION.
- 0.1 s cross-check and stresses: FULL_SWITCHING_MODEL_A_EQUATIONS.
- FULL_SWITCHING_MODEL_A_EQUATIONS denotes the frozen switching equations, not Simscape.
- Abrupt steps are stress tests; ramps are health-realistic tracking tests.
- M1-M3 carry no adaptive Q or change detector; M4 adds only the
  locked two-time-scale supervisor above. No estimator retuning or
  weighted score anywhere.
