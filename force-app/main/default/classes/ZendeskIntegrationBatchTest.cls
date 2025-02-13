@isTest
public class ZendeskIntegrationBatchTest {
	static testMethod void testCaseProcessing() {
		Account acc = TestUtility.CompanyAccount();

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Priority = 'Low';
		cse.Type = 'QLE';
		cse.Status = 'New';
		insert cse;

		FeedItem feed = new FeedItem();
		feed.ParentId = cse.id;
		feed.Body = 'test';
		feed.Type = 'TextPost';
		insert feed;

		EmailMessage msg = new EmailMessage();
		msg.ParentId = cse.id;
		msg.FromAddress = 'test@gusto.com';
		msg.ToAddress = 'test.test@gusto.com';
		msg.Subject = 'test';
		msg.TextBody = 'test';
		insert msg;

		Zendesk_Integration_Queue__c integQueue = new Zendesk_Integration_Queue__c();
		integQueue.Case_Id__c = cse.Id;
		integQueue.Object_Type__c = 'Case';
		integQueue.Processing_State__c = '';
		integQueue.Zendesk_Instance__c = 'ApIntego';
		insert integQueue;

		integQueue = new Zendesk_Integration_Queue__c();
		integQueue.Case_Id__c = cse.Id;
		integQueue.Object_Type__c = 'Email';
		integQueue.Object_Id__c = msg.id;
		integQueue.Processing_State__c = '';
		integQueue.Zendesk_Instance__c = 'ApIntego';
		insert integQueue;

		integQueue = new Zendesk_Integration_Queue__c();
		integQueue.Case_Id__c = cse.Id;
		integQueue.Object_Type__c = 'Chatter';
		integQueue.Object_Id__c = feed.id;
		integQueue.Processing_State__c = '';
		integQueue.Zendesk_Instance__c = 'ApIntego';
		insert integQueue;

		List<Zendesk_Integration_Queue__c> caseQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> emailQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> chatterQueues = new List<Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c queue : [
			SELECT Id, Case_Id__c, Create_As_Followup__c, Last_Processed__c, Message__c, Object_Id__c, Object_Type__c, Processing_State__c, CreatedById, Zendesk_Instance__c
			FROM Zendesk_Integration_Queue__c
		]) {
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
			//ZendeskIntegration.processCaseInformation(caseQueues);
		}
		cse.Zendesk_Id__c = '12345';
		update cse;
		if (emailQueues.size() > 0) {
			//ZendeskIntegration.processCaseEmailInformation(emailQueues);
		}
		if (chatterQueues.size() > 0) {
			//ZendeskIntegration.processCaseChatterInformation(chatterQueues);
		}
		test.startTest();
		database.executeBatch(new ZendeskIntegrationBatch(), 10);
		test.stopTest();
	}
}