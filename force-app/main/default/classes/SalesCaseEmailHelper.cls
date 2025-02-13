/**
 * @author Lalitha kasturi
 * @date June 29, 2022
 * @description  This class handles the case creation on input task id from the flow
 */
global class SalesCaseEmailHelper {
	@InvocableMethod(description='This method handles the case creation on input task id')
	global static List<Results> createCaseForFollowUpEmail(List<Requests> requests) {
		String strTaskRecordId = requests[0].strTaskRecordInputId;
		if (String.isBlank(strTaskRecordId) || !strTaskRecordId?.startsWith('00T')) {
			return null;
		}

		Task objTaskRecord = [SELECT Id, Primary_Call_Reason__c, Secondary_Call_Reason__c, WhatId FROM Task WHERE Id = :strTaskRecordId AND WhatId != NULL AND What.Type = 'Opportunity' LIMIT 1];
		Id idOpp = objTaskRecord?.WhatId;

		Opportunity objOpp = [SELECT Id, AccountId, LeadName__c FROM Opportunity WHERE Id = :idOpp LIMIT 1];
		Id idAcc = objOpp.AccountId;
		Id idLead = objOpp.LeadName__c;

		OpportunityContactRole objOppConRole = [
			SELECT Id, OpportunityId, Opportunity.AccountId, Opportunity.LeadName__c, ContactId, IsPrimary
			FROM OpportunityContactRole
			WHERE OpportunityId = :objTaskRecord.WhatId
			LIMIT 1
		];
		Id idCon = objOppConRole.ContactId;
		idAcc = objOppConRole.Opportunity.AccountId;
		idLead = objOppConRole.Opportunity.LeadName__c;


		Case objCase = new Case();
		objCase.ContactId = idCon;
		objCase.AccountId = idAcc;
		objCase.RecordTypeId = CaseUtils.RECTYPE_SALES_CASES;
		objCase.Lead__c = idLead;
		objCase.Opportunity__c = objOpp.Id;
		objCase.Origin = CaseUtils.ORIGIN_EMAIL;
		objCase.Primary_Call_Reason__c = objTaskRecord.Primary_Call_Reason__c;
		objCase.Secondary_Call_Reason__c = objTaskRecord.Secondary_Call_Reason__c;

		try {
			insert objCase;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('SalesCaseEmailHelper', 'createCaseForFollowUpEmail', ex.getMessage(), ex.getStackTraceString() + '. line number: ' + ex.getLineNumber());
		}

		if (objCase != null) {
			//Below query is to pull more info of a case after the dml.
			Case objCaseInfo = [SELECT Id, CaseNumber FROM Case WHERE Id = :objCase.Id LIMIT 1];
			Task objTaskUpdate = new Task(Id = strTaskRecordId);
			objTaskUpdate.Case__c = objCase.Id;

			try {
				update objTaskUpdate;
			} catch (Exception ex) {
				ExceptionLogUtil.logException('SalesCaseEmailHelper', 'createCaseForFollowUpEmail', ex.getMessage(), ex.getStackTraceString() + '. line number: ' + ex.getLineNumber());
			}
		}
		Results objResults = new Results();
		objResults.strCaseId = objCase.Id;

		List<Results> list_Results = new List<Results>();
		list_Results.add(objResults);
		return list_Results;
	}

	global class Requests {
		@InvocableVariable
		global String strTaskRecordInputId;
	}

	global class Results {
		@InvocableVariable
		global String strCaseId;
	}
}