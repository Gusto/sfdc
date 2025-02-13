/**
 * Test class for CaseMergeControllerExtension
 * @author Aurobind
 * @author David Schach
 * @date 4/2018, 1/2022
 * @see CaseMergeControllerExtension
 * @group Enablement
 */
@isTest
private class CaseMergeControllerExtensionTest {
	/**
	 * @description Set up data for testing
	 */
	@testSetup
	static void setUp() {
		Account acc = TestUtility.CompanyAccount();
		CaseTriggerHelper.skipTrigger = true;
		TriggerHandler.bypass('ContactTriggerHandler');
		EmailMessageTriggerHelper.skipTrigger = true;

		Contact con = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test')
			.setLastName('Test')
			.setZPUserId('777777777777777')
			.setEmail('testuer@abccompany.com')
			.setPhone('123456')
			.build();
		insert con;

		List<Case> caseList = new List<Case>();
		Case cse = new Case();
		cse.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Subject = 'Test 1';
		cse.ContactId = con.Id;
		cse.Description = 'Test';
		cse.Type = 'Payroll Care';
		cse.Status = 'Open';
		caseList.add(cse);

		Case cse1 = new Case();
		cse1.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		cse1.AccountId = acc.Id;
		cse1.Subject = 'Test 2';
		cse1.Description = 'Test';
		cse1.Type = 'Payroll Care';
		cse1.Status = 'Open';
		caseList.add(cse1);
		insert caseList;

		EmailMessage msg = new EmailMessage();
		msg.ParentId = caseList[1].id;
		msg.Subject = 'Test';
		msg.TextBody = 'Test';
		insert msg;

		Attachment atth = new Attachment();
		atth.Name = 'Test Attachment';
		atth.Body = Blob.valueOf('Test Immage');
		atth.ParentId = msg.id;
		insert atth;

		FeedItem item = new FeedItem();
		item.ParentId = caseList[1].id;
		item.Body = 'Test';
		insert item;
	}

	/**
	 * @description Run test as running user - may have modify all data, so need additional method
	 */
	@isTest
	static void testMergeCase() {
		List<Case> caseList = [SELECT Id FROM Case];

		ApexPages.StandardController stdCase = new ApexPages.StandardController(caseList[0]);
		CaseMergeControllerExtension extension = new CaseMergeControllerExtension(stdCase);
		extension.selectedCaseToMerge = caseList[1].id;
		extension.searchSubject = 'Test';
		extension.searchStatus = 'Open';
		Test.startTest();
		extension.mergeSeletedCase();
		extension.searchBySubject();
		Test.stopTest();
		System.assertNotEquals(null, extension.caseSearchList, 'List cannot be null');
	}

	/**
	 * @description Craete Risk user and run tests as that user (who does not have modify all data perm)
	 * @author David Schach
	 */
	@isTest
	static void testMergeCaseAsRiskUser() {
		List<Case> caseList = [SELECT Id FROM Case];
		User riskUser = TestUserUtility.createMDRUser(false);
		riskUser.UserRoleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'Risk_Team' LIMIT 1].Id;
		riskUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Risk' LIMIT 1].Id;
		TriggerHandler.bypass('UserTriggerHandler');
		insert riskUser;
		TriggerHandler.clearAllBypasses();
		System.runAs(riskUser) {
			ApexPages.StandardController stdCase = new ApexPages.StandardController(caseList[0]);
			CaseMergeControllerExtension extension = new CaseMergeControllerExtension(stdCase);
			extension.selectedCaseToMerge = caseList[1].id;
			extension.searchSubject = 'Test';
			extension.searchStatus = 'Open';
			Test.startTest();
			extension.mergeSeletedCase();
			extension.searchBySubject();
			Test.stopTest();
			System.assertNotEquals(null, extension.caseSearchList, 'List cannot be null');
		}
	}
}