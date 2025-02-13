public with sharing class UR_ResearchUploadInfoTriggerHelper {
	public static Boolean skipTrigger = false;

	public void OnBeforeInsert(List<Research_Upload_Info__c> list_ResearchUploadInfos) {
		researchUploadMethod(list_ResearchUploadInfos);
	}

	public void OnAfterInsert(Map<ID, Research_Upload_Info__c> map_ResearchUploadInfos) {
	}

	public void OnBeforeUpdate(Map<ID, Research_Upload_Info__c> map_OldResearchUploadInfos, Map<ID, Research_Upload_Info__c> map_NewResearchUploadInfos) {
		researchUploadMethod(map_NewResearchUploadInfos.values());
	}

	public void OnAfterUpdate(Map<ID, Research_Upload_Info__c> map_OldResearchUploadInfos, Map<ID, Research_Upload_Info__c> map_NewResearchUploadInfos) {
	}

	public void OnBeforeDelete(List<Research_Upload_Info__c> list_ResearchUploadInfos, Map<ID, Research_Upload_Info__c> map_OldResearchUploadInfos) {
	}

	public void OnAfterDelete(List<Research_Upload_Info__c> list_ResearchUploadInfos, Map<ID, Research_Upload_Info__c> map_OldResearchUploadInfos) {
	}

	public void OnUndelete(List<Research_Upload_Info__c> list_ResearchUploadInfos) {
	}

	//This method updated uploaded CSV record is Blacklist, Opt Out or blank
	public void researchUploadMethod(List<Research_Upload_Info__c> list_ResearchUploadInfos) {
		//Get User id and Email in Collection
		Set<String> set_EmailUserIds = new Set<String>();
		for (Research_Upload_Info__c objRUI : list_ResearchUploadInfos) {
			if (String.isNotBlank(objRUI.Email__c)) {
				set_EmailUserIds.add(objRUI.Email__c);
			}
		}

		//Retrive contact based on user id and email
		Map<String, Contact> map_EmailWithContacts = new Map<String, Contact>();
		if (set_EmailUserIds.size() > 0) {
			for (Contact objContact : [
				SELECT Id, UXResearch_Opt_Out__c, UXResearch_Blacklist__c, Email, ZP_User_Id__c, HasOptedOutOfEmail, Salesloft_Email_Opt_Out__c
				FROM Contact
				WHERE Email IN :set_EmailUserIds
			]) {
				map_EmailWithContacts.put(objContact.Email, objContact);
			}
		}
		if (map_EmailWithContacts != null && map_EmailWithContacts.size() > 0) {
			for (Research_Upload_Info__c objRUI : list_ResearchUploadInfos) {
				//get Contact based on email id
				Contact objContact = map_EmailWithContacts.get(objRUI.Email__c);
				if (objContact != null) {
					objRUI.Blacklist__c = objContact.UXResearch_Blacklist__c;

					String strOptOutReason = '';
					if (objContact.UXResearch_Opt_Out__c) {
						objRUI.Opt_Out__c = true;
						strOptOutReason = strOptOutReason + 'UXR Scout Opt Out & ';
					}
					if (objContact.HasOptedOutOfEmail) {
						objRUI.Opt_Out__c = true;
						strOptOutReason = strOptOutReason + 'Email Opt Out & ';
					}
					if (objContact.Salesloft_Email_Opt_Out__c) {
						objRUI.Opt_Out__c = true;
						strOptOutReason = strOptOutReason + 'Email Opt Out - Salesloft & ';
					}
					if (String.isNotBlank(strOptOutReason)) {
						strOptOutReason = strOptOutReason.trim();
						strOptOutReason = strOptOutReason.removeEnd('&');
					}

					objRUI.Opt_Out_Reason__c = strOptOutReason;
				}
			}
		}
	}
}