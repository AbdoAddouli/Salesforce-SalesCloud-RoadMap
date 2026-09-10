trigger TaskActivityTrigger on Task (after insert, after update) {
    List<Task> completedTasks = new List<Task>();
    List<Task> allTasks = new List<Task>();

    for (Task t : Trigger.new) {
        allTasks.add(t);

        if (Trigger.isInsert && t.Status == 'Completed') {
            completedTasks.add(t);
        }

        if (Trigger.isUpdate) {
            Task oldTask = Trigger.oldMap.get(t.Id);
            if (t.Status == 'Completed' && oldTask.Status != 'Completed') {
                completedTasks.add(t);
            }
        }
    }

    if (!completedTasks.isEmpty()) {
        ActivityService.createFollowUpTasks(completedTasks);
        ActivityService.postChatterOnHighValueActivity(completedTasks);
        ActivityService.notifyManagerOnLargeDealActivity(completedTasks);
    }
}
