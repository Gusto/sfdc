@isTest
private class PlayModeCaseListControllerTest {
    
    @testSetup static void testData() {
        Account acc = TestUtility.CompanyAccount();
        
        Group objGroup = [SELECT Id, Name from Group WHERE Type='Queue' AND Name = 'Payroll Compliance Queue'];
        
        Test.startTest();
        List<Case> caseList = new List<Case>();
        Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
        cse.AccountId = acc.Id;
        cse.Routing_Case_Reason__c = 'test';
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='Payroll Care';
        cse.Origin ='Phone';
        cse.OwnerId = objGroup.Id;
        caseList.add(cse);
        
        Case cse1 = new Case();
        cse1.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
        cse1.AccountId = acc.Id;
        cse1.Routing_Case_Reason__c = 'test';
        cse1.Subject='Test';
        cse1.Description='Test';
        cse1.Type='Payroll Care';
        cse1.Origin ='Phone';
        cse1.OwnerId = objGroup.Id;
        caseList.add(cse1);
        insert caseList;
        
        User objUser = [SELECT Id,Individual_Queues__c FROM User WHERE Id = :UserInfo.getUserId()];
        objUser.Individual_Queues__c = 'Payroll Compliance Queue';
        update objUser;
        Test.stopTest();
    }
    
    @isTest static void playModeFunctionalityTest() {
        
        Case cse = new Case();
        list<Case> caseList = [select id from Case];
        if(caseList.size()>0){
            cse = caseList.get(0);
        }
        
        PlayModeCaseListController controller  = new PlayModeCaseListController();
        ApexPages.StandardSetController sc = controller.setCon;
        list<case> tempList = controller.getCases();
        controller.getTotalPages();
        controller.first();
        controller.last();
        controller.previous();
        controller.next();  
        boolean isNext = controller.hasNext; 
        isNext = controller.hasPrevious;
        integer pagenum = controller.pageNumber;
        controller.strPlaySize = '5';
        controller.launchCasePlay();
        
        list<User_Preference__c> preferenceList = [select id from User_Preference__c where User__c =:UserInfo.getUserId()];
        system.assert(preferenceList.size()>0);
        
        controller.getQueueRecords();
        controller.nextRecordInCasePlay();
        
        PlayModeCaseListController.getCaseStatus(string.valueof(cse.id));
        PlayModeCaseListController.updateCaseStatus(string.valueof(cse.id),'Open');
        
    }
    
    @isTest static void skipCaseFunctionalityTest(){
        
        Case cse = new Case();
        list<Case> caseList = [select id from Case];
        if(caseList.size()>0){
            cse = caseList.get(0);
        }
        
        PlayModeCaseListController controller  = new PlayModeCaseListController();
        controller.getcaseStatusPicklist();
        controller.skipCaseId = cse.id;
        controller.skipReason = controller.getcaseSkipPicklist().get(0).getvalue();
        controller.skipComment = 'Code Coverage';
        controller.skipCaseRecord();
        list<Case_Skip_History__c> skipHistoryList = [select id from Case_Skip_History__c where Case__c =:cse.id];
        system.assert(skipHistoryList.size()>0);
    }
    
    @isTest static void escalateCaseFunctionalityTest(){
        Case cse = new Case();
        list<Case> caseList = [select id from Case];
        if(caseList.size()>0){
            cse = caseList.get(0);
        }
        
        PlayModeCaseListController controller  = new PlayModeCaseListController();
        controller.escalationCaseId = cse.id;
        controller.escalationReason = controller.getcaseEscalationReason().get(0).getValue();
        controller.escalationComment = 'Code Coverage';
        controller.escalateCaseRecord();
        
        cse = [select id, Escalated_By_Task_Us__c from Case where id=:cse.id].get(0);
        system.assert(cse.Escalated_By_Task_Us__c == true);
        
    }
}