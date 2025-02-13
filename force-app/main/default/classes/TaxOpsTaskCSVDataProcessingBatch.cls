public with sharing class TaxOpsTaskCSVDataProcessingBatch implements Database.Batchable<sObject> {
	public string taxOpsTaskId;
	set<id> set_taxOpsTaskIds = new Set<id>();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		string objFields;

		for (Tax_Ops_Tasks_Csv_Field_Mapping__c rec : Tax_Ops_Tasks_Csv_Field_Mapping__c.getAll().values()) {
			if (string.isBlank(rec.API_Name__c)) {
				continue;
			}
			if (string.isBlank(objFields)) {
				objFields = rec.API_Name__c;
			} else {
				objFields += ', ' + rec.API_Name__c;
			}
		}

		string quertStr =
			' SELECT Id,Message__c,Processed_At__c, Processing_Status__c,Record_Type__c,Tax_Ops_Task__c, ' +
			objFields +
			'  FROM Tax_Ops_Tasks_Csv_Data__c WHERE Tax_Ops_Task__c =:taxOpsTaskId AND Processing_Status__c=\'Queued\' ';

		return Database.getQueryLocator(quertStr);
	}

	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		map<string, list<Tax_Ops_Tasks_Csv_Data__c>> map_parentIdCsvRecordList = new Map<string, list<Tax_Ops_Tasks_Csv_Data__c>>();
		list<Tax_Ops_Tasks_Csv_Data__c> lst_CSVData = (list<Tax_Ops_Tasks_Csv_Data__c>) scope;
		TaxOpsTaskCSVDataTriggerHelper helper = new TaxOpsTaskCSVDataTriggerHelper();

		if (lst_CSVData != null && lst_CSVData.size() > 0) {
			for (Tax_Ops_Tasks_Csv_Data__c obj_csvData : lst_CSVData) {
				if (obj_csvData.Tax_Ops_Task__c != null) {
					list<Tax_Ops_Tasks_Csv_Data__c> lst_tempCsvData = new List<Tax_Ops_Tasks_Csv_Data__c>();

					if (map_parentIdCsvRecordList.containsKey(obj_csvData.Tax_Ops_Task__c)) {
						lst_tempCsvData = map_parentIdCsvRecordList.get(obj_csvData.Tax_Ops_Task__c);
					}
					lst_tempCsvData.add(obj_csvData);
					map_parentIdCsvRecordList.put(obj_csvData.Tax_Ops_Task__c, lst_tempCsvData);
				} else {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Parent information missing.', obj_csvData);
					continue;
				}

				set_taxOpsTaskIds.add(obj_csvData.Tax_Ops_Task__c);
			}

			if (map_parentIdCsvRecordList.keyset().size() > 0) {
				map<id, Tax_Ops_Task__c> map_taxOpsIdRecord = new Map<id, Tax_Ops_Task__c>(
					[
						SELECT Id, Failed_Filing_Account_Numbers__c, Tax_Code__c, Failed_Filing_FEINs__c, Failed_Payment_FEINs__c, Failed_Payment_Account_Numbers__c
						FROM Tax_Ops_Task__c
						WHERE Id IN :map_parentIdCsvRecordList.keyset()
					]
				);

				for (string taxOpsId : map_parentIdCsvRecordList.keyset()) {
					createFailedRecordsForTaxOps(map_parentIdCsvRecordList.get(taxOpsId), map_taxOpsIdRecord.get(taxOpsId));
				}

				try {
					TaxOpsTaskCSVDataTriggerHelper.SkipTrigger = true;
					update lst_CSVData;
					TaxOpsTaskCSVDataTriggerHelper.SkipTrigger = false;
				} catch (exception ex) {
				}
			}
		}
	}

	private void createFailedRecordsForTaxOps(List<Tax_Ops_Tasks_Csv_Data__c> lst_CSVData, Tax_Ops_Task__c taxOpsRecObj) {
		set<string> accountNumberSet = new Set<string>();
		set<string> feinSet = new Set<string>();
		Map<string, string> labelApiMap = new Map<string, string>();
		List<Tax_Ops_Failed_Record__c> lst_FailedRecords = new List<Tax_Ops_Failed_Record__c>();

		string taxCode = taxOpsRecObj.Tax_Code__c;
		id parentId = taxOpsRecObj.id;
		string recordTypeId = lst_CSVData.get(0).Record_Type__c;

		if (lst_CSVData != null && lst_CSVData.size() > 0) {
			for (Tax_Ops_Tasks_Csv_Field_Mapping__c rec : Tax_Ops_Tasks_Csv_Field_Mapping__c.getAll().values()) {
				labelApiMap.put(rec.Field_Label__c, rec.API_Name__c);
			}

			Map<String, Schema.SObjectField> map_failedRecordFieldMap = Schema.SObjectType.Tax_Ops_Failed_Record__c.fields.getMap();

			for (Tax_Ops_Tasks_Csv_Data__c csvDataObj : lst_CSVData) {
				if (labelApiMap.keyset().size() == 0) {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Field mapping information is missing.', csvDataObj);
					continue;
				}

				Tax_Ops_Failed_Record__c failedRec = new Tax_Ops_Failed_Record__c();
				failedRec.Tax_Ops_Task__c = csvDataObj.Tax_Ops_Task__c;
				failedRec.recordTypeId = csvDataObj.Record_Type__c;

				for (string commonAPINameStr : labelApiMap.values()) {
					if (map_failedRecordFieldMap.containsKey(commonAPINameStr) && !map_failedRecordFieldMap.get(commonAPINameStr).getDescribe().isUpdateable()) {
						continue;
					}

					if (!doesFieldExist(commonAPINameStr)) {
						continue;
					}

					string fieldValStr = STRING.valueOf(csvDataObj.get(commonAPINameStr));
					if ('Amount_Held__c'.equalsIgnoreCase(commonAPINameStr) && string.isNotBlank(fieldValStr)) {
						Decimal dValue = decimal.valueOf(fieldValStr);
						failedRec.put(commonAPINameStr, dValue);
					} else if ('Uploaded_to_Koala__c'.equalsIgnoreCase(commonAPINameStr) || 'Filing_Successful__c'.equalsIgnoreCase(commonAPINameStr)) {
						if (fieldValStr == null || fieldValStr.equalsIgnoreCase('false')) {
							failedRec.put(commonAPINameStr, false);
						} else {
							failedRec.put(commonAPINameStr, true);
						}
					} else {
						if ('Account_Number__c'.equalsIgnoreCase(commonAPINameStr) && string.isNotBlank(fieldValStr)) {
							fieldValStr = replaceSpecialCharacters(fieldValStr);
							accountNumberSet.add(fieldValStr);
						} else if ('FEIN__c'.equalsIgnoreCase(commonAPINameStr) && string.isNotBlank(fieldValStr)) {
							fieldValStr = replaceSpecialCharacters(fieldValStr);
							feinSet.add(fieldValStr);
						}

						failedRec.put(commonAPINameStr, fieldValStr);
					}
				}

				lst_FailedRecords.add(failedRec);
			}

			map<string, id> feindAccIdMap = new Map<string, id>();
			map<string, id> accNumAccIdMap = new Map<string, id>();
			TaxOpsFailedRecordsCreationController controller = new TaxOpsFailedRecordsCreationController();
			if (feinSet.size() > 0) {
				feindAccIdMap = controller.getFeinAccNumAccountMap(feinSet, taxCode, true);
			}

			if (accountNumberSet.size() > 0) {
				accNumAccIdMap = controller.getFeinAccNumAccountMap(accountNumberSet, taxCode, false);
			}

			if (feindAccIdMap.keyset().size() > 0) {
				map<string, Tax_Ops_Failed_Record__c> uniqueFRMap = new Map<string, Tax_Ops_Failed_Record__c>();
				for (Tax_Ops_Failed_Record__c rec : lst_FailedRecords) {
					if (rec.Account__c == null && rec.FEIN__c != null && feindAccIdMap.containsKey(rec.FEIN__c)) {
						rec.Account__c = feindAccIdMap.get(rec.FEIN__c);
					}

					if (rec.Account__c == null && rec.Account_Number__c != null && accNumAccIdMap.containsKey(rec.Account_Number__c)) {
						rec.Account__c = accNumAccIdMap.get(rec.Account_Number__c);
					}

					string keyStr;
					if (rec.FEIN__c != null) {
						keyStr = rec.FEIN__c;
					} else if (rec.Account_Number__c != null) {
						keyStr = rec.Account_Number__c;
					}
					if (keyStr != null && uniqueFRMap.containsKey(keyStr)) {
						rec.isDuplicate__c = true;
						Tax_Ops_Failed_Record__c tempRec = uniqueFRMap.get(keyStr);
					} else {
						uniqueFRMap.put(keyStr, rec);
					}
				}
			}

			if (lst_FailedRecords != null && lst_FailedRecords.size() > 0) {
				try {
					Map<String, String> dmlCaseUpsertErrorsMap = new Map<String, String>();

					List<Database.SaveResult> saveResult = database.insert(lst_FailedRecords, false);
					dmlCaseUpsertErrorsMap = processSaveResult(saveResult, lst_FailedRecords);

					for (Tax_Ops_Tasks_Csv_Data__c objFailedRec : lst_CSVData) {
						if (objFailedRec.Processing_Status__c == IntegrationUtils.DEAD_STATE || objFailedRec.Processing_Status__c == IntegrationUtils.ERROR_STATE) {
							continue;
						}

						string keyStr = objFailedRec.fein__c + objFailedRec.Account_Number__c;

						if (dmlCaseUpsertErrorsMap.containsKey(keyStr)) {
							setProcessingState(IntegrationUtils.ERROR_STATE, dmlCaseUpsertErrorsMap.get(keyStr), objFailedRec);
							continue;
						} else {
							setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Data successfully Processed', objFailedRec);
						}
					}

					if (accountNumberSet.size() > 0 || feinSet.size() > 0) {
						Tax_Ops_Task__c tempTaskRec = taxOpsRecObj;
						string recordTypeName = cache.getRecordTypeName('Tax_Ops_Failed_Record__c', recordTypeId);

						if (accountNumberSet.size() > 0) {
							list<string> tempList = new List<string>();
							tempList.addAll(accountNumberSet);
							if (recordTypeName != null && recordTypeName.equalsIgnoreCase('Failed Filing')) {
								if (String.isNotBlank(tempTaskRec.Failed_Filing_Account_Numbers__c)) {
									tempTaskRec.Failed_Filing_Account_Numbers__c += ',';
									tempTaskRec.Failed_Filing_Account_Numbers__c += string.join(tempList, ',');
								} else {
									tempTaskRec.Failed_Filing_Account_Numbers__c = string.join(tempList, ',');
								}
							} else {
								if (String.isNotBlank(tempTaskRec.Failed_Payment_Account_Numbers__c)) {
									tempTaskRec.Failed_Payment_Account_Numbers__c += ',';
									tempTaskRec.Failed_Payment_Account_Numbers__c += string.join(tempList, ',');
								} else {
									tempTaskRec.Failed_Payment_Account_Numbers__c = string.join(tempList, ',');
								}
							}
						}

						if (feinSet.size() > 0) {
							list<string> tempList = new List<string>();
							tempList.addAll(feinSet);
							if (recordTypeName != null && recordTypeName.equalsIgnoreCase('Failed Filing')) {
								if (String.isNotBlank(tempTaskRec.Failed_Filing_FEINs__c)) {
									tempTaskRec.Failed_Filing_FEINs__c += ',';
									tempTaskRec.Failed_Filing_FEINs__c += string.join(tempList, ',');
								} else {
									tempTaskRec.Failed_Filing_FEINs__c = string.join(tempList, ',');
								}
							} 
						}
						update tempTaskRec;
					}
				} catch (exception ex) {
					for (Tax_Ops_Tasks_Csv_Data__c objFailedRec : lst_CSVData) {
						if (objFailedRec.Processing_Status__c == IntegrationUtils.DEAD_STATE || objFailedRec.Processing_Status__c == IntegrationUtils.ERROR_STATE) {
							continue;
						}
						setProcessingState(IntegrationUtils.ERROR_STATE, ex.getMessage(), objFailedRec);
					}
				}
			}
		}
	}
	
	private boolean doesFieldExist(string fieldName) {
		try {
			return Utils.getSObjectDescribe('Tax_Ops_Tasks_Csv_Data__c').fields.getMap().containsKey(fieldName);
		} catch (Exception ex) {
		}

		return false;
	}

	private Tax_Ops_Tasks_Csv_Data__c setProcessingState(String ProcessingState, String message, Tax_Ops_Tasks_Csv_Data__c objCSVData) {
		objCSVData.Processing_Status__c = ProcessingState;
		objCSVData.Message__c = message;
		objCSVData.Processed_At__c = System.now();
		return objCSVData;
	}

	private Map<String, String> processSaveResult(List<Database.SaveResult> saveResult, List<SObject> listOfSObjectRecords) {
		Map<String, String> errorMap = new Map<String, String>();
		integer i = 0;

		for (Database.SaveResult result : saveResult) {
			if (!result.isSuccess()) {
				String errorMessage = ConsolidateErrors(result.getErrors());
				String mapKey = String.valueOf(listOfSObjectRecords[i].get('FEIN__c')) + string.valueof(listOfSObjectRecords[i].get('Account_Number__c'));
				errorMap.put(mapKey, errorMessage);
			}
			i++;
		}

		return errorMap;
	}

	public string ConsolidateErrors(Database.Error[] errors) {
		string s = '';
		for (Database.Error err : errors) {
			s += '    ' + err.getMessage() + '\n';
		}
		return s;
	}

	//by:PR, Date: 7/10/19, Desc: below method is removing all the special characters.
	private String replaceSpecialCharacters(String val) {
		if (string.isNotBlank(val)) {
			String res = val.replaceAll('[^a-zA-Z0-9]', '');
			return res;
		}
		return val;
	}

	public void finish(Database.BatchableContext BC) {
		Tax_Ops_Task__c tempObj = new Tax_Ops_Task__c(id = taxOpsTaskId, CSV_File_Processing__c = false);

		try {
			update tempObj;
		} catch (exception ex) {
		}
	}
}