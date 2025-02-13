/**
 * @description  Used to decide whether to show welcome mat content for Sales users
 * @author       Praveen Sethu
 * @date         07-28-2022
 * @see          WelcomeMatControllerTest
 **/
public without sharing class WelcomeMatController {
	public final static String SALES_LIGHTNING_SETTING = 'Sales Lightning';
	public final static String PT_LIGHTNING_SETTING = 'Payroll Transfers Lightning';

	/**
	 * @description  Wrapper response class shared with LWC
	 * @author       Praveen Sethu
	 * @date         07-28-2022
	 * @see          WelcomeMatControllerTest
	 **/
	public class WelcomeMatWrapper {
		@AuraEnabled
		public Boolean blnSuccess;

		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public Boolean blnIsSales;

		@AuraEnabled
		public Boolean blnIsPT;

		@AuraEnabled
		public Welcome_Mat_Config__c objConfig = new Welcome_Mat_Config__c();

		public WelcomeMatWrapper(Welcome_Mat_Config__c objConfig, Boolean blnSuccess, String strMessage, Boolean blnIsSales, Boolean blnIsPT) {
			this.objConfig = objConfig;
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.blnIsSales = blnIsSales;
			this.blnIsPT = blnIsPT;
		}
	}

	/**
	 * @description Queries logged in user record and checks whether user is eligible to see welcome mat
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      Wrapper response with boolean flag set to false or true
	 **/
	@AuraEnabled
	public static WelcomeMatWrapper showWelcomeMat(String strConfig) {
		// initialize variables
		Boolean blnUserUpdate = false;
		Boolean blnShowWelcomeMat = false;
		Boolean blnIsSales = false;
		Boolean blnIsPT = false;

		// welcome mat custom settings config
		Welcome_Mat_Config__c objConfig = Welcome_Mat_Config__c.getValues(strConfig);

		try {
			if (strConfig == SALES_LIGHTNING_SETTING) {
				blnIsSales = true;
			} else if (strConfig == PT_LIGHTNING_SETTING) {
				blnIsPT = true;
			}

			// query logged in user profile details
			User objUser = [SELECT Id, Welcome_Mat_Disabled__c, Welcome_Mat_Last_Seen_At__c, Welcome_Mat_Count__c FROM User WHERE Id = :UserInfo.getUserId()];

			// take visibility threshold from custom settings
			Integer intVisiblityThreshold = objConfig.Visibility_Threshold__c != null && objConfig.Visibility_Threshold__c > 0 ? Integer.valueOf(objConfig.Visibility_Threshold__c) : 3;
			Integer intUserWelcomeMatCount = objUser.Welcome_Mat_Count__c == null ? 0 : Integer.valueOf(objUser.Welcome_Mat_Count__c);

			// do not show if welcome mat is disabled for user or if the user already have seen welcome mat for three times
			if (objUser.Welcome_Mat_Disabled__c || intUserWelcomeMatCount >= intVisiblityThreshold) {
				return new WelcomeMatWrapper(objConfig, false, '', blnIsSales, blnIsPT);
			}

			// if user hasn't sales welcome yet, set last seen date as today and increase counter
			// if user saw sales welcome mat in the past, set last seen as today and show sales mat & increase counter
			if (objUser.Welcome_Mat_Last_Seen_At__c == null || objUser.Welcome_Mat_Last_Seen_At__c < Date.today()) {
				objUser.Welcome_Mat_Last_Seen_At__c = Date.today();
				intUserWelcomeMatCount = intUserWelcomeMatCount + 1;
				blnUserUpdate = true;
				blnShowWelcomeMat = true;
			}

			// update user record
			if (blnUserUpdate) {
				UserTriggerHelper.skipTrigger = true;
				objUser.Welcome_Mat_Count__c = intUserWelcomeMatCount;
				update objUser;
				UserTriggerHelper.skipTrigger = false;
			}

			// return response back to LWC
			return new WelcomeMatWrapper(objConfig, blnShowWelcomeMat, '', blnIsSales, blnIsPT);
		} catch (Exception objEx) {
			return new WelcomeMatWrapper(objConfig, false, objEx.getMessage(), false, false);
		}
	}

	/**
	 * @description Updates user preference to display welcome mat for Sales users
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      Boolean flag to indicate status of user update
	 **/
	@AuraEnabled
	public static Boolean updateWelcomeMatPreference(Boolean blnPreference) {
		try {
			// instantiate new user object with logged in user id
			User objUser = new User(Id = UserInfo.getUserId());
			// update preference flag
			objUser.Welcome_Mat_Disabled__c = blnPreference;

			UserTriggerHelper.skipTrigger = true;
			update objUser;
			UserTriggerHelper.skipTrigger = false;

			// return true if update is successful
			return true;
		} catch (Exception objEx) {
			// return false in case of exception
			return false; 
		}
	}
}