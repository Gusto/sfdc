/**
Created by : Prity Kumari & Old Authors
Created Date : 04/03/2023
**/
@isTest
public class ZPAccountingFirmTriggerHelperTest {
	@testSetup
	static void setupTestData() {
		List<UserRole> list_roles = [SELECT Id FROM UserRole WHERE Name IN ('sales_sdr_partner_xx', 'sales_partner_ae_xx')];
		User objMDRUser = new TestDataFactory.UserBuilder()
			.setIsActive(true)
			.setProfileId(UserInfo.getProfileId())
			.setUserName('mdruser@testgusto.com')
			.setLastName('MDR User')
			.setEmail('mdruser@testorg.com')
			.setAlias('mdrusr')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setLocaleSidKey('en_US')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setCalendarLink('testCalendarLink')
			.setUserRoleId(list_roles.get(0).Id)
			.setExemptfromValidationRules(true)
			.build();

		User objPartnerUser = new TestDataFactory.UserBuilder()
			.setAlias('ptruser')
			.setEmail('partneruser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User1')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partneruser@testgusto.com')
			.setUserRoleId(list_roles[1].Id)
			.build();
		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objcurrentUser) {
			insert new List<User>{ objMDRUser, objPartnerUser };
		}
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('7000000001').setEmail('testhpq01@gmail.com').setName('HPQ 01').build();
		insert objZPAccFirm;
	}

	@isTest
	static void createNewFirmWithOutExistingLead() {
		ZPAccountingFirmTriggerHelper.queue = true;
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setEmail('test.abc@gusto.com')
			.setName('Test Accountant')
			.setCustRewardElg(1)
			.setCustRewardInElg(2)
			.setSetupCustRewardElg(1)
			.build();

		insert objZPAccFirm;

		ZP_Accounting_Firm__c zpFirm = [SELECT Id, processing_state__c FROM ZP_Accounting_Firm__c WHERE id = :objZPAccFirm.id];

		Account objAcctAssert = [
			SELECT Id, ZP_Firm_ID__c, Customers_Reward_Eligible__c, Customers_Reward_Ineligible__c, Setup_Customers_Reward_Eligible__c, Setup_Customers_Reward_Ineligible__c
			FROM Account
			WHERE ZP_Firm_ID__c = '11111111111111'
		];
		System.assertEquals(1, objAcctAssert.Customers_Reward_Eligible__c, 'Customer Reward Eligible value is not correct.');
		System.assertEquals(2, objAcctAssert.Customers_Reward_Ineligible__c, 'Customer Reward Ineligible value is not correct.');
		System.assertEquals(1, objAcctAssert.Setup_Customers_Reward_Eligible__c, 'Setup Customer Reward Eligible value is not correct.');
		System.assertEquals(0, objAcctAssert.Setup_Customers_Reward_Ineligible__c, 'Setup Customer Reward Ineligible value is not correct.');
	}

	@isTest
	static void createNewFirmWithExistingLead() {
		ZPAccountingFirmTriggerHelper.queue = true;

		LeadTriggerHelper.skipTrigger = true;
		Lead lead = new TestDataFactory.LeadBuilder()
			.setZPFirmId('11111111111111')
			.setZPCompanyLeadID('222222222222')
			.setFirstName('test')
			.setLastName('test')
			.setCompany('Test Accountant')
			.setEmail('test.test@gusto.com')
			.setRecordTypeId(Cache.getRecordTypeId('Lead', 'Reseller'))
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert lead;

		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c zpFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setName('Test Accountant')
			.setProcessingState('Queued')
			.setCreatedAt(System.today())
			.setEmail('test.test@gusto.com')
			.build();
		insert zpFirm;

		zpFirm = [SELECT Id, Processing_State__c, Message__c FROM ZP_Accounting_Firm__c WHERE id = :zpFirm.id];
		System.assertequals('Processed', zpFirm.Processing_State__c, 'ZP Accounting Firm should be in a processed state');
		Account acc = [SELECT Id, ZP_Firm_ID__c, Name FROM Account WHERE ZP_Firm_ID__c = '11111111111111'];
		System.assertequals(acc.Name, 'Test Accountant', 'Accounting Firm name is incorrect');
		Test.stopTest();
		update zpFirm;
		delete zpFirm;
	}

	/*** Tests if Lead conversion via ZP Accounting firm sets MQL reason as Gusto for Partners to converted Lead ***/
	@isTest
	static void testZPAccountingFirmLeadConversion() {
		Lead objLead = TestUtils.createNewLead(
			Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Reseller').getRecordTypeId(),
			'FName',
			'LName',
			'email@zpfirm.com',
			'123456789',
			'ZP Firm Lead',
			true
		);

		Test.startTest();
		TestUtils.createZPAccountingFirm('15975328542', 'Test ZP Accounting Firm', objLead.Email, true);
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, Status, MQL_Reason__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(Config.LeadConversion.CONVERTED_LEAD_STATUS, objLeadAssert.Status, 'Lead status is incorrect');
		System.assertEquals('Gusto for Partners', objLeadAssert.MQL_Reason__c, 'MQL Reason is incorrect');
	}

	/*** When no lead already exists, test if ZP Accounting Firm Creates and Converts Leads ***/
	@isTest
	static void testAutoCreateLeadOnAccountingFirmInsert() {
		LeadTriggerHelper.skipTrigger = true;
		// This ZP Accounting Firm record does not require creating Leads before. Hence, not using test setup method
		ZP_Accounting_Firm__c objFirm = new ZP_Accounting_Firm__c(
			Id__c = '753159456',
			Name__c = 'Test Name',
			Created_by_Email__c = 'test@testgusto.com',
			Lead_First_Name__c = 'Test FName',
			Lead_Last_Name__c = 'Test LName',
			Lead_Phone__c = '123456789',
			Lead_Number_Of_Clients__c = 10,
			Lead_Source__c = 'Web'
		);
		Test.startTest();
		insert objFirm;
		Test.stopTest();

		// Assert if Lead is created and converted
		List<Lead> list_Leads = [SELECT Id, IsConverted, Status FROM Lead WHERE Email = 'test@testgusto.com'];
		System.assertEquals(1, list_Leads.size(), 'List size is not equal to 1');
		System.assertEquals(true, list_Leads.get(0).IsConverted, 'Lead is not converted');
		System.assertEquals(Config.LeadConversion.CONVERTED_LEAD_STATUS, list_Leads.get(0).Status, 'Lead status should be converted');

		// Assert if Lead is converted into Contact
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE Email = 'test@testgusto.com'];
		System.assertEquals(1, list_Contacts.size(), 'Contact list size is not equal to 1');

		// Assert if Lead is converted into Account
		List<Account> list_Accounts = [SELECT Id FROM Account WHERE Id = :list_Contacts.get(0).AccountId];
		System.assertEquals(1, list_Accounts.size(), 'Account list size is not equal to 1');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Assert if Accountant Lead Id is updated on Lead from ZP Accounting Firm
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testAccountantLeadIdUpdate() {
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setLeadSource('adwords')
			.setCompany('Reseller Lead 1')
			.build();
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('111111122222')
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('1212121')
			.build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted and Accountant Lead Id got set
		Lead objLeadAssert = [SELECT Id, IsConverted, ZP_Accountant_Lead_ID__c FROM Lead WHERE Id = :objLead.Id];

		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');
		System.assertEquals(objZPAccFirm.Accountant_Lead_ID__c, objLeadAssert.ZP_Accountant_Lead_ID__c, 'Accountant Lead Id is not set correctly');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Reseller Leads are converted based on matching email address
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionBasedOnEmail() {
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.build();
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('111111122222').setEmail(objLead.Email).setName('test name').build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted and firm id is populated
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ZP_Firm_Id__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Lead converted account id is not set correctly');
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId, 'Lead converted contact id is not set correctly');
		System.assertEquals(objZPAccFirm.Id__c, objLeadAssert.ZP_Firm_Id__c, 'Accounting Firm Id is not set correctly');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Test if Reseller Leads are converted based on matching accountant lead id
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionBasedOnAccountantLeadId() {
		LeadTriggerHelper.skipTrigger = true;
		String strInitialEmail = 'reseller@normalizeddomain.com';
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail(strInitialEmail)
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.setZPAccountantLeadID('8767877')
			.build();
		insert objLead;

		// Mimic scenario when email is manually changed by rep
		objLead.Email = 'emailchangebyrep@change.com';
		objLead.Status = LeadUtil.LEAD_STATUS_AQL;
		update objLead;

		LeadTriggerHelper.skipTrigger = false;

		// Create firm with lead accountant id
		// Result = Accounting Firm should be able to identify resller lead based on accountant lead id
		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('111111122222')
			.setEmail(strInitialEmail)
			.setName('test name')
			.setAccountantLeadId(objLead.ZP_Accountant_Lead_Id__c)
			.build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted and firm id is populated
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ZP_Firm_Id__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Lead converted account id is not set correctly');
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId, 'Lead converted contact id is not set correctly');
		System.assertEquals(objZPAccFirm.Id__c, objLeadAssert.ZP_Firm_Id__c, 'Accounting Firm Id is not set correctl');
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Assert if Account Lookup is updated on ZP Accounting Firm.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testAccountLookupUpdate() {
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.build();
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('firmId01')
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('AccLeadId01')
			.build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted.
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Lead converted account id is not set correctly');

		ZP_Accounting_Firm__c objZPAccFirmAssert = [SELECT Id, Account__c FROM ZP_Accounting_Firm__c WHERE Id = :objZPAccFirm.Id];
		System.assertEquals(objLeadAssert.ConvertedAccountId, objZPAccFirmAssert.Account__c, 'Lead did not convert correctly into existing account');
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Assert if Sales Engagment Status is updated to False SAL and Detail is updated to Pre-MDR
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testSaleEngagmentProspectiveUpdate() {
		User objMDRUser = [SELECT Id FROM User WHERE Email = 'mdruser@testorg.com'];
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@falsesal.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.setOwnerId(objMDRUser.Id)
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setLeadSource(LeadUtil.LEADSOURCE_ABC)
			.build();
		insert objLead;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('8756987').setEmail(objLead.Email).setName('test name').build();
		insert objZPAccFirm;

		Test.stopTest();

		Account objAccAssert = [SELECT Id, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c FROM Account WHERE ZP_Firm_Id__c = :objZPAccFirm.Id__c];
		System.assertEquals(ZPAccountingFirmUtil.ACC_SALES_ENGMNT_PROSPECTIVE, objAccAssert.Sales_Engagement_Status__c, 'Sales Engagement Status is not set correctly');
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Test if Matching ZP Accounting Firm by email,managing firm id with company then reprocess the ZP Companies
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	private static void testMatchingZPCompanyByEmailOnZPAcctFirm() {
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account 1').setZPFirmId('setupfirmId1').build();
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		Test.startTest();

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setCreatedAtDate(System.today())
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_Id__c)
			.build();
		insert objZPCompany;

		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId(objResellerAccount.ZP_Firm_Id__c)
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('1212121')
			.build();
		insert objZPAccFirm;

		ZP_Company__c objCompany = [SELECT Id, Deleted_At__c, ID__c, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objCompany.Processing_State__c, 'Company is not processed');

		Test.stopTest();
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Assert if fields on Accounts is updated when Accountants merged in Panda
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerAccountMergeAutomation() {
		ZP_Accounting_Firm__c objZPAccFirmRec = [SELECT Id, Name, ID__c FROM ZP_Accounting_Firm__c WHERE ID__c = '7000000001'];
		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@gmail.com')
			.setPhone('123456789')
			.setCompany('Reseller Lead')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource('adwords')
			.setStatus(LeadUtil.LEAD_STATUS_DISC_CALL_SCH)
			.build();
		insert objLead;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('87867867').setEmail(objLead.Email).setName('test name').build();
		insert objZPAccFirm;

		ZP_Accounting_Firm__c objZPAccFirmUpdate = [SELECT Id, Processing_State__c, Message__c FROM ZP_Accounting_Firm__c WHERE Id = :objZPAccFirm.Id];
		objZPAccFirmUpdate.Merged_Firm_ID__c = objZPAccFirmRec.Id__c;
		update objZPAccFirmUpdate;
		System.assertEquals(IntegrationUtils.QUEUED_STATE, objZPAccFirmUpdate.Processing_State__c, 'Accounting Firm is not processed');
		Test.stopTest();

		// Assert Lead got converted.
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');

		//Assert Account Update Merge Operation
		Account objAcc = [SELECT Id, Name, Possible_Duplicate_Account__c, Is_Duplicate__c FROM Account WHERE Id = :objLeadAssert.ConvertedAccountId];
		System.assertEquals(true, objAcc.Is_Duplicate__c, 'Duplicate Flag is not set');
	}
	/**
	 * @Author      : Prity Kumari
	 * @Description : Assert if Account ownership does not change on lead conversion if owner is partner
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionPartnerOwner() {
		map<String, User> map_Users = new Map<String, User>();
		for (User objUser : [SELECT Id, Email FROM User WHERE Email IN ('partneruser@testorg.com', 'mdruser@testorg.com')]) {
			map_Users.put(objUser.Email, objUser);
		}

		LeadTriggerHelper.skipTrigger = true;
		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.setOwnerId(map_Users.get('mdruser@testorg.com').Id)
			.build();
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			.setName('Test Reseller Account 2')
			.setZPFirmId('111111122222')
			.setOwnerId(map_Users.get('partneruser@testorg.com').Id)
			.build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('111111122222')
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('1212121')
			.build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted and Account stayed in partner's name
		Account objAccountAssert = [SELECT Id, OwnerId FROM Account WHERE ZP_Firm_ID__c = '111111122222'];
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Email = 'reseller@normalizeddomain.com'];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead  is not converted');
		System.assertEquals(objAccountAssert.Id, objLeadAssert.ConvertedAccountId, 'Lead did not convert properly');
		System.assertEquals(map_Users.get('partneruser@testorg.com').Id, objAccountAssert.OwnerId, 'Account Owner is incorrect');
	}

	/**
	 * @Author      : Prity Kumari
	 * @Description : Assert if circular depemdemcy is handled for Lead Conversion
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionCircularDependency() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Test Reseller Account 2').setZPFirmId('111111122222').build();
		insert objAccount;
		AccountTriggerHelper.skipTrigger = false;

		// Create a new reseller lead. Skip Lead Trigger for faster lead inserts
		LeadTriggerHelper.skipTrigger = true;
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('reseller@normalizeddomain.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead 1')
			.setReferredBy(objAccount.Id)
			.build();
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;
		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('111111122222')
			.setEmail(objLead.Email)
			.setName('test name')
			.setAccountantLeadId('1212121')
			.build();
		insert objZPAccFirm;
		Test.stopTest();
		Lead objAssertLead = [SELECT Id, IsConverted, ConvertedAccountId, Referred_By__c FROM Lead WHERE Email = 'reseller@normalizeddomain.com' LIMIT 1];
		System.assertEquals(true, objAssertLead.IsConverted, 'Lead is not converted');
		System.assertEquals(objAccount.Id, objAssertLead.ConvertedAccountId, 'Lead did not convert properly');
		System.assertNotEquals(objAccount.Id, objAssertLead.Referred_By__c, 'Lead should not have referred by account');
	}

	/**
	 * @Description : Test if failing reseller leads are reprocessed
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionInactiveUser() {
		User objInactiveUser = [SELECT Id FROM User WHERE IsActive = FALSE AND userType != 'Guest' LIMIT 1][0];
		// Create a new reseller lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('Name')
			.setLastName('LName')
			.setEmail('resellerlead@inactiveuser.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead Inactive User')
			.setOwnerId(objInactiveUser.Id)
			.build();
		insert objLead;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('987654321012').setEmail(objLead.Email).setName('Reseller Lead Inactive User').build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead got converted and firm id is populated
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ZP_Firm_Id__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId, 'Lead converted account id is not set correctly');
		System.assertNotEquals(null, objLeadAssert.ConvertedContactId, 'Lead converted contact id is not set correctly');
		System.assertEquals(objZPAccFirm.Id__c, objLeadAssert.ZP_Firm_Id__c, 'Accounting Firm Id is not set correctly');
	}

	/**
	 * @Description : Test handling if failing reseller leads that are reprocessed errors out
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testResellerLeadConversionInactiveUserError() {
		User objInactiveUser = [SELECT Id FROM User WHERE IsActive = FALSE AND userType != 'Guest' LIMIT 1][0];
		// Create a new reseller lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('Name')
			.setLastName('LName')
			.setEmail('resellerlead@inactiveuser.com')
			.setLeadSource('Sourcing Error')
			.setPhone('123456789')
			.setCompany('Reseller Lead Inactive User')
			.setOwnerId(objInactiveUser.Id)
			.build();
		insert objLead;

		LeadConvertQueueable.idOwner = objInactiveUser.Id;

		Test.startTest();
		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder().setZPFirmId('987654321012').setEmail(objLead.Email).setName('Reseller Lead Inactive User').build();
		insert objZPAccFirm;
		Test.stopTest();

		// Assert Lead did not get converted
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ZP_Firm_Id__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, !objLeadAssert.IsConverted, 'Lead conversion should throw error');
	}
}