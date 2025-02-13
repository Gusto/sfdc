@isTest
private class MemberFulfillmentEscalationControlleTest {
    
    @testsetup
    static void setupMethod(){
        Account acc = TestUtility.CompanyAccount();
        
        test.startTest();
	        Case cse = new Case();
	        cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
	        cse.AccountId = acc.Id;
	        cse.Subject='Test';
	        cse.Description='Test';
	        cse.Type='QLE';
	        insert cse;
        test.stopTest();
    }
    
    @isTest
    static void testCreateCaseMethod() {
        List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];
        
        if (!list_Cases.isEmpty()) {
            ApexPages.StandardController sc = new ApexPages.StandardController(list_Cases.get(0));
            MemberFulfillmentEscalationController controller = new MemberFulfillmentEscalationController(sc);
            controller.reason = 'BenCare-Benefits Reversal';
            controller.setSubjectAndDescription();
            controller.createNewCase();
            
            Id oldCaseId = list_Cases.get(0).Id;
            list_Cases = new List<Case>();
            list_Cases = [SELECT Id FROM Case WHERE Id !=: oldCaseId LIMIT 1];
            System.assert(list_Cases.size() > 0);
        }
    }
    
    static testMethod void testCreateBenefitsReversalMethod() {
        
        list<case> caseList = [select id from Case];
        
        if(caseList.size()>0){
            
            apexPages.StandardController sc = new apexPages.StandardController(caseList.get(0));
            MemberFulfillmentEscalationController controller = new MemberFulfillmentEscalationController(sc);
            controller.reason='BenCare-Benefits Reversal';
            controller.setSubjectAndDescription();
            controller.createNewCase();
            
            id oldCaseId = caseList.get(0).id;
            caseList = new list<case>();
            caseList = [select id from Case where id !=: oldCaseId];
            system.assert(caseList.size()>0);
        }
        
    }
}