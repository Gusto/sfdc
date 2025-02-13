/**
 * @name         OEReminderEmailBatch
 * @author       Neha Dabas
 * @date         11th August 2020
 * @description  Send OE Reminder Emails 1 day before the Window End Date to the customer.
 * @test class   OEReminderEmailBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class OEReminderEmailBatch implements Database.Batchable<sObject> {
	EmailTemplate objEmailTemplate;
	String strEmailTemplateName;
	Map<String, OrgWideEmailAddress> map_orgWideAddress;
	public OEReminderEmailBatch() {
		strEmailTemplateName = 'OE_Reminder_Email';
		objEmailTemplate = [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName LIMIT 1];
		map_orgWideAddress = OEEmailAutomationHelper.getOrgWideAddresses(new Set<String>{ 'newplans@gusto.com', 'renewals@gusto.com' });
	}

	public Database.queryLocator Start(Database.batchableContext bc) {
		Set<String> set_ValidOrderStatus = new Set<String>{ 'OE', 'OE Extended', 'OE Verification/Checking Participation' };
		Set<String> set_ValidBORecordTypes = new Set<String>{ 'Renewal', 'New_Plan', 'Change', 'Benefits_BYOB' };
		String strCaseQuery =
			'SELECT Opportunity__c' +
			', Opportunity__r.RecordType.DeveloperName' +
			', Benefit_Order__r.Open_Enrollment_End_Date__c' +
			', Integration_Id__c' +
			', Benefit_Order__r.RecordType.DeveloperName' +
			', Case_Reference__c' +
			', ContactId' +
			', Contact.FirstName' +
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
			' WHERE Integration_Id__c != NULL' +
			' AND ContactId != NULL' +
			' AND Benefit_Order__c != NULL' +
			' AND Carrier_Order__c = NULL' +
			' AND Benefit_Order__r.RecordType.DeveloperName IN :set_ValidBORecordTypes' +
			' AND Benefit_Order__r.Is_Multi_EIN__c = false' +
			' AND Benefit_Order__r.Parent_Benefit_Order__c = NULL' +
			' AND Benefit_Order__r.Order_Status__c IN :set_ValidOrderStatus' +
			' AND Benefit_Order__r.OE_Complete__c = false' +
			' AND Benefit_Order__r.Open_Enrollment_End_Date__c = NEXT_N_DAYS:1';

		strCaseQuery += strWhereClause;

		return Database.getqueryLocator(strCaseQuery);
	}
	public void Execute(Database.BatchableContext bc, List<Case> list_CustomerCases) {
		if (list_CustomerCases == null || list_CustomerCases.size() == 0 || objEmailTemplate == null) {
			return;
		}
		Id idCaseBeingProcessed;
		try {
			Set<Id> set_BOOwners = new Set<Id>();
			Set<Id> set_CaseIds = new Set<Id>();

			//Identify Benefit Order Owners to fetch their signatures
			for (Case objCase : list_CustomerCases) {
				idCaseBeingProcessed = objCase.Id;
				if (String.valueOf(objCase.Benefit_Order__r.OwnerId).startsWith('005')) {
					set_BOOwners.add(objCase.Benefit_Order__r.OwnerId);
				}

				//to check if any Reminder emails are already sent on these cases
				set_CaseIds.add(objCase.Id);
			}

			if (set_CaseIds.size() > 0) {
				OEEmailAutomationHelper.fetchCaseTeamMember(set_CaseIds);
			}

			Map<Id, String> map_UserSignature = OEEmailAutomationHelper.fetchUserSignature(set_BOOwners);
			List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
			Map<Id, Integer> map_ExistingEmailCounts = OEEmailAutomationHelper.fetchSentEmailCountForCases(set_CaseIds, new Set<String>{ strEmailTemplateName });
			List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();
			for (Case objCase : list_CustomerCases) {
				//create emailMessage and Mail records
				String strIntegrationKey = 'hippo-' + objCase.Opportunity__r.RecordType.DeveloperName + '-' + objCase.Opportunity__c;
				if (objCase.Integration_Id__c == strIntegrationKey && (map_ExistingEmailCounts == null || !map_ExistingEmailCounts.containsKey(objCase.Id))) {
					String strBody = OEEmailAutomationHelper.mergeCommonFieldsInTemplate(objEmailTemplate.HTMLValue, map_UserSignature, objCase);

					if (objCase.Benefit_Order__r.Open_Enrollment_End_Date__c != null) {
						String strformattedDate =
							'' +
							objCase.Benefit_Order__r.Open_Enrollment_End_Date__c.month() +
							'/' +
							objCase.Benefit_Order__r.Open_Enrollment_End_Date__c.day() +
							'/' +
							objCase.Benefit_Order__r.Open_Enrollment_End_Date__c.year();

						strBody = strBody.replace('[OEW End Date]', strformattedDate);
					}
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
				ExceptionLogUtil.logException('OEReminderEmailBatch', 'execute for Case(' + idCaseBeingProcessed + ')', objExcep.getMessage() + '  ' + objExcep.getStackTraceString(), 'high');
			}
		}
	}
	public void Finish(Database.BatchableContext bc) {
	}
}