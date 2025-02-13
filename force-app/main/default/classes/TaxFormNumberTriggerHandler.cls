/**
 * @author Pravesh Rana
 * @description handler class for TaxFormNumberTrigger
 * @TestClass TaxFormNumberTriggerHelperTest
 */
public class TaxFormNumberTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;

	/**** To reset all skip trigger flags for Case ****/
	public static void resetSkipTriggerFlags() {
		TaxFormNumberTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				TaxFormNumberTriggerHelper objHelper = new TaxFormNumberTriggerHelper();
				objHelper.processBeforeInsert((List<Tax_Form_Number__c>) Trigger.new);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TaxFormNumberTriggerHandler', 'beforeInsert', ex);
			}
		}
	}

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				TaxFormNumberTriggerHelper objHelper = new TaxFormNumberTriggerHelper();
				objHelper.processBeforeUpdate((Map<Id, Tax_Form_Number__c>) Trigger.oldMap, (Map<Id, Tax_Form_Number__c>) Trigger.newMap);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TaxFormNumberTriggerHandler', 'beforeUpdate', ex);
			}
		}
	}
}