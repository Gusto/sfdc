public with sharing class TaxOpsTaskPageExtension {
	public transient Blob csvFileBody { get; set; }
	public Tax_Ops_Task__c taxOpsTaskRec { get; set; }
	public Attachment latestAttachment { get; set; }
	public string message { get; set; }
	public Boolean isUploadInprogress { get; set; }
	public string userFriendlyFeinStr { get; set; }
	public string userFriendlyAccNumStr { get; set; }
	public List<FieldSetWrapper> list_FieldSetWrapper { get; set; }
	public List<Tax_Ops_Task__c> list_TaxOpsTask { get; set; }
	Set<String> set_EditableFields = new Set<String>();
	static final String FIELD_SET_VOIDED_FIELDS = 'Voided_Fields';
	
	
	public TaxOpsTaskPageExtension(ApexPages.standardcontroller sc) {
		isUploadInprogress = false;
		taxOpsTaskRec = (Tax_Ops_Task__c) sc.getRecord();
		set_EditableFields = new Set<String>();
		Map<String, Schema.SObjectField> map_Fields = Utils.getSObjectDescribe('Tax_Ops_Task__c').fields.getMap();
		for(Schema.SObjectField objRef : map_Fields.values()) {
			Schema.DescribeFieldResult objFieldResult = objRef.getDescribe();
			if (objFieldResult.isUpdateable()) {
				set_EditableFields.add(objFieldResult.getname());
			}
		}

		//get all the fields from fieldset "Starting_Details_for_Quarter_End" of tax ops
		readFieldSet();

		getTaxOpsData();
	}

	public void readFieldSet() {
		list_TaxOpsTask = new List<Tax_Ops_Task__c>();
		String strQuery = 'SELECT ';
		Set<String> set_EditableFields = new Set<String>{
			'Total_Count_of_Returns__c',
			'Payment_estimate__c',
			'Tax_Code__c',
			'Form_Code__c',
			'Filing_Method__c',
			'Period_End__c'
		};
		list_FieldSetWrapper = new List<FieldSetWrapper>();
		for (
			Schema.FieldSetMember objFieldSetMember : SObjectType.Tax_Ops_Task__c.FieldSets.Starting_Details_for_Quarter_End.getFields()
		) {
			strQuery += objFieldSetMember.getFieldPath() + ', ';
			FieldSetWrapper objField = new FieldSetWrapper();
			objField.objFieldSet = objFieldSetMember;
			objField.blnEditable = false;
			if (set_EditableFields.contains(objFieldSetMember.getFieldPath())) {
				objField.blnEditable = true;
			}
			list_FieldSetWrapper.add(objField);
		}
		strQuery += ' Id FROM Tax_Ops_Task__c WHERE Id= \'' + taxOpsTaskRec.id + '\'';
		list_TaxOpsTask = Database.query(strQuery);
	}

	public class FieldSetWrapper {
		public Schema.FieldSetMember objFieldSet { get; set; }
		public boolean blnEditable { get; set; }
	}

	public void updateTaxOps() {
		try {
			if (list_TaxOpsTask?.size() > 0) {
				update list_TaxOpsTask;
			}
		} catch (Exception objEx) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objEx.getMessage()));
		}
	}

	public static List<Schema.FieldSetMember> readFieldSet(String strFieldSetName, String strObjectName)
	{
		Map<String, Schema.SObjectType> map_GlobalDescribe = Schema.getGlobalDescribe(); 
		Schema.SObjectType objSobjectType = map_GlobalDescribe.get(strObjectName);
		Schema.DescribeSObjectResult objDescribeResult = objSobjectType.getDescribe();
		Schema.FieldSet objFieldSet = objDescribeResult.FieldSets.getMap().get(strFieldSetName);
		return objFieldSet.getFields(); 
	}  

	public void setVoid() {
		try {
			List<Schema.FieldSetMember> list_FieldSetMembers =  readFieldSet(FIELD_SET_VOIDED_FIELDS,'Tax_Ops_Task__c');

			for(Schema.FieldSetMember objFieldSetMember : list_FieldSetMembers)
			{
				if (set_EditableFields.contains(objFieldSetMember.getFieldPath())) {
					String strFieldType = string.valueof(objFieldSetMember.getType());
					if (strFieldType == 'CURRENCY' || strFieldType == 'DOUBLE') {
						taxOpsTaskRec.put(objFieldSetMember.getFieldPath()+'',0);
					}

					if (strFieldType == 'STRING' || strFieldType == 'URL') {
						taxOpsTaskRec.put(objFieldSetMember.getFieldPath()+'','VOID');
					}
				}
			}
			update taxOpsTaskRec;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'Successfully updated'));
		} catch (Exception objEx) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objEx.getMessage()));
		}
	}

	public void getTaxOpsData() {
		latestAttachment = new Attachment();
		list<Attachment> tempList = [
			SELECT id, name
			FROM Attachment
			WHERE ParentId = :taxOpsTaskRec.id
			ORDER BY CreatedDate DESC
			LIMIT 1
		];
		if (tempList.size() > 0) {
			latestAttachment = tempList.get(0);
		}

		String queryStr = 'SELECT ';
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe()
			.get('Tax_Ops_Task__c')
			.getDescribe()
			.fields.getMap();

		for (String s : objectFields.keySet()) {
			if (s == 'Payment_estimate__c' || s == 'Total_Count_of_Returns__c')
				continue;

			queryStr += ' ' + s + ', ';
		}

		queryStr = queryStr.trim();

		if (queryStr.subString(queryStr.Length() - 1, queryStr.Length()) == ',') {
			queryStr = queryStr.subString(0, queryStr.Length() - 1);
		}

		queryStr += ' from Tax_Ops_Task__c where id= \'' + taxOpsTaskRec.id + '\'';
		list<Tax_Ops_Task__c> tempTaskList = database.query(queryStr);
		if (tempTaskList.size() > 0) {
			taxOpsTaskRec = tempTaskList.get(0);
		}
	}

	public void saveRec() {
		try {
			message = '0';

			/*By: PR, Date:7/10/19, Desc: Skip_Save__c flag is set to true if user uploads a .CSV file
                                            This the flag is true we only want to set the flag as false and not save any other date from page 
                                            as it can be invalid because of backhand activity*/

			list<Tax_Ops_Task__c> lst_tempData = [
				SELECT Id, Skip_Save__c, CSV_File_Processing__c
				FROM Tax_Ops_Task__c
				WHERE id = :taxOpsTaskRec.id
			];

			if (lst_tempData.size() > 0 && lst_tempData.get(0).Skip_Save__c == true) {
				if (lst_tempData.get(0).CSV_File_Processing__c == false) {
					Tax_Ops_Task__c tempTaskObj = new Tax_Ops_Task__c(id = taxOpsTaskRec.id);
					tempTaskObj.Skip_Save__c = false;
					update tempTaskObj;
				}
			} else {
				update taxOpsTaskRec;
				getTaxOpsData();
			}
		} catch (exception ex) {
			apexPages.addMessage(
				new apexPages.Message(
					apexPages.severity.error,
					'Unexpected error occured while saving the record, please contact system admin.' +
					ex.getMessage()
				)
			);
			message = 'error';
		}
	}

	public void updateTaskStatus() {
		if (taxOpsTaskRec.id != null) {
			if (
				taxOpsTaskRec.Status__c != null &&
				(taxOpsTaskRec.Status__c.equalsIgnoreCase('Open') ||
				taxOpsTaskRec.Status__c.equalsIgnoreCase('New'))
			) {
				taxOpsTaskRec.Status__c = 'In Progress';

				try {
					update taxOpsTaskRec;
				} catch (exception ex) {
					apexPages.addMessage(
						new apexPages.Message(
							apexPages.severity.error,
							'Unexpected error occured, please contact system admin.' + ex.getMessage()
						)
					);
				}
			}
		}
	}

	public pageReference moveToInprogress() {
		if (taxOpsTaskRec.Status__c != null && taxOpsTaskRec.Status__c != 'In Progress') {
			taxOpsTaskRec.Status__c = 'In Progress';
			try {
				update taxOpsTaskRec;
				apexPages.addMessage(
					new apexPages.Message(ApexPages.Severity.INFO, 'Tax Ops Task record is successfully updated')
				);
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		PageReference pgref = ApexPages.currentPage();
		return pgref;
	}

	public pageReference moveToOpen() {
		if (taxOpsTaskRec.Status__c != null && taxOpsTaskRec.Status__c != 'Open') {
			taxOpsTaskRec.Status__c = 'Open';
			try {
				update taxOpsTaskRec;
				apexPages.addMessage(
					new apexPages.Message(ApexPages.Severity.INFO, 'Tax Ops Task record is successfully updated')
				);
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		PageReference pgref = ApexPages.currentPage();
		return pgref;
	}

	public void checkUploadInprogress() {
		for (Tax_Ops_Task__c tOpsTask : [
			SELECT Id, Skip_Save__c, CSV_File_Processing__c
			FROM Tax_Ops_Task__c
			WHERE id = :taxOpsTaskRec.id
		]) {
			isUploadInprogress = tOpsTask.CSV_File_Processing__c;
		}
	}

	public void uploadFailedRecCsv() {
		if (csvFileBody != null) {
			csvParser parser = new csvParser();
			parser.csvFileBody = csvFileBody;
			parser.parentId = taxOpsTaskRec.id;
			if (taxOpsTaskRec.Process_Step__c.contains('Filing')) {
				parser.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Filing');
			} else if (taxOpsTaskRec.Process_Step__c.equalsIgnoreCase('payments')) {
				parser.recordTypeId = cache.getRecordTypeId('Tax_Ops_Failed_Record__c', 'Failed Payment');
			}
			try {
				parser.importCSVFile();
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getmessage()));
			}
		}
	}
}