trigger CampaignMemberStatusTrigger on Task (after insert) {
    List<Task> contactTasks = new List<Task>();

    for (Task t : Trigger.new) {
        if (t.WhoId != null && String.valueOf(t.WhoId).startsWith('003')) {
            contactTasks.add(t);
        }
    }

    if (!contactTasks.isEmpty()) {
        CampaignService.updateMemberStatusOnActivity(contactTasks);
    }
}
