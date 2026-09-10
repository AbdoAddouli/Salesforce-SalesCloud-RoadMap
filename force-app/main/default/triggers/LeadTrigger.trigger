trigger LeadTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore) {
        LeadScoringService.calculateLeadScore(Trigger.new);
        LeadScoringService.updateNurtureStatus(Trigger.new);
        LeadScoringService.setHotRating(Trigger.new);
    }
}
