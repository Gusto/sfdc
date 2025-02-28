@istest
public class HICommuterBenefitQueueTest {
	@isTest
	static void HINewPlanApplicationCommuterTest() {
		HINewPlansApplicationTriggerHelper.queue = true;
		Account accRec = new Account();
		accRec.ZP_Company_Id__c = 'company321';
		accRec.Name = 'Gusto HINewPlanApplication Test';
		insert accRec;

		PriceBook2 bk = new PriceBook2();
		bk.Name = 'Benefits 2017';
		bk.IsActive = true;
		insert bk;

		Product2 productRec = TestUtility.createTestProduct('Dental', 'Benefit', false);
		insert productRec;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, Test.getStandardPriceBookId(), false));
		pbeList.add(TestUtility.createTestPriceBookEntry(productRec.Id, 5, bk.id, false));
		insert pbeList;

		State__c state = (State__c) State__c.SObjectType.newSObject();
		state.Abbreviation__c = 'CA';
		state.Name = 'TEST STATE';
		insert state;

		Opportunity opportunityRec = TestUtility.createOpportunity('Benefits New Plan', accRec.Id);
		opportunityRec.Pricebook2Id = bk.id;
		opportunityRec.StageName = 'SAL';
		opportunityRec.NumberOfEmployees__c = 5;
		opportunityRec.Source_Id__c = 'hawaiian_ice-new_plans_application-321';
		opportunityRec.Benefits_State__c = 'CA';
		insert opportunityRec;

		list<HI_New_Plans_Application__c> listnewPlan = new List<HI_New_Plans_Application__c>();

		HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
		hiNewPlansApplicationRec.Company_Id__c = 'company321';
		hiNewPlansApplicationRec.External_Key__c = 'hawaiian_ice-new_plans_application-321';
		hiNewPlansApplicationRec.Id__c = '321';
		hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
		listnewPlan.add(hiNewPlansApplicationRec);
		insert listnewPlan;

		HI_Commuter_Benefits__c commuter = new HI_Commuter_Benefits__c();
		commuter.Company_Id__c = 'company321';
		commuter.Created_At__c = system.now();
		commuter.End_Date__c = system.today() + 365;
		commuter.External_Key__c = 'hawaiian_ice-commuter-101';
		commuter.id__c = '101';
		insert commuter;

		//Check that the record was inserted and the Id__c is correct
		HI_Commuter_Benefits__c var_HIcommuterBenefits = [SELECT Id, Company_Id__c, External_Key__c FROM HI_Commuter_Benefits__c WHERE Id__c = '101'];
		System.assertNotEquals(null, var_HIcommuterBenefits, 'Commuter Benefit record should exist.');
		System.assertEquals('hawaiian_ice-commuter-101', var_HIcommuterBenefits.External_Key__c, 'External_Key__c should match.');

		update listnewPlan;
		delete listnewPlan;
	}
}