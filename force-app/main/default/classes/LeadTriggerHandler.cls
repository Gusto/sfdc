/**
    @Author       :   David (Dato) Tsamalashvili
    @CreatedDate  :   10/06/2020
    @Desc         :   Trigger Handler class that delegates tasks between LeadTrigger and LeadTriggerHelper
**/
public with sharing class LeadTriggerHandler extends TriggerHandler{

    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;
    public static Boolean blnSkipAfterDelete = false;

    /**** To reset all skip trigger flags for Lead ****/
    public static void resetSkipTriggerFlags(){
        LeadTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = 
                    blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
    }

    /**** Handles Before Insert Context ****/
    public override void beforeInsert(){
        // Check if Before Insert Logic needs to be Skipped
        if(!blnSkipBeforeInsert){
            try{
                LeadTriggerHelper leadTrigHelper = new LeadTriggerHelper();
                leadTrigHelper.processBeforeInsert(Trigger.new);
            }catch(Exception ex){
                ExceptionLogUtil.logException('LeadTriggerHandler', 'BeforeInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    
    /**** Handles After Insert Context ****/
    public override void afterInsert(){
        // Check if After Insert Logic needs to be Skipped
        if(!blnSkipBeforeUpdate){
            try{
                LeadTriggerHelper leadTrigHelper = new LeadTriggerHelper();
                leadTrigHelper.processAfterInsert(Trigger.new);
            }catch(Exception ex){
                ExceptionLogUtil.logException('LeadTriggerHandler', 'AfterInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    
    /**** Handles Before Update Context ****/
    public override void beforeUpdate(){
        // Check if Before Update Logic needs to be skipped
        if(!blnSkipBeforeUpdate){
            try{
                LeadTriggerHelper leadTrigHelper = new LeadTriggerHelper();
                leadTrigHelper.processBeforeUpdate((List<Lead>)Trigger.new, (Map<Id, Lead>)Trigger.oldMap);
            }catch(Exception ex){
                ExceptionLogUtil.logException('LeadTriggerHandler', 'BeforeUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    
    /**** Handles After Update Context ****/
    public override void afterUpdate(){
        // Check if After Update Logic needs to be skipped
        if(!blnSkipAfterUpdate){
            try{
                LeadTriggerHelper leadTrigHelper = new LeadTriggerHelper();
                leadTrigHelper.processAfterUpdate((List<Lead>)Trigger.new, (Map<Id, Lead>)Trigger.oldMap);
            }catch(Exception ex){
                ExceptionLogUtil.logException('LeadTriggerHandler', 'AfterUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
}