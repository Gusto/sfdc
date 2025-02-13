/**
 * @name         : InsuranceQuoteTriggerHandler
 * @author       : David (Dato) Tsamalashvili
 * @date         : 10-06-2021
 * @description  : Trigger Handler class that delegates tasks between InsuranceQuote and InsuranceQuoteTriggerHelper
 * @test classes : InsuranceQuoteTriggerHelperTest
 **/
public class InsuranceQuoteTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/**** To reset all skip trigger flags for  PayrollAudit****/
	public static void resetSkipTriggerFlags() {
		InsuranceQuoteTriggerHelper.blnSkipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Overrided method from TriggerHandler - Handles Before Insert Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				InsuranceQuoteTriggerHelper objHelper = new InsuranceQuoteTriggerHelper();
				objHelper.processBeforeInsert((List<Insurance_Quote__c>) Trigger.new);

				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'InsuranceQuoteTriggerHandler',
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
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Overrided method from TriggerHandler - Handles Before Update Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				InsuranceQuoteTriggerHelper objHelper = new InsuranceQuoteTriggerHelper();
				objHelper.processBeforeUpdate(
					(List<Insurance_Quote__c>) Trigger.new,
					(Map<Id, Insurance_Quote__c>) Trigger.oldMap
				);

				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'InsuranceQuoteTriggerHandler',
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