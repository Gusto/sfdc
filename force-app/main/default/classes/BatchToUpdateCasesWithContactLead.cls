/*
    By: Deepak Tyagi
    Date : April 16, 2019
    Description : Case Back attach Batch
*/
public class BatchToUpdateCasesWithContactLead implements Database.Batchable<sObject> {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String salesRecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases');
		String salesClosedRecordTypeId = Cache.getRecordTypeId('Case', 'Sales Cases - Closed');
		String queryString = 'SELECT Id, SuppliedEmail, Origin, Subject FROM Case WHERE (RecordTypeId = :salesRecordTypeId OR RecordTypeId = :salesClosedRecordTypeId) AND ContactId = null AND Lead__c = null';
		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<sObject> scope) {
		Set<String> emailSet = new Set<String>();
		Set<String> phoneSet = new Set<String>();
		Map<String, Lead> leadEmailMap = new Map<String, Lead>();
		Map<String, Contact> contactEmailMap = new Map<String, Contact>();
		Map<String, Lead> leadPhoneMap = new Map<String, Lead>();
		Map<String, Contact> contactPhoneMap = new Map<String, Contact>();
		List<Case> listAllCases = scope;
		List<Case> listToUpdateCase = new List<Case>();

		for (Case cseObj : listAllCases) {
			if (String.isNotBlank(cseObj.SuppliedEmail)) {
				emailSet.add(cseObj.SuppliedEmail);
			}

			// As of 11/10/2022, this condition will always be false -- (cseObj.Origin == 'Gusto' && cseObj.Channel__c == 'Phone')
			if (cseObj.Origin == 'Phone' && cseObj.Subject != null && cseObj.Subject.contains('Incoming Call')) {
				String strSubject = cseObj.Subject.left(10);
				phoneSet.add(strSubject);
			}
		}

		for (Contact con : [SELECT Id, Email, RecordTypeId, Phone FROM Contact WHERE Email IN :emailSet OR Phone IN :phoneSet]) {
			contactEmailMap.put(con.Email, con);
			contactPhoneMap.put(con.Phone, con);
		}

		for (Lead leadObj : [SELECT Id, Email, RecordTypeId, Phone FROM Lead WHERE Email IN :emailSet OR Phone IN :phoneSet]) {
			leadEmailMap.put(leadObj.Email, leadObj);
			leadPhoneMap.put(leadObj.Phone, leadObj);
		}

		for (Case cseObj : listAllCases) {
			String strSubject = '';
			Boolean addCase = false;
			// As of 11/10/2022, this condition will always be false -- (cseObj.Origin == 'Gusto' && cseObj.Channel__c == 'Phone')
			if (cseObj.Origin == 'Phone' && cseObj.Subject != null && cseObj.Subject.contains('Incoming Call')) {
				strSubject = cseObj.Subject.left(10);
			}

			if (contactEmailMap.containsKey(cseObj.SuppliedEmail)) {
				cseObj.ContactId = contactEmailMap.get(cseObj.SuppliedEmail).Id;
				addCase = true;
			} else if (leadEmailMap.containsKey(cseObj.SuppliedEmail) && leadEmailMap.get(cseObj.SuppliedEmail).RecordTypeId == Cache.getRecordTypeId('Lead', 'Reseller')) {
				cseObj.Lead__c = leadEmailMap.get(cseObj.SuppliedEmail).Id;
				addCase = true;
			} else if (leadEmailMap.containsKey(cseObj.SuppliedEmail) && leadEmailMap.get(cseObj.SuppliedEmail).RecordTypeId == Cache.getRecordTypeId('Lead', 'Company')) {
				cseObj.Lead__c = leadEmailMap.get(cseObj.SuppliedEmail).Id;
				addCase = true;
			} else if (String.isNotBlank(strSubject) && contactPhoneMap.containsKey(strSubject) && contactPhoneMap.get(strSubject).RecordTypeId == Cache.getRecordTypeId('Contact', 'Reseller')) {
				cseObj.ContactId = contactPhoneMap.get(strSubject).Id;
				addCase = true;
			} else if (String.isNotBlank(strSubject) && contactPhoneMap.containsKey(strSubject) && contactPhoneMap.get(strSubject).RecordTypeId == Cache.getRecordTypeId('Contact', 'Company')) {
				cseObj.ContactId = contactPhoneMap.get(strSubject).Id;
				addCase = true;
			} else if (String.isNotBlank(strSubject) && leadPhoneMap.containsKey(strSubject) && leadPhoneMap.get(strSubject).RecordTypeId == Cache.getRecordTypeId('Lead', 'Reseller')) {
				cseObj.Lead__c = leadPhoneMap.get(strSubject).Id;
				addCase = true;
			} else if (String.isNotBlank(strSubject) && leadPhoneMap.containsKey(strSubject) && leadPhoneMap.get(strSubject).RecordTypeId == Cache.getRecordTypeId('Lead', 'Company')) {
				cseObj.Lead__c = leadPhoneMap.get(strSubject).Id;
				addCase = true;
			}

			if (addCase) {
				listToUpdateCase.add(cseObj);
			}
		}

		if (listToUpdateCase != null && listToUpdateCase.size() > 0) {
			CaseTriggerHelper.skipTrigger = true;
			update listToUpdateCase;
			CaseTriggerHelper.skipTrigger = false;
		}
	}

	public void finish(Database.BatchableContext BC) {
	}
}