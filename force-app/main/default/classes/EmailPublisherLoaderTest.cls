@isTest
private class EmailPublisherLoaderTest {
	static EmailMessage myMsg { get; set; }
	static Case myCase { get; set; }

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
	}

	@isTest
	static void EmailPublisherLoader_NoReplyToId() {
		Exception failureDuringExecution = null;
		init();

		//create QuickActionDefaults
		List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => myCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.Email',
				'fromAddressList' => new List<String>{ 'salesforce@test.com' }
			}
		};

		List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(defaultSettingAsObject),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);
		Test.startTest();
		try {
			EmailPublisherLoader emailLoader = new EmailPublisherLoader();
			(emailLoader).onInitDefaults(defaultsSettings);
			QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaultsSettings.get(0);
			EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
			System.assertEquals('test@test.com;test1@test.com;test2@test.com', emailMessage.CcAddress, 'CcAddress should match.');
		} catch (Exception e) {
			failureDuringExecution = e;
		}

		Test.stopTest();
	}

	static void init() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];

		myCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setType('Sales')
			.setSubject('1234 has been assigned to you')
			.setOrigin('Payroll Care Email')
			.setStatus(CaseUtils.STATUS_NEW)
			.build();
		insert myCase;

		myMsg = new EmailMessage(ParentId = myCase.Id, toAddress = 'test@test.com', ccAddress = 'test1@test.com;test2@test.com', fromAddress = 'salesforce@test.com', HtmlBody = 'id::{{12341234}}');
		insert myMsg;
	}

	@isTest
	static void EmailPublisherLoaderTestPayrollTransferCase() {
		Exception failureDuringExecution = null;
		//Create test data
		//Account
		Account account1 = new TestDataFactory.AccountBuilder().setName('TestAccount').setRecordTypeId('Company').setZPCompanyId('TestAcc001').build();
		AccountTriggerHelper.skiptrigger = true;
		insert account1;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(account1.Id)
			.setEmail('testAddress1@domain.com')
			.setFirstName('fName1')
			.setLastName('lName1')
			.build();

		List<Contact> lstContact = new List<Contact>();
		lstContact.add(objContact1);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(account1.Id)
			.setEmail('testAddress2@domain.com')
			.setFirstName('fName2')
			.setLastName('lName2')
			.build();
		lstContact.add(objContact2);

		ContactTriggerHelper.skiptrigger = true;
		insert lstContact;

		Opportunity opp1 = new Opportunity(
			Name = 'TestOpty1',
			AccountId = account1.Id,
			StageName = 'SAL',
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = System.today().addDays(30)
		);

		opp1.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		opp1.Source_Id__c = 'TestAcc001';

		OpportunityTriggerHelper.skiptrigger = true;
		insert opp1;

		Order objOrder1 = new Order(
			Status = 'Drafted',
			First_Check_Date__c = System.today().addDays(20),
			EffectiveDate = System.today().addDays(8),
			opportunityId = opp1.Id,
			AccountId = account1.Id,
			Fast_ACH__c = true,
			Agent_Email__c = 'test@agent.com'
		);
		OrderTriggerHelper.skiptrigger = true;
		insert objOrder1;

		myCase = new Case(
			Status = 'Status',
			Origin = 'Email',
			Reason = 'Reason',
			RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case'),
			Order__c = objOrder1.Id,
			ContactId = objContact1.Id
		);

		CaseTriggerHelper.skiptrigger = true;
		insert myCase;
		Bulk_Migration_Request__c bmr = new Bulk_Migration_Request__c(Bulk_Case__c = myCase.Id, Type__c = 'Bulk Migration');
		insert bmr;
		Configuration_Settings__c cs = new Configuration_Settings__c(BMR_Aditional_CC_Addresses__c = 'additional@email.com');
		insert cs;
		//Fetch case team role
		List<CaseTeamRole> lstCaseTeamRole = Database.query('SELECT Id FROM CaseTeamRole WHERE Name = \'Customer Contact\'');
		Id idCaseTRole;
		if (null != lstCaseTeamRole && lstCaseTeamRole.size() > 0) {
			idCaseTRole = lstCaseTeamRole[0].Id;
		}
		CaseTeamMember csTeamMember = new CaseTeamMember(TeamRoleId = idCaseTRole, ParentId = myCase.Id, MemberId = objContact2.Id);
		insert csTeamMember;

		myMsg = new EmailMessage(ParentId = myCase.Id, fromAddress = 'salesforce@test.com');
		insert myMsg;

		//create QuickActionDefaults
		List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => myCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.Email',
				'fromAddressList' => new List<String>{ 'salesforce@test.com' }
			}
		};

		List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(defaultSettingAsObject),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);
		Test.startTest();
		try {
			EmailPublisherLoader emailLoader = new EmailPublisherLoader();
			(emailLoader).onInitDefaults(defaultsSettings);
			QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaultsSettings.get(0);
			EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
			System.assertEquals('test@agent.com;additional@email.com', emailMessage.CcAddress, 'CcAddress should match.');
			System.assertEquals('testaddress1@domain.com;testaddress2@domain.com', emailMessage.toAddress, 'toAddress should match.');
		} catch (Exception e) {
			failureDuringExecution = e;
		}

		Test.stopTest();
	}

	@isTest
	static void EmailPublisherLoaderLEX() {
		Exception failureDuringExecution = null;
		init();

		//create QuickActionDefaults
		List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => myCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.SendEmailLTE',
				'fromAddressList' => new List<String>{ 'salesforce@test.com' }
			}
		};
		myCase.Type = 'QSEHRA';
		myCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		update myCase;

		List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(defaultSettingAsObject),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);
		Test.startTest();
		try {
			EmailPublisherLoader emailLoader = new EmailPublisherLoader();
			(emailLoader).onInitDefaults(defaultsSettings);
			QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaultsSettings.get(0);
			EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
			System.assertEquals('QSEHRA@gusto.com', emailMessage.ValidatedFromAddress, 'ValidatedFromAddress should match.');
		} catch (Exception e) {
			failureDuringExecution = e;
		}

		Test.stopTest();
	}
	/**
	 * @Author      : Alex Xiong
	 * @Description : assert investigations will set From Address to fci-risk
	 */
	@isTest
	public static void investigationsTest() {
		Exception objFailureDuringExecution = null;
		init();

		//create QuickActionDefaults
		List<Map<String, Object>> list_DefaultSettingAsObject = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => myCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.Email',
				'fromAddressList' => new List<String>{ 'salesforce@test.com' }
			}
		};

		myCase.Type = 'Investigations';
		myCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Risk Assurance');
		update myCase;

		List<QuickAction.SendEmailQuickActionDefaults> list_DefaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(list_DefaultSettingAsObject),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);

		Test.startTest();
		try {
			EmailPublisherLoader objEmailLoader = new EmailPublisherLoader();
			(objEmailLoader).onInitDefaults(list_DefaultsSettings);
			QuickAction.SendEmailQuickActionDefaults objSendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) list_DefaultsSettings.get(0);
			EmailMessage objEmailMessage = (EmailMessage) objSendEmailDefaults.getTargetSObject();
			System.assertEquals('fci-risk@gusto.com', objEmailMessage.ValidatedFromAddress, 'ValidatedFromAddress should match.');
		} catch (Exception e) {
			objFailureDuringExecution = e;
		}
		Test.stopTest();
	}

	/**
	 * @description Test R&D Tax credits Case defaults for Email activity
	 * The from address should auto populated to Default R&D Org. email
	 * @author  Ajay Krihsna P U
	 * @since   2023-06-02
	 */
	@isTest
	static void testRDTaxCredits() {
		Case objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('R&D Tax Credits').setStatus('New').setSubject('Test').setOrigin('Email').build();
		insert objCase;
		List<Map<String, Object>> list_ObjectFormat = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => objCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.Email',
				'fromAddressList' => new List<String>{ Label.R_D_Tax_Credits_Default_Case_From_Address, 'salesforce@test.com' }
			}
		};
		List<QuickAction.SendEmailQuickActionDefaults> list_ActionDefaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(list_ObjectFormat),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);

		Test.startTest();
		Boolean isRaisedException = false;
		try {
			//Initialize
			EmailPublisherLoader objPublisher = new EmailPublisherLoader();
			objPublisher.onInitDefaults(list_ActionDefaultsSettings);

			//validate
			QuickAction.SendEmailQuickActionDefaults objUpdatedSettings = (QuickAction.SendEmailQuickActionDefaults) list_ActionDefaultsSettings.get(0);
			EmailMessage objEmailMessage = (EmailMessage) objUpdatedSettings.getTargetSObject();
			System.assertEquals(Label.R_D_Tax_Credits_Default_Case_From_Address, objEmailMessage.FromAddress, 'From address did not auto populated');
		} catch (Exception objException) {
			isRaisedException = true;
		}
		System.assert(isRaisedException == false, 'Exception raised, Failed to auto populate R&D Tax credits defaults');
		Test.stopTest();
	}

	/**
	 * @description Test GEP CX Case defaults for Email activity
	 * The from address should auto populated to Default R&D Org. email
	 * @author  Deepesh Rao
	 * @since   2023-10-10
	 */
	@isTest
	static void testGEPCX() {
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCase = new TestDataFactory.CaseBuilder().setRecordTypeId('GEP CX').setStatus('New').setSubject('Test').setOrigin('Email').setContactId(list_Contact[0].Id).build();
		insert objCase;
		List<Map<String, Object>> list_ObjectFormat = new List<Map<String, Object>>{
			new Map<String, Object>{
				'targetSObject' => new EmailMessage(),
				'contextId' => objCase.Id,
				'actionType' => 'Email',
				'actionName' => 'Case.Email',
				'fromAddressList' => new List<String>{ Label.GEP_CX_Default_Case_From_Address, 'salesforce@test.com' }
			}
		};
		List<QuickAction.SendEmailQuickActionDefaults> list_ActionDefaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>) JSON.deserialize(
			JSON.serialize(list_ObjectFormat),
			List<QuickAction.SendEmailQuickActionDefaults>.class
		);

		Test.startTest();
		Boolean isRaisedException = false;
		try {
			//Initialize
			EmailPublisherLoader objPublisher = new EmailPublisherLoader();
			objPublisher.onInitDefaults(list_ActionDefaultsSettings);

			//validate
			QuickAction.SendEmailQuickActionDefaults objUpdatedSettings = (QuickAction.SendEmailQuickActionDefaults) list_ActionDefaultsSettings.get(0);
			EmailMessage objEmailMessage = (EmailMessage) objUpdatedSettings.getTargetSObject();
			System.assertEquals(Label.GEP_CX_Default_Case_From_Address, objEmailMessage.FromAddress, 'From address did not auto populated');
		} catch (Exception objException) {
			isRaisedException = true;
		}
		System.assert(isRaisedException == false, 'Exception raised, Failed to auto populate GEP CX defaults');
		Test.stopTest();
	}
}