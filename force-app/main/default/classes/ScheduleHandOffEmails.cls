/*
 * Purpose:- Send the email to the customers where Send Hand Off Field is False in the case Object.
 * TestClass:- ScheduleHandOffEmailsTest
 * */
global class ScheduleHandOffEmails implements Schedulable {
	global void execute(SchedulableContext SC) {
		// Set to get the Opportunity Id of the Case which Send Hand off email is False
		Set<Id> oppIdSet = new Set<Id>();
		//Map is used for which contact email should be send
		Map<Id, Contact> conMap = new Map<Id, Contact>();
		//Map is used for which Opportunity email should be send
		Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
		//Map contains the count of the Policy related to each opportunity.
		Map<Id, Integer> mapCountPolicyOnOpportunity = new Map<Id, Integer>();
		//map used to get all the Cases without checking the count of the policy
		Map<Id, Case> map_Case = new Map<Id, Case>();
		//Contain the list of cases which have the opportunity with any policy.
		List<Case> caseEmailNotificationList = new List<Case>();
		//Create Map of Opp and ContactRole Email
		Map<Id, Set<String>> map_OppContactRoleEmails = new Map<Id, Set<String>>();
		//Fetching the cases where Send Hand off email is false
		for (Case objCase : [
			SELECT
				Id,
				Status,
				ownerId,
				Owner.Email,
				Origin,
				owner.firstname,
				Opportunity__c,
				Benefit_Order__c,
				Benefit_Order__r.RecordTypeId,
				Send_Handoff_Email__c,
				ContactId,
				Benefit_Order__r.Parent_Benefit_Order__c,
				RecordTypeId
			FROM Case
			WHERE
				Opportunity__c != NULL
				AND Send_Handoff_Email__c = FALSE
				AND Type NOT IN ('Benefits Renewal alignment', 'Carrier Submission')
				AND recordType.Name IN ('Benefits New Plan Case', 'Benefits Renewal Case')
				AND IsClosed = FALSE
				AND Origin = 'Hippo'
				AND Carrier_Order__c = NULL
				AND Benefit_Order__c != NULL
				AND Benefit_Order__r.Parent_Benefit_Order__c = NULL
				AND Benefit_Order__r.RecordTypeId != :Cache.getRecordTypeId('Benefit_Order__c', 'Change')
				AND Benefit_Order__r.CreatedDate >= YESTERDAY
		]) {
			// Check for the Owner id Should only be start with 005(user)
			if (string.valueOf(objCase.OwnerId).startsWith('005')) {
				if (objCase.Opportunity__c != null) {
					oppIdSet.add(objCase.Opportunity__c);
				}
				map_Case.put(objCase.Opportunity__c, objCase);
			}
		}
		// if opportunity exists, getting the list of Policy's count, NP_Complexity_scoring object for the Contact information
		if (!oppIdSet.isEmpty()) {
			for (Opportunity opp : [
				SELECT
					id,
					OwnerId,
					owner.Email,
					owner.name,
					owner.firstname,
					owner.lastname,
					(
						SELECT id, Owner.Email, owner.firstname
						FROM Cases__r
						WHERE
							opportunity__c != NULL
							AND Send_Handoff_Email__c = FALSE
							AND Type NOT IN ('Benefits Renewal alignment', 'Carrier Submission')
							AND recordType.Name IN ('Benefits New Plan Case', 'Benefits Renewal Case', 'Benefits Change Case')
							AND IsClosed = FALSE
							AND Origin = 'Hippo'
							AND Carrier_Order__c = NULL
							AND Benefit_Order__c != NULL
					),
					(SELECT Id, Opportunity__c, Contact__r.Owner.Email, Contact__c, Contact__r.Email FROM NP_Complexity_Scorings__r),
					(SELECT Id FROM Policies__r WHERE Is_Selected__c = TRUE)
				FROM Opportunity
				WHERE Id IN :oppIdSet
			]) {
				//If any policy exist related to the Opportunity.
				if (opp.Policies__r.size() > 0) {
					for (Transition_to_Fulfillment__c ttfRecs : opp.NP_Complexity_Scorings__r) {
						conMap.put(ttfRecs.Contact__c, ttfRecs.Contact__r);
					}
					oppMap.put(opp.Id, opp);
					mapCountPolicyOnOpportunity.put(opp.Id, opp.Policies__r.size());
					if (map_Case.containsKey(opp.Id)) {
						//Case to update the sendHandoffEmail
						Case objCaseToUpdate = map_Case.get(opp.Id);
						objCaseToUpdate.Send_Handoff_Email__c = true;
						caseEmailNotificationList.add(objCaseToUpdate);
					}
				}
			}

			for (OpportunityContactRole objOppRole : [
				SELECT Id, OpportunityId, Contact.Email, Check_Additional_POC__c
				FROM OpportunityContactRole
				WHERE OpportunityId IN :oppIdSet AND Check_Additional_POC__c = TRUE AND ContactId != NULL AND Contact.Email != NULL
			]) {
				Set<String> set_Emails = new Set<String>();
				if (map_OppContactRoleEmails.containsKey(objOppRole.OpportunityId)) {
					set_Emails = map_OppContactRoleEmails.get(objOppRole.OpportunityId);
				}

				set_Emails.add(objOppRole.Contact.Email);
				map_OppContactRoleEmails.put(objOppRole.OpportunityId, set_Emails);
			}

			//Method which will send the email
			String strErrorIfExist = BenefitOrderHelper.sendEmailOnCaseCreation(caseEmailNotificationList, oppMap, conMap, mapCountPolicyOnOpportunity, map_OppContactRoleEmails);
			// SJay - 5-20-2020 - Commented out error handling as this is resulting in sending emails multiple even if there is no error found.
			//if(String.isBlank(strErrorIfExist)){
			if (caseEmailNotificationList.size() > 0) {
				//Skipping the triggers
				CaseTriggerHelper.skipTrigger = true;
				//Update Cases List
				update caseEmailNotificationList;
				CaseTriggerHelper.skipTrigger = false;
			}
			//}
		}
	}
}