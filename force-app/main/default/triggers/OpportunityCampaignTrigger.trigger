trigger OpportunityCampaignTrigger on Opportunity (after update) {
    List<Opportunity> closedWonOpps = new List<Opportunity>();

    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            closedWonOpps.add(opp);
        }
    }

    if (!closedWonOpps.isEmpty()) {
        CampaignService.addContactsToCampaignOnDealClose(closedWonOpps);
    }
}
