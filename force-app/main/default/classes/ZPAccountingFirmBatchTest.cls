/**
 * @name         ZPAccountingFirmBatchTest
 * @author       David (Dato) Tsamalashvili
 * @date         05/12/2022
 * @description  New Refactored ZPAccountingFirmBatchTest Class
 * @see ZPAccountingFirmBatch
 **/
@isTest
public class ZPAccountingFirmBatchTest {
	@isTest
	static void testAccountingFirmBatch() {
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.LABEL_RESELLER)
			.setFirstName('test')
			.setLastName('test')
			.setEmail('test@test.com')
			.setCompany('Test Accountan')
			.setZPFirmId('11111111111111')
			.setZPCompanyLeadID('222222222222')
			.setLeadSource('adwords')
			.build();
		insert objLead;

		ZP_Accounting_Firm__c objZPAccFirm = new TestDataFactory.ZPAccountingFirmBuilder()
			.setZPFirmId('11111111111111')
			.setName('Test Accountant')
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAt(System.today())
			.build();
		insert objZPAccFirm;

		Test.startTest();
        objZPAccFirm = [SELECT Id,Processing_State__c FROM ZP_Accounting_Firm__c];
        System.assertEquals(objZPAccFirm.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Accounting_Firm__c records should be Queued.');
        Database.executeBatch(new ZPAccountingFirmBatch('SELECT Id FROM ZP_Accounting_Firm__c'), 10);
        Test.stopTest();
        objZPAccFirm = [SELECT Id,Processing_State__c FROM ZP_Accounting_Firm__c];
        System.assertEquals(objZPAccFirm.Processing_State__c, 'Processed', 'The Processing_State__c of ZP_Accounting_Firm__c records should be Processed.');
	}
}