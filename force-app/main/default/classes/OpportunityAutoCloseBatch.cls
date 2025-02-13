/**
 * @description  Used for closing opportunities that are older than a certain age and have not been updated in a while.
 * @date         03-18-2024
 * @see          OpportunityAutoCloseBatchTest
 **/
public class OpportunityAutoCloseBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	public static Boolean blnTestException = false;
	public static Boolean blnTestError = false;
	public static final String CLOSED_LOST = 'Closed Lost';
	public static final String SFDC_ADMINISTRATIVE = 'SFDC Administrative';
	public String strTeam = 'SBIZ';
	Opportunity_Auto_Close_Settings__mdt objAutoCloseSetting = Opportunity_Auto_Close_Settings__mdt.getAll().get(strTeam);
	public List<Exception_Log__c> list_ExceptionLogs = new List<Exception_Log__c>();

	//Parameterized Constructor to accept team name
	public OpportunityAutoCloseBatch(String strTeam) {
		this.strTeam = strTeam;
		this.objAutoCloseSetting = Opportunity_Auto_Close_Settings__mdt.getAll().get(strTeam);
	}

	//Default Constructor
	public OpportunityAutoCloseBatch() {
	}

	/**
	 * @description Start method of the batch to get the list of opportunities that need to be closed.
	 *              Fetches the opportunities that fit the criteria for auto close.
	 * @param       Batchable context
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		Date dtOppAgeCutoff = Date.today().addDays(-(Integer) objAutoCloseSetting.Opportunity_Age__c);
		Date dtLastLoginCutoff = Date.today().addDays(-(Integer) objAutoCloseSetting.Last_Login_Days_Ago__c);
		Integer intLastOnboardingStep = (Integer) objAutoCloseSetting.Last_Completed_Onboarding_Step__c;
		String strBatchQuery =
			'SELECT Id, StageName, Stage_Detail__c FROM Opportunity ' +
			'WHERE IsClosed = false AND CreatedDate < :dtOppAgeCutoff AND Account.Last_Login_Time__c < :dtLastLoginCutoff AND Days_Since_Last_Set_Up_Step__c > :intLastOnboardingStep ' +
			'AND (Anchor_Pay_Date__c = null OR Anchor_Pay_Date__c < today)';
		// Add Record Type and Role filters if they are set in the metadata
		if (String.isNotBlank(objAutoCloseSetting.Record_Type__c)) {
			List<String> list_RecordTypes = objAutoCloseSetting.Record_Type__c.split(',');
			strBatchQuery += ' AND RecordType.Name IN :list_RecordTypes';
		}
		// Add contains/exact match filters for roles if they are set in the metadata.
		if (String.isNotBlank(objAutoCloseSetting.Roles__c)) {
			List<String> list_Roles = objAutoCloseSetting.Roles__c.split(',');
			strBatchQuery += ' AND Opportunity_Owner_Role__c IN :list_Roles';
		} else if (String.isNotBlank(objAutoCloseSetting.Roles_Like__c)) {
			String strRolesLike = objAutoCloseSetting.Roles_Like__c + '%';
			strBatchQuery += ' AND Opportunity_Owner_Role__c LIKE :strRolesLike';
		}
		return Database.getQueryLocator(strBatchQuery);
	}

	/**
	 * @description Execute method of the batch to update the stages of the opportunities in scope.
	 * @param       Batchable context, List of opportunities
	 **/
	public void execute(Database.BatchableContext BC, List<Opportunity> list_Opptys) {
		try {
			// Test Exception
			if (Test.isRunningTest() && blnTestException) {
				Integer intInfinity = 1 / 0;
			}

			for (Opportunity objOpp : list_Opptys) {
				objOpp.StageName = CLOSED_LOST;
				objOpp.Stage_Detail__c = SFDC_ADMINISTRATIVE;
			}

			//Update the opportunities and log any errors
			Database.SaveResult[] list_updateResults = Database.update(list_Opptys, false);
			for (Integer i = 0; i < list_updateResults.size(); i++) {
				Database.SaveResult objSR = list_updateResults[i];
				if (!objSR.isSuccess()) {
					Exception_Log__c objLog = new Exception_Log__c(
						Type__c = 'ERROR',
						Class_Name__c = 'OpportunityAutoCloseBatch',
						Method_Name__c = 'execute',
						Record_ID__c = objSR.getId(),
						Message__c = objSR.getErrors()[0].getMessage()
					);
					list_ExceptionLogs.add(objLog);
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'OpportunityAutoCloseBatch',
				'execute',
				'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	/**
	 * @description Finish method of the batch to log the completion of the batch.
	 * @param       Batchable context
	 **/
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'OpportunityAutoCloseBatch', false);
		if (!list_ExceptionLogs.isEmpty()) {
			insert list_ExceptionLogs;
		}
	}

	/**
	 * @description Execute method of the scheduler that will run the OpportunityAutoCloseBatch.
	 * @param       Schedulable context
	 **/
	public void execute(SchedulableContext sc) {
		List<AsyncApexJob> runningBatchJobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status IN ('Queued', 'Processing') AND ApexClass.Name = 'OpportunityAutoCloseBatch'];
		if (runningBatchJobs.isEmpty()) {
			Database.executeBatch(new OpportunityAutoCloseBatch(strTeam), (Integer) objAutoCloseSetting.Batch_Size__c);
		}
	}
}