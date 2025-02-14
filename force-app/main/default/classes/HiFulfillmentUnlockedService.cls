@RestResource(urlMapping='/Hifulfillment/enrollmentUnlocked/*') 
global with sharing class HiFulfillmentUnlockedService {

    @HttpPost
    global static void  doPost(updateInfo updInfo) {
        HI_Fulfillment_Event__c eventInfo = [Select Id, Employee_Id__c,CreatedDate from HI_Fulfillment_Event__c where id=:updInfo.id and Event_Type__c='enrollment_unlocked'];
        if(eventInfo != null){
            DateTime dtm = eventInfo.CreatedDate;
            dtm = dtm.addMinutes(5);
            boolean terminationExists = false;
            HI_Fulfillment_Event__c nheEventInfo;
            List<HI_Fulfillment_Event__c> eventList = new List<HI_Fulfillment_Event__c>([Select id, Event_Type__c, id__c from HI_Fulfillment_Event__c where createddate>=:eventInfo.CreatedDate and createddate<:dtm and Employee_id__c=:eventInfo.Employee_Id__c and Event_Type__c in('employee_losing_eligibility','enrollment_ready_for_processing') ] );
            
            for(HI_Fulfillment_Event__c event : eventList){
                if(event.Event_Type__c=='employee_losing_eligibility'){
                    terminationExists=true;
                } else if (event.Event_Type__c=='enrollment_ready_for_processing'){
                    nheEventInfo = event;
                }
            }
            if(eventList.size() == 2 && terminationExists==true && nheEventInfo!=null){
                List<Case> caseList = new List<Case>([Select id from case where Integration_id__c=:nheEventInfo.Id__c and Status in ('Draft','New')] );
                for(Case c : caseList){
                    c.cancel_case__c=true;
                }
                if(caseList.size() > 0){
                    caseTriggerHelper.skipTrigger=true;
                    update caseList;
                }
            }
            HIFulfillmentEventTriggerHelper.skipTrigger=true;
            eventInfo.Enrollment_Unlocked_Processed__c =true;
            update eventInfo;
        }
    }
    
    global class updateInfo {
        global String id;	
    }
}