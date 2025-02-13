@istest
public class CaseTransitionToFulfillmentExtensionTest {
    Private Static testmethod void testBoRtransitionToFulfillment(){
        AccountTriggerHelper.SkipTrigger = true;
        OpportunityTriggerHelper.skipTrigger = true;
        BenefitOrderHelper.skipTrigger = true;  
        CaseTriggerHelper.skipTrigger = true;
        Account acc = TestUtility.CompanyAccount();
        acc.ZP_Company_ID__c = '1111111111';
        update acc;
        

        
		ZP_User_Role__c role = new ZP_User_Role__c();
        role.Company_Id__c = '1111111111';
        role.First_Name__c = 'First';
        role.Last_Name__c = 'Last';
        role.Phone__c = '1234567890';
        role.Type__c = 'Role::Signatory';
        role.User_Id__c ='5555';
        insert role;
        
        Opportunity objOppty = TestUtility.BenefitsBoROpportunity();
        objOppty.Id__c = 'HIBORTRANSFER1123';
        objOppty.Order_Generated__c = false;
        update objOppty;
        Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id,'Test BO ', true);
        
        Transition_to_fulfillment__c transition = new Transition_to_fulfillment__c();
        transition.Account__c = acc.Id;
        transition.Opportunity__c = objOppty.id;
        insert transition;
        
        Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits BoR');
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Benefit_Order__c = objBO.id;
        insert cse;
        AccountTriggerHelper.SkipTrigger = false;
        OpportunityTriggerHelper.skipTrigger = false;
        BenefitOrderHelper.skipTrigger = false;  
        CaseTriggerHelper.skipTrigger = false;
        test.startTest();
			ApexPages.currentPage().getParameters().put('id',cse.id);
            ApexPages.StandardController stdCase = new ApexPages.StandardController(cse);
            CaseTransitionToFulfillmentExtension extension  = new CaseTransitionToFulfillmentExtension(stdCase);
        	cse = extension.theCase;

        	
        test.stopTest();
		
    }
}