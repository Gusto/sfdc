/**
 * @name         TaskTriggerHandler
 * @author       Praveen Sethu
 * @date         05-27-2021
 * @description  Trigger Handler class that delegates tasks between TaskTrigger and TaskTriggerHelper
 * @see          TaskTriggerHelperTest
 **/

public class TaskTriggerHandler extends TriggerHandler {

	private List<Task> newRecords;
	private List<Task> oldRecords;
	private Map<Id, Task> newRecordsMap;
	private Map<Id, Task> oldRecordsMap;

	/**
	 * Constructor
	 * @author David Schach
	 */
    public TaskTriggerHandler() {
		super('TaskTriggerHandler');
		this.newRecords = (List<Task>)Trigger.new;
		this.oldRecords = (List<Task>)Trigger.old;
		this.newRecordsMap = (Map<Id, Task>)Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Task>)Trigger.oldMap;
    }


	// Context Specific Skip Flags
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Overrided method from TriggerHandler - Handles Task Before Insert Context
	 **/
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
				TaskTriggerHelper objHelper = new TaskTriggerHelper();
				objHelper.processBeforeInsert(newRecords);
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('TaskTriggerHandler', 'BeforeInsert', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
			}
		}
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Overrided method from TriggerHandler - Handles Task After Insert Context
	 **/
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
				TaskTriggerHelper objHelper = new TaskTriggerHelper();
				objHelper.processAfterInsert(newRecordsMap);
			} catch (Exception objEx) {
				String strExceptionMessage = objEx.getMessage();
				Boolean blnLogException = true;
				for (String strErrorToIgnore : TaskUtil.set_ValidationErrorsToIgnoreLogging) {
					if (strExceptionMessage.contains(strErrorToIgnore)) {
						blnLogException = false;
						break;
					}    
				}
				if (blnLogException) {
					ExceptionLogUtil.logException('TaskTriggerHandler', 'AfterInsert', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
				}
			}
		}
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Overrided method from TriggerHandler - Handles Task Before Update Context
	 **/
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
				TaskTriggerHelper objHelper = new TaskTriggerHelper();
				objHelper.processBeforeUpdate(newRecordsMap, oldRecordsMap);
			} catch (Exception objEx) {
				ExceptionLogUtil.logException('TaskTriggerHandler', 'BeforeUpdate', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
			}
		}
	}

	/**
	 * @author      Praveen Sethu & Veeresh
	 * @description Overrided method from TriggerHandler - Handles Task After Update Context
	 **/
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				if (blnTestException) {
					Integer intException = 0 / 0;
				}
				TaskTriggerHelper objHelper = new TaskTriggerHelper();
				objHelper.processAfterUpdate(newRecordsMap, oldRecordsMap);
			} catch (Exception objEx) {
				String strExceptionMessage = objEx.getMessage();
				Boolean blnLogException = true;
				for (String strErrorToIgnore : TaskUtil.set_ValidationErrorsToIgnoreLogging) {
					if (strExceptionMessage.contains(strErrorToIgnore)) {
						blnLogException = false;
						break;
					}    
				}
				if (blnLogException) {
					ExceptionLogUtil.logException('TaskTriggerHandler', 'AfterUpdate', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
				}
			}
		}
	}

	/**
	 * @author      David (Dato) Tsamalashvili
	 * @description Overrided method from TriggerHandler - Handles Task Before Delete Context
	 **/
	public override void beforeDelete() {
		try {
			TaskTriggerHelper objHelper = new TaskTriggerHelper();
			objHelper.processBeforeDelete(oldRecordsMap);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('TaskTriggerHandler', 'BeforeDelete', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}
}