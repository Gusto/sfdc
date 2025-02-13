/**
 * @name         AccountTriggerBypassService
 * @author       Praveen Sethu
 * @description  REST service to bypass the Account trigger and update Account records
 * @test classes AccountTriggerBypassServiceTest
 **/
@RestResource(urlMapping='/TriggerBypass/Account/*')
global without sharing class AccountTriggerBypassService {
	/**
	 * @Description : Post method that accepts a JSON string from request body and updates the Account records
	 * @Parm        : NA
	 * @Return      : Object of TransactionResult
	 **/
	@HttpPost
	global static TransactionResult bypassAccountTrigger() {
		// Get data from rqeuest body
		RestRequest objRequest = RestContext.request;
		Blob objBlobBody = objRequest.requestBody;
		String strRequestBody = objBlobBody.toString();

		TransactionResult objResultToReturn = new TransactionResult();
		Database.SaveResult[] list_SaveResult = new List<Database.SaveResult>{};
		List<Account> list_updateAccounts = new List<Account>();

		try {
			// Deserialize data from JSON request
			TransactionRequest objTransactionRequest = (TransactionRequest) System.JSON.deserialize(strRequestBody, TransactionRequest.class);
			// Extract the skiptrigger field
			Boolean blnSkipTrigger = objTransactionRequest.skiptrigger;

			// Extract and process the list_Accounts field
			List<AccountData> list_AccountData = objTransactionRequest.list_Accounts;
			// Iterate through the accounts and update them
			for (AccountData objAccountData : list_AccountData) {
				Account objAcc = new Account(Id = objAccountData.Id);
				objAcc.Account_Rank__c = objAccountData.dblAccountRank;
				list_updateAccounts.add(objAcc);
			}
			// Update the accounts
			AccountTriggerHelper.skipTrigger = blnSkipTrigger;
			list_SaveResult = Database.update(list_updateAccounts, false);
		} catch (Exception e) {
			objResultToReturn.addErrors(e.getMessage());
			objResultToReturn.success = false;
		}

		// Iterate through the results
		for (Database.SaveResult sr : list_SaveResult) {
			if (!sr.isSuccess()) {
				// If the update failed, capture the Account ID in the erroredAccountIds list
				objResultToReturn.addFailedRecord(sr.getId());
				objResultToReturn.addErrors(sr.getErrors().get(0).getMessage());
			}
		}
		// Set the overall success status
		objResultToReturn.setSuccess(objResultToReturn.getFailedRecords().isEmpty());
		return objResultToReturn;
	}

	/**
	 * @name         TransactionResult
	 * @description  Object used to share data as REST response
	 **/
	global class TransactionResult {
		public Boolean success { get; set; }
		public List<Id> erroredRecordIds { get; set; }
		public List<String> listErrorMessages { get; set; }
		public TransactionResult() {
			success = true;
			erroredRecordIds = new List<Id>();
			listErrorMessages = new List<String>();
		}
		public void addFailedRecord(Id recordId) {
			erroredRecordIds.add(recordId);
		}
		public List<String> getFailedRecords() {
			return erroredRecordIds;
		}
		public void addErrors(String errorMessage) {
			listErrorMessages.add(errorMessage);
		}
		public void setSuccess(Boolean isSuccess) {
			success = isSuccess;
		}
	}

	/**
	 * @name         TransactionRequest
	 * @description  Object used to receive data as REST request
	 **/
	global class TransactionRequest {
		public Boolean skiptrigger;
		public List<AccountData> list_Accounts;
	}

	/**
	 * @name         AccountData
	 * @description  Object used to receive data as REST request
	 **/
	global class AccountData {
		public String Id;
		public Double dblAccountRank;
	}
}