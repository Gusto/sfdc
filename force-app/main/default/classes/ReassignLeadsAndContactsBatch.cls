/**
 * @name         ReassignLeadsAndContactsBatch
 * @author       Prity Kumari
 * @date         04-19-2022
 * @description  Resigns Leads and Contacts to Reseller_Inactive_Owner
 * @see          ReassignLeadsAndContactsBatchTest
 **/
public class ReassignLeadsAndContactsBatch implements Database.Batchable<sObject> {
	public static Id idTestUser;
	public ReassignLeadsAndContactsBatch() {
	}
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strBatchQuery = 'SELECT Id, Inactive__c FROM User WHERE Inactive__c = true';
		if (Test.isRunningTest()) {
			strBatchQuery += ' AND Id =: idTestUser';
		}
		return Database.getQueryLocator(strBatchQuery);
	}
	public void execute(Database.BatchableContext BC, List<User> list_User) {
		// Get the assigned user
		String strResellerOwnerId = Label.Reseller_Inactive_Owner;
		List<Contact> list_ContactsToResign = new List<Contact>();
		List<Lead> list_LeadsToResign = new List<Lead>();
		List<User> list_UserUpdate = new List<User>();
		Map<Id, User> map_Users = new Map<Id, User>(list_User);

		try {
			User objUser = [SELECT Id, IsActive FROM User WHERE Id = :strResellerOwnerId];
			if (objUser.IsActive) {
				for (Contact objContact : [SELECT Id, OwnerId FROM Contact WHERE OwnerId IN :map_Users.keySet() AND RecordTypeId = :ContactUtil.RESELLER_CONTACT_RT_ID ORDER BY OwnerId]) {
					//reassign contacts to chris charter
					Contact objNewContact = new Contact(Id = objContact.Id, OwnerId = strResellerOwnerId);
					list_ContactsToResign.add(objNewContact);
				}
				for (Lead objLead : [SELECT Id, OwnerId FROM Lead WHERE OwnerId IN :map_Users.keySet() AND IsConverted = FALSE AND RecordTypeId = :LeadUtil.RESELLER_LEAD_RT_ID ORDER BY OwnerId]) {
					//reassign lead to chris charter
					Lead objNewLead = new Lead(Id = objLead.Id, OwnerId = strResellerOwnerId);
					list_LeadsToResign.add(objNewLead);
				}

				if (!list_ContactsToResign.isEmpty()) {
					TriggerHandler.bypass('ContactTriggerHandler');
					List<Database.SaveResult> result = Database.update(list_ContactsToResign, false);
					TriggerHandler.clearBypass('ContactTriggerHandler');
				}
				if (!list_LeadsToResign.isEmpty()) {
					LeadTriggerHelper.skipTrigger = true;
					List<Database.SaveResult> result = Database.update(list_LeadsToResign, false);
					LeadTriggerHelper.skipTrigger = false;
				}
				for (User objUser1 : list_User) {
					User objUserUpdate = new User(Id = objUser1.Id, Inactive__c = false);
					list_UserUpdate.add(objUserUpdate);
				}
				if (!list_UserUpdate.isEmpty()) {
					UserTriggerHelper.skipTrigger = true;
					List<Database.SaveResult> result = Database.update(list_UserUpdate, false);
					UserTriggerHelper.skipTrigger = false;
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ReassignLeadsAndContactsBatch', 'execute', 'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(), objEx.getStackTraceString());
		}
	}
	public void finish(Database.BatchableContext BC) {
	}
}