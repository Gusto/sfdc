/**
 * @description  Retrieves Task/Event records related to a sObject, ordered by ActivityDate
 *               and filtered by RecordType Developer Names
 * @see OpportunityTaskControllerTest
 **/
public with sharing class OpportunityTaskController {
	/**
	 * @description                     Retrieves sObject Tasks/Events
	 * @param idRecord                  Record id to identify parent opportunity
	 * @param strTaskRecordTypeDevNames Task/Event record types to be queried (comma separated)
	 * @return                          `List<sObject>`
	 */
	@AuraEnabled(cacheable=true)
	public static List<sObject> getsObjectActivities(Id idRecord, String strTaskRecordTypeDevNames) {
		Set<String> set_TaskRecordTypeDevNames = new Set<String>((strTaskRecordTypeDevNames ?? '').split(','));
		Boolean blnIsOpportunity = String.valueOf(idRecord).startsWith(TaskUtil.OPPORTUNITY_PREFIX);
		Boolean blnIsTicket = String.valueOf(idRecord).startsWith(TaskUtil.TICKET_PREFIX);
		
		if (blnIsTicket) {
			return [
				SELECT Id, Subject, Description, ActivityDate, What.Name, RecordType.DeveloperName, Priority
				FROM Task
				WHERE WhatId IN (SELECT Opportunity__c FROM Ticket__c WHERE Id = :idRecord) AND RecordTypeId IN :RecordTypes.getRecordTypeIdSetFromDevNames('Task', set_TaskRecordTypeDevNames)
				ORDER BY ActivityDate DESC
			];
		} else if (blnIsOpportunity) {
			return [
				SELECT Id, Subject, Description, ActivityDate, ActivityDateTime, RecordType.DeveloperName, What.Name
				FROM Event
				WHERE WhatId IN (SELECT Id FROM Ticket__c WHERE Opportunity__c = :idRecord) AND RecordTypeId IN :RecordTypes.getRecordTypeIdSetFromDevNames('Event', set_TaskRecordTypeDevNames)
				ORDER BY ActivityDate DESC
			];
		} else {
			return new List<sObject>();
		}
	}
}