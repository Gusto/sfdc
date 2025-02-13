/*
 * @name         SendOpportunityToRingLeadBatch
 * @author       Praveen Sethu
 * @date         07-03-2024
 * @description  Send tier upsell opportunities to RingLead for routing
 * @test classes SendOpportunityToRingLeadTest
 */
global without sharing class SendOpportunityToRingLeadBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
	public String strQuery;
	Id idTierUpsellRecordType = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
	String strUpsellTierInternationlPayroll = OpportunityUtil.UPSELL_TIER_INTERNATIONNAL_PAYROLL;

	public Database.QueryLocator start(Database.BatchableContext bc) {
		// Only select open tier upsells with upsell tier as International Payroll and Joined date as TODAY
		strQuery = 'SELECT Id FROM Opportunity WHERE Account.Joined_Date_Panda__c = TOMORROW AND IsClosed = FALSE AND RecordTypeId = :idTierUpsellRecordType AND Upsell_Tier__c = :strUpsellTierInternationlPayroll';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) {
		Set<Id> set_OpportunityIdsToRoute = new Set<Id>();
		for (Opportunity objOppty : (List<Opportunity>) scope) {
			set_OpportunityIdsToRoute.add(objOppty.Id);
		}
		// use the queueable class to send the opportunities to RingLead
		new SendOpportunityToRingLead(set_OpportunityIdsToRoute).sendOpportunityToRingLead();
	}

	public void finish(Database.BatchableContext BC) {
	}

	global void execute(SchedulableContext sc) {
		// batch size has to be constant - we don't expect too many opportunities to be sent to RingLead using this process
		Database.executeBatch(new SendOpportunityToRingLeadBatch(), 5);
	}
}