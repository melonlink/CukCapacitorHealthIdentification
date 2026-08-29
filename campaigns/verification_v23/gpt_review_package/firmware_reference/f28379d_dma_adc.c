#include "f28379d_health_adc.h"

#pragma DATA_SECTION(gHealthAdcA, "ramgs0");
#pragma DATA_SECTION(gHealthAdcB, "ramgs1");
#pragma DATA_SECTION(gHealthAdcC, "ramgs2");
#pragma DATA_SECTION(gHealthAdcD, "ramgs3");
volatile uint16_t gHealthAdcA[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
volatile uint16_t gHealthAdcB[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
volatile uint16_t gHealthAdcC[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];
volatile uint16_t gHealthAdcD[HEALTH_FRAME_CYCLES][HEALTH_ADC_SOC_COUNT];

static void configure_channel(uint32_t channelBase, DMA_Trigger trigger,
                              volatile uint16_t *destination,
                              uint32_t resultBase)
{
    DMA_configAddresses(channelBase, (const void *)destination,
                        (const void *)resultBase);
    DMA_configBurst(channelBase, HEALTH_ADC_SOC_COUNT, 1, 1);
    /* After RESULT9, return the source to RESULT0 and advance destination. */
    DMA_configTransfer(channelBase, HEALTH_FRAME_CYCLES,
                       -(int16_t)(HEALTH_ADC_SOC_COUNT - 1U), 1);
    DMA_configWrap(channelBase, 0xFFFFU, 0, 0xFFFFU, 0);
    DMA_configMode(channelBase, trigger,
                   DMA_CFG_ONESHOT_DISABLE |
                   DMA_CFG_CONTINUOUS_DISABLE |
                   DMA_CFG_SIZE_16BIT);
    DMA_setInterruptMode(channelBase, DMA_INT_AT_END);
    DMA_enableInterrupt(channelBase);
    DMA_enableOverrunInterrupt(channelBase);
    DMA_enableTrigger(channelBase);
    DMA_startChannel(channelBase);
}

void f28379d_dma_adc_init(void)
{
    DMA_initController();
    DMA_setEmulationMode(DMA_EMULATION_STOP);
    configure_channel(DMA_CH1_BASE, DMA_TRIGGER_ADCA1, &gHealthAdcA[0][0],
                      ADCARESULT_BASE);
    configure_channel(DMA_CH2_BASE, DMA_TRIGGER_ADCB1, &gHealthAdcB[0][0],
                      ADCBRESULT_BASE);
    configure_channel(DMA_CH3_BASE, DMA_TRIGGER_ADCC1, &gHealthAdcC[0][0],
                      ADCCRESULT_BASE);
    configure_channel(DMA_CH4_BASE, DMA_TRIGGER_ADCD1, &gHealthAdcD[0][0],
                      ADCDRESULT_BASE);
}
