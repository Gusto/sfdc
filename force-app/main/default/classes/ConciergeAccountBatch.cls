public with sharing class ConciergeAccountBatch implements Database.Batchable<sObject> {
	public String queryStr;

	public Database.QueryLocator start(Database.BatchableContext bc) {
		string companyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');
		string statusStr = 'Not Processed';
		queryStr =
			'SELECT Id, Concierge_Group__c,Concierge_Group_Id__c,Tier_Update_Status__c, ZP_Company_Id__c FROM Account WHERE ' +
			' RecordTypeId =: companyRecordTypeId AND Tier_Update_Status__c = :statusStr AND Concierge_Group_Id__c != null ';

		return Database.getQueryLocator(queryStr);
	}

	public void execute(Database.BatchableContext bc, List<Account> companyList) {
		Map<string, Account> companyIdAccRecMap = new Map<string, Account>();
		Set<Id> accountIdSet = new Set<Id>();
		Set<String> contactId = new Set<String>();
		Map<String, Contact> contactIdIsConciergeMap = new Map<String, Contact>();

		Map<String, List<String>> companyIdUserIDListMap = new Map<String, List<String>>();
		Map<String, List<Contact>> userIdContactRecListMap = new Map<String, List<Contact>>();
		Map<String, string> userIDContactIdMap = new Map<String, string>();
		Set<String> userIdSet = new Set<String>();

		List<AccountContactRelation> toUpdateRelationList = new List<AccountContactRelation>();

		for (Account accRec : companyList) {
			companyIdAccRecMap.put(accRec.ZP_Company_Id__c, accRec);
			accountIdSet.add(accRec.id);
		}

		Set<String> deletedUserRoleRecIdSet = new Set<String>();
		Map<String, Set<String>> userIdGroupdIdSetMap = new Map<String, Set<String>>();

		for (ZP_User_Role__c rec : [SELECT id, User_Id__c, Company_Id__c, Type__c, Deleted_At__c FROM ZP_User_Role__c WHERE Company_Id__c IN :companyIdAccRecMap.keyset()]) {
			List<String> tempUserIdList = new List<String>();
			if (rec.Company_Id__c != null && companyIdUserIDListMap.containsKey(rec.Company_Id__c)) {
				tempUserIdList = companyIdUserIDListMap.get(rec.Company_Id__c);
			}
			tempUserIdList.add(rec.User_Id__c);
			companyIdUserIDListMap.put(rec.Company_Id__c, tempUserIdList);
			userIdSet.add(rec.User_Id__c);
			if (rec.Deleted_At__c != null) {
				deletedUserRoleRecIdSet.add(rec.User_Id__c);
			}

			if (
				rec.Deleted_At__c == null &&
				rec.Type__c != null &&
				rec.Company_Id__c != null &&
				rec.User_Id__c != null &&
				(rec.Type__c.indexof('PayrollAdmin') > -1 ||
				rec.Type__c.indexof('Signatory') > -1)
			) {
				Set<String> groupIdSet = new Set<String>();
				groupIdSet.add(companyIdAccRecMap.get(rec.Company_Id__c).Concierge_Group_Id__c);
				if (userIdGroupdIdSetMap.containsKey(rec.User_Id__c)) {
					groupIdSet.addAll(userIdGroupdIdSetMap.get(rec.User_Id__c));
				}
				userIdGroupdIdSetMap.put(rec.User_Id__c, groupIdSet);
			}
		}

		if (userIdSet.size() > 0) {
			for (Contact con : [SELECT id, Email, ZP_User_Id__c, Concierge_Account__c, Related_Concierge_Acccounts__c FROM Contact WHERE ZP_User_Id__c IN :userIdSet]) {
				List<Contact> tempContactList = new List<Contact>();
				if (con.ZP_User_Id__c != null && userIdContactRecListMap.containsKey(con.ZP_User_Id__c)) {
					tempContactList = userIdContactRecListMap.get(con.ZP_User_Id__c);
				}
				tempContactList.add(con);

				userIdContactRecListMap.put(con.ZP_User_Id__c, tempContactList);
			}
		}

		List<Contact> toUpdateContactList = new List<Contact>();

		if (userIdContactRecListMap.keyset().size() > 0 && companyIdUserIDListMap.keyset().size() > 0) {
			for (Account accRec : companyList) {
				if (accRec.ZP_company_id__c != null && companyIdUserIDListMap.containsKey(accRec.ZP_company_id__c)) {
					for (string userId : companyIdUserIDListMap.get(accRec.ZP_company_id__c)) {
						List<Contact> contactList = new List<Contact>();
						if (!userIdContactRecListMap.containsKey(userId)) {
							return;
						} else {
							contactList = userIdContactRecListMap.get(userId);
						}

						for (Contact conRec : contactList) {
							Contact tempConrec;
							if (!contactIdIsConciergeMap.containsKey(conRec.Id)) {
								tempConrec = new Contact(id = conRec.Id, Concierge_Account__c = false);
							} else {
								tempConrec = contactIdIsConciergeMap.get(conRec.Id);
							}

							if (accRec.Concierge_Group_Id__c != null && conrec.Concierge_Account__c == false && !deletedUserRoleRecIdSet.contains(conrec.ZP_User_Id__c)) {
								tempConrec.Concierge_Account__c = true;
							} else {
								tempConrec.Concierge_Account__c = false;
							}

							if (userIdGroupdIdSetMap.containsKey(conrec.ZP_User_Id__c)) {
								List<String> tempList = new List<String>();
								tempList.addAll(userIdGroupdIdSetMap.get(conrec.ZP_User_Id__c));
								tempConrec.Related_Concierge_Acccounts__c = string.join(tempList, ',');
							}

							contactIdIsConciergeMap.put(conRec.id, tempConrec);
						}
					}
				}
				accRec.Tier_Update_Status__c = 'Processed';
			}

			if (contactIdIsConciergeMap.keyset().size() > 0) {
				try {
					ContactTriggerHelper.skiptrigger = true;
					update contactIdIsConciergeMap.values();

					AccountTriggerHelper.SkipTrigger = true;
					update companyList;
				} catch (exception ex) {
				}
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}