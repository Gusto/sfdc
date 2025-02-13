@isTest
public class QAPlayControllerTest {
	@TestSetup
	static void setup() {
		List<Case> list_Cases = new List<Case>();

		List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>{
			new Case_Reason_Classification__c(
				Name = 'Account Takeover',
				Class__c = 'Class 1',
				Type__c = 'Benefits Care',
				Generic_Routing_Reason__c = false,
				Active__c = true
			),
			new Case_Reason_Classification__c(
				Name = 'Gusto Giving',
				Class__c = 'Class 1',
				Type__c = 'Benefits Care',
				Generic_Routing_Reason__c = false,
				Active__c = true
			)
		};
		insert list_CaseReasons;

		Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];

		User objUser = new User(
			Alias = 'standt',
			Email = 'standarduser@testorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'Testing',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = testProfile.Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'standarduser1111@testorg.com',
			ManagerId = UserInfo.getUserId()
		);
		UserTriggerHelper.skipTrigger = true;
		insert objUser;
		UserTriggerHelper.skipTrigger = false;

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		// Create Company Accounts
		Account objAccount = new Account();
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAccount.Name = 'TEST ACCOUNT';
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_ID__c = String.valueOf(CaseTriggerHelperTest.generateRandomId());
		insert objAccount;

		// Create Company Contact
		Contact objContact = new Contact();
		objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
		objContact.AccountId = objAccount.Id;
		objContact.FirstName = 'TEST CONTACT';
		objContact.LastName = 'CONTACT';
		objContact.Phone = '1234567890';
		objContact.Email = 'test.contact@gusto.com';
		objContact.ZP_User_Id__c = String.valueOf(CaseTriggerHelperTest.generateRandomId());
		insert objContact;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case objCase1 = new Case(
			Subject = 'objCase1',
			Description = 'Desc',
			RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care - Read Only'),
			Type = 'Benefit Care',
			Origin = 'Phone',
			Direction__c = 'Inbound',
			SuppliedPhone = '1234567890',
			Class__c = 'Class 2',
			Confirm_Case_Reason__c = 'Gusto Giving',
			Status = 'Closed',
			OwnerId = objUser.Id,
			Authorized_User__c = 'Yes',
			AccountId = objAccount.Id,
			ContactId = objContact.Id
		);
		list_Cases.add(objCase1);

		Case objParent = new Case(
			Subject = 'Parent Case 1',
			Description = 'Desc',
			RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care - Read Only'),
			Type = 'Benefits Care',
			Origin = 'Email',
			Direction__c = 'Inbound',
			SuppliedEmail = 'test@test.com',
			Class__c = 'Class 1',
			Confirm_Case_Reason__c = 'Account Takeover',
			Status = 'Closed',
			OwnerId = objUser.Id,
			Authorized_User__c = 'Yes',
			AccountId = objAccount.Id,
			ContactId = objContact.Id
		);
		list_Cases.add(objParent);

		Case objCaseClosed = new Case(
			Subject = 'objCaseClosed',
			Description = 'Desc',
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care - Read Only'),
			Type = 'Payroll Care',
			Origin = 'Email',
			Direction__c = 'Inbound',
			SuppliedPhone = '1234567890',
			Class__c = 'Class 2',
			Status = 'Closed',
			Authorized_User__c = 'Yes',
			AccountId = objAccount.Id,
			ContactId = objContact.Id
		);
		list_Cases.add(objCaseClosed);

		Case objCaseSolved = new Case(
			Subject = 'objCaseSolved',
			Description = 'Desc',
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Type = 'Payroll Care',
			Origin = 'Email',
			Direction__c = 'Inbound',
			SuppliedPhone = '1234567890',
			Class__c = 'Class 2',
			Status = 'Solved',
			Authorized_User__c = 'Yes',
			Confirm_Case_Reason__c = 'payroll',
			Date_Time_Solved__c = System.now(),
			AccountId = objAccount.Id,
			ContactId = objContact.Id
		);
		list_Cases.add(objCaseSolved);

		System.runAs(objUser) {
			CaseTriggerHelper.skipTrigger = true;
			insert list_Cases;
			CaseTriggerHelper.skipTrigger = false;
		}

		Case objEscalation = new Case(
			Subject = 'Child Case 1',
			Description = 'Desc',
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Type = 'Payroll Care',
			Origin = 'Escalation',
			Direction__c = 'Inbound',
			SuppliedEmail = 'test@test.com',
			ParentId = objParent.Id,
			Authorized_User__c = 'Yes',
			OwnerId = objUser.Id,
			AccountId = objAccount.Id,
			ContactId = objContact.Id
		);
		CaseTriggerHelper.skipTrigger = true;
		insert objEscalation;
		CaseTriggerHelper.skipTrigger = false;

		Case_Survey_Response__c objSurvey1 = new Case_Survey_Response__c(
			How_satisfied_are_you_with_service__c = 4,
			How_easy_did_we_make_it_for_you__c = 5,
			Case__c = objCase1.Id
		);
		insert objSurvey1;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests QAPlayController.queryReasons()
	 **/
	@isTest
	public static void testQueryReasons() {
		Test.startTest();
		Map<String, Map<Id, String>> map_Reasons = QAPlayController.queryReasons();
		System.assertEquals(false, map_Reasons.isEmpty());
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests QAPlayController.queryUsers()
	 **/
	@isTest
	static void testGetUsers() {
		Test.startTest();
		List<User> list_Users = QAPlayController.queryUsers(true);
		System.assertEquals(false, list_Users.isEmpty());
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests QAPlayController.queryCases(). Makes sure list_CaseWithGoodCSAT != list_CaseWithBadCSAT
	 **/
	@isTest
	static void testQueryCases() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Alias = 'standt'];
		List<Case> list_CaseWithGoodCSAT = QAPlayController.queryCases(
			objUser.Id,
			System.today().addDays(-1),
			System.today().addDays(2),
			'Class 2',
			'Benefits Care',
			'Gusto Giving',
			'Phone',
			'Good',
			'All Cases'
		);
		List<Case> list_CaseWithBadCSAT = QAPlayController.queryCases(
			objUser.Id,
			System.today().addDays(-1),
			System.today().addDays(2),
			'Class 2',
			'Benefits Care',
			'Gusto Giving',
			'Phone',
			'Bad',
			'All Cases'
		);

		System.assertNotEquals(list_CaseWithBadCSAT.size(), list_CaseWithGoodCSAT.size());
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests QAPlayController.queryCases(). Makes sure Escalation filter works properly
	 **/
	@isTest
	public static void testEscalationQA() {
		Test.startTest();
		User objUser = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com'];

		List<Case> list_Cases = QAPlayController.queryCases(
			objUser.Id,
			System.today().addDays(-1),
			System.today().addDays(2),
			'Class 1',
			'Benefits Care',
			'Account Takeover',
			'Email',
			'Any',
			'Escalated Cases'
		);

		System.assertEquals(1, list_Cases.size());
		Test.stopTest();
	}

	/**
	 * @Author          : Alex Xiong
	 * @Description     : tests if solved and closed cases can be queried
	 */
	@isTest
	public static void testClosedAndSolved() {
		Test.startTest();
		List<Case> list_Cases = [
			SELECT Id, Subject, RecordType.Name, Solved_Closed_Date_Time__c, Status, Class__c
			FROM Case
			WHERE RecordType.Name LIKE 'Payroll Care%' AND (Status = 'Closed' OR Status = 'Solved')
		];

		User objUser = [SELECT Id FROM User WHERE Email = 'standarduser@testorg.com'];

		List<Case> list_QAPlayCases = QAPlayController.queryCases(
			objUser.Id,
			System.today().addDays(-1),
			System.today().addDays(2),
			'Any',
			'Payroll Care',
			'',
			'Any',
			'Any',
			'All Cases'
		);

		System.assertEquals(list_Cases.size(), list_QAPlayCases.size());
		Test.stopTest();
	}
}