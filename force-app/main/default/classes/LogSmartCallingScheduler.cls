/**
 * @name         : LogSmartCallingScheduler
 * @description  : Scheduled code to process activities without call duration. To be run nightly.
 * @test classes : LogSmartCallingControllerLEXTest.testDoCalculations
 **/
public without sharing class LogSmartCallingScheduler implements Schedulable {
	public static final String TASK_STATUS_CONNECT = 'Connect';
	public static final String TASK_STATUS_VOICEMAIL = 'Voicemail';
	public static final Set<String> TASK_STATUSES = new Set<String>{ TASK_STATUS_CONNECT, TASK_STATUS_VOICEMAIL };
	public static Boolean blnTestException = false;
	public static Id CX_ONE_INTEGRATION_USER_ID = Configuration_Settings__c.getOrgDefaults()?.CXOne_Integration_User_Id__c;
	public Integer intLimit = 3000;

	//Default Constructor
	public LogSmartCallingScheduler() {
	}

	//Parameterized Constructor to accept query limit
	public LogSmartCallingScheduler(Integer intLimit) {
		this.intLimit = intLimit;
	}

	/**
	 * @description Execute method of the scheduler.
	 * @param       Schedulable context
	 **/
	public void execute(SchedulableContext sc) {
		try {
			//Fetch tasks without call duration
			List<Task> list_tasksToProcess = [
				SELECT Id, CallDurationInSeconds, Date_Completed__c, Start_Date__c, Genesys_Interaction_Id__c, CreatedDate, CreatedById, Description, CallDisposition
				FROM Task
				WHERE CallDurationInSeconds = NULL AND Genesys_Interaction_Id__c != NULL AND Status IN :TASK_STATUSES AND (NOT Genesys_Interaction_Id__c LIKE 'FK-%')
				ORDER BY CreatedDate DESC
				LIMIT :intLimit
			];

			Map<String, Task> map_GenesysInteractionIdToTask = new Map<String, Task>();
			Map<Id, Task> map_tasksToUpdate = new Map<Id, Task>();
			Map<String, Nice_Interaction__c> map_NiceInteractionsToUpdate = new Map<String, Nice_Interaction__c>();
			List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();
			if (!list_tasksToProcess.isEmpty()) {
				for (Task objtask : list_tasksToProcess) {
					map_GenesysInteractionIdToTask.put(objtask.Genesys_Interaction_Id__c, objTask);
				}
				//If tasks are found, fetch nice interactions for the tasks and update the tasks with call duration, calculated start and end dates
				for (Nice_Interaction__c objNiceInteraction : [
					SELECT Id, ContactID__c, Call_Duration_in_Sec__c, Call_Start_Date_and_Time__c, Call_End_Date_and_Time__c, Processing_State__c, Retry_Process_Count__c, Comment__c, Call_Result__c
					FROM Nice_Interaction__c
					WHERE ContactID__c IN :map_GenesysInteractionIdToTask.keySet()
				]) {
					Task objTask = map_GenesysInteractionIdToTask.get(objNiceInteraction.ContactID__c);
					objTask.CallDurationInSeconds = String.isNotBlank(objNiceInteraction.Call_Duration_in_Sec__c) ? Integer.valueOf(objNiceInteraction.Call_Duration_in_Sec__c) : null;
					objTask.Start_Date__c = String.isNotBlank(objNiceInteraction.Call_Start_Date_and_Time__c)
						? LogSmartCallingControllerLEX.getCalculatedDateTime(objNiceInteraction.Call_Start_Date_and_Time__c)
						: null;
					objTask.Date_Completed__c = String.isNotBlank(objNiceInteraction.Call_End_Date_and_Time__c)
						? LogSmartCallingControllerLEX.getCalculatedDateTime(objNiceInteraction.Call_End_Date_and_Time__c)
						: null;

					if (objTask.CreatedById == CX_ONE_INTEGRATION_USER_ID || Test.isRunningTest()) {
						objTask.Description = String.isBlank(objTask.Description) ? objNiceInteraction.Comment__c : objTask.Description;
						objTask.CallDisposition = String.isBlank(objTask.CallDisposition) ? objNiceInteraction.Call_Result__c : objTask.CallDisposition;
					}

					//Task is updated as per the latest nice interaction
					map_tasksToUpdate.put(objTask.Id, objTask);
					//Update nice interaction processing state
					objNiceInteraction.Processing_State__c = LogSmartCallingUtil.PROCESSED_STATE;
					map_NiceInteractionsToUpdate.put(objTask.Genesys_Interaction_Id__c, objNiceInteraction);
				}
				if (!map_tasksToUpdate.values().isEmpty()) {
					//Skip task trigger and attempt update
					TaskTriggerHelper.skipTrigger = true;
					Database.SaveResult[] list_updateResults = Database.update(map_tasksToUpdate.values(), false);
					for (Integer i = 0; i < list_updateResults.size(); i++) {
						Database.SaveResult objSR = list_updateResults[i];
						//Create exception logs for failed updates
						if (!objSR.isSuccess() || blnTestException) {
							Exception_Log__c objLog = new Exception_Log__c(
								Type__c = 'ERROR',
								Class_Name__c = 'LogSmartCallingScheduler',
								Method_Name__c = 'Tasks update',
								Record_ID__c = objSR.getId(),
								Message__c = blnTestException ? null : objSR.getErrors()[0].getMessage()
							);
							list_ExceptionLogs.add(objLog);
							//Update nice interaction processing state to error for failed tasks
							if (map_NiceInteractionsToUpdate.containsKey(map_tasksToUpdate.values()[i].Genesys_Interaction_Id__c)) {
								Nice_Interaction__c objNiceInteraction = map_NiceInteractionsToUpdate.get(map_tasksToUpdate.values()[i].Genesys_Interaction_Id__c);
								objNiceInteraction.Processing_State__c = LogSmartCallingUtil.ERROR_STATE;
								map_NiceInteractionsToUpdate.put(map_tasksToUpdate.values()[i].Genesys_Interaction_Id__c, objNiceInteraction);
							}
						}
					}
					TaskTriggerHelper.skipTrigger = false;
				}
				//Update nice interactions
				if (!map_NiceInteractionsToUpdate.values().isEmpty()) {
					update map_NiceInteractionsToUpdate.values();
				}
				//Insert exception logs
				if (!list_ExceptionLogs.isEmpty()) {
					insert list_ExceptionLogs;
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('LogSmartCallingScheduler', 'execute', objException.getMessage(), objException.getStackTraceString());
		}
	}
}