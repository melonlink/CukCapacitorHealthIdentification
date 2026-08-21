# Independent Theory Check

## Definitions and sign convention

The check uses the task-book convention: `u=1` denotes the main switch ON,
`i1` and `i2` are positive CCM inductor-current magnitudes, `vC` is the ideal
capacitor voltage, `vT` is the voltage across the series C-ESR component, and
`vo` is the positive magnitude of the inverting output voltage.

During the OFF state the transfer-capacitor branch carries `+i1`; during the
ON state it carries `-i2`. Therefore

\[
i_C=(1-u)i_1-ui_2.
\]

With a passive-sign ESR definition, `vT=vC+rC*iC`, and charge conservation
gives `dvC/dt=iC/C1`. These establish T1-T3 without using a converter KVL.

## State equations

For `u=1`, substituting `iC=-i2` into the capacitor-port equation gives
`vT=vC-rC*i2`. The input inductor is connected to the input source and the
second inductor is driven by `vT-vo`, yielding T4-T7.

For `u=0`, substituting `iC=i1` gives `vT=vC+rC*i1`. The first inductor is
driven by `Vin-vT`; the second inductor freewheels against the output voltage,
yielding T8-T11. Under the stated polarity convention all signs in T4-T11 are
internally consistent.

## Edge and charge relations

At a 0-to-1 transition the ideal capacitor voltage and both inductor currents
are continuous, whereas capacitor branch current changes from `+i1` to
`-i2`. The same-time left and right limits are

\[
v_T^-=v_C+r_Ci_1,\qquad v_T^+=v_C-r_Ci_2,
\]

so `vT_minus-vT_plus=rC*(i1+i2)` (T13). T15 and T16 follow by integrating
`dvC/dt=i1/C1` in OFF and `dvC/dt=-i2/C1` in ON, respectively, after removing
the ESR voltage from the terminal measurement.

For any window with constant C and ESR,

\[
\Delta v_T=\Delta v_C+r_C\Delta i_C
            =q(1/C_1)+r_C\Delta i_C,
\]

which is T17. Mixing finite-charge subinterval rows with zero-charge edge rows
produces two non-collinear regressor directions in CCM, so rank two is expected
unless current/charge excitation collapses.

## Independent assessment before simulation

T1-T17 are algebraically consistent under the task's explicit polarities.
This is not evidence that the selected physical circuit uses the same sensor
polarities; Model B must still check that independently. ESL invalidates an
instantaneous ESR-only edge measurement because it adds
`LESL*diC/dt`; temperature and frequency also make the identified ESR an
operating-point equivalent rather than an aging-only quantity.

