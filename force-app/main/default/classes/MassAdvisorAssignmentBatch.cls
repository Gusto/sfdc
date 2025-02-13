/**
 * @name         MassAdvisorAssignmentBatch
 * @author       Bhagat Singh
 * @date         26 June 2024
 * @description  Update Advisor Assignment field on selected opportunities.
 * @test class   MassAdvisorAssignmentCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
global without sharing class MassAdvisorAssignmentBatch implements Database.stateful, Database.Batchable<SObject> {
	public Set<Id> set_OppIds = new Set<Id>();
	public String strAdvisorAssignment = '';

	global Database.QueryLocator start(Database.BatchableContext bContext) {
		String strQuery = 'SELECT Id, RecordTypeId, Advisor_Assignment__c, Big_Desk_BenOps__c, Owner_Role_Name__c FROM Opportunity WHERE Id IN :set_OppIds';

		return Database.getQueryLocator(strQuery);
	}

	global void Execute(Database.BatchableContext bContext, List<Opportunity> list_Opps) {
		if (list_Opps?.size() > 0) {
			List<Opportunity> list_UpdatedOpp = new List<Opportunity>();
			for (Opportunity objOpp : list_Opps) {
				if (objOpp.Advisor_Assignment__c != strAdvisorAssignment) {
					objOpp.Advisor_Assignment__c = strAdvisorAssignment;
					list_UpdatedOpp.add(objOpp);
				}
			}

			if (list_UpdatedOpp?.size() > 0) {
				update list_UpdatedOpp;
			}
		}
	}

	global void finish(Database.BatchableContext bContext) {
	}
}