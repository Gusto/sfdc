/**
 * @name         TaxResAutomatedCustomerCommBatch
 * @author       Anand Singh
 * @Date         20th July 2021
 * @description  This class handles the TaxRes Customer Communication on after every 7 days
 * @test class   TaxResAutomatedCustomerCommBatchTest.cls
 **/
public class TaxResAutomatedCustomerCommBatch implements Database.Batchable<sObject> {
	static Date dtToday = Date.today();
	static String CASE_STATUS_SOLVED = 'Solved';
	static String CASE_STATUS_CLOSED = 'Closed';
	static String EMAIL_TEMPLATE_NAME = 'Automated_E_Mail_to_Customer';
	static String CASE_RECORD_TYPE_ID = Cache.getRecordTypeId('Case', 'Tax Res');
	static Set<String> set_ExcludeCase = new Set<String>{ CASE_STATUS_SOLVED, CASE_STATUS_CLOSED };
	static String METADATA_FEATURE = 'Feature';
	static String METADATA_AUTOMATEEMAIL = 'Tax_Res_Automate_Customer_Email';
	static String EMAILTEMPLATE_FOLDER_NAME = 'Tax Res';
	static String NO_REPLY_EMAIL = 'no-reply@gusto.com';
	static Boolean blnAutomateEmail = false;
	static Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_FeatureConfigurationsTemp = getQueryConfigurationRecords(METADATA_FEATURE);

	/**
	 * @Author      : Anand Singh
	 * @Description : Start metod of Batch
	 * @Parm        : Object of BatchableContext.
	 * @Return      : List of Cases
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strQuery = '';
		String strSent = '3'; // Code for Sent Status
		if (map_FeatureConfigurationsTemp?.size() > 0) {
			if (map_FeatureConfigurationsTemp.containsKey(METADATA_AUTOMATEEMAIL)) {
				strQuery = map_FeatureConfigurationsTemp.get(METADATA_AUTOMATEEMAIL).Filter_Value__c;
			}
		}

		return Database.getQueryLocator(strQuery);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Execute metod of Batch
	 * @Parm        : Object of BatchableContex and list of Cases
	 * @Return      : NA
	 **/
	public void execute(Database.BatchableContext BC, List<Case> list_Cases) {
		TaxResAutomatedCustomerCommBatch.processCustomerCommunication(list_Cases);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Finish metod of Batch
	 * @Parm        : Object of BatchableContex
	 * @Return      : NA
	 **/
	public void finish(Database.BatchableContext BC) {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Method to get Case based on filter criteria to send an email
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public static void processCustomerCommunication(List<Case> list_TempCases) {
		blnAutomateEmail = false;
		if (map_FeatureConfigurationsTemp?.size() > 0) {
			if (map_FeatureConfigurationsTemp.containsKey(METADATA_AUTOMATEEMAIL)) {
				blnAutomateEmail = map_FeatureConfigurationsTemp.get(METADATA_AUTOMATEEMAIL).Active__c;
			}
		}

		if (Test.isRunningTest()) {
			blnAutomateEmail = true;
		}

		Date dtToday = Date.today();
		List<Case> list_FinalCases = new List<Case>();
		if (list_TempCases?.size() > 0) {
			for (Case objCase : list_TempCases) {
				List<EmailMessage> list_EmailMessages = objCase.EmailMessages;
				if (list_EmailMessages.size() == 0) {
					list_FinalCases.add(objCase);
				} else {
					if (list_EmailMessages.size() > 0) {
						Date dtMessageDate = list_EmailMessages[0].messageDate.Date();
						if (dtMessageDate.daysBetween(dtToday) == 7) {
							list_FinalCases.add(objCase);
						}
					}
				}
			}

			if (list_FinalCases?.size() > 0) {
				if (blnAutomateEmail) {
					TaxResAutomatedCustomerCommBatch.sendEmail(list_FinalCases);
				}
			}
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Send email to customer
	 * @Parm        : List of case
	 * @Return      : void
	 **/
	private static void sendEmail(List<Case> list_CasesTemp) {
		//Get Email Template
		List<EmailTemplate> list_EmailTemplates = [
			SELECT Id
			FROM EmailTemplate
			WHERE DeveloperName = :EMAIL_TEMPLATE_NAME AND Folder.Name = :EMAILTEMPLATE_FOLDER_NAME
			LIMIT 1
		];

		List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();
		if (list_EmailTemplates?.size() > 0) {
			List<OrgWideEmailAddress> list_OrgWideEmails = GlobalQueryHelper.getOrgWideEmailByAdd(NO_REPLY_EMAIL);
			for (Case objCase : list_CasesTemp) {
				Messaging.SingleEmailMessage objEmail = new Messaging.SingleEmailMessage();
				objEmail.setTemplateId(list_EmailTemplates[0].Id);
				objEmail.setTargetObjectId(objCase.ContactId);
				objEmail.setWhatId(objCase.Id);
				objEmail.setSaveAsActivity(true);
				if (list_OrgWideEmails?.size() > 0) {
					objEmail.setOrgWideEmailAddressId(list_OrgWideEmails[0].Id);
				}
				list_Emails.add(objEmail);
			}
		}

		skipTrigger(true);
		if (!Test.isRunningTest()) {
			Messaging.SendEmailResult[] results = Messaging.sendEmail(list_Emails, false);
		}
		skipTrigger(false);
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : get Feature value from Metadata
	 * @Parm        : String Team Name.
	 * @Return      : Map of Meta data records.
	 **/
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> getQueryConfigurationRecords(String strTeamName) {
		Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_FeatureConfigurationsTemp = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
		for (Tax_Res_Play_Mode_Configuration__mdt objConfig : [
			SELECT Id, Active__c, Filter_Value__c, DeveloperName
			FROM Tax_Res_Play_Mode_Configuration__mdt
			WHERE Team__c = :strTeamName
		]) {
			map_FeatureConfigurationsTemp.put(objConfig.DeveloperName, objConfig);
		}

		return map_FeatureConfigurationsTemp;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		AccountTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		TriggerTaskDispatchClass.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
	}
}