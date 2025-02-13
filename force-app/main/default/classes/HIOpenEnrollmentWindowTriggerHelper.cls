/*
 *   By : Akash Sharma
 *   Created Date : March 7, 2019
 *
 */

public with sharing class HIOpenEnrollmentWindowTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	public static boolean queue = false;

	public void OnBeforeInsert(List<HI_Open_Enrollment_Window__c> openEnrollmentWindowList) {
		counter++;
		if (queue == true) {
			processInformation(openEnrollmentWindowList);
		} else {
			for (HI_Open_Enrollment_Window__c state : openEnrollmentWindowList) {
				state.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, HI_Open_Enrollment_Window__c> openEnrollmentWindowMap) {
		if (queue == false) {
			HIOpenEnrollmentWindowQueue updateJob = new HIOpenEnrollmentWindowQueue(openEnrollmentWindowMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedopenEnrollmentWindowIDs) {
	}

	public void OnBeforeUpdate(Map<ID, HI_Open_Enrollment_Window__c> oldopenEnrollmentWindowMap, Map<ID, HI_Open_Enrollment_Window__c> newOpenEnrollmentWindowMap) {
		counter++;
		if (queue == true) {
			processInformation(newOpenEnrollmentWindowMap.values());
		} else {
			for (HI_Open_Enrollment_Window__c enrollRec : newOpenEnrollmentWindowMap.values()) {
				HI_Open_Enrollment_Window__c oldRewObj = oldopenEnrollmentWindowMap.get(enrollRec.Id);
				enrollRec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HI_Open_Enrollment_Window__c> oldopenEnrollmentWindowMap, Map<ID, HI_Open_Enrollment_Window__c> newOpenEnrollmentWindowMap) {
		if (queue == false) {
			HIOpenEnrollmentWindowQueue updateJob = new HIOpenEnrollmentWindowQueue(newOpenEnrollmentWindowMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedCompantIDs) {
	}

	public void OnBeforeDelete(HI_Open_Enrollment_Window__c[] openEnrollmentWindowToDelete, Map<ID, HI_Open_Enrollment_Window__c> oldOpenEnrollmentWindowMap) {
		counter++;
	}

	public void OnAfterDelete(HI_Open_Enrollment_Window__c[] deletedOpenEnrollmentWindow, Map<ID, HI_Open_Enrollment_Window__c> oldOpenEnrollmentWindowMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedCompanyIDs) {
	}

	public void OnUndelete(HI_Open_Enrollment_Window__c[] restoredOpenEnrollmentWindow) {
		counter++;
	}

	private void processInformation(List<HI_Open_Enrollment_Window__c> openEnrollmentWindowList) {
		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();
		List<Benefit_Order__c> boToUpdate = new List<Benefit_Order__c>();
		Set<String> companyIdSet = new Set<String>();
		Map<String, HI_Open_Enrollment_Window__c> enrollmentFulFillmentIdMap = new Map<String, HI_Open_Enrollment_Window__c>();
		Map<String, String> fulFillmentRecMap;

		for (HI_Open_Enrollment_Window__c openEnrollRec : openEnrollmentWindowList) {
			if (openEnrollRec.Company_Id__c != null) {
				companyIdSet.add(string.valueof(openEnrollRec.Company_Id__c));
				enrollmentFulFillmentIdMap.put(openEnrollRec.Fulfillment_Id__c, openEnrollRec);
			}
		}

		//Fetching the Hi_Fulfillment records based on the FulfillmentIds on HI_Open_Enrollment_Window__c
		if (enrollmentFulFillmentIdMap != null && enrollmentFulFillmentIdMap.keySet().size() > 0) {
			fulFillmentRecMap = new Map<String, String>();
			for (HI_Fulfillment__c fulfillmentRec : [
				SELECT Id__c, Fulfillable_Id__c, Fulfillable_Type__c
				FROM HI_Fulfillment__c
				WHERE Id__c IN :enrollmentFulFillmentIdMap.keySet() AND Created_At__c != NULL
			]) {
				if (fulfillmentRec.Fulfillable_Type__c == 'NewPlansApplication') {
					fulFillmentRecMap.put('hawaiian_ice-new_plans_application-' + fulfillmentRec.Fulfillable_Id__c, fulfillmentRec.Id__c);
				} else if (fulfillmentRec.Fulfillable_Type__c == 'BenefitChangeApplication') {
					fulFillmentRecMap.put('hawaiian_ice-benefit_change_application-' + fulfillmentRec.Fulfillable_Id__c, fulfillmentRec.Id__c);
				} else if (fulfillmentRec.Fulfillable_Type__c == 'Renewal') {
					fulFillmentRecMap.put('hawaiian_ice-renewal-' + fulfillmentRec.Fulfillable_Id__c, fulfillmentRec.Id__c);
				}
			}
		}

		if (fulFillmentRecMap != null && companyIdSet != null && fulFillmentRecMap.size() > 0 && companyIdSet.size() > 0) {
			for (Benefit_Order__c boRec : [
				SELECT Final_Extension_Date__c, OE_Complete__c, Open_Enrollment_End_Date__c, Open_Enrollment_Start_Date__c, Opportunity__r.Account.ZP_Company_ID__c, Opportunity__r.Source_ID__c
				FROM Benefit_Order__c
				WHERE
					Opportunity__r.Source_ID__c IN :fulFillmentRecMap.keySet()
					AND Opportunity__r.Account.ZP_Company_ID__c IN :companyIdSet
					AND Opportunity__c != NULL
					AND Opportunity__r.Source_ID__c != NULL
					AND Opportunity__r.AccountId != NULL
					AND Opportunity__r.Account.ZP_Company_ID__c != NULL
			]) {
				if (
					enrollmentFulFillmentIdMap != null &&
					enrollmentFulFillmentIdMap.keyset().size() > 0 &&
					fulFillmentRecMap.containsKey(boRec.Opportunity__r.Source_ID__c) &&
					enrollmentFulFillmentIdMap.containsKey(fulFillmentRecMap.get(boRec.Opportunity__r.Source_ID__c))
				) {
					HI_Open_Enrollment_Window__c relatedWindowRec = enrollmentFulFillmentIdMap.get(fulFillmentRecMap.get(boRec.Opportunity__r.Source_ID__c));
					boRec.Open_Enrollment_Start_Date__c = relatedWindowRec.Window_Start_Date__c;
					boRec.Open_Enrollment_End_Date__c = relatedWindowRec.Window_End_Date__c;
					boRec.Final_Extension_Date__c = relatedWindowRec.Final_Extension_Date__c;
					boRec.OE_Complete__c = relatedWindowRec.OE_Complete__c;
					boToUpdate.add(boRec);
				}
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();

		if (boToUpdate != null && boToUpdate.size() > 0) {
			//Update benefit order records
			Boolean benefitOrderTriggerFlag = BenefitOrderHelper.skipTrigger;
			BenefitOrderHelper.skipTrigger = true;
			update boToUpdate;
			BenefitOrderHelper.skipTrigger = benefitOrderTriggerFlag;
			for (HI_Open_Enrollment_Window__c openEnrollmentRec : openEnrollmentWindowList) {
				openEnrollmentRec.Processing_State__c = 'Processed';
			}
		}
	}
	private HI_Open_Enrollment_Window__c setProcessingState(String ProcessingState, String message, HI_Open_Enrollment_Window__c hiOpenEnrollmentWindow) {
		hiOpenEnrollmentWindow.Processing_State__c = ProcessingState;
		hiOpenEnrollmentWindow.Message__c = message;
        
		return hiOpenEnrollmentWindow;
	}
}