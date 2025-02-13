@isTest
public class TaxOpsTaskKnowledgeFooterExtensionTest {
	@testSetup
	static void setupMethod() {
		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		Account objAccount = TestUtility.CompanyAccount();

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setPhone('12345632')
			.setFirstName('TestBatchCaseAuditContact')
			.setLastName('Test')
			.setAccountId(objAccount.Id)
			.build();
		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Payroll Care')
			.setAccountId(objAccount.Id)
			.setStatus('New')
			.setSubject('Test')
			.setDescription('Test')
			.setType('Sales')
			.setOrigin('Email')
			.setSuppliedEmail('test.test@batchcaseautologcreationtest.com')
			.setContactId(objContact.Id)
			.build();
		objCase.Large_Scale_Issue__c = 'Test LSI';
		insert objCase;

		Tax_Ops_Task__c objTask = new TestDataFactory.TaxOpsTaskBuilder().build();
		objTask.Form_Code__c = 'Test';
		objTask.Filing_Method__c = 'Paper';
		insert objTask;

		CaseTriggerHelper.skipTrigger = false;
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void knowledgeArticleTest() {
		list<Case> list_Cases = [SELECT Id FROM Case];

		Test.startTest();
		TaxOpsTaskKnowledgeFooterExtension objController = new TaxOpsTaskKnowledgeFooterExtension();
		objController.primaryCaseId = list_Cases.get(0).Id;
		objController.populateArticleDetails();
		objController.searchStr = 'Test';
		objController.selectedSortFilter = 'Title: Z to A';
		objController.searchArticle();
		objController.selectedSortFilter = 'Title: Z to A';
		objController.searchArticle();
		objController.selectedSortFilter = 'External';
		objController.searchArticle();
		objController.selectedSortFilter = 'Internal';
		objController.searchArticle();
		List<TaxOpsTaskKnowledgeFooterExtension.articleDetail> list_Temp = objController.articleKnowledgeDetailList;
		objController.previous();
		objController.next();
		TaxOpsTaskKnowledgeFooterExtension.articleDetail objTempRec = new TaxOpsTaskKnowledgeFooterExtension.articleDetail(
			'Internal',
			'Test',
			'123',
			'Title',
			objController.primaryCaseId,
			objController.primaryCaseId
		);
		Test.stopTest();
	}

	@isTest
	static void getTaxOpsTaskArticlesPresenceInfoTest() {
		Tax_Ops_Task__c objTask1 = [
			SELECT Id, OwnerId, Process_step__c, Tax_Code__c, Form_Code__c, Filing_Method__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c
			FROM Tax_Ops_Task__c
			WHERE Tax_Code__c = :'OH000-001'
		];

		Test.startTest();
		TaxOpsTaskKnowledgeFooterExtension objController = new TaxOpsTaskKnowledgeFooterExtension();
		objController.primaryCaseId = objTask1.id;
		objController.populateArticleDetails();
		objController.searchStr = 'Test';
		objController.selectedSortFilter = 'Title: Z to A';
		objController.searchArticle();
		objController.selectedSortFilter = 'Title: Z to A';
		objController.searchArticle();
		objController.selectedSortFilter = 'External';
		objController.searchArticle();
		objController.selectedSortFilter = 'Internal';
		objController.searchArticle();
		List<TaxOpsTaskKnowledgeFooterExtension.articleDetail> list_Temp = objController.articleKnowledgeDetailList;
		boolean blnTempNext = objController.hasNext;
		boolean blnTempBol = objController.hasPrevious;
		integer intTempInt = objController.pageNumber;
		objController.previous();
		objController.next();
		Test.stopTest();
	}
}