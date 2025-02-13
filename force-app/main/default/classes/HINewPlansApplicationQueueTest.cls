@isTest
private class HINewPlansApplicationQueueTest {

    static testMethod void hiNewPlanQpplicationQueueTest() {
    	list<HI_New_Plans_Application__c> listnewPlan = new list<HI_New_Plans_Application__c>();
    	
    	HI_New_Plans_Application__c hiNewPlansApplicationRec = new HI_New_Plans_Application__c();
    	hiNewPlansApplicationRec.Company_Id__c = 'company321';
    	hiNewPlansApplicationRec.External_Key__c = 'Opportunity321';
    	hiNewPlansApplicationRec.Id__c = 'newPlan321';
    	hiNewPlansApplicationRec.Requested_Start_Date__c = system.today();
    	listnewPlan.add(hiNewPlansApplicationRec);
    	
    	HI_New_Plans_Application__c hiNewPlansApplicationRec1 = new HI_New_Plans_Application__c();
    	hiNewPlansApplicationRec1.Company_Id__c = 'company321';
    	//hiNewPlansApplicationRec1.External_Key__c = 'Opportunity322';
    	hiNewPlansApplicationRec1.Id__c = 'newPlan322';
    	hiNewPlansApplicationRec1.Requested_Start_Date__c = system.today();
    	listnewPlan.add(hiNewPlansApplicationRec1);
    	
    	insert listnewPlan;
        
        Test.startTest();
        HINewPlansApplicationQueue updateJob = new HINewPlansApplicationQueue(listnewPlan);
        ID jobID = System.enqueueJob(updateJob);
        system.assert(jobID!=null);
        /*if(jobID != null){
        	system.assert(string.valueof(jobID).length()>0);
        }*/
        Test.stopTest();
    }
}