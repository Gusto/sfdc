@isTest
private class CaseFeatureRequestExtensionTest {
	static Case cse;
	static Contact contact;
	static CaseFeatureRequestExtension extension;

	@testSetup
	static void setUp() {
		Account account = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('1234567890')
			.build();
		insert account;

		Contact contact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(account.id)
			.setFirstName('Test')
			.setLastName('Test')
			.setZPUserId('777777777777777')
			.setEmail('testuer@abccompany.com')
			.setPhone('123456')
			.build();
		insert contact;

		Case cse = new Case();
		cse.ContactId = contact.Id;
		cse.AccountId = account.Id;
		cse.Direction__c = 'Inbound';
		cse.Origin = 'Phone';
		cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res');
		insert cse;

		Feature_Request__c feature = new Feature_Request__c();
		feature.Case__c = cse.Id;
		feature.Account__c = account.Id;
		feature.Feature__c = 'Chat Support';
		feature.Comments__c = 'Test Support';
		insert feature;
	}

	@isTest
	static void cancelNewContactTest() {
		test.startTest();
		Case cse = [SELECT Id FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		setupTestRun(cse);
		List<Feature_Request__c> featureList = extension.caseFeatureList;
		List<SelectOption> featureOptionList = extension.featureList;
		System.assertNotEquals(null, featureList, 'List Cannot be null');
		System.assertNotEquals(null, featureOptionList, 'List Cannot be null');
		System.assertEquals('Chat Support', featureList[0].Feature__c, 'List Cannot be null');

		test.stopTest();
	}

	@isTest
	static void submitDuplicateFeatureTest() {
		test.startTest();
		Case cse = [SELECT Id FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		setupTestRun(cse);
		extension.selectedFeature = 'Chat Support';
		extension.submitFeature();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(1, pageMessages.size(), 'Incorrect Result');
		System.assertEquals('Feature is already requested for the account', pageMessages[0].getDetail(), 'Incorrect Result');
		test.stopTest();
	}

	@isTest
	static void submitFeatureTest() {
		test.startTest();
		Case cse = [SELECT Id FROM Case WHERE contact.FirstName = 'Test' LIMIT 1];
		setupTestRun(cse);
		extension.selectedFeature = 'Expense Management';
		extension.selectedFeatureComment = 'Test';
		extension.submitFeature();
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertEquals(0, pageMessages.size(), 'Incorrect Result');
		List<Feature_Request__c> featureList = extension.caseFeatureList;
		System.assertEquals(2, featureList.size(), 'List cannot be null');
		test.stopTest();
	}

	static void setupTestRun(Case cse) {
		ApexPages.StandardController stdController = new ApexPages.StandardController(cse);
		extension = new CaseFeatureRequestExtension(stdController);
		System.assertNotEquals(null, extension, 'Incorrect Result');
	}
}