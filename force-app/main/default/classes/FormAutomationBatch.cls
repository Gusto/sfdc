/**
 * @name         FormAutomationBatch
 * @author       Neha Dabas
 * @date         22nd June 2020
 * @description  If a case is eligible, send communication email to Carrier with forms as attachments for NHE, Member/Group Updates and Termination cases
 * @test class   FormAutomationSchedulerTest
 * @revisions    Date ------------ Name ------------ Comments
 */
global without sharing class FormAutomationBatch implements Database.Batchable<SObject> {
	Id idFormAutomationQueue;
	OrgWideEmailAddress FromAddress;
	Map<String, Id> map_RecordTypeNameToEmailTemplate;
	
	global FormAutomationBatch() {
		//Get Automation Queue Id
		List<Group> list_Queue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Form_Automation'];

		if (list_Queue != null && !list_Queue.isEmpty()) {
			idFormAutomationQueue = list_Queue[0].Id;
		}

		map_RecordTypeNameToEmailTemplate = new Map<String, Id>();
		//fetch email templates
		Set<String> set_templateNames = new Set<String>{ 'Form_Automation_NHE_Carrier_Email', 'Form_Automation_Term_Carrier_Email', 'Form_Automation_Member_Update_Carrier_Email' };
		List<EmailTemplate> list_template = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :set_templateNames];

		if (list_template != null && !list_template.isEmpty()) {
			for (EmailTemplate objTemplate : list_template) {
				if (objTemplate.DeveloperName.containsIgnoreCase('NHE')) {
					map_RecordTypeNameToEmailTemplate.put('MF NHE', objTemplate.Id);
				} else if (objTemplate.DeveloperName.containsIgnoreCase('Term')) {
					map_RecordTypeNameToEmailTemplate.put('MF Termination', objTemplate.Id);
				} else if (objTemplate.DeveloperName.containsIgnoreCase('Member')) {
					map_RecordTypeNameToEmailTemplate.put('MF Member/Group Updates', objTemplate.Id);
				}
			}
		}

		//Fetch Org Wide Email Address
		List<OrgWideEmailAddress> list_addresses = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'memberfulfillment@gusto.com'];
		if (list_addresses != null && !list_addresses.isempty()) {
			FromAddress = list_addresses[0];
		}
	}

	global Database.QueryLocator start(Database.BatchableContext bContext) {
		//Fetch cases
		Set<String> set_CaseRecType = new Set<String>{ 'MF NHE', 'MF Member/Group Updates', 'MF Termination' };
		String strCaseQuery = 'SELECT Update_Information__c,Group_Member_Update_Type_Text__c,MF_Group_Number__c,Account.Name,Number_of_Forms__c, Carrier__r.Submission_Email__c,ContactId,Missing_Form_Attributes__c,RecordType.Name,Type FROM Case ';
		String strWhereClause =
			'WHERE  RecordType.Name IN :set_CaseRecType AND Form_Fully_Mapped__c = true AND Form_Fits_Dependents__c = true' +
			' AND Number_of_Forms__c > 0' +
			' AND Integration_Key__c != NULL AND Form_Sent_Automatically__c = false AND Group_Member_Update_Type__c EXCLUDES (\'SSN Update\',\'Birthday Update\')' +
			' AND Status = \'New\' AND OwnerId = :idFormAutomationQueue';
		strCaseQuery += strWhereClause;
		return Database.getQueryLocator(strCaseQuery);
	}

	global void Execute(Database.BatchableContext bContext, List<Case> list_Cases) {
		Map<Id, List<Attachment>> map_SuccessCases = new Map<Id, List<Attachment>>();
		try {
			Set<Id> set_CaseIdSuccess = new Set<Id>();
			// If Email templates do not exist
			if (map_RecordTypeNameToEmailTemplate == null || map_RecordTypeNameToEmailTemplate.isEmpty() || list_Cases == null || list_Cases.isEmpty()) {
				return;
			}

			Map<Id, Case> map_Cases = new Map<Id, Case>();
			for (Case objCase : list_Cases) {
				map_Cases.put(objCase.Id, objCase);
			}

			//Fetch the ContentDocumentLink linked with Cases
			List<Attachment> list_Attachments = [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :map_Cases.keySet() AND Name != 'encFile.txt'];

			if (list_Attachments == null || list_Attachments.isEmpty()) {
				return;
			}

			//Identify Attachments for each Case
			Map<Id, List<Id>> map_CaseToAttachment = new Map<Id, List<Id>>();
			Map<Id, List<Attachment>> map_CaseAttachments = new Map<Id, List<Attachment>>();
			for (Attachment objAtt : list_Attachments) {
				List<Id> list_CVId;
				List<Attachment> list_Attch;
				if (map_CaseToAttachment.containsKey(objAtt.ParentId)) {
					list_CVId = map_CaseToAttachment.get(objAtt.ParentId);
					list_Attch = map_CaseAttachments.get(objAtt.ParentId);
				} else {
					list_CVId = new List<Id>();
					list_Attch = new List<Attachment>();
				}
				list_CVId.add(objAtt.Id);
				list_Attch.add(objAtt);
				map_CaseToAttachment.put(objAtt.ParentId, list_CVId);
				map_CaseAttachments.put(objAtt.ParentId, list_Attch);
			}

			List<Messaging.SingleEmailMessage> list_emailMessage = new List<Messaging.SingleEmailMessage>();

			for (Case objCase : list_Cases) {
				// As it is a long text area field, this cannot be filterred in query. If there are any missing attributes we do not automate form submission
				if (objCase.Missing_Form_Attributes__c != null || String.isNotBlank(objCase.Missing_Form_Attributes__c)) {
					objCase.Automation_Message__c = 'Form is incomplete as there are missing attributes';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}
				//Submission email id blank on Carrier
				if (objCase.Carrier__c == null || objCase.Carrier__r.Submission_Email__c == null || String.isBlank(objCase.Carrier__r.Submission_Email__c)) {
					objCase.Automation_Message__c = 'Submission Email on Carrier is blank';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}
				// there is no Contact on Case
				if (objCase.ContactId == null && objCase.Type != 'Group Updates') {
					objCase.Automation_Message__c = 'Contact is blank on Case.';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}
				//No Attachments on Case
				if (!map_CaseToAttachment.containsKey(objCase.Id)) {
					objCase.Automation_Message__c = 'No form attachments found';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}
				List<Id> list_DocIds = map_CaseToAttachment.get(objCase.Id);
				// Attachment count is not in sync with form count in HIFulfillmentEvent pushed from HIPPO
				if (list_DocIds.size() != objCase.Number_of_Forms__c) {
					objCase.Automation_Message__c = 'Number of forms attached do not match with number of forms in Events request';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}
				// Email template does not exist for Case.RecordType
				if (!map_RecordTypeNameToEmailTemplate.containsKey(objCase.RecordType.Name) && objCase.Type != 'Group Updates') {
					objCase.Automation_Message__c = 'Form Automation Email Template does not exist';
					objCase.Automation_Status__c = 'Failed';
					continue;
				}

				Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
				objEmail.setEntityAttachments(list_DocIds);
				if (objCase.RecordType.Name == 'MF Member/Group Updates' && objCase.Type == 'Group Updates') {
					String strEmailSubject = 'Information Update for ' + objCase.Account.Name + ' / ' + objCase.MF_Group_Number__c;
					String strEmailBody = 'Hello,';
					strEmailBody += '\n\n';
					strEmailBody += 'We have an ' + objCase.Group_Member_Update_Type_Text__c + ' for ' + objCase.Account.Name;
					strEmailBody += '\n\n';
					strEmailBody += 'Group ID: ' + objCase.MF_Group_Number__c;
					strEmailBody += '\n\n';
					strEmailBody += '' + objCase.Update_Information__c;
					strEmailBody += '\n\n';
					strEmailBody += 'Please let me know once this has been processed.';
					strEmailBody += '\n\n\n';
					strEmailBody += 'Thank you,';
					strEmailBody += '\n';
					strEmailBody += 'Member Operations | Gusto | 800-683-8526';
					strEmailBody += '\n';
					strEmailBody += 'Gusto | all-in-one platform for HR, Payroll, & Benefits';
					strEmailBody += '\n';
					strEmailBody += 'noun (guhs-toh)';
					strEmailBody += '\n';
					strEmailBody += 'great enjoyment, energy, & enthusiasm';

					objEmail.setPlainTextBody(strEmailBody);
					objEmail.setSubject(strEmailSubject);
				} else {
					objEmail.setTemplateId(map_RecordTypeNameToEmailTemplate.get(objCase.RecordType.Name));
					objEmail.setTargetObjectId(objCase.ContactId);
				}

				objEmail.setToAddresses(new List<String>{ objCase.Carrier__r.Submission_Email__c });
				objEmail.setWhatId(objCase.Id);
				objEmail.setSaveAsActivity(true);
				objEmail.setTreatTargetObjectAsRecipient(false);
				if (FromAddress != null) {
					objEmail.setOrgWideEmailAddressId(FromAddress.Id);
				}

				list_emailMessage.add(objEmail);

				objCase.Automation_Message__c = 'Email sent to carrier';
				objCase.Automation_Status__c = 'Completed';
				objCase.Status = 'Submitted';
				objCase.Submission_Method__c = 'Mapped Form';
				objCase.Follow_Up_Date__c = System.today().addDays(7);
				objCase.Form_Sent_Automatically__c = true;
				objCase.Date_Time_Submitted__c = system.now();

				set_CaseIdSuccess.add(objCase.Id);
			}

			if (!list_emailMessage.isEmpty()) {
				Messaging.SendEmailResult[] list_results = Messaging.sendEmail(list_emailMessage);
				String strErrorMessages = '';
				for (Messaging.SendEmailResult objResult : list_results) {
					if (!objResult.success) {
						strErrorMessages += objResult.errors[0].message + ', ';
					}
				}
				if (String.isNotBlank(strErrorMessages))
					ExceptionLogUtil.logException('FormAutomationBatch', 'Execute', strErrorMessages, '');
				for (Id idCase : set_CaseIdSuccess) {
					map_SuccessCases.put(idCase, map_CaseAttachments.get(idCase));
				}
			}

			CaseTriggerHelper.skipTrigger = false;
			CaseTriggerHelper.blnFormAutomationBatch = true;
			update list_Cases;
			CaseTriggerHelper.blnFormAutomationBatch = false;

			createEmailAttachments(map_SuccessCases);
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('FormAutomationBatch', 'Execute', objEx.getMessage(), objEx.getStackTraceString());
		}
	}

	global void finish(Database.BatchableContext bContext) {
	}

	void createEmailAttachments(Map<Id, List<Attachment>> map_SuccessCases) {
		try {
			if (map_SuccessCases.size() == 0)
				return;
			//Get Email message records inserted
			List<EmailMessage> list_EmailsSent = new List<EmailMessage>();
			list_EmailsSent = [
				SELECT FromAddress, RelatedToId, Attachment_Created__c
				FROM EmailMessage
				WHERE RelatedToId IN :map_SuccessCases.keySet() AND CreatedDate = TODAY AND FromAddress = :FromAddress.Address AND Incoming = FALSE AND Attachment_Created__c = FALSE AND Status = '3'
			];
			//Insert attachments for the EmailMessage records inserted
			List<Attachment> list_EmailAttachments = new List<Attachment>();
			if (!list_EmailsSent.isEmpty()) {
				for (EmailMessage objMessage : list_EmailsSent) {
					List<Attachment> list_CaseAttachments = map_SuccessCases.get(objMessage.RelatedToId);
					for (Attachment objAtt : list_CaseAttachments) {
						list_EmailAttachments.add(new Attachment(Body = objAtt.Body, ParentId = objMessage.Id, ContentType = objAtt.ContentType, Name = objAtt.Name));
					}
					objMessage.Attachment_Created__c = true;
				}
				Boolean blnEmailSkipTriggerFlag = EmailMessageTriggerHelper.SkipTrigger;
				EmailMessageTriggerHelper.SkipTrigger = true;
				update list_EmailsSent;
				EmailMessageTriggerHelper.SkipTrigger = blnEmailSkipTriggerFlag;

				if (!list_EmailAttachments.isEmpty()) {
					Boolean blnAttachmentSkipTriggerFlag = TriggerHandler.isBypassed('AttachmentTriggerHandler');
					TriggerHandler.bypass('AttachmentTriggerHandler');
					insert list_EmailAttachments;
					if (!blnAttachmentSkipTriggerFlag) {
						TriggerHandler.clearBypass('AttachmentTriggerHandler');
					}
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('FormAutomationBatch', 'Finish', objEx.getMessage(), objEx.getStackTraceString());
		}
	}
}