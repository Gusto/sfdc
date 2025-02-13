@istest
public class HIHSABenefitQueueTest {
    
    static testMethod void HINewPlanApplicationHSATestAsync() {
    	HINewPlansApplicationTriggerHelper.queue=true;
    	Account accRec = new Account();
       	accRec.ZP_Company_Id__c = 'company321';
       	accRec.Name ='Gusto HINewPlanApplication Test';
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
    	

    	
    	list<HI_New_Plans_Application__c> listnewPlan = new list<HI_New_Plans_Application__c>();
    	
    	HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
    	hiNewPlansApplicationRec.Company_Id__c = 'company321';
    	hiNewPlansApplicationRec.External_Key__c = 'hawaiian_ice-new_plans_application-321';
    	hiNewPlansApplicationRec.Id__c = '321';
    	hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
    	listnewPlan.add(hiNewPlansApplicationRec);
        insert listnewPlan;
    	
        HIHSABenefitTriggerHelper.queue=false;
        
		HI_HSA_Benefit__c hsa = new HI_HSA_Benefit__c();
        hsa.Company_Id__c = 'company321';
        hsa.Created_At__c = system.now();
        hsa.External_Key__c = 'hawaiian_ice-commuter-101';
        hsa.id__c = '101';
        hsa.Source_Id__c='321';
        hsa.Source_Type__c='NewPlansApplication';
        insert hsa;
        
        List<Policy__c> policyList = [Select Id from Policy__c];
		system.assert(policyList.size()==0);
    }
   
}