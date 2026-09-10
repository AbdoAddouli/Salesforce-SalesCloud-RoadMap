trigger OpportunityStageTrigger on Opportunity (before update, after update) {
    if (Trigger.isBefore) {
        OpportunityService.setCloseDateByStage(Trigger.new);
    }

    if (Trigger.isAfter) {
        OpportunityService.createStageChangeTasks(Trigger.new);
    }
}
