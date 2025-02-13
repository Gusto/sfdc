/**
 * @name         OEFinalExtensionEmailBatch
 * @author       Neha Dabas
 * @date         26th August 2020
 * @description  Send OE Final Extension Email on the Final Extension Date, to the customer.
 * @test class   OEFinalExtensionEmailBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class OEFinalExtensionEmailBatch implements Database.Batchable<sObject> {
	Map<String, EmailTemplate> map_EmailTemplate;
	Map<String, OrgWideEmailAddress> map_orgWideAddress;
	String strDefaultEmailTemplateName, strRenewalSameCarrierTemplateName;
	public OEFinalExtensionEmailBatch() {
		strDefaultEmailTemplateName = 'OE_Final_Extension_Email_Default';
		strRenewalSameCarrierTemplateName = 'OE_Final_Extension_Email_Renewal_Same_Carrier';
		List<EmailTemplate> list_EmailTemplates = [
			SELECT Subject, DeveloperName, HtmlValue
			FROM EmailTemplate
			WHERE DeveloperName = :strDefaultEmailTemplateName OR DeveloperName = :strRenewalSameCarrierTemplateName
			LIMIT 2
		];
		map_orgWideAddress = OEEmailAutomationHelper.getOrgWideAddresses(new Set<String>{ 'newplans@gusto.com', 'renewals@gusto.com' });

		if (list_EmailTemplates != null && !list_EmailTemplates.isEmpty()) {
			map_EmailTemplate = new Map<String, EmailTemplate>();
			for (EmailTemplate objTemplate : list_EmailTemplates) {
				map_EmailTemplate.put(objTemplate.DeveloperName, objTemplate);
			}
		}
	}

	public Database.queryLocator Start(Database.batchableContext bc) {
		Set<String> set_ValidOrderStatus = new Set<String>{ 'OE', 'OE Extended', 'OE Verification/Checking Participation' };
		Set<String> set_ValidBORecordTypes = new Set<String>{ 'Renewal', 'New_Plan', 'Change', 'Benefits_BYOB' };
		String strCaseQuery =
			'SELECT Opportunity__c' +
			', Opportunity__r.RecordType.DeveloperName' +
			', Integration_Id__c' +
			', Benefit_Order__r.RecordType.DeveloperName' +
			', Case_Reference__c,ContactId,Contact.FirstName' +
			', Benefit_Order__c' +
			', Benefit_Order__r.OE_Complete__c' +
			', Benefit_Order__r.Order_Status__c' +
			', Benefit_Order__r.Final_Extension_Date__c' +
			', Benefit_Order__r.Owner.Name' +
			', Benefit_Order__r.OwnerId' +
			', Benefit_Order__r.Coverage_Effective_Date__c' +
			', AccountId' +
			', Account.Name' +
			' FROM Case';
		String strWhereClause =
			' WHERE Benefit_Order__r.RecordType.DeveloperName IN :set_ValidBORecordTypes' +
			' AND Integration_Id__c != NULL' +
			' AND ContactId != NULL' +
			' AND Benefit_Order__c != NULL' +
			' AND Benefit_Order__r.Is_Multi_EIN__c = false' +
			' AND Benefit_Order__r.Parent_Benefit_Order__c = NULL' +
			' AND Benefit_Order__r.Order_Status__c IN :set_ValidOrderStatus' +
			' AND Benefit_Order__r.OE_Complete__c = false' +
			' AND Carrier_Order__c = NULL' +
			' AND Benefit_Order__r.Final_Extension_Date__c = TODAY' +
			' AND Benefit_Order__r.Open_Enrollment_End_Date__c < TODAY';
		strCaseQuery += strWhereClause;
		return Database.getqueryLocator(strCaseQuery);
	}
	public void Execute(Database.BatchableContext bc, List<Case> list_CustomerCases) {
		Id idCaseBeingProcessed;
		if (list_CustomerCases == null || list_CustomerCases.isEmpty() || map_EmailTemplate == null || map_EmailTemplate.isEmpty()) {
			return;
		}
		try {
			//Identify Benefit Order Owners to fetch their signatures
			Set<Id> set_BOOwners = new Set<Id>();
			Set<Id> set_CaseIds = new Set<Id>();
			Set<Id> set_BOIds = new Set<Id>();

			for (Case objCase : list_CustomerCases) {
				if (String.valueOf(objCase.Benefit_Order__r.OwnerId).startsWith('005')) {
					set_BOOwners.add(objCase.Benefit_Order__r.OwnerId);
				}
				//to check if any Incomplete emails are already sent on these cases
				set_CaseIds.add(objCase.Id);

				//to check BO rec type and CO Order Types for choosing the correct email template
				set_BOIds.add(objCase.Benefit_Order__c);
			}

			if (set_CaseIds.size() > 0) {
				OEEmailAutomationHelper.fetchCaseTeamMember(set_CaseIds);
			}

			Map<Id, String> map_BOIdTemplateName = OEEmailAutomationHelper.identifyOEFinalExtensionTemplate(strDefaultEmailTemplateName, strRenewalSameCarrierTemplateName, set_BOIds);
			Map<Id, String> map_UserSignature = OEEmailAutomationHelper.fetchUserSignature(set_BOOwners);
			List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
			Map<Id, Integer> map_ExistingEmailCounts = OEEmailAutomationHelper.fetchSentEmailCountForCases(set_CaseIds, map_EmailTemplate.keySet());
			List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();

			for (Case objCase : list_CustomerCases) {
				idCaseBeingProcessed = objCase.Id;
				//create emailMessage and Mail records
				String strIntegrationKey = 'hippo-' + objCase.Opportunity__r.RecordType.DeveloperName + '-' + objCase.Opportunity__c;

				if (
					objCase.Integration_Id__c == strIntegrationKey &&
					(map_ExistingEmailCounts == null || !map_ExistingEmailCounts.containsKey(objCase.Id)) &&
					map_BOIdTemplateName != null &&
					map_BOIdTemplateName.containsKey(objCase.Benefit_Order__c) &&
					map_EmailTemplate.containsKey(map_BOIdTemplateName.get(objCase.Benefit_Order__c))
				) {
					EmailTemplate objEmailTemplate = map_EmailTemplate.get(map_BOIdTemplateName.get(objCase.Benefit_Order__c));
					String strBody = OEEmailAutomationHelper.mergeCommonFieldsInTemplate(objEmailTemplate.HTMLValue, map_UserSignature, objCase);
					Messaging.SingleEmailMessage objMail = OEEmailAutomationHelper.createEmailRecord(objEmailTemplate.Subject, objCase, strBody);
					EmailMessage objMsg = OEEmailAutomationHelper.createEmailMessageRecord(strBody, objCase, objEmailTemplate.Subject, objEmailTemplate.DeveloperName);

					//set from addresses
					if (map_orgWideAddress != null && map_orgWideAddress.containsKey(objCase.Benefit_Order__r.RecordType.DeveloperName)) {
						objMsg.fromAddress = map_orgWideAddress.get(objCase.Benefit_Order__r.RecordType.DeveloperName).Address;
						objMail.setOrgWideEmailAddressId(map_orgWideAddress.get(objCase.Benefit_Order__r.RecordType.DeveloperName).Id);
					}

					list_Emails.add(objMail);

					list_EmailMessage.add(objMsg);
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
				ExceptionLogUtil.logException('OEFinalExtensionEmailBatch', 'execute for Case(' + idCaseBeingProcessed + ')', objExcep.getMessage() + '  ' + objExcep.getStackTraceString(), 'high');
			}
		}
	}
	public void Finish(Database.BatchableContext bc) {
	}
}