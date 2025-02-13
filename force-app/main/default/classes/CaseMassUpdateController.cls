public with sharing class CaseMassUpdateController {
	public case toUpdateCase { get; set; }
	public boolean isRecordSelected { get; set; }
	public boolean massUpdateSuccessful { get; set; }
	public boolean recordTypeSupported { get; set; }
	public list<SelectOption> recordTypeOptionList { get; set; }
	public string selectedRecordType { get; set; }
	public list<Schema.FieldSetMember> fieldsApiNameList { get; set; }

	public list<case> selectedCaseList = new List<Case>();
	map<string, string> recordTypeNameFieldSetNameMap = new Map<string, string>();
	public map<string, id> recordTypeNameIdMap = new Map<string, id>();

	public CaseMassUpdateController(apexPages.standardsetcontroller setCon) {
		isRecordSelected = true;
		massUpdateSuccessful = false;
		toUpdateCase = new case();
		recordTypeSupported = false;
		recordTypeOptionList = new List<SelectOption>();

		if (setCon.getSelected().size() == 0) {
			isRecordSelected = false;
		} else {
			selectedCaseList = setCon.getSelected();

			toUpdateCase.RecordTypeId = selectedCaseList.get(selectedCaseList.size() - 1).RecordTypeId;
			selectedRecordType = [SELECT id, Name FROM RecordType WHERE id = :toUpdateCase.RecordTypeId].get(0).Name;

			for (Case_RecordType_FieldSet_Setting__c rec : [SELECT id, Name, Field_Set_API_Name__c FROM Case_RecordType_FieldSet_Setting__c]) {
				recordTypeNameFieldSetNameMap.put(rec.Name, rec.Field_Set_API_Name__c);
				recordTypeOptionList.add(new SelectOption(rec.Name, rec.Name));

				if (selectedRecordType.equalsIgnoreCase(rec.Name)) {
					recordTypeSupported = true;
				}
			}

			if (recordTypeSupported) {
				populateRecordTypeNameAndIdMap(); //populating map in case we are going forward with the funcitonality
				populateFieldNameList(); //populating fields name list based on recordtype
			}
		}
	}

	public void populateRecordTypeNameAndIdMap() {
		if (recordTypeNameFieldSetNameMap != null && recordTypeNameFieldSetNameMap.keyset().size() > 0) {
			for (RecordType rec : [SELECT id, Name FROM RecordType WHERE Name IN :recordTypeNameFieldSetNameMap.keyset() AND SobjectType = 'Case']) {
				recordTypeNameIdMap.put(rec.Name, Rec.id);
			}
		}
	}

	//populating the field api name list we are using to show fields on page
	public void populateFieldNameList() {
		fieldsApiNameList = new List<Schema.FieldSetMember>();

		if (recordTypeNameFieldSetNameMap != null && recordTypeNameFieldSetNameMap.keyset().size() > 0 && !string.isblank(selectedRecordType)) {
			string fieldSetName = recordTypeNameFieldSetNameMap.get(selectedRecordType);
			fieldsApiNameList.addAll(getFields(fieldSetName, 'Case'));

			//we are pupulating fields with null value as to stop displaying them prepopulated
			for (Schema.FieldSetMember f : fieldsApiNameList) {
				if (f.getType() == Schema.DisplayType.Boolean) {
					toUpdateCase.put(f.getFieldPath(), null);
				} else {
					toUpdateCase.put(f.getFieldPath(), '');
				}
			}
		}
		toUpdateCase.RecordTypeId = recordTypeNameIdMap.get(selectedRecordType);
	}

	//return fields of the fieldSet whose name we have passed as a parameter
	public static List<Schema.FieldSetMember> getFields(String fieldSetName, String ObjectName) {
		Schema.DescribeSObjectResult DescribeSObjectResultObj = Utils.getSObjectDescribe(ObjectName);
		Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
		return fieldSetObj.getFields();
	}

	//return routing and confirm case reasons
	public list<string> getCaseReasons() {
		list<string> caseReasons = new List<string>();

		if (toUpdateCase.Type != null) {
			caseReasons = new List<String>();
			for (Case_Reason_Classification__c crc : [SELECT Id, Name, Class__c FROM Case_Reason_Classification__c WHERE type__c = :selectedRecordType AND Active__c = TRUE]) {
				caseReasons.add(crc.Name);
			}
		}
		return caseReasons;
	}

	//get lsi option list
	public list<string> getlsiList() {
		list<string> lsiList = new List<string>();
		for (Large_Scale_Issue__c lsi : [SELECT Id, Name FROM Large_Scale_Issue__c]) {
			lsiList.add(lsi.Name);
		}
		return lsiList;
	}

	boolean isRoute = false;

	public void massUpdateAndRoute() {
		isRoute = true;
		massUpdate();
	}

	public void massUpdate() {
		list<Case> toMassUpdateCaseList = new List<Case>();

		toUpdateCase.recordTypeId = recordTypeNameIdMap.get(selectedRecordType);

		for (case rec : selectedCaseList) {
			Case tempCaseRec = new case(id = rec.id, recordTypeId = recordTypeNameIdMap.get(selectedRecordType));

			for (Schema.FieldSetMember f : fieldsApiNameList) {
				if (toUpdateCase.get(f.getFieldPath()) != null && toUpdateCase.get(f.getFieldPath()) != '' && string.valueof(toUpdateCase.get(f.getFieldPath())).length() > 0) {
					tempCaseRec.put(f.getFieldPath(), toUpdateCase.get(f.getFieldPath()));
				}
			}

			if (isRoute) {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				tempCaseRec.setOptions(dmo);
			}

			toMassUpdateCaseList.add(tempCaseRec);
		}

		if (toMassUpdateCaseList.size() > 0) {
			try {
				update toMassUpdateCaseList;
				massUpdateSuccessful = true;
				isRoute = false;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
			}
		}
	}
}