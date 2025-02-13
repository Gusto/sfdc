/**
    Created by : Anand Singh
    Created Date : 23/03/2021
    Description: TransitiontoFulfilment related Utilities for reuse
**/
public class TransitiontoFulfilmentUtil {
	public static final String CARRIER_NAME_BASIC = 'BASIC';
	public static final String CO_CANCELED_STAGE = 'Canceled';
	public static final String CO_APPROVED_STAGE = 'Approved';
	public static final String CO_ORDER_TYPE_NEW_TO_GUSTO = 'New to Gusto';
	public static final String CO_ORDER_TYPE_CARRIER_SWITCH = 'Carrier switch';
	public static final String CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE = 'New Line of Coverage';
	public static final String CO_ORDER_TYPE_SAME_GROUP_LEVEL = 'Same carrier, plan/group level changes';
	public static final String CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL = 'Same carrier, No plan/group level changes';
	public static final String CO_ORDER_TYPE_TADA_NO_PRE_OE_SETUP = 'TAdA: No Pre OE Setup';
	public static final String CO_ORDER_TYPE_TADA_PRE_OE_SETUP = 'TAdA: Pre OE Setup';
	public static final String LABEL_PROCESSED = 'Processed';
	public static final String LABEL_TTS_POST_OE_EMAIL = 'tts_note_post_OE_email';
	public static final String LABEL_QA_SHEET_INFO = 'qa_sheet_info';
	public static Set<String> set_EventsType = new Set<String>{ LABEL_TTS_POST_OE_EMAIL, LABEL_QA_SHEET_INFO };
	public static final String MSG_WAITING_FOR_EVENT = 'We are waiting for the information from HI to get to the TTS once the information is received you will need to refresh the TTS page and upload the census. This can take about 5 minutes. If you are still experiencing this message please submit a Jira to BizTech.';
	public static final String EVENT_TYPE = 'Event';
	public static final String TTS_OBJECT_NAME = 'Transition_to_Fulfillment__c';
	public static final String QA_OBJECT_NAME = 'QA_Lines_Of_Coverage__c';
	public static final String CLD_OBJECT_NAME = 'Company_Level_Documents__c';
	public static final String CENSUS_SECTION_HEADER = 'Census Attachment';
	public static final String PLOICY_DETAILS_DENTAL_SECTION_HEADER = 'Policy Details (Dental/Vision)';
	public static final String PLOICY_DETAILS_LIDI_SECTION_HEADER = 'Policy Details (LiDi)';
	public static final String PLOICY_DETAILS_MEDICAL_SECTION_HEADER = 'Policy Details (Medical)';
	public static final String ALL_CHECK = 'All';
	public static final String COMPANY_LEVEL_DOCUMENTS = 'Company Level Documents';
	public static final String SUBMISSION_ADVOCATE = 'Submission Advocate';
	public static final String AUTOPOPULATE = 'Autopopulate';
	public static final String BENEFIT_TYPE_MEDICAL = 'Medical';
	public static final String BENEFIT_TYPE_DENTAL = 'Dental';
	public static final String BENEFIT_TYPE_VISION = 'Vision';
	public static final String BENEFIT_TYPE_LIFE = 'Life';
	public static final String BENEFIT_TYPE_STD = 'Short Term Disability';
	public static final String BENEFIT_TYPE_LTD = 'Long Term Disability';
	public static final String HSA = 'HSA';
	public static final String COMMUTER = 'Commuter';
	public static final String FLEXIBLE_SPENDING_ACCOUNT_MEDICAL = 'Flexible Spending Account - Medical';
	public static final String FLEXIBLE_SPENDING_ACCOUNT_DEPENDENT_CARE = 'Flexible Spending Account - Dependent Care';
	public static final String YES = 'Y';
	public static final String BENEFITS_NEW_PLAN = 'Benefits New Plan';
	public static final String BENEFITS_CHANGE = 'Benefits Change';

	public static final String TTS_EVENT = 'tts_note_post_OE_email';
	public static final String QA_SHEET_EVENT = 'qa_sheet_info';
	public static final String BANK_ADDRESS_API = 'Bank_Address__c';

	public static final String TTF_STATUS_SALES_SUBMITTED = 'Sales Submitted';
	public static final String TTF_STATUS_PT_APPROVED = 'PT Approved';

	public static String strTTFBenChangeRecTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
	public static String strTTFBenNewPlanRecTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
	public static String strBenRenewalRecTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
	public static String strBenBybRecTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BYB');
	public static String strBenBorRecTypeId = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');

	public static Schema.SObjectType ttfobjectType = Transition_to_Fulfillment__c.getSObjectType();
	public static List<String> list_TTFFields = new List<String>(ttfobjectType.getDescribe().fields.getMap().keySet());

	public final static Id BENEFIT_NEW_PLAN_TTF_RT_ID = Cache.getRecordTypeId('Transition_To_Fulfillment__c', 'Benefits New Plan');

	private static Map<String, String> map_PreviousPayrollProviders;
	public static final String BENEFITS_ADMIN = 'Benefits Admin';
	public static final String BENEFITS_SIGNATORY = 'Benefits Signatory';
	public static final String PRIMARY_PAYROLL_ADMIN = 'Primary Payroll Admin';

	//Getting Previous Payroll Provider Collect_Options based on Previous Payroll Provider
	public static Map<String, String> getPreviousPayrollProviders() {
		if (map_PreviousPayrollProviders == null) {
			fetchPreviousPayrollProviders();
		}
		return map_PreviousPayrollProviders;
	}

	private static void fetchPreviousPayrollProviders() {
		map_PreviousPayrollProviders = new Map<String, String>();
		for (Payroll_Transfer_Auto_Assign_Exceptions__mdt objPT : [SELECT Id, Previous_Payroll_Provider__c, Payroll_Provider_Collect_Options__c FROM Payroll_Transfer_Auto_Assign_Exceptions__mdt]) {
			map_PreviousPayrollProviders.put(objPT.Previous_Payroll_Provider__c, objPT.Payroll_Provider_Collect_Options__c);
		}
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Auto Populate Field values from HiGroupEvents
	 * @parm:           NA
	 * @return:         NA
	 */
	public static String autoPopulateValue(
		String strEventType,
		String strAttributeName,
		HIGroupEventTTSNotePostOEEmailJSON objHIGroupEventTTSNotePostOEEmailJSON,
		HIQaSheetWrapper objHIQaSheetWrapper
	) {
		String strValue;

		try {
			if (strEventType?.equalsIgnoreCase(TTS_EVENT)) {
				Map<String, Object> objDynamicInstance = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objHIGroupEventTTSNotePostOEEmailJSON));
				if (strAttributeName.equals('ghost_plans')) {
					List<HIGroupEventTTSNotePostOEEmailJSON.GhostPlans> listGhostPlans = (List<HIGroupEventTTSNotePostOEEmailJSON.GhostPlans>) JSON.deserialize(
						JSON.serialize(objDynamicInstance?.get(strAttributeName)),
						List<HIGroupEventTTSNotePostOEEmailJSON.GhostPlans>.class
					);
					if (listGhostPlans != null && !listGhostPlans.isEmpty()) {
						for (HIGroupEventTTSNotePostOEEmailJSON.GhostPlans objGhostPlan : listGhostPlans) {
							strValue = (String.isBlank(strValue) ? '' : strValue + '; ') + objGhostPlan.carrier_name;
							if (objGhostPlan.plan_details != null && !objGhostPlan.plan_details.isEmpty()) {
								strValue += ': ' + String.join(objGhostPlan.plan_details, ', ');
							}
						}
					}
				} else {
					strValue = (String) objDynamicInstance?.get(strAttributeName);
				}
			}

			if (strEventType?.equalsIgnoreCase(QA_SHEET_EVENT)) {
				Map<String, Object> objDynamicInstance = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objHIQaSheetWrapper));

				if (strAttributeName.equalsIgnoreCase('filing_address')) {
					Object objBenifitAddress = objDynamicInstance?.get(strAttributeName);

					Map<String, Object> map_BenefitAddress = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objBenifitAddress));
					strValue = '';

					if (map_BenefitAddress != null) {
						if (map_BenefitAddress.get('street_1') != null) {
							strValue += (String) map_BenefitAddress.get('street_1');
						}

						if (map_BenefitAddress.get('street_2') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('street_2');
						}

						if (map_BenefitAddress.get('city') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('city');
						}

						if (map_BenefitAddress.get('county_name') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('county_name');
						}

						if (map_BenefitAddress.get('state') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('state');
						}

						if (map_BenefitAddress.get('zip') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('zip');
						}

						if (map_BenefitAddress.get('country') != null) {
							strValue += ', ' + (String) map_BenefitAddress.get('country');
						}
					}
				} else if (strAttributeName.equalsIgnoreCase('scheduled_payroll_run_dates')) {
					List<Date> list_scheduledPayrollDates = objHIQaSheetWrapper != null ? objHIQaSheetWrapper.scheduled_payroll_run_dates : null;

					if (list_scheduledPayrollDates != null && !list_scheduledPayrollDates.isEmpty()) {
						strValue = '';
						for (Date payRollScheduleDate : list_scheduledPayrollDates) {
							if (payRollScheduleDate != null) {
								strValue += String.valueOf(payRollScheduleDate) + '; ';
							}
						}
					}
				} else {
					strValue = (String) objDynamicInstance?.get(strAttributeName);
				}
			}
		} catch (Exception objException) {
			// The autoPopulateValue method is called from VF Page -> Constructor and it is not possible to throw exception from constructor
			Exception_Log_Event__e newsEvent = new Exception_Log_Event__e(
				Class_Name__c = 'TransitiontoFulfilmentUtil',
				Message__c = objException.getMessage().left(131072),
				Method_Name__c = 'autoPopulateValue',
				Stack_Trace__c = objException.getStackTraceString().left(131072),
				Type__c = objException.getTypeName()
			);
			EventBus.publish(newsEvent);
		}

		return strValue;
	}

	public static String checkOrderStatus(Transition_to_Fulfillment__c objNewTTF) {
		String strOrderStatus = 'Same carrier, NO plan/group level changes';
		if (objNewTTF.Medical_Plan_Change__c == 'Y' || objNewTTF.Medical_Contribution_Change__c == 'Y' || objNewTTF.Medical_Waiting_Period_Change__c == 'Y') {
			strOrderStatus = 'Same carrier, plan/group level changes';
		}

		return strOrderStatus;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for Medical Plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of Medical Order Type
	 **/
	public static List<String> getOrderTypeforMedical(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_MedicalOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Carrier__c == YES || objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_MedicalOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if (objQALinesOfCoverage.Plan_changes__c == YES || objQALinesOfCoverage.Contribution_Change__c == YES || objQALinesOfCoverage.Waiting_Period_Change__c == YES) {
				list_MedicalOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_MedicalOrderType.size() == 0) {
			list_MedicalOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}

		return list_MedicalOrderType;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for Dental plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of Dental Order Type
	 **/
	public static List<string> getOrderTypeforDental(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_DentalOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_DentalOrderType.add(CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE);
			}
			if (objQALinesOfCoverage.New_Carrier__c == YES) {
				list_DentalOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if (objQALinesOfCoverage.Plan_changes__c == YES || objQALinesOfCoverage.Contribution_Change__c == YES || objQALinesOfCoverage.Waiting_Period_Change__c == YES) {
				list_DentalOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_DentalOrderType.size() == 0) {
			list_DentalOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}

		return list_DentalOrderType;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for vision  plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of Vision Order Type
	 **/
	public static List<string> getOrderTypeforVision(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_VisionOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_VisionOrderType.add(CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE);
			}
			if (objQALinesOfCoverage.New_Carrier__c == YES) {
				list_VisionOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if ((objQALinesOfCoverage.Plan_changes__c == YES || objQALinesOfCoverage.Contribution_Change__c == YES || objQALinesOfCoverage.Waiting_Period_Change__c == YES)) {
				list_VisionOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_VisionOrderType.size() == 0) {
			list_VisionOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}
		return list_VisionOrderType;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for Life Insurance plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of Life Insurance Order Type
	 **/
	public static List<string> getOrderTypeforLifeInsurance(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_LifeInsuranceOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_LifeInsuranceOrderType.add(CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE);
			}
			if (objQALinesOfCoverage.New_Carrier__c == YES) {
				list_LifeInsuranceOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if (objQALinesOfCoverage.Waiting_Period_Change__c == YES) {
				list_LifeInsuranceOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_lifeInsuranceOrderType.size() == 0) {
			list_lifeInsuranceOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}
		return list_lifeInsuranceOrderType;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for STD plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of STD Order Type
	 **/
	public static List<string> getOrderTypeforSTD(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_STDOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_STDOrderType.add(CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE);
			}
			if (objQALinesOfCoverage.New_Carrier__c == YES) {
				list_STDOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if (objQALinesOfCoverage.Waiting_Period_Change__c == YES) {
				list_STDOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_STDOrderType.size() == 0) {
			list_STDOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}
		return list_STDOrderType;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : get Order Type for LTD plan
	 * @parm        : strBenefitType - Benefit type
	 *                map_QALinesOfCoverage - Map of Benefit type and QA Line Of coverage
	 * @return      : list of LTD Order Type
	 **/
	public static List<string> getOrderTypeforLTD(String strBenefitType, Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage) {
		QA_Lines_Of_Coverage__c objQALinesOfCoverage;
		if (map_QALinesOfCoverage.containsKey(strBenefitType)) {
			objQALinesOfCoverage = map_QALinesOfCoverage.get(strBenefitType);
		}
		List<String> list_LTDOrderType = new List<String>();
		if (objQALinesOfCoverage != null) {
			if (objQALinesOfCoverage.New_Line_of_Coverage__c == YES) {
				list_LTDOrderType.add(CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE);
			}
			if (objQALinesOfCoverage != null && objQALinesOfCoverage.New_Carrier__c == YES) {
				list_LTDOrderType.add(CO_ORDER_TYPE_CARRIER_SWITCH);
			}
			if (objQALinesOfCoverage != null && objQALinesOfCoverage.Waiting_Period_Change__c == YES) {
				list_LTDOrderType.add(CO_ORDER_TYPE_SAME_GROUP_LEVEL);
			}
		}
		if (list_LTDOrderType.size() == 0) {
			list_LTDOrderType.add(CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL);
		}
		return list_LTDOrderType;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : set the Map of Contact Role with giving preference to Benefit Admin and Signatory
	 * @Parm        : Map<Id, OpportunityContactRole> Contact Id with Contact Role
	 * 				  OpportunityContactRole Contact Role
	 * @Return      : Map<Id, OpportunityContactRole>
	 **/
	public static Map<Id, OpportunityContactRole> setPreferredContactRole(Map<Id, OpportunityContactRole> map_ContactRole, OpportunityContactRole objConRole) {
		if (!map_ContactRole.containsKey(objConRole.ContactId)) {
			map_ContactRole.put(objConRole.ContactId, objConRole);
		} else {
			if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_ADMIN) {
				map_ContactRole.put(objConRole.ContactId, objConRole);
			} else if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_SIGNATORY && map_ContactRole?.get(objConRole.ContactId).role != TransitiontoFulfilmentUtil.BENEFITS_ADMIN) {
				map_ContactRole.put(objConRole.ContactId, objConRole);
			}
		}
		return map_ContactRole;
	}
}