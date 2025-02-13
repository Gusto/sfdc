@isTest
public class FollowUpEscalationCaseController_LEXTest {
	@testSetup
	static void setupData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		User objUser = new User();

		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String strDate = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer intRandom = Integer.valueOf(math.rint(math.random() * 1000000));
		String strUniqueName = orgId + strDate + intRandom;
		String strUserName = strUniqueName + '@testgusto' + orgId + '.com';

		System.runAs(objThisUser) {
			Profile objProfile = TestDataFactory.objZPSysAdminProfile;
			objUser = new TestDataFactory.UserBuilder()
				.setUniqueUserName()
				.setLastName('Test User')
				.setEmail(strUserName)
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.build();
			insert objUser;
		}

		// Create Company Accounts
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Test Company Account')
			.setJoinedDate(System.today())
			.setZPCompanyId(String.valueOf(CaseTriggerHelperTest.generateRandomId()))
			.build();
		insert objAccount;

		// Create Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objAccount.Id)
			.setFirstName('TEST CONTACT')
			.setLastName('CONTACT')
			.setPhone('1234567890')
			.setEmail('test.contact@gusto.com')
			.setZPUserId(String.valueOf(CaseTriggerHelperTest.generateRandomId()))
			.build();
		insert objContact;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	@isTest
	public static void testCreateEscalationCase() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];

		Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c();
		objCaseReasonClassification.Name = 'Test Payroll Care Reason';
		objCaseReasonClassification.Type__c = 'Payroll Care';
		objCaseReasonClassification.Active__c = true;
		insert objCaseReasonClassification;

		Case objCase = new Case();
		objCase.Status = 'New';
		objCase.Error_Origin_New__c = 'Bug';
		objCase.Description = 'Test Desc';
		objCase.Subject = 'Escalation Follo Up Case';
		objCase.Preferred_Customer_Outreach__c = 'Callback';
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		objCase.AccountId = list_Account[0].Id;
		objCase.ContactId = list_Contact[0].Id;
		Test.startTest();
		insert objCase;
		Case caseObj = FollowUpEscalationCaseController_LEX.createFollowEscalationCase(
			objCase.Id,
			'Customer',
			'Test Desc',
			'Escalation Follo Up Case',
			'Callback',
			'Test Steps',
			'Yes',
			System.now(),
			'Test Payroll Care Reason',
			'Payroll Care',
			'Payroll Care Escalation'
		);

		List<Group> list_EscalationGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'Payroll_Care_Escalation'];
		Case objQueriedCase = [SELECT Id, OwnerId, Skip_Survey__c FROM Case WHERE Origin = 'Escalation'];
		Test.stopTest();
		System.assertEquals(list_EscalationGroup[0].Id, objQueriedCase.OwnerId, 'OwnerId should match.');
		System.assert(objQueriedCase.Skip_Survey__c, 'Skip_Survey__c should be true.');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check the creation of Follow up Case of type Payroll Care with original Case of type Benefits Care.
	 **/
	@isTest
	public static void testCreateBenefitsCareEscalationCase() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];

		Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c();
		objCaseReasonClassification.Name = 'Test Payroll Care Reason';
		objCaseReasonClassification.Type__c = 'Payroll Care';
		objCaseReasonClassification.Active__c = true;
		insert objCaseReasonClassification;

		Case objCase = new Case();
		objCase.Status = 'New';
		objCase.Error_Origin_New__c = 'Bug';
		objCase.Description = 'Test Desc';
		objCase.Subject = 'Escalation Follo Up Case';
		objCase.Preferred_Customer_Outreach__c = 'Callback';
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		objCase.AccountId = list_Account[0].Id;
		objCase.ContactId = list_Contact[0].Id;

		Test.startTest();
		insert objCase;
		Case caseObj = FollowUpEscalationCaseController_LEX.createFollowEscalationCase(
			objCase.Id,
			'Customer',
			'Test Desc',
			'Escalation Follo Up Case',
			'Callback',
			'Test Steps',
			'Yes',
			System.now(),
			'Test Payroll Care Reason',
			'Payroll Care',
			'Payroll Care Escalation'
		);

		List<Group> list_EscalationGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Payroll_Care_Escalation'];
		List<Case> list_QueriedCases = [SELECT Id, RecordTypeId, Type, OwnerId, Origin, Skip_Survey__c FROM Case];
		Test.stopTest();
		for (Case objQueriedCase : list_QueriedCases) {
			if (objQueriedCase.Origin == 'Escalation') {
				System.assertEquals(list_EscalationGroup[0].Id, objQueriedCase.OwnerId, 'Escalation Case should go to Escalation queue');
				System.assert(objQueriedCase.Skip_Survey__c, 'Skip_Survey__c should be true.');
			} else {
				System.assertNotEquals(list_EscalationGroup[0].Id, objQueriedCase.OwnerId, 'Parent Case should not be in Escalation queue');
				System.assert(!objQueriedCase.Skip_Survey__c, 'Skip_Survey__c should be true.');
			}
			System.assertEquals('Payroll Care', Cache.getRecordTypeName('Case', objQueriedCase.RecordTypeId), 'Parent and Escalation Case should be same record type');
			System.assertEquals('Payroll Care', objQueriedCase.Type, 'Parent and Escalation Case should have same Type');
		}
	}

	public static void testInsertFeedComments() {
		List<Case> lst_case = new List<Case>();
		Case objCase = new Case();
		objCase.Status = 'New';

		Case objCaseNew = new Case();
		objCaseNew.Status = 'New';
		objCaseNew.Description = 'Test Desc';

		lst_case.add(objCase);
		lst_case.add(objCaseNew);
		insert lst_case;

		Test.startTest();
		FollowUpEscalationCaseController_LEX.insertChatterFeed(objCase.Id, '589702', objCaseNew.Id);
		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Tests creating escalation case without case reason
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/

	@isTest
	public static void testCreateEscalationCaseNoCaseReason() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setType('Payroll Care')
			.setSubject('Test Parent Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.build();

		insert objCase;

		Test.startTest();
		Case objEscCase = FollowUpEscalationCaseController_LEX.createFollowEscalationCase(
			objCase.Id,
			'Customer',
			'Test Desc',
			'Escalation Follow Up Case',
			'Callback',
			'Test Steps',
			'Yes',
			System.now(),
			'',
			'Payroll Care',
			'Payroll Care Escalation'
		);

		List<Group> list_EscalationGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'Payroll_Care_Escalation'];
		Case objQueriedCase = [SELECT Id, OwnerId, RecordTypeId, Skip_Survey__c FROM Case WHERE Origin = 'Escalation'];
		Test.stopTest();
		System.assertEquals(objQueriedCase.RecordTypeId, objCase.RecordTypeId, 'RecordTypeId should match.');
		System.assertEquals(list_EscalationGroup[0].Id, objQueriedCase.OwnerId, 'OwnerId should match.');
		System.assert(objQueriedCase.Skip_Survey__c, 'Skip_Survey__c should be true.');
	}
}