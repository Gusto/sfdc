@isTest
private class ControllerTest {
	private static Controller cont;

	@testSetup
	private static void createTestData() {
		Account testAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('TEST NAME')
			.setOnboardingFlow('In-App')
			.setZPCompanyId('ControllerTest121')
			.build();
		testAccount.Number_of_Active_Employees__c = 5;
		insert testAccount;
		System.assertEquals(1, [SELECT COUNT() FROM Account], 'Account not inserted');

		Opportunity opportunity = new Opportunity();
		opportunity.StageName = 'SAL';
		opportunity.CloseDate = system.today();
		opportunity.RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		opportunity.AccountId = testAccount.Id;
		opportunity.NumberOfEmployees__c = 1;
		opportunity.ZP_Company_ID__c = 'ControllerTest121';
		opportunity.Source_Id__c = 'ControllerTest12121212121212';
		opportunity.Name = 'Controller Test Opp Name';

		insert opportunity;

		list<Opp_Cosed_Lost_Description__c> customSettRecList = new List<Opp_Cosed_Lost_Description__c>();

		Opp_Cosed_Lost_Description__c custRec = new Opp_Cosed_Lost_Description__c();
		custRec.Name = 'Other';
		custRec.Stage_Name_Value__c = 'Other';
		custRec.Description__c = 'Please fill additional detail';
		custRec.Show_Closed_Detail__c = true;
		customSettRecList.add(custRec);

		Opp_Cosed_Lost_Description__c custRec2 = new Opp_Cosed_Lost_Description__c();
		custRec2.Name = 'Value for Offering';
		custRec2.Stage_Name_Value__c = 'Value for Offering';
		custRec2.Description__c = 'Please fill additional detail';
		custRec2.Show_Closed_Detail__c = false;
		customSettRecList.add(custRec2);

		insert customSettRecList;
	}

	@isTest
	private static void stageIsClosedLost() {
		givenCurrentPageIsAccount();
		whenOpportunityIsSetToClosedLost();
		thenStageNameIs('Closed Lost');
	}

	@isTest
	private static void dateIsToday() {
		givenCurrentPageIsAccount();
		whenOpportunityIsSetToClosedLost();
		thenCloseDateIs(System.Today());
	}

	@isTest
	private static void accountIsSet() {
		givenCurrentPageIsAccount();
		whenOpportunityIsSetToClosedLost();
		thenAccountIdIsSet();
	}

	@isTest
	private static void nameIsSet() {
		givenCurrentPageIsAccount();
		whenOpportunityIsSetToClosedLost();
	}

	@isTest
	private static void insertOpportunity() {
		givenCurrentPageIsAccount();
		whenOpportunityIsInserted();
	}

	@isTest
	private static void updateOpportunity() {
		givenCurrentPageIsOpportunity();
		whenOpportunityIsSetToClosedLost();
		thenStageNameIs('Closed Lost');
	}

	private static void givenCurrentPageIsAccount() {
		setPageReferenceToAccount();
		setSetController();
	}

	private static void givenCurrentPageIsOpportunity() {
		setStandardController();
	}

	private static void whenOpportunityIsSetToClosedLost() {
		Test.startTest();
		cont.setClosedLost();
		Test.stopTest();
	}

	private static void whenOpportunityIsInserted() {
		Test.startTest();
		cont.setClosedLost();
		cont.insertOpportunity();
		Test.stopTest();
	}

	private static void thenStageNameIs(String stageName) {
		assertStageName(stageName);
	}

	private static void thenCloseDateIs(Date closeDate) {
		assertCloseDate(closeDate);
	}

	private static void thenAccountIdIsSet() {
		Account testAccount = getAccount();
		assertAccountId(testAccount.Id);
	}

	private static void setPageReferenceToAccount() {
		PageReference pgRef = Page.ClosedLostOpportunity;
		Test.setCurrentPage(pgRef);
		Account testAccount = getAccount();
		ApexPages.currentPage().getParameters().put('Id', testAccount.Id);
	}

	private static void setSetController() {
		ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(new List<Opportunity>());
		cont = new Controller(ssc);
	}

	private static void setStandardController() {
		Opportunity testOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('TestOpp')
			.setAccountId(getAccount().Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.setIsHistorical(true)
			.setNumberOfEE(12)
			.setHIEffectiveDate(System.today().addDays(30))
			.setPriceBookId(Test.getStandardPricebookId())
			.build();
		insert testOppty;
		PageReference pageRef = Page.ClosedLostOpportunity;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController sc = new ApexPages.StandardController(testOppty);
		cont = new Controller(sc);
		cont.setClosedLost();
		cont.Opportunity.Stage_Detail__c = 'Price Too High';
		cont.Opportunity.Stage_Detail_2__c = 'Value for Offering';
		cont.Opportunity.Closed_Details__c = 'Test Closed Details';
		cont.Opportunity.Competitor__c = 'Other';
		cont.insertOppOpenFeedback();
		cont.openFeedback();
		cont.getObjectPage();
		cont.getReasonDetails();
	}

	private static Account getAccount() {
		return [SELECT Id, Name FROM Account];
	}

	private static Opportunity getOpportunity() {
		return cont.getOpportunity();
	}

	private static void assertStageName(String exp) {
		String act = getOpportunity().StageName;
		System.assertEquals(exp, act, 'Opportuntiy Stage Name not set');
	}

	private static void assertCloseDate(Date exp) {
		Date act = getOpportunity().CloseDate;
		System.assertEquals(exp, act, 'Opportuntiy Close Date not set');
	}

	private static void assertAccountId(Id exp) {
		Id act = getOpportunity().AccountId;
		System.assertEquals(exp, act, 'Opportuntiy Account not set');
	}

	@isTest
	static void closedLostExistingOpp() {
		list<Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

		if (oppList.size() > 0) {
			PageReference pageRef = Page.ClosedLostExistingOpportunity;
			Test.setCurrentPage(pageRef);
			apexPages.StandardController sc = new apexPages.StandardController(oppList.get(0));
			controller cont = new controller(sc);
			cont.setClosedLost();
			cont.Opportunity.Stage_Detail__c = 'Future Sale';
			cont.Opportunity.Stage_Detail_2__c = 'Other';
			cont.Opportunity.Closed_Details__c = 'Test Closed Details';
			cont.Opportunity.Competitor__c = 'Other';
			cont.updateOpportunity();
		}

		List<Opportunity> list_UpdatedOpportunities = [SELECT Id, Stage_Detail__c FROM Opportunity WHERE Id = :oppList[0].Id LIMIT 1];
		System.assertEquals('Future Sale', list_UpdatedOpportunities[0].Stage_Detail__c, 'Incorrect Stage value');
	}
}