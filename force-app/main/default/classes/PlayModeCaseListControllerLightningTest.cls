@isTest
public class PlayModeCaseListControllerLightningTest {
	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		Utils.skipTrigger(true);
		Group objCaseGroup = new Group(Name = 'Test Group', type = 'Queue');
		insert objCaseGroup;
		QueuesObject objCaseQueue = new QueueSObject(QueueID = objCaseGroup.id, SobjectType = 'Case');
		insert objCaseQueue;

		Utils.skipTrigger(false);
	}

	static testMethod void testFetchCasesRelatedToQueue() {
		// Moved insertTestCaseQueue content to setupData.
		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE

		// Create a new Payroll Care Case
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);

		List<Group> list_caseGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];
		// Check if Queues are created properly
		System.assertEquals(false, list_caseGroup.isEmpty(), 'Routing Case Controller - Test Fetch Case Related to Queue - Test queues not inserted');

		Test.startTest();
		if (!list_caseGroup.isEmpty()) {
			// Create a new case reason classification
			Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c(
				Active__c = true,
				Class__c = 'Class 1',
				Type__c = 'Payroll Care',
				Name = 'Test Payroll Care Reason'
			);
			insert objCaseReasonClassification;

			List<Case> list_Cases = new List<Case>();
			objCase.OwnerId = list_caseGroup.get(0).Id;
			CaseTriggerHelper.skipTrigger = true;
			objCase.Routing_Case_Reason__c = objCaseReasonClassification.Id;
			list_Cases.add(objCase);

			// Insert second case with same routing case reason
			Case secondCaseObj = new Case(
				AccountId = objCase.AccountId,
				OwnerId = list_caseGroup.get(0).Id,
				RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care'),
				Subject = 'Test Subject',
				Description = 'Test Description',
				Routing_Case_Reason__c = objCaseReasonClassification.Id
			);
			list_Cases.add(secondCaseObj);

			Case objCase3 = new TestDataFactory.CaseBuilder()
				.setRecordTypeId('Payroll Care')
				.setAccountId(objCase.AccountId)
				.setSubject('Test Subject')
				.setDescription('Test Description')
				.setRoutingCaseReason(objCaseReasonClassification.Id)
				.setStatus('Awaiting Internal Support')
				.setOwnerId(list_caseGroup.get(0).Id)
				.build();
			list_Cases.add(objCase3);

			insert list_Cases;

			// Testing to get number of pending cases
			PlayModeCaseListControllerLightning.PlayModeCaseListWrapper objPendingCaseWrapper = PlayModeCaseListControllerLightning.getNumberOfPendingCases(list_caseGroup.get(0).Id);
			System.assertEquals(true, objPendingCaseWrapper.intPendingCases > 0, 'Play mode Case List Controller Lightning - Number of pending cases not greater than zero');
			PlayModeCaseListControllerLightning.PlayModeCaseListWrapper objWrapper = PlayModeCaseListControllerLightning.assignCaseFromQueue(
				list_caseGroup.get(0).Id, 
				3,
				new List<String> { 'Awaiting Internal Support', 'Awaiting External Support' }
			);
			System.assertEquals(true, objWrapper.blnIsSuccess, 'Play mode Case List Controller Lightning - Unable to assign cases');
			objCase3 = [SELECT Id, Status FROM Case WHERE Id = :objCase3.Id];
			// Assert that the Status should not change to In Progress when the Case is in Awaiting Internal Support Status
			System.assertNotEquals('In Progress', objCase3.Status, 'Status should not change to In Progress.');

			PlayModeCaseListControllerLightning.handleNextButton();
		}
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method for asserting if Escalation Case is created for a Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testCaseEscalation() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Test.startTest();
		Account objAccount = TestUtility.CompanyAccount();

		Opportunity objOpp1 = TestUtility.BenefitsNewPlanOpportunity();

		Contact objContactRecord = new Contact();
		objContactRecord.FirstName = 'Test Demo';
		objContactRecord.LastName = 'AccountName 1';
		objContactRecord.Phone = '19992344444';
		objContactRecord.MailingStreet = 'Testing Avenue 1';
		objContactRecord.MailingPostalCode = '123455';
		objContactRecord.MobilePhone = '19992344444';
		objContactRecord.OtherPhone = '19992344444';
		objContactRecord.Email = 'test@acme.com';
		objContactRecord.AccountId = objAccount.id;
		insert objContactRecord;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContactRecord.Id)
			.setRecordTypeId('Payroll Care')
			.setSubject('Test 1')
			.setDescription('Test')
			.setType('QLE')
			.build();

		insert objCase;

		//Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		// Call Escalate Case Method
		PlayModeCaseListControllerLightning.escalateCaseRecord(objCase.Id, 'Escalation Comments', 'Out of Scope', 'Dedicated Support', 'Do not have required access - Hippo', 'Payroll');

		List<Case_Escalation__c> list_CaseEscalation = [SELECT Id, Case_Type__c, Out_of_Scope_Reason__c, Team__c FROM Case_Escalation__c WHERE Case__c = :objCase.Id];

		System.assertEquals(true, list_CaseEscalation.size() > 0, 'Play Mode Case List Controller Lightning - Escalation Case not created successfully');
		System.assertNotEquals(null, list_CaseEscalation[0].Case_Type__c);
		System.assertNotEquals(null, list_CaseEscalation[0].Out_of_Scope_Reason__c);
		System.assertNotEquals(null, list_CaseEscalation[0].Team__c);
		Case objUpdatedCase = [SELECT Id, Escalated_By_Task_Us__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(true, objUpdatedCase.Escalated_By_Task_Us__c);
		Test.stopTest();
	}

	static testMethod void testGetCaseQueueList() {
		Test.startTest();
		List<String> lst_pickListValues = returnPickListValues('User', 'Individual_Queues__c');
		User objLoggedInUser = new User(Id = UserInfo.getUserId(), Individual_Queues__c = lst_pickListValues.get(0));

		update objLoggedInUser;
		Test.stopTest();
		PlayModeCaseListControllerLightning.PlayModeCaseListWrapper objWrapper = PlayModeCaseListControllerLightning.getcaseQueueList();
	}

	static testMethod void testAllQueueId() {
		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE
		Test.startTest();
		List<Group> list_caseGroup = [SELECT Id FROM Group WHERE Name = 'Test Group'];

		if (!list_caseGroup.isEmpty()) {
			User objUser = new User(Id = UserInfo.getUserId(), All_Queues__c = 'Test Group');
			String strAllQueues = PlayModeCaseListControllerLightning.returnAllQueueId(objUser);
			System.assertEquals(true, String.isNotBlank(strAllQueues), 'Play Mode Case List Controller Lightning - Unable to find All Queues for Logged In User');
		}
		Test.stopTest();
	}

	public static List<String> returnPickListValues(String strObjectName, String strFieldName) {
		List<String> lst_pickListValues = new List<String>();
		Schema.SObjectType s = Schema.getGlobalDescribe().get(strObjectName);
		Schema.DescribeSObjectResult r = s.getDescribe();
		Map<String, Schema.SObjectField> fields = r.fields.getMap();
		Schema.DescribeFieldResult fieldResult = fields.get(strFieldName).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			lst_pickListValues.add(pickListVal.getValue());
		}
		return lst_pickListValues;
	}
}