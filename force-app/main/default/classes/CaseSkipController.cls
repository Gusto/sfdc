/*
 * Description: Contains methods related skipping a case record (Creating new case skip history records)
 * Author: Praveeen Sethu
 * Date: 09/16/2020
 */

public with sharing class CaseSkipController {
	/* Wrapper class to share data between Apex and LWC */
	public class CaseSkipWrapper {
		@AuraEnabled
		public List<User_Preference__c> list_userPreference;

		@AuraEnabled
		public Case objCase;

		public CaseSkipWrapper(List<User_Preference__c> list_userPreference, Case objCase) {
			this.list_userPreference = list_userPreference;
			this.objCase = objCase;
		}
	}

	/* Creates a new Case Skip History records */
	@AuraEnabled
	public static Case skipCaseRecord(Id idCase, String strSkipComment) {
		// Initialize new Case Skip History Record
		Case_Skip_History__c objSkipRecord = new Case_Skip_History__c();
		try {
			objSkipRecord.Case__c = idCase;
			objSkipRecord.User__c = UserInfo.getUserId();
			objSkipRecord.Skip_Comment__c = strSkipComment;
			// Insert Case Skip History Record
			insert objSkipRecord;
			// Update Case  to Run Assignment Rules
			Case objCaseRec = [SELECT Id, Recent_Queue_Id__c FROM Case WHERE Id = :idCase];

			if (String.isNotBlank(objCaseRec.Recent_Queue_Id__c) && objCaseRec.Recent_Queue_Id__c instanceof Id) {
				CaseTriggerHelper.skipTrigger = true;
				objCaseRec.OwnerId = objCaseRec.Recent_Queue_Id__c;
				update objCaseRec;
			} else {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				Database.update(objCaseRec, dmo);
			}

			return [SELECT Id, Owner.Name FROM Case WHERE Id = :objCaseRec.Id];
		} catch (Exception objException) {
			ExceptionLogUtil.logException('EngagementCaseViewExtension_LEX', 'acceptCase', objException.getMessage(), objException.getStackTraceString());
			return null;
		}
	}

	/* Returns User Preference Record */
	@AuraEnabled
	public static CaseSkipWrapper getUserPreference(Id idCase) {
		Case objCase = [SELECT Id, OwnerId FROM Case WHERE Id = :idCase];
		List<User_Preference__c> list_userPreference = [SELECT Id, Case_Play_Selected_Cases__c FROM User_Preference__c WHERE User__c = :UserInfo.getUserId()];

		return new CaseSkipWrapper(list_userPreference, objCase);
	}
}