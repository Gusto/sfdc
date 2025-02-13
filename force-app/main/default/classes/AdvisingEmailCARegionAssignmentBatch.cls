/*
    Component Name:AdvisingEmailCARegionAssignmentBatch.cls
    Date of Creation: Jan-18-2021
    Description: Code is used to upDate the Opportunity Region field in bulk. This class is executed from AdvisingEmailCARegionAssignmentCntrl
    Author: PR
*/
public with sharing class AdvisingEmailCARegionAssignmentBatch implements Database.Batchable<sObject>, Database.StateFul {
	String strQuery;
	public Integer intCAEastCount;
	public Integer intCAWestCount;
	public Integer intCACentralCount;
	public Boolean blnIsAssignment;
	public Boolean blnIsAssignmentRFDOnly;
	public Date dtSelectedMonthStartDate;
	public Date dtSelectedMonthEndDate;
	Set<String> set_ToExcludeOpportunityStageNames = new Set<String>{ OpportunityUtil.CLOSED_ADMIN_STAGE, OpportunityUtil.CLOSED_WON_STAGE, OpportunityUtil.CLOSED_LOST_STAGE };
	public Set<Id> set_OppIdsForUnassignment = new Set<Id>();
	public Integer intNumberOfRecordsProcessed;
	public final static String strRequireStageDetailLostMessage = 'Please select the Stage Detail as to why this Opportunity was lost.: [Stage_Detail__c]';

	//constructor
	public AdvisingEmailCARegionAssignmentBatch() {
		blnIsAssignment = false;
		blnIsAssignmentRFDOnly = false;
	}

	//start method
	public Database.QueryLocator start(Database.BatchableContext BC) {
		if (String.isBlank(strQuery)) {
			strQuery = getRelatedQuery();
		}
		return Database.getQueryLocator(strQuery);
	}

	//execute method
	public void execute(Database.BatchableContext BC, List<Opportunity> list_Opportunity) {
		if (list_Opportunity != null && list_Opportunity.size() > 0) {
			updateOpportunityRegion(list_Opportunity);
		}
	}

	//returns query
	public String getRelatedQuery() {
		Integer intTotalOppCount = (intCAEastCount == null ? 0 : intCAEastCount) + (intCAWestCount == null ? 0 : intCAWestCount) + (intCACentralCount == null ? 0 : intCACentralCount);

		strQuery = 'SELECT Id,Region__c FROM Opportunity ';
		if (blnIsAssignment) {
			strQuery +=
				' WHERE UW_State_PY__c = \'California\' AND Region__c = NULL AND ' +
				' HI_Effective_Date__c >=:dtSelectedMonthStartDate AND HI_Effective_Date__c <=:dtSelectedMonthEndDate ' +
				' AND RecordType.Name = \'Benefits Renewal\' ';

			if (blnIsAssignmentRFDOnly) {
				strQuery += ' AND StageName = ' + '\'' + AdvisingEmailCARegionAssignmentCtrl.OPP_StageName_ReadyForDefault + '\'';
			}
			strQuery += ' LIMIT ' + String.valueOf(intTotalOppCount);
		} else {
			//we need ideas to get the correct number of records and in correct ratio
			strQuery += ' WHERE  Id IN: set_OppIdsForUnassignment';
		}
		return strQuery;
	}

	//this method handles list of opportunity records. And we are using the code to update the Region field val on related Opportunity
	public void updateOpportunityRegion(List<Opportunity> list_Opportunity) {
		if (list_Opportunity != null && list_Opportunity.size() > 0) {
			if (blnIsAssignment) {
				for (Opportunity objOppRec : list_Opportunity) {
					if (intNumberOfRecordsProcessed < intCAEastCount) {
						objOppRec.Region__c = 'CA East';
						intNumberOfRecordsProcessed++;
					} else if (intNumberOfRecordsProcessed < (intCAEastCount + intCAWestCount)) {
						objOppRec.Region__c = 'CA West';
						intNumberOfRecordsProcessed++;
					} else if (intNumberOfRecordsProcessed < (intCAEastCount + intCAWestCount + intCACentralCount)) {
						objOppRec.Region__c = 'CA Central';
						intNumberOfRecordsProcessed++;
					}
				}
			} else {
				for (Opportunity objOppRec : list_Opportunity) {
					objOppRec.Region__c = '';
					intNumberOfRecordsProcessed++;
				}
			}

			try {
				OpportunityTriggerHelper.skipTrigger = true;
				update list_Opportunity;
			} catch (exception ex) {
				if (system.isBatch()) {
					if (ex.getMessage().contains(strRequireStageDetailLostMessage)){
						return;
					}
					ExceptionLogUtil.logException('AdvisingEmailCAregionAssingmentBatch', 'Opportunity updation.', 'Error while updating Opportunity object :- ' + ex.getMessage(), 'high');
				} else {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Error while updating opportunity records. ' + ex.getMessage()));
				}
				return;
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}