/**
 * @name         : ZPCompanySuspensionBatchTest
 * @author       : David (Dato) Tsamalashvili
 * @date         : 01-27-2022
 * @description  : Test class for batch job - ZPCompanySuspensionBatch
 **/
@isTest
public class ZPCompanySuspensionBatchTest {
	@testSetup
	static void setupData() {
		Configuration_Settings__c objConfig = new TestDataFactory.ConfigurationSettingsBuilder().setZPTierBatchSize(1).build();
		insert objConfig;
	}

	@isTest
	static void testBatch() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_COMPANY)
			.setFirstName('Test Lead 1')
			.setLastName('LName2')
			.setEmail('company12@companylead.com')
			.setPhone('123456789')
			.setCompany('Test Company')
			.setZPCompanyID('11111111111111')
			.setZPCompanyLeadID('222222222222')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.setLeadSource('LinkedIn')
			.build();

		insert objLead;

		ZP_Company_Suspension__c objZPCompSuspension = new TestDataFactory.ZPCompanySuspensionBuilder()
			.setId('22233344553')
			.setCompanyId('11111111111111')
			.setReason('Leaving for other vendor')
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setSuspendedAt(Date.Today())
			.build();

		insert objZPCompSuspension;

		Test.startTest();
        objZPCompSuspension = [SELECT Id,Processing_State__c FROM ZP_Company_Suspension__c];
        System.assertEquals(objZPCompSuspension.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Company_Suspension__c records should be Queued.');
        Database.executeBatch(new ZPCompanySuspensionBatch(), 5);
        Test.stopTest();
        objZPCompSuspension = [SELECT Id,Processing_State__c FROM ZP_Company_Suspension__c];
        System.assertEquals(objZPCompSuspension.Processing_State__c, 'Error', 'The Processing_State__c of ZP_Company_Suspension__c records should be Error.');
	}
}