/**
 * @name CustomerHealthTriggerHelperTest
 * @author David (Dato) Tsamalashvili
 * @since 02/13/2024
 * @desc test class for CustomerHealthTriggerHelper
 **/
@isTest
public class CustomerHealthTriggerHelperTest {
	@testSetup
	static void setupTestData() {
		//create company account
		List<Account> list_Accounts = new List<Account>();
		Account objAcc = new TestDataFactory.AccountBuilder().setName('name').setRecordTypeId('Company').setZPCompanyId('1234567890').build();
		list_Accounts.add(objAcc);

		Account objAcc1 = new TestDataFactory.AccountBuilder().setName('name-1').setRecordTypeId('Company').setZPCompanyId('1234567891').build();
		list_Accounts.add(objAcc1);

		insert list_Accounts;

		// Create Customer Success Opportunity
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Opportunity objCSOpp = new TestDataFactory.OpportunityBuilder()
			.setAccountId(list_Accounts[0].Id)
			.setName('Test Opp CS')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.CUSTOMER_SUCCESS_RT_ID)
			.setStage('New')
			.build();

		list_Opportunities.add(objCSOpp);

		Opportunity objCSOpp1 = new TestDataFactory.OpportunityBuilder()
			.setAccountId(list_Accounts[1].Id)
			.setName('Test Opp CS')
			.setCloseDate(System.today())
			.setRecordTypeId(OpportunityUtil.CUSTOMER_SUCCESS_RT_ID)
			.setStage('New')
			.build();

		list_Opportunities.add(objCSOpp1);

		insert list_Opportunities;
	}

	@isTest
	static void testCustomerHealthCreation() {
		Test.startTest();
		// Create Customer Health record
		Customer_Health__c objCustHealth = new TestDataFactory.CustomerHealthBuilder()
			.setCompanyId('1234567890')
			.setFirstRiskChurnFeature('pto_management_policies_attach')
			.setFirstProtectiveChurnFeature('next_day_payroll_attach')
			.setSecondRiskChurnFeature('number_of_payroll_employees')
			.setSecondProtectiveChurnFeature('pct_rttl_3mths_admins_logging_in')
			.setThirdRiskChurnFeature('ttl_plus_features_offer')
			.setThirdProtectiveChurnFeature('has_new_admin_last6mths_1.0')
			.setChurnRiskBucket('low churn risk')
			.setUpgradePropensity('medium upgrade propensity')
			.setHINPRank(0.5)
			.setChurnScore(0.2)
			.build();

		insert objCustHealth;

		Account objAcc = [SELECT Id, NP_Rank__c FROM Account WHERE ZP_Company_ID__c = :objCustHealth.Company_Id__c];

		System.assertEquals(objCustHealth.HI_NP_Rank__c, objAcc.NP_Rank__c, 'Account NP Rank was not updated correctly');
		Test.stopTest();
	}

	@isTest
	static void testCustomerHealthUpdate() {
		Test.startTest();
		// Create Customer Health record
		Customer_Health__c objCustHealth = new TestDataFactory.CustomerHealthBuilder()
			.setCompanyId('1234567890')
			.setFirstRiskChurnFeature('pto_management_policies_attach')
			.setFirstProtectiveChurnFeature('next_day_payroll_attach')
			.setSecondRiskChurnFeature('number_of_payroll_employees')
			.setSecondProtectiveChurnFeature('pct_rttl_3mths_admins_logging_in')
			.setThirdRiskChurnFeature('ttl_plus_features_offer')
			.setThirdProtectiveChurnFeature('has_new_admin_last6mths_1.0')
			.setChurnRiskBucket('low churn risk')
			.setUpgradePropensity('medium upgrade propensity')
			.setHINPRank(0.5)
			.setChurnScore(0.2)
			.setHealthScore(0.3)
			.build();

		insert objCustHealth;

		Account objAcc = [SELECT Id, NP_Rank__c,Customer_Health_Score__c,Churn_Risk__c,Upgrade_Propensity__c FROM Account WHERE ZP_Company_ID__c = :objCustHealth.Company_Id__c];
		System.assertEquals(objCustHealth.HI_NP_Rank__c, objAcc.NP_Rank__c, 'Account NP Rank was not updated correctly');
		System.assertEquals(objCustHealth.Health_Score__c, objAcc.Customer_Health_Score__c, 'Account Health Score was not updated correctly');
		System.assertEquals(objCustHealth.Churn_Risk_Bucket__c, objAcc.Churn_Risk__c, 'Account Churn Risk was not updated correctly');
		System.assertEquals(objCustHealth.Upgrade_Propensity__c, objAcc.Upgrade_Propensity__c, 'Account Upgrade Propensity was not updated correctly');

		objCustHealth.Company_Id__c = '1234567891';
		update objCustHealth;

		Account objAcc1 = [SELECT Id, NP_Rank__c FROM Account WHERE ZP_Company_ID__c = :objCustHealth.Company_Id__c];
		System.assertEquals(objCustHealth.HI_NP_Rank__c, objAcc.NP_Rank__c, 'Account NP Rank was not updated correctly');
		Test.stopTest();
	}

	@isTest
	static void testSkipTrigger() {
		Test.startTest();
		// Create Customer Health record
		Customer_Health__c objCustHealth = new TestDataFactory.CustomerHealthBuilder()
			.setCompanyId('1234567890')
			.setFirstRiskChurnFeature('pto_management_policies_attach')
			.setFirstProtectiveChurnFeature('next_day_payroll_attach')
			.setSecondRiskChurnFeature('number_of_payroll_employees')
			.setSecondProtectiveChurnFeature('pct_rttl_3mths_admins_logging_in')
			.setThirdRiskChurnFeature('ttl_plus_features_offer')
			.setThirdProtectiveChurnFeature('has_new_admin_last6mths_1.0')
			.setChurnRiskBucket('low churn risk')
			.setUpgradePropensity('medium upgrade propensity')
			.setHINPRank(0.5)
			.setChurnScore(0.2)
			.build();

		CustomerHealthTriggerHelper.skipTrigger = true;
		insert objCustHealth;

		Account objAcc1 = [SELECT Id, NP_Rank__c FROM Account WHERE ZP_Company_ID__c = :objCustHealth.Company_Id__c];
		System.assertEquals(null, objAcc1.NP_Rank__c, 'Account NP Rank was updated incorectly');

		CustomerHealthTriggerHandler.resetSkipTriggerFlags();
		Test.stopTest();
	}

	@isTest
	static void testErrorHandling() {
		Test.startTest();
		// Create Customer Health record
		Customer_Health__c objCustHealth = new TestDataFactory.CustomerHealthBuilder()
			.setCompanyId('1234567890')
			.setFirstRiskChurnFeature('pto_management_policies_attach')
			.setFirstProtectiveChurnFeature('next_day_payroll_attach')
			.setSecondRiskChurnFeature('number_of_payroll_employees')
			.setSecondProtectiveChurnFeature('pct_rttl_3mths_admins_logging_in')
			.setThirdRiskChurnFeature('ttl_plus_features_offer')
			.setThirdProtectiveChurnFeature('has_new_admin_last6mths_1.0')
			.setChurnRiskBucket('low churn risk')
			.setUpgradePropensity('medium upgrade propensity')
			.setHINPRank(0.5)
			.setChurnScore(0.2)
			.build();

		CustomerHealthTriggerHandler.blnTestException = true;
		insert objCustHealth;

		Account objAcc1 = [SELECT Id, NP_Rank__c FROM Account WHERE ZP_Company_ID__c = :objCustHealth.Company_Id__c];
		System.assertEquals(objCustHealth.HI_NP_Rank__c, objAcc1.NP_Rank__c, 'Account NP Rank was not updated correctly');

		update objCustHealth;
		Test.stopTest();
	}
}