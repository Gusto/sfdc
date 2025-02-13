/**
* @name         HIGroupEventQASheetHandler
* @description  This class handels the HIGroupEvent__c object json parsing and field mapping to  QA_Sheet__c, TTIA,
				Company_Level_Documents__c, QA_Lines_OF_Coverage and Benefi_Order__c objects
* @test class   HIGroupEventQASheetHandlerTest.cls
**/
public class HIGroupEventQASheetHandler {
	public static final String SUCCESSOR_PREDECESSOR = 'Predecessor Policy Name:Successor Plan Name';
	public static final String STR_UNKNOWN = 'unknown';
	public static final string SUBJECT_TO_FEDERAL = 'Federal';
	static final Id BENEFIT_ORDER_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	static final Id BENEFIT_ORDER_RT_RENEWAL = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	static Id CARRIER_ORDER_NEW_PLAN_RT = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
	static Id CARRIER_ORDER_RENEWAL_RT = Cache.getRecordTypeId('Carrier_Order__c', 'Renewal');
	static final string CARRIER_BASIC_PACIFIC_RENEWAL = 'BASIC PACIFIC Renewal';
	static final string CARRIER_BASIC_PACIFIC_SETUP = 'BASIC PACIFIC Setup';
	private static Map<String, String> map_QAEvent_OpptyType = new Map<String, String>{
		'Renewal' => 'Benefits_Renewal',
		'NewPlansApplication' => 'Benefits_New_Plan',
		'BenefitChangeApplication' => 'Benefits_Change'
	};
	private static Map<String, String> map_coverageType = new Map<String, String>{
		'long_term_disability' => 'Long Term Disability',
		'short_term_disability' => 'Short Term Disability'
	};
	private static Map<String, String> map_companyDoc = new Map<String, String>{
		'pending_in_gusto' => 'Pending in Gusto',
		'exists_in_gdrive' => 'In gdrive',
		'request_from_er' => 'Request from ER'
	};
	public Map<String, String> map_TaDaTypes = new Map<String, String>{
		'hsa' => 'HSA',
		'commuter' => 'Commuter',
		'fsa' => 'Flexible Spending Account - Medical',
		'dca' => 'Flexible Spending Account - Dependent Care'
	};
	public static Set<Id> set_OppRTIds = QASheetHelper.set_opptyRecordTypeIds;
	public static Set<String> set_OppStage = new Set<String>{ 'Closed Won', 'Order Lost', 'Closed Lost Disqualified', 'Suspended', 'Closed Admin', 'Order Lost', 'Closed Lost' };
	Set<Id> set_BenefitOrderIds = new Set<Id>();

	public void processInformation(List<HIEventWrapper> list_QASheetEvent) {
		if (list_QASheetEvent != null && !list_QASheetEvent.isEmpty()) {
			Map<String, HIGroupEvent__c> map_HIGroupEvent = new Map<String, HIGroupEvent__c>();
			Map<String, HIQASheetWrapper> map_HIQASheetWrapper = new Map<String, HIQASheetWrapper>();
			Set<String> set_companyIds = new Set<String>();

			for (HIEventWrapper objHIGroupEventWrapper : list_QASheetEvent) {
				HIGroupEvent__c objHIGroupEvent = (HIGroupEvent__c) objHIGroupEventWrapper.objHiGroupEvent;
				try {
					String strJson = objHIGroupEventWrapper.jsonString;
					HIQASheetWrapper objHIQASheetWrapper = (HIQASheetWrapper) JSON.deserialize(strJson, HIQASheetWrapper.class);
					objHIQASheetWrapper.company_id = objHIGroupEvent.Company_Id__c;
					map_HIGroupEvent.put(objHIQASheetWrapper.application_id, objHIGroupEvent);
					map_HIQASheetWrapper.put(objHIQASheetWrapper.application_id, objHIQASheetWrapper);
					if (String.isNotBlank(objHIQASheetWrapper.company_id)) {
						set_companyIds.add(objHIQASheetWrapper.company_id);
					}

					objHIGroupEvent.Application_Type__c = objHIQASheetWrapper.application_type;
					objHIGroupEvent.Application_Id__c = objHIQASheetWrapper.application_id;
				} catch (Exception objEx) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objHIGroupEvent);
					continue;
				}
			}

			if (map_HIQASheetWrapper.isEmpty()) {
				return;
			}

			try {
				List<String> list_QAfields = new List<String>(QA_Sheet__c.getSObjectType().getDescribe().fields.getMap().keySet());
				List<String> list_QLCfields = new List<String>(QA_Lines_Of_Coverage__c.getSObjectType().getDescribe().fields.getMap().keySet());
				Set<String> set_ApplicationIds = map_HIQASheetWrapper.keySet();
				List<Opportunity> list_Opportunity = new List<Opportunity>();
				for (Opportunity objOpp : [
					SELECT Id, AccountId, RecordTypeId, HI_Effective_Date__c, (SELECT Id FROM QA_Sheet__r)
					FROM Opportunity
					WHERE RecordTypeId IN :set_OppRTIds AND StageName NOT IN :set_OppStage AND Application_Id__c IN :set_ApplicationIds AND ZP_Company_ID_from_Account__c IN :set_companyIds
				]) {
					if (objOpp.QA_Sheet__r == null || objOpp.QA_Sheet__r.size() == 0) {
						list_Opportunity.add(objOpp);
					}
				}

				if (list_Opportunity.size() > 0) {
					QASheetHelper.createOrUpdateQASheet(list_Opportunity);
				}

				String strSOQL =
					'SELECT ' +
					String.join(list_QAfields, ',') +
					', RecordType.DeveloperName, Opportunity__r.Application_Id__c, Opportunity__r.AccountId, ' +
					'Opportunity__r.OwnerId, Opportunity__r.RecordTypeId, Opportunity__r.RecordType.DeveloperName, Benefit_Order__r.UW_Owner__c, ' +
					'(SELECT ' +
					String.join(list_QLCfields, ',') +
					', Benefits_selected_Carrier__r.Id__c FROM QA_Lines_Of_Coverage_del__r) FROM QA_Sheet__c ' +
					'WHERE Opportunity__r.Application_Id__c IN :set_ApplicationIds AND Opportunity__r.ZP_Company_ID_from_Account__c IN: set_companyIds';
				List<QA_Sheet__c> list_QASheet = Database.query(strSOQL);

				Map<String, QA_Sheet__c> map_qaSheetToUpdate = new Map<String, QA_Sheet__c>();
				Map<String, HIQASheetWrapper> map_qasIdToWrapper = new Map<String, HIQASheetWrapper>();
				Map<String, Transition_to_Fulfillment__c> map_TTF = new Map<String, Transition_to_Fulfillment__c>();
				Map<String, HIQASheetWrapper.QALineOfCoverageWrapper> map_qlcWrapper = new Map<String, HIQASheetWrapper.QALineOfCoverageWrapper>();
				Map<String, QA_Lines_Of_Coverage__c> map_Qlc = new Map<String, QA_Lines_Of_Coverage__c>();

				String strCoverageType = '';
				Set<String> set_newTAdAs = new Set<String>();
				if (list_QASheet != null && list_QASheet.size() > 0) {
					for (QA_Sheet__c objQASheet : list_QASheet) {
						HIQASheetWrapper objHIQASheetWrapper = map_HIQASheetWrapper.get(objQASheet.Opportunity__r.Application_Id__c);
						String str_applicationType = map_QAEvent_OpptyType.get(objHIQASheetWrapper.Application_type) != null
							? map_QAEvent_OpptyType.get(objHIQASheetWrapper.Application_type)
							: '';

						if (str_applicationType != null && str_applicationType != objQASheet.Opportunity__r.RecordType.DeveloperName) {
							continue;
						}

						objQASheet.Subject_to_Federal_or_State_Cobra__c = objHIQASheetWrapper.subject_to_federal_or_state_cobra;
						objQASheet.Registration_Date__c = objHIQASheetWrapper.registration_date;
						objQASheet.WC_Carrier_Name__c = objHIQASheetWrapper.wc_carrier_name;
						objQASheet.Date_Established__c = objHIQASheetWrapper.date_business_established;
						objQASheet.Entity_Type__c = objHIQASheetWrapper.entity_type;
						objQASheet.Signatory_Name_Title__c = objHIQASheetWrapper.panda_signatory_name_and_title;
						objQASheet.Taxed_as_s_corp__c = objHIQASheetWrapper.taxable_as_scorp != null && objHIQASheetWrapper.taxable_as_scorp == true ? HIGroupEventUtil.YES_VALUE : HIGroupEventUtil.NO_VALUE;
						objQASheet.SIC_Code__c = objHIQASheetWrapper.sic_code;
						objQASheet.WC_Status__c = objHIQASheetWrapper.wc_status;
						objQASheet.Secretary_of_State_Registration_Status__c = objHIQASheetWrapper.secretary_of_state_registration_status;
						objQASheet.Owner_Names_and_of_Ownership__c = objHIQASheetWrapper.owner_names_and_percent_ownership;
						objQASheet.Waived_waiting_period_for_new_hires__c = objHIQASheetWrapper.waiving_initial_waiting_period;

						if (objHIQaSheetWrapper.address_change_to_be_made_by_submission != null) {
							objQASheet.Does_group_have_an_address_change__c = objHIQaSheetWrapper.address_change_to_be_made_by_submission ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE ;
						}
						if (objHIQaSheetWrapper.submit_for_special_enrollment != null) {
							objQASheet.Special_Enrollment__c = objHIQaSheetWrapper.submit_for_special_enrollment ? HIGroupEventUtil.Y_VALUE : HIGroupEventUtil.N_VALUE;
						}
						if (objHIQaSheetWrapper.types_of_new_tadas != null && !objHIQaSheetWrapper.types_of_new_tadas.isEmpty()) {
							set_newTAdAs = new Set<String>();
							for (String strTaDaType : objHIQaSheetWrapper.types_of_new_tadas) {
								String strLowerCaseTadaType = strTaDaType.toLowerCase();
								if (map_TaDaTypes.containsKey(strLowerCaseTadaType)) {
									set_newTAdAs.add(map_TaDaTypes.get(strLowerCaseTadaType));
								}
							}
							objQASheet.New_TAdAs__c = String.join(new List<String> (set_newTAdAs), ';');
						}
						if (objHIQaSheetWrapper.types_of_renewing_tadas != null && !objHIQaSheetWrapper.types_of_renewing_tadas.isEmpty()) {
							set_newTAdAs = new Set<String>();
							for (String strTaDaType : objHIQaSheetWrapper.types_of_renewing_tadas) {
								String strLowerCaseTadaType = strTaDaType.toLowerCase();
								if (map_TaDaTypes.containsKey(strLowerCaseTadaType)) {
									set_newTAdAs.add(map_TaDaTypes.get(strLowerCaseTadaType));
								}
							}
							objQASheet.Renewing_TAdAs__c = String.join(new List<String> (set_newTAdAs), ';');
						}
						if (objHIQaSheetWrapper.peo_switcher != null) {
							objQASheet.PEO_switcher__c = objHIQaSheetWrapper.peo_switcher == 'Yes' ? 'Y' : 'N';
						}

						String strSuccessor_predecessor = '';
						if (objHIQaSheetWrapper.plan_successors_predecessors != null) {
							for (HIQASheetWrapper.successorsPredecessorsWrapper dataWrapper : objHIQaSheetWrapper.plan_successors_predecessors) {
								if (String.isBlank(strSuccessor_predecessor)) {
									strSuccessor_predecessor = SUCCESSOR_PREDECESSOR;
								}
								strSuccessor_predecessor += '\n ' + dataWrapper.predecessor_policy_name + ':' + dataWrapper.successor_plan_name;
							}
						}
						objQASheet.Successor_predecessor_plan_codes_and_nam__c = formatString(strSuccessor_predecessor, 32768, '\n');

						for (HIQASheetWrapper.QALineOfCoverageWrapper objQlWrapper : objHIQASheetWrapper.qual_loc_data) {
							if (objQlWrapper.benefit_type != null) {
								strCoverageType = map_coverageType.get(objQlWrapper.benefit_type.toLowerCase());
								if (String.isBlank(strCoverageType)) {
									strCoverageType = objQlWrapper.benefit_type;
								}
							}
							map_qlcWrapper.put(objQASheet.Opportunity__c + ';' + objQASheet.Id + ';' + strCoverageType.toLowerCase() + ';' + objQlWrapper.state_carrier_id, objQlWrapper);
						}

						for (QA_Lines_Of_Coverage__c objQlc : objQASheet.QA_Lines_Of_Coverage_del__r) {
							map_Qlc.put(
								objQASheet.Opportunity__c +
									';' +
									objQASheet.Id +
									';' +
									(objQlc.Lines_Of_Coverage__c != null ? objQlc.Lines_Of_Coverage__c.toLowerCase() : null) +
									';' +
									objQlc.Benefits_selected_Carrier__r.Id__c,
								objQlc
							);
						}

						map_qaSheetToUpdate.put(objQASheet.Opportunity__c, objQASheet);
						map_qasIdToWrapper.put(objQASheet.Id, objHIQASheetWrapper);
						if (objQASheet.Subject_to_Federal_or_State_Cobra__c == SUBJECT_TO_FEDERAL && objQASheet.Benefit_Order__c != null) {
							set_BenefitOrderIds.add(objQASheet.Benefit_Order__c);
						}
					}
				} else {
					for (String strIdVal : map_HIGroupEvent.keySet()) {
						HIGroupEvent__c objHIGroup = map_HIGroupEvent.get(strIdVal);
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'QA Sheet does not exist, please ensure Oppty exists.', objHIGroup);
					}
					return;
				}

				if (map_qaSheetToUpdate != null && !map_qaSheetToUpdate.isEmpty()) {
					try {
						upsert map_qaSheetToUpdate.values();
					} catch (exception ex) {
						ExceptionLogUtil.logException('HIGroupEventQASheetHandler', 'processInformation',ex);
					}
					upsertQlc(map_qaSheetToUpdate.keySet(), map_qlcWrapper, map_Qlc, map_qasIdToWrapper);
					createCOWithBasic(set_BenefitOrderIds);
				}

				for (String strIdVal : map_HIGroupEvent.keySet()) {
					HIGroupEvent__c objHIGroup = map_HIGroupEvent.get(strIdVal);
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'HI Group event QA Sheet processed sucessfully', objHIGroup);
				}
			} catch (Exception objEx) {
				for (String strIdVal : map_HIGroupEvent.keySet()) {
					HIGroupEvent__c objHIGroup = map_HIGroupEvent.get(strIdVal);
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'QA Sheet processing failed. ' + objEx.getMessage() + ' \n ' + objEx.getStackTraceString(), objHIGroup);
					ExceptionLogUtil.logException(
						'HIGroupEventQASheetHandler', 'processInformation', objEx);
				}
			}
		}
	}

	private void upsertQlc(Set<String> set_opptyIds, Map<String, HIQASheetWrapper.QALineOfCoverageWrapper> map_qlcWrapper, Map<String, QA_Lines_Of_Coverage__c> map_Qlc, Map<String, HIQASheetWrapper> map_qasIdToWrapper) {
		Set<String> set_strOpptyIds = new Set<String>();
		Set<String> set_carrierStateId = new Set<String>();
		Map<String, Company_Level_Documents__c> map_ToUpsertDocNameClDocsRecord = new Map<String, Company_Level_Documents__c>();
		Map<String, Company_Level_Documents__c> map_CompanyLevelDocs = new Map<String, Company_Level_Documents__c>();
		Map<String, QA_Lines_Of_Coverage__c> map_newQALoC = new Map<String, QA_Lines_Of_Coverage__c>();

		for (Company_Level_Documents__c objClDoc : [SELECT Id, Opportunity__c, Name, Primary_Options__c FROM Company_Level_Documents__c WHERE Opportunity__c IN :set_opptyIds]) {
			if (!String.isBlank(objClDoc.Opportunity__c) && !String.isBlank(objClDoc.Name)) {
				String strNameKey = (objClDoc.Opportunity__c + ';' + objClDoc.Name).toLowerCase().replaceAll('[^\\w\\s]', '1').trim();
				map_CompanyLevelDocs.put(strNameKey, objClDoc);
			}
		}

		for (String strKey : map_qlcWrapper.keySet()) {
			String strOpptyId = strKey.split(';')[0];
			String strQAId = strKey.split(';')[1];
			String strCoverage = strKey.split(';')[2];
			String strStateCarrierId = strKey.split(';')[3];
			HIQASheetWrapper objHIQASheetWrapper = map_qasIdToWrapper.get(strQAId);
			HIQASheetWrapper.QALineOfCoverageWrapper objQlWrapper = map_qlcWrapper.get(strKey);
			QA_Lines_Of_Coverage__c objQlc = map_Qlc.get(strKey);

			if (objQlWrapper == null && objQlc == null) {
				continue;
			}

			if (objQlc != null) {
				objQlc.Verified_rates__c = objQlWrapper.verified_rates;
				objQlc.Documents_Require_for_Submission__c = formatString(objQlWrapper.documents_required_for_submission, 32768, '\n');
				objQlc.LIst_of_Owner_names_and_the_percentage__c = formatString(objQlWrapper.owner_names_and_percent_ownership, 5000, '\n');
				objQlc.Non_owner_enrolled_required__c = objQlWrapper.non_owner_must_enroll;
				if (objQlWrapper.is_early_submission_required != null) {
					objQlc.Early_Submission_Required__c = objQlWrapper.is_early_submission_required;
				}
			} else {
				QA_Lines_Of_Coverage__c objNewQlc = new QA_Lines_Of_Coverage__c();
				objNewQlc.QA_Sheet__c = strQAId;
				objNewQlc.Lines_Of_Coverage__c = strCoverage;
				objNewQlc.Renewal_Type__c = objQlWrapper.renewal_type;
				objNewQlc.Verified_rates__c = objQlWrapper.verified_rates;
				objNewQlc.Documents_Require_for_Submission__c = formatString(objQlWrapper.documents_required_for_submission, 32768, '\n');
				objNewQlc.List_of_Owner_names_and_the_percentage__c = formatString(objQlWrapper.owner_names_and_percent_ownership, 5000, '\n');
				objNewQlc.Non_owner_enrolled_required__c = objQlWrapper.non_owner_must_enroll;
				objNewQlc.Contribution_Description__c = objQlWrapper.contribution_description;
				objNewQlc.Waiting_Period_Description__c = objQlWrapper.waiting_period_description;
				//objNewQlc.Rating_Structure_Composite_Age_Banded__c = objQlWrapper.composite_rated;
				objNewQlc.New_Carrier__c = objQlWrapper.carrier_switch != null ? (objQlWrapper.carrier_switch ? HIGroupEventUtil.Y_VALUE : HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.Waiting_Period_change__c = objQlWrapper.waiting_period_change != null ? (objQlWrapper.waiting_period_change ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.New_line_of_Coverage__c = objQlWrapper.new_line_of_coverage != null ? (objQlWrapper.new_line_of_coverage ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.Plan_changes__c = objQlWrapper.plan_change != null ? (objQlWrapper.plan_change ? HIGroupEventUtil.Y_VALUE : HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.Contribution_change__c = objQlWrapper.contribution_change != null ? (objQlWrapper.contribution_change ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.Does_group_have_an_alignment__c = objHIQASheetWrapper.alignment_to_be_requested_by_submission != null ? (objHIQASheetWrapper.alignment_to_be_requested_by_submission ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE) : '';
				objNewQlc.Rate_Change__c = objHIQASheetWrapper.has_rating_structure_change != null ? (objHIQASheetWrapper.has_rating_structure_change ? HIGroupEventUtil.Y_VALUE :  HIGroupEventUtil.N_VALUE) : '';

				if (objQlWrapper.plan_description != null) {
					String strPlanDescription = '';
					if (objQlWrapper.plan_description.plan_additions != null && !objQlWrapper.plan_description.plan_additions.isEmpty()) {
						strPlanDescription += HIGroupEventUtil.PLAN_ADDITIONS +'\n' + String.join(objQlWrapper.plan_description.plan_additions, '\n') + '\n';
					}

					if (objQlWrapper.plan_description.plan_removals != null && !objQlWrapper.plan_description.plan_removals.isEmpty()) {
						strPlanDescription += HIGroupEventUtil.PLAN_REMOVALS +'\n' + String.join(objQlWrapper.plan_description.plan_removals, '\n') + '\n';
					}

					if (objQlWrapper.plan_description.plan_renewals != null && !objQlWrapper.plan_description.plan_renewals.isEmpty()) {
						strPlanDescription += HIGroupEventUtil.PLAN_RENEWALS +'\n' + String.join(objQlWrapper.plan_description.plan_renewals, '\n') + '\n';
					}

					objNewQlc.Plan_Description__c = strPlanDescription;
				}

				if (objQlWrapper.is_early_submission_required != null) {
					objNewQlc.Early_Submission_Required__c = objQlWrapper.is_early_submission_required;
				}

				set_strOpptyIds.add(strOpptyId);
				map_newQALoC.put(strKey, objNewQlc);
				set_carrierStateId.add(strStateCarrierId);
			}

			if (objQlWrapper.documents_required_oa != null && !objQlWrapper.documents_required_oa.isEmpty()) {
				for (HIQASheetWrapper.CompanyDocWrapper objdocWrapper : objQlWrapper.documents_required_oa) {
					Boolean newDocument = true;
					String strName = (!String.isBlank(objdocWrapper.document) && objdocWrapper.document.length() >= 80) ? objdocWrapper.document.subString(0, 79) : objdocWrapper.document;
					String strCdocOption = String.isBlank(objdocWrapper.option) ? null : map_companyDoc.get(objdocWrapper.option.toLowerCase());
					String strNameKey = (strOpptyId + ';' + strName).toLowerCase().replaceAll('[^\\w\\s]', '1').trim();

					Company_Level_Documents__c objTemp;
					if (map_CompanyLevelDocs.get(strNameKey) != null) {
						objTemp = map_CompanyLevelDocs.get(strNameKey);
					} else {
						objTemp = new Company_Level_Documents__c(Name = strName, Opportunity__c = strOpptyId);
					}
					objTemp.Additional_Details__c = objdocWrapper.document;
					objTemp.Primary_Options__c = strCdocOption == null && STR_UNKNOWN != objdocWrapper.option ? objdocWrapper.option : strCdocOption;
					map_ToUpsertDocNameClDocsRecord.put(strNameKey, objTemp);
				}
			}
		}

		try {
			upsert map_ToUpsertDocNameClDocsRecord.values();
			upsert map_Qlc.values();
			if (!map_newQALoC.isEmpty()) {
				insertQLC(map_newQALoC, set_strOpptyIds, set_carrierStateId);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('HIGroupEventQASheetHandler', 'upsertQlc', ex);
		}
	}

	private void insertQLC(Map<String, QA_Lines_Of_Coverage__c> map_newQALoC, Set<String> set_opptyIds, Set<String> set_carrierStateId) {
		Map<Id, Opportunity> map_opptyMap = new Map<Id, Opportunity>([SELECT HI_Effective_Date__c FROM Opportunity WHERE Id IN :set_opptyIds]);

		Map<String, Date> map_carrIdPolicyEffMap = new Map<String, Date>();
		for (String strKey : map_newQALoC.keySet()) {
			String strOpptyId = strKey.split(';')[0];
			String strQAId = strKey.split(';')[1];
			String strCoverage = strKey.split(';')[2];
			String strStateCarrierId = strKey.split(';')[3];

			if (map_opptyMap != null && map_opptyMap.get(strOpptyId) != null) {
				map_carrIdPolicyEffMap.put(strStateCarrierId, map_opptyMap.get(strOpptyId).HI_Effective_Date__c);
			}
		}

		Map<String, Carrier_Version_Detail__c> map_carrierVersion = new Map<String, Carrier_Version_Detail__c>();
		Map<String, Carrier__c> map_carrierIdCarrier = new Map<String, Carrier__c>();
		if (!map_carrIdPolicyEffMap.isEmpty()) {
			map_carrierVersion = Utils.getCarrierVersion(map_carrIdPolicyEffMap);

			Set<String> set_carrierIdsWithoutCarrierVersions = map_carrIdPolicyEffMap.KeySet();
			set_carrierIdsWithoutCarrierVersions.removeAll(map_carrierVersion.keyset());
			if (set_carrierIdsWithoutCarrierVersions != null && set_carrierIdsWithoutCarrierVersions.size() > 0) {
				for (Carrier__c objCarrier : [SELECT Id, Id__c, Name FROM Carrier__c WHERE Id__c != NULL AND Id__c IN :set_carrierIdsWithoutCarrierVersions]) {
					map_carrierIdCarrier.put(objCarrier.Id__c, objCarrier);
				}
			}
		}

		List<QA_Lines_Of_Coverage__c> list_qaloc = new List<QA_Lines_Of_Coverage__c>();
		for (String strKey : map_newQALoC.keySet()) {
			String strOpptyId = strKey.split(';')[0];
			String strQAId = strKey.split(';')[1];
			String strCoverage = strKey.split(';')[2];
			String strStateCarrierId = strKey.split(';')[3];

			Carrier_Version_Detail__c objCarrierVersion = map_carrierVersion != null ? map_carrierVersion.get(strStateCarrierId) : null;
			Carrier__c objCarrierRec = map_carrierIdCarrier != null ? map_carrierIdCarrier.get(strStateCarrierId) : null;
			QA_Lines_Of_Coverage__c objQALoc = map_newQALoC.get(strKey);

			if (objCarrierVersion != null) {
				objQALoc.Benefits_selected_Carrier__c = objCarrierVersion.Carrier_Id__c;
				objQALoc.Carriers__c = objCarrierVersion.Carrier_Id__r.Name;
				objQALoc.Medical_LOA_Required__c = objCarrierVersion.Medical_LOA_Required__c;
				objQALoc.LOA_Required__c = objCarrierVersion.Personal_LOA_Required__c;
				objQALoc.OOS_EE_Requirements__c = objCarrierVersion.Oos_Plan_Restrictions__c;
				objQALoc.Participation_Requirements__c = objCarrierVersion.Participation_Requirements__c != null ? objCarrierVersion.Participation_Requirements__c : '';
				objQALoc.WP_Default__c = objCarrierVersion.Waiting_Period_Default_for_New_Hires__c != null ? objCarrierVersion.Waiting_Period_Default_for_New_Hires__c : '';
				objQALoc.Waiting_Period_Default__c = objCarrierVersion.Waiting_Period_Default_for_New_Hires__c != null ? objCarrierVersion.Waiting_Period_Default_for_New_Hires__c : '';
				objQALoc.of_Plans_Allowed__c = objCarrierVersion.Number_of_Plans_Allowed__c != null ? String.valueOf(objCarrierVersion.Number_of_Plans_Allowed__c) : null;
				objQALoc.Allows_plans_with_no_enrollees__c = objCarrierVersion.Allows_Plans_with_No_Enrollees__c != null ? objCarrierVersion.Allows_Plans_with_No_Enrollees__c : null;
				objQALoc.Rating_Structure_Composite_Age_Banded__c = objCarrierVersion.Gusto_Default_Rating_Structure__c != null ? objCarrierVersion.Gusto_Default_Rating_Structure__c : '';
				objQALoc.Valid_Waivers__c = objCarrierVersion.Valid_Waivers__c != null ? objCarrierVersion.Valid_Waivers__c : '';
				objQALoc.Job_Titles_Required__c = objCarrierVersion.job_titles_required__c;
			}

			if (objQALoc.Benefits_selected_Carrier__c == null && objCarrierRec != null) {
				objQALoc.Benefits_selected_Carrier__c = objCarrierRec.Id;
				objQALoc.Carriers__c = objCarrierRec.Name;
			}
			list_qaloc.add(objQALoc);
		}

		if (!list_qaloc.isEmpty()) {
			try {
				insert list_qaloc;
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIGroupEventQASheetHandler', 'insertQLC', ex);
			}
		}
	}
	@TestVisible
	private String formatString(String strActualText, Integer intMaxlength, String strSeperator) {
		if (String.isBlank(strActualText)) {
			return null;
		}

		String strFormatted = String.join(strActualText.split('\n'), strSeperator);
		if (strActualText.length() > intMaxlength) {
			strFormatted = strFormatted.left(intMaxlength);
		}
		return strFormatted;
	}

	/**
	 * @author      : Deepika Saini
	 * @description : This method is used to create Carrier Order
	 * @parm        : set_BenefitOrdersId : set of Benefit Orders Id
	 * @return      : list of ticket
	 **/
	private void createCOWithBasic(Set<Id> set_BenefitOrderIds) {
		List<Carrier_Order__c> list_COsToInsert = new List<Carrier_Order__c>();
		if (!set_BenefitOrderIds.isEmpty()) {
			for (Benefit_Order__c objbo : [
				SELECT
					Id,
					Opportunity__c,
					Account__c,
					Account__r.Name,
					RecordTypeId,
					(SELECT Id, Benefit_Types__c FROM Carrier_Orders__r WHERE Benefit_Types__c = :TransitiontoFulfilmentUtil.CARRIER_NAME_BASIC)
				FROM Benefit_Order__c
				WHERE Id IN :set_BenefitOrderIds
			]) {
				if (objbo.Carrier_Orders__r.size() == 0) {
					Carrier_Order__c objBasicCarrierOrder;
					if (objbo.RecordTypeId == BENEFIT_ORDER_RT_RENEWAL) {
						objBasicCarrierOrder = new Carrier_Order__c();
						objBasicCarrierOrder.Order_Type__c = CarrierOrderUtil.ORDER_TYPE_SAME_CARRIER_NO_PLAN_GROUP_LEVEL_CHANGES;
						objBasicCarrierOrder.RecordTypeId = CARRIER_ORDER_RENEWAL_RT;
						objBasicCarrierOrder.name = objbo.Account__r.Name + ' ' + CARRIER_BASIC_PACIFIC_RENEWAL;
					}
					if (objbo.RecordTypeId == BENEFIT_ORDER_RT_NEW_PLAN) {
						objBasicCarrierOrder = new Carrier_Order__c();
						objBasicCarrierOrder.Order_Type__c = CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO;
						objBasicCarrierOrder.RecordTypeId = CARRIER_ORDER_NEW_PLAN_RT;
						objBasicCarrierOrder.name = objbo.Account__r.Name + ' ' + CARRIER_BASIC_PACIFIC_SETUP;
					}
					if (objBasicCarrierOrder != null) {
						if (objBasicCarrierOrder.Name.length() > 80) {
							objBasicCarrierOrder.Name = objBasicCarrierOrder.Name.subString(0, 80);
						}
						objBasicCarrierOrder.benefit_order__c = objbo.Id;
						objBasicCarrierOrder.Benefit_Types__c = TransitiontoFulfilmentUtil.CARRIER_NAME_BASIC;
						objBasicCarrierOrder.Carrier__c = Label.BASIC_Carrier;
						objBasicCarrierOrder.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_OE_PREP;
						list_COsToInsert.add(objBasicCarrierOrder);
					}
				}
			}
		}
		if (!list_COsToInsert.isEmpty()) {
			insert list_COsToInsert;
		}
	}
}