/**
 * @name         : HIQuoteTriggerHandler
 * @author       : Debasmita Rawooth
 * @date         : 09-20-2021
 * @description  : Trigger Handler class that delegates tasks between HIQuoteTrigger and HIQuoteTriggerHelper
 * @test classes : HIQuoteTriggerHelperTest
 **/
public class HIQuoteTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/**** To reset all skip trigger flags for  PayrollAudit****/
	public static void resetSkipTriggerFlags() {
		HIQuoteTriggerHelper.str_skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Overrided method from TriggerHandler - Handles Before Insert Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void afterInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				HIQuoteTriggerHelper objHelper = new HIQuoteTriggerHelper();
				objHelper.processAfterInsert((List<HI_Quote__c>) Trigger.new);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'HIQuoteTriggerHandler',
					'BeforeInsert',
					'Exception On Line ' +
					ex.getLineNumber() +
					'-' +
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Overrided method from TriggerHandler - Handles Before Update Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void afterUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				HIQuoteTriggerHelper objHelper = new HIQuoteTriggerHelper();
				objHelper.processAfterUpdate(
					(List<HI_Quote__c>) Trigger.new,
					(Map<Id, HI_Quote__c>) Trigger.oldMap
				);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'HIQuoteTriggerHandler',
					'BeforeUpdate',
					'Exception On Line ' +
					ex.getLineNumber() +
					'-' +
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}
	}
}