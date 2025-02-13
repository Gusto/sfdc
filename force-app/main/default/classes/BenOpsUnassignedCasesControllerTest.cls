@isTest
public class BenOpsUnassignedCasesControllerTest {
	@isTest
	static void testViewUnassignedCases() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE
		Test.startTest();
		insertTestCaseQueue();
		Test.stopTest();

		List<Group> list_caseGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];
		System.assertEquals(false, list_caseGroup.isEmpty(), 'Ben Ops Unassigned Case Controller - Test queues not inserted');

		if (!list_caseGroup.isEmpty()) {
			// Insert new company account
			Account objAccount = TestUtility.CompanyAccount();

			// Create a new Contact
			ContactTriggerHelper.skipTrigger = false;
			Contact objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objAccount.id)
				.setFirstName('Test Contact Name')
				.setLastName('Test Last Name')
				.setEmail('testuer@abccompany.com')
				.build();
			insert objContact;

			// Insert new Payroll Care Case
			Case objFirstPayrollCareCase = new Case();
			objFirstPayrollCareCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
			objFirstPayrollCareCase.AccountId = objAccount.Id;
			objFirstPayrollCareCase.ContactId = objContact.Id;
			objFirstPayrollCareCase.OwnerId = list_caseGroup.get(0).Id;

			insert objFirstPayrollCareCase;

			// Insert new Benefits Care Case
			Case objSecondPayrollCareCase = new Case();
			objSecondPayrollCareCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
			objSecondPayrollCareCase.AccountId = objAccount.Id;
			objSecondPayrollCareCase.ContactId = objContact.Id;
			objSecondPayrollCareCase.OwnerId = list_caseGroup.get(0).Id;

			insert objSecondPayrollCareCase;

			BenOpsUnassignedCasesController.BenOpsUnAssignedCaseResponse objResponse = BenOpsUnassignedCasesController.returnBenOpsUnAssignedCases(objFirstPayrollCareCase.Id);

			System.assertEquals(0, objResponse.list_Cases.size(), 'List Cannot be Empty');
		}
	}

	@future
	public static void insertTestCaseQueue() {
		Group objCaseGroup = new Group(Name = 'Test Group', type = 'Queue');
		insert objCaseGroup;
		QueuesObject objCaseQueue = new QueueSObject(QueueID = objCaseGroup.id, SobjectType = 'Case');
		insert objCaseQueue;
	}
}