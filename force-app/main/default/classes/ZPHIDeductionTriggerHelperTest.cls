@isTest
private class ZPHIDeductionTriggerHelperTest {
	@TestSetup
	static void makeData() {
		insert new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Demo Account')
			.setZPCompanyId('56465453434')
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();
	}

	@isTest
	static void testNewZPHIRecord() {
		Test.startTest();
		insert new TestDataFactory.ZPHIDeductionBuilder().setName('Test - New Record').setCompanyId('56465453434').setActiveEECount(6).setCarrier('Aetna').setMedicalCarriersSupported(true).build();
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		Account objAccount = [
			SELECT Id, Medical_Deductions__c, No_of_EE_with_Active_Benefits__c, Has_Medical_Deductions_Timestamp__c, Carriers__c, Carriers_Other__c, Benefit_Deduction_Category__c
			FROM Account
			WHERE ZP_Company_Id__c = '56465453434'
		];
		System.assert(objAccount.Medical_Deductions__c, 'Medical deduction is false');
		System.assertEquals(6, objAccount.No_of_EE_with_Active_Benefits__c, 'EE count does not match');
		System.assertNotEquals(null, objAccount.Has_Medical_Deductions_Timestamp__c, 'Timestamp is null');
		System.assertEquals('Aetna', objAccount.Carriers__c, 'Carriers does not match');
		System.assertEquals(null, objAccount.Carriers_Other__c, 'Carriers other does not match');
		System.assertEquals('BoR', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
	}

	@isTest
	static void testExistingZPHIRecord() {
		Account objAccount = [SELECT Id, No_of_EE_with_Active_Benefits__c, Medical_Deduction_Descriptions__c, Carriers__c FROM Account WHERE ZP_Company_Id__c = '56465453434'];
		objAccount.No_of_EE_with_Active_Benefits__c = 2;
		objAccount.Medical_Deduction_Descriptions__c = 'Initial data';
		objAccount.Carriers__c = 'Aetna';
		update objAccount;

		Test.startTest();
		insert new TestDataFactory.ZPHIDeductionBuilder().setName('Test - Existing Acct').setCompanyId('56465453434').setActiveEECount(6).setCarrier('Other').setCarrierOther('Test').build();
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		objAccount = [
			SELECT Id, Medical_Deductions__c, No_of_EE_with_Active_Benefits__c, Has_Medical_Deductions_Timestamp__c, Carriers__c, Carriers_Other__c
			FROM Account
			WHERE ZP_Company_Id__c = '56465453434'
		];
		System.assert(objAccount.Medical_Deductions__c, 'Medical deduction is false');
		System.assertEquals(6, objAccount.No_of_EE_with_Active_Benefits__c, 'EE count does not match');
		System.assertNotEquals(null, objAccount.Has_Medical_Deductions_Timestamp__c, 'Timestamp is null');
		System.assertEquals('Other', objAccount.Carriers__c, 'Carriers does not match');
		System.assertEquals('Test', objAccount.Carriers_Other__c, 'Carriers other does not match');
	}

	@isTest
	static void testInactiveZPHIRecord() {
		Test.startTest();
		insert new TestDataFactory.ZPHIDeductionBuilder().setName('Test - Inactive Record').setCompanyId('56465453434').setStatus(ZPHIDeductionTriggerHelper.STR_STATUS_INACTIVE).build();
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		Account objAccount = [
			SELECT
				Id,
				Medical_Deductions__c,
				No_of_EE_with_Active_Benefits__c,
				Medical_Deduction_Descriptions__c,
				Has_Medical_Deductions_Timestamp__c,
				Carriers__c,
				Carriers_Other__c,
				Benefit_Deduction_Category__c
			FROM Account
			WHERE ZP_Company_Id__c = '56465453434'
		];
		System.assert(!objAccount.Medical_Deductions__c, 'Medical deduction is true');
		System.assertEquals(null, objAccount.No_of_EE_with_Active_Benefits__c, 'EE count does not match');
		System.assertEquals(null, objAccount.Medical_Deduction_Descriptions__c, 'Deductions descriptions does not match');
		System.assertEquals(null, objAccount.Has_Medical_Deductions_Timestamp__c, 'Timestamp is not null');
		System.assertEquals(null, objAccount.Carriers__c, 'Carriers does not match');
		System.assertEquals(null, objAccount.Carriers_Other__c, 'Carriers other does not match');
		System.assertEquals(null, objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
	}

	@isTest
	static void testUpdateZPHIRecord() {
		ZP_HI_Deduction__c objDeduction = new TestDataFactory.ZPHIDeductionBuilder().setName('Test - Update Record').setCompanyId('56465453434').setActiveEECount(6).build();
		insert objDeduction;

		Test.startTest();
		objDeduction.active_employee_count__c = 12;
		update objDeduction;
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		Account objAccount = [SELECT Id, Medical_Deductions__c, No_of_EE_with_Active_Benefits__c FROM Account WHERE ZP_Company_Id__c = '56465453434'];
		System.assert(objAccount.Medical_Deductions__c, 'Medical deduction is false');
		System.assertEquals(12, objAccount.No_of_EE_with_Active_Benefits__c, 'EE count does not match');
	}

	@isTest
	static void testZPHIStatusChanged() {
		ZP_HI_Deduction__c objDeduction = new TestDataFactory.ZPHIDeductionBuilder().setName('Test - Status Change').setCompanyId('56465453434').setActiveEECount(6).build();
		insert objDeduction;

		Test.startTest();
		objDeduction.Status__c = ZPHIDeductionTriggerHelper.STR_STATUS_INACTIVE;
		update objDeduction;
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		System.assertEquals(false, [SELECT Medical_Deductions__c FROM Account WHERE ZP_Company_Id__c = '56465453434'].Medical_Deductions__c, 'Medical deduction is true');
	}

	@isTest
	static void testErrorZPHIRecord() {
		Test.startTest();
		insert new TestDataFactory.ZPHIDeductionBuilder().setName('Test - Error Record').setCompanyId('12454411294').setActiveEECount(6).build();
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 1);
		Test.stopTest();

		System.assertEquals('Error', [SELECT Processing_State__c FROM ZP_HI_Deduction__c LIMIT 1].Processing_State__c, 'Incorrect processing state');
	}

	/**
	 * @description Check Account Benefit_Deduction_Category__c value which getting populated from ZP_HI_Deduction__c record
	 * @author Rushi | 04-19-2023
	 **/
	@isTest
	static void testBenefitCategories() {
		Utils.skipTrigger(true);
		Account acctNoState = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setName('Test Account 1').setZPCompanyId('77885453434').build();
		insert acctNoState;

		Account acctValidState = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Account 2')
			.setZPCompanyId('88775453434')
			.setBillingState('California')
			.setBillingCountry('United States')
			.build();
		insert acctValidState;

		Account acctInvalidState = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('Test Account 2')
			.setZPCompanyId('10775453434')
			.setBillingState('Rhode Island')
			.setBillingCountry('United States')
			.build();
		insert acctInvalidState;
		Utils.skipTrigger(false);

		Test.startTest();
		List<ZP_HI_Deduction__c> list_Deductions = new List<ZP_HI_Deduction__c>{
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - No State').setCompanyId('77885453434').setActiveEECount(6).build(), // BYB
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - HI State').setCompanyId('88775453434').setActiveEECount(3).setCarrier('Aetna').setMedicalCarriersSupported(true).build(), // BYB
			new TestDataFactory.ZPHIDeductionBuilder().setName('Test - CA State').setCompanyId('56465453434').setActiveEECount(3).setCarrier('Aetna,Other').setMedicalCarriersSupported(true).build() // BoR Partial
		};
		insert list_Deductions;
		Database.executeBatch(new ZPHIDeductionBatchScheduler(), 10);
		Test.stopTest();

		List<Account> list_Accounts = [SELECT Benefit_Deduction_Category__c, ZP_Company_Id__c FROM Account WHERE ZP_Company_Id__c IN ('77885453434', '88775453434', '56465453434')];

		for (Account objAccount : list_Accounts) {
			if (objAccount.ZP_Company_Id__c == '77885453434') {
				System.assertEquals('BYB', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
			}

			if (objAccount.ZP_Company_Id__c == '88775453434') {
				System.assertEquals('BoR', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
			}

			if (objAccount.ZP_Company_Id__c == '56465453434') {
				System.assertEquals('BoR Partial', objAccount.Benefit_Deduction_Category__c, 'Benefit Deduction Category does not match');
			}
		}
	}
}