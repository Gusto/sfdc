/**
 * @description  Testing calculation of reseller metrics
 * @author       Praveen Sethu
 * @author       Ajay Krishna P U
 * @date         01-30-2023
 **/

@isTest
public with sharing class CalculateResellerMetricsBatchTest {
	private final static String COMPANY_1_ACCOUNT_REF = 'PP1-Company Account';
	private final static String COMPANY_2_ACCOUNT_REF = 'PP2-Company Account';
	private final static String RESELLER_1_ACCOUNT_REF = 'PP1-Reseller Account';
	private final static String RESELLER_2_ACCOUNT_REF = 'PP2-Reseller Account';

	/**
	 * @description Test setup method to insert configurable batch size
	 * @author      Praveen Sethu
	 **/
	@TestSetup
	static void setup() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setResellerMetricsBatchSize(1).build();
		insert objConfigSettings;

		Account objCompanyAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(COMPANY_1_ACCOUNT_REF).build();
		Account objCompanyAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName(COMPANY_2_ACCOUNT_REF).build();
		Account objResellerAccount1 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName(RESELLER_1_ACCOUNT_REF).build();
		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName(RESELLER_2_ACCOUNT_REF).build();

		AccountTriggerHelper.skipTrigger = true;
		insert new List<Account>{ objCompanyAccount1, objCompanyAccount2, objResellerAccount1, objResellerAccount2 };
		AccountTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description Test if open opportunity metrics are calculated on resller account.
	 * @author      Praveen Sethu
	 **/
	@isTest
	private static void testOpenOpptyMetricsOnInsert() {
		AccountTriggerHelper.skipTrigger = true;

		// Insert reseller account and company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').build();

		insert new List<Account>{ objCompanyAccount, objResellerAccount };

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Acquisition Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.setSoldBy(objResellerAccount.Id)
			.setReferredBy(objResellerAccount.Id)
			.build();
		insert objOppty;

		Account objResellerAccountAssert = [SELECT Id, Calculate_Reseller_Metrics__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(true, objResellerAccountAssert.Calculate_Reseller_Metrics__c);

		Test.startTest();
		CalculateResellerMetricsScheduler clsScehule = new CalculateResellerMetricsScheduler();
		clsScehule.execute(null);
		Test.stopTest();

		// test if calculate metrics flag is set to false and metrics is calculate
		objResellerAccountAssert = [
			SELECT Id, Calculate_Reseller_Metrics__c, First_Client_Create_Date__c, Number_Of_Open_Payroll_Opps_Sold_By__c, Number_Of_Open_Payroll_Opps_Referred_By__c
			FROM Account
			WHERE Id = :objResellerAccount.Id
		];
		System.assertEquals(false, objResellerAccountAssert.Calculate_Reseller_Metrics__c);
		System.assertEquals(1, objResellerAccountAssert.Number_Of_Open_Payroll_Opps_Sold_By__c);
		System.assertEquals(1, objResellerAccountAssert.Number_Of_Open_Payroll_Opps_Referred_By__c);
		System.assertEquals(Date.today(), objResellerAccountAssert.First_Client_Create_Date__c);
	}

	/**
	 * @description Test if closed opportunity metrics are calculated on resller account
	 * @author      Praveen Sethu
	 **/
	@isTest
	private static void testClosedOpptyMetricsOnUpdate() {
		AccountTriggerHelper.skipTrigger = true;

		// Insert reseller account and company account
		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_RT_ID).setName('Reseller Account').build();

		insert new List<Account>{ objCompanyAccount, objResellerAccount };

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Acquisition Opportunity')
			.setAccountId(objCompanyAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		// move opportunity to closed won
		objOppty.StageName = OpportunityUtil.CLOSED_WON_STAGE;
		objOppty.Sold_By__c = objResellerAccount.Id;
		objOppty.Referred_By__c = objResellerAccount.Id;

		update objOppty;

		Account objResellerAccountAssert = [SELECT Id, Calculate_Reseller_Metrics__c FROM Account WHERE Id = :objResellerAccount.Id];
		System.assertEquals(true, objResellerAccountAssert.Calculate_Reseller_Metrics__c);

		Test.startTest();

		CalculateResellerMetricsScheduler clsScehule = new CalculateResellerMetricsScheduler();
		clsScehule.execute(null);

		Test.stopTest();

		// test if calculate metrics flag is set to false and metrics is calculate
		objResellerAccountAssert = [
			SELECT Id, Calculate_Reseller_Metrics__c, First_Client_Create_Date__c, NumberOf_Closed_Payroll_Opps_Sold_By__c, NumberOf_Closed_Payroll_Opps_Referred_By__c
			FROM Account
			WHERE Id = :objResellerAccount.Id
		];
		System.assertEquals(false, objResellerAccountAssert.Calculate_Reseller_Metrics__c);
		System.assertEquals(1, objResellerAccountAssert.NumberOf_Closed_Payroll_Opps_Sold_By__c);
		System.assertEquals(1, objResellerAccountAssert.NumberOf_Closed_Payroll_Opps_Sold_By__c);
		System.assertEquals(Date.today(), objResellerAccountAssert.First_Client_Create_Date__c);
	}

	/**
	 * @description Test Firm MRR Recalculation, When Partner Program Changes
	 * @see PartnerProgramCompanyTriggerHelperTest for detailed Tracker testing.
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testRecalculateFirmMRRPartnerProgramChange() {
		Map<String, Account> map_NameToAccount = getAccountMap();

		//1. Create Partner Programs
		Partner_Program_Company_Data__c objPartnerProgram1 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Partner_Program_Company_Data__c objPartnerProgram2 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id)
			.build();
		insert new List<Partner_Program_Company_Data__c>{ objPartnerProgram1, objPartnerProgram2 };

		//3. Forcefully Update Current_MRR__c for accurate testing
		Account objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		Account objCompany2 = map_NameToAccount.get(COMPANY_2_ACCOUNT_REF);
		objCompany1.Current_MRR__c = 50;
		objCompany2.Current_MRR__c = 60;

		AccountTriggerHelper.skipTrigger = true;
		update new List<Account>{ objCompany1, objCompany2 };
		AccountTriggerHelper.skipTrigger = false;

		//4. Trigger the batch to recalculate Firm_MRR__c
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//5. Verify Firm_MRR__c updation
		Account objReseller = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(objReseller.Firm_MRR__c == 50 + 60, 'Firm MRR calculation failed');
		System.assert(objReseller.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset');
	}

	/**
	 * @description Test Firm MRR Recalculation, When Related Account Changes
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testRecalculateFirmMRRAccountChange() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		updateBatchSize(5);

		//1. Create Partner Programs
		Partner_Program_Company_Data__c objPartnerProgram1 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Partner_Program_Company_Data__c objPartnerProgram2 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id)
			.build();
		insert new List<Partner_Program_Company_Data__c>{ objPartnerProgram1, objPartnerProgram2 };

		//2. Reset Reseller Tracking to avoid calculation from reseller
		Account objReseller = map_NameToAccount.get(RESELLER_1_ACCOUNT_REF);
		objReseller.Recalculate_Metrics_Tracker__c = null;
		update objReseller;

		//3. Forcefully Update Current_MRR__c  and Tracker
		Account objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		Account objCompany2 = map_NameToAccount.get(COMPANY_2_ACCOUNT_REF);

		objCompany1.Current_MRR__c = 50;
		objCompany1.Recalculate_Metrics_Tracker__c = AccountUtil.TRACKER_FIRM_MRR;
		objCompany2.Current_MRR__c = 60;
		objCompany2.Recalculate_Metrics_Tracker__c = AccountUtil.TRACKER_FIRM_MRR;

		AccountTriggerHelper.skipTrigger = true;
		update new List<Account>{ objCompany1, objCompany2 };
		AccountTriggerHelper.skipTrigger = false;

		//4. Trigger the batch to recalculate Firm_MRR__c
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//5. Verify Firm_MRR__c updation & Tracker
		map_NameToAccount = getAccountMap();

		objReseller = map_NameToAccount.get(RESELLER_1_ACCOUNT_REF);
		System.assert(objReseller.Firm_MRR__c == 50 + 60, 'Firm MRR calculation failed');
		System.assert(objReseller.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Reseller');

		objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		System.assert(objCompany1.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Company 1');

		objCompany2 = map_NameToAccount.get(COMPANY_2_ACCOUNT_REF);
		System.assert(objCompany2.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Company 2');
	}

	/**
	 * @description Test Firm MRR Recalculation, When Reseller have no Partner Program
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testRecalculateFirmMRRWithNoPartnerProgram() {
		Map<String, Account> map_NameToAccount = getAccountMap();

		//1. Set the tracker to initiate recalculation
		Account objReseller = map_NameToAccount.get(RESELLER_2_ACCOUNT_REF);
		objReseller.Recalculate_Metrics_Tracker__c = AccountUtil.TRACKER_FIRM_MRR;
		update objReseller;

		//2. Trigger the batch to recalculate Firm_MRR__c
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//3. Verify Firm_MRR__c updation & Tracker
		objReseller = queryAccount(map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id);
		System.assert(objReseller.Firm_MRR__c == 0, 'Firm MRR calculation failed');
		System.assert(objReseller.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Reseller');
	}

	/**
	 * @description Test Firm MRR Recalculation, When Client got Deactivated
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testRecalculateFirmMRRClientDeactivated() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		updateBatchSize(5);

		//1. Create Partner Programs
		Partner_Program_Company_Data__c objPartnerProgram1 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Partner_Program_Company_Data__c objPartnerProgram2 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id)
			.build();
		insert new List<Partner_Program_Company_Data__c>{ objPartnerProgram1, objPartnerProgram2 };

		//2. Update Company - 1 to Suspend
		Account objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		objCompany1.ZP_Company_Suspension_Date__c = Date.today();
		update objCompany1;

		//3. Update Partner Program - 2 to Deactivate
		objPartnerProgram2.Deleted_At__c = Date.today();
		update objPartnerProgram2;

		//4. Trigger the batch to recalculate Firm_MRR__c
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//5. Verify Firm_MRR__c updation & Tracker
		map_NameToAccount = getAccountMap();

		Account objReseller = map_NameToAccount.get(RESELLER_2_ACCOUNT_REF);
		System.assert(objReseller.Firm_MRR__c == 0, 'Firm MRR calculation failed');
		System.assert(objReseller.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Reseller');

		objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		System.assert(objCompany1.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Company 1');
	}

	/**
	 * @description Test Active Clients & Client Book calculation
	 * The test create Partner Program which would lead a change in Active Clients & Client Book
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testCalculateNoOfClients() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		updateBatchSize(5);

		//1. Create Partner Programs
		Partner_Program_Company_Data__c objPartnerProgram1 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Partner_Program_Company_Data__c objPartnerProgram2 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id)
			.build();
		insert new List<Partner_Program_Company_Data__c>{ objPartnerProgram1, objPartnerProgram2 };

		//2. Trigger the batch to recalculate Active and Total Clients
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//3. Verify
		Account objReseller = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);
		System.assert(objReseller.Active_Clients__c == 2, 'Active Clients calculation failed');
		System.assert(objReseller.Client_Book_Size__c == 2, 'Client Book/ All Clients calculation failed');
	}

	/**
	 * @description Test Active Clients & Client Book calculation on Deactivation
	 * The test update a Client to suspend it, which would lead a change in Active Clients
	 * +  The test update a Partner Program to deactivate it, which would lead a change in Active Clients
	 * @author Ajay Krishna P U
	 */
	@isTest
	static void testCalculateNoOfClientsOnDeactivation() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		updateBatchSize(5);

		//1. Create Partner Programs
		Partner_Program_Company_Data__c objPartnerProgram1 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_1_ACCOUNT_REF).Id)
			.build();

		Partner_Program_Company_Data__c objPartnerProgram2 = new TestDataFactory.PartnerProgramCompanyDataBuilder()
			.setManagingAccountFirm(map_NameToAccount.get(RESELLER_2_ACCOUNT_REF).Id)
			.setAccount(map_NameToAccount.get(COMPANY_2_ACCOUNT_REF).Id)
			.build();
		insert new List<Partner_Program_Company_Data__c>{ objPartnerProgram1, objPartnerProgram2 };

		//2. Update Company - 1 to Suspend --> RESELLER_1_ACCOUNT_REF to change
		Account objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		objCompany1.ZP_Company_Suspension_Date__c = Date.today();
		update objCompany1;

		//3. Update Partner Program - 2 to Deactivate --> RESELLER_2_ACCOUNT_REF change
		objPartnerProgram2.Deleted_At__c = Date.today();
		update objPartnerProgram2;

		//4. Trigger the batch to recalculate No.of Clients
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();

		//5. Verify No.of Clients updation & Tracker
		map_NameToAccount = getAccountMap();

		Account objReseller1 = map_NameToAccount.get(RESELLER_2_ACCOUNT_REF);
		objCompany1 = map_NameToAccount.get(COMPANY_1_ACCOUNT_REF);
		System.assert(objReseller1.Active_Clients__c == 0, 'Active client calculation failed - Reseller 1');
		System.assert(objReseller1.Client_Book_Size__c == 1, 'Client Book/ Total No.Of Clients calculation failed - Reseller 1');
		System.assert(objCompany1.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Company 1');
		System.assert(objReseller1.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Reseller 1');

		Account objReseller2 = map_NameToAccount.get(RESELLER_2_ACCOUNT_REF);
		System.assert(objReseller2.Active_Clients__c == 0, 'Active client calculation failed - Reseller 2');
		System.assert(objReseller2.Client_Book_Size__c == 1, 'Client Book/ Total No.Of Clients calculation failed - Reseller 2');
		System.assert(objReseller2.Recalculate_Metrics_Tracker__c == null, 'Recalculation Tracker did not reset - Reseller 2');
	}

	/**
	 * @description Test Sales Engagement Status Update when No of Clients = 0
	 * @author Prity Kumari
	 */
	@isTest
	static void testSalesEnagagementStatusUpdate() {
		Map<String, Account> map_NameToAccount = getAccountMap();
		updateBatchSize(5);

		Account objReseller = map_NameToAccount.get(RESELLER_1_ACCOUNT_REF);
		objReseller.Sales_Engagement_Status__c = 'Active';
		objReseller.Recalculate_Metrics_Tracker__c = Utils.addToMultiPicklistValue(objReseller.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR);
		update objReseller;
		//2. Trigger the batch to recalculate Active and Total Clients
		Test.startTest();
		CalculateResellerMetricsScheduler objScheduler = new CalculateResellerMetricsScheduler();
		objScheduler.execute(null);
		Test.stopTest();
		//3. Verify
		Account objResellerAssert = queryAccount(map_NameToAccount.get(RESELLER_1_ACCOUNT_REF).Id);

		System.assertEquals(objResellerAssert.Sales_Engagement_Status__c, 'Churned', 'Sales Engagement Status is not set correctly');
	}

	/**
	 * @description Get Name --> Account map set by test setup
	 * @author Ajay Krishna P U
	 * @return      `Map<String, Account>`
	 */
	static Map<String, Account> getAccountMap() {
		Map<String, Account> map_NameToAccount = new Map<String, Account>();
		List<String> list_AccountNames = new List<String>{ COMPANY_1_ACCOUNT_REF, COMPANY_2_ACCOUNT_REF, RESELLER_1_ACCOUNT_REF, RESELLER_2_ACCOUNT_REF };
		for (Account objAccount : [
			SELECT Id, Name, Recalculate_Metrics_Tracker__c, Current_MRR__c, Firm_MRR__c, Active_Clients__c, Client_Book_Size__c, No_of_Clients__c
			FROM Account
			WHERE Name IN :list_AccountNames
		]) {
			map_NameToAccount.put(objAccount.Name, objAccount);
		}

		return map_NameToAccount;
	}

	/**
	 * @description	Query Account by Id
	 * @author Ajay Krishna P U
	 * @param idAccount Id of the account to be queried
	 * @return          `Account`
	 */
	static Account queryAccount(Id idAccount) {
		List<Account> list_Accounts = [
			SELECT Id, Recalculate_Metrics_Tracker__c, Current_MRR__c, Firm_MRR__c, Active_Clients__c, Client_Book_Size__c, Sales_Engagement_Status__c, Sales_Engagement_Status_Detail__c
			FROM Account
			WHERE Id = :idAccount
		];
		System.assert(!list_Accounts.isEmpty(), 'Account Not found');

		return list_Accounts[0];
	}

	/**
	 * @description Update calculate Reseller Metrics Batch
	 * @author Ajay Krishna P U
	 * @param intBatchSize The batch size to be updated
	 */
	static void updateBatchSize(Integer intBatchSize) {
		List<Configuration_Settings__c> list_Config = [SELECT Id, Calculate_Reseller_Metrics_Batch__c FROM Configuration_Settings__c];
		for (Configuration_Settings__c config : list_Config) {
			config.Calculate_Reseller_Metrics_Batch__c = intBatchSize;
		}

		update list_Config;
	}
}