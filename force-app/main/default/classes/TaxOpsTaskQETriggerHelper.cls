public with sharing class TaxOpsTaskQETriggerHelper {
	public static boolean skipTrigger = false;
	public static boolean queue = false;
	public static integer counter = 0;
	public static boolean fromUpdate = false;

	public TaxOpsTaskQETriggerHelper() {
	}

	public void OnBeforeInsert(Tax_Ops_Task_QE__c[] newRecords) {
		counter++;
		if (queue == true) {
			processInformation(newRecords);
		} else {
			for (Tax_Ops_Task_QE__c info : newRecords) {
				info.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Tax_Ops_Task_QE__c[] newRecords) {
		if (queue == false) {
			TaxOpsTaskQEQueue insertJob = new TaxOpsTaskQEQueue(newRecords);
			ID jobID = System.enqueueJob(insertJob);
		}
	}

	public void OnBeforeUpdate(Tax_Ops_Task_QE__c[] oldRecords, Tax_Ops_Task_QE__c[] updatedRecords, Map<ID, Tax_Ops_Task_QE__c> recordMap) {
		counter++;
		// we only want to process the records for insert scenario
		if (queue == true) {
			processInformation(updatedRecords);
		} else {
			for (Tax_Ops_Task_QE__c qeRec : updatedRecords) {
				// setProcessingState(IntegrationUtils.PROCESSED_STATE,'Update is not possible for this object.',qeRec);
			}
		}
	}

	public void OnAfterUpdate(Tax_Ops_Task_QE__c[] oldRecords, Tax_Ops_Task_QE__c[] updatedRecords, Map<ID, Tax_Ops_Task_QE__c> recordMap) {
		if (queue == false) {
			TaxOpsTaskQEQueue insertJob = new TaxOpsTaskQEQueue(updatedRecords);
		}
	}

	public void OnBeforeDelete(Tax_Ops_Task_QE__c[] recordsToDelete, Map<ID, Tax_Ops_Task_QE__c> recordMap) {
	}

	public void OnAfterDelete(Tax_Ops_Task_QE__c[] deletedRecords, Map<ID, Tax_Ops_Task_QE__c> recordMap) {
	}

	public void OnUndelete(Tax_Ops_Task_QE__c[] restoredRecords) {
	}

	public void processInformation(Tax_Ops_Task_QE__c[] taskQERecords) {
		if (taskQERecords != null && taskQERecords.size() > 0) {
			list<Tax_Ops_Task__c> toInsertTaxOpsTaskList = new List<Tax_Ops_Task__c>();

			sourceApiNameMap = getEditableFieldLabelList('Tax_Ops_Task_QE__c');
			destinationApiNameMap = getEditableFieldLabelList('Tax_Ops_Task__c');

			list<Group> defaultQueueList = [SELECT id, Name FROM Group WHERE DeveloperName = 'Needs_Attention_Unassigned' AND Type = 'Queue'];

			for (Tax_Ops_Task_QE__c qeRec : taskQERecords) {
				Tax_Ops_Task__c taskRec = new Tax_Ops_Task__c();
				// make sure that apiname maps are populated before calling the sync method.
				taskRec = SyncRecordsTaxOpsTask(qeRec, taskRec);
				if (defaultQueueList.size() > 0) {
					taskrec.OwnerId = defaultQueueList.get(0).id;
				}
				taskrec.status__c = 'New';
				toInsertTaxOpsTaskList.add(taskRec);
			}

			Map<String, String> dmlInsertErrorsMap = new Map<String, String>();

			if (toInsertTaxOpsTaskList.size() > 0) {
				List<Database.SaveResult> saveResult = database.insert(toInsertTaxOpsTaskList, false);
				dmlInsertErrorsMap = Utils.processSaveResult(saveResult, toInsertTaxOpsTaskList, 'Tax_code__c', true, 'TaxOpsTaskQETriggerHelper-processInformation');
			}

			for (Tax_Ops_Task_QE__c qeRec : taskQERecords) {
				if (dmlInsertErrorsMap.containsKey(qeRec.Tax_code__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, dmlInsertErrorsMap.get(qeRec.Tax_code__c), qeRec);
				} else {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', qeRec);
				}
			}
		}
	}

	private Tax_Ops_Task_QE__c setProcessingState(String ProcessingState, String message, Tax_Ops_Task_QE__c taskQEInfo) {
		taskQEInfo.Processing_State__c = ProcessingState;
		taskQEInfo.Message__c = message;
		taskQEInfo.Last_Processed__c = System.now();
		return taskQEInfo;
	}

	map<string, string> sourceApiNameMap = new Map<string, string>();
	map<string, string> destinationApiNameMap = new Map<string, string>();

	public Tax_Ops_Task__c SyncRecordsTaxOpsTask(Tax_Ops_Task_QE__c sourceRecord, Tax_Ops_Task__c destinationRecord) {
		string SourceObjectName = 'Tax_Ops_Task_QE__c';
		String DestinationObjectName = 'Tax_Ops_Task__c';

		for (string sourceApiName : sourceApiNameMap.Keyset()) {
			if (destinationApiNameMap.containsKey(sourceApiName)) {
				destinationRecord.put(destinationApiNameMap.get(sourceApiName), sourceRecord.get(sourceApiNameMap.get(sourceApiName)));
			}
		}

		return destinationRecord;
	}

	public map<string, string> getEditableFieldLabelList(string ObjectApiName) {
		map<String, string> FieldNameMap = new Map<string, string>();
		Map<string, schema.sobjecttype> globalObjectsMap = Schema.getGlobalDescribe();
		Set<string> objectKeys = globalObjectsMap.keySet();

		if (objectKeys.contains(ObjectApiName.toLowerCase())) {
			Schema.DescribeSObjectResult r = globalObjectsMap.get(ObjectApiName).getDescribe();
			Map<String, Schema.SObjectField> fieldMap = r.fields.getMap();
			for (String str : fieldMap.keySet()) {
				Schema.DescribeFieldResult fieldDescribe = fieldMap.get(str).getDescribe();
				if (fieldDescribe.isCustom()) {
					FieldNameMap.put(fieldDescribe.getLabel(), str);
				}
			}
		}

		return FieldNameMap;
	}
}