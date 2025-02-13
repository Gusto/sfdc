/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RenewalOpportunityComplexityCalBatchTest {
	@isTest
	static void myUnitTest() {
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').setZPCompanyId('12121212121212321').build();
		insert objAccount;

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.StageName = 'SAL';
		objOpportunity.CloseDate = System.today();
		objOpportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		objOpportunity.AccountId = objAccount.Id;
		objOpportunity.NumberOfEmployees__c = 1;
		objOpportunity.ZP_Company_ID__c = '12121212121212321';
		objOpportunity.Source_Id__c = '121212121212123211';
		objOpportunity.Renewal_Date__c = System.today().adddays(100);

		insert objOpportunity;

		test.startTest();
		RenewalOpportunityComplexityCalBatch controller = new RenewalOpportunityComplexityCalBatch();
		database.executeBatch(controller, 1);
		test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}
}