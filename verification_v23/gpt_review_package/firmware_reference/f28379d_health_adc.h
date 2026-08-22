#ifndef F28379D_HEALTH_ADC_H
#define F28379D_HEALTH_ADC_H

#include <stdint.h>
#include "driverlib.h"
#include "device.h"

#define HEALTH_ADC_ACQPS             63U
#define HEALTH_ADC_SOC_COUNT         10U
#define HEALTH_FRAME_CYCLES          1024U
#define HEALTH_TBPRD                 1999U
#define HEALTH_EPWM2_POST_CMPA       50U
#define HEALTH_EPWM2_C_ON_CMPB       350U
#define HEALTH_EPWM4_C_OFF_CMPA      1650U
#define HEALTH_EPWM4_PRE_CMPB        1730U

extern volatile uint16_t gHealthAdcA[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
extern volatile uint16_t gHealthAdcB[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
extern volatile uint16_t gHealthAdcC[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
extern volatile uint16_t gHealthAdcD[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];

void f28379d_adc_init(void);
void f28379d_adc_soc_schedule_init(void);
void f28379d_epwm_trigger_init(float duty);
void f28379d_epwm_set_duty(float duty);
void f28379d_dma_adc_init(void);

#endif
