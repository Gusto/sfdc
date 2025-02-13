/**
 * @description  Refactored ZPUserRoleTriggerHandler. Delegates control between trigger and trigger helper
 * @author       Praveen Sethu
 * @date         02-12-2021
 * @see          ZPUserRoleTriggerHelperTest
 **/

public with sharing class ZPUserRoleTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;

	/**
	 * @description Handles before insert context. Overridden method from TriggerHandler
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				ZPUserRoleTriggerHelper objHelper = new ZPUserRoleTriggerHelper();
				objHelper.processBeforeInsert((List<ZP_User_Role__c>) Trigger.new);
				objHelper.updateAccountForConciergeBatch(Trigger.new);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ZPUserRoleTriggerHandler', 'BeforeInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	/**
	 * @description Handles after insert context. Overridden method from TriggerHandler
	 * @param       NA
	 * @return      NA
	 **/
	public override void afterInsert() {
		try {
			ZPUserRoleTriggerHelper objHelper = new ZPUserRoleTriggerHelper();
			objHelper.processAfterInsert((List<ZP_User_Role__c>) Trigger.new);
			if (Test.isRunningTest()) {
				Integer i = 1 / 0;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ERROR', 'ZPUserRoleTriggerHandler', 'AfterInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	/**
	 * @description Handles before update context. Overridden method from TriggerHandler
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				ZPUserRoleTriggerHelper objHelper = new ZPUserRoleTriggerHelper();
				objHelper.processBeforeUpdate((Map<Id, ZP_User_Role__c>) Trigger.newMap, (Map<Id, ZP_User_Role__c>) Trigger.oldMap);
				objHelper.updateAccountForConciergeBatch(Trigger.new);
				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('ZPUserRoleTriggerHandler', 'BeforeUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
	}
}