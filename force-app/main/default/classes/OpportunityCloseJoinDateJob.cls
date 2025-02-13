/*
 * @name         OpportunityCloseJoinDateJob
 * @author       Praveen Sethu
 * @date         07-03-20201
 * @description  Sync Close Date and Join Date of 'Closed Won' Opportunities
 * @test classes OpportunityCloseJoinDateSchedulerTest
 */
public with sharing class OpportunityCloseJoinDateJob implements Database.Batchable<SObject> {
	public String strQuery;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (String.isBlank(strQuery)) {
			strQuery =
				'SELECT Id, Opportunity.Id, Opportunity.CloseDate, Opportunity.Joined_Date_Panda__c, Opportunity.Account.Joined_Date_Panda__c ' +
				' FROM OpportunityHistory WHERE Opportunity.StageName = \'Closed Won\' AND CreatedDate = TODAY ' +
				' AND Opportunity.Account.Joined_Date_Panda__c  != null AND Opportunity.Joined_Date_Panda__c != null AND Opportunity.CloseDate != null';
			if (Test.isRunningTest()) {
				strQuery = strQuery + ' AND Opportunity.Account.ZP_Company_Id__c = \'123456789\'';
			}
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<SObject> list_HistoryRecs) {
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		for (OpportunityHistory objHistory : (List<OpportunityHistory>) list_HistoryRecs) {
			if (
				objHistory.Opportunity.Joined_Date_Panda__c ==
				objHistory.Opportunity.Account.Joined_Date_Panda__c &&
				objHistory.Opportunity.Joined_Date_Panda__c != objHistory.Opportunity.CloseDate
			) {
				map_OpptysToUpdate.put(
					objHistory.Opportunity.Id,
					new Opportunity(
						Id = objHistory.Opportunity.Id,
						CloseDate = objHistory.Opportunity.Joined_Date_Panda__c
					)
				);
			}
		}
		if (!map_OpptysToUpdate.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			update map_OpptysToUpdate.values();
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [
			SELECT Id, Status, NumberOfErrors, TotalJobItems
			FROM AsyncApexJob
			WHERE Id = :BC.getJobId()
		];
		Utils.processBatchFinish(objAsyncJob, 'OpportunityCloseJoinDateJob', false);
	}
}