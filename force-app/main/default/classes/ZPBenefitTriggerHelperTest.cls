/**
 * @description Test class for ZPBenefitTriggerHandler
 * @author Praveen Sethu
 * @see ZPBenefitTriggerHandler
 */
@isTest
public class ZPBenefitTriggerHelperTest {
	@isTest
	static void testZPBenefitInsert() {
		// Create a new company account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objAccnt = new Account(RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID, Name = 'Test Acc', ZP_Company_Id__c = '123456789');
		insert objAccnt;
		TriggerHandler.clearAllBypasses();

		// Start test and insert new ZP benefit record
		Test.startTest();
		ZP_Benefit__c objBenefit = new ZP_Benefit__c(Id__c = '5456424', Company_Id__c = '123456789');
		insert objBenefit;
		Test.stopTest();

		// Stop test to stop all asyncrhonous calls
		// Query ZP Benefit and check if Account__c was set properly

		ZP_Benefit__c objBenefitAssert = [SELECT Id, Account__c FROM ZP_Benefit__c WHERE Id = :objBenefit.Id];
		System.assertEquals(objBenefitAssert.Account__c, objAccnt.Id, 'ZP Benefit Account was not set properly');
	}

	@isTest
	static void testZPBenefitUpdate() {
		// Create a new company account
		Account objAccnt = new Account(RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID, Name = 'Test Acc', ZP_Company_Id__c = '123456789');
		insert objAccnt;

		// Start test and insert new ZP benefit record
		Test.startTest();
		ZP_Benefit__c objBenefit = new ZP_Benefit__c(Id__c = '5456424');
		insert objBenefit;

		// Update ZP Benefit Record
		objBenefit.Company_Id__c = '123456789';
		update objBenefit;
		Test.stopTest();

		// Stop test to stop all asyncrhonous calls
		// Query ZP Benefit and check if Account__c was set properly

		ZP_Benefit__c objBenefitAssert = [SELECT Id, Account__c FROM ZP_Benefit__c WHERE Id = :objBenefit.Id];
		System.assertEquals(objBenefitAssert.Account__c, objAccnt.Id, 'ZP Benefit Account was not set properly');
	}
}