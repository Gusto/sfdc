public class UR_DeleteCSVStagingData implements Database.Batchable<sObject>, Database.Stateful {
	public string projectId;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strQuery = 'select id from UXR_CSV_Staging__c where Research_Project_Master__c=:projectId';
		return Database.getQueryLocator(strQuery);
	}
	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		try {
			if (scope.size() > 0) {
				UR_ResearchCSVDataTriggerHelper.skipTrigger = true;
				delete scope;
				UR_ResearchCSVDataTriggerHelper.skipTrigger = false;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_DeleteCSVStagingData', 'execute', ex.getMessage(), ex.getStackTraceString());
		}
	}
	public void finish(Database.BatchableContext bc) {
		try {
			Research_Project_Master__c projectMasterObj = new Research_Project_Master__c(Id = projectId, CSV_Delete_In_Progress__c = false);
			update projectMasterObj;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_DeleteCSVStagingData', 'finish', ex.getMessage(), ex.getStackTraceString());
		}
	}
}