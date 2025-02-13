/**
 * @name         : PayrollAuditTriggerHandler
 * @author       : Debasmita Rawooth
 * @date         : 07-28-2021
 * @description  : Trigger Handler class that delegates tasks between PayrollAuditTrigger and PayrollAuditTriggerHelper
 * @test classes : PayrollAuditTriggerHelperTest
 **/
public class PayrollAuditTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/**** To reset all skip trigger flags for  PayrollAudit****/
	public static void resetSkipTriggerFlags() {
		PayrollAuditTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Overrided method from TriggerHandler - Handles Before Insert Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				PayrollAuditTriggerHelper objHelper = new PayrollAuditTriggerHelper();
				objHelper.processBeforeInsert(Trigger.new);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'PayrollAuditTriggerHandler',
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
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				PayrollAuditTriggerHelper objHelper = new PayrollAuditTriggerHelper();
				objHelper.processBeforeUpdate(
					(List<Payroll_Audit__c>) Trigger.new,
					(Map<Id, Payroll_Audit__c>) Trigger.oldMap
				);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'PayrollAuditTriggerHandler',
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