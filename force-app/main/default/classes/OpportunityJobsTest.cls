/**
 * @name         : OpportunityJobsTest
 * @author       : Prashant Bhatt
 * @date         : 03-17-2021
 * @description  : Test class for OpportunityJobs
 **/

@isTest
public class OpportunityJobsTest {
	@isTest
	public static void testBenefitsOptOutSyncOnOpportunityPositive() {
		List<Account> list_Accounts = new List<Account>();

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setZPCompanyId('1234567890')
			 .build(); 
		list_Accounts.add(objCompanyAccount);

		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			 .setZPFirmId('7777789')
			 .setBenefitsEmailOptOut('Health Insurance')
			 .build();
		list_Accounts.add(objResellerAccount);

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
			 .setAccountId(objCompanyAccount.Id)
			 .setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			 .setName('GUSTO-TESTOPP')
			 .setStage('Qualified')
			 .setCloseDate(System.today())
			 .setSoldBy(objResellerAccount.Id)
			 .build();
		OpportunityTriggerHelper.skipTrigger = true;
		insert objCompanyOpp;

		Test.startTest();
		objResellerAccount.Apply_to_all_clients__c = true;
		objResellerAccount.Benefits_Email_Opt_Out__c = 'Health Insurance;Workers Comp';
		update objResellerAccount;

		Database.executeBatch(new OpportunityJobs(''));
		Test.stopTest();

		objCompanyOpp = [SELECT Id, Benefits_Opt_Out__c FROM Opportunity WHERE Id = :objCompanyOpp.Id];
		System.assertEquals(objCompanyOpp.Benefits_Opt_Out__c, 'Health Insurance;Workers Comp');

		objResellerAccount = [SELECT Id, Benefit_Opt_Out_Sync__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(objResellerAccount.Benefit_Opt_Out_Sync__c, false);
	}

	@isTest
	public static void testBenefitsOptOutSyncOnOpportunityNegative() {
		List<Account> list_Accounts = new List<Account>();

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setZPCompanyId('1234567890')
			 .build();
		list_Accounts.add(objCompanyAccount);

		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			 .setZPFirmId('7777789')
			 .setBenefitsEmailOptOut('Health Insurance')
			 .build();
		list_Accounts.add(objResellerAccount);

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
			 .setAccountId(objCompanyAccount.Id)
			 .setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			 .setName('GUSTO-TESTOPP')
			 .setStage('Qualified')
			 .setCloseDate(System.today())
			 .setSoldBy(objResellerAccount.Id)
			 .build();
		OpportunityTriggerHelper.skipTrigger = true;
		insert objCompanyOpp;

		Test.startTest();
		objResellerAccount.Apply_to_all_clients__c = true;
		update objResellerAccount;

		Database.executeBatch(new OpportunityJobs(''));
		Test.stopTest();

		objCompanyOpp = [SELECT Id, Benefits_Opt_Out__c FROM Opportunity WHERE Id = :objCompanyOpp.Id];
		System.assertEquals(objCompanyOpp.Benefits_Opt_Out__c, null);

		objResellerAccount = [SELECT Id, Benefit_Opt_Out_Sync__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(objResellerAccount.Benefit_Opt_Out_Sync__c, false);
	}

	@isTest
	static void testBenefitsOptOutSyncOnOpportunityPositiveScheduled() {
		List<Account> list_Accounts = new List<Account>();

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId('Company')
			 .setZPCompanyId('1234567890')
			 .build();
		list_Accounts.add(objCompanyAccount);

		Account objResellerAccount = new TestDataFactory.AccountBuilder()
			 .setName('name')
			 .setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID)
			 .setZPFirmId('7777789')
			 .setBenefitsEmailOptOut('Health Insurance')
			 .build();
		list_Accounts.add(objResellerAccount);

		AccountTriggerHelper.skipTrigger = true;
		insert list_Accounts;
		AccountTriggerHelper.skipTrigger = false;

		Opportunity objCompanyOpp = new TestDataFactory.OpportunityBuilder()
			 .setAccountId(objCompanyAccount.Id)
			 .setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			 .setName('GUSTO-TESTOPP')
			 .setStage('Qualified')
			 .setCloseDate(System.today())
			 .setSoldBy(objResellerAccount.Id)
			 .build();
		OpportunityTriggerHelper.skipTrigger = true;
		insert objCompanyOpp;

		Test.startTest();
		objResellerAccount.Apply_to_all_clients__c = true;
		objResellerAccount.Benefits_Email_Opt_Out__c = 'Health Insurance;Workers Comp';
		update objResellerAccount;

		// Dynamically scheduling jobs for next year
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;
		OpportunityJobsScheduler objScheduler = new OpportunityJobsScheduler();
		String jobId = System.schedule('Test Benefits Opt Out Sync Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		objCompanyOpp = [SELECT Id, Benefits_Opt_Out__c FROM Opportunity WHERE Id = :objCompanyOpp.Id];
		System.assertEquals(objResellerAccount.Benefits_Email_Opt_Out__c, objCompanyOpp.Benefits_Opt_Out__c);

		objResellerAccount = [SELECT Id, Benefit_Opt_Out_Sync__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(objResellerAccount.Benefit_Opt_Out_Sync__c, false);
	}

	@isTest
	static void testTierUpsellClosedLostScheduled() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
		objTierConfig = Tier_Config__c.getOrgDefaults();
		setUpNewPrices(objTierConfig.New_Price_2__c, false);
		setUpNewPrices(objTierConfig.New_Price_1__c, false);
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setTierUpsellTimingSize(45).build();
		Integer intAge = objConfigSettings.CL_Tier_Upsell_Age__c != null && objConfigSettings.CL_Tier_Upsell_Age__c != 0 ? objConfigSettings.CL_Tier_Upsell_Age__c.intValue() : 45;
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account OHI')
			.setZPCompanyId('11123334')
			.setPricing(AccountUtil.SIMPLE_PAYMENT_PLAN)
			.setTier(AccountUtil.SIMPLE_TIER)
			.setNumberOfActiveEEs(8)
			.build();
		insert objAccount;
		TriggerHandler.clearAllBypasses();
		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID)
			.setName('APD Upsell Opportunity')
			.setAccountId(objAccount.Id)
			.setUpsellTier(AccountUtil.PLUS_TIER)
			.setStage('Qualified')
			.setType('Upsell')
			.build();
		objOpportunity.Current_Tier__c = AccountUtil.SIMPLE_TIER;
		insert objOpportunity;
		DateTime dtCLTime = Datetime.now().addDays(-47);
		Test.setCreatedDate(objOpportunity.Id, dtCLTime);
		Account objAssertAcc = [SELECT Id, Upsell_Opp_Open__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAssertAcc.Upsell_Opp_Open__c, true);

		Test.startTest();
		Database.executeBatch(new OpportunityJobs(''));
		Test.stopTest();

		Opportunity objAssertOpp = [SELECT Id, CloseDate, StageName, Stage_Detail__c FROM Opportunity WHERE Id = :objOpportunity.Id];
		objAssertAcc = [SELECT Id, Upsell_Opp_Open__c FROM Account WHERE Id = :objAccount.Id];
		System.assertEquals(objAssertOpp.StageName, 'Closed Lost');
		System.assertEquals(objAssertOpp.Stage_Detail__c, 'Timing');
		System.assertEquals(objAssertOpp.CloseDate, Date.today());
		System.assertEquals(objAssertAcc.Upsell_Opp_Open__c, false);
	}

	/**
	 * @description Setting up test data for creating pricebook and pricebook entries
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public static void setUpNewPrices(String strPriceName, Boolean blnPrioritySupport) {
		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		Pricebook2 objPriceBookOne = new TestDataFactory.PriceBookBuilder().setName(strPriceName).setActive().build();
		insert objPriceBookOne;

		// Create new products
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(TestUtility.createTestProduct('Company', 'Company', false));
		list_Products.add(TestUtility.createTestProduct('Active Employee', 'Employee', false));
		list_Products.add(TestUtility.createTestProduct('Contractor', 'Payroll', false));
		if (blnPrioritySupport) {
			list_Products.add(TestUtility.createTestProduct(OpportunityUtil.PRIORITY_SUPPORT_EMPLOYEE, 'Payroll', false));
			list_Products.add(TestUtility.createTestProduct(OpportunityUtil.PRIORITY_SUPPORT_CONTRACTOR, 'Payroll', false));
		}
		insert list_Products;

		// Create pricebook entries
		List<PricebookEntry> list_Entries = new List<PricebookEntry>();
		// create standard pricebook entries before creating custom ones
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, Test.getStandardPriceBookId(), false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, Test.getStandardPriceBookId(), false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, Test.getStandardPriceBookId(), false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, 5, Test.getStandardPriceBookId(), false));
		}

		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[0].Id, 5, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[1].Id, 5, objPriceBookOne.id, false));
		list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[2].Id, 5, objPriceBookOne.id, false));
		if (blnPrioritySupport) {
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[3].Id, 5, objPriceBookOne.id, false));
			list_Entries.add(TestUtility.createTestPriceBookEntry(list_Products[4].Id, 5, objPriceBookOne.id, false));
		}

		insert list_Entries;
	}
}