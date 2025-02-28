/**
 * @description  Used for updating an account record
 * @author       Praveen Sethu
 * @see          UpdateAccountControllerTest
 **/
public without sharing class UpdateAccountController {
	/**
	 * @description  Response class to be used for returning the result of the update operation
	 * @author       Praveen Sethu
	 **/
	public class UpdateAccountResponse {
		@AuraEnabled
		public String strMessage;

		@AuraEnabled
		public Boolean blnSuccess;

		/**
		 * @description Custom constructor to initialize the response object
		 * @author      Praveen Sethu
		 * @param       String strMessage - The message to be returned
		 * @param       Boolean blnSuccess - The success flag
		 **/
		public UpdateAccountResponse(String strMessage, Boolean blnSuccess) {
			this.strMessage = strMessage;
			this.blnSuccess = blnSuccess;
		}
	}

	/**
	 * @description Method to update an account record
	 * @author      Praveen Sethu
	 * @param       Account - The account record to be updated
	 * @param       UpdateAccountResponse - The response object to be returned along with success or failure message
	 **/
	@AuraEnabled
	public static UpdateAccountResponse updateAccount(Account objAccount) {
		try {
			Account objAccQuery = [SELECT Id, RecordTypeId FROM Account WHERE Id = :objAccount.Id];
			// HI owner can be set only on Company Accounts
			if (objAccQuery.RecordTypeId != AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				return new UpdateAccountResponse('Only company accounts are eligible for routing HI Owner', false);
			}

			// HI owner cannot be re-routed if there is a closed won opportunity in the last 90 days
			Integer intCount = [
				SELECT COUNT()
				FROM Opportunity
				WHERE
					AccountId = :objAccount.Id
					AND RecordTypeId IN :OpportunityUtil.set_BenefitRTChangeEmployees
					AND Type != :OpportunityUtil.OPPTY_TYPE_RENEWAL_BYB
					AND IsWon = TRUE
					AND CloseDate = LAST_N_DAYS:90
			];
			if (intCount > 0) {
				return new UpdateAccountResponse('HI Owner cannot be re-routed because of Closed Won opportunity in the last 90 days', false);
			} else {
				update objAccount;
			}
			return new UpdateAccountResponse('Account updated successfully', true);
		} catch (Exception objEx) {
			return new UpdateAccountResponse(objEx.getMessage(), false);
		}
	}
}