#include <math.h>
#include <stdint.h>

#define HEALTH_FRAME_CYCLES 1024U

typedef struct
{
    float deltaVC[HEALTH_FRAME_CYCLES];
    float chargeC[HEALTH_FRAME_CYCLES];
    float deltaVEdge[HEALTH_FRAME_CYCLES];
    float currentSum[HEALTH_FRAME_CYCLES];
} HealthFeatureFrame;

typedef struct
{
    float C;
    float ESR;
    float covarianceC;
    float covarianceESR;
} HealthEstimatorState;

typedef struct
{
    float C;
    float ESR;
    float nisC;
    float nisESR;
    uint16_t acceptedCycles;
} HealthEstimate;

static float project(float x, float low, float high)
{
    return fminf(high, fmaxf(low, x));
}

void ts_sltvke_step(HealthEstimatorState *state,
                    const HealthFeatureFrame *frame,
                    HealthEstimate *output)
{
    uint16_t k;
    uint16_t accepted = 0U;
    float cSum = 0.0F;
    float rSum = 0.0F;
    float cM2 = 0.0F;
    float rM2 = 0.0F;

    for(k = 0U; k < HEALTH_FRAME_CYCLES; k++)
    {
        if((fabsf(frame->deltaVC[k]) > 1.0e-6F) &&
           (fabsf(frame->currentSum[k]) > 1.0e-3F))
        {
            float c = fabsf(frame->chargeC[k] / frame->deltaVC[k]);
            float r = fabsf(frame->deltaVEdge[k] / frame->currentSum[k]);
            float dc;
            float dr;
            accepted++;
            dc = c - cSum / (float)accepted;
            cSum += c;
            cM2 += dc * (c - cSum / (float)accepted);
            dr = r - rSum / (float)accepted;
            rSum += r;
            rM2 += dr * (r - rSum / (float)accepted);
        }
    }

    if(accepted > 1U)
    {
        float zC = cSum / (float)accepted;
        float zR = rSum / (float)accepted;
        float measurementC = fmaxf(cM2 / ((float)accepted - 1.0F), 1.0e-14F);
        float measurementR = fmaxf(rM2 / ((float)accepted - 1.0F), 1.0e-10F);
        float innovationC = zC - state->C;
        float innovationR = zR - state->ESR;
        float innovationCovC = state->covarianceC + measurementC;
        float innovationCovR = state->covarianceESR + measurementR;
        float gainC = state->covarianceC / innovationCovC;
        float gainR = state->covarianceESR / innovationCovR;
        output->nisC = innovationC * innovationC / innovationCovC;
        output->nisESR = innovationR * innovationR / innovationCovR;
        if((output->nisC < 9.0F) && (output->nisESR < 9.0F))
        {
            state->C = project(state->C + gainC * innovationC, 50.0e-6F, 150.0e-6F);
            state->ESR = project(state->ESR + gainR * innovationR, 10.0e-3F, 200.0e-3F);
            state->covarianceC *= (1.0F - gainC);
            state->covarianceESR *= (1.0F - gainR);
        }
    }
    output->C = state->C;
    output->ESR = state->ESR;
    output->acceptedCycles = accepted;
}
