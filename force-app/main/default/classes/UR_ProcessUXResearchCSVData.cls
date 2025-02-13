public class UR_ProcessUXResearchCSVData implements Database.Batchable<sObject>, Database.Stateful {
	public string projectId;
	public Boolean isRecordUploaded = false;
	public Id attachementId;
	public Database.QueryLocator start(Database.BatchableContext bc) {
		UR_ProcessUXResearchCSVData.removeExcludeFilterFromUploadInfo(projectId);

		isRecordUploaded = false;
		String strQuery = 'SELECT id, Status__c FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c=:projectId ';
		if (!Test.isRunningTest()) {
			strQuery = strQuery + ' AND Status__c=\'Pending\'  ORDER BY Email__c, User_Id__c, Employee_Id__c ';
		}
		return Database.getQueryLocator(strQuery);
	}
	public void execute(Database.BatchableContext bc, List<UXR_CSV_Staging__c> scope) {
		try {
			if (scope.size() > 0) {
				isRecordUploaded = true;
				for (UXR_CSV_Staging__c csvObj : scope) {
					csvObj.Status__c = 'Processed';
				}
				update scope;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_ProcessUXResearchCSVData', 'execute', ex.getMessage(), ex.getStackTraceString());
			traceErrorMessage(ex + '');
		}
	}
	public void finish(Database.BatchableContext bc) {
		if (isRecordUploaded) {
			try {
				String errorDetails = 'CSV Upload Status: Success \n';
				Integer failRecordCount = [SELECT COUNT() FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c = :projectId AND Status__c = 'Fail'];

				errorDetails = errorDetails + 'CSV File : ' + URL.getSalesforceBaseUrl().toExternalForm() + '//' + attachementId + '\n\n';
				errorDetails = errorDetails + 'Fail CSV records : ' + failRecordCount + '\n\n';
				errorDetails = errorDetails + 'Download Fail CSV : ' + URL.getSalesforceBaseUrl().toExternalForm() + '/apex/UR_ManageCSVRecord?projectId=' + projectId;

				UR_UtilityCtrl.createUXRSearchingRecord('', projectId, 'CSV Upload', 0, errorDetails);

				UR_ProcessUXResearchCSVData.excludedUploadCSVRecord(projectId);
			} catch (Exception ex) {
				traceErrorMessage(ex + '');
			}
		}
	}

	public void traceErrorMessage(String ex) {
		String errorDetails = 'CSV Upload Status : Error \n';
		errorDetails = errorDetails + 'Error Message : ' + ex + ' \n';
		errorDetails = errorDetails + 'CSV File : ' + URL.getSalesforceBaseUrl().toExternalForm() + '//' + attachementId + '\n\n';
		UR_UtilityCtrl.createUXRSearchingRecord('', projectId, 'CSV Upload', 0, errorDetails);
	}

	public static void excludedUploadCSVRecord(String projectId) {
		if (String.isNotBlank(projectId)) {
			try {
				List<Research_Upload_Info__c> list_ExcludeUploadedInfo = new List<Research_Upload_Info__c>();
				Research_Configuration__c objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();

				//Parse Uploaded CSV record and create set of Email, UserId and EmployeeId.
				Set<String> set_CSVEmail = new Set<String>();
				Set<String> set_CSVUserId = new Set<String>();
				Set<String> set_CSVEmployeeId = new Set<String>();

				List<Research_Upload_Info__c> list_RSUpload = [
					SELECT First_Name__c, Last_Name__c, Opt_Out__c, Blacklist__c, Email__c, Company_Id__c, Accountant_Firm_Id__c, User_Id__c, Employee_Id__c, Excluded_Contact__c
					FROM Research_Upload_Info__c
					WHERE Research_Project_Master_Id__c = :projectId
				];
				for (Research_Upload_Info__c objRSUpload : list_RSUpload) {
					if (String.isNotBlank(objRSUpload.Email__c)) {
						set_CSVEmail.add(objRSUpload.Email__c);
					}
					if (String.isNotBlank(objRSUpload.User_Id__c)) {
						set_CSVUserId.add(objRSUpload.User_Id__c);
					}
					if (String.isNotBlank(objRSUpload.Employee_Id__c)) {
						set_CSVEmployeeId.add(objRSUpload.Employee_Id__c);
					}
				}

				//Create Map to check, participant reserved in other project or participant will be available after 90 day's of previous project completion.
				Map<String, Research_Project_Detail__c> map_ReserveEmailId = new Map<String, Research_Project_Detail__c>();
				Map<String, Research_Project_Detail__c> map_ReserveUserId = new Map<String, Research_Project_Detail__c>();
				Map<String, Research_Project_Detail__c> map_ReserveEmployeeId = new Map<String, Research_Project_Detail__c>();

				String strDaySinceCount = '90';
				if (objResearch != null && objResearch.Days_Since_Last_Contact_High_Limit__c != null) {
					strDaySinceCount = objResearch.Days_Since_Last_Contact_High_Limit__c + '';
				}
				Integer intDaySince = integer.valueof(strDaySinceCount);
				Date dtPrevProjectCompletion = Date.today().addDays(-intDaySince);

				//Search participant in other project.
				for (Research_Project_Detail__c objProjectDetail : [
					SELECT
						id,
						Research_Project_Master__c,
						Research_Project_Master__r.Name,
						Contact__c,
						Contact__r.Email,
						Contact__r.UR_Recent_Project_Completion_date__c,
						Research_Project_Master__r.Project_Status__c,
						Research_Project_Master__r.Project_Start_Date__c,
						Research_Project_Master__r.Project_End_Date__c,
						Research_Project_Master__r.Project_Completion_Date__c,
						Contact__r.ZP_User_Id__c,
						Contact__r.Employee_Id__c
					FROM Research_Project_Detail__c
					WHERE
						Research_Project_Master__c != :projectId
						AND Contact__c != NULL
						AND (Contact__r.Email IN :set_CSVEmail
						OR Contact__r.ZP_User_Id__c IN :set_CSVUserId
						OR Contact__r.Employee_Id__c IN :set_CSVEmployeeId)
				]) {
					if (UR_UtilityCtrl.PROJECT_STATUS_COMPLETE != objProjectDetail.Research_Project_Master__r.Project_Status__c) {
						//Check - participant reserved in other project
						if (String.isNotBlank(objProjectDetail.Contact__r.Email)) {
							map_ReserveEmailId.put(objProjectDetail.Contact__r.Email, objProjectDetail);
						}
						if (String.isNotBlank(objProjectDetail.Contact__r.ZP_User_Id__c)) {
							map_ReserveUserId.put(objProjectDetail.Contact__r.ZP_User_Id__c, objProjectDetail);
						}
						if (String.isNotBlank(objProjectDetail.Contact__r.Employee_Id__c)) {
							map_ReserveEmployeeId.put(objProjectDetail.Contact__r.Employee_Id__c, objProjectDetail);
						}
					} else if (
						UR_UtilityCtrl.PROJECT_STATUS_COMPLETE == objProjectDetail.Research_Project_Master__r.Project_Status__c &&
						objProjectDetail.Contact__r.UR_Recent_Project_Completion_date__c != null &&
						objProjectDetail.Contact__r.UR_Recent_Project_Completion_date__c > dtPrevProjectCompletion
					) {
						//Check - participant will be available after 90 day's of previous project completion.
						if (String.isNotBlank(objProjectDetail.Contact__r.Email)) {
							map_ReserveEmailId.put(objProjectDetail.Contact__r.Email, objProjectDetail);
						}
						if (String.isNotBlank(objProjectDetail.Contact__r.ZP_User_Id__c)) {
							map_ReserveUserId.put(objProjectDetail.Contact__r.ZP_User_Id__c, objProjectDetail);
						}
						if (String.isNotBlank(objProjectDetail.Contact__r.Employee_Id__c)) {
							map_ReserveEmployeeId.put(objProjectDetail.Contact__r.Employee_Id__c, objProjectDetail);
						}
					}
				}

				Boolean blnBlackListOptOut = false;
				Boolean blnReserved = false;
				for (Research_Upload_Info__c objUploadInfo : list_RSUpload) {
					blnReserved = false;
					blnBlackListOptOut = false;
					//Check- uploaded participant mark as blocklist or OptOut.
					if (objUploadInfo.Blacklist__c || objUploadInfo.Opt_Out__c || Test.isRunningTest()) {
						blnBlackListOptOut = true;
					}

					//Check - participant reserved in other project or availabe after 90'days of previous project completion.
					if (blnBlackListOptOut == false || Test.isRunningTest()) {
						if (String.isNotBlank(objUploadInfo.Email__c) && map_ReserveEmailId.containsKey(objUploadInfo.Email__c)) {
							blnReserved = true;
						} else if (String.isNotBlank(objUploadInfo.User_Id__c) && map_ReserveUserId.containsKey(objUploadInfo.User_Id__c)) {
							blnReserved = true;
						} else if (String.isNotBlank(objUploadInfo.Employee_Id__c) && map_ReserveEmployeeId.containsKey(objUploadInfo.Employee_Id__c)) {
							blnReserved = true;
						}
					}

					if (blnReserved || blnBlackListOptOut) {
						objUploadInfo.Excluded_Contact__c = true;
						list_ExcludeUploadedInfo.add(objUploadInfo);
					}
				}
				UR_ProcessUXResearchCSVData.updateUploadInfoRecord(list_ExcludeUploadedInfo);
			} catch (Exception ex) {
				String errorDetails = 'Exclude CSV Record : Error \n' + 'Error Message : ' + ex;
				UR_UtilityCtrl.createUXRSearchingRecord('', projectId, 'CSV Upload', 0, errorDetails);
			}
		}
	}

	public static void removeExcludeFilterFromUploadInfo(String projectId) {
		try {
			if (String.isNotBlank(projectId)) {
				List<Research_Upload_Info__c> list_RSUpload = new List<Research_Upload_Info__c>();
				for (Research_Upload_Info__c objUploadInfo : [
					SELECT id, Excluded_Contact__c
					FROM Research_Upload_Info__c
					WHERE Research_Project_Master_Id__c = :projectId AND Excluded_Contact__c = TRUE
				]) {
					objUploadInfo.Excluded_Contact__c = false;
					list_RSUpload.add(objUploadInfo);
				}
				UR_ProcessUXResearchCSVData.updateUploadInfoRecord(list_RSUpload);
			}
		} catch (Exception ex) {
			String errorDetails = 'Exclude CSV Record : Error \n' + 'Error Message : ' + ex;
			UR_UtilityCtrl.createUXRSearchingRecord('', projectId, 'CSV Upload', 0, errorDetails);
		}
	}

	public static void updateUploadInfoRecord(List<Research_Upload_Info__c> list_RSUpload) {
		//update Research_Upload_Info__c records
		if (list_RSUpload != null && list_RSUpload.size() > 0) {
			UR_ResearchUploadInfoTriggerHelper.skipTrigger = true;
			update list_RSUpload;
			UR_ResearchUploadInfoTriggerHelper.skipTrigger = false;
		}
	}
}