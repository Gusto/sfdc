global with sharing class BatchToUpdateCasesScheduler Implements Schedulable {
	
    global void execute(SchedulableContext sc){
        BatchToUpdateCasesWithContactLead batchObj = new BatchToUpdateCasesWithContactLead();
		Database.executeBatch(batchObj);
    }
}