@isTest
private class NPRNOrderNotificationComponentContTest {
	public static final String RENEWAL_END_OF_YEAR_MACRO = 'Renewal end of year insert';
	public static final String NEWPLAN_END_OF_YEAR_MACRO = 'New Plan end of year insert';
	@testSetup
	static void setupData() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		PolicyHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		List<Account> list_Accounts = new List<Account>();
		List<Opportunity> list_Opps = new List<Opportunity>();
		List<Benefit_Order__c> list_BOs = new List<Benefit_Order__c>();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		PriceBook2 objPriceBook = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true);
		insert objPriceBook;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company Account')
			.setRecordTypeId('Company')
			.setPricing(objTierConfig.New_Price_1__c)
			.build(); 

		list_Accounts.add(objAccount);

		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setName('Test Company Account')
			.setRecordTypeId('Company')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();

		list_Accounts.add(objAccount1);
		insert list_Accounts;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setFirstName('first')
			.setLastName('last')
			.setEmail('testcontact@domain.com')
			.setAccountId(objAccount.Id)
			.setRecordTypeId('Company')
			.build();

		insert objContact;

		Opportunity objOpp = new Opportunity(
			AccountId = objAccount.Id,
			Pricebook2Id = objPriceBook.Id,
			name = 'Benefit Designer Opp',
			StageName = 'SAL',
			Sold_By__c = list_Accounts[1].Id,
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = System.today().addDays(30),
			Owner_Role_Name__c = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER,
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal')
		);
		list_Opps.add(objOpp);

		Opportunity objOpp1 = new Opportunity(
			AccountId = objAccount.Id,
			Pricebook2Id = objPriceBook.Id,
			name = 'Renewal Specialist Opp',
			StageName = 'SAL',
			Sold_By__c = list_Accounts[1].Id,
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = System.today().addDays(30),
			Owner_Role_Name__c = FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST,
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal')
		);
		list_Opps.add(objOpp1);

		Opportunity objOpp2 = new Opportunity(
			AccountId = objAccount.Id,
			Pricebook2Id = objPriceBook.Id,
			name = 'New Plan Opp',
			StageName = 'SAL',
			Sold_By__c = list_Accounts[1].Id,
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = System.today().addDays(30),
			RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan')
		);
		list_Opps.add(objOpp2);
		insert list_Opps;

		Benefit_Order__c objBenefitOrder = new Benefit_Order__c(
			Name = 'Test Benefit Designer',
			Opportunity__c = objOpp.Id,
			Account__c = objAccount.Id,
			Coverage_Effective_Date__c = Date.today(),
			Submission_Deadline__c = Date.today(),
			Push_Rate_Reason__c = 'Not enough EE enrolled',
			RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal')
		);
		list_BOs.add(objBenefitOrder);

		Benefit_Order__c objBenefitOrder1 = new Benefit_Order__c(
			Name = 'Test Benefit Renewal',
			Opportunity__c = objOpp1.Id,
			Account__c = objAccount.Id,
			Coverage_Effective_Date__c = Date.today(),
			Submission_Deadline__c = Date.today(),
			Push_Rate_Reason__c = 'Not enough EE enrolled',
			RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal')
		);
		list_BOs.add(objBenefitOrder1);

		Benefit_Order__c objBenefitOrderNewPlan = new Benefit_Order__c(
			Name = 'Test Bendfit',
			Opportunity__c = objOpp1.Id,
			Account__c = objAccount.Id,
			Coverage_Effective_Date__c = Date.today(),
			Submission_Deadline__c = Date.today(),
			Push_Rate_Reason__c = 'Not enough EE enrolled',
			RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan')
		);
		list_BOs.add(objBenefitOrderNewPlan);
		insert list_BOs;

		Carrier__c objCarrier = new Carrier__c(Name = 'Principal The Standard');
		objCarrier.State__c = 'AL; AK; AZ; AR; CA; CO; CT; DE; FL; GA; HI; ID; IL; IN; IA; KS; KY; LA; ME; MD; MA; MI; MN; MS; MO; MT; NE; NV; NH; NJ; NM; NY; NC; ND; OH; OK; OR; PA; RI; SC; SD; TN; TX; UT; VT; VA; WA; WV; WI; WY';
		insert objCarrier;

		Carrier_Order__c objCarrierOrder = new Carrier_Order__c(
			Carrier__c = objCarrier.Id,
			Name = 'acc1 Ameritas Order',
			Benefit_Order__c = objBenefitOrderNewPlan.Id,
			Start_Date__c = Date.today(),
			Submission_Deadline__c = Date.today()
		);
		list_CarrierOrders.add(objCarrierOrder);

		Carrier_Order__c objCarrierOrder1 = new Carrier_Order__c(
			Carrier__c = objCarrier.Id,
			Name = 'acc1 Ameritas Order',
			Benefit_Order__c = objBenefitOrder.Id,
			Start_Date__c = Date.today(),
			Submission_Deadline__c = Date.today()
		);
		list_CarrierOrders.add(objCarrierOrder1);
		insert list_CarrierOrders;

		List<Policy__c> list_Policies = new List<Policy__c>();
		Policy__c objPolicy1 = new Policy__c(
			Name = 'Medical Policy',
			Account__c = objAccount.Id,
			Opportunity__c = objOpp.Id,
			Carrier__c = objCarrier.Id,
			Carrier_Order__c = objCarrierOrder1.Id,
			Is_Selected__c = true,
			Benefit_Type__c = 'Medical'
		);
		list_Policies.add(objPolicy1);

		Policy__c objPolicy2 = new Policy__c(
			Name = 'Medical Policy',
			Account__c = objAccount.Id,
			Opportunity__c = objOpp1.Id,
			Carrier__c = objCarrier.Id,
			Carrier_Order__c = objCarrierOrder.Id,
			Is_Selected__c = true,
			Benefit_Type__c = 'Medical'
		);
		list_Policies.add(objPolicy2);

		Policy__c objPolicy3 = new Policy__c(
			Name = 'Dental Policy',
			Account__c = objAccount.Id,
			Opportunity__c = objOpp1.Id,
			Carrier__c = objCarrier.Id,
			Is_Selected__c = true,
			Benefit_Type__c = 'Dental'
		);
		list_Policies.add(objPolicy3);
		insert list_Policies;

		List<Email_Macro__c> list_EM = new List<Email_Macro__c>();
		list_EM.add(new Email_Macro__c(Macro_Identifier__c = 'RENEWAL_END_OF_YEAR', Body__c = RENEWAL_END_OF_YEAR_MACRO));
		list_EM.add(new Email_Macro__c(Macro_Identifier__c = 'NEWPLAN_END_OF_YEAR', Body__c = NEWPLAN_END_OF_YEAR_MACRO));

		insert list_EM;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Check fields related to Benefits Designer.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testTemplateForBenefitDesigner() {
		Test.startTest();
		List<Opportunity> list_Opps = [SELECT Id, Name, AccountId, Pricebook2Id, StageName, Sold_By__c, closedate, NumberOfEmployees__c FROM Opportunity WHERE Name = 'Benefit Designer Opp'];

		NPRNOrderNotificationComponentController objNPRNOrderNotification = new NPRNOrderNotificationComponentController();
		objNPRNOrderNotification.oppId = list_Opps[0].Id;
		objNPRNOrderNotification.caseRecordId = null;
		objNPRNOrderNotification.oppEffDate = Date.today();
		objNPRNOrderNotification.benefitOwnerName = UserInfo.getUserName();
		objNPRNOrderNotification.waitingPeriod = '1';
		objNPRNOrderNotification.medicalCarrierSubmissionDays = 20;
		objNPRNOrderNotification.getOpp();
		objNPRNOrderNotification.getPolicyInfoList();

		Test.stopTest();

		System.assert(!objNPRNOrderNotification.blnIsRenewalSpecialistAssigned);
		System.assert(objNPRNOrderNotification.blnIsAdvisingIncludedInSignature);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Check fields related to Renewal Specialist.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testTemplateForRenewalSpec() {
		Test.startTest();
		List<Opportunity> list_Opps = [SELECT Id, Name, AccountId, Pricebook2Id, StageName, Sold_By__c, closedate, NumberOfEmployees__c FROM Opportunity WHERE Name = 'Renewal Specialist Opp'];

		NPRNOrderNotificationComponentController objNPRNOrderNotification = new NPRNOrderNotificationComponentController();
		objNPRNOrderNotification.oppId = list_Opps[0].Id;
		objNPRNOrderNotification.caseRecordId = null;
		objNPRNOrderNotification.oppEffDate = Date.today();
		objNPRNOrderNotification.benefitOwnerName = UserInfo.getUserName();
		objNPRNOrderNotification.waitingPeriod = '1';
		objNPRNOrderNotification.medicalCarrierSubmissionDays = 20;
		objNPRNOrderNotification.getOpp();
		objNPRNOrderNotification.getPolicyInfoList();

		Test.stopTest();

		System.assert(objNPRNOrderNotification.blnIsRenewalSpecialistAssigned);
		System.assert(!objNPRNOrderNotification.blnIsAdvisingIncludedInSignature);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Validate Email Macro
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testValidateEmailMacro() {
		Test.startTest();
		NPRNOrderNotificationComponentController objNPRNOrderNotification = new NPRNOrderNotificationComponentController();

		Test.stopTest();

		System.assert(NPRNOrderNotificationComponentController.RENEWAL_MACRO == 'Renewal end of year insert');
		System.assert(NPRNOrderNotificationComponentController.NEWPLAN_MACRO == 'New Plan end of year insert');
	}
}