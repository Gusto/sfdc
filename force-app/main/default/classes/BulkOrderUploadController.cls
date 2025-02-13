public with sharing class BulkOrderUploadController {
	public Boolean readSuccess { get; set; }
	public Set<String> setFieldNames { get; set; }
	public Map<String, String> fieldNamesMap { get; set; }
	public Bulk_Migration_Request__c BMRRecord { get; set; }
	public string testCSVData { get; set; }
	public List<Bulk_Order_CSV_Data__c> lstCSVRecords { get; set; }
	public List<Bulk_Order_CSV_Data__c> lstCSVRecordsFinal { get; set; }

	public Set<string> companyIdSet = new Set<string>();
	public Blob fileData { get; set; }
	String CSVDataAsString;
	String fieldValue;
	Integer fieldNumber;
	string message = '';
	Map<String, Integer> fieldNumberMap = new Map<String, Integer>();
	Map<String, string> fieldsCustSettingsMap = new Map<String, string>();
	Id bulkMigrationId { get; set; }

	public BulkOrderUploadController() {
		lstCSVRecordsFinal = new List<Bulk_Order_CSV_Data__c>();
		setFieldNames = new Set<string>();
		readSuccess = false;

		Map<String, Bulk_Order_CSV_Columns__c> uploadSetting = Bulk_Order_CSV_Columns__c.getAll();
		for (Bulk_Order_CSV_Columns__c temp : uploadSetting.Values()) {
			string sfieldName = temp.Field_Values__c.replaceAll('[^a-zA-Z0-9]', '').trim();
			fieldsCustSettingsMap.put(sfieldName, String.valueOf(temp.Field_API_Name__c));
		}
		bulkMigrationId = ApexPages.currentPage().getParameters().get('id');

		if (!String.isEmpty(bulkMigrationId)) {
			populateBulMigrationFields(bulkMigrationId);
		} else {
			BMRRecord = new Bulk_Migration_Request__c();
		}
	}
	public void populateBulMigrationFields(Id bulMigId) {
		List<Bulk_Migration_Request__c> bulkMigRequestList = [
			SELECT
				Id,
				Requested_By__c,
				Bulk_Migration_Owner__c,
				Bulk_Migration_Status__c,
				Requested_First_Check_Date__c,
				Primary_Point_of_Contact__c,
				Final_Check_Date__c,
				Transition_To_Fulfillment__c,
				Reseller_Account__c,
				OwnerId
			FROM Bulk_Migration_Request__c
			WHERE ID = :bulMigId
		];

		if (bulkMigRequestList != null && bulkMigRequestList.size() > 0) {
			BMRRecord = bulkMigRequestList[0];
		}
	}

	List<List<String>> allData;
	private List<List<String>> parseCSV(string contents) {
		try {
			String freshString = '';
			List<String> lines = new List<String>();
			lines.addAll(contents.split('\r\n'));
			callDataParsing(lines);
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		return allData;
	}
	public void callDataParsing(List<string> lines) {
		allData = new List<List<String>>();
		for (String line : lines) {
			if (line.replaceAll(',', '').trim().length() == 0) {
				break;
			}

			List<String> cleanFields = new List<String>();
			String compositeField;
			Boolean makeCompositeField = false;

			for (String field : line.split(',')) {
				if (!'#EOL#'.equalsIgnoreCase(field)) {
					if (field.trim().startsWith('"') && field.trim().endsWith('"')) {
						cleanFields.add(field.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
					} else if (field.trim().startsWith('"')) {
						makeCompositeField = true;
						compositeField = field.trim();
					} else if (field.trim().endsWith('"')) {
						compositeField += ',' + field.trim();
						cleanFields.add(compositeField.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
						makeCompositeField = false;
					} else if (makeCompositeField) {
						compositeField += ',' + field.trim();
					} else {
						cleanFields.add(field.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
					}
				}
			}
			allData.add(cleanFields);
		}
	}
	public void readCSVFile(List<List<String>> allData) {
		Set<string> bulkOrderCSVDataObjFieldsSet = getCSVObjectFields();
		//lstCSVRecords.clear();
		lstCSVRecordsFinal.clear();
		fieldNamesMap = new Map<String, String>();
		List<Bulk_Order_CSV_Data__c> lstCSVRecords = new List<Bulk_Order_CSV_Data__c>();
		string[] csvFieldNames = allData[0];
		for (Integer i = 0; i < csvFieldNames.size(); i++) {
			fieldNumberMap.put(csvFieldNames[i], i);

			String apiName = getFieldMapping(csvFieldNames[i].trim());
			if (apiName != null) {
				if (bulkOrderCSVDataObjFieldsSet.contains(apiName)) {
					fieldNamesMap.put(csvFieldNames[i].trim(), apiName);
					setFieldNames.add(csvFieldNames[i].trim());
				}
			}
		}
		for (Integer i = 1; i < allData.size(); i++) {
			Bulk_Order_CSV_Data__c oppObj = new Bulk_Order_CSV_Data__c();
			String[] csvRecordData = allData[i];
			if (csvRecordData.size() > 0) {
				for (String fieldName : csvFieldNames) {
					fieldNumber = fieldNumberMap.get(fieldName);
					if (csvRecordData.size() - 1 >= fieldNumber) {
						fieldValue = csvRecordData[fieldNumber];
					} else {
						fieldValue = '';
					}
					String apiName = fieldNamesMap.get(fieldName.trim());
					if (apiName != null) {
						if (bulkOrderCSVDataObjFieldsSet.contains(apiName)) {
							oppObj.put(apiName, fieldValue.trim());
						}
					}
				}

				lstCSVRecords.add(oppObj);
			}
		}
		if (lstCSVRecords.size() > 0) {
			// Remove duplicate records
			companyIdSet.clear();
			for (Bulk_Order_CSV_Data__c obj : lstCSVRecords) {
				if (!companyIdSet.contains(obj.Company_ID__c)) {
					obj.OwnerId = UserInfo.getUserId();
					lstCSVRecordsFinal.add(obj);
					companyIdSet.add(obj.Company_ID__c);
				}
			}
			if (lstCSVRecordsFinal.size() > 0) {
				readSuccess = true;
			} else {
				readSuccess = false;
				message = 'CSV cannot be recognized. Please upload correct CSV';
				displayErrorMessage(message);
			}
		} else {
			readSuccess = false;
			message = 'CSV does not have any data rows. Please update your file and try again.';
			displayErrorMessage(message);
		}
	}
	public void readFromFile() {
		try {
			if (!Test.isRunningTest()) {
				CSVDataAsString = fileData.toString();
			} else {
				CSVDataAsString = testCSVData;
			}

			List<List<String>> cleanData = parseCSV(CSVDataAsString);
			if (cleanData.size() > 0) {
				readCSVFile(cleanData);
			} else {
				readSuccess = false;
				message = 'Invalid csv file. Please upload correct csv file.';
				displayErrorMessage(message);
			}
		} catch (exception e) {
			readSuccess = false;
			if (e.getMessage() == 'Argument cannot be null.') {
				message = 'Please Select and Upload CSV File';
			} else if (e.getMessage() == 'BLOB is not a valid UTF-8 string') {
				message = 'Only CSV file is allowed';
			} else {
				message = 'Invalid csv /Error reading csv file' + '<Br/>' + 'Exception === ' + e.getMessage() + ' ' + e.getStackTraceString();
			}
			displayErrorMessage(message);
		}
	}
	public String getFieldMapping(String fieldName) {
		String fieldAPIName;
		string sFiledName = fieldName.replaceAll('[^a-zA-Z0-9]', '').trim();
		if (fieldsCustSettingsMap.containsKey(sFiledName)) {
			fieldAPIName = fieldsCustSettingsMap.get(sFiledName);
		}
		return fieldAPIName;
	}
	public void discard() {
		lstCSVRecordsFinal.clear();
		readSuccess = false;
		ApexPages.getMessages().clear();
	}
	public PageReference confirm() {
		Boolean isValidDate = validateDate(lstCSVRecordsFinal);
		if (!isValidDate) {
			return null;
		}

		bulkMigrationId = ApexPages.currentPage().getParameters().get('id');
		Id bmrId;
		Savepoint sp = Database.setSavepoint();
		if (String.IsEmpty(bulkMigrationId)) {
			// Insert scenario
			BMRRecord.Bulk_Migration_Status__c = 'New';
			BMRRecord.Type__c = 'Bulk Migration';

			Database.SaveResult srList = Database.insert(BMRRecord, false);
			if (!srList.isSuccess()) {
				for (Database.Error error : srList.getErrors()) {
					message += error.getMessage() + ';';
				}
				Database.rollback(sp);
				displayErrorMessage(message);
				return null;
			} else {
				bmrId = srList.getId();
			}
		} else {
			// Update scenario
			bmrId = bulkMigrationId; // recieved as a page parameter
			BMRRecord.Bulk_Migration_Status__c = 'In Progress';
			update BMRRecord;
		}

		for (Bulk_Order_CSV_Data__c temp : lstCSVRecordsFinal) {
			temp.Bulk_Migration_Request__c = bmrId;
		}
		Database.SaveResult[] orderList = Database.insert(lstCSVRecordsFinal, false);
		// Iterate through each returned result
		for (Database.SaveResult sr : orderList) {
			if (sr.isSuccess()) {
				PageReference orderPage = new PageReference('/apex/BulkOrderUploadStatus?id=' + bmrId);
				orderPage.setRedirect(true);
				return orderPage;
			} else {
				for (Database.Error error : sr.getErrors()) {
					message += error.getMessage() + ';';
				}
				Database.rollback(sp);
				displayErrorMessage(message);
			}
		}

		return null;
	}

	public Set<String> getCSVObjectFields() {
		Set<string> fieldsSet = new Set<String>();
		Schema.DescribeSObjectResult a_desc = Bulk_Order_CSV_Data__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> a_fields = a_desc.fields.getMap();
		for (Schema.sObjectField fld : a_fields.values()) {
			fieldsSet.add(String.valueOf(fld));
		}
		return fieldsSet;
	}

	public boolean validateDate(List<Bulk_Order_CSV_Data__c> bulkOrderCSVDataList) {
		integer i = 0;
		for (Bulk_Order_CSV_Data__c obj : bulkOrderCSVDataList) {
			try {
				i++;
				if (!String.isBlank(obj.First_Pay_Date__c)) {
					Date d = date.ValueOf(obj.First_Pay_Date__c);
				}
			} catch (Exception e) {
				message = 'Invalid date format : ' + obj.First_Pay_Date__c + ' (at row no. ' + i + ')';
				displayErrorMessage(message);
				return false;
			}
		}
		return true;
	}

	public void displayErrorMessage(string message) {
		if (!String.isBlank(message)) {
			ApexPages.getMessages().clear();
			ApexPages.Message errorMessage;
			errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR, message);
			ApexPages.addMessage(errorMessage);
		}
	}
}