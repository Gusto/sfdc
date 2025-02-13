/**
Created by : Gaurav Khare
Created Date : 4/23/2019
Reference :  
**/
public with sharing class BulkUserUploadController {
	public Boolean readSuccess { get; set; }
	public Set<String> setFieldNames { get; set; }
	public Map<String, String> fieldNamesMap { get; set; }
	public Bulk_Migration_Request__c BMRRecord { get; set; }
	public String testCSVData { get; set; }
	public List<Bulk_User_CSV_Data__c> lstCSVRecordsFinal { get; set; }

	public Set<string> newUserSet = new Set<string>();
	public Set<string> updateUserSet = new Set<string>();
	public Blob fileData { get; set; }
	String CSVDataAsString;
	String fieldValue;
	Integer fieldNumber;
	String message = '';
	Map<String, Integer> fieldNumberMap = new Map<String, Integer>();
	Map<String, string> fieldsCustSettingsMap = new Map<String, string>();

	public BulkUserUploadController() {
		lstCSVRecordsFinal = new List<Bulk_User_CSV_Data__c>();
		setFieldNames = new Set<string>();
		readSuccess = false;
		BMRRecord = new Bulk_Migration_Request__c();
		Map<String, Bulk_User_CSV_Columns__c> uploadSetting = Bulk_User_CSV_Columns__c.getAll();
		for (Bulk_User_CSV_Columns__c temp : uploadSetting.Values()) {
			string sfieldName = temp.Field_Values__c.replaceAll('[^a-zA-Z0-9]', '').trim();
			fieldsCustSettingsMap.put(sfieldName, String.valueOf(temp.Field_API_Name__c));
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
			System.debug(logginglevel.ERROR, ex.getMessage());
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
		String csvId = String.valueOf(DateTime.now()).replaceAll('[^a-zA-Z0-9]', '').trim();
		Set<string> bulkUserCSVDataObjFieldsSet = getCSVObjectFields();
		lstCSVRecordsFinal.clear();
		fieldNamesMap = new Map<String, String>();
		List<Bulk_User_CSV_Data__c> lstCSVRecords = new List<Bulk_User_CSV_Data__c>();
		String[] csvFieldNames = allData[0];
		for (Integer i = 0; i < csvFieldNames.size(); i++) {
			fieldNumberMap.put(csvFieldNames[i], i);

			String apiName = getFieldMapping(csvFieldNames[i].trim());
			if (apiName != null) {
				if (bulkUserCSVDataObjFieldsSet.contains(apiName)) {
					fieldNamesMap.put(csvFieldNames[i].trim(), apiName);
					setFieldNames.add(csvFieldNames[i].trim());
				}
			}
		}
		for (Integer i = 1; i < allData.size(); i++) {
			Bulk_User_CSV_Data__c bulkCSVObj = new Bulk_User_CSV_Data__c();
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
						if (bulkUserCSVDataObjFieldsSet.contains(apiName)) {
							if (apiName == 'Create_New_User__c') {
								bulkCSVObj.put(apiName, Boolean.ValueOf(fieldValue.trim()));
							} else {
								bulkCSVObj.put(apiName, fieldValue.trim());
							}
						}
					}
				}
				bulkCSVObj.CSV_Id__c = csvId; // unique identifier for a CSV
				lstCSVRecords.add(bulkCSVObj);
			}
		}
		if (lstCSVRecords.size() > 0) {
			// Remove duplicate records
			newUserSet.clear();
			updateUserSet.clear();
			for (Bulk_User_CSV_Data__c obj : lstCSVRecords) {
				if (obj.Create_New_User__c) {
					// Check for duplicate based on name (for new user)
					if (!newUserSet.contains(obj.Email__c)) {
						lstCSVRecordsFinal.add(obj);
						newUserSet.add(obj.Email__c);
					}
				} else {
					// Check for duplicate for update User based on email
					if (!updateUserSet.contains(obj.Email__c)) {
						lstCSVRecordsFinal.add(obj);
						updateUserSet.add(obj.Email__c);
					}
				}
			}
			if (lstCSVRecordsFinal.size() > 0) {
				readSuccess = true;
			} else {
				readSuccess = false;
				message = 'CSV cannot be recognized. Please upload correct CSV';
				displayErrorMessage(message);
			}
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
		Boolean isValidData = validateData(lstCSVRecordsFinal);
		if (!isValidData) {
			return null;
		}
		Savepoint sp = Database.setSavepoint();
		Database.SaveResult[] saveResult = Database.insert(lstCSVRecordsFinal, false);
		// Iterate through each returned result
		for (Database.SaveResult sr : saveResult) {
			if (sr.isSuccess()) {
				PageReference statusPage = new PageReference('/apex/BulkUserUploadStatus?csvid=' + lstCSVRecordsFinal[0].CSV_Id__c);
				statusPage.setRedirect(true);
				return statusPage;
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

	public set<string> getCSVObjectFields() {
		Set<string> fieldsSet = new Set<string>();
		Schema.DescribeSObjectResult a_desc = Bulk_User_CSV_Data__c.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> a_fields = a_desc.fields.getMap();
		for (Schema.sObjectField fld : a_fields.values()) {
			fieldsSet.add(String.valueOf(fld));
		}
		return fieldsSet;
	}

	public boolean validateData(List<Bulk_User_CSV_Data__c> bulkUserCSVDataList) {
		integer i = 0;
		for (Bulk_User_CSV_Data__c obj : bulkUserCSVDataList) {
			try {
				i++;
				NoDataFoundException ex;
				if (String.isBlank(obj.Email__c)) {
					throwNoDataException('Email name cannot be null');
				} else {
					if (!validateEmail(String.ValueOf(obj.Email__c))) {
						throwNoDataException('Email not in correct format');
					}
				}
				// If Team or SubTeam is blank then Clone_from_user__c should be supplied
				if (String.isBlank(obj.Team__c) || String.isBlank(obj.Sub_Team__c)) {
					if (String.isBlank(obj.Clone_from_user__c)) {
						throwNoDataException('Clone from User cannot be blank when team/subteam are blank');
					} else {
						if (!validateEmail(String.ValueOf(obj.Clone_from_user__c))) {
							throwNoDataException('Email not in correct format');
						}
					}
				}

				// Added new validation for Team and Sub Team
				if (String.isBlank(obj.Clone_from_user__c)) {
					if (String.isBlank(obj.Team__c)) {
						throwNoDataException('Team cannot be blank when Clone from User is blank');
					}
					if (String.isBlank(obj.Sub_Team__c)) {
						throwNoDataException('Sub Team cannot be blank when Clone from User is blank');
					}
				}
			} catch (Exception e) {
				message = e.getMessage() + ' (at row no. ' + i + ')';
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

	public Boolean validateEmail(String email) {
		Boolean res = true;
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(email);
		if (!MyMatcher.matches()) {
			res = false;
		}
		return res;
	}

	public void throwNoDataException(string message) {
		NoDataFoundException ex = new NoDataFoundException();
		ex.setMessage(message);
		throw ex;
	}
}