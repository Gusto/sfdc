/**
    Created by : Anand Singh
    Created Date : 17/01/2022
    Description: Trigger Handler that delegates tasks between ZPCompanyMigrationTrigger and ZPCompanyMigrationTriggerHelper
**/
public class ZPCompanyMigrationTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	public ZPCompanyMigrationTriggerHandler() {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : To reset all skip trigger flags for Order
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public static void resetSkipTriggerFlags() {
		ZPCompanyMigrationTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles Before Insert Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				ZPCompanyMigrationTriggerHelper objHelper = new ZPCompanyMigrationTriggerHelper();
				objHelper.processBeforeInsert((List<ZP_Company_Migration__c>) Trigger.new);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'ZPCompanyMigrationHandler',
					'BeforeInsert',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles After Insert Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				ZPCompanyMigrationTriggerHelper objHelper = new ZPCompanyMigrationTriggerHelper();
				objHelper.processAfterInsert((List<ZP_Company_Migration__c>) Trigger.new);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'ZPCompanyMigrationHandler',
					'AfterInsert',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles Before Update Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				ZPCompanyMigrationTriggerHelper objHelper = new ZPCompanyMigrationTriggerHelper();
				objHelper.processBeforeUpdate((Map<Id, ZP_Company_Migration__c>) Trigger.NewMap, (Map<Id, ZP_Company_Migration__c>) Trigger.oldMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'ZPCompanyMigrationHandler',
					'BeforeUpdate',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Handles After Update Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				ZPCompanyMigrationTriggerHelper objHelper = new ZPCompanyMigrationTriggerHelper();
				objHelper.processAfterUpdate((Map<Id, ZP_Company_Migration__c>) Trigger.NewMap, (Map<Id, ZP_Company_Migration__c>) Trigger.oldMap);
				if (Test.isRunningTest() && blnTestException) {
					Integer i = 1 / 0;
				}
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'ZPCompanyMigrationHandler',
					'AfterUpdate',
					'Exception On Line ' +
					objException.getLineNumber() +
					'-' +
					objException.getMessage(),
					objException.getStackTraceString()
				);
			}
		}
	}
}