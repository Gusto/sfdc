/**
 * @description  Used to open CHS related to parent Account of CS Opportunity
 * @author       Debasmita Rawooth
 * @date         03-11-2024
 * @see          OpenCustomerHealthScoreControllerTest
 **/
public without sharing class OpenCustomerHealthScoreController {
	/**
	 * @description Returns the CHS record id to be opened
	 * @author      Debasmita Rawooth
	 * @param       idRecord - (Opportunity Id)
	 * @return      Id
	 **/
	@AuraEnabled
	public static Id getCHSRecordId(Id idRecord) {
		Customer_Health__c objCHS = new Customer_Health__c();
		try {
			Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :idRecord AND AccountId != NULL];
			if (objOpp != null) {
				objCHS = [SELECT Id, Account__c, CreatedDate FROM Customer_Health__c WHERE Account__c = :objOpp.AccountId ORDER BY CreatedDate DESC LIMIT 1];
			}
		} catch (Exception objException) {
			String strErrorMsg = objException.getMessage();
			throw new AuraHandledException(strErrorMsg);
		}
		return objCHS.Id;
	}
}