/**
 * Author: Lakshey Mendiratta
 * Date: 9/17/2020
 * Desc: Controller for UserDetail LWC
 */
public without sharing class UserDetailsComponentController_LEX {
	//only set during apex testing
	public static Boolean blnFail = false;
	public static Boolean blnIsTaxResRingLeadUser = false;

	public class UserDetailsWrapper {
		@AuraEnabled
		public User objUser;

		@AuraEnabled
		public Boolean blnIsSuccess;

		@AuraEnabled
		public String strMessage;

		public UserDetailsWrapper(User objUser, Boolean blnIsSuccess, String strMessage) {
			this.objUser = objUser;
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
		}
	}

	@AuraEnabled
	public static UserDetailsWrapper getUserData() {
		try {
			User objUser = [SELECT Id, Out_Of_Office__c FROM User WHERE Id = :UserInfo.getUserId()];
			//throw exception on purpose
			if (blnFail) {
				Integer intZero = 0 / 0;
			}
			return new UserDetailsWrapper(objUser, true, null);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('UserDetailsComponentController_LEX', 'getUserData', objException.getMessage(), objException.getStackTraceString());
			return new UserDetailsWrapper(null, false, objException.getMessage());
		}
	}

	@AuraEnabled
	public static UserDetailsWrapper updateUser(Boolean blnIsUsrOutOfOffice) {
		try {
			User objUser = [SELECT Id, Out_Of_Office__c FROM User WHERE Id = :UserInfo.getUserId()];
			if (objUser.Out_Of_Office__c != blnIsUsrOutOfOffice) {
				objUser.Out_Of_Office__c = blnIsUsrOutOfOffice;
				update objUser;
			}

			//throw exception on purpose
			if (blnFail && Test.isRunningTest()) {
				Integer intZero = 0 / 0;
			}

			return new UserDetailsWrapper(objUser, true, null);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('UserDetailsComponentController_LEX', 'updateUser', objException.getMessage(), objException.getStackTraceString());
			return new UserDetailsWrapper(null, false, objException.getMessage());
		}
	}
}