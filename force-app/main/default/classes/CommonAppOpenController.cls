/**
 * @description  This class is used as a controller for commonHippo and commonGdrive headless lwc
 * to be used as quick action button on multiple objects to open company in hippo/gdrive
 * @author       Aviinandaan Dutta
 * @date         03-29-2023
 * @see          CommonAppOpenControllerTest
 * BSS-1113
 **/
public with sharing class CommonAppOpenController {
	public static final String DEV = 'Dev';
	public static final String PROD = 'Prod';
	public static final String HIPPO = 'Hippo';
	public static final String GDRIVE = 'Gdrive';
	public static final String BENEFITS_NEW_PLAN = 'Benefits New Plan';
	public static final String BENEFITS_CHANGE = 'Benefits Change';
	public static final String BENEFITS_RENEWAL = 'Benefits Renewal';
	public static final String QA_SHEET = 'qa_sheet';
	public static final String NEW_PLANS_APPLICATIONS = 'new_plans_applications';
	public static final String BENEFITS_CHANGE_APPLICATIONS = 'benefit_change_applications';
	public static final String RENEWALS = 'renewals';

	/**
	 * @description When invoked from lwc, returns a wrapper response containing status and url if success based on record id
	 * @date        03-29-2023
	 * @param       idRecord - Id of record triggering record. Polymorphic (Benfit Order,Carrier Order, Opportunity, etc.),
	 *              strApp - App in context (Hippo/Gdrive) BSS-1139
	 * @return      ResultWrapper
	 **/
	@AuraEnabled
	public static ResultWrapper getUrl(Id idRecord, String strApp, String strPage) {
		// return null if idRecord is null
		if (idRecord == null) {
			return null;
		}
		try {
			// HYPERLINK("https://hippo.gusto.com/companies/" & ", "QA Sheet")
			//Get hippo/Gdrive url based on current environment and return failure if not configured
			String strAppUrl = new ElevatedContext().getAppUrl(strApp);
			if (String.isBlank(strAppUrl)) {
				return new ResultWrapper(false, strApp + ' url has not yet been configured for this environment. Please contact your Salesforce admin!', null);
			}
			//Based on triggering object type, query respective records and get company Id
			String strCompanyId;
			String strQASheetLink;
			String strApplicationId;
			if (idRecord.getSobjectType() == Schema.Benefit_Order__c.getSobjectType()) {
				strCompanyId = new ElevatedContext().getCompanyIdBenfitOrder(idRecord);
			}
			if (idRecord.getSobjectType() == Schema.Carrier_Order__c.getSobjectType()) {
				strCompanyId = new ElevatedContext().getCompanyIdCarrierOrder(idRecord);
			}
			if (idRecord.getSobjectType() == Schema.Opportunity.getSobjectType() && strPage != QA_SHEET) {
				strCompanyId = new ElevatedContext().getCompanyIdOpportunity(idRecord);
			}
			if (idRecord.getSobjectType() == Schema.Opportunity.getSobjectType() && strPage == QA_SHEET) {
				Opportunity objOpportunity = new ElevatedContext().getQASheetOpportunity(idRecord);
				strCompanyId = objOpportunity != null && objOpportunity.AccountId != null && String.isNotBlank(objOpportunity.Account.ZP_Company_ID__c) ? objOpportunity.Account.ZP_Company_ID__c : '';
				strApplicationId = objOpportunity != null && String.isNotBlank(objOpportunity.Account.ZP_Company_ID__c) ? objOpportunity.Application_Id__c : '';
				String strApplicationType = getApplicationType(objOpportunity?.RecordType?.Name);
				strQASheetLink = strCompanyId + strApplicationType + strApplicationId + '/' + QA_SHEET;
			}
			//If company Id is blank return failure, else form url and return success
			if (String.isBlank(strCompanyId)) {
				return new ResultWrapper(false, 'Company Id not found', null);
			}
			if (String.isBlank(strApplicationId) && strPage == QA_SHEET) {
				return new ResultWrapper(false, 'Application Id not found', null);
			} else {
				if (strApp == HIPPO && strPage != QA_SHEET) {
					return new ResultWrapper(true, null, strAppUrl + '/companies/' + strCompanyId);
				} else if (strApp == HIPPO && strPage == QA_SHEET) {
					return new ResultWrapper(true, null, strAppUrl + '/companies/' + strQASheetLink);
				} else if (strApp == GDRIVE) {
					return new ResultWrapper(true, null, strAppUrl + '?q=' + strCompanyId);
				} else {
					return new ResultWrapper(false, 'App not configured', '');
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CommonAppOpenController', 'getUrl', idRecord, ex);
			return new ResultWrapper(false, 'Error in CommonAppOpenController', '');
		}
	}

	/**
	 * @description  wrapper inner class to return response
	 * @date         03-29-2023
	 **/
	public class ResultWrapper {
		@AuraEnabled
		public Boolean blnSuccess;
		@AuraEnabled
		public String strMessage;
		@AuraEnabled
		public String strUrl;

		public ResultWrapper(Boolean blnSuccess, String strMessage, String strUrl) {
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.strUrl = strUrl;
		}
	}

	/**
	 * @description  private inner class to query records with elevated privileges
	 * @date         03-29-2023
	 **/
	private without sharing class ElevatedContext {
		/**
		 * @description Queries and returns app url based on current environment
		 * @date        03-29-2023
		 * @param       strApp - Triggering app in context
		 * @return      String app url
		 **/
		public String getAppUrl(String strApp) {
			String strUrl;
			String strCurrentEnvironment = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox ? DEV : PROD;
			List<App_URL_Map__c> list_appUrlMap = [SELECT Id, URL__c FROM App_URL_Map__c WHERE App_Name__c = :strApp AND Environment__c = :strCurrentEnvironment];
			if (!list_appUrlMap?.isEmpty()) {
				strUrl = list_appUrlMap.get(0).URL__c;
			}
			return strUrl;
		}

		/**
		 * @description Queries and returns company id from benefit order record
		 * @date        03-29-2023
		 * @param       idRecord Id of triggering benefit order record
		 * @return      String CompanyId
		 **/
		public String getCompanyIdBenfitOrder(Id idRecord) {
			// return null if idRecord is null
			if (idRecord == null) {
				return null;
			}
			String strCompanyId;
			List<Benefit_Order__c> list_BenefitOrder = [SELECT Id, ZP_Company_ID__c FROM Benefit_Order__c WHERE Id = :idRecord AND ZP_Company_ID__c != NULL];
			if (!list_BenefitOrder.isEmpty()) {
				Benefit_Order__c objBenefitOrder = list_BenefitOrder.get(0);
				strCompanyId = objBenefitOrder != null && String.isNotBlank(objBenefitOrder.ZP_Company_ID__c) ? objBenefitOrder.ZP_Company_ID__c : strCompanyId;
			}
			return strCompanyId;
		}

		/**
		 * @description Queries and returns company id from carrier order record
		 * @date        03-29-2023
		 * @param       idRecord Id of triggering carrier order record
		 * @return      String CompanyId
		 **/
		public String getCompanyIdCarrierOrder(Id idRecord) {
			// return null if idRecord is null
			if (idRecord == null) {
				return null;
			}
			String strCompanyId;
			List<Carrier_Order__c> list_CarrierOrder = [SELECT Id, ZP_Company_ID__c FROM Carrier_Order__c WHERE Id = :idRecord AND ZP_Company_ID__c != NULL];
			if (!list_CarrierOrder.isEmpty()) {
				Carrier_Order__c objCarrierOrder = list_CarrierOrder.get(0);
				strCompanyId = objCarrierOrder != null && String.isNotBlank(objCarrierOrder.ZP_Company_ID__c) ? objCarrierOrder.ZP_Company_ID__c : strCompanyId;
			}
			return strCompanyId;
		}

		/**
		 * @description Queries and returns company id from opportunity record
		 * @date        03-29-2023
		 * @param       idRecord Id of triggering opportunity record
		 * @return      String CompanyId
		 **/
		public String getCompanyIdOpportunity(Id idRecord) {
			// return null if idRecord is null
			if (idRecord == null) {
				return null;
			}
			String strCompanyId;
			List<Opportunity> list_Opportunity = [SELECT Id, Account.ZP_Company_ID__c FROM Opportunity WHERE Id = :idRecord AND AccountId != NULL AND Account.ZP_Company_ID__c != NULL];
			if (!list_Opportunity.isEmpty()) {
				Opportunity objOpportunity = list_Opportunity.get(0);
				strCompanyId = objOpportunity != null &&
					objOpportunity.AccountId != null &&
					String.isNotBlank(objOpportunity.Account.ZP_Company_ID__c)
					? objOpportunity.Account.ZP_Company_ID__c
					: strCompanyId;
			}
			return strCompanyId;
		}

		/**
		 * @description Queries and returns company id from opportunity record
		 * @date        09-05-2023
		 * @param       idRecord Id of triggering opportunity record
		 * @return      String QA Sheet Url
		 **/
		public Opportunity getQASheetOpportunity(Id idRecord) {
			// return null if idRecord is null
			if (idRecord == null) {
				return null;
			}
			Opportunity objOpportunity;
			List<Opportunity> list_Opportunity = [SELECT Id, Account.ZP_Company_ID__c, Application_Id__c, RecordType.Name FROM Opportunity WHERE Id = :idRecord AND AccountId != NULL];
			if (!list_Opportunity.isEmpty()) {
				objOpportunity = list_Opportunity.get(0);
			}
			return objOpportunity;
		}
	}

	/**
	 * @description get application type value based of opportunity record type value
	 * @date        09-05-2023
	 * @param       Record Type Name
	 * @return      String Application type value
	 **/
	public static String getApplicationType(String strRecordTypeName) {
		String strApplicationTypeURL = '';
		if (strRecordTypeName == BENEFITS_NEW_PLAN) {
			strApplicationTypeURL = '/' + NEW_PLANS_APPLICATIONS + '/';
		} else if (strRecordTypeName == BENEFITS_CHANGE) {
			strApplicationTypeURL = '/' + BENEFITS_CHANGE_APPLICATIONS + '/';
		} else if (strRecordTypeName == BENEFITS_RENEWAL) {
			strApplicationTypeURL = '/' + RENEWALS + '/';
		}
		return strApplicationTypeURL;
	}
}