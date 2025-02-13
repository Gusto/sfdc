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
private class KnowledgeFooterControllerTest {
	@testSetup
	static void setupMethod() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Account acc = TestUtility.CompanyAccount();

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(Cache.getRecordTypeId('Contact', 'Company'))
			.setPhone('12345632')
			.setFirstName('TestBatchCaseAuditContact')
			.setLastName('Test')
			.setAccountId(acc.id)
			.build();
		insert objContact;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.AccountId = acc.Id;
		cse.Status = 'New';
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Sales';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'test.test@batchcaseautologcreationtest.com';
		cse.ContactId = objContact.id;
		cse.Large_Scale_Issue__c = 'Test LSI';
		insert Cse;

		CaseTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void knowledgeArticleTest() {
		List<Case> caseList = [SELECT id FROM Case];

		Test.startTest();
		apexPages.StandardController sc = new apexPages.StandardController(caseList.get(0));
		knowledgeFooterController controller = new knowledgeFooterController(sc);
		controller.primaryCaseId = caseList.get(0).id;
		controller.populateArticleDetails();
		controller.searchStr = 'Test';
		controller.selectedSortFilter = 'Title: Z to A';
		controller.searchArticle();
		controller.selectedSortFilter = 'Title: Z to A';
		controller.searchArticle();
		controller.selectedSortFilter = 'External';
		controller.searchArticle();
		controller.selectedSortFilter = 'Internal';
		controller.searchArticle();
		List<knowledgeFooterController.articleDetail> tempList = controller.articleKnowledgeDetailList;
		boolean tempNext = controller.hasNext;
		boolean tempBol = controller.hasPrevious;
		integer tempInt = controller.pageNumber;
		controller.previous();
		controller.next();
		knowledgeFooterController.articleDetail tempRec = new knowledgeFooterController.articleDetail('Internal', 'Test', '123', 'Title', controller.primaryCaseId, controller.primaryCaseId);
		Test.stopTest();
	}
}