/**
 * @name         TaxResAutoSolveEmailHelper
 * @author       Shyam Nasare
 * @date         08/17/2023
 * @description
 **/
public with sharing class TaxResAutoSolveEmailHelper {
	public static final String STR_AUTO_GENERIC_EMAIL_CUSTOM_TEMPLATE = 'Auto_Generic_Email_Custom_Template';

	/**
	 * @author        Shyam Nasare
	 * @description   Send the email alerts with attachments
	 * @param         instance of Case
	 * @return 		  NA
	 * Last Modified  Oct 10, 2023
	 * Reason		  Using the same code to send TIFR email for an "Electronic Notice" case
	 */
	@InvocableMethod(label='Send Auto Solve Email2' description='send auto solve email alerts to the customer')
	public static void sendAutoSolveEmail(List<Case> list_Cases) {
		Map<Id, Case> map_CaseIdToCase = new Map<Id, Case>();
		Map<Id, Set<Id>> map_ParentToContenDocumentIds = new Map<Id, Set<Id>>();
		Set<Id> set_ContentDocumentIds = new Set<Id>();
		Set<Id> set_AutoSolveFailedCaseIds = new Set<Id>();
		Map<Id, Id> map_ContDocIdToContentVersionIds = new Map<Id, Id>();
		Map<Id, ContentVersion> map_ContentVersions = new Map<Id, ContentVersion>();
		List<Case> list_CasesToUpdateWhenFailed = new List<Case>();
		List<Case> list_CasesToUpdateWhenSuccess = new List<Case>();
		List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();
		Map<Id, Id> map_CaseToEmailMessages = new Map<Id, Id>();
		Map<Id, List<String>> map_CaseToAttachments = new Map<Id, List<String>>();
		Map<Id, Attachment> map_CaseFBEDAttachment = new Map<Id, Attachment>();
		String strAutomationTriggred_TaxResResearchInProgress = 'Tax Res Research in progress Email';
		
		Map<Id, Id> map_EmailMessageIdToCaseId = new Map<Id, Id>();
		Map<Id, Set<Attachment>> map_CaseIdToAttachmentIdsFromEmailMsg = new Map<Id, Set<Attachment>>();
		Map<Id, Set<Attachment>> map_CaseIdToAttachmentIds = new Map<Id, Set<Attachment>>();

		Map<Id, Id> map_ContactIdToCaseId = new Map<Id, Id>();

		List<OrgWideEmailAddress> list_objOrgEmailAddressSupport = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');
		EmailTemplate objEmailTemplate = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = :STR_AUTO_GENERIC_EMAIL_CUSTOM_TEMPLATE];

		for (Case objCase : list_Cases) {
			map_CaseIdToCase.put(objCase.Id, objCase);
			if (objCase.ContactId != null) {
				map_ContactIdToCaseId.put(objCase.ContactId, objCase.Id);
			}
		}

		//getting Email Messages from which Cases are created
		for (EmailMessage objEmailMessage : [SELECT Id, ParentId, CreatedDate, Subject, Status FROM EmailMessage WHERE ParentId IN :map_CaseIdToCase.keySet() ORDER BY CreatedDate ASC]) {
			if ((objEmailMessage.CreatedDate).date() == (map_CaseIdToCase.get(objEmailMessage.ParentId).CreatedDate).date() &&
			objEmailMessage.Subject == map_CaseIdToCase.get(objEmailMessage.ParentId).Subject && objEmailMessage.Status == '1') {
				map_EmailMessageIdToCaseId.put(objEmailMessage.Id, objEmailMessage.ParentId);
			}
		}

		//fetching Attachments from first email messages
		if (!map_EmailMessageIdToCaseId.isEmpty()) {
			for (Attachment objAttachment : [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :map_EmailMessageIdToCaseId.keySet()]) {
				Set<Attachment> set_AttachmentIds = new Set<Attachment>();
				if (map_CaseIdToAttachmentIdsFromEmailMsg.get(map_EmailMessageIdToCaseId.get(objAttachment.ParentId)) != null) {
					set_AttachmentIds = map_CaseIdToAttachmentIdsFromEmailMsg.get(map_EmailMessageIdToCaseId.get(objAttachment.ParentId));
				}
				set_AttachmentIds.add(objAttachment);
				map_CaseIdToAttachmentIdsFromEmailMsg.put(map_EmailMessageIdToCaseId.get(objAttachment.ParentId), set_AttachmentIds);
			}
		}

		//fetching attachments related with cases getting their ContentDocumentIds
		Set<Id> set_CaseIds = map_CaseIdToCase.keySet();
		if (!set_CaseIds.isEmpty()) {
			for (ContentDocumentLink objContentDoc : [
				SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.FileExtension, ContentDocument.FileType, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :set_CaseIds
				ORDER BY ContentDocument.CreatedDate ASC
			]) {
				Set<Id> set_ContentDocIds = new Set<Id>();
				if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objContentDoc.LinkedEntityId)) {
					set_ContentDocIds = map_ParentToContenDocumentIds.get(objContentDoc.LinkedEntityId);
				}

				set_ContentDocIds.add(objContentDoc.ContentDocumentId);
				map_ParentToContenDocumentIds.put(objContentDoc.LinkedEntityId, set_ContentDocIds);
			}
		}

		//fetching attachments from attachment object for Case
		for (Attachment objAttachment : [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :set_CaseIds AND Name != NULL ORDER BY CreatedDate ASC]) { 
			Set<Attachment> set_AttachmentIds = new Set<Attachment>();
			if (map_CaseIdToAttachmentIds.get(objAttachment.ParentId) != null) { 
				set_AttachmentIds = map_CaseIdToAttachmentIds.get(objAttachment.ParentId);
			}
			set_AttachmentIds.add(objAttachment);
			map_CaseIdToAttachmentIds.put(objAttachment.ParentId, set_AttachmentIds);
		}

		/*segregate the cases on the basis of the attachment size. If case attachment is greater than 1 then that case
          added in the AutoSolveFailed set and other cases aatachment IDs are added in the set_ContentDocumentIds for processing.
          */
		for (Case objCase : list_Cases) {
			if (map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) != null && map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id).size() > 3) {
				set_AutoSolveFailedCaseIds.add(objCase.Id);
			} else if (map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) == null && (map_ParentToContenDocumentIds.containsKey(objCase.Id) || map_CaseIdToAttachmentIds.containsKey(objCase.Id))) {
				if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objCase.Id) && map_ParentToContenDocumentIds?.get(objCase.Id)?.size() > 3) {
					set_AutoSolveFailedCaseIds.add(objCase.Id);
				} else if (!map_CaseIdToAttachmentIds.isEmpty() && map_CaseIdToAttachmentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.get(objCase.Id).size() > 3) {
					set_AutoSolveFailedCaseIds.add(objCase.Id);
				} else if (!map_ParentToContenDocumentIds.isEmpty() && !map_CaseIdToAttachmentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.containsKey(objCase.Id) &&
				(map_ParentToContenDocumentIds?.get(objCase.Id)?.size() + map_CaseIdToAttachmentIds.get(objCase.Id).size()) > 3) {
					set_AutoSolveFailedCaseIds.add(objCase.Id);
				} else if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds?.get(objCase.Id)?.size() <= 3) {
					set_ContentDocumentIds.addAll(map_ParentToContenDocumentIds.get(objCase.Id));
				}
			}
		}

		//create map of ContentVerion's ContenetDocumentIds with it's Id
		for (ContentVersion objContentVersion : [
			SELECT Id, VersionData, Title, FileExtension, ContentDocumentId
			FROM ContentVersion
			WHERE IsLatest = TRUE AND ContentDocumentId IN :set_ContentDocumentIds
		]) {
			map_ContDocIdToContentVersionIds.put(objContentVersion.ContentDocumentId, objContentVersion.Id);
			map_ContentVersions.put(objContentVersion.Id, objContentVersion);
		}

		//processing the cases. If the case present in AutoSolveFailed set then Status and Automation Status of case will update , otherwise AutoSolve process will proceed and email will sent.
		for (Case objCase : list_Cases) {
			if (set_AutoSolveFailedCaseIds.Contains(objCase.Id)) {
				objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE;
				objCase.Automation_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
				objCase.OwnerId = TaxResNoticeIndexDetailsController.SPECIALIST_QUEUE_ID;
				objCase.Tax_Res_Auto_Response_Sent__c = false;
				
				if (objCase.Automation_Message_Follow_Up__c == null) {
					objCase.Automation_Message_Follow_Up__c = CaseUtils.CASE_AUTO_SOLVE_ERROR_MULTIPLE_ATTACHMENTS;
				} else {
					objCase.Automation_Message_Follow_Up__c = objCase.Automation_Message_Follow_Up__c + ';' + CaseUtils.CASE_AUTO_SOLVE_ERROR_MULTIPLE_ATTACHMENTS;
				}
				list_CasesToUpdateWhenFailed.add(objCase);
			} else {
				if (objCase.Automation_Message__c != strAutomationTriggred_TaxResResearchInProgress) {
					objCase.Status = CaseUtils.STATUS_CLOSED;
				}
				objCase.Automation_Status__c = CaseUtils.STATUS_COMPLETED;
				objCase.Tax_Res_Auto_Response_Sent__c = true;
				list_CasesToUpdateWhenSuccess.add(objCase);

				Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
				objMail.TemplateId = objEmailTemplate?.Id;
				objMail.TargetObjectId = objCase.ContactId;
				objMail.WhatId = objCase.Id;
				objMail.setUseSignature(false);

				if (String.isNotBlank(objCase.ContactEmail)) {
					objMail.setToAddresses(new List<String>{ objCase.ContactEmail });
				}

				if (String.isNotBlank(objCase.SuppliedEmail)) {
					objMail.setCcAddresses(new List<String>{ objCase.SuppliedEmail });
				}

				if (!Test.isRunningTest()) {
					objMail.setOrgWideEmailAddressId(list_objOrgEmailAddressSupport.get(0).Id);
				}

				List<Messaging.EmailFileAttachment> list_attachments = new List<Messaging.EmailFileAttachment>();

				if (!map_CaseIdToAttachmentIdsFromEmailMsg.isEmpty() && map_CaseIdToAttachmentIdsFromEmailMsg.containsKey(objCase.Id) && map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) != null) { 
					for (Attachment objAttachment : map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id)) {
						Messaging.EmailFileAttachment objFileAttachment = new Messaging.EmailFileAttachment();
						objFileAttachment.setFileName(objAttachment.Name);
						objFileAttachment.setBody(objAttachment.Body);
						objFileAttachment.setContentType(objAttachment.ContentType);
						objFileAttachment.setInline(false);
						list_attachments.add(objFileAttachment);
					}
				} else if (!map_CaseIdToAttachmentIds.isEmpty() && map_CaseIdToAttachmentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.get(objCase.Id) != null) {
					for (Attachment objAttachment : map_CaseIdToAttachmentIds.get(objCase.Id)) {
						Messaging.EmailFileAttachment objFileAttachment = new Messaging.EmailFileAttachment();
						objFileAttachment.setFileName(objAttachment.Name);
						objFileAttachment.setBody(objAttachment.Body);
						objFileAttachment.setContentType(objAttachment.ContentType);
						objFileAttachment.setInline(false);
						list_attachments.add(objFileAttachment);
					}
				}
				
				if (list_attachments != null && !list_attachments.isEmpty()) {
					objMail.setFileAttachments(list_attachments);
				}

				//Add attachment if the criteria matched and Case have attachments.
				if (!map_ContDocIdToContentVersionIds.isEmpty() && !map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objCase.Id) &&
				(map_CaseIdToAttachmentIdsFromEmailMsg.isEmpty() || !map_CaseIdToAttachmentIdsFromEmailMsg.containsKey(objCase.Id) || map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) == null)) {
					List<Id> list_RelContentVerIds = new List<Id>();
					if (map_ParentToContenDocumentIds.containsKey(objCase.Id)) {
						for (Id idContentDoc : map_ParentToContenDocumentIds.get(objCase.Id)) {
							if (map_ContDocIdToContentVersionIds.containsKey(idContentDoc)) {
								list_RelContentVerIds.add(map_ContDocIdToContentVersionIds.get(idContentDoc));
							}
						}
					}

					if (!list_RelContentVerIds.isEmpty()) {
						objMail.setEntityAttachments(list_RelContentVerIds);
					}
				}

				if (String.isNotBlank(objCase.ContactEmail) || String.isNotBlank(objCase.SuppliedEmail)) {
					list_Emails.add(objMail);
				}
			}
		}

		Boolean blnRevertCases = false;
		try {
			if (!list_Emails?.isEmpty()) {
				Set<Id> set_FailedCaseId = new Set<Id>();
				List<Case> list_CasesToRevert = new List<Case>();
				Messaging.SendEmailResult[] list_sendEmails = Messaging.sendEmail(list_Emails);

				for (Messaging.SendEmailResult objEmail : list_sendEmails) {
					if (!objEmail.isSuccess()) {
						if (String.valueOf(objEmail.getErrors()[0].getStatusCode()) == 'EMAIL_ADDRESS_BOUNCED') {
							String strContactId = objEmail.getErrors()[0].getTargetObjectId();
							if (strContactId != null && map_ContactIdToCaseId.containsKey(strContactId)) {
								for (Case objCase : list_Cases) {
									if (objCase.Id == map_ContactIdToCaseId.get(strContactId)) {
										if (objCase.Automation_Message_Follow_Up__c == null) {
											objCase.Automation_Message_Follow_Up__c = CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
										} else {
											objCase.Automation_Message_Follow_Up__c = objCase.Automation_Message_Follow_Up__c + '; ' + CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
										}
										list_CasesToRevert.add(objCase);
									}
								}
							}
						}
						blnRevertCases = true;
					}
				}

				if (blnRevertCases || (Test.isRunningTest() && TaxResAutoSolveUtilTest.blnTestRevertCases)) {
					TaxResAutoSolveUtil.revertCaseRecords(list_CasesToRevert);
					return;
				}
			}

			//update the closed cases
			if (!list_CasesToUpdateWhenSuccess?.isEmpty()) {
				TaxResAutoSolveUtil.updateCases(list_CasesToUpdateWhenSuccess);
			}

			//update the AutoSolve Process failed Cases
			if (!list_CasesToUpdateWhenFailed?.isEmpty()) {
				TaxResAutoSolveUtil.updateCases(list_CasesToUpdateWhenFailed);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxResAutoSolveEmailHelper', 'sendAutoSolveEmail', objException);
			Exception_Log__c objLog = ExceptionLogUtil.parseException(objException);
			if (objLog.Message__c.contains('EMAIL_ADDRESS_BOUNCED')) {
				if (objLog.Field_Names__c != null) {
					String strContactId = objLog.Field_Names__c.split(',')[1];
					if (strContactId != null && map_ContactIdToCaseId.containsKey(strContactId)) {
						for (Case objCase : list_Cases) {
							if (objCase.Id == map_ContactIdToCaseId.get(strContactId)) {
								if (objCase.Automation_Message_Follow_Up__c == null) {
									objCase.Automation_Message_Follow_Up__c = CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
								} else {
									objCase.Automation_Message_Follow_Up__c = objCase.Automation_Message_Follow_Up__c + '; ' + CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
								}
							}
						}
					}
				}
			}
			TaxResAutoSolveUtil.revertCaseRecords(list_Cases);
		}
	}
}