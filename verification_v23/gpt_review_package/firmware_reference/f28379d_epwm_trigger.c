#include "f28379d_health_adc.h"

static uint16_t duty_to_count(float duty)
{
    float limited = duty;
    if(limited < 0.25F) { limited = 0.25F; }
    if(limited > 0.65F) { limited = 0.65F; }
    return (uint16_t)(limited * 2000.0F + 0.5F);
}

static void configure_trigger_timer(uint32_t base)
{
    EPWM_setClockPrescaler(base, EPWM_CLOCK_DIVIDER_1,
                           EPWM_HSCLOCK_DIVIDER_1);
    EPWM_setTimeBasePeriod(base, HEALTH_TBPRD);
    EPWM_setTimeBaseCounter(base, 0U);
    EPWM_setTimeBaseCounterMode(base, EPWM_COUNTER_MODE_UP);
    EPWM_enablePhaseShiftLoad(base);
    EPWM_setPhaseShift(base, 0U);
    EPWM_setCountModeAfterSync(base, EPWM_COUNT_MODE_UP_AFTER_SYNC);
}

static void configure_soc_pair(uint32_t base)
{
    EPWM_setADCTriggerSource(base, EPWM_SOC_A, EPWM_SOC_TBCTR_U_CMPA);
    EPWM_setADCTriggerSource(base, EPWM_SOC_B, EPWM_SOC_TBCTR_U_CMPB);
    EPWM_setADCTriggerEventPrescale(base, EPWM_SOC_A, 1U);
    EPWM_setADCTriggerEventPrescale(base, EPWM_SOC_B, 1U);
    EPWM_enableADCTrigger(base, EPWM_SOC_A);
    EPWM_enableADCTrigger(base, EPWM_SOC_B);
}

void f28379d_epwm_set_duty(float duty)
{
    uint16_t edge = duty_to_count(duty);
    EPWM_setCounterCompareValue(EPWM1_BASE, EPWM_COUNTER_COMPARE_A, edge);
    EPWM_setCounterCompareValue(EPWM3_BASE, EPWM_COUNTER_COMPARE_A,
                                (uint16_t)(edge - 80U));
    EPWM_setCounterCompareValue(EPWM3_BASE, EPWM_COUNTER_COMPARE_B,
                                (uint16_t)(edge + 80U));
}

void f28379d_epwm_trigger_init(float duty)
{
    SysCtl_disablePeripheral(SYSCTL_PERIPH_CLK_TBCLKSYNC);
    SysCtl_setEPWMClockDivider(SYSCTL_EPWMCLK_DIV_2);

    configure_trigger_timer(EPWM1_BASE);
    configure_trigger_timer(EPWM2_BASE);
    configure_trigger_timer(EPWM3_BASE);
    configure_trigger_timer(EPWM4_BASE);

    EPWM_setSyncOutPulseMode(EPWM1_BASE,
                             EPWM_SYNC_OUT_PULSE_ON_COUNTER_ZERO);
    EPWM_disablePhaseShiftLoad(EPWM1_BASE);
    EPWM_setActionQualifierAction(EPWM1_BASE, EPWM_AQ_OUTPUT_A,
        EPWM_AQ_OUTPUT_HIGH, EPWM_AQ_OUTPUT_ON_TIMEBASE_ZERO);
    EPWM_setActionQualifierAction(EPWM1_BASE, EPWM_AQ_OUTPUT_A,
        EPWM_AQ_OUTPUT_LOW, EPWM_AQ_OUTPUT_ON_TIMEBASE_UP_CMPA);

    EPWM_setCounterCompareValue(EPWM2_BASE, EPWM_COUNTER_COMPARE_A,
                                HEALTH_EPWM2_POST_CMPA);
    EPWM_setCounterCompareValue(EPWM2_BASE, EPWM_COUNTER_COMPARE_B,
                                HEALTH_EPWM2_C_ON_CMPB);
    EPWM_setCounterCompareValue(EPWM4_BASE, EPWM_COUNTER_COMPARE_A,
                                HEALTH_EPWM4_C_OFF_CMPA);
    EPWM_setCounterCompareValue(EPWM4_BASE, EPWM_COUNTER_COMPARE_B,
                                HEALTH_EPWM4_PRE_CMPB);
    f28379d_epwm_set_duty(duty);

    configure_soc_pair(EPWM2_BASE);
    configure_soc_pair(EPWM3_BASE);
    configure_soc_pair(EPWM4_BASE);
    SysCtl_enablePeripheral(SYSCTL_PERIPH_CLK_TBCLKSYNC);
}
