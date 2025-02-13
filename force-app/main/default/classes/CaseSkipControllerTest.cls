@isTest
public class CaseSkipControllerTest {
	static testMethod void testUserPreference() {
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);

		// Insert new user preference
		User_Preference__c objUserPreference = new User_Preference__c(User__c = UserInfo.getUserId(), Number_to_Serve_Up__c = 1);
		insert objUserPreference;

		Test.startTest();
		List<User_Preference__c> list_userPreference = CaseSkipController.getUserPreference(objCase.Id).list_userPreference;
		// Ensures only one user preference record is inserted for logged in user
		System.assertEquals(1, list_userPreference.size(), 'No user preference record found for logged in user');
		Test.stopTest();
	}

	static testMethod void testskipCaseRecordWithValidCase() {
		// Create a new Payroll Care Case
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('TEST ACCOUNT')
			.setJoinedDate(System.today())
			.setZPCompanyId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('TEST1')
			.setLastName('Con1')
			.setEmail('ttest1con@test.com')
			.setZPUserId(String.valueOf(Utils.getRandomIntValue(10)))
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test subject')
			.setStatus('New')
			.setType('Payroll Care')
			.setOrigin('Phone')
			.setDirection('Inbound')
			.setSuppliedEmail('ttest1con@test.com')
			.setOwnerId(UserInfo.getUserId())
			.build();
		
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = false;
		objCase.setOptions(dmo);
		insert objCase;

		Test.startTest();
		// Skip newly created case, provide a skip comment
		Case caseReturned = CaseSkipController.skipCaseRecord(objCase.Id, 'Test skip comment');
		Test.stopTest();

		// Check if case skip history record is created
		Integer intCaseSkipHistoryCount = [SELECT COUNT() FROM Case_Skip_History__c WHERE Case__c = :objCase.Id];
		System.assertEquals(1, intCaseSkipHistoryCount, 'Case skip history records not inserted');
	}

	static testMethod void testskipCaseRecordWithInValidCase() {
		Test.startTest();
		// Pass an invalid case Id
		Case objCaseReturned = CaseSkipController.skipCaseRecord(null, 'Test skip comment');
		Test.stopTest();
		// Check Case Skip History record should not be created. Exceptions should be handled when method receieves invalid case ids
		System.assertEquals(true, objCaseReturned == null, 'Case Skip History exception not handled');
	}
}