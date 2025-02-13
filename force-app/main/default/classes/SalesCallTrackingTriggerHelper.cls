/**
* Created By        :   Neha
* Created Date      :   17-Nov-2020
* Desciption        :   Helper for SalesCallTrackingTrigger
* Test Classes      :   CreateSalesCallTrackingControllerTest
*/
public with sharing class SalesCallTrackingTriggerHelper {
    public static Boolean skipTrigger = false;
    static final List<Id> RECTYPES_SALES_CALL_TRACKING = SalesCallTrackingUtil.BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS?.values();
    static final String EVENT_TYPE_PHONE = 'Phone';

    //Before Update functionality
    public void processBeforeUpdate(Map<Id, Sales_Call_Tracking__c> map_OldTracking, List<Sales_Call_Tracking__c> list_newTracking){
        createCaseAuditLogForRecordsProcessedByWorkato(map_OldTracking, list_newTracking);
    }
    /**
    * Created By        :   Neha
    * Created Date      :   18-Nov-2020
    * Desciption        :   Create case audit logs for processed Sales Call Tracking records
    */
    public void createCaseAuditLogForRecordsProcessedByWorkato(Map<Id, Sales_Call_Tracking__c> map_OldTracking, List<Sales_Call_Tracking__c> list_newTracking){
        Map<String, Case_Audit_Log__c> map_AuditLogToInsert = new Map<String, Case_Audit_Log__c>();

        for(Sales_Call_Tracking__c objTrack : list_newTracking){
            Sales_Call_Tracking__c objOldTrack = map_OldTracking.get(objTrack.Id);

            if (RECTYPES_SALES_CALL_TRACKING.contains(objTrack.RecordTypeId)
                && objOldTrack.Processed_By_Workato__c != objTrack.Processed_By_Workato__c
                && objTrack.Processed_By_Workato__c == true
                && objTrack.Call_Start_Time__c != null
                && objTrack.Call_End_Time__c != null
                && String.isNotBlank(objTrack.Case__c)
                && String.isNotBlank(objTrack.Genesys_Integration_Id__c)
                && !map_AuditLogToInsert.containsKey(objTrack.Genesys_Integration_Id__c)) {
                map_AuditLogToInsert.put(objTrack.Genesys_Integration_Id__c,
                                            new Case_Audit_Log__c(Genesys_Id__c = objTrack.Genesys_Integration_Id__c,
                                                                Direction__c = objTrack.Call_Direction__c,
                                                                To_Date_Time__c = objTrack.Call_End_Time__c,
                                                                From_Date_Time__c = objTrack.Call_Start_Time__c,
                                                                Case__c = objTrack.Case__c,
                                                                Touchpoint__c = 1,
                                                                Event_Type__c = EVENT_TYPE_PHONE,
                                                                Advocate__c = objTrack.OwnerId,
                                                                Duration_In_Seconds__c = objTrack.Call_Duration__c*60
                                                                ));
            }
        }

        if(!map_AuditLogToInsert.isEmpty()){
            upsert map_AuditLogToInsert.values() Genesys_Id__c;
        }
    }
}