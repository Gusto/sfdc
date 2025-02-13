public without sharing class RecoveryCaseClassSettingUpdateController {
	public List<SettingWrapper> lst_wrapper { get; set; }

	public RecoveryCaseClassSettingUpdateController() {
		lst_wrapper = new List<SettingWrapper>();

		List<Recovery_Case_Class_Assignment_Setting__c> list_settingRecords = [
			SELECT id, name, Error_Code__c, Recovery_Amount_Starting_Limit__c, Recovery_Amount_End_Limit__c, Eligible_Class__c, Expedite_Reason__c, Task_Us__c
			FROM Recovery_Case_Class_Assignment_Setting__c
		];
		list_settingRecords.sort();

		for (Recovery_Case_Class_Assignment_Setting__c cSettObj : list_settingRecords) {
			SettingWrapper newRec = new SettingWrapper();
			newRec.cSettingid = cSettObj.id;
			newRec.Name = cSettObj.Name;
			newRec.errorCode = cSettObj.Error_Code__c;
			newRec.amtLowerLimit = cSettObj.Recovery_Amount_Starting_Limit__c;
			newRec.amtUpperLimit = cSettObj.Recovery_Amount_End_Limit__c;
			newRec.eClass = cSettObj.Eligible_Class__c;
			newRec.eReason = cSettObj.Expedite_Reason__c;
			newRec.isTaskUs = cSettObj.Task_Us__c;
			lst_wrapper.add(newRec);
		}
	}

	public PageReference saveCustomSetting() {
		List<Recovery_Case_Class_Assignment_Setting__c> list_toUpdateSettingRecords = new List<Recovery_Case_Class_Assignment_Setting__c>();

		try {
			for (SettingWrapper recCS : lst_wrapper) {
				Recovery_Case_Class_Assignment_Setting__c tempObj = new Recovery_Case_Class_Assignment_Setting__c(id = recCS.cSettingid);
				tempObj.Name = recCS.Name;
				tempObj.Error_Code__c = recCS.errorCode;
				tempObj.Recovery_Amount_Starting_Limit__c = recCS.amtLowerLimit;
				tempObj.Recovery_Amount_End_Limit__c = recCS.amtUpperLimit;
				tempObj.Eligible_Class__c = recCS.eClass;
				tempObj.Expedite_Reason__c = recCS.eReason;
				tempObj.Task_Us__c = recCS.isTaskUs;
				list_toUpdateSettingRecords.add(tempObj);
			}

			update list_toUpdateSettingRecords;
		} catch (exception ex) {
			ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.Error, ex.getMessage()));
			return null;
		}
		ApexPages.addMessage(new ApexPages.Message(apexPages.Severity.Info, 'Update successful.'));
		return null;
	}

	public pageReference closeCurrentPage() {
		string strRetURL = ApexPages.currentPage().getparameters().get('retURL');
		if (string.isNotBlank(strRetURL)) {
			return new PageReference(strRetURL);
		}

		return new PageReference('/home/home.jsp');
	}

	public class SettingWrapper {
		public string cSettingid { get; set; }
		public string name { get; set; }
		public string errorCode { get; set; }
		public decimal amtLowerLimit { get; set; }
		public decimal amtUpperLimit { get; set; }
		public string eClass { get; set; }
		public string eReason { get; set; }
		public boolean isTaskUs { get; set; }

		public SettingWrapper() {
		}
	}
}