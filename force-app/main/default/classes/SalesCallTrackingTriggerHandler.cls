/**
    @Author       :   David
    @CreatedDate  :   3-December-2020
    @Desc         :   Trigger Handler class that delegates tasks between SalesCallTrackingTrigger and SalesCallTrackingTriggerHelper
**/
public with sharing class SalesCallTrackingTriggerHandler extends TriggerHandler{

    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;
    public static Boolean blnSkipAfterDelete = false;

    /**** To reset all skip trigger flags for SalesCallTracking ****/
    public static void resetSkipTriggerFlags(){
        SalesCallTrackingTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = 
                    blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
    }

    /**** Handles Before Insert Context ****/
    /*public override void beforeInsert(){
        // Check if Before Insert Logic needs to be Skipped
        if(!blnSkipBeforeInsert){
            try{
                //to call before insert
            }catch(Exception ex){
                ExceptionLogUtil.logException('SalesCallTrackingTriggerHandler', 'BeforeInsert', ex.getMessage() + ' ON Line ' + ex.getLineNumber(), ex.getStackTraceString());
            }
        }
    }*/
    
    /**** Handles After Insert Context ****/
    /*public override void afterInsert(){
        // Check if After Insert Logic needs to be Skipped
        if(!blnSkipBeforeUpdate){
            try{
                //to call after insert
            }catch(Exception ex){
                ExceptionLogUtil.logException('SalesCallTrackingTriggerHandler', 'AfterInsert', ex.getMessage() + ' ON Line ' + ex.getLineNumber(), ex.getStackTraceString());
            }
        }
    }*/
    
    /**** Handles Before Update Context ****/
    public override void beforeUpdate(){
        // Check if Before Update Logic needs to be skipped
        if(!blnSkipBeforeUpdate){
            try{
                SalesCallTrackingTriggerHelper salesCallTrackingTrigger = new SalesCallTrackingTriggerHelper();
                salesCallTrackingTrigger.processBeforeUpdate((Map<Id, Sales_Call_Tracking__c>)Trigger.oldMap, (List<Sales_Call_Tracking__c>)Trigger.new);
            }catch(Exception ex){
                ExceptionLogUtil.logException('SalesCallTrackingTriggerHandler', 'BeforeUpdate', ex.getMessage() + ' ON Line ' + ex.getLineNumber(), ex.getStackTraceString());
            }
        }
    }
    
    /**** Handles After Update Context ****/
    /*public override void afterUpdate(){
        // Check if After Update Logic needs to be skipped
        if(!blnSkipAfterUpdate){
            try{
                //to process after update
            }catch(Exception ex){
                ExceptionLogUtil.logException('SalesCallTrackingTriggerHandler', 'AfterUpdate', ex.getMessage() + ' ON Line ' + ex.getLineNumber(), ex.getStackTraceString());
            }
        }
    }*/
}