public with sharing class ZendeskIntegrationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'SELECT Id, Case_Id__c ,Create_As_Followup__c ,Object_Id__c ,Object_Type__c,CreatedById,Zendesk_Instance__c  FROM Zendesk_Integration_Queue__c WHERE (Processing_State__c=null or Processing_State__c=\'\' or Processing_State__c=\'Error\' or Processing_State__c=\'Queued\')  ORDER BY CreatedDate asc';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<Zendesk_Integration_Queue__c> zendeskList = (List<Zendesk_Integration_Queue__c>) scope;

		List<Zendesk_Integration_Queue__c> caseQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> emailQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> chatterQueues = new List<Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c queue : zendeskList) {
			if (queue.Object_Type__c == 'Case') {
				caseQueues.add(queue);
			}
			if (queue.Object_Type__c == 'Email') {
				emailQueues.add(queue);
			}
			if (queue.Object_Type__c == 'Chatter') {
				chatterQueues.add(queue);
			}
		}
		if (caseQueues.size() > 0) {
			ZendeskIntegration.processCaseInformation(caseQueues);
		}
		if (emailQueues.size() > 0) {
			ZendeskIntegration.processCaseEmailInformation(emailQueues);
		}
		if (chatterQueues.size() > 0) {
			ZendeskIntegration.processCaseChatterInformation(chatterQueues);
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob a = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new List<String>{ a.CreatedById };
		mail.setToAddresses(toAddresses);
		mail.setSubject('Zendesk Integration ' + a.Status);
		mail.setPlainTextBody('records processed ' + a.TotalJobItems + 'with ' + a.NumberOfErrors + ' failures.');
		if (a.NumberOfErrors > 0) {
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
		}
	}
}