/**
 * @name         OpportunityPlayModeBatch
 * @author       Praveen Sethu
 * @date         03-07-2021
 * @description  Updating eligiblity status of ineligible opportunities for play mode
 * @test classes OpportunityPlayModeBatchTest
 **/

public class OpportunityPlayModeBatch implements Database.Batchable<sObject>, Database.stateful {
	public static Boolean blnTestException = false;

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strInEligiblePlayMode = OpportunityUtil.INELIGIBLE_SAL_GREETERS_PLAYMODE;
		String strBatchQuery = 'SELECT Id, (SELECT Id, ContactId, Contact.Current_Sequence_Status__c FROM OpportunityContactRoles) FROM Opportunity WHERE Served_Play_Mode__c = :strInEligiblePlayMode AND IsClosed = false AND CreatedDate = LAST_N_DAYS:60';
		return Database.getQueryLocator(strBatchQuery);
	}

	public void execute(Database.BatchableContext BC, List<Opportunity> list_Opptys) {
		Set<Id> set_Opptys = new Set<Id>();
		List<Opportunity> list_OpptysToUpdate = new List<Opportunity>();
		try {
			// Test Exception
			if (Test.isRunningTest() && blnTestException) {
				Integer intInfinity = 1 / 0;
			}

			for (Opportunity objOppty : list_Opptys) {
				if (objOppty.OpportunityContactRoles != null) {
					for (OpportunityContactRole objContactRole : objOppty.OpportunityContactRoles) {
						if (
							objContactRole != null &&
							objContactRole.ContactId != null &&
							String.isNotBlank(objContactRole.Contact.Current_Sequence_Status__c) &&
							objContactRole.Contact.Current_Sequence_Status__c.equalsIgnoreCase('active')
						) {
							objOppty.Served_Play_Mode__c = '';
							list_OpptysToUpdate.add(objOppty);
							break;
						}
					}
				}
			}

			if (!list_OpptysToUpdate.isEmpty()) {
				OpportunityTriggerHelper.skipTrigger = true;
				update list_OpptysToUpdate;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'OpportunityPlayModeBatch',
				'execute',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'OpportunityPlayModeBatch', false);
	}
}