/**
 * @name         OEEmailAutomationHelper
 * @author       Neha Dabas
 * @date         13th August 2020
 * @description  Common methods for OE Email Automation.
 * @test class   OEIncompleteEmailBatchTest,CarrierOrderTriggerHelperTest,OEReminderEmailBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class OEEmailAutomationHelper {
	public static final String NONE = 'None';
	public static final Id idBasicCarrier = Label.BASIC_Carrier;
	public static Map<String, OrgWideEmailAddress> map_orgWideAddress;
	public static final String BENEFITS_NEW_PLAN_CASE_RT_ID = 'Benefits New Plan Case';
	public static final String BENEFITS_CHANGE_CASE_RT_ID = 'Benefits Change Case';
	public static final String BENEFITS_RENEWAL_CASE_RT_ID = 'Benefits Renewal Case';
	public static final String MSQ_ALL_ORDERS_SHOULD_BE_APPROVED = 'All Carrier orders needs to be approved before Benefit order is Fulfilled';
	public static final String MSQ_ORDER_SHOULD_BE_TERMINATION_COMPLETE = 'terminated carrier order status should be termination complete';
	public static Map<Id, Set<String>> map_CaseTeamMemberEmails = new Map<Id, Set<String>>();
	public static final String CONTACT_ID_PREFIX = '003';
	public static final String FULFILLED =  'Fulfilled';
	public static final String strTAdA =  'TAdA';
	public static Set<Id> set_TAdACarrierIds = Utils.set_TAdACarrierIds;
	/*
	 * Send Confirmation Email
	 */
	public static void sendConfirmationEmail(Id idBO) {
		try {
			if (String.isBlank(idBO)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This action is accessible only from Benefit Order.'));
				return;
			}
			Set<String> set_COValidStages = new Set<String>{ 'Approved', 'Approved Pending EE Audit'};
			Case objCustomerCase;
			Benefit_Order__c objBO = [
				SELECT
					Order_Status__c,
					OwnerId,
					Opportunity__r.RecordType.DeveloperName,
					RecordTypeId,
					RecordType.DeveloperName,
					Opportunity__c,
					Coverage_Effective_Date__c,
					(
						SELECT Carrier__c, Order_Type__c, Benefit_Types__c, Group_Number__c, Order_Assignment__c, Carrier__r.Carrier_Unique_Name__c
						FROM Carrier_Orders__r
						WHERE (Implementation_Stage__c IN :set_COValidStages OR (Order_Assignment__c = 'Terminated Order')) AND Carrier__c != NULL
					),
					(
						SELECT
							ContactId,
							Contact.Name,
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
							Opportunity__c
						FROM Cases__r
						WHERE Integration_Id__c != NULL AND Integration_Id__c LIKE 'hippo-%' AND Benefit_Order__c != NULL AND Carrier_Order__c = NULL AND AccountId != NULL
					)
				FROM Benefit_Order__c
				WHERE Id = :idBO AND Order_Status__c = 'Approved' AND Opportunity__c != NULL
			];

			if (objBO == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Benefit Order is either not approved or this action is not avaiable to you.'));
				return;
			}

			List<Benefit_Order__c> list_BenefitOrdersToBeUpdated = new List<Benefit_Order__c>();

			List<Carrier_Order__c> list_CarrierOrders = [
				SELECT Id, Name, Implementation_Stage__c, Benefit_Order__r.Order_Status__c
				FROM Carrier_Order__c
				WHERE
					Benefit_Order__c = :idBO
					AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_APPROVED
					AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CLOSED_ADMIN
					AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CLOSED_LOST
					AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CANCELLED
					AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_APPROVED_PENDING_EE_AUDIT
			];
			if (list_CarrierOrders.size() > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MSQ_ALL_ORDERS_SHOULD_BE_APPROVED));
				return;
			} else {
				Map<Id, Ticket__c> map_OpenTicketsWithBO = BenefitOrderUtil.fetchOpenTicketsRelatedToBO(new Set<Id>{ idBO });
				if (!map_OpenTicketsWithBO.isEmpty()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, BenefitOrderUtil.MSQ_CLOSE_OPEN_TICKET_FIRST));
					return;
				}
				if (objBO.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_RENEWAL || objBO.RecordTypeId == BenefitOrderHelper.BO_REC_TYPE_ID_CHANGE) {
					List<Carrier_Order__c> list_COsTerminatedOrder = [
						SELECT Id, name, Implementation_Stage__c, Benefit_Order__r.Order_Status__c
						FROM Carrier_Order__c
						WHERE
							Benefit_Order__c = :idBO
							AND Order_Type__c = :BenefitOrderUtil.ORDER_TYPE_TERMINATED_ORDER
							AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CLOSED_LOST
							AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CANCELLED
							AND Implementation_Stage__c != :BenefitOrderUtil.STATUS_CLOSED_ADMIN
					];

					if (list_COsTerminatedOrder.size() > 0) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MSQ_ORDER_SHOULD_BE_TERMINATION_COMPLETE));
					} else {
						Benefit_Order__c objBOToUpdate = new Benefit_Order__c(Id = idBO, Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED);
						list_BenefitOrdersToBeUpdated.add(objBOToUpdate);
						updateChildBenefitOrderStatus(idBO);
					}
				} else {
					//if it is new plan then directly benefit order gets updated.
					Benefit_Order__c objBOToUpdate = new Benefit_Order__c(Id = idBO, Order_Status__c = BenefitOrderUtil.STATUS_FULFILLED);
					list_BenefitOrdersToBeUpdated.add(objBOToUpdate);
					updateChildBenefitOrderStatus(idBO);
				}
			}

			if (objBO.Cases__r == null || objBO.Cases__r.isEmpty()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Customer case associated with this Benefit Order.'));
				return;
			}
			String strIntegrationKey = 'hippo-' + objBO.Opportunity__r.RecordType.DeveloperName + '-' + objBO.Opportunity__c;

			for (Case objCase : objBO.Cases__r) {
				if (strIntegrationKey.equalsIgnoreCase(objCase.Integration_Id__c)) {
					objCustomerCase = objCase;
					break;
				}
			}
			if (objCustomerCase == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Integeration Id is not in desired format on the Customer Case.'));
				return;
			}
			if (objCustomerCase.ContactId == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is not present on the Customer Case.'));
				return;
			}
			// update benefit order
			if (list_BenefitOrdersToBeUpdated != null) {
				Boolean blnSkipTrigger = BenefitOrderHelper.skipTrigger;
				BenefitOrderHelper.skipTrigger = false;
				update list_BenefitOrdersToBeUpdated;
				BenefitOrderHelper.skipTrigger = blnSkipTrigger;
			}
			map_orgWideAddress = getOrgWideAddresses(new Set<String>{ 'newplans@gusto.com', 'renewals@gusto.com' });
			String strEmailTemplateName = 'OE_Confirmation_Email_Default';
			EmailTemplate objEmailTemplate = [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName LIMIT 1];

			if (objEmailTemplate == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email template not present.'));
				return;
			}
			Map<Id, Map<String, Email_Macro__c>> map_CarrierEmailMacros;

			Map<Id, String> map_UserSignature = OEEmailAutomationHelper.fetchUserSignature(new Set<Id>{ objBO.OwnerId });
			List<Attachment> list_Attachments = [SELECT Name, Body, ContentType FROM Attachment WHERE ParentId = :objEmailTemplate.Id];
			if (objBO.Carrier_Orders__r != null && !objBO.Carrier_Orders__r.isEmpty()) {
				Set<Id> set_CarrierIds = new Set<Id>();
				for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
					if (objCO.Carrier__c != null) {
						set_CarrierIds.add(objCO.Carrier__c);
					}			
				}

				//fetch Email macros
				List<Email_Macro__c> list_EmailMacro = fetchEmailMacros(set_CarrierIds);
				Map<String, Object> map_Response = segregateEmailMacros(list_EmailMacro);
				Map<String, Email_Macro__c> map_MacroWithoutCarrier;
				Map<String, Map<String, Email_Macro__c>> map_MacrosWithTAdA = new Map<String, Map<String, Email_Macro__c>>();
				if (map_Response != null) {
					if (map_Response.containsKey('WithCarrier')) {
						map_CarrierEmailMacros = (Map<Id, Map<String, Email_Macro__c>>) map_Response.get('WithCarrier');
					}
					if (map_Response.containsKey('WithoutCarrier')) {
						map_MacroWithoutCarrier = (Map<String, Email_Macro__c>) map_Response.get('WithoutCarrier');
					}
					if (map_Response.containsKey('WithTAdA')) {
						map_MacrosWithTAdA = (Map<String, Map<String, Email_Macro__c>>) map_Response.get('WithTAdA');
					}
				}
				String strBody = '';
				Messaging.EmailFileAttachment objAlegeusAttachment;
				Map<String, Object> map_Results = mergeDynamicContentInEmail(
					objBO.Carrier_Orders__r,
					map_CarrierEmailMacros,
					objEmailTemplate.HtmlValue,
					map_UserSignature,
					objCustomerCase,
					map_MacroWithoutCarrier,
					map_MacrosWithTAdA
				);
				if (map_Results.containsKey('EmailBody')) {
					strBody = (String) map_Results.get('EmailBody');
				}

				String strformattedDate = '';
				if (objBO.Coverage_Effective_Date__c != null) {
					strformattedDate = '' + objBO.Coverage_Effective_Date__c.month() + '/' + objBO.Coverage_Effective_Date__c.day() + '/' + objBO.Coverage_Effective_Date__c.year();
				}

				strBody = strBody.replace('[EFFECTIVE DATE]', strformattedDate);
				strBody = strBody.replace('[Effective DATE]', strformattedDate);
				strBody = strBody.replace('[Effective Date]', strformattedDate);

				if (objCustomerCase != null && objCustomerCase.Id != null) {
					OEEmailAutomationHelper.fetchCaseTeamMember(new Set<Id>{ objCustomerCase.Id });
				}

				Messaging.SingleEmailMessage objMail = OEEmailAutomationHelper.createEmailRecord(objEmailTemplate.Subject, objCustomerCase, strBody);
				EmailMessage objMsg = OEEmailAutomationHelper.createEmailMessageRecord(strBody, objCustomerCase, objEmailTemplate.Subject, objEmailTemplate.DeveloperName);

				//set from addresses
				if (map_orgWideAddress != null && map_orgWideAddress.containsKey(objBO.RecordType.DeveloperName)) {
					objMsg.fromAddress = map_orgWideAddress.get(objBO.RecordType.DeveloperName).Address;
					objMail.setOrgWideEmailAddressId(map_orgWideAddress.get(objBO.RecordType.DeveloperName).Id);
				}

				List<Messaging.EmailFileAttachment> list_EmailAttchments = new List<Messaging.EmailFileAttachment>();
				if (map_Results.containsKey('MacroAttachments')) {
					if (list_Attachments == null) {
						list_Attachments = new List<Attachment>();
					}
					list_Attachments.addAll((List<Attachment>) map_Results.get('MacroAttachments'));
				}
				if (list_Attachments != null && !list_Attachments.isEmpty()) {
					for (Attachment objAtt : list_Attachments) {
						Messaging.EmailFileAttachment objAttachment = new Messaging.EmailFileAttachment();
						objAttachment.setFileName(objAtt.Name);
						objAttachment.setBody(objAtt.Body);
						list_EmailAttchments.add(objAttachment);
					}
				}
				if (!list_EmailAttchments.isEmpty()) {
					objMail.setFileAttachments(list_EmailAttchments);
				}
				Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objMail });

				if (results[0].success) {
					insert objMsg;
					if (list_Attachments != null && !list_Attachments.isEmpty()) {
						List<Attachment> list_AttachmentsToAddToEmailMessage = new List<Attachment>();
						for (Attachment objAtt : list_Attachments) {
							list_AttachmentsToAddToEmailMessage.add(new Attachment(Body = objAtt.Body, ParentId = objMsg.Id, ContentType = objAtt.ContentType, Name = objAtt.Name));
						}
						insert list_AttachmentsToAddToEmailMessage;
					}
				}
			}
		} catch (Exception objExcep) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExcep.getMessage() + '  ' + objExcep.getStackTraceString()));
		}
	}
	/*
	 * Fetch Attachments for Email Macros
	 */
	public static List<Attachment> getMacroAttachments(Set<Id> set_MacroIds) {
		List<Attachment> list_Attachments = new List<Attachment>();
		if (set_MacroIds == null || set_MacroIds.isEmpty()) {
			return list_Attachments;
		}

		list_Attachments = [SELECT Id, Body, Name, ContentType FROM Attachment WHERE ParentId IN :set_MacroIds];

		return list_Attachments;
	}
	/*
	 *
	 */

	public static Map<String, Object> mergeDynamicContentInEmail(
		List<Carrier_Order__c> list_CO,
		Map<Id, Map<String, Email_Macro__c>> map_CarrierEmailMacros,
		String strRawBody,
		Map<Id, String> map_UserSignature,
		Case objCase,
		Map<String, Email_Macro__c> map_MacroWithoutCarrier,
		Map<String, Map<String, Email_Macro__c>> map_MacrosWithTAdA
	) {
		Map<String, Object> map_Results = new Map<String, Object>();
		String strMergedEmailBody = mergeCommonFieldsInTemplate(strRawBody, map_UserSignature, objCase);
		strMergedEmailBody = mergeSurveyURL(strMergedEmailBody, objCase);

		String strCarrierSpecificEmailContents = '', strCarrierSwitchInfo = '';
		String strCarrierSwitchCarrierNames = '', strTerminatedCarrierNames = '';
		Boolean blnNonAlegeusMacroIncluded = false;
		Map<String, String> map_BenefitsTypeVariations = new Map<String, String>{
			'HSA' => 'HSA',
			'Health Savings Account' => 'HSA',
			'Commuter' => 'Commuter',
			'Flexible Spending Account - Medical' => 'FSA',
			'FSA' => 'FSA',
			'Flexible Spending Account - Dependent Care' => 'DCA',
			'DCA' => 'DCA',
			'DCFSA' => 'DCA',
			'Dependent Care FSA' => 'DCA'
		};
		Messaging.EmailFileAttachment objAlegeusAttachment;

		Set<Id> set_IncludedEmailMacroIds = new Set<Id>();
		String strAlegeusCarrierMacroContents = '';
		for (Carrier_Order__c objCO : list_CO) {
			List<String> list_GroupNumbers = String.isnotBlank(objCO.Group_Number__c) ? objCO.Group_Number__c.split(',') : null;
			String strGrpNumber = list_GroupNumbers != null && list_GroupNumbers.size() > 0 ? list_GroupNumbers[list_GroupNumbers.size() - 1] : '';
			Set<String> set_BenefitTypes = new Set<String>();
			if (String.isNotBlank(objCO.Benefit_Types__c)) {
				for (String strBType : objCO.Benefit_Types__c.split(';')) {
					strBType = strBType.trim();
					if (map_BenefitsTypeVariations.containsKey(strBType)) {
						set_BenefitTypes.add(map_BenefitsTypeVariations.get(strBType));
					}
				}
			}
			if (String.isNotBlank(objCO.Order_Assignment__c) && objCO.Order_Assignment__c.containsIgnoreCase('Carrier switch')) {
				if (String.isNotBlank(strCarrierSwitchCarrierNames)) {
					strCarrierSwitchCarrierNames += ', ';
				}
				strCarrierSwitchCarrierNames += objCO.Carrier__r.Carrier_Unique_Name__c;
			}
			if (String.isNotBlank(objCO.Order_Assignment__c) && objCO.Order_Assignment__c.containsIgnoreCase('Terminated Order')) {
				if (String.isNotBlank(strTerminatedCarrierNames)) {
					strTerminatedCarrierNames += ', ';
				}
				strTerminatedCarrierNames += objCO.Carrier__r.Carrier_Unique_Name__c;
			}
			if (
				(String.isNotBlank(objCO.Order_Assignment__c) &&
				(objCO.Order_Assignment__c.containsIgnoreCase('New to Gusto') ||
				objCO.Order_Assignment__c.containsIgnoreCase('new line of coverage') ||
				objCO.Order_Assignment__c.containsIgnoreCase('Carrier switch'))) ||
				(String.isNotBlank(objCO.Carrier__c) &&
				set_TAdACarrierIds.contains(objCO.Carrier__c))
			) {
				if (map_CarrierEmailMacros.containsKey(objCO.Carrier__c) || set_TAdACarrierIds.contains(objCO.Carrier__c)) {
					if (
						!blnNonAlegeusMacroIncluded &&
						!set_TAdACarrierIds.contains(objCO.Carrier__c) &&
						map_MacroWithoutCarrier != null &&
						map_MacroWithoutCarrier.containsKey('Premium Payments')
					) {
						blnNonAlegeusMacroIncluded = true;
						strCarrierSpecificEmailContents += map_MacroWithoutCarrier.get('Premium Payments').Body__c;
					}

					Map<String, Email_Macro__c> map_EmailMacro = new Map<String, Email_Macro__c>();
					if (map_CarrierEmailMacros.containsKey(objCO.Carrier__c)) {
						map_EmailMacro = map_CarrierEmailMacros.get(objCO.Carrier__c);
					} else if (set_TAdACarrierIds.contains(objCO.Carrier__c) && map_MacrosWithTAdA.containsKey(strTAdA)) {
						map_EmailMacro = map_MacrosWithTAdA.get(strTAdA);
					}

					if (map_EmailMacro.size() > 1) {
						for (String strBenefitType : map_EmailMacro.keySet()) {
							if (strBenefitType != NONE && set_BenefitTypes.contains(strBenefitType)) {
								if (set_TAdACarrierIds.contains(objCO.Carrier__c)) {
									strAlegeusCarrierMacroContents += map_EmailMacro.get(strBenefitType).Body__c.replace('[GroupNumber]', strGrpNumber);
								} else {
									strCarrierSpecificEmailContents += map_EmailMacro.get(strBenefitType).Body__c.replace('[GroupNumber]', strGrpNumber);
								}
								set_IncludedEmailMacroIds.add(map_EmailMacro.get(strBenefitType).Id);
							}
						}
					}
					if (map_EmailMacro.containsKey(NONE)) {
						if (set_TAdACarrierIds.contains(objCO.Carrier__c)) {
							strAlegeusCarrierMacroContents += map_EmailMacro.get(NONE).Body__c.replace('[GroupNumber]', strGrpNumber);
						} else {
							strCarrierSpecificEmailContents += map_EmailMacro.get(NONE).Body__c.replace('[GroupNumber]', strGrpNumber);
						}
						set_IncludedEmailMacroIds.add(map_EmailMacro.get(NONE).Id);
					}
				}
			}
		}

		if (String.isNotBlank(strCarrierSwitchCarrierNames) && map_MacroWithoutCarrier != null && map_MacroWithoutCarrier.containsKey('Carrier Switch')) {
			strCarrierSwitchInfo = map_MacroWithoutCarrier.get('Carrier Switch').Body__c;

			strCarrierSwitchInfo = strCarrierSwitchInfo.replace('[CARRIER SWITCH CARRIERS]', strCarrierSwitchCarrierNames);
			if (String.isNotBlank(strTerminatedCarrierNames)) {
				strTerminatedCarrierNames = 'with ' + strTerminatedCarrierNames;
			}
			strCarrierSwitchInfo = strCarrierSwitchInfo.replace('[TERMINATED CARRIERS]', strTerminatedCarrierNames);
		}
		strMergedEmailBody = strMergedEmailBody.replace('[CarrierSpecificInfo]', strCarrierSpecificEmailContents + strAlegeusCarrierMacroContents);
		strMergedEmailBody = strMergedEmailBody.replace('[CarrierSwitchInfo]', strCarrierSwitchInfo);
		List<Attachment> list_MailAttachments = getMacroAttachments(set_IncludedEmailMacroIds);
		map_Results.put('EmailBody', strMergedEmailBody);
		map_Results.put('MacroAttachments', list_MailAttachments);
		return map_Results;
	}
	/*
	 * Fetch email macro records based on carriers
	 */
	public static Map<String, Object> segregateEmailMacros(List<Email_Macro__c> list_EmailMacro) {
		Map<String, Map<String, Email_Macro__c>> map_MacrosWithTAdA = new Map<String, Map<String, Email_Macro__c>>();
		Map<String, Email_Macro__c> map_MacrosWithoutCarrier = new Map<String, Email_Macro__c>();
		Map<Id, Map<String, Email_Macro__c>> map_CarrierEmailMacros = new Map<Id, Map<String, Email_Macro__c>>();
		Map<String, Object> map_Response = new Map<String, Object>();
		for (Email_Macro__c objMacro : list_EmailMacro) {
			if (String.isBlank(objMacro.Carrier__c)) {
				if (String.isNotBlank(objMacro.Benefit_Type__c)) {
					Map<String, Email_Macro__c> map_BenefitTypeMacro = new Map<String, Email_Macro__c>();
					if (map_MacrosWithTAdA.containsKey(strTAdA)) {
						map_BenefitTypeMacro = map_MacrosWithTAdA.get(strTAdA);
					}
					
					List<String> list_BenefitsTypes = objMacro.Benefit_Type__c.split(';');
					for (String strBenefitType : list_BenefitsTypes) {
						if (String.isNotBlank(strBenefitType) && !map_BenefitTypeMacro.containsKey(strBenefitType)) {
							map_BenefitTypeMacro.put(strBenefitType, objMacro);
						}
					}

					map_MacrosWithTAdA.put(strTAdA, map_BenefitTypeMacro);

				}
				
				if (String.isNotBlank(objMacro.Macro_Identifier__c)) {
					map_MacrosWithoutCarrier.put(objMacro.Macro_Identifier__c, objMacro);
				}
			} else {
				Map<String, Email_Macro__c> map_BenefitTypeMacro;
				if (map_CarrierEmailMacros.containsKey(objMacro.Carrier__c)) {
					map_BenefitTypeMacro = map_CarrierEmailMacros.get(objMacro.Carrier__c);
				} else {
					map_BenefitTypeMacro = new Map<String, Email_Macro__c>();
				}
				String strBenefitTypeArr = objMacro.Benefit_Type__c == null ? NONE : objMacro.Benefit_Type__c;
				List<String> list_BenefitsTypes = strBenefitTypeArr.split(';');

				for (String strBenefitType : list_BenefitsTypes) {
					if (String.isNotBlank(strBenefitType) && !map_BenefitTypeMacro.containsKey(strBenefitType)) {
						map_BenefitTypeMacro.put(strBenefitType, objMacro);
					}
				}

				map_CarrierEmailMacros.put(objMacro.Carrier__c, map_BenefitTypeMacro);
			}
		}
		map_Response.put('WithCarrier', map_CarrierEmailMacros);
		map_Response.put('WithoutCarrier', map_MacrosWithoutCarrier);
		map_Response.put('WithTAdA', map_MacrosWithTAdA);
		return map_Response;
	}
	/*
	 * Fetch email macro records based on carriers
	 */
	public static List<Email_Macro__c> fetchEmailMacros(Set<Id> set_CarrierIds) {
		List<Email_Macro__c> list_EmailMacro = new List<Email_Macro__c>();
		list_EmailMacro = [
			SELECT Carrier__c, Benefit_Type__c, Body__c, Macro_Identifier__c
			FROM Email_Macro__c
			WHERE (Carrier__c != NULL AND Carrier__c IN :set_CarrierIds) OR Macro_Identifier__c != NULL OR Benefit_Type__c != NULL
		];

		return list_EmailMacro;
	}
	/*
	 * Identify which email template to use based on BO and COs
	 */
	public static Map<Id, String> identifyOEFinalExtensionTemplate(String strDefaultEmailTemplateName, String strRenewalSameCarrierTemplateName, set<Id> set_BOId) {
		Map<Id, String> map_BOIdTemplateName = new Map<Id, String>();
		if (set_BOId == null || set_BOId.isEmpty()) {
			return map_BOIdTemplateName;
		}
		Set<String> set_OrderStatusToExclude = new Set<String>{ 'Canceled', 'Closed Admin' };
		for (Carrier_Order__c objCO : [
			SELECT Benefit_Order__r.RecordType.DeveloperName, Order_Assignment__c, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Order_Assignment__c != NULL
				AND Order_Type__c != 'Terminated Order'
				AND Implementation_Stage__c NOT IN :set_OrderStatusToExclude
				AND Carrier__c != NULL
				AND Carrier__c NOT IN :set_TAdACarrierIds
				AND Carrier__c != :idBasicCarrier
				AND Benefit_Order__c IN :set_BOId
		]) {
			if (objCO.Benefit_Order__r.RecordType.DeveloperName.equalsIgnoreCase('Renewal')) {
				if (objCO.Order_Assignment__c.containsIgnoreCase('Same Carrier')) {
					if (!map_BOIdTemplateName.containsKey(objCO.Benefit_Order__c)) {
						map_BOIdTemplateName.put(objCO.Benefit_Order__c, strRenewalSameCarrierTemplateName);
					}
				} else {
					map_BOIdTemplateName.put(objCO.Benefit_Order__c, strDefaultEmailTemplateName);
				}
			} else if (!map_BOIdTemplateName.containsKey(objCO.Benefit_Order__c)) {
				map_BOIdTemplateName.put(objCO.Benefit_Order__c, strDefaultEmailTemplateName);
			}
		}
		return map_BOIdTemplateName;
	}
	/*
	 * Check CO eligibility based on other Carrier Orders on that Benefit Order and the related Carrier
	 */

	public static void checkOEStatusForBenefitOrder(Map<Id, Id> map_COIdWithBOId) {
		if (map_COIdWithBOId == null) {
			return;
		}

		//fetch benefit orders
		Set<Id> set_BOId = new Set<Id>(map_COIdWithBOId.values());
		Map<Id, Integer> map_recentlyApprovedNonAlegeusCOPerBO = new Map<Id, Integer>();
		Map<Id, Integer> map_nonAlegeusCOPerBO = new Map<Id, Integer>(), map_nonAlegeusApprovedCOPerBO = new Map<Id, Integer>();
		Set<Id> set_BOForPartialApproval = new Set<Id>();
		Set<String> set_OrderStatusToExclude = new Set<String>{ 'Canceled', 'Closed Admin' };
		Map<Id, String> map_ApprovedCarrierNamesPerBO = new Map<Id, String>(), map_PendingApprovalCarrierNamesPerBO = new Map<Id, String>();

		Set<String> set_EligibleBORecordTypes = new Set<String>{ 'Change', 'New_Plan', 'Renewal' };
		for (Carrier_Order__c objCO : [
			SELECT Carrier__r.Name, Implementation_Stage__c, Benefit_Order__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__c IN :set_BOId
				AND Benefit_Order__r.Order_Status__c != 'Blocked'
				AND Order_Type__c != 'Terminated Order'
				AND Implementation_Stage__c NOT IN :set_OrderStatusToExclude
				AND Benefit_Order__r.Is_Multi_EIN__c = FALSE
				AND Benefit_Order__r.Parent_Benefit_Order__c = NULL
				AND Carrier__c != NULL
				AND Carrier__c NOT IN :set_TAdACarrierIds
				AND Carrier__c != :idBasicCarrier
				AND Benefit_Order__r.RecordType.DeveloperName IN :set_EligibleBOREcordTypes
		]) {
			if (map_COIdWithBOId.containsKey(objCO.Id)) {
				Integer intApprovedCOCount = map_recentlyApprovedNonAlegeusCOPerBO.containsKey(objCO.Benefit_Order__c) ? map_recentlyApprovedNonAlegeusCOPerBO.get(objCO.Benefit_Order__c) : 0;
				intApprovedCOCount++;

				String strApprovedCarrierNames = map_ApprovedCarrierNamesPerBO.containsKey(objCO.Benefit_Order__c) ? map_ApprovedCarrierNamesPerBO.get(objCO.Benefit_Order__c) + ' ,' : '';
				strApprovedCarrierNames += objCO.Carrier__r.Name;
				map_ApprovedCarrierNamesPerBO.put(objCO.Benefit_Order__c, strApprovedCarrierNames);

				map_recentlyApprovedNonAlegeusCOPerBO.put(objCO.Benefit_Order__c, intApprovedCOCount);
			} else if (objCO.Implementation_Stage__c == 'Approved' || objCO.Implementation_Stage__c == 'Approved Pending EE Audit') {
				Integer intExistingApprovedCOCount = map_nonAlegeusApprovedCOPerBO.containsKey(objCO.Benefit_Order__c) ? map_nonAlegeusApprovedCOPerBO.get(objCO.Benefit_Order__c) : 0;
				intExistingApprovedCOCount++;

				map_nonAlegeusApprovedCOPerBO.put(objCO.Benefit_Order__c, intExistingApprovedCOCount);
			} else {
				String strPendingApprovalCarrierNames = map_PendingApprovalCarrierNamesPerBO.containsKey(objCO.Benefit_Order__c)
					? map_PendingApprovalCarrierNamesPerBO.get(objCO.Benefit_Order__c) + ', '
					: '';
				strPendingApprovalCarrierNames += objCO.Carrier__r.Name;
				map_PendingApprovalCarrierNamesPerBO.put(objCO.Benefit_Order__c, strPendingApprovalCarrierNames);
			}
			Integer intNonAlegeusCOCount = map_nonAlegeusCOPerBO.containsKey(objCO.Benefit_Order__c) ? map_nonAlegeusCOPerBO.get(objCO.Benefit_Order__c) : 0;
			intNonAlegeusCOCount++;

			map_nonAlegeusCOPerBO.put(objCO.Benefit_Order__c, intNonAlegeusCOCount);
		}
		if (!map_recentlyApprovedNonAlegeusCOPerBO.isEmpty()) {
			for (Id idBO : map_recentlyApprovedNonAlegeusCOPerBO.keySet()) {
				if (map_nonAlegeusCOPerBO.containsKey(idBO)) {
					if (map_recentlyApprovedNonAlegeusCOPerBO.get(idBO) < map_nonAlegeusCOPerBO.get(idBO) && !map_nonAlegeusApprovedCOPerBO.containsKey(idBO)) {
						//partialApproval
						set_BOForPartialApproval.add(idBO);
					}
				}
			}
		}
		if (!set_BOForPartialApproval.isEmpty()) {
			sendPartialApprovalEmail(set_BOForPartialApproval, map_PendingApprovalCarrierNamesPerBO, map_ApprovedCarrierNamesPerBO);
		}
	}
	/*
	 * Org wide addresses based on BO record type
	 */
	public static Map<String, OrgWideEmailAddress> getOrgWideAddresses(Set<String> set_FromEmailAddr) {
		if (map_orgWideAddress != null && !map_orgWideAddress.isEmpty()) {
			return map_orgWideAddress;
		}
		map_orgWideAddress = new Map<String, OrgWideEmailAddress>();
		if (set_FromEmailAddr == null || set_FromEmailAddr.isEmpty()) {
			return map_orgWideAddress;
		}
		for (OrgWideEmailAddress objAddr : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :set_FromEmailAddr]) {
			if (objAddr.Address.containsIgnoreCase('Renewal')) {
				map_orgWideAddress.put('Renewal', objAddr);
				map_orgWideAddress.put('Change', objAddr);
			} else if (objAddr.Address.containsIgnoreCase('Newplans')) {
				map_orgWideAddress.put('New_Plan', objAddr);
				map_orgWideAddress.put('Benefits_BYOB', objAddr);
			}
		}

		return map_orgWideAddress;
	}
	/*
	 * Send Partial Approval Emails
	 */
	public static void sendPartialApprovalEmail(Set<Id> set_BOId, Map<Id, String> map_PendingApprovalCarrierNamesPerBO, Map<Id, String> map_ApprovedCarrierNamesPerBO) {
		Id idCaseBeingProcessed;
		try {
			if (set_BOId == null || set_BOId.isEmpty()) {
				return;
			}
			String strEmailTemplateName = 'Partial_Approval_Email';
			EmailTemplate objEmailTemplate = [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName LIMIT 1];

			List<Case> list_CustomerCases = new List<Case>();
			Set<String> set_ValidBORecordTypes = new Set<String>{ 'Renewal', 'New_Plan', 'Change' };
			list_CustomerCases = [
				SELECT
					Opportunity__c,
					Opportunity__r.RecordType.DeveloperName,
					Benefit_Order__r.RecordType.DeveloperName,
					Integration_Id__c,
					Case_Reference__c,
					ContactId,
					Contact.Name,
					Contact.FirstName,
					Benefit_Order__c,
					Benefit_Order__r.Final_Extension_Date__c,
					Benefit_Order__r.Owner.Name,
					Benefit_Order__r.OwnerId,
					Benefit_Order__r.Coverage_Effective_Date__c,
					AccountId,
					Account.Name
				FROM Case
				WHERE
					Benefit_Order__r.RecordType.DeveloperName IN :set_ValidBORecordTypes
					AND Integration_Id__c != NULL
					AND Benefit_Order__c != NULL
					AND Benefit_Order__c IN :set_BOId
					AND Carrier_Order__c = NULL
					AND ContactId != NULL
					AND AccountId != NULL
			];

			if (list_CustomerCases == null || list_CustomerCases.isEmpty() || objEmailTemplate == null) {
				return;
			}

			Map<String, OrgWideEmailAddress> map_orgWideAddress = getOrgWideAddresses(new Set<String>{ 'newplans@gusto.com', 'renewals@gusto.com' });

			Set<Id> set_BOOwners = new Set<Id>(), set_CaseId = new Set<Id>();
			for (Case objCase : list_CustomerCases) {
				if (String.valueOf(objCase.Benefit_Order__r.OwnerId).startsWith('005')) {
					set_BOOwners.add(objCase.Benefit_Order__r.OwnerId);
				}
				set_CaseId.add(objCase.Id);
			}

			if (set_CaseId != null && set_CaseId.size() > 0) {
				OEEmailAutomationHelper.fetchCaseTeamMember(set_CaseId);
			}

			Map<Id, String> map_UserSignature = fetchUserSignature(set_BOOwners);

			List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
			Map<Id, Integer> map_ExistingEmailCount = fetchSentEmailCountForCases(set_CaseId, new Set<String>{ strEmailTemplateName });
			List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();
			for (Case objCase : list_CustomerCases) {
				idCaseBeingProcessed = objCase.Id;
				String strIntegrationKey = 'hippo-' + objCase.Opportunity__r.RecordType.DeveloperName + '-' + objCase.Opportunity__c;
				if (objCase.Integration_Id__c == strIntegrationKey && (map_ExistingEmailCount == null || !map_ExistingEmailCount.containsKey(objCase.Id))) {
					String strBody = OEEmailAutomationHelper.mergeCommonFieldsInTemplate(objEmailTemplate.HTMLValue, map_UserSignature, objCase);

					if (map_PendingApprovalCarrierNamesPerBO != null && map_PendingApprovalCarrierNamesPerBO.containsKey(objCase.Benefit_Order__c)) {
						strBody = strBody.replace('[CARRIER NAME PENDING APPROVAL]', map_PendingApprovalCarrierNamesPerBO.get(objCase.Benefit_Order__c));
					}
					if (map_ApprovedCarrierNamesPerBO != null && map_ApprovedCarrierNamesPerBO.containsKey(objCase.Benefit_Order__c)) {
						strBody = strBody.replace('[APPROVED CARRIER NAME]', map_ApprovedCarrierNamesPerBO.get(objCase.Benefit_Order__c));
					}

					Messaging.SingleEmailMessage objMail = OEEmailAutomationHelper.createEmailRecord(objEmailTemplate.Subject, objCase, strBody);
					EmailMessage objMsg = OEEmailAutomationHelper.createEmailMessageRecord(strBody, objCase, objEmailTemplate.Subject, objEmailTemplate.DeveloperName);
					if (map_orgWideAddress != null && map_orgWideAddress.containsKey(objCase.Benefit_Order__r.RecordType.DeveloperName)) {
						objMsg.fromAddress = map_orgWideAddress.get(objCase.Benefit_Order__r.RecordType.DeveloperName).Address;
						objMail.setOrgWideEmailAddressId(map_orgWideAddress.get(objCase.Benefit_Order__r.RecordType.DeveloperName).Id);
					}

					list_Emails.add(objMail);

					list_EmailMessage.add(objMsg);

					Integer intEmailCount = map_ExistingEmailCount.containsKey(objCase.Id) ? map_ExistingEmailCount.get(objCase.Id) : 0;
					map_ExistingEmailCount.put(objCase.Id, intEmailCount + 1);
				}
			}

			if (list_Emails.size() > 0) {
				Messaging.SendEmailResult[] results = Messaging.sendEmail(list_Emails);

				if (results[0].success) {
					insert list_EmailMessage;
				}
			}
		} catch (Exception objExcep) {
			if (!objExcep.getMessage().contains(Utils.BOUNCE_EMAIL_ERROR)) {
				ExceptionLogUtil.logException(
					'OEEmailAutomationHelper',
					'sendPartialApprovalEmail for Case(' +
					idCaseBeingProcessed +
					')',
					objExcep.getMessage() +
					'  ' +
					objExcep.getStackTraceString(),
					'high'
				);
			}
		}
	}
	/*
	 * User signature for the Benefit Order Owners
	 */
	public static Map<Id, String> fetchUserSignature(Set<Id> set_UserIds) {
		Map<Id, String> map_UserSignature = new Map<Id, String>();
		if (set_UserIds == null || set_UserIds.isEmpty()) {
			return map_UserSignature;
		}

		for (User objUser : [SELECT Signature FROM User WHERE Id IN :set_UserIds AND Signature != NULL]) {
			String strSignature = '';
			if (String.isNotBlank(objUser.Signature)) {
				strSignature = objUser.Signature.replace('\n', '<br/>');
			}
			map_UserSignature.put(objUser.Id, strSignature);
		}

		return map_UserSignature;
	}
	/*
	 * To check if any emails were already sent for a particular Email Template on a particular case
	 */
	public static Map<Id, Integer> fetchSentEmailCountForCases(Set<Id> set_CaseId, Set<String> set_TemplateName) {
		Map<Id, Integer> map_SentEmailForCases = new Map<Id, Integer>();
		if (set_TemplateName == null || set_TemplateName.isEmpty() || set_CaseId == null || set_CaseId.isEmpty()) {
			return map_SentEmailForCases;
		}
		for (EmailMessage objEmailMsg : [
			SELECT Id, RelatedToId
			FROM EmailMessage
			WHERE Email_Template_Name__c IN :set_TemplateName AND Status = '3' AND RelatedToId != NULL AND RelatedToId IN :set_CaseId
		]) {
			Integer intEmailCount = 0;
			if (map_SentEmailForCases.containsKey(objEmailMsg.RelatedToId)) {
				intEmailCount = map_SentEmailForCases.get(objEmailMsg.RelatedToId);
			}
			intEmailCount++;

			map_SentEmailForCases.put(objEmailMsg.RelatedToId, intEmailCount);
		}

		return map_SentEmailForCases;
	}
	/*
	 * Creates e-Mail record
	 */
	public static Messaging.SingleEmailMessage createEmailRecord(String strSubject, Case objCase, String strBody) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}
		Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
		objMail.setSubject(strSubject);
		objMail.setHTMLBody(strBody);
		objMail.setTargetObjectId(objCase.ContactId);
		objMail.setSaveAsActivity(false);
		objMail.setWhatId(objCase.Id);
		objMail.setUseSignature(false);

		Map<Id, Set<String>> map_OppToCCEmails = OEEmailAutomationHelper.map_CaseTeamMemberEmails;
		if (objCase != null && objCase.Id != null && map_OppToCCEmails != null && map_OppToCCEmails.containsKey(objCase.Id)) {
			Set<String> set_CCEmails = map_OppToCCEmails.get(objCase.Id);

			if (set_CCEmails.size() > 0) {
				objMail.setCcAddresses(new List<String>(set_CCEmails));
			}
		}

		return objMail;
	}
	/*
	 * Creates EmailMessage record
	 */
	public static EmailMessage createEmailMessageRecord(String strBody, Case objCase, String strSubject, String strEmailTemplateName) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}
		EmailMessage objMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
		objMsg.ToAddress = objCase.contactId;
		objMsg.Subject = strSubject;
		objMsg.HtmlBody = strBody;
		objMsg.ParentId = objCase.Id; //Attaching with the case
		objMsg.MessageDate = System.now();
		objMsg.Status = '3';
		objMsg.Email_Template_Name__c = strEmailTemplateName;

		Map<Id, Set<String>> map_OppToCCEmails = OEEmailAutomationHelper.map_CaseTeamMemberEmails;
		if (objCase != null && objCase.Id != null && map_OppToCCEmails != null && map_OppToCCEmails.containsKey(objCase.Id)) {
			Set<String> set_CCEmails = map_OppToCCEmails.get(objCase.Id);

			if (set_CCEmails.size() > 0) {
				objMsg.ccAddress = String.join(new List<String>(set_CCEmails), ';');
			}
		}

		return objMsg;
	}
	/*
	 * Merge the common values in email template body
	 */
	public static String mergeCommonFieldsInTemplate(String strRawBody, Map<Id, String> map_UserSignature, Case objCase) {
		String strSignature = (map_UserSignature != null && map_UserSignature.containsKey(objCase.Benefit_Order__r.OwnerId)) ? map_UserSignature.get(objCase.Benefit_Order__r.OwnerId) : '';

		strRawBody = objCase.Contact?.FirstName != null ? strRawBody.replace('[ER Name]', objCase.Contact.FirstName) : strRawBody.replace('[ER Name]', objCase.Contact.Name);
		strRawBody = strRawBody.replace('[Signature of OA]', strSignature);
		strRawBody += '<div style="color: transparent">' + objCase.Case_Reference__c + '</div>';

		return strRawBody;
	}

	public static String mergeSurveyURL(String strRawBody, Case objCase) {
		if (objCase.RecordTypeId != null) {
			if (objCase.RecordType.Name == BENEFITS_NEW_PLAN_CASE_RT_ID || objCase.RecordType.Name == BENEFITS_CHANGE_CASE_RT_ID) {
				strRawBody = strRawBody.replace('[survey]', objCase.NP_Survey_URL__c);
			}

			if (objCase.RecordType.Name == BENEFITS_RENEWAL_CASE_RT_ID) {
				strRawBody = strRawBody.replace('[survey]', objCase.Renewal_Survey_URL__c);
			}
		}

		return strRawBody;
	}

	//Fetch fetchCaseTeamMember
	public static Map<Id, Set<String>> fetchCaseTeamMember(Set<Id> set_CaseId) {
		map_CaseTeamMemberEmails = new Map<Id, Set<String>>();
		Map<Id, Set<Id>> map_CaseToContactIds = new Map<Id, Set<Id>>();
		Set<Id> set_RelatedContactIds = new Set<Id>();
		Set<Id> set_RelatedUserIds = new Set<Id>();
		String strObjId = '';

		for (CaseTeamMember objCaseTeam : [SELECT Id, ParentId, MemberId FROM CaseTeamMember WHERE ParentId != NULL AND MemberId != NULL AND ParentId IN :set_CaseId]) {
			strObjId = objCaseTeam.MemberId;
			if (String.isNotBlank(strObjId) && strObjId.subString(0, 3) == CONTACT_ID_PREFIX) {
				set_RelatedContactIds.add(objCaseTeam.MemberId);
			} else {
				set_RelatedUserIds.add(objCaseTeam.MemberId);
			}

			//Create Map of Opp and ContactRole Email
			Set<Id> set_ContactIds = new Set<Id>();
			if (map_CaseToContactIds.containsKey(objCaseTeam.ParentId)) {
				set_ContactIds = map_CaseToContactIds.get(objCaseTeam.ParentId);
			}

			set_ContactIds.add(objCaseTeam.MemberId);
			map_CaseToContactIds.put(objCaseTeam.ParentId, set_ContactIds);
		}

		//If case team member is a contact record then run soql query on contact object and get email address.
		Map<Id, Contact> map_ContactIdToEmails = new Map<Id, Contact>();
		if (set_RelatedContactIds.size() > 0) {
			map_ContactIdToEmails = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Email != NULL AND Id IN :set_RelatedContactIds]);
		}

		//If case team member is a user record then run soql query on user object and get email address.
		Map<Id, User> map_UserIdToEmails = new Map<Id, User>();
		if (set_RelatedUserIds.size() > 0) {
			map_UserIdToEmails = new Map<Id, User>([SELECT Id, Email FROM User WHERE Email != NULL AND Id IN :set_RelatedUserIds]);
		}

		if (map_CaseToContactIds != null && map_CaseToContactIds.size() > 0) {
			for (Id idCase : map_CaseToContactIds.keySet()) {
				Set<String> set_Emails = new Set<String>();

				for (Id idSObj : map_CaseToContactIds.get(idCase)) {
					//Get CC email address either from map_ContactIdToEmail or from map_UserIdToEmail Map.
					if (map_ContactIdToEmails != null && map_ContactIdToEmails.containsKey(idSObj)) {
						set_Emails.add(map_ContactIdToEmails.get(idSObj).Email);
					} else if (map_UserIdToEmails != null && map_UserIdToEmails.containsKey(idSObj)) {
						set_Emails.add(map_UserIdToEmails.get(idSObj).Email);
					}
				}

				map_CaseTeamMemberEmails.put(idCase, set_Emails);
			}
		}

		return map_CaseTeamMemberEmails;
	}

	public static void updateChildBenefitOrderStatus(Id idBO) {
		List<Benefit_Order__c> lstChidBenefitOrder = new List<Benefit_Order__c>();
		for (Benefit_Order__c bo : [SELECT id, name FROM Benefit_Order__c WHERE Parent_Benefit_Order__c = :idBO]) {
			bo.Order_Status__c = FULFILLED;
			lstChidBenefitOrder.add(bo);
		}
		if (!lstChidBenefitOrder.isEmpty()) {
			update lstChidBenefitOrder;
		}
	}
}