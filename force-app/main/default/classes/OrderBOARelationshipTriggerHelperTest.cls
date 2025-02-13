@isTest
public class OrderBOARelationshipTriggerHelperTest {
	@TestSetup
	static void setupData() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		list<Profile> lst_userProfiles = [SELECT Id FROM Profile WHERE Name = 'Direct Sales User'];

		//========User Creation=================
		User objAdminUser = new TestDataFactory.UserBuilder()
			.setUserName('Implementation.Advocate1@test.Implementation')
			.setExemptfromValidationRules(true)
			.setOOO(false)
			.setBackInOfficeDateTime(System.now())
			.setIsActive(true)
			.setProfileId(lst_userProfiles.get(0).Id)
			.setEmail('Implementation.Advocate1@test.Implementation')
			.build();
		insert objAdminUser;

		Role__c roleObj = new Role__c();
		roleObj.Name = 'Payroll Transfer Advocate';
		insert roleObj;

		User_Role__c userRoleObj = new User_Role__c();
		userRoleObj.User__c = objAdminUser.Id;
		insert userRoleObj;

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

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('1234567890')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		insert objCompanyAccount;

		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objCompanyAccount.Id)
			.setFirstName('fName')
			.setLastName('lName')
			.setEmail('testAddress@domain.com')
			.build();
		insert objCompanyContact;

		list<Opportunity> testOpportunities = new List<Opportunity>();
		Opportunity opp1 = new Opportunity(
			AccountId = objCompanyAccount.id,
			Pricebook2Id = bk.id,
			name = 'TestOpp',
			StageName = 'SAL',
			closedate = system.today(),
			NumberOfEmployees__c = 12,
			HI_Effective_Date__c = system.today().addDays(30)
		);
		//opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp1.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		insert opp1;

		Transition_to_Fulfillment__c rec = new Transition_to_Fulfillment__c(
			Bulk_Deal__c = 'N',
			Demo_Complete__c = 'No',
			Exception_Request__c = 'No',
			Contact__c = objCompanyContact.Id,
			Physical_address_accurate__c = 'N',
			Of_hours_for_EE_to_be_eligible__c = '222',
			Out_of_State_Employees_States__c = 'N',
			Quoting_Address__c = 'test',
			Opportunity__c = opp1.Id,
			Account__c = opp1.AccountId
		);

		rec.Reason_for_exception_request__c = 'Contract ending with current payroll provider';
		rec.Previous_Payroll_Provider__c = 'Other';
		rec.Contractors_paid_on_first_pay_date__c = 'No';
		rec.RecordTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Payroll Transfer');
		TransitiontoFulfilmentTriggerHelper.skipTrigger = true;
		insert rec;

		list<Group> list_Queue = [SELECT Id, Name FROM GROUP WHERE Type = 'Queue' AND Name = 'Company Migration - Unassigned Orders'];

		Order ord = new Order(
			AccountId = objCompanyAccount.id,
			Status = 'Drafted',
			First_Check_Date__c = date.newInstance(2019, 10, 1),
			EffectiveDate = date.newInstance(2019, 9, 28),
			Transition_to_Fulfillment__c = rec.id,
			RecordTypeId = Cache.getRecordTypeId('Order', 'Company Migration'),
			OwnerId = list_Queue.get(0).id,
			Active_Employee_Count__c = 10,
			Contractor_Count__c = 2,
			Inactive_Employee_Count__c = 5,
			States__c = 'CA'
		);

		insert ord;

		Payroll_Transfer_FBOS_Forecast__c ptfForecast1 = new Payroll_Transfer_FBOS_Forecast__c(
			FBOS_Forecast__c = 1200,
			Fifth_Week_Cap__c = 295,
			First_week_cap__c = 285,
			Forecast_Multiplier__c = 100,
			Fourth_Week_Cap__c = 285,
			Month__c = 'October',
			Second_week_cap__c = 285,
			Third_week_cap__c = 285,
			Year__c = '2019',
			RecordTypeId = cache.getrecordTypeId('Payroll_Transfer_FBOS_Forecast__c', 'Advocate')
		);

		insert ptfForecast1;

		Benefit_Order_Allocation__c benOrdAlloc = new Benefit_Order_Allocation__c(
			Max_BO__c = 285,
			Month__c = 10,
			Role_Type__c = 'Advocate',
			Week_End_Date__c = Date.newInstance(2019, 10, 4),
			Week_Order_Capacity__c = 12,
			Week_Start_Date__c = Date.newInstance(2019, 10, 1),
			User_Role__c = userRoleObj.id,
			User__c = objAdminUser.Id,
			Working_days__c = 5,
			Payroll_Transfer_FBOS_Forecast__c = ptfForecast1.id,
			Year__c = 2019
		);
		insert benOrdAlloc;
	}

	@isTest
	static void insertRecordTestMethod() {
		list<Order> lst_orders = [SELECT id FROM Order];
		list<Benefit_Order_Allocation__c> lst_boas = [SELECT id FROM Benefit_Order_Allocation__c];

		if (lst_boas.size() > 0 && lst_orders.size() > 0) {
			insert new Order_BOA_Relationship__c(Orders__c = lst_orders.get(0).Id, Benefit_Order_Allocation__c = lst_boas.get(0).id);
		}
	}
}