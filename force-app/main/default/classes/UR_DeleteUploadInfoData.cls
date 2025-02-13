public class UR_DeleteUploadInfoData implements Database.Batchable<sObject>, Database.Stateful {
	public string projectId;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'select id from Research_Upload_Info__c where Research_Project_Master_Id__c=:projectId or Research_Project_Master_Id__c=\'\' ';
		return Database.getQueryLocator(strQuery);
	}
	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			if (scope.size() > 0) {
				UR_ResearchUploadInfoTriggerHelper.skipTrigger = true;
				delete scope;
				UR_ResearchUploadInfoTriggerHelper.skipTrigger = false;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_DeleteUploadInfoData', 'execute', ex.getMessage(), ex.getStackTraceString());
		}
	}
	public void finish(Database.BatchableContext bc) {
		UR_DeleteCSVStagingData deleteBatchObj = new UR_DeleteCSVStagingData();
		deleteBatchObj.projectId = projectId;
		Database.executeBatch(deleteBatchObj, 500);
	}
}