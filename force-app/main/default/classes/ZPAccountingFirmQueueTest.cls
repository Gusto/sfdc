/**
 * @name         ZPAccountingFirmQueueTest
 * @author       Praveen Sethu
 * @date         02-25-2021
 * @description  Testing ZP Accounting Firm Queue
 **/

@isTest
public class ZPAccountingFirmQueueTest {
	@isTest
	static void testFirmQueue() {
		// Creating Leads before ZP Accounting Firm Is Created
		Lead objLead = TestUtils.createNewLead(LeadUtil.RESELLER_LEAD_RT_ID, 'FName', 'LName', 'email@zpfirm.com', '123456789', 'ZP Firm Lead', true);

		ZP_Accounting_Firm__c objFirm = TestUtils.createZPAccountingFirm('15975328542', 'Test ZP Accounting Firm', objLead.Email, true);

		Test.startTest();
		System.enqueueJob(new ZPAccountingFirmQueue(new List<ZP_Accounting_Firm__c>{ objFirm }));
		Test.stopTest();

		ZP_Accounting_Firm__c objFirmAssert = [SELECT Id, Processing_State__c FROM ZP_Accounting_Firm__c WHERE Id = :objFirm.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objFirmAssert.Processing_State__c);
	}
}