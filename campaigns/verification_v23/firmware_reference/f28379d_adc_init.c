#include "f28379d_health_adc.h"

static const uint32_t kAdcBases[4] = {
    ADCA_BASE, ADCB_BASE, ADCC_BASE, ADCD_BASE
};

void f28379d_adc_init(void)
{
    uint16_t module;

    /* ADC_setMode is mandatory after startup: it loads mode-specific trims. */
    for(module = 0U; module < 4U; module++)
    {
        ADC_setPrescaler(kAdcBases[module], ADC_CLK_DIV_4_0);
        ADC_setMode(kAdcBases[module], ADC_RESOLUTION_16BIT,
                    ADC_MODE_DIFFERENTIAL);
        ADC_setInterruptPulseMode(kAdcBases[module], ADC_PULSE_END_OF_CONV);
        ADC_setSOCPriority(kAdcBases[module], ADC_PRI_ALL_ROUND_ROBIN);
        ADC_enableConverter(kAdcBases[module]);
    }

    DEVICE_DELAY_US(1000U);
    f28379d_adc_soc_schedule_init();
}
