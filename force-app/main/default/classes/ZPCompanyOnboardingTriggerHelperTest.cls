/**
Created by : Aurobind Ravichandran
Created Date : 3/28/2017 
**/
@isTest
public class ZPCompanyOnboardingTriggerHelperTest {
	@testSetup
	static void setUp() {

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Company')
			.setRecordTypeId('Company')
			.setZPCompanyId('11111111111111')
			.build();

		insert objAccount;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setZPCompanyID('11111111111111')
			.setZPCompanyLeadID('222222222222')
			.setCompany('Test Company')
			.setFirstName('Test')
			.setLastName('Lead')
			.setRecordTypeId(Cache.getRecordTypeId('Lead', 'Company'))
			.build();

		insert objLead;

		Contact objCntct = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setAccountId(objAccount.Id)
			.setEmail('ZPComapnyFunnel@domain.com')
			.setFirstName('fName')
			.setLastName('ZPFunnelLName')
			.build();
			
		insert objCntct;

		//=================opp - acc=================
		PriceBook2 bk = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true);
		insert bk;

		List<Product2> prodList = new List<Product2>();
		prodList.add(TestUtility.createTestProduct('Medical', 'Benefit', false));
		prodList.add(TestUtility.createTestProduct('Dental', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Vision', 'Employee', false));
		prodList.add(TestUtility.createTestProduct('Life', 'Employee', false));
		insert prodList;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[0].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[1].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[2].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[3].Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[0].Id, 5, bk.id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[1].Id, 5, bk.id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[2].Id, 5, bk.id, false));
		pbeList.add(TestUtility.createTestPriceBookEntry(prodList[3].Id, 5, bk.id, false));
		insert pbeList;

		list<Opportunity> testOpportunities = new List<Opportunity>();
		Opportunity opp1 = new Opportunity(
			AccountId = objAccount.id,
			Pricebook2Id = bk.id,
			name = 'TestOpp',
			StageName = 'SAL',
			Is_Historical__c = true,
			closedate = system.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = system.today().addDays(30)
		);
		//opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp1.RecordTypeId = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		testOpportunities.add(opp1);

		OpportunityTriggerHelper.skipTrigger = true;
		insert testOpportunities;

		List<Transition_to_Fulfillment__c> lst_transitionRecords = new List<Transition_to_Fulfillment__c>();
		Transition_to_Fulfillment__c rec = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'N',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = objCntct.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test1',
			Opportunity__c = testOpportunities[0].Id,
			Account__c = testOpportunities[0].AccountId
		);

		rec.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec.Previous_Payroll_Provider__c = 'Other';
		rec.Contractors_paid_on_first_pay_date__c = 'No';
		rec.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		lst_transitionRecords.add(rec);

		insert lst_transitionRecords;

		list<Group> lst_queue = [SELECT id, Name FROM GROUP WHERE Type = 'Queue' AND Name = 'Company Migration - Unassigned Orders'];

		list<Order> lst_toInsertOrder = new List<Order>();
		Order ord = new Order(
			AccountId = objAccount.id,
			Status = 'Onboarding Steps 1 - 6',
			First_Check_Date__c = date.newInstance(2019, 10, 1),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec.id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = lst_queue.get(0).id,
			Active_Employee_Count__c = 10,
			Contractor_Count__c = 2,
			Inactive_Employee_Count__c = 5,
			States__c = 'CA',
			Assign_Facilitator__c = false,
			Facilitator_Due_Date__c = date.newInstance(2019, 10, 3),
			OpportunityId = opp1.Id
		);
		lst_toInsertOrder.add(ord);

		OrderTriggerHelper.skipTrigger = true;
		insert lst_toInsertOrder;
		OrderTriggerHelper.skipTrigger = false;

		Id idBenefitsMasterChk = Cache.getRecordTypeId('BOR_Master_Checklist__c', 'Payroll');

		List<BOR_Master_Checklist__c> masterCheckList = new List<BOR_Master_Checklist__c>();
		BOR_Master_Checklist__c checkList1 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist1.BOR_Checklist_Name__c = '* Added Employees';
		checklist1.Sequence__c = 1;
		checklist1.Mandatory__c = true;
		checklist1.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist1);
		BOR_Master_Checklist__c checkList2 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist2.BOR_Checklist_Name__c = '* Added Historical Payrolls + QA\'d';
		checklist2.Sequence__c = 2;
		checklist2.Mandatory__c = true;
		checklist2.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist2);
		BOR_Master_Checklist__c checkList3 = new BOR_Master_Checklist__c(RecordTypeId = idBenefitsMasterChk);
		checklist3.BOR_Checklist_Name__c = 'Test CheckList3';
		checklist3.Sequence__c = 3;
		checklist3.Mandatory__c = true;
		checklist3.BOR_Checklist_Status__c = 'Active';
		masterCheckList.add(checklist3);
		insert masterCheckList;

		Order_Facilitator_Checklist__c objOrderChecklist = new Order_Facilitator_Checklist__c(Order__c = ord.Id, Checklist_Name__c = '* Added Employees', Is_Checked__c = true, Sequence__c = 1);

		insert objOrderChecklist;
	}

	@isTest
	static void createNewCompanyWithExistingLeadWithfunnel() {
		ZPCompanyTriggerHelper.queue = true;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.company_id__c = '11111111111111';
		funnel.Add_Addresses_Completed__c = true;

		funnel.Sign__c = 'Test';
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		List<Opportunity> oppList = new List<Opportunity>([SELECT Id, ZP_Add_Company_Addresses__c, StageName FROM Opportunity WHERE Source_Id__c = '11111111111111']);
		System.assertEquals(oppList.size(), 0);
		test.startTest();
		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.setName('Test Company')
			.build();

		insert objZpCompany;

		oppList = new List<Opportunity>([SELECT Id, ZP_Add_Company_Addresses__c, StageName FROM Opportunity WHERE Source_Id__c = '11111111111111']);
		//System.assertEquals(oppList.size(), 1);
		//System.assertEquals(oppList[0].ZP_Add_Company_Addresses__c, true);

		funnel.Create_User_Account_Completed__c = true;
		funnel.Add_Employees_Completed__c = true;
		funnel.Federal_Tax_Setup_Completed__c = true;
		funnel.State_Setup_Completed__c = true;
		funnel.Add_Bank_Info_Completed__c = true;
		funnel.Payroll_Schedule_Completed__c = true;
		funnel.Previous_Paystubs_Completed__c = true;
		funnel.Sign_All_Forms_Completed__c = true;
		funnel.Add_Signatory_Completed__c = true;
		funnel.Verify_Bank_Info_Completed__c = true;

		update funnel;
		test.stopTest();
	}

	@isTest
	static void createNewFunnelWithClosedOpp() {
		ZPCompanyTriggerHelper.queue = true;
		ZPCompanyOnboardingFunnelTriggerHelper.queue = true;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.company_id__c = '11111111111111';
		funnel.Id__c = '949494';
		funnel.Sign__c = 'Test';
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;

		test.startTest();
		ZP_Company__c objZpCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState('Queued')
			.setCreatedAtDate(System.today())
			.setName('Test Company')
			.build();

		insert objZpCompany;

		List<Opportunity> oppList1 = new List<Opportunity>([SELECT id FROM Opportunity WHERE Source_Id__c = '11111111111111']);
		// System.assertEquals(oppList.size(), 1);
		// oppList[0].StageName = 'Closed Won';
		// update opp;

		funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.company_id__c = '11111111111111';
		funnel.Sign__c = 'Test';
		funnel.Id__c = '34343434';
		insert funnel;

		List<Opportunity> oppList = new List<Opportunity>([SELECT Id, ZP_Add_Company_Addresses__c, StageName FROM Opportunity WHERE Source_Id__c = '11111111111111']);
		// System.assertEquals(oppList.size(), 1);
		//System.assertEquals('Closed Won',oppList[0].StageName);

		delete funnel;
		test.stopTest();
	}
}