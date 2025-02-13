/**
 * @name         ZPCompanyQueueTest
 * @author       David (Dato) Tsamalashvili
 * @date         05/12/2022
 * @description  New Refactored ZPCompanyQueueTest Class
 * @see ZPCompanyQueue
 **/
@isTest
public class ZPCompanyQueueTest {
	@isTest
	static void testLeadQueue() {
		ZPCompanyTriggerHelper.skipTrigger = true;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('11111111111111')
			.setCompanyLeadId('222222222222')
			.setProcessingState(IntegrationUtils.ERROR_STATE)
			.setCreatedAtDate(System.today())
			.setName('Test Company Name')
			.build();

		insert objZPCompany;

		ZPCompanyTriggerHelper.skipTrigger = false;

		List<ZP_Company__c> list_ZPCompanies = new List<ZP_Company__c>();
		list_ZPCompanies.add(objZPCompany);

		Test.startTest();
		System.enqueueJob(new ZPCompanyQueue(list_ZPCompanies));
		Test.stopTest();

		ZP_Company__c objZPCompAssert = [SELECT Id, Processing_State__c FROM ZP_Company__c WHERE Id = :objZPCompany.Id];
		System.assertEquals(IntegrationUtils.PROCESSED_STATE, objZPCompAssert.Processing_State__c);
	}

	/**
	 * Test exception scenarios
	 **/
	@isTest
	static void testException() {
		// Skip Account Trigger for faster Account inserts
		//Given a reseller account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account 2').setZPFirmId('987456124').build();
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		//Given a list of ZP Companies
		List<ZP_Company__c> list_testZPCompanies = new List<ZP_Company__c>();
		for (Integer i = 0; i < 17; i++) {
			ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId('12344321567' + i)
				.setName('Test ZP ' + i)
				.setProcessingState(IntegrationUtils.QUEUED_STATE)
				.setCreatedAtDate(System.today())
				.setNumberOfActiveEEs(4)
				.build();
			list_testZPCompanies.add(objZPCompany);
		}
		insert list_testZPCompanies;
		Test.startTest();
		//When some ZP Companies have a field getting updated thats prioritized
		for (Integer i = 0; i < list_testZPCompanies.size(); i++) {
			list_testZPCompanies[i].Managing_Accounting_Firm_Id__c = objResellerAccount.ZP_Firm_ID__c;
		}
		update list_testZPCompanies;
		Test.stopTest();
		//Then the ZP Companies with the prioritized field updated should be processed first
		Integer intProcessed = [SELECT COUNT() FROM ZP_Company__c WHERE Id IN :list_testZPCompanies AND Processing_State__c = :IntegrationUtils.PROCESSED_STATE];
		Assert.areEqual(15, intProcessed, 'Count of ZP Companies processed incorrect');
	}

	/**
	 * Test exception scenarios
	 **/
	@isTest
	static void testExceptionIfNoResources() {
		// Skip Account Trigger for faster Account inserts
		//Given a reseller account
		TriggerHandler.bypass('AccountTriggerHandler');
		Account objResellerAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account').setZPFirmId('987456123').build();
		Account objResellerAccount2 = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.RESELLER_ACCOUNT_TYPE).setName('Reseller Account 2').setZPFirmId('987456124').build();
		insert objResellerAccount;
		TriggerHandler.clearBypass('AccountTriggerHandler');

		//Given a list of ZP Companies
		List<ZP_Company__c> list_testZPCompanies = new List<ZP_Company__c>();
		for (Integer i = 0; i < 17; i++) {
			ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
				.setZPCompanyId('12344321567' + i)
				.setName('Test ZP ' + i)
				.setProcessingState(IntegrationUtils.QUEUED_STATE)
				.setCreatedAtDate(System.today())
				.setNumberOfActiveEEs(4)
				.build();
			list_testZPCompanies.add(objZPCompany);
		}
		insert list_testZPCompanies;
		Test.startTest();

		//When some ZP Companies have a field getting updated thats prioritized
		for (Integer i = 0; i < list_testZPCompanies.size(); i++) {
			list_testZPCompanies[i].Managing_Accounting_Firm_Id__c = objResellerAccount.ZP_Firm_ID__c;
		}
		ZPCompanyQueue updateJob = new ZPCompanyQueue(list_testZPCompanies, 'Prioritized', null);
		updateJob.blnTestException = true;
		ID jobID = System.enqueueJob(updateJob);
		Test.stopTest();
		//Then the ZP Companies with the prioritized field updated should be processed first
		Integer intProcessed = [SELECT COUNT() FROM ZP_Company__c WHERE Id IN :list_testZPCompanies AND Processing_State__c = :IntegrationUtils.PROCESSED_STATE];
		Assert.areEqual(15, intProcessed, 'Count of ZP Companies processed incorrect');
	}
}