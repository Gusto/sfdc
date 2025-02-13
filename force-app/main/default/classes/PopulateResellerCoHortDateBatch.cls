/**
    Created by : Aurobind Ravichandran
    Created Date : 10/01/2020 
**/
public class PopulateResellerCoHortDateBatch implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string queryString = 'SELECT Id, Name, RecordType.Name, Joined_Date_Panda__c, Sold_By__c, Referred_By__c, Managing_Firm__c, Sold_By__r.Cohort_Date__c, Referred_By__r.Cohort_Date__c, Managing_Firm__r.Cohort_Date__c, Sold_By__r.Referred_By__c, Referred_By__r.Referred_By__c, Managing_Firm__r.Referred_By__c, Sold_By__r.Reseller_Company__c, Referred_By__r.Reseller_Company__c, Managing_Firm__r.Reseller_Company__c FROM Account WHERE Recordtype.Name=\'Company\' AND Joined_Date_Panda__c != null AND Joined_Date_Panda__c>=LAST_N_DAYS:30 AND ((Referred_By__c != null AND Referred_By__r.Cohort_Date__c = null) OR (Sold_By__c != null AND Sold_By__r.Cohort_Date__c = null) OR (Managing_Firm__c != null AND Managing_Firm__r.Cohort_Date__c = null)) ORDER BY Joined_Date_Panda__c DESC';

		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<Account> list_Accounts = (List<Account>) scope;
		Map<Id, Account> map_AccountsForUpdate = new Map<Id, Account>();
		List<String> list_AccountIds = new List<String>();
		for (Account objAccount : list_Accounts) {
			Id idAccount = null;
			if (objAccount.Sold_By__c != null && objAccount.Id != objAccount.Sold_By__r.Reseller_Company__c && objAccount.Id != objAccount.Sold_By__r.Referred_By__c) {
				if (objAccount.Sold_By__r.Cohort_Date__c == null)
					list_AccountIds.add(objAccount.Sold_By__c);
			}
			if (objAccount.Referred_By__c != null && objAccount.Id != objAccount.Referred_By__r.Reseller_Company__c && objAccount.Id != objAccount.Referred_By__r.Referred_By__c) {
				if (objAccount.Referred_By__r.Cohort_Date__c == null)
					list_AccountIds.add(objAccount.Referred_By__c);
			}
			if (objAccount.Managing_Firm__c != null && objAccount.Id != objAccount.Managing_Firm__r.Reseller_Company__c && objAccount.Id != objAccount.Managing_Firm__r.Referred_By__c) {
				if (objAccount.Managing_Firm__r.Cohort_Date__c == null)
					list_AccountIds.add(idAccount = objAccount.Managing_Firm__c);
			}
		}

		Map<Id, Account> map_ResellerAccounts = new Map<Id, Account>([SELECT Id, Cohort_Date__c, Reseller_Company__c, Referred_By__c, CreatedDate FROM Account WHERE Id IN :list_AccountIds]);
		for (Account objAccount : list_Accounts) {
			Id idAccount = null;
			if (objAccount.Sold_By__c != null) {
				if (objAccount.Sold_By__r.Cohort_Date__c == null)
					idAccount = objAccount.Sold_By__c;
			}
			if (objAccount.Referred_By__c != null) {
				if (objAccount.Referred_By__r.Cohort_Date__c == null)
					idAccount = objAccount.Referred_By__c;
			}
			if (objAccount.Managing_Firm__c != null) {
				if (objAccount.Managing_Firm__r.Cohort_Date__c == null)
					idAccount = objAccount.Managing_Firm__c;
			}

			if (
				String.isNotBlank(idAccount) &&
				map_AccountsForUpdate.containsKey(idAccount) &&
				map_ResellerAccounts.get(idAccount)?.Reseller_Company__c != objAccount.Id &&
				map_ResellerAccounts.get(idAccount)?.Referred_By__c != objAccount.Id
			) {
				Account objResellerAccount = map_AccountsForUpdate.get(idAccount);
				if (objResellerAccount.Cohort_Date__c > objAccount.Joined_Date_Panda__c) {
					objResellerAccount.Cohort_Date__c = objAccount.Joined_Date_Panda__c;
					map_AccountsForUpdate.put(idAccount, objResellerAccount);
				}
			} else if (
				String.isNotBlank(idAccount) &&
				list_AccountIds.contains(idAccount) &&
				map_ResellerAccounts.get(idAccount)?.Reseller_Company__c != objAccount.Id &&
				map_ResellerAccounts.get(idAccount)?.Referred_By__c != objAccount.Id
			) {
				Account objResellerAccount = new Account(Id = idAccount, Cohort_Date__c = objAccount.Joined_Date_Panda__c);
				map_AccountsForUpdate.put(idAccount, objResellerAccount);
			}
		}

		if (map_AccountsForUpdate != null && !map_AccountsForUpdate.isEmpty()) {
			update map_AccountsForUpdate.values();
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		if (objAsyncJob.NumberOfErrors > 0) {
			Utils.processBatchFinish(objAsyncJob, 'PopulateResellerCoHortDateBatch', false);
		}
	}
}