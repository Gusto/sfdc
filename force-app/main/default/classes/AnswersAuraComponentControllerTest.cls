@isTest
public class AnswersAuraComponentControllerTest {
	@isTest
	static void testGetAnswersWithValidCriteria() {
		// This method tests if you own a case and view them on a Lightning page, the answers background utility runs and updates case status to In Progress
		// Create a new Payroll Care Case. Do not insert the case in test data factory
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		// Set Owner Id to Logged In User Id
		objCase.OwnerId = UserInfo.getUserId();
		objCase.Prior_Agent__c = UserInfo.getUserId();
		// Insert new payroll care case with owner id as logged in user Id
		insert objCase;
		Test.startTest();
		// Set Case Status to Open and update Case
		objCase.Status = 'Open';
		update objCase;
		List<String> list_Statuses = new List<String>{ 'Awaiting Response', 'Solved', 'Closed', 'In Progress', 'Awaiting Internal Support' };
		AnswersAuraComponentController.getAnswers(objCase.Id, list_Statuses);
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status == 'In Progress', 'Answers Component - Get Answers method - Case Status not updated to In Progress');
	}

	@isTest
	static void testGetAnswersWithInvalidCriteria() {
		// Create a new Payroll Care Case.
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		Test.startTest();
		// Set Case Status to Closed
		objCase.Status = 'Closed';
		update objCase;
		List<String> list_Statuses = new List<String>{ 'Awaiting Response', 'Solved', 'Closed', 'In Progress', 'Awaiting Internal Support' };
		AnswersAuraComponentController.getAnswers(objCase.Id, list_Statuses);
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status != 'In Progress', 'Answers Component - Get Answers method -  Case Status was updated to In Progress');
	}

	@isTest
	static void testCheckPrimaryTabsWithValidCriteria() {
		// This method tests if you work on a case that you own, only the status of the case that you view should be In Progress. Remaining Case status should be Open
		// Create a new Payroll Care Case. Do not insert the case in test data factory
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		// Set Owner Id to Logged In User Id
		objCase.OwnerId = UserInfo.getUserId();
		// Insert new payroll care case with owner id as logged in user Id
		insert objCase;
		Test.startTest();
		// Set Case Status to In Progress and update Case
		objCase.Status = 'In Progress';
		update objCase;
		AnswersAuraComponentController.checkAllPrimaryTabStatus(new List<String>{ objCase.Id });
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status == 'Open', 'Answers Component - Check Primary Tabs method - Case Status not updated to Open');
	}

	@isTest
	static void testCheckPrimaryTabsWithInValidCriteria() {
		// Create a new Payroll Care Case.
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		Test.startTest();
		AnswersAuraComponentController.checkAllPrimaryTabStatus(new List<String>{ objCase.Id });
		Test.stopTest();
		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status != 'Open', 'Answers Component - Check Primary Tabs method Case Status was updated to Open');
	}

	@isTest
	static void testCloseTabStatusWithValidCriteria() {
		// This method tests if you work on a case that you own and close the tab, case status should be updated to Open
		// Create a new Payroll Care Case. Do not insert the case in test data factory
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		// Set Owner Id to Logged In User Id
		objCase.OwnerId = UserInfo.getUserId();
		// Insert new payroll care case with owner id as logged in user Id
		insert objCase;
		Test.startTest();
		// Set Case Status to In Progress and update Case
		objCase.Status = 'In Progress';
		update objCase;
		AnswersAuraComponentController.checkClosedTabStatus(objCase.Id);
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status == 'Open', 'Answers Component - Check Closed Tab Status method - Case Status not updated to Open');
	}

	@isTest
	static void testCloseTabStatusWithInValidCriteria() {
		// This method tests if you work on a case that you do not own and close the tab, case status should not be updated to Open
		// Create a new Payroll Care Case.
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		Test.startTest();
		AnswersAuraComponentController.checkClosedTabStatus(objCase.Id);
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status != 'Open', 'Answers Component - Check Closed Tab Status - Case Status was updated to Open');
	}

	@isTest
	static void testCaseInRouteUpdatedOnCloseTab() {
		// This method tests if Case in Route is getting updated when case tab is closed
		// Create a new Payroll Care Case.
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		insert objCase;
		Test.startTest();
		// Set Case In Route flag to be True
		objCase.Case_In_Route__c = true;
		objCase.Status = 'Open';
		update objCase;
		AnswersAuraComponentController.checkClosedTabStatus(objCase.Id);
		Test.stopTest();

		// Check if Case In Route was updated to false
		Case objCaseRecord = [SELECT Id, Case_In_Route__c FROM Case WHERE Id = :objCase.Id];
		System.assert(!objCaseRecord.Case_In_Route__c, 'Answers Component - Check Closed Tab Status - Case In Route was not updated to false');
	}

	@isTest
	static void testCloseTabStatusWithInvalidRecordType() {
		// This method tests if you work on an invalid record type case, status should not be updated
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		insert objCase;
		Test.startTest();
		AnswersAuraComponentController.checkClosedTabStatus(objCase.Id);
		Test.stopTest();

		// Check if Case was updated to In Progress
		Case objCaseRecord = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assert(objCaseRecord.Status != 'Open', 'Answers Component - Check Closed Tab Status - Case Status was updated to Open');
	}
}