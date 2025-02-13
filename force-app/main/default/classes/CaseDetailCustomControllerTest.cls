/**
 
 */
@isTest
private class CaseDetailCustomControllerTest {

    @testSetup static void testData() {
        Account acc = TestUtility.CompanyAccount();
        
        test.startTest();
	        Case cse = new Case();
	        cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
	        cse.AccountId = acc.Id;
	        cse.Subject='Test';
	        cse.Description='Test';
	        cse.Type='QLE';
	        insert cse;
        test.stopTest();
    }
    
    @isTest static void playModeFunctionalityTest() {
        Case cse = new Case();
        list<Case> caseList = new list<case>();
        caseList = [select id,Routing_Case_Reason__c from Case];
        if(caseList.size()>0){
            cse = caseList.get(0);
        }
        
        apexPages.StandardSetController sc = new apexPages.StandardSetController(caseList);
        CaseDetailCustomController controller  = new CaseDetailCustomController(sc);
        //play functionality check
        controller.currentCaseId = caseList.get(0).id;
        list<case> tempCaseList = controller.caseList;
        controller.getCaseDetail();       
        controller.startPlay();        
        system.assert(controller.isPlay == true); //isPlay boolean value check
        caseList = [select id,isCaseInPlay__c from Case];
        if(caseList.size()>0){
            system.assert(caseList.get(0).isCaseInPlay__c == true);//Locked on Record check.
        }
        
        
        controller.cancelUpdate();
        system.assert(controller.isPlay == false);
        controller.getcaseQueueList();
        
        controller.startPlay();         
        caseList = [select id,isCaseInPlay__c from Case];
        if(caseList.size()>0){
            system.assert(caseList.get(0).isCaseInPlay__c == true);//Locked on Record check.
        }
                
        
        
        //saveNext functionality check 
        controller.selectedCaseRec =  cse;              
        controller.selectedCaseRec.Routing_Case_Reason__c='Payroll Care'; 
        string caseId = controller.selectedCaseRec.id;
        controller.saveNextRecord();
        controller.getselectedQueueRecCount();
        
    }
}