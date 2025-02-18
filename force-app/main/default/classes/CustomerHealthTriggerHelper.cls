/**
 * @name         : CustomerHealthTriggerHelper
 * @author       : David (Dato) Tsamalashvili
 * @date         : 02/12/2024
 * @description  : New CustomerHealthTriggerHelper Class
 * @see : CustomerHealthTriggerHelperTest
 **/
public class CustomerHealthTriggerHelper {
	// Static Variable used to Lead Skip Triggers
	public static Boolean skipTrigger = false;
	public static Set<String> set_CompanyIds;
	public static Map<String, Account> map_CompIdToAccount = new Map<String, Account>();
	public static Set<String> set_ChangedCompanyIds;
	public static Map<Id, Account> map_AccountsToUpdate;
	public static Map<Id, Opportunity> map_AccIdToOpportunity;

	// Constructor:
	public CustomerHealthTriggerHelper() {
		set_CompanyIds = new Set<String>();
		set_ChangedCompanyIds = new Set<String>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_AccIdToOpportunity = new Map<Id, Opportunity>();
	}

	//Before Insert functionality
	public void processBeforeInsert(List<Customer_Health__c> list_CustomHealth) {
		//collect data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			if (String.isNotBlank(objCustHealth.Company_Id__c)) {
				set_CompanyIds.add(objCustHealth.Company_Id__c);
			}
		}

		//queries
		if (set_CompanyIds != null && set_CompanyIds.size() > 0) {
			queryAccounts();
		}

		//populate data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			populateAccount(objCustHealth, null);
		}
	}

	//After Insert functionality
	public void processAfterInsert(List<Customer_Health__c> list_CustomHealth) {
		//populate data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			updateAccountInformation(objCustHealth, null);
		}

		//process DML
		processDMLOperation();
	}

	//Before Update functionality
	public void processBeforeUpdate(List<Customer_Health__c> list_CustomHealth, Map<Id, Customer_Health__c> map_OldCustomerHealth) {
		//collect data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			if (String.isNotBlank(objCustHealth.Company_Id__c)) {
				set_CompanyIds.add(objCustHealth.Company_Id__c);
				Customer_Health__c objOldRecord = map_OldCustomerHealth.get(objCustHealth.Id);
				if (objOldRecord.Company_Id__c != objCustHealth.Company_Id__c) {
					set_ChangedCompanyIds.add(objCustHealth.Company_Id__c);
				}
			}
		}

		//queries
		if (set_CompanyIds != null && set_CompanyIds.size() > 0) {
			queryAccounts();
		}

		//populate data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			Customer_Health__c objOldRecord = map_OldCustomerHealth.get(objCustHealth.Id);
			populateAccount(objCustHealth, objOldRecord);
		}
	}

	//After Update functionality
	public void processAfterUpdate(List<Customer_Health__c> list_CustomHealth, Map<Id, Customer_Health__c> map_OldCustomerHealth) {
		//populate data
		for (Customer_Health__c objCustHealth : list_CustomHealth) {
			Customer_Health__c objOldRecord = map_OldCustomerHealth.get(objCustHealth.Id);
			updateAccountInformation(objCustHealth, objOldRecord);
		}

		//process DML
		processDMLOperation();
	}

	/** Populate Account on Customer Health **/
	public static void populateAccount(Customer_Health__c objCustHealth, Customer_Health__c objOldRecord) {
		if (String.isNotBlank(objCustHealth.Company_Id__c) && map_CompIdToAccount != null && map_CompIdToAccount.containsKey(objCustHealth.Company_Id__c)) {
			//if it is a new record or the company id has changed
			if (objOldRecord == null || (set_ChangedCompanyIds != null && set_ChangedCompanyIds.contains(objCustHealth.Company_Id__c))) {
				objCustHealth.Account__c = map_CompIdToAccount.get(objCustHealth.Company_Id__c).Id;
			}
		}
	}

	/** Populate Customer Health Information on Account **/
	public static void updateAccountInformation(Customer_Health__c objCustHealth, Customer_Health__c objOldRecord){
		if (objCustHealth.Account__c == null) {
			return;
		}

		Boolean blnUpdateAccount = false;

		Account objAccount = new Account(Id=objCustHealth.Account__c);

		/** Update NP Rank on Account **/
		if (objCustHealth.HI_NP_Rank__c != null && (objOldRecord == null || (objCustHealth.HI_NP_Rank__c != objOldRecord.HI_NP_Rank__c))) {
			objAccount.NP_Rank__c = objCustHealth.HI_NP_Rank__c;
			blnUpdateAccount = true;
		}

		/** Update Customer Health Score on Account **/
		if(objOldRecord == null || (objCustHealth.Health_Score__c != objOldRecord.Health_Score__c)){
			objAccount.Customer_Health_Score__c = objCustHealth.Health_Score__c;
			blnUpdateAccount = true;
		}

		/** Update Churn Risk on Account **/
		if(objOldRecord == null || (objCustHealth.Churn_Risk_Bucket__c != objOldRecord.Churn_Risk_Bucket__c)){
			objAccount.Churn_Risk__c = objCustHealth.Churn_Risk_Bucket__c;
			blnUpdateAccount = true;
		}

		/** Update Upgrade Propensity on Account **/
		if(objOldRecord == null || (objCustHealth.Upgrade_Propensity__c != objOldRecord.Upgrade_Propensity__c)){
			objAccount.Upgrade_Propensity__c = objCustHealth.Upgrade_Propensity__c;
			blnUpdateAccount = true;
		}

		if(blnUpdateAccount){
			map_AccountsToUpdate.put(objCustHealth.Account__c, objAccount);
		}
	}

	/** Query Accounts **/
	public static void queryAccounts() {
		for (Account objAccount : [
			SELECT Id, Name, ZP_Company_ID__c
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanyIds
		]) {
			map_CompIdToAccount.put(objAccount.ZP_Company_ID__c, objAccount);
		}
	}

	/**** Process DML operations ****/
	public void processDMLOperation() {
		//update accounts
		if (map_AccountsToUpdate != null && !map_AccountsToUpdate.isEmpty()) {
			skipTriggers(true);
			update map_AccountsToUpdate.values();
			skipTriggers(false);
		}
	}

	static void skipTriggers(Boolean blnValue) {
		OpportunityTriggerHelper.skipTrigger = blnValue;
		AccountTriggerHelper.skipTrigger = blnValue;
		CaseTriggerHelper.skipTrigger = blnValue;
		TaskTriggerHelper.skipTrigger = blnValue;
	}
}