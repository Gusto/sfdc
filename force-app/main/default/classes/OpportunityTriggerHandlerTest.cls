/**
 * Standalone test class for OpportunityTriggerHandler, as OpportunityTriggerHelperTest is too fragile at this time
 * @author David Schach
 * @since Jan 2022
 * @see OpportunityTriggerHandler
 */
@IsTest
private class OpportunityTriggerHandlerTest {
	/* @author        Praveen Sethu
	 * @description	  Setup method to insert tier config custom settings
	 * @param         void
	 * @return        void
	 **/
	@testSetup
	static void setup() {
		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;
	}

	@isTest
	static void testBypassTriggerSetting() {
		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		User adminUser = TestUserUtility.createAdminUser(false);
		User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		System.runAs(adminUser) {
			upsert new TriggerBypass__c(OpportunityTrigger__c = true);
		}

		System.runAs(currentUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			Account objCompanyAccount = new TestDataFactory.AccountBuilder()
				.setName('Gustomer')
				.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
				.setZPCompanyId('123456789')
				.setHIOwner(UserInfo.getUserId())
				.build();
			objCompanyAccount.Pricing__c = objTierConfig.New_Price_1__c;
			objCompanyAccount.Discount__c = 20;
			objCompanyAccount.Number_Of_Active_Employees__c = 10;
			insert objCompanyAccount;

			Test.startTest();
			Opportunity objAPDOppty = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setName('APD Account - Payroll')
				.setAccountId(objCompanyAccount.Id)
				.setStage('MQL')
				.setCloseDate(System.today().addDays(2))
				.build();

			insert objAPDOppty;
			Test.stopTest();
		}

		Opportunity assertOpp = [SELECT Id, NumberOfEmployees__c FROM Opportunity LIMIT 1];
		System.assertEquals(0, assertOpp.NumberOfEmployees__c);
	}

	@IsTest
	private static void createDeleteOpportunity() {
		TriggerHandler.bypass('AccountTriggerHandler');

		// Get org default tier config settings and assert new price 1 is not blank
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		System.assertNotEquals(null, objTierConfig.New_Price_1__c);

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setName('Gustomer')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setZPCompanyId('123456789')
			.setHIOwner(UserInfo.getUserId())
			.build();
		objCompanyAccount.Pricing__c = objTierConfig.New_Price_1__c;
		objCompanyAccount.Discount__c = 20;
		insert objCompanyAccount;

		User objcurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		objcurrentUser.Exempt_From_Validation_Rules__c = false;
		update objcurrentUser;
		Test.startTest();
		System.runAs(objcurrentUser) {
			Account a = [SELECT Id FROM Account LIMIT 1];

			Opportunity objAPDOppty = new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
				.setName('APD Account - Payroll')
				.setAccountId(a.Id)
				.setStage('MQL')
				.setCloseDate(System.today().addDays(2))
				.build();

			insert objAPDOppty;

			objAPDOppty.CloseDate = System.today().addDays(1);

			update objAPDOppty;
			System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);

			delete objAPDOppty;
			System.assertEquals(0, [SELECT COUNT() FROM Opportunity]);

			undelete objAPDOppty;
			System.assertEquals(1, [SELECT COUNT() FROM Opportunity]);
		}
		Test.stopTest();
	}

	/**
	 * Attempt to cause an exception on Opportunity creation or update
	 */
	@IsTest
	static void testOpportunityException() {
		TriggerHandler.bypass('AccountTriggerHandler');

		Account objCompanyAccount = new TestDataFactory.AccountBuilder()
			.setName('Gustomer')
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setZPCompanyId('123456789')
			.setHIOwner(UserInfo.getUserId())
			.build();
		objCompanyAccount.Pricing__c = 'test';
		objCompanyAccount.Discount__c = 20;
		insert objCompanyAccount;

		User objCurrentUser = TestUserUtility.getRunningUser();
		System.runAs(objCurrentUser) {
			TriggerHandler.bypass('AccountTriggerHandler');
			TriggerHandler.bypass('CaseTriggerHandler');
			Opportunity objOpp = new Opportunity();
			objOpp.RecordTypeId = null;
			Test.startTest();
			TriggerHandler.bypass('AccountTriggerHandler');
			Boolean blnHasError = false;
			try {
				insert objOpp; // trigger handler will catch the error
			} catch (Exception ex) {
				blnHasError = true;
			}
			System.assert(blnHasError);
			objOpp = new Opportunity();
			Test.stopTest();
			insert objOpp;
			blnHasError = false;
			objOpp.Name = null;
			try {
				update objOpp;
			} catch (Exception e) {
				blnHasError = true;
			}
			System.assert(blnHasError);
			objOpp.Name = 'TestName';
			update objOpp;
			System.assertEquals(1, [SELECT COUNT() FROM Exception_Log__c]);
		}

	}

	@IsTest
	static void testFiscalQuarter() {
		Test.startTest();
		OpportunityUtil.quarterLastDay(Date.today());
		OpportunityUtil.quarterLastDay(Date.today().addMonths(3));
		OpportunityUtil.quarterLastDay(Date.today().addMonths(6));
		OpportunityUtil.quarterLastDay(Date.today().addMonths(9));
		OpportunityUtil.quarterLastDay(null);
		Test.stopTest();
	}
}