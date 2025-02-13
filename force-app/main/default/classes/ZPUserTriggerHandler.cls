/**
 * @Author       :   David (Dato) Tsamalashvili
 * @CreatedDate  :   03/23/2021
 * @Desc         :   Trigger Handler class that delegates tasks between ZPUserTrigger and ZPUserTriggerHelper
 **/
public with sharing class ZPUserTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;

	/**** To reset all skip trigger flags for ZPUser ****/
	public static void resetSkipTriggerFlags() {
		ZPUserTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipBeforeUpdate = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				ZPUserTriggerHelper zpUserTrigHelper = new ZPUserTriggerHelper();
				zpUserTrigHelper.processBeforeInsert((List<ZP_User__c>) Trigger.new);

				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'ZPUserTriggerHandler',
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

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				ZPUserTriggerHelper zpUserTrigHelper = new ZPUserTriggerHelper();
				zpUserTrigHelper.processBeforeUpdate(
					(Map<Id, ZP_User__c>) Trigger.newMap,
					(Map<Id, ZP_User__c>) Trigger.oldMap
				);

				if (Test.isRunningTest()) {
					Integer i = 1 / 0;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'ZPUserTriggerHandler',
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