/**
 * @author Elavarasan N
 * @description handler class for TaxNoticeIndexTrigger
 * @see TaxNoticeIndexTriggerHelperTest
 */
public class TaxNoticeIndexTriggerHandler extends TriggerHandler {
    // Context Specific Skip Flags
    public static Boolean blnSkipBeforeInsert = false;
    public static Boolean blnSkipAfterInsert = false;

    /**** Handles Before Insert Context ****/
    public override void beforeInsert() {
        // Check if After Insert logic needs to be skipped
        if (!blnSkipBeforeInsert) {
            try {
                TaxNoticeIndexTriggerHelper objHelper = new TaxNoticeIndexTriggerHelper();
                objHelper.processBeforeInsert((List<Tax_Notice_Index__c>) Trigger.new);
            } catch (Exception objException) {
                ExceptionLogUtil.logException('TaxNoticeIndexTriggerHandler', 'beforeInsert', objException.getMessage(), objException.getStackTraceString());
            } 
        }
    }

    /**** Handles After Insert Context ****/
    public override void afterInsert() {
        // Check if After Insert logic needs to be skipped
        if (!blnSkipAfterInsert) {
            try {
                TaxNoticeIndexTriggerHelper objHelper = new TaxNoticeIndexTriggerHelper();
                objHelper.processAfterInsert((Map<Id, Tax_Notice_Index__c>) Trigger.newMap);
            } catch (Exception objException) {
                ExceptionLogUtil.logException('TaxNoticeIndexTriggerHandler', 'afterInsert', objException.getMessage(), objException.getStackTraceString());
            }
        }
    }
}