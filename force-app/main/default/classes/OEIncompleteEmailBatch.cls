/**
 * @name         OEIncompleteEmailBatch
 * @author       Neha Dabas
 * @date         13th August 2020
 * @description  Send OE Incomplete Emails 1 day and 2 days before the Final Extension Date, to the customer.
 * @test class   OEIncompleteEmailBatchTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class OEIncompleteEmailBatch implements Database.Batchable<sObject> {
	EmailTemplate objEmailTemplate;
	String strEmailTemplateName;
	Map<String, OrgWideEmailAddress> map_orgWideAddress;
	public OEIncompleteEmailBatch() {
		strEmailTemplateName = 'OE_Incomplete_Email';
		objEmailTemplate = [SELECT Subject, DeveloperName, HtmlValue FROM EmailTemplate WHERE DeveloperName = :strEmailTemplateName LIMIT 1];
		map_orgWideAddress = OEEmailAutomationHelper.getOrgWideAddresses(new Set<String>{ 'newplans@gusto.com', 'renewals@gusto.com' });
	}

	public Database.queryLocator Start(Database.batchableContext bc) {
		Set<String> set_ValidOrderStatus = new Set<String>{ 'OE', 'OE Extended', 'OE Verification/Checking Participation' };
		Set<String> set_ValidBORecordTypes = new Set<String>{ 'Renewal', 'New_Plan', 'Change', 'Benefits_BYOB' };
		String strCaseQuery =
			'SELECT Benefit_Order__r.Open_Enrollment_End_Date__c' +
			', Benefit_Order__r.Final_Extension_Date__c' +
			', Opportunity__c' +
			', Opportunity__r.RecordType.DeveloperName' +
			', Integration_Id__c' +
			', Benefit_Order__r.RecordType.DeveloperName' +
			', Case_Reference__c' +
			', ContactId' +
			', Contact.FirstName' +
			', Benefit_Order__c' +
			', Benefit_Order__r.OE_Complete__c' +
			', Benefit_Order__r.Order_Status__c' +
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
			' AND Carrier_Order__c = NULL' +
			' AND Benefit_Order__r.Is_Multi_EIN__c = false' +
			' AND Benefit_Order__r.Parent_Benefit_Order__c = NULL' +
			' AND Benefit_Order__r.Order_Status__c != NULL' +
			' AND Benefit_Order__r.Order_Status__c IN :set_ValidOrderStatus' +
			' AND Benefit_Order__r.OE_Complete__c = false' +
			' AND Benefit_Order__r.Open_Enrollment_End_Date__c  = LAST_N_DAYS:2' +
			' AND Benefit_Order__r.Open_Enrollment_End_Date__c != TODAY' +
			' AND Benefit_Order__r.Final_Extension_Date__c > TODAY';
		strCaseQuery += strWhereClause;
		return Database.getqueryLocator(strCaseQuery);
	}
	public void Execute(Database.BatchableContext bc, List<Case> list_CustomerCases) {
		Id idCaseBeingProcessed;
		if (list_CustomerCases == null || list_CustomerCases.isEmpty() || objEmailTemplate == null) {
			return;
		}
		try {
			//Identify Benefit Order Owners to fetch their signatures
			Set<Id> set_BOOwners = new Set<Id>();
			Set<Id> set_CaseIds = new Set<Id>();

			for (Case objCase : list_CustomerCases) {
				if (String.valueOf(objCase.Benefit_Order__r.OwnerId).startsWith('005')) {
					set_BOOwners.add(objCase.Benefit_Order__r.OwnerId);
				}
				//to check if any Incomplete emails are already sent on these cases
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
				idCaseBeingProcessed = objCase.Id;
				//create emailMessage and Mail records
				String strIntegrationKey = 'hippo-' + objCase.Opportunity__r.RecordType.DeveloperName + '-' + objCase.Opportunity__c;
				if (
					objCase.Integration_Id__c == strIntegrationKey &&
					(map_ExistingEmailCounts == null ||
					!map_ExistingEmailCounts.containsKey(objCase.Id) ||
					map_ExistingEmailCounts.get(objCase.Id) == 1)
				) {
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
				ExceptionLogUtil.logException('OEIncompleteEmailBatch', 'execute for Case(' + idCaseBeingProcessed + ')', objExcep.getMessage() + '  ' + objExcep.getStackTraceString(), 'high');
			}
		}
	}
	public void Finish(Database.BatchableContext bc) {
	}
}