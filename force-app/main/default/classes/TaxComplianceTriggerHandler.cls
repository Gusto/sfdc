/**
 * @name         TaxComplianceTriggerHandler
 * @author       Sindhu
 * @date         06/17/2024
 * @description  Handles the TaxComplianceTrigger
 **/
public class TaxComplianceTriggerHandler extends TriggerHandler {
    public List < Tax_Compliance__c > list_NewRecords;
    public List < Tax_Compliance__c > list_OldRecords;
    public Map < Id, Tax_Compliance__c > map_NewRecordsMap;
    public Map < Id, Tax_Compliance__c > map_OldRecordsMap;

    public TaxComplianceTriggerHandler() {
        this.list_NewRecords = (List < Tax_Compliance__c > ) Trigger.new;
        this.list_OldRecords = (List < Tax_Compliance__c > ) Trigger.old;
        this.map_NewRecordsMap = (Map < Id, Tax_Compliance__c > ) Trigger.newMap;
        this.map_OldRecordsMap = (Map < Id, Tax_Compliance__c > ) Trigger.oldMap;
    }
    // Context Specific Skip Flags
    public static Boolean blnSkipAfterInsert = false;
    public static Boolean blnSkipAfterUpdate = false;

    /**** To reset all skip trigger flags for Case ****/
    public static void resetSkipTriggerFlags() {
        TaxComplianceTriggerHelper.blnSkipTrigger = blnSkipAfterInsert = blnSkipAfterUpdate = false;
    }

    /**** Handles After Insert Context ****/
    public override void afterInsert() {
        // Check if After Insert logic needs to be skipped
        if (!blnSkipAfterInsert) {
            try {
                TaxComplianceTriggerHelper objHelper = new TaxComplianceTriggerHelper();
                objHelper.processAfterInsert(map_NewRecordsMap);
            } catch (Exception ex) {
                ExceptionLogUtil.logException('TaxComplianceTriggerHandler', 'AfterInsert', ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
    /**** Handles After Update Context ****/
    public override void afterUpdate() {
        // Check if After Update logic needs to be skipped
        if (!blnSkipAfterUpdate) {
            try {
                TaxComplianceTriggerHelper objHelper = new TaxComplianceTriggerHelper();
                objHelper.processAfterUpdate(map_OldRecordsMap, map_NewRecordsMap);
            } catch (Exception ex) {
                ExceptionLogUtil.logException('TaxComplianceTriggerHandler', 'AfterUpdate', ex.getMessage(), ex.getStackTraceString());
            }
        }
    }
}