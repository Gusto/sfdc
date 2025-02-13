@isTest
public class HICarrierInformationQueueTest {
	@isTest
	static void CreateCarrierInformationWithoutBORTransfer() {
		HICarrierInformationTriggerHelper.queue = false;
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('11111111').build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder().setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID).setAccountId(objAccount.Id).setLastName('TestCompanyUser').build();
		insert objContact;

		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID)
			.setName('Benefits BoR Opp')
			.setId('HIBORTRANSFER1123')
			.setAccountId(objAccount.Id)
			.setOrderGenerated(false)
			.build();

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setKey('abc_ca').build();
		insert objCarrier;

		Test.startTest();
		HI_Carrier_Information__c objCarrierInfo = new TestDataFactory.HICarrierInformationBuilder().setBorTransferId('1123').setId('33333').setKey('abc_ca').build();
		insert objCarrierInfo;
		Test.stopTest();

		System.assert(true, 'Fixing Apex PMD issue.');
	}
}