public with sharing class UR_ResearchCSVDataTriggerHelper {
	public static boolean skipTrigger = false;

	public void OnBeforeInsert(List<UXR_CSV_Staging__c> resUpload) {
	}

	public void OnAfterInsert(Map<ID, UXR_CSV_Staging__c> newResUploadMap) {
	}

	public void OnBeforeUpdate(Map<ID, UXR_CSV_Staging__c> oldResUploadMap, Map<ID, UXR_CSV_Staging__c> newResUploadMap) {
	}

	public void OnAfterUpdate(Map<ID, UXR_CSV_Staging__c> oldResUploadMap, Map<ID, UXR_CSV_Staging__c> newResUploadMap, List<UXR_CSV_Staging__c> resUpload) {
		Set<Id> csvDataSet = new Set<Id>();
		UXR_CSV_Staging__c oldObj = null;
		Set<Id> projectIdSet = new Set<Id>();
		for (UXR_CSV_Staging__c newObj : resUpload) {
			oldObj = oldResUploadMap.get(newObj.id);
			if (newObj.CSV_Header__c == false && 'Processed' == newObj.Status__c && newObj.Status__c != oldObj.Status__c) {
				csvDataSet.add(newObj.Id);
			}
			projectIdSet.add(newObj.Research_Project_Master__c);
		}

		if (csvDataSet.size() > 0) {
			UR_ReaserachCSVDataQueue updateJob = new UR_ReaserachCSVDataQueue(csvDataSet, projectIdSet);
			Id jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeDelete(UXR_CSV_Staging__c[] ResUploadToDelete, Map<ID, UXR_CSV_Staging__c> oldResUploadMap) {
	}

	public void OnAfterDelete(UXR_CSV_Staging__c[] deletedResUpload, Map<ID, UXR_CSV_Staging__c> oldResUploadMap) {
	}

	public void OnUndelete(UXR_CSV_Staging__c[] restoredResUpload) {
	}

	public static void moveDataIntoResearchUploadInfo(Set<Id> csvDataSet, Set<Id> projectIdSet) {
		Map<Id, List<UXR_CSV_Staging__c>> csvDataMap = new Map<Id, List<UXR_CSV_Staging__c>>();
		String queryStr = getQueryString();
		queryStr = queryStr + ' where Id IN  : csvDataSet ';
		for (UXR_CSV_Staging__c csvObj : database.query(queryStr)) {
			if (csvDataMap.containsKey(csvObj.Research_Project_Master__c)) {
				List<UXR_CSV_Staging__c> csvObjList = csvDataMap.get(csvObj.Research_Project_Master__c);
				csvObjList.add(csvObj);
				csvDataMap.put(csvObj.Research_Project_Master__c, csvObjList);
			} else {
				List<UXR_CSV_Staging__c> csvObjList = new List<UXR_CSV_Staging__c>();
				csvObjList.add(csvObj);
				csvDataMap.put(csvObj.Research_Project_Master__c, csvObjList);
			}
		}

		Map<Id, Integer> extraColumnMap = new Map<Id, Integer>();
		Integer extraCSVColumn = 0;
		Map<Id, UXR_CSV_Staging__c> csvHeaderMap = new Map<Id, UXR_CSV_Staging__c>();
		queryStr = getQueryString();
		queryStr = queryStr + ' where Research_Project_Master__c IN  : projectIdSet and CSV_Header__c = true';
		for (UXR_CSV_Staging__c csvHeaderObj : database.query(queryStr)) {
			csvHeaderMap.put(csvHeaderObj.Research_Project_Master__c, csvHeaderObj);

			extraCSVColumn = 0;
			if (csvHeaderObj.Research_Project_Master__r.Uploaded_CSV_Column__c > 7) {
				extraCSVColumn = Integer.valueOf(csvHeaderObj.Research_Project_Master__r.Uploaded_CSV_Column__c) - 7;
			}
			extraColumnMap.put(csvHeaderObj.Research_Project_Master__c, extraCSVColumn);
		}

		Integer extraColumn = 0;
		UXR_CSV_Staging__c headerObj = null;
		for (Id projectId : csvDataMap.keySet()) {
			if (extraColumnMap.containsKey(projectId) && csvHeaderMap.containsKey(projectId)) {
				extraColumn = extraColumnMap.get(projectId);
				headerObj = csvHeaderMap.get(projectId);
				processedCSVRecord(projectId, csvDataMap.get(projectId), extraColumn, headerObj);
			}
		}
	}

	public static void processedCSVRecord(String projectId, List<UXR_CSV_Staging__c> scope, Integer extraColumn, UXR_CSV_Staging__c headerObj) {
		Map<Id, UXR_CSV_Staging__c> updateCSVStatusMap = new Map<Id, UXR_CSV_Staging__c>();
		Map<Integer, String> csvQuestionMap = new Map<Integer, String>();
		if (extraColumn != null && extraColumn > 0) {
			String fieldAPIName = '';
			for (Integer iCount = 1; iCount <= extraColumn; iCount++) {
				fieldAPIName = 'UXR_CSV_Column' + iCount + '__c';
				csvQuestionMap.put(iCount, headerObj.get(fieldAPIName) + '');
			}
		}

		Set<String> emailId = new Set<String>();
		Set<String> userId = new Set<String>();
		Set<String> empId = new Set<String>();
		try {
			List<Research_Upload_Info__c> uploadInfoList = new List<Research_Upload_Info__c>();
			Map<Integer, List<Research_Upload_Field_Data__c>> uploadDataMap = new Map<Integer, List<Research_Upload_Field_Data__c>>();
			Integer recordIndex = 1;
			String fieldAPIName = '';
			boolean duplicateFlag = false;
			list<UXR_CSV_Staging__c> uxCSVDataList = new List<UXR_CSV_Staging__c>();
			for (UXR_CSV_Staging__c sObj : scope) {
				List<Research_Upload_Field_Data__c> uploadDataList = new List<Research_Upload_Field_Data__c>();
				Research_Upload_Info__c uploadInfoObj = new Research_Upload_Info__c();
				parseUploadInfo(uploadInfoObj, sObj);

				duplicateFlag = false;
				if (String.isNotBlank(uploadInfoObj.Email__c) && emailId.contains(uploadInfoObj.Email__c)) {
					duplicateFlag = true;
					sObj.Status__c = 'Fail';
					sObj.Message__c = 'Duplicate Email Id : ' + uploadInfoObj.Email__c;
				} else if (String.isNotBlank(uploadInfoObj.User_Id__c) && userId.contains(uploadInfoObj.User_Id__c)) {
					duplicateFlag = true;
					sObj.Status__c = 'Fail';
					sObj.Message__c = 'Duplicate User Id : ' + uploadInfoObj.User_Id__c;
				} else if (String.isNotBlank(uploadInfoObj.Employee_Id__c) && empId.contains(uploadInfoObj.Employee_Id__c)) {
					duplicateFlag = true;
					sObj.Status__c = 'Fail';
					sObj.Message__c = 'Duplicate Employee Id : ' + uploadInfoObj.Employee_Id__c;
				}

				if (duplicateFlag == false) {
					if (String.isNotBlank(uploadInfoObj.Email__c)) {
						emailId.add(uploadInfoObj.Email__c);
					}
					if (String.isNotBlank(uploadInfoObj.User_Id__c)) {
						userId.add(uploadInfoObj.User_Id__c);
					}
					if (String.isNotBlank(uploadInfoObj.Employee_Id__c)) {
						empId.add(uploadInfoObj.Employee_Id__c);
					}

					uploadInfoList.add(uploadInfoObj); // Insert Research_Upload_Info__c list
					uxCSVDataList.add(sObj); // Update Staging(UXR_CSV_Staging__c) object status.
					if (extraColumn != null && extraColumn > 0) {
						String fieldValue = '';
						for (Integer iCount = 1; iCount <= extraColumn; iCount++) {
							fieldAPIName = 'UXR_CSV_Column' + iCount + '__c';
							fieldValue = sObj.get(fieldAPIName) + '';
							if (String.isBlank(fieldValue) || 'null' == fieldValue) {
								uploadDataList.add(new Research_Upload_Field_Data__c(Field_Label__c = csvQuestionMap.get(iCount), Field_Value__c = ''));
							} else {
								uploadDataList.add(new Research_Upload_Field_Data__c(Field_Label__c = csvQuestionMap.get(iCount), Field_Value__c = sObj.get(fieldAPIName) + ''));
							}
						}
					}

					if (uploadDataList.size() > 0) {
						uploadDataMap.put(recordIndex, uploadDataList);
						recordIndex = recordIndex + 1;
					}
				}
			}

			if (uploadInfoList.size() > 0) {
				checkExistingInfo(empId, userId, emailId, uploadInfoList, projectId);

				//Insert "Research_Upload_Info__c" record list.
				Database.UpsertResult[] srList = Database.upsert(uploadInfoList, false);
				Map<Id, Research_Upload_Info__c> rsUploadedInfoMap = new Map<Id, Research_Upload_Info__c>();
				for (Research_Upload_Info__c uploadObj : uploadInfoList) {
					if (uploadObj.Id != null) {
						rsUploadedInfoMap.put(uploadObj.Id, uploadObj);
					}
				}
				Set<Integer> successIndexSet = new Set<Integer>();
				String statusMsg = '';
				String errorMsg = '';
				Id csvObjId = null;

				for (Integer index = 0; index < srList.size(); index++) {
					csvObjId = uxCSVDataList[index].Id;
					UXR_CSV_Staging__c csvObj = new UXR_CSV_Staging__c(Id = csvObjId);
					errorMsg = '';
					statusMsg = '';
					if (srList[index].isSuccess()) {
						successIndexSet.add(index + 1);
						statusMsg = 'Success';
					} else {
						statusMsg = 'Fail';
						for (Database.Error err : srList[index].getErrors()) {
							errorMsg = err.getMessage();
							break;
						}
					}

					//When parent record is locked then we, will reprocessed the records again.
					if (String.isNotBlank(errorMsg) && errorMsg.contains('exclusive access to this record')) {
						statusMsg = 'Pending';
						errorMsg = '';
					}

					csvObj.Status__c = statusMsg;
					csvObj.Message__c = errorMsg;
					updateCSVStatusMap.put(csvObjId, csvObj);
				}

				//Insert "Research_Upload_Field_Data__c" list.
				List<Research_Upload_Field_Data__c> uploadfieldDataList = new List<Research_Upload_Field_Data__c>();
				if (uploadInfoList.size() > 0 && uploadDataMap.size() > 0) {
					Integer indexCount = 1;
					for (Research_Upload_Info__c infoObj : uploadInfoList) {
						if (successIndexSet.contains(indexCount)) {
							// If "Research_Upload_Info__c" record successfully saved then we will saved there respective "Research_Upload_Field_Data__c" list.
							for (Research_Upload_Field_Data__c uploadfieldData : uploadDataMap.get(indexCount)) {
								uploadfieldData.Research_Upload_Info__c = infoObj.id;
								uploadfieldDataList.add(uploadfieldData);
							}
						}
						indexCount = indexCount + 1;
					}
				}

				if (uploadfieldDataList.size() > 0) {
					upsert uploadfieldDataList;
				}
			}
			UR_ResearchCSVDataTriggerHelper.skipTrigger = true;
			update updateCSVStatusMap.values();
			UR_ResearchCSVDataTriggerHelper.skipTrigger = false;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_ResearchCSVDataTriggerHelper', 'processedCSVRecord', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static void parseUploadInfo(Research_Upload_Info__c uploadInfoObj, UXR_CSV_Staging__c sObj) {
		uploadInfoObj.UXR_CSV_Staging__c = sObj.Id;
		uploadInfoObj.First_Name__c = sObj.First_Name__c;
		uploadInfoObj.Last_Name__c = sObj.Last_Name__c;
		uploadInfoObj.Email__c = sObj.Email__c;
		uploadInfoObj.Company_Id__c = sObj.Company_Id__c;
		uploadInfoObj.User_Id__c = sObj.User_Id__c;
		uploadInfoObj.Employee_Id__c = sObj.Employee_Id__c;
		uploadInfoObj.Accountant_Firm_Id__c = sObj.Accountant_Firm_Id__c;
		uploadInfoObj.CSV_File_Name__c = sObj.CSV_File_Name__c;
		uploadInfoObj.CSV_Upload_Date__c = sObj.CSV_Upload_Date__c;
	}

	// Check existing "Research Upload Info" record.
	public static void checkExistingInfo(Set<String> empId, Set<String> userId, Set<String> emailId, List<Research_Upload_Info__c> uploadInfoList, String projectId) {
		try {
			Map<String, Id> existingInfoMap = new Map<String, Id>();
			String key = '';
			for (Research_Upload_Info__c existingInfoObj : [
				SELECT id, User_Id__c, Email__c, Employee_Id__c, Blacklist__c, Opt_Out__c
				FROM Research_Upload_Info__c
				WHERE Research_Project_Master__c = :projectId AND (Email__c IN :empId OR User_Id__c IN :userId OR Employee_Id__c IN :emailId)
				ORDER BY First_Name__c
			]) {
				key = ''; //emailId + userId + employeeId
				if (String.isNotBlank(existingInfoObj.Email__c)) {
					key = key + existingInfoObj.Email__c + '_';
				}
				if (String.isNotBlank(existingInfoObj.User_Id__c)) {
					key = key + existingInfoObj.User_Id__c + '_';
				}
				if (String.isNotBlank(existingInfoObj.Employee_Id__c)) {
					key = key + existingInfoObj.Employee_Id__c + '_';
				}
				if (String.isNotBlank(key)) {
					key = key.subString(0, key.length() - 1);
					existingInfoMap.put(key, existingInfoObj.Id);
				}
			}

			Set<Id> existingUploadData = new Set<Id>();
			for (Research_Upload_Info__c uploadInfoObj : uploadInfoList) {
				key = ''; //emailId + userId + employeeId
				if (String.isNotBlank(uploadInfoObj.Email__c)) {
					key = key + uploadInfoObj.Email__c + '_';
				}
				if (String.isNotBlank(uploadInfoObj.User_Id__c)) {
					key = key + uploadInfoObj.User_Id__c + '_';
				}
				if (String.isNotBlank(uploadInfoObj.Employee_Id__c)) {
					key = key + uploadInfoObj.Employee_Id__c + '_';
				}
				if (String.isNotBlank(key)) {
					key = key.subString(0, key.length() - 1);
				}
				if (String.isNotBlank(key) && existingInfoMap.containsKey(key)) {
					// update existing "Research Upload Info" record.
					if (!existingUploadData.contains(existingInfoMap.get(key))) {
						uploadInfoObj.Id = existingInfoMap.get(key);
						existingUploadData.add(uploadInfoObj.Id);
					}
				}
				uploadInfoObj.Unique_Id__c = projectId + '_' + key;
			}

			if (existingUploadData.size() > 0) {
				// Delete existing "Research Upload Field Data" record.
				delete [SELECT id FROM Research_Upload_Field_Data__c WHERE Research_Upload_Info__c IN :existingUploadData];
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
			ExceptionLogUtil.logException('UR_ResearchCSVDataTriggerHelper', 'checkExistingInfo', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static String getQueryString() {
		String query = '';
		query =
			'Select Id, Name, Accountant_Firm_Id__c, Company_Id__c, CSV_File_Name__c, CSV_Header__c, CSV_Upload_Date__c, Email__c, ' +
			'Employee_Id__c, First_Name__c, Last_Name__c, Message__c, Research_Project_Master__c, Status__c, User_Id__c, UXR_CSV_Column1__c, ' +
			'UXR_CSV_Column10__c, UXR_CSV_Column11__c, UXR_CSV_Column12__c, UXR_CSV_Column13__c, UXR_CSV_Column14__c, UXR_CSV_Column15__c, ' +
			'UXR_CSV_Column16__c, UXR_CSV_Column17__c, UXR_CSV_Column18__c, UXR_CSV_Column19__c, UXR_CSV_Column2__c, UXR_CSV_Column20__c, ' +
			'UXR_CSV_Column21__c, UXR_CSV_Column22__c, UXR_CSV_Column23__c, UXR_CSV_Column24__c, UXR_CSV_Column25__c, UXR_CSV_Column26__c, ' +
			'UXR_CSV_Column27__c, UXR_CSV_Column28__c, UXR_CSV_Column29__c, UXR_CSV_Column3__c, UXR_CSV_Column30__c, UXR_CSV_Column31__c, ' +
			'UXR_CSV_Column32__c, UXR_CSV_Column33__c, UXR_CSV_Column34__c, UXR_CSV_Column35__c, UXR_CSV_Column36__c, UXR_CSV_Column37__c, ' +
			'UXR_CSV_Column38__c, UXR_CSV_Column39__c, UXR_CSV_Column4__c, UXR_CSV_Column40__c, UXR_CSV_Column41__c, UXR_CSV_Column42__c, ' +
			'UXR_CSV_Column43__c, UXR_CSV_Column44__c, UXR_CSV_Column45__c, UXR_CSV_Column46__c, UXR_CSV_Column47__c, UXR_CSV_Column48__c,' +
			'UXR_CSV_Column49__c, UXR_CSV_Column5__c, UXR_CSV_Column50__c, UXR_CSV_Column51__c, UXR_CSV_Column52__c, UXR_CSV_Column53__c, ' +
			'UXR_CSV_Column54__c, UXR_CSV_Column55__c, UXR_CSV_Column56__c, UXR_CSV_Column57__c, UXR_CSV_Column58__c, UXR_CSV_Column59__c,' +
			'UXR_CSV_Column6__c, UXR_CSV_Column60__c, UXR_CSV_Column61__c, UXR_CSV_Column62__c, UXR_CSV_Column63__c, UXR_CSV_Column64__c,' +
			'UXR_CSV_Column65__c, UXR_CSV_Column66__c, UXR_CSV_Column67__c, UXR_CSV_Column68__c, UXR_CSV_Column69__c, UXR_CSV_Column7__c,' +
			'UXR_CSV_Column70__c, UXR_CSV_Column71__c, UXR_CSV_Column72__c, UXR_CSV_Column73__c, UXR_CSV_Column74__c, UXR_CSV_Column75__c,' +
			'UXR_CSV_Column76__c, UXR_CSV_Column77__c, UXR_CSV_Column78__c, UXR_CSV_Column79__c, UXR_CSV_Column8__c, UXR_CSV_Column80__c, ' +
			'UXR_CSV_Column81__c, UXR_CSV_Column82__c, UXR_CSV_Column83__c, UXR_CSV_Column84__c, UXR_CSV_Column85__c, UXR_CSV_Column86__c,' +
			'UXR_CSV_Column87__c, UXR_CSV_Column88__c, UXR_CSV_Column89__c, UXR_CSV_Column9__c, UXR_CSV_Column90__c, UXR_CSV_Column91__c, ' +
			'UXR_CSV_Column92__c, UXR_CSV_Column93__c, Research_Project_Master__r.Uploaded_CSV_Column__c from UXR_CSV_Staging__c ';
		return query;
	}
}