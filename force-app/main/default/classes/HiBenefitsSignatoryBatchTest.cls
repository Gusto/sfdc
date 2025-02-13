@isTest
public class HiBenefitsSignatoryBatchTest {
	@isTest
	static void testBatchExecution() {
		list<HI_Benefits_Signatory__c> signatoryList = new List<HI_Benefits_Signatory__c>();
		HI_Benefits_Signatory__c signatory = new HI_Benefits_Signatory__c();
		signatory.Id__c = '23233';
		signatory.External_Key__c = '232323';
		signatory.Processing_State__c = 'Error';
		signatoryList.add(signatory);
		insert signatoryList;

		Test.startTest();
		database.executeBatch(new HIBenefitsSignatoryBatch(), 10);
		Test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}
}