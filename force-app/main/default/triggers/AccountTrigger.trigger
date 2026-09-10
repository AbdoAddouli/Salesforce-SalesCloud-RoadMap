trigger AccountTrigger on Account (before insert, after insert, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountService.setAccountLevel(Trigger.new);
        AccountService.setUltimateParent(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        AccountService.createDefaultContact(Trigger.new);

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : Trigger.new) {
            accountIds.add(acc.Id);
        }
        AccountService.refreshAccountMetrics(accountIds);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> changedAccountIds = new Set<Id>();
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            if (acc.ParentId != oldAcc.ParentId) {
                changedAccountIds.add(acc.Id);
            }
        }

        if (!changedAccountIds.isEmpty()) {
            AccountService.setUltimateParent(
                [SELECT Id, ParentId FROM Account WHERE Id IN :changedAccountIds]
            );
        }
    }
}
