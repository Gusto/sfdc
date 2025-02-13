/**
* @name         : EmailMessageTriggerHandler
* @author       : Ankit CS
* @date         : 12-21-2021
* @description  : Trigger Handler that delegates tasks between EmailMessageTrigger and EmailMessageTriggerHelper
* @test classes : EmailMessageTriggerHandlerTest
**/
public class EmailMessageTriggerHandler extends TriggerHandler {
	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnSkipAfterUnDelete = false;
	
	/**** To reset all skip trigger flags for Opportunity ****/
	public static void resetSkipTriggerFlags() {
		EmailMessageTriggerHelper.skipTrigger = blnSkipBeforeInsert = blnSkipAfterInsert = blnSkipBeforeUpdate = 
			blnSkipAfterUpdate = blnSkipBeforeDelete = blnSkipAfterDelete = false;
	}
	
	/**** Handles Before Insert Context ****/
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}

				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnBeforeInsert((List<EmailMessage>) Trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'beforeInsert', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles After Insert Context ****/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}

				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnAfterInsert((Map<Id, EmailMessage>) Trigger.newMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'afterInsert', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles Before Update Context ****/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}

				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnBeforeUpdate((Map<Id, EmailMessage>) Trigger.oldMap, (Map<Id, EmailMessage>) Trigger.newMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'beforeUpdate', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles After Update Context ****/
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}

				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnAfterUpdate((Map<Id, EmailMessage>) Trigger.oldMap, (Map<Id, EmailMessage>) Trigger.newMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'afterUpdate', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles Before Delete Context ****/
	public override void beforeDelete() {
		// Check if Before Delete logic needs to be skipped
		if (!blnSkipBeforeDelete) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}
				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnBeforeDelete((List<EmailMessage>) Trigger.old, (Map<Id, EmailMessage>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'beforeDelete', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles After Delete Context ****/
	public override void afterDelete() {
		// Check if  After Delete logic needs to be skipped
		if (!blnSkipAfterDelete) {
			try {
				if (
					Test.isRunningTest() && 
					EmailMessageTriggerHelperTest.blnThrowException
				) {
					throw new NullPointerException();
				}
				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnAfterDelete((List<EmailMessage>) Trigger.old, (Map<Id, EmailMessage>) Trigger.oldMap);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'afterDelete', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
	
	/**** Handles After Un-Delete Context ****/
	public override void afterUndelete() {
		// Check if  After Un-Delete logic needs to be skipped
		if (!blnSkipAfterUnDelete) {
			try {
				EmailMessageTriggerHelper objHelper = new EmailMessageTriggerHelper();
				objHelper.OnUndelete((List<EmailMessage>) Trigger.new);
			} catch (Exception objException) {
				ExceptionLogUtil.logException(
					'EmailMessageTriggerHandler', 
					'afterUndelete', 
					'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
					objException.getStackTraceString()
				);
			}
		}
	}
}