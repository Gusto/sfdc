@RestResource(urlMapping='/FulfillmentEvent/*')
global with sharing class HiFulfillmentEventHandler {

@HttpPost   
    global static String createNewCase(String event_id, String event_type, String event_info, String ticket_owner, String company_id, String employee_id) {
    
        //HI Fulfillment Events Processing State, Message//
        HI_Fulfillment_Event__c objHIFulfill = new HI_Fulfillment_Event__c(
            Id__c = event_id,
            Event_Type__c = event_type,
            Event_Info__c = event_info,
            Company_id__c=company_id,
            Ops_Owner__c = ticket_owner,
            Employee_id__c = employee_id
        );
        insert objHIFulfill;
        return null;
    }
}