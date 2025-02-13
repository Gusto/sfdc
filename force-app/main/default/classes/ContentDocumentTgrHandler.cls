/**
    @Author       :   
    @CreatedDate  :   
    @Desc         :   Trigger Handler class that delegates tasks between ContentDocumentTrigger and ContentDocumentTriggerHelper
**/
public with sharing class ContentDocumentTgrHandler extends TriggerHandler {

    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipBeforeUpdate = false;
    public static Boolean blnSkipAfterUpdate = false;
    public static Boolean blnSkipBeforeDelete = false;
    public static Boolean blnSkipAfterDelete = false;

    /**** To reset all skip trigger flags for Lead ****/
    public static void resetSkipTriggerFlags() {
        ContentDocumentTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
    }

    /**** Handles Before Delete Context ****/
    public override void beforeDelete() {
        // Check if Before Delete Logic needs to be Skipped
        if(!blnSkipBeforeDelete){
            try {
                ContentDocumentTriggerHelper contentDocTrgHelper = new ContentDocumentTriggerHelper();
                contentDocTrgHelper.processBeforeDelete(Trigger.old);
            } catch(Exception ex) {
                ExceptionLogUtil.logException('ContentDocumentTgrHandler', 'BeforeDelete', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    
}