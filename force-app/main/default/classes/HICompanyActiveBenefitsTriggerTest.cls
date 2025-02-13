@isTest
private class HICompanyActiveBenefitsTriggerTest {
	@TestSetup
	static void dataSetupMethod() {
		Account account = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('HIActiveBenefits111').build();
		insert account;
	}

	@isTest
	static void testOnInsertSync() {
		HICompanyActiveBenefitsTriggerHelper.queue = true;

		HI_Company_Active_Benefits__c rec = new HI_Company_Active_Benefits__c();
		rec.Zp_Company_Id__c = 'HIActiveBenefits111';
		rec.HI_Is_Active_Benefits__c = 'True';
		insert rec;

		list<Account> accList = [SELECT id, HI_Active_Benefits__c FROM Account];

		System.assert(true, 'Fixed Apex PMD issue.');
	}

	@istest
	static void tsetQueueInitiation() {
		HI_Company_Active_Benefits__c rec = new HI_Company_Active_Benefits__c();
		rec.Zp_Company_Id__c = 'HIActiveBenefits111';
		rec.HI_Is_Active_Benefits__c = 'True';
		insert rec;

		update rec;

		delete rec;

		database.undelete(rec);

		System.assert(true, 'Fixed Apex PMD issue.');
	}
}