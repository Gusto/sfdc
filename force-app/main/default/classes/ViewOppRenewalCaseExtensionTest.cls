@isTest
public class ViewOppRenewalCaseExtensionTest {
	@isTest
	static void testCaseCreation() {
		HICarrierInformationTriggerHelper.queue = true;
		Account account = new TestDataFactory.AccountBuilder().setRecordTypeId(Cache.getRecordTypeId('Account', 'Company')).setName('Test Account').setZPCompanyId('11111111').build();
		insert account;

		Contact cntct = new TestDataFactory.ContactBuilder().setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company')).setLastName('Test Last Name').build();
		insert cntct;

		Opportunity opp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Opportunity', 'Benefits Renewal'))
			.setId('HIBORTRANSFER1123')
			.setName('test Opportunity')
			.setAccountId(account.Id)
			.setStage('New')
			.setCloseDate(Date.today())
			.setOrderGenerated(false)
			.build();
		insert opp;

		ApexPages.currentPage().getParameters().put('id', opp.id);
		ApexPages.StandardController stdOpp = new ApexPages.StandardController(opp);
		ViewOppRenewalCaseExtension extension = new ViewOppRenewalCaseExtension(stdOpp);

		List<Case> caseList = [SELECT Id FROM Case WHERE Opportunity__c = :opp.Id];
		System.assert(caseList.size() > 0, 'There should be at least one case in list.');
	}
}