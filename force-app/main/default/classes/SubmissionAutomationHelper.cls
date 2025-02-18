/**
 * @name         SubmissionAutomationHelper
 * @author       Deepika Saini
 * @date         22-Jan-2021
 * @description  Utility class for Submission Automation on Carrier Orders
 * @test classes
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class SubmissionAutomationHelper {
	static Set<String> set_QueueName = new Set<String>{ CarrierOrderUtil.AUTOMATION_QUEUE, CarrierOrderUtil.CARRIER_IMPLEMENTATION_QUEUE };
	static Map<String, Id> map_Queue = GlobalQueryHelper.getNameQueueMap(set_QueueName);

	/*
	 * Process HIGroupEvents and copy information to Carrier Orders
	 */
	public static void processSubmissionAutomationEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_CarrierOrderIds = new Set<String>();
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationType = new Set<String>();
		Set<String> set_StateCarrierIds = new Set<String>();

		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}

		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent = new Map<String, HIGroupEvent__c>();
		Map<String, CarrierOrderInfoWrapper> map_CarrierOrderInfoWrap = new Map<String, CarrierOrderInfoWrapper>();
		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objEvent);
				continue;
			}
			map_EventIdHIGrpEvent.put(objEvent.Event_Id__c, objEvent);

			try {
				SubmissionAutomationJSON objEventInfoJSON = (SubmissionAutomationJSON) JSON.deserialize(objEvent.Event_Info__c, SubmissionAutomationJSON.class);

				CarrierOrderInfoWrapper objCOWrap = new CarrierOrderInfoWrapper(
					objEventInfoJSON.automation_status,
					objEventInfoJSON.automation_message,
					objEvent.Event_Id__c,
					objEventInfoJSON.hippo_link
				);

				String strCOIdKey = '';
				if (String.isNotBlank(objEvent.Carrier_Order_Id__c)) {
					strCOIdKey = objEvent.Carrier_Order_Id__c;
					if (String.isNotBlank(strCOIdKey) && strCOIdKey.length() > 15) {
						strCOIdKey = strCOIdKey.substring(0, 15);
					}
				}

				if (String.isNotBlank(strCOIdKey)) {
					set_CarrierOrderIds.add(strCOIdKey);
					map_CarrierOrderInfoWrap.put(strCOIdKey, objCOWrap);
					continue;
				}

				if (String.isBlank(objEvent.State_Carrier_Id__c)) {
					if (String.isBlank(objEventInfoJSON.state_carrier_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_STATE_CARRIER_MISSING, objEvent);
						continue;
					}
					objEvent.State_Carrier_Id__c = objEventInfoJSON.state_carrier_id;
				}
				set_StateCarrierIds.add(objEvent.State_Carrier_Id__c);

				if (String.isBlank(objEvent.Application_Id__c)) {
					if (String.isBlank(objEventInfoJSON.application_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING, objEvent);
						continue;
					}
					objEvent.Application_Id__c = objEventInfoJSON.application_id;
				}
				set_ApplicationIds.add(objEvent.Application_Id__c);

				if (String.isBlank(objEvent.Application_type__c)) {
					if (String.isBlank(objEventInfoJSON.application_type)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING, objEvent);
						continue;
					}
					objEvent.Application_type__c = objEventInfoJSON.application_type;
				}
				set_ApplicationType.add(objEvent.Application_type__c);

				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfoJSON.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objEvent);
						continue;
					}
					objEvent.Company_Id__c = objEventInfoJSON.company_id;
				}
				set_CompanyIds.add(objEvent.Company_Id__c);

				String strKey = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c + '-' + objEvent.State_Carrier_Id__c;
				map_CarrierOrderInfoWrap.put(strKey, objCOWrap);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
			}
		}

		try {
			if (set_CarrierOrderIds.isEmpty() && (set_ApplicationIds.isEmpty() || set_CompanyIds.isEmpty() || set_ApplicationType.isEmpty() || set_StateCarrierIds.isEmpty())) {
				return;
			}

			updateCarrierOrders(map_EventIdHIGrpEvent, map_CarrierOrderInfoWrap, set_ApplicationIds, set_CompanyIds, set_ApplicationType, set_StateCarrierIds, set_CarrierOrderIds);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException(
				'SubmissionAutomationHelper',
				'processSubmissionAutomationEvents',
				'Exception On Line ' +
				objEx.getLineNumber() +
				'-' +
				objEx.getMessage(),
				objEx.getStackTraceString()
			);
		}
	}

	static void updateCarrierOrders(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvent,
		Map<String, CarrierOrderInfoWrapper> map_CarrierOrderInfoWrap,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds,
		Set<String> set_ApplicationType,
		Set<String> set_StateCarrierIds,
		Set<String> set_CarrierOrderIds
	) {
		Set<String> set_ProcessingStateCheck = new Set<String>();
		set_ProcessingStateCheck.add(IntegrationUtils.DEAD_STATE);
		set_ProcessingStateCheck.add(IntegrationUtils.ERROR_STATE);

		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		Map<String, String> map_EventIdToCarrierOrder = new Map<String, String>();
		List<Carrier_Order__c> list_COToUpdate = new List<Carrier_Order__c>(), list_COMovedToConfirmation = new List<Carrier_Order__c>();
		List<FeedItem> list_FeedItems = new List<FeedItem>(); //to create feed for Carrier Order when there is an update
		for (Carrier_Order__c objCO : [
			SELECT
				Id,
				HI_Submission_Automation_Status__c,
				HI_Submission_Automation_Message__c,
				Carrier__r.Id__c,
				Benefit_Order__r.Application_Id__c,
				Benefit_Order__r.RecordType.Name,
				Benefit_Order__r.Account__r.ZP_Company_Id__c,
				Order_Type__c,
				Eligible_for_Submission_Automation__c,
				Hippo_Link__c,
				Implementation_Stage__c,
				Effective_Date__c,
				OwnerId
			FROM Carrier_Order__c
			WHERE
				Id IN :set_CarrierOrderIds
				OR (Carrier__c != NULL
				AND Carrier__r.Id__c IN :set_StateCarrierIds
				AND Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Benefit_Order__r.Application_Id__c != NULL
				AND Benefit_Order__r.Application_Id__c IN :set_ApplicationIds
				AND Benefit_Order__r.RecordType.Name IN :set_ApplicationType
				AND RecordType.Name IN :HIGroupEventUtil.set_EligibleCORecTypesForAutomation)
		]) {
			String strKey =
				objCO.Benefit_Order__r.Account__r.ZP_Company_Id__c +
				'-' +
				objCO.Benefit_Order__r.Application_Id__c +
				'-' +
				objCO.Benefit_Order__r.RecordType.Name +
				'-' +
				objCO.Carrier__r.Id__c;

			String strCOIdKey = objCO.Id;
			if (strCOIdKey.length() > 15) {
				strCOIdKey = strCOIdKey.substring(0, 15);
			}

			CarrierOrderInfoWrapper objCOWrapper = null;
			if (map_CarrierOrderInfoWrap.containsKey(strCOIdKey)) {
				objCOWrapper = map_CarrierOrderInfoWrap.get(strCOIdKey);
			} else if (map_CarrierOrderInfoWrap.containsKey(strKey)) {
				objCOWrapper = map_CarrierOrderInfoWrap.get(strKey);
			}

			if (objCOWrapper != null) {
				map_EventIdToCarrierOrder.put(objCOWrapper.strEventId, objCO.Id);

				objCO.HI_Submission_Automation_Message__c = objCOWrapper.strAutomationMessage;
				objCO.HI_Submission_Automation_Status__c = objCOWrapper.strAutomationStatus;
				objCO.Hippo_Link__c = objCOWrapper.strHippoLink;
				String strFeedText = 'Submission Automation Details::\nStatus : ' + (String.isNotBlank(objCOWrapper.strAutomationStatus) ? objCOWrapper.strAutomationStatus : '');
				strFeedText += '\nMessage : ' + (String.isNotBlank(objCOWrapper.strAutomationMessage) ? objCOWrapper.strAutomationMessage : '');
				strFeedText += '\nHippo Link : ' + (String.isNotBlank(objCOWrapper.strHippoLink) ? objCOWrapper.strHippoLink : '');

				list_FeedItems.add(new FeedItem(Type = HIGroupEventUtil.FEED_TEXT_POST, Visibility = HIGroupEventUtil.FEED_VISIBILITY_ALL, ParentId = objCO.Id, Body = strFeedText));

				if (
					String.isNotBlank(objCOWrapper.strAutomationStatus) &&
					HIGroupEventUtil.STATUS_SUCCESS.equalsIgnoreCase(objCOWrapper.strAutomationStatus) &&
					objCO.Eligible_for_Submission_Automation__c &&
					HIGroupEventUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP.equalsIgnoreCase(objCO.Implementation_Stage__c)
				) {
					//Move to confirmation
					objCO.Implementation_Stage__c = HIGroupEventUtil.CO_STATUS_READY_FOR_CONFIRMATION;
					objCO.Eligible_for_Submission_Automation__c = false;
					objCO.Automated_Submission__c = CarrierOrderUtil.CO_SUBMISSION_AUTOMATED_VIA_HI;
					list_COMovedToConfirmation.add(objCO);
					objCO.Eligible_for_Submission_Automation__c = false;
					continue;
				}
				objCO.Eligible_for_Submission_Automation__c = false;
				if (objCO.OwnerId == map_Queue.get(CarrierOrderUtil.AUTOMATION_QUEUE)) {
					objCO.OwnerId = map_Queue.get(CarrierOrderUtil.CARRIER_IMPLEMENTATION_QUEUE);
				}

				list_COToUpdate.add(objCO);
			}
		}

		if (!list_COMovedToConfirmation.isEmpty()) {
			list_COMovedToConfirmation = OnboardingPlayModeUtility.setFirstPlayDateForCarrierOrders('Order', list_COMovedToConfirmation);
			list_COToUpdate.addAll(list_COMovedToConfirmation);
		}

		Map<String, String> map_COUpdateErrors = new Map<String, String>(), map_FeedInsertErrors = new Map<String, String>();

		if (!list_COToUpdate.isEmpty()) {
			Database.SaveResult[] objResults = Database.update(list_COToUpdate, false);

			if (!list_FeedItems.isEmpty()) {
				Database.SaveResult[] list_FeedResults = Database.insert(list_FeedItems, false);
				map_FeedInsertErrors = Utils.processSaveResult(list_FeedResults, list_FeedItems, 'ParentId', true, 'SubmissionAutomationHelper');
			}
			map_COUpdateErrors = Utils.processSaveResult(objResults, list_COToUpdate, 'Id', true, 'SubmissionAutomationHelper');
		}

		for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvent.values()) {
			if (set_ProcessingStateCheck.contains(objEvent.Processing_State__c)) {
				continue;
			}
			if (!map_EventIdToCarrierOrder.containsKey(objEvent.Event_Id__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_UNPROCESSED_EVENT, objEvent);
				continue;
			}
			String strCOId = map_EventIdToCarrierOrder.get(objEvent.Event_Id__c);
			if (map_COUpdateErrors.containsKey(strCOId)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_COUpdateErrors.get(strCOId), objEvent);
				continue;
			} else if (map_FeedInsertErrors.containsKey(strCOId)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, map_FeedInsertErrors.get(strCOId), objEvent);
				continue;
			} else {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIGroupEventUtil.PROCESSED_MESSAGE, objEvent);
			}
		}
	}

	/*
	 * @author:         Bhagat Singh
	 * @description:    Check Carrier Order eligible for route to Automation.
	 * @parm:           Map of Carrier Order
	 * @return:         NA
	 */
	public static void checkCOToAutomation(Map<Id, Carrier_Order__c> map_CarrierOrderToBeUpdated) {
		List<Carrier_Order__c> list_ValidCOs = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCO :map_CarrierOrderToBeUpdated.values()) {
			if (objCO.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED) {
				list_ValidCOs.add(objCO);
			}
		}

		List<Carrier_Order__c> list_COsAfterEligibility = routeSubmissionCOToAutomation(list_ValidCOs);
		if (!list_COsAfterEligibility.isEmpty()) {
			for (Carrier_Order__c objUpdatedCO : list_COsAfterEligibility) {
				if (map_CarrierOrderToBeUpdated.containsKey(objUpdatedCO.Id)) {
					Carrier_Order__c objCO = map_CarrierOrderToBeUpdated.get(objUpdatedCO.Id);
					if (objCO.OwnerId != objUpdatedCO.OwnerId) {
						objCO.Is_Order_Eligible_For_Sub_Automation__c = objUpdatedCO.Is_Order_Eligible_For_Sub_Automation__c;
					}
					objCO.Eligible_for_Submission_Automation__c = objUpdatedCO.Eligible_for_Submission_Automation__c;
					objCO.OwnerId = objUpdatedCO.OwnerId;
					objCO.Plan_Change__c = objUpdatedCO.Plan_Change__c;
					objCO.Waiting_Period_Change__c = objUpdatedCO.Waiting_Period_Change__c;
					objCO.Contribution_Change__c = objUpdatedCO.Contribution_Change__c;
				}
			}
		}
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Route submission orders to the automation.
	 * @parm:           NA
	 * @return:         NA
	 */
	public static List<Carrier_Order__c> routeSubmissionCOToAutomation(List<Carrier_Order__c> list_COToCheckEligibility) {
		Set<Id> set_CarrierIds = new Set<Id>();
		Map<String, String> map_BenfitChangeTypeAndAPI = new Map<String, String>();

		map_BenfitChangeTypeAndAPI.put('CS Change', 'Contribution_Change__c');
		map_BenfitChangeTypeAndAPI.put('WP Change', 'Waiting_Period_Change__c');
		map_BenfitChangeTypeAndAPI.put('Plan Change', 'Plan_Change__c');

		Set<Id> set_CarrierIdWithSubEligibility = new Set<Id>();

		for (Carrier_Order__c objCO : list_COToCheckEligibility) {
			set_CarrierIds.add(objCO.Id);
			if (objCO.Is_Order_Eligible_For_Sub_Automation__c) {
				set_CarrierIdWithSubEligibility.add(objCO.Id);
			}
		}

		if (!set_CarrierIds.isEmpty()) {
			list_COToCheckEligibility = new List<Carrier_Order__c>();
			list_COToCheckEligibility = CarrierOrderUtil.getCarrierOrders(set_CarrierIds);
		}

		BusinessHours objBusinessHours = GlobalQueryHelper.getDefaultBusinessHour();
		Map<Id, Carrier_Order__c> map_IdANDCO = updateBenefitTypeChangeValues(list_COToCheckEligibility);
		Integer intNoOfBusinessDays = 0;

		for (Carrier_Order__c objCO : list_COToCheckEligibility) {
			if (objCO.Carrier__c == null || objCO.Carrier__r.Carrier_Id__c == null || objCO.Carrier__r.State__c == null) {
				continue;
			}
			for (RPA_Submission_Automation_rules__mdt objSubmissionRules : RPA_Submission_Automation_rules__mdt.getAll().values()) {
				if (objSubmissionRules.Active__c) {
					Boolean blnWithinBusinessDays = true;

					Set<String> set_HICarrierIds = new Set<String>();
					if (String.isNotBlank(objSubmissionRules.HI_Carrier_Id__c)) {
						set_HICarrierIds.addAll(objSubmissionRules.HI_Carrier_Id__c.split(';'));
					}
					System.debug('set_HICarrierIds--------->' + set_HICarrierIds);
                    System.debug(objSubmissionRules.Carrier_Id__c + '--------->' + objCO.Carrier__r.Carrier_Id__c);
                    System.debug(objSubmissionRules.Order_Type__c + '--------->' + objCO.Order_Assignment__c);
                    System.debug(objCO.Carrier__r.Id__c + '--------->' + set_HICarrierIds.contains(objCO.Carrier__r.Id__c));
                    System.debug('--------->' + set_HICarrierIds);
					if (
						objSubmissionRules.Carrier_Id__c.equalsIgnoreCase(objCO.Carrier__r.Carrier_Id__c) &&
						objSubmissionRules.Order_Type__c != null &&
						objCO.Order_Assignment__c != null &&
						objSubmissionRules.Order_Type__c.containsIgnoreCase(objCO.Order_Assignment__c) &&
						(set_HICarrierIds.isEmpty() || (set_HICarrierIds != null && set_HICarrierIds.contains(objCO.Carrier__r.Id__c)))
					) {
						intNoOfBusinessDays = 0;
						if (objSubmissionRules.No_of_Business_Days__c != null) {
							intNoOfBusinessDays = Integer.valueOf(objSubmissionRules.No_of_Business_Days__c);
							if (calculateBusinessWorkingDays(objBusinessHours.Id, objCO.Submission_Deadline_Date__c) > intNoOfBusinessDays) {
								blnWithinBusinessDays = true;
							} else {
								blnWithinBusinessDays = false;
							}
						}

						if (objSubmissionRules.No_of_days_to_Effective_Deadline__c != null) {
							intNoOfBusinessDays = Integer.valueOf(objSubmissionRules.No_of_days_to_Effective_Deadline__c);
							if (calculateBusinessWorkingDays(objBusinessHours.Id, objCO.Effective_Date__c) > intNoOfBusinessDays) {
								blnWithinBusinessDays = true;
							} else {
								blnWithinBusinessDays = false;
							}
						}
						System.debug('-111-------->' + blnWithinBusinessDays);
						if (blnWithinBusinessDays) {
                            System.debug('--------->' + objSubmissionRules.Submission_Type__c);
							if (objSubmissionRules.Submission_Type__c?.equalsIgnoreCase(Utils.HI_ONLY) && validateHIOnlyCOForAutomation(objSubmissionRules, objCO)) {
								System.debug('--------->' + objSubmissionRules.Submission_Type__c);
                                objCO.Eligible_for_Submission_Automation__c = true;
								objCO.Sent_to_HI_for_Submission__c = false;
								objCO.HI_Submission_Automation_Status__c = '';
								objCO.HI_Submission_Automation_Message__c = '';
							} else if (
								objSubmissionRules.Submission_Type__c?.equalsIgnoreCase(Utils.RPA_ONLY) &&
								set_CarrierIdWithSubEligibility.contains(objCO.Id) &&
								validateRPACOForAutomation(objSubmissionRules, objCO)
							) {
								List<String> list_ChangeType = new List<String>();
								if (String.isNotBlank(objSubmissionRules.Dont_Allow__c)) {
									list_ChangeType = objSubmissionRules.Dont_Allow__c.split(';');
								}

								Boolean blnAllowAutomation = true;
								if (map_IdANDCO != null && map_IdANDCO.containsKey(objCO.Id)) {
									objCO.Waiting_Period_Change__c = map_IdANDCO.get(objCO.Id).Waiting_Period_Change__c;
									objCO.Contribution_Change__c = map_IdANDCO.get(objCO.Id).Contribution_Change__c;
									objCO.Plan_Change__c = map_IdANDCO.get(objCO.Id).Plan_Change__c;
								}

								for (String changeType : list_ChangeType) {
									if (objCO.get(map_BenfitChangeTypeAndAPI.get(changeType)) == 'Yes') {
										blnAllowAutomation = false;
										break;
									}
								}

								if (blnAllowAutomation) {
									objCO.OwnerId = map_Queue.get('Automation Queue');
									objCO.Is_Order_Eligible_For_Sub_Automation__c = false;

									if (objCO.No_Of_Submission_Automation_Attempts__c == null) {
										objCO.No_Of_Submission_Automation_Attempts__c = 1;
									} else {
										objCO.No_Of_Submission_Automation_Attempts__c += 1;
									}
								}
							} else if (
								objSubmissionRules.Submission_Type__c?.equalsIgnoreCase(Utils.HI_AND_RPA) &&
								set_CarrierIdWithSubEligibility.contains(objCO.Id) &&
								validateRPACOForAutomation(objSubmissionRules, objCO)
							) {
								objCO.OwnerId = map_Queue.get('Automation Queue');
								objCO.Eligible_for_Submission_Automation__c = true;
								objCO.Is_Order_Eligible_For_Sub_Automation__c = false;
								objCO.Sent_to_HI_for_Submission__c = false;
								objCO.HI_Submission_Automation_Status__c = '';
								objCO.HI_Submission_Automation_Message__c = '';
								objCO.Automation_Status__c = '';
								objCO.Automation_Message__c = '';
								objCO.Automation_Message_Details__c = '';
							}
						}
					}
				}
			}
		}

		return list_COToCheckEligibility;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Validate RPA Only and HI & RPA COs for the automation eligibility.
	 * @parm:           NA
	 * @return:         NA
	 */
	public static Boolean validateRPACOForAutomation(RPA_Submission_Automation_rules__mdt objSubmissionRules, Carrier_Order__c carrierOrderToValidate) {
		Boolean blnIsEligible = false;
		if (
			carrierOrderToValidate.Submitted_Completed_Datetime__c == null &&
			!carrierOrderToValidate.Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c &&
			!carrierOrderToValidate.policies__r.isEmpty() &&
			carrierOrderToValidate.Parent_Carrier_Order__c == null &&
			!carrierOrderToValidate.Is_Multi_EIN__c
		) {
			if (
				!CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO.equalsIgnoreCase(carrierOrderToValidate.Order_Assignment__c) &&
				!CarrierOrderUtil.ORDER_TYPE_CARRIER_SWITCH.equalsIgnoreCase(carrierOrderToValidate.Order_Assignment__c) &&
				String.isNotBlank(carrierOrderToValidate.Group_Number__c)
			) {
				blnIsEligible = true;
			} else if (
				CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO.equalsIgnoreCase(carrierOrderToValidate.Order_Assignment__c) ||
				CarrierOrderUtil.ORDER_TYPE_CARRIER_SWITCH.equalsIgnoreCase(carrierOrderToValidate.Order_Assignment__c) && String.isBlank(carrierOrderToValidate.Group_Number__c)
			) {
				blnIsEligible = true;
			}
		}
		return blnIsEligible;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Validate HI Only for the automation eligibility.
	 * @parm:           NA
	 * @return:         NA
	 */
	public static Boolean validateHIOnlyCOForAutomation(RPA_Submission_Automation_rules__mdt objSubmissionRules, Carrier_Order__c carrierOrderToValidate) {
		Boolean blnIsEligible = false;
		if (
			carrierOrderToValidate.Effective_Date__c != null &&
			!carrierOrderToValidate.Eligible_for_Submission_Automation__c &&
			!carrierOrderToValidate.Sent_to_HI_for_Submission__c &&
			carrierOrderToValidate.Benefit_Order__c != null &&
			carrierOrderToValidate.Benefit_Order__r.Parent_Benefit_Order__c == null &&
			!carrierOrderToValidate.Benefit_Order__r.Is_Multi_EIN__c &&
			!carrierOrderToValidate.Benefit_Order__r.Transition_To_Fulfillment__r.Do_they_have_affiliates__c &&
			!carrierOrderToValidate.policies__r.isEmpty() &&
			carrierOrderToValidate.Parent_Carrier_Order__c == null &&
			!carrierOrderToValidate.Is_Multi_EIN__c
		) {
			blnIsEligible = true;
		}
		return blnIsEligible;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Calculate Business Hours
	 * @parm:           NA
	 * @return:         NA
	 */
	public static Integer calculateBusinessWorkingDays(Id businessHourId, Datetime dateToCalculate) {
		Integer intCount = 0;
		Date dtStartDate = Date.today();
		Datetime dtCurrentDateTime = System.now();
		Time objTime = Time.newInstance(10, 10, 10, 0);
		while (dtStartDate <= dateToCalculate) {
			dtCurrentDateTime = Datetime.newInstance(dtStartDate, objTime);
			if (BusinessHours.isWithin(businessHourId, dtCurrentDateTime)) {
				intCount++;
			}
			dtStartDate = dtStartDate.addDays(1);
		}

		return intCount;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Populate Benefit Type changes
	 * @parm:           NA
	 * @return:         NA
	 */
	public static Map<Id, Carrier_Order__c> updateBenefitTypeChangeValues(List<Carrier_Order__c> list_CO) {
		Set<String> set_TTFRecordTypes = new Set<String>{ TransitiontoFulfilmentUtil.strBenRenewalRecTypeId, TransitiontoFulfilmentUtil.strTTFBenChangeRecTypeId };
		Set<Id> set_BOIds = new Set<Id>();
		Map<Id, Carrier_Order__c> map_IdANDCO = new Map<Id, Carrier_Order__c>();
		Map<Id, Transition_to_Fulfillment__c> map_BOToTTF = new Map<Id, Transition_to_Fulfillment__c>();
		for (Carrier_Order__c objCO : list_CO) {
			set_BOIds.add(objCO.Benefit_Order__c);
		}

		List<Transition_to_Fulfillment__c> list_TTFs = [
			SELECT
				Id,
				Benefit_Order__c,
				Medical_Plan_Change__c,
				Medical_Waiting_Period_Change__c,
				Medical_Contribution_Change__c,
				Vision_Waiting_Period_Change__c
			FROM Transition_to_Fulfillment__c
			WHERE
				Benefit_Order__c != null AND
				Benefit_Order__c IN :set_BOIds AND
				RecordTypeId IN :set_TTFRecordTypes
		];

		if (list_TTFs != null && list_TTFs.size() > 0) {
			for (Transition_to_Fulfillment__c objTTF : list_TTFs) {
				map_BOToTTF.put(objTTF.Benefit_Order__c, objTTF);
			}
		}

		for (Carrier_Order__c objCarrierOrder : list_CO) {
			if (map_BOToTTF != null && map_BOToTTF.size() > 0 && map_BOToTTF.containsKey(objCarrierOrder.Benefit_Order__c)) {
				Transition_to_Fulfillment__c objTTFTemp = map_BOToTTF.get(objCarrierOrder.Benefit_Order__c);
				Carrier_Order__c objCO = setCOChangeFields(objTTFTemp, objCarrierOrder);
				map_IdANDCO.put(objCarrierOrder.Id, objCO);
			}
		}

		return map_IdANDCO;
	}

	class CarrierOrderInfoWrapper {
		String strAutomationStatus;
		String strAutomationMessage;
		String strEventId;
		String strHippoLink;
		CarrierOrderInfoWrapper(String strStatus, String strMessage, String strEvent, String strHippoLink) {
			strAutomationStatus = strStatus;
			strAutomationMessage = strMessage;
			strEventId = strEvent;
			this.strHippoLink = strHippoLink;
		}
	}

	/**
	 * @author        Deepika Saini
	 * @description   This method is used to set change feilds of CO.
	 * @param         TTF record with respect to CO record.
	 * @return        Carrier order record.
	 **/
	public static Carrier_Order__c setCOChangeFields(Transition_to_Fulfillment__c objTTFTemp, Carrier_Order__c objCarrierOrder) {
		Carrier_Order__c objCO = new Carrier_Order__c();

		objCO.Plan_Change__c = CarrierOrderUtil.NO;
		objCO.Waiting_Period_Change__c = CarrierOrderUtil.NO;
		objCO.Contribution_Change__c = CarrierOrderUtil.NO;

		if (objCarrierOrder.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_MEDICAL)) {
			if (objTTFTemp.Medical_Plan_Change__c == CarrierOrderUtil.PICKLIST_VALUE_YES) {
				objCO.Plan_Change__c = CarrierOrderUtil.YES;
			}

			if (objTTFTemp.Medical_Waiting_Period_Change__c == CarrierOrderUtil.PICKLIST_VALUE_YES) {
				objCO.Waiting_Period_Change__c = CarrierOrderUtil.YES;
			}

			if (objTTFTemp.Medical_Contribution_Change__c == CarrierOrderUtil.PICKLIST_VALUE_YES) {
				objCO.Contribution_Change__c = CarrierOrderUtil.YES;
			}
		}

		if (objCarrierOrder.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_VISION)) {
			if (objTTFTemp.Vision_Waiting_Period_Change__c == CarrierOrderUtil.PICKLIST_VALUE_YES) {
				objCO.Waiting_Period_Change__c = CarrierOrderUtil.YES;
			}
		}

		if (objCarrierOrder.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LIFE)) {
			objCO.Waiting_Period_Change__c = CarrierOrderUtil.YES;
		}

		if (objCarrierOrder.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_LTD)) {
			objCO.Waiting_Period_Change__c = CarrierOrderUtil.YES;
		}

		if (objCarrierOrder.Benefit_Types__c.containsIgnoreCase(HIEnrollmentEventUtility.BENEFIT_TYPE_STD)) {
			objCO.Waiting_Period_Change__c = CarrierOrderUtil.YES;
		}

		return objCO;
	}
}