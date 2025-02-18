global class AutoCloseCasesBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM Case WHERE Confirm_Case_Reason__c IN (\'No Action\', \'Wrong Email\') AND Audience__c IN (\'Other\', \'Unknown\')';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : scope) {
            c.Status = 'Closed';
            //c.Closed_Reason__c = '';
            casesToUpdate.add(c);
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional
    }
}