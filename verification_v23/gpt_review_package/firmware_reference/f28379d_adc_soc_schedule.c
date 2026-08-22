#include "f28379d_health_adc.h"

static const uint32_t kAdcBases[4] = {
    ADCA_BASE, ADCB_BASE, ADCC_BASE, ADCD_BASE
};

static const ADC_Trigger kTriggers[HEALTH_ADC_SOC_COUNT] = {
    ADC_TRIGGER_EPWM4_SOCB, ADC_TRIGGER_EPWM4_SOCB,
    ADC_TRIGGER_EPWM4_SOCB, ADC_TRIGGER_EPWM2_SOCA,
    ADC_TRIGGER_EPWM2_SOCA, ADC_TRIGGER_EPWM2_SOCA,
    ADC_TRIGGER_EPWM2_SOCB, ADC_TRIGGER_EPWM3_SOCA,
    ADC_TRIGGER_EPWM3_SOCB, ADC_TRIGGER_EPWM4_SOCA
};

void f28379d_adc_soc_schedule_init(void)
{
    uint16_t module;
    uint16_t soc;

    for(module = 0U; module < 4U; module++)
    {
        for(soc = 0U; soc < HEALTH_ADC_SOC_COUNT; soc++)
        {
            ADC_setupSOC(kAdcBases[module], (ADC_SOCNumber)soc,
                         kTriggers[soc], ADC_CH_ADCIN2_ADCIN3,
                         HEALTH_ADC_ACQPS);
        }

        /* SOC2 is physically last in the cycle; late ADCINT starts DMA. */
        ADC_setInterruptSource(kAdcBases[module], ADC_INT_NUMBER1,
                               ADC_SOC_NUMBER2);
        ADC_enableContinuousMode(kAdcBases[module], ADC_INT_NUMBER1);
        ADC_clearInterruptStatus(kAdcBases[module], ADC_INT_NUMBER1);
        ADC_clearInterruptOverflowStatus(kAdcBases[module], ADC_INT_NUMBER1);
        ADC_enableInterrupt(kAdcBases[module], ADC_INT_NUMBER1);
    }
}
