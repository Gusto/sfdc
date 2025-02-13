/**
    Created by : Aurobind Ravichandran
    Created Date : 10/29/2020 
**/
public class ZPEmployeeTriggerHandler extends TriggerHandler{
    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;
    public static Boolean blnSkipAfterDelete = false;

    /**** To reset all skip trigger flags for ZP_Employee__c ****/
    public static void resetSkipTriggerFlags(){
        ZPEmployeeTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = 
            		blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
    }
    
    /**** Handles After Insert Context ****/
    public override void afterInsert(){
        // Check if After Insert logic needs to be skipped
        if(!blnSkipAfterInsert){
            ZPEmployeeTriggerHelper objHelper = new ZPEmployeeTriggerHelper();
            objHelper.processAfterInsert((Map<Id, ZP_Employee__c>)Trigger.newMap);
        }
    }
    
    /**** Handles After Update Context ****/
    public override void afterUpdate(){
        // Check if After Update logic needs to be skipped
        if(!blnSkipAfterUpdate){
			ZPEmployeeTriggerHelper objHelper = new ZPEmployeeTriggerHelper();
            objHelper.processAfterUpdate((Map<Id, ZP_Employee__c>)Trigger.oldMap, (Map<Id, ZP_Employee__c>)Trigger.newMap);
        }
    }
}