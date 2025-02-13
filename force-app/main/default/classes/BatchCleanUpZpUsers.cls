/**
 * @name         : BatchCleanUpZpUsers
 * @author       : Seshu Korivi
 * @date         : 03-23-2021
 * @description  : Batch job to process ZP User Queued and Error records, job will run every 1 hour
 * @test classes : BatchCleanUpZpUsersTest
 **/
public class BatchCleanUpZpUsers implements Database.Batchable<sObject>, Database.Stateful {
	static final Set<String> set_relavantProccessingState = new Set<String>{ 'Queued', 'Error' };
	String strQuery;
	List<String> list_ZPUserfields = new List<String>();

	public BatchCleanUpZpUsers(string strQuery) {
		strQuery = strQuery;
	}

	public BatchCleanUpZpUsers() {
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (strQuery == null) {

			Integer intSignInCount = [SELECT COUNT() FROM ZP_User__c WHERE Processing_State__c IN :set_relavantProccessingState AND Sign_In_Changed__c = TRUE];

			if (intSignInCount != 0) {
				// process sign in updates first
				strQuery = 'SELECT Id FROM ZP_User__c WHERE Processing_State__c IN :set_relavantProccessingState AND Sign_In_Changed__c = TRUE';
			} else {
				strQuery = 'SELECT Id FROM ZP_User__c WHERE Processing_State__c IN :set_relavantProccessingState ORDER BY CreatedDate DESC';
			}
		}

		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<ZP_User__c> list_ZPUsers) {
		// declare all variables here
		// list variables
		List<ZP_User__c> list_SignInUsers = new List<ZP_User__c>();
		List<ZP_User__c> list_ProcessUsers = new List<ZP_User__c>();
		List<ZP_User__c> list_AllUsers = new List<ZP_User__c>();

		// class variable
		ZPUserTriggerHelper clsZPUser = new ZPUserTriggerHelper();

		if (!list_ZpUsers.isEmpty()) {
			if (list_ZPUserfields.isEmpty()) {
				list_ZPUserfields = new List<String>(ZP_User__c.SObjectType.getDescribe().fields.getMap().keySet());
			}

			// re-query records to get updated data as record context would have changed since the time batch apex was executed.
			list_AllUsers = Database.query(
				'SELECT ' +
				String.join(list_zpUserfields, ',') +
				' FROM ZP_User__c WHERE Id IN :list_ZpUsers FOR UPDATE'
			);

			// check if last sign in changed
			for (ZP_User__c objUser : list_AllUsers) {
				if (objUser.Sign_In_Changed__c) {
					list_SignInUsers.add(objUser);
				}
			}

			// skip all triggers before update
			ContactTriggerHelper.skiptrigger = true;
			LeadTriggerHelper.skiptrigger = true;

			clsZPUser.processInformation(list_AllUsers); //process zp user information

			if (!list_SignInUsers.isEmpty()) {
				clsZPUser.processLastSignIn(list_SignInUsers); //update last sign in information on account, lead and contact
			}

			ContactTriggerHelper.skiptrigger = false;
			LeadTriggerHelper.skiptrigger = false;

			//skip trigger and run update to stamp lookup fields, processing state and message
			ZPUserTriggerHelper.skipTrigger = true;

			if (!list_AllUsers.isEmpty()) {
				update list_AllUsers;
			}

			if (!list_SignInUsers.isEmpty()) {
				update list_SignInUsers;
			}
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}