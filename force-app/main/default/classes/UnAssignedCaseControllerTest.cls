@isTest
public class UnAssignedCaseControllerTest {
	static testMethod void testViewUnassignedCases() {
		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE
		Test.startTest();
		insertTestCaseQueue();
		Test.stopTest();

		List<Group> list_caseGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];
		System.assertEquals(false, list_caseGroup.isEmpty(), 'View Unassigned Case Controller - Test queues not inserted');

		if (!list_caseGroup.isEmpty()) {
			AccountTriggerHelper.skipTrigger = true;
			// Insert new company account
			Account objAccount = TestUtility.CompanyAccount();

			// Create a new Contact
			ContactTriggerHelper.skipTrigger = false;
			Contact objContact = new TestDataFactory.ContactBuilder()
				.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
				.setLastName('Test')
				.setAccountId(objAccount.Id)
				.setEmail('testuer@abccompany.com')
				.build();

			insert objContact;

			List<Case> list_Cases = new List<Case>();

			// Insert new Payroll Care Case
			Case objFirstPayrollCareCase = new Case();
			objFirstPayrollCareCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
			objFirstPayrollCareCase.AccountId = objAccount.Id;
			objFirstPayrollCareCase.ContactId = objContact.Id;
			objFirstPayrollCareCase.OwnerId = list_caseGroup.get(0).Id;

			list_Cases.add(objFirstPayrollCareCase);

			// Insert new Benefits Care Case
			Case objSecondPayrollCareCase = new Case();
			objSecondPayrollCareCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
			objSecondPayrollCareCase.AccountId = objAccount.Id;
			objSecondPayrollCareCase.ContactId = objContact.Id;
			objSecondPayrollCareCase.OwnerId = list_caseGroup.get(0).Id;

			list_Cases.add(objSecondPayrollCareCase);

			insert list_Cases;

			UnAssignedCaseController.UnAssignedCaseResponse objResponse = UnAssignedCaseController.returnUnAssignedCases(objFirstPayrollCareCase.Id);

			// Assert to ensure you only find one unassigned cases to the same contact
			System.assertEquals(1, objResponse.list_Cases.size(), 'Unassgined Case Controller - More than one unassgined cases for contact');
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