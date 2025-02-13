public with sharing class TaxResCaseAgencyInfoAgathaSyncBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext BC) {
		decimal decTimeDiff = Configuration_Settings__c.getInstance().TaxRes_Agatha_Sync_Time_Gap_in_Minutes__c;
		if (decTimeDiff == null) {
			decTimeDiff = 45.0;
		}

		datetime dtDateTimeBefore45Minute = System.now().addMinutes(-integer.valueOf(decTimeDiff));
		string strQuery =
			'SELECT Id, TaxRes_OBMsg_Trigger__c FROM Case WHERE RecordType.Name = \'Tax Res\' AND TaxRes_OBMsg_Trigger__c = true AND ' +
			'Agency_Info_Agatha__c = null AND Status != \'Solved\' AND CreatedDate >= :dtDateTimeBefore45Minute';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext BC, List<sObject> list_Scope) {
		if (list_Scope != null && list_Scope.size() > 0) {
			list<Case> list_CaseRec = (Case[]) list_Scope;

			for (Case objCase : list_CaseRec) {
				objCase.TaxRes_OBMsg_Trigger__c = false;
			}

			try {
				CaseTriggerHelper.skipTrigger = true;
				update list_CaseRec;
				CaseTriggerHelper.skipTrigger = false;
			} catch (Exception objException) {
				ExceptionLogUtil.logException('TaxResCaseAgencyInfoAgathaSyncBatch', 'execute()', 'Error while updating Case::TaxRes_OBMsg_Trigger__c field - ' + objException.getMessage(), 'High');
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'TaxResCaseAgencyInfoAgathaSyncBatch', false);
	}
}