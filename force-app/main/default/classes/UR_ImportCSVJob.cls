public class UR_ImportCSVJob implements Database.Batchable<String>, Database.Stateful {
	public String csvFileId;
	public String projectObjId;
	public Id attachementId;
	public Map<Integer, String> csvQuestionMap = new Map<Integer, String>();
	public String UR_Delimiter = Label.UR_Delimiter;
	public String csvName = '';
	public Integer batchLoopCount = 0;
	public boolean isValidCSV = true;
	public Set<String> emailId = new Set<String>();
	public Set<String> userId = new Set<String>();
	public Set<String> empId = new Set<String>();
	public static final String RQ_LAST_NAME = 'Last Name';
	public static final String RQ_EMAIL_ID = 'Email Id';
	public static final String RQ_COMPANY_AND_FIRM_ID = 'Company Id or Accounting Firm Id';
	public List<String> start(Database.BatchableContext context) {
		batchLoopCount = 0;
		isValidCSV = true;
		List<String> parsedCSVRows = new List<String>();
		List<Attachment> attachmentList = [SELECT Id, Name, Body FROM Attachment WHERE Id = :csvFileId];
		try {
			if (attachmentList.size() > 0) {
				//Clear UXR_CSV_Staging__c table, if there is no record exist in Main table(Research_Upload_Info__c).
				List<Research_Upload_Info__c> list_RSUploadInfo = [SELECT Id FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :projectObjId];
				if (list_RSUploadInfo.size() == 0) {
					List<UXR_CSV_Staging__c> list_CSVStaging = [SELECT Id FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c = :projectObjId];
					if (list_CSVStaging.size() > 0) {
						delete list_CSVStaging;
					}
				}
				attachementId = attachmentList[0].Id;
				String contents = attachmentList[0].Body.toString();
				csvName = attachmentList[0].Name;
				if (contents.length() < 100000 && !Test.isRunningTest()) {
					parsedCSVRows = contents.split('\n');
				} else {
					Integer startIndex = 0;
					Integer endIndex = 0;
					Integer csvLength = contents.length();
					while (startIndex < csvLength) {
						endIndex = contents.indexOf('\n', startIndex);
						if (endIndex == -1) {
							endIndex = csvLength;
						}
						parsedCSVRows.add(contents.subString(startIndex, endIndex));
						startIndex = endIndex + 1;
					}
				}
			}
		} catch (Exception ex) {
			traceErrorMessage(ex.getMessage() + '');
		}

		return parsedCSVRows;
	}

	public void execute(Database.BatchableContext context, List<String> records) {
		batchLoopCount = batchLoopCount + 1;

		if (isValidCSV) {
			try {
				List<List<String>> parsedCSV = UR_UtilityCtrl.callDataParsing(records);
				List<UXR_CSV_Staging__c> uploadInfoList = new List<UXR_CSV_Staging__c>();
				List<String> csvRecordData = new List<String>();
				boolean duplicateFlag = false;
				Set<String> companyIdSet = new Set<String>();
				Set<String> firmIdSet = new Set<String>();
				Set<String> set_NewEmailId = new Set<String>();
				Set<String> set_NewUserId = new Set<String>();
				Set<String> set_NewEmpId = new Set<String>();
				string errorMsg = '';
				if (batchLoopCount == 1 && parsedCSV.size() > 0) {
					//Delete fail records.
					List<UXR_CSV_Staging__c> list_CSVRecord = [SELECT Id FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c = :projectObjId AND Status__c = 'Fail'];
					if (list_CSVRecord.size() > 0) {
						delete list_CSVRecord;
					}
				}
				//'Pending'
				for (Integer rowIndex = 0; rowIndex < parsedCSV.size(); rowIndex++) {
					errorMsg = '';
					csvRecordData = parsedCSV[rowIndex];
					duplicateFlag = false;
					UXR_CSV_Staging__c uploadInfoObj = new UXR_CSV_Staging__c(Research_Project_Master__c = projectObjId, Status__c = 'Pending');
					if (batchLoopCount == 1 && rowIndex == 0) {
						isValidCSV = processQuestion(csvRecordData);
						uploadInfoObj.CSV_Header__c = true;
						uploadInfoObj.Status__c = 'Success';
						uploadInfoObj.Message__c = 'Error Message';
					} else {
						uploadInfoObj.CSV_Header__c = false;
					}

					//==Below mentioned for loop to handel, blank field value getting in CSV parsing.======
					//==============Start==================================================================
					Integer requiredSize = csvQuestionMap.size() + 7; //Here 7 is fixed header size.
					Integer currentRecordSize = csvRecordData.size();
					if (currentRecordSize < requiredSize) {
						for (Integer iCount = currentRecordSize; iCount < requiredSize; iCount++) {
							csvRecordData.add('');
						}
					}
					//==============End======================================================================

					uploadInfoObj.First_Name__c = csvRecordData[0];
					uploadInfoObj.Last_Name__c = csvRecordData[1];
					uploadInfoObj.Email__c = csvRecordData[2];
					uploadInfoObj.Company_Id__c = removeDelimiter(csvRecordData[3]);
					uploadInfoObj.User_Id__c = removeDelimiter(csvRecordData[4]);
					uploadInfoObj.Employee_Id__c = removeDelimiter(csvRecordData[5]);
					uploadInfoObj.Accountant_Firm_Id__c = removeDelimiter(csvRecordData[6]);
					uploadInfoObj.CSV_File_Name__c = csvName;
					uploadInfoObj.CSV_Upload_Date__c = Date.today();

					//Put extra column value.
					Integer columnIndex = 1, iIndex = 1;
					String fieldAPIName = '';
					for (String data : csvRecordData) {
						fieldAPIName = 'UXR_CSV_Column' + columnIndex + '__c';
						if (iIndex <= 7) {
							//Do nothing
						} else {
							/*if(string.isNotBlank(UR_Delimiter)){
								data = removeDelimiter(data);
							}*/
							uploadInfoObj.put(fieldAPIName, data);
							columnIndex = columnIndex + 1;
						}
						iIndex = iIndex + 1;
					}

					if (String.isNotBlank(csvRecordData[3]) && csvRecordData[3].indexOf('E') > -1) {
						errorMsg = ' Company Id is not valid : ' + csvRecordData[3];
					}
					if (String.isNotBlank(csvRecordData[4]) && csvRecordData[4].indexOf('E') > -1) {
						errorMsg = errorMsg + ' User Id is not valid : ' + csvRecordData[4];
					}
					if (String.isNotBlank(csvRecordData[5]) && csvRecordData[5].indexOf('E') > -1) {
						errorMsg = errorMsg + ' Employee Id is not valid : ' + csvRecordData[5];
					}

					String strRequiredField = '';
					if (String.isBlank(csvRecordData[1])) {
						strRequiredField = strRequiredField + RQ_LAST_NAME + ', ';
					}

					if (String.isBlank(csvRecordData[2])) {
						strRequiredField = strRequiredField + RQ_EMAIL_ID + ', ';
					}

					if (String.isBlank(csvRecordData[3]) && String.isBlank(csvRecordData[6])) {
						strRequiredField = strRequiredField + RQ_COMPANY_AND_FIRM_ID + ', ';
					}

					if (String.isNotBlank(strRequiredField)) {
						strRequiredField = strRequiredField.removeEnd(', ');
						errorMsg = errorMsg + ' ' + strRequiredField + ' should not be blank.';
					}

					if (String.isNotBlank(errorMsg)) {
						uploadInfoObj.Message__c = errorMsg;
						uploadInfoObj.Status__c = 'Fail';
					}

					//Create two set, companyIdSet and firmIdSet to check Account record exit or not.
					if (String.isNotBlank(csvRecordData[3])) {
						companyIdSet.add(removeDelimiter(csvRecordData[3]));
					}
					if (String.isNotBlank(csvRecordData[6])) {
						firmIdSet.add(removeDelimiter(csvRecordData[6]));
					}

					//Check duplicate records on the basis of Email ID, User Id and Employee Id and set duplicateFlag as true.
					if (String.isNotBlank(uploadInfoObj.Email__c) && emailId.contains(uploadInfoObj.Email__c)) {
						duplicateFlag = true;
						uploadInfoObj.Message__c = 'Duplicate Email : ' + uploadInfoObj.Email__c;
					} else if (String.isNotBlank(uploadInfoObj.User_Id__c) && userId.contains(uploadInfoObj.User_Id__c)) {
						duplicateFlag = true;
						uploadInfoObj.Message__c = 'Duplicate User Id : ' + uploadInfoObj.User_Id__c;
					} else if (String.isNotBlank(uploadInfoObj.Employee_Id__c) && empId.contains(uploadInfoObj.Employee_Id__c)) {
						duplicateFlag = true;
						uploadInfoObj.Message__c = 'Duplicate Employee Id : ' + uploadInfoObj.Employee_Id__c;
					}

					if (duplicateFlag) {
						uploadInfoObj.Status__c = 'Fail';
					}

					//Create a set of email Id, user Id and employee Id to check duplicate record in csv file.
					if (String.isBlank(errorMsg) && duplicateFlag == false) {
						if (String.isNotBlank(uploadInfoObj.Email__c)) {
							emailId.add(uploadInfoObj.Email__c);
							set_NewEmailId.add(uploadInfoObj.Email__c);
						}

						if (String.isNotBlank(uploadInfoObj.User_Id__c)) {
							userId.add(uploadInfoObj.User_Id__c);
							set_NewUserId.add(uploadInfoObj.User_Id__c);
						}

						if (String.isNotBlank(uploadInfoObj.Employee_Id__c)) {
							empId.add(uploadInfoObj.Employee_Id__c);
							set_NewEmpId.add(uploadInfoObj.Employee_Id__c);
						}
					}

					uploadInfoList.add(uploadInfoObj);

					if (isValidCSV == false) {
						String failMsg = 'CSV upload unsuccessful. Please ensure your CSV has all 7 columns is in the order shown in the example, and the required columns populated: First name, Email, Company ID OR Accouting firm ID (whichever is applicable), and EE ID.';
						uploadInfoObj.Status__c = 'Fail';
						uploadInfoObj.Message__c = failMsg;

						String errorDetails = ' CSV Upload Status : Fail \n';
						errorDetails = errorDetails + 'CSV File : ' + URL.getSalesforceBaseUrl().toExternalForm() + '//' + attachementId + '\n\n';
						errorDetails = errorDetails + 'Reason : ' + failMsg;
						UR_UtilityCtrl.createUXRSearchingRecord('', projectObjId, 'CSV Upload', 0, errorDetails);

						if (String.isNotBlank(projectObjId)) {
							updateErrorMessage(failMsg);
						}
						break;
					}
				}

				if (uploadInfoList.size() > 0) {
					//Check Account record exit or not.
					checkExistingAccountRecord(companyIdSet, firmIdSet, uploadInfoList);

					//Check record already exit in sales-force or not.
					checkExistingInfo(set_NewEmpId, set_NewUserId, set_NewEmailId, uploadInfoList);

					upsert uploadInfoList;

					if (batchLoopCount == 1) {
						//Update CSV uploaded status as in-progress.
						Research_Project_Master__c ProjectMasterObj = new Research_Project_Master__c(Id = projectObjId);
						//ProjectMasterObj.CSV_Upload_In_Progress__c = true;
						ProjectMasterObj.Uploaded_CSV_Column__c = csvQuestionMap.size() + 7;
						update ProjectMasterObj;
					}
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('UR_ImportCSVJob', 'execute', ex.getMessage(), ex.getStackTraceString());
				traceErrorMessage(ex.getMessage() + '');
			}
		}
	}

	public void finish(Database.BatchableContext context) {
		try {
			Research_Project_Master__c projectMasterObj = new Research_Project_Master__c(Id = projectObjId, CSV_Upload_In_Progress__c = false);
			update projectMasterObj;

			UR_ProcessUXResearchCSVData batchObj = new UR_ProcessUXResearchCSVData();
			batchObj.projectId = projectObjId;
			batchObj.attachementId = attachementId;
			Database.executeBatch(batchObj, 50);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_ImportCSVJob', 'finish', ex.getMessage(), ex.getStackTraceString());
			traceErrorMessage(ex.getMessage() + '');
		}
	}

	public string removeDelimiter(string strValue) {
		if (string.isBlank(strValue)) {
			strValue = '';
		} else if (string.isNotBlank(UR_Delimiter)) {
			strValue = strValue.trim();
			if (UR_Delimiter == strValue.subString(0, 1)) {
				strValue = strValue.subString(1, strValue.length());
			}
		}
		return strValue;
	}

	//This method process question only and put into a Map as : {rowIndex_7:Q1, rowIndex_8:Q2,... }
	public boolean processQuestion(List<String> csvRecordData) {
		boolean isValidCSV = true;
		String reqField = '';
		//List<String> csvRecordData = obj.split(',');
		Integer columnIndex = 1;
		List<String> sampleCSVHeader = 'first_name,last_name,email,company_id,user_id,employee_id,accounting_firm_id'.split(',');
		if (csvRecordData.size() < 7) {
			isValidCSV = false;
		} else {
			for (String question : csvRecordData) {
				if (columnIndex <= 7) {
					string strCSVColumn = string.valueof(csvRecordData[columnIndex - 1]).trim();
					string strCSVSampleColumn = string.valueof(sampleCSVHeader[columnIndex - 1]).trim();

					// if(sampleCSVHeader[columnIndex-1].equalsIgnoreCase(csvRecordData[columnIndex-1].trim()))
					if (strCSVColumn.indexOf(strCSVSampleColumn) > -1) {
						//Do nothing
					} else {
						reqField = sampleCSVHeader[columnIndex - 1];
						isValidCSV = false;
						break;
					}
				} else {
					csvQuestionMap.put(columnIndex, question);
				}
				columnIndex = columnIndex + 1;
			}
		}
		return isValidCSV;
	}

	public void checkExistingAccountRecord(Set<String> companyIdSet, Set<String> firmIdSet, List<UXR_CSV_Staging__c> uploadInfoList) {
		Map<String, Id> companyIdWithAccountMap = new Map<String, Id>();
		Map<String, Id> firmIdWithAccountMap = new Map<String, Id>();

		if (companyIdSet.size() > 0 || firmIdSet.size() > 0) {
			for (Account accObj : [
				SELECT Id, ZP_Firm_ID__c, ZP_Company_ID__c
				FROM Account
				WHERE ZP_Firm_ID__c IN :firmIdSet OR ZP_Company_ID__c IN :companyIdSet
			]) {
				//Create existing Account Map
				if (String.isNotBlank(accObj.ZP_Company_ID__c)) {
					companyIdWithAccountMap.put(accObj.ZP_Company_ID__c, accObj.id);
				}
				if (String.isNotBlank(accObj.ZP_Firm_ID__c)) {
					firmIdWithAccountMap.put(accObj.ZP_Firm_ID__c, accObj.id);
				}
			}
		}

		Boolean isAccountExist = false;
		for (UXR_CSV_Staging__c csvObj : uploadInfoList) {
			if (csvObj.CSV_Header__c == false) {
				isAccountExist = false;
				if (String.isNotBlank(csvObj.Company_Id__c) && companyIdWithAccountMap.containsKey(csvObj.Company_Id__c)) {
					isAccountExist = true;
				} else if (String.isNotBlank(csvObj.Accountant_Firm_Id__c) && firmIdWithAccountMap.containsKey(csvObj.Accountant_Firm_Id__c)) {
					isAccountExist = true;
				}

				if (isAccountExist == false) {
					csvObj.Message__c = 'Company Id ' + csvObj.Company_Id__c + ' or Accountant Firm Id ' + csvObj.Accountant_Firm_Id__c + ' does not exist';
					csvObj.Status__c = 'Fail';
				}
			}
		}
	}

	// Check existing "Research Upload Info" record.
	public void checkExistingInfo(Set<String> empId, Set<String> userId, Set<String> emailId, List<UXR_CSV_Staging__c> uploadInfoList) {
		//Research_Upload_Info__c
		try {
			Map<String, Id> existingInfoMap = new Map<String, Id>();
			String key = '';
			Id headerRecordId = null;
			for (UXR_CSV_Staging__c existingInfoObj : [
				SELECT id, User_Id__c, Email__c, Employee_Id__c, CSV_Header__c
				FROM UXR_CSV_Staging__c
				WHERE Research_Project_Master__c = :projectObjId AND (Email__c IN :empId OR User_Id__c IN :userId OR Employee_Id__c IN :emailId OR CSV_Header__c = TRUE)
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
				if (existingInfoObj.CSV_Header__c) {
					key = '';
					headerRecordId = existingInfoObj.Id;
				}
				if (String.isNotBlank(key)) {
					key = key.subString(0, key.length() - 1);
					existingInfoMap.put(key, existingInfoObj.Id);
				}
			}

			Set<Id> existingUploadData = new Set<Id>();
			for (UXR_CSV_Staging__c uploadInfoObj : uploadInfoList) {
				if (uploadInfoObj.Status__c != 'Fail') {
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
					if (uploadInfoObj.CSV_Header__c == true) {
						key = '';
						if (headerRecordId != null) {
							uploadInfoObj.Id = headerRecordId;
						}
					}
					if (String.isNotBlank(key) && existingInfoMap.containsKey(key)) {
						// update existing "Research Upload Info" record.
						if (!existingUploadData.contains(existingInfoMap.get(key))) {
							uploadInfoObj.Id = existingInfoMap.get(key);
							uploadInfoObj.Status__c = 'Success';
							existingUploadData.add(uploadInfoObj.Id);
						}
					}
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_ImportCSVJob', 'checkExistingInfo', ex.getMessage(), ex.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
		}
	}

	public void traceErrorMessage(String ex) {
		String errorDetails = 'CSV Upload Status : Error \n';
		errorDetails = errorDetails + 'Error Message : ' + ex + ' \n';
		errorDetails = errorDetails + 'CSV File : ' + URL.getSalesforceBaseUrl().toExternalForm() + '//' + attachementId + '\n\n';
		UR_UtilityCtrl.createUXRSearchingRecord('', projectObjId, 'CSV Upload', 0, errorDetails);
		updateErrorMessage(ex);
	}

	public void updateErrorMessage(String failMsg) {
		UR_ProjectMasterTriggerHelper.skipTrigger = true;
		Research_Project_Master__c obj = new Research_Project_Master__c(Id = projectObjId);
		obj.CSV_Error__c = failMsg;
		update obj;
		UR_ProjectMasterTriggerHelper.skipTrigger = false;
	}
}