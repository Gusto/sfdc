public with sharing class TaxOpsFailedFilingTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	private static boolean doNotSendEmail = false;
	private static map<string, EmailTemplate> templateExtIdRecMap = new Map<string, EmailTemplate>();

	public void OnBeforeInsert(List<Tax_Ops_Failed_Filing__c> failedFilings) {
		counter++;
		populateContactForTaxOpsFailedFilingCases(failedFilings);
	}

	public void OnAfterInsert(Map<ID, Tax_Ops_Failed_Filing__c> newFailedFilingMap) {
		sendEmailMessageForTaxOpsFailedFilings(newFailedFilingMap.values());
	}

	@future
	public static void OnAfterInsertAsync(Set<ID> insertedCaseIDs) {
	}

	public void OnBeforeUpdate(Map<ID, Tax_Ops_Failed_Filing__c> oldFailedFilingMap, Map<ID, Tax_Ops_Failed_Filing__c> newFailedFilingMap) {
		counter++;
	}

	public void OnAfterUpdate(Map<ID, Tax_Ops_Failed_Filing__c> oldFailedFilingMap, Map<ID, Tax_Ops_Failed_Filing__c> newFailedFilingMap) {
	}

	@future
	public static void OnAfterUpdateAsync(Set<ID> updatedFailedFilingIDs) {
	}

	public void OnBeforeDelete(Tax_Ops_Failed_Filing__c[] failedFilingToDelete, Map<ID, Tax_Ops_Failed_Filing__c> oldFailedFilingMap) {
		counter++;
	}

	public void OnAfterDelete(Tax_Ops_Failed_Filing__c[] deletedFailedFiling, Map<ID, Tax_Ops_Failed_Filing__c> oldFailedFilingMap) {
		counter++;
	}

	@future
	public static void OnAfterDeleteAsync(Set<ID> deletedFailedFilingIDs) {
	}

	public void OnUndelete(Tax_Ops_Failed_Filing__c[] restoredFailedFilings) {
		counter++;
	}

	public void sendEmailMessageForTaxOpsFailedFilings(list<Tax_Ops_Failed_Filing__c> originalFailedFilingList) {
		list<Tax_Ops_Failed_Filing__c> eligibleCaseList = new List<Tax_Ops_Failed_Filing__c>();
		set<id> accountIdSet = new Set<id>();
		set<string> templateIdSet = new Set<string>();
		list<EmailMessage> toInsertEmailMessageList = new List<EmailMessage>();
		map<Tax_Ops_Failed_Filing__c, Messaging.SingleEmailMessage> toSendSingleEmailMap = new Map<Tax_Ops_Failed_Filing__c, Messaging.SingleEmailMessage>();
		string orgWideEmailString = label.Email_Message_From_Address;
		id orgwideEmailId;
		list<OrgWideEmailAddress> owEmailist = [SELECT id FROM OrgWideEmailAddress WHERE Address = :Label.Email_Message_From_Address];
		if (owEmailist.size() > 0) {
			orgwideEmailId = owEmailist.get(0).id;
		}
		for (Tax_Ops_Failed_Filing__c rec : originalFailedFilingList) {
			EmailTemplate templateRec = new EmailTemplate();
			if (templateExtIdRecMap.keyset().size() > 0 && templateExtIdRecMap.containsKey(rec.Email_Template_Unique_Name__c)) {
				templateRec = templateExtIdRecMap.get(rec.Email_Template_Unique_Name__c);
			} else {
				continue;
			}
			if (rec.Status__c == 'Failed') {
				continue;
			}

			Messaging.SingleEmailMessage emailRec = new Messaging.SingleEmailMessage();
			emailRec.setTemplateId(templateRec.id);

			emailRec.setToAddresses(new List<string>{ rec.Contact__c });
			if (rec.CC_Ids__c != null && rec.CC_Ids__c != '') {
				List<Id> ccList = rec.CC_Ids__c.split(',');
				emailRec.setccAddresses(ccList);
			}

			emailRec.setWhatId(rec.id);
			emailRec.settargetObjectId(rec.Contact__c);
			emailRec.saveAsActivity = false;
			emailRec.setOrgWideEmailAddressId(orgwideEmailId);
			toSendSingleEmailMap.put(rec, emailRec);
		}

		if (toSendSingleEmailMap.keyset().size() > 0) {
			if (OrganizationUtilities.canSendEmails()) {
				Messaging.sendEmail(toSendSingleEmailMap.values());
			}
			populateTaxOpsFailedFilingEmailDetails(toSendSingleEmailMap);
		}
	}

	/*
    public void populateContactForTaxOpsFailedFilingCases(list<Tax_Ops_Failed_Filing__c> failedFilingList){
        
        
        map<id,id> accountContactIdMap = new map<id,id>();
        
        for(Tax_Ops_Failed_Filing__c rec: failedFilingList){
            if(rec.Account__c != null)
                accountContactIdMap.put(rec.Account__c,null);
        }
        
        if(accountContactIdMap.keyset().size()>0){
            for(Account acc: [Select id,(Select id,ZP_User_Role__c From Contacts)                    
                               From Account where ID IN: accountContactIdMap.keyset()]){
                if(acc.Contacts.size()>0){
                    for(Contact rec: acc.Contacts){                        
                       if(rec.ZP_User_Role__c == 'Primary Payroll Admin'){
                            accountContactIdMap.put(acc.id,rec.id);
                        }
                    }
                }
            }
            
            if(accountContactIdMap.size()>0){
                for(Tax_Ops_Failed_Filing__c rec: failedFilingList){
                    if(rec.Account__c != null && accountContactIdMap.containsKey(rec.Account__c)){
                        rec.Contact__c = accountContactIdMap.get(rec.Account__c);
                    }
                }
            }    
        }        
    }

    */

	public static void populateTaxOpsFailedFilingEmailDetails(map<Tax_Ops_Failed_Filing__c, Messaging.SingleEmailMessage> failedFilingEmailMap) {
		if (failedFilingEmailMap.keyset().size() > 0) {
			list<Tax_Ops_Failed_Filing__c> tempList = new List<Tax_Ops_Failed_Filing__c>();
			set<string> contactIdSet = new Set<string>();
			map<string, string> contactIdEmailMap = new Map<string, string>();

			for (Tax_Ops_Failed_Filing__c rec : failedFilingEmailMap.Keyset()) {
				contactIdSet.add(rec.Contact__c);
				if (rec.CC_Ids__c != null && rec.CC_Ids__c != '')
					contactIdSet.addAll(rec.CC_Ids__c.split(','));
			}

			if (contactIdSet.size() > 0) {
				for (Contact con : [SELECT id, email FROM Contact WHERE Id IN :contactIdSet]) {
					contactIdEmailMap.put(con.id, con.email);
				}
			}

			for (Tax_Ops_Failed_Filing__c rec : failedFilingEmailMap.Keyset()) {
				Messaging.SingleEmailMessage emailRec = failedFilingEmailMap.get(rec);
				Tax_Ops_Failed_Filing__c tempRec = new Tax_Ops_Failed_Filing__c(id = rec.id);
				tempRec.Subject__c = emailRec.getSubject();
				if (contactIdEmailMap != null && contactIdEmailMap.containsKey(string.join(emailRec.getToAddresses(), ','))) {
					tempRec.To_Address__c = contactIdEmailMap.get(string.join(emailRec.getToAddresses(), ','));
				}

				if (!string.isBlank(rec.CC_Ids__c)) {
					string ccStr;
					for (string conId : rec.CC_Ids__c.split(',')) {
						if (string.isBlank(ccStr)) {
							ccStr = contactIdEmailMap.get(conId);
						} else {
							ccStr += ', ' + contactIdEmailMap.get(conId);
						}
					}
					tempRec.CC_Address__c = ccStr;
				}

				tempRec.From_Address__c = Label.Email_Message_From_Address;
				tempRec.Body__c = emailRec.getHtmlBody();
				tempRec.Date_Sent__c = system.now().addSeconds(5);
				tempList.add(tempRec);
			}

			skipTrigger = true;
			update tempList;
		}
	}

	public void populateContactForTaxOpsFailedFilingCases(list<Tax_Ops_Failed_Filing__c> failedFilingList) {
		Set<String> compIdSet = new Set<String>();
		Set<String> templateIdSet = new Set<String>();
		for (Tax_Ops_Failed_Filing__c rec : failedFilingList) {
			templateIdSet.add(rec.Email_Template_Unique_Name__c);

			if (rec.Account__c != null)
				compIdSet.add(rec.ZP_Company_Id__c);
		}

		for (EmailTemplate rec : [
			SELECT Subject, Name, Id, HtmlValue, DeveloperName, Body
			FROM EmailTemplate
			WHERE DeveloperName IN :templateIdSet
		]) {
			templateExtIdRecMap.put(rec.DeveloperName, rec);
		}

		map<String, accountContact> compMap = getCompanyContactInfo(compIdSet);
		for (Tax_Ops_Failed_Filing__c rec : failedFilingList) {
			if (templateExtIdRecMap.keyset().size() > 0 && templateExtIdRecMap.containsKey(rec.Email_Template_Unique_Name__c)) {
				//templateRec = templateExtIdRecMap.get(rec.Email_Template_Unique_Name__c);
			} else {
				rec.Status__c = 'Failed';
				rec.Message__c = 'Template does not exist.';
			}

			if (rec.ZP_Company_Id__c != null && compMap.containsKey(rec.ZP_Company_Id__c)) {
				accountContact accCont = compMap.get(rec.ZP_Company_Id__c);
				if (accCont.primaryContactId != '') {
					rec.Contact__c = accCont.primaryContactId;
				} else {
					rec.Status__c = 'Failed';
				}
				if (accCont.secondaryContactIds != '') {
					rec.CC_Ids__c = accCont.secondaryContactIds;
				}
			} else {
				rec.Status__c = 'Failed';
			}
		}
	}

	private map<String, accountContact> getCompanyContactInfo(Set<String> companyIdSet) {
		map<String, accountContact> compContactMap = new Map<String, accountContact>();
		List<ZP_User_Role__c> userRoleList = new List<ZP_User_Role__c>(
			[
				SELECT id, Company_Id__c, User_Id__c, Is_Primary__c
				FROM ZP_User_Role__c
				WHERE Company_id__c IN :companyIdSet AND Type__c = 'Role::PayrollAdmin' AND deleted_at__c = NULL
				ORDER BY Company_Id__c
			]
		);
		Set<String> userIdSet = new Set<String>();
		map<String, String> companyPrimaryUserMap = new Map<String, String>();
		map<String, List<String>> companyUserMap = new Map<String, List<String>>();
		for (ZP_User_Role__c role : userRoleList) {
			userIdSet.add(role.User_Id__c);
			if (role.Is_Primary__c == true) {
				companyPrimaryUserMap.put(role.Company_Id__c, role.User_Id__c);
			} else {
				List<String> compUsrList = new List<String>();
				if (companyUserMap.containsKey(role.Company_Id__c)) {
					compUsrList = companyUserMap.get(role.Company_Id__c);
				}
				compUsrList.add(role.User_Id__c);
				companyUserMap.put(role.Company_Id__c, compUsrList);
			}
		}
		map<String, String> userIdEmailMap = new Map<String, String>();
		for (ZP_User__c usr : [SELECT Id, id__c, email__c FROM ZP_User__c WHERE Deleted_at__c = NULL AND id__c IN :userIdSet]) {
			userIdEmailMap.put(usr.id__c, usr.email__c);
		}
		map<String, String> emailContactIdMap = new Map<String, String>();
		for (Contact cnt : [SELECT id, email FROM contact WHERE email IN :userIdEmailMap.values() AND email != NULL AND email != '']) {
			emailContactIdMap.put(cnt.email, cnt.id);
		}
		for (String compId : companyIdSet) {
			accountContact accCnt = new accountContact();
			accCnt.primaryContactId = '';
			accCnt.secondaryContactIds = '';
			accCnt.companyId = compId;
			if (companyPrimaryUserMap.containsKey(compId)) {
				String userId = companyPrimaryUserMap.get(compId);
				if (userIdEmailMap.containsKey(userId)) {
					String email = userIdEmailMap.get(userId);

					if (emailContactIdMap.containsKey(email)) {
						accCnt.primaryContactId = emailContactIdMap.get(email);
					}
				}
			}
			if (companyUserMap.containsKey(compId)) {
				List<String> userIdList = companyUserMap.get(compId);
				for (String usrId : userIdList) {
					if (userIdEmailMap.containsKey(usrId)) {
						String email = userIdEmailMap.get(usrId);

						if (emailContactIdMap.containsKey(email)) {
							if (emailContactIdMap.get(email) != '') {
								if (accCnt.secondaryContactIds == '') {
									accCnt.secondaryContactIds = emailContactIdMap.get(email);
								} else {
									accCnt.secondaryContactIds += ',' + emailContactIdMap.get(email);
								}
							}
						}
					}
				}
			}
			compContactMap.put(compId, accCnt);
		}
		return compContactMap;
	}

	private class accountContact {
		private string companyId;
		private string primaryContactId;
		private String secondaryContactIds;
	}
}