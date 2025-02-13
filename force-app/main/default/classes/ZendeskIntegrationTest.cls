@isTest
public class ZendeskIntegrationTest {
	static testMethod void testCaseProcessing() {
		Account acc = TestUtility.CompanyAccount();

		test.startTest();
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.Priority = 'Low';
		insert cse;

		FeedItem feed = new FeedItem();
		feed.ParentId = cse.id;
		feed.Body = 'test';
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
		insert integQueue;

		integQueue = new Zendesk_Integration_Queue__c();
		integQueue.Case_Id__c = cse.Id;
		integQueue.Object_Type__c = 'Email';
		integQueue.Object_Id__c = msg.id;
		insert integQueue;

		integQueue = new Zendesk_Integration_Queue__c();
		integQueue.Case_Id__c = cse.Id;
		integQueue.Object_Type__c = 'Chatter';
		integQueue.Object_Id__c = feed.id;
		insert integQueue;

		List<Zendesk_Integration_Queue__c> caseQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> emailQueues = new List<Zendesk_Integration_Queue__c>();
		List<Zendesk_Integration_Queue__c> chatterQueues = new List<Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c queue : [
			SELECT Id, Zendesk_Instance__c, Case_Id__c, Create_As_Followup__c, Last_Processed__c, Message__c, Object_Id__c, Object_Type__c, Processing_State__c, CreatedById
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
			ZendeskIntegration.processCaseInformation(caseQueues);
		}

		cse.Zendesk_Id__c = '12345';
		update cse;

		if (emailQueues.size() > 0) {
			ZendeskIntegration.processCaseEmailInformation(emailQueues);
		}

		if (chatterQueues.size() > 0) {
			ZendeskIntegration.processCaseChatterInformation(chatterQueues);
		}

		test.stopTest();
	}

	static testMethod void testZendeskUserCreation() {
		ZendeskIntegration.ZendeskUser user = new ZendeskIntegration.ZendeskUser();
		user.id = '121212';
		user.name = 'Test';
		user.email = 'test';
		user.role = 'Test';
		ZendeskIntegration integ = new ZendeskIntegration();
		ZendeskIntegration.ZendeskUserResponse res = integ.createZendeskUser(user, 'ApIntego');
		system.assert(res.Status == 'Processed');
	}

	static testMethod void testSearchTickets() {
		ZendeskIntegration integration = new ZendeskIntegration();
		ZendeskIntegration.ZendeskTicketSearchResult result = integration.searchZendeskTickets('Test', 'ApIntego');
	}

	@isTest
	static void createUserInZendesk() {
		ZendeskIntegration.ZendeskUser usr = new ZendeskIntegration.ZendeskUser();
		usr.careAccountManager = 'test user';
		usr.email = 'test.test@gusto.com';
		usr.name = 'test user';
		usr.role = 'tester';

		test.startTest();
		ZendeskIntegration integration = new ZendeskIntegration();
		ZendeskIntegration.ZendeskUserResponse response = integration.createZendeskUser(usr, 'ApIntego');
		system.assertEquals('Processed', response.status);
		test.stopTest();
	}

	@isTest
	static void searchZendeskUsers() {
		test.startTest();
		ZendeskIntegration integration = new ZendeskIntegration();
		ZendeskIntegration.ZendeskUserSearchResult response = integration.searchZendeskUsers('test@test.com', 'ApIntego');
		integration.updateZendeskTicketInteractionId('ticketId', 'interactionId', 'app');
		test.stopTest();
	}
}