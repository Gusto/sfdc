/*
@Create Date - 04/29/2019
@Created By - David (Dato) Tsamalashvili
@Desc: Batch to update concierge accounts.
*/
global class BatchToUpdateConciergeAccount implements Database.Batchable<sObject> {
	String query;

	global BatchToUpdateConciergeAccount() {
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		string companyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');

		query =
			'Select id, Concierge_Group__c,Concierge_Group_Id__c,Tier_Update_Status__c, ZP_Company_Id__c from Account Where ' +
			' recordTypeId =: companyRecordTypeId  AND Tier_Update_Status__c = \'Not Processed\' AND Concierge_Group_Id__c != null ';

		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Account> scope) {
		Map<String, Account> companyIdAccRecMap = new Map<String, Account>();
		List<ZP_User_Role__c> zpUserRolesList = new List<ZP_User_Role__c>();
		Set<String> deletedUserRoleRecIdSet = new Set<String>();
		Map<String, String> userIdGroupdIdMap = new Map<String, String>();
		Set<String> userIdSet = new Set<String>();
		Map<String, Contact> userIdToContactMap = new Map<String, Contact>();
		Map<String, Set<String>> companyIdToUserIdsMap = new Map<String, Set<String>>();
		Map<String, Contact> contactToUpdateMap = new Map<String, Contact>();

		for (Account acc : scope) {
			if (String.isNotBlank(acc.ZP_Company_Id__c)) {
				companyIdAccRecMap.put(acc.ZP_Company_Id__c, acc);
			}
		}

		zpUserRolesList = [SELECT id, User_Id__c, Company_Id__c, Type__c, Deleted_At__c FROM ZP_User_Role__c WHERE Company_Id__c IN :companyIdAccRecMap.keyset()];

		if (zpUserRolesList.size() > 0) {
			for (ZP_User_Role__c rec : zpUserRolesList) {
				Set<String> userIdsSet = new Set<String>();
				userIdSet.add(rec.User_Id__c);

				if (companyIdToUserIdsMap.containsKey(rec.Company_Id__c)) {
					userIdsSet = companyIdToUserIdsMap.get(rec.Company_Id__c);
				}

				if (rec.User_Id__c != null) {
					userIdsSet.add(rec.User_Id__c);
					companyIdToUserIdsMap.put(rec.Company_Id__c, userIdsSet);
				}

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
					Account currentAccount = null;
					String accountConciergeGroupIds = '';

					if (companyIdAccRecMap.containsKey(rec.Company_Id__c)) {
						currentAccount = companyIdAccRecMap.get(rec.Company_Id__c);
					}

					if (userIdGroupdIdMap.containsKey(rec.User_Id__c)) {
						accountConciergeGroupIds = userIdGroupdIdMap.get(rec.User_Id__c);
					}

					if (currentAccount != null) {
						if (String.isNotBlank(currentAccount.Concierge_Group_Id__c)) {
							if (String.isBlank(accountConciergeGroupIds)) {
								accountConciergeGroupIds = currentAccount.Concierge_Group_Id__c;
							} else {
								accountConciergeGroupIds += ',';
								accountConciergeGroupIds += currentAccount.Concierge_Group_Id__c;
							}

							userIdGroupdIdMap.put(rec.User_Id__c, accountConciergeGroupIds);
						} else {
							return;
						}
					}
				}
			}
		}

		if (userIdSet.size() > 0) {
			for (Contact con : [SELECT id, Email, ZP_User_Id__c, Concierge_Account__c, Related_Concierge_Acccounts__c FROM Contact WHERE ZP_User_Id__c IN :userIdSet]) {
				if (!userIdToContactMap.containsKey(con.ZP_User_Id__c)) {
					userIdToContactMap.put(con.ZP_User_Id__c, con);
				}
			}
		}

		for (Account acc : scope) {
			if (companyIdToUserIdsMap.containsKey(acc.ZP_Company_Id__c)) {
				Set<String> currentUsers = companyIdToUserIdsMap.get(acc.ZP_Company_Id__c);
				for (String cu : currentUsers) {
					if (userIdToContactMap.containsKey(cu)) {
						Contact con = userIdToContactMap.get(cu);
						if (userIdGroupdIdMap.containsKey(cu)) {
							con.Related_Concierge_Acccounts__c = userIdGroupdIdMap.get(cu);
							con.Concierge_Account__c = false;
							if (acc.Concierge_Group_Id__c != null && con.Concierge_Account__c == false && !deletedUserRoleRecIdSet.contains(con.ZP_User_Id__c)) {
								con.Concierge_Account__c = true;
							}

							contactToUpdateMap.put(con.Id, con);
						}
					}
				}
			}
			acc.Tier_Update_Status__c = 'Processed';
		}

		if (contactToUpdateMap.size() > 0) {
			try {
				ContactTriggerHelper.skiptrigger = true;
				update contactToUpdateMap.values();

				AccountTriggerHelper.SkipTrigger = true;
				update scope;
			} catch (exception ex) {
				String errorMessage = 'The batch Apex job processed to Update Concierge Accounts Contacts failed! ';
				errorMessage += 'Ecxeption During Concierge Accounts and Contacts update ::: ' + ex.getMessage() + ' Exception Type --> ' + ex.getTypeName() + ' ON LINE ' + ex.getLineNumber();

				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				String[] toAddresses = new List<String>{ Label.Batch_Finish_Email_DL };
				mail.setToAddresses(toAddresses);
				mail.setSubject('Failed To Update Concierge Accounts And Contacts');
				mail.setPlainTextBody(errorMessage);
				if (!test.isRunningTest()) {
					Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
				}
			}
		}
	}

	global void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'BatchToUpdateConciergeAccount', false);
	}
}