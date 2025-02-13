/*
 * Description: Contains methods to set case team for email
 * Author: Omar Benitez
 * Date: 04/22/2024
 */
public without sharing class CaseEmailTeamController {
	public static final String BENEFIT_ORDER_NEW_PLAN_RT_NAME = 'New Plan';
	public static final String BENEFIT_ORDER_RENEWAL_RT_NAME = 'Renewal';
	public static final String BENEFIT_ORDER_CHANGE_RT_NAME = 'Change';
	public static final String BENEFIT_ORDER_BOR_RT_NAME = 'Benefits BoR';
	public static final String BOR_TRANSFER = 'BoR Transfer';
	public static final String BR = '<br>';
	public static final String DRAFT_STATUS = '5';
	public static final String EMAIL_MEMBER_FUL = 'memberfulfillment@gusto.com';
	public static Boolean blnUpdateFrom = false;

	/* Method will return all the related contact and user ids related with the case and case team members */
	@AuraEnabled(cacheable=true)
	public static List<Id> getCaseTeamMemberIds(Id idCase) {
		Set<Id> set_CaseTeamMemberIds = new Set<Id>();
		List<CaseTeamMember> list_CaseTeamMembers = [SELECT Id, MemberId, Parent.ContactId FROM CaseTeamMember WHERE parentId = :idCase];
		if (!list_CaseTeamMembers.isEmpty()) {
			set_CaseTeamMemberIds.add(list_CaseTeamMembers[0].Parent.ContactId);
			for (CaseTeamMember ctm : list_CaseTeamMembers) {
				set_CaseTeamMemberIds.add(ctm.MemberId);
			}
		}
		//In case the set is empty we need at least add the contact related with the account
		if (set_CaseTeamMemberIds.isEmpty()) {
			Case objCase = [SELECT Id, ContactId FROM Case WHERE Id = :idCase];
			if (objCase.ContactId != null) {
				set_CaseTeamMemberIds.add(objCase.ContactId);
			}
		}
		return new List<Id>(set_CaseTeamMemberIds);
	}

	/**
	 * @description getCurrentUserSignature
	 * @author Nigam Goyal | 06-05-2024
	 * @return String
	 **/
	@AuraEnabled(cacheable=true)
	public static String getCurrentUserSignature() {
		User currentUser = [SELECT Signature FROM User WHERE Id = :UserInfo.getUserId()];
		return currentUser.Signature;
	}

	/* Method will return all the related carriers from the case */
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getCarrierOptions(Id idCase) {
		Map<String, Object> map_Response = new Map<String, Object>();
		Map<String, String> map_Carriers = new Map<String, String>();
		String strFromEmail = '';
		Case objCase = [SELECT Id, Opportunity__c, Benefit_Order__c, RecordType.Name, Carrier_Order__r.Carrier__c FROM Case WHERE Id = :idCase];
		if (objCase.RecordType.Name.indexOf(BENEFIT_ORDER_RENEWAL_RT_NAME) > -1 || objCase.RecordType.Name.indexOf(BENEFIT_ORDER_CHANGE_RT_NAME) > -1) {
			strFromEmail = Label.RenewalCaseCarrierEmail;
		} else if (objCase.RecordType.Name.indexOf(BENEFIT_ORDER_NEW_PLAN_RT_NAME) > -1) {
			strFromEmail = Label.NewPlanCaseCarrierEmail;
		} else if (objCase.RecordType.Name.indexOf(BENEFIT_ORDER_BOR_RT_NAME) > -1) {
			strFromEmail = Label.BORTransferCaseCarrierEmail;
		}
		map_Response.put('fromEmail', strFromEmail);
		map_Response.put('carrierId', objCase.Carrier_Order__r.Carrier__c);
		return map_Response;
	}

	/* Method will return all the related email options from the carrier */
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getEmailOptions(String strCarrierId) {
		Map<String, String> map_EmailOptions = new Map<String, String>();
		if (strCarrierId != null && strCarrierId != '') {
			Carrier__c objCarrier = [SELECT Id, Renewal_Email_List__c, New_Plan_Email_List__c, BOR_Transfer_Email_List__c FROM Carrier__c WHERE id = :strCarrierId];
			if (objCarrier.Renewal_Email_List__c != null && objCarrier.Renewal_Email_List__c != '') {
				for (String emailInfo : objCarrier.Renewal_Email_List__c.split('\n')) {
					if (emailInfo.indexOf('::') > -1) {
						map_EmailOptions.put(emailInfo.split('::')[1].trim(), BENEFIT_ORDER_RENEWAL_RT_NAME + ' - ' + emailInfo.split('::')[0]);
					}
				}
			}
			if (objCarrier.New_Plan_Email_List__c != null && objCarrier.New_Plan_Email_List__c != '') {
				for (String emailInfo : objCarrier.New_Plan_Email_List__c.split('\n')) {
					if (emailInfo.indexOf('::') > -1) {
						map_EmailOptions.put(emailInfo.split('::')[1].trim(), BENEFIT_ORDER_NEW_PLAN_RT_NAME + ' - ' + emailInfo.split('::')[0]);
					}
				}
			}
			if (objCarrier.BOR_Transfer_Email_List__c != null && objCarrier.BOR_Transfer_Email_List__c != '') {
				for (String emailInfo : objCarrier.BOR_Transfer_Email_List__c.split('\n')) {
					if (emailInfo.indexOf('::') > -1) {
						map_EmailOptions.put(emailInfo.split('::')[1].trim(), BOR_TRANSFER + ' - ' + emailInfo.split('::')[0]);
					}
				}
			}
		}
		return map_EmailOptions;
	}

	/* Method will update the email message draft adding the proper signature, adding proper to and from addresses */
	@AuraEnabled
	public static void updateDraft(String strCarrierId, String strToAddress, String strFrom) {
		List<EmailMessage> list_drafts = [
			SELECT Id, FromAddress, ToAddress, IsPrivateDraft, Status, HtmlBody
			FROM EmailMessage
			WHERE RelatedToId = :strCarrierId AND IsPrivateDraft = TRUE
			ORDER BY CreatedDate DESC
		];
		EmailMessage objEmailMsg = new EmailMessage();
		objEmailMsg.RelatedToId = strCarrierId;
		objEmailMsg.FromAddress = strFrom;
		objEmailMsg.ToAddress = strToAddress;
		objEmailMsg.IsPrivateDraft = true;
		objEmailMsg.Status = DRAFT_STATUS;
		if (list_drafts.isEmpty()) {
			User objUser = [SELECT Id, Signature FROM User WHERE Id = :userinfo.getuserId()];
			String strUserSignature = (objUser.Signature != null) ? objUser.Signature : '';
			if (String.isNotBlank(strUserSignature)) {
				strUserSignature = strUserSignature.replace('\n', BR);
			}
			objEmailMsg.HtmlBody = BR + BR + strUserSignature;
		} else {
			objEmailMsg.HtmlBody = list_drafts[0].HtmlBody;
		}
		delete list_drafts;
		insert objEmailMsg;
	}

	/* Method will update the email message draft adding the proper signature, adding proper to address */
	@AuraEnabled
	public static void createEmailCarrier(String strCaseId) {
		Case objCase = [SELECT Id, Carrier__r.Submission_Email__c, BYOB_Customer__c FROM Case WHERE Id = :strCaseId];
		updateDraft(strCaseId, objCase.Carrier__r.Submission_Email__c, EMAIL_MEMBER_FUL);
	}

	/* Method will update the email message draft adding the proper signature, adding proper to address for customer*/
	@AuraEnabled
	public static void createEmailCustomer(String strCaseId) {
		Case objCase = [SELECT ContactId, BYOB_Customer__c FROM Case WHERE Id = :strCaseId];
		updateDraft(strCaseId, objCase.ContactId, EMAIL_MEMBER_FUL);
	}

}