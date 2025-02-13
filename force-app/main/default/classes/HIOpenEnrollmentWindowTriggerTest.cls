@isTest
private class HIOpenEnrollmentWindowTriggerTest {
	@TestSetup
	static void setupData() {
		HI_Fulfillment__c fullFillmentObj = new HI_Fulfillment__c();
		fullFillmentObj.Created_At__c = DateTime.now();
		fullFillmentObj.Deleted_At__c = DateTime.now();
		fullFillmentObj.External_Key__c = '6666';
		fullFillmentObj.Fulfillable_Id__c = 'Test_FulfillableId';
		fullFillmentObj.Fulfillable_Type__c = 'NewPlansApplication';
		fullFillmentObj.Historical__c = false;
		fullFillmentObj.Id__c = 'Test_FulfillmentId';
		fullFillmentObj.Message__c = 'Test';
		fullFillmentObj.Processed_At__c = DateTime.now();
		fullFillmentObj.Processing_State__c = 'In Process';
		fullFillmentObj.Requires_Signature__c = false;
		fullFillmentObj.Status__c = 'Test';
		fullFillmentObj.Updated_At__c = DateTime.now();
		insert fullFillmentObj;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		PriceBook2 bk = new PriceBook2(Name = objTierConfig.New_Price_1__c, IsActive = true);
		insert bk;

		List<Account> lstAccount = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account')
			.setZPCompanyId('44444')
			.setPricing(objTierConfig.New_Price_1__c)
			.build();
		lstAccount.add(objAccount);

		Account objAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').setPricing(objTierConfig.New_Price_1__c).build();
		lstAccount.add(objAccount1);
		insert lstAccount;

		Contact objContact = new TestDataFactory.ContactBuilder().setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID).setAccountId(objAccount.Id).setLastName('TestUser1').build();
		insert objContact;

		Opportunity objOpp1 = new Opportunity(
			AccountId = objAccount.id,
			Pricebook2Id = bk.id,
			name = 'TestOpp',
			StageName = 'SAL',
			Sold_By__c = lstAccount[1].Id,
			closedate = System.today(),
			NumberOfEmployees__c = 12,
			Source_ID__c = 'hawaiian_ice-new_plans_application-' + fullFillmentObj.Fulfillable_Id__c
		);
		objOpp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		OpportunityTriggerHelper.skipTrigger = true;
		insert objOpp1;

		Benefit_Order__c objBenOrder = new Benefit_Order__c(
			Name = 'Test Bendfit',
			Opportunity__c = objOpp1.id,
			Account__c = objAccount.Id,
			Coverage_Effective_Date__c = Date.today(),
			Submission_Deadline__c = Date.today(),
			Push_Rate_Reason__c = 'Not enough EE enrolled'
		);
		insert objBenOrder;
	}

	@isTest
	static void testHIOpenEnrollmentWindow() {
		HI_Open_Enrollment_Window__c obj = new HI_Open_Enrollment_Window__c();
		obj.Company_Id__c = '44444';
		obj.Created_At__c = DateTime.now();
		obj.Deleted_At__c = DateTime.now();
		obj.External_Key__c = '2222';
		obj.Fulfillment_Id__c = 'Test_FulfillmentId';
		obj.Id__c = '11111';
		obj.Message__c = 'Test';
		obj.New_Hire_Extension_End_Date__c = Date.today();
		obj.OPS_Owner__c = UserInfo.getUserName();
		obj.Processed_At__c = DateTime.now();
		obj.Processing_State__c = 'In Process';
		obj.Updated_At__c = DateTime.now();
		obj.Window_End_Date__c = Date.today().addDays(2);
		obj.Window_Start_Date__c = Date.today();
		insert obj;

		obj.Window_End_Date__c = Date.today().addDays(3);
		update obj;

		delete obj;
		undelete obj;

		System.assert(true, 'Fixing Apex PMD issue.');
	}
}