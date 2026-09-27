function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}
function round100(value) {
  return Math.round(value / 100) * 100;
}
function addRule(rules, key, multiplier, reason) {
  if (multiplier !== 1) rules.push({ key, multiplier, reason });
}

/**
 * Deterministic pricing recommendation.
 * PMS owns inventory/booking. This engine only recommends a selling rate.
 */
export function calculateRoomRate(input) {
  const {
    baseRate, minRate, maxRate,
    occupancyPct=0, daysBeforeCheckIn=30,
    isWeekend=false, seasonMultiplier=1, eventMultiplier=1,
    bookingPaceMultiplier=1, competitorMedianRate=null,
    competitorWeight=0, demandIndex=1
  } = input;

  if (!(baseRate>0) || !(minRate>0) || !(maxRate>=minRate)) {
    throw new Error("Invalid rate limits");
  }

  let multiplier=1;
  const rules=[];

  if (occupancyPct>=95) { multiplier*=1.40; addRule(rules,"occupancy_95",1.40,"Critical occupancy"); }
  else if (occupancyPct>=85) { multiplier*=1.28; addRule(rules,"occupancy_85",1.28,"Very high occupancy"); }
  else if (occupancyPct>=75) { multiplier*=1.18; addRule(rules,"occupancy_75",1.18,"High occupancy"); }
  else if (occupancyPct>=60) { multiplier*=1.10; addRule(rules,"occupancy_60",1.10,"Healthy occupancy"); }
  else if (occupancyPct<30) { multiplier*=0.90; addRule(rules,"occupancy_low",0.90,"Low occupancy"); }

  if (daysBeforeCheckIn<=2) { multiplier*=1.12; addRule(rules,"lead_2d",1.12,"Last-minute demand"); }
  else if (daysBeforeCheckIn<=7) { multiplier*=1.06; addRule(rules,"lead_7d",1.06,"Near-term booking"); }
  else if (daysBeforeCheckIn>=45) { multiplier*=0.95; addRule(rules,"lead_45d",0.95,"Long lead-time incentive"); }

  if (isWeekend) { multiplier*=1.08; addRule(rules,"weekend",1.08,"Weekend demand"); }
  if (seasonMultiplier!==1) { multiplier*=seasonMultiplier; addRule(rules,"season",seasonMultiplier,"Season rule"); }
  if (eventMultiplier!==1) { multiplier*=eventMultiplier; addRule(rules,"event",eventMultiplier,"Event/festival demand"); }
  if (bookingPaceMultiplier!==1) { multiplier*=bookingPaceMultiplier; addRule(rules,"pace",bookingPaceMultiplier,"Booking pickup pace"); }

  if (demandIndex!==1) { multiplier*=demandIndex; addRule(rules,"demand_index",demandIndex,"Demand index"); }

  let raw=baseRate*multiplier;
  if (competitorMedianRate && competitorWeight>0) {
    const weighted = (raw*(1-competitorWeight)) + (competitorMedianRate*competitorWeight);
    raw=weighted;
    rules.push({key:"competitor_weight",multiplier:competitorWeight,reason:"Competitor median weighted into recommendation"});
  }

  const unclamped=round100(raw);
  const finalRate=clamp(unclamped,minRate,maxRate);

  return {
    baseRate, multiplier:Number(multiplier.toFixed(4)),
    rawRecommendedRate:unclamped, finalRate,
    clamped:finalRate!==unclamped,
    rules,
    explanation: finalRate===unclamped
      ? "Recommended rate is within configured price guardrails."
      : `Recommended rate was clamped to the configured ${finalRate===minRate?"minimum":"maximum"} rate.`
  };
}
