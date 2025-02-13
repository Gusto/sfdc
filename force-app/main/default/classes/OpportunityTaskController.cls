/**
 * @description  Retrieves Task records related to an opportunity, ordered by ActivityDate
 *               and filtered by RecordType Developer Names
 * @see OpportunityTaskControllerTest
 **/
public with sharing class OpportunityTaskController {
	/**
	 * @description                     Retrieves parent opportunities Tasks
	 * @param idTicket                  Ticket id to identify parent opportunity
	 * @param strTaskRecordTypeDevNames Task record types to be queried (comma separated)
	 * @return                          `List<Task>`
	 */
	@AuraEnabled(cacheable=true)
	public static List<Task> getOpportunityTasks(Id idTicket, String strTaskRecordTypeDevNames) {
		Set<String> set_TaskRecordTypeDevNames = new Set<String>((strTaskRecordTypeDevNames ?? '').split(','));
		return [
			SELECT Id, Subject, Description, ActivityDate, What.Name, RecordType.DeveloperName, Priority
			FROM Task
			WHERE WhatId IN (SELECT Opportunity__c FROM Ticket__c WHERE Id = :idTicket) AND RecordTypeId IN :RecordTypes.getRecordTypeIdSetFromDevNames('Task', set_TaskRecordTypeDevNames)
			ORDER BY ActivityDate DESC
		];
	}
}