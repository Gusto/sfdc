/**
 * @name         HIGroupEventOAIntroEmail
 * @author       Bhagat Singh
 * @Date         29 June 2021
 * @description  This class handles the messages sent to kafka topic OA_intro_email via Workato and writes it to the HIGroupEvent__c object
 * @test class   HIGroupEventOAIntroEmailTest.cls
 **/
public class HIGroupEventOAIntroEmail {
	public static String OT_NEW_TO_GUSTO = 'New to Gusto';
	public static String OT_CARRIER_SWITCH = 'Carrier switch';
	public static String OT_SAME_CARRIER_PLAN_GROUP = 'Same carrier, plan/group level changes';
	public static String OT_SAME_CARRIER_NO_PLAN_GROUP = 'Same carrier, NO plan/group level changes';
	public static String OA_INTRO_EMAIL_TEMPLATE = 'OA_Intro_Email';
	public static final String EMAIL_SUBJECT_1 = 'OA-INTRO-EMAIL-SUBJECT-1';
	public static final String EMAIL_SUBJECT_2 = 'OA-INTRO-EMAIL-SUBJECT-2';
	public static final String USER_ID_PREFIX = '005';
	public static final String EMAIL_SUBJECT_TAG = '[OA Intro Email Subject]';
	public static final String EMAIL_BODY_TAG = '[OA Intro Email Body]';
	public static final String OWD_EMAIL_NEWPLANS = 'newplans@gusto.com';
	public static final String OWD_EMAIL_RENEWALS = 'renewals@gusto.com';
	public static EmailTemplate objEmailTemplate = new EmailTemplate();
	public static Map<String, String> map_EmailMacros = new Map<String, String>();
	public static final Set<String> set_COExcludedStages = new Set<String>{ 'Canceled', 'Approved'};
	public static final String CO_STAGE_OE = 'OE';
	public static Map<Id, Boolean> map_CaseIdsWithSentEmail = new Map<Id, Boolean>();

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Reterive email template and email macro.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static {
		objEmailTemplate = [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :OA_INTRO_EMAIL_TEMPLATE LIMIT 1];

		for (Email_Macro__c objEM : [
			SELECT Body__c, Macro_Identifier__c
			FROM Email_Macro__c
			WHERE Macro_Identifier__c != NULL AND (Macro_Identifier__c = :EMAIL_SUBJECT_1 OR Macro_Identifier__c = :EMAIL_SUBJECT_2)
		]) {
			map_EmailMacros.put(objEM.Macro_Identifier__c, objEM.Body__c);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Process HIGroupEvents and send OA Intro email to related case team member.
	 * @Parm        : List of HIGroupEvent__c records.
	 * @Return      : void
	 **/
	public static void processEvents(List<HIGroupEvent__c> list_Events) {
		Set<String> set_ApplicationIds = new Set<String>();
		Set<String> set_CompanyIds = new Set<String>();
		Set<String> set_ApplicationTypes = new Set<String>();
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents = new Map<String, HIGroupEvent__c>();
		Map<String, BenefitOrderInfoWrapper> map_BenefitOrderInfoWraps = new Map<String, BenefitOrderInfoWrapper>();
		map_CaseIdsWithSentEmail = new Map<Id, Boolean>();

		if (list_Events == null || list_Events.isEmpty()) {
			return;
		}

		for (HIGroupEvent__c objEvent : list_Events) {
			if (String.isBlank(objEvent.Event_Info__c)) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EVENT_INFO_MISSING, objEvent);
				continue;
			}

			try {
				HIGroupEventOAIntroEmailJSON objEventInfoJSON = (HIGroupEventOAIntroEmailJSON) JSON.deserialize(objEvent.Event_Info__c, HIGroupEventOAIntroEmailJSON.class);

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

				if (String.isBlank(objEvent.Email_Body__c)) {
					if (String.isBlank(objEventInfoJSON.email_body)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, HIGroupEventUtil.ERROR_EMAIL_BODY_MISSING, objEvent);
						continue;
					}
					objEvent.Email_Body__c = objEventInfoJSON.email_body;
				}

				set_ApplicationIds.add(objEvent.Application_Id__c);
				set_CompanyIds.add(objEvent.Company_Id__c);
				set_ApplicationTypes.add(objEvent.Application_type__c);

				String strKey = objEvent.Company_Id__c + '-' + objEvent.Application_Id__c + '-' + objEvent.Application_type__c;
				BenefitOrderInfoWrapper objBOWrap = new BenefitOrderInfoWrapper(objEvent.Event_Id__c, objEvent.Email_Body__c);
				map_BenefitOrderInfoWraps.put(strKey, objBOWrap);
				map_EventIdHIGrpEvents.put(objEvent.Event_Id__c, objEvent);
			} catch (Exception objEx) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Error while parsing Event Info: ' + objEx.getMessage(), objEvent);
			}
		}

		try {
			if (map_EventIdHIGrpEvents.isEmpty() || set_ApplicationIds.isEmpty() || set_CompanyIds.isEmpty() || set_ApplicationTypes.isEmpty()) {
				return;
			}
			sendEmailtoBOCaseTeamMember(map_EventIdHIGrpEvents, map_BenefitOrderInfoWraps, list_Events, set_ApplicationIds, set_CompanyIds, set_ApplicationTypes);
		} catch (Exception objEx) {

			if(!objEx.getMessage().contains('EMAIL_ADDRESS_BOUNCED') && !objEx.getMessage().contains('INVALID_EMAIL_ADDRESS')) {
				createErrorLog(objEx);
			}

			for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvents.values()) {
				HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, objEx.getMessage(), objEvent);
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Send email to case team member.
	 * @Parm        : Map of Event Id with HIGroupEvent__c object
					: Map of "Company_Id__c +  Application_Id__c + Application_type__c" with BenefitOrderInfoWrapper wrapper object
	  				: Set of Application_Id__c
	  				: Set of Company_Id__c
	                : Set of Application_type__c
	 * @Return      : void
	 **/
	static void sendEmailtoBOCaseTeamMember(
		Map<String, HIGroupEvent__c> map_EventIdHIGrpEvents,
		Map<String, BenefitOrderInfoWrapper> map_BenefitOrderInfoWraps,
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
						Contact.Name,
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
						Benefit_Order__c,
						Benefit_Order__r.Parent_Benefit_Order__c
					FROM Cases__r
					WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE 'hippo-%' AND Benefit_Order__c != NULL AND Carrier_Order__c = NULL AND AccountId != NULL AND ContactId != NULL
					LIMIT 1
				),
				(
					SELECT Id, Order_Type__c, Implementation_Stage__c, Carrier__c, Carrier__r.Carrier_Id__c, Order_Assignment__c, Benefit_Order__c
					FROM Carrier_Orders__r
					WHERE RecordTypeId != NULL AND Implementation_Stage__c NOT IN :set_COExcludedStages AND Carrier__c != NULL
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
		]) {
			list_BOs.add(objBO);
			String strKey = getBenefitOrderKey(objBO);
			if (map_BenefitOrderInfoWraps.containsKey(strKey)) {
				BenefitOrderInfoWrapper objBOWrapper = map_BenefitOrderInfoWraps.get(strKey);
				map_EventIdToBenefitOrders.put(objBOWrapper.strEventId, objBO.Id);

				if (objBO.Cases__r != null && objBO.Cases__r.size() > 0) {
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
		}

		if (map_BOToCaseIds.size() > 0) {
			List<Messaging.SingleEmailMessage> list_SingleEmailMessages = new List<Messaging.SingleEmailMessage>();
			List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
			OEEmailAutomationHelper.fetchCaseTeamMember(new Set<Id>(map_BOToCaseIds.values()));
			checkOAIntroEmailSent(map_BOToCaseIds.values());
			Set<Id> set_CaseIdsWithSentEmail = new Set<Id>();

			for (Case objCustomerCase : list_Cases) {
				if (map_CaseIdsWithSentEmail.containsKey(objCustomerCase.Id) || objCustomerCase.Benefit_Order__r?.Parent_Benefit_Order__c != null) {
					set_CaseIdsWithSentEmail.add(objCustomerCase.Id);
					continue;
				}

				Benefit_Order__c objBO = map_CaseIdToBOs.get(objCustomerCase.Id);
				String strKey = getBenefitOrderKey(objBO);
				BenefitOrderInfoWrapper objBOWrapper = null;
				if (map_BenefitOrderInfoWraps.containsKey(strKey)) {
					objBOWrapper = map_BenefitOrderInfoWraps.get(strKey);
				}

				String strEmailSubject = getEmailSubject(objBO.Type__c);
				//Calling this in loop because we are sure that there will be one case and contact for Benefit Order
				Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(objEmailTemplate.Id, objCustomerCase.Id, objCustomerCase.ContactId);
				String strEmailBody = mail.getHtmlBody();
				strEmailBody = strEmailBody.replace(EMAIL_SUBJECT_TAG, strEmailSubject);
				if (objBOWrapper != null) {
					strEmailBody = strEmailBody.replace(EMAIL_BODY_TAG, objBOWrapper.strEmailBody);
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

			if (list_SingleEmailMessages.size() > 0) {
				List<Messaging.SendEmailResult> list_results = new List<Messaging.SendEmailResult>();
				if(OrganizationUtilities.canSendEmails()){
					list_results = Messaging.sendEmail(list_SingleEmailMessages);
				}
				if (list_results.size() == 0 || list_results[0].success) {
					insert list_EmailMessages;
				}
			}

			if (list_EmailMessages.size() > 0 || set_CaseIdsWithSentEmail.size() > 0) {
				updateGroupEventStatus(map_EventIdHIGrpEvents, map_EventIdToBenefitOrders, map_BOToCaseIds, list_BOs);
			}
		} else {
			updateGroupEventStatus(map_EventIdHIGrpEvents, map_EventIdToBenefitOrders, map_BOToCaseIds, list_BOs);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Create Error Logs.
	 * @Parm        : Exception object.
	 * @Return      : void
	 **/
	public static void createErrorLog(Exception objEx) {
		ExceptionLogUtil.logException('HIGroupEventOAIntroEmail', 'sendEmailtoBOCaseTeamMember', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
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
	 * @Description : Get Email subject on the basis of Order Type
	 * @Parm        : String object.
	 * @Return      : String
	 **/
	public static String getEmailSubject(String strOrderType) {
		String strEmailSubject = '';
		if ((strOrderType == OT_NEW_TO_GUSTO || strOrderType == OT_CARRIER_SWITCH) && map_EmailMacros.containsKey(EMAIL_SUBJECT_1)) {
			strEmailSubject = map_EmailMacros.get(EMAIL_SUBJECT_1);
		} else if ((strOrderType == OT_SAME_CARRIER_PLAN_GROUP || strOrderType == OT_SAME_CARRIER_NO_PLAN_GROUP) && map_EmailMacros.containsKey(EMAIL_SUBJECT_1)) {
			strEmailSubject = map_EmailMacros.get(EMAIL_SUBJECT_2);
		}

		return strEmailSubject;
	}

	/********/
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
		Set<Id> set_ParentBoIds = new Set<Id>();
		for (HIGroupEvent__c objEvent : map_EventIdHIGrpEvents.values()) {
			if (String.isNotBlank(objEvent.Event_Id__c)) {
				if (map_EventIdToBenefitOrders.containsKey(objEvent.Event_Id__c)) {
					Id idBO = map_EventIdToBenefitOrders.get(objEvent.Event_Id__c);
					if (map_BOToCaseIds.containsKey(idBO)) {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, HIGroupEventUtil.GROUP_OA_INTRO_EMAIL_PROCESSED_MESSAGE, objEvent);
						set_BOIds.add(idBO);
					} else {
						HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIGroupEventUtil.CASE_RELATED_TO_BO_NOT_FOUND, objEvent);
					}
				} else {
					HIGroupEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, HIGroupEventUtil.DOC_COLLECTION_DEAD_UNPROCESSED_EVENT, objEvent);
				}
			}
		}

		if (set_BOIds?.size() > 0 && list_BOs?.size() > 0) {
			List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
			List<Carrier_Order__c> list_COs = new List<Carrier_Order__c>();
			Set<String> set_EarlySubmissionStages = CarrierOrderTriggerHelper.set_ImplementationStages;
			for (Benefit_Order__c objBO : list_BOs) {
				if (set_BOIds.contains(objBO.Id)) {
					Id idCaseObj = null;
					if (objBO.Cases__r != null && objBO.Cases__r.size() > 0) {
						idCaseObj = objBO.Cases__r[0].Id;
					}

					if (idCaseObj == null || !map_CaseIdsWithSentEmail.containsKey(idCaseObj)) {
						Integer intEarlySubmissionCOCount = 0;
						Integer intOtherCOCount = 0;
						for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
							if (String.isNotBlank(objCO.Implementation_Stage__c) && !set_EarlySubmissionStages.contains(objCO.Implementation_Stage__c)) {
								set_ParentBoIds.add(objCO.Benefit_Order__c);
								list_COs.add(new Carrier_Order__c(Id = objCO.Id, Implementation_Stage__c = CO_STAGE_OE));
								intOtherCOCount += 1;
							}

							if (set_EarlySubmissionStages.contains(objCO.Implementation_Stage__c)) {
								intEarlySubmissionCOCount += 1; 
							}
						}

						//Exclude CO is in 'Canceled' or 'Approved' stage. 
						//If all the other CO under the benefit order is in 'Ready for Early Submission' or 'Early Submission'. Move BO to 'OE' stage
						if (intEarlySubmissionCOCount > 0 && intOtherCOCount == 0) {
							list_BenefitOrders.add(new Benefit_Order__c(Id = objBO.Id, Order_Status__c = CO_STAGE_OE));
						}
					}
				}
			}

			if (set_ParentBoIds?.size() > 0) {
				for (Carrier_Order__c objCO : [
					SELECT Id, Order_Type__c, Implementation_Stage__c, Carrier__c, Carrier__r.Carrier_Id__c, Order_Assignment__c, Benefit_Order__r.Parent_Benefit_Order__c
					FROM Carrier_Order__c
					WHERE Benefit_Order__r.Parent_Benefit_Order__c IN :set_ParentBoIds AND Implementation_Stage__c NOT IN :set_EarlySubmissionStages
				]) {
					list_COs.add(new Carrier_Order__c(Id = objCO.Id, Implementation_Stage__c = CO_STAGE_OE));
				}
			}

			if (list_COs?.size() > 0) {
				update list_COs;
			}

			if (list_BenefitOrders.size() > 0) {
				update list_BenefitOrders;
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Check oa_intro_email already sent or not.
	 * @Parm        : List of Case record Ids.
	 * @Return      : void
	 **/
	public static void checkOAIntroEmailSent(List<Id> list_CaseIds) {
		map_CaseIdsWithSentEmail = new Map<Id, Boolean>();
		for (EmailMessage objEM : [SELECT Id, ParentId FROM EmailMessage WHERE ParentId IN :list_CaseIds AND Email_Template_Name__c = :OA_INTRO_EMAIL_TEMPLATE]) {
			map_CaseIdsWithSentEmail.put(objEM.ParentId, true);
		}
	}

	/**
	 * @name         BenefitOrderInfoWrapper
	 * @author       Bhagat Singh
	 * @Date         03 June 2021
	 * @description  This class handles the Benefit Order Info getting from json response
	 * @test class   HIGroupEventOAIntroEmailTest.cls
	 **/
	class BenefitOrderInfoWrapper {
		String strEmailBody;
		String strEventId;
		BenefitOrderInfoWrapper(String strEvent, String strEmailBody) {
			this.strEventId = strEvent;
			this.strEmailBody = strEmailBody;
		}
	}
}