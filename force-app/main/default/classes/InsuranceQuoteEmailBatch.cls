/**
 * @name         : InsuranceQuoteEmailBatch
 * @author       : Debasmita Rawooth
 * @date         : 10-08-2021
 * @description  : Batch Class for sending completed quote email to customer.
 * @test classes : InsuranceQuoteEmailBatchTest
 **/
public with sharing class InsuranceQuoteEmailBatch implements Database.Batchable<SObject>, Database.Stateful {
	public String strQuery = '';

	/** All Final Variables */
	public static final String QUEUED_STATE = 'Queued';
	public static final String PROCESSED_STATE = 'Processed';
	public static final String PRM_PAYROLL_ADMIN = 'Primary Payroll Admin';
	public static final String PAYROLL_ADMIN = 'Payroll Admin';
	public static final String EMAIL_SUBJECT = 'Your Custom Medical Insurance Quote from Gusto';

	/*** All set variables ***/
	public Set<String> set_OpportunityIds;
	public Set<String> set_AccountIds;

	/*** All List List Variables ***/
	public List<EmailTemplate> list_EmailTemplates;

	/*** All Map Variables ***/
	public Map<String, EmailMessage> map_OpportunityIdToEmailMessage;
	public Map<String, Task> map_AccountIdEmailTask;
	public Map<String, String> map_AccountIdToPrimaryPayrollContact;
	public Map<String, String> map_AccountIdToPayrollContact;
	public Map<String, String> map_AccountIdToPrimaryPayrollContactName;
	public Map<String, String> map_AccountIdToPayrollContactName;

	public InsuranceQuoteEmailBatch() {
		set_OpportunityIds = new Set<String>();
		set_AccountIds = new Set<String>();
		map_OpportunityIdToEmailMessage = new Map<String, EmailMessage>();
		map_AccountIdEmailTask = new Map<String, Task>();
		map_AccountIdToPrimaryPayrollContact = new Map<String, String>();
		map_AccountIdToPayrollContact = new Map<String, String>();
		map_AccountIdToPrimaryPayrollContactName = new Map<String, String>();
		map_AccountIdToPayrollContactName = new Map<String, String>();

		list_EmailTemplates = [SELECT Id, Name, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :Label.HI_QuoteEmailTemplate];
	}

	public Database.QueryLocator start(Database.BatchableContext objBC) {
		//Fetch InsuranceQuotes
		if (String.isBlank(strQuery)) {
			strQuery = 'SELECT Id, Quote_Link__c, Account__c, Opportunity__c, Date_Quote_Sent__c, Status__c, Sales_Rep__c, Sales_Rep__r.FirstName, Sales_Rep__r.Name, Sales_Rep__r.Email, Sales_Rep__r.agentsync__NPN__c FROM Insurance_Quote__c ';
			strQuery += 'WHERE Processing_State__c =: QUEUED_STATE ';
			strQuery += 'AND Sales_Rep__c != null AND Date_Quote_Sent__c = null AND Account__c != null';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext objBC, List<Insurance_Quote__c> list_InsuranceQuotes) {
		processInsuranceQuotes(list_InsuranceQuotes);
	}

	public void Finish(Database.BatchableContext objBC) {
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Iterates over Insurance Quotes to send Email
	 * @Parm        : list_InsuranceQuotes - List of InsuranceQuotes
	 * @Return      : NA
	 **/
	public void processInsuranceQuotes(List<Insurance_Quote__c> list_InsuranceQuotes) {
		List<Messaging.SingleEmailMessage> list_EmailMessages = new List<Messaging.SingleEmailMessage>();
		List<Insurance_Quote__c> list_InsuranceQuotesToUpdateDate = new List<Insurance_Quote__c>();
		List<Insurance_Quote__c> list_InsuranceQuotesToUpdateError = new List<Insurance_Quote__c>();
		String strContactName = '';
		if (!list_InsuranceQuotes.isEmpty()) {
			for (Insurance_Quote__c objInsuranceQuote : list_insuranceQuotes) {
				set_AccountIds.add(String.valueOf(objInsuranceQuote.Account__c).substring(0, 15));
			}
		}
		setCollections();
		for (Insurance_Quote__c objInsuranceQuote : list_insuranceQuotes) {
			List<Contact> list_taskContacts = new List<Contact>();
			List<Contact> list_emailMessageContacts = new List<Contact>();
			Boolean blnCheckContact = false;
			String strTargetId;
			String strOpptyId = objInsuranceQuote.Opportunity__c != null ? String.valueOf(objInsuranceQuote.Opportunity__c).substring(0, 15) : '';
			String strAcctId = objInsuranceQuote.Account__c != null ? String.valueOf(objInsuranceQuote.Account__c).substring(0, 15) : '';
			Messaging.SingleEmailMessage objSingleEmailMessage = new Messaging.SingleEmailMessage();
			objSingleEmailMessage.setTreatTargetObjectAsRecipient(true);

			List<OrgWideEmailAddress> list_OrgWideEmail = GlobalQueryHelper.getOrgWideEmailByAdd('no-reply@gusto.com');

			if (objInsuranceQuote.Account__c != null) {
				if (map_AccountIdEmailTask.containsKey(strAcctId)) {
					if (map_AccountIdEmailTask.get(strAcctId).WhoId != null) {
						list_taskContacts = queryContact(map_AccountIdEmailTask.get(strAcctId).WhoId);
					} else {
						List<EmailMessage> list_emails = queryEmailMessage(map_AccountIdEmailTask.get(strAcctId).Id);
						if (list_emails?.size() > 0) {
							list_emailMessageContacts = queryContactEmail(list_emails[0].ToAddress);
						}
					}
				} else {
					blnCheckContact = true;
				}
			}

			if (!list_taskContacts.isEmpty()) {
				strTargetId = list_taskContacts[0].Id;
				strContactName = list_taskContacts[0].Name;
			} else if (!list_emailMessageContacts.isEmpty()) {
				strTargetId = list_emailMessageContacts[0].Id;
				strContactName = list_emailMessageContacts[0].Name;
			} else {
				blnCheckContact = true;
			}

			if (blnCheckContact) {
				if (objInsuranceQuote.Account__c != null && String.isNotBlank(strAcctId)) {
					if (map_AccountIdToPrimaryPayrollContact.containsKey(strAcctId)) {
						strTargetId = map_AccountIdToPrimaryPayrollContact.get(strAcctId);
						strContactName = map_AccountIdToPrimaryPayrollContactName.get(strAcctId);
					} else if (map_AccountIdToPayrollContact.containsKey(strAcctId)) {
						strTargetId = map_AccountIdToPayrollContact.get(strAcctId);
						strContactName = map_AccountIdToPayrollContactName.get(strAcctId);
					}
				}
			}

			//To save the email under activities
			objSingleEmailMessage.setSaveAsActivity(true);

			//Setting the WhatId to OpportunityId so the email appears on Opportunity record
			if (objInsuranceQuote.Opportunity__c != null && String.isNotBlank(strOpptyId)) {
				objSingleEmailMessage.setWhatId(strOpptyId);
			} else if (objInsuranceQuote.Account__c != null && String.isNotBlank(strAcctId)) {
				objSingleEmailMessage.setWhatId(strAcctId);
			}
			//Setting custom email template
			String strTempHTML;
			if (!list_EmailTemplates.isEmpty()) {
				objSingleEmailMessage.setTemplateId(list_EmailTemplates[0].Id);
				strTempHTML = list_EmailTemplates[0].HtmlValue;
				if (!Test.isRunningTest()) {
					strTempHTML = strTempHTML.replace('{!Insurance_Quote__c.Sales_Rep__r.FirstName}', objInsuranceQuote.Sales_Rep__r.FirstName);
				}
				if (!Test.isRunningTest()) {
					strTempHTML = strTempHTML.replace('{!User.Name}', objInsuranceQuote.Sales_Rep__r.Name);
				}

				if (objInsuranceQuote.Sales_Rep__r.agentsync__NPN__c != null) {
					strTempHTML = strTempHTML.replace('{!User.agentsync__NPN__c}', objInsuranceQuote.Sales_Rep__r.agentsync__NPN__c);
				} else {
					strTempHTML = strTempHTML.replace('{!User.agentsync__NPN__c}', '');
				}
				if (!String.isBlank(strContactName)) {
					strTempHTML = strTempHTML.replace('{!Contact.FirstName}', strContactName);
				} else {
					strTempHTML = strTempHTML.replace('{!Contact.FirstName}', '');
				}

				if (objInsuranceQuote.Quote_Link__c != null) {
					strTempHTML = strTempHTML.replace('{!Quote_Link__c}', objInsuranceQuote.Quote_Link__c);
				}

				if (String.isNotBlank(objInsuranceQuote.Sales_Rep__r.Email)) {
					strTempHTML = strTempHTML.replace('{!User.Email}', objInsuranceQuote.Sales_Rep__r.Email);
				}

				objSingleEmailMessage.setHtmlBody(strTempHTML);
			}

			objSingleEmailMessage.setSubject(EMAIL_SUBJECT);
			//objSingleEmailMessage.setSenderDisplayName(objInsuranceQuote.Sales_Rep__r.Name);
			objSingleEmailMessage.setOrgWideEmailAddressId(list_OrgWideEmail[0].Id);
			//objSingleEmailMessage.setReplyTo(objInsuranceQuote.Sales_Rep__r.Email);

			if (String.isNotBlank(strTargetId)) {
				objSingleEmailMessage.setTargetObjectId(strTargetId);
				list_InsuranceQuotesToUpdateDate.add(objInsuranceQuote);
				list_EmailMessages.add(objSingleEmailMessage);
			} else {
				list_InsuranceQuotesToUpdateError.add(objInsuranceQuote);
			}
		}
		try {
			if (list_InsuranceQuotesToUpdateError != null && list_InsuranceQuotesToUpdateError.size() > 0) {
				updateInsuranceQuoteError(list_InsuranceQuotesToUpdateError);
			}
			if (list_EmailMessages != null && list_EmailMessages.size() > 0) {
				Messaging.SendEmailResult[] list_SingleEmailResults = Messaging.sendEmail(list_EmailMessages);
			}
			if (list_InsuranceQuotesToUpdateDate != null && list_InsuranceQuotesToUpdateDate.size() > 0) {
				updateInsuranceQuoteDate(list_InsuranceQuotesToUpdateDate);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('InsuranceQuoteTriggerHelper', 'processEmailMessage', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Populates the collections to be used in creating email message
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	public void setCollections() {
		if (set_AccountIds?.size() > 0) {
			for (Task objTask : queryAcccountTasks(set_AccountIds)) {
				String strAcountId = String.valueOf(objTask.AccountId).substring(0, 15);
				if (map_AccountIdEmailTask.containsKey(strAcountId)) {
					if (objTask.CreatedDate > map_AccountIdEmailTask.get(strAcountId).CreatedDate) {
						map_AccountIdEmailTask.put(strAcountId, objTask);
					}
				} else {
					map_AccountIdEmailTask.put(strAcountId, objTask);
				}
			}
		}

		if (set_AccountIds?.size() > 0) {
			for (Contact objContact : queryAccountContacts(set_AccountIds)) {
				String strAccountId = String.valueOf(objContact.AccountId).substring(0, 15);
				Set<String> set_Roles = new Set<String>();
				if (String.isNotBlank(objContact.ZP_User_Role__c)) {
					for (String strRoleName : objContact.ZP_User_Role__c.split(';')) {
						set_Roles.add(strRoleName);
					}
				}
				if (String.isNotBlank(objContact.ZP_User_Role__c) && set_Roles.contains(PRM_PAYROLL_ADMIN)) {
					map_AccountIdToPrimaryPayrollContact.put(strAccountId, objContact.Id);
					map_AccountIdToPrimaryPayrollContactName.put(strAccountId, objContact.Name);
				} else if (String.isNotBlank(objContact.ZP_User_Role__c) && set_Roles.contains(PAYROLL_ADMIN)) {
					map_AccountIdToPayrollContact.put(strAccountId, objContact.Id);
					map_AccountIdToPayrollContactName.put(strAccountId, objContact.Name);
				}
			}
		}
	}

	public List<Task> queryAcccountTasks(Set<String> set_AccountIds) {
		String strSubjectName = 'Email: ' + Label.HI_QuoteEmailSubject;
		return [SELECT Id, AccountId, WhoId, CreatedDate FROM Task WHERE AccountId IN :set_AccountIds AND Subject = :strSubjectName];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Contacts based on Email Id
	 * @Parm        : Id of Contact
	 * @Return      : List of Contacts
	 **/
	public List<Contact> queryContact(String strContactId) {
		return [SELECT Id, Name, Email FROM Contact WHERE Id = :strContactId];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Contacts based on Email Id
	 * @Parm        : Email Id of Contact
	 * @Return      : List of Contacts
	 **/
	public List<Contact> queryContactEmail(String strEmail) {
		return [SELECT Id, Name, Email FROM Contact WHERE Email = :strEmail];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries EmailMessages based on Activity Id
	 * @Parm        : ActivityId
	 * @Return      : List of EmailMessages
	 **/
	public List<EmailMessage> queryEmailMessage(String strActivityId) {
		return [SELECT Id, Subject, ToAddress, RelatedToId, ActivityId FROM EmailMessage WHERE ActivityId = :strActivityId];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Contact Records based on Account Ids
	 * @Parm        : set_AccountIds - Set of Account Ids
	 * @Return      : List of Contacts
	 **/
	public List<Contact> queryAccountContacts(Set<String> set_AccountIds) {
		return [SELECT Id, AccountId, Name, ZP_User_Role__c FROM Contact WHERE AccountId IN :set_AccountIds];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Update Date Quote Sent Field on Insurance Quote
	 * @Parm        : list_InsuranceQuoteIds - List of Insurance Quotes
	 * @Return      : N/A
	 **/
	private void updateInsuranceQuoteDate(List<Insurance_Quote__c> list_InsuranceQuotes) {
		List<Insurance_Quote__c> list_InsuranceQuotesToUpdate = new List<Insurance_Quote__c>();

		for (Insurance_Quote__c objInsuranceQuote : list_InsuranceQuotes) {
			objInsuranceQuote.Date_Quote_Sent__c = System.now();
			objInsuranceQuote.Processing_State__c = PROCESSED_STATE;
			list_InsuranceQuotesToUpdate.add(objInsuranceQuote);
		}

		if (list_InsuranceQuotesToUpdate != null && list_InsuranceQuotesToUpdate.size() > 0) {
			update list_InsuranceQuotesToUpdate;
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Update Error Field on Insurance Quote
	 * @Parm        : list_InsuranceQuoteIds - List of Insurance Quotes
	 * @Return      : N/A
	 **/
	private void updateInsuranceQuoteError(List<Insurance_Quote__c> list_InsuranceQuotes) {
		List<Insurance_Quote__c> list_InsuranceQuotesToUpdate = new List<Insurance_Quote__c>();

		for (Insurance_Quote__c objInsuranceQuote : list_InsuranceQuotes) {
			objInsuranceQuote.Error_Text__c = 'No contact found to send email';
			list_InsuranceQuotesToUpdate.add(objInsuranceQuote);
		}

		if (list_InsuranceQuotesToUpdate != null && list_InsuranceQuotesToUpdate.size() > 0) {
			update list_InsuranceQuotesToUpdate;
		}
	}
}