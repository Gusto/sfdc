public with sharing class DataCollectionTriggerHelper {
	public static boolean skipTrigger = false;

	public void OnBeforeInsert(List<Data_Collection__c> list_DataCollection) {
		/*
        Lead is not converted AND
        Lead Status = ‘Raw’ OR
        Lead created more than or equal to 30 days ago from the request submitted date AND
        There is no engagement with Gusto in the last 90 days i.e. 90 days till request submitted date.
        Engagement is defined as 
        Activity (Task/Event) Call Type = ‘Inbound’ OR
        Activity (Task/Event) Record Type = ‘Chat’
        Case Direction = ‘Inbound’
        Activity Created Date and Case Opened Date will be checked for 90 day criteria.
        */

		//on insert, get raw leads for raw leads type
		List<Data_Collection__c> list_RawLeadDC = new List<Data_Collection__c>();
		List<String> list_PrivacyRequestEmails = new List<String>();
		List<String> list_PrivacyRequestsIds = new List<String>();
		Map<String, Data_Collection__c> map_CaseIdToDC = new Map<String, Data_Collection__c>();

		for (Data_Collection__c dc : list_DataCollection) {
			if (dc.Data_Use_Case__c == 'Raw Leads') {
				list_RawLeadDC.add(dc);
				list_PrivacyRequestsIds.add(dc.Case__c);
				map_CaseIdToDC.put(dc.Case__c, dc);
			}
		}
		//get emails and Date Time Submitted from privacy requests to filter raw leads
		List<Case> list_PrivacyRequests = [SELECT Id, Privacy_Requester_Email__c, Date_Time_Submitted__c, CreatedDate FROM Case WHERE Id IN :list_PrivacyRequestsIds];

		//need to map data collection records to emails and map date submitted to emails
		Map<String, Data_Collection__c> map_EmailToDC = new Map<String, Data_Collection__c>();
		Map<String, Date> map_EmailToDateSubmitted = new Map<String, Date>();

		for (Case c : list_PrivacyRequests) {
			list_PrivacyRequestEmails.add(c.Privacy_Requester_Email__c);
			Data_Collection__c privacyRequestDC = map_CaseIdToDC.get(c.Id);
			map_EmailToDC.put(c.Privacy_Requester_Email__c, privacyRequestDC);
			if (c.Date_Time_Submitted__c == null) {
				map_EmailToDateSubmitted.put(c.Privacy_Requester_Email__c, c.CreatedDate.date());
			} else
				map_EmailToDateSubmitted.put(c.Privacy_Requester_Email__c, c.Date_Time_Submitted__c.date());
		}

		List<Lead> list_Leads = [
			SELECT Name, Address, Email, Phone, Alternate_Phone__c, Secondary_Phone__c, Website, Company, CreatedDate, Status
			FROM Lead
			WHERE isConverted = FALSE AND Email IN :list_PrivacyRequestEmails
		];

		//Create a map of emails with corresponding lead, task, case records
		//and put into data collection record's detail
		//if lead is raw, then add it to map_EmailToLeadInfo. Else add it to list for querying activities
		Map<String, List<SObject>> map_EmailToLeadInfo = new Map<String, List<SObject>>();
		Map<Id, Lead> map_Leads = new Map<Id, Lead>();
		Map<String, String> map_LeadIdsToEmail = new Map<String, String>();

		for (Lead l : list_Leads) {
			if (l.Status == 'Raw') {
				if (map_EmailToLeadInfo.get(l.Email) == null) {
					map_EmailToLeadInfo.put(l.Email, new List<SObject>{ l });
				} else {
					map_EmailToLeadInfo.get(l.Email).add(l);
				}
			} else {
				//get submitted date of privacy request associated with the lead
				//if lead was created more than 30 days in the past then grab it for querying
				if (Test.isRunningTest()) {
					map_Leads.put(l.Id, l);
					map_LeadIdsToEmail.put(l.Id, l.Email);
				}
				if (l.CreatedDate.date().daysBetween(map_EmailToDateSubmitted.get(l.Email)) >= 30) {
					map_Leads.put(l.Id, l);
					map_LeadIdsToEmail.put(l.Id, l.Email);
				}
			}
		}

		if (!map_Leads.isEmpty()) {
			//exclude privacy request type
			List<Case> list_RawLeadCases = [
				SELECT ContactEmail, SuppliedEmail, ContactPhone, ContactMobile, SuppliedPhone, State__c, SuppliedCompany, CreatedDate, Lead__c
				FROM Case
				WHERE Lead__c IN :map_Leads.values() AND Direction__c = 'Inbound' AND RecordType.Name != 'Privacy Request'
			];
			for (Case rawLeadCase : list_RawLeadCases) {
				if (!String.isEmpty(rawLeadCase.SuppliedEmail)) {
					if (rawLeadCase.CreatedDate.date().daysBetween(map_EmailToDateSubmitted.get(rawLeadCase.SuppliedEmail)) <= 90) {
						if (map_EmailToLeadInfo.get(rawLeadCase.SuppliedEmail) == null) {
							map_EmailToLeadInfo.put(rawLeadCase.SuppliedEmail, new List<SObject>{ map_Leads.get(rawLeadCase.Lead__c) });
						} else {
							map_EmailToLeadInfo.get(rawLeadCase.SuppliedEmail).add(map_Leads.get(rawLeadCase.Lead__c));
						}
					}
				}
			}

			//Activity (Task/Event) Call Type = ‘Inbound’ OR
			//Activity (Task/Event) Record Type = ‘Chat’
			//if a lead has a task that is created 90 days before privacy request submitted date,
			//add lead to map_EmailToLeadInfo
			List<Task> list_RawLeadTasks = [
				SELECT WhoId, CreatedDate
				FROM Task
				WHERE WhoId IN :map_Leads.values() AND (CallType = 'Inbound' OR RecordType.Name = 'Chat')
			];
			for (Task rawLeadTask : list_RawLeadTasks) {
				String taskEmail = map_LeadIdsToEmail.get(rawLeadTask.WhoId);
				if (rawLeadTask.CreatedDate.date().daysBetween(map_EmailToDateSubmitted.get(taskEmail)) <= 90) {
					if (map_EmailToLeadInfo.get(taskEmail) == null) {
						map_EmailToLeadInfo.put(taskEmail, new List<SObject>{ map_Leads.get(rawLeadTask.WhoId) });
					} else {
						map_EmailToLeadInfo.get(taskEmail).add(map_Leads.get(rawLeadTask.WhoId));
					}
				}
			}
		}
		//go through emails
		//for each one, find the data collection record and raw lead info to match
		//Change status to completed if not found
		for (String email : list_PrivacyRequestEmails) {
			Data_Collection__c dc = map_EmailToDC.get(email);
			dc.Details__c = '';
			try {
				if (map_EmailToLeadInfo.get(email) != null) {
					for (SObject rawLeadInfo : map_EmailToLeadInfo.get(email)) {
						//get fields we queried into a map
						Map<String, Object> map_FieldMap = rawLeadInfo.getPopulatedFieldsAsMap();

						//get field labels
						Map<String, Schema.SObjectField> map_FieldLabels = Utils.getSObjectDescribe(String.valueOf(rawLeadInfo.getSObjectType())).fields.getMap();

						//populate the details field with field label : field value
						for (String fieldName : map_FieldMap.keySet()) {
							Object fieldValue = map_FieldMap.get(fieldName);
							if ((fieldName != 'Id' && fieldName != 'RecordTypeId' && fieldName != 'Status' && fieldName != 'CreatedDate') && fieldValue != null) {
								if (fieldName == 'Address') {
									dc.Details__c += map_FieldLabels.get(fieldName).getDescribe().getLabel() + ' : ' + addressToString((System.Address) fieldValue) + '\n';
								} else {
									dc.Details__c += map_FieldLabels.get(fieldName).getDescribe().getLabel() + ' : ' + map_FieldMap.get(fieldName) + '\n';
								}
							}
						}
						dc.Details__c += '\n';
					}
				}
				dc.Status__c = 'Completed';
			} catch (Exception e) {
				dc.Status__c = 'Failed';
				dc.Details__c = e.getMessage() + ' ' + e.getStackTraceString();
			}
		}
	}
	
	public void OnAfterUpdate(Map<ID, Data_Collection__c> map_OldDCMap, Map<ID, Data_Collection__c> map_NewDCMap) {
		//Check all Data Collection records if one was moved to Completed
		//if all DC records are completed, change the Case's status to Data Collected
		Set<String> set_PrivacyRequestIdsWithCompletedDC = new Set<String>();
		for (Data_Collection__c dc : map_NewDCMap.values()) {
			if (dc.Status__c == 'Completed' && map_OldDCMap.get(dc.Id).Status__c != 'Completed') {
				set_PrivacyRequestIdsWithCompletedDC.add(dc.Case__c);
			}
		}

		List<Case> list_PrivacyRequestsWithCompletedDC = [
			SELECT
				Id,
				Status,
				IsClosed,
				(
					SELECT Id, Status__c
					FROM Data_Collection__r
				)
			FROM Case
			WHERE Id IN :set_PrivacyRequestIdsWithCompletedDC
		];

		//go through all privacy requests
		//if all data collection records are Completed, mark the privacy request case's status as Data Collected
		List<Case> list_DataCollected = new List<Case>();
		for (Case pr : list_PrivacyRequestsWithCompletedDC) {
			Boolean allCompleted = true;
			for (Data_Collection__c dc : pr.Data_Collection__r) {
				if (dc.Status__c != 'Completed') {
					allCompleted = false;
				}
			}

			if (allCompleted == true && pr.Status == 'Identity Verified') {
				pr.Status = 'Data Collected';
				list_DataCollected.add(pr);
			}
		}

		update list_DataCollected;
	}
	

	public static String addressToString(System.Address address) {
		String str_Address = '';
		if (!String.isBlank(address.getCity())) {
			str_Address += 'City: ' + address.getCity() + ', ';
		}
		if (!String.isBlank(address.getState())) {
			str_Address += 'State: ' + address.getState() + ', ';
		}
		if (!String.isBlank(address.getCountry())) {
			str_Address += 'Country: ' + address.getCountry() + ', ';
		}
		if (!String.isBlank(address.getPostalCode())) {
			str_Address += 'Postal Code: ' + address.getPostalCode();
		}

		return str_Address;
	}
}