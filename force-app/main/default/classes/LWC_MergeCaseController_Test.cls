@isTest
public class LWC_MergeCaseController_Test {

	@TestSetup
	static void setup() {
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('1111111111')
			.build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@LWCMergeCaseControllerTest.com')
			.build();
		insert objContact;

		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setType('Payroll Care')
			.setSubject('original case')
			.setOrigin('Email')
			.setStatus('New')
			.setDescription('description')
			.build();

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setType('Payroll Care')
			.setSubject('second case')
			.setOrigin('Email')
			.setStatus('In Progress')
			.setDescription('description')
			.build();
		
		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Modern Bank')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setType('Modern Bank')
			.setSubject('modern bank case')
			.setOrigin('Email')
			.setStatus('In Progress')
			.setDescription('description')
			.build();

		List<Case> list_Case = new List<Case> {objCase1, objCase2, objCase3};
		insert list_Case;
	}

	static testMethod void method1(){
		Test.startTest();
		Case caseObj1 = new Case();
		caseObj1.Subject = 'Om Test';  
		caseObj1.Status ='New';
		caseObj1.Priority = 'Medium';
		caseObj1.Origin = 'Email';
		insert caseObj1;

		EmailMessage email = new EmailMessage();
		email.FromAddress = 'test@abc.org';
		email.Incoming = True;
		email.ToAddress= 'test@xyz.org';
		email.Subject = 'Test email';
		email.HtmlBody = 'Test email body';
		email.ParentId = caseObj1.Id; 
		insert email;
		
		Attachment obj = new Attachment();
		obj.Body = Blob.valueOf('I am doing good');
		obj.ParentId = email.Id;
		obj.Name = 'Dummy.pdf';
		obj.ContentType = 'application/pdf';
		insert obj;
		
		FeedItem feed = new FeedItem (
			parentid = caseObj1.id,
			type = 'ContentPost',
			Body = 'Hello');
			insert feed ; 
		
		FeedComment fc = new FeedComment(CommentBody='Test Comment',FeedItemId = feed.Id);
		insert fc;
		
		Case caseObj2 = new Case(Origin = 'Phone', status='Open');
		insert caseObj2;
		
		LWC_MergeCaseController.returnCaseList(caseObj1.id, '', true);       
		LWC_MergeCaseController.getSelectedCaseRecord([Select id, CaseNumber from Case where id = : caseObj1.id LIMIT 1].CaseNumber);
		LWC_MergeCaseController.mergeSeletedCase(new List<id>{caseObj1.Id}, caseObj2, new List<String>{[Select id, CaseNumber from Case where id = : caseObj2.id LIMIT 1].CaseNumber});
		
		System.assertEquals([Select Id,Status From Case Where Id = :caseObj1.Id][0].Status,
							'Closed');
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description make sure Case Audit Logs are created when merging cases
	 */
	@isTest
	static void testCaseAuditLogCreation() {
		Test.startTest();
		Case objCase1 = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'original case'];
		Case objCase2 = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'second case'];

		LWC_MergeCaseController.mergeSeletedCase(new List<Id>{objCase2.Id}, objCase1, new List<String>{objCase1.CaseNumber, objCase2.CaseNumber});

		Test.stopTest();
		List<Case_Audit_Log__c> list_Logs = [SELECT Id, Case__c, From_Status__c, To_Status__c FROM Case_Audit_Log__c WHERE Case__c = :objCase2.Id AND Event_Type__c = 'Status Change'];
		System.assertEquals(objCase2.Id, list_Logs[0].Case__c);
		System.assertEquals('In Progress', list_Logs[0].From_Status__c);
		System.assertEquals('Closed', list_Logs[0].To_Status__c);
	}

	/**
	 * @author Alex Xiong
	 * @description test copyFeeds()
	 */
	@isTest
	static void testCopyFeeds() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case];
		List<Id> list_CaseIds = new List<Id>();

		for (Case objCase : list_Case) {
			list_CaseIds.add(objCase.Id);
		}

		FeedItem objFeed = new FeedItem (
			Parentid = list_Case[0].Id,
			Type = 'ContentPost',
			Body = 'Hello');
		insert objFeed;

		LWC_MergeCaseController.copyFeeds(list_CaseIds, objFeed.Id);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test returnCaseList()
	 */
	@isTest
	static void testReturnCaseList() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id, CaseNumber FROM Case];

		LWC_MergeCaseController.WrapperResponse objWrapper = LWC_MergeCaseController.returnCaseList(list_Case[0].Id, list_Case[1].CaseNumber, true);
		System.assert(objWrapper.blnIsSuccess);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description make sure Modern Bank Cases will be merged with a Complaint Type of 'No Complaint'
	 */
	@isTest
	static void modernBankNoComplaint() {
		Test.startTest();
		List<Case> list_CasePRC = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'second case'];
		List<Case> list_CaseMB = [SELECT Id, CaseNumber FROM Case WHERE Subject = 'modern bank case'];

		LWC_MergeCaseController.WrapperResponse objWrapper = LWC_MergeCaseController.mergeSeletedCase(new List<Id>{list_CaseMB[0].Id}, list_CasePRC[0], new List<String>{list_CasePRC[0].CaseNumber, list_CaseMB[0].CaseNumber});
		Test.stopTest();

		List<Case> list_CaseMBAfter = [SELECT Id, Complaint_Type__c FROM Case WHERE Subject = 'modern bank case'];
		System.assertEquals('No Complaint', list_CaseMBAfter[0].Complaint_Type__c, 'modern bank case should be closed with a Complaint Type');
	}
}