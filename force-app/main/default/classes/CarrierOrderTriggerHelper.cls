/**
 * @name         CarrierOrderTriggerHelper
 * @author       Aurobind Ravichandran
 * @date         06/23/2017
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 *               02/01/2020      Deepika         replace the Order Assignment code to the Common method on
calculateOrderAssignmentForCO (in CarrierOrderTriggerHeplerFunction)
    06/01/2020      Deepika         Added the Order status handler code
    
 **/
public with sharing class CarrierOrderTriggerHelper extends TriggerHandler {
	public static boolean isFirstRun = true;
	public static boolean historyCreated = false;
	public static boolean skipTrigger = false;
	public static map<Id, Benefit_Order__c> benefitOrderMap;
	public static map<Id, Carrier__c> map_Carrier;
	//Map used to save all the changes which need to update on the Benefit order
	public Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate;
	public static Boolean blnCaseCreatedFromCO = false;
	public static Boolean blnReprocessCases = false;
	public static Boolean blnUpdateOwner = true;
	public static Boolean blnUpdateSubmissionDeadlineDates = false;
	public static Map<Id, Carrier_Order__c> map_TerminationCO;
	public static Set<String> set_ImplementationStages = new Set<String>{ CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION, CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION };
	public static Date dtSpecial_Enrollment_Start_Date = Configuration_Settings__c.getOrgDefaults().Special_Enrollment_Start_Date__c;
	public static Date dtSpecial_Enrollment_Date = Configuration_Settings__c.getOrgDefaults().Special_Enrollment_Deadline_Date__c;
	public static List<String> list_CarrierIdsFromFlow = new List<String>();
	public CarrierOrderTriggerHelper() {
		super('CarrierOrderTriggerHelper');
	}

	public override void beforeInsert() {
		List<Carrier_Order__c> newCarrierOrderList = (List<Carrier_Order__c>) Trigger.new;

		cacheData(newCarrierOrderList);
		//Populate the Order Assignment based on Order type
		populateOrderAssignementOnChangeOfType(newCarrierOrderList, null, true);
		populateOrderAssignmentForTada(newCarrierOrderList);
		coStatusHandler(newCarrierOrderList, null);
		//populate submission date on co
		populateSubmissionDate(newCarrierOrderList, null);
		populateUniqueIdForCO(newCarrierOrderList, null);
		assignOwnerAndSubPrepDateForCO(newCarrierOrderList);
		setCarrierOrderImpStage(newCarrierOrderList, null);
		// Added for BBO-1974
		setSubmissionForTadaPreOESetup(newCarrierOrderList);
	}

	public override void afterInsert() {
		List<Carrier_Order__c> newCarrierOrderList = (List<Carrier_Order__c>) Trigger.new;
		map_BenefitOrderToUpdate = new Map<Id, Benefit_Order__c>();
		map_TerminationCO = new Map<Id, Carrier_Order__c>();

		syncSelectedOppPoliciesWithCarrierOrder(newCarrierOrderList);
		UpdateSubmissionDateOnBenefitOrder(newCarrierOrderList, null);
		processCases(newCarrierOrderList);
		CreateQALinesRecordAgainstCO(newCarrierOrderList, null);
		orderStatushandler(newCarrierOrderList, null, map_BenefitOrderToUpdate, benefitOrderMap);

		updateBenefitOrder(map_BenefitOrderToUpdate);
		//Update No_Of_Non_TADA_Carrier_Order__c, No_Of_TADA_Carrier_Order__c field on BO.
		Set<Id> set_BOIds = new Set<Id>();
		//DS[16/7/2020] exclude closed admin, closed lost
		Set<String> set_COExcludeTemp = UtilitiesFactory.set_FWExcludeCOBO;
		for (Carrier_Order__c objCarrier : newCarrierOrderList) {
			if (objCarrier.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR && set_COExcludeTemp.contains(objCarrier.Implementation_Stage__c) == false && objCarrier.Benefit_Order__c != null) {
				set_BOIds.add(objCarrier.Benefit_Order__c);
			}
		}

		if (set_BOIds.size() > 0) {
			CarrierOrderHelperFunctions.updateBOTadaNonTadaFieldValue(set_BOIds);
		}

		// QASheetHelper.createOrUpdateQASheet(newCarrierOrderList);
	}

	public override void beforeUpdate() {
		if (skipTrigger) {
			return;
		}

		List<Carrier_Order__c> newCarrierOrderList = (List<Carrier_Order__c>) Trigger.new;
		Map<Id, Carrier_Order__c> oldCarrierOrderMap = (Map<Id, Carrier_Order__c>) Trigger.oldMap;

		cacheData(newCarrierOrderList);
		//populate the Order Assignment On change of Order type
		populateOrderAssignementOnChangeOfType(newCarrierOrderList, oldCarrierOrderMap, false);
		populateUniqueIdForCO(newCarrierOrderList, oldCarrierOrderMap);
		populateSubmissionDate(newCarrierOrderList, oldCarrierOrderMap);
		//Lirik - Migration for BOR to BO -- Start ---
		populateTimeStampDateAndStage(newCarrierOrderList, oldCarrierOrderMap);
		validateCarrierOrderStage((Map<Id, Carrier_Order__c>) Trigger.newMap, oldCarrierOrderMap);
		//Lirik - Migration for BOR to BO -- End ---
		//@Neha 28-Sept-2020, Confirmation Automation
		Map<Id, Carrier_Order__c> map_ReadyForConfirmationCOIds = new Map<Id, Carrier_Order__c>(), map_COMovingToReadyForConfirmation2ndTime = new Map<Id, Carrier_Order__c>();
		for (Carrier_Order__c objCO : newCarrierOrderList) {
			Carrier_Order__c objOldCO = oldCarrierOrderMap.get(objCO.Id);
			if (objCO.Implementation_Stage__c != objOldCO.Implementation_Stage__c) {
				if (objCO.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION) {
					map_ReadyForConfirmationCOIds.put(objCO.Id, objCO);

					if (objCO.Order_Moved_Back_To_Confirmation__c == false) {
						map_COMovingToReadyForConfirmation2ndTime.put(objCO.Id, objCO);
					}
				} else if (
					objOldCO.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION &&
					objCO.Eligible_for_Confirmation_Automation__c == true &&
					objCO.Implementation_Stage__c != CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT
				) {
					objCO.Eligible_for_Confirmation_Automation__c = false;
				} else if (objOldCO.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT && objCO.Eligible_for_Confirmation_Automation__c == true) {
					objCO.Eligible_for_Confirmation_Automation__c = false;
				} else if (objCO.Follow_Up_Notes__c != objOldCO.Follow_Up_Notes__c) {
					objCO.Follow_Up_Notes_last_modified__c = System.now();
				}
			} else if (objCO.Follow_Up_Notes__c != objOldCO.Follow_Up_Notes__c) {
				objCO.Follow_Up_Notes_last_modified__c = System.now();
			}

			if (objCO.HI_Submission_Automation_Status__c != objOldCO.HI_Submission_Automation_Status__c) {
				objCO.API_Submission_Date__c = System.now();
			}

			if (
				objCO.Eligible_for_Confirmation_Automation__c != objOldCO.Eligible_for_Confirmation_Automation__c && objCO.Eligible_for_Confirmation_Automation__c == false ||
				(objCO.HI_Confirmation_Automation_Status__c == CarrierOrderUtil.STATUS_UNABLE_TO_AUDIT ||
				objCO.HI_Confirmation_Automation_Status__c == CarrierOrderUtil.HI_SUBMISSION_AUTOMATION_STATUS_SUCCESS)
			) {
				objCO.HI_Confirmation_Automation_End_Date_Time__c = System.now();
			}
		}

		if (!map_COMovingToReadyForConfirmation2ndTime.isEmpty()) {
			ConfirmationAutomationHelper.checkIfCOWereMovedToReadyForConfirmationEarlier(map_COMovingToReadyForConfirmation2ndTime);
		}
		UtilitiesFactory.setHistoryTracking((List<SObject>) newCarrierOrderList, (Map<Id, SObject>) oldCarrierOrderMap, 'Carrier_Order');
		// making sure that this method is called only once
		// [SM 07/16/2019] : Moved code here to capture stage changes.
		if (!historyCreated)
			createCarrierOrderStageHistory(newCarrierOrderList, oldCarrierOrderMap);

		coStatusHandler(newCarrierOrderList, oldCarrierOrderMap);
		updateParentCOForMultiEIN(newCarrierOrderList);
		onAutomationStatusUpdate(newCarrierOrderList, oldCarrierOrderMap);
		updateInitialOwnerRelatedToSubmission(newCarrierOrderList, oldCarrierOrderMap);

		if (!map_ReadyForConfirmationCOIds.isEmpty()) {
			ConfirmationAutomationHelper.makeCOsEligibleForConfirmationAutomation(map_ReadyForConfirmationCOIds);
		}
		markCOsEligibleForSubmissionAutomation(newCarrierOrderList, oldCarrierOrderMap);
		setFlagOnCarrierOrder(newCarrierOrderList, oldCarrierOrderMap);
		setCarrierOrderImpStage(newCarrierOrderList, oldCarrierOrderMap);
		// Added for BBO-1974
		setSubmissionForTadaPreOESetup(newCarrierOrderList);
	}

	public override void afterUpdate() {
		map_BenefitOrderToUpdate = new Map<Id, Benefit_Order__c>();
		if (skipTrigger) {
			return;
		}

		List<Carrier_Order__c> newCarrierOrderList = (List<Carrier_Order__c>) Trigger.new;
		Map<Id, Carrier_Order__c> newCarrierOrderMap = (Map<Id, Carrier_Order__c>) Trigger.newMap;
		Map<Id, Carrier_Order__c> oldCarrierOrderMap = (Map<Id, Carrier_Order__c>) Trigger.oldMap;

		UpdateSubmissionDateOnBenefitOrder(newCarrierOrderList, oldCarrierOrderMap);
		UpdateSubmissionDateOnQALinesOfCoverage(newCarrierOrderList, oldCarrierOrderMap);
		UpdateRelatedCasesOnCo(newCarrierOrderMap, oldCarrierOrderMap, newCarrierOrderList);
		CreateQALinesRecordAgainstCO(newCarrierOrderList, oldCarrierOrderMap);
		orderStatushandler(newCarrierOrderList, oldCarrierOrderMap, map_BenefitOrderToUpdate, benefitOrderMap);
		updateTerminationDateOnPreceedingCO(newCarrierOrderList, oldCarrierOrderMap);
		updateBenefitOrder(map_BenefitOrderToUpdate);

		//Written by AKS Dated 15th May 2020
		//Called this method on "After Update" as Sanjay suggested to avoid load of  before committing
		UpdateChecklistCompletedDateTime(newCarrierOrderList);

		//Update No_Of_Non_TADA_Carrier_Order__c, No_Of_TADA_Carrier_Order__c field on BO.
		//DS[16/7/2020] exclude closed admin, closed lost
		Set<String> set_COExcludeTemp = UtilitiesFactory.set_FWExcludeCOBO;
		Set<Id> set_BOIds = new Set<Id>();
		for (Carrier_Order__c objCarrier : newCarrierOrderList) {
			Carrier_Order__c oldObjCarrier = oldCarrierOrderMap.get(objCarrier.Id);
			if (
				objCarrier.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR &&
				objCarrier.Implementation_Stage__c != oldObjCarrier.Implementation_Stage__c &&
				(set_COExcludeTemp.contains(objCarrier.Implementation_Stage__c) == false ||
				set_COExcludeTemp.contains(oldObjCarrier.Implementation_Stage__c) == false)
			) {
				set_BOIds.add(objCarrier.Benefit_Order__c);
			}
		}

		if (set_BOIds.size() > 0) {
			CarrierOrderHelperFunctions.updateBOTadaNonTadaFieldValue(set_BOIds);
		}

		updateChildOrderPlayableDate(newCarrierOrderList, oldCarrierOrderMap);
		updateCarrierOrderStageDetail(newCarrierOrderList, oldCarrierOrderMap);
		updateTerminatedCO(newCarrierOrderList);
		reassignInProgressTickets(newCarrierOrderMap, (List<Carrier_Order__c>) Trigger.old);
	}

	public override void afterDelete() {
		Map<Id, Carrier_Order__c> oldCarrierOrderMap = (Map<Id, Carrier_Order__c>) Trigger.oldMap;

		cacheData(oldCarrierOrderMap.values());
		map_BenefitOrderToUpdate = new Map<Id, Benefit_Order__c>();
		orderStatushandler(null, oldCarrierOrderMap, map_BenefitOrderToUpdate, benefitOrderMap);
		updateBenefitOrder(map_BenefitOrderToUpdate);
	}

	public override void afterUndelete() {
		Map<Id, Carrier_Order__c> newCarrierOrderMap = (Map<Id, Carrier_Order__c>) Trigger.newMap;

		cacheData(newCarrierOrderMap.values());
		map_BenefitOrderToUpdate = new Map<Id, Benefit_Order__c>();
		orderStatushandler(newCarrierOrderMap.values(), null, map_BenefitOrderToUpdate, benefitOrderMap);
		updateBenefitOrder(map_BenefitOrderToUpdate);
	}

	//Lirik - Migration for BOR to BO -- Start ---
	private void populateTimeStampDateAndStage(list<Carrier_Order__c> newCarrierOrderList, map<id, Carrier_Order__c> oldCarrierOrderMap) {
		String strBasicCarrierOrderId = Label.BASIC_Carrier;

		if (oldCarrierOrderMap != null && newCarrierOrderList != null && !newCarrierOrderList.isEmpty()) {
			for (Carrier_Order__c coRec : newCarrierOrderList) {
				if (coRec.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
					String str15DigitId = string.valueof(coRec.Carrier__c).substring(0, 15);
					if (coRec.Submitted_Completed_Datetime__c == null) {
						if (
							(strBasicCarrierOrderId == str15DigitId ||
							(!map_Carrier.isEmpty() &&
							coRec.Carrier__c != null &&
							map_Carrier.containsKey(coRec.Carrier__c) &&
							map_Carrier.get(coRec.Carrier__c).Partner_Type__c != null &&
							map_Carrier.get(coRec.Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA)) &&
							coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED &&
							oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c != CarrierOrderUtil.CO_STATUS_APPROVED
						) {
							coRec.Submitted_Completed_Datetime__c = System.now();
						} else if (
							coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION &&
							oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c != CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION
						) {
							coRec.Submitted_Completed_Datetime__c = System.now();
						}
					}

					if (
						coRec.Implementation_Stage__c != null &&
						coRec.Implementation_Stage__c != oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c &&
						coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION
					) {
						coRec.Ready_for_Confirmation_Timestamp__c = System.now();
					}

					if (coRec.Follow_Up_Date__c != null && coRec.Follow_Up_Date__c != oldCarrierOrderMap.get(coRec.Id).Follow_Up_Date__c && !CarrierOrderExt.blnIsEarlySubmissionButtonClick) {
						if (set_ImplementationStages.contains(oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c)) {
							if (
								!benefitOrderMap.isEmpty() &&
								coRec.Benefit_Order__c != null &&
								benefitOrderMap.containsKey(coRec.Benefit_Order__c) &&
								benefitOrderMap.get(coRec.Benefit_Order__c).Order_Status__c != null &&
								benefitOrderMap.get(coRec.Benefit_Order__c).Order_Status__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP
							) {
								if (coRec.Implementation_Stage__c == CarrierOrderUtil.STAGE_SUBMISSION_PREP) {
									coRec.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
								} else if (coRec.Implementation_Stage__c == CarrierOrderUtil.STAGE_PENDING_CONFIRMATION) {
									coRec.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
									coRec.Ready_for_Confirmation_Timestamp__c = System.now();
								} else if (coRec.Implementation_Stage__c == CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION) {
									coRec.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
								}
							} else if (coRec.Implementation_Stage__c == CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION) {
								coRec.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
							}
						} else {
							if (coRec.Implementation_Stage__c == CarrierOrderUtil.STAGE_SUBMISSION_PREP) {
								coRec.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
							} else if (coRec.Implementation_Stage__c == CarrierOrderUtil.STAGE_PENDING_CONFIRMATION) {
								coRec.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
								coRec.Ready_for_Confirmation_Timestamp__c = System.now();
							} else if (coRec.Implementation_Stage__c == CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION) {
								coRec.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
							}
						}
					}

					if (
						coRec.Implementation_Stage__c != null &&
						coRec.Implementation_Stage__c != oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c &&
						coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP
					) {
						coRec.Submission_Prep_Assigned_Date__c = System.now();
					}
				} else {
					//[DS]Capture Enrollment Review completed date time for each carrier order
					if (coRec.Implementation_Stage__c != oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c && coRec.Implementation_Stage__c == 'Ready to Send Enrollment Review') {
						coRec.Enrollment_Review_Completed_Date_Time__c = System.now();
					} else if (coRec.Implementation_Stage__c != oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c && coRec.Implementation_Stage__c == 'Ready to Send Plan Review') {
						//[DS]Capture Plan build completed date time for each carrier order.
						coRec.Plan_Review_Completed_Date_Time__c = System.now();
					}
				}

				if (coRec.Implementation_Stage__c != oldCarrierOrderMap.get(coRec.Id).Implementation_Stage__c) {
					coRec.Status_Change_Date_Time__c = system.now();
				}

				if (coRec.Confirmation_Owner__c != oldCarrierOrderMap.get(coRec.Id).Confirmation_Owner__c) {
					coRec.Confirmation_Owner_Last_Modified__c = system.now();
				}
			}
		}
	}

	/**
* @author        Deepika Saini
* @description   check if Order playable date on child orders 
* @param          list_NewCarrierOrders  list of New Carrier Orders
map_OldCarrierOrders  Map of Old Carrier Orders
* @return        null
**/
	private void updateChildOrderPlayableDate(List<Carrier_Order__c> list_NewCarrierOrders, Map<Id, Carrier_Order__c> map_OldCarrierOrders) {
		Set<Id> set_ParentCarrierOrders = new Set<Id>();
		Map<Id, Date> map_ParentCOsWithOrderPlayable = new Map<Id, Date>();
		Map<Id, Date> map_ParentCOsWithAuditPlayable = new Map<Id, Date>();
		for (Carrier_Order__c objCO : list_NewCarrierOrders) {
			Carrier_Order__c objOldCO;
			if (map_OldCarrierOrders != null && map_OldCarrierOrders.containsKey(objCO.id)) {
				objOldCO = map_OldCarrierOrders.get(objCO.id);

				if (objCO.Is_Multi_EIN__c && objCO.Parent_Carrier_Order__c == null) {
					if (objCO.Order_Playable_Date__c != null && objCO.Order_Playable_Date__c != objOldCO.Order_Playable_Date__c) {
						map_ParentCOsWithOrderPlayable.put(objCO.Id, objCO.Order_Playable_Date__c);
						set_ParentCarrierOrders.add(objCO.Id);
					}

					if (objCO.Audit_Playable_Date__c != null && objCO.Audit_Playable_Date__c != objOldCO.Audit_Playable_Date__c) {
						map_ParentCOsWithAuditPlayable.put(objCO.Id, objCO.Audit_Playable_Date__c);
						set_ParentCarrierOrders.add(objCO.Id);
					}
				}
			}
		}

		if (!set_ParentCarrierOrders.isEmpty()) {
			List<Carrier_Order__c> list_ChildCOs = [
				SELECT Id, Name, Order_Playable_Date__c, Audit_Playable_Date__c, Parent_Carrier_Order__c
				FROM Carrier_Order__c
				WHERE Parent_Carrier_Order__c IN :set_ParentCarrierOrders
			];
			List<Carrier_Order__c> list_ChildCOsToUpdated = new List<Carrier_Order__c>();
			for (Carrier_Order__c objCO : list_ChildCOs) {
				if (map_ParentCOsWithOrderPlayable?.size() > 0) {
					objCO.Order_Playable_Date__c = map_ParentCOsWithOrderPlayable.get(objCO.Parent_Carrier_Order__c);
				}

				if (map_ParentCOsWithAuditPlayable?.size() > 0) {
					objCO.Audit_Playable_Date__c = map_ParentCOsWithAuditPlayable.get(objCO.Parent_Carrier_Order__c);
				}
				list_ChildCOsToUpdated.add(objCO);
			}

			if (!list_ChildCOsToUpdated.isEmpty()) {
				Boolean blnCOSkip = CarrierOrderTriggerHelper.skipTrigger;
				CarrierOrderTriggerHelper.skipTrigger = true;
				update list_ChildCOsToUpdated;
				CarrierOrderTriggerHelper.skipTrigger = blnCOSkip;
			}
		}
	}

	private void UpdateChecklistCompletedDateTime(list<Carrier_Order__c> newCarrierOrderList) {
		try {
			List<Carrier_Order__c> list_TempCarrierOrder = new List<Carrier_Order__c>();
			for (Carrier_Order__c co : newCarrierOrderList) {
				if (co.Checklist_For_Plan_Build__c == true && co.Checklist_For_Enrollment_Review__c == true && co.Checklist_Completed_Date_Time__c == null) {
					Carrier_Order__c objCoTemp = new Carrier_Order__c(id = co.Id);
					objCoTemp.Checklist_Completed_Date_Time__c = DateTime.now();
					list_TempCarrierOrder.add(objCoTemp);
				}
			}
			if (list_TempCarrierOrder != null && list_TempCarrierOrder.size() > 0) {
				Boolean blnCOSkip = CarrierOrderTriggerHelper.skipTrigger;
				CarrierOrderTriggerHelper.skipTrigger = true;
				update list_TempCarrierOrder;
				CarrierOrderTriggerHelper.skipTrigger = blnCOSkip;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CarrierOrderTriggerHelper', 'UpdateChecklistCompletedDateTime', ex.getMessage(), 'High');
		}
	}

	public void populateOrderAssignmentForTada(List<Carrier_Order__c> list_COs) {
		Set<String> set_EarlySubmissionRequired = new Set<String>();
		Set<Id> set_OppIds = new Set<Id>();
		for (Carrier_Order__c objCO : list_COs) {
			if (
				objCO.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR &&
				objCO.Order_Type__c != null &&
				(objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP ||
				objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE)
			) {
				objCO.Order_Assignment__c = objCO.Order_Type__c;
			}

			if (objCO.Carrier__c != null && objCO.Benefit_Order__c != null && String.isBlank(objCO.Implementation_Stage__c)) {
				Benefit_Order__c objBO = benefitOrderMap.get(objCO.Benefit_Order__c);
				set_OppIds.add(objBO.Opportunity__c);
			}
		}

		//When user Maually create Carrier Order then Implementation_Stage__c is blank then this code will set the Implementation_Stage__c field value.
		if (set_OppIds.size() > 0) {
			for (QA_Lines_Of_Coverage__c objQALOC : [
				SELECT Id, Benefits_selected_Carrier__c, Early_Submission_Required__c, QA_Sheet__r.Opportunity__c
				FROM QA_Lines_Of_Coverage__c
				WHERE QA_Sheet__r.Opportunity__c IN :set_OppIds AND Benefits_selected_Carrier__c != NULL
			]) {
				set_EarlySubmissionRequired.add(objQALOC.QA_Sheet__r.Opportunity__c + '-' + objQALOC.Benefits_selected_Carrier__c);
			}

			for (Carrier_Order__c objCO : list_COs) {
				if (objCO.Carrier__c != null && objCO.Benefit_Order__c != null && String.isBlank(objCO.Implementation_Stage__c)) {
					Benefit_Order__c objBO = benefitOrderMap.get(objCO.Benefit_Order__c);
					if (objCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
					} else if (
						(objCO.RecordTypeId == CarrierOrderHelperFunctions.CARRIER_ORDER_RENEWAL_RT ||
						objCO.RecordTypeId == CarrierOrderHelperFunctions.CARRIER_ORDER_NEW_PLAN_RT ||
						objCO.RecordTypeId == CarrierOrderHelperFunctions.CARRIER_ORDER_CHANGE_RT) &&
						String.isNotBlank(objCO.Order_Type__c) &&
						objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER
					) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
					}
					if (!set_EarlySubmissionRequired.isEmpty() && set_EarlySubmissionRequired.contains(objBO.Opportunity__c + '-' + objCO.Carrier__c)) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION;
					}
				}
			}
		}
	}

	//Added for BBO-1974
	public void setSubmissionForTadaPreOESetup(List<Carrier_Order__c> list_NewCarrierOrders) {
		for (Carrier_Order__c objCO : list_NewCarrierOrders) {
			if (objCO.Order_Type__c == 'TAdA: Pre OE Setup') {
				if (Trigger.isInsert) {
					Date dtTodaysDate = System.today();
					objCO.Group_Submission_Date__c = dtTodaysDate.addDays(3);
					objCO.Submission_Deadline__c = dtTodaysDate.addDays(3);
				} else if (Trigger.isUpdate) {
					if (objCO.Group_Submission_Date__c == null || objCO.Submission_Deadline__c == null) {
						Date dtActionDate = Date.valueOf(objCO.createdDate);
						objCO.Group_Submission_Date__c = dtActionDate.addDays(3);
						objCO.Submission_Deadline__c = dtActionDate.addDays(3);
					}
				}
				Integer intSixtyDaysPriorToCoverageDate = -60;
				if (benefitOrderMap.containsKey(objCO.Benefit_Order__c)) {
					Benefit_Order__c objBenifitOrder = benefitOrderMap.get(objCO.Benefit_Order__c);
					if (objBenifitOrder.Coverage_Effective_Date__c != null) {
						objCO.Submission_Deadline_Start_Date__c = objBenifitOrder.Coverage_Effective_Date__c.addDays(intSixtyDaysPriorToCoverageDate);
					}
				}
			}
		}
	}

	public void assignOwnerAndSubPrepDateForCO(List<Carrier_Order__c> newCarrierOrderList) {
		Set<Id> carrierIdSet = new Set<Id>();
		for (Carrier_Order__c coRec : newCarrierOrderList) {
			if (coRec.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
				//Assign Submission Prep Assigned Date
				if (coRec.Implementation_Stage__c != null && coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP) {
					coRec.Submission_Prep_Assigned_Date__c = System.now();
				}
				//Assign Ready for Confirmation Date
				if (coRec.Implementation_Stage__c != null && coRec.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION) {
					coRec.Ready_for_Confirmation_Timestamp__c = System.now();
				}
				//Assign Owner
				if (coRec.Parent_Carrier_Order__c == null) {
					coRec.OwnerId = Label.Carrier_Implementation_Queue;
				} else {
					carrierIdSet.add(coRec.Parent_Carrier_Order__c);
				}
			} else {
				if (coRec.Parent_Carrier_Order__c == null) {
					//BY:PR, Date: Feb-20-20, Desc: For TAdA carrier we are assigning the BO Owner(Advocate) as CO Owner
					if (
						!map_Carrier.isEmpty() &&
						coRec.Carrier__c != null &&
						map_Carrier.containsKey(coRec.Carrier__c) &&
						(map_Carrier.get(coRec.Carrier__c).Partner_Type__c == null ||
						map_Carrier.get(coRec.Carrier__c).Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA)
					) {
						coRec.OwnerId = Label.Carrier_Implementation_Queue;
					}
				}
			}
		}
		if (!carrierIdSet.isEmpty()) {
			//Fetch the Parent Carrier Owner Id
			Map<string, string> mapParentCarrierOwner = new Map<string, string>();
			for (Carrier_Order__c objCarrierOrder : [SELECT Id, OwnerId FROM Carrier_Order__c WHERE Id IN :carrierIdSet]) {
				mapParentCarrierOwner.put(objCarrierOrder.Id, objCarrierOrder.OwnerId);
			}
			//Assign Parent Carrier Owner Id
			for (Carrier_Order__c coRec : newCarrierOrderList) {
				if (coRec.Parent_Carrier_Order__c != null) {
					coRec.OwnerId = mapParentCarrierOwner.get(coRec.Parent_Carrier_Order__c);
				}
			}
		}
	}

	// populate the unique Id on CO
	public void populateUniqueIdForCO(List<Carrier_Order__c> lst_NewCarrierOrder, Map<id, Carrier_Order__c> map_OldCarrierOrder) {
		for (Carrier_Order__c objCarrierOrder : lst_NewCarrierOrder) {
			if (
				(map_OldCarrierOrder == null && objCarrierOrder.Unique_Id__c == null) ||
				(map_OldCarrierOrder != null &&
				map_OldCarrierOrder.containsKey(objCarrierOrder.Id) &&
				(objCarrierOrder.carrier__c != map_OldCarrierOrder.get(objCarrierOrder.Id).carrier__c ||
				objCarrierOrder.Benefit_Order__c != map_OldCarrierOrder.get(objCarrierOrder.Id).Benefit_Order__c ||
				objCarrierOrder.Benefit_Types__c != map_OldCarrierOrder.get(objCarrierOrder.Id).Benefit_Types__c ||
				objCarrierOrder.RecordType != map_OldCarrierOrder.get(objCarrierOrder.Id).RecordType))
			) {
				String strUniqueIdField = objCarrierOrder.Benefit_Order__c + '-' + objCarrierOrder.carrier__c;
				if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_NEW_PLAN || objCarrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_CHANGE) {
					if (objCarrierOrder.Benefit_Types__c != null && (objCarrierOrder.Benefit_Types__c.contains('HSA') || objCarrierOrder.Benefit_Types__c.contains('Commuter'))) {
						strUniqueIdField += '-InitialTadaSetup';
					}
				} else if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_RENEWAL) {
					if (objCarrierOrder.Order_Type__c != null && (!objCarrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') && objCarrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup'))) {
						strUniqueIdField += '-InitialTadaSetup';
					}
				}
				objCarrierOrder.Unique_Id__c = strUniqueIdField;
			}
		}
	}

	// Populate the order Assignment on change of Order Type
	public void populateOrderAssignementOnChangeOfType(List<Carrier_Order__c> list_NewCarrierOrder, Map<id, Carrier_Order__c> map_OldCarrierOrder, Boolean blnIsInsert) {
		CarrierOrderHelperFunctions objCOUtilClass = new CarrierOrderHelperFunctions();

		for (Carrier_Order__c objCarrierOrder : list_NewCarrierOrder) {
			if (
				!blnIsInsert &&
				objCarrierOrder.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR &&
				String.isNotBlank(objCarrierOrder.Order_Type__c) &&
				map_OldCarrierOrder != null &&
				objCarrierOrder.Order_Type__c != map_OldCarrierOrder.get(objCarrierOrder.id).Order_Type__c
			) {
				objCarrierOrder.Order_Assignment__c = objCOUtilClass.calculateOrderAssignmentForCO(objCarrierOrder);
			} else if (
				blnIsInsert &&
				objCarrierOrder.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR &&
				String.isNotBlank(objCarrierOrder.Order_Type__c) &&
				String.isBlank(objCarrierOrder.Order_Assignment__c)
			) {
				objCarrierOrder.Order_Assignment__c = objCOUtilClass.calculateOrderAssignmentForCO(objCarrierOrder);
			}
		}
	}

	public void cacheData(list<Carrier_Order__c> newCarrierOrderList) {
		Set<Id> boIdSet = new Set<Id>();
		Set<Id> set_Carriers = new Set<Id>();

		for (Carrier_Order__c ord : newCarrierOrderList) {
			if (ord.Benefit_Order__c != null) {
				boIdSet.add(ord.Benefit_Order__c);
			}
			if (ord.Carrier__c != null) {
				set_Carriers.add(ord.Carrier__c);
			}
		}
		benefitOrderMap = new Map<Id, Benefit_Order__c>();
		if (boIdSet.size() > 0) {
			benefitOrderMap = CarrierOrderHelperFunctions.getBenefitOrdersById(boIdSet);
		}
		map_Carrier = new Map<Id, Carrier__c>();
		if (set_Carriers.size() > 0) {
			map_Carrier = CarrierOrderHelperFunctions.getCarrierById(set_Carriers);
		}
	}

	/*
PB: [Carrier Order] Status handler
BY: PR
date: April 5, 2018
*/

	public static void processCases(list<Carrier_Order__c> newCOList) {
		if (newCOList.size() > 0) {
			map<id, Benefit_Order__c> carrierOrderBoMap = new Map<id, Benefit_Order__c>();
			set<Id> boIdsSet = new Set<Id>();
			//Written by AKS dated 21st Sept 2020 to get updated value
			Set<Id> set_COId = new Set<Id>();
			for (Carrier_Order__c co : newCOList) {
				if (co.Benefit_Order__c != null) {
					boIdsSet.add(co.Benefit_Order__c);
					//It should not execute for non BOR
					if (co.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
						set_COId.add(co.id);
					}
				}
			}
			list<Case> insertCORelatedCases = new List<Case>();

			if (!boIdsSet.isEmpty()) {
				for (Benefit_Order__c bo : benefitOrderMap.values()) {
					carrierOrderBoMap.put(bo.Id, bo);
				}
				Map<Id, String> map_COGroupNumber = new Map<Id, String>();
				//get Updated value from carrier order after Policy processing
				if (set_COId != null && set_COId.size() > 0) {
					for (Carrier_Order__c co : [SELECT id, Group_Number__c FROM Carrier_Order__c WHERE id IN :set_COId AND Group_Number__c != NULL FOR UPDATE]) {
						map_COGroupNumber.put(co.id, co.Group_Number__c);
					}
				}

				for (Carrier_Order__c co : newCOList) {
					if (co.Order_Type__c == 'TAdA: Pre OE Setup' || co.Order_Type__c == 'TAdA: No Pre OE Setup' || co.Order_Type__c == 'Terminated Order') {
						continue;
					}

					//BY:PR, Date: Jan/27/2019, Desc: We want to skip creation of Case for Tada Carrier Order
					if (
						co.recordTypeId == CarrierOrderUtil.REC_TYPE_BOR &&
						co.Carrier__c != null &&
						!map_Carrier.isEmpty() &&
						co.Carrier__c != null &&
						map_Carrier.containsKey(co.Carrier__c) &&
						map_Carrier.get(co.Carrier__c).Partner_Type__c != null &&
						map_Carrier.get(co.Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA
					) {
						continue;
					}

					Case coCase = new Case(Status = 'Open', Priority = 'Medium', Origin = 'Hippo', Carrier_Order__c = co.Id);
					if (co.OwnerId != null)
						coCase.OwnerId = co.OwnerId;
					if (carrierOrderBoMap.containsKey(co.Benefit_Order__c)) {
						Benefit_Order__c objBenefitOrder = carrierOrderBoMap.get(co.Benefit_Order__c);
						if (objBenefitOrder.Cases__r.Size() > 0) {
							coCase.ParentId = objBenefitOrder.Cases__r[0].Id;
						}
						coCase.Benefit_Order__c = co.Benefit_Order__c;
						// align carrier order's cases to Opp and account
						coCase.AccountId = objBenefitOrder.Account__c;
						coCase.Opportunity__c = objBenefitOrder.Opportunity__c;
					}
					coCase.Type = 'Carrier Submission';
					string strCOGroupNumber = '';
					//if it is multiple value then get one
					if (map_COGroupNumber != null && map_COGroupNumber.size() > 0 && map_COGroupNumber.containsKey(co.id) && String.isNotBlank(map_COGroupNumber.get(co.id))) {
						if (map_COGroupNumber.get(co.id).contains(';'))
							strCOGroupNumber = map_COGroupNumber.get(co.id).split(';')[0];
						else
							strCOGroupNumber = map_COGroupNumber.get(co.id);
					}

					if (String.isNotBlank(strCOGroupNumber)) {
						coCase.Group_Number__c = strCOGroupNumber;
					}

					coCase.Subject = co.Name;
					if (carrierOrderBoMap.containsKey(co.Benefit_Order__c)) {
						if (carrierOrderBoMap.get(co.Benefit_Order__c).recordType.Name == 'New Plan') {
							coCase.recordTypeId = CaseUtils.RECTYPE_NEW_PLAN;
						} else if (carrierOrderBoMap.get(co.Benefit_Order__c).recordType.Name == 'Renewal') {
							coCase.recordTypeId = CaseUtils.RECTYPE_RENEWAL;
						} else if (carrierOrderBoMap.get(co.Benefit_Order__c).recordType.Name == 'Change') {
							coCase.recordTypeId = CaseUtils.RECTYPE_CHANGE;
						} else if (carrierOrderBoMap.get(co.Benefit_Order__c).recordType.Name == 'Benefits BoR') {
							//Lirik - Migration for BOR to BO -- Start ---
							coCase.recordTypeId = CaseUtils.RECTYPE_BOR;
							coCase.Type = 'Benefits BOR Carrier Case';
						} //Lirik - Migration for BOR to BO -- End ---
					}
					insertCORelatedCases.add(coCase);
				}
			}

			if (insertCORelatedCases.size() > 0) {
				try {
					Boolean blnCaseTriggerFlag = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;

					if (!BenefitOrderHelper.list_CaseToUpserts.isEmpty()) {
						BenefitOrderHelper.list_CaseToUpserts.addAll(insertCORelatedCases);
						upsert BenefitOrderHelper.list_CaseToUpserts;
						blnCaseCreatedFromCO = true;
					} else {
						insert insertCORelatedCases;
					}

					CaseTriggerHelper.skipTrigger = blnCaseTriggerFlag;
				} catch (Exception objEx) {
					ExceptionLogUtil.logException('CarrierOrderTriggerHelper', 'processCases', objEx.getMessage(), objEx.getStackTraceString(), '. line number: ' + objEx.getLineNumber());

					Set<Id> set_COIds = new Set<Id>();
					Boolean blnCaseCreatedOnBO = false;
					if (!BenefitOrderHelper.list_CaseToUpserts.isEmpty()) {
						blnCaseCreatedFromCO = true;
						blnCaseCreatedOnBO = true;
						BenefitOrderHelper.list_CaseToUpserts.clear();
					}

					for (Case objCase : insertCORelatedCases) {
						if (objCase.Carrier_Order__c != null) {
							set_COIds.add(objCase.Carrier_Order__c);
						}
					}

					if (set_COIds.size() > 0 && !blnReprocessCases && !System.isFuture() && !System.isBatch()) {
						reProcessCases(set_COIds, blnCaseCreatedOnBO);
					}
				}
			}
		}
	}

	/*
PB: [Carrier Order] Status handler
BY: PR
date: April 5, 2018
*/
	public void coStatusHandler(list<Carrier_Order__c> newCOList, map<id, Carrier_Order__c> oldCOMap) {
		List<Carrier_Order__c> list_AuditOrders = new List<Carrier_Order__c>();
		Map<Id, Id> map_COIdWithBOId = new Map<Id, Id>();
		if (newCOList != null && newCOList.size() > 0) {
			for (Carrier_Order__c newCO : newCOList) {
				Carrier_Order__c oldCO;
				if (oldCOMap != null && oldCOMap.keyset().size() > 0 && oldCOMap.containsKey(newCO.id)) {
					oldCO = oldCOMap.get(newCO.id);
				}

				if (oldCO != null && oldCO.id != null) {
					if (
						oldCO.Implementation_Stage__c != newCO.Implementation_Stage__c &&
						(oldCO.Implementation_Stage__c == 'Approved' ||
						oldCO.Implementation_Stage__c == 'Canceled' ||
						oldCO.Implementation_Stage__c == 'Closed Lost' ||
						oldCO.Implementation_Stage__c == 'Closed Admin')
					) {
						newCO.End_Date__c = null;
					}
					//Update code by AKS dated 30th Sept 2019 Update field Approved Pending EE Audit Date when Stage  is get change from Approved Pending EE Audit to anything else
					if (newCO.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR && oldCO.Implementation_Stage__c != newCO.Implementation_Stage__c) {
						if (oldCO.Implementation_Stage__c == 'Approved Pending EE Audit' && newCO.Implementation_Stage__c != 'Approved') {
							newCO.Approved_Pending_EE_Audit_Date__c = null;
						}
						/*
						 *@Neha, August 14, 2020 : For sending partial/approval emails to customers for Approved Carrier Orders.
						 */
						if (
							newCO.Carrier__c != Label.BASIC_Carrier &&
							!map_Carrier.isEmpty() &&
							newCO.Carrier__c != null &&
							map_Carrier.containsKey(newCO.Carrier__c) &&
							(map_Carrier.get(newCO.Carrier__c).Partner_Type__c == null ||
							map_Carrier.get(newCO.Carrier__c).Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA) &&
							(newCO.Implementation_Stage__c == 'Approved Pending EE Audit' ||
							newCO.Implementation_Stage__c == 'Approved')
						) {
							map_COIdWithBOId.put(newCO.Id, newCO.Benefit_Order__c);
						}
					}
				}

				if (
					newCO.Implementation_Stage__c == 'Approved' ||
					newCO.Implementation_Stage__c == 'Canceled' ||
					newCO.Implementation_Stage__c == 'Closed Lost' ||
					newCO.Implementation_Stage__c == 'Closed Admin'
				) {
					if (newCO.End_Date__c == null) {
						newCO.End_Date__c = System.now();
					}
				}
				//Update code by AKS dated 30th Sept 2019 Update field Approved Pending EE Audit Date when Stage is Approved Pending EE Audit
				if (newCO.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR && newCO.Implementation_Stage__c == 'Approved Pending EE Audit' && newCO.Approved_Pending_EE_Audit_Date__c == null) {
					newCO.Approved_Pending_EE_Audit_Date__c = system.today();
					list_AuditOrders.add(newCO);
				}
				//By AKS dated - 30th Sept 2020 https://app.asana.com/0/1195411211351298/1195220590060833
				if (oldCO != null && oldCO.id != null) {
					//For Confirmation Owner
					Set<string> set_ConfirmationStage = new Set<string>{ 'Approved', 'Approved Pending EE Audit' };
					if (
						newCO.Initial_Confirmation_Owner__c == null &&
						newCO.Implementation_Stage__c != null &&
						set_ConfirmationStage.contains(newCO.Implementation_Stage__c) &&
						oldCO.Implementation_Stage__c == 'Pending Confirmation'
					) {
						newCO.Initial_Confirmation_Owner__c = UserInfo.getUserId();
					}
					//For Audit Owner
					if (
						newCO.Initial_Audit_Owner__c == null &&
						newCO.Implementation_Stage__c != null &&
						newCO.Implementation_Stage__c == 'Approved' &&
						oldCO.Implementation_Stage__c == 'Approved Pending EE Audit'
					) {
						newCO.Initial_Audit_Owner__c = UserInfo.getUserId();
					}
				}
			}
			if (!list_AuditOrders.isEmpty()) {
				OnboardingPlayModeUtility.setFirstPlayDateForCarrierOrders('Audit', list_AuditOrders);
			}
			/*
			 *@Neha, August 14, 2020 : For sending partial/approval emails to customers for Approved Carrier Orders.
			 */
			if (!map_COIdWithBOId.isEmpty()) {
				OEEmailAutomationHelper.checkOEStatusForBenefitOrder(map_COIdWithBOId);
			}
		}
	}

	/*
PB: Track Carrier Order Stage Change
BY: PR
Date: April 9, 2018
*/
	public void createCarrierOrderStageHistory(list<Carrier_Order__c> newCOList, map<id, Carrier_Order__c> oldCOMap) {
		list<Carrier_Order_Stage_History__c> toInsertCOStageHistoryList = new List<Carrier_Order_Stage_History__c>();

		for (Carrier_Order__c newCO : newCOList) {
			Carrier_Order__c oldCO;
			if (oldCOMap != null && oldCOMap.containsKey(newCO.id)) {
				oldCO = oldCOMap.get(newCO.id);
			}

			if (oldCO != null && oldCO.id != null && oldCO.Implementation_Stage__c != newCO.Implementation_Stage__c && newCO.stage_TimeStamp__c != null) {
				Carrier_Order_Stage_History__c coStageRec = new Carrier_Order_Stage_History__c();
				coStageRec.Carrier_Order__c = newCO.id;
				coStageRec.End_Time__c = system.now();
				coStageRec.From_Stage__c = oldCO.Implementation_Stage__c;
				coStageRec.Start_Time__c = newCO.stage_TimeStamp__c;
				coStageRec.To_Stage__c = newCO.Implementation_Stage__c;
				toInsertCOStageHistoryList.add(coStageRec);
			}

			if (oldCO != null && oldCO.id != null && oldCO.Implementation_Stage__c != newCO.Implementation_Stage__c) {
				newCO.stage_TimeStamp__c = system.now();
			}
		}

		if (toInsertCOStageHistoryList.size() > 0 || test.isRunningTest()) {
			historyCreated = true;

			Map<String, String> errorOppMap = Utils.doDMLAndReturnAllErrors(
				'Insert', // type of DML operation
				'Carrier_Order__c', // Return map key
				toInsertCOStageHistoryList, // sObject list
				false, // all or none flag
				true, // log the error
				'CarrierOrderTriggerHelper-createCarrierOrderStageHistory'
			);

			for (Carrier_Order__c coOrder : newCOList) {
				if (errorOppMap.containsKey(coOrder.Id)) {
					coOrder.addError(errorOppMap.get(coOrder.Id));
				}
			}
		}
	}

	/*
PB: Carrier Operations/ Sync Selected Opportuntiy Policies to Carrier Order
By: PR
Date: April 9, 2017
*/
	public void syncSelectedOppPoliciesWithCarrierOrder(list<Carrier_Order__c> newCOList) {
		set<id> boIdSet = new Set<id>();
		set<id> carrierIdSet = new Set<id>();
		map<id, id> boIdOppIdMap = new Map<id, id>();
		list<Policy__c> toUpdatePoliciesList = new List<Policy__c>();

		for (Carrier_Order__c coRec : newCOList) {
			//DS[16-09-2020]: Policies getting attached to Terminated Orders
			//https://app.asana.com/0/1193021409156758/1191050113283073
			if (coRec.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
				boIdSet.add(coRec.Benefit_Order__c);
				carrierIdSet.add(coRec.Carrier__c);
			}
		}

		if (boIdSet.size() > 0) {
			for (Benefit_Order__c boRec : benefitOrderMap.values()) {
				boIdOppIdMap.put(boRec.id, boRec.Opportunity__c);
			}

			map<id, Opportunity> oppIdRecordMap = new Map<id, Opportunity>(
				[
					SELECT
						id,
						(SELECT Carrier__c, Carrier_Order__c, Opportunity__c, Is_Selected__c FROM Policies__r WHERE Carrier__c IN :carrierIdSet AND Carrier_Order__c = NULL AND Is_Selected__c = TRUE)
					FROM Opportunity
					WHERE Id IN :boIdOppIdMap.values()
				]
			);

			if (oppIdRecordMap != null && oppIdRecordMap.keyset().size() > 0) {
				for (Carrier_Order__c coRec : newCOList) {
					id oppId = boIdOppIdMap.get(coRec.Benefit_Order__c);
					if (oppIdRecordMap.containsKey(oppId) && oppIdRecordMap.get(oppId).Policies__r.size() > 0) {
						toUpdatePoliciesList.addAll(populateCOinPolicies(oppIdRecordMap.get(oppId).Policies__r, coRec));
					}
				}
			}
		}

		if (toUpdatePoliciesList.size() > 0 || test.isRunningTest()) {
			Map<String, String> errorOppMap = Utils.doDMLAndReturnAllErrors(
				'Update', // type of DML operation
				'Carrier__c', // Return map key
				toUpdatePoliciesList, // sObject list
				false, // all or none flag
				true, // log the error
				'CarrierOrderTriggerHelper-syncSelectedOppPoliciesWithCarrierOrder'
			);

			for (Carrier_Order__c coOrder : newCOList) {
				if (errorOppMap.containsKey(coOrder.Carrier__c)) {
					coOrder.addError(errorOppMap.get(coOrder.Carrier__c));
				}
			}
		}
	}

	/*
PB: Carrier Operations/ Sync Selected Opportuntiy Policies to Carrier Order
By: PR
Date: April 9, 2017
*/
	public list<Policy__c> populateCOinPolicies(list<Policy__c> policyList, Carrier_Order__c coRec) {
		list<Policy__c> toReturnPolicyList = new List<Policy__c>();

		if (policyList == null || policyList.isempty() || coRec == null) {
			return null;
		}

		for (Policy__c pRec : policyList) {
			//DS[16-09-2020]: Policies getting attached to Terminated Orders
			//https://app.asana.com/0/1193021409156758/1191050113283073
			if (pRec.Carrier_Order__c == null && pRec.Carrier__c == coRec.Carrier__c && pRec.Is_Selected__c && coRec.Order_Type__c != 'Terminated Order') {
				pRec.Carrier_Order__c = coRec.id;
				toReturnPolicyList.add(pRec);
			}
		}

		return toReturnPolicyList;
	}

	/*BY:PR, Date: Oct-8-2020, Desc:sets submission deadline. modified  to receive sobject as a parameter as this method can
	 receive both "carrier" and "carrier version details" object recoords*/
	private void calculateBeforeMonthDate(sObject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/**
Updated by:-Deepika Saini
Reason:- New Requirment New Plan Variation should be changed (for tada)
For TAdA: Pre OE Setup:- New_Plan_Variation_Num1__c is used
For TAdA: No Pre OE Setup:- New_Plan_Variation_Num2__c is used
*/
		if (carrierOrder.Special_Enrollment__c == true) {
			carrierOrder = setSubmissionDatesAsEnrollmentDate(carrierOrder);
		} else if (
			objCarrierDetails.get(CarrierOrderUtil.NEW_PLAN_VARIATION_NUM_1) != null &&
			carrierOrder.Order_Type__c != null &&
			carrierOrder.Order_Type__c.contains(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
		) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				//always go to before month and create a new date
				Date newEffectiveDate = effectiveDate.addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			} else {
				// for before alws assume effective date to start from 1st of every month
				Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			}
		} else if (objCarrierDetails.get('New_Plan_Variation_Num2__c') != null && carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				//always go to before month and create a new date
				Date newEffectiveDate = effectiveDate.addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
			} else {
				// for before alws assume effective date to start from 1st of every month
				Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
			}
		} else if (objCarrierDetails.get('New_Plan_Variation_Num2__c') == null) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				//always go to before month and create a new date
				Date newEffectiveDate = effectiveDate.addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			} else {
				// for before alws assume effective date to start from 1st of every month
				Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			}
		} else {
			//we have a variation
			if (effectiveday == 1) {
				//always go to before month and create a new date
				//assuming alws last day of month, 1st date -1 = 30 or 31
				if (objCarrierDetails.get('New_Plan_Variation_Num1__c') == 1) {
					Date newEffectiveDate = effectiveDate.addDays(-1);
					carrierOrder.Submission_Deadline__c = newEffectiveDate;
				} else {
					Date newEffectiveDate = effectiveDate.addMonths(-1);
					carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
				}
			} else {
				// for before alws assume effective date to start from 1st of every month
				//Date newEffectiveDate = effectiveDate.toStartOfMonth();
				//check if its needed to be same month or previous based on num2 val
				if (objCarrierDetails.get('New_Plan_Variation_Num2__c') != null && Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')) < 15) {
					carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
				} else {
					Date newEffectiveDate = effectiveDate.addMonths(-1);
					carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
				}
			}
		}
	}

	//Sets submission deadline
	private void calculateAfterMonthDate(sobject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/**
Updated by:-Deepika Saini
Reason:- New Requirment New Plan Variation should be changed (for tada)
For TAdA: Pre OE Setup:- New_Plan_Variation_Num1__c is used
For TAdA: No Pre OE Setup:- New_Plan_Variation_Num2__c is used
*/
		if (carrierOrder.Special_Enrollment__c == true) {
			carrierOrder = setSubmissionDatesAsEnrollmentDate(carrierOrder);
		} else if (
			objCarrierDetails.get(CarrierOrderUtil.NEW_PLAN_VARIATION_NUM_1) != null &&
			carrierOrder.Order_Type__c != null &&
			carrierOrder.Order_Type__c.contains(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP)
		) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			} else {
				Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			}
		} else if (objCarrierDetails.get('New_Plan_Variation_Num2__c') != null && carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
			} else {
				//for after go to next month and add
				Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
			}
		} else if (objCarrierDetails.get('New_Plan_Variation_Num2__c') == null) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			} else {
				//for after go to next month and add
				Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
				carrierOrder.Submission_Deadline__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			}
		} else {
			//we have a variation and its always after in same month.lets have different if we will remove later
			if (effectiveday == 1) {
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
			} else {
				carrierOrder.Submission_Deadline__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
			}
		}
	}

	//validated
	public void populateSubmissionDate(list<Carrier_Order__c> newCOList, map<id, Carrier_Order__c> oldCOMap) {
		set<string> carrierIdSet = new Set<string>();
		set<string> benefitOrderIdSet = new Set<string>();
		//BY:PR, Date:Sep/21/2020, Desc: Related to: Consider "Carrier Version Details" object if present, in case record is not present consider "Carrier" record functionality
		set<string> set_OpportunityIds = new Set<string>();
		//BY:PR, Date:Sep/21/2020, Desc: Related to: Consider "Carrier Version Details" object if present, in case record is not present consider "Carrier" record functionality
		map<Id, Date> map_CarrierOrderIdEffectiveDate = new Map<Id, Date>();
		//getting the carrier and opportunity ids from the "carrier order" records
		for (Carrier_Order__c carrierOrder : newCOList) {
			if (
				Trigger.isUpdate &&
				oldCOMap != null &&
				oldCOMap.containsKey(carrierOrder.Id) &&
				(carrierOrder.carrier__c != oldCOMap.get(carrierOrder.Id).carrier__c ||
				carrierOrder.Effective_Date_Changed_on__c != oldCOMap.get(carrierOrder.Id).Effective_Date_Changed_on__c ||
				(carrierOrder.recordTypeId == CarrierOrderUtil.REC_TYPE_BOR &&
				carrierOrder.Renewal_Date__c != oldCOMap.get(carrierOrder.Id).Renewal_Date__c) ||
				(!list_CarrierIdsFromFlow.isEmpty() && list_CarrierIdsFromFlow.contains(carrierOrder.Id))) &&
				carrierOrder.Carrier__c != null
			) {
				carrierIdSet.add(carrierOrder.Carrier__c);
			} else if (oldCOMap == null && carrierOrder.Carrier__c != null) {
				//BY:PR, Date:oct-15-2020, Desc: We are populating this field while we are creating CO records in case CO is of "special enrollment" type
				if (
					benefitOrderMap != null &&
					benefitOrderMap.size() > 0 &&
					benefitOrderMap.containsKey(carrierOrder.Benefit_Order__c) &&
					benefitOrderMap.get(carrierOrder.Benefit_Order__c).Special_Enrollment__c == true &&
					carrierOrder.submission_deadline__c != null
				) {
					continue;
				}
				carrierIdSet.add(carrierOrder.Carrier__c);
			}
			//in insert we will not get effective date as its a formula field
			if (carrierOrder.Benefit_Order__c != null)
				benefitOrderIdSet.add(carrierOrder.Benefit_Order__c);

			//BY:PR, Date:Sep/21/2020 ,Desc: maintains Carrier and related Carrier Order relation
			if (
				benefitOrderMap != null &&
				benefitOrderMap.size() > 0 &&
				benefitOrderMap.containsKey(carrierOrder.Benefit_Order__c) &&
				benefitOrderMap.get(carrierOrder.Benefit_Order__c).Opportunity__c != null
			) {
				map_CarrierOrderIdEffectiveDate.put(carrierOrder.Id, benefitOrderMap.get(carrierOrder.Benefit_Order__c).Opportunity__r.HI_Effective_Date__c);
				set_OpportunityIds.add(benefitOrderMap.get(carrierOrder.Benefit_Order__c).Opportunity__c);
			}
		}

		//get rules make map
		if (carrierIdSet.size() > 0) {
			//BY:PR, Date:Sep/21/2020
			map<Id, Carrier__c> map_carrierRecord = new Map<Id, Carrier__c>();
			map<String, Date> map_CarrierIdCOEffMap = new Map<String, Date>();

			for (Carrier__c objCar : [
				SELECT
					Id,
					New_Plan_Submission_Event__c,
					New_Plan_Variation_Num1__c,
					Id__c,
					New_Plan_Variation_Num2__c,
					Group_Submission_Event__c,
					Group_Variation_Number__c,
					Group_Variation_Number_2__c,
					Member_Submission_Event__c,
					Member_Variation_Number__c,
					Member_Variation_Number_2__c
				FROM Carrier__c
				WHERE Id IN :carrierIdSet
			]) {
				map_carrierRecord.put(objCar.Id, objCar);
			}

			if (benefitOrderMap != null && benefitOrderMap.size() > 0) {
				//BY:PR, Date:Sep/21/2020
				for (Carrier_Order__c objCarrierOrder : newCOList) {
					Id idCarrier = objCarrierOrder.Carrier__c;
					if (map_carrierRecord.containsKey(idCarrier) && map_carrierRecord.get(idCarrier).Id__c != null && map_CarrierOrderIdEffectiveDate.containsKey(objCarrierOrder.Id)) {
						map_CarrierIdCOEffMap.put(map_carrierRecord.get(idCarrier).Id__c, map_CarrierOrderIdEffectiveDate.get(objCarrierOrder.Id));
					}
				}

				//BY:PR, Date:Sep/21/2020
				Map<String, Carrier_Version_Detail__c> map_CarrierVersion;
				if (!map_CarrierIdCOEffMap.isEmpty()) {
					map_CarrierVersion = Utils.getCarrierVersion(map_CarrierIdCOEffMap);
				}

				//DS:[06-11-2019] Solving 101 Query
				List<BusinessHours> listBusinessHours = new List<BusinessHours>{ GlobalQueryHelper.getDefaultBusinessHour() };
				for (Carrier_Order__c carrierOrder : newCOList) {
					//BY:PR, Date:oct-15-2020, Desc: We are populating this field while we are creating CO records in case CO is of "special enrollment" type
					if (carrierOrder.Submission_Deadline__c != null && oldCOMap == null && !blnUpdateSubmissionDeadlineDates) {
						continue;
					}

					//BY:PR, Date:Sep/21/2020
					string strCarrierExternalId = '';
					if (map_carrierRecord.containsKey(carrierOrder.Carrier__c) && map_carrierRecord.get(carrierOrder.Carrier__c).Id__c != null) {
						strCarrierExternalId = map_carrierRecord.get(carrierOrder.Carrier__c).Id__c;
					}

					if (
						benefitOrderMap.containskey(carrierOrder.Benefit_Order__c) &&
						((string.isNotBlank(strCarrierExternalId) && map_CarrierVersion != null && map_CarrierVersion.containskey(strCarrierExternalId)) ||
						(map_carrierRecord != null && map_carrierRecord.containsKey(carrierOrder.Carrier__c)))
					) {
						//calculate submission date as per rules on before insert before update
						Benefit_Order__c benefitOrder = benefitOrderMap.get(carrierOrder.Benefit_Order__c);
						SObject objCarrierDetails;
						Carrier_Version_Detail__c carrierRule = strCarrierExternalId != null && map_CarrierVersion != null ? map_CarrierVersion.get(strCarrierExternalId) : null;
						Carrier__c objCarrier = map_carrierRecord.get(carrierOrder.Carrier__c);
						if (carrierRule != null) {
							objCarrierDetails = carrierRule;
							populateSubmissionStartDate(carrierOrder, carrierRule, benefitOrder);
						} else {
							if (
								carrierOrder.Special_Enrollment__c == false && (carrierOrder.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES) ||
								(carrierOrder.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES)
							) {
								carrierOrder.Submission_Deadline_Start_Date__c = null;
							}
							objCarrierDetails = objCarrier;
						}

						/*Akash
Method to calculate group submission dates and member submission dates for record type of CO as Renewal or Benefit Change
Date- March 1 2019
*/
						if (carrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_RENEWAL || carrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_CHANGE) {
							//to update termination submission date, fetch coverageeffectivedate from opp, calculate with Term Submission Event and Term Variation Number in carrier
							if (
								carrierOrder.Order_Type__c != 'Terminated Order' &&
								(carrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_RENEWAL ||
								carrierOrder.RecordTypeId == CarrierOrderUtil.RECTYPE_CHANGE)
							) {
								if (carrierOrder.Special_Enrollment__c == true) {
									carrierOrder = setSubmissionDatesAsEnrollmentDate(carrierOrder);
									continue;
								}

								// remove Tada: pre oe setup
								updateSubDateForRenewalAndChange(listBusinessHours, carrierOrder, benefitOrder, objCarrierDetails);

								if (objCarrierDetails != null) {
									if (
										objCarrierDetails.get('New_Plan_Submission_Event__c') != null && string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('same')
									) {
										carrierOrder.Submission_Deadline__c = checkDate(benefitOrder.Coverage_Effective_Date__c);
										continue;
									}
									if (
										objCarrierDetails.get('New_Plan_Submission_Event__c') != null &&
										objCarrierDetails.get('New_Plan_Variation_Num1__c') != null &&
										benefitOrder.Coverage_Effective_Date__c != null
									) {
										Date effectiveDate = benefitOrder.Coverage_Effective_Date__c;
										Integer effectiveday = effectiveDate.day();
										if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
											calculateBeforeMonthDate(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
											carrierOrder.Submission_Deadline__c = checkDate(carrierOrder.Submission_Deadline__c);
											continue;
										}
										if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('After Month')) {
											calculateAfterMonthDate(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
											carrierOrder.Submission_Deadline__c = checkDate(carrierOrder.Submission_Deadline__c);
											continue;
										}
										if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
											/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
											Date businessDate;
											if (
												carrierOrder.Order_Type__c != null &&
												carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') &&
												objCarrierDetails.get('New_Plan_Variation_Num1__c') != null
											) {
												businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num1__c)) * 8 * 60 * 60 * 1000L);
											} else if (
												carrierOrder.Order_Type__c != null &&
												carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') &&
												objCarrierDetails.get('New_Plan_Variation_Num2__c') != null
											) {
												businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num2__c)) * 8 * 60 * 60 * 1000L);
											} else {
												businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num1__c)) * 8 * 60 * 60 * 1000L);
											}
											if (businessDate != null) {
												carrierOrder.Submission_Deadline__c = checkDate(businessDate);
											}
											continue;
										}
										if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('After Days')) {
											/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
											Date businessDate;
											if (
												carrierOrder.Order_Type__c != null &&
												carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') &&
												objCarrierDetails.get('New_Plan_Variation_Num1__c') != null
											) {
												businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num1__c)) * 8 * 60 * 60 * 1000L);
											} else if (
												carrierOrder.Order_Type__c != null &&
												carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') &&
												objCarrierDetails.get('New_Plan_Variation_Num2__c') != null
											) {
												businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num2__c)) * 8 * 60 * 60 * 1000L);
											} else {
												businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
												//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num1__c)) * 8 * 60 * 60 * 1000L);
											}
											if (businessDate != null) {
												carrierOrder.Submission_Deadline__c = checkDate(businessDate);
											}
											continue;
										}
									}
								}
							}
						} else if (carrierOrder.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR) {
							if (carrierOrder.Special_Enrollment__c == true) {
								carrierOrder = setSubmissionDatesAsEnrollmentDate(carrierOrder);
								continue;
							}
							if (objCarrierDetails != null) {
								updateGroupMemeberVariables(objCarrierDetails);
							}

							if (objCarrierDetails.get('Group_Submission_Event__c') != null && string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('same')) {
								carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Renewal_Date__c);
								continue;
							}
							if (objCarrierDetails.get('Group_Submission_Event__c') != null && objCarrierDetails.get(strGroupVarNum1ApiName) != null && carrierOrder.Renewal_Date__c != null) {
								Date effectiveDate = carrierOrder.Renewal_Date__c;
								Integer effectiveday = effectiveDate.day();
								if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
									calBeforeMonthDateForGroupSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
									carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('After Month')) {
									calAfterMonthDateForGroupSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
									carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
									/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
									Date businessDate;
									if (objCarrierDetails.get(strGroupVarNum2ApiName) != null && carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')) {
										businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName)));
										//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num2__c)) * 8 * 60 * 60 * 1000L);
									} else {
										businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
										//businessDate = BusinessHours.add(listBusinessHours[0].id, effectiveDateDateTime, -(Integer.valueOf(carrierRule.New_Plan_Variation_Num1__c)) * 8 * 60 * 60 * 1000L);
									}

									if (businessDate != null) {
										carrierOrder.Group_Submission_Date__c = checkDate(businessDate);
									}
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('After Days')) {
									/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
									Date businessDate;
									if (objCarrierDetails.get(strGroupVarNum2ApiName) != null && carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')) {
										businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName)));
									} else {
										businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
									}
									if (businessDate != null) {
										carrierOrder.Group_Submission_Date__c = checkDate(businessDate);
									}
									continue;
								}
							}
						} else {
							if (carrierOrder.Special_Enrollment__c == true) {
								carrierOrder = setSubmissionDatesAsEnrollmentDate(carrierOrder);
								continue;
							}

							if (objCarrierDetails.get('New_Plan_Submission_Event__c') != null && string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('same')) {
								carrierOrder.Submission_Deadline__c = checkDate(benefitOrder.Coverage_Effective_Date__c);
								continue;
							}
							if (
								objCarrierDetails.get('New_Plan_Submission_Event__c') != null &&
								objCarrierDetails.get('New_Plan_Variation_Num1__c') != null &&
								benefitOrder.Coverage_Effective_Date__c != null
							) {
								Date effectiveDate = benefitOrder.Coverage_Effective_Date__c;
								Integer effectiveday = effectiveDate.day();
								if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
									calculateBeforeMonthDate(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
									carrierOrder.Submission_Deadline__c = checkDate(carrierOrder.Submission_Deadline__c);
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('After Month')) {
									calculateAfterMonthDate(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
									carrierOrder.Submission_Deadline__c = checkDate(carrierOrder.Submission_Deadline__c);
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
									/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
									Date businessDate;
									if (
										objCarrierDetails.get('New_Plan_Variation_Num2__c') != null &&
										carrierOrder.Order_Type__c != null &&
										carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')
									) {
										businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
									} else {
										businessDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
									}
									if (businessDate != null) {
										carrierOrder.Submission_Deadline__c = checkDate(businessDate);
									}
									continue;
								}
								if (string.valueOf(objCarrierDetails.get('New_Plan_Submission_Event__c')).equalsIgnoreCase('After Days')) {
									/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the New plan variation num 2
*/
									Date businessDate;
									if (
										objCarrierDetails.get('New_Plan_Variation_Num2__c') != null &&
										carrierOrder.Order_Type__c != null &&
										carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup')
									) {
										businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num2__c')));
									} else {
										businessDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get('New_Plan_Variation_Num1__c')));
									}
									if (businessDate != null) {
										carrierOrder.Submission_Deadline__c = checkDate(businessDate);
									}
									continue;
								}
							}
						} // end of else
					}
				}
			}
		}

		//BY:PR, Date: oct-19-20, Desc: moved in the end after the submission deadline date logic has run its course
		for (Carrier_Order__c objCO : newCOList) {
			//BY:PR, Desc: sync two field values
			if (objCO.Special_Enrollment__c == true) {
				objCO.Submission_Deadline_Start_Date__c = dtSpecial_Enrollment_Start_Date;
			} else if (
				objCO.Special_Enrollment__c == false &&
				objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES &&
				objCO.Order_Type__c != CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES
			) {
				objCO.Submission_Deadline_Start_Date__c = null;
			}
		}
	}

	// -validated
	public void UpdateSubmissionDateOnBenefitOrder(list<Carrier_Order__c> newCarrierOrderList, map<id, Carrier_Order__c> oldCarrierOrderMap) {
		set<id> boIdSet = new Set<id>();
		map<id, Benefit_Order__c> benefitOrderMap = new Map<id, Benefit_Order__c>();
		List<Benefit_Order__c> borToUpdateList = new List<Benefit_Order__c>();
		for (Carrier_Order__c carrierOrder : newCarrierOrderList) {
			if (carrierOrder.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
				if (
					oldCarrierOrderMap == null ||
					(oldCarrierOrderMap != null &&
					oldCarrierOrderMap.containsKey(carrierOrder.Id) &&
					(carrierOrder.carrier__c != oldCarrierOrderMap.get(carrierOrder.Id).carrier__c ||
					carrierOrder.Effective_Date_Changed_on__c != oldCarrierOrderMap.get(carrierOrder.Id).Effective_Date_Changed_on__c ||
					carrierOrder.Submission_Deadline_Date__c != oldCarrierOrderMap.get(carrierOrder.Id).Submission_Deadline_Date__c))
				) {
					boIdSet.add(carrierOrder.Benefit_Order__c);
				}
			}
		}

		if (boIdSet.size() > 0) {
			//Get the Benefit Order with Carrier Order where Submission Deadline Date is not Null and order by Submission Deadline Date
			//Except Carrier Order with Carrier Termination Record Type
			benefitOrderMap = new Map<id, Benefit_Order__c>(
				[
					SELECT
						id,
						Type__c,
						Submission_Deadline__c,
						Account__c,
						Opportunity__c,
						RecordType.Name,
						Effective_Date_Change__c,
						(
							SELECT id, RecordTypeId, Submission_Deadline_Date__c, Effective_Date_Change__c
							FROM Carrier_Orders__r
							WHERE Submission_Deadline_Date__c != NULL
							ORDER BY Submission_Deadline_Date__c
						)
					FROM Benefit_Order__c
					WHERE Id IN :boIdSet
					FOR UPDATE
				]
			);
		}

		for (Id benefitOrderId : benefitOrderMap.keyset()) {
			//Check any carrier order exist then update the Benefit Order's Submission Deadline.
			if (benefitOrderMap.get(benefitOrderId).Carrier_Orders__r.size() > 0) {
				Benefit_Order__c objBO = benefitOrderMap.get(benefitOrderId);
				for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
					if (objCO.Effective_Date_Change__c && !objBO.Effective_Date_Change__c) {
						objBO.Effective_Date_Change__c = true;
					}
				}

				objBO.Submission_Deadline__c = benefitOrderMap.get(benefitOrderId).Carrier_Orders__r[0].Submission_Deadline_Date__c;
				borToUpdateList.add(objBO);
				map_BenefitOrderToUpdate.put(objBO.id, objBO);
			}
		}
	}

	//BY:PR, Date: Oct/1/2020, Desc: field api names which are not common between Carrier__c and Carrier_Version_Detail__c object
	string strGroupVarNum1ApiName = '';
	string strGroupVarNum2ApiName = '';
	string strMemberSubNum1ApiName = '';
	string strMemberSubNum2ApiName = '';

	//BY:PR, Date: Oct/1/2020, Desc: field api names which are not common between Carrier__c and Carrier_Version_Detail__c object
	private void updateGroupMemeberVariables(SObject objCarrierDetails) {
		if (objCarrierDetails != null) {
			if ('Carrier__c'.equalsIgnoreCase(id.valueOf(string.valueOf(objCarrierDetails.get('Id'))).getSObjectType().getDescribe().getName())) {
				strGroupVarNum1ApiName = 'Group_Variation_Number__c';
				strGroupVarNum2ApiName = 'Group_Variation_Number_2__c';
				strMemberSubNum1ApiName = 'Member_Variation_Number__c';
				strMemberSubNum2ApiName = 'Member_Variation_Number_2__c';
			} else {
				strGroupVarNum1ApiName = 'Group_Variation_Number1__c';
				strGroupVarNum2ApiName = 'Group_Variation_Number2__c';
				strMemberSubNum1ApiName = 'Member_Submission_Variation1__c';
				strMemberSubNum2ApiName = 'Member_Submission_Variation2__c';
			}
		}
	}

	// Sets group submission and member submission dates
	private void updateSubDateForRenewalAndChange(List<BusinessHours> listBusinessHours, Carrier_Order__c carrierOrder, Benefit_Order__c benefitOrder, SObject objCarrierDetails) {
		//BY:PR, Date: Oct/1/2020, Desc: field api names which are not common between Carrier__c and Carrier_Version_Detail__c object
		if (objCarrierDetails != null) {
			updateGroupMemeberVariables(objCarrierDetails);
		} else {
			return;
		}

		//Calculating Group Submission Dates
		if (objCarrierDetails.get('Group_Submission_Event__c') != null && string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('same')) {
			carrierOrder.Group_Submission_Date__c = checkDate(benefitOrder.Coverage_Effective_Date__c);
		} else {
			if (objCarrierDetails.get('Group_Submission_Event__c') != null && (objCarrierDetails.get(strGroupVarNum1ApiName) != null || objCarrierDetails.get(strGroupVarNum2ApiName) != null)) {
				Date effectiveDate;
				Integer effectiveday = 0;

				if (benefitOrder.Coverage_Effective_Date__c != null) {
					effectiveDate = benefitOrder.Coverage_Effective_Date__c;
					effectiveday = effectiveDate.day();
				}

				if (effectiveDate != null && effectiveday != null) {
					if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
						calBeforeMonthDateForGroupSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
						carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
					} else if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('After Month')) {
						calAfterMonthDateForGroupSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
						carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
					} else if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
						/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Group variation number 2
*/
						Date newSubDate;
						if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') && objCarrierDetails.get(strGroupVarNum2ApiName) != null) {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName)));
						} else if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') && objCarrierDetails.get(strGroupVarNum1ApiName) != null) {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
						} else {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
						}
						if (newSubDate != null) {
							carrierOrder.Group_Submission_Date__c = newSubDate;
							//Check if the date is a weekend if so push it to the last weekday
							carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
						}
					} else if (string.valueOf(objCarrierDetails.get('Group_Submission_Event__c')).equalsIgnoreCase('After Days')) {
						/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Group variation number 2
*/
						Date newSubDate;
						if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') && objCarrierDetails.get(strGroupVarNum2ApiName) != null) {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName)));
						} else if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') && objCarrierDetails.get(strGroupVarNum1ApiName) != null) {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
						} else {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
						}
						if (newSubDate != null) {
							carrierOrder.Group_Submission_Date__c = newSubDate;
							carrierOrder.Group_Submission_Date__c = checkDate(carrierOrder.Group_Submission_Date__c);
						}
					}
				}
			}
		}

		//Calculating Member Submission Dates
		if (objCarrierDetails.get('Member_Submission_Event__c') != null && string.valueOf(objCarrierDetails.get('Member_Submission_Event__c')).equalsIgnoreCase('same')) {
			carrierOrder.Member_Submission_Date__c = checkDate(benefitOrder.Coverage_Effective_Date__c);
		} else {
			Date effectiveDate;
			Integer effectiveday = 0;
			if (objCarrierDetails.get('Member_Submission_Event__c') != null && (objCarrierDetails.get(strMemberSubNum1ApiName) != null || objCarrierDetails.get(strMemberSubNum2ApiName) != null)) {
				if (benefitOrder.Coverage_Effective_Date__c != null) {
					effectiveDate = benefitOrder.Coverage_Effective_Date__c;
					effectiveday = effectiveDate.day();
				}
				if (effectiveDate != null && effectiveday != null) {
					if (string.valueOf(objCarrierDetails.get('Member_Submission_Event__c')).equalsIgnoreCase('Before Month')) {
						calBeforeMonthDateForMemberSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
						carrierOrder.Member_Submission_Date__c = checkDate(carrierOrder.Member_Submission_Date__c);
					} else if (string.valueOf(objCarrierDetails.get('Member_Submission_Event__c')).equalsIgnoreCase('After Month')) {
						calAfterMonthDateForMemberSubmission(objCarrierDetails, carrierOrder, effectiveday, effectiveDate);
						carrierOrder.Member_Submission_Date__c = checkDate(carrierOrder.Member_Submission_Date__c);
					} else if (string.valueOf(objCarrierDetails.get('Member_Submission_Event__c')).equalsIgnoreCase('Before Days')) {
						/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Member variation number 2
*/
						Date newSubDate;
						if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') && objCarrierDetails.get(strMemberSubNum2ApiName) != null) {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strMemberSubNum2ApiName)));
						} else if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') && objCarrierDetails.get(strMemberSubNum1ApiName) != null) {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
						} else {
							newSubDate = effectiveDate.addDays(-Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
						}
						if (newSubDate != null) {
							carrierOrder.Member_Submission_Date__c = newSubDate;
							carrierOrder.Member_Submission_Date__c = checkDate(carrierOrder.Member_Submission_Date__c);
						}
					} else if (string.valueOf(objCarrierDetails.get('Member_Submission_Event__c')).equalsIgnoreCase('After Days')) {
						/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Member variation number 2
*/
						Date newSubDate;
						if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup') && objCarrierDetails.get(strMemberSubNum2ApiName) != null) {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strMemberSubNum2ApiName)));
						} else if (carrierOrder.Order_Type__c != null && carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') && objCarrierDetails.get(strMemberSubNum1ApiName) != null) {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
						} else {
							newSubDate = effectiveDate.addDays(Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
						}
						if (newSubDate != null) {
							carrierOrder.Member_Submission_Date__c = newSubDate;
							carrierOrder.Member_Submission_Date__c = checkDate(carrierOrder.Member_Submission_Date__c);
						}
					}
				}
			}
		}
	}

	// Sets Group_Submission_Date__c
	private void calBeforeMonthDateForGroupSubmission(SObject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Group variation number 2
*/
		if (
			(objCarrierDetails.get(strGroupVarNum1ApiName) != null ||
			objCarrierDetails.get(strGroupVarNum2ApiName) != null) &&
			carrierOrder.Order_Type__c != null &&
			(carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') || carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup'))
		) {
			Integer intGroupVariationNumber;
			if (carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup')) {
				intGroupVariationNumber = Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName));
			} else {
				intGroupVariationNumber = Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName));
			}
			if (intGroupVariationNumber != null) {
				//check for month for 1st or 15th
				if (effectiveday == 1) {
					//always go to before month and create a new date
					Date newEffectiveDate = effectiveDate.addMonths(-1);
					carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intGroupVariationNumber);
				} else {
					// for before alws assume effective date to start from 1st of every month
					Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
					carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intGroupVariationNumber);
				}
			}
		} else if (objCarrierDetails.get(strGroupVarNum1ApiName) != null) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				//always go to before month and create a new date
				Date newEffectiveDate = effectiveDate.addMonths(-1);
				carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
			} else {
				// for before alws assume effective date to start from 1st of every month
				Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
				carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
			}
		}
	}

	// Sets Group_Submission_Date__c
	private void calAfterMonthDateForGroupSubmission(SObject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Group variation number 2
*/
		if (
			(objCarrierDetails.get(strGroupVarNum1ApiName) != null ||
			objCarrierDetails.get(strGroupVarNum2ApiName) != null) &&
			carrierOrder.Order_Type__c != null &&
			(carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') || carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup'))
		) {
			Integer intGroupVariationNumber;
			if (carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup')) {
				intGroupVariationNumber = Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName));
			} else {
				intGroupVariationNumber = Integer.valueOf(objCarrierDetails.get(strGroupVarNum2ApiName));
			}
			if (intGroupVariationNumber != null) {
				if (effectiveday == 1) {
					carrierOrder.Group_Submission_Date__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), intGroupVariationNumber);
				} else {
					//for after go to next month and add
					Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
					carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intGroupVariationNumber);
				}
			}
		} else if (objCarrierDetails.get(strGroupVarNum1ApiName) != null) {
			if (effectiveday == 1) {
				carrierOrder.Group_Submission_Date__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
			} else {
				//for after go to next month and add
				Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
				carrierOrder.Group_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strGroupVarNum1ApiName)));
			}
		}
	}

	//Sets Member_Submission_Date__c
	private void calBeforeMonthDateForMemberSubmission(SObject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Member variation number 2
*/
		if (
			(objCarrierDetails.get(strMemberSubNum1ApiName) != null ||
			objCarrierDetails.get(strMemberSubNum2ApiName) != null) &&
			carrierOrder.Order_Type__c != null &&
			(carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') || carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup'))
		) {
			Integer intMemberVariationNumber;
			if (carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup')) {
				intMemberVariationNumber = Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName));
			} else {
				intMemberVariationNumber = Integer.valueOf(objCarrierDetails.get(strMemberSubNum2ApiName));
			}
			if (intMemberVariationNumber != null) {
				//check for month for 1st or 15th
				if (effectiveday == 1) {
					//always go to before month and create a new date
					Date newEffectiveDate = effectiveDate.addMonths(-1);
					carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intMemberVariationNumber);
				} else {
					// for before alws assume effective date to start from 1st of every month
					Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
					carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intMemberVariationNumber);
				}
			}
		} else if (objCarrierDetails.get(strMemberSubNum1ApiName) != null) {
			//check for month for 1st or 15th
			if (effectiveday == 1) {
				//always go to before month and create a new date
				Date newEffectiveDate = effectiveDate.addMonths(-1);
				carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
			} else {
				// for before alws assume effective date to start from 1st of every month
				Date newEffectiveDate = effectiveDate.toStartOfMonth().addMonths(-1);
				carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
			}
		}
	}

	// Sets member submission date
	private void calAfterMonthDateForMemberSubmission(SObject objCarrierDetails, Carrier_Order__c carrierOrder, Integer effectiveday, Date effectiveDate) {
		/*
Updated By:- Deepika Saini
Reason:- Add a check for the TAdA: No Pre OE Setup uses the Member variation number 2
*/
		if (
			(objCarrierDetails.get(strMemberSubNum1ApiName) != null ||
			objCarrierDetails.get(strMemberSubNum2ApiName) != null) &&
			carrierOrder.Order_Type__c != null &&
			(carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup') || carrierOrder.Order_Type__c.contains('TAdA: No Pre OE Setup'))
		) {
			Integer intMemberVariationNumber;
			if (carrierOrder.Order_Type__c.contains('TAdA: Pre OE Setup')) {
				intMemberVariationNumber = Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName));
			} else {
				intMemberVariationNumber = Integer.valueOf(objCarrierDetails.get(strMemberSubNum2ApiName));
			}
			if (intMemberVariationNumber != null) {
				if (effectiveday == 1) {
					carrierOrder.Member_Submission_Date__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), intMemberVariationNumber);
				} else {
					//for after go to next month and add
					Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
					carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), intMemberVariationNumber);
				}
			}
		} else if (objCarrierDetails.get(strMemberSubNum1ApiName) != null) {
			if (effectiveday == 1) {
				carrierOrder.Member_Submission_Date__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
			} else {
				//for after go to next month and add
				Date newEffectiveDate = effectiveDate.addMonths(1).toStartOfMonth();
				carrierOrder.Member_Submission_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(objCarrierDetails.get(strMemberSubNum1ApiName)));
			}
		}
	}

	/* - validated
Method to check if date is sat or sun and pushback to last weekday of that week in case date falls on weekend
*/
	public Date checkDate(Date newEffectiveDate) {
		if (newEffectiveDate != null) {
			datetime myDate = datetime.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), newEffectiveDate.day());
			String day = myDate.format('EEEE');
			if (day != null && day.equalsIgnoreCase('Sunday')) {
				newEffectiveDate = newEffectiveDate.addDays(-2);
			} else if (day != null && day.equalsIgnoreCase('Saturday')) {
				newEffectiveDate = newEffectiveDate.addDays(-1);
			}
		}
		return newEffectiveDate;
	}

	/**Created by : Syam Nukilla - validated
Created Date : 3/27/2019
Description : creating QA Lines of Coverage record whenever Carrier order gets created.
**/
	public void CreateQALinesRecordAgainstCO(list<Carrier_Order__c> newCarrierOrderList, Map<Id, Carrier_Order__c> map_OldCarrierOrder) {
		list<QA_Lines_Of_Coverage__c> qaslist = new List<QA_Lines_Of_Coverage__c>();
		Set<Id> set_OppIds = new Set<id>();
		map<id, id> oppidMap = new Map<id, id>();
		map<id, Transition_to_Fulfillment__c> ttfmap = new Map<id, Transition_to_Fulfillment__c>();
		map<string, Policy__c> polmap = new Map<string, Policy__c>();
		map<string, Policy__c> polmapunique = new Map<string, Policy__c>();
		map<string, QA_Sheet__c> qamap = new Map<string, QA_Sheet__c>();
		map<string, Carrier_Order__c> cariermap = new Map<string, Carrier_Order__c>();
		list<id> carriernameList = new List<id>();
		map<string, string> polname = new Map<string, string>();
		set<id> rboid = new Set<id>();
		map<string, Carrier_Order__c> renecarier = new Map<string, Carrier_Order__c>();
		map<string, QA_Sheet__c> rqamap = new Map<string, QA_Sheet__c>();
		set<id> list_savedCarrierOrderIds = new Set<id>();
		Set<id> set_CanceledCarrierOrder = new Set<Id>();

		Boolean blnIsNew = (map_OldCarrierOrder == null);
		for (Carrier_Order__c co : newCarrierOrderList) {
			if (co.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR) {
				continue;
			}

			//if the Carrier Order's implementation stage is canceled
			if (
				map_OldCarrierOrder != null &&
				map_OldCarrierOrder.containsKey(co.Id) &&
				co.Implementation_Stage__c == CarrierOrderUtil.STAGE_CANCELLED &&
				co.Implementation_Stage__c != map_OldCarrierOrder.get(co.id).Implementation_Stage__c
			) {
				set_CanceledCarrierOrder.add(co.Id);
			} else if (co.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED) {
				// if tada, with recordtype change or renewal and carrier is alegus
				if (
					(co.RecordTypeid == CarrierOrderUtil.RECTYPE_RENEWAL ||
					co.RecordTypeid == CarrierOrderUtil.RECTYPE_CHANGE) &&
					!map_Carrier.isEmpty() &&
					co.Carrier__c != null &&
					map_Carrier.containsKey(co.Carrier__c) &&
					map_Carrier.get(co.Carrier__c).Partner_Type__c != null &&
					map_Carrier.get(co.Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA &&
					blnIsNew
				) {
					rboid.add(co.Benefit_Order__c);
					if (co.Benefit_Types__c != null)
						for (string str : co.Benefit_Types__c.split(';')) {
							renecarier.put(co.id + ':' + co.Carrier__c + ':' + str, co);
						}
					list_savedCarrierOrderIds.add(co.id);
				} else {
					if (!blnIsNew) {
						if (
							!map_Carrier.isEmpty() &&
							co.Carrier__c != null &&
							map_Carrier.containsKey(co.Carrier__c) &&
							map_Carrier.get(co.Carrier__c).Partner_Type__c != null &&
							map_Carrier.get(co.Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA
						) {
							continue;
						}
						if (benefitOrderMap != null && benefitOrderMap.containsKey(co.Benefit_Order__c) && benefitOrderMap.get(co.Benefit_Order__c).Opportunity__c != null) {
							set_OppIds.add(benefitOrderMap.get(co.Benefit_Order__c).Opportunity__c);
						}
						carriernameList.add(co.Carrier__c);
						if (co.Benefit_Types__c != null) {
							Benefit_Order__c objBenefitOrder = null;
							if (benefitOrderMap != null && benefitOrderMap.containsKey(co.Benefit_Order__c)) {
								objBenefitOrder = benefitOrderMap.get(co.Benefit_Order__c);
							}

							for (string str : co.Benefit_Types__c.split(';')) {
								str = str != null ? str.trim() : '';
								if (objBenefitOrder != null) {
									cariermap.put(objBenefitOrder.Opportunity__c + ':' + co.Carrier__c + ':' + str, co);
								}
							}
						}
						list_savedCarrierOrderIds.add(co.id);
					}
				}
			}
		}

		if (!set_CanceledCarrierOrder.isEmpty()) {
			delete [SELECT Id FROM QA_Lines_Of_Coverage__c WHERE Carrier_Order__c IN :set_CanceledCarrierOrder];
		}

		if (!list_savedCarrierOrderIds.isEmpty()) {
			Map<String, QA_Lines_Of_Coverage__c> map_Qlc = new Map<String, QA_Lines_Of_Coverage__c>();
			if (set_OppIds != null && set_OppIds.size() > 0) {
				for (QA_Sheet__c objQASheet : [
					SELECT
						Id,
						Name,
						Benefit_Order__c,
						Opportunity__c,
						(SELECT Id, Carrier_Order__c, Lines_Of_Coverage__c, QA_Sheet__r.Opportunity__c, Benefits_selected_Carrier__c FROM QA_Lines_Of_Coverage_del__r)
					FROM QA_Sheet__c
					WHERE Opportunity__c IN :set_OppIds
				]) {
					qamap.put(objQASheet.Benefit_Order__c, objQASheet);
					oppidMap.put(objQASheet.Opportunity__c, objQASheet.Benefit_Order__c);

					for (QA_Lines_Of_Coverage__c objQlc : objQASheet.QA_Lines_Of_Coverage_del__r) {
						map_Qlc.put(
							objQASheet.Opportunity__c +
								';' +
								objQASheet.Id +
								';' +
								(objQlc.Lines_Of_Coverage__c != null ? objQlc.Lines_Of_Coverage__c.toLowerCase() : null) +
								';' +
								objQlc.Benefits_selected_Carrier__c,
							objQlc
						);
					}
				}
			}

			list<Policy__c> policylist = new List<Policy__c>();
			if (carriernameList != null && carriernameList.size() > 0) {
				policylist = [
					SELECT
						Id,
						name,
						Opportunity__r.HI_Effective_Date__c,
						Opportunity__c,
						Carrier__c,
						Coverage_Effective_Date__c,
						Carrier__r.Id__c,
						Carrier__r.Name,
						Benefit_Type__c,
						Contribution_for_EEs__c,
						Contribution_for_Dependents__c,
						Waiting_Period__c,
						Carrier__r.PY_or_CY_Deductible__c,
						Carrier__r.LOA_Required__c,
						Is_Base__c,
						Contribution_Scheme_Type__c
					FROM Policy__c
					WHERE Opportunity__c != NULL AND Opportunity__c IN :oppidMap.keyset() AND Is_Selected__c = TRUE AND Carrier__c != NULL AND Carrier__c IN :carriernameList
				];
			}

			map<String, Date> map_CarrIdpolicyEffMap = new Map<String, Date>();
			if (policylist != null && policylist.size() > 0) {
				for (Policy__c pol : policylist) {
					if (pol.Carrier__r != null && pol.Carrier__r.Id__C != null && pol.Opportunity__r != null && pol.Opportunity__r.HI_Effective_Date__c != null) {
						map_CarrIdpolicyEffMap.put(pol.Carrier__r.Id__C, pol.Opportunity__r.HI_Effective_Date__c);
					}
					String strPolMapKey = pol.Opportunity__c + ':' + pol.Benefit_Type__c + ':' + pol.Carrier__c;
					// [SM] Temp fix to prioritize base plan for medical
					if (!(pol.Benefit_Type__c == 'Medical' && polmap.containsKey(strPolMapKey) && polmap.get(strPolMapKey).Is_Base__c))
						polmap.put(strPolMapKey, pol);

					if (pol.Contribution_Scheme_Type__c == 'Percentage Of Base' && pol.Benefit_Type__c == 'Medical' && pol.Is_Base__c == true) {
						polmapunique.put(pol.Opportunity__c + ':' + pol.Benefit_Type__c + ':' + pol.Carrier__c, pol);
					}
					if (!polname.containskey(pol.Benefit_Type__c + ':' + pol.Carrier__c)) {
						polname.put(pol.Benefit_Type__c + ':' + pol.Carrier__c, pol.name);
					} else {
						polname.put(pol.Benefit_Type__c + ':' + pol.Carrier__c, polname.get(pol.Benefit_Type__c + ':' + pol.Carrier__c) + '\n' + pol.name);
					}
				}
			}

			Map<String, Carrier_Version_Detail__c> mapCarrierVersion;
			if (!map_CarrIdpolicyEffMap.isEmpty()) {
				mapCarrierVersion = Utils.getCarrierVersion(map_CarrIdpolicyEffMap);
			}

			list<Transition_to_Fulfillment__c> ttflist = [
				SELECT Id, Opportunity__c, Name, Composite_Rated__c, PEO__c, Contact__r.name, Contact__r.email
				FROM Transition_to_Fulfillment__c
				WHERE Opportunity__c IN :oppidMap.keySet() AND RecordTypeId IN :CarrierOrderUtil.set_TTFRecordTypes
			];
			if (ttflist != null && ttflist.size() > 0) {
				for (Transition_to_Fulfillment__c ttf : ttflist) {
					ttfmap.put(ttf.Opportunity__c, ttf);
				}
			}

			for (string str : polmap.keyset()) {
				Carrier_Version_Detail__c objCarrierVersion = mapCarrierVersion != null ? mapCarrierVersion.get(polmap.get(str).Carrier__r.Id__c) : null;

				string s = str.split(':')[0];
				QA_Lines_Of_Coverage__c qlc;
				String strCarrier = polmap != null && polmap.containsKey(str) ? polmap.get(str)?.Carrier__c : null;
				String strOpptyId = polmap != null && polmap.containsKey(str) ? polmap.get(str)?.Opportunity__c : null;
				String strBenefitType = polmap != null && polmap.containsKey(str) ? polmap.get(str)?.Benefit_Type__c : null;
				String strQASheetId = qamap != null && qamap.containsKey(oppidMap.get(s)) ? qamap.get(oppidMap.get(s)).Id : null;
				String strKey = strOpptyId + ';' + strQASheetId + ';' + strBenefitType?.toLowerCase() + ';' + strCarrier;
				if (!map_Qlc.isEmpty() && map_Qlc.containsKey(strKey)) {
					qlc = map_Qlc.get(strKey);
				} else {
					if (String.isNotBlank(strQASheetId)) {
						qlc = new QA_Lines_Of_Coverage__c(QA_Sheet__c = strQASheetId);
					}
				}

				if (qlc == null) {
					continue;
				}

				/*For fetching contribution scheme type, EE, dependents, only special condition is if its benefit type is 'Medical'
and contribution scheme type is 'Percentage of base' then check for base is true or not,
if not true search for other policies which has medical benefit type,Percentage of base and base is set to true in opp
rest all cases just simply populate contribution scheme type, EE, dependents from policy to QAL.*/
				if (polmap.get(str).Contribution_Scheme_Type__c != null && polmap.get(str).Benefit_Type__c != null) {
					if (polmap.get(str).Contribution_Scheme_Type__c == 'Percentage Of Base' && polmap.get(str).Benefit_Type__c == 'Medical') {
						if (polmap.get(str).Is_Base__c == true) {
							qlc.Contribution_Scheme_Type__c = polmap.get(str).Contribution_Scheme_Type__c;
							qlc.Contribution_for_EEs__c = polmap.get(str).Contribution_for_EEs__c;
							qlc.Contribution_for_Dependents__c = polmap.get(str).Contribution_for_Dependents__c;
						} else {
							if (!polmapunique.isEmpty() && polmapunique.containskey(str)) {
								qlc.Contribution_Scheme_Type__c = polmapunique.get(str).Contribution_Scheme_Type__c;
								qlc.Contribution_for_EEs__c = polmapunique.get(str).Contribution_for_EEs__c;
								qlc.Contribution_for_Dependents__c = polmapunique.get(str).Contribution_for_Dependents__c;
							}
						}
					} else {
						qlc.Contribution_Scheme_Type__c = polmap.get(str).Contribution_Scheme_Type__c;
						qlc.Contribution_for_EEs__c = polmap.get(str).Contribution_for_EEs__c;
						qlc.Contribution_for_Dependents__c = polmap.get(str).Contribution_for_Dependents__c;
					}
				}
				//Populate the alignment field without Contribution_Scheme_Type__c null check
				/* if (polmap.get(str).Benefit_Type__c != null) {
if (NewTransitionToFulfillmentController.map_QALinesOfCoveragePerPolicy != null && NewTransitionToFulfillmentController.map_QALinesOfCoveragePerPolicy.containsKey(str)) {
qlc.Does_group_have_an_alignment__c = NewTransitionToFulfillmentController.map_QALinesOfCoveragePerPolicy.get(str).Does_group_have_an_alignment__c;
qlc.Rate_Change__c = NewTransitionToFulfillmentController.map_QALinesOfCoveragePerPolicy.get(str).Rate_Change__c;
}
} */
				qlc.Carriers__c = polmap.get(str).Carrier__r.Name != null ? polmap.get(str).Carrier__r.Name : null;
				qlc.Benefits_selected_Carrier__c = polmap.get(str).Carrier__r.Name != null ? polmap.get(str).Carrier__c : null;
				qlc.Waiting_Period__c = polmap.get(str).Waiting_Period__c != null ? polmap.get(str).Waiting_Period__c : '';
				qlc.Base_Plan__c = polmap.get(str).name != null ? polmap.get(str).name : '';

				if (objCarrierVersion != null) {
					qlc.Medical_LOA_Required__c = objCarrierVersion.Medical_LOA_Required__c;
					qlc.LOA_Required__c = objCarrierVersion.Personal_LOA_Required__c;
					qlc.OOS_EE_Requirements__c = objCarrierVersion.oos_plan_restrictions__c;
					qlc.Participation_Requirements__c = objCarrierVersion.Participation_Requirements__c != null ? objCarrierVersion.Participation_Requirements__c : '';

					//BY:PR, Date:Aug-27-2020, Desc: of_Plans_Allowed__c qa line item field should contain concatinated value from two field present in Carrier Verison Object.
					qlc.of_Plans_Allowed__c = null;
					if (string.isNotBlank(objCarrierVersion.Number_of_Plans_Allowed_based_on_FTE__c)) {
						qlc.of_Plans_Allowed__c = 'Number of Plans Allowed based on FTE - ' + objCarrierVersion.Number_of_Plans_Allowed_based_on_FTE__c;
					}
					if (string.isNotBlank(objCarrierVersion.Number_of_Plans_Allowed_on_Enrolle_count__c)) {
						if (string.isBlank(qlc.of_Plans_Allowed__c)) {
							qlc.of_Plans_Allowed__c = 'Number of Plans Allowed based on Enrolle - ' + objCarrierVersion.Number_of_Plans_Allowed_on_Enrolle_count__c;
						} else {
							qlc.of_Plans_Allowed__c += ' \n\n ' + 'Number of Plans Allowed based on Enrolle - ' + objCarrierVersion.Number_of_Plans_Allowed_on_Enrolle_count__c;
						}
					}

					qlc.Allows_plans_with_no_enrollees__c = objCarrierVersion.Allows_Plans_with_No_Enrollees__c != null ? objCarrierVersion.Allows_Plans_with_No_Enrollees__c : '';
					qlc.Rating_Structure_Composite_Age_Banded__c = objCarrierVersion.Gusto_Default_Rating_Structure__c != null ? objCarrierVersion.Gusto_Default_Rating_Structure__c : '';
					qlc.Allow_Ghost_Plans__c = objCarrierVersion.Allows_Plans_with_No_Enrollees__c;
					qlc.job_titles_required__c = objCarrierVersion.job_titles_required__c;
					//BY:PR, Date:Sep/9/2020, Desc: Introduced New Field https://app.asana.com/0/0/1191418728413377/f
					qlc.Owner_Required__c = objCarrierVersion.Owner_Percentage_Required__c;
					qlc.PY_or_CY_Deductible__c = objCarrierVersion.Deductible_Reset_Year__c;
					// qlc.Non_owner_enrolled_required__c = objCarrierVersion.nonowner_eligible_w2ees_req__c == null ? 'No' : objCarrierVersion.nonowner_eligible_w2ees_req__c == '0' ? 'No' : 'Yes';
				}
				//update in ui
				qlc.Lines_Of_Coverage__c = polmap.get(str).Benefit_Type__c != null ? polmap.get(str).Benefit_Type__c : '';

				if (oppidMap != null && oppidMap.containsKey(s) && qlc.Benefits_selected_Carrier__c != null && cariermap.containsKey(s + ':' + strCarrier + ':' + strBenefitType)) {
					Carrier_Order__c carrierOrd = cariermap.get(s + ':' + strCarrier + ':' + strBenefitType);
					qlc.Carrier_Order__c = carrierOrd.id;

					//for checking the order assignment value on carrier order, then populating value in QAL submission deadline
					if (carrierOrd.Order_Assignment__c == null) {
						qlc.Submission_Deadline__c = null;
					} else {
						qlc.Submission_Deadline__c = carrierOrd.Submission_Deadline_Date__c;
					}
				}
				string polstring = qlc.Lines_Of_Coverage__c + ':' + strCarrier;

				qlc.Plan_Names__c = polname.get(polstring) != '' ? polname.get(polstring) : '';
				//DS[18th Jan 2021]:TTIA does not reflect composite rates, TTQ/QA sheet does (specific groups only)
				//https://app.asana.com/0/1199605183564487/1199628309121376
				//overide the rating structure composite age felid to composite
				if (
					polmap.get(str).Benefit_Type__c != null &&
					polmap.get(str).Benefit_Type__c == 'Medical' &&
					ttfmap != null &&
					ttfmap.containsKey(s) &&
					ttfmap.get(s).Composite_Rated__c != null &&
					ttfmap.get(s).Composite_Rated__c == 'Y'
				) {
					qlc.Rating_Structure_Composite_Age_Banded__c = 'Composite';
				}
				qaslist.add(qlc);
			}
			// for creating QAL, if tada, with recordtype change or renewal and carrier is alegus
			if (renecarier.size() > 0) {
				list<QA_Sheet__c> rbenfitlist = [SELECT id, name, Benefit_Order__c FROM QA_Sheet__c WHERE Benefit_Order__c IN :rboid];
				if (rbenfitlist != null && rbenfitlist.size() > 0) {
					for (QA_Sheet__c qs : rbenfitlist) {
						rqamap.put(qs.Benefit_Order__c, qs);
					}
				}

				for (string ss : renecarier.keyset()) {
					QA_Lines_Of_Coverage__c qlc = new QA_Lines_Of_Coverage__c();
					if (rqamap != null && rqamap.containsKey(renecarier.get(ss).Benefit_Order__c))
						qlc.QA_Sheet__c = rqamap.get(renecarier.get(ss).Benefit_Order__c).id;
					else
						continue;

					qlc.Carriers__c = renecarier.get(ss).Carrier__r.Name != null ? renecarier.get(ss).Carrier__r.Name : null;
					qlc.Benefits_selected_Carrier__c = renecarier.get(ss).Carrier__c != null ? renecarier.get(ss).Carrier__c : null;

					qlc.PY_or_CY_Deductible__c = renecarier.get(ss).Carrier__r.PY_or_CY_Deductible__c != null ? renecarier.get(ss).Carrier__r.PY_or_CY_Deductible__c : '';
					qlc.Lines_Of_Coverage__c = ss.split(':')[2] != '' ? ss.split(':')[2] : '';
					qlc.Carrier_Order__c = renecarier.get(ss).id;

					if (renecarier != null && renecarier.containsKey(ss)) {
						Carrier_Order__c renewalCarrier = renecarier.get(ss);
						if (renewalCarrier.Order_Assignment__c == null) {
							qlc.Submission_Deadline__c = null;
						} else {
							qlc.Submission_Deadline__c = renewalCarrier.Submission_Deadline_Date__c;
						}
						qaslist.add(qlc);
					}
				}
			}

			// a check identify which QA lines of coverage is availble on carrier order accordingly insert and delete
			list<QA_Lines_Of_Coverage__c> list_existingQALs;
			if (list_savedCarrierOrderIds != null && list_savedCarrierOrderIds.size() > 0) {
				list_existingQALs = [
					SELECT id, name, Carrier_Order__c, Benefits_selected_Carrier__c, Lines_Of_Coverage__c, Plan_Names__c
					FROM QA_Lines_Of_Coverage__c
					WHERE Carrier_Order__c IN :list_savedCarrierOrderIds
				];
			}

			// if there find any QALs on carrier order then verify and delete or insert
			map<String, QA_Lines_Of_Coverage__c> map_existingQals = new Map<String, QA_Lines_Of_Coverage__c>();
			if (list_existingQALs != null && list_existingQALs.size() > 0) {
				for (QA_Lines_Of_Coverage__c qaloc : list_existingQALs) {
					map_existingQals.put(qaloc.Carrier_Order__c + ':' + qaloc.Benefits_selected_Carrier__c + ':' + qaloc.Lines_Of_Coverage__c, qaloc);
				}
				map<String, QA_Lines_Of_Coverage__c> map_toBeCreatedQAL = new Map<String, QA_Lines_Of_Coverage__c>();
				for (QA_Lines_Of_Coverage__c qa : qaslist) {
					map_toBeCreatedQAL.put(qa.Carrier_Order__c + ':' + qa.Benefits_selected_Carrier__c + ':' + qa.Lines_Of_Coverage__c, qa);
				}
				qaslist = new List<QA_Lines_Of_Coverage__c>();
				// remove which not need to be created
				for (string key : map_existingQals.keySet()) {
					if (map_toBeCreatedQAL.containsKey(key)) {
						if (map_existingQals.get(key).Plan_Names__c != null && map_toBeCreatedQAL.get(key).Plan_Names__c != null) {
							string existName = map_existingQals.get(key).Plan_Names__c;
							string newName = map_toBeCreatedQAL.get(key).Plan_Names__c;
							if (!existName.contains(newName)) {
								map_existingQals.get(key).Plan_Names__c = map_existingQals.get(key).Plan_Names__c + ';' + map_toBeCreatedQAL.get(key).Plan_Names__c;
								map_toBeCreatedQAL.get(key).Plan_Names__c = map_existingQals.get(key).Plan_Names__c;
								map_toBeCreatedQAL.get(key).Id = map_existingQals.get(key).Id;
							} else {
								map_toBeCreatedQAL.remove(key);
							}
						}
					}
				}
				// add which need to be created
				for (QA_Lines_Of_Coverage__c qa : map_toBeCreatedQAL.values()) {
					qaslist.add(qa);
				}
				for (Carrier_Order__c co : newCarrierOrderList) {
					if (co.Benefit_Types__c != null && co.Order_Type__c != 'Terminated Order') {
						for (string str : co.Benefit_Types__c.split(';')) {
							if (String.isNotBlank(str)) {
								str = str.trim();
							}
							String strKey = co.id + ':' + co.Carrier__c + ':' + str;
							String strKeyShortForm = co.id + ':' + co.Carrier__c;
							if (str == 'Flexible Spending Account - Dependent Care') {
								strKeyShortForm += ':DCA';
							} else if (str == Utils.BENEFIT_TYPE_LTD) {
								strKeyShortForm += ':LTD';
							} else if (str == Utils.BENEFIT_TYPE_STD) {
								strKeyShortForm += ':STD';
							} else if (str == 'Flexible Spending Account - Medical') {
								strKeyShortForm += ':FSA';
							}
							if (map_existingQals.containsKey(strKey)) {
								map_existingQals.remove(strKey);
							} else if (map_existingQals.containsKey(strKeyShortForm)) {
								map_existingQals.remove(strKeyShortForm);
							}
						}
					}
				}

				for (QA_Lines_Of_Coverage__c qa : qaslist) {
					set<String> set_pName = new Set<String>();
					if (qa.Plan_Names__c != null && qa.Id != null) {
						for (String s : qa.Plan_Names__c.split(';')) {
							for (String s1 : s.split('\n')) {
								set_pName.add(s1);
							}
						}
						list<String> lsName = new List<String>();
						lsName.addAll(set_pName);
						qa.Plan_Names__c = String.join(lsName, '\n');
					}
				}
			}

			if (qaslist.size() > 0 && qaslist != null) {
				upsert qaslist;
			}
			if (map_existingQals != null && map_existingQals.size() > 0) {
				delete map_existingQals.values();
			}
		}
	}

	/**Created by : Syam Nukilla
Created Date : 3/29/2019
Description : Whenever submission deadline field got updated, then it should update in the QA Lines of coverage as well.
**/
	public void UpdateSubmissionDateOnQALinesOfCoverage(list<Carrier_Order__c> newCarrierOrderList, map<id, Carrier_Order__c> oldCarrierOrderMap) {
		map<id, date> carrierDateMap = new Map<id, date>();
		for (Carrier_Order__c carrierOrder : newCarrierOrderList) {
			if (carrierOrder.Submission_Deadline_Date__c != null && carrierOrder.Submission_Deadline_Date__c != oldCarrierOrderMap.get(carrierOrder.Id).Submission_Deadline_Date__c) {
				carrierDateMap.put(carrierOrder.id, carrierOrder.Submission_Deadline_Date__c);
			}
		}
		list<QA_Lines_Of_Coverage__c> qalinelist = [SELECT Carrier_Order__c, Id, Submission_Deadline__c FROM QA_Lines_Of_Coverage__c WHERE Carrier_Order__c IN :carrierDateMap.keyset()];

		if (qalinelist != null && qalinelist.size() > 0) {
			for (QA_Lines_Of_Coverage__c qaline : qalinelist) {
				qaline.Submission_Deadline__c = carrierDateMap.get(qaline.Carrier_Order__c);
			}
		}
		if (qalinelist != null && qalinelist.size() > 0) {
			update qalinelist;
		}
	}

	//update casses associated with carrier order
	public void UpdateRelatedCasesOnCo(Map<Id, Carrier_Order__c> newCarrierOrderMap, Map<Id, Carrier_Order__c> oldCarrierOrderMap, List<Carrier_Order__c> newCarrierOrderList) {
		Set<Id> coIdSet = new Set<Id>();
		List<Case> updateCase = new List<Case>();
		List<Case> UpdateApprovedCOCases = new List<Case>();
		Set<String> set_COImplementationStage = new Set<String>{ 'Approved', CarrierOrderUtil.STAGE_CANCELLED, 'Closed Admin', 'Closed Lost' };
		for (Carrier_Order__c coRec : newCarrierOrderList) {
			Carrier_Order__c oldCo = oldCarrierOrderMap.get(coRec.Id);
			if (coRec.OwnerId != oldCo.OwnerId || (coRec.Implementation_Stage__c != oldCo.Implementation_Stage__c && set_COImplementationStage.contains(coRec.Implementation_Stage__c))) {
				coIdSet.add(coRec.Id);
			}
			//by AKS Dated 16th Sept 2020 https://app.asana.com/0/1193021409156758/1193177195795943
			//It should not execute for "Benefit BOR"
			if (coRec.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR && string.isNotBlank(coRec.Group_Number__c) && coRec.Group_Number__c != oldCo.Group_Number__c) {
				coIdSet.add(coRec.Id);
			}
		}

		if (coIdSet.size() > 0) {
			Set<String> setCaseRecordType = new Set<String>{ 'Benefits Renewal Case', 'Benefits New Plan Case', 'Benefits Change Case' };
			List<Case> lstCarrierOrderCases = [
				SELECT ID, Carrier_Order__c, Carrier_Order__r.Group_Number__c, Group_Number__c, Type, RecordTypeId, RecordType.Name, Carrier_Order__r.Implementation_Stage__c, Carrier_Order__r.OwnerId
				FROM Case
				WHERE Carrier_Order__c IN :coIdSet AND RecordTypeId != :CaseUtils.RECTYPE_MF_AUDIT
			];
			String strGroupTermincationCaseRecordTypeId = CaseUtils.RECTYPE_GROUP_TERMINATION;
			for (Case c : lstCarrierOrderCases) {
				//get Old Carrier Order data
				Carrier_Order__c oldCoTemp = oldCarrierOrderMap.get(c.Carrier_Order__c);

				if (oldCoTemp != null && oldCoTemp.OwnerId != c.Carrier_Order__r.OwnerId && c.RecordTypeId != strGroupTermincationCaseRecordTypeId) {
					c.OwnerId = c.Carrier_Order__r.OwnerId;
				}
				//for updating case status to 'closed' whenever implemenatation stage of carrier order updates to 'Approved'
				if (
					oldCoTemp != null &&
					oldCoTemp.Implementation_Stage__c != c.Carrier_Order__r.Implementation_Stage__c &&
					set_COImplementationStage.contains(c.Carrier_Order__r.Implementation_Stage__c) &&
					c.RecordTypeId != strGroupTermincationCaseRecordTypeId
				) {
					c.Status = 'Closed';
				}

				//assign Group Number if it is muliple value then get any one value
				if (
					oldCoTemp != null &&
					c.Carrier_Order__r.Group_Number__c != null &&
					c.RecordTypeId != null &&
					c.Type == 'Carrier Submission' &&
					setCaseRecordType.contains(c.RecordType.Name) &&
					oldCoTemp.Group_Number__c != c.Carrier_Order__r.Group_Number__c
				) {
					c.Group_Number__c = c.Carrier_Order__r.Group_Number__c.split(';')[0];
				}
				updateCase.add(c);
			}
		}
		if (updateCase.size() > 0) {
			boolean caseTriggerFlag = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			update updateCase;
			CaseTriggerHelper.skipTrigger = caseTriggerFlag;
		}
	}

	private void updateBenefitOrder(Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate) {
		if (!map_BenefitOrderToUpdate.isEmpty()) {
			update map_BenefitOrderToUpdate.values();
		}
	}
	//>>>>>>>>>>>>>>>>>>>>>>>>>logic for Order Assignment "New Plan, Renewal, Benefits Change"  type  ==============Start=================

	/**BY:PR, Date:Feb-24-2020, Desc: This code is updating the related Line Item records so as to recalculate the [Renewal Date] and [Type] on BO */
	public static void handleCancelCarrierOrders(set<String> set_carrierOrderCanceledIds) {
		if (set_carrierOrderCanceledIds != null && set_carrierOrderCanceledIds.size() > 0) {
			list<Carrier_Order_Line_Item__c> list_CanceledCOLineItems = [SELECT Id FROM Carrier_Order_Line_Item__c WHERE Carrier_Order__c IN :set_carrierOrderCanceledIds];

			if (list_CanceledCOLineItems.size() > 0) {
				try {
					update list_CanceledCOLineItems;
				} catch (exception ex) {
					ExceptionLogUtil.logException('CarrierOrderTriggerHelper', 'handleCancelCarrierOrders', ex.getMessage(), 'Medium');
				}
			}
		}
	}

	public static void orderStatushandler(
		List<Carrier_Order__c> lst_NewCarrierOrder,
		Map<id, Carrier_Order__c> map_OldCarrierOrder,
		Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate,
		Map<Id, Benefit_Order__c> benefitOrderMap
	) {
		Set<Id> set_BenefitOrderIds = new Set<Id>();
		Set<Id> set_BoRBenefitOrderIds = new Set<Id>();
		Set<String> set_BTCanceledCarrierOrderIds = new Set<String>();
		//Insert, Update, Undelete
		if (null != lst_NewCarrierOrder) {
			for (Carrier_Order__c objCarrierOrder : lst_NewCarrierOrder) {
				//Update
				if (
					null != map_OldCarrierOrder &&
					!map_OldCarrierOrder.isEmpty() &&
					map_OldCarrierOrder.containsKey(objCarrierOrder.Id) &&
					objCarrierOrder.Implementation_Stage__c != map_OldCarrierOrder.get(objCarrierOrder.Id).Implementation_Stage__c
				) {
					if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR) {
						set_BoRBenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
					} else {
						set_BenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
					}
				} else if (null == map_OldCarrierOrder) {
					//Insert, Undelete
					if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR) {
						set_BoRBenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
					} else {
						set_BenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
					}
				}

				//this code is used to handle CO if Implementation_Stage becomes 'Canceled','Closed Admin'
				if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR && CarrierOrderUtil.set_COExcludeStages.contains(objCarrierOrder.Implementation_Stage__c)) {
					set_BTCanceledCarrierOrderIds.add(objCarrierOrder.Id);
				}
			}
		} else if (null != map_OldCarrierOrder && !map_OldCarrierOrder.isEmpty() && null == lst_NewCarrierOrder) {
			//Delete
			for (Carrier_Order__c objCarrierOrder : map_OldCarrierOrder.values()) {
				if (objCarrierOrder.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR) {
					set_BoRBenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
				} else {
					set_BenefitOrderIds.add(objCarrierOrder.Benefit_Order__c);
				}
			}
		}

		if (set_BTCanceledCarrierOrderIds.size() > 0) {
			handleCancelCarrierOrders(set_BTCanceledCarrierOrderIds);
		}

		if (!set_BenefitOrderIds.isEmpty()) {
			populateOrderStatusForNonBoR(set_BenefitOrderIds, map_BenefitOrderToUpdate, false);
		}
		if (!set_BoRBenefitOrderIds.isEmpty()) {
			populateOrderStatusForBoR(set_BoRBenefitOrderIds, map_BenefitOrderToUpdate);
		}
	}

	private static void populateOrderStatusForBoR(Set<Id> set_BoRBenefitOrderIds, Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate) {
		List<Benefit_Order__c> lst_BenefitOrderWithLeastStage = new List<Benefit_Order__c>();
		//query for the worst case implementation stage
		lst_BenefitOrderWithLeastStage = [
			SELECT
				Id,
				Order_Status__c,
				Status_Detail__c,
				Type__c,
				RecordTypeId,
				(
					SELECT Implementation_Stage__c, Order_Type__c, Stage_Detail__c, Carrier__c, Benefit_Types__c, Additional_Details__c
					FROM Carrier_Orders__r
					ORDER BY Implementation_Stage__c ASC
				)
			FROM Benefit_Order__c
			WHERE Id IN :set_BoRBenefitOrderIds
		];
		if (lst_BenefitOrderWithLeastStage.isEmpty())
			return;
		String strRawStage;
		String strRawStageDetail, strRawAdditionalDetails;
		for (Benefit_Order__c objBO : lst_BenefitOrderWithLeastStage) {
			if (!objBO.Carrier_Orders__r.isEmpty()) {
				if ('BOR TAdA Only'.equalsIgnoreCase(objBO.Type__c) || 'BOR'.equalsIgnoreCase(objBO.Type__c)) {
					strRawStage = objBO.Carrier_Orders__r[0].Implementation_Stage__c;
					strRawStageDetail = objBO.Carrier_Orders__r[0].Stage_Detail__c;
					strRawAdditionalDetails = objBO.Carrier_Orders__r[0].Additional_Details__c; //Neha November 5, 2020 . To Capture relevant Additional Details
				} else {
					if (
						!map_Carrier.isEmpty() &&
						objBO.Carrier_Orders__r[0].Carrier__c != null &&
						map_Carrier.containsKey(objBO.Carrier_Orders__r[0].Carrier__c) &&
						map_Carrier.get(objBO.Carrier_Orders__r[0].Carrier__c).Partner_Type__c != null &&
						map_Carrier.get(objBO.Carrier_Orders__r[0].Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA
					) {
						for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
							if (
								!map_Carrier.isEmpty() &&
								objCO.Carrier__c != null &&
								map_Carrier.containsKey(objCO.Carrier__c) &&
								(map_Carrier.get(objCO.Carrier__c).Partner_Type__c == null ||
								map_Carrier.get(objCO.Carrier__c).Partner_Type__c != CarrierOrderUtil.PARTNER_TYPE_TADA)
							) {
								if (String.isBlank(strRawStage)) {
									strRawStage = objCO.Implementation_Stage__c;
									strRawStageDetail = objCO.Stage_Detail__c;
									strRawAdditionalDetails = objCO.Additional_Details__c; //Neha November 5, 2020 . To Capture relevant Additional Details
									break;
								}
							}
						}
						if (strRawStage == 'Approved' && !'Approved'.equalsIgnoreCase(objBO.Carrier_Orders__r[0].Implementation_Stage__c)) {
							strRawStage = 'BOR complete pending TAdAs';
						}
					} else {
						strRawStage = objBO.Carrier_Orders__r[0].Implementation_Stage__c;
						strRawStageDetail = objBO.Carrier_Orders__r[0].Stage_Detail__c;
						strRawAdditionalDetails = objBO.Carrier_Orders__r[0].Additional_Details__c; //Neha November 5, 2020 . To Capture relevant Additional Details
					}
				}
				if (strRawStage == CarrierOrderUtil.STAGE_CANCELLED) {
					for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
						if (String.isNotBlank(objCO.Benefit_Types__c) && objCO.Benefit_Types__c.contains('Medical')) {
							strRawStageDetail = objCO.Stage_Detail__c;
							strRawAdditionalDetails = objCO.Additional_Details__c;
							break;
						}
					}
				}
				if (strRawStage == 'Approved') {
					strRawStage = 'Fulfilled';
				}

				//skip if status did not change
				if (objBO.Order_Status__c == strRawStage)
					continue;

				if (String.isNotBlank(strRawStage)) {
					objBO.Order_Status__c = strRawStage;
					objBO.Status_Detail__c = strRawStageDetail;

					if (objBO.Order_Status__c == BenefitOrderUtil.STATUS_CANCELLED && objBO.Status_Detail__c == 'Other') {
						objBO.Additional_Details__c = strRawAdditionalDetails;
					}
				}

				if (!map_BenefitOrderToUpdate.isEmpty() && map_BenefitOrderToUpdate.containsKey(objBO.Id)) {
					Benefit_Order__c objTempBO = map_BenefitOrderToUpdate.get(objBO.Id);
					objTempBO.Order_Status__c = objBO.Order_Status__c;
					objTempBO.Status_Detail__c = objBO.Status_Detail__c;
					if (objBO.Order_Status__c == BenefitOrderUtil.STATUS_CANCELLED && objBO.Status_Detail__c == 'Other') {
						objTempBO.Additional_Details__c = objBO.Additional_Details__c;
					}
					map_BenefitOrderToUpdate.put(objTempBO.Id, objTempBO);
				} else {
					map_BenefitOrderToUpdate.put(objBO.Id, objBO);
				}
			}
		}
	}

	public static void populateOrderStatusForNonBoR(Set<Id> set_BenefitOrderIds, Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate, Boolean blnHasOAClickedUnblock) {
		List<Benefit_Order__c> benefitOrdersWithBestCaseStage = new List<Benefit_Order__c>();
		final Set<String> set_ERTicketStatus = new Set<String>{ 'Awaiting ER response - Pending Item', 'ER Outreach Required' };
		//query for the worst case implementation stage
		//By: Deepak Tyagi, Date: 13 May, 2019 Desc: Update Status Detail for "TAdA: Pre OE Setup" Type
		// Neha Dabas 8th May 2020, Fetch related ER Outreach tickets for BO
		benefitOrdersWithBestCaseStage = [
			SELECT
				Id,
				Order_Status__c,
				Status_Detail__c,
				Open_Enrollment_Start_Date__c,
				Open_Enrollment_End_Date__c,
				RecordTypeId,
				(
					SELECT Implementation_Stage__c, Order_Type__c, Stage_Detail__c
					FROM Carrier_Orders__r
					ORDER BY Implementation_Stage__c ASC
				),
				(SELECT Status__c FROM Tickets__r WHERE Status__c IN :set_ERTicketStatus ORDER BY Status__c ASC LIMIT 1)
			FROM Benefit_Order__c
			WHERE Id IN :set_BenefitOrderIds
		];
		if (benefitOrdersWithBestCaseStage.isEmpty())
			return;

		String orderStatus, rawStage;
		Map<Id, String> map_BOwithCOStatusDetail = new Map<Id, String>();
		for (Benefit_Order__c objBo : benefitOrdersWithBestCaseStage) {
			for (Carrier_Order__c objCo : objBo.Carrier_Orders__r) {
				if (
					objCo.Order_Type__c != null &&
					objCo.Order_Type__c.contains(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) &&
					objBo.Open_Enrollment_Start_Date__c == null &&
					objBo.Open_Enrollment_End_Date__c == null
				) {
					map_BOwithCOStatusDetail.put(objBo.Id, objCo.Stage_Detail__c);
				}
			}
		}

		for (Benefit_Order__c bo : benefitOrdersWithBestCaseStage) {
			//if BO is blocked then we should not update the BO status on CO Implementation stage change
			if (bo.Order_Status__c != null && bo.Order_Status__c == BenefitOrderUtil.STATUS_BLOCKED && !blnHasOAClickedUnblock) {
				continue;
			}

			//If there are ticket with ER Outreach on BO, Set BO Status to ER Outreach Status
			if (!bo.Tickets__r.isEmpty()) {
				orderStatus = bo.Tickets__r[0].Status__c;
			} else if (bo.Carrier_Orders__r.isEmpty()) {
				//skip if benefit order does not have a carrier order
				//reset benefit order to default value
				orderStatus = CarrierOrderUtil.DEFAULT_STATUS;
			} else {
				//convert carrier order implementation stage to benefit order order status
				boolean blockedCarrierExist = false;
				for (Carrier_Order__c carrierOrder : bo.Carrier_Orders__r) {
					if (carrierOrder.Implementation_Stage__c == 'Blocked') {
						blockedCarrierExist = true;
					}
				}
				if (blockedCarrierExist == true) {
					continue;
				}
				rawStage = bo.Carrier_Orders__r[0].Implementation_Stage__c;
				orderStatus = stageToStatusConversion.get(rawStage);
				// if the CO stage is pending Item from Ready to Confirmation And Pending Confirmation
				if (rawStage == 'Pending Item') {
					if (Trigger.oldMap != null && Trigger.oldMap.containsKey(bo.Carrier_Orders__r[0].Id)) {
						String strImplementationStage = (String) Trigger.oldMap.get(bo.Carrier_Orders__r[0].Id).get('Implementation_Stage__c');
						if (strImplementationStage == CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION || strImplementationStage == 'Pending Confirmation') {
							orderStatus = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
						}
					}
				}
			}
			if (String.isBlank(orderStatus))
				continue;

			if (map_BOwithCOStatusDetail.containsKey(bo.Id)) {
				if (bo.Status_Detail__c != map_BOwithCOStatusDetail.get(bo.Id)) {
					bo.Status_Detail__c = map_BOwithCOStatusDetail.get(bo.Id);
					map_BenefitOrderToUpdate = setBenefitOrdertoUpdate(map_BenefitOrderToUpdate, bo);
				}
			}

			//skip if status did not change
			if (bo.Order_Status__c == orderStatus)
				continue;
			if (
				!bo.Carrier_Orders__r.isEmpty() &&
				bo.Carrier_Orders__r[0].Order_Type__c != null &&
				bo.Carrier_Orders__r[0].Order_Type__c.contains(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) &&
				String.isNotBlank(bo.Carrier_Orders__r[0].Stage_Detail__c)
			) {
				bo.Status_Detail__c = bo.Carrier_Orders__r[0].Stage_Detail__c;
			}

			//Changed By Deepika 29/10/2019
			// if the order status is Approved or Approved Pending EE Audit and BO status is fulfilled then
			//We are not updating the benfit order

			Boolean isUpdateBo = true;
			//Run Loop on carrier order
			if (Trigger.oldMap != null && Trigger.newMap != null) {
				for (sObject sObjectCo : Trigger.newMap.values()) {
					Carrier_Order__c co = (Carrier_Order__c) sObjectCo;
					if (co.Benefit_Order__c == bo.Id) {
						String OldStatus = (String) Trigger.oldMap.get(co.Id).get('Implementation_Stage__c');
						String newStatus = co.Implementation_Stage__c;
						if (
							((OldStatus == 'Approved' && newStatus == 'Approved Pending EE Audit') || (newStatus == 'Approved' && OldStatus == 'Approved Pending EE Audit')) &&
							bo.Order_Status__c == 'Fulfilled'
						) {
							isUpdateBo = false;
						}
					}
				}
			}
			if (isUpdateBo)
				bo.Order_Status__c = orderStatus;

			// Update Order Status Detail When Order Status changed to 'Canceled'
			if (!bo.Carrier_Orders__r.isEmpty() && String.isNotBlank(bo.Carrier_Orders__r[0].Stage_Detail__c)) {
				if (BenefitOrderUtil.STATUS_CANCELLED.equalsIgnoreCase(bo.Order_Status__c))
					bo.Status_Detail__c = bo.Carrier_Orders__r[0].Stage_Detail__c;
			}

			map_BenefitOrderToUpdate = setBenefitOrdertoUpdate(map_BenefitOrderToUpdate, bo);
		}
	}

	private static Map<String, String> stageToStatusConversion {
		get {
			if (stageToStatusConversion == null) {
				stageToStatusConversion = new Map<String, String>{
					'Ready For Qualification' => 'Ready For Qualification',
					'Qualification' => 'Qualification',
					'With Sales' => 'With Sales',
					'With Advising' => 'With Advising',
					'Awaiting Routing' => 'Awaiting Routing',
					'Ready for OE Prep' => 'Ready for OE Prep',
					'OE Prep' => 'OE Prep',
					'OE' => 'OE',
					'OE Extended' => 'OE Extended',
					'OE Verification/Checking Participation' => 'OE Verification/Checking Participation',
					'Ready for Submission Prep' => 'Ready for Submission Prep',
					'Submission Prep' => 'Submission Prep',
					'Ready for Confirmation' => 'Ready for Confirmation',
					'Pending Confirmation' => 'Pending Confirmation',
					'Pending Item' => 'Awaiting Routing',
					'Approved Pending EE Audit' => 'Approved',
					'Approved' => 'Approved',
					'Closed Lost' => 'Closed Lost',
					'Denied' => 'Denied',
					CarrierOrderUtil.STAGE_CANCELLED => BenefitOrderUtil.STATUS_CANCELLED,
					'Blocked' => 'Blocked',
					'Closed Admin' => 'Closed Admin'
				};
			}
			return stageToStatusConversion;
		}
		set;
	}
	//<<<<<<<<<<<<<<<<<<<<<<<<<logic for Order Assignment "New Plan, Renewal, Benefits Change"  type  ==============END=================
	//==================Multi-EIN Parent CO assignment logic==========================Start============================

	void updateParentCOForMultiEIN(list<Carrier_Order__c> list_MultiEinCOs) {
		if (list_MultiEinCOs == null || list_MultiEinCOs.size() == 0) {
			return;
		}

		set<String> set_BenefitIds = new Set<string>();
		set<String> set_CarrierIds = new Set<string>();

		for (Carrier_Order__c objCO : list_MultiEinCOs) {
			if (
				objCO.Is_Multi_EIN__c &&
				objCO.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR &&
				objCO.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED &&
				objCO.Parent_Carrier_Order__c == null
			) {
				set_BenefitIds.add(objCO.Benefit_Order__c);
				set_CarrierIds.add(objCO.carrier__c);
			}
		}

		if (set_BenefitIds.size() > 0) {
			map<string, string> map_boIdAccountId = new Map<string, string>();
			set<string> set_UniqueAccountIds = new Set<String>();
			for (Benefit_Order__c objBO : [SELECT Id, Opportunity__r.AccountId, Opportunity__r.Account.ParentId FROM Benefit_Order__c WHERE Id IN :set_BenefitIds AND Is_Multi_EIN__c = TRUE]) {
				if (objBO.Opportunity__r.Account.ParentId != null) {
					map_boIdAccountId.put(objBO.Id, objBO.Opportunity__r.Account.ParentId);
					set_UniqueAccountIds.add(objBO.Opportunity__r.Account.ParentId);
				} else if (objBO.Opportunity__r.AccountId != null) {
					map_boIdAccountId.put(objBO.Id, objBO.Opportunity__r.AccountId);
					set_UniqueAccountIds.add(objBO.Opportunity__r.AccountId);
				}
			}

			if (map_boIdAccountId.size() > 0) {
				map<string, Carrier_Order__c> map_CarrierIdParentAccountIdKeyCarrierOrder = new Map<string, Carrier_Order__c>();
				map<string, Carrier_Order__c> map_parentAccountIdCarrierIdKeyCOrec = new Map<string, Carrier_Order__c>();
				list<Carrier_Order__c> list_CarrierOrderWithoutParent = new List<Carrier_Order__c>();
				list<Carrier_Order__c> list_toUpdateCarrierOrder = new List<Carrier_Order__c>();

				//we want Parent + Child Multi EIN that is why we are using OR
				for (Carrier_Order__c objCO : [
					SELECT
						Id,
						Carrier__c,
						Benefit_Order__r.Opportunity__r.AccountId,
						Benefit_Order__r.Opportunity__r.Account.ParentId,
						CreatedDate,
						Parent_Carrier_Order__c,
						Is_Multi_EIN__c,
						Implementation_Stage__c,
						RecordTypeId,
						Benefit_Order__c
					FROM Carrier_Order__c
					WHERE
						Carrier__c IN :set_CarrierIds
						AND Implementation_Stage__c != :CarrierOrderUtil.STAGE_CANCELLED
						AND Is_Multi_EIN__c = TRUE
						AND (Benefit_Order__r.Opportunity__r.AccountId IN :set_UniqueAccountIds
						OR Benefit_Order__r.Opportunity__r.Account.ParentId IN :set_UniqueAccountIds)
						AND RecordTypeId = :CarrierOrderUtil.REC_TYPE_BOR
					ORDER BY CreatedDate ASC
				]) {
					string strKey;
					if (objCO.Benefit_Order__r.Opportunity__r.Account.ParentId == null) {
						strKey = string.valueOf(objCO.Carrier__c) + string.valueOf(objCO.Benefit_Order__r.Opportunity__r.AccountId);
						map_CarrierIdParentAccountIdKeyCarrierOrder.put(strKey, objCO);
						map_parentAccountIdCarrierIdKeyCOrec.put(strKey, objCO);
					} else {
						strKey = string.valueOf(objCO.Carrier__c) + string.valueOf(objCO.Benefit_Order__r.Opportunity__r.Account.ParentId);
						if (map_CarrierIdParentAccountIdKeyCarrierOrder.containsKey(strKey)) {
							Carrier_Order__c tempCO = map_CarrierIdParentAccountIdKeyCarrierOrder.get(strKey);
							if (map_parentAccountIdCarrierIdKeyCOrec.containsKey(strKey) && map_parentAccountIdCarrierIdKeyCOrec.get(strKey).Id == tempCO.Id) {
								continue;
							}
							if (tempCO.CreatedDate > objCO.CreatedDate) {
								map_CarrierIdParentAccountIdKeyCarrierOrder.put(strKey, objCO);
							}
						} else {
							map_CarrierIdParentAccountIdKeyCarrierOrder.put(strKey, objCO);
						}
					}

					if (objCO.Parent_Carrier_Order__c == null && !set_BenefitIds.contains(objCO.Benefit_Order__c)) {
						list_CarrierOrderWithoutParent.add(objCO);
						if (objCO.Benefit_Order__r.Opportunity__r.Account.ParentId != null) {
							map_boIdAccountId.put(objCO.Benefit_Order__c, objCO.Benefit_Order__r.Opportunity__r.Account.ParentId);
						} else {
							map_boIdAccountId.put(objCO.Benefit_Order__c, objCO.Benefit_Order__r.Opportunity__r.AccountId);
						}
					}
				}

				for (Carrier_Order__c objCO : list_MultiEinCOs) {
					if (
						objCO.Is_Multi_EIN__c &&
						objCO.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR &&
						objCO.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED &&
						objCO.Parent_Carrier_Order__c == null
					) {
						string strKey = string.valueOf(objCO.Carrier__c) + string.valueOf(map_boIdAccountId.get(objCO.Benefit_Order__c));
						if (map_CarrierIdParentAccountIdKeyCarrierOrder.containsKey(strKey) && objCo.Id != map_CarrierIdParentAccountIdKeyCarrierOrder.get(strKey).Id) {
							objCO.Parent_Carrier_Order__c = map_CarrierIdParentAccountIdKeyCarrierOrder.get(strKey).Id;
						}
					}
				}

				if (list_CarrierOrderWithoutParent.size() > 0) {
					for (Carrier_Order__c objCO : list_CarrierOrderWithoutParent) {
						if (
							objCO.Is_Multi_EIN__c &&
							objCO.RecordTypeId == CarrierOrderUtil.REC_TYPE_BOR &&
							objCO.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED &&
							objCO.Parent_Carrier_Order__c == null
						) {
							string strKey = string.valueOf(objCO.Carrier__c) + string.valueOf(map_boIdAccountId.get(objCO.Benefit_Order__c));
							if (map_CarrierIdParentAccountIdKeyCarrierOrder.containsKey(strKey) && objCo.Id != map_CarrierIdParentAccountIdKeyCarrierOrder.get(strKey).Id) {
								objCO.Parent_Carrier_Order__c = map_CarrierIdParentAccountIdKeyCarrierOrder.get(strKey).Id;
								list_toUpdateCarrierOrder.add(objCO);
							}
						}
					}

					if (list_toUpdateCarrierOrder.size() > 0) {
						try {
							boolean blnPreviousSkipVal = CarrierOrderTriggerHelper.skipTrigger;
							CarrierOrderTriggerHelper.skipTrigger = true;
							update list_toUpdateCarrierOrder;
							CarrierOrderTriggerHelper.skipTrigger = blnPreviousSkipVal;
						} catch (exception ex) {
							ExceptionLogUtil.logException(
								'CarrierOrderTriggerHelper',
								'updateParentCOForMultiEIN',
								'Error while updating Child Multi-EIN Carrier Order with Parent Carrier Orders :- ' + ex.getMessage(),
								'high'
							);
						}
					}
				}
			}
		}
	}

	/*
	 *Description : On Automation Status update, move CO to appropriate team based on Automation Status and Automation Message
	 */
	void onAutomationStatusUpdate(List<Carrier_Order__c> list_CO, Map<Id, Carrier_Order__c> map_OldCO) {
		Set<String> set_QueueNames = new Set<String>{ 'Carrier Implementation Queue' };
		Map<String, Id> map_Queue = GlobalQueryHelper.getNameQueueMap(set_QueueNames);
		List<Carrier_Order__c> list_COWithAutomationStatusCompleted;
		for (Carrier_Order__c objCO : list_CO) {
			Carrier_Order__c objOldCO = map_OldCO.get(objCO.Id);
			Boolean blnManualInterventionRequired =
				objOldCO.Automation_Status__c != objCO.Automation_Status__c &&
				(objCO.Automation_Status__c == 'Failed' || (objCO.Automation_Status__c == 'Completed' && objCO.Automation_Message__c == 'Manual Review Required'));

			if (blnManualInterventionRequired) {
				//Move CO to Submission Team
				if (!CarrierOrderExt.blnIsEarlySubmissionButtonClick && set_ImplementationStages.contains(map_OldCO.get(objCO.Id).Implementation_Stage__c)) {
					if (
						!benefitOrderMap.isEmpty() &&
						objCO.Benefit_Order__c != null &&
						benefitOrderMap.containsKey(objCO.Benefit_Order__c) &&
						benefitOrderMap.get(objCO.Benefit_Order__c).Order_Status__c != null &&
						benefitOrderMap.get(objCO.Benefit_Order__c).Order_Status__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP
					) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
					}
				} else {
					objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
				}
				objCO.OwnerId = map_Queue.get('Carrier Implementation Queue');
				objCO.Eligible_for_Submission_Automation__c = false;
			} else {
				Boolean blnAutomationSucceeded =
					objOldCO.Automation_Status__c != objCO.Automation_Status__c &&
					objCO.Automation_Status__c == 'Completed' &&
					objCO.Automation_Message__c != 'Manual Review Required';
				if (blnAutomationSucceeded) {
					//Move CO to Confirmation Team
					if (list_COWithAutomationStatusCompleted == null) {
						list_COWithAutomationStatusCompleted = new List<Carrier_Order__c>();
					}
					if (!CarrierOrderExt.blnIsEarlySubmissionButtonClick && set_ImplementationStages.contains(map_OldCO.get(objCO.Id).Implementation_Stage__c)) {
						if (
							!benefitOrderMap.isEmpty() &&
							objCO.Benefit_Order__c != null &&
							benefitOrderMap.containsKey(objCO.Benefit_Order__c) &&
							benefitOrderMap.get(objCO.Benefit_Order__c).Order_Status__c != null &&
							benefitOrderMap.get(objCO.Benefit_Order__c).Order_Status__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP
						) {
							objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
							objCO.Ready_for_Confirmation_Timestamp__c = System.now();
						}
					} else {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
						objCO.Ready_for_Confirmation_Timestamp__c = System.now();
					}
					objCO.Automated_Submission__c = CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_BOT;
					list_COWithAutomationStatusCompleted.add(objCO);
				}
			}

			if (
				objOldCO.Automation_Status__c != objCO.Automation_Status__c &&
				(CarrierOrderUtil.AUTOMATION_STATUS_FAILED.equalsIgnoreCase(objCO.Automation_Status__c) ||
				CarrierOrderUtil.AUTOMATION_STATUS_COMPLETED.equalsIgnoreCase(objCO.Automation_Status__c) ||
				CarrierOrderUtil.AUTOMATION_STATUS_SUBMITTED.equalsIgnoreCase(objCO.Automation_Status__c))
			) {
				objCO.CO_Automation_Date__c = Datetime.now();
			}

			if (
				(objOldCO.Automation_Status__c != objCO.Automation_Status__c || objOldCO.Sent_to_HI_for_Submission__c != objCO.Sent_to_HI_for_Submission__c) &&
				CarrierOrderUtil.AUTOMATION_STATUS_COMPLETED.equalsIgnoreCase(objCO.Automation_Status__c)
			) {
				if (objCO.Sent_to_HI_for_Submission__c) {
					objCO.Automated_Submission__c = CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI_AND_BOT;
				} else {
					objCO.Automated_Submission__c = CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_BOT;
				}
			}

			if (
				objOldCO.HI_Submission_Automation_Status__c != objCO.HI_Submission_Automation_Status__c &&
				CarrierOrderUtil.AUTOMATION_STATUS_COMPLETED.equalsIgnoreCase(objCO.HI_Submission_Automation_Status__c)
			) {
				objCO.Automated_Submission__c = CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI;
			}

			if (
				objCO.HI_Submission_Automation_Status__c != null &&
				objOldCO.HI_Submission_Automation_Status__c != objCO.HI_Submission_Automation_Status__c &&
				(CarrierOrderUtil.AUTOMATION_STATUS_FAILED.equalsIgnoreCase(objCO.HI_Submission_Automation_Status__c) ||
				CarrierOrderUtil.AUTOMATION_STATUS_UNABLE_TO_AUTOMATE.equalsIgnoreCase(objCO.HI_Submission_Automation_Status__c) ||
				CarrierOrderUtil.HI_SUBMISSION_AUTOMATION_STATUS_SUCCESS.equalsIgnoreCase(objCO.HI_Submission_Automation_Status__c))
			) {
				if (CarrierOrderUtil.HI_SUBMISSION_AUTOMATION_STATUS_SUCCESS.equalsIgnoreCase(objCO.HI_Submission_Automation_Status__c)) {
					if (objCO.Eligible_for_Submission_Automation__c) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
						objCO.Ready_for_Confirmation_Timestamp__c = System.now();
					}
				}
				objCO.API_Submission_Date__c = System.now();
			}
		}
		//Calculate Order Playable Date
		if (list_COWithAutomationStatusCompleted != null && !list_COWithAutomationStatusCompleted.isEmpty()) {
			OnboardingPlayModeUtility.setFirstPlayDateForCarrierOrders('Order', list_COWithAutomationStatusCompleted);
		}
	}
	/*
*Initial Owner is updated for New Renewal and Change record type
when ever first Submitted completed date is update then save the submission owner
in Initial owner
*/
	void updateInitialOwnerRelatedToSubmission(List<Carrier_Order__c> list_CO, Map<Id, Carrier_Order__c> map_OldCO) {
		for (Carrier_Order__c objCO : list_CO) {
			Carrier_Order__c objOldCO = map_OldCO.get(objCO.Id);
			if (
				objCO.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR &&
				objCO.Initial_Owner__c == null &&
				objOldCO.Submitted_Completed_Datetime__c == null &&
				objCO.Submitted_Completed_Datetime__c != null
			) {
				if (String.valueOf(objCO.OwnerId).startsWith('005')) {
					objCO.Initial_Owner__c = objCO.OwnerId;
				}
			}
		}
	}

	// mark Eligible for Submission Automation true or false as per logic
	void markCOsEligibleForSubmissionAutomation(List<Carrier_Order__c> list_NewCO, Map<Id, Carrier_Order__c> map_OldCO) {
		Map<Id, Carrier_Order__c> map_ReadyForSubmissionCOIds = new Map<Id, Carrier_Order__c>();

		for (Carrier_Order__c objCO : list_NewCO) {
			if (objCO.RecordTypeId != CarrierOrderUtil.REC_TYPE_BOR) {
				Carrier_Order__c objOldCO = map_OldCO.get(objCO.Id);

				if (objCO.Implementation_Stage__c != objOldCO.Implementation_Stage__c && objCO.Implementation_Stage__c != null && objOldCO.Implementation_Stage__c != null) {
					if (CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP.equalsIgnoreCase(objOldCO.Implementation_Stage__c) && objCO.Eligible_for_Submission_Automation__c == true) {
						objCO.Eligible_for_Submission_Automation__c = false;
					}
				}
			}
		}
	}

	@future
	public static void reProcessCases(Set<Id> set_COIds, Boolean blnCaseCreatedOnBO) {
		try {
			blnReprocessCases = true;
			Utils.skipTrigger(true);
			Set<Id> set_BOIds = new Set<Id>();
			List<Carrier_Order__c> list_COS = new List<Carrier_Order__c>();
			for (Carrier_Order__c objCO : [SELECT Id, Name, Benefit_Order__c, RecordTypeId, OwnerId, Order_Type__c FROM Carrier_Order__c WHERE Id IN :set_COIds AND Benefit_Order__c != NULL]) {
				set_BOIds.add(objCO.Benefit_Order__c);
				list_COS.add(objCO);
			}

			List<Benefit_Order__c> list_BOS = [SELECT Id, Name, Account__c, Opportunity__c, Parent_Benefit_Order__c, RecordTypeId, OwnerId FROM Benefit_Order__c WHERE Id IN :set_BOIds];

			if (blnCaseCreatedOnBO) {
				if (list_BOS.size() > 0) {
					BenefitOrderHelper.processCases(list_BOS);
				}
				CarrierOrderTriggerHelper.blnCaseCreatedFromCO = true;
			}
			CarrierOrderTriggerHelper.benefitOrderMap = CarrierOrderHelperFunctions.getBenefitOrdersById(set_BOIds);
			CarrierOrderTriggerHelper.processCases(list_COS);
			BenefitOrderHelper.processCaseEmailFunctionality(list_BOS);

			Utils.skipTrigger(false);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('CarrierOrderTriggerHelper', 'reProcessCases', objEx.getMessage(), objEx.getStackTraceString(), '. line number: ' + objEx.getLineNumber());
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Populate the Submission deadline start date
	 * @param         N/A
	 * @return       N/A
	 **/
	private void populateSubmissionStartDate(Carrier_Order__c objCO, Carrier_Version_Detail__c objCarrierVersion, Benefit_Order__c objBO) {
		String strChangeSubmissionStartEvent = '';
		Integer strChangeSubmissionStartVariationNO;
		if (objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES) {
			strChangeSubmissionStartEvent = objCarrierVersion.With_Changes_Submission_Start_Event__c;
			strChangeSubmissionStartVariationNO = (Integer) objCarrierVersion.With_Changes_Sub_Start_Variation_No__c;
		} else if (objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES) {
			strChangeSubmissionStartEvent = objCarrierVersion.Without_Changes_Submission_Start_Event__c;
			strChangeSubmissionStartVariationNO = (Integer) objCarrierVersion.Without_Changes_Sub_Start_Variation_No__c;
		}

		if (String.isNotBlank(strChangeSubmissionStartEvent)) {
			if (strChangeSubmissionStartEvent != null && strChangeSubmissionStartEvent.equalsIgnoreCase(CarrierOrderUtil.SAME_EVENT)) {
				objCO.Submission_Deadline_Start_Date__c = checkDate(objBO.Coverage_Effective_Date__c);
			} else if (strChangeSubmissionStartEvent != null && strChangeSubmissionStartVariationNO != null && objBO.Coverage_Effective_Date__c != null) {
				Date dtEffectiveDate = objBO.Coverage_Effective_Date__c;
				if (strChangeSubmissionStartEvent.equalsIgnoreCase(CarrierOrderUtil.BEFORE_MONTH)) {
					calculateStartDate(objCO, objCarrierVersion, strChangeSubmissionStartVariationNO, CarrierOrderUtil.BEFORE_EVENT, dtEffectiveDate);
					objCO.Submission_Deadline_Start_Date__c = checkDate(objCO.Submission_Deadline_Start_Date__c);
				} else if (strChangeSubmissionStartEvent.equalsIgnoreCase(CarrierOrderUtil.AFTER_MONTH)) {
					calculateStartDate(objCO, objCarrierVersion, strChangeSubmissionStartVariationNO, CarrierOrderUtil.AFTER_EVENT, dtEffectiveDate);
					objCO.Submission_Deadline_Start_Date__c = checkDate(objCO.Submission_Deadline_Start_Date__c);
				} else if (strChangeSubmissionStartEvent.equalsIgnoreCase(CarrierOrderUtil.BEFORE_DAYS)) {
					Date dtNewDate = dtEffectiveDate.addDays(-Integer.valueOf(strChangeSubmissionStartVariationNO));
					objCO.Submission_Deadline_Start_Date__c = checkDate(dtNewDate);
				} else if (strChangeSubmissionStartEvent.equalsIgnoreCase(CarrierOrderUtil.AFTER_DAYS)) {
					Date dtNewDate = dtEffectiveDate.addDays(Integer.valueOf(strChangeSubmissionStartVariationNO));
					objCO.Submission_Deadline_Start_Date__c = checkDate(dtNewDate);
				}
			}
		} else if (
			(objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_PLAN_GROUP_LEVEL_CHANGES) || (objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES)
		) {
			objCO.Submission_Deadline_Start_Date__c = null;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  calculate the Submission deadline start date for Before and After Month Events
	 * @param         N/A
	 * @return       N/A
	 **/
	private void calculateStartDate(Carrier_Order__c objCO, Carrier_Version_Detail__c objCarrierVersion, Integer strVariationNO, String strEvent, Date dtEffectiveDate) {
		Integer intEffectiveday = dtEffectiveDate.day();
		Integer intMonth;
		if (strEvent == CarrierOrderUtil.BEFORE_EVENT) {
			intMonth = -1;
		} else if (strEvent == CarrierOrderUtil.AFTER_EVENT) {
			intMonth = 1;
		}

		Date newEffectiveDate = dtEffectiveDate.toStartOfMonth().addMonths(intMonth);
		objCO.Submission_Deadline_Start_Date__c = Date.newInstance(newEffectiveDate.year(), newEffectiveDate.month(), Integer.valueOf(strVariationNO));
	}

	/**
	 * @author       Deepika Saini
	 * @description  calculate the Termination Deadline Date on Parent CO of the Terminated CO
	 * @param        map of Id of parent CO and Child's Termination submission date
	 * @return       N/A
	 **/
	private void updateTerminationDateOnPreceedingCO(List<Carrier_Order__c> list_NewCarrierOrders, Map<Id, Carrier_Order__c> map_OldCarrierOrders) {
		List<Carrier_Order__c> list_UpdatedCOs = new List<Carrier_Order__c>();
		Map<Id, Carrier_Order__c> map_ParentIDToTerminatedCO = new Map<Id, Carrier_Order__c>();
		for (Carrier_Order__c objCarrierOrder : list_NewCarrierOrders) {
			Carrier_Order__c objOldCO = map_OldCarrierOrders.get(objCarrierOrder.Id);

			if ((objCarrierOrder.Term_Submission_Date__c != objOldCO.Term_Submission_Date__c && objCarrierOrder.Parent__c != null)) {
				map_ParentIDToTerminatedCO.put(objCarrierOrder.Parent__c, objCarrierOrder);
			}
		}

		if (!map_ParentIDToTerminatedCO.isEmpty()) {
			for (Id idValue : map_ParentIDToTerminatedCO.keySet()) {
				Carrier_Order__c objCO = new Carrier_Order__c(Id = idValue);
				list_UpdatedCOs.add(objCO);
			}
		}

		if (!list_UpdatedCOs.isEmpty()) {
			Boolean blnCOSkipTrigger = CarrierOrderTriggerHelper.skipTrigger;
			CarrierOrderTriggerHelper.skipTrigger = true;
			update list_UpdatedCOs;
			CarrierOrderTriggerHelper.skipTrigger = blnCOSkipTrigger;
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  update the stage detail when Implementation stage of terminated order is Termination Completed.
	 * @param        list of new Carrier orders values and Map of Old Carrier orders values
	 * @return       N/A
	 **/
	private void updateCarrierOrderStageDetail(List<Carrier_Order__c> list_CarrierOrders, Map<Id, Carrier_Order__c> map_OldCarrierOrders) {
		Set<Id> set_ParentCOIds = new Set<Id>();
		List<Carrier_Order__c> list_CarrierOrdersToUpdate = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCO : list_CarrierOrders) {
			if (objCO.Implementation_Stage__c != map_OldCarrierOrders.get(objCO.Id).Implementation_Stage__c) {
				set_ParentCOIds.add(objCO.Parent__c);
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  update preceding CO of terminated co if old precedding CO is Canceld.
	 * @param        list of new Carrier orders values
	 * @return       N/A
	 **/
	public void updateTerminatedCO(List<Carrier_Order__c> list_NewCarrierOrders) {
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();
		Map<String, Carrier_Order__c> map_TerminatedCOs = new Map<String, Carrier_Order__c>();
		if (!PolicyHelper.set_COSwitchIds.isEmpty()) {
			for (Carrier_Order__c objCO : list_NewCarrierOrders) {
				if (objCO.RecordTypeId == CarrierOrderUtil.RECTYPE_RENEWAL && objCO.Order_Type__c == CarrierOrderUtil.ORDER_TYPE_CARRIER_SWITCH) {
					list_CarrierOrders.add(objCO);
				}
			}

			if (!list_CarrierOrders.isEmpty()) {
				List<Carrier_Order__c> list_TerminatedCO = [
					SELECT Id, Parent__c, Benefit_Types__c, Benefit_Order__c, Parent__r.Implementation_Stage__c, Carrier__c
					FROM Carrier_Order__c
					WHERE Parent__c IN :PolicyHelper.set_COSwitchIds
				];
				for (Carrier_Order__c objTermCO : list_TerminatedCO) {
					map_TerminatedCOs.put(objTermCO.Carrier__c, objTermCO);
				}

				Map<Id, Carrier_Order__c> map_UpdatedCarriers = new Map<Id, Carrier_Order__c>();
				if (!map_TerminatedCOs.isEmpty()) {
					CarrierOrderHelperFunctions objCOHelpFunction = new CarrierOrderHelperFunctions();
					map_UpdatedCarriers = objCOHelpFunction.terminatedCOReparenting(list_CarrierOrders, map_TerminatedCOs, null, null);
				}

				if (!map_UpdatedCarriers.isEmpty()) {
					Boolean blnSkipTrg = CarrierOrderTriggerHelper.skipTrigger;
					CarrierOrderTriggerHelper.skipTrigger = true;
					update map_UpdatedCarriers.values();
					CarrierOrderTriggerHelper.skipTrigger = blnSkipTrg;
				}
			}
		}
	}

	/**
	 * @author       Bhagat singh
	 * @description  set Flag on Carrier Order. eg: increment No_Of_Submission_Automation_Attempts__c
	 * @param        list of new Carrier orders values & map of old Carrier orders.
	 * @return       N/A
	 **/
	public void setFlagOnCarrierOrder(List<Carrier_Order__c> list_NewCarrierOrders, Map<Id, Carrier_Order__c> map_OldCarrierOrders) {
		for (Carrier_Order__c objNewCO : list_NewCarrierOrders) {
			Carrier_Order__c objOldCO = map_OldCarrierOrders.get(objNewCO.Id);

			if (objNewCO.Eligible_for_Submission_Automation__c && !objOldCO.Eligible_for_Submission_Automation__c) {
				if (objNewCO.No_Of_Submission_Automation_Attempts__c == null) {
					objNewCO.No_Of_Submission_Automation_Attempts__c = 1;
				} else {
					objNewCO.No_Of_Submission_Automation_Attempts__c += 1;
				}
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Update Implementation Stage detail
	 * @param        list of new Carrier orders values and Map of Old Carrier orders values
	 * @return       NA
	 **/
	public void setCarrierOrderImpStage(List<Carrier_Order__c> list_CarrierOrders, Map<Id, Carrier_Order__c> map_OldCarrierOrder) {
		for (Carrier_Order__c objNewCO : list_CarrierOrders) {
			if (
				objNewCO.Benefit_Order__c != null &&
				objNewCO.Order_Type__c == CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP &&
				!map_Carrier.isEmpty() &&
				objNewCO.Carrier__c != null &&
				map_Carrier.containsKey(objNewCO.Carrier__c) &&
				map_Carrier.get(objNewCO.Carrier__c).Partner_Type__c != null &&
				map_Carrier.get(objNewCO.Carrier__c).Partner_Type__c == CarrierOrderUtil.PARTNER_TYPE_TADA
			) {
				if (
					objNewCO.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP &&
					(map_OldCarrierOrder == null || (map_OldCarrierOrder != null && map_OldCarrierOrder.get(objNewCO.Id).Implementation_Stage__c != objNewCO.Implementation_Stage__c))
				) {
					objNewCO.Stage_Detail__c = CarrierOrderUtil.CO_STAGE_DETAIL_READY_FOR_TADA_SETUP;
				} else if (
					objNewCO.Implementation_Stage__c == CarrierOrderUtil.STAGE_SUBMISSION_PREP &&
					(map_OldCarrierOrder == null || (map_OldCarrierOrder != null && map_OldCarrierOrder.get(objNewCO.Id).Implementation_Stage__c != objNewCO.Implementation_Stage__c))
				) {
					objNewCO.Stage_Detail__c = CarrierOrderUtil.CO_STAGE_DETAIL_TADA_SETUP_PENDING;
				} else if (
					objNewCO.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED &&
					(map_OldCarrierOrder == null || (map_OldCarrierOrder != null && map_OldCarrierOrder.get(objNewCO.Id).Implementation_Stage__c != objNewCO.Implementation_Stage__c))
				) {
					objNewCO.Stage_Detail__c = CarrierOrderUtil.CO_STAGE_DETAIL_TADA_SETUP_COMPLETE;
				}
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  Update Benefit Order Status and STatus Detail
	 * @param        Map of new Benefit orders values and Object of Benefit Order
	 * @return       Map<Id, Benefit_Order__c>
	 **/
	private static Map<Id, Benefit_Order__c> setBenefitOrdertoUpdate(Map<Id, Benefit_Order__c> map_BenefitOrderToUpdate, Benefit_Order__c objBO) {
		if (!map_BenefitOrderToUpdate.isEmpty() && map_BenefitOrderToUpdate.containsKey(objBO.Id)) {
			Benefit_Order__c objTempBO = map_BenefitOrderToUpdate.get(objBO.Id);
			objTempBO.Order_Status__c = objBO.Order_Status__c;
			objTempBO.Status_Detail__c = objBO.Status_Detail__c;
			map_BenefitOrderToUpdate.put(objTempBO.Id, objTempBO);
		} else {
			map_BenefitOrderToUpdate.put(objBO.Id, objBO);
		}
		return map_BenefitOrderToUpdate;
	}

	/* @author      Deepika Saini
	 * @description Update Fields on Carrier Order
	 * @param       List of Input Variables
	 * @return      NA
	 **/
	@InvocableMethod(label='SetCOIdsWithFalseSpecialEnrollment')
	public static void getCarrierOrderIdsWithFalseSpecialEnrollment(List<CarrierOrderIds> list_CarrierOrderIds) {
		for (CarrierOrderIds objCarrierOrderIds : list_CarrierOrderIds) {
			list_CarrierIdsFromFlow.addAll(objCarrierOrderIds.list_COWithfalseSpecialEnrollment);
		}
	}
	public class CarrierOrderIds {
		@InvocableVariable
		public List<String> list_COWithfalseSpecialEnrollment;
	}

	/**
	 * @Author      : Jai Aswani
	 * @Description : Validates Carrier Order Stage to Approved Only when Tasks are Completed
	 * @Parm        : newCarrierOrderList - List of SObject (Carrier_Order__c)
	 * @Parm        : oldCarrierOrderMap - Old State Map of SObject (Carrier_Order__c)
	 * @Return      : void
	 **/
	public static void validateCarrierOrderStage(Map<Id, Carrier_Order__c> newCarrierOrderMap, Map<Id, Carrier_Order__c> oldCarrierOrderMap) {
		Set<Id> carrierOrderIds = new Set<Id>();
		for (Carrier_Order__c carrierOrderRecord : newCarrierOrderMap.values()) {
			if (
				oldCarrierOrderMap == null ||
				(carrierOrderRecord.Implementation_Stage__c != oldCarrierOrderMap.get(carrierOrderRecord.Id).Implementation_Stage__c &&
				(carrierOrderRecord.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED_PENDING_EE_AUDIT ||
				carrierOrderRecord.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED))
			) {
				carrierOrderIds.add(carrierOrderRecord.Id);
			}
		}
		for (Task taskRecord : [
			SELECT Id, Status, WhatId
			FROM Task
			WHERE WhatId IN :carrierOrderIds AND Status != :TaskUtil.TASK_STATUS_COMPLETE AND RecordTypeId = :TaskUtil.TASK_BENEFIT_FULFILLMENT_RT_ID
			WITH SYSTEM_MODE
		]) {
			newCarrierOrderMap.get(taskRecord.WhatId).addError(System.Label.RestrictOrderApproveErrorMessage);
		}
	}

	/* @author      Deepika Saini
	 * @description  Assign Carrier Order Owner To The Opened Tickets
	 * @param        map_NewCarrierOrders - Old State of Map of SObject (Carrier_Order__c)
	 *				list_OldCarrierOrder - Old State List of SObject (Carrier_Order__c)
	 * @return      NA
	 **/
	public static void reassignInProgressTickets(Map<Id, Carrier_Order__c> map_NewCarrierOrders, List<Carrier_Order__c> list_OldCarrierOrder) {
		List<Id> list_CarrierOrderReassign = new List<Id>();
		for (Carrier_Order__c objCO : list_OldCarrierOrder) {
			if (objCO.OwnerId != map_NewCarrierOrders.get(objCO.Id).OwnerId && ('' + map_NewCarrierOrders.get(objCO.Id).OwnerId).startsWith(TicketUtil.USER_PREFIX)) {
				list_CarrierOrderReassign.add(objCO.Id);
			}
		}

		if (!list_CarrierOrderReassign.isEmpty()) {
			List<Ticket__c> list_TicketsToUpdate = new List<Ticket__c>();
			for (Ticket__c objTicket : [
				SELECT Id, OwnerId, Carrier_Order__c
				FROM Ticket__c
				WHERE
					Carrier_Order__c IN :list_CarrierOrderReassign
					AND Status__c != :TicketUtil.TICKET_STATUS_CLOSED
					AND (RecordTypeId = :TicketUtil.BENEFITS_ONBOARDING_NEWPLANS_TICKET_RT_ID
					OR RecordTypeId = :TicketUtil.BENEFITS_ONBOARDING_RENEWAL_TICKET_RT_ID)
			]) {
				if (map_NewCarrierOrders.containskey(objTicket.Carrier_Order__c)) {
					objTicket.OwnerId = map_NewCarrierOrders.get(objTicket.Carrier_Order__c).OwnerId;
					list_TicketsToUpdate.add(objTicket);
				}
			}

			if (!list_TicketsToUpdate.isEmpty()) {
				update list_TicketsToUpdate;
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Set Submission Dates as Enrollment Date
	 * @Parm        : objCO - SObject (Carrier_Order__c)
	 * @Return      : Carrier_Order__c
	 **/
	private static Carrier_Order__c setSubmissionDatesAsEnrollmentDate(Carrier_Order__c objCO) {
		objCO.Group_Submission_Date__c = dtSpecial_Enrollment_Date;
		objCO.submission_deadline__c = dtSpecial_Enrollment_Date;
		objCO.Member_Submission_Date__c = dtSpecial_Enrollment_Date;
		return objCO;
	}
}