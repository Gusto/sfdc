/**
 * @name         ZPPayrollAuditTriggerHandler
 * @author       Sanjay Paryani
 * @date         11-24-2021
 * @description  Trigger Handler class that delegates tasks between ZPPayrollAuditTrigger and ZPPayrollAuditTriggerHelper
 * @test class   ZPPayrollAuditTriggerHelperTest
 */
public class ZPPayrollAuditTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**** To reset all skip trigger flags for  PayrollAudit****/
	public static void resetSkipTriggerFlags() {
		ZPPayrollAuditTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Overrided method from TriggerHandler - Handles ZP_Payroll_Audit__c Before Insert Context
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				ZPPayrollAuditTriggerHelper objHelper = new ZPPayrollAuditTriggerHelper();
				objHelper.processBeforeInsert(Trigger.new);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ZPPayrollAuditTriggerHandler', 'BeforeInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	/**
	 * @description Overrided method from TriggerHandler - Handles ZP_Payroll_Audit__c Before Update Context
	 * @author      Sanjay Paryani
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				ZPPayrollAuditTriggerHelper objHelper = new ZPPayrollAuditTriggerHelper();
				objHelper.processBeforeUpdate((Map<Id, ZP_Payroll_Audit__c>) Trigger.newMap, (Map<Id, ZP_Payroll_Audit__c>) Trigger.oldMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ZPPayrollAuditTriggerHandler', 'BeforeUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}
}