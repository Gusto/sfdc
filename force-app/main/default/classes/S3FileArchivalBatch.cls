/**
 * @name         : S3FileArchivalBatch
 * @author       : Komal Khatija
 * @date         : 06/27/2022
 * @description  : Batch class to process file archival
 * @see : S3FileArchivalBatchTest
 **/
global class S3FileArchivalBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	String strQuery = '';
	String strObjectName = '';
	String strFile = 'File';
	Boolean blnManualJob = false; //need to be defined as true if job is running manually, otherwise config will be applied.
	List<Archival_Job_Configuration__c> list_SelectedJobs = new List<Archival_Job_Configuration__c>();
	global List<Archival_Job_Configuration__c> list_ExecutedJobs = new List<Archival_Job_Configuration__c>();
	List<String> list_BatchPendingStatus = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };
	List<AsyncApexJob> list_Jobs = new List<AsyncApexJob>();
	String strContentDocLink = 'ContentDocumentLink';
	String strAttachment = 'Attachment';
	String strEmailMessage = 'EmailMessage';
	Integer intRunSize = 0;

	public S3FileArchivalBatch(String strInputQuery, String strInputObjectName, Boolean blnInputManualJob) {
		if (blnInputManualJob) {
			strQuery = strInputQuery;
			strObjectName = strInputObjectName;
		}
		blnManualJob = blnInputManualJob;

		if (!blnManualJob) {
			//Validate only File archival config.
			for (Archival_Job_Configuration__c objAC : [
				SELECT Id, Archival_Type__c, Active__c, Completed_At__c, Priority__c, Query__c, Last_Run_Size__c
				FROM Archival_Job_Configuration__c
				WHERE Type__c = :strFile AND Active__c = TRUE
				ORDER BY Priority__c ASC, Completed_At__c ASC
			]) {
				if (objAC.Completed_At__c != null && list_SelectedJobs.size() < 2) {
					//if last run was < 100, allow 3 days to kick of same job in order to get additional files.
					if (objAc.Last_Run_Size__c > 100 || (objAC.Last_Run_Size__c < 100 && objAC.Completed_At__c > System.today().addDays(-3))) {
						list_SelectedJobs.add(objAC);
					}
				}
			}

			list_Jobs = [
				SELECT Id, ApexClass.Name, JobItemsProcessed, TotalJobItems, Status
				FROM AsyncApexJob
				WHERE Status IN :list_BatchPendingStatus AND ApexClass.Name IN ('S3FileArchivalBatch')
				LIMIT 150
			];
		}
	}

	public S3FileArchivalBatch() {
	}

	public List<ContentDocumentLink> start(Database.BatchableContext BC) {
		//if jobs already running - don't run a new one, or if config doesn't exist
		if (!blnManualJob && (list_Jobs.size() > 1 || list_SelectedJobs.size() == 0)) {
			return null;
		}

		if (!blnManualJob) {
			//Read configuration
			Archival_Job_Configuration__c objAC = list_SelectedJobs[0];
			strQuery = objAC.Query__c;
			strObjectName = objAC.Archival_Type__c;
			list_ExecutedJobs.add(objAC);

			//reset completed date/time
			objAC.Completed_At__c = null;
			update objAC;
		}

		if (String.isBlank(strQuery)) {
			strQuery = 'SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Payroll_Audit__c) AND LinkedEntity.Type = \'Payroll_Audit__c\' AND SystemModStamp < LAST_N_DAYS:60';
		}

		if (String.isBlank(strObjectName)) {
			strObjectName = strContentDocLink;
		}

		return Database.query(strQuery);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		//Set of Email Message IDs
		Set<Id> set_EmailMessageIds = new Set<Id>();
		//if job shouldn't execute scope will be null
		if (scope == null) {
			return;
		}

		Set<Id> set_InputIds = new Set<Id>();

		for (sObject objScope : scope) {
			set_InputIds.add(objScope.Id);
		}

		//count run size, if automated run
		if (!blnManualJob) {
			intRunSize += set_InputIds.size();
		}

		//validate if archiving Email Messages to retrieve initial IDs
		if (strObjectName.equalsIgnoreCase(strEmailMessage)) {
			for (Attachment objAttachment : (List<Attachment>) scope) {
				set_EmailMessageIds.add(objAttachment.ParentId);
			}
		}

		if (strObjectName.equalsIgnoreCase(strContentDocLink)) {
			NEILON.apGlobalUtils.createS3LinkFilesForContentVersion(set_InputIds, true, false);
		} else if (strObjectName.equalsIgnoreCase(strAttachment)) {
			NEILON.apGlobalUtils.createS3LinkFilesForAttachments((List<Attachment>) scope, true, false);
		} else if (strObjectName.equalsIgnoreCase(strEmailMessage)) {
			NEILON.apGlobalUtils.createS3LinkFilesForEmailMessageAttachments(set_EmailMessageIds);
		}
	}

	public void finish(Database.BatchableContext BC) {
		try {
			for (Archival_Job_Configuration__c objAC : list_ExecutedJobs) {
				objAC.Completed_At__c = System.now();
				objAC.Last_Run_Size__c = intRunSize;
			}

			update list_ExecutedJobs;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('S3FileArchivalBatch', 'finish', null, objException);
		}
	}
}