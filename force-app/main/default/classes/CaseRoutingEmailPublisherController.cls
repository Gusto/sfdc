public with sharing class CaseRoutingEmailPublisherController {
	/**
	 * Author: Pradeep
	 * Date: 1/21/2021
	 * Desc: get a case's Routing Case Reason's fields, send data to caseRoutingEmailPublisherCmp
	 */
	@AuraEnabled
	public static Map<String, String> getCaseInformation(String idCaseRecord) {
		Map<String, String> map_Resp = new Map<String, String>();
		try {
			Case objCase = new Case();
			objCase = [
				SELECT
					Id,
					Routing_Case_Reason_Classification__c,
					Routing_Case_Reason_Classification__r.Auto_Email_Behavior__c,
					Routing_Case_Reason_Classification__r.Email_Content__c,
					Routing_Case_Reason_Classification__r.Name
				FROM Case
				WHERE Id = :idCaseRecord
			];
			map_Resp.put('EmailBehaviour', objCase.Routing_Case_Reason_Classification__r.Auto_Email_Behavior__c);
			map_Resp.put('EmailContent', objCase.Routing_Case_Reason_Classification__r.Email_Content__c);
			map_Resp.put('RoutingCaseReason', objCase.Routing_Case_Reason_Classification__c);
			map_Resp.put('Name', objCase.Routing_Case_Reason_Classification__r.Name);
			//map_Resp.put('objCase', objCase);
			return map_Resp;
		} catch (Exception e) {
			if (!Test.isRunningTest()) {
				throw new AuraHandledException(e.getMessage());
			} else {
				return new Map<String, String>();
			}
		}
	}

	/**
	 * Author: Pradeep
	 * Date: 1/21/2021
	 * Desc: get case reason classifications that have Auto Email Behavior
	 */
	@AuraEnabled
	public static Map<String, Map<Id, Case_Reason_Classification__c>> queryReasons() {
		Map<String, Map<Id, Case_Reason_Classification__c>> map_caseReasonToGroupMap = new Map<String, Map<Id, Case_Reason_Classification__c>>();
		List<Case_Reason_Classification__c> list_caseReasonClassifications = new List<Case_Reason_Classification__c>();

		try {
			list_caseReasonClassifications = [
				SELECT Id, Name, Class__c, Type__c, Email_Content__c, Auto_Email_Behavior__c
				FROM Case_Reason_Classification__c
				WHERE Active__c = TRUE AND Generic_Routing_Reason__c = FALSE AND Type__c != 'Generic Routing' AND Auto_Email_Behavior__c != NULL
			];
			// Arrange in such a way that all generic routing cases appear first, followed by reasons related to case record type
			// Iterate over list of case reason classification
			// Create a map of type and list of case reason classsification
			for (Case_Reason_Classification__c objCrc : list_caseReasonClassifications) {
				if (map_caseReasonToGroupMap.containsKey(objCrc.Type__c)) {
					Map<Id, Case_Reason_Classification__c> map_IdToCaseReasonClassification = map_caseReasonToGroupMap.get(objCrc.Type__c);
					map_IdToCaseReasonClassification.put(objCrc.Id, objCrc);
					map_caseReasonToGroupMap.put(objCrc.Type__c, map_IdToCaseReasonClassification);
				} else {
					map_caseReasonToGroupMap.put(objCrc.Type__c, new Map<Id, Case_Reason_Classification__c>{ objCrc.Id => objCrc });
				}
			}

			return map_caseReasonToGroupMap;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}