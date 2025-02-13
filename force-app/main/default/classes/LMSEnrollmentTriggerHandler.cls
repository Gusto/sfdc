/*
 * @name         LMSEnrollmentTriggerHandler
 * @author       Prity Kumari
 * @date         2022-07-19
 * @description  Delegates tasks to LMSEnrollmentTriggerHelper
 * @test classes LMSEnrollmentTriggerHelperTest
 */

public with sharing class LMSEnrollmentTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;

	/*
	 * @author:         Prity Kumari
	 * @description:    Handles Before Insert Context
	 * @parm:
	 * @return:
	 */
	public override void beforeInsert() {
		// Check if Before Insert Logic needs to be Skipped
		if (!blnSkipBeforeInsert) {
			try {
				LMSEnrollmentTriggerHelper objHelper = new LMSEnrollmentTriggerHelper();
				objHelper.processBeforeInsert((List<intellumapp__IntellumEnrollment__c>) Trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('LMSEnrollmentTriggerHandler', 'beforeInsert', objException.getMessage(), objException.getStackTraceString());
			}
		}
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    Handles After Insert Context
	 * @parm:
	 * @return:
	 */
	public override void afterInsert() {
		// Check if After Insert Logic needs to be Skipped
		if (!blnSkipAfterInsert) {
			try {
				LMSEnrollmentTriggerHelper objHelper = new LMSEnrollmentTriggerHelper();
				objHelper.processAfterInsert((List<intellumapp__IntellumEnrollment__c>) Trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('LMSEnrollmentTriggerHandler', 'afterInsert', objException.getMessage(), objException.getStackTraceString());
			}
		}
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    Handles Before Update
	 * @parm:
	 * @return:
	 */
	public override void beforeUpdate() {
		// Check if Before Update Logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			// LMSEnrollment Before Update Logic
			try {
				LMSEnrollmentTriggerHelper objHelper = new LMSEnrollmentTriggerHelper();
				objHelper.processBeforeUpdate((List<intellumapp__IntellumEnrollment__c>) Trigger.new, (Map<Id, intellumapp__IntellumEnrollment__c>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('LMSEnrollmentTriggerHandler', 'beforeUpdate', objException.getMessage(), objException.getStackTraceString());
			}
		}
	}

	/*
	 * @author:         Prity Kumari
	 * @description:    Handles After Update
	 * @parm:
	 * @return:
	 */
	public override void afterUpdate() {
		// Check if After Update Logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			// LMSEnrollment After Update Logic
			try {
				LMSEnrollmentTriggerHelper objHelper = new LMSEnrollmentTriggerHelper();
				objHelper.processAfterUpdate((List<intellumapp__IntellumEnrollment__c>) Trigger.new, (Map<Id, intellumapp__IntellumEnrollment__c>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException('LMSEnrollmentTriggerHandler', 'afterUpdate', objException.getMessage(), objException.getStackTraceString());
			}
		}
	}
}