/**
 * @name         TaxResReadyForDataCaptureCasesCtrlTest
 * @author       Pravesh Rana
 * @date         June 3 2022
 * @description  Test class for TaxResICReadyForDataCaptureCasesCtrl class.
 **/
@isTest
public with sharing class TaxResICReadyForDataCaptureCasesCtrlTest {
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		List<Case> list_cases = new List<Case>();
		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase.Status = TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_READYFORDATACAPTURE;
		objCase.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
		list_cases.add(objCase);

		Case objCase2 = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase2.Status = TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_READYFORDATACAPTURE;
		objCase2.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
		list_cases.add(objCase2);

		Case objCase3 = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase3.Status = TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_READYFORDATACAPTURE;
		list_cases.add(objCase3);

		CaseTriggerHelper.skipTrigger = true;
		update list_cases;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getCasesTestPositiveMethod() {
		Test.startTest();
		List<Case> list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(1, 0, 'createdDate', 'ASC', false, false, 'All');
		//because the limit is defined as 1
		system.assertEquals(1, list_Cases.size());

		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'createdDate', 'ASC', false, false, 'All');
		//because the limit is defined as 5 so we should get all the not assigned records
		system.assertEquals(2, list_Cases.size());

		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'createdDate', 'ASC', true, false, 'All');
		//because the limit is defined as 5 so we should get all the assigned records
		system.assertEquals(1, list_Cases.size());
		//other sorted by filters. -- start
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'accountName', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'agencyInfo', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'segment', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'age', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'Status', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(5, 0, 'tier', 'ASC', true, false, 'All');
		system.assertEquals(1, list_Cases.size());
		//other sorted by filters. -- end
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getCasesTestNegativeMethod() {
		Test.startTest();
		List<Case> list_Cases = TaxResICReadyForDataCaptureCasesCtrl.getCases(0, 0, null, null, false, false, 'All');
		System.assertEquals(null, list_Cases);
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void takeItCaseTestPositiveMethod() {
		User logedInUserId = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(logedInUserId) {
			List<Case> list_cases = [SELECT Id, status FROM CASE];
			Test.startTest();

			String strMessage = TaxResICReadyForDataCaptureCasesCtrl.takeItCase(list_cases[0].Id);
			List<Case> list_tempCases = [SELECT Id, OwnerId, Status FROM Case WHERE Id = :list_cases[0].Id];
			System.assertEquals('success', strMessage);
			System.assert(list_tempCases[0].OwnerId == UserInfo.getUserId());
			System.assert(list_tempCases[0].Status == TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS);

			list_cases[0].Status = TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
			update list_cases;
			String strMsg = TaxResICReadyForDataCaptureCasesCtrl.takeItCase(list_cases[0].Id);
			system.assertEquals('alreadytaken', strMsg);
			Test.stopTest();
		}
	}
	@isTest
	static void takeItCaseTestNegativeMethod() {
		Test.startTest();
		List<Case> list_cases = [SELECT Id, Status FROM CASE WHERE Status = :TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_READYFORDATACAPTURE];
		list_cases[0].Status = TaxResICReadyForDataCaptureCasesCtrl.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
		update list_cases;
		String strMsg = TaxResICReadyForDataCaptureCasesCtrl.takeItCase(list_cases[0].Id);
		system.assertEquals('alreadytaken', strMsg);
		Test.stopTest();
	}
}