/**
 * @name         : SendAccountQualtricsSurveyBatch
 * @author       : Debasmita Rawooth
 * @date         : 28-08-2023
 * @description  : Batch Class for sending qualtrics surveys to customers.
 * @test classes : SendAccountQualtricsSurveyBatchTest
 **/
public with sharing class SendAccountQualtricsSurveyBatch implements Database.Batchable<sObject>, Schedulable {
	public String strQuery = '';

	/** All Final Variables */
	public static final String PREMIUM_TIER = 'Premium';
	public static final String SUSPENDED_CUSTOMER_STATUS = 'Suspended Customer';
	public static final String SUSPENDED_SETUP_STATUS = 'Suspended In-Setup';
	public static final String PRM_PAYROLL_ADMIN = 'Primary Payroll Admin';

	/*** All set variables ***/
	public Set<String> set_AccountIds;

	/*** All List List Variables ***/
	List<Contact> list_Contacts;
	List<Account> list_AccountsToUpdate;
	List<String> list_EmailAddresses;
	public List<EmailTemplate> list_EmailTemplates;
	public static final List<String> SUSPENDED_STATUSES = new List<String>{ SUSPENDED_CUSTOMER_STATUS, SUSPENDED_SETUP_STATUS };

	/*** All Map Variables ***/
	public Map<String, Contact> map_AccountIdToPrimaryPayrollContact;

	public SendAccountQualtricsSurveyBatch() {
		set_AccountIds = new Set<String>();
		list_Contacts = new List<Contact>();
		list_AccountsToUpdate = new List<Account>();
		list_EmailAddresses = new List<String>();
		map_AccountIdToPrimaryPayrollContact = new Map<String, Contact>();

		list_EmailTemplates = [SELECT Id, Name, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :Label.CSM_QualtricsSurveyTemplate];
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		DateTime dtPremiumSetDate = System.now().adddays(-90);
		//Fetch Accounts
		if (String.isBlank(strQuery)) {
			strQuery = 'SELECT id, Name, Tier__c, Account_Status__c FROM Account ';
			strQuery += 'WHERE Tier__c IN (:PREMIUM_TIER) AND Account_Status__c NOT IN :SUSPENDED_STATUSES AND ((Last_Survey_Sent_Date__c  = NULL AND Current_Tier_Start_Date__c  != NULL AND Current_Tier_Start_Date__c < :dtPremiumSetDate) OR (Last_Survey_Sent_Date__c != NULL AND Last_Survey_Sent_Date__c < :dtPremiumSetDate))';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<sObject> list_Accounts) {
		processSurveyEmails(list_Accounts);
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		if (objAsyncJob.NumberOfErrors > 0) {
			Utils.processBatchFinish(objAsyncJob, '', false);
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Iterates over Premium Accounts to send survey email
	 * @Parm        : list_Accounts - List of Accounts
	 * @Return      : NA
	 **/
	private void processSurveyEmails(List<Account> list_Accounts) {
		List<Messaging.SingleEmailMessage> list_EmailMessages = new List<Messaging.SingleEmailMessage>();
		List<OrgWideEmailAddress> list_OrgWideEmails = GlobalQueryHelper.getOrgWideEmailByAdd('no-reply@gusto.com');

		for (Account objAccount : list_Accounts) {
			set_AccountIds.add(objAccount.Id);
		}

		if (set_AccountIds.size() > 0) {
			for (Contact objContact : queryAccountContacts(set_AccountIds)) {
				Set<String> set_Roles = new Set<String>();
				if (String.isNotBlank(objContact.ZP_User_Role__c)) {
					for (String strRoleName : objContact.ZP_User_Role__c.split(';')) {
						set_Roles.add(strRoleName);
					}
					if (set_Roles.contains(PRM_PAYROLL_ADMIN) && objContact.Email != '') {
						map_AccountIdToPrimaryPayrollContact.put(objContact.AccountId, objContact);
					}
				}
			}
		}

		for (Contact objContact : map_AccountIdToPrimaryPayrollContact.values()) {
			Messaging.SingleEmailMessage objSingleEmail = new Messaging.SingleEmailMessage();
			if (!list_EmailTemplates.isEmpty()) {
				objSingleEmail.setTemplateId(list_EmailTemplates[0].Id);
			}
			if (!list_OrgWideEmails.isEmpty()) {
				objSingleEmail.setOrgWideEmailAddressId(list_OrgWideEmails[0].Id);
			}
			objSingleEmail.setTargetObjectId(objContact.Id);
			objSingleEmail.setWhatId(objContact.AccountId);
			objSingleEmail.setSaveAsActivity(true);

			list_EmailMessages.add(objSingleEmail);
		}
		try {
			if (list_EmailMessages != null && list_EmailMessages.size() > 0) {
				Messaging.SendEmailResult[] list_SingleEmailResults = Messaging.sendEmail(list_EmailMessages);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('SendAccountQualtricsSurveyBatch', 'processEmailMessage', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
		// Update on Last_Survey_Sent_Date__c eligible Accounts after sending the survey
		if (list_Accounts.size() > 0) {
			updateAccounts(list_Accounts);
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Contact Records based on Account Ids
	 * @Parm        : set_AccountIds - Set of Account Ids
	 * @Return      : List of Contacts
	 **/
	private List<Contact> queryAccountContacts(Set<String> set_AccountIds) {
		return [SELECT Id, AccountId, Name, ZP_User_Role__c, Email FROM Contact WHERE AccountId IN :set_AccountIds AND Email != NULL];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Updates Last_Survey_Sent_Date__c on Accounts
	 * @Parm        : list_Account
	 * @Return      : NA
	 **/
	private void updateAccounts(List<Account> list_Accounts) {
		for (Account objAccount : list_Accounts) {
			objAccount.Last_Survey_Sent_Date__c = System.now();
			list_AccountsToUpdate.add(objAccount);
		}
		try {
			if (list_AccountsToUpdate.size() > 0) {
				update list_AccountsToUpdate;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('SendAccountQualtricsSurveyBatch', 'updateAccounts', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = objConfigSettings?.Batch_Size__c != null ? (Integer) objConfigSettings.Batch_Size__c : 20;

		Database.executeBatch(new SendAccountQualtricsSurveyBatch(), intBatch);
	}
}