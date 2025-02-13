public with sharing class csvParser {
	public transient Blob csvFileBody { get; set; }
	public transient String csvAsString { get; set; }
	public string parentId { get; set; }
	public string recordTypeId { get; set; }
	List<List<String>> allData;
	transient List<List<Map<String, String>>> recordsJSON;
	Tax_Ops_Task__c taskRec = new Tax_Ops_Task__c();

	Map<string, string> labelApiMap;
	List<Tax_Ops_Tasks_Csv_Field_Mapping__c> configMap = Tax_Ops_Tasks_Csv_Field_Mapping__c.getAll().values();

	public csvParser() {
		labelApiMap = new Map<string, string>();
		for (Tax_Ops_Tasks_Csv_Field_Mapping__c rec : configMap) {
			labelApiMap.put(rec.Field_Label__c.tolowerCase(), rec.API_Name__c.tolowerCase());
		}
	}

	public void importCSVFile() {
		//PageReference detailPage;

		try {
			if (!Test.isRunningTest()) {
				csvAsString = csvFileBody.toString();
			} else {
				csvAsString = 'Amount_Held__c,Uploaded_to_Koala__c,FEIN__c,Amount_Held__c,Uploaded_to_Koala__c,FEIN__c,\r\n1,Free Corporate,Queue,1.2,leadsource,758373,,,,,,,,\r\n';
			}

			if (parentId != null) {
				taskRec = [SELECT id, Tax_Code__c, FEIN_Account_Number__c, Process_Step__c FROM Tax_Ops_Task__c WHERE id = :parentId];
			}

			List<List<String>> parsedCSV = new List<List<String>>();
			parsedCSV = parseCSV(csvAsString);

			if (parsedCSV != null && parsedCSV.size() > 0) {
				List<String> header = parsedCSV.get(0);
				parsedCSV.remove(0);
				createJSON(header, parsedCSV);

				insertTaxCsvRecords();
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('csvParser', 'importCSVFile', ex.getMessage(), ex.getStackTraceString());
		}
	}
	

	public void insertRecords() {
	}

	private List<List<String>> parseCSV(string contents) {
		try {
			String freshString = '';
			List<String> lines = new List<String>();
			lines.addAll(contents.split('\r\n'));
			callDataParsing(lines);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('csvParser', 'parseCSV', ex.getMessage(), ex.getStackTraceString());
		}

		return allData;
	}

	public void callDataParsing(List<string> lines) {
		allData = new List<List<String>>();

		for (String line : lines) {
			if (line.replaceAll(',', '').trim().length() == 0)
				break;

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

	public void createJSON(List<String> header, List<List<String>> records) {
		recordsJSON = new List<List<Map<String, String>>>();
		if (records != null && records.size() > 0) {
			for (integer i = 0; i < records.size(); i++) {
				List<Map<String, String>> recordMap = new List<Map<String, String>>();

				for (integer j = 0; j < records.get(i).size(); j++) {
					recordMap.add(new Map<String, String>{ header.get(j).toLowerCase().replaceAll('"', '') => records.get(i).get(j) });
				}

				recordsJSON.add(recordMap);
			}
		}
	}

	public void insertTaxCsvRecords() {
		if (recordsJSON != null && recordsJSON.size() > 0) {
			List<Tax_Ops_Tasks_Csv_Data__c> csvDataList = new List<Tax_Ops_Tasks_Csv_Data__c>();
			for (List<Map<String, String>> line : recordsJSON) {
				if (line != null && line.size() > 0) {
					Tax_Ops_Tasks_Csv_Data__c csvData = new Tax_Ops_Tasks_Csv_Data__c();

					for (Map<String, String> record : line) {
						if (record != null && record.keySet().size() > 0) {
							for (String label : record.keySet()) {
								string api = labelApiMap.get(label.trim());
								String value = record.containsKey(label) ? record.get(label).replaceAll('"', '') : '';
								if (String.isNotBlank(value)) {
									if (string.isNotBlank(api)) {
										csvData.put(api, value);
									}
								}
							}
						}
					}

					csvData.Tax_Ops_Task__c = parentId;
					csvData.Record_Type__c = recordTypeId;

					if (csvData.FEIN__c != null) {
						csvData.FEIN__c = replaceSpecialCharacters(csvData.FEIN__c);
					}

					if (csvData.Account_Number__c != null) {
						csvData.Account_Number__c = replaceSpecialCharacters(csvData.Account_Number__c);
					}

					csvDataList.add(csvData);
				}
			}

			try {
				if (csvDataList.size() > 0) {
					/*BY:PR, Date:7/16/19, Desc:Introduce Skip_save logic to handle delay during csv records creation*/
					TaxOpsTaskTriggerHelper.skipTrigger = true;
					Tax_Ops_Task__c tempTaxObj = new Tax_Ops_Task__c(id = parentId);
					tempTaxObj.Skip_Save__c = true;
					tempTaxObj.CSV_File_Processing__c = true;
					update tempTaxObj;
					TaxOpsTaskTriggerHelper.skipTrigger = false;

					insert csvDataList;

					if (!test.isRunningTest()) {
						TaxOpsTaskCSVDataProcessingBatch batchController = new TaxOpsTaskCSVDataProcessingBatch();
						batchController.taxOpsTaskId = parentId;
						database.executeBatch(batchController);
					}
				}
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.Error, ex.getMessage()));
				ExceptionLogUtil.logException('csvParser', 'insertTaxCsvRecords', ex.getMessage(), ex.getStackTraceString());
			}
			apexPages.addMessage(new apexPages.Message(apexPages.severity.Info, 'File processed successfully.'));
		}
	}

	//by:PR, Date: 7/10/19, Desc: below method is removing all the special characters.
	public String replaceSpecialCharacters(String val) {
		if (string.isNotBlank(val)) {
			String res = val.replaceAll('[^a-zA-Z0-9]', '');
			return res;
		}
		return val;
	}
}