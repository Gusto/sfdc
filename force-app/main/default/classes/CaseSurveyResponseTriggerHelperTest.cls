@isTest
private class CaseSurveyResponseTriggerHelperTest {
	
    @testSetup 
    static void setUp() {
    	
        Account acc = TestUtility.CompanyAccount();
        
        test.startTest();
        Case cse = new Case();        
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.Routing_Case_Reason__c = 'Test Reason';
        cse.Confirm_Case_Reason__c = 'Test Confirm';
        cse.Type='Payroll Suspension';
        cse.Description='Test';
        cse.Type='QLE';
        insert cse;
        
    }    
    
    @isTest
    static void testMostRecentFlag(){
        
        List<Case> caseList = [select id from Case];
        system.assert(caseList.size()>0);
        
        Case_Survey_Response__c surveyRec1 = new Case_Survey_Response__c();
        surveyRec1.Case__c = caseList.get(0).id;
        insert surveyRec1;
        
        Case_Survey_Response__c surveyRec2 = new Case_Survey_Response__c();
        surveyRec2.Case__c = caseList.get(0).id;
        insert surveyRec2;
        
        list<Case_Survey_Response__c> surveyList = [select id, Most_Recent_Survey__c 
                                                   from Case_Survey_Response__c 
                                                    where Case__c=:caseList.get(0).id 
                                                   order by Name Desc];
        system.assert(surveyList.size() == 2);
        system.assert(surveyList.get(0).Most_Recent_Survey__c == true);
        system.assert(surveyList.get(1).Most_Recent_Survey__c == false);
        
        update surveyRec2;
        delete surveyRec2;
    }
    
}