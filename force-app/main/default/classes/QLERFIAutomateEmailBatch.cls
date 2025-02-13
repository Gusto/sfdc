/**
 * @name         QLERFIAutomateEmailBatch
 * @test class   QLERFIAutomateEmailTest
 * @author       Bhagat Singh
 * @date         20th April 2021
 * @description  QLE RFI Automate Email scheduler.
 * @revisions    Date ------------ Name ------------ Comments
 *               10/27 ----------- Rushi R --------- Send success email and handle failure differently instead of all failure
 */

public with sharing class QLERFIAutomateEmailBatch implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts {
	public static final String RFI_STATUS = 'RFI%';
	public static final Id MF_QLE_RT = CaseUtils.RECTYPE_MF_QLE;
	public static final Id RENEWAL_RT = CaseUtils.RECTYPE_RENEWAL;

	public void execute(SchedulableContext objSC) {
		QLERFIAutomateEmailBatch objBatch = new QLERFIAutomateEmailBatch();
		Database.executeBatch(objBatch, 2);
	}

	public Database.QueryLocator start(Database.BatchableContext objBC) {
		Date dtToday = Date.today();
		Set<String> set_ExcludedCaseStatus = new Set<String>();
		set_ExcludedCaseStatus.add(CaseUtils.STATUS_CLOSED);
		set_ExcludedCaseStatus.add(CaseUtils.STATUS_CANCELLED);
		String strQuery =
			'SELECT Id' +
			', ContactId' +
			', Opportunity__c' +
			', RecordTypeId' +
			', OwnerId' +
			', QLE_RFI_Type__c' +
			', Contact.Name' +
			', Contact.LastName' +
			', Contact.FirstName' +
			', ContactEmail' +
			', Case_Reference__c' +
			', Insufficient_Proof_Reason__c' +
			', RFI_3rd_Business_Day__c' +
			', RFI_6th_Business_Day__c' +
			', RFI_9th_Business_Day__c' +
			' FROM Case' +
			' WHERE Automated_RFI_Flow__c = true' +
			' AND ((RecordTypeId = :MF_QLE_RT AND RFI_Status__c != null AND RFI_Status__c LIKE :RFI_STATUS)' +
			' OR RecordTypeId = :RENEWAL_RT)' +
			' AND Status NOT IN :set_ExcludedCaseStatus' +
			' AND (RFI_3rd_Business_Day__c = :dtToday' +
			' OR RFI_6th_Business_Day__c = :dtToday' +
			' OR RFI_9th_Business_Day__c = :dtToday)';

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext objBatch, List<Case> list_Cases) {
		Date dtReminder = Date.today();
		List<Case> list_UpdatedCases = new List<Case>();
		List<EmailMessage> list_EmailMessages = new List<EmailMessage>();
		List<Messaging.SingleEmailMessage> list_SingleEmailMessages = new List<Messaging.SingleEmailMessage>();

		Map<Id, Case> map_CaseIdCase = new Map<Id, Case>();
		Map<Id, List<Id>> map_ContactIdCaseIds = new Map<Id, List<Id>>();
		Map<Id, EmailMessage> map_CaseIdCaseEmailMsg = new Map<Id, EmailMessage>();
		Set<Id> set_MFQLECaseIds = new Set<Id>();
		Set<Id> set_RecertificationCaseIds = new Set<Id>();
		Set<Id> set_OpportunityIds = new Set<Id>();
		Set<Id> set_CaseOwnerIds = new Set<Id>();
		for (Case objCase : list_Cases) {
			set_CaseOwnerIds.add(objCase.OwnerId);
			if (objCase.Opportunity__c != null) {
				set_OpportunityIds.add(objCase.Opportunity__c);
			}
		}

		Map<Id, List<String>> map_OppIdWithToEmails = QLERFIAutomateEmailUtils.getOpportunityContactRolesEmail(set_OpportunityIds);
		Map<Id, String> map_UserSignatures = OEEmailAutomationHelper.fetchUserSignature(set_CaseOwnerIds);
		Boolean blnIsCaseUpdate;

		for (Case objCase : list_Cases) {
			blnIsCaseUpdate = false;
			Integer intIndex = 1;
			if (objCase.RecordtypeId == CaseUtils.RECTYPE_MF_QLE) {
				set_MFQLECaseIds.add(objCase.Id);
			}

			if (dtReminder == objCase.RFI_3rd_Business_Day__c) {
				intIndex = 2;

				if (objCase.RecordtypeId == CaseUtils.RECTYPE_MF_QLE) {
					blnIsCaseUpdate = true;
					objCase.RFI_Status__c = QLERFIAutomateEmailUtils.STATUS_RFI_2;
				}
			} else if (dtReminder == objCase.RFI_6th_Business_Day__c) {
				intIndex = 3;
				blnIsCaseUpdate = true;

				if (objCase.RecordtypeId == CaseUtils.RECTYPE_RENEWAL) {
					objCase.Automated_RFI_Flow__c = false;
					set_RecertificationCaseIds.add(objCase.Id);
				} else {
					objCase.RFI_Status__c = QLERFIAutomateEmailUtils.STATUS_RFI_3;
				}
			} else if (dtReminder == objCase.RFI_9th_Business_Day__c) {
				intIndex = 4;
				objCase.RFI_Status__c = QLERFIAutomateEmailUtils.STATUS_RFI_VIOLATED;
				objCase.Automated_RFI_Flow__c = false;
				objCase.Status = CaseUtils.STATUS_NEW;
				blnIsCaseUpdate = true;
			}

			if (intIndex > 1) {
				Messaging.SingleEmailMessage objEM = QLERFIAutomateEmailUtils.createEmailRecord(objCase, intIndex, map_UserSignatures);
				if (objEM != null) {
					list_SingleEmailMessages.add(objEM);

					EmailMessage objEmailMessage = QLERFIAutomateEmailUtils.createEmailMessageRecord(objEM, objCase, intIndex);
					if (objEmailMessage != null) {
						map_CaseIdCaseEmailMsg.put(objCase.Id, objEmailMessage);
					}

					if (objCase.Opportunity__c != null && objCase.RecordTypeId == CaseUtils.RECTYPE_RENEWAL && map_OppIdWithToEmails.containsKey(objCase.Opportunity__c)) {
						objEM.setToAddresses(map_OppIdWithToEmails.get(objCase.Opportunity__c));
						objEmailMessage.ToAddress = String.join(map_OppIdWithToEmails.get(objCase.Opportunity__c), ';');
					}
				}

				// populate map to handle email failures & case updates
				if (map_ContactIdCaseIds.containsKey(objCase.ContactId)) {
					map_ContactIdCaseIds.get(objCase.ContactId).add(objCase.Id);
				} else {
					map_ContactIdCaseIds.put(objCase.ContactId, new List<Id>{ objCase.Id });
				}
			}

			if (blnIsCaseUpdate) {
				map_CaseIdCase.put(objCase.Id, objCase);
			}
		}

		if (list_SingleEmailMessages.isEmpty()) {
			return;
		}

		Set<Id> set_FailedCaseId = new Set<Id>();
		List<Id> list_EmailParentIds = new List<Id>();
		try {
			Messaging.SendEmailResult[] list_SendMails = Messaging.sendEmail(list_SingleEmailMessages, false);
			for (Messaging.SendEmailResult objEmail : list_SendMails) {
				if (!objEmail.isSuccess()) {
					for (Messaging.SendEmailError objEmailError : objEmail.getErrors()) {
						Id idContactId = objEmailError.getTargetObjectId();
						if (map_ContactIdCaseIds.containsKey(idContactId)) {
							set_FailedCaseId.addAll(map_ContactIdCaseIds.get(idContactId));
						}
					}
				}
			}
		} catch (Exception objExp) {
			if (!list_Cases.isEmpty()) {
				createExceptionRecord(map_CaseIdCase.keySet());
			}
		}

		if (!set_FailedCaseId.isEmpty()) {
			for (Id idCase : map_CaseIdCase.keySet()) {
				if (!set_FailedCaseId.contains(idCase)) {
					list_UpdatedCases.add(map_CaseIdCase.get(idCase));
				}
			}

			for (Id idCase : map_CaseIdCaseEmailMsg.keySet()) {
				if (!set_FailedCaseId.contains(idCase)) {
					list_EmailMessages.add(map_CaseIdCaseEmailMsg.get(idCase));
					if (!set_MFQLECaseIds.contains(idCase)) {
						list_EmailParentIds.add(idCase);
					}
				}
			}
		} else {
			list_UpdatedCases.addAll(map_CaseIdCase.values());
			list_EmailMessages.addAll(map_CaseIdCaseEmailMsg.values());
			for (Id idCase : map_CaseIdCaseEmailMsg.keySet()) {
				if (!set_MFQLECaseIds.contains(idCase)) {
					list_EmailParentIds.add(idCase);
				}
			}
		}

		if (!list_EmailMessages.isEmpty()) {
			insert list_EmailMessages;
			EmailMessageTriggerHelper.logCaseEmailAlerts(list_EmailParentIds);
		}

		if (list_UpdatedCases.size() > 0) {
			CaseTriggerHelper.skipTrigger = true;
			update list_UpdatedCases;
			CaseTriggerHelper.skipTrigger = false;
		}

		if (!set_RecertificationCaseIds.isEmpty()) {
			List<Ticket__c> list_Tickets = CaseQueryHelper.getRelatedTickets(set_RecertificationCaseIds);
			if (list_Tickets != null && !list_Tickets.isEmpty()) {
				for (Ticket__c objTicket : list_Tickets) {
					if (objTicket.Case__c != null && objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_RECERTIFICATION) {
						objTicket.Recert_Status__c = TicketUtil.RECERT_STATUS_RECERT_FAILED;
					}
				}

				Boolean blnSkipTrigger = TicketTriggerHelper.skipTrigger;
				TicketTriggerHelper.skipTrigger = true;
				update list_Tickets;
				TicketTriggerHelper.skipTrigger = blnSkipTrigger;
			}
		}

		if (!set_FailedCaseId.isEmpty()) {
			createExceptionRecord(set_FailedCaseId);
		}
	}

	public void finish(Database.BatchableContext objBC) {
		// failed cases create exception records, hence no email
	}

	/**
	 * @name         createExceptionRecord
	 * @description  Creates Exception Log using Util methods, based on parameters
	 * @input        CaseIds to log exceptions for, and exception record (null allowed)
	 */
	private void createExceptionRecord(Set<Id> set_CaseIds) {
		List<String> list_CaseIds = new List<String>();
		for (Id idCase : set_CaseIds) {
			list_CaseIds.add(String.valueOf(idCase));
		}

		ExceptionLogUtil.logException('QLERFIAutomateEmailBatch', 'Execute method', 'Error while sending QLE email.\nCase Ids - ' + String.join(list_CaseIds, ','), 'Medium');
	}
}