
export interface SafetyIndicators {
  lightingScore: number | null;
  activityScore: number | null;
  infrastructureScore: number | null;
  incidentScore: number | null;
}

const weights = {
  lightingScore: 30,
  activityScore: 20,
  infrastructureScore: 25,
  incidentScore: 25,
} as const;

export function calculateSafetyScore(
  indicators: SafetyIndicators,
) {
  let availableWeight = 0;
  let weightedTotal = 0;

  for (const key of Object.keys(weights) as
    (keyof SafetyIndicators)[]) {
    const value = indicators[key];

    // Missing data is unknown, not zero or automatically safe.
    if (value === null) continue;

    if (!Number.isFinite(value) || value < 0 || value > 100) {
      throw new Error(`${key} must be between 0 and 100`);
    }

    weightedTotal += value * weights[key];
    availableWeight += weights[key];
  }

  if (availableWeight === 0) {
    return {
      score: null,
      status: "insufficient_data",
      coveragePercent: 0,
      message: "Insufficient verified safety data.",
    };
  }

  return {
    // Provisional score based only on available indicators.
    score: Math.round(weightedTotal / availableWeight),
    status: availableWeight === 100
      ? "provisional"
      : "incomplete_data",
    coveragePercent: availableWeight,
    message: "Provisional indicator score, not a guarantee of safety.",
  };
}
