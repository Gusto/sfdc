public with sharing class TaxOpsTaskCSVImportController {
	public string headerLabelStr { get; set; }
	public list<string> failedRecordsDetailList { get; set; }
	public list<string> failedRecordsDetailListNoDups { get; set; }

	list<Schema.FieldSetMember> fieldsApiNameList;
	list<Tax_Ops_Failed_Record__c> failedRecordList;
	id taxOpsTaskId;

	public TaxOpsTaskCSVImportController(apexPages.standardController sc) {
		taxOpsTaskId = sc.getId();
	}

	public TaxOpsTaskCSVImportController() {
		taxOpsTaskId = apexPages.currentPage().getParameters().get('id');
		gatherCSVData();
	}

	public pagereference saveChildDetailsAsCSVAttachment() {
		if (string.isNotBlank(taxOpsTaskId)) {
			list<Tax_Ops_Task__c> taskRecList = [SELECT id, RecordType.Name, Tax_Code__c, Period_End__c FROM Tax_Ops_Task__c WHERE id = :taxOpsTaskId];

			if (taskRecList.size() > 0) {
				Attachment attRec = new Attachment();
				attRec.ParentId = taskRecList.get(0).id;
				string todayDate = string.valueof(system.today().month()) + '/' + string.valueof(system.today().day()) + '/' + string.valueof(system.today().year());
				string periodEndDate;
				if (taskRecList.get(0).Period_End__c != null) {
					periodEndDate =
						string.valueof(taskRecList.get(0).Period_End__c.month()) +
						'/' +
						string.valueof(taskRecList.get(0).Period_End__c.day()) +
						'/' +
						string.valueof(taskRecList.get(0).Period_End__c.year());
				}
				attRec.Name = taskRecList.get(0).RecordType.Name + '_' + taskRecList.get(0).Tax_Code__c + '_' + (string.isNotBlank(periodEndDate) ? periodEndDate : ' ') + '_' + todayDate + '.csv';
				attRec.body = getCSV(taxOpsTaskId);
				attRec.ContentType = 'text/csv';

				try {
					insert attRec;
					apexPages.addMessage(new apexPages.message(apexPages.Severity.Info, 'CSV file successfuly created and saved.'));
				} catch (exception ex) {
					apexPages.addMessage(new apexPages.message(apexPages.Severity.Info, 'Error occured while saving the file as an attachment. Please contact system admin.' + ex.getMessage()));
				}
			}
		}

		return null;
	}

	private Blob getCSV(string recId) {
		Blob csv;
		if (Test.isRunningTest()) {
			// Test methods don't support getContent call
			csv = Blob.valueOf('Sample');
		} else {
			PageReference pr = new PageReference('/apex/GenerateCSV');
			pr.getParameters().put('id', recId);
			try {
				csv = pr.getContent();
			} catch (Exception e) {
				//Errorlogger.logError('CSV generation failed from PageReference '+pr.getUrl(), e);
			}
		}

		return csv;
	}

	//=====================================================

	//return fields of the fieldSet whose name we have passed as a parameter
	public static List<Schema.FieldSetMember> getFields(String fieldSetName, String ObjectName) {
		Schema.DescribeSObjectResult DescribeSObjectResultObj = Utils.getSObjectDescribe(ObjectName);
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		return fieldSetObj.getFields();
	}

	public void gatherCSVData() {
		if (taxOpsTaskId == null) {
			return;
		}
		failedRecordList = new List<Tax_Ops_Failed_Record__c>();
		fieldsApiNameList = new List<Schema.FieldSetMember>();
		failedRecordsDetailList = new List<string>();
		failedRecordsDetailListNoDups = new List<String>();
		fieldsApiNameList = getFields('csvImportEligibleFields', 'Tax_Ops_Failed_Record__c');
		string queryStr = 'Select ';
		for (Schema.FieldSetMember field : fieldsApiNameList) {
			queryStr += field.getFieldPath() + ', ';
		}

		queryStr += ' id,Account__r.Name,RecordType.Name, isDuplicate__c, Inactive__c from Tax_Ops_Failed_Record__c where Tax_Ops_Task__c =:taxOpsTaskId and RecordType.Name=\'Failed Filing\'';
		for (Tax_Ops_Failed_Record__c rec : database.query(queryStr)) {
			string fieldValueCSVStr = '';
			boolean isheaderStored = true;
			if (string.isBlank(headerLabelStr)) {
				isheaderStored = false;
				headerLabelStr = '';
			}
			for (Schema.FieldSetMember fieldName : fieldsApiNameList) {
				if (fieldName.getFieldPath().equalsIgnoreCase('recordtypeId')) {
					fieldValueCSVStr += '\"' + rec.RecordType.Name + '\",';
				} else if (fieldName.getFieldPath().equalsIgnoreCase('Account__c')) {
					if (rec.Account__c != null) {
						fieldValueCSVStr += '\"' + rec.Account__r.Name + '\",';
					} else {
						fieldValueCSVStr += '\" \",';
					}
				} else {
					if (rec.get(fieldName.getFieldPath()) != null) {
						fieldValueCSVStr += '\"' + rec.get(fieldName.getFieldPath()) + '\",';
					} else {
						fieldValueCSVStr += '\" \",';
					}
				}

				if (!isheaderStored) {
					headerLabelStr += '\"' + fieldName.getLabel() + '\",';
				}
			}
			fieldValueCSVStr = fieldValueCSVStr.substring(0, fieldValueCSVStr.length() - 2);
			failedRecordsDetailList.add(fieldValueCSVStr.trim());

			if (rec.Inactive__c == false && rec.isDuplicate__c == false)
				failedRecordsDetailListNoDups.add(fieldValueCSVStr.trim());
		}
		if (string.isNotBlank(headerLabelStr)) {
			headerLabelStr = headerLabelStr.trim();
			if (headerLabelStr.lastIndexOfIgnoreCase(',') == (headerLabelStr.length() - 1)) {
				headerLabelStr = headerLabelStr.substringBeforeLast(',');
			}
		}
	}
}