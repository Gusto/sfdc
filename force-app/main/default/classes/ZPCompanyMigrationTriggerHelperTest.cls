/**
 * @name         : ZPCompanyMigrationTriggerHelperTest
 * @author       : Aurobind Ravichandran
 * @date         : 3/28/2017
 * @description  : Unit tests for ZPCompanyMigrationTriggerHelper
 * @test classes : NA
 **/
@isTest
public class ZPCompanyMigrationTriggerHelperTest {
	@testSetup
	static void setup() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		ZPCompanyMigrationTriggerHelper.queue = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Company')).setName('Test Company Acc').setZpCompanyId('11111111').build();
		insert objAccount;

		ContactTriggerHelper.skipTrigger = true;

		Contact objCompanyContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuserZPCompany@abccompany.com')
			.build();
		insert objCompanyContact;

		list<AccountContactRelation> list_objAccContactRelation = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :objAccount.Id LIMIT 1];
		list_objAccContactRelation.get(0).Roles = 'Payroll Admin';
		update list_objAccContactRelation;

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setName('Test Opportunity')
			.setAccountId(objAccount.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Company Opportunity'))
			.setStage('SAL')
			.setCloseDate(System.today())
			.setZPCompanyId(objAccount.ZP_Company_ID__c)
			.build();
		insert objOpportunity;

		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}

	@isTest
	static void testCreateNewCompanyMigration() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		Test.startTest();
		List<Account> list_Account = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		ZP_Company_Migration__c objZPCompanyMigration;
		String strPPPCollectionOption = 'upload';
		string strCovidValue = 'Test Covid 19';
		String strBenefit = 'medical, dental, vision';
		String strCommuterBenefit = 'commuter benefits';
		System.assert(list_Account.size() > 0);

		if (list_Account.size() > 0) {
			Account objAccount = list_Account.get(0);
			objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
				.setZPCompanyId(objAccount.ZP_Company_ID__c)
				.setMigrationId('12345')
				.setExternalKey('ZP_CM_12345')
				.setPreviousPayrollProviderCollectOption(strPPPCollectionOption)
				.setCOVID19ReliefPrograms(strCovidValue)
				.build();
			objZPCompanyMigration.Which_Health_Benefits_Currently_Offered__c = strBenefit;
			objZPCompanyMigration.Other_Health_Benefits_Currently_Offered__c = null;
			objZPCompanyMigration.Financial_Health_Benefits__c = strBenefit;
			objZPCompanyMigration.Transportation_Benefits__c = strCommuterBenefit;
			objZPCompanyMigration.Other_Financial_Benefits_Currently_Offer__c = null;
			objZPCompanyMigration.Custom_Deductions__c = null;

			insert objZPCompanyMigration;

			System.assertEquals(objZPCompanyMigration.Id__c, '12345');
		}

		Test.stopTest();

		list<Order> list_OrderRec = [SELECT Id, Financial_Health_Benefits__c,
		Transportation_Benefits__c,Previous_Payroll_Provider_Collect_Option__c, 
		COVID_19_relief_programs__c FROM Order LIMIT 1];
		System.assert(list_OrderRec.size() > 0);
		System.assert(list_OrderRec.get(0).Previous_Payroll_Provider_Collect_Option__c == strPPPCollectionOption);
		System.assert(list_OrderRec.get(0).COVID_19_relief_programs__c == strCovidValue);
		System.assert(list_OrderRec.get(0).Financial_Health_Benefits__c == strBenefit);
		System.assert(list_OrderRec.get(0).Transportation_Benefits__c == strCommuterBenefit);

		delete objZPCompanyMigration;
		undelete objZPCompanyMigration;
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}

	@isTest
	static void testCreateUpdateNewCompanyMigration() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		Test.startTest();
		list<Account> list_Account = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		ZP_Company_Migration__c objZPCompanyMigration;
		string strCovidValue = 'Test Covid 19';
		string strUpdatedCovidValue = 'Updated Test Covid 19';
		System.assert(list_Account.size() > 0);

		if (list_Account.size() > 0) {
			Account objAccount = list_Account.get(0);
			objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
				.setZPCompanyId(objAccount.ZP_Company_ID__c)
				.setMigrationId('123456')
				.setExternalKey('ZP_CM_123456')
				.setCOVID19ReliefPrograms(strCovidValue)
				.build();
			insert objZPCompanyMigration;

			objZPCompanyMigration.COVID_19_relief_programs__c = strUpdatedCovidValue;
			update objZPCompanyMigration;

			System.assertEquals(objZPCompanyMigration.Id__c, '123456');
		}
		Test.stopTest();

		list<Order> list_OrderRec = [SELECT Id, COVID_19_relief_programs__c FROM Order LIMIT 1];
		System.assert(list_OrderRec.size() > 0);
		System.assert(list_OrderRec.get(0).COVID_19_relief_programs__c == strUpdatedCovidValue);
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}

	@isTest
	static void testPayRollRunOrder() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		ZPCompanyMigrationTriggerHelper.queue = true;
		CaseTriggerHelper.skipTrigger = true;
		Test.startTest();
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		ZP_Company_Migration__c objZPCompanyMigration;
		String strDate = Date.today() + '';
		strDate = strDate.subString(0, 10);
		String strAdditionalDate =
			'{"industry_title":"Test industry","naics_code":"123","sic_codes":"456","cannot_find_industry":"true",' +
			'"custom_description":"Test Desc","first_name":null,"last_name":null,"email":null,"primary_contact_same_as_payroll_runner":"Yes",' +
			'"number_of_pay_schedules":"One","last_expected_pay_date":"' +
			strDate +
			'","direct_deposit_speed":"2-day",' +
			'"has_remote_employees":"No","registered_as_employer_in_work_states":"Not sure",' +
			'"employee_payment_method":"Direct Deposit and check","employees_with_multiple_tax_jurisdictions":"Yes",' +
			'"invite_employees_via_email":null,"invite_dismissed_employees_via_email":"Add and invite",' +
			'"pay_contractors_with_payroll_provider":"Yes","contractor_payment_method":"Direct deposit",' +
			'"pay_international_contractors":"Yes","contractor_countries":null,' +
			'"invite_contractors_via_email":null,"time_off_offered":"No",' +
			'"track_pto_policies":"No","new_health_benefits":"No"}';

		if (list_Accounts.size() > 0) {
			Account objAccount = list_Accounts.get(0);
			objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
				.setZPCompanyId(objAccount.ZP_Company_ID__c)
				.setMigrationId('123456')
				.setExternalKey('ZP_CM_123456')
				.setAdditionalData(strAdditionalDate)
				.build();
			insert objZPCompanyMigration;
		}

		list<Order> list_Orders = [SELECT Id, Status FROM Order LIMIT 1];
		if (list_Orders.size() > 0) {
			list_Orders[0].Status = 'Closed: Payroll Run';
			update list_Orders[0];

			objZPCompanyMigration.Deleted_At__c = System.today();
			update objZPCompanyMigration;
		}

		Test.stopTest();

		list_Orders = [SELECT Id, Status, Industry_Title__c, Last_Expected_Pay_Date__c, Contractor_Payment_Method__c FROM Order LIMIT 1];
		System.assert(list_Orders.size() > 0);
		System.assert(list_Orders.get(0).Status == 'Closed: Payroll Run');
		System.assert(list_Orders[0].Industry_Title__c == 'Test industry');
		System.assert(list_Orders[0].Last_Expected_Pay_Date__c == Date.today());
		System.assert(list_Orders[0].Contractor_Payment_Method__c == 'Direct Deposit');
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}

	@isTest
	static void testPayRollRunOrderNegativeCase() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		Test.startTest();
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		ZP_Company_Migration__c objZPCompanyMigration;

		if (list_Accounts.size() > 0) {
			Account objAccount = list_Accounts.get(0);

			objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
				.setZPCompanyId(objAccount.ZP_Company_ID__c)
				.setMigrationId('123456')
				.setExternalKey('ZP_CM_12345')
				.setAdditionalData('')
				.build();
			insert objZPCompanyMigration;

			objZPCompanyMigration.Deleted_At__c = System.today();
			update objZPCompanyMigration;
		}

		Test.stopTest();

		List<Order> list_Orders = [SELECT Id, Status, Industry_Title__c FROM Order LIMIT 1];
		System.assert(list_Orders.size() > 0);
		System.assert(list_Orders.get(0).Status == 'Closed: Canceled');
		System.assert(String.isBlank(list_Orders[0].Industry_Title__c));
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}
	/**
	 * @Author      : Sanjay Paryani
	 * @Description : validate Order end date cannot go beyond start date method
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testPayRollRunOrderBeyondEndDate() {
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(true);
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
		PriceBook2 objPriceBook = new TestDataFactory.PriceBookBuilder().setName(objTierConfig.New_Price_1__c).setActive().build();
		insert objPriceBook;
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];

		Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(list_Accounts[0].Id)
			.setStage('SAL')
			.setPriceBookId(objPriceBook.Id)
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.build();
		insert objOpportunity;

		Order objOrder = new TestDataFactory.OrderBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setOpportunityId(objOpportunity.Id)
			.setRecordTypeId(Cache.getRecordTypeId('Order', 'Company Migration'))
			.setStatus('Drafted')
			.setOwnerId(UserInfo.getUserId())
			.build();
		objOrder.Active_Employee_Count__c = 10;
		objOrder.EffectiveDate = System.today().addDays(-5);
		objOrder.Payroll_Run_Date__c = system.today();
		objOrder.First_Check_Date__c = system.today();
		objOrder.EndDate = system.today().addDays(-1);
		objOrder.External_Key__c = 'zenpayroll-company_migration-12345';
		upsert objOrder;

		Test.startTest();
		ZP_Company_Migration__c objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
			.setZPCompanyId(list_Accounts[0].ZP_Company_ID__c)
			.setMigrationId('12345')
			.setExternalKey('zenpayroll-company_migration-12345')
			.setAdditionalData('')
			.build();
		upsert objZPCompanyMigration;

		Test.stopTest();

		List<Order> list_Orders = [SELECT Id, Status, Industry_Title__c FROM Order LIMIT 1];
		List<ZP_Company_Migration__c> list_ZPCMs = [SELECT Id, Processing_State__c FROM ZP_Company_Migration__c];
		System.assert(list_Orders.size() > 0);
		System.assert(list_ZPCMs.size() > 0);
		ZPCompanyMigrationTriggerHelperTest.skipTrigger(false);
	}

	@isTest
	static void testZPCompanyMigrationCoverHandlerEx() {
		ZPCompanyMigrationTriggerHandler.resetSkipTriggerFlags();
		Test.startTest();
		ZPCompanyMigrationTriggerHandler.blnTestException = true;
		List<Account> list_Accounts = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
		ZP_Company_Migration__c objZPCompanyMigration;

		if (list_Accounts.size() > 0) {
			Account objAccount = list_Accounts.get(0);
			objZPCompanyMigration = new TestDataFactory.ZPCompanyMigrationBuilder()
				.setZPCompanyId(objAccount.ZP_Company_ID__c)
				.setMigrationId('123456')
				.setExternalKey('ZP_CM_12345')
				.setAdditionalData('')
				.build();
			insert objZPCompanyMigration;

			objZPCompanyMigration.Deleted_At__c = System.today();
			update objZPCompanyMigration;
		}
		Test.stopTest();
	}

	//This method skip required triggers.
	public static void skipTrigger(Boolean blnFlag) {
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
	}
}