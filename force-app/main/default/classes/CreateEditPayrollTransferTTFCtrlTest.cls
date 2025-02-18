/*
 * Test class for covering unit test scenarios for CreateEditPayrollTransferTTFCtrl (Payroll Transfer TTF)
 */
@isTest
class CreateEditPayrollTransferTTFCtrlTest {
	static list<Opportunity> testOpportunities;

	private static void setupTestData() {
		//Accounts
		Account objAccount1 = new TestDataFactory.AccountBuilder()
			.setName('Test Account1')
			.setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
			.setZPCompanyId('TestAcc001')
			.build();

		List<Account> lstAcc = new List<Account>();
		lstAcc.add(objAccount1);

		Account objAccount2 = new TestDataFactory.AccountBuilder()
			.setName('Test Account2')
			.setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
			.setZPCompanyId('TestAcc002')
			.build();
		lstAcc.add(objAccount2);

		Account objAccount3 = new TestDataFactory.AccountBuilder()
			.setName('Test Account3')
			.setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
			.setZPCompanyId('TestAcc003')
			.build();
		lstAcc.add(objAccount3);

		Account account4 = new TestDataFactory.AccountBuilder()
			.setName('Company Account 004')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setZPCompanyId('TestAcc004')
			.build();
		lstAcc.add(account4);

		AccountTriggerHelper.skiptrigger = true;
		insert lstAcc;

		Contact objContact1 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objAccount1.Id)
			.setEmail('testAddress1@domain.com')
			.setFirstName('fName1')
			.setLastName('lName1')
			.build();

		List<Contact> lstContact = new List<Contact>();
		lstContact.add(objContact1);

		Contact objContact2 = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objAccount1.Id)
			.setEmail('testAddress2@domain.com')
			.setFirstName('fName2')
			.setLastName('lName2')
			.build();
		lstContact.add(objContact2);

		insert lstContact;

		//Opportunities
		testOpportunities = new List<Opportunity>();
		Opportunity opp1 = new Opportunity(AccountId = objAccount1.id, StageName = 'SAL', Closedate = System.today(), NumberOfEmployees__c = 12, HI_Effective_Date__c = System.today().addDays(30));
		opp1.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		opp1.Source_Id__c = 'TestAcc001';
		opp1.Name = objAccount1.Name + 'Acquisition Opportunity';
		testOpportunities.add(opp1);

		Opportunity opp2 = opp1.clone(false);
		opp2.Source_Id__c = 'TestAcc002';
		opp2.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		opp2.AccountId = objAccount2.Id;
		opp2.Name = objAccount2.Name + 'Acquisition Opportunity';
		testOpportunities.add(opp2);

		Opportunity opp3 = opp1.clone(false);
		opp3.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		opp3.AccountId = objAccount3.Id;
		opp3.Source_Id__c = 'TestAcc003';
		opp3.Name = objAccount3.Name + 'Acquisition Opportunity';
		opp3.Owner_Division__c = 'Small Business';
		testOpportunities.add(opp3);

		Opportunity opp4 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(account4.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setSourceID('TestAcc004')
			.setName(account4.Name + 'Acquisition Opportunity')
			.build();

		opp4.Owner_Division__c = 'Partner';
		testOpportunities.add(opp4);

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setAccountId(objAccount1.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setSourceID('TestOppty123')
			.setName(objAccount1.Name + 'Acquisition Opportunity')
			.build();
	   
		testOpportunities.add(objOppty);

		OpportunityTriggerHelper.skipTrigger = true;

		insert testOpportunities;

		System.assert(testOpportunities[0].Id != null, 'Opportunity Id should not be null.');
		//Orders
		List<Order> lstOrders = new List<Order>();

		Order objOrder1 = new Order(
			Status = 'Drafted',
			First_Check_Date__c = System.today().addDays(20),
			EffectiveDate = System.today().addDays(8),
			opportunityId = opp1.Id,
			AccountId = objAccount1.Id,
			Fast_ACH__c = true,
			Direct_Deposit_Speed__c = '2-day',
			Last_Expected_Pay_Date__c = Date.today(),
			Contractor_Payment_Method__c = 'Direct Deposit'
		);

		lstOrders.add(objOrder1);
		Order objOrder2 = new Order(Status = 'Drafted', First_Check_Date__c = System.today().addDays(20), EffectiveDate = System.today().addDays(8), opportunityId = opp2.Id, AccountId = objAccount2.Id);

		lstOrders.add(objOrder2);

		Order objOrder3 = new Order(
			Status = 'Drafted',
			First_Check_Date__c = Date.newInstance(2022, 1, 4),
			EffectiveDate = System.today().addDays(8),
			opportunityId = opp3.Id,
			AccountId = objAccount3.Id
		);
		objOrder3.First_Check_Date_Week_Number__c = 1;
		lstOrders.add(objOrder3);

		Id ORDER_RT_COMPANYMIGRATION = Cache.getRecordTypeId('Order', 'Company Migration');
		Order objOrder4 = new TestDataFactory.OrderBuilder().setOwnerId(UserInfo.getUserId()).setAccountId(account4.Id).setOpportunityId(opp4.Id).setRecordTypeId(ORDER_RT_COMPANYMIGRATION).setStatus('Drafted').build();

		objOrder4.First_Check_Date__c = Date.newInstance(2022, 1, 4);
		objOrder4.EffectiveDate = System.today().addDays(8);
		objOrder4.First_Check_Date_Week_Number__c = 1;
		lstOrders.add(objOrder4);

		OrderTriggerHelper.skipTrigger = true;
		insert lstOrders;

		testOpportunities[0].Order__c = objOrder1.Id;
		testOpportunities[1].Order__c = objOrder2.Id;
		testOpportunities[2].Order__c = objOrder3.Id;
		testOpportunities[3].Order__c = objOrder4.Id;

		OpportunityTriggerHelper.skipTrigger = true;
		update testOpportunities;

		//Opportunity Contact Role
		List<OpportunityContactRole> lstOpptyCRole = new List<OpportunityContactRole>();
		lstOpptyCRole.add(new OpportunityContactRole(ContactID = objContact1.Id, OpportunityId = opp1.Id, Check_Additional_POC__c = true, Role = 'Payroll Admin'));
		lstOpptyCRole.add(new OpportunityContactRole(ContactID = objContact2.Id, OpportunityId = opp1.Id, Check_Additional_POC__c = false, Role = 'Primary Payroll Admin'));
		lstOpptyCRole.add(new OpportunityContactRole(ContactID = objContact1.Id, OpportunityId = opp4.Id, Check_Additional_POC__c = true, Role = 'Payroll Admin'));
		lstOpptyCRole.add(new OpportunityContactRole(ContactID = objContact2.Id, OpportunityId = opp4.Id, Check_Additional_POC__c = false, Role = 'Primary Payroll Admin'));
		insert lstOpptyCRole;

		Id idFbos_RTId_Advocate = Cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate');
		Set<String> set_Months = new Set<String>{ 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' };
		List<Payroll_Transfer_FBOS_Forecast__c> lst_FBOSForecasts = new List<Payroll_Transfer_FBOS_Forecast__c>();

		for (string strMonth : set_Months) {
			Payroll_Transfer_FBOS_Forecast__c objForecast = new TestDataFactory.PayrollTransferFBOSForecastBuilder()
				.setYear(string.valueOf(System.today().year()))
				.setMonth(strMonth)
				.setFBOSForecast(100)
				.setFirstWeekCap(20)
				.setSecondWeekCap(20)
				.setThirdWeekCap(20)
				.setFourthWeekCap(20)
				.setFifthWeekCap(20)
				.setRecordTypeId(idFbos_RTId_Advocate)
				.build();
			lst_FBOSForecasts.add(objForecast);
		}

		for (string strMonth : set_Months) {
			Payroll_Transfer_FBOS_Forecast__c objForecast = new TestDataFactory.PayrollTransferFBOSForecastBuilder()
				.setYear(string.valueOf(2022))
				.setMonth(strMonth)
				.setFBOSForecast(100)
				.setFirstWeekCap(20)
				.setSecondWeekCap(20)
				.setThirdWeekCap(20)
				.setFourthWeekCap(20)
				.setFifthWeekCap(20)
				.setRecordTypeId(idFbos_RTId_Advocate)
				.build();
			lst_FBOSForecasts.add(objForecast);
		}
		if (!lst_FBOSForecasts.isEmpty()) {
			insert lst_FBOSForecasts;
		}
	}

	@isTest
	private static void testPayrollTransferTTFValidations() {
		setupTestData();
		test.startTest();
		if (testOpportunities != null && testOpportunities.size() > 0) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', testOpportunities[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			System.assert(ctrl.ttfRecord != null, 'ttfRecord should not be null.');
			ctrl.ttfRecord.Exception_Request__c = 'Yes';
			ctrl.savePayrollTTF();

			//System.assert(ctrl.ttfRecord.Id == NULL);
		}
		test.stopTest();
	}
	
	@isTest
	private static void testPayrollTransferTTF() {
		setupTestData();
		Test.startTest();
		Id idTTF = null;
		if (testOpportunities != null && testOpportunities.size() > 0) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', testOpportunities[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			System.assert(ctrl.ttfRecord != null, 'ttfRecord should not be null.');

			ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'No';
			ctrl.ttfRecord.Demo_Complete__c = 'Yes';
			//Commented by AKS dated 6th Nov 2020- Not require to recalculate PayrollRunDate
			//ctrl.recalculatePayrollRunDate();

			ctrl.idPrimaryRole = ctrl.lstPOCWrapper[0].objContactRole.Id;
			ctrl.lstPOCWrapper[0].boolChkPrimary = true;
			ctrl.selectPrimary();

			ctrl.ttfRecord.TTF_Status__c = 'Sales Submitted';

			ctrl.ttfRecord.Multi_EIN__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Multi-EIN';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Bulk_Deal__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Bulk Migration';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Same_Login__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Same Login';
			ctrl.validateMultiEINSameLoginBulkDeal();

			if (null != ctrl.lstAccWrapper && ctrl.lstAccWrapper.size() > 0) {
				ctrl.selectedCompanyIndx = 0;
				ctrl.lstAccWrapper[0].isSelected = true;
				ctrl.selectCompany();
			}
			ctrl.savePayrollTTF();
			idTTF = ctrl.ttfRecord.Id;
			//System.assert(ctrl.ttfRecord.Id != NULL);

			ctrl.idAcccountToBeRemoved = ctrl.lstAccWrapper[0].objAccount.Id;
			ctrl.removeAccount();

			System.assert(ctrl.mapSelectedAccounts.size() == 0, 'Size of mapSelectedAccounts should be 0.');
		}

		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTF = [
			SELECT Id, Direct_Deposit_Speed__c, Last_Expected_Pay_Date__c, Contractor_Payment_Method__c
			FROM Transition_To_Fulfillment__c
			WHERE Id = :idTTF
			LIMIT 1
		];
		System.assert(list_TTF[0].Direct_Deposit_Speed__c == '2-day', 'Direct_Deposit_Speed__c should be 2-day.');
		System.assert(list_TTF[0].Last_Expected_Pay_Date__c == Date.today(), 'Last_Expected_Pay_Date__c should match the today\'s date.');
		System.assert(list_TTF[0].Contractor_Payment_Method__c == 'Direct Deposit', 'Contractor_Payment_Method__c should be Direct Deposit.');
	}
	
	@isTest
	private static void testTTFEditMode() {
		setupTestData();
		test.startTest();
		if (testOpportunities != null && testOpportunities.size() > 0) {
			Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c(
				Opportunity__c = testOpportunities[0].Id,
				Order__c = testOpportunities[0].Order__c,
				Account__c = testOpportunities[0].AccountId,
				Previous_Payroll_Provider__c = 'Paychex',
				Contractors_paid_on_first_pay_date__c = 'Yes',
				Demo_Complete__c = 'Yes',
				Multi_EIN__c = 'Y',
				RecordTypeId = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Payroll Transfer')
			);
			insert objTTF;

			//Case
			Case objCase = new Case(Subject = 'Test CAse', Order__c = testOpportunities[0].Order__c, RecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Transfer Case'));

			insert objCase;
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('ttfId', objTTF.Id);
			ref.getParameters().put('retURL', '/' + testOpportunities[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(objTTF);
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			//test pagination
			Boolean hasNext = ctrl.hasNExt;
			Boolean hasPrev = ctrl.hasPrevious;
			Integer pg = ctrl.pageNumber;
			ctrl.getTotalPages();
			ctrl.first();
			ctrl.last();
			ctrl.previous();
			ctrl.next();

			ctrl.strAccName = 'test';
			ctrl.strZPCompanyId = 'test';
			ctrl.searchAccounts();

			ctrl.idSecRole = ctrl.lstPOCWrapper[0].objContactRole.Id;
			ctrl.lstPOCWrapper[0].objContactRole.Check_Additional_POC__c = true;
			ctrl.lstPOCWrapper[0].boolChkPrimary = true;
			ctrl.selectSecondary();

			ctrl.idPrimaryRole = ctrl.lstPOCWrapper[1].objContactRole.Id;
			ctrl.lstPOCWrapper[1].boolChkPrimary = true;
			ctrl.lstPOCWrapper[1].objContactRole.Check_Additional_POC__c = true;
			ctrl.selectPrimary();

			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'No';
			//ctrl.recalculatePayrollRunDate();

			ctrl.ttfRecord.TTF_Status__c = 'PT Approved';

			ctrl.savePayrollTTF();

			ctrl.cancelPayrollTTF();

			System.assert(ctrl.ttfRecord.Id != null, 'ttfRecord Id should not be null.');
		}
		test.stopTest();
	}

	@isTest
	private static void testPayrollTransferTTFAutoException() {
		test.startTest();

		if (testOpportunities != null && testOpportunities.size() > 0) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', testOpportunities[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			System.assert(ctrl.ttfRecord != null, 'ttfRecord should not be null.');
		}

		test.stopTest();
	}

	@isTest
	private static void testPayrollTransferTTFExcpetion() {
		setupTestData();
		test.startTest();

		if (testOpportunities != null && testOpportunities.size() > 0) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', testOpportunities[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			System.assert(ctrl.ttfRecord != null, 'ttfRecord should not be null.');

			ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'Yes';
			ctrl.ttfRecord.Demo_Complete__c = 'Yes';
			//ctrl.recalculatePayrollRunDate();

			ctrl.idPrimaryRole = ctrl.lstPOCWrapper[0].objContactRole.Id;
			ctrl.lstPOCWrapper[0].boolChkPrimary = true;
			ctrl.selectPrimary();

			ctrl.ttfRecord.TTF_Status__c = 'Bad Value';

			ctrl.savePayrollTTF();

			System.assert(ctrl.ttfRecord.Id == null, 'ttfRecord Id should be null.');
		}
	}

	/**
	 * @Author      : Sandeep Golla
	 * @Description : Assert if TTF status is Sales Submitted after inserting
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	private static void testTTFvalidateWeeklyCap() {
		setupTestData();
		Test.startTest();
		Id idTTF = null;
		List<Opportunity> list_Opps = [SELECT Id, Name, RecordTypeId, AccountId, Source_Id__c FROM Opportunity WHERE Source_Id__c = 'TestAcc004' LIMIT 1];
		if (list_Opps != null && !list_Opps.isEmpty()) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', list_Opps[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'No';
			ctrl.ttfRecord.Demo_Complete__c = 'Yes';

			ctrl.idPrimaryRole = ctrl.lstPOCWrapper[0].objContactRole.Id;
			ctrl.lstPOCWrapper[0].boolChkPrimary = true;
			ctrl.selectPrimary();

			ctrl.ttfRecord.TTF_Status__c = 'Sales Submitted';

			ctrl.ttfRecord.Multi_EIN__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Multi-EIN';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Bulk_Deal__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Bulk Migration';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Same_Login__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Same Login';
			ctrl.validateMultiEINSameLoginBulkDeal();

			if (null != ctrl.lstAccWrapper && ctrl.lstAccWrapper.size() > 0) {
				ctrl.selectedCompanyIndx = 0;
				ctrl.lstAccWrapper[0].isSelected = true;
				ctrl.selectCompany();
			}
			ctrl.savePayrollTTF();
			idTTF = ctrl.ttfRecord.Id;

			ctrl.idAcccountToBeRemoved = ctrl.lstAccWrapper[0].objAccount.Id;
			ctrl.removeAccount();
			System.assert(ctrl.mapSelectedAccounts.size() == 0, 'Size of mapSelectedAccounts should be 0.');
		}
		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTF = [
			SELECT Id, TTF_Status__c, Direct_Deposit_Speed__c, Last_Expected_Pay_Date__c, Contractor_Payment_Method__c
			FROM Transition_To_Fulfillment__c
			WHERE Id = :idTTF
			LIMIT 1
		];
		System.assert(list_TTF[0].TTF_Status__c == 'Sales Submitted', 'TTF_Status__c should be Sales Submitted.');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test to see if the Exception Log records are not created in case of validation rule trigger
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	private static void testTTFSkipValidationRuleException() {
		setupTestData();
		Test.startTest();
		Id idTTF = null;
		List<Opportunity> list_Opps = [SELECT Id, Name, RecordTypeId, AccountId, Source_Id__c FROM Opportunity WHERE Source_Id__c = 'TestAcc004' LIMIT 1];
		if (list_Opps != null && !list_Opps.isEmpty()) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', list_Opps[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'No';
			ctrl.ttfRecord.Demo_Complete__c = 'Yes';
			ctrl.ttfRecord.Does_customer_have_integrated_deductions__c = 'Yes';

			ctrl.idPrimaryRole = ctrl.lstPOCWrapper[0].objContactRole.Id;
			ctrl.lstPOCWrapper[0].boolChkPrimary = true;
			ctrl.selectPrimary();

			ctrl.ttfRecord.TTF_Status__c = 'Sales Submitted';

			ctrl.ttfRecord.Multi_EIN__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Multi-EIN';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Bulk_Deal__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Bulk Migration';
			ctrl.validateMultiEINSameLoginBulkDeal();

			ctrl.ttfRecord.Same_Login__c = 'Y';
			ctrl.strTypeBulkDealSelected = 'Same Login';
			ctrl.validateMultiEINSameLoginBulkDeal();

			if (null != ctrl.lstAccWrapper && ctrl.lstAccWrapper.size() > 0) {
				ctrl.selectedCompanyIndx = 0;
				ctrl.lstAccWrapper[0].isSelected = true;
				ctrl.selectCompany();
			}
			ctrl.savePayrollTTF();
			idTTF = ctrl.ttfRecord.Id;

			ctrl.idAcccountToBeRemoved = ctrl.lstAccWrapper[0].objAccount.Id;
			ctrl.removeAccount();
			System.assert(ctrl.mapSelectedAccounts.size() == 0, 'Size of mapSelectedAccounts should be 0.');
		}
		Test.stopTest();

		List<Transition_To_Fulfillment__c> list_TTF = [
			SELECT Id, TTF_Status__c, Direct_Deposit_Speed__c, Last_Expected_Pay_Date__c, Contractor_Payment_Method__c
			FROM Transition_To_Fulfillment__c
			WHERE Id = :idTTF
			LIMIT 1
		];

		System.assertEquals(0,list_TTF.size(), 'TTF record should not be created');

		List<Exception_Log__c> objExceptionLog = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'CreateEditPayrollTransferTTFCtrl' AND Method_Name__c = 'savePayrollTTF'];
		System.assertEquals(0,objExceptionLog.size(), 'Exception log record should not be created for the validation rule exception');
	}

	/**
	 * @Author      : Swati Arya
	 * @Description : Test Method to No Order Exception Scenario
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	private static void testPayrollTransferNoOrderException() {
        setupTestData();
        Opportunity objOpp = [SELECT Id, Source_ID__c FROM Opportunity WHERE RecordTypeId =:OpportunityUtil.ACQUISITION_OPPTY_RT_ID AND Source_ID__c = 'TestOppty123' LIMIT 1];
        
        Test.startTest();
        
        PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
        ref.getParameters().put('oppId', objOpp.Id);
        Test.setCurrentPageReference(ref);

        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
        CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

        ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
        ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'Yes';
        ctrl.ttfRecord.Demo_Complete__c = 'Yes';
		
        ctrl.savePayrollTTF();
        Test.stopTest();

        System.assertEquals(null, ctrl.ttfRecord.Id, 'TTF Should not be created since there is no order attached to opportunity');
    }

	/**
	 * @Description : Test reserve allocation
	 * @See : Updates to CreateEditPayrollTransferTTFCtrl.validateWeeklyCap for reserve calculation
	 **/
	private static testMethod void testTTFvalidateWeeklyCapReserve() {
		setupTestData();
		Test.startTest();
		Id idTTF = null;
		Account objTestAccount = [SELECT Id FROM Account WHERE ZP_Company_ID__c = 'TestAcc003' LIMIT 1][0];
		List<Opportunity> list_Opps = [SELECT Id, Name, RecordTypeId, AccountId, Source_Id__c FROM Opportunity WHERE Owner_Division__c = 'Small Business'];
		Contact objTestContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objTestAccount.Id)
			.setEmail('testAddressReserve@domain.com')
			.setFirstName('fNameReserve')
			.setLastName('lNameReserve')
			.build();
		insert objTestContact;
		if (list_Opps != null && !list_Opps.isEmpty()) {
			PageReference ref = new PageReference('/CreateEditPayrollTransferTTF');
			ref.getParameters().put('oppId', list_Opps[0].Id);
			Test.setCurrentPageReference(ref);

			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(new Transition_To_Fulfillment__c());
			CreateEditPayrollTransferTTFCtrl ctrl = new CreateEditPayrollTransferTTFCtrl(stdCtrl);

			ctrl.ttfRecord.Previous_Payroll_Provider__c = 'Paychex';
			ctrl.ttfRecord.Contractors_paid_on_first_pay_date__c = 'No';
			ctrl.ttfRecord.Demo_Complete__c = 'Yes';
			ctrl.ttfRecord.Contact__c = objTestContact.Id;

			ctrl.ttfRecord.TTF_Status__c = 'Sales Submitted';

			ctrl.savePayrollTTF();
		}
		Test.stopTest();
		Id idFbos_RTId_Advocate = Cache.getRecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate');
		List<Payroll_Transfer_FBOS_Forecast__c> lst_ForeCasts = [
			SELECT Id, First_week_cap__c
			FROM Payroll_Transfer_FBOS_Forecast__c
			WHERE Year__c = '2022' AND Month__c = 'January' AND RecordTypeId = :idFbos_RTId_Advocate
		];
		List<Payroll_Transfer_FBOS_Forecast_Cap__mdt> lst_PayrollForecastCaps = [
			SELECT Id, Maximum_cap__c
			FROM Payroll_Transfer_FBOS_Forecast_Cap__mdt
			WHERE Owner_Division__c = 'Small Business'
		];
		Decimal decSmallBizCapacity = 0;
		decSmallBizCapacity = lst_PayrollForecastCaps.isEmpty() ? 0 : lst_PayrollForecastCaps[0].Maximum_cap__c / 100 * Integer.valueOf(lst_ForeCasts[0].First_week_cap__c);
		List<Transition_To_Fulfillment__c> list_TTF = [
			SELECT Id, TTF_Status__c, Direct_Deposit_Speed__c, Last_Expected_Pay_Date__c, Contractor_Payment_Method__c
			FROM Transition_To_Fulfillment__c
		];
		System.assert(list_TTF.size() > decSmallBizCapacity, 'TTF not created from reserve');
	}
}