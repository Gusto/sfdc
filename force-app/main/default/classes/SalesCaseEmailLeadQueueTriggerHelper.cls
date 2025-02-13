public with sharing class SalesCaseEmailLeadQueueTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;

	public void OnBeforeInsert(List<Sales_Case_Email_Lead_Queue__c> salesCaseEmails) {
		counter++;
		if (queue == true) {
			processInformation(salesCaseEmails);
		} else {
			for (Sales_Case_Email_Lead_Queue__c salesCase : salesCaseEmails) {
				salesCase.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, Sales_Case_Email_Lead_Queue__c> salesCaseEmailMap) {
		if (queue == false) {
			SalesCaseEmailLeadQueue updateJob = new SalesCaseEmailLeadQueue(salesCaseEmailMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeUpdate(Map<ID, Sales_Case_Email_Lead_Queue__c> oldSalesCaseEmailMap, Map<ID, Sales_Case_Email_Lead_Queue__c> newSalesCaseEmailMap) {
		counter++;

		if (queue == true) {
			processInformation(newSalesCaseEmailMap.values());
		} else {
			for (Sales_Case_Email_Lead_Queue__c salesCaseEmail : newSalesCaseEmailMap.values()) {
				salesCaseEmail.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, Sales_Case_Email_Lead_Queue__c> oldSalesCaseEmailMap, Map<ID, Sales_Case_Email_Lead_Queue__c> newSalesCaseEmailMap) {
		if (queue == false) {
			SalesCaseEmailLeadQueue updateJob = new SalesCaseEmailLeadQueue(newSalesCaseEmailMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	private void processInformation(List<Sales_Case_Email_Lead_Queue__c> salesCaseEmails) {
		map<String, caseContact> caseIdEmailMap = new Map<String, caseContact>();
		Set<id> caseIdSet = new Set<id>();
		Set<id> caseIdWithoutEmailSet = new Set<id>();
		Set<String> emailIdSet = new Set<String>();
		List<Lead> leadList = new List<Lead>();
		Map<String, String> dmlInsertErrorsMap = new Map<String, String>();
		Map<String, String> dmlCaseUpdateErrorsMap = new Map<String, String>();
		Map<String, Case> caseMap = new Map<String, Case>();

		for (Sales_Case_Email_Lead_Queue__c salesCase : salesCaseEmails) {
			if (salesCase.Processing_State__c == integrationUtils.PROCESSED_STATE) {
				continue;
			}
			caseIdSet.add(salesCase.Case__c);
		}

		for (Case c : [SELECT id, SuppliedEmail, SuppliedName, Subject, Description, Origin FROM Case WHERE id IN :caseidSet]) {
			caseMap.put(c.id, c);
			if (c.Description != null && c.Description.indexOf('Email address: ') > -1 && c.Description.indexOf('First name: ') > -1) {
				caseContact cntct = new caseContact();
				String splitParam = '\n';
				if (c.Description.IndexOf('\r\n') > -1) {
					splitParam = '\r\n';
				}
				for (String sr : c.Description.split(splitParam)) {
					if (sr.indexOf('First name: ') > -1) {
						String[] arr = sr.split(': ');
						if (arr.size() > 1) {
							cntct.firstName = arr[1];
						}
					} else if (sr.indexOf('Last name: ') > -1) {
						String[] arr = sr.split(': ');
						if (arr.size() > 1) {
							cntct.lastName = arr[1];
						}
					} else if (sr.indexOf('Email address: ') > -1) {
						String[] arr = sr.split(': ');
						if (arr.size() > 1) {
							cntct.email = arr[1];
							emailIdSet.add(cntct.email);
						}
					}
				}
				caseIdEmailMap.put(c.Id, cntct);
			} else if (c.SuppliedEmail != null) {
				caseContact cntct = new caseContact();
				cntct.email = c.SuppliedEmail;
				emailIdSet.add(c.SuppliedEmail);
				if (c.SuppliedName != null) {
					String[] nameArray = c.SuppliedName.split(' ');
					cntct.FirstName = nameArray[0];
					if (nameArray.size() > 1) {
						cntct.LastName = nameArray[1];
					}
				}
				caseIdEmailMap.put(c.Id, cntct);
			} else {
				caseIdWithoutEmailSet.add(c.Id);
			}
		}

		if (emailIdSet.size() > 0) {
			map<String, ZP_User__c> userMap = getZPUserMap(emailIdSet);
			map<String, Contact> contactMap = getContactMap(emailIdSet);
			map<String, Lead> leadMap = getLeadMap(emailIdSet);

			for (Sales_Case_Email_Lead_Queue__c salesCase : salesCaseEmails) {
				if (caseIdWithoutEmailSet.contains(salesCase.Case__c)) {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Email does not exist', salesCase);
				} else {
					if (caseIdEmailMap.containsKey(salesCase.case__c)) {
						caseContact cContact = caseIdEmailMap.get(salesCase.case__c);
						if (userMap.containsKey(cContact.Email)) {
							setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Email exists as a user', salesCase);
						} else if (contactMap.containsKey(cContact.Email)) {
							setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Email exists as a Contact', salesCase);
						} else if (leadMap.containsKey(cContact.Email)) {
							setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Email exists as a Lead', salesCase);
						} else {
							Lead l = new Lead();
							l.email = cContact.email;
							l.Unique_Email_Address__c = 'Company-' + cContact.email;
							l.FirstName = String.isNotBlank(cContact.FirstName) ? cContact.FirstName : 'N/A';
							l.LastName = cContact.LastName;

							l.status = 'AQL';
							l.Company = 'NA';
							l.RecordTypeId = cache.getRecordTypeId('Lead', 'Company');
							if (caseMap.containsKey(salesCase.Case__c)) {
								Case c = caseMap.get(salesCase.Case__c);
								if (c.Origin == 'Email' || c.Origin == 'Success Email') {
									l.LeadSource = 'Inbound Email';
								} else if (c.Origin == 'Phone' || (c.Origin == 'Gusto' && c.Channel__c == 'Phone')) {
									l.LeadSource = 'Inbound Phone';
								} else if (c.Origin == 'Chat' || (c.Origin == 'Gusto' && c.Channel__c == 'Chat')) {
									l.LeadSource = 'Inbound Chat';
								}
								l.Lead_Source_Detail__c = 'Small Biz Salesforce';
							} else {
								l.LeadSource = 'Success Inbound';
								l.Lead_Source_Detail__c = 'Small Biz Salesforce';
							}
							leadList.add(l);
						}
					}
				}
			}

			if (leadList.size() > 0) {
				List<Database.SaveResult> saveResult = database.insert(leadList, false);
				dmlInsertErrorsMap = Utils.processSaveResult(saveResult, leadList, 'Email', true, 'SalesCaseEmailLeadQueueTriggerHelper-processInformation');
			}
			map<String, Lead> leadIdMap = new Map<String, Lead>();
			for (Lead l : leadList) {
				leadIdMap.put(l.Email, l);
			}
			List<Case> caseListForUpdate = new List<Case>();
			for (String caseId : caseIdEmailMap.keySet()) {
				CaseContact cContact = caseIdEmailMap.get(caseId);
				if (leadIdMap.containsKey(cContact.Email)) {
					Case c = new Case(Id = caseId);
					c.Lead__c = leadIdMap.get(cContact.Email).Id;
					caseListForUpdate.add(c);
				}
			}

			if (caseListForUpdate.size() > 0) {
				List<Database.SaveResult> saveResult = database.update(caseListForUpdate, false);
				dmlCaseUpdateErrorsMap = Utils.processSaveResult(saveResult, caseListForUpdate, 'Id', true, 'SalesCaseEmailLeadQueueTriggerHelper-processInformation');
			}
		}

		for (Sales_Case_Email_Lead_Queue__c salesCase : salesCaseEmails) {
			if (salesCase.Processing_State__c != integrationUtils.QUEUED_STATE) {
				continue;
			}
			if (caseIdEmailMap.containsKey(salesCase.case__c)) {
				CaseContact cnt = caseIdEmailMap.get(salesCase.case__c);
				if (dmlInsertErrorsMap.containsKey(cnt.email)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, dmlInsertErrorsMap.get(cnt.email), salesCase);
				} else {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information processed', salesCase);
				}
			} else if (dmlCaseUpdateErrorsMap.containsKey(salesCase.case__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlCaseUpdateErrorsMap.get(salesCase.case__c), salesCase);
			} else {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information processed', salesCase);
			}
		}
	}

	private map<String, ZP_User__c> getZPUserMap(Set<String> emailSet) {
		map<String, ZP_User__c> emailMap = new Map<String, ZP_User__c>();
		for (ZP_User__c user : [SELECT Id, Email__c FROM ZP_User__c WHERE Email__c IN :emailSet]) {
			emailMap.put(user.Email__c, user);
		}
		return emailMap;
	}

	private map<String, Contact> getContactMap(Set<String> emailSet) {
		map<String, Contact> emailMap = new Map<String, Contact>();
		for (Contact cont : [SELECT Id, Email FROM Contact WHERE Email IN :emailSet ORDER BY RecordType.Name DESC]) {
			emailMap.put(cont.Email, cont);
		}
		return emailMap;
	}

	private map<String, Lead> getLeadMap(Set<String> emailSet) {
		map<String, Lead> emailMap = new Map<String, Lead>();
		for (Lead ld : [SELECT Id, Email FROM Lead WHERE Email IN :emailSet ORDER BY RecordType.Name DESC]) {
			emailMap.put(ld.Email, ld);
		}
		return emailMap;
	}

	private Sales_Case_Email_Lead_Queue__c setProcessingState(String ProcessingState, String message, Sales_Case_Email_Lead_Queue__c hiEvent) {
		hiEvent.Processing_State__c = ProcessingState;
		hiEvent.Message__c = message;
		hiEvent.Last_Processed__c = System.now();
		return hiEvent;
	}
	public class caseContact {
		public string email;
		public string firstName;
		public string lastName;
	}
}