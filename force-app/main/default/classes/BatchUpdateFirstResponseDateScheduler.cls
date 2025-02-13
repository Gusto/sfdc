/**
    @Created by : Deepesh Rao
    @Created Date : 17-Oct-2023
    @Desc : Scheduler class to update R&D Tax Credits case when an email is replied to from case
**/
global class BatchUpdateFirstResponseDateScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = config.Case_First_Response_Batch_Size__c.intValue() != null &&
			config.Case_First_Response_Batch_Size__c.intValue() != 0
			? config.Case_First_Response_Batch_Size__c.intValue()
			: 100;
		BatchUpdateFirstResponseDateCase batchObj = new BatchUpdateFirstResponseDateCase();
		Database.executeBatch(batchObj, intBatch);
	}
}