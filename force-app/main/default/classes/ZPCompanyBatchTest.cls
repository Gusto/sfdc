/**
 * @name         ZPCompanyBatchTest
 * @author       David (Dato) Tsamalashvili
 * @date         05/12/2022
 * @description  New Refactored ZPCompanyBatchTest Class
 * @see ZPCompanyBatch
 **/
@isTest
public class ZPCompanyBatchTest {
	@isTest
	static void testBatchExecution() {
		ZPCompanyTriggerHelper.queue = false;
		ZPCompanyTriggerHelper.skipTrigger = true;
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.build();

		insert objZPCompany;

		insert new TestDataFactory.ConfigurationSettingsBuilder().setZPAccountingFirmBatchSize(1).setZPCompanyMigrationBatchSize(1).build();

		Test.startTest();
		Database.executeBatch(new ZPCompanyBatch(), 10);
		Test.stopTest();
	}

	/**
	 * @description    Test method to process processing of companies linked to large firms
	 */
	@isTest
	static void testProcessingLargeFirms() {
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('7756161242710583').build();

		// Skip Account Trigger for faster Account inserts
		TriggerHandler.bypass('AccountTriggerHandler');
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName1')
			.setLastName('LName1')
			.setEmail('testuser1@test.com')
			.setPhone('8976567890')
			.setCompany('Test Accountant')
			.setOwnerId(UserInfo.getUserId())
			.setReferredBy(objResellerAccount.Id)
			.setLeadSource('LinkedIn')
			.build();

		// Skip Lead Trigger for faster Lead inserts
		TriggerHandler.bypass('LeadTriggerHandler');
		insert objLead;
		TriggerHandler.clearBypass('LeadTriggerHandler');

		ZPCompanyTriggerHelper.skipTrigger = true;
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setManagingAccountingFirmId(objResellerAccount.ZP_Firm_ID__c)
			.build();
		insert objZPCompany;
		ZPCompanyTriggerHelper.skipTrigger = false;

		Test.startTest();
		Database.executeBatch(new ZPCompanyBatch(), 10);
		Test.stopTest();

		Lead objLeadAssert = [SELECT Id, IsConverted FROM Lead WHERE Email = :objLead.Email];
		System.assertEquals(true, objLeadAssert.IsConverted, 'Lead is not converted');

		ZP_Company__c objCompanyAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objCompanyAssert.Processing_State__c, 'Company not Processed');
	}
}