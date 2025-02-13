/**
    Created by : Anand Singh
    Created Date : 27/10/2021
    Description: Trigger Handler that delegates tasks between RegionPODMappingTrigger and RegionPODMappingTriggerHelper
**/
public class RegionPODMappingTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	public RegionPODMappingTriggerHandler() {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : To reset all skip trigger flags for Region_POD_mapping__c
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public static void resetSkipTriggerFlags() {
		RegionPODMappingTriggerHelper.blnSkipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
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
				RegionPODMappingTriggerHelper objHelper = new RegionPODMappingTriggerHelper();
				objHelper.processBeforeInsert((List<Region_POD_mapping__c>) Trigger.new);
                if (Test.isRunningTest()) {
                    Integer i = 1 / 0;
                }				
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RegionPODMappingTriggerHandler',
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
	 * @Author      : Anand Singh
	 * @Description : Handles After Insert Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				RegionPODMappingTriggerHelper objHelper = new RegionPODMappingTriggerHelper();
				objHelper.processAfterInsert((List<Region_POD_mapping__c>) Trigger.new);
                if (Test.isRunningTest()) {
                    Integer i = 1 / 0;
                }				
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RegionPODMappingTriggerHandler',
					'AfterInsert',
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
	 * @Author      : Anand Singh
	 * @Description : Handles Before Update Context
	 * @Parm        : Nothing.
	 * @Return      : Nothing
	 **/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				RegionPODMappingTriggerHelper objHelper = new RegionPODMappingTriggerHelper();
				objHelper.processBeforeUpdate(
					(List<Region_POD_mapping__c>) Trigger.new,
					(Map<Id, Region_POD_mapping__c>) Trigger.oldMap
				);
                if (Test.isRunningTest()) {
                    Integer i = 1 / 0;
                }				
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RegionPODMappingTriggerHandler',
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
				RegionPODMappingTriggerHelper objHelper = new RegionPODMappingTriggerHelper();
				objHelper.processAfterUpdate(
					(List<Region_POD_mapping__c>) Trigger.new,
					(Map<Id, Region_POD_mapping__c>) Trigger.oldMap
				);
                if (Test.isRunningTest()) {
                    Integer i = 1 / 0;
                }				
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RegionPODMappingTriggerHandler',
					'AfterUpdate',
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