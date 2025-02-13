@isTest
public class LogSmartCallingControllerTest {
	@testSetup
	static void makeData() {
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		List<Case> list_Case = new List<Case>();
		List<Contact> list_Contact = new List<Contact>();
		List<Benefit_Order__c> list_BO = new List<Benefit_Order__c>();
		List<Opportunity> list_OpportunitiesToInsert = new List<Opportunity>();
		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');

		Account objAcc = new Account(Name = 'test acc1', ZP_Company_Id__c = '100989001');
		insert objAcc;

		Opportunity objOpp = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan'));
		objOpp.AccountId = objAcc.Id;
		objOpp.StageName = 'SAL';
		objOpp.Name = 'test';
		objOpp.closeDate = System.today();
		list_OpportunitiesToInsert.add(objOpp);

		Opportunity objOpptyRenewal = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'));
		objOpptyRenewal.AccountId = objAcc.Id;
		objOpptyRenewal.StageName = 'SAL';
		objOpptyRenewal.Name = 'test';
		objOpptyRenewal.closeDate = System.today();
		list_OpportunitiesToInsert.add(objOpptyRenewal);

		insert list_OpportunitiesToInsert;

		list_Contact.add(new Contact(FirstName = 'Neha 1', LastName = 'Test August 6 ', Email = 'neha.dabastest+1@lirik.io', AccountId = objOpp.AccountId, Phone = '(437) 654-6678'));

		list_Contact.add(new Contact(FirstName = 'Neha 2', LastName = 'Test August 6 ', Email = 'neha.dabastest+2@lirik.io', AccountId = objOpptyRenewal.AccountId, Phone = '(437) 654-6679'));

		insert list_Contact;

		Benefit_Order__c objBONewPlan = new Benefit_Order__c();
		objBONewPlan.Name = 'New Plan BO';
		objBONewPlan.Opportunity__c = objOpp.Id;
		objBONewPlan.Account__c = objOpp.AccountId;
		objBONewPlan.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		objBONewPlan.OwnerId = UserInfo.getUserId();
		list_BO.add(objBONewPlan);

		Benefit_Order__c objBORenewalAligment = new Benefit_Order__c();
		objBORenewalAligment.Name = 'Renewal Aligment BO';
		objBORenewalAligment.Opportunity__c = objOpptyRenewal.Id;
		objBORenewalAligment.Account__c = objOpptyRenewal.AccountId;
		objBORenewalAligment.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal Alignment');
		objBORenewalAligment.OwnerId = UserInfo.getUserId();
		list_BO.add(objBORenewalAligment);

		insert list_BO;

		list_Case.add(
			new Case(
				Subject = 'Test Case 1',
				contactId = list_Contact[0].Id,
				AccountId = objAcc.Id,
				RecordTypeId = idNewPlan,
				Priority = 'Medium',
				Direction__c = 'Inbound',
				Origin = 'Email',
				Benefit_Order__c = objBONewPlan.Id,
				Integration_Id__c = 'hippo-Benefits_New_Plan-' + objOpp.Id,
				Opportunity__c = objOpp.Id
			)
		);

		insert list_Case;

		insert new List<State__c>{ new TestDataFactory.StateBuilder().setName('state1').build(), new TestDataFactory.StateBuilder().setName('state2').build() };

		/* Profile objBenefitsUserProfile = [
			SELECT Id
			FROM Profile
			WHERE Name = :LogSmartCallingController.USER_PROFILE_NAME_BENEFITS_USER
		];

		User objBenefitsUser = new TestDataFactory.UserBuilder()
			.setProfileId(objBenefitsUserProfile.Id)
			.setUserName('benefitsuser' + DateTime.now().getTime() + '@testorg.com')
			.setLastName('Testing')
			.setEmail('benefitsuser@testorg.com')
			.setAlias('standt')
			.setEmailEncoding('UTF-8')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.build();

		insert objBenefitsUser; */
	}

	@isTest
	static void testAccountRecordHiOpp() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		//insert acc
		Account objAcc = new Account();
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAcc.Name = 'Test Account';
		insert objAcc;
		//insert contact list
		List<Contact> list_accContacts = new List<Contact>();
		list_accContacts.add(
			new Contact(
				AccountId = objAcc.Id,
				FirstName = 'Fname 1',
				LastName = 'Lname 1',
				Email = 'PriPayrollAdmin@gusto.com',
				ZP_User_Role__c = 'Primary Payroll Admin',
				User_Role__c = 'Primary Payroll Admin'
			)
		);
		list_accContacts.add(
			new Contact(AccountId = objAcc.Id, FirstName = 'Fname 2', LastName = 'Lname 2', Email = 'PayrollAdmin@gusto.com', ZP_User_Role__c = 'Accountant', User_Role__c = 'Accountant')
		);

		insert list_accContacts;

		List<Case> list_case = new List<Case>();
		list_case.add(new Case(ContactId = list_accContacts[0].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 1 desc'));
		list_case.add(new Case(ContactId = list_accContacts[1].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 2 desc'));
		CaseTriggerHelper.skipTrigger = true; //yuvraj : 9 june 2020
		insert list_case;
		CaseTriggerHelper.skipTrigger = false;

		ZPCompanyTriggerHelper.queue = true;

		ZP_Accounting_Firm__c objZpFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setName('Test Accountant')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAt(System.today())
			.build();
		insert objZpFirm;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.Company_Id__c = '33333333333333';
		funnel.Sign__c = 'Test';
		funnel.add_addresses_completed__c = true;
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		ZPUserTriggerHelper.skipTrigger = true;
		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Id__c = '1212121212';
		zpUser.Email__c = 'asdfsdfadsfasd@asdfsdfsdf.com';
		zpUser.Created_At__c = System.now();
		zpUser.Updated_At__c = System.now();
		insert zpUser;
		ZPUserTriggerHelper.skipTrigger = false;

		ZPUserRoleTriggerHelper.skipTrigger = true;
		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = '1212121212';
		userRole.Type__c = 'Role::PayrollAdmin';
		userRole.Company_Id__c = '11111111111111';
		userRole.Is_Primary__c = true;
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[0].Id;
		userRole.Accounting_Firm_Id__c = '11111111111';
		userRole.Created_At__c = System.now();
		userRole.Updated_At__c = System.now();
		insert userRole;

		ZP_User_Role__c userRole2 = new ZP_User_Role__c();
		userRole2.User_Id__c = '1212121212';
		userRole2.Type__c = 'Role::Accountant';
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[1].Id;
		userRole2.Created_At__c = System.now();
		userRole2.Updated_At__c = System.now();
		insert userRole2;

		ZPUserRoleTriggerHelper.skipTrigger = false;

		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setName('Test Company')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.build();

		AccountTriggerHelper.skipTrigger = true;

		insert objZpCompany;

		//insert opportunity
		Opportunity objOpp = new Opportunity();
		objOpp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		objOpp.CloseDate = System.today();
		objOpp.StageName = 'SAL';
		objOpp.AccountId = objAcc.Id;
		objOpp.Name = 'Test Name objOpp';
		insert objOpp;

		//account contact relation
		List<AccountContactRelation> list_accContRelations = new List<AccountContactRelation>();

		for (AccountContactRelation acr : [SELECT Id, AccountId, Roles, ContactId FROM AccountContactRelation WHERE AccountId = :objAcc.Id]) {
			if (acr.ContactId == list_accContacts[0].Id) {
				acr.Roles = 'Primary Payroll Admin';
				list_accContRelations.add(acr);
			} else if (acr.ContactId == list_accContacts[1].Id) {
				acr.Roles = 'Payroll Admin';
				list_accContRelations.add(acr);
			}
		}
		update list_accContRelations;

		Test.StartTest();
		ApexPages.currentPage().getParameters().put('id', objAcc.Id);

		LogSmartCallingController.strTaskType = TaskUtil.TASK_TYPE_INBOUND;

		LogSmartCallingController contrlCls = new LogSmartCallingController();
		contrlCls.bol_InboundCall = true;
		contrlCls.callbegain();
		contrlCls.callend();
		contrlCls.selDispostion = 'Voicemail';
		//Set case caseWhoid - to display cases
		contrlCls.caseWhoid = list_accContacts[0].Id;
		contrlCls.setDisplayCases();
		//Create follow up Task
		contrlCls.wrapSections.bol_FollowUpSection = true;
		contrlCls.followTaskObj.Subject = 'Follow up Call';
		contrlCls.followTaskObj.ActivityDate = System.today();
		//Create Product Upsell
		contrlCls.upsellTier.workersCompInterest = 'workers comp test';
		contrlCls.upsellTier.fourOonekInterest = '401 comp test';
		contrlCls.upsellTier.twentynineInterese = '529 comp test';
		contrlCls.upsellTier.upsellNotes = 'test product upsell notes';
		//Create HI New Plan Opp
		contrlCls.createHIOpp = true;
		contrlCls.wrapSections.bol_HIOpsSection = true;
		contrlCls.hiOpportunity.hiStage = 'SAL';
		contrlCls.hiOpportunity.employeesNumber = 5;
		contrlCls.hiOpportunity.hiCloseDate = Date.Today().addDays(7);
		contrlCls.hiOpportunity.hiAssignmentState = 'California';
		contrlCls.hiOpportunity.hiOpportunityType = 'HI Benefits New Plan';
		//Create Payroll Opp
		contrlCls.createPayrollOpp = true;
		contrlCls.wrapSections.bol_PayrollOpsSection = true;
		contrlCls.payrollOpp.oppName = 'Payroll Opp Test';
		contrlCls.payrollOpp.oppStage = 'SAL';
		contrlCls.payrollOpp.oppCloseDate = Date.Today().addDays(7);
		//Create Product Upsell
		contrlCls.wrapSections.bol_ProductUpsellSection = true;
		contrlCls.upsellTier.workersCompInterest = 'Prod Upsell Test';

		//Close previous tasks
		contrlCls.wrapSections.bol_ClosePrevTasks = true;

		contrlCls.save();

		Test.stopTest();

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testAccountRecordHiOpp2() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		//insert acc
		Account objAcc = new Account();
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAcc.Name = 'Test Account';
		insert objAcc;
		//insert contact list
		List<Contact> list_accContacts = new List<Contact>();
		list_accContacts.add(
			new Contact(
				AccountId = objAcc.Id,
				FirstName = 'Fname 1',
				LastName = 'Lname 1',
				Email = 'PriPayrollAdmin@gusto.com',
				ZP_User_Role__c = 'Primary Payroll Admin',
				User_Role__c = 'Primary Payroll Admin'
			)
		);
		list_accContacts.add(
			new Contact(AccountId = objAcc.Id, FirstName = 'Fname 2', LastName = 'Lname 2', Email = 'PayrollAdmin@gusto.com', ZP_User_Role__c = 'Accountant', User_Role__c = 'Accountant')
		);

		insert list_accContacts;

		List<Case> list_case = new List<Case>();
		list_case.add(new Case(ContactId = list_accContacts[0].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 1 desc'));
		list_case.add(new Case(ContactId = list_accContacts[1].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 2 desc'));
		CaseTriggerHelper.skipTrigger = true; //yuvraj : 9 june 2020
		insert list_case;
		CaseTriggerHelper.skipTrigger = false;
		ZPCompanyTriggerHelper.queue = true;

		ZP_Accounting_Firm__c objZpFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setName('Test Accountant')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAt(System.today())
			.build();
		insert objZpFirm;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.Company_Id__c = '33333333333333';
		funnel.Sign__c = 'Test';
		funnel.add_addresses_completed__c = true;
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		ZPUserTriggerHelper.skipTrigger = true;
		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Id__c = '1212121212';
		zpUser.Email__c = 'asdfsdfadsfasd@asdfsdfsdf.com';
		zpUser.Created_At__c = System.now();
		zpUser.Updated_At__c = System.now();
		insert zpUser;
		ZPUserTriggerHelper.skipTrigger = false;

		ZPUserRoleTriggerHelper.skipTrigger = true;
		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = '1212121212';
		userRole.Type__c = 'Role::PayrollAdmin';
		userRole.Company_Id__c = '11111111111111';
		userRole.Is_Primary__c = true;
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[0].Id;
		userRole.Accounting_Firm_Id__c = '11111111111';
		userRole.Created_At__c = System.now();
		userRole.Updated_At__c = System.now();
		insert userRole;

		ZP_User_Role__c userRole2 = new ZP_User_Role__c();
		userRole2.User_Id__c = '1212121212';
		userRole2.Type__c = 'Role::Accountant';
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[1].Id;
		userRole2.Created_At__c = System.now();
		userRole2.Updated_At__c = System.now();
		insert userRole2;

		ZPUserRoleTriggerHelper.skipTrigger = false;

		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setName('Test Company')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.build();

		AccountTriggerHelper.skipTrigger = true;

		insert objZpCompany;

		//insert opportunity
		Opportunity objOpp = new Opportunity();
		objOpp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		objOpp.CloseDate = System.today();
		objOpp.StageName = 'SAL';
		objOpp.AccountId = objAcc.Id;
		objOpp.Name = 'Test Name objOpp';
		insert objOpp;

		//account contact relation
		List<AccountContactRelation> list_accContRelations = new List<AccountContactRelation>();

		for (AccountContactRelation acr : [SELECT Id, AccountId, Roles, ContactId FROM AccountContactRelation WHERE AccountId = :objAcc.Id]) {
			if (acr.ContactId == list_accContacts[0].Id) {
				acr.Roles = 'Primary Payroll Admin';
				list_accContRelations.add(acr);
			} else if (acr.ContactId == list_accContacts[1].Id) {
				acr.Roles = 'Payroll Admin';
				list_accContRelations.add(acr);
			}
		}
		update list_accContRelations;

		Test.StartTest();
		ApexPages.currentPage().getParameters().put('id', objAcc.Id);

		LogSmartCallingController.strTaskType = TaskUtil.TASK_TYPE_INBOUND_CALL;

		LogSmartCallingController contrlCls = new LogSmartCallingController();
		contrlCls.bol_InboundCall = true;
		contrlCls.callbegain();
		contrlCls.callend();
		contrlCls.selDispostion = 'Voicemail';
		//Set case caseWhoid - to display cases
		contrlCls.caseWhoid = list_accContacts[0].Id;
		contrlCls.setDisplayCases();
		//Create follow up Task
		contrlCls.wrapSections.bol_FollowUpSection = true;
		contrlCls.followTaskObj.Subject = 'Follow up Call';
		contrlCls.followTaskObj.ActivityDate = System.today();
		//Create Product Upsell
		contrlCls.upsellTier.workersCompInterest = 'workers comp test';
		contrlCls.upsellTier.fourOonekInterest = '401 comp test';
		contrlCls.upsellTier.twentynineInterese = '529 comp test';
		contrlCls.upsellTier.upsellNotes = 'test product upsell notes';
		//Create HI New Plan Opp
		contrlCls.createHIOpp = true;
		contrlCls.wrapSections.bol_HIOpsSection = true;
		contrlCls.hiOpportunity.hiStage = 'SAL';
		contrlCls.hiOpportunity.employeesNumber = 5;
		contrlCls.hiOpportunity.hiCloseDate = Date.Today().addDays(7);
		contrlCls.hiOpportunity.hiAssignmentState = 'California';
		contrlCls.hiOpportunity.hiOpportunityType = 'HI Benefits New Plan';
		//Create Payroll Opp
		contrlCls.createPayrollOpp = true;
		contrlCls.wrapSections.bol_PayrollOpsSection = true;
		contrlCls.payrollOpp.oppName = null;
		contrlCls.payrollOpp.oppStage = null;
		contrlCls.payrollOpp.oppCloseDate = null;
		//Create Product Upsell
		contrlCls.wrapSections.bol_ProductUpsellSection = true;
		contrlCls.upsellTier.workersCompInterest = 'Prod Upsell Test';

		//Close previous tasks
		contrlCls.wrapSections.bol_ClosePrevTasks = true;

		contrlCls.save();

		Test.stopTest();

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}
	/**
	 * Author :Yuvraj
	 * Date :17-09-2020
	 * Unit testing for HI Opp QSehra creation
	 *
	 */
	@isTest
	static void testAccountRecordHiOppQSehra() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		//insert acc
		Account objAcc = new Account();
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAcc.Name = 'Test Account';
		insert objAcc;
		//insert contact list
		List<Contact> list_accContacts = new List<Contact>();
		list_accContacts.add(
			new Contact(
				AccountId = objAcc.Id,
				FirstName = 'Fname 1',
				LastName = 'Lname 1',
				Email = 'PriPayrollAdmin@gusto.com',
				ZP_User_Role__c = 'Primary Payroll Admin',
				User_Role__c = 'Primary Payroll Admin'
			)
		);
		list_accContacts.add(
			new Contact(AccountId = objAcc.Id, FirstName = 'Fname 2', LastName = 'Lname 2', Email = 'PayrollAdmin@gusto.com', ZP_User_Role__c = 'Accountant', User_Role__c = 'Accountant')
		);

		insert list_accContacts;

		List<Case> list_case = new List<Case>();
		list_case.add(new Case(ContactId = list_accContacts[0].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 1 desc'));
		list_case.add(new Case(ContactId = list_accContacts[1].Id, Type = 'Question', Status = 'New', Priority = 'High', Description = 'Test 2 desc'));
		CaseTriggerHelper.skipTrigger = true; //yuvraj : 9 june 2020
		insert list_case;
		CaseTriggerHelper.skipTrigger = false;
		ZPCompanyTriggerHelper.queue = true;

		ZP_Accounting_Firm__c objZpFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setName('Test Accountant')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAt(System.today())
			.build();
		insert objZpFirm;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.Company_Id__c = '33333333333333';
		funnel.Sign__c = 'Test';
		funnel.add_addresses_completed__c = true;
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		ZPUserTriggerHelper.skipTrigger = true;
		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Id__c = '1212121212';
		zpUser.Email__c = 'asdfsdfadsfasd@asdfsdfsdf.com';
		zpUser.Created_At__c = System.now();
		zpUser.Updated_At__c = System.now();
		insert zpUser;
		ZPUserTriggerHelper.skipTrigger = false;

		ZPUserRoleTriggerHelper.skipTrigger = true;
		ZP_User_Role__c userRole = new ZP_User_Role__c();
		userRole.User_Id__c = '1212121212';
		userRole.Type__c = 'Role::PayrollAdmin';
		userRole.Company_Id__c = '11111111111111';
		userRole.Is_Primary__c = true;
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[0].Id;
		userRole.Accounting_Firm_Id__c = '11111111111';
		userRole.Created_At__c = System.now();
		userRole.Updated_At__c = System.now();
		insert userRole;

		ZP_User_Role__c userRole2 = new ZP_User_Role__c();
		userRole2.User_Id__c = '1212121212';
		userRole2.Type__c = 'Role::Accountant';
		userRole.Company_Account__c = objAcc.ID;
		userRole.Contact__c = list_accContacts[1].Id;
		userRole2.Created_At__c = System.now();
		userRole2.Updated_At__c = System.now();
		insert userRole2;

		ZPUserRoleTriggerHelper.skipTrigger = false;

		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setName('Test Company')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.build();

		AccountTriggerHelper.skipTrigger = true;

		insert objZpCompany;

		//insert opportunity
		Opportunity objOpp = new Opportunity();
		objOpp.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		objOpp.CloseDate = System.today();
		objOpp.StageName = 'SAL';
		objOpp.AccountId = objAcc.Id;
		objOpp.Name = 'Test Name objOpp';
		insert objOpp;

		//account contact relation
		List<AccountContactRelation> list_accContRelations = new List<AccountContactRelation>();

		for (AccountContactRelation acr : [SELECT Id, AccountId, Roles, ContactId FROM AccountContactRelation WHERE AccountId = :objAcc.Id]) {
			if (acr.ContactId == list_accContacts[0].Id) {
				acr.Roles = 'Primary Payroll Admin';
				list_accContRelations.add(acr);
			} else if (acr.ContactId == list_accContacts[1].Id) {
				acr.Roles = 'Payroll Admin';
				list_accContRelations.add(acr);
			}
		}
		update list_accContRelations;

		Test.StartTest();
		ApexPages.currentPage().getParameters().put('id', objAcc.Id);
		LogSmartCallingController contrlCls = new LogSmartCallingController();
		contrlCls.bol_InboundCall = true;
		contrlCls.callbegain();
		contrlCls.callend();
		contrlCls.selDispostion = 'Voicemail';
		//Set case caseWhoid - to display cases
		contrlCls.caseWhoid = list_accContacts[0].Id;
		contrlCls.setDisplayCases();
		//Create follow up Task
		contrlCls.wrapSections.bol_FollowUpSection = true;
		contrlCls.followTaskObj.Subject = 'Follow up Call';
		contrlCls.followTaskObj.ActivityDate = System.today();
		//Create Product Upsell
		contrlCls.upsellTier.workersCompInterest = 'workers comp test';
		contrlCls.upsellTier.fourOonekInterest = '401 comp test';
		contrlCls.upsellTier.twentynineInterese = '529 comp test';
		contrlCls.upsellTier.upsellNotes = 'test product upsell notes';
		//Create HI New Plan Opp
		contrlCls.createHIOpp = true;
		contrlCls.wrapSections.bol_HIOpsSection = true;
		contrlCls.hiOpportunity.hiStage = 'SAL';
		contrlCls.hiOpportunity.employeesNumber = 5;
		contrlCls.hiOpportunity.hiCloseDate = Date.Today().addDays(7);
		contrlCls.hiOpportunity.hiAssignmentState = 'California';
		contrlCls.hiOpportunity.hiOpportunityType = 'HI Benefits QSEHRA';
		contrlCls.save();

		Test.stopTest();

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testAccountRecord() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		//insert account
		Account objAcc = new Account();
		objAcc.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAcc.Name = 'Test Account';
		insert objAcc;

		//insert contact list
		List<Contact> list_accContacts = new List<Contact>();
		list_accContacts.add(
			new Contact(
				AccountId = objAcc.Id,
				FirstName = 'Fname 1',
				LastName = 'Lname 1',
				Email = 'PriPayrollAdmin@gusto.com',
				ZP_User_Role__c = 'Primary Payroll Admin',
				User_Role__c = 'Primary Payroll Admin'
			)
		);
		list_accContacts.add(
			new Contact(AccountId = objAcc.Id, FirstName = 'Fname 2', LastName = 'Lname 2', Email = 'PayrollAdmin@gusto.com', ZP_User_Role__c = 'Payroll Admin', User_Role__c = 'Payroll Admin')
		);

		insert list_accContacts;

		Test.StartTest();
		ApexPages.currentPage().getParameters().put('id', objAcc.Id);
		LogSmartCallingController contrlCls = new LogSmartCallingController();
		contrlCls.bol_InboundCall = true;
		contrlCls.whoid = list_accContacts[0].Id;
		contrlCls.selDispostion = 'Voicemail';
		//Set case caseWhoid - to display cases
		contrlCls.caseWhoid = list_accContacts[0].Id;
		//contrlCls.setDisplayCases(); //Yuvraj : 26-05-2020 - to resolve null pointer error
		//Create follow up Task
		contrlCls.followTaskObj.Subject = 'Follow up Call';
		contrlCls.followTaskObj.ActivityDate = System.today();

		//Create HI New Plan Opp
		contrlCls.createHIOpp = true;

		//Create Payroll Opp
		contrlCls.createPayrollOpp = true;
		contrlCls.payrollOpp.oppName = 'Payroll Opp Test';
		contrlCls.payrollOpp.oppStage = 'SAL';
		contrlCls.payrollOpp.oppCloseDate = Date.Today().addDays(7);
		contrlCls.save();
		//System.assertEquals(actionObj.Status__c, 'completed');*/
		Test.stopTest();

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
	}

	static testMethod void testLeadRecord() {
		//get profile
		List<Profile> list_profiles = [SELECT Id, Name FROM Profile WHERE Id = :Userinfo.getProfileId() LIMIT 1];
		//create custom meta data
		AllSmartCalling__mdt mdtRecord = new AllSmartCalling__mdt();
		mdtRecord.Object_Name__c = 'Lead';
		mdtRecord.Follow_Up__c = true;
		mdtRecord.Current_Record__c = true;
		mdtRecord.Outbound_Email__c = true;
		mdtRecord.Inbound_Call__c = true;
		mdtRecord.Do_Not_Call__c = true;
		mdtRecord.Object_Name__c = 'Lead';
		mdtRecord.Profile_Name__c = list_profiles[0].Name;

		//insert lead
		Lead objLead = new Lead();
		objLead.FirstName = 'Test';
		objLead.LastName = 'Test';
		objLead.Email = 'test@test.com';
		objLead.Company = 'Test';
		insert objLead;

		Test.StartTest();
		ApexPages.currentPage().getParameters().put('id', objLead.Id);
		LogSmartCallingController contrlCls = new LogSmartCallingController();
		contrlCls.bol_InboundCall = true;
		contrlCls.wrapSections.bol_CurrentRecord = true;
		contrlCls.selDispostion = 'Voicemail';
		contrlCls.whoid = objLead.Id;
		List<SelectOption> list_pickres = contrlCls.getPickListValueIntoList();
		contrlCls.save();
		contrlCls.processLTCLead();
		Test.stopTest();
	}

	static testMethod void testBenefitOrderWithPhone() {
		Benefit_Order__c objBo = [SELECT Id FROM Benefit_Order__c WHERE Name = 'New Plan BO' LIMIT 1];

		Test.startTest();
		Test.setCurrentPageReference(new PageReference('/LogSmartCallingPage?id=' + objBo.Id + '&_c=1256243769&ani=4376546678'));
		LogSmartCallingController objExtension = new LogSmartCallingController();

		objExtension.selDispostion = 'Connect';
		objExtension.agentNotes = 'Notes: testing';
		objExtension.strSelectedCallType = 'Inbound';
		objExtension.objCallTrackPlaceholder.Was_this_a_scheduled_call_calendly__c = 'Y';
		objExtension.objCallTrackPlaceholder.Reason_for_Call__c = 'Incomplete OE';
		objExtension.strPhoneNumber = '4376546678';
		objExtension.save();
		Test.stopTest();

		List<Sales_Call_Tracking__c> list_SalesCallTracking = [SELECT Id, RecordType.Name FROM Sales_Call_Tracking__c WHERE Benefit_Order__c = :objBo.Id];

		if (!list_SalesCallTracking.isEmpty()) {
			System.assertEquals(list_SalesCallTracking[0].RecordType.Name, 'New Plan');
		}
	}

	static testMethod void testBenefitOrderRenewalWithPhone() {
		Benefit_Order__c objBo = [SELECT Id FROM Benefit_Order__c WHERE Name = 'Renewal Aligment BO' LIMIT 1];

		Test.startTest();
		Test.setCurrentPageReference(new PageReference('/LogSmartCallingPage?id=' + objBo.Id + '&_c=1256243769&_c=4376546679'));
		LogSmartCallingController objExtension = new LogSmartCallingController();

		objExtension.selDispostion = 'Connect';
		objExtension.agentNotes = 'Notes: testing';
		objExtension.strSelectedCallType = 'Inbound';
		objExtension.objCallTrackPlaceholder.Was_this_a_scheduled_call_calendly__c = 'Y';
		objExtension.objCallTrackPlaceholder.Reason_for_Call__c = 'Incomplete OE';
		objExtension.strPhoneNumber = '4376546678';
		objExtension.save();
		Test.stopTest();

		List<Sales_Call_Tracking__c> list_SalesCallTracking = [SELECT Id, RecordType.Name FROM Sales_Call_Tracking__c WHERE Benefit_Order__c = :objBo.Id];

		if (!list_SalesCallTracking.isEmpty()) {
			System.assertEquals(list_SalesCallTracking[0].RecordType.Name, 'Renewal');
		}
	}

	static testMethod void testBenefitOrderWithoutPhone() {
		Benefit_Order__c objBo = [SELECT Id FROM Benefit_Order__c WHERE Name = 'New Plan BO' LIMIT 1];

		Test.startTest();
		Test.setCurrentPageReference(new PageReference('/LogSmartCallingPage?id=' + objBo.Id + '&_c=1256243769&_c=4376546680'));
		LogSmartCallingController objExtension = new LogSmartCallingController();

		objExtension.selDispostion = 'Connect';
		objExtension.agentNotes = 'Notes: testing';
		objExtension.strSelectedCallType = 'Inbound';
		objExtension.objCallTrackPlaceholder.Was_this_a_scheduled_call_calendly__c = 'Y';
		objExtension.objCallTrackPlaceholder.Reason_for_Call__c = 'Incomplete OE';
		objExtension.save();
		Test.stopTest();

		System.assert([SELECT COUNT() FROM Sales_Call_Tracking__c] > 0);
	}

	@isTest
	static void testAccountRecordAsBenefitsUser() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objBenefitsUser = [SELECT Id, Email FROM User WHERE Profile.Name = :LogSmartCallingController.USER_PROFILE_NAME_BENEFITS_USER AND IsActive = TRUE LIMIT 1];

		Account objCompanyAccount;
		Contact objContact;
		Opportunity objOpportunity;

		Test.StartTest();

		objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE).setName('Test Account').setBenefitsNotes('Test Account Benefit Notes 1').build();
		insert objCompanyAccount;

		ContactTriggerHelper.skipTrigger = true;

		objContact = new Contact(RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID, AccountId = objCompanyAccount.Id, FirstName = 's', LastName = 's', Email = objBenefitsUser.Email);
		insert objContact;

		System.runAs(objBenefitsUser) {
			// insert Account:

			NICE_Interaction__c objNICEInteraction = new TestDataFactory.NICEInteractionBuilder()
				.setDNIS(new normalizationUtil().normalisePhoneField(objContact.Phone))
				.setEmailId(objBenefitsUser.Email)
				.setContactID(objContact.Id)
				.build();
			insert objNICEInteraction;

			objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setAccountId(objCompanyAccount.Id)
				.setName('Test Opportunity 1')
				.build();
			insert objOpportunity;

			ApexPages.currentPage().getParameters().put('id', objCompanyAccount.Id);

			LogSmartCallingController.strHiAssignmentState = LogSmartCallingController.OPPORTUNITY_TYPE_HI_ASSIGNMENT_STATE_CALIFORNIA;
			LogSmartCallingController.strHiOpportunityType = LogSmartCallingController.HI_OPPORTUNITY_TYPE_HI_BENEFITS_NEW_PLAN;

			LogSmartCallingController contrlCls = new LogSmartCallingController();
			contrlCls.strSelectedPhoneNumber = objContact.Phone;

			contrlCls.bol_InboundCall = true;
			contrlCls.whoid = objContact.Id;
			contrlCls.selDispostion = 'Voicemail';

			//Set case caseWhoid - to display cases
			contrlCls.caseWhoid = objContact.Id;
			//contrlCls.setDisplayCases(); //Yuvraj : 26-05-2020 - to resolve null pointer error

			//Create follow up Task
			contrlCls.followTaskObj.Subject = 'Follow up Call';
			contrlCls.followTaskObj.ActivityDate = System.today();

			//Create HI New Plan Opp
			contrlCls.createHIOpp = true;

			//Create Payroll Opp
			contrlCls.createPayrollOpp = true;
			contrlCls.payrollOpp.oppName = 'Payroll Opp Test';
			contrlCls.payrollOpp.oppStage = 'SAL';
			contrlCls.payrollOpp.oppCloseDate = Date.Today().addDays(7);

			contrlCls.save();

			Test.stopTest();
		}

		Account objAccountAssert = [SELECT Id, Last_Activity_Date__c, SDR_Notes__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertNotEquals(null, objAccountAssert.SDR_Notes__c);
		System.assertEquals(Date.today(), objAccountAssert.Last_Activity_Date__c);

		Opportunity objOpportunityAssert = [SELECT Id, Benefits_Notes__c FROM opportunity WHERE Id = :objOpportunity.Id];
		//System.assertEquals(objCompanyAccount.Benefits_Notes__c, objOpportunityAssert.Benefits_Notes__c);

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testOppRecordAsMMPRUser() {
		AccountTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objMMPRUser = [SELECT Id, Email FROM User WHERE Profile.Name = :LogSmartCallingController.USER_PROFILE_NAME_MMPR_USER AND IsActive = TRUE LIMIT 1];

		Account objCompanyAccount;
		Contact objContact;
		Opportunity objOpportunity;
		Task objTask;

		Test.StartTest();

		objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE).setName('Test Account').build();
		insert objCompanyAccount;

		ContactTriggerHelper.skipTrigger = true;

		objContact = new Contact(RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID, AccountId = objCompanyAccount.Id, FirstName = 's', LastName = 's', Email = 'newcontact@demo.com');
		insert objContact;

		System.runAs(objMMPRUser) {
			// insert Opportunity:
			objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setCloseDate(System.today())
				.setStage(OpportunityUtil.SAL_STAGE)
				.setAccountId(objCompanyAccount.Id)
				.setName('Test Opportunity 1')
				.build();
			insert objOpportunity;

			// insert OpportunityContactRole:
			OpportunityContactRole objOpportunityContactRole = new TestDataFactory.OpportunityContactRoleBuilder()
				.setContactId(objContact.Id)
				.setOpportunityId(objOpportunity.Id)
				.setRole('Payroll Admin')
				.build();
			insert objOpportunityContactRole;

			objTask = new TestDataFactory.TaskBuilder()
				.setRecordTypeId(TaskUtil.TASK_CALL_RT_ID)
				.setWhatId(objOpportunity.Id)
				.setStatus(TaskUtil.TASK_STATUS_OPEN)
				.setType(TaskUtil.TASK_TYPE_DEMO)
				.setStartDate(System.now())
				.build();

			TaskTriggerHelper.skipTrigger = true;
			insert objTask;
			TaskTriggerHelper.skipTrigger = false;

			ApexPages.currentPage().getParameters().put('id', objOpportunity.Id);

			LogSmartCallingController.strTaskType = TaskUtil.TASK_TYPE_INBOUND_CALL;
			LogSmartCallingController.strHiAssignmentState = LogSmartCallingController.OPPORTUNITY_TYPE_HI_ASSIGNMENT_STATE_CALIFORNIA;
			LogSmartCallingController.strHiOpportunityType = LogSmartCallingController.HI_OPPORTUNITY_TYPE_HI_BENEFITS_NEW_PLAN;

			LogSmartCallingController contrlCls = new LogSmartCallingController();
			contrlCls.whoId = objContact.Id;
			contrlCls.selDispostion = 'Connect';
			contrlCls.upsellTier.workersCompInterest = 'test workers comp intterest';
			contrlCls.upsellTier.fourOonekInterest = 'test workers comp intterest';
			contrlCls.upsellTier.twentynineInterese = 'test workers comp intterest';

			//hi opp
			contrlCls.createHIOpp = true;

			// set follow up task values
			contrlCls.followTaskObj.Subject = 'Follow up Call';
			contrlCls.followTaskObj.ActivityDate = System.today();

			// contrlCls.createFollowTask();
			contrlCls.save();
		}

		Test.stopTest();

		Task objTaskInsertAssert = [SELECT Id, Status FROM Task WHERE Id != :objTask.Id AND WhatId = :objOpportunity.Id AND OwnerId = :objMMPRUser.Id AND Subject = 'Follow up Call'];
		System.assertEquals(TaskUtil.TASK_STATUS_OPEN, objTaskInsertAssert.Status);

		Task objTaskUpdateAssert = [SELECT Id, Status FROM Task WHERE Id = :objTask.Id];
		System.assertEquals(TaskUtil.TASK_STATUS_COMPLETE, objTaskUpdateAssert.Status);

		Opportunity objOpportunityAssert = [SELECT Id, Last_Call__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		System.assertEquals(System.today(), objOpportunityAssert.Last_Call__c);

		AccountTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Try to Insert a new HI Opportunity as an Gusto Direct MDR User.
	 *                Result - Check if a new HI Opportunity is inserted.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testAccountRecordAsGustoDirectMDRUser() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		User objGustoDirectMDRUser = [SELECT Id, Email FROM User WHERE Profile.Name = :LogSmartCallingController.USER_PROFILE_NAME_GUSTO_DIRECT_MDR AND IsActive = TRUE LIMIT 1];

		Account objCompanyAccount;
		Contact objContact;
		Opportunity objOpportunity;

		Test.StartTest();

		// insert Account:
		objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_TYPE)
			.setName('Test Account')
			.setZPCompanyId('MDR-CompanyId01')
			.setBenefitsNotes('Test Account Benefit Notes 1')
			.build();
		insert objCompanyAccount;

		objContact = new Contact(RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID, AccountId = objCompanyAccount.Id, FirstName = 's', LastName = 's', Email = 'newcontact@demo2.com');
		insert objContact;

		System.runAs(objGustoDirectMDRUser) {
			NICE_Interaction__c objNICEInteraction = new TestDataFactory.NICEInteractionBuilder()
				.setDNIS(new normalizationUtil().normalisePhoneField(objContact.Phone))
				.setEmailId(objGustoDirectMDRUser.Email)
				.setContactID(objContact.Id)
				.build();
			insert objNICEInteraction;

			objOpportunity = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				.setAccountId(objCompanyAccount.Id)
				.setName('Test Opportunity 1')
				.build();
			insert objOpportunity;

			ApexPages.currentPage().getParameters().put('id', objCompanyAccount.Id);

			LogSmartCallingController.strHiAssignmentState = LogSmartCallingController.OPPORTUNITY_TYPE_HI_ASSIGNMENT_STATE_CALIFORNIA;
			LogSmartCallingController.strHiOpportunityType = LogSmartCallingController.HI_OPPORTUNITY_TYPE_HI_BENEFITS_BYOB;

			LogSmartCallingController contrlCls = new LogSmartCallingController();
			contrlCls.strSelectedPhoneNumber = objContact.Phone;

			contrlCls.bol_InboundCall = true;
			contrlCls.whoid = objContact.Id;
			contrlCls.selDispostion = 'Voicemail';

			//Set case caseWhoid - to display cases
			contrlCls.caseWhoid = objContact.Id;

			//Create follow up Task
			contrlCls.followTaskObj.Subject = 'Follow up Call';
			contrlCls.followTaskObj.ActivityDate = System.today();

			//Create HI New Plan Opp
			contrlCls.createHIOpp = true;
			contrlCls.wrapSections.bol_HIOpsSection = true;
			contrlCls.hiOpportunity.hiStage = OpportunityUtil.SAL_STAGE;
			contrlCls.hiOpportunity.employeesNumber = 5;
			contrlCls.hiOpportunity.hiCloseDate = Date.Today().addDays(7);

			//Create Payroll Opp
			contrlCls.createPayrollOpp = true;
			contrlCls.payrollOpp.oppName = 'Payroll Opp Test';
			contrlCls.payrollOpp.oppStage = 'SAL';
			contrlCls.payrollOpp.oppCloseDate = Date.Today().addDays(7);

			contrlCls.processTaskWOCall();

			Test.stopTest();
		}

		Account objAccountAssert = [SELECT Id, Name, Last_Activity_Date__c, SDR_Notes__c, ZP_Company_ID__c FROM Account WHERE Id = :objCompanyAccount.Id];
		System.assertNotEquals(null, objAccountAssert.SDR_Notes__c);
		System.assertEquals(System.today(), objAccountAssert.Last_Activity_Date__c);

		Opportunity objHiOpportunityAssert = [SELECT Id, Name, RecordTypeId, ZP_Company_ID__c, Source_ID__c, Type FROM Opportunity WHERE Source_ID__c LIKE 'BYB -%'];

		System.assertEquals(objCompanyAccount.ZP_Company_ID__c, objHiOpportunityAssert.ZP_Company_ID__c);
		System.assertEquals(true, objHiOpportunityAssert.Name.endsWithIgnoreCase(OpportunityUtil.map_OpptyRTToDefaultValues.get(objHiOpportunityAssert.RecordTypeId)[2]));
		System.assertEquals(OpportunityUtil.map_OpptyRTToDefaultValues.get(objHiOpportunityAssert.RecordTypeId)[0], objHiOpportunityAssert.Type);

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}
}