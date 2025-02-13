/**
 * @name         : ZPUserRoleAccountantBatch
 * @author       : Praveen Sethu
 * @date         : 03-24-2021
 * @description  : Updates Contact's Account associated with Accountant ZP User Roles.
 * 				   Batch class updates all Company Contacts associated with Accountant ZP User Roles and map correct Accounting Firm on Contact
 * @test classes : ZPUserRoleAccountantBatchTest
 **/
public with sharing class ZPUserRoleAccountantBatch implements Database.Batchable<sObject>, Database.stateful {

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Id idContactRType = ContactUtil.COMPANY_CONTACT_RT_ID;
		Id idCompanyRType = AccountUtil.COMPANY_ACCOUNT_RT_ID;
		String strBatchQuery = 'SELECT Id, Accounting_Firm_Id__c, Contact__c, Contact__r.AccountId, Contact__r.Id, Contact__r.RecordTypeId FROM ZP_User_Role__c WHERE Accounting_Firm_Id__c != null AND (Contact__r.RecordTypeId = :idContactRType OR Contact__r.Account.RecordTypeId = :idCompanyRType) AND Deleted_At__c = null';
		return Database.getQueryLocator(strBatchQuery);
	}

	public void execute(Database.BatchableContext BC, List<ZP_User_Role__c> list_Roles) {
		Map<Id, Contact> map_ContactsToUpdate = new Map<Id, Contact>();
		Map<String, Account> map_FirmIdToAccount = new Map<String, Account>();
		Set<String> set_Accounts = new Set<String>();

		for (ZP_User_Role__c objRole : list_Roles) {
			set_Accounts.add(objRole.Accounting_Firm_Id__c);
		}

		for (Account objAccount : [SELECT Id, ZP_Firm_ID__c FROM Account WHERE ZP_Firm_ID__c IN :set_Accounts]) {
			map_FirmIdToAccount.put(objAccount.ZP_Firm_ID__c, objAccount);
		}

		for (ZP_User_Role__c objRole : list_Roles) {
			if (map_FirmIdToAccount.containsKey(objRole.Accounting_Firm_Id__c)) {
				Account objResellerAccount = map_FirmIdToAccount.get(objRole.Accounting_Firm_Id__c);
				if (
					objRole.Contact__c != null &&
					objRole.Contact__r.AccountId != null &&
					objResellerAccount != null &&
					(objRole.Contact__r.AccountId != objResellerAccount.Id ||
					objRole.Contact__r.RecordTypeId == ContactUtil.COMPANY_CONTACT_RT_ID)
				) {
					// Update Account Id and Change Record Type to Reseller
					map_ContactsToUpdate.put(
						objRole.Contact__r.Id,
						new Contact(
							Id = objRole.Contact__r.Id,
							AccountId = objResellerAccount.Id,
							RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID
						)
					);
				}
			}
		}

		if (!map_ContactsToUpdate.isEmpty()) {
			ContactTriggerHelper.skipTrigger = true;
			update map_ContactsToUpdate.values();
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [
			SELECT Id, Status, NumberOfErrors, TotalJobItems
			FROM AsyncApexJob
			WHERE Id = :BC.getJobId()
		];
		Utils.processBatchFinish(objAsyncJob, 'ZPUserRoleAccountantBatch', false);
	}
}