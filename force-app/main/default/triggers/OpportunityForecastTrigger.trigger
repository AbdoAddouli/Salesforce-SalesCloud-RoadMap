trigger OpportunityForecastTrigger on Opportunity (before insert, before update) {
    ForecastingService.calculateWeightedForecast(Trigger.new);
    ForecastingService.setDefaultForecastCategory(Trigger.new);
}
