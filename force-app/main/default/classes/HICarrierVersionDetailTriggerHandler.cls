/**
 * @name         HICarrierVersionTriggerHandler
 * @author       Gireesh
 * @date         07 July 2020
 * @description  TriggerHandler class to execute HI Carrier version events
 * @test class   HICarrierVersionTriggerHandlerTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public class HICarrierVersionDetailTriggerHandler {
	public static boolean blnSkipTrigger = false;
	public static boolean blnQueue = false;
	public static final String STR_ERROR_MSG = 'HI carrier process failed';
	public static final String STR_SUCCESS_MSG = 'HI carrier successfully processed';
	public void OnBeforeInsert(List<HICarrierVersionDetail__c> list_Events) {
		for (HICarrierVersionDetail__c objHiCarrierVersion : list_Events) {
			if (objHiCarrierVersion.state_carrier_id__c != null && objHiCarrierVersion.Effective_date__c != null) {
				objHiCarrierVersion.Version_Key__c = objHiCarrierVersion.state_carrier_id__c + '-' + objHiCarrierVersion.Effective_date__c.Year() + '-' + objHiCarrierVersion.Effective_date__c.month();
			}
		}
		if (blnQueue == true) {
			processEvents(list_Events);
		}
	}
	public void OnAfterInsert(List<HICarrierVersionDetail__c> list_HiCarrierVersions) {
		if (blnQueue == false) {
			if (Limits.getQueueableJobs() == 0) {
				ID jobID = System.enqueueJob(new HiCarrierVersionQueue(list_HiCarrierVersions));
			}
		}
	}

	public void OnBeforeUpdate(map<ID, HICarrierVersionDetail__c> map_OldHiCarrierVersions, List<HICarrierVersionDetail__c> list_HiCarrierVersions) {
		if (blnQueue == true) {
			processEvents(list_HiCarrierVersions);
		}
	}

	public void OnAfterUpdate(Map<ID, HICarrierVersionDetail__c> map_OldHiCarrierVersions, List<HICarrierVersionDetail__c> list_HiCarrierVersions) {
		if (blnQueue == false && Limits.getQueueableJobs() == 0) {
			ID idJob = System.enqueueJob(new HICarrierVersionQueue(list_HICarrierVersions));
		}
	}

	private void processEvents(List<HICarrierVersionDetail__c> list_Events) {
		List<HICarrierVersionDetail__c> list_HiCarrierVersion = new List<HICarrierVersionDetail__c>();

		for (HICarrierVersionDetail__c objEvent : list_Events) {
			if (objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objEvent.Event_Id__c == null) {
				continue;
			}
			if (objEvent.Event_Type__c == 'carrier_metadata') {
				list_HiCarrierVersion.add(objEvent);
			}
		}
		if (list_HICarrierVersion != null && !list_HICarrierVersion.isEmpty()) {
			processInformation(list_HiCarrierVersion);
		}
	}

	/*
    Map the HI Version event with Carrier Version detail table.
    
    */
	public void processInformation(List<HICarrierVersionDetail__c> list_HICarrierVersionEvent) {
		if (list_HICarrierVersionEvent != null && !list_HICarrierVersionEvent.isEmpty()) {
			Map<String, HICarrierVersionDetail__c> map_HICarrierVersion = new Map<String, HiCarrierVersionDetail__c>();
			Map<String, Date> map_HICarrierVersionDate = new Map<String, Date>();

			for (HICarrierVersionDetail__c objHICarrierV : list_HICarrierVersionEvent) {
				if (objHICarrierV.state_carrier_id__c != null && objHICarrierV.Effective_date__c != null) {
					map_HICarrierVersionDate.put(objHICarrierV.state_carrier_id__c, objHICarrierV.Effective_date__c);
					map_HICarrierVersion.put(objHICarrierV.state_carrier_id__c, objHICarrierV);
				} else {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'HI Carrier state id or effective date is missing', objHICarrierV);
				}
			}
			if (!map_HICarrierVersion.isEmpty())
				updateCarrierVersion(map_HICarrierVersionDate, map_HICarrierVersion);
		}
	}
	/*
            Determine whether need to create new version or update existing versiom
        */
	public void updateCarrierVersion(Map<String, Date> map_CarrierIdDate, Map<String, HICarrierVersionDetail__c> map_CarrierVersion) {
		List<Carrier_Version_Detail__c> list_carrierVersionDetailInsert = new List<Carrier_Version_Detail__c>();
		List<Carrier_Version_Detail__c> list_carrierVersionDetailUpdate = new List<Carrier_Version_Detail__c>();
		//Get the carrier based on effective date
		Map<String, Carrier_Version_Detail__c> map_carrierVersionExisting = Utils.getCarrierVersion(map_CarrierIdDate);
		Map<String, Carrier_Version_Detail__c> map_carrierVersionIncoming = new Map<String, Carrier_Version_Detail__c>();
		List<Carrier__C> list_Carrier = [SELECT id, Id__C, name FROM Carrier__C WHERE id__C IN :map_CarrierVersion.keySet()];
		if (list_Carrier.isEmpty()) {
			for (String strId : map_CarrierVersion.keySet()) {
				HiCarrierVersionDetail__c objHICarrVersion = map_CarrierVersion.get(strId);
				setProcessingState('Error', 'No state carrier found', objHICarrVersion);
			}
			return;
		}
		for (Carrier__C objCarrier : list_Carrier) {
			if (objCarrier.Id__C != null && !String.isEmpty(objCarrier.Id__C)) {
				HiCarrierVersionDetail__c objHiCarrierVersion = map_CarrierVersion.get(objCarrier.Id__C);
				Carrier_Version_Detail__c objCarrVersion = new Carrier_Version_Detail__c();
				objCarrVersion.Carrier_Id__c = objCarrier.Id;
				objCarrVersion.Carrier_Id__r = objCarrier;
				objCarrVersion.Effective_date__c = objHiCarrierVersion.Effective_date__c.toStartOfMonth();
				objCarrVersion.Updated_Effective_Date__c = objHiCarrierVersion.Effective_date__c;
				//State Carrier Id-YYYY-MM
				objCarrVersion.Version_Key__c = objHiCarrierVersion.state_carrier_id__c + '-' + objCarrVersion.Effective_date__c.Year() + '-' + objCarrVersion.Effective_date__c.month();
				//map all fields
				objCarrVersion.Allows_Plans_with_No_Enrollees__c = getYNValues(objHiCarrierVersion.Allows_Plans_with_No_Enrollees__c);
				objCarrVersion.Out_of_State_Employees__c = getYNValues(objHiCarrierVersion.allows_out_of_state_employees__c);
				objCarrVersion.Gusto_Default_Rating_Structure__c = objHiCarrierVersion.gusto_default_rating_structure__c;
				objCarrVersion.Job_Titles_Required__c = getYNValues(objHiCarrierVersion.job_titles_required__c);
				objCarrVersion.Max_Number_of_Ghost_Plans__c = objHiCarrierVersion.max_number_of_ghost_plans__c;
				objCarrVersion.Medical_LOA_Required__c = getYNValues(objHiCarrierVersion.medical_loa_required__c);
				objCarrVersion.Number_of_Plans_Allowed_based_on_FTE__c = getStrArrayValues(objHiCarrierVersion.number_of_plans_allowed_on_fte_count__c);
				objCarrVersion.Number_of_Plans_Allowed_on_Enrolle_count__c = getStrArrayValues(objHiCarrierVersion.Number_of_Plans_Allowed_on_EnrolleeCount__c);
				objCarrVersion.One_Enrolling_EE_Group_Restrictions__c = getStrArrayValues(objHiCarrierVersion.one_enrolling_ee_group_restrictions__c);
				objCarrVersion.Owner_Percentage_Required__c = getYNValues(objHiCarrierVersion.owner_percent_required__c);
				objCarrVersion.Participation_Requirements__c = objHiCarrierVersion.Participation_Requirements__c;
				objCarrVersion.Personal_LOA_Required__c = getYNValues(objHiCarrierVersion.personal_loa_required__c);
				objCarrVersion.Valid_Waivers__c = getStrArrayValues(objHiCarrierVersion.valid_waivers__c);
				objCarrVersion.Waiting_Period_Default_for_New_Hires__c = getStrArrayValues(objHiCarrierVersion.waiting_period_default_for_new_hires__c);
				objCarrVersion.NP_Submission_Docs_Required__c = objHiCarrierVersion.NP_Submission_Docs_Required__c;
				objCarrVersion.New_Plan_Submission_Event__c = objHiCarrierVersion.New_Plan_Submission_Event__c;
				objCarrVersion.New_Plan_Variation_Num2__c = objHiCarrierVersion.new_plan_variation_num_2__c;
				objCarrVersion.New_Plan_Variation_Num1__c = objHiCarrierVersion.new_plan_variation_num_1__c;
				objCarrVersion.Group_Submission_Event__c = objHiCarrierVersion.Group_Submission_Event__c;
				objCarrVersion.Group_Variation_Number1__c = objHiCarrierVersion.group_variation_num_1__c;
				objCarrVersion.Group_Variation_Number2__c = objHiCarrierVersion.group_variation_num_2__c;
				objCarrVersion.Member_Submission_Event__c = objHiCarrierVersion.Member_Submission_Event__c;
				objCarrVersion.Member_Submission_Variation1__c = objHiCarrierVersion.member_variation_num_1__c;
				objCarrVersion.Member_Submission_Variation2__c = objHiCarrierVersion.member_variation_num_2__c;
				objCarrVersion.Term_Submission_Event__c = objHiCarrierVersion.Term_Submission_Event__c;
				objCarrVersion.Term_Variation_Number__c = objHiCarrierVersion.term_variation_num__c;
				objCarrVersion.Submission_Email__c = objHiCarrierVersion.Submission_Email__c;
				objCarrVersion.Renewal_Email_List__c = objHiCarrierVersion.Renewal_Email_List__c;
				objCarrVersion.Newplan_Email_List__c = objHiCarrierVersion.new_plan_email_list__c;
				objCarrVersion.Carrier_Play_Mode__c = objHiCarrierVersion.Carrier_Play_Mode__c;
				objCarrVersion.Carrier_Unique_Name__c = objHiCarrierVersion.Carrier_Unique_Name__c;
				objCarrVersion.Oos_Plan_Restrictions__c = objHiCarrierVersion.oos_plan_restrictions__c;
				objCarrVersion.nonowner_eligible_w2ees_req__c = objHiCarrierVersion.nonowner_eligible_w2ees_req__c;
				objCarrVersion.nonowner_eligible_w2ees_req_to_enroll__c = objHiCarrierVersion.nonowner_eligible_w2ees_req_to_enroll__c;
				objCarrVersion.Deductible_Reset_Year__c = objHiCarrierVersion.deductible_reset_year__c;
				objCarrVersion.Renewal_Participation_Details__c = objHiCarrierVersion.renewal_participation_details__c;
				objCarrVersion.With_Changes_Submission_Start_Event__c = objHiCarrierVersion.renewal_with_changes_submission_event__c;
				objCarrVersion.With_Changes_Sub_Start_Variation_No__c = objHiCarrierVersion.Renewal_With_Changes_Submission_Num__c;
				objCarrVersion.Without_Changes_Submission_Start_Event__c = objHiCarrierVersion.Renewal_Without_Changes_Submission_Event__c;
				objCarrVersion.Without_Changes_Sub_Start_Variation_No__c = objHiCarrierVersion.Renewal_Without_Changes_Submission_Num__c;

				map_carrierVersionIncoming.put(objCarrier.Id__C, objCarrVersion);
			}
		}

		try {
			for (String strCarrierId : map_CarrierIdDate.keySet()) {
				Carrier_Version_Detail__c objCarrierVersionUpdated = map_carrierVersionIncoming.get(strCarrierId);
				//get the exisitng carrier version:
				if (map_carrierVersionExisting.get(strCarrierId) != null) {
					Carrier_Version_Detail__c objCarrierVersionCurrent = map_carrierVersionExisting.get(strCarrierId);
					//carrier version for next year or new version for the current year
					if (
						objCarrierVersionCurrent.effective_date__c.year() < objCarrierVersionUpdated.effective_date__c.year() ||
						(objCarrierVersionCurrent.effective_date__c.year() <= objCarrierVersionUpdated.effective_date__c.year() &&
						objCarrierVersionCurrent.effective_date__c.month() < objCarrierVersionUpdated.effective_date__c.month())
					) {
						list_carrierVersionDetailInsert.add(objCarrierVersionUpdated);
					} else if (
						objCarrierVersionCurrent.effective_date__c.year() == objCarrierVersionUpdated.effective_date__c.year() &&
						objCarrierVersionCurrent.effective_date__c.month() == objCarrierVersionUpdated.effective_date__c.month()
					) {
						objCarrierVersionUpdated.Id = objCarrierVersionCurrent.Id;
						list_carrierVersionDetailUpdate.add(objCarrierVersionUpdated);
						if (map_CarrierVersion.get(strCarrierId) != null) {
							map_CarrierVersion.get(strCarrierId).carrier_version_detail__c = objCarrierVersionCurrent.Id;
						}
					}
				} else {
					list_carrierVersionDetailInsert.add(objCarrierVersionUpdated);
				}
			}

			if (list_carrierVersionDetailInsert != null && !list_carrierVersionDetailInsert.isEmpty()) {
				insert list_carrierVersionDetailInsert;
				Map<Id, Carrier_version_detail__c> map_CaVersion = new Map<Id, Carrier_version_detail__c>(list_carrierVersionDetailInsert);
				for (Carrier_version_detail__c objCversion : [SELECT Carrier_Id__r.id__C FROM Carrier_version_detail__c WHERE id = :map_CaVersion.keySet()]) {
					if (map_CarrierVersion.get(objCversion.Carrier_Id__r.id__C) != null) {
						map_CarrierVersion.get(objCversion.Carrier_Id__r.id__C).carrier_version_detail__c = objCversion.Id;
					}
				}
			}
			if (list_carrierVersionDetailUpdate != null && !list_carrierVersionDetailUpdate.isEmpty()) {
				update list_carrierVersionDetailUpdate;
			}
			for (String strId : map_CarrierVersion.keySet()) {
				HiCarrierVersionDetail__c objHICarrVersion = map_CarrierVersion.get(strId);
				setProcessingState('Processed', STR_SUCCESS_MSG, objHICarrVersion);
			}
		} catch (Exception e) {
			for (String strId : map_CarrierVersion.keySet()) {
				HiCarrierVersionDetail__c objHICarrVersion = map_CarrierVersion.get(strId);
				setProcessingState('Error', STR_ERROR_MSG + ' ' + e.getMessage(), objHICarrVersion);
			}
		}
	}

	@TestVisible
	private static HiCarrierVersionDetail__c setProcessingState(String strProcessingState, String strMessage, HiCarrierVersionDetail__c objHICarrierVersionEve) {
		objHICarrierVersionEve.Processing_State__c = strProcessingState;
		objHICarrierVersionEve.Message__c = strMessage;
		objHICarrierVersionEve.Processed_At__c = System.now();
		return objHICarrierVersionEve;
	}

	@TestVisible
	private static String getStrArrayValues(String strInput) {
		if (strInput == null)
			return null;
		String strValue;
		try {
			strValue = Utils.getStrArrayToString(strInput, ';');
		} catch (Exception objException) {
			ExceptionLogUtil.logException('HICarrierVersionDetailTriggerHandler', 'getStrArrayValues', objException.getMessage(), objException.getStackTraceString());
		}
		return strValue;
	}
	@TestVisible
	private static String getYNValues(String strInput) {
		if (strInput == null)
			return null;
		strInput = strInput.toLowerCase(strInput);
		String strValue;
		switch on strInput {
			when 'yes' {
				strValue = 'Y';
			}
			when 'no' {
				strValue = 'N';
			}
			when else {
				strvalue = 'None';
			}
		}
		return strValue;
	}
}