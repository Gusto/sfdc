/**
 * @description  used to open company or accounting firm in panda or hippo
 * @author       Praveen Sethu
 * @date         07-25-2022
 * @see          OpenAccountControllerTest
 **/
public without sharing class OpenAccountController {
	// app names
	public final static String APP_NAME_PANDA = 'Panda';
	public final static String APP_NAME_HIPPO = 'Hippo';

	// environment names
	public final static String ENV_DEV = 'Dev';
	public final static String ENV_PROD = 'Prod';

	// object names
	public final static String OBJECT_NAME_ACCOUNT = 'Account';
	public final static String OBJECT_NAME_OPPORTUNITY = 'Opportunity';
	public final static String OBJECT_NAME_LEAD = 'Lead';
	public final static String OBJECT_NAME_ORDER = 'Order';

	// account types
	public final static String ACCOUNT_TYPE_COMPANY = 'Company';
	public final static String ACCOUNT_TYPE_RESELLER = 'Reseller';

	/**
	 * @description  wrapper object that is shared as response back to LWC
	 * @author       Praveen Sethu
	 * @date         07-25-2022
	 * @see          OpenAccountControllerTest
	 **/
	public class OpenAccountWrapper {
		@AuraEnabled
		public Boolean blnSuccess;

		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public String strAccountURL;

		public OpenAccountWrapper(Boolean blnSuccess, String strMessage, String strAccountURL) {
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.strAccountURL = strAccountURL;
		}
	}

	/**
	 * @description Returns a wrapper response containing page url to be opened
	 * @author      Praveen Sethu
	 * @param       idRecord - Can be any record (Lead or Account or Opportunity)
	 * @return      OpenAccountWrapper
	 **/
	@AuraEnabled
	public static OpenAccountWrapper getAccountExternalURL(Id idRecord, String strAppName) {
		String strAccountURL = '';
		String strCompanyId = '';
		String strAccountingFirmId = '';
		String strAccountType = '';
		try {
			String strObjectType = String.valueOf(idRecord.getSobjectType());

			if (strObjectType.equalsIgnoreCase(OBJECT_NAME_ACCOUNT)) {
				// Query company or reseller account
				Account objAcc = [SELECT Id, RecordTypeId, ZP_Firm_Id__c, ZP_Company_Id__c FROM Account WHERE Id = :idRecord];
				// set company and accounting firm ids
				strCompanyId = objAcc.ZP_Company_Id__c;
				strAccountingFirmId = objAcc.ZP_Firm_Id__c;

				if (objAcc.RecordTypeId == Cache.getRecordTypeId('Account', 'Company')) {
					strAccountType = ACCOUNT_TYPE_COMPANY;
				} else if (objAcc.RecordTypeId == Cache.getRecordTypeId('Account', 'Reseller')) {
					strAccountType = ACCOUNT_TYPE_RESELLER;
				}
			} else if (strObjectType.equalsIgnoreCase(OBJECT_NAME_OPPORTUNITY)) {
				// query company opportunity and set company id
				Opportunity objOppty = [SELECT Id, Account.ZP_Company_Id__c FROM Opportunity WHERE Id = :idRecord];
				strCompanyId = objOppty.Account.ZP_Company_Id__c;
				strAccountType = ACCOUNT_TYPE_COMPANY;
			} else if (strObjectType.equalsIgnoreCase(OBJECT_NAME_ORDER)) {
				// query company opportunity and set company id
				Order objOrder = [SELECT Id, Account.ZP_Company_Id__c FROM Order WHERE Id = :idRecord];
				strCompanyId = objOrder.Account.ZP_Company_Id__c;
				strAccountType = ACCOUNT_TYPE_COMPANY;
			} 
			else if (strObjectType.equalsIgnoreCase(OBJECT_NAME_LEAD)) {
				// query company or reseller lead
				Lead objLead = [SELECT Id, RecordTypeId, ZP_Firm_ID__c, ZP_Company_Id__c FROM Lead WHERE Id = :idRecord];
				// set company and accounting firm ids
				strCompanyId = objLead.ZP_Company_Id__c;
				strAccountingFirmId = objLead.ZP_Firm_ID__c;

				if (objLead.RecordTypeId == Cache.getRecordTypeId('Lead', 'Company')) {
					strAccountType = ACCOUNT_TYPE_COMPANY;
				} else if (objLead.RecordTypeId == Cache.getRecordTypeId('Lead', 'Reseller')) {
					strAccountType = ACCOUNT_TYPE_RESELLER;
				}
			}

			if (String.isBlank(strCompanyId) && String.isBlank(strAccountingFirmId)) {
				return new OpenAccountWrapper(false, 'No Company or Firm Id found on ' + strObjectType + ' record. Please try on different record.' , null);
			}

			// check if instance is sandbox or production
			Boolean blnSandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;

			// Create a new environment variable
			String strEnv = blnSandbox ? ENV_DEV : ENV_PROD;

			// query config record that stores app name and base urls
			List<App_URL_Map__c> list_AppURLs = [SELECT Id, URL__c FROM App_URL_Map__c WHERE App_Name__c = :strAppName AND Environment__c = :strEnv ORDER BY CreatedDate DESC LIMIT 1];

			// if no config is found, set error message
			if (list_AppURLs.isEmpty()) {
				return new OpenAccountWrapper(false, strAppName + ' URL has not yet been configured for ' + strEnv + ' environment. Please contact your Salesforce admin!', null);
			} else {
				// take first value from config list
				App_URL_Map__c objURLMap = list_AppURLs.get(0);

				if (strAppName == APP_NAME_PANDA) {
					if (strAccountType.equalsIgnoreCase(ACCOUNT_TYPE_COMPANY)) {
						return new OpenAccountWrapper(true, '', objURLMap.URL__c + '/panda/companies/' + strCompanyId);
					} else if (strAccountType.equalsIgnoreCase(ACCOUNT_TYPE_RESELLER)) {
						return new OpenAccountWrapper(true, '', objURLMap.URL__c + '/panda/accounting_firms/' + strAccountingFirmId);
					}
				} else if (strAppName == APP_NAME_HIPPO) {
					return new OpenAccountWrapper(true, '', objURLMap.URL__c + '/companies/' + strCompanyId);
				}
			}
			return new OpenAccountWrapper(true, '', strAccountURL);
		} catch (Exception objEx) {
			return new OpenAccountWrapper(false, 'Error in opening account. Reason - ' + objEx.getMessage(), null);
		}
	}
}