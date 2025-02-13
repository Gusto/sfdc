/**
 * @name         HIGroupEventTTSNotePostOEEmail
 * @author       Deepika Saini
 * @date         10-04-2021
 * @description  Utility class for TTS notes Post OE Email
 * @test classes
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventTTSNotePostOEEmail {
	public static List<String> list_Errors;
	public final static String SUBMISSION_NEW_PLAN_TTF_RT_NAME = 'Submission New Plan';
	public final static String SUBMISSION_RENEWAL_CHANGE_TTF_RT_NAME = 'Submission Renewal/Change';
	public final static String LABEL_YES = 'Y';
	public final static String LABEL_NO = 'N';
	public static final Set<String> set_TTSRecordTypes = new Set<String>{ SUBMISSION_RENEWAL_CHANGE_TTF_RT_NAME, SUBMISSION_NEW_PLAN_TTF_RT_NAME };
	public final static Id SUBMISSION_NEW_PLAN_TTF_RT_ID = Cache.getRecordTypeId('Transition_To_Fulfillment__c', SUBMISSION_NEW_PLAN_TTF_RT_NAME);
	public final static Id SUBMISSION_RENEWAL_CHANGE_TTF_RT_ID = Cache.getRecordTypeId('Transition_To_Fulfillment__c', SUBMISSION_RENEWAL_CHANGE_TTF_RT_NAME);
	public static List<Transition_To_Fulfillment__c> list_TTSsToUpsert = new List<Transition_To_Fulfillment__c>();
	public static List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
	public static Map<String, BOInfoWrapper> map_BOInfoWraps = new Map<String, BOInfoWrapper>();
	public static final String USER_ID_PREFIX = '005';
	public static final String CO_CANCELED_STAGE = 'Canceled';
	public static final String CO_APPROVED_STAGE = 'Approved';
	public static final String OWD_EMAIL_NEWPLANS = 'newplans@gusto.com';
	public static final String OWD_EMAIL_RENEWALS = 'renewals@gusto.com';
	public static final String CONTACT_FIRST_NAME_TAG = '[CONTACT FIRST NAME]';
	public static final String GUSTO_PLAN_REMOVED_TAG = '[Ghost Plan Removed]';
	public static final String GHOST_PLAN_GUARDIAN = 'Guardian';
	public static final String GUSTO_PLAN_NAME_TAG = '[Plan Name]';
	public static final String CO_READY_FOR_SUBMISSION_PREP = 'Ready for Submission Prep';
	public static EmailTemplate objEmailTemplate = new EmailTemplate();
	public static final String RENEWWAL_EMAIL_TEMPLATE = 'X3b_Post_OE_Subprep_Renewal';
	public static final String NEWPLAN_EMAIL_TEMPLATE = 'X3a_Post_OE_Subprep_New_Plan_Carrier_Switch';
	public static Map<String, EmailTemplate> map_EmailTemplates = new Map<String, EmailTemplate>();
	public static final String GHOST_PLAN_SECTION = '[GHOST_PLAN_SECTION]';
	public static final String GHOST_PLAN_MACRO = 'OE_EMAIL_GHOST_PLAN';
	public static Map<String, String> map_EmailMacros = new Map<String, String>();
	public static String CO_OA_CARRIER_SWITCH = 'Carrier switch';

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reterive email template and email macro.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static {
		for (EmailTemplate objET : [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :RENEWWAL_EMAIL_TEMPLATE OR DeveloperName = :NEWPLAN_EMAIL_TEMPLATE]) {
			map_EmailTemplates.put(objET.DeveloperName, objET);
		}

		for (Email_Macro__c objEM : [SELECT Body__c, Macro_Identifier__c FROM Email_Macro__c WHERE Macro_Identifier__c != NULL AND Macro_Identifier__c = :GHOST_PLAN_MACRO]) {
			map_EmailMacros.put(objEM.Macro_Identifier__c, objEM.Body__c);
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Process HIGroupEvents (type = tts_note_post_oe_email) and update TTS.
	 * @Parm        : List of HIGroupEvent__c records.
	 * @Return      : void
	 **/
	public static void processEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationTypes = new Set<String>();
		Set<String> set_TTSApplicationTypes = new Set<String>();
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents = new Map<String, HIGroupEvent__c>();
		Map<String, TTSInfoWrapper> map_TTSInfoWraps = new Map<String, TTSInfoWrapper>();
		Map<String, BOWithEventInfoWrapper> map_BenefitOrderInfoWraps = new Map<String, BOWithEventInfoWrapper>();
		if (list_Events?.size() == 0) {
			return;
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			String strTTSRecordType = '';

			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objEvent);
				continue;
			}

			try {
				HIGroupEventTTSNotePostOEEmailJSON objEventInfoJSON = (HIGroupEventTTSNotePostOEEmailJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupEventTTSNotePostOEEmailJSON.class);

				if (String.isBlank(objEvent.Application_Id__c)) {
					if (String.isBlank(objEventInfoJSON.application_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_ID_MISSING, objEvent);
						continue;
					}

					objEvent.Application_Id__c = objEventInfoJSON.application_id;
				}

				if (String.isBlank(objEvent.Application_type__c)) {
					if (String.isBlank(objEventInfoJSON.application_type)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_TYPE_MISSING, objEvent);
						continue;
					}

					objEvent.Application_type__c = objEventInfoJSON.application_type;
				}

				if (String.isBlank(objEvent.Company_Id__c)) {
					if (String.isBlank(objEventInfoJSON.company_id)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_COMPANY_ID_MISSING, objEvent);
						continue;
					}

					objEvent.Company_Id__c = objEventInfoJSON.company_id;
				}

				strTTSRecordType = getTTSRecordType(objEvent.Application_type__c);

				if (String.isBlank(strTTSRecordType)) {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_APPLICATION_TYPE_INVALID, objEvent);
					continue;
				}

				set_TTSApplicationTypes.add(strTTSRecordType);
				set_ApplicationIds.add(objEvent.Application_Id__c);
				set_CompanyIds.add(objEvent.Company_Id__c);
				set_ApplicationTypes.add(objEvent.Application_type__c);

				String strKeyTTS = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + strTTSRecordType;

				TTSInfoWrapper objTTSWrap = new TTSInfoWrapper(
					objEvent.Event_Id__c,
					objEvent.Ghost_Plan_Names__c,
					objEvent.Continuation_EE_Notes__c,
					objEvent.Additional_Details_for_Submission__c,
					objEvent.Riders__c,
					objEvent.ER_Signature_Location__c,
					objEvent.POA_Signatory_Name__c,
					objEvent.POA_Signatory_Title__c,
					objEvent.Benefits_Admin_Name__c,
					objEvent.Benefits_Admin_Title__c,
					objEvent.Company_Name__c
				);

				map_TTSInfoWraps.put(strKeyTTS, objTTSWrap);
				map_EventIdHIGrpEvents.put(objEvent.Event_Id__c, objEvent);

				String strKey = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c;

				BOWithEventInfoWrapper objBOWrap = new BOWithEventInfoWrapper(objEvent.Event_Id__c, objEventInfoJSON);
				map_BenefitOrderInfoWraps.put(strKey, objBOWrap);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
			}
		}

		try {
			if (map_EventIdHIGrpEvents.isEmpty() || set_ApplicationIds.isEmpty() || set_CompanyIds.isEmpty() || set_ApplicationTypes.isEmpty() || set_TTSApplicationTypes.isEmpty()) {
				return;
			}

			getBenefitOrderDetails(set_ApplicationIds, set_CompanyIds, set_ApplicationTypes);

			upsertTTSRecord(map_EventIdHIGrpEvents, map_TTSInfoWraps, list_Events, set_ApplicationIds, set_CompanyIds, set_TTSApplicationTypes);

			if (list_Errors?.size() > 0) {
				HIGroupEvent__c objHIGroup = map_EventIdHIGrpEvents.values().get(0);
				ExceptionLogUtil.logException('HIGroupEventTTSNotePostOEEmail Field error for ID' + objHIGroup.Id, 'Exceed max field limit', 'Exceed max field limit', String.join(list_Errors, ';'));
			}

			sendEmailtoBOCaseTeamMember(map_EventIdHIGrpEvents, map_BenefitOrderInfoWraps, list_Events, set_ApplicationIds, set_CompanyIds, set_ApplicationTypes);
		} catch (Exception objEx) {
			String strErrorMessage = objEx.getMessage();
			if (!strErrorMessage.contains(Utils.BOUNCE_EMAIL_ERROR)) {
				createErrorLog(objEx, 'upsertTTSRecord');
			}
			for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvents.values()) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, objEx.getMessage(), objEvent);
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Get Benefit Order Details
	 * @Parm        : Map of "Company_Id__c +  Application_Id__c + Application_type__c" with BOInfoWrapper wrapper object
	  				: Set of Application_Id__c
	  				: Set of Company_Id__c
	                : Set of Application_type__c
	 * @Return      : void
	 **/
	static void getBenefitOrderDetails(Set<String> set_ApplicationIds, Set<String> set_CompanyIds, Set<String> set_ApplicationTypes) {
		for (Benefit_Order__c objBO : [
			SELECT Id, Account__c, Opportunity__c, Account__r.ZP_Company_Id__c, Application_Id__c, RecordType.Name
			FROM Benefit_Order__c
			WHERE
				Account__c != NULL
				AND Account__r.ZP_Company_Id__c != NULL
				AND Application_Id__c != NULL
				AND RecordTypeId != NULL
				AND Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Application_Id__c IN :set_ApplicationIds
				AND RecordType.Name IN :set_ApplicationTypes
		]) {
			String strKeyBO = objBO.Account__r.ZP_Company_Id__c + '-' + objBO.Application_Id__c + '-' + objBO.RecordType.Name;

			BOInfoWrapper objBOWrap = new BOInfoWrapper(objBO.Id, objBO.Account__c, objBO.Opportunity__c, objBO.RecordType.Name);
			map_BOInfoWraps.put(strKeyBO, objBOWrap);
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Upsert TTS
	 * @Parm        : Map of Event Id with HIGroupEvent__c object
					: Map of "Company_Id__c +  Application_Id__c + (TTS)RecordType" with TTSInfoWrapper wrapper object
	  				: Set of Application_Id__c
	  				: Set of Company_Id__c
	                : Set of (TTS)RecordType
	 * @Return      : void
	 **/
	static void upsertTTSRecord(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents,
		Map<String, TTSInfoWrapper> map_TTSInfoWraps,
		List<HIGroupEvent__c> list_Events,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds,
		Set<String> set_TTSApplicationTypes
	) {
		Map<String, Id> map_TransitionToFulfilments = new Map<String, Id>();

		for (Transition_to_Fulfillment__c objTTS : [
			SELECT Id, Name, Account__r.ZP_Company_Id__c, Application_Id__c, RecordType.Name
			FROM Transition_to_Fulfillment__c
			WHERE
				Account__c != NULL
				AND Account__r.ZP_Company_Id__c != NULL
				AND Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Application_Id__c != NULL
				AND RecordTypeId != NULL
				AND Application_Id__c IN :set_ApplicationIds
				AND RecordType.Name IN :set_TTSApplicationTypes
		]) {
			String strKeyTemp = objTTS.Account__r.ZP_Company_Id__c + '-' + objTTS.Application_Id__c + '-' + objTTS.RecordType.Name;

			map_TransitionToFulfilments.put(strKeyTemp, objTTS.Id);
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			String strTTSRecordType = getTTSRecordType(objEvent.Application_type__c);
			String strKeyTTS = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + strTTSRecordType;

			String strKeyBO = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c;

			if (!map_TTSInfoWraps.isEmpty() && map_TTSInfoWraps.containsKey(strKeyTTS)) {
				Transition_to_Fulfillment__c objTTS = new Transition_to_Fulfillment__c();
				TTSInfoWrapper objTTSWrapper = map_TTSInfoWraps.get(strKeyTTS);
				BOInfoWrapper objBOWrapper = null;

				if (!map_BOInfoWraps.isEmpty() && map_BOInfoWraps.containsKey(strKeyBO)) {
					objBOWrapper = map_BOInfoWraps.get(strKeyBO);
				}

				if (!map_TransitionToFulfilments.isEmpty() && map_TransitionToFulfilments.containsKey(strKeyTTS)) {
					objTTS.Id = map_TransitionToFulfilments.get(strKeyTTS);
				}

				populateTTSFields(objTTS, objTTSWrapper, objBOWrapper);
				list_TTSsToUpsert.add(objTTS);
			}
		}

		upsert list_TTSsToUpsert;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Get TTS Record Type
	 * @Parm        : String BO Application Type
	 * @Return      : String TTS Record Type
	 **/
	public static String getTTSRecordType(String strApplicationType) {
		String strTTSRecordType = '';

		if (strApplicationType == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL || strApplicationType == BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE) {
			strTTSRecordType = SUBMISSION_RENEWAL_CHANGE_TTF_RT_NAME;
		} else if (strApplicationType == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN) {
			strTTSRecordType = SUBMISSION_NEW_PLAN_TTF_RT_NAME;
		}

		return strTTSRecordType;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Populate TTS Fields
	 * @Parm        : Transition_to_Fulfillment__c object
	 * 				  TTSInfoWrapper object
	 * 				  BOInfoWrapper object
	 * @Return      : void
	 **/
	public static void populateTTSFields(Transition_to_Fulfillment__c objTTS, TTSInfoWrapper objTTSWrapper, BOInfoWrapper objBOWrapper) {
		objTTS.List_of_plans_removed__c = objTTSWrapper.strGhostPlan;

		if (String.isNotBlank(objTTSWrapper.strContinuationEENotes)) {
			objTTS.Does_group_have_continuation_enrollees__c = LABEL_YES;
		}

		objTTS.Continuation_EEs_to_be_included__c = objTTSWrapper.strContinuationEENotes;
		objTTS.Additional_Details_for_Submission__c = formatString(
			'Additional_Details_for_Submission__c',
			objTTSWrapper.strAdditionalDetails,
			Transition_to_Fulfillment__c.Additional_Details_for_Submission__c.getDescribe().getLength(),
			true,
			list_Errors,
			'\n',
			'<br/>'
		);

		if (objTTSWrapper.blnIsRiders) {
			objTTS.Infertility_Rider__c = LABEL_YES;
		} else {
			objTTS.Infertility_Rider__c = LABEL_NO;
		}

		objTTS.ER_Signature_Location__c = objTTSWrapper.strERSignatureLocation;
		objTTS.POA_Signatory_Name__c = objTTSWrapper.strPOASignatoryName;
		objTTS.POA_Signatory_Title__c = objTTSWrapper.strPOASignatoryTitle;
		objTTS.Admin_Name__c = objTTSWrapper.strBenefitsAdminName;
		objTTS.Admin_Title__c = objTTSWrapper.strBenefitsAdminTitle;
		objTTS.New_group_name__c = objTTSWrapper.strCompanyName;

		if (String.isBlank(objTTS.Id) && objBOWrapper != null) {
			objTTS.Benefit_Order__c = objBOWrapper.idBenefitOrder;
			objTTS.Account__c = objBOWrapper.idAccount;
			objTTS.Opportunity__c = objBOWrapper.idOpportunity;
			if (objBOWrapper.strRecordTypeName == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN) {
				objTTS.RecordTypeId = SUBMISSION_NEW_PLAN_TTF_RT_ID;
			} else {
				objTTS.RecordTypeId = SUBMISSION_RENEWAL_CHANGE_TTF_RT_ID;
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Format the String
	 * @Parm        : String - Field Name
	 * 				  String - Actual text
	 * 				  Integer - length of field
	 * 				  Boolean - New line added
	 * 				  String - Split by
	 * 				  String - Seperator
	 * @Return      : void
	 **/
	@TestVisible
	private static String formatString(String strFieldName, String strActualText, Integer intMaxlength, Boolean blnNewLineFormat, List<String> list_Errors, String strsplit, String strSeperator) {
		String strFormatted = strActualText;

		if (String.isBlank(strFormatted))
			return null;

		if (blnNewLineFormat) {
			List<String> list_temp = strActualText.split(strsplit);
			strFormatted = String.join(list_temp, strSeperator);
		}

		if (strActualText.length() > intMaxlength) {
			strFormatted = strFormatted.left(intMaxlength - 1);

			if (list_Errors == null) {
				list_Errors = new List<String>();
			}

			list_Errors.add(strFieldName);
		}

		return strFormatted;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Create Error Logs.
	 * @Parm        : Exception object.
	 * 				  string - method Name
	 * @Return      : void
	 **/
	public static void createErrorLog(Exception objEx, String strMethodName) {
		ExceptionLogUtil.logException('HIGroupEventTTSNotePostOEEmail', strMethodName, 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
	}

	/**
	 * @name         BOInfoWrapper
	 * @author       Deepika Saini
	 * @Date         10-07-2021
	 * @description  This class handles the BO Info
	 * @test class
	 **/
	class BOInfoWrapper {
		Id idBenefitOrder;
		Id idAccount;
		Id idOpportunity;
		String strRecordTypeName;

		BOInfoWrapper(Id idBenefitOrderTemp, Id idAccountTemp, Id idOpportunityTemp, String strRecordTypeNameTemp) {
			this.idBenefitOrder = idBenefitOrderTemp;
			this.idAccount = idAccountTemp;
			this.idOpportunity = idOpportunityTemp;
			this.strRecordTypeName = strRecordTypeNameTemp;
		}
	}

	/**
	 * @name         TTSInfoWrapper
	 * @author       Deepika Saini
	 * @Date         10-06-2021
	 * @description  This class handles the TTS Info getting from json response
	 * @test class
	 **/
	class TTSInfoWrapper {
		String strEventId;
		String strGhostPlan;
		String strContinuationEENotes;
		String strAdditionalDetails;
		Boolean blnIsRiders;
		String strERSignatureLocation;
		String strPOASignatoryName;
		String strPOASignatoryTitle;
		String strBenefitsAdminName;
		String strBenefitsAdminTitle;
		String strCompanyName;

		TTSInfoWrapper(
			String strEvent,
			String strGhostPlanTemp,
			String strContinuationEENotesTemp,
			String strAdditionalDetailsTemp,
			Boolean blnIsRidersTemp,
			String strERSignatureLocationTemp,
			String strPOASignatoryNameTemp,
			String strPOASignatoryTitleTemp,
			String strBenefitsAdminNameTemp,
			String strBenefitsAdminTitleTemp,
			String strCompanyNameTemp
		) {
			this.strEventId = strEvent;
			this.strGhostPlan = strGhostPlanTemp;
			this.strContinuationEENotes = strContinuationEENotesTemp;
			this.strAdditionalDetails = strAdditionalDetailsTemp;
			this.blnIsRiders = blnIsRidersTemp;
			this.strERSignatureLocation = strERSignatureLocationTemp;
			this.strPOASignatoryName = strPOASignatoryNameTemp;
			this.strPOASignatoryTitle = strPOASignatoryTitleTemp;
			this.strBenefitsAdminName = strBenefitsAdminNameTemp;
			this.strBenefitsAdminTitle = strBenefitsAdminTitleTemp;
			this.strCompanyName = strCompanyNameTemp;
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Send email to case team member.
	 * @Parm        : Map of Event Id with HIGroupEvent__c object
					: Map of "Company_Id__c +  Application_Id__c + Application_type__c" with BOWithEventInfoWrapper wrapper object
	  				: Set of Application_Id__c
	  				: Set of Company_Id__c
	                : Set of Application_type__c
	 * @Return      : void
	 **/
	static void sendEmailtoBOCaseTeamMember(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents,
		Map<String, BOWithEventInfoWrapper> map_BenefitOrderInfoWraps,
		List<HIGroupEvent__c> list_Events,
		Set<String> set_ApplicationIds,
		Set<String> set_CompanyIds,
		Set<String> set_ApplicationTypes
	) {
		Map<String, Id> map_EventIdToBenefitOrders = new Map<String, Id>();
		Map<Id, Id> map_BOToCaseIds = new Map<Id, Id>();
		Map<Id, Benefit_Order__c> map_CaseIdToBOs = new Map<Id, Benefit_Order__c>();
		List<Case> list_Cases = new List<Case>();
		Set<Id> set_BOOwners = new Set<Id>();
		List<Benefit_Order__c> list_BOs = new List<Benefit_Order__c>();
		Map<String, String> map_BOIdAndEventKey = new Map<String, String>();
		for (Benefit_Order__c objBO : [
			SELECT
				Application_Id__c,
				RecordType.Name,
				RecordType.DeveloperName,
				Account__r.ZP_Company_Id__c,
				Type__c,
				Order_Status__c,
				OwnerId,
				Coverage_Effective_Date__c,
				(
					SELECT
						Id,
						ContactId,
						Contact.FirstName,
						Contact.LastName,
						Contact.Email,
						Integration_Id__c,
						Case_Reference__c,
						Benefit_Order__r.OwnerId,
						AccountId,
						Account.Name,
						RecordTypeId,
						RecordType.Name,
						NP_Survey_URL__c,
						Renewal_Survey_URL__c,
						Opportunity__c,
						Benefit_Order__c
					FROM Cases__r
					WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE 'hippo-%' AND Benefit_Order__c != NULL AND Carrier_Order__c = NULL AND AccountId != NULL AND ContactId != NULL
					LIMIT 1
				),
				(
					SELECT
						Id,
						Order_Type__c,
						Implementation_Stage__c,
						Carrier__c,
						Carrier__r.Carrier_Id__c,
						Order_Assignment__c,
						Eligible_for_Submission_Automation__c,
						Plan_Change__c,
						Waiting_Period_Change__c,
						Contribution_Change__c,
						Is_Order_Eligible_For_Sub_Automation__c,
						OwnerId,
						Benefit_Types__c
					FROM Carrier_Orders__r
					WHERE
						RecordTypeId != NULL
						AND Implementation_Stage__c != :CO_CANCELED_STAGE
						AND Implementation_Stage__c != :CO_APPROVED_STAGE
						AND Carrier__c != NULL
				)
			FROM Benefit_Order__c
			WHERE
				Account__c != NULL
				AND Account__r.ZP_Company_Id__c != NULL
				AND Account__r.ZP_Company_Id__c IN :set_CompanyIds
				AND Application_Id__c != NULL
				AND RecordTypeId != NULL
				AND Application_Id__c IN :set_ApplicationIds
				AND RecordType.Name IN :set_applicationTypes
				AND Order_Status__c != :CO_CANCELED_STAGE
		]) {
			list_BOs.add(objBO);
			String strKey = getBenefitOrderKey(objBO);

			if (map_BenefitOrderInfoWraps.containsKey(strKey)) {
				BOWithEventInfoWrapper objBOWrapper = map_BenefitOrderInfoWraps.get(strKey);
				map_EventIdToBenefitOrders.put(objBOWrapper.strEventId, objBO.Id);

				if (objBO.Cases__r?.size() > 0) {
					for (Case objCase : objBO.Cases__r) {
						map_BOToCaseIds.put(objBO.Id, objCase.Id);
						list_Cases.add(objCase);
						map_CaseIdToBOs.put(objCase.Id, objBO);
					}
				}
			}

			if (String.valueOf(objBO.OwnerId).startsWith(USER_ID_PREFIX)) {
				set_BOOwners.add(objBO.OwnerId);
			}

			map_BOIdAndEventKey.put(objBO.Id, objBO.Application_Id__c + ';' + objBO.Account__r.ZP_Company_Id__c + ';tts_note_post_OE_email');
		}

		if (map_BOToCaseIds?.size() > 0) {
			List<Messaging.SingleEmailMessage> list_SingleEmailMessages = new List<Messaging.SingleEmailMessage>();
			List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
			OEEmailAutomationHelper.fetchCaseTeamMember(new Set<Id>(map_BOToCaseIds.values()));

			for (Case objCustomerCase : list_Cases) {
				Benefit_Order__c objBO = map_CaseIdToBOs.get(objCustomerCase.Id);

				objEmailTemplate = map_EmailTemplates.get(RENEWWAL_EMAIL_TEMPLATE);
				if (objBO.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN) {
					objEmailTemplate = map_EmailTemplates.get(NEWPLAN_EMAIL_TEMPLATE);
				} else if (objBO.RecordType.Name == BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL) {
					Boolean blnCarrierSwitch = false;
					for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
						if (String.isNotBlank(objCO.Order_Assignment__c) && objCO.Order_Assignment__c.containsIgnoreCase(CO_OA_CARRIER_SWITCH)) {
							blnCarrierSwitch = true;
						}
					}

					if (blnCarrierSwitch) {
						objEmailTemplate = map_EmailTemplates.get(NEWPLAN_EMAIL_TEMPLATE);
					}
				}

				String strKey = getBenefitOrderKey(objBO);
				BOWithEventInfoWrapper objBOWrapper = null;

				if (map_BenefitOrderInfoWraps.containsKey(strKey)) {
					objBOWrapper = map_BenefitOrderInfoWraps.get(strKey);
				}

				String strEmailSubject = objEmailTemplate.Subject;
				String strEmailBody = objEmailTemplate.HtmlValue;
				if (objCustomerCase != null && objCustomerCase.ContactId != null) {
					strEmailBody = objCustomerCase.Contact.FirstName != null
						? strEmailBody.replace(CONTACT_FIRST_NAME_TAG, objCustomerCase.Contact.FirstName)
						: strEmailBody.replace(CONTACT_FIRST_NAME_TAG, '');
				}

				String strGhostPlans = '';
				String strGhostPlanCarriers = '';

				if (objBOWrapper.objEventInfoJSON != null && objBOWrapper.objEventInfoJSON.ghost_plans?.size() > 0) {
					for (HIGroupEventTTSNotePostOEEmailJSON.GhostPlans objGhostPlan : objBOWrapper.objEventInfoJSON.ghost_plans) {
						if (String.isNotBlank(objGhostPlan.carrier_name)) {
							strGhostPlans = strGhostPlans + ', ' + objGhostPlan.carrier_name;

							if (objGhostPlan.plan_details?.size() > 0) {
								strGhostPlanCarriers = strGhostPlanCarriers + ', ' + String.join(objGhostPlan.plan_details, ', ');
							}
						}
					}
				}

				if (String.isNotBlank(strGhostPlans) && String.isNotBlank(strGhostPlanCarriers)) {
					strGhostPlans = strGhostPlans.replaceFirst(', ', '');
					strGhostPlanCarriers = strGhostPlanCarriers.replaceFirst(', ', '');
					String strMarcoBody = '';
					if (map_EmailMacros != null && !map_EmailMacros.isEmpty() && map_EmailMacros.containsKey(GHOST_PLAN_MACRO)) {
						strMarcoBody = map_EmailMacros.get(GHOST_PLAN_MACRO);
					}
					strEmailBody = strEmailBody.replace(GHOST_PLAN_SECTION, strMarcoBody);
					strEmailBody = strEmailBody.replace(GUSTO_PLAN_REMOVED_TAG, strGhostPlans);
					strEmailBody = strEmailBody.replace(GUSTO_PLAN_NAME_TAG, strGhostPlanCarriers);
				} else {
					strEmailBody = strEmailBody.remove(GHOST_PLAN_SECTION);
				}

				Map<Id, String> map_UserSignature = OEEmailAutomationHelper.fetchUserSignature(set_BOOwners);
				strEmailBody = OEEmailAutomationHelper.mergeCommonFieldsInTemplate(strEmailBody, map_UserSignature, objCustomerCase);

				Messaging.SingleEmailMessage objMail = OEEmailAutomationHelper.createEmailRecord(strEmailSubject, objCustomerCase, strEmailBody);
				EmailMessage objMsg = OEEmailAutomationHelper.createEmailMessageRecord(strEmailBody, objCustomerCase, strEmailSubject, objEmailTemplate.DeveloperName);

				Map<String, OrgWideEmailAddress> map_orgWideAddress = OEEmailAutomationHelper.getOrgWideAddresses(new Set<String>{ OWD_EMAIL_NEWPLANS, OWD_EMAIL_RENEWALS });
				if (objBO != null && map_orgWideAddress != null && map_orgWideAddress.containsKey(objBO.RecordType.DeveloperName)) {
					objMsg.fromAddress = map_orgWideAddress.get(objBO.RecordType.DeveloperName).Address;
					objMail.setOrgWideEmailAddressId(map_orgWideAddress.get(objBO.RecordType.DeveloperName).Id);
				}

				list_SingleEmailMessages.add(objMail);
				list_EmailMessages.add(objMsg);
			}

			if (list_SingleEmailMessages?.size() > 0) {
				List<Messaging.SendEmailResult> list_results = new List<Messaging.SendEmailResult>();
				if (OrganizationUtilities.canSendEmails()) {
					list_results = Messaging.sendEmail(list_SingleEmailMessages);
				}

				if (list_results.size() == 0 || list_results[0].success) {
					insert list_EmailMessages;
				}
			}

			if (list_EmailMessages?.size() > 0) {
				updateGroupEventStatus(map_EventIdHIGrpEvents, map_EventIdToBenefitOrders, map_BOToCaseIds, list_BOs);
			}
		} else {
			updateGroupEventStatus(map_EventIdHIGrpEvents, map_EventIdToBenefitOrders, map_BOToCaseIds, list_BOs);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Process Benefit Order and return a key
	 * @Parm        : Benefit_Order__c object.
	 * @Return      : String
	 **/
	public static String getBenefitOrderKey(Benefit_Order__c objBO) {
		String strKey = objBO.Account__r.ZP_Company_Id__c + '-' + objBO.Application_Id__c + '-' + objBO.RecordType.Name;

		return strKey;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Get Selected Policy
	 * @Parm        : Set of CO Ids.
	 * @Return      : Map<Id, Boolean>
	 **/
	public static Map<Id, Boolean> getSelectedPolicy(Set<Id> set_COIds) {
		Map<Id, Boolean> map_COIdWithSelectedPolicy = new Map<Id, Boolean>();
		if (!set_COIds.isEmpty()) {
			for (Policy__c objPolicy : [SELECT id, name, Carrier_Order__c, Is_Selected__c FROM Policy__c WHERE Carrier_Order__c != NULL AND Carrier_Order__c IN :set_COIds AND Is_Selected__c = TRUE]) {
				map_COIdWithSelectedPolicy.put(objPolicy.Carrier_Order__c, true);
			}
		}

		return map_COIdWithSelectedPolicy;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update Success or Error status on HI Group Event records
	 * @Parm        : Map of String and HIGroupEvent__c object.
	 				: Map of String and Id of of Benefit Order object.
					: Map of Benefit Order Id and Case record Id.
	 * @Return      : void
	 **/
	public static void updateGroupEventStatus(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents,
		Map<String, Id> map_EventIdToBenefitOrders,
		Map<Id, Id> map_BOToCaseIds,
		List<Benefit_Order__c> list_BOs
	) {
		Set<Id> set_BOIds = new Set<Id>();
		Set<String> set_BOTypeToInclude = new Set<String>();
		set_BOTypeToInclude.add(BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN);
		set_BOTypeToInclude.add(BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL);

		for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvents.values()) {
			if (String.isNotBlank(objEvent.Event_Id__c)) {
				if (map_EventIdToBenefitOrders.containsKey(objEvent.Event_Id__c)) {
					Id idBO = map_EventIdToBenefitOrders.get(objEvent.Event_Id__c);
					if (map_BOToCaseIds.containsKey(idBO)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIGroupEventUtil.GROUP_TTS_NOTE_POST_PROCESSED_MESSAGE, objEvent);
						set_BOIds.add(idBO);
					} else {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIGroupEventUtil.CASE_RELATED_TO_BO_NOT_FOUND, objEvent);
					}
				} else {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIGroupEventUtil.DOC_COLLECTION_DEAD_UNPROCESSED_EVENT, objEvent);
				}
			}
		}

		Map<Id, Boolean> map_COIdWithSelectedPolicy = new Map<Id, Boolean>();
		Set<Id> set_COIds = new Set<Id>();
		if (list_BOs != null && list_BOs?.size() > 0) {	
			for (Benefit_Order__c objBO : list_BOs) {
				for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
					set_COIds.add(objCO.Id);
				}
			}
			map_COIdWithSelectedPolicy = getSelectedPolicy(set_COIds);
		}

		if (set_BOIds?.size() > 0 && list_BOs?.size() > 0) {
			Map<Id, Carrier_Order__c> map_COs = new Map<Id, Carrier_Order__c>();	
			for (Benefit_Order__c objBO : list_BOs) {
				if (set_BOIds.contains(objBO.Id)) {
					for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
						if (set_BOTypeToInclude.contains(objBO.RecordType.Name)) {
							if ((objCO.Carrier__c != null && objCO.Carrier__c == Label.BASIC_Carrier) || map_COIdWithSelectedPolicy.containsKey(objCO.Id)) {
								objCO.Implementation_Stage__c = CO_READY_FOR_SUBMISSION_PREP;
								objCO.Is_Order_Eligible_For_Sub_Automation__c = true;
							} else {
								objCO.Implementation_Stage__c = CarrierOrderUtil.STAGE_CANCELLED;
							}
							map_COs.put(objCO.Id, objCO);
						}
					}
				}
			}

			if (map_COs.size() > 0) {
				SubmissionAutomationHelper.checkCOToAutomation(map_COs);
				update map_COs.values();
			}
		}
	}

	/**
	 * @name         BOWithEventInfoWrapper
	 * @author       Bhagat Singh
	 * @Date         10-05-2021
	 * @description  This class handles the Benefit Order Info getting from json response
	 * @test class   HIGroupEventTTSNotePostOEEmailTest.cls
	 **/
	class BOWithEventInfoWrapper {
		String strEventId;
		HIGroupEventTTSNotePostOEEmailJSON objEventInfoJSON;
		BOWithEventInfoWrapper(String strEvent, HIGroupEventTTSNotePostOEEmailJSON objEvent) {
			this.strEventId = strEvent;
			this.objEventInfoJSON = objEvent;
		}
	}
}