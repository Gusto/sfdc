/**
 * @name         QLERFIAutomateEmailUtils
 * @test class   QLERFIAutomateEmailTest
 * @author       Bhagat Singh
 * @date         22th April 2021
 * @description  QLE RFI Automate Email scheduler utill class.
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class QLERFIAutomateEmailUtils {
	public static Map<String, String> map_QLEEmailMacros = new Map<String, String>();
	public static Map<String, EmailTemplate> map_EmailTemplates = new Map<String, EmailTemplate>();
	public static Set<String> set_EmailTemplateNames = new Set<String>();
	public static final String PREFIX_EMAIL_MACRO = 'QLE-RFI-';
	public static final String SUFFIX_EM_PROOF = '-PROOF';
	public static final String SUFFIX_EM_VERBIAGE = '-VERBIAGE';
	//Email Template Name
	public static final String QLE_RFI_FIRST_EMAIL = 'QLE_RFI_First_Automated_Email';
	public static final String QLE_RFI_SECOND_EMAIL = 'QLE_RFI_Second_Automated_Email';
	public static final String QLE_RFI_THIRD_EMAIL = 'QLE_RFI_Third_Automated_Email';
	public static final String QLE_RFI_FOURTH_EMAIL = 'QLE_RFI_Fourth_Automated_Email';
	public static final String FOLLOW_UP_EMAIL_1 = 'Follow_up_email_11';
	public static final String FOLLOW_UP_EMAIL_2 = 'Follow_up_email_21';
	//Email Macro
	public static final String EM_NAME = '[INSERT EE NAME]';
	public static final String EM_REASON = '[INSERT REASON]';
	public static final String EM_DATE_RFI = '[DATE AUTO FILLED FROM RFI 1]';
	public static final String EM_EVENT_TYPE = '[INSERT PROOF BASED ON QLE EVENT TYPE]';
	public static final String EM_VERBIAGE = '[INSERT QLE EVENT TYPE VERBIAGE IF APPLICABLE]';
	//Status
	public static final String STATUS_RFI_1 = 'RFI 1';
	public static final String STATUS_RFI_2 = 'RFI 2';
	public static final String STATUS_RFI_3 = 'RFI 3';
	public static final String STATUS_RFI_VIOLATED = 'RFI Violated';
	public static final String STATUS_PENDING = 'Pending';
	public static final String FROM_EMAIL_MF = 'memberfulfillment@gusto.com';
	public static final String FROM_EMAIL_RENEWAL = 'renewals@gusto.com';
	public static final String CASE_REFERENCE = '[CASE REFERENCE]';
	public static Id idOrgWideEmailAddress = null;
	public static Id idRenewalOrgWideEmailAddress = null;
	public static Set<String> set_FollowUpEmailTemplateNames = new Set<String>{ FOLLOW_UP_EMAIL_1, FOLLOW_UP_EMAIL_2 };
	public static Set<String> set_Roles = new Set<String>{ 'Primary Payroll Admin', 'Benefits Admin', 'Benefits Signatory', 'Signatory' };

	static {
		String strMacroPrefix = PREFIX_EMAIL_MACRO + '%';
		set_EmailTemplateNames.add(QLE_RFI_FIRST_EMAIL);
		set_EmailTemplateNames.add(QLE_RFI_SECOND_EMAIL);
		set_EmailTemplateNames.add(QLE_RFI_THIRD_EMAIL);
		set_EmailTemplateNames.add(QLE_RFI_FOURTH_EMAIL);

		for (EmailTemplate objEmailTemplate : [
			SELECT Subject, DeveloperName, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName != NULL AND (DeveloperName IN :set_EmailTemplateNames OR DeveloperName IN :set_FollowUpEmailTemplateNames)
		]) {
			if (objEmailTemplate.DeveloperName == QLE_RFI_FIRST_EMAIL) {
				map_EmailTemplates.put('RFI-1', objEmailTemplate);
			} else if (objEmailTemplate.DeveloperName == QLE_RFI_SECOND_EMAIL) {
				map_EmailTemplates.put('RFI-2', objEmailTemplate);
			} else if (objEmailTemplate.DeveloperName == QLE_RFI_THIRD_EMAIL) {
				map_EmailTemplates.put('RFI-3', objEmailTemplate);
			} else if (objEmailTemplate.DeveloperName == QLE_RFI_FOURTH_EMAIL) {
				map_EmailTemplates.put('RFI-4', objEmailTemplate);
			} else if (objEmailTemplate.DeveloperName == FOLLOW_UP_EMAIL_1) {
				map_EmailTemplates.put('RECERT-2', objEmailTemplate);
			} else if (objEmailTemplate.DeveloperName == FOLLOW_UP_EMAIL_2) {
				map_EmailTemplates.put('RECERT-3', objEmailTemplate);
			}
		}

		for (Email_Macro__c objMacro : [
			SELECT Macro_Identifier__c, Body__c
			FROM Email_Macro__c
			WHERE Carrier__c = NULL AND Benefit_Type__c = NULL AND Macro_Identifier__c != NULL AND Macro_Identifier__c LIKE :strMacroPrefix
		]) {
			map_QLEEmailMacros.put(objMacro.Macro_Identifier__c, objMacro.Body__c);
		}

		Set<String> set_OrgWideEmailAddress = new Set<String>{ FROM_EMAIL_MF, FROM_EMAIL_RENEWAL };
		List<OrgWideEmailAddress> list_OWDAddress = GlobalQueryHelper.QueryTogetOrgWideEmail(set_OrgWideEmailAddress);

		if (list_OWDAddress != null && list_OWDAddress.size() > 0) {
			for (OrgWideEmailAddress objOrgAddress : list_OWDAddress) {
				if (objOrgAddress.Address == FROM_EMAIL_MF) {
					idOrgWideEmailAddress = objOrgAddress.Id;
				} else if (objOrgAddress.Address == FROM_EMAIL_RENEWAL) {
					idRenewalOrgWideEmailAddress = objOrgAddress.Id;
				}
			}
		}
	}

	public static Messaging.SingleEmailMessage createEmailRecord(Case objCase, Integer intIndex, Map<Id, String> map_UserSignatures) {
		Messaging.SingleEmailMessage objMail = null;
		String strKey = '';
		Id idFromOrgWideEmailAddress = null;
		if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_QLE) {
			strKey = 'RFI-' + intIndex;
			idFromOrgWideEmailAddress = QLERFIAutomateEmailUtils.idOrgWideEmailAddress;
		} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_RENEWAL) {
			strKey = 'RECERT-' + intIndex;
			idFromOrgWideEmailAddress = QLERFIAutomateEmailUtils.idRenewalOrgWideEmailAddress;
		}

		if (map_EmailTemplates != null && map_EmailTemplates.containsKey(strKey)) {
			EmailTemplate objTemplate = map_EmailTemplates.get(strKey);
			String strEmailBody = objTemplate.HtmlValue;
			if (objCase != null && objCase.QLE_RFI_Type__c != null) {
				strEmailBody = QLERFIAutomateEmailUtils.processEmailBody(objCase, strEmailBody);
				String strSignature = (map_UserSignatures != null && map_UserSignatures.containsKey(objCase.OwnerId)) ? map_UserSignatures.get(objCase.OwnerId) : '';
				strEmailBody = strEmailBody + strSignature;
			}

			objMail = new Messaging.SingleEmailMessage();
			objMail.setSubject(objTemplate.Subject);
			objMail.setHTMLBody(strEmailBody);
			objMail.setTargetObjectId(objCase.ContactId);
			objMail.setSaveAsActivity(false);
			objMail.setWhatId(objCase.Id);
			objMail.setUseSignature(false);
			objMail.setTreatBodiesAsTemplate(true);
			objMail.setTreatTargetObjectAsRecipient(true);
			objMail.setOrgWideEmailAddressId(idFromOrgWideEmailAddress);
		}

		return objMail;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Creates EmailMessage record
	 * @Parm        : objMail - SingleEmailMessage record
	 * 				  objCase - Case record
	 * 				  strEmailTemplateName - Email Template Name
	 * @Return      : EmailMessage
	 **/
	public static EmailMessage createEmailMessageRecord(Messaging.SingleEmailMessage objMail, Case objCase, Integer intIndex) {
		EmailMessage objMsg = new EmailMessage();
		objMsg.ToAddress = objCase.contactId;
		objMsg.Subject = objMail.Subject;
		objMsg.HtmlBody = objMail.HtmlBody;
		objMsg.ParentId = objCase.Id; //Attaching with the case
		objMsg.MessageDate = System.now();
		objMsg.Status = '3';
		objMsg.ccAddress = objCase.ContactEmail;

		String strKey = '';
		if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_QLE) {
			strKey = 'RFI-' + intIndex;
			objMsg.FromAddress = FROM_EMAIL_MF;
			objMsg.FromName = FROM_EMAIL_MF;
		} else if (objCase.RecordTypeId == CaseUtils.RECTYPE_RENEWAL) {
			strKey = 'RECERT-' + intIndex;
			objMsg.FromAddress = FROM_EMAIL_RENEWAL;
			objMsg.FromName = FROM_EMAIL_RENEWAL;
		}

		if (map_EmailTemplates != null && map_EmailTemplates.containsKey(strKey)) {
			EmailTemplate objTemplate = map_EmailTemplates.get(strKey);
			objMsg.Email_Template_Name__c = objTemplate.DeveloperName;
		}

		return objMsg;
	}

	public static String processEmailBody(Case objCase, String strEmailBody) {
		if (String.isNotBlank(strEmailBody) && String.isNotBlank(objCase.QLE_RFI_Type__c)) {
			if (objCase.ContactId != null) {
				strEmailBody = strEmailBody.replace(EM_NAME, objCase.Contact.FirstName);
			}

			strEmailBody = strEmailBody.replace(EM_REASON, objCase.Insufficient_Proof_Reason__c);

			if (objCase.RFI_9th_Business_Day__c != null) {
				strEmailBody = strEmailBody.replace(EM_DATE_RFI, objCase.RFI_9th_Business_Day__c.format());
			} else {
				strEmailBody = strEmailBody.replace(EM_DATE_RFI, '');
			}

			strEmailBody = strEmailBody.replace(CASE_REFERENCE, objCase.Case_Reference__c);

			String strKey = PREFIX_EMAIL_MACRO + objCase.QLE_RFI_Type__c + SUFFIX_EM_PROOF;
			if (map_QLEEmailMacros.containsKey(strKey) && strEmailBody.contains(EM_EVENT_TYPE)) {
				strEmailBody = strEmailBody.replace(EM_EVENT_TYPE, map_QLEEmailMacros.get(strKey));
			}

			strKey = PREFIX_EMAIL_MACRO + objCase.QLE_RFI_Type__c + SUFFIX_EM_VERBIAGE;
			if (map_QLEEmailMacros.containsKey(strKey) && strEmailBody.contains(EM_VERBIAGE)) {
				strEmailBody = strEmailBody.replace(EM_VERBIAGE, map_QLEEmailMacros.get(strKey));
			} else {
				strEmailBody = strEmailBody.replace(EM_VERBIAGE + '.', '');
			}
		}

		return strEmailBody;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Get Emails reletaed to Opportunity Contact Roles.
	 * @Parm        : Set of OpportunityIds
	 * @Return      : Map of OpportunityId with List of Email Ids.
	 **/
	public static Map<Id, List<String>> getOpportunityContactRolesEmail(Set<Id> set_OpportunityIds) {
		Map<Id, List<String>> map_OppIdWithToEmails = new Map<Id, List<String>>();
		List<String> list_Emails = new List<String>();
		for (OpportunityContactRole objRole : [SELECT Id, Contact.Email, OpportunityId FROM OpportunityContactRole WHERE OpportunityId IN :set_OpportunityIds AND Role IN :set_Roles]) {
			list_Emails = new List<String>();
			if (map_OppIdWithToEmails.containsKey(objRole.OpportunityId)) {
				list_Emails = map_OppIdWithToEmails.get(objRole.OpportunityId);
			}

			list_Emails.add(objRole.Contact.Email);
			map_OppIdWithToEmails.put(objRole.OpportunityId, list_Emails);
		}

		return map_OppIdWithToEmails;
	}
}