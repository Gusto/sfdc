@isTest
public class CaseTriggerHelperTest {
	public static Boolean blnRunCatchTest = false;
	public static String strTestSubject = '[NEW Request Received] - ID#';
	public static String strEmailSubject = '[NEW Request Received] - ID#;has been assigned to you';
	public static Map<Id, Group> map_Queues = GlobalQueryHelper.getAllGroupQueueMap();

	public static Integer generateRandomId() {
		return Integer.valueOf(10000000 + Math.rint(Math.random() * 90000000));
	}

	@testSetup
	static void setUp() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseAuditLogTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		EmailMessageTriggerHelper.skipTrigger = true;
		LeadTriggerHelper.skipTrigger = true;
		UserTriggerHelper.skipTrigger = true;
		ZPUserTriggerHelper.skipTrigger = true;
		ZPUserRoleTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		IVRRoutingLogTriggerHelper.skipTrigger = true;

		User objLoggedUser = new User(Id = UserInfo.getUserId());
		System.runAs(objLoggedUser) {
			Group objGroup = new Group(Name = 'TaxRes Ricoh Users');
			insert objGroup;

			GroupMember objGroupMember = new GroupMember(UserOrGroupId = UserInfo.getUserId(), GroupId = objGroup.Id);
			insert objGroupMember;

			User objTestUser = new TestDataFactory.UserBuilder()
				.setIsActive(true)
				.setProfileId(UserInfo.getProfileId())
				.setUserRoleId(Label.MDR_Role_ID)
				.setUserName('testSalesMDR_XX_User@task.com')
				.setFirstName('Test FName')
				.setLastName('Test Lastname')
				.setEmail('testSalesMDR_XX_User@task.com')
				.setAlias('SaleMDR')
				.setTimeZoneSidKey('America/Los_Angeles')
				.setLocaleSidKey('en_US')
				.setEmailEncoding('UTF-8')
				.setLanguageLocaleKey('en_US')
				.build();
			insert objTestUser;
		}

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		// Create Company Accounts
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new Account();
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objAccount.Name = 'TEST ACCOUNT';
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_ID__c = String.valueOf(generateRandomId());
		list_Accounts.add(objAccount);

		Account objConciergeAccount = new Account();
		objConciergeAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		objConciergeAccount.Name = 'TEST ACCOUNT CONCIERGE';
		objConciergeAccount.Joined_Date_Panda__c = System.today();
		objConciergeAccount.ZP_Company_ID__c = String.valueOf(generateRandomId());
		objConciergeAccount.Tier__c = objTierConfig.New_Tier_2__c;
		list_Accounts.add(objConciergeAccount);

		// Create Reseller Account
		Account objResllerAccount = new Account();
		objResllerAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
		objResllerAccount.Name = 'TEST RESELLER ACCOUNT';
		objResllerAccount.Joined_Date_Panda__c = System.today();
		objResllerAccount.ZP_Company_ID__c = String.valueOf(generateRandomId());
		list_Accounts.add(objResllerAccount);
		insert list_Accounts;

		List<Contact> list_Contacts = new List<Contact>();
		// Create Company Contact
		Contact objContact = new Contact();
		objContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
		objContact.AccountId = objAccount.Id;
		objContact.FirstName = 'TEST CONTACT';
		objContact.LastName = 'CONTACT';
		objContact.Phone = '1234567890';
		objContact.Email = 'test.contact@gusto.com';
		objContact.ZP_User_Id__c = String.valueOf(generateRandomId());
		list_Contacts.add(objContact);

		// Create Reseller Contact
		Contact objResellerContact = new Contact();
		objResellerContact.RecordTypeId = Cache.getRecordTypeId('Contact', 'Reseller');
		objResellerContact.AccountId = objResllerAccount.Id;
		objResellerContact.FirstName = 'TEST RESELLER CONTACT';
		objResellerContact.LastName = 'CONTACT';
		objResellerContact.Phone = '1234567890';
		objResellerContact.Email = 'test.contact.@gusto.com.reseller';
		objResellerContact.ZP_User_Id__c = String.valueOf(generateRandomId());
		list_Contacts.add(objResellerContact);

		Contact objAccountantContact = new TestDataFactory.ContactBuilder()
			.setZPUserRole('Accountant')
			.setEmail('testaccountant@gusto.com')
			.setFirstName('Test')
			.setLastName('Accountant')
			.setAccountId(objAccount.Id)
			.setRecordTypeId('Company')
			.build();
		list_Contacts.add(objAccountantContact);

		insert list_Contacts;

		//Creating Email Subject AutoClosed
		List<Email_Subject_AutoClosed__c> list_EmailAutoClosed = new List<Email_Subject_AutoClosed__c>();
		list_EmailAutoClosed.add(new Email_Subject_AutoClosed__c(Record_Type__c = 'Sales Cases', Email_Subject__c = 'Test', Name = 'Test'));
		list_EmailAutoClosed.add(
			new Email_Subject_AutoClosed__c(
				Record_Type__c = 'Payroll Care',
				Email_Subject__c = strEmailSubject,
				Name = 'Test Spam Cases',
				Is_Partial_Match__c = true,
				Auto_Close__c = true,
				Queue_Name__c = 'Tax_Res_Auto_Close'
			)
		);
		list_EmailAutoClosed.add(
			new Email_Subject_AutoClosed__c(Record_Type__c = 'Benefits BYB', Email_Subject__c = CaseUtils.ONE_TIME_PASSCODE_SUBJECT, Name = 'Test Auto Close One Time Passcode', Auto_Close__c = true)
		);
		insert list_EmailAutoClosed;

		//Creating Opportunities
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Opportunity objBenefitsRenewalOpportunity = TestUtility.createOpportunity('Benefits Renewal', objAccount.Id);
		objBenefitsRenewalOpportunity.Name = 'Test';
		objBenefitsRenewalOpportunity.StageName = 'SAL';
		objBenefitsRenewalOpportunity.CloseDate = System.today();
		objBenefitsRenewalOpportunity.NumberOfEmployees__c = 12;
		list_Opportunities.add(objBenefitsRenewalOpportunity);
		list_Opportunities.add(TestUtility.createOpportunity('Benefits Renewal', objAccount.Id));
		list_Opportunities.add(TestUtility.createOpportunity('Benefits BYOB', objAccount.Id));
		list_Opportunities.add(TestUtility.createOpportunity('Benefits Change', objAccount.Id));
		Opportunity objOpportunity = TestUtility.createOpportunity('Benefits Change', objAccount.Id);
		objOpportunity.Name = 'Closed Won Opportunity';
		list_Opportunities.add(objOpportunity);
		insert list_Opportunities;

		//Creating Benefit Orders
		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('Renewal', list_Opportunities[2].Id, 'Test Benefit Order', false);
		objBenefitOrder.Order_Status__c = 'Awaiting Routing';
		objBenefitOrder.Account__c = objAccount.Id;
		list_BenefitOrders.add(objBenefitOrder);

		objBenefitOrder = TestUtility.createTestBenefitOrder('New Plan', list_Opportunities[2].Id, 'Test Benefit Order', false);
		objBenefitOrder.Order_Status__c = 'Fulfilled';
		objBenefitOrder.Account__c = objConciergeAccount.Id;
		list_BenefitOrders.add(objBenefitOrder);

		objBenefitOrder = TestUtility.createTestBenefitOrder('Change', list_Opportunities[2].Id, 'Test Benefit Order', false);
		objBenefitOrder.Order_Status__c = 'Awaiting Routing';
		objBenefitOrder.Account__c = objAccount.Id;
		list_BenefitOrders.add(objBenefitOrder);

		objBenefitOrder = TestUtility.createTestBenefitOrder('Renewal', list_Opportunities[2].Id, 'New BO Opp', false);
		objBenefitOrder.Account__c = objAccount.Id;
		objBenefitOrder.Order_Status__c = 'Fulfilled';
		objBenefitOrder.EE_at_Fulfillment__c = 16;
		list_BenefitOrders.add(objBenefitOrder);

		Benefit_Order__c objBenefitOrder01 = TestUtility.createTestBenefitOrder('Benefits BYB', list_Opportunities[2].Id, 'New BO Opp01', false);
		objBenefitOrder01.Account__c = objAccount.Id;
		objBenefitOrder01.Order_Status__c = 'Ready for Intro';
		objBenefitOrder01.Does_group_require_OE__c = true;
		list_BenefitOrders.add(objBenefitOrder01);

		insert list_BenefitOrders;

		//Creating Large Scale Issue
		Large_Scale_Issue__c objLargeScaleIssue = new Large_Scale_Issue__c();
		objLargeScaleIssue.Name = 'Test LSI';
		insert objLargeScaleIssue;

		//Creating Case Reason Classifications
		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
		Case_Reason_Classification__c objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder().setName('Test Reason').setIsActive(true).setType('Tax Res').build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		Case_Reason_Classification__c objCaseReasonClassification2 = new TestDataFactory.CaseReasonClassificationBuilder().setName('Client Unresponsive').setIsActive(true).setType('Tax Res').build();
		list_CaseReasonClassifications.add(objCaseReasonClassification2);

		Case_Reason_Classification__c objCaseReasonClassification3 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('1099 Adjustment')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setSurveyEligible(true)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification3);

		Case_Reason_Classification__c objCaseReasonClassification4 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('No Action Required')
			.setIsActive(true)
			.setType('Payroll Care')
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification4);

		Case_Reason_Classification__c objCaseReasonClassification5 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('No Action Required')
			.setIsActive(true)
			.setType('Benefits Care')
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification5);

		Case_Reason_Classification__c objMBCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Modern Bank Test')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Modern Bank')
			.build();
		list_CaseReasonClassifications.add(objMBCaseReason);

		Case_Reason_Classification__c objBYBInterestCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('BYB Interest')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Engagement')
			.setSpecialization('Benefits Care Tier 1 - New')
			.build();
		list_CaseReasonClassifications.add(objBYBInterestCaseReason);

		insert list_CaseReasonClassifications;

		List<Sub_Case_Reason_Classification__c> list_SubReasons = new List<Sub_Case_Reason_Classification__c>{
			new Sub_Case_Reason_Classification__c(Name = 'Test Sub Reason 1', Case_Reason__c = objCaseReasonClassification.Id, Active__c = true),
			new Sub_Case_Reason_Classification__c(Name = 'Test Sub Reason 2', Case_Reason__c = objCaseReasonClassification2.Id, Active__c = true),
			new Sub_Case_Reason_Classification__c(Name = 'Test Sub Reason 3', Case_Reason__c = objCaseReasonClassification3.Id, Active__c = true)
		};
		insert list_SubReasons;

		//Creating Agency Information
		Agency_Information__c objAgencyInformation = new Agency_Information__c();
		objAgencyInformation.Name = 'Test text Res';
		objAgencyInformation.Tax_type__c = 'Unemployment';
		objAgencyInformation.Active__c = true;
		insert objAgencyInformation;

		//Creating ZP User
		ZP_User__c objZPUser = new ZP_User__c();
		objZPUser.Email__c = 'test.test@test.com';
		objZPUser.Created_At__c = Date.newInstance(2016, 11, 9);
		objZPUser.Updated_At__c = Date.newInstance(2016, 12, 9);
		objZPUser.Last_Sign_In_At__c = Date.newInstance(2018, 1, 1);
		objZPUser.Id__c = '1111111111';
		insert objZPUser;

		//Creating ZP User Role
		ZP_User_Role__c objZPUserRole = new ZP_User_Role__c();
		objZPUserRole.User_Id__c = '1111111111';
		objZPUserRole.Phone__c = '8888888888';
		insert objZPUserRole;

		BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];

		//Creating Entitlements
		Entitlement objEntitlement = new Entitlement(
			Name = 'Testing',
			AccountId = objAccount.Id,
			StartDate = Date.valueof(System.now()),
			EndDate = Date.valueof(System.now().addYears(2)),
			BusinessHoursId = objBusinessHours.Id
		);
		objEntitlement.Type = 'Engagement - First Response';
		insert objEntitlement;

		//Creating ZP Company Onboarding Funnel
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c objZPOnboarding = new ZP_Company_Onboarding_Funnel__c();
		objZPOnboarding.Company_id__c = objAccount.ZP_Company_Id__c;
		objZPOnboarding.Add_addresses_completed__c = true;
		objZPOnboarding.Sign__c = 'Test';
		objZPOnboarding.Add_addresses_started_at__c = System.now().addDays(2);
		objZPOnboarding.Add_addresses_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Add_employees_started_at__c = System.now().addDays(2);
		objZPOnboarding.Add_employees_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.State_setup_started_at__c = System.now().addDays(2);
		objZPOnboarding.State_setup_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Add_bank_info_started_at__c = System.now().addDays(2);
		objZPOnboarding.Add_bank_info_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Payroll_schedule_started_at__c = System.now().addDays(2);
		objZPOnboarding.Payroll_schedule_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Previous_paystubs_started_at__c = System.now().addDays(2);
		objZPOnboarding.Previous_paystubs_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Add_signatory_started_at__c = System.now().addDays(2);
		objZPOnboarding.Add_signatory_started_at__c = System.now().addDays(2);
		objZPOnboarding.Sign_all_forms_started_at__c = System.now().addDays(2);
		objZPOnboarding.Sign_all_forms_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Verify_bank_info_started_at__c = System.now().addDays(2);
		objZPOnboarding.Verify_bank_info_completed_at__c = System.now().addDays(-1);
		objZPOnboarding.Historical_liabilities_started_at__c = System.now().addDays(2);
		objZPOnboarding.Historical_liabilities_completed_at__c = System.now().addDays(-1);
		insert objZPOnboarding;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		//Creating Lead
		Lead objLead = new Lead();
		objLead.FirstName = 'Test';
		objLead.LastName = 'Lead';
		objLead.Email = 'TEST@LEAD.COM';
		objLead.Company = 'Gusto';
		objLead.Phone = '1234567890';
		insert objLead;

		//Creating Cases
		List<Case> list_Cases = new List<Case>();
		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		objCase.AccountId = objAccount.Id;
		objCase.ContactId = objContact.Id;
		objCase.Subject = 'Payroll Care Case';
		objCase.Description = 'Payroll Care Case';
		objCase.SuppliedEmail = 'test.contact@gusto.com';
		objCase.Type = 'Payroll Care';
		objCase.Origin = 'Email';
		objCase.Direction__c = 'Inbound';
		objCase.Confirm_Case_Reason__c = objCaseReasonClassification3.Name;
		objCase.Confirm_Case_Reason_Classification__c = objCaseReasonClassification3.Id;
		objCase.Confirm_Sub_Case_Reason__c = list_SubReasons[2].Name;
		objCase.Confirm_Sub_Case_Reason_Classification__c = list_SubReasons[2].Id;
		list_Cases.add(objCase);

		Case objCase2 = new Case();
		objCase2.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		objCase2.AccountId = objAccount.Id;
		objCase2.ContactId = objContact.Id;
		objCase2.Subject = 'Test Relation';
		objCase2.Description = 'Test Relation';
		objCase2.SuppliedEmail = 'test.contact@gusto.com';
		objCase2.Type = 'Sales';
		objCase2.Origin = 'Email';
		objCase2.Direction__c = 'Inbound';
		list_Cases.add(objCase2);

		Case objCase3 = new Case(
			RecordTypeId = Cache.getRecordTypeId('Case', 'Privacy Request'),
			ContactId = objContact.Id,
			Subject = 'Test Privacy Request',
			Description = 'Test Relation',
			Type = 'Benefits Care',
			Origin = 'Email',
			Status = 'Solved',
			Privacy_Requester_Email__c = 'test@test.com',
			Date_Time_Solved__c = System.now().addHours(6),
			Routing_Case_Reason__c = 'Test Reason'
		);
		list_Cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Test Duplicate Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('lalithatest@acme.com')
			.setDescription('Test Duplicate Case')
			.build();
		objCase4.CCEmailAddress__c = 'seantest@acme.com;alextest@acme.com';
		list_Cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits BYB')
			.setType('BYOB')
			.setSubject('Test Require Action')
			.setStatus('New')
			.setSuppliedEmail('deepikasaini@acme.com')
			.setDescription('Test Require Action')
			.build();
		objCase5.Benefit_Order__c = objBenefitOrder01.Id;
		list_Cases.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Case to be solved with an escalation')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Case to be solved with an escalation')
			.build();
		list_Cases.add(objCase6);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setOrigin('Phone')
			.setType('Payroll Care')
			.setSubject('Phone case 1')
			.setStatus('New')
			.setSuppliedPhone('0987654321')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Phone case')
			.build();
		list_Cases.add(objCase7);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setOrigin('Phone')
			.setType('Payroll Care')
			.setSubject('Phone case 2')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Phone case')
			.build();
		list_Cases.add(objCase8);

		Case objCase9 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_TAX_OPS)
			.setType(CaseUtils.TYPE_TAX_OPS)
			.setSubject('Test Tax Ops Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection('Inbound')
			.setStatus(CaseUtils.STATUS_IN_PROGRESS)
			.setSuppliedEmail('test.test1@gmail.com')
			.setDescription('Test Tax Ops Case')
			.build();
		list_Cases.add(objCase9);

		Case objCase10 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setOpportunity(objBenefitsRenewalOpportunity.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setOrigin('Phone')
			.setType('Payroll Care')
			.setSubject('Phone case 2')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Phone case')
			.build();
		list_Cases.add(objCase10);

		Case objCase11 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setOpportunity(objBenefitsRenewalOpportunity.Id)
			.setRecordTypeId('MF NHE')
			.setOrigin('Phone')
			.setType('NHE')
			.setSubject('NHE Case')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('NHE Case')
			.setFormFullyMapped(true)
			.setFormFitsDependents(true)
			.build();
		list_Cases.add(objCase11);

		Case objCase13 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Email')
			.setType('Payroll')
			.setSubject('Engagement test case')
			.setStatus('New')
			.setSuppliedEmail('testengagement1@gusto.com')
			.setDescription('Engagement test case')
			.build();
		objCase13.Confirm_Case_Reason_Classification__c = objCaseReasonClassification4.Id;
		list_Cases.add(objCase13);

		Case objCase14 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Email')
			.setType('Payroll')
			.setSubject('Escalation test case')
			.setStatus('New')
			.setSuppliedEmail('testescalation@gusto.com')
			.setDescription('Escalation test case')
			.build();
		list_Cases.add(objCase14);

		Group objPayrollCareQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Phone_Routing' AND Type = 'Queue' LIMIT 1];
		Case objCase15 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setDirection('Inbound')
			.setType('Payroll')
			.setSubject('Escalation Phone test case')
			.setOwnerId(objPayrollCareQueue.Id)
			.setStatus('New')
			.setSuppliedPhone('12345678900')
			.setDescription('Escalation Phone test case')
			.build();
		list_Cases.add(objCase15);

		Case objCase16 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setType(CaseUtils.PAYROLL_CASE_PILLAR)
			.setSubject('Test case pillar mapping')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testcasepillar1@gusto.com')
			.setDescription('Test case pillar mapping')
			.build();
		list_Cases.add(objCase16);

		Case objCase17 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits BYB')
			.setType('BYOB')
			.setSubject('Test Require Action 1')
			.setStatus('New')
			.setSuppliedEmail('deepikasaini@acme.com')
			.setDescription('Test Require Action 1')
			.build();
		list_Cases.add(objCase17);

		Case objCase18 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objAccountantContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setType(CaseUtils.PAYROLL_CASE_PILLAR)
			.setSubject('Test case pillar mapping accountant persona')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testcasepillar2@gusto.com')
			.setDescription('Test case pillar mapping accountant persona')
			.build();
		list_Cases.add(objCase18);

		Case objCase19 = new TestDataFactory.CaseBuilder()
		.setAccountId(objAccount.Id)
		.setContactId(objContact.Id)
		.setRecordTypeId('Modern Bank')
		.setOrigin(CaseUtils.ORIGIN_EMAIL)
		.setType(CaseUtils.TYPE_MODERN_BANK)
		.setSubject('Test Modern bank')
		.setStatus(CaseUtils.STATUS_OPEN)
		.setSuppliedEmail('test.test@test.com')
		.setDescription('Test Modern bank')
		.build();
		list_Cases.add(objCase19);

		Case objCase20 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin(CaseUtils.ORIGIN_GUSTO)
			.setType(CaseUtils.PAYROLL_CASE_PILLAR)
			.setSubject('Test chat case')
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('testchatcase@gusto.com')
			.setDescription('Test chat case')
			.build();
		objCase20.First_Level__c = 'test';
		list_Cases.add(objCase20);

		Test.startTest();

		insert list_Cases;

		Case_Escalation__c objCaseEscalation = new Case_Escalation__c(Case__c = objCase6.Id, RecordTypeId = Cache.getRecordTypeId('Case_Escalation__c', 'Social & Executive'));

		insert objCaseEscalation;

		//Creating users
		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		List<User> list_Users = new List<User>();
		System.runAs(objThisUser) {
			Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
			UserRole objCCRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
			User objUser = new TestDataFactory.UserBuilder()
				.setUserName('testinactiveuser@gusto.com')
				.setFirstName('')
				.setLastName('Test Inactive User')
				.setEmail('testinactiveuser@gusto.com')
				.setProfileId(objProfile.Id)
				.setUserRoleId(objCCRole.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(false)
				.build();
			list_Users.add(objUser);

			objUser = new TestDataFactory.UserBuilder()
				.setUserName('testactiveuser@gusto.com')
				.setFirstName('')
				.setLastName('Test Active User')
				.setEmail('testactiveuser@gusto.com')
				.setProfileId(objProfile.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test')
				.setIsActive(true)
				.setBenefitsClass('Class 1')
				.setClassQueue('Class 1')
				.setSecondaryRole('Engagement')
				.build();
			list_Users.add(objUser);

			objUser = new TestDataFactory.UserBuilder()
				.setUserName('testactiveuser2@gusto.com')
				.setFirstName('')
				.setLastName('Test Active User 2')
				.setEmail('testactiveuser2@gusto.com')
				.setProfileId(objProfile.Id)
				.setUserRoleId(objCCRole.Id)
				.setTimeZoneSidKey('America/Denver')
				.setLocaleSidKey('en_US')
				.setLanguageLocaleKey('en_US')
				.setEmailEncoding('ISO-8859-1')
				.setAlias('test2')
				.setIsActive(true)
				.setBenefitsClass('Class 2')
				.setClassQueue('Class 2')
				.build();
			list_Users.add(objUser);

			insert list_Users;
		}

		List<Case_Pillar_Mapping__c> list_CasePillarMappings = new List<Case_Pillar_Mapping__c>();
		Case_Pillar_Mapping__c objMapping = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM001')
			.setType('Payroll')
			.setSupportLevel('Tier 2')
			.setCompanySize('Standard 5-24')
			.setPersona('Admin')
			.setPillar('Test Pillar')
			.setSubPillar('Test Sub Pillar')
			.setCaseOrigin('Email')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-001')
			.setSubPillarKey('SP-001')
			.build();
		list_CasePillarMappings.add(objMapping);

		Case_Pillar_Mapping__c objMapping2 = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM002')
			.setSpecialization('Cancel')
			.setPillar('Cancel Pillar')
			.setSubPillar('Cancel Sub Pillar')
			.setCaseOrigin('Email')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-002')
			.setSubPillarKey('SP-002')
			.build();
		list_CasePillarMappings.add(objMapping2);

		Case_Pillar_Mapping__c objMapping3 = new TestDataFactory.CasePillarMappingBuilder()
			.setName('CPM003')
			.setType('Payroll')
			.setSupportLevel('Tier 2')
			.setCompanySize('Standard 5-24')
			.setPersona('Accountant')
			.setPillar('Test Pillar')
			.setSubPillar('Test Sub Pillar')
			.setCaseOrigin('Email')
			.setWFMQueueTag('Test WFM Queue Tag')
			.setPillarKey('P-001')
			.setSubPillarKey('SP-001')
			.build();
		list_CasePillarMappings.add(objMapping3);

		insert list_CasePillarMappings;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		OpportunityTriggerHelper.skipTrigger = false;
		CaseAuditLogTriggerHelper.skipTrigger = false;
		BenefitOrderHelper.skipTrigger = false;

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check the creation of Zendesk Integration Queue
	 **/
	@isTest
	static void testIntegrationQueCreation() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Test.startTest();
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'MF QLE');
		objCase.AccountId = objAccount.Id;
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		objCase.Origin = 'Email';
		objCase.SuppliedEmail = 'test.test1@test.com';
		objCase.Authorized_User__c = 'No';
		objCase.Formating_Status__c = 'Pending';
		objCase.Status = 'New';
		objCase.Shared_With__c = 'ApIntego';
		objCase.Partner_Record_Id__c = '12345';
		insert objCase;

		//Update case
		objCase.Status = 'Awaiting Response';
		objCase.Partner_Record_Id__c = '12345';
		objCase.Shared_With__c = 'ApIntego';
		objCase.Shared_By__c = 'Test';
		update objCase;

		//Solved the case
		objCase.Status = 'Solved';
		update objCase;

		Test.stopTest();

		List<Zendesk_Integration_Queue__c> list_ZendeskQueues = new List<Zendesk_Integration_Queue__c>([SELECT Id FROM Zendesk_Integration_Queue__c WHERE Case_Id__c = :objCase.id]);
	//	System.assertEquals(1, list_ZendeskQueues.size(), 'List cannot be empty');

		List<Case> list_Cases = [SELECT Customer_Journey__c FROM Case WHERE Id = :objCase.id];
		System.assertEquals(null, list_Cases[0].Customer_Journey__c, 'List cannot be empty');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check whether Business day is updated
	 **/
	@isTest
	static void testSetBusinessDay() {
		Case objCase = [SELECT Id, RFI_3rd_Business_Day__c, RFI_6th_Business_Day__c, RFI_9th_Business_Day__c FROM Case WHERE Subject = 'Payroll Care Case' LIMIT 1];

		System.assert(objCase.RFI_3rd_Business_Day__c == null, 'Incorrect Result');
		System.assert(objCase.RFI_6th_Business_Day__c == null, 'Incorrect Result');
		System.assert(objCase.RFI_9th_Business_Day__c == null, 'Incorrect Result');

		Test.startTest();
		objCase.RFI_Status__c = 'Requested';
		objCase.Status = 'In Progress';
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, RFI_3rd_Business_Day__c, RFI_6th_Business_Day__c, RFI_9th_Business_Day__c FROM Case WHERE Subject = 'Payroll Care Case' LIMIT 1];
		System.assert(objCase.RFI_3rd_Business_Day__c != null, 'Incorrect Result');
		System.assert(objCase.RFI_6th_Business_Day__c != null, 'Incorrect Result');
		System.assert(objCase.RFI_9th_Business_Day__c != null, 'Incorrect Result');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation
	 **/
	@isTest
	static void testSalesCaseCreation() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Contact'];
		List<Large_Scale_Issue__c> list_LargeScaleIssues = [SELECT Id FROM Large_Scale_Issue__c WHERE Name = 'Test LSI'];
		Test.startTest();
		//Creating Cases of various record types
		List<Case> list_Cases = new List<Case>();
		//Creating Benefits Renewal Case
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		objCase1.AccountId = objAccount.Id;
		objCase1.ContactId = list_Contacts[0].Id;
		objCase1.Subject = 'Test Relation';
		objCase1.Description = 'Test Relation';
		objCase1.SuppliedEmail = 'test.contact@gusto.com';
		objCase1.Type = 'Sales';
		objCase1.Origin = 'Email';
		objCase1.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase1);

		//Creating Sales Case
		Case objCase2 = new Case();
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases');
		objCase2.AccountId = objAccount.Id;
		objCase2.Subject = 'Test';
		objCase2.Description = 'Test';
		objCase2.Type = 'Sales';
		objCase2.Origin = 'HelloFax Email';
		objCase2.SuppliedEmail = 'test.test@test.com';
		objCase2.ContactId = list_Contacts[0].Id;
		objCase2.Related_Case__c = objCase1.Id;
		objCase2.Large_Scale_Issue__c = 'Test LSI';
		objCase2.Chat_Closure_Reason_Drift__c = '2-Day IBV Errors;Edit State Tax Numbers;Benefits;Test';
		list_Cases.add(objCase2);

		//Creating Benefits New Plan Case
		Case objCase3 = new Case();
		objCase3.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase3.AccountId = objAccount.Id;
		objCase3.ContactId = list_Contacts[0].Id;
		objCase3.Subject = 'Test Relation';
		objCase3.Description = 'Test Relation';
		objCase3.SuppliedEmail = 'test.contact@gusto.com';
		objCase3.Type = 'Sales';
		objCase3.Origin = 'Email';
		objCase3.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase3);

		//Creating Benefits BoR Case
		Case objCase4 = new Case();
		objCase4.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase4.AccountId = objAccount.Id;
		objCase4.ContactId = list_Contacts[0].Id;
		objCase4.Subject = 'Test Relation';
		objCase4.Description = 'Test Relation';
		objCase4.SuppliedEmail = 'test.contact@gusto.com';
		objCase4.Type = 'Sales';
		objCase4.Origin = 'Email';
		objCase4.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase4);

		insert list_Cases;

		System.assert(objCase1.Id != null, 'Incorrect Result');
		System.assert(objCase2.Id != null, 'Incorrect Result');
		System.assert(objCase3.Id != null, 'Incorrect Result');
		System.assert(objCase4.Id != null, 'Incorrect Result');

		List<Sales_Case_Email_Lead_Queue__c> list_Queues = [SELECT Id FROM Sales_Case_Email_Lead_Queue__c];
		System.assert(list_Queues.size() > 0, 'List cannot be empty');

		objCase2.Status = 'Awaiting Response';
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		update objCase2;

		Case objUpdateCase = [SELECT Id, RecordType.Name FROM Case WHERE Id = :objCase2.Id];
		System.assertEquals('Tax Ops', objUpdateCase.RecordType.Name, 'Incorrect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation
	 **/
	@isTest
	static void testSalesCaseCreation1() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseAuditLogTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		Map<String, Account> map_AccountsByName = new Map<String, Account>();
		for (Account objAccount : [SELECT Id, Name FROM Account WHERE Name IN ('TEST ACCOUNT', 'TEST ACCOUNT CONCIERGE')]) {
			map_AccountsByName.put(objAccount.Name, objAccount);
		}
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Contact'];
		List<Large_Scale_Issue__c> list_LargeScaleIssues = [SELECT Id FROM Large_Scale_Issue__c WHERE Name = 'Test LSI'];
		Test.startTest();
		Opportunity objOpportunity = [SELECT Id, AccountId, RecordTypeId FROM Opportunity WHERE Name = 'Closed Won Opportunity'];
		objOpportunity.StageName = 'Closed Won';
		update objOpportunity;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		objCase1.AccountId = map_AccountsByName.get('TEST ACCOUNT').Id;
		objCase1.ContactId = list_Contacts[0].Id;
		objCase1.Subject = 'Test Relation';
		objCase1.Description = 'Test Relation';
		objCase1.SuppliedEmail = 'test.contact@gusto.com';
		objCase1.Type = 'Sales';
		objCase1.Origin = 'Email';
		objCase1.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase1);

		Case objCase2 = new Case();
		objCase2.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
		objCase2.AccountId = map_AccountsByName.get('TEST ACCOUNT').Id;
		objCase2.Subject = 'Test';
		objCase2.Description = 'Test';
		objCase2.Type = 'Sales';
		objCase2.Origin = 'HelloFax Email';
		objCase2.SuppliedEmail = 'test.test@test.com';
		objCase2.ContactId = list_Contacts[0].Id;
		objCase2.Related_Case__c = objCase1.id;
		objCase2.Large_Scale_Issue__c = 'Test LSI';
		objCase2.Chat_Closure_Reason_Drift__c = '2-Day IBV Errors;Edit State Tax Numbers;Benefits;Test';
		list_Cases.add(objCase2);

		Case objCase3 = new Case();
		objCase3.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase3.AccountId = map_AccountsByName.get('TEST ACCOUNT CONCIERGE').Id;
		objCase3.ContactId = list_Contacts[0].Id;
		objCase3.Subject = 'Test Relation';
		objCase3.Description = 'Test Relation';
		objCase3.SuppliedEmail = 'test.contact@gusto.com';
		objCase3.Type = 'Sales';
		objCase3.Origin = 'Email';
		objCase3.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase3);

		Case objCase4 = new Case();
		objCase4.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase4.AccountId = map_AccountsByName.get('TEST ACCOUNT').Id;
		objCase4.ContactId = list_Contacts[0].Id;
		objCase4.Subject = 'Test Relation';
		objCase4.Description = 'Test Relation';
		objCase4.SuppliedEmail = 'test.contact@gusto.com';
		objCase4.Type = 'Sales';
		objCase4.Origin = 'Email';
		objCase4.Large_Scale_Issue_Classification__c = list_LargeScaleIssues[0].Id;
		list_Cases.add(objCase4);
		insert list_Cases;

		System.assert(objCase1.Id != null, 'Incorrect Result');
		System.assert(objCase2.Id != null, 'Incorrect Result');
		System.assert(objCase3.Id != null, 'Incorrect Result');
		System.assert(objCase4.Id != null, 'Incorrect Result');

		List<Sales_Case_Email_Lead_Queue__c> list_Queues = [SELECT Id FROM Sales_Case_Email_Lead_Queue__c];
		System.assert(list_Queues.size() > 0, 'List cannot be empty');

		list_Cases[1].Status = 'Awaiting Response';
		list_Cases[1].RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		list_Cases[3].Type = 'BOR';
		update list_Cases;
		Case objUpdateCase = [SELECT Id, RecordType.Name FROM Case WHERE Id = :list_Cases[1].Id];
		System.assertEquals('Tax Ops', objUpdateCase.RecordType.Name, 'Incorrect Result');

		Group objCareRoutingQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Engagement Cases'];
		Case objCareRoutingCase = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase3.Id];
		System.assertEquals(objCareRoutingQueue.Id, objCareRoutingCase.OwnerId, 'Incorrect Result');
		//delete cse;
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation
	 **/
	@isTest
	static void testCaseCreation() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];
		BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE TimeZoneSidKey = 'America/Denver' LIMIT 1];
		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Subject = 'Test Relation';
		objCase.Description = 'Test Relation';
		objCase.Type = 'Benefits Care';
		objCase.Origin = 'Cobra Email';
		objCase.Status = 'Solved';
		//cse1.BusinessHoursId = bnHrs.id;
		objCase.CreatedDate = System.today();
		objCase.Date_Time_Solved__c = System.now().addHours(6);
		objCase.Routing_Case_Reason__c = 'Test Reason';
		insert objCase;
		System.assert(objCase.Id != null, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation for record type Privary request
	 **/
	@isTest
	static void testCaseCreationPrivacyRequest() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		Account objAccount = TestUtility.CompanyAccount();
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];
		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Privacy Request');
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Subject = 'Test Privacy Request';
		objCase.Description = 'Test Relation';
		objCase.Type = 'Benefits Care';
		objCase.Origin = 'Email';
		objCase.Status = 'Solved';
		objCase.Privacy_Requester_Email__c = 'test@test.com';
		objCase.CreatedDate = System.today();
		objCase.Date_Time_Solved__c = System.now().addHours(6);
		objCase.Routing_Case_Reason__c = 'Test Reason';
		insert objCase;
		//Yuvraj : 21-05-2020
		objCase.Status = 'Identity Verified';
		update objCase;
		objCase.Status = 'Closed';
		update objCase;
		Case objUpdatedCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Closed', objUpdatedCase.Status, 'Status has to Closed');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the creation of duplicate privacy request case
	 **/
	@isTest
	static void testCaseCreationPrivacyRequestDuplicate() {
		Test.startTest();

		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'TEST CONTACT'];

		Case objCase = new Case(
			RecordTypeId = Cache.getRecordTypeId('Case', 'Privacy Request'),
			ContactId = list_Contacts[0].Id,
			Subject = 'Test Privacy Request',
			Description = 'Test Relation',
			Type = 'Benefits Care',
			Origin = 'Email',
			Status = 'Solved',
			Privacy_Requester_Email__c = 'test@test.com',
			CreatedDate = System.today(),
			Date_Time_Solved__c = System.now().addHours(6),
			Routing_Case_Reason__c = 'Test Reason'
		);
		insert objCase;

		Case objUpdatedCase = [SELECT Id, Status, ParentId FROM Case WHERE Id = :objCase.Id];

		System.assert(objUpdatedCase != null, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation for Benefits Care
	 **/
	@isTest
	static void testBenefitsCareCreation() {
		Account objAccount = TestUtility.CompanyAccount();
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		CaseAuditLogTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;

		BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE TimeZoneSidKey = 'America/Denver' LIMIT 1];

		Agency_Information__c objAgency = new Agency_Information__c();
		objAgency.Name = 'Test Name';
		objAgency.Tax_type__c = 'Unemployment';
		objAgency.Active__c = true;
		insert objAgency;

		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		objCase.AccountId = objAccount.Id;
		objCase.Subject = 'Test';
		objCase.Status = 'Closed';
		objCase.Status = 'Awaiting Response';
		objCase.Description = 'Test [~~~5185~~~]';
		objCase.Type = 'Suspension Audit';
		objCase.Origin = 'Email';
		objCase.BusinessHoursId = objBusinessHours.Id;
		objCase.SuppliedEmail = 'test.test@test.com';
		objCase.Integration_Id__c = 'Zendesk-5185';
		objCase.Automation_Status__c = 'Started';
		objCase.Automation_Status_Follow_Up__c = 'Started';
		//cse.ContactId = contact.id;
		objCase.Agency_Information__c = objAgency.Id;
		insert objCase;

		Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
		objBenefitOrder.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
		objBenefitOrder.Name = 'New BO Opp';
		objBenefitOrder.Account__c = objAccount.Id;
		objBenefitOrder.Order_Status__c = 'Fulfilled';
		objBenefitOrder.EE_at_Fulfillment__c = 16;
		insert objBenefitOrder;

		objCase.Status = 'Solved';
		objCase.First_Response_Time__c = Date.newInstance(2018, 3, 9);
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		objCase.Requires_Action__c = true;
		objCase.Benefit_Order__c = objBenefitOrder.id;
		objCase.Routing_Case_Reason__c = 'Test Reason';
		objCase.Confirm_Case_Reason__c = 'Test Confirm';
		CaseTriggerHelper.counter = 0;
		update objCase;

		Case objUpdatedCase = [SELECT Id, Status, Shared_By__c, Shared_With__c, RecordTypeId, Partner_Record_Id__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Solved', objUpdatedCase.Status, 'Status has to be Solved');
		objUpdatedCase.Status = 'Closed';
		objUpdatedCase.Partner_Record_Id__c = 'Test PartnerId';
		objUpdatedCase.Shared_With__c = 'ApIntego';
		objUpdatedCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Ops');
		update objUpdatedCase;
		Case objUpdatedCase2 = [SELECT Id, Status, Shared_By__c, Shared_With__c, RecordTypeId, Partner_Record_Id__c FROM Case WHERE Id = :objUpdatedCase.Id];
		System.assertEquals('Closed', objUpdatedCase2.Status, 'Status has to be Closed');

		//delete cse;
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the Phone updation on Contact when Case is solved
	 **/
	@isTest
	static void testSolvedCaseContactPhoneUpdate() {
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		// cse.AccountId = acc.Id;
		objCase.Subject = 'Test';
		objCase.Status = 'Closed';
		objCase.Status = 'Awaiting Response';
		objCase.Description = 'Test ';
		objCase.Type = 'Payroll Care';
		objCase.Origin = 'Phone';
		objCase.Direction__c = 'Inbound';
		objCase.SuppliedPhone = '8888888888';
		objCase.SuppliedEmail = 'test.test@test.com';
		objCase.Integration_Id__c = 'Zendesk-5185';
		objCase.Send_Survey__c = true;
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Confirm_Case_Reason__c = 'Test reason';
		insert objCase;

		objCase.Status = 'Solved';

		Test.startTest();
		update objCase;

		list_Contacts = [SELECT Id, MobilePhone FROM Contact WHERE Id = :objCase.ContactId];
		System.assert(list_Contacts[0].MobilePhone == objCase.SuppliedPhone, 'Incorrect Result');
		//step 2
		objCase.Status = 'In Progress';
		objCase.SuppliedPhone = '8888888811';
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		objCase.Status = 'Solved';
		update objCase;
		list_Contacts = [SELECT Id, MobilePhone FROM Contact WHERE Id = :objCase.ContactId];
		System.assertEquals('8888888888', list_Contacts[0].MobilePhone, 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the Benefits Care Suspension Audit Case Email
	 **/
	@isTest
	static void testBenefitsCareSuspensionAuditCaseEmail() {
		AccountTriggerHelper.skipTrigger = true;
		Account objAccount = TestUtility.CompanyAccount();
		objAccount.ZP_Company_Id__c = '432432432';
		update objAccount;
		AccountTriggerHelper.skipTrigger = false;

		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];
		list_Contacts[0].ZP_User_Id__c = '4324324321';
		update list_Contacts;
		ContactTriggerHelper.skipTrigger = false;

		ZPUserRoleTriggerHelper.skipTrigger = true;
		ZP_User_Role__c objZPUserRole = new Zp_User_Role__c();
		objZPUserRole.User_Id__c = '4324324321';
		objZPUserRole.Company_Id__c = '432432432';
		objZPUserRole.Type__c = 'Payroll:Admin';
		insert objZPUserRole;

		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
		objCase.AccountId = objAccount.Id;
		objCase.Subject = 'Suspension Audit Case';
		objCase.Description = 'Test Relation';
		objCase.Type = 'Suspension Audit';
		objCase.status = 'New';
		insert objCase;

		Case objUpdatedCase = [SELECT Id, ContactId FROM Case WHERE Id = :objCase.Id];
		System.assert(objUpdatedCase.ContactId != null, 'Incorrect Result');

		test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation of type Modern Bank
	 **/
	@isTest
	static void modernBankCaseCodeCoverage() {
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];
		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Modern Bank');
		// cse.AccountId = acc.Id;
		objCase.Subject = 'Test';
		objCase.Status = 'New';
		objCase.Description = 'Test ';
		objCase.Type = 'Modern Bank';
		objCase.Origin = 'Phone';
		objCase.Direction__c = 'Inbound';
		objCase.SuppliedPhone = '8888888888';
		objCase.SuppliedEmail = 'test.test@test.com';
		objCase.Integration_Id__c = 'Zendesk-5185123';
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Complaint_Type__c = 'Threatened Legal Action';
		insert objCase;
		System.assertEquals(objCase.RecordTypeId, Cache.getRecordTypeId('Case', 'Modern Bank'), 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation of MF NHE type
	 **/
	@isTest
	static void MFCaseCodeCoverage() {
		List<Contact> list_Contacts = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact'];

		Test.startTest();
		User objUser = new User();
		User objThisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(objThisUser) {
			Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
			UserRole objUserRole = [SELECT Id FROM UserRole WHERE Name = 'sales_sdr_partner_xx'];
			objUser.Username = 'test1239@gm.com';
			objUser.LastName = 'test';
			objUser.Email = 'test1239@gm.com';
			objUser.Alias = 'test';
			objUser.CommunityNickname = 'testMFC';
			objUser.TimeZoneSidKey = 'America/Denver';
			objUser.LocaleSidKey = 'en_US';
			objUser.EmailEncodingKey = 'ISO-8859-1';
			objUser.LanguageLocaleKey = 'en_US';
			objUser.FederationIdentifier = 'test@gm.com';
			objUser.ProfileId = objProfile.Id;
			objUser.UserRoleId = objUserRole.Id;
			objUser.IsActive = false;

			insert objUser;
		}

		Agency_Information__c objAgency = new Agency_Information__c();
		objAgency.Name = 'Test Name';
		objAgency.Tax_type__c = 'Unemployment';
		objAgency.Active__c = true;
		insert objAgency;

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'MF NHE');
		// cse.AccountId = acc.Id;
		objCase.Subject = 'Test';
		objCase.Status = 'New';
		objCase.Description = 'Test ';
		objCase.Type = 'MF NHE';
		objCase.Origin = 'Gusto';
		objCase.Direction__c = 'Inbound';
		objCase.SuppliedPhone = '8888888888';
		objCase.SuppliedEmail = 'test.test@test.com';
		objCase.Integration_Id__c = 'Zendesk-51851234';
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Follow_Up_Completed_by__c = UserInfo.getUserId();
		objCase.OwnerId = objUser.id;
		objCase.Agency_Information__c = objAgency.Id;
		objCase.Large_Scale_Issue__c = 'TaxOps';
		insert objCase;

		objCase.OwnerId = objUser.Id;
		update objCase;
		Case objUpdatedCase = [SELECT Id, HI_Fulfillment_Event_Completed_Date__c FROM Case WHERE Id = :objCase.Id];
		System.assert(objUpdatedCase.HI_Fulfillment_Event_Completed_Date__c != null, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case fulfillment process
	 **/
	@isTest
	static void testProcessCaseFulfillmentStatus() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		Test.startTest();

		Account objAccount = new Account();
		objAccount.Name = 'Test Account';
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		insert objAccount;

		Contact objContact = new Contact();
		objContact.FirstName = 'Test1';
		objContact.LastName = 'Con1';
		objContact.AccountId = objAccount.Id;
		objContact.Email = 'test1con@test.com';
		insert objContact;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.Subject = 'Test subject';
		objCase1.Status = 'New';
		objCase1.Origin = 'Web';
		objCase1.Direction__c = 'Inbound';
		objCase1.ContactId = objContact.Id;
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		//cse1.Selection_Ids__c = '123456';
		objCase1.Subscriber_Id__c = '5678765';
		objCase1.Automation_Status__c = 'Started'; //Started,Completed
		list_Cases.add(objCase1);

		Case objCase2 = new Case();
		objCase2.Subject = 'test subject';
		objCase2.Status = 'New';
		objCase2.Origin = 'Web';
		objCase2.Direction__c = 'Inbound';
		objCase2.ContactId = objContact.Id;
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		list_Cases.add(objCase2);
		insert list_Cases;

		list_Cases[0].Automation_Status__c = 'Completed';
		list_Cases[0].Selection_UUIds__c = objCase2.Id;
		list_Cases[0].Subscriber_Id__c = 'Test';
		list_Cases[0].Type = 'NHE';
		list_Cases[0].Status = 'Awaiting Response';
		list_Cases[0].Partner_Record_Id__c = '1234567890';
		list_Cases[0].Shared_With__c = 'ApIntego';
		list_Cases[0].Shared_By__c = 'test';

		list_Cases[1].Automation_Status__c = 'Completed';
		list_Cases[1].Selection_Ids__c = objCase2.Id;
		list_Cases[1].Subscriber_Id__c = 'Test';
		list_Cases[1].Type = 'NHE';
		list_Cases[1].Status = 'Awaiting Response';
		list_Cases[1].Partner_Record_Id__c = list_Cases[0].Id;
		list_Cases[1].Selection_Ids__c = list_Cases[0].Id;
		list_Cases[1].Shared_With__c = 'ApIntego';
		update list_Cases;

		List<Case_Fulfillment_Selection_Status__c> list_CaseFulfillmentStatus = new List<Case_Fulfillment_Selection_Status__c>();
		list_CaseFulfillmentStatus = [SELECT Id FROM Case_Fulfillment_Selection_Status__c WHERE Case__c IN :list_Cases];
		System.assert(list_CaseFulfillmentStatus.size() > 0, 'List cannot be empty');

		Test.stopTest();
	}

	/**
	 * @Author      : Nigam Goyal
	 * @Description : Testing the case fulfillment process
	 **/
	@isTest
	static void testProcessCaseFulfillmentFailedStatus() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		List<Account> list_Accounts = new List<Account>();

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

		//Creating Cases
		List<Case> list_Cases = new List<Case>();
		Case objCase = new Case();

		objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test subject')
			.setStatus('New')
			.setType('Payroll Care')
			.setOrigin('Web')
			.setDirection('Inbound')
			.setSuppliedPhone('1234567890')
			.setSubscriberId('5678765')
			.setAutomationStatus('Started')
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setContactId(objContact.Id)
			.setSubject('Test Subject')
			.setStatus('New')
			.setDescription('Test Case 1 Description')
			.setSuppliedEmail('test.contact@gusto.com')
			.setType('Payroll Care')
			.setOrigin('Web')
			.setDirection('Inbound')
			.build();
		list_Cases.add(objCase2);
		insert list_Cases;

		Test.startTest();
		list_Cases[0].Automation_Status__c = 'Failed';
		list_Cases[0].Automation_Status_Follow_Up__c = 'Failed';
		list_Cases[0].Selection_UUIds__c = objCase2.Id;
		list_Cases[0].Subscriber_Id__c = 'Test';
		list_Cases[0].Type = 'NHE';
		list_Cases[0].Status = 'Awaiting Response';
		list_Cases[0].Partner_Record_Id__c = '1234567890';
		list_Cases[0].Shared_With__c = 'ApIntego';
		list_Cases[0].Shared_By__c = 'test';

		list_Cases[1].Automation_Status__c = 'Failed';
		list_Cases[1].Automation_Status_Follow_Up__c = 'Failed';
		list_Cases[1].Selection_Ids__c = objCase2.Id;
		list_Cases[1].Subscriber_Id__c = 'Test';
		list_Cases[1].Type = 'NHE';
		list_Cases[1].Status = 'Awaiting Response';
		list_Cases[1].Partner_Record_Id__c = list_Cases[0].Id;
		list_Cases[1].Selection_Ids__c = list_Cases[0].Id;
		list_Cases[1].Shared_With__c = 'ApIntego';
		update list_Cases;

		List<Case_Fulfillment_Selection_Status__c> list_CaseFulfillmentStatus = new List<Case_Fulfillment_Selection_Status__c>();
		list_CaseFulfillmentStatus = [SELECT Id FROM Case_Fulfillment_Selection_Status__c WHERE Case__c IN :list_Cases];
		System.assert(list_CaseFulfillmentStatus.size() > 0, 'List cannot be empty');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation for Payroll Transfer
	 **/
	@isTest
	static void testPayrollTransferCase() {
		Test.startTest();

		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Contact'];

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		objOpportunity.Name = 'Test';
		objOpportunity.StageName = 'SAL';
		objOpportunity.CloseDate = System.today().addDays(30);
		objOpportunity.NumberOfEmployees__c = 12;
		OpportunityTriggerHelper.skipTrigger = true;
		insert objOpportunity;

		Order objOrder = new Order(
			AccountId = objAccount.Id,
			Status = 'Drafted',
			First_Check_Date__c = Date.newInstance(2019, 10, 1),
			EffectiveDate = Date.newInstance(2019, 9, 28),
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			Active_Employee_Count__c = 10,
			Contractor_Count__c = 2,
			Inactive_Employee_Count__c = 5,
			States__c = 'CA'
		);
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		objCase1.AccountId = objAccount.Id;
		objCase1.ContactId = list_Contacts[0].Id;
		objCase1.Subject = 'Test Relation';
		objCase1.Description = 'Test Relation';
		objCase1.SuppliedEmail = 'PayrolltransferCasetriggerHelper@gusto.com';
		objCase1.Type = 'Payroll Transfer';
		objCase1.Origin = 'Email';
		objCase1.Direction__c = 'Inbound';
		list_Cases.add(objCase1);

		Case objCase2 = new Case();
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		objCase2.AccountId = objAccount.Id;
		objCase2.ContactId = list_Contacts[0].Id;
		objCase2.Subject = 'Test Relation';
		objCase2.Description = 'Test Relation';
		objCase2.SuppliedEmail = 'PayrolltransferCasetriggerHelper@gusto.com';
		objCase2.Type = 'Payroll Transfer';
		objCase2.Origin = 'Email';
		objCase2.Direction__c = 'Inbound';
		list_Cases.add(objCase2);
		insert list_Cases;

		Bulk_Migration_Request__c objBulkMigrationRequest = new Bulk_Migration_Request__c(Type__c = 'Bulk Migration', Bulk_Migration_Status__c = 'New');
		insert objBulkMigrationRequest;

		list_Cases[1].Requires_Action__c = true;
		list_Cases[1].Bulk_Migration__c = objBulkMigrationRequest.Id;
		update list_Cases[1];

		Case objUpdatedCase = [SELECT Id, Requires_Action__c FROM Case WHERE Id = :list_Cases[1].Id];
		System.assertEquals(true, objUpdatedCase.Requires_Action__c, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the populateFulfillmentEventCompletedDate method logic
	 **/
	@isTest
	static void testPopulateFulfillmentEventCompletedDate() {
		Test.startTest();

		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Contact'];

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		objOpportunity.Name = 'Test';
		objOpportunity.StageName = 'SAL';
		objOpportunity.CloseDate = System.today().addDays(30);
		objOpportunity.NumberOfEmployees__c = 12;
		OpportunityTriggerHelper.skipTrigger = true;
		insert objOpportunity;

		Order objOrder = new Order(
			AccountId = objAccount.Id,
			Status = 'Drafted',
			First_Check_Date__c = Date.newInstance(2019, 10, 1),
			EffectiveDate = Date.newInstance(2019, 9, 28),
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			Active_Employee_Count__c = 10,
			Contractor_Count__c = 2,
			Inactive_Employee_Count__c = 5,
			States__c = 'CA'
		);
		OrderTriggerHelper.skipTrigger = true;
		insert objOrder;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Member Fulfillment Emails');
		objCase1.AccountId = objAccount.Id;
		objCase1.ContactId = list_Contacts[0].Id;
		objCase1.Subject = 'Test Relation';
		objCase1.Description = 'Test Relation';
		objCase1.SuppliedEmail = 'PayrolltransferCasetriggerHelper@gusto.com';
		objCase1.Integration_Id__c = '123111111123';
		objCase1.Origin = 'Email';
		objCase1.Direction__c = 'Inbound';
		objCase1.Follow_Up_Completed_by__c = UserInfo.getUserId();
		list_Cases.add(objCase1);

		Case objCase2 = new Case();
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Member Fulfillment Emails');
		objCase2.AccountId = objAccount.Id;
		objCase2.ContactId = list_Contacts[0].Id;
		objCase2.Subject = 'Test Relation';
		objCase2.Description = 'Test Relation';
		objCase2.SuppliedEmail = 'PayrolltransferCasetriggerHelper@gusto.com';
		objCase2.Integration_Id__c = '123111111123';
		objCase2.Origin = 'Email';
		objCase2.Direction__c = 'Inbound';
		list_Cases.add(objCase2);

		insert list_Cases;

		objCase2.Follow_Up_Completed_by__c = UserInfo.getUserId();
		update objCase2;

		Case objUpdatedCase = [SELECT Id, HI_Fulfillment_Event_Completed_Date__c FROM Case WHERE Id = :objCase1.Id];
		System.assert(objUpdatedCase.HI_Fulfillment_Event_Completed_Date__c != null, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the Auto Assignment ForReseller Account Cases
	 **/
	@isTest
	static void testAutoAssignmentForResellerAccountCases() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST RESELLER ACCOUNT' LIMIT 1];
		Contact objContactReseller = [SELECT Id FROM Contact WHERE FirstName = 'TEST RESELLER CONTACT' LIMIT 1];

		Test.startTest();

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		objCase1.AccountId = objAccount.Id;
		objCase1.ContactId = objContactReseller.Id;
		objCase1.Subject = 'Test Auto Assignment';
		objCase1.Description = 'Test Auto Assignment';
		objCase1.Origin = 'Email';
		objCase1.Direction__c = 'Inbound';
		objCase1.OwnerId = UserInfo.getUserId();
		list_Cases.add(objCase1);
		//System.assert(objCase1.Id != null);

		Case objCase2 = new Case();
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res'); //Yuvraj : 21-05-2020
		objCase2.AccountId = objAccount.Id;
		objCase2.ContactId = objContactReseller.Id;
		objCase2.Subject = 'Test Auto Assignment';
		objCase2.Description = 'Test Auto Assignment';
		objCase2.Origin = 'Email';
		objCase2.Direction__c = 'Inbound';
		list_Cases.add(objCase2);

		//Yuvraj : 21-05-2020
		Group objTaxResQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Mass_Email_Cases' AND Type = 'Queue' LIMIT 1];
		List<Large_Scale_Issue__c> list_largeScaleIssues = [SELECT Id FROM Large_Scale_Issue__c WHERE Name = 'Test LSI'];
		Case objCase3 = new Case();
		objCase3.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		objCase3.AccountId = objAccount.Id;
		objCase3.ContactId = objContactReseller.Id;
		objCase3.Subject = 'Test Auto Assignment';
		objCase3.Description = 'Test Auto Assignment';
		objCase3.Large_Scale_Issue_Classification__c = null;
		objCase3.Direction__c = 'Inbound';
		objCase3.OwnerId = objTaxResQueue.Id;
		objCase3.Status = 'Response Received';
		list_Cases.add(objCase3);

		insert list_Cases;

		Test.stopTest();

		objCase3.Large_Scale_Issue_Classification__c = list_largeScaleIssues[0].Id;
		update objCase3;
		Case objUpdatedCase = [SELECT Id, Large_Scale_Issue_Classification__c FROM Case WHERE Id = :objCase3.Id];
		System.assert(objUpdatedCase.Large_Scale_Issue_Classification__c != null, 'Incorrect Result');

		//get Tax Res case and Update owner to "Tax_Res_Auto_Close"
		Case objTaxResCase = [SELECT Id, OwnerId FROM Case WHERE RecordType.Name = 'Tax Res' LIMIT 1];
		objTaxResCase.OwnerId = CaseTriggerHelper.TAXRES_AUTO_CLOSE_QUEUE_ID;
		update objTaxResCase;

		Case objTaxRes = [SELECT Id, Status FROM Case WHERE Id = :objTaxResCase.Id];
		System.assertEquals('Closed', objTaxRes.Status, 'Incorrect Result');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the Auto Assignment ForReseller Account Cases with BMR
	 **/
	@isTest
	static void testAutoAssignmentForResellerAccountCasesWithBMR() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST RESELLER ACCOUNT' LIMIT 1];
		Contact objContactReseller = [SELECT Id FROM Contact WHERE FirstName = 'TEST RESELLER CONTACT' LIMIT 1];

		Bulk_Migration_Request__c objMigrationRequest = new Bulk_Migration_Request__c(Reseller_Account__c = objAccount.Id);
		insert objMigrationRequest;

		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case');
		objCase.AccountId = objAccount.Id;
		objCase.ContactId = objContactReseller.Id;
		objCase.Subject = 'Test Auto Assignment';
		objCase.Description = 'Test Auto Assignment';
		objCase.Origin = 'Email';
		objCase.Direction__c = 'Inbound';
		insert objCase;
		System.assert(objCase.Id != null, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the setRequiresActionOnTicket() method
	 **/
	static void testTicketRequiresAction() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Contact'];
		Test.startTest();

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		objCase.AccountId = objAccount.Id;
		objCase.ContactId = list_Contacts[0].Id;
		objCase.Subject = 'Underwriting Update';
		objCase.Description = 'Underwriting Update';
		objCase.SuppliedEmail = 'test.contact@gusto.com';
		objCase.Type = 'Sales';
		objCase.Origin = 'Email';
		objCase.Status = 'New';
		insert objCase;

		TicketTriggerHelper.skipTrigger = true;

		Ticket__c objTicket = new Ticket__c();
		objTicket.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get('Qualification').getRecordTypeId();
		objTicket.Escalation_Reason__c = 'Underwriting Update';
		objTicket.Escalation_Reason_Detail__c = 'Start Up Groups';
		objTicket.Team__c = 'Onboarding';
		objTicket.Sub_Team__c = 'Qualification';
		objTicket.Status__c = 'New';
		objTicket.Priority__c = 'Low';
		objTicket.Skip_Assignment__c = true;
		objTicket.OwnerId = userInfo.getUserId();
		objTicket.Fulfillment_Case__c = objCase.Id;
		insert objTicket;

		objCase.Requires_Action__c = true;
		update objCase;
		objTicket = [SELECT Id, Requires_Action__c FROM Ticket__c WHERE Id = :objTicket.Id];
		System.assertEquals(true, objTicket.Requires_Action__c, 'Incorrect Result');
		Test.stopTest();
		//system.assert([SELECT count() FROM Ticket__c WHERE Id = :objTicket.Id AND Requires_Action__c = true] > 0);
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the handleEmailToCaseForCustomerResponses method logic
	 **/
	@isTest
	static void testHandleCustomerResponses() {
		//Insert custom settings
		Tax_Res_Product_Email_Subject__c objEmailSubject = new Tax_Res_Product_Email_Subject__c(Name = 'Subject1', Subject__c = 'FYI: Gusto updated your federal deposit schedule to Semiweekly');
		insert objEmailSubject;

		AccountTriggerHelper.skipTrigger = true;
		contactTriggerHelper.skipTrigger = true;
		Test.startTest();

		Account objAccount = new Account();
		objAccount.Name = 'Test Account';
		objAccount.RecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		insert objAccount;

		Contact objContact = new Contact();
		objContact.FirstName = 'Test1';
		objContact.LastName = 'Con1';
		objContact.AccountId = objAccount.Id;
		objContact.Email = 'test1con@test.com';
		insert objContact;

		Case objCase = new Case();
		objCase.Subject = 'FYI: Gusto updated your federal deposit schedule to Semiweekly';
		objCase.Status = 'New';
		objCase.Origin = 'Email';
		objCase.Direction__c = 'Inbound';
		objCase.ContactId = objContact.Id;
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		insert objCase;

		System.assert([SELECT COUNT() FROM Case WHERE RecordType.Name = 'Tax Res'] == 1, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the handleRquiresAction method logic
	 **/
	@isTest
	static void testBenefitsBoRCreation() {
		Test.startTest();

		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		HIBorTransferTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		Group objGroup = new Group(Name = 'Carrier Implementation Queue', Type = 'Queue');
		insert objGroup;

		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueuesObject objQueue = new QueueSObject(QueueId = objGroup.Id, SobjectType = 'Carrier_Order__c');
			insert objQueue;
		}

		HI_BOR_Transfer__c objBORTransfer = new HI_BOR_Transfer__c();
		objBORTransfer.Benefit_Types__c = '["dca", "vision", "short_term_disability", "long_term_disability", "medical", "dental", "fsa", "hsa", "hra", "commuter", "life"]';
		objBORTransfer.Id__c = '1123';
		objBORTransfer.Status__c = 'form_created';
		objBORTransfer.Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "dca"=>"Zenefits", "commuter"=>"Wage Works", "hsa"=>"Zenefits"}, "title"=>"President", "effective_month"=>6, "effective_month_same_as_medical"=>"no", "effective_month_fsa"=>5, "effective_month_dca"=>5}';
		insert objBORTransfer;

		Opportunity objOpportunity = TestUtility.BenefitsBoROpportunity();
		objOpportunity.Id__c = '1123';
		objOpportunity.Source_Id__c = '1123';
		objOpportunity.Id_And_Source_Id__c = 'Id__c=>1123,Source_Id__c=>1123';
		update objOpportunity;

		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('Benefits BoR', objOpportunity.Id, 'Test Benefit Order', false);
		objBenefitOrder.BoR_Id__c = '1123';
		objBenefitOrder.Type__c = 'BOR';
		objBenefitOrder.Order_Status__c = 'Closed Admin';
		insert objBenefitOrder;

		Carrier__c objCarrier = TestUtility.Carrier();
		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = 'TEST CARRIER ORDER';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Benefit_Order__c = objBenefitOrder.Id;
		objCarrierOrder.Order_Type__c = 'Qualification';
		objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		objCarrierOrder.OwnerId = objGroup.Id;
		insert objCarrierOrder;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objOpportunity.AccountId)
			.setFirstName('Test Contact')
			.setLastName('Test')
			.setZPUserId('432432432')
			.setEmail('CasetriggerHelper1@gusto.com')
			.setPhone('123456')
			.build();
		insert objContact;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase1.AccountId = objOpportunity.AccountId;
		objCase1.Subject = 'Test';
		objCase1.Status = 'New';
		objCase1.Description = 'Test [~~~5185~~~]';
		objCase1.Type = 'BOR';
		objCase1.Origin = 'Hippo';
		objCase1.Benefit_Order__c = objBenefitOrder.Id;
		objCase1.SuppliedEmail = 'test.test@test.com';
		objCase1.ContactId = objContact.Id;
		objCase1.Requires_Action__c = false;
		list_Cases.add(objCase1);

		Case objCase2 = objCase1.clone();
		objCase2.Type = 'Benefits BOR Carrier Case';
		objCase2.Origin = 'Hippo';
		objCase2.Benefit_Order__c = objBenefitOrder.Id;
		objCase2.Carrier_Order__c = objCarrierOrder.Id;
		objCase2.Requires_Action__c = false;
		list_Cases.add(objCase2);

		insert list_Cases;

		List<Case> list_CaseUpdates = new List<Case>();
		objCase1.Requires_Action__c = true;
		list_CaseUpdates.add(objCase1);
		objCase2.Requires_Action__c = true;
		list_CaseUpdates.add(objCase2);
		update list_CaseUpdates;
		Benefit_Order__c objUpdatedBenefitOrder = [SELECT Id, Requires_Action__c FROM Benefit_Order__c WHERE Id = :objBenefitOrder.Id];
		System.assertEquals(true, objUpdatedBenefitOrder.Requires_Action__c, 'Incorrect Result');
		Carrier_Order__c objUpdatedCarrierOrder = [SELECT Id, CO_Requires_Action__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id];
		System.assertEquals(true, objUpdatedCarrierOrder.CO_Requires_Action__c, 'Incorrect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the case creation
	 **/
	@isTest
	static void testBenefitsBoRCreationDeletion() {
		blnRunCatchTest = true;
		Test.startTest();
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		HIBorTransferTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		Group objGroup = new Group(Name = 'Carrier Implementation Queue', Type = 'Queue');
		insert objGroup;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueuesObject objQueue = new QueueSObject(QueueId = objGroup.Id, SobjectType = 'Carrier_Order__c');
			insert objQueue;
		}

		HI_BOR_Transfer__c objHIBORTransfer = new HI_BOR_Transfer__c();
		objHIBORTransfer.Benefit_Types__c = '["dca", "vision", "short_term_disability", "long_term_disability", "medical", "dental", "fsa", "hsa", "hra", "commuter", "life"]';
		objHIBORTransfer.Id__c = '1123';
		objHIBORTransfer.Status__c = 'form_created';
		objHIBORTransfer.Additional_Information__c = '{"administrators"=>{"fsa"=>"Zenefits", "dca"=>"Zenefits", "commuter"=>"Wage Works", "hsa"=>"Zenefits"}, "title"=>"President", "effective_month"=>6, "effective_month_same_as_medical"=>"no", "effective_month_fsa"=>5, "effective_month_dca"=>5}';
		insert objHIBORTransfer;

		Opportunity objOpportunity = TestUtility.BenefitsBoROpportunity();
		objOpportunity.Id__c = '1123';
		objOpportunity.Source_Id__c = '1123';
		objOpportunity.Id_And_Source_Id__c = 'Id__c=>1123,Source_Id__c=>1123';
		update objOpportunity;

		Benefit_Order__c objBenefitOrder = TestUtility.createTestBenefitOrder('Benefits BoR', objOpportunity.Id, 'Test Benefit Order', false);
		objBenefitOrder.BoR_Id__c = '1123';
		objBenefitOrder.Type__c = 'BOR';
		objBenefitOrder.Order_Status__c = 'Closed Admin';
		insert objBenefitOrder;

		Carrier__c objCarrier = TestUtility.Carrier();
		Carrier_Order__c objCarrierOrder = (Carrier_Order__c) Carrier_Order__c.SObjectType.newSObject();
		objCarrierOrder.Name = 'TEST CARRIER ORDER';
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Benefit_Order__c = objBenefitOrder.Id;
		objCarrierOrder.Order_Type__c = 'Qualification';
		objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
		objCarrierOrder.OwnerId = objGroup.Id;
		insert objCarrierOrder;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objOpportunity.AccountId)
			.setFirstName('Test Contact')
			.setLastName('Test')
			.setZPUserId('432432432')
			.setEmail('CasetriggerHelper1@gusto.com')
			.setPhone('123456')
			.build();
		insert objContact;

		List<Case> list_Cases = new List<Case>();
		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits BoR');
		objCase.AccountId = objOpportunity.AccountId;
		objCase.Subject = 'Test';
		objCase.Status = 'New';
		objCase.Description = 'Test [~~~5185~~~]';
		objCase.Type = 'BOR';
		objCase.Origin = 'Hippo';
		objCase.Benefit_Order__c = objBenefitOrder.Id;
		objCase.SuppliedEmail = 'test.test@test.com';
		objCase.ContactId = objContact.Id;
		objCase.Requires_Action__c = false;
		list_Cases.add(objCase);

		Case objCase2 = objCase.clone();
		objCase2.Type = 'Benefits BOR Carrier Case';
		objCase2.Origin = null;
		objCase2.Benefit_Order__c = null;
		objCase2.Carrier_Order__c = null;
		objCase2.Description = null;
		objCase2.Requires_Action__c = false;
		list_Cases.add(objCase2);

		try {
			insert list_Cases;
			System.assert(objCase.Id != null, 'Incorrect Result');
			delete objCase;
			undelete objCase;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CaseTriggerHelperTest', 'testBenefitsBoRCreationDeletion', ex.getMessage(), ex.getStackTraceString());
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing if the case record type is updated from IVR
	 **/
	@isTest
	public static void testIVRPayroll() {
		Test.startTest();

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c, 'Incorect Result');
		String strAllTiers =
			objTierConfig.Old_Tier_1__c +
			';' +
			objTierConfig.Old_Tier_2__c +
			';' +
			objTierConfig.Old_Tier_3__c +
			';' +
			objTierConfig.New_Tier_1__c +
			';' +
			objTierConfig.New_Tier_2__c +
			';' +
			objTierConfig.New_Tier_3__c;

		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		IVR_Routing_Log__c objIVRRoutingLog = new IVR_Routing_Log__c(
			ConversationId__c = '1111111111111',
			CIP_Auth__c = 'Authenticated',
			InQueue_Queue_Name__c = 'Payroll Care',
			ZP_User_Id__c = '098765432',
			ANI__c = '0000000000',
			Type__c = 'Inbound Call',
			CIP_Auth_Path__c = 'AuthPath',
			CIP_Company_Id__c = '22222222222',
			Lex_Transcript__c = 'Test Lex value',
			Skill__c = 'Payroll Class 3',
			Divrid__c = '12345',
			CIP_Account__c = objAccount.Id,
			Contact__c = objContact.Id
		);

		insert objIVRRoutingLog;

		Case objCase = new Case(Origin = 'Phone', Genesys_Call_Id__c = '1111111111111', SuppliedPhone = '0000000000', ContactId = objContact.Id, AccountId = objAccount.Id, Subject = 'Test IVR');

		insert objCase;

		Test.stopTest();

		Case objQueriedCase = [SELECT Id, AccountId, ContactId, Auth__c, AuthPath__c, IVR_Skill__c, OwnerId, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(CaseUtils.RECTYPE_ENGAGEMENT, objQueriedCase.RecordTypeId, 'Record type not updated to Engagement');
		System.assertEquals(CaseUtils.PAYROLL_CASE_PILLAR, objQueriedCase.Type, 'Type not updated to Payroll');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing if the case record type is updated from IVR Full stack
	 **/
	@isTest
	public static void testIVRFullStack() {
		Test.startTest();

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c, 'Incorect Result');
		String strAllTiers =
			objTierConfig.Old_Tier_1__c +
			';' +
			objTierConfig.Old_Tier_2__c +
			';' +
			objTierConfig.Old_Tier_3__c +
			';' +
			objTierConfig.New_Tier_1__c +
			';' +
			objTierConfig.New_Tier_2__c +
			';' +
			objTierConfig.New_Tier_3__c;

		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		IVR_Routing_Log__c objIVRRoutingLog = new IVR_Routing_Log__c(
			ConversationId__c = '1111111111111',
			CIP_Auth__c = 'Authenticated',
			InQueue_Queue_Name__c = 'Full-Stack Care',
			ZP_User_Id__c = '098765432',
			ANI__c = '0000000000',
			Type__c = 'Inbound Call',
			CIP_Auth_Path__c = 'AuthPath',
			CIP_Company_Id__c = '22222222222',
			Lex_Transcript__c = 'Test Lex value',
			Skill__c = 'Benefits Class 3',
			Divrid__c = '12345',
			CIP_Account__c = objAccount.Id,
			Contact__c = objContact.Id
		);

		insert objIVRRoutingLog;

		Case objCase = new Case(Origin = 'Phone', Genesys_Call_Id__c = '1111111111111', SuppliedPhone = '0000000000', Subject = 'Test IVR');

		insert objCase;
		Test.stopTest();

		Case objQueriedCase = [SELECT Id, AccountId, ContactId, Auth__c, AuthPath__c, IVR_Skill__c, OwnerId, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.RECTYPE_ENGAGEMENT, objQueriedCase.RecordTypeId, 'Record type not updated to Engagement');
		System.assertEquals(CaseUtils.BENEFITS_CASE_PILLAR, objQueriedCase.Type, 'Type not updated to Benefits');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing if the case record type is updated for Modern Bank
	 **/
	@isTest
	public static void testIVRModernBank() {
		Test.startTest();

		// Get org default tier config settings and assert new tier 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Tier_1__c, 'Incorect Result');
		String strAllTiers =
			objTierConfig.Old_Tier_1__c +
			';' +
			objTierConfig.Old_Tier_2__c +
			';' +
			objTierConfig.Old_Tier_3__c +
			';' +
			objTierConfig.New_Tier_1__c +
			';' +
			objTierConfig.New_Tier_2__c +
			';' +
			objTierConfig.New_Tier_3__c;

		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		IVR_Routing_Log__c objIVRRoutingLog = new IVR_Routing_Log__c(
			ConversationId__c = '1111111111111',
			CIP_Auth__c = 'Authenticated',
			InQueue_Queue_Name__c = 'Modern Bank',
			ZP_User_Id__c = '098765432',
			ANI__c = '0000000000',
			Type__c = 'Inbound Call',
			CIP_Auth_Path__c = 'AuthPath',
			CIP_Company_Id__c = '22222222222',
			Lex_Transcript__c = 'Test Lex value',
			Skill__c = 'Modern Bank',
			Divrid__c = '12345',
			CIP_Account__c = objAccount.Id,
			Contact__c = objContact.Id
		);

		insert objIVRRoutingLog;

		Case objCase = new Case(Origin = 'Phone', Genesys_Call_Id__c = '1111111111111', SuppliedPhone = '0000000000', Subject = 'Test IVR');

		insert objCase;
		Test.stopTest();

		Case objQueriedCase = [SELECT Id, AccountId, ContactId, Auth__c, AuthPath__c, IVR_Skill__c, OwnerId, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(Cache.getRecordTypeId('Case', 'Modern Bank'), objQueriedCase.RecordTypeId, 'Incorect Result');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the prepareCaseReasonAutoEmail method logic
	 **/
	@isTest
	public static void testAutoEmail() {
		Test.startTest();

		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];

		Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c(
			Name = 'Test Auto Email',
			Type__c = 'Payroll Care',
			Auto_Email_Behavior__c = 'Send',
			Email_Content__c = 'Hello world',
			Active__c = true
		);
		insert objCaseReasonClassification;

		Case objCase = new Case(Subject = 'Test case auto', AccountId = objAccount.Id, ContactId = objContact.Id, RecordTypeId = CaseUtils.RECTYPE_PAYROLL_CARE);
		insert objCase;

		CaseTriggerHelper.prepareCaseReasonAutoEmail(objCaseReasonClassification, objCase, null, false);
		Test.stopTest();
		System.assertEquals('Send - Manually Routed', objCase.Auto_Email_Behavior__c, 'Incorect Result');
		System.assertEquals(true, objCase.Auto_Response_Email_Content__c.contains('Hello world'), 'Incorect Result');
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the updateOpenBenefitOrderOwnerToCase method logic
	 **/
	@isTest
	public static void testUpdateOpenBenefitOrderOwnerToCase() {
		Test.startTest();
		Benefit_Order__c objBenefitOrder = [SELECT Id, Opportunity__c, OwnerId, Opportunity__r.OwnerId, Order_Status__c FROM Benefit_Order__c WHERE Name = 'New BO Opp'];
		Case objCase = [SELECT Id, Opportunity__c, Benefit_Order__c, Skip_Assignment__c FROM Case WHERE Subject = 'Test Relation' AND RecordType.Name = 'Payroll Care'];

		Set<String> set_OrderStatus = new Set<String>{ 'Not Fulfulled' };
		CaseTriggerHelper objCaseTriggerHelper = new CaseTriggerHelper();
		objCaseTriggerHelper.updateOpenBenefitOrderOwnerToCase(objBenefitOrder, objCase, set_OrderStatus);
		System.assert(objCase.Skip_Assignment__c, 'Incorect Result');
		System.assertEquals(objCase.Benefit_Order__c, objBenefitOrder.Id, 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Testing the mergeDuplicateCases method logic
	 **/
	@isTest
	public static void testMergeDuplicateCases() {
		Case objCase1 = new Case();
		objCase1.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		objCase1.Subject = 'Test';
		objCase1.Description = 'Test';
		objCase1.Origin = 'Email';
		objCase1.SuppliedEmail = 'excludedEmail1@gusto.com';
		insert objCase1;

		Case objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Id = :objCase1.Id];

		Test.startTest();
		Case objCase2 = new Case();
		objCase2.RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
		objCase2.Subject = 'Test';
		objCase2.Description = 'Test';
		objCase2.Origin = 'Email';
		objCase2.SuppliedEmail = 'excludedEmail1@gusto.com';
		insert objCase2;
		Test.stopTest();

		objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Id = :objCase2.Id];
		System.assertEquals('Merged Duplicate', objCaseQueried.Closed_Reason__c, 'Incorect Result');
		System.assertEquals('Closed', objCaseQueried.Status, 'Incorect Result');
	}

	public static List<Case_Merge_Exclusion__mdt> generateMetadata() {
		List<Case_Merge_Exclusion__mdt> list_CaseMergeExclusionMdt = new List<Case_Merge_Exclusion__mdt>();
		Case_Merge_Exclusion__mdt objEmailExclusion = new Case_Merge_Exclusion__mdt();
		objEmailExclusion.Email__c = 'excludedEmail@gusto.com';
		objEmailExclusion.Subject__c = '';
		objEmailExclusion.Is_Active__c = true;
		objEmailExclusion.Matching_Criteria__c = 'Email';

		list_CaseMergeExclusionMdt.add(objEmailExclusion);

		Case_Merge_Exclusion__mdt objEmailSubjectExclusion = new Case_Merge_Exclusion__mdt();
		objEmailSubjectExclusion.Email__c = 'excludedEmailSubject@gusto.com';
		objEmailSubjectExclusion.Subject__c = 'Excluded Subject';
		objEmailSubjectExclusion.Is_Active__c = true;
		objEmailSubjectExclusion.Matching_Criteria__c = 'Email+Subject';

		list_CaseMergeExclusionMdt.add(objEmailSubjectExclusion);

		return list_CaseMergeExclusionMdt;
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check the updation of Opportunity on Case
	 **/
	@isTest
	public static void testUpdateOpenOpportunityOwnerToCase() {
		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		User objUser = new User(
			Alias = 'testU',
			Email = 'objUser@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objTestUser@test.com',
			ProfileId = objProfile.Id
		);
		list_Users.add(objUser);
		insert list_Users;

		Case objCase = [SELECT Id, IsClosed, Status, Opportunity__c, Skip_Assignment__c, OwnerId FROM Case LIMIT 1];
		Opportunity objOpportunity = [SELECT Id, Name, OwnerId FROM opportunity LIMIT 1];
		Map<String, Id> map_Queue = new Map<String, Id>();
		for (Group objGroup : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Renewal Benefits Operations']) {
			map_Queue.put('Renewal Benefits Operations', objGroup.Id);
		}
		Test.startTest();
		CaseTriggerHelper objHelper = new CaseTriggerHelper();
		objHelper.updateOpenOpportunityOwnerToCase(objOpportunity, list_Users[0], objCase, map_Queue, 'Renewal Benefits Operations');
		Case objUpdatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objOpportunity.OwnerId, objUpdatedCase.OwnerId, 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check the logic handleBulkCaseRequiresAction
	 **/
	@isTest
	public static void testHandleBulkCaseRequiresAction() {
		List<Case> list_Cases = [SELECT Id, IsClosed, Status, Requires_Action__c, Opportunity__c, Skip_Assignment__c, OwnerId, Bulk_Migration__c FROM Case];
		Bulk_Migration_Request__c objBulkMigrationRequest = new Bulk_Migration_Request__c(Type__c = 'Bulk Migration', Bulk_Migration_Status__c = 'New');
		Test.startTest();
		insert objBulkMigrationRequest;
		list_Cases[0].Bulk_Migration__c = objBulkMigrationRequest.Id;
		update list_Cases;
		CaseTriggerHelper objHelper = new CaseTriggerHelper();
		objHelper.handleBulkCaseRequiresAction(list_Cases);
		Bulk_Migration_Request__c objUpdatedBMR = [SELECT Id, Requires_Action__c FROM Bulk_Migration_Request__c WHERE Id = :list_Cases[0].Bulk_Migration__c];
		System.assertEquals(list_Cases[0].Requires_Action__c, objUpdatedBMR.Requires_Action__c, 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to check the udpation of Activity field on Lead/Account
	 **/
	@isTest
	public static void testUpdateAccLeadActivityDate() {
		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		User objUser = new User(
			Alias = 'testU',
			Email = 'objUser@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'objTestUser@test.com',
			ProfileId = objProfile.Id,
			UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'sales_sb_ib_xx']
			.Id
		);
		list_Users.add(objUser);
		insert list_Users;

		Test.startTest();
		Lead objLead = [SELECT Id FROM Lead LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact LIMIT 1];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Case objCase = new Case();
		System.runAs(list_Users[0]) {
			objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases');
			objCase.AccountId = objAccount.Id;
			objCase.ContactId = objContact.Id;
			objCase.Lead__c = objLead.Id;
			objCase.Subject = 'Test Relation';
			objCase.Description = 'Test Relation';
			objCase.SuppliedEmail = 'test.contact@gusto.com';
			objCase.Type = 'Sales Chat';
			objCase.Origin = 'Chat';
			objCase.Direction__c = 'Inbound';
			insert objCase;
		}
		objLead = [SELECT Id, Last_Rep_Activity_Date_New__c, Last_Lead_Activity_Date__c FROM Lead WHERE Id = :objCase.Lead__c];
		System.assert(objLead.Last_Rep_Activity_Date_New__c != null, 'Incorect Result');
		System.assert(objLead.Last_Lead_Activity_Date__c != null, 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Ankit CS
	 * @Description : Test method to test reassignment of Case to Care Routing queue if Case Owner is inactive
	 **/
	@isTest
	public static void testUpdateInactiveOwners() {
		Case objCase = [SELECT Id, OwnerId FROM Case WHERE RecordType.Name = 'Modern Bank' LIMIT 1];
		Map<String, User> map_UsersByName = new Map<String, User>();
		Group objCareRoutingQueue = new Group();
		for (User objUser : [SELECT Id, Name FROM User WHERE Name LIKE '%Test%']) {
			map_UsersByName.put(objUser.Name, objUser);
		}

		List<Group> list_Groups = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Modern Bank Routing' LIMIT 1];
		if (list_Groups.isEmpty()) {
			objCareRoutingQueue = new Group(Name = 'Modern Bank Routing', DeveloperName = 'Modern_Bank_Routing', Type = 'Queue');
			insert objCareRoutingQueue;

			QueuesObject objQueue = new QueueSObject(QueueId = objCareRoutingQueue.Id, SobjectType = 'Case');
			insert objQueue;
		} else {
			objCareRoutingQueue = list_Groups[0];
		}

		Test.startTest();

		//Testing when a case is assigned to an inactive user
		objCase.OwnerId = map_UsersByName.get('Test Inactive User').Id;
		update objCase;
		Case objUpdatedCase = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCareRoutingQueue.Id, objUpdatedCase.OwnerId, 'Incorect Result');
		//TODO: @sparyani to update with future change
		Test.stopTest();
	}


	/**
	 * @Author      : Pradeep Chary
	 * @Description : Test method to ByPass Auto close of Risk Assurance Case
	 **/
	@isTest
	static void testBypassUnauthorizedUserAutoCloseQueues() {
		Test.startTest();
		Group objQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Risk_Security_Check' LIMIT 1];

		Case objCase = new Case();
		objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Risk Assurance');
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'Assurance';
		objCase.Origin = 'Email';
		objCase.SuppliedEmail = 'test.test1@gmail.com';
		objCase.OwnerId = objQueue.Id;
		objCase.Status = 'New';
		insert objCase;

		List<Case> list_Cases = [SELECT Authorized_User__c, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('New', list_Cases[0].Status, 'Incorect Result');

		Test.stopTest();
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Assert Tax Ops Case changing owner to a Queue will change the status to New
	 **/
	@isTest
	static void testTaxOpsOwnerChange() {
		List<Case> list_Case = [SELECT Id, Status FROM Case WHERE Subject = 'Test Tax Ops Case'];
		System.assertEquals(CaseUtils.STATUS_IN_PROGRESS, list_Case[0].Status, 'Incorect Result');

		Test.startTest();
		list_Case[0].OwnerId = GlobalQueryHelper.getQueueIdByDevName('TaxOps_Audit_Queue');
		update list_Case[0];
		Test.stopTest();

		List<Case> list_CaseAfter = [SELECT Status FROM Case WHERE Id = :list_Case[0].Id];
		System.assertEquals('New', list_CaseAfter[0].Status, 'Incorect Result');
	}

	/**
	* @Author      : Ankit CS - Bhagat Singh
	* @Description : Test method for assignOwnerToResellerAccountCase() which asserts the owner will not 
					 be modified if the user is inactive. Positive Case
	**/
	@isTest
	static void testAssignOwnerToResellerAccountCase() {
		Test.startTest();

		Map<String, User> map_UsersByName = new Map<String, User>();
		Group objCareRoutingQueue = new Group();
		for (User objUser : [SELECT Id, Name FROM User WHERE Name LIKE '%Test%']) {
			map_UsersByName.put(objUser.Name, objUser);
		}

		Account objResellerAccount = [SELECT Id, (SELECT Id FROM Contacts LIMIT 1) FROM Account WHERE RecordType.Name = 'Reseller' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objResellerAccount.Id)
			.setContactId(objResellerAccount.Contacts[0].Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setType('Payroll Transfer')
			.setSubject('Test Payroll Transfer Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Payroll Transfer Case')
			.build();
		insert objCase;

		//Assigning the case to an active user.
		CaseTriggerHelper.skipTrigger = true;
		objCase.OwnerId = map_UsersByName.get('Test Active User').Id;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		//Creating a case which should be assigned to the active user.
		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objResellerAccount.Id)
			.setContactId(objResellerAccount.Contacts[0].Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setType('Payroll Transfer')
			.setSubject('Test Payroll Transfer Case 3')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('This case will be assigned to active user')
			.build();
		insert objCase3;

		Test.stopTest();

		//Asserting if the case owner is updated with the OwnerId of the latest case.
		objCase3 = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase3.Id];
		System.assertEquals(objCase3.OwnerId, map_UsersByName.get('Test Active User').Id, 'Incorect Result');
	}

	/**
	* @Author      : Ankit CS - Bhagat Singh
	* @Description : Test method for assignOwnerToResellerAccountCase() which asserts the owner will not 
					 be modified if the user is inactive. Negative Case
	**/
	@isTest
	static void testAssignOwnerToResellerAccountCaseNC() {
		Test.startTest();

		Map<String, User> map_UsersByName = new Map<String, User>();
		Group objCareRoutingQueue = new Group();
		for (User objUser : [SELECT Id, Name FROM User WHERE Name LIKE '%Test%']) {
			map_UsersByName.put(objUser.Name, objUser);
		}

		Account objResellerAccount = [SELECT Id, (SELECT Id FROM Contacts LIMIT 1) FROM Account WHERE RecordType.Name = 'Reseller' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objResellerAccount.Id)
			.setContactId(objResellerAccount.Contacts[0].Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setType('Payroll Transfer')
			.setSubject('Test Payroll Transfer Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Payroll Transfer Case')
			.build();
		insert objCase;

		//Assigning the case to an inactive user.
		CaseTriggerHelper.skipTrigger = true;
		objCase.OwnerId = map_UsersByName.get('Test Inactive User').Id;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		//Creating a case which should not be assigned to the inactive user.
		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objResellerAccount.Id)
			.setContactId(objResellerAccount.Contacts[0].Id)
			.setRecordTypeId('Payroll Transfer Case')
			.setType('Payroll Transfer')
			.setSubject('Test Payroll Transfer Case 2')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('This case will not be assigned to inactive user')
			.build();
		insert objCase2;

		Test.stopTest();

		//Asserting if the case is not assigned to the inactive user.
		objCase2 = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase2.Id];
		System.assertNotEquals(objCase2.OwnerId, map_UsersByName.get('Test Inactive User').Id, 'Incorect Result');
	}

	private static void skipTriggers(Boolean blnFlag) {
		HIGroupEventTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTaskCreation = blnFlag;
		UserTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		AccountRelatedTrackingTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		CaseAuditLogTriggerHelper.skipTrigger = blnFlag;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Tests if send survey gets updated when case reason classification changes
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testCaseSendSurvey() {
		skipTriggers(true);

		Case_Reason_Classification__c objTRCUCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Client Unresponsive')
			.setIsActive(true)
			.setClass('')
			.setType('Tax Res')
			.build();
		objTRCUCaseReason.Survey_Eligible__c = false;
		insert objTRCUCaseReason;

		Case_Reason_Classification__c objTRSNCaseReason = new TestDataFactory.CaseReasonClassificationBuilder().setName('State Notice').setIsActive(true).setClass('').setType('Tax Res').build();
		objTRCUCaseReason.Survey_Eligible__c = true;
		objTRSNCaseReason.Reason_Code__c = 'state_notice_tr';
		insert objTRSNCaseReason;

		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Test Builder').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@firstcontact.com')
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('RE: Amended W-2 for 2019 needed')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Amended W-2 for 2019 needed')
			.build();
		objCase.Confirm_Case_Reason_Classification__c = objTRSNCaseReason.Id;
		insert objCase;

		skipTriggers(false);

		Test.startTest();
		List<Case> list_CasesToUpdate = [SELECT Confirm_Case_Reason_Classification__c, Send_Survey__c FROM Case WHERE Subject = 'RE: Amended W-2 for 2019 needed'];

		list_CasesToUpdate.get(0).Confirm_Case_Reason_Classification__c = objTRCUCaseReason.Id;
		update list_CasesToUpdate;
		Test.stopTest();

		List<Case> list_QuriedCases = [SELECT Confirm_Case_Reason_Classification__c, Send_Survey__c FROM Case WHERE Subject = 'RE: Amended W-2 for 2019 needed'];
		System.assertEquals(false, list_QuriedCases[0].Send_Survey__c, 'Incorect Result');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Set TaxRes Case Status Based On Agency - Positive Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testCaseStatusBasedOnAgency() {
		Test.startTest();
		Agency_Information__c objAgency = TestDataFactory.CreateOneAgencyInforation('Social Security Administration');

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Tax Res')
			.setDescription('Tax Res')
			.setOrigin('Email')
			.setStatus('Ready for Data Capture')
			.setSuppliedEmail('test.test1@gmail.com')
			.setEmailStatus('Open')
			.build();
		insert objCase;

		objCase.Agency_Information__c = objAgency.Id;
		update objCase;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Authorized_User__c, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals('Ready for Data Capture', list_Cases[0].Status, 'Incorect Result');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Set TaxRes Case Status Based On Agency - Negative Case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testCaseStatusBasedOnAgencyNegativeCase() {
		Test.startTest();
		Agency_Information__c objAgency = TestDataFactory.CreateOneAgencyInforation('Federal Unemployment');

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Tax Res')
			.setDescription('Tax Res')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test.test1@gmail.com')
			.setEmailStatus('Open')
			.build();
		insert objCase;

		objCase.Agency_Information__c = objAgency.Id;
		update objCase;

		Test.stopTest();

		List<Case> list_Cases = [SELECT Authorized_User__c, Status FROM Case WHERE Id = :objCase.Id];
		System.assert('Ready for Research' != list_Cases[0].Status, 'Incorect Result');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation for "createTaxResAuditLogs" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testCreateTaxResAuditLogsPositive() {
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		Case objCase = new Case();

		Test.startTest();
		CaseTriggerHelper.SkipTrigger = false;
		objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Tax Res')
			.setDescription('Tax Res')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test.test1@gmail.com')
			.setEmailStatus('Open')
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objCase;
		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLog = [SELECT Id, Event_Type__c FROM Case_Audit_Log__c WHERE Case__c = :objCase.Id];
		System.assert(list_CaseAuditLog.size() > 0, 'List cannot be empty');
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : validation negative scenario for "createTaxResAuditLogs" method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testCreateTaxResAuditLogsNegative() {
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 1];
		Case objCase;

		Test.startTest();
		objCase = TestDataFactory.createTestCase(list_Accounts[0].Id, list_Contacts[0].Id);
		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLog = [SELECT Id, Event_Type__c FROM Case_Audit_Log__c WHERE Case__c = :objCase.Id AND Event_Type__c = :CaseUtils.EMAIL_STATUS_CHANGE];
		System.assert(list_CaseAuditLog.size() == 0, 'List cannot be empty');
	}

	/**
	 * @Author		: Alex Xiong
	 * @Description	: confirm a case reason with incorrect capitalization finds the
	 * 				  correct case reason classification and fixes the capitalization
	 */
	@isTest
	static void testCaseReasonCapitalization() {
		Test.startTest();

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('cap test case')
			.setDescription('Tax Res')
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test.test1@gmail.com')
			.setRoutingCaseReason('clienT unresponsivE')
			.setConfirmCaseReason('clieNt uNresponsive')
			.build();
		insert objCase;

		Test.stopTest();

		Case objCaseQueried = [SELECT Routing_Case_Reason__c, Confirm_Case_Reason__c FROM Case WHERE Subject = 'cap test case'];
		System.assertEquals('Client Unresponsive', objCaseQueried.Routing_Case_Reason__c, 'Incorect Result');
		System.assertEquals('Client Unresponsive', objCaseQueried.Confirm_Case_Reason__c, 'Incorect Result');
	}

	/**
	 * @Author		: Alex Xiong
	 * @Description	: test updateContactPhoneDetails() to make sure metadata records can block saving to Contacts
	 */
	@isTest
	static void testUpdateContactPhoneDetails() {
		Test.startTest();
		Contact objContact = [
			SELECT Id, Phone, MobilePhone, OtherPhone, ZP_Phone__c, Normalized_Mobile_Phone__c, Normalized_Other_Phone__c, Normalized_Phone__c, Additional_Phone_Numbers__c
			FROM Contact
			WHERE Email = 'test.contact@gusto.com'
		];
		CaseTriggerHelper objHelper = new CaseTriggerHelper();
		objHelper.updateContactPhoneDetails(objContact, '4159077030');

		System.assertNotEquals('4159077030', objContact.Phone, 'Incorect Result');
		System.assertNotEquals('4159077030', objContact.MobilePhone, 'Incorect Result');
		System.assertNotEquals('4159077030', objContact.OtherPhone, 'Incorect Result');
		System.assertNotEquals('4159077030', objContact.ZP_Phone__c, 'Incorect Result');

		objHelper.updateContactPhoneDetails(objContact, '1111111111');
		System.assertEquals('1111111111', objContact.MobilePhone, 'Incorect Result');

		objHelper.updateContactPhoneDetails(objContact, '1111111112');
		System.assertEquals('1111111112', objContact.OtherPhone, 'Incorect Result');

		objHelper.updateContactPhoneDetails(objContact, '1111111113');
		System.assertEquals('1111111113', objContact.ZP_Phone__c, 'Incorect Result');

		objHelper.updateContactPhoneDetails(objContact, '1111111114');
		System.assertEquals('1111111114', objContact.Additional_Phone_Numbers__c, 'Incorect Result');

		objHelper.updateContactPhoneDetails(objContact, '1111111115');
		System.assert(objContact.Additional_Phone_Numbers__c.contains('1111111115'), 'Incorect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Testing the spam and duplicate subject cases positive scenario
	 */
	@isTest
	public static void testSpamAndDuplicateSubjectOnCasePartialMatch() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setType('Sales')
			.setSubject(strTestSubject + ' 1234 has been assigned to you')
			.setOrigin('Payroll Care Email')
			.setStatus('New')
			.setDescription(strTestSubject)
			.build();

		Test.startTest();
		try {
			insert objCase1;
		} catch (Exception ex) {
			System.debug('# Ex - ' + ex.getMessage());
		}
		Test.stopTest();

		List<Case> list_TestCase = [SELECT Status, RecordType.DeveloperName, OwnerId FROM Case WHERE Id = :objCase1.Id LIMIT 1];
		List<Group> list_Queue = [SELECT Id, Name FROM Group WHERE Id = :list_TestCase[0].OwnerId LIMIT 1];
		System.assertEquals(list_TestCase[0].Status, 'Closed', 'Incorect Result');
		System.assertEquals(list_TestCase[0].RecordType.DeveloperName, 'Tax_Res_Read_Only', 'Incorect Result');
		System.assertEquals(list_Queue[0].Name, 'Tax Res - Auto Close', 'Incorect Result');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Testing the spam and duplicate subject cases negative scenario
	 */
	@isTest
	public static void testSpamAndDuplicateSubjectOnCaseNoPartialMatch() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setType('Sales')
			.setSubject(strTestSubject + ' is assigned to you')
			.setOrigin('Payroll Care Email')
			.setStatus('New')
			.setDescription(strTestSubject)
			.build();

		Test.startTest();
		try {
			insert objCase1;
		} catch (Exception ex) {
			System.debug('# Ex - ' + ex.getMessage());
		}
		Test.stopTest();

		List<Case> list_TestCase = [SELECT Status, RecordType.DeveloperName, Owner.Name FROM Case WHERE Id = :objCase1.Id LIMIT 1];
		System.assertNotEquals(list_TestCase[0].Status, 'Closed', 'Incorect Result');
		System.assertNotEquals(list_TestCase[0].RecordType.DeveloperName, 'Tax_Res_Read_Only', 'Incorect Result');
		System.assertNotEquals(list_TestCase[0].Owner.Name, 'Tax Res - Auto Close', 'Incorect Result');
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Testing if OCR cases are going to OCR Capture Queue
	 */
	@isTest
	public static void testOCRCases() {
		// Create Agnecy for Tax Res Case
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('CA-EDD');
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCAEDDCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setSubject(strTestSubject + ' for CA-EDD')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE)
			.setDescription(strTestSubject)
			.setAgencyInformation(objAgency.Id)
			.build();

		Test.startTest();
		try {
			insert objCAEDDCase;
		} catch (Exception ex) {
			System.debug('# Ex - ' + ex.getMessage());
		}
		Test.stopTest();

		List<Case> list_TestCase = [SELECT Status, Type, Owner.Name FROM Case WHERE Id = :objCAEDDCase.Id LIMIT 1];
		System.assertEquals(list_TestCase[0].Status, CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE, 'The case is moved to OCR status correctly.');
		System.assertEquals(list_TestCase[0].Type, CaseUtils.TYPE_TAX_RES, 'The Type is correctly updated.');
	}

	/**
	 * @Author      : Lalitha Kasturi
	 * @Description : Testing the mergeDuplicateCases method logic including cc, to and from emails
	 */
	@isTest
	public static void testMergeDuplicateCasesWithCcAndToEmails() {
		Case objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Subject = 'Test Duplicate Case' LIMIT 1];

		Test.startTest();
		List<Case> list_BulkifiedDuplicateCases = new List<Case>();

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Re: Test Duplicate Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('alextest@acme.com')
			.setDescription('Test Duplicate Case')
			.build();

		objCase2.CCEmailAddress__c = 'seantest@acme.com;lalithatest@acme.com';
		objCase2.To_Email_Address__c = 'support@gusto.com';
		list_BulkifiedDuplicateCases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Re: Test Duplicate Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('seantest@acme.com')
			.setDescription('Test Duplicate Case')
			.build();

		objCase3.CCEmailAddress__c = 'alextest@acme.com;lalithatest@acme.com';
		objCase3.To_Email_Address__c = 'support@gusto.com';
		list_BulkifiedDuplicateCases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Re: Test Duplicate Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('newusertest@acme.com')
			.setDescription('Test Duplicate Case')
			.build();

		objCase4.CCEmailAddress__c = 'alextest@acme.com;seantest@acme.com;lalithatest@acme.com';
		objCase4.To_Email_Address__c = 'support@gusto.com';
		list_BulkifiedDuplicateCases.add(objCase4);

		insert list_BulkifiedDuplicateCases;
		Test.stopTest();

		List<Case> list_MergedCases = [SELECT Id, Status, Closed_Reason__c FROM Case WHERE ParentId = :objCaseQueried.Id];

		System.assertEquals(2, list_MergedCases.size(), 'Incorect Result');
		System.assertEquals('Merged Duplicate', list_MergedCases[0].Closed_Reason__c, 'Incorect Closed Reason');
		System.assertEquals('Closed', list_MergedCases[0].Status, 'Status has to be closed');
	}

	/**
	 * @Author      : Lalitha Kasturi
	 * @Description : Testing the mergeDuplicateCases method logic including cc, to and from emails to SKIP the match for invalid use case
	 **/
	@isTest
	public static void testMergeDuplicateCasesWithCcAndToEmails_NegativeTestCase() {
		Case objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Subject = 'Test Duplicate Case' LIMIT 1];

		Test.startTest();
		List<Case> list_BulkifiedDuplicateCases = new List<Case>();
		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Re: Test Duplicate Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('newusertest@acme.com')
			.setDescription('Test Duplicate Case')
			.build();
		objCase4.CCEmailAddress__c = 'alextest@acme.com;seantest@acme.com;lalithatest@acme.com';
		objCase4.To_Email_Address__c = 'support@gusto.com';
		list_BulkifiedDuplicateCases.add(objCase4);

		insert list_BulkifiedDuplicateCases;
		Test.stopTest();
		List<Case> list_MergedCases = [SELECT Id FROM Case WHERE ParentId = :objCaseQueried.Id];

		System.assertEquals(0, list_MergedCases.size(), 'List cannot be empty');
	}

	/**
	 * @Author		: Lalitha Kasturi
	 * @Description	: If Confirm Case Reason is Blank for Phone Origin and Case Owner is Phone Routing,
	 *                then populate Confirm Case Reason with No action required
	 */
	@isTest
	static void testConfirmCaseReasonOnPhoneRoutingCase() {
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setSubject('ConfirmationReasonCode test case')
			.setDescription('ConfirmationReasonCode test case')
			.setOrigin('Phone')
			.setStatus('New')
			.build();
		insert objCase;

		Id idRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Payroll Care - Read Only').getRecordTypeId();
		Group objPhoneRoutingQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Payroll_Care_Non_Actionable' AND Type = 'Queue' LIMIT 1];

		Test.startTest();
		objCase.OwnerId = objPhoneRoutingQueue.Id;
		objCase.Status = 'Closed';
		objCase.RecordTypeId = idRecordType;
		update objCase;
		Test.stopTest();

		Case_Reason_Classification__c objCaseReasonClassification = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'No Action Required' LIMIT 1];
		Case objCaseQueried = [SELECT Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c FROM Case WHERE Id = :objCase.Id];

		System.assertEquals('No Action Required', objCaseQueried.Confirm_Case_Reason__c, 'Incorect Result');
		System.assertEquals(objCaseQueried.Confirm_Case_Reason_Classification__c, objCaseReasonClassification.Id, 'Incorect Result');
	}

	/**
	 * @Author		: Lalitha Kasturi
	 * @Description	: If Confirm Case Reason is Blank for Phone Origin and Case Owner is Payroll-Care Non-actionable,
	 *                then populate Confirm Case Reason with No action required
	 */
	@isTest
	static void testConfirmCaseReasonOnPayrollCaseNonActionableCase() {
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care')
			.setSubject('ConfirmationReasonCode test case')
			.setDescription('ConfirmationReasonCode test case')
			.setOrigin('Phone')
			.setStatus('New')
			.build();
		insert objCase;

		Id idRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Payroll Care - Read Only').getRecordTypeId();
		Group objPayrollCareQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Phone_Routing' AND Type = 'Queue' LIMIT 1];

		Test.startTest();
		objCase.OwnerId = objPayrollCareQueue.Id;
		objCase.Status = 'Closed';
		objCase.RecordTypeId = idRecordType;
		update objCase;
		Test.stopTest();

		Case_Reason_Classification__c objCaseReasonClassification = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'No Action Required' LIMIT 1];
		Case objCaseQueried = [SELECT Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c FROM Case WHERE Id = :objCase.Id];

		System.assertEquals('No Action Required', objCaseQueried.Confirm_Case_Reason__c, 'Incorect Result');
		System.assertEquals(objCaseQueried.Confirm_Case_Reason_Classification__c, objCaseReasonClassification.Id, 'Incorect Result');
	}

	/**
	 * @author Alex Xiong
	 * @description test original case reference formula and assert the new formula is the same
	 */
	@isTest
	static void testCaseReferenceFormula() {
		Test.startTest();
		list<Case> list_Cases = [SELECT Id, Case_Reference__c FROM Case];

		for (Case objCase : list_Cases) {
			List<Messaging.RenderEmailTemplateBodyResult> list_Render = Messaging.renderEmailTemplate(null, objCase.Id, new List<String>{ objCase.Case_Reference__c });
			System.assertEquals(list_Render[0].getMergedBody(), objCase.Case_Reference__c, 'Incorect Result');
		}

		Test.stopTest();
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for check Require Action for BO and Case.
	 * @param        N/A
	 * @return       N/A
	 **/
	@isTest
	static void testBORequireAction() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Requires_Action__c FROM Benefit_Order__c WHERE Name = 'New BO Opp01' LIMIT 1];
		objBO.Requires_Action__c = false;
		update objBO;
		Case objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Subject = 'Test Require Action' LIMIT 1];

		objCaseQueried.Requires_Action__c = true;
		update objCaseQueried;

		Case objCase = [SELECT Id, Requires_Action__c FROM Case WHERE Id = :objCaseQueried.Id];

		Benefit_Order__c objBO1 = [SELECT Id, Name, Requires_Action__c FROM Benefit_Order__c WHERE Name = 'New BO Opp01' LIMIT 1];
		Test.stopTest();
		System.assertEquals(objCase.Requires_Action__c, objBO1.Requires_Action__c, 'Incorect Result');
	}

	/**
	 * @author       Deepika Saini
	 * @description  Test method for check Require Action for BO and Case.
	 * @param        N/A
	 * @return       N/A
	 **/
	@isTest
	static void testBYBRequireAction() {
		Test.startTest();
		Benefit_Order__c objBO = [SELECT Id, Name, Requires_Action__c FROM Benefit_Order__c WHERE Name = 'New BO Opp01' LIMIT 1];
		objBO.Requires_Action__c = true;
		update objBO;
		Case objCaseQueried = [SELECT Id, Status, RecordType.Name, Closed_Reason__c FROM Case WHERE Subject = 'Test Require Action 1' LIMIT 1];
		objCaseQueried.Benefit_Order__c = objBO.Id;
		objCaseQueried.Requires_Action__c = true;
		update objCaseQueried;

		Case objCase = [SELECT Id, Requires_Action__c FROM Case WHERE Id = :objCaseQueried.Id];

		Test.stopTest();
		System.assertEquals(objCase.Requires_Action__c, objBO.Requires_Action__c, 'Incorect Result');
	}

	/**
	 * @author       Pravesh Rana
	 * @description  Test method to validate Specialist assignment logic
	 * @param        N/A
	 * @return       N/A
	 **/
	@isTest
	static void testSpecialistCaseAssignment() {
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();
		Role__c objRole = TestDataFactory.CreateRole('Account Specialist');
		Region_POD__c objRegionPOD = TestDataFactory.CreateAgencyRegion('Test Notice Region', 'Account Specialist');
		List<Region_POD_mapping__c> list_RegionPODMappings = TestDataFactory.CreateAgencyRegionPODMapping(objRegionPOD, list_AgencyInformations);

		User_Role__c objSpecialistRole = TestDataFactory.CreateUserRole('Account Specialist');
		List<Skill__c> list_Skills = TestDataFactory.CreateSkill(objRole, list_RegionPODMappings);
		List<User_Skill__c> list_UserSkills = TestDataFactory.CreateUserSkill(objSpecialistRole, list_Skills);

		Account objAccount = TestDataFactory.CompanyAccount();
		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);
		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);

		Test.startTest();
		objCase.Status = 'Ready for Research';
		objCase.Agency_Information__c = list_AgencyInformations[0].Id;
		update objCase;
		Test.stopTest();

		List<Case> list_cases = [SELECT Id, OwnerId, Account_Specialist__c FROM Case];
		System.assert(String.valueOf(list_cases[0].OwnerId).startsWith('005'), 'Incorect Result');
	}

	/* @author       Ankit
	 * @description  Test method to validate that a case cannot be solved if there's a
	 * 				 case escalation record with no root cause
	 **/
	@isTest
	static void testCaseEscalationWithoutRootCasue() {
		Case objCase = [SELECT Id, Status FROM Case WHERE Subject = 'Case to be solved with an escalation'];
		objCase.Status = 'Solved';
		objCase.Confirm_Case_Reason__c = 'Add or Edit Beneficiary';
		objCase.Audience__c = 'Employee';
		Test.startTest();
		try {
			update objCase;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CaseTriggerHelperTest', 'testCaseEscalationWithoutRootCasue', objException.getMessage(), objException.getStackTraceString());
		}
		Test.stopTest();

		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		// Assert that the case was not solved
		System.assertNotEquals('Solved', objCase.Status, 'Incorrect Result');
	}

	/**
	 * @author       David (Dato) Tsamalashvili
	 * @description  Test method to validate SMS Record creation for survey
	 **/
	@isTest
	static void testCaseSMSSurvay() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE Email = 'test.contact@gusto.com'];

		ContactTriggerHelper.skipTrigger = true;
		objContact.Last_Login_Date_Time__c = System.today();
		objContact.Survey_Opt_Out__c = false;

		update objContact;
		ContactTriggerHelper.skipTrigger = false;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setSuppliedPhone(objContact.Phone)
			.setSubject('Test SMS Survey Records')
			.setOrigin('Phone')
			.setStatus('New')
			.setSuppliedEmail('test21@gusto.com')
			.setDescription('Test SMS Survey')
			.setSendSurvey(true)
			.setSkipSurvey(false)
			.setSurveySent(false)
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();

		try {
			objCase.Status = CaseUtils.STATUS_SOLVED;
			objCase.Date_Time_Solved__c = System.now().date().addDays(1);
			objCase.Confirm_Case_Reason__c = '1099 Adjustment';
			objCase.Audience__c = 'Employee';
			objCase.Send_Survey__c = true;

			update objCase;
		} catch (Exception objException) {
		}

		Test.stopTest();

		List<SMS__c> list_SMS = [SELECT Id FROM SMS__c WHERE Case__c = :objCase.Id];
		System.assertEquals(1, list_SMS.size(), 'Incorrect Result');
	}

	/**
	 * @author       Ela Nagarathinam
	 * @description  Test method to validate SMS Record creation for GEP CX record type
	 **/
	@isTest
	static void testCaseSMSSurvayForGEPCX() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test.contact@gusto.com'];

		ContactTriggerHelper.skipTrigger = true;
		objContact.Last_Login_Date_Time__c = System.today();
		objContact.Survey_Opt_Out__c = false;

		update objContact;
		ContactTriggerHelper.skipTrigger = false;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('GEP CX')
			.setSuppliedPhone('111-222-7656')
			.setSubject('Test SMS Survey Records')
			.setOrigin('Phone')
			.setStatus('New')
			.setSuppliedEmail('test21@gusto.com')
			.setDescription('Test SMS Survey')
			.setSendSurvey(true)
			.setSkipSurvey(false)
			.setSurveySent(false)
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();

		try {
			objCase.Status = CaseUtils.STATUS_SOLVED;
			objCase.Date_Time_Solved__c = System.now().date().addDays(1);
			objCase.Confirm_Case_Reason__c = '1099 Adjustment';
			objCase.Audience__c = 'Employee';
			objCase.Send_Survey__c = true;

			update objCase;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CaseTriggerHelperTest', 'testCaseSMSSurvayForGEPCX', objException.getMessage(), objException.getStackTraceString());
		}

		update objCase;

		Test.stopTest();

		List<SMS__c> list_SMS = [SELECT Id FROM SMS__c WHERE Case__c = :objCase.Id];
		System.assertEquals(1, list_SMS.size(), 'Incorrect Result');
	}

	/**
	 * @author       Atul Hinge
	 * @description  Test method to validate Partner Account population on Record creation for GEP CX record type
	 **/
	@isTest
	static void testCaseUpdatePartnerAccountForGEPCX() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST RESELLER ACCOUNT' LIMIT 1];
		objAccount.Type = AccountUtil.EMBEDDED_COMPANY_TYPE;
		update objAccount;
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test.contact.@gusto.com.reseller'];
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('GEP CX')
			.setSuppliedPhone('111-222-7656')
			.setSubject('Test UpdatePartnerAccount Record')
			.setOrigin('Phone')
			.setStatus('New')
			.setSuppliedEmail('test21@gusto.com')
			.setDescription('Test SMS Survey')
			.build();

		insert objCase;
		Case updatedCase = [SELECT Id, Partner_Account__c FROM Case WHERE id = :objCase.Id];
		System.assertEquals(updatedCase.Partner_Account__c, objAccount.Id, 'Incorrect Result');
		updatedCase.Partner_Account__c=null;
		update updatedCase;
		updatedCase = [SELECT Id, Partner_Account__c FROM Case WHERE id = :objCase.Id];
		System.assertEquals(updatedCase.Partner_Account__c, objAccount.Id, 'Incorrect Result');
		Test.stopTest();
	}

	/**
	 * @author       Atul Hinge
	 * @description  Test method to validate Partner Account population on Record creation for GEP CX record type
	 **/
	@isTest
	static void testAutoCloseGEPCXLeakageCases() {
		Account objAccount = [SELECT Id, Name FROM Account WHERE Name = 'TEST RESELLER ACCOUNT' LIMIT 1];
		Account objAccount1 = [SELECT Id, Name FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		objAccount.Type = AccountUtil.EMBEDDED_COMPANY_TYPE;
		objAccount.RecordTypeId = AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID;
		objAccount.Sold_By__c = objAccount1.Id;
		update objAccount;
		GEPPartnerDetails__c partnerDetails = new GEPPartnerDetails__c();
		partnerDetails.Name = objAccount1.Name;
		partnerDetails.Partner_Name__c = objAccount1.Name;
		partnerDetails.PartnerPhoneNumber__c = '111';
		partnerDetails.PartnerSupportEmailAddress__c = 'abc@xyz.com';
		partnerDetails.Account_Id__c = objAccount1.Id;
		insert partnerDetails;

		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test.contact.@gusto.com.reseller'];
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSuppliedPhone('111-222-7656')
			.setSubject('Test UpdatePartnerAccount Record')
			.setRecordTypeId('Engagement')
			.setOrigin('Phone')
			.setStatus('New')
			.setSuppliedEmail('test21@gusto.com')
			.setDescription('Test SMS Survey')
			.build();

		insert objCase;
		Case updatedCase = [SELECT Id, Partner_Account__c, Status FROM Case WHERE id = :objCase.Id];
		System.assertEquals(updatedCase.Status, 'Closed', 'Incorrect Result');
		Test.stopTest();
	}

	/**
	 * @Author      : Todd Dowdy
	 * @Description : Testing Date/Time Solve and Time to Resolution on Case
	 **/
	@isTest
	static void testCaseDateTimeSolved() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE Email = 'test.contact@gusto.com'];

		ContactTriggerHelper.skipTrigger = true;
		objContact.Last_Login_Date_Time__c = System.today();
		objContact.Survey_Opt_Out__c = false;

		update objContact;
		ContactTriggerHelper.skipTrigger = false;

		Case objPRCCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setOwnerId(UserInfo.getUserId())
			.setRecordTypeId('Payroll Care')
			.setSubject('Test Payroll Care Case Date/Time Solve Logic')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('Open')
			.setSuppliedEmail('test21@gusto.com')
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objPRCCase;
		CaseTriggerHelper.skipTrigger = false;

		System.assertEquals(objPRCCase.Date_Time_Solved__c, null, 'Incorrect Result');

		Test.startTest();

		try {
			objPRCCase.Status = CaseUtils.STATUS_SOLVED;
			update objPRCCase;
		} catch (Exception objException) {
			System.debug(objException);
		}

		Test.stopTest();

		List<Case> list_CaseDateTimeSolveCheck = [SELECT Id, Date_Time_Solved__c, Time_To_Resolution_Hours__c, Status FROM Case WHERE Id = :objPRCCase.Id];

		System.assertNotEquals(list_CaseDateTimeSolveCheck.size(), 0, 'List should not be empty');
		System.assertNotEquals(list_CaseDateTimeSolveCheck[0].Date_Time_Solved__c, null, 'List should not be empty');
		System.assertNotEquals(list_CaseDateTimeSolveCheck[0].Time_To_Resolution_Hours__c, null, 'List should not be empty');
	}

	/* @author       Swati Arya
	 * @description  Test method to validate that a case is auto Closed with
	 * 				  Your one-time passcode to view the message subject for BYB Cases
	 **/
	@isTest
	static void testCaseAutoCloseOneTimePasscodeBYBCasesOnInsert() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId('Benefits BYB')
			.setSubject(CaseUtils.ONE_TIME_PASSCODE_SUBJECT)
			.setStatus('New')
			.setSuppliedEmail('test@test.com')
			.setDescription(CaseUtils.ONE_TIME_PASSCODE_SUBJECT + 'Test Description')
			.build();

		Test.startTest();
		insert objCase;
		Test.stopTest();

		Case objCaseAssert = [SELECT Id, Status, Status_Detail__c FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(CaseUtils.STATUS_CLOSED, objCaseAssert.Status, 'Status Should be set to Closed');
		System.assertEquals(CaseUtils.INACTIONABLE_REQ_STATUS_DETAIL, objCaseAssert.Status_Detail__c, 'Status Details should be set to Inactionable request');
	}

	/**
	 * @author Alex Xiong
	 * @description assert GEP CX gets auto solve/close date
	 */
	@isTest
	static void testGEPCXAutoSolveAndCloseTime() {
		Test.startTest();
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('GEP CX')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setSubject('GEP CX Case 1')
			.setStatus('New')
			.setSuppliedEmail('test@test.com')
			.build();

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('GEP CX')
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setSubject('GEP CX Case 2')
			.setStatus('New')
			.setSuppliedEmail('test@test.com')
			.build();

		List<Case> list_Case = new List<Case>{ objCase1, objCase2 };
		insert list_Case;
		Test.stopTest();

		objCase1.Status = 'Awaiting Response';
		objCase2.Status = 'Solved';
		update list_Case;

		List<Case> list_CaseQueried = [SELECT Id, Subject, Auto_Solve_Date_Time__c, Auto_Close_Date_Time__c FROM Case WHERE Subject LIKE 'GEP CX Case%'];
		for (Case objCase : list_CaseQueried) {
			if (objCase.Subject == 'GEP CX Case 1') {
				System.assertNotEquals(null, objCase.Auto_Solve_Date_Time__c, 'Incorrect Result');
			} else {
				System.assertNotEquals(null, objCase.Auto_Close_Date_Time__c, 'Incorrect Result');
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @description assert setSubCaseReasonId() will clear Sub Case Reason when a case's record type is changed
	 */
	@isTest
	static void testSetSubCaseReasonId() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c, Confirm_Sub_Case_Reason__c, Confirm_Sub_Case_Reason_Classification__c
			FROM Case
			WHERE Subject = 'Payroll Care Case'
		];
		List<Case_Reason_Classification__c> list_CaseReasons = [SELECT Id, Name, Type__c FROM Case_Reason_Classification__c WHERE Type__c = 'Tax Res' AND Name = 'Client Unresponsive'];
		List<Sub_Case_Reason_Classification__c> list_SubCaseReasons = [SELECT Id, Name FROM Sub_Case_Reason_Classification__c];
		RecordType objTaxRes = [SELECT Id FROM RecordType WHERE DeveloperName = 'Tax_Res' AND SObjectType = 'Case'];

		objCase.RecordTypeId = objTaxRes.Id;
		update objCase;
		Test.stopTest();

		Case objCaseQueried = [
			SELECT Id, Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c, Confirm_Sub_Case_Reason__c, Confirm_Sub_Case_Reason_Classification__c
			FROM Case
			WHERE Subject = 'Payroll Care Case'
		];
		System.assert(objCaseQueried.Confirm_Sub_Case_Reason__c == null, 'Incorrect Result');
	}

	/**
	 * @author Alex Xiong
	 * @description assert setSubCaseReasonId() will not clear Sub Case Reason when a case's record type is changed and Status is not solved/closed
	 */
	@isTest
	static void testSetSubCaseReasonIdKeepSubCaseReason() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c, Confirm_Sub_Case_Reason__c, Confirm_Sub_Case_Reason_Classification__c
			FROM Case
			WHERE Subject = 'Payroll Care Case'
		];
		List<Case_Reason_Classification__c> list_CaseReasons = [SELECT Id, Name, Type__c FROM Case_Reason_Classification__c WHERE Type__c = 'Tax Res' AND Name = 'Client Unresponsive'];
		List<Sub_Case_Reason_Classification__c> list_SubCaseReasons = [SELECT Id, Name FROM Sub_Case_Reason_Classification__c];
		RecordType objTaxRes = [SELECT Id FROM RecordType WHERE DeveloperName = 'Tax_Res' AND SObjectType = 'Case'];

		objCase.RecordTypeId = objTaxRes.Id;
		objCase.Status = 'Solved';
		update objCase;
		Test.stopTest();

		Case objCaseQueried = [
			SELECT Id, Confirm_Case_Reason__c, Confirm_Case_Reason_Classification__c, Confirm_Sub_Case_Reason__c, Confirm_Sub_Case_Reason_Classification__c
			FROM Case
			WHERE Subject = 'Payroll Care Case'
		];
		System.assert(objCaseQueried.Confirm_Sub_Case_Reason__c != null, 'Incorrect Result');
	}

	/**
	 * @author Alex Xiong
	 * @description assert createSMSRecords() creates a SMS record when Contact is updated to have a phone number from a Case
	 */
	@isTest
	static void testCreateSMSRecordsAfterContactUpdate() {
		Test.startTest();
		List<Contact> list_Contact = [SELECT Id, Phone, MobilePhone FROM Contact WHERE Email = 'test.contact@gusto.com'];
		List<Case> list_Case = [SELECT Id, SuppliedPhone FROM Case WHERE ContactId = :list_Contact[0].Id AND Origin = 'Phone' AND SuppliedPhone = '0987654321'];
		System.assertEquals(null, list_Contact[0].MobilePhone, 'Incorrect Result');

		list_Case[0].Status = 'Solved';
		list_Case[0].Confirm_Case_Reason__c = '1099 Adjustment';
		update list_Case;
		Test.stopTest();

		List<Contact> list_ContactQueried = [SELECT Id, Phone, MobilePhone FROM Contact WHERE Email = 'test.contact@gusto.com'];
		List<SMS__c> list_SMS = [SELECT Id FROM SMS__c WHERE Case__c = :list_Case[0].Id];
		List<Exception_Log__c> list_Logs = [SELECT Id FROM Exception_Log__c];
		list_Case = [SELECT Id, Survey_Sent_Date_Time__c FROM Case WHERE Id IN :list_Case];

		System.assertNotEquals(null, list_ContactQueried[0].MobilePhone, 'Incorrect Result');
		System.assertNotEquals(0, list_SMS.size(), 'List should not be empty');
		System.assertEquals(0, list_Logs.size(), 'List should not be empty');
		System.assertNotEquals(null, list_Case[0].Survey_Sent_Date_Time__c, 'List should not be empty');
	}

	/**
	 * @author Alex Xiong
	 * @description assert createSMSRecords() creates a SMS record when Contact already has a phone number from a Case
	 */
	@isTest
	static void testCreateSMSRecords() {
		Test.startTest();
		List<Contact> list_Contact = [SELECT Id, Phone, MobilePhone FROM Contact WHERE Email = 'test.contact@gusto.com'];
		List<Case> list_Case = [SELECT Id, SuppliedPhone FROM Case WHERE ContactId = :list_Contact[0].Id AND Origin = 'Phone' AND SuppliedPhone = '1234567890'];

		list_Case[0].Status = 'Solved';
		list_Case[0].Confirm_Case_Reason__c = '1099 Adjustment';
		update list_Case;
		Test.stopTest();

		List<Contact> list_ContactQueried = [SELECT Id, Phone, MobilePhone FROM Contact WHERE Email = 'test.contact@gusto.com'];
		List<SMS__c> list_SMS = [SELECT Id FROM SMS__c WHERE Case__c = :list_Case[0].Id];
		List<Exception_Log__c> list_Logs = [SELECT Id FROM Exception_Log__c];
		list_Case = [SELECT Id, Survey_Sent_Date_Time__c FROM Case WHERE Id IN :list_Case];

		System.assertNotEquals(0, list_SMS.size(), 'List cannot be empty');
		System.assertEquals(0, list_Logs.size(), 'List cannot be empty');
		System.assertNotEquals(null, list_Case[0].Survey_Sent_Date_Time__c, 'List cannot be empty');
	}

	/**
	 * @author       Elavarasan N
	 * @description  Test method for check the population of the TFIR and TRES based on 24/7 instead of business hours
	 **/
	@isTest
	static void testTFIRandTRES() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id, First_Response_Time__c, Time_To_First_Response_Hours__c, Date_Time_Solved__c, Time_To_Resolution_Hours__c, CreatedDate FROM Case];
		System.assertEquals(null, list_Cases[0].Time_To_First_Response_Hours__c, 'List should not be empty');
		System.assertEquals(null, list_Cases[0].Time_To_Resolution_Hours__c, 'List should not be empty');

		list_Cases[0].First_Response_Time__c = list_Cases[0].CreatedDate.addDays(1);
		list_Cases[0].Date_Time_Solved__c = list_Cases[0].CreatedDate.addDays(2);
		update list_Cases[0];
		Test.stopTest();

		Case objCaseRecord = [SELECT Id, First_Response_Time__c, Time_To_First_Response_Hours__c, Date_Time_Solved__c, Time_To_Resolution_Hours__c, CreatedDate FROM Case WHERE Id = :list_Cases[0].Id];
		System.assertEquals(24, objCaseRecord.Time_To_First_Response_Hours__c, 'List should not be empty');
		System.assertEquals(48, objCaseRecord.Time_To_Resolution_Hours__c, 'List should not be empty');
	}

	/**
	 * @author       Ankit C
	 * @description  Test method for setAutomatedEmailSent()
	 **/
	@isTest
	static void testSetAutomatedEmailSent() {
		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('testAgencyInformation')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized@gmail.com')
			.setDescription('Testing Tax Res Unauthorized User')
			.setAuthorizedUser('No')
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setSubject('Testing Modern Bank Unauthorized User')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized2@gmail.com')
			.setDescription('Testing Modern Bank Unauthorized User')
			.setAuthorizedUser('No')
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setSubject('Testing Benefits Care Unauthorized User')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized3@gmail.com')
			.setDescription('Testing Benefits Care Unauthorized User')
			.setAuthorizedUser('No')
			.build();
		list_Cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Testing Payroll Care Authorized User')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testauthorized@gusto.com')
			.setDescription('Testing Payroll Care Authorized User')
			.build();
		list_Cases.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Modern Bank')
			.setType('Savings')
			.setSubject('Testing Modern Bank Savings Type')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testauthorized2@gusto.com')
			.setDescription('Testing Modern Bank Savings Type')
			.build();
		list_Cases.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setSubject('Testing Modern Bank Authorized User')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testauthorized3@gusto.com')
			.setDescription('Testing Modern Bank Authorized User')
			.build();
		list_Cases.add(objCase6);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setSubject('Testing Benefits Care Authorized User')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testauthorized4@gusto.com')
			.setDescription('Testing Benefits Care Authorized User')
			.build();
		list_Cases.add(objCase7);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care')
			.setType('Cobra')
			.setSubject('Testing Cobra')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testauthorized5@gusto.com')
			.setDescription('Testing Cobra')
			.build();
		list_Cases.add(objCase8);

		Test.startTest();
		insert list_Cases;
		Test.stopTest();
		Map<Id, Case> map_CaseById = new Map<Id, Case>([SELECT Id, Automated_Email_Sent__c FROM Case WHERE Id IN :list_Cases]);
		System.assertEquals('Payroll Care NOT Authorized', map_CaseById.get(objCase.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Modern Bank NOT Authorized', map_CaseById.get(objCase2.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Ben Care NOT Authorized', map_CaseById.get(objCase3.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Engagement Case Acknowledgement', map_CaseById.get(objCase4.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Modern Bank Savings', map_CaseById.get(objCase5.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Modern bank Ack', map_CaseById.get(objCase6.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('Engagement Case Acknowledgement', map_CaseById.get(objCase7.Id).Automated_Email_Sent__c, 'Incorrect Result');
		System.assertEquals('COBRA Case Acknowledgement', map_CaseById.get(objCase8.Id).Automated_Email_Sent__c, 'Incorrect Result');
	}

	/**
	 * @author       Pradeep Chary
	 * @description  Test method for updateCaseOwnerInformation()
	 **/
	@isTest
	static void testUpdateCaseOwnerInformation() {
		User objUserOwner = [SELECT Id FROM User WHERE Username = 'testactiveuser2@gusto.com'];

		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setSubject('Testing Benefits Care Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testbenefitscarecase@gmail.com')
			.setDescription('Testing Benefits Care Case')
			.setAuthorizedUser('Yes')
			.setOwnerId(objUserOwner.Id)
			.build();
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Testing Payroll Care Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testpayrollcarecase@gusto.com')
			.setDescription('Testing Payroll Care Case')
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase2);
		insert list_Cases;

		Test.startTest();
		List<Case> list_Case = [SELECT Id, Case_Owner_Role__c FROM Case WHERE SuppliedEmail = 'testbenefitscarecase@gmail.com'];
		System.assertEquals('Core & Complete', list_Case[0].Case_Owner_Role__c, 'A case created by a user should have Case Owner Role');

		User objUser = [SELECT Id, Class_Queue__c, Benefits_Class__c, Secondary_Role__c FROM User WHERE Username = 'testactiveuser@gusto.com'];

		list_Cases = new List<Case>();
		objCase.OwnerId = objUser.Id;
		objCase2.OwnerId = objUser.Id;

		list_Cases.add(objCase);
		list_Cases.add(objCase2);

		System.runAs(objUserOwner) {
			update list_Cases;
		}

		Test.stopTest();

		Map<Id, Case> map_CaseById = new Map<Id, Case>([SELECT Id, Owner_Class__c, Benefits_Owner_Class__c, Case_Owner_Role__c, Status FROM Case WHERE Id IN :list_Cases]);

		System.assertEquals(objUser.Class_Queue__c, map_CaseById.get(objCase2.Id).Owner_Class__c, 'Incorrect Result');
		System.assertEquals(objUser.Benefits_Class__c, map_CaseById.get(objCase.Id).Benefits_Owner_Class__c, 'Incorrect Result');
		System.assertEquals(objUser.Secondary_Role__c, map_CaseById.get(objCase2.Id).Case_Owner_Role__c, 'Incorrect Case Owner Role');
		System.assertEquals(CaseUtils.STATUS_OPEN, map_CaseById.get(objCase2.Id).Status, 'Incorrect Status');
		System.assertEquals(CaseUtils.STATUS_OPEN, map_CaseById.get(objCase.Id).Status, 'Incorrect Status');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  Test method for Automation Status Changed as Completed
	 **/
	@isTest
	static void testAutomationStatusAsCompleted() {
		Utils.skipTrigger(true);
		State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('3').setAbbreviation('CA').build();
		objState.Key__c = 'CA';
		insert objState;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName(CaseUtils.CARRIER_FLORIDA_BLUE)
			.setUniqueName(CaseUtils.CARRIER_FLORIDA_BLUE)
			.setState('CA')
			.setCarrierId('112')
			.setTerminationEffectiveDate('End of Month')
			.build();
		insert objCarrier;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('MF Member/Group Updates')
			.setSubject('Test MF/Group Updates')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testunauthorized@gmail.com')
			.setDescription('Test MF/Group Updates')
			.build();
		insert objCase;
		Utils.skipTrigger(false);
		Test.startTest();

		CaseTriggerHelper.blnFormAutomationBatch = true;
		objCase.Automation_Message__c = CaseUtils.STR_EMAIL_SENT_TO_CARRIER;
		objCase.Automation_Status__c = CaseUtils.STATUS_COMPLETED;
		objCase.Submission_Method__c = 'Carrier Portal';
		update objCase;

		CaseTriggerHelper.blnFormAutomationBatch = false;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id LIMIT 1];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MF_FOLLOWUP), objCase.OwnerId, 'Case Owner can not be change as MF Followup');
		System.assertEquals(CaseUtils.STATUS_SUBMITTED, objCase.Status, 'Case Status can not be change as Submitted');
	}

	/**
	 * @author Alex Xiong
	 * @description test logic from Auto Close Cases moved to before insert
	 */
	@isTest
	static void testAutoCloseCasesWFRule() {
		Test.startTest();
		List<Case> list_Case = new List<Case>();
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Change Case')
			.setSubject(CaseUtils.GUARDIAN_BIZ_SUBJECT)
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail(CaseUtils.NO_REPLY_GLIC)
			.setDescription('test auto close')
			.build();
		list_Case.add(objCase1);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Renewal Case')
			.setSubject(CaseUtils.AUTO_RESPONDER_SUBJECT)
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testemail@gusto.com')
			.setDescription('test auto close')
			.build();
		list_Case.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Benefits Change Case')
			.setSubject(CaseUtils.THANK_YOU_SUBJECT)
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail(CaseUtils.SBS_HUMANA)
			.setDescription('test auto close')
			.build();
		list_Case.add(objCase3);
		insert list_Case;
		Test.stopTest();

		List<Case> list_CaseQueried = [SELECT Id, Subject, Status FROM Case WHERE Subject IN (:CaseUtils.GUARDIAN_BIZ_SUBJECT, :CaseUtils.AUTO_RESPONDER_SUBJECT, :CaseUtils.THANK_YOU_SUBJECT)];

		for (Case objCase : list_CaseQueried) {
			System.assertEquals('Closed', objCase.Status, 'Incorrect Status');
		}
	}

	/**
	 * @author Alex Xiong
	 * @description test auto solve and auto close date time logic
	 */
	@isTest
	static void autoSolveDateTime() {
		List<Account> list_Account = [SELECT Id FROM Account];
		List<Contact> list_Contact = [SELECT Id FROM Contact];

		Case objAutoCloseDateCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Payroll Care clear auto close date')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gustotest.com')
			.setDescription('Test Payroll Care')
			.setAutoCloseDateTime(System.now().addDays(5))
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objAutoCloseDateCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Subject = 'Payroll Care Case' OR Subject = 'Payroll Care clear auto close date'];
		List<Id> list_CaseIds = new List<Id>();

		for (Case objCase : list_Case) {
			objCase.Status = 'Awaiting Response';
			list_CaseIds.add(objCase.Id);
		}

		update list_Case;
		Test.stopTest();

		List<Case> list_CaseAfter = [SELECT Id, Auto_Solve_Date_Time__c, Auto_Close_Date_Time__c FROM Case WHERE Id IN :list_CaseIds];
		for (Case objCase : list_CaseAfter) {
			System.assertEquals(null, objCase.Auto_Solve_Date_Time__c, 'Payroll Care cases should have an auto solve date time');
			System.assertNotEquals(null, objCase.Auto_Close_Date_Time__c, 'Payroll Care cases should get their auto close date time cleared when set to Awaiting Response');
		}
	}

	/**
	 * @author Alex Xiong
	 * @description test auto solve and auto close date time logic
	 */
	@isTest
	static void autoCloseDateTime() {
		Test.startTest();
		BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
		List<Case> list_Case = [SELECT Id, Status, BusinessHoursId FROM Case WHERE Subject = 'Payroll Care Case' LIMIT 1];
		list_Case[0].Status = 'Awaiting Response';
		list_Case[0].BusinessHoursId = objBusinessHours.Id;
		update list_Case[0];
		Test.stopTest();

		List<Case> list_CaseAfter = [SELECT Id, Auto_Close_Date_Time__c FROM Case WHERE Id = :list_Case[0].Id];
		System.assertNotEquals(null, list_CaseAfter[0].Auto_Close_Date_Time__c, 'Payroll Care case should have an auto close date time');
	}

	/**
	 * @author Alex Xiong
	 * @description Modern Bank should not have auto solve date time
	 */
	@isTest
	static void modernBankAutoSolveDateTime() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objMBCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setSubject('Test Modern Bank Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gustotest.com')
			.setDescription('Test Modern Bank Case')
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objMBCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		List<Case> list_MBCase = [SELECT Id FROM Case WHERE Id = :objMBCase.Id];
		list_MBCase[0].Status = 'Awaiting Response';
		update list_MBCase;
		Test.stopTest();

		List<Case> list_MBCaseAfter = [SELECT Id, Auto_Solve_Date_Time__c FROM Case WHERE Id = :objMBCase.Id];
		System.assertEquals(null, list_MBCaseAfter[0].Auto_Solve_Date_Time__c, 'Modern Bank Cases should not have auto solve date time');
	}

	/**
	 * @author Alex Xiong
	 * @description Modern Bank should not have auto solve date time
	 */
	@isTest
	static void modernBankAutoCloseDateTime() {
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objMBCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setSubject('Test Modern Bank Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gustotest.com')
			.setDescription('Test Modern Bank Case')
			.build();

		CaseTriggerHelper.skipTrigger = true;
		insert objMBCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		List<Case> list_MBCase = [SELECT Id FROM Case WHERE Id = :objMBCase.Id];
		list_MBCase[0].Confirm_Case_Reason__c = 'Modern Bank Test';
		list_MBCase[0].Status = 'Solved';
		list_MBCase[0].Complaint_Type__c = 'No Complaint';
		list_MBCase[0].Complaint_Method__c = 'No Complaint';
		list_MBCase[0].Product__c = 'Cashout';
		update list_MBCase;
		Test.stopTest();

		List<Case> list_MBCaseAfter = [SELECT Id, Auto_Solve_Date_Time__c FROM Case WHERE Id = :objMBCase.Id];
		System.assertEquals(null, list_MBCaseAfter[0].Auto_Solve_Date_Time__c, 'Modern Bank Cases should not have auto close date time');
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description Test for Payroll care case auto close
	 */
	@isTest
	static void testPayrollCareCaseAutoClose() {
		List<Case> list_Cases = [SELECT Id, Class__c, Status, OwnerId FROM Case WHERE RecordType.Name = 'Payroll Care' AND Class__c != 'Class 0' LIMIT 1];

		Test.startTest();
		if (list_Cases != null && list_Cases.isEmpty()) {
			list_Cases[0].Class__c = 'Class 0';
			update list_Cases[0];

			Case objCase = [SELECT Id, Class__c, Status, OwnerId, RecordType.Name, Owner.Name FROM Case WHERE ID = :list_Cases[0].Id];
			System.assertEquals('Closed', objCase.Status, 'Status is Invalid');
			System.assertEquals('Payroll Care - Read Only', objCase.RecordType.Name, 'Record Type is Invalid');
			System.assertEquals('Payroll Care - Auto Close', map_Queues.get(objCase.OwnerId).Name, 'Owner is Invalid');
		}
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test delete case
	 */
	@isTest
	static void assertDelete() {
		Test.startTest();
		blnRunCatchTest = true;
		EmailToCaseTest.blnTestRealLife = true;
		List<Case> list_Case = [SELECT Id FROM Case LIMIT 1];

		try {
			delete list_Case;
		} catch (Exception ex) {
			List<Case> list_CaseAfter = [SELECT Id FROM Case WHERE Id = :list_Case[0].Id];
			System.assertEquals(false, list_CaseAfter.isEmpty(), 'Cases are not allowed to be deleted');
		}
		EmailToCaseTest.blnTestRealLife = false;
		blnRunCatchTest = false;
	}

	/**
	 * @author Alex Xiong
	 * @description make sure Recent Queue Id and Recent Queue Name are updated
	 */
	@isTest
	static void recentQueueTest() {
		List<Group> list_PhoneRoutingQueue = GlobalQueryHelper.getGroupsByName('Phone_Routing');
		List<Group> list_CareRoutingQueue = GlobalQueryHelper.getGroupsByName('Care_Routing');
		Test.startTest();
		List<Account> list_Account = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contact = [SELECT Id FROM Contact LIMIT 1];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Account[0].Id)
			.setContactId(list_Contact[0].Id)
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setOrigin(CaseUtils.ORIGIN_PHONE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setSubject('recentQueueTest')
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Phone case')
			.setOwnerId(list_PhoneRoutingQueue[0].Id)
			.build();

		insert objCase;
		List<Case> list_Case = [SELECT Recent_Queue_Id__c, Recent_Queue_Name__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(list_PhoneRoutingQueue[0].Id, list_Case[0].Recent_Queue_Id__c, 'Recent Queue Id should have been populated on insert');
		System.assertEquals(list_PhoneRoutingQueue[0].Name, list_Case[0].Recent_Queue_Name__c, 'Recent Queue Name should have been populated on insert');

		Test.stopTest();

		list_Case[0].OwnerId = list_CareRoutingQueue[0].Id;
		update list_Case;

		List<Case> list_CaseAfter = [SELECT Recent_Queue_Id__c, Recent_Queue_Name__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(list_CareRoutingQueue[0].Name, list_CaseAfter[0].Recent_Queue_Name__c, 'Recent Queue Name should have been changed');
		System.assertEquals(list_CareRoutingQueue[0].Id, list_CaseAfter[0].Recent_Queue_Id__c, 'Recent Queue Id should have been changed');
	}

	/**
	 * @author Alex Xiong
	 * @description make sure Answer IQ Eligible is set to true
	 */
	@isTest
	static void assertAnswerIQ() {
		List<Case> list_InsertCase = new List<Case>();

		Case objPayrollCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Answer IQ PRC')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test.contact@gusto.com')
			.setDescription('Testing PRC')
			.setAuthorizedUser('Yes')
			.build();
		list_InsertCase.add(objPayrollCase);

		Case objTaxCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Answer IQ Tax Res')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test.contact@gusto.com')
			.setDescription('Testing Tax Res')
			.setAuthorizedUser('Yes')
			.build();
		list_InsertCase.add(objTaxCase);

		insert list_InsertCase;

		Test.startTest();

		List<Case> list_Case = [SELECT Id, Subject, Answer_IQ_Eligible__c FROM Case WHERE Subject LIKE 'Answer IQ%'];

		for (Case objCase : list_Case) {
			System.assert(objCase.Answer_IQ_Eligible__c, 'Payroll Care and Tax Res should have Answer IQ Eligible = true');
		}
	}

	/**
	 * @author Alex Xiong
	 * @description assert Tax Res Cases get TaxRes_OBMsg_Trigger__c set to true from updateTaxResOBMessageTrigger()
	 */
	@isTest
	static void assertUpdateTaxResOBMessageTriggerTrue() {
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('TaxRes_OBMsg_Trigger__c true')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test.contact@gmail.com')
			.setDescription('Testing TaxRes_OBMsg_Trigger__c')
			.setAuthorizedUser('Yes')
			.setAnswerIQProcessed('Yes')
			.build();

		CaseTriggerHelper.updateTaxResOBMessageTrigger(objCase);
		System.assert(objCase.TaxRes_OBMsg_Trigger__c, 'Tax Res Case should have gotten TaxRes_OBMsg_Trigger__c set to true');

		objCase.Subject = 'lorem' + CaseUtils.list_TaxResOBMsgTriggerSubjects[CaseUtils.list_TaxResOBMsgTriggerSubjects.size() - 1] + 'ipsum';
		objCase.TaxRes_OBMsg_Trigger__c = false;

		CaseTriggerHelper.updateTaxResOBMessageTrigger(objCase);
		System.assertEquals(false, objCase.TaxRes_OBMsg_Trigger__c, 'Tax Res Case should have kept TaxRes_OBMsg_Trigger__c false');

		Test.stopTest();
	}

	/**
	 * @author        Pradeep Chary
	 * @description   WFRule Migration, Vitals Expedite Case to Priority High
	 **/
	@isTest
	static void testVitalsExpediteCase() {
		Test.startTest();

		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		List<Contact> list_Contacts = [SELECT Id FROM Contact LIMIT 1];

		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setContactId(list_Contacts[0].Id)
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_COMPLIANCE)
			.setType(CaseUtils.TYPE_PAYROLL_COMPLIANCE_INQUIRY)
			.setSubject('Testing Payroll Compliance Inquiry expedite Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection(CaseUtils.STR_INBOUND)
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('testbenefitscarecase@gmail.com')
			.setDescription('Testing Payroll Compliance Inquiry Case')
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase);

		insert list_Cases;
		Test.stopTest();

		Map<Id, Case> map_CaseById = new Map<Id, Case>([SELECT Id, Priority FROM Case WHERE Id IN :list_Cases]);
		System.assertEquals(CaseUtils.PRIORITY_HIGH, map_CaseById.get(objCase.Id).Priority, 'Case Priority needs to be High');
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description test case for the logics on workflow rule Update First Response Start Time <30
	 */
	@isTest
	static void testMFUpdateFirstResponseStartTime() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Carrier__c objCarrier = TestUtility.Carrier();

		List<Case> list_Cases = new List<Case>();
		Case objCaseAudit = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.REC_TYPE_STR_MF_AUDIT)
			.setType(CaseUtils.TYPE_NHE)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_DRAFT)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Default Submission & Follow up Method')
			.setAnticipatedEffectiveDate(System.today())
			.build();
		list_Cases.add(objCaseAudit);

		Case objCaseTermination = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.REC_TYPE_STR_MF_TERMINATION)
			.setType(CaseUtils.TYPE_TERMINATION)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_DRAFT)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Default Submission & Follow up Method')
			.setAnticipatedEffectiveDate(System.today())
			.build();
		list_Cases.add(objCaseTermination);

		Case objCaseMemberUpdates = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.REC_TYPE_STR_MF_MEMBER_GROUP_UPDATES)
			.setType(CaseUtils.TYPE_MEMBER_UPDATES)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_DRAFT)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Default Submission & Follow up Method')
			.setAnticipatedEffectiveDate(System.today() + 60)
			.build();
		list_Cases.add(objCaseMemberUpdates);

		insert list_Cases;

		for (Case objCase : [SELECT Id, OwnerId, Owner.Name, Type, Status, First_Response_Start_Time__c, RecordTypeId FROM Case WHERE Id IN :list_Cases]) {
			// Field update not available for MF Audit record type
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_AUDIT) {
				System.assertEquals(objCase.Status, CaseUtils.STATUS_DRAFT, 'Status should not be updated');
				System.assertEquals(objCase.First_Response_Start_Time__c, null, 'First Response Start Time should not be updated');
			}

			// Field update available for MF Termination record type and all criteria met
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_TERMINATION) {
				System.assertEquals(objCase.Status, CaseUtils.STATUS_NEW, 'Status not updated correctly');
				System.assertEquals(objCase.First_Response_Start_Time__c.date(), System.today(), 'First Response Start Time not updated correctly');
			}

			// Field update available for MF Termination record type and all criteria not met
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES) {
				//System.assertEquals(objCase.Status, CaseUtils.STATUS_DRAFT, 'Status should not be updated');
				//System.assertEquals(objCase.First_Response_Start_Time__c, null, 'First Response Start Time should not be updated');
			}
		}
		Test.stopTest();
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description test case Owner update for Benefits New Plan cases
	 */
	@isTest
	static void testBenefitsNewPlanOwnerUpdate() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Carrier__c objCarrier = TestUtility.Carrier();
		Profile objProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Benefits Care'];
		List<Group> list_groups = [SELECT Id, Name FROM Group WHERE DeveloperName = 'New_Plan_Benefits_Operations'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('benefitsuser' + DateTime.now().getTime() + '@testorg.com')
			.setFirstName('BenefitsUsers')
			.setLastName('Test Active User 2')
			.setEmail('testactiveuser2@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test2')
			.setIsActive(true)
			.build();
		insert objUser;

		List<Case> list_Cases = new List<Case>();
		Case objCaseBenefitsNewPlan = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.REC_TYPE_STR_BENEFITS_NEW_PLAN)
			.setType(CaseUtils.TYPE_BENEFITS_NEW_PLAN)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setOwnerId(objUser.Id)
			.setStatus(CaseUtils.STATUS_DRAFT)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Positive')
			.build();
		list_Cases.add(objCaseBenefitsNewPlan);

		Case objCaseBenefitsNewPlanNeg = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.REC_TYPE_STR_BENEFITS_NEW_PLAN)
			.setType(CaseUtils.TYPE_TERMINATION)
			.setSubject('Test User Role Changes')
			.setOwnerId(objUser.Id)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.TYPE_BENEFITS_NEW_PLAN)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Negative')
			.setHistoricalData('Zendesk')
			.build();
		list_Cases.add(objCaseBenefitsNewPlanNeg);
		insert list_Cases;

		for (Case objCase : [SELECT Id, OwnerId, Description, RecordTypeId FROM Case WHERE Id IN :list_Cases]) {
			// Field update happened as conditions not met
			if (objCase.Description == 'Positive') {
				System.assertEquals(list_groups[0].Id, objCase.OwnerId, 'Owner not updated');
			}

			// Field update not happened as conditions not met
			if (objCase.Description == 'Negative') {
				System.assertEquals(objCaseBenefitsNewPlanNeg.OwnerId, objCase.OwnerId, 'Owner is updated wrongly');
			}
		}
		Test.stopTest();
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description update the owner to Risk Unauthorized queue
	 */
	@isTest
	static void testUpdateOwnerToRiskUnAuthorized() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Carrier__c objCarrier = TestUtility.Carrier();
		Profile objProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Benefits Care'];
		List<Group> list_groups = [SELECT Id, Name FROM Group WHERE DeveloperName = 'Risk_Unauthorized_Queue'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('benefitsuser' + DateTime.now().getTime() + '@testorg.com')
			.setFirstName('')
			.setLastName('System')
			.setEmail('testactiveuser2@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test2')
			.setIsActive(true)
			.build();
		insert objUser;

		List<Case> list_Cases = new List<Case>();
		Case objCaseRiskAssurance = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.TYPE_RISK_ASSURANCE)
			.setType(CaseUtils.TYPE_ASSURANCE)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setOwnerId(objUser.Id)
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Positive')
			.build();
		list_Cases.add(objCaseRiskAssurance);

		Case objCaseRiskAssuranceNeg = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.TYPE_RISK_ASSURANCE)
			.setType(CaseUtils.TYPE_ASSURANCE)
			.setSubject('Test User Role Changes')
			.setOwnerId(objUser.Id)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_DRAFT)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Negative')
			.build();
		list_Cases.add(objCaseRiskAssuranceNeg);
		insert list_Cases;

		for (Case objCase : [SELECT Id, OwnerId, Description, RecordTypeId FROM Case WHERE Id IN :list_Cases]) {
			// Field update happened as conditions not met
			if (objCase.Description == 'Positive') {
				System.assertEquals(list_groups[0].Id, objCase.OwnerId, 'Owner not updated');
			}

			// Field update not happened as conditions not met
			if (objCase.Description == 'Negative') {
				System.assertEquals(objCaseRiskAssuranceNeg.OwnerId, objCase.OwnerId, 'Owner is updated wrongly');
			}
		}
		Test.stopTest();
	}

	/**
	 * @author Ankit C
	 * @description Test case status update on owner change.
	 */
	@isTest
	static void testTaxOpsCaseOwnerChange() {
		Database.DMLOptions objDMLOptions = new Database.DMLOptions();
		objDMLOptions.assignmentRuleHeader.useDefaultRule = true;
		User objUser = [SELECT Id FROM User WHERE Username = 'testactiveuser@gusto.com'];
		Contact objContact = [SELECT Id, AccountId FROM Contact LIMIT 1];
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objContact.AccountId)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_TAX_OPS)
			.setType(CaseUtils.TYPE_COMPLIANCE)
			.setSubject('Test Tax Ops Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection(CaseUtils.DIRECTION_INBOUND)
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('test@taxopstest.com')
			.setDescription('Test tax ops Case')
			.build();
		objCase.setOptions(objDMLOptions);
		Test.startTest();
		insert objCase;
		objCase = [SELECT Id, Status FROM Case WHERE Id = :objCase.Id];
		//Assert to check if case is created with status as New
		System.assertEquals(CaseUtils.STATUS_NEW, objCase.Status, 'Incorrect Status');

		//Changing the owner
		objCase.OwnerId = objUser.Id;
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, OwnerId, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUser.Id, objCase.OwnerId, 'Incorrect Result');
		//Assert to check if case status was updated to Open
		System.assertEquals(CaseUtils.STATUS_OPEN, objCase.Status, 'Incorrect Status');
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description update the auto close date time for solved risk assurance case
	 */
	@isTest
	static void testUpdateAutoCloseDateRiskAssurance() {
		Test.startTest();
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		Profile objProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Benefits Care'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('benefitsuser' + DateTime.now().getTime() + '@testorg.com')
			.setFirstName('')
			.setLastName('System')
			.setEmail('testactiveuser2@gusto.com')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test2')
			.setIsActive(true)
			.build();
		insert objUser;

		List<Case> list_Cases = new List<Case>();
		Case objCaseRiskAssurance = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.TYPE_RISK_ASSURANCE)
			.setType(CaseUtils.TYPE_ASSURANCE)
			.setSubject('Test User Role Changes')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setOwnerId(objUser.Id)
			.setStatus(CaseUtils.STATUS_SOLVED)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Case Insert Test')
			.build();
		list_Cases.add(objCaseRiskAssurance);

		Case objCaseRiskAssuranceNeg = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setRecordTypeId(CaseUtils.TYPE_RISK_ASSURANCE)
			.setType(CaseUtils.TYPE_ASSURANCE)
			.setSubject('Test User Role Changes')
			.setOwnerId(objUser.Id)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setStatus(CaseUtils.STATUS_OPEN)
			.setSuppliedEmail('test1@gusto.com')
			.setDescription('Case Update Test')
			.build();
		list_Cases.add(objCaseRiskAssuranceNeg);
		System.runAs(objUser) {
			insert list_Cases;
		}

		for (Case objCase : [SELECT Id, OwnerId, Description, RecordTypeId, Auto_Close_Date_Time__c FROM Case WHERE Id IN :list_Cases]) {
			// Field update happened as conditions not met
			if (objCase.Description == 'Case Insert Test') {
				System.assertEquals(System.today() + 2, objCase.Auto_Close_Date_Time__c.date(), 'Auto close date is not updated');
			}

			// Field update not happened as conditions not met
			if (objCase.Description == 'Case Update Test') {
				System.assertEquals(null, objCase.Auto_Close_Date_Time__c, 'Auto close date should not be updated');
			}
		}

		list_Cases[1].Status = CaseUtils.STATUS_SOLVED;
		System.runAs(objUser) {
			update list_Cases[1];
		}

		List<Case> list_UpdatedCases = [SELECT Id, OwnerId, Description, RecordTypeId, Auto_Close_Date_Time__c FROM Case WHERE Id = :list_Cases[1].Id];
		System.assertEquals(System.today() + 2, list_UpdatedCases[0].Auto_Close_Date_Time__c.date(), 'Auto close date is not updated');

		Test.stopTest();
	}

	/**
	 * @author        Pradeep Chary
	 * @description   testing Mineral trust incoming cases are not getting auto-closed
	 **/
	@isTest
	static void testMineralTrustCase() {
		Test.startTest();

		List<Case> list_Cases = new List<Case>();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setSubject('Testing Mineral trust follow-up Case')
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.setDirection(CaseUtils.STR_INBOUND)
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('testbenefitscarecase@trustmineral.com')
			.setDescription('Testing Mineral trust follow-up Case')
			.setAuthorizedUser('Yes')
			.build();
		list_Cases.add(objCase);

		insert list_Cases;
		Test.stopTest();

		Map<Id, Case> map_CaseById = new Map<Id, Case>([SELECT Id, Status FROM Case WHERE Id IN :list_Cases]);
		System.assertEquals(CaseUtils.STATUS_NEW, map_CaseById.get(objCase.Id).Status, 'Case should not Auto-Close');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Assign Cases to Sales Cases - WFR migration
	 **/
	@isTest
	static void testStampSalesCasesChangesInsert() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE Email = 'test.contact@gusto.com'];

		Group objSalesCaseQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Sales_Case_Queue' AND Type = 'Queue' LIMIT 1];

		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Sales')
			.setSubject('Test Stamp Sales Cases Changes Insert')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('swatiarya@acme.com')
			.setDescription('Test Stamp Sales Cases Changes Insert')
			.setOwnerId(objSalesCaseQueue.Id)
			.build();
		insert objCase;

		Test.stopTest();

		objCase = [SELECT Id, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.RECTYPE_SALES_CASES, objCase.RecordTypeId, 'Case Record Type should be set to Sales Cases');
		System.assertEquals(CaseUtils.TYPE_SALES_EMAIL, objCase.Type, 'Case Type should be set to Sales Email');
	}

	/**
	 * @author       Swati Arya
	 * @description  Test Assign Cases to Sales Cases - WFR migration
	 **/
	@isTest
	static void testStampSalesCasesChangesUpdate() {
		Account objAccount = [SELECT Id FROM Account WHERE Name = 'TEST ACCOUNT' LIMIT 1];
		Contact objContact = [SELECT Id, Phone FROM Contact WHERE Email = 'test.contact@gusto.com'];

		Group objSalesCaseQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Sales_Case_Queue' AND Type = 'Queue' LIMIT 1];

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits BYB')
			.setType('BYOB')
			.setSubject('Test Stamp Sales Cases Changes Update')
			.setStatus('New')
			.setSuppliedEmail('swatiarya@acme.com')
			.setDescription('Test Stamp Sales Cases Changes Update')
			.build();

		Test.startTest();
		insert objCase;

		objCase = [SELECT Id, OwnerId, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(UserInfo.getUserId(), objCase.OwnerId, 'Case owner should be set to logged in user');

		objCase.OwnerId = objSalesCaseQueue.Id;
		update objCase;

		Test.stopTest();
		objCase = [SELECT Id, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];

		System.assertEquals(CaseUtils.RECTYPE_SALES_CASES, objCase.RecordTypeId, 'Case Record Type should be set to Sales Cases');
		System.assertEquals(CaseUtils.TYPE_SALES_EMAIL, objCase.Type, 'Case Type should be set to Sales Email');
	}

	/**
	 * @author       Deepika Saini
	 * @description  This methos is used to test the updation of ticket.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void testTicketUpdateionRecertStatus() {
		Test.startTest();
		Case objCase = [SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c FROM Case WHERE RecordType.Name = 'Benefits Renewal Case' LIMIT 1];

		CasetriggerHelper.skipTrigger = true;
		objCase.Automated_RFI_Flow__c = true;
		update objCase;
		CasetriggerHelper.skipTrigger = false;

		TicketTriggerHelper.skipTrigger = true;
		Ticket__c objTicket = new TestDataFactory.TicketBuilder()
			.setCaseId(objCase.Id)
			.setEscalationReason(TicketUtil.TICKET_REASON_RECERTIFICATION)
			.setOppId(objCase.Opportunity__c)
			.setAccountId(objCase.AccountId)
			.setRecordTypeId(TicketUtil.ADVISING_FULFILLMENT_TICKET_RT_ID)
			.setOwnerId(UserInfo.getUserId())
			.build();
		insert objTicket;
		TicketTriggerHelper.skipTrigger = false;

		objCase = [SELECT Id, Automated_RFI_Flow__c FROM Case WHERE Id = :objCase.Id];
		objCase.Automated_RFI_Flow__c = false;
		update objCase;

		Test.stopTest();

		objTicket = [SELECT Id, Recert_Status__c FROM Ticket__c WHERE Id = :objTicket.Id LIMIT 1];
		System.assertEquals(TicketUtil.RECERT_STATUS_ADVISOR_ACTION_NEEDED, objTicket.Recert_Status__c, 'Ticket Recert status is not changed.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test Automation Status as Failed For NHE Cases : Positive Case
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void automationStatusFailedForNHECases() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		objCase.Automation_Status__c = CaseUtils.STATUS_FAILED;
		update objCase;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MEMBER_FULFILLMENT), objCase.OwnerId, 'Case Owner can not be change as Member Fulfillment');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test Automation Status as Failed For NHE Cases : Negative Case
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void automationStatusFailedForNHECasesNeg() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		objCase.Missing_Form_Attributes__c = 'Test';
		objCase.Automation_Status__c = CaseUtils.STATUS_FAILED;
		update objCase;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MEMBER_FULFILLMENT), objCase.OwnerId, 'Case Owner can not be change as Member Fulfillment');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test Automation Status as Completed For NHE Cases : Positive Case
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void automationStatusCompletedForNHECases() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		CaseTriggerHelper.blnFormAutomationBatch = true;
		objCase.Automation_Status__c = CaseUtils.STATUS_COMPLETED;
		objCase.Automation_Message__c = CaseUtils.STR_EMAIL_SENT_TO_CARRIER;
		objCase.Submission_Method__c = CaseUtils.STR_CARRIER_PORTAL;
		update objCase;

		CaseTriggerHelper.blnFormAutomationBatch = false;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MF_FOLLOWUP), objCase.OwnerId, 'Case Owner can not be change as MF Followup');
		System.assertEquals(CaseUtils.STATUS_SUBMITTED, objCase.Status, 'Case Status can not be change as Submitted');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test Automation Status as Completed For NHE Cases : Negative Case
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void automationStatusCompletedForNHECasesNeg() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];
		CaseTriggerHelper.blnFormAutomationBatch = true;
		objCase.Automation_Status__c = CaseUtils.STATUS_COMPLETED;
		objCase.Automation_Message__c = 'Test Message';
		update objCase;

		CaseTriggerHelper.blnFormAutomationBatch = false;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED), objCase.OwnerId, 'Case Owner can not be change as MF Completed');
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case Status can not be change as Closed');
	}

	/**
	 * @author       Elavarasan Nagarathinam
	 * @description  This methos is used to test OCR capture queue assignment on on record type update. Case is not OCR Processed before.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void testTaxResNotOCRProcessedRecTypeChange() {
		Test.startTest();
		Case objCase = [SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c FROM Case WHERE RecordType.Name = 'Payroll Care' AND Subject = 'Phone case 1' LIMIT 1];
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('CA-EDD');

		// OCR not processed case record type updated from payroll care to tax res
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
		objCase.Agency_Information__c = objAgency.Id;
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE, objCase.Status, 'Status not updated to Ready For OCR Capture');
		System.assertEquals(CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID, objCase.OwnerId, 'Owner not updated to OCR Capture Queue');
		System.assertEquals(CaseUtils.TYPE_TAX_RES, objCase.Type, 'Type not updated to Tax Res');
	}

	/**
	 * @author       Elavarasan Nagarathinam
	 * @description  This methos is used to test OCR capture queue assignment on on record type update. Case is already OCR Processed but not indexed
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void testTaxResNotOCRProcessedNotIndexedRecTypeChange() {
		Test.startTest();
		Case objCase = [SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c FROM Case WHERE RecordType.Name = 'Payroll Care' AND Subject = 'Phone case 1' LIMIT 1];
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('CA-EDD');

		// OCR not processed case record type updated from payroll care to tax res
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
		objCase.Agency_Information__c = objAgency.Id;
		objCase.Is_OCR_Processed__c = true;
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, objCase.Status, 'Status not updated to Ready For Data Capture');
		System.assertEquals(CaseTriggerHelper.TAXRESDATACAPTURE_QUEUE_ID, objCase.OwnerId, 'Owner not updated to Data Capture Queue');
		System.assertEquals(CaseUtils.TYPE_TAX_RES, objCase.Type, 'Type not updated to Tax Res');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to manually submit the case record.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void caseManuallySubmittedForNHE() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		objCase.Status = CaseUtils.STATUS_SUBMITTED;
		objCase.Submission_Method__c = CaseUtils.STR_CARRIER_PORTAL;
		update objCase;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Date_Time_Submitted__c, Submitted_By__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED), objCase.OwnerId, 'Case Owner can not be change as MF Completed');
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case Status can not be change as Closed');
		System.assertEquals(UserInfo.getUserId(), objCase.Submitted_By__c, 'Case Submitted By field is not set correctly');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to manually Followup Completed the case record.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void caseManuallyFollowupCompletedForNHE() {
		Test.startTest();
		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		objCase.Status = CaseUtils.CASE_STATUS_FOLLOWUP_COMPLETED;
		update objCase;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId, Follow_Up_Completed_by__c, Closed_By__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseTriggerHelper.nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED), objCase.OwnerId, 'Case Owner can not be change as MF Completed');
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCase.Status, 'Case Status can not be change as Closed');
		System.assertEquals(UserInfo.getUserId(), objCase.Follow_Up_Completed_by__c, 'Case Follow up Completed By field is not set correctly');
		System.assertEquals(UserInfo.getUserId(), objCase.Closed_By__c, 'Closed_By__c should be the current user');
	}

	/**
	 * @author       Ankit C
	 * @description  This method tests the creation of case audit log when owner changes
	 **/
	@isTest
	static void testCaseOwnerChangeAuditLog() {
		Case objCase = [SELECT Id, OwnerId, Subject FROM Case WHERE SuppliedEmail = 'testengagement1@gusto.com'];
		User objUser = [SELECT Id FROM User WHERE Email = 'testactiveuser@gusto.com'];
		objCase.OwnerId = objUser.Id;
		Test.startTest();
		update objCase;
		Test.stopTest();

		List<Case_Audit_Log__c> list_CaseAuditLogs = [
			SELECT Id, To_Owner__c
			FROM Case_Audit_Log__c
			WHERE Case__c = :objCase.Id AND Event_Type__c = :CaseUtils.OWNER_CHANGE
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		System.assert(!list_CaseAuditLogs.isEmpty(), 'Case audit logs were not created for owner change');
		System.assertEquals(list_CaseAuditLogs[0].To_Owner__c, objCase.OwnerId, 'New owner was not updated correctly on case audit log');
	}

	/**
	 * @author       Pradeep Chary
	 * @description  Calculates Time to First Response Hours for Engagement Cases
	 **/
	@isTest
	static void testEngagementTFIRandTRES() {
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE SuppliedEmail = 'testengagement1@gusto.com' LIMIT 1];
		objCase.Status = 'Closed';
		objCase.Audience__c = 'Gusto';

		Test.startTest();
		update objCase;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Time_To_Resolution_Hours__c, Closed_By__c FROM Case WHERE Id = :objCase.Id];
		System.assertNotEquals(null, list_Cases[0].Time_To_Resolution_Hours__c, 'Time_To_Resolution_Hours__c should not be empty');
		System.assertEquals(UserInfo.getUserId(), list_Cases[0].Closed_By__c, 'Closed_By__c should be the current user');
	}

	@isTest
	static void autoInProgressDateTime() {
		Test.startTest();
		BusinessHours objBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
		List<Case> list_Case = [SELECT Id, Status, BusinessHoursId, Follow_Up_Date_Time__c, Internal_Support_Requested_From__c FROM Case WHERE Subject = 'Engagement test case' LIMIT 1];
		list_Case[0].Status = 'Awaiting Internal Support';
		list_Case[0].Internal_Support_Requested_From__c = 'Captain/SME';
		list_Case[0].BusinessHoursId = objBusinessHours.Id;
		update list_Case[0];
		Test.stopTest();

		List<Case> list_CaseAfter = [SELECT Id, Follow_Up_Date_Time__c FROM Case WHERE Id = :list_Case[0].Id];
		System.assertNotEquals(null, list_CaseAfter[0].Follow_Up_Date_Time__c, 'Engagement test case should have a Follow-Up date time');
	}

	/**
	 * @author       Ankit C
	 * @description  Check if IsEscalated is true on case, it should be routed to Engagement Escalations queue.
	 **/
	@isTest
	static void testEscalationCase() {
		Case objCase = [SELECT Id, OwnerId, IsEscalated FROM Case WHERE SuppliedEmail = 'testescalation@gusto.com'];

		Test.startTest();
		objCase.IsEscalated = true;
		update objCase;
		Test.stopTest();

		objCase = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];
		Group objGroup = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :CaseUtils.QUEUE_ENGAGEMENT_ESCALATIONS];
		System.assertEquals(objGroup.Id, objCase.OwnerId, 'Case was not routed to Engagement Escalations queue');
	}

	/**
	 * @author       Akanksha
	 * @description  Check if autoclose datetime is populated for Awaiting response case
	 **/
	@isTest
	static void testAutoCloseDateEngagement() {
		Case objCase = [SELECT Id, status FROM Case WHERE SuppliedEmail = 'testengagement1@gusto.com'];

		Test.startTest();
		objCase.status = 'Awaiting Response';
		update objCase;
		Test.stopTest();
		List<Case> list_CaseAfter = [SELECT Id, BusinessHoursId, Auto_Close_Date_Time__c, status FROM Case WHERE Id = :objCase.Id];
		Date dExpectedAutoCloseDate = BusinessHours.add(list_CaseAfter[0].BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * (Integer.valueOf(Label.EngagementAutoCloseDays))).date();
		Date dActualAutoCloseDate = list_CaseAfter[0].Auto_Close_Date_Time__c.date();

		System.assertEquals('Awaiting Response', list_CaseAfter[0].status);
		// Assert check for the Auto Close date time population
		System.assertEquals(dExpectedAutoCloseDate, dActualAutoCloseDate, 'Auto Close Date Time doesnt match');
	}

	/**
	 * @author       Pradeep Chary
	 * @description  For a Engagement Phone Origin Case update Owner to current user
	 **/
	@isTest
	static void testEngagementPhoneClosedCase() {
		Case objCase = [SELECT Id, OwnerId, Status FROM Case WHERE SuppliedPhone = '12345678900' LIMIT 1];

		objCase.Status = 'Closed';
		objCase.Audience__c = 'Gusto';

		Test.startTest();
		update objCase;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(UserInfo.getUserId(), list_Cases[0].OwnerId, 'Owner Not updated');
	}

	/**
	 * @description  Check if autoclose datetime is populated for same Awaiting response case
	 **/
	@isTest
	static void testAutoCloseDateEngagementOutboundEmail() {
		Case objCase = [SELECT Id, status, Last_out_bound_email__c FROM Case WHERE SuppliedEmail = 'testengagement1@gusto.com'];

		Test.startTest();

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(objCase.Id)
			.setToAddress('test@test.com')
			.setFromAddress('test@gusto.com')
			.setIncoming(false)
			.setSubject('Testing Auto Close Date Time Update')
			.setTextBody('Auto Close Date Time Update')
			.build();
		insert objEmailMessage;

		Test.stopTest();
		List<Case> list_CaseAfter = [SELECT Id, BusinessHoursId, Auto_Close_Date_Time__c, status, Last_out_bound_email__c FROM Case WHERE Id = :objCase.Id];
		Date dExpectedAutoCloseDate = BusinessHours.add(list_CaseAfter[0].BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * (Integer.valueOf(Label.EngagementAutoCloseDays))).date();
		Date dActualAutoCloseDate = list_CaseAfter[0].Auto_Close_Date_Time__c.date();

		System.assertEquals('Awaiting Response', list_CaseAfter[0].status);
		System.assertEquals(dExpectedAutoCloseDate, dActualAutoCloseDate, 'Auto Close Date Time doesnt match');
		System.assertNotEquals(objCase.Last_out_bound_email__c, list_CaseAfter[0].Last_out_bound_email__c, 'Last Out Bound Email Not Updated');
	}

	/**
	 * @author       Ankit C
	 * @description  Check if Specialization is updated on Case if it's created with Routing Case Reaosn with Specialization
	 **/
	@isTest
	static void testSpecializationOnCaseCreate() {
		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('Test case with with routing case reason')
			.setDescription('Test case with with routing case reason')
			.setOrigin('Gusto')
			.setRecordTypeId('Engagement')
			.setRoutingCaseReason('BYB Interest')
			.build();

		Case_Reason_Classification__c objCaseReason = [SELECT Id, Specialization__c FROM Case_Reason_Classification__c WHERE Name = 'BYB Interest'];

		Test.startTest();
		insert objCase;
		Test.stopTest();

		objCase = [SELECT Id, Specialization__c FROM Case WHERE Id = :objCase.Id];
		Assert.areEqual(objCaseReason.Specialization__c, objCase.Specialization__c, 'Specialization was not updated correctly on case.');
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method is used to test Automation Status as Pending For NHE Cases.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void automationStatusSubmittedForNHECases() {
		Test.startTest();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder()
			.setName('Guardian')
			.setUniqueName('guardian-ca')
			.setState('CA')
			.setCarrierId('24')
			.setTerminationEffectiveDate('End of Month')
			.build();
		insert objCarrier;

		Case objCase = [
			SELECT Id, Opportunity__c, AccountId, Automated_RFI_Flow__c
			FROM Case
			WHERE RecordType.Name = 'MF NHE' AND Form_Fully_Mapped__c = TRUE AND Form_Fits_Dependents__c = TRUE
			LIMIT 1
		];

		objCase.Automation_Status__c = CaseUtils.STATUS_SUBMITTED;
		objCase.Carrier__c = objCarrier.Id;
		update objCase;

		Test.stopTest();

		objCase = [SELECT Id, Status, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.CASE_STATUS_PENDING, objCase.Status, 'Case Status can not be change as Pending');
	}

	/**
	 * @author       Ankit C
	 * @description  This method checks the Pillar and Sub-Pillar mappings on Case
	 **/
	@isTest
	static void testCasePillarMapping() {
		Case objCase = [SELECT Id, Specialization__c, Company_Size__c, Support_Level__c FROM Case WHERE SuppliedEmail = 'testcasepillar1@gusto.com'];
		Case objCase2 = [SELECT Id, Specialization__c, Company_Size__c, Support_Level__c FROM Case WHERE SuppliedEmail = 'testcasepillar2@gusto.com'];
		
		Test.startTest();
		objCase.Specialization__c = 'Cancel';
		update objCase;

		Case objUpdatedCase1 = [SELECT Id, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c, Specialization__c, Pillar_Key__c, Sub_Pillar_Key__c FROM Case WHERE Id = :objCase.Id];

		objCase.Specialization__c = '';
		objCase.Company_Size__c = 'Standard 5-24';
		objCase.Support_Level__c = 'Tier 2';
		update objCase;

		Case objUpdatedCase2 = [SELECT Id, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c, Specialization__c, Pillar_Key__c, Sub_Pillar_Key__c FROM Case WHERE Id = :objCase.Id];

		objCase2.Support_Level__c = 'Tier 2';
		objCase2.Company_Size__c = 'Standard 5-24';
		update objCase2;

		Case objUpdatedCase3 = [SELECT Id, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c, Specialization__c FROM Case WHERE Id = :objCase2.Id];

		Case objChatCase = [SELECT Id, Company_Size__c, Support_Level__c, Origin FROM Case WHERE SuppliedEmail = 'testchatcase@gusto.com'];
		objChatCase.Origin = 'Email';
		objChatCase.Company_Size__c = 'Standard 5-24';
		objChatCase.Support_Level__c = 'Tier 2';
		update objChatCase;

		objChatCase = [SELECT Id, Company_Size__c, Support_Level__c, Origin, WFM_Queue_Tag__c FROM Case WHERE Id = :objChatCase.Id];

		Test.stopTest();
		Assert.areEqual('Cancel Pillar', objUpdatedCase1.Case_Pillar__c, 'Pillar was not updated correctly');
		Assert.areEqual('Cancel Sub Pillar', objUpdatedCase1.Sub_Pillar__c, 'Sub Pillar was not updated correctly');
		Assert.areEqual('Test WFM Queue Tag', objUpdatedCase1.WFM_Queue_Tag__c, 'WFM Queue Tag was not updated correctly');
		Assert.areEqual('P-002', objUpdatedCase1.Pillar_Key__c, 'Pillar Key was not updated correctly');
		Assert.areEqual('SP-002', objUpdatedCase1.Sub_Pillar_Key__c, 'Sub Pillar Key was not updated correctly');
		Assert.areEqual('Test Pillar', objUpdatedCase2.Case_Pillar__c, 'Pillar was not updated correctly');
		Assert.areEqual('Test Sub Pillar', objUpdatedCase2.Sub_Pillar__c, 'Sub Pillar was not updated correctly');
		Assert.areEqual('Test WFM Queue Tag', objUpdatedCase2.WFM_Queue_Tag__c, 'WFM Queue Tag was not updated correctly');
		Assert.areEqual('P-001', objUpdatedCase2.Pillar_Key__c, 'Pillar Key was not updated correctly');
		Assert.areEqual('SP-001', objUpdatedCase2.Sub_Pillar_Key__c, 'Sub Pillar Key was not updated correctly');
		Assert.isTrue(String.isNotBlank(objUpdatedCase3.Case_Pillar__c));
		Assert.areEqual('Test WFM Queue Tag', objChatCase.WFM_Queue_Tag__c, 'WFM Queue Tag was not updated correctly');
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test if Closed_Owenr_Role__c is getting updated on case creation
	 **/
	@isTest
	static void testClosedOwnerRoleInsert() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];

		User objUser = [
			SELECT Id, UserRole.Name
			FROM User
			WHERE Email = 'testSalesMDR_XX_User@task.com' AND UserRoleId = :Label.MDR_Role_ID
			LIMIT 1
		];

		System.runAs(objUser) {
			Test.startTest();

			Case objCase = new TestDataFactory.CaseBuilder()
				.setAccountId(objAccount.Id)
				.setContactId(objContact.Id)
				.setRecordTypeId('Payroll Care')
				.setType('Sales')
				.setSubject('Test Duplicate Case')
				.setOrigin('Email')
				.setDirection('Inbound')
				.setStatus('New')
				.setSuppliedEmail('lalithatest@acme.com')
				.setDescription('Test Duplicate Case')
				.build();

			insert objCase;

			Test.stopTest();

			Case objCaseAssert = [SELECT Id, Closed_Owner_Role__c FROM Case WHERE Id = :objCase.Id LIMIT 1];
			System.assertEquals(objUser.UserRole.Name, objCaseAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
		}

	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Test if Closed_Owenr_Role__c is getting updated on case update
	 **/
	@isTest
	static void testClosedOwnerRoleUpdate() {
		Account objAccount = [SELECT Id, Name FROM Account LIMIT 1];
		Contact objContact = [SELECT Id FROM Contact WHERE FirstName = 'Test Contact' LIMIT 1];

		User objUser = [
			SELECT Id, UserRole.Name
			FROM User
			WHERE Email = 'testSalesMDR_XX_User@task.com' AND UserRoleId = :Label.MDR_Role_ID
			LIMIT 1
		];

		System.runAs(objUser) {
			Test.startTest();

			Case objCase = new TestDataFactory.CaseBuilder()
				.setAccountId(objAccount.Id)
				.setContactId(objContact.Id)
				.setRecordTypeId('Payroll Care')
				.setType('Sales')
				.setSubject('Test Duplicate Case')
				.setOrigin('Email')
				.setDirection('Inbound')
				.setStatus('New')
				.setSuppliedEmail('lalithatest@acme.com')
				.setDescription('Test Duplicate Case')
				.build();

			insert objCase;

			objCase.Status = 'Closed';

			Test.stopTest();

			Case objCaseAssert = [SELECT Id, Closed_Owner_Role__c FROM Case WHERE Id = :objCase.Id LIMIT 1];
			System.assertEquals(objUser.UserRole.Name, objCaseAssert.Closed_Owner_Role__c, 'Closed Owner Role did not get updated with owner role.');
		}
	}

	/**
	 * @author       Jayesh Gawande
	 * @description  This method is used to test setCaseOwnerWhenEmailSenderIsNBKC method when case from NBKC route it to Risk Assurance.
	 * @param 		 NA
	 * @return 		 NA
	 **/
	@isTest
	static void setCaseOwnerWhenEmailSenderIsNBKCTest() {
		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setSubject('Case From NBKC')
			.setDescription('Test')
			.setOrigin('Email')
			.setSuppliedEmail('bsacompliance@nbkc.com')
			.setRecordTypeId('Engagement')
			.build();
		insert objCase;
		Test.stopTest();

		objCase = [SELECT Id, RecordTypeId, Type FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objCase.RecordTypeId, CaseUtils.RECTYPE_RISK_ASSURANCE, 'Case RecordType should be set to Risk Assurance');
		System.assertEquals(objCase.Type, CaseUtils.TYPE_INVESTIGATIONS, 'Case Type should be set to Investigations');
	}
}