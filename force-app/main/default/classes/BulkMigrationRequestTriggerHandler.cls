/**
 * Trigger Handler that delegates tasks between BulkMigrationRequestTrigger and BulkMigrationRequestTriggerHelper
 * @author Anand K Singh
 * @since 04-27-2022
 * @see BulkMigrationReqTriggerHelperTest
 */
public with sharing class BulkMigrationRequestTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**** To reset all skip trigger flags for Lead ****/
	public static void resetSkipTriggerFlags() {
		BulkMigrationRequestTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				BulkMigrationRequestTriggerHelper objBMRTHelper = new BulkMigrationRequestTriggerHelper();
				objBMRTHelper.processBeforeInsert(Trigger.new);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException('BulkMigrationRequestTriggerHandler', 'BeforeInsert', objException);
			}
		}
	}

	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert Logic needs to be Skipped
		if (!blnSkipBeforeUpdate) {
			try {
				BulkMigrationRequestTriggerHelper objBMRTHelper = new BulkMigrationRequestTriggerHelper();
				objBMRTHelper.processAfterInsert((Map<Id, Bulk_Migration_Request__c>) Trigger.newMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException('BulkMigrationRequestTriggerHandler', 'AfterInsert', objException);
			}
		}
	}

	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				BulkMigrationRequestTriggerHelper objBMRTHelper = new BulkMigrationRequestTriggerHelper();
				objBMRTHelper.processBeforeUpdate((Map<Id, Bulk_Migration_Request__c>) Trigger.oldMap, (Map<Id, Bulk_Migration_Request__c>) Trigger.newMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException('BulkMigrationRequestTriggerHandler', 'BeforeUpdate', objException);
			}
		}
	}

	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		// Check if After Update Logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				BulkMigrationRequestTriggerHelper objBMRTHelper = new BulkMigrationRequestTriggerHelper();
				objBMRTHelper.processAfterUpdate((Map<Id, Bulk_Migration_Request__c>) Trigger.oldMap, (Map<Id, Bulk_Migration_Request__c>) Trigger.newMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException('BulkMigrationRequestTriggerHandler', 'AfterUpdate', objException);
			}
		}
	}
}