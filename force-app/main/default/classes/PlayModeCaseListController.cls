public with sharing class PlayModeCaseListController {
	public string selectedCaseQueueId { get; set; }
	public integer pageSize { get; set; }
	public integer totalRecordsQueried { get; set; }
	public string currentCaseId { get; set; }
	public string currentCaseStatus { get; set; }

	//follows wether queue fields are populated for Logged in user
	public boolean isUserFieldsNull { get; set; }

	public string skipCaseId { get; set; }
	public string skipReason { get; set; }
	public string skipComment { get; set; }

	public string escalationCaseId { get; set; }
	public string escalationReason { get; set; }
	public string escalationComment { get; set; }

	// [SM] Added on 04/06/2020 for Play Mode changes for doing bulk assignments
	public string strPlaySize { get; set; }
	public string strCaseIds { get; set; }

	string allQueueIdString = ''; //using to store list of 'All Queue' ids string

	public PlayModeCaseListController() {
		isUserFieldsNull = false;
		pageSize = 10;
		totalRecordsQueried = 0;
		getcaseQueueList();
	}

	public ApexPages.StandardSetController setCon {
		get {
			set<string> queueSet = new Set<string>();
			string userId = UserInfo.getUserId();
			string queryString = ' Select ';

			for (Schema.FieldSetMember f : SObjectType.Case.FieldSets.Case_Play_List_View_Fields.getFields()) {
				queryString += f.getFieldPath() + ', ';
			}
			queryString += ' id, owner.Type,CaseNumber from Case ';
			//string queryString = 'select Id,CaseNumber,Subject,AccountId,ContactId,RecordTypeId,CreatedDate, owner.Type from Case ';

			//if this is first time we want to get the variable value based on User field value
			if (selectedCaseQueueId == null) {
				getcaseQueueList();
			}
			if (isUserFieldsNull) {
				return new ApexPages.StandardSetController(new List<case>());
			}

			if (selectedCaseQueueId == 'All') {
				for (string qId : allQueueIdString.split(';')) {
					queueSet.add(qId);
				}
			} else {
				queueSet.add(selectedCaseQueueId);
			}

			queryString += ' where OwnerId IN: queueSet and id not in (Select Case__c from Case_Skip_History__c where Case__r.OwnerId IN:queueSet and User__c=:userId ) Order By Priority_Number__c,CreatedDate ASC limit 1000';
			list<Case> tempCaseList = Database.query(queryString);
			setCon = new ApexPages.StandardSetController(tempCaseList);
			totalRecordsQueried = setCon.getResultSize();
			if (pageSize != null && pageSize > 0) {
				if (pageSize < 10)
					pageSize = 10;
				setCon.setPageSize(pageSize);
			} else {
				pageSize = 10; //default value
				setCon.setPageSize(10);
			}

			if (totalRecordsQueried <= pageSize) {
				pageSize = totalRecordsQueried;
			}

			return setCon;
		}
		set;
	}

	public List<Case> getCases() {
		return (List<Case>) setCon.getRecords();
	}

	//returns selectoption list for the logged-in user
	public list<SelectOption> getcaseQueueList() {
		allQueueIdString = '';
		list<SelectOption> queueList = new List<SelectOption>();

		User usrRec = [SELECT id, All_Queues__c, Individual_Queues__c FROM User WHERE Id = :UserInfo.getUserId()];

		if (usrRec.All_Queues__c != null && usrRec.All_Queues__c.length() > 0) {
			queueList.add(new SelectOption('All', 'All Queues'));
			if (selectedCaseQueueId == null) {
				selectedCaseQueueId = 'All';
			}
			for (Group qRec : [SELECT Type, Name, Id FROM Group WHERE type = 'Queue' AND Name IN :usrRec.All_Queues__c.split(';')]) {
				if (string.isBlank(allQueueIdString))
					allQueueIdString = qRec.Id;
				else
					allQueueIdString += ';' + qRec.Id;
			}
		}

		if (usrRec.Individual_Queues__c != null && usrRec.Individual_Queues__c.length() > 0) {
			for (Group qRec : [SELECT Type, Name, Id FROM Group WHERE type = 'Queue' AND Name IN :usrRec.Individual_Queues__c.split(';')]) {
				queueList.add(new SelectOption(qRec.id, qRec.Name));
			}
			if (selectedCaseQueueId == null) {
				selectedCaseQueueId = queueList.get(0).getValue();
			}
		}

		if (queueList.size() > 0) {
			isUserFieldsNull = false;
		} else {
			isUserFieldsNull = true;
		}
		return queueList;
	}

	public void getQueueRecords() {
		getcaseQueueList();
	}

	public void nextRecordInCasePlay() {
		boolean breakNext = false;
		list<Case> tempCaseList = getCases();
		if (tempCaseList != null && tempCaseList.size() > 0) {
			currentCaseId = tempCaseList.get(0).id;
		}
	}

	public void launchCasePlay() {
		User_Preference__c userPreference = new User_Preference__c();

		list<User_Preference__c> userList = [SELECT Id, Case_Play_Selected_Queues__c FROM User_Preference__c WHERE User__c = :UserInfo.getUserId()];
		if (userList.size() > 0) {
			userPreference = userList[0];
		} else {
			userPreference.User__c = UserInfo.getUserId();
		}

		string queStr;

		if (selectedCaseQueueId == 'All') {
			for (string qId : allQueueIdString.split(';')) {
				if (string.isBlank(queStr))
					queStr = qId;
				else
					queStr += ';' + qId;
			}
		}

		if (!string.isBlank(queStr)) {
			userPreference.Case_Play_Selected_Queues__c = queStr;
		} else {
			userPreference.Case_Play_Selected_Queues__c = selectedCaseQueueId;
		}

		set<string> queueSet = new Set<string>();
		if (userPreference.Case_Play_Selected_Queues__c.indexof(';') > 0) {
			queueSet.addAll(userPreference.Case_Play_Selected_Queues__c.split(';'));
		} else {
			queueSet.add(userPreference.Case_Play_Selected_Queues__c);
		}

		//Case assignRec = new Case(id=currentCaseId,OwnerId=userInfo.getUserId());

		try {
			upsert userPreference;
			currentCaseId = getNextCase();
			// [SM] Making changes here to ensure existing functionality anywhere does not break
			strCaseIds = String.isBlank(currentCaseId) ? '' : currentCaseId;
			Integer intPlaySize = Integer.valueOf(strPlaySize);
			if (String.isNotBlank(currentCaseId) && intPlaySize > 1) {
				String strRoutingReason = [SELECT Routing_Case_Reason__c FROM Case WHERE Id = :currentCaseId].Routing_Case_Reason__c;
				if (String.isNotBlank(strRoutingReason)) {
					List<Case> list_AdditionalCases = [
						SELECT Id
						FROM Case
						WHERE
							OwnerId IN :queueSet
							AND Owner.Type = 'Queue'
							AND Routing_Case_Reason__c = :strRoutingReason
							AND Id NOT IN (SELECT Case__c FROM Case_Skip_History__c WHERE Case__r.OwnerId IN :queueSet AND User__c = :UserInfo.getUserId())
						ORDER BY Priority_Number__c, CreatedDate ASC
						LIMIT :(intPlaySize - 1)
					];

					for (Case objCase : list_AdditionalCases) {
						objCase.OwnerId = UserInfo.getUserId();
						//objCase.Status= 'In Progress'; Only First case status should be 'In Progress'
						objCase.Assigned_by_Play_Mode__c = true;
						objCase.Play_Mode_Type__c = 'Swimlane';
					}
					if (!list_AdditionalCases.isEmpty())
						update list_AdditionalCases;

					// [SM] Constructing Ids string later to ensure update is successful before we try to open tabs.
					for (Case objCase : list_AdditionalCases)
						strCaseIds += ',' + objCase.Id;
				}
			}
		} catch (exception ex) {
		}
	}

	/** indicates whether there are more records after the current page set.*/
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	/** indicates whether there are more records before the current page set.*/
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	/** returns the page number of the current page set*/
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	/** return total number of pages for page set*/
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	/** returns the first page of the page set*/
	public void first() {
		// updateSearchItemsMap();
		setCon.first();
		getCases();
	}

	/** returns the last page of the page set*/
	public void last() {
		//updateSearchItemsMap();
		setCon.last();
		getCases();
	}

	/** returns the previous page of the page set*/
	public void previous() {
		//updateSearchItemsMap();
		setCon.previous();
		getCases();
	}

	/** returns the next page of the page set*/
	public void next() {
		// updateSearchItemsMap();
		//getCases();
		setCon.next();
	}

	@remoteAction
	public static void updateCaseStatus(string caseId, string selStatus) {
		if (!string.isBlank(caseId) && !string.isBlank(selStatus)) {
			Case caseRec = new Case(id = caseId, Status = selStatus);

			try {
				update caseRec;
			} catch (exception ex) {
			}
		}
	}

	@remoteAction
	public static string getCaseStatus(string caseId) {
		/**what is the purpose of this method**/
		string caseStatus;

		if (!string.isBlank(caseId)) {
			list<Case> caseList = [SELECT id, Status, OwnerId FROM Case WHERE Id = :caseId];
			if (caseList.size() > 0) {
				caseStatus = caseList.get(0).Status;
				if (string.valueof(caseList.get(0).OwnerId).StartsWith('00G') && caseList.get(0).OwnerId != userInfo.getUserId()) {
					Case assignRec = new Case(id = caseList.get(0).id, OwnerId = userInfo.getUserId());
					try {
						update assignRec;
						caseStatus += caseStatus + '#';
					} catch (exception ex) {
					}
				}
			}
		}

		return caseStatus;
	}

	@remoteAction
	public static string getNextCase() {
		string caseId;

		list<User_Preference__c> userList = [SELECT Id, Case_Play_Selected_Queues__c FROM User_Preference__c WHERE User__c = :UserInfo.getUserId()];
		if (userList.size() > 0) {
			User_Preference__c userPreference = userList[0];
			if (!string.isBlank(userPreference.Case_Play_Selected_Queues__c) && userPreference.Case_Play_Selected_Queues__c.length() > 0) {
				set<string> queueSet = new Set<string>();
				if (userPreference.Case_Play_Selected_Queues__c.indexof(';') > 0) {
					queueSet.addAll(userPreference.Case_Play_Selected_Queues__c.split(';'));
				} else {
					queueSet.add(userPreference.Case_Play_Selected_Queues__c);
				}

				if (queueSet != null && queueSet.size() > 0) {
					list<Case> tempCaseList = [
						SELECT id, Priority_Number__c, CreatedDate, OwnerId
						FROM Case
						WHERE OwnerId IN :queueSet AND id NOT IN (SELECT Case__c FROM Case_Skip_History__c WHERE Case__r.OwnerId IN :queueSet AND User__c = :userInfo.getUserId())
						ORDER BY Priority_Number__c, CreatedDate ASC
						LIMIT 20
					];

					for (Case c : tempCaseList) {
						if (tempCaseList.size() > 0 && string.valueof(c.OwnerId).StartsWith('00G') && c.OwnerId != userInfo.getUserId()) {
							CaseTriggerHelper.playmode = true;
							Case assignRec = new Case(id = c.id, OwnerId = userInfo.getUserId(), Status = 'In Progress', Assigned_by_Play_Mode__c = true, Play_Mode_Type__c = 'Swimlane');

							try {
								update assignRec;
								caseId = assignRec.id;
								break;
								//caseStatus += caseStatus+'#';
							} catch (exception ex) {
							}
						}
					}
				}
			}
		}

		return caseId;
	}

	//=======SkipCase component methods==============

	public list<selectOption> getcaseStatusPicklist() {
		List<SelectOption> options = new List<SelectOption>();

		Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), 'Submit as ' + f.getValue()));
		}

		return options;
	}

	public list<selectOption> getcaseSkipPicklist() {
		List<SelectOption> options = new List<SelectOption>();

		Schema.DescribeFieldResult fieldResult = Case_Skip_History__c.Skip_Reason__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), f.getValue()));
		}

		return options;
	}

	public void skipCaseRecord() {
		Case_Skip_History__c skipRec = new Case_Skip_History__c();
		skipRec.Case__c = skipCaseId;
		skipRec.User__c = userInfo.getUserId();
		//skipRec.Skip_Reason__c = skipReason;
		skipRec.Skip_Comment__c = skipComment;

		try {
			insert skipRec;
		} catch (exception ex) {
			return;
		}

		Case caseRec = new case(id = skipCaseId);
		caseRec.Last_Skipped_By__c = userInfo.getUserId();

		try {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Database.update(caseRec, dmo);
		} catch (exception ex) {
			return;
		}
	}

	//====caseEscalation component methods================

	public list<selectOption> getcaseEscalationReason() {
		List<SelectOption> options = new List<SelectOption>();

		Schema.DescribeFieldResult fieldResult = Case_Escalation__c.Escalation_Reason__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), f.getValue()));
		}

		return options;
	}

	public void escalateCaseRecord() {
		Case_Escalation__c escalationRec = new Case_Escalation__c();
		escalationRec.Case__c = escalationCaseId;
		escalationRec.Escalation_Reason__c = escalationReason;
		escalationRec.Escalation_Comments__c = escalationComment;
		escalationRec.Type__c = 'Task Us Escalation';

		try {
			insert escalationRec;
		} catch (exception ex) {
			return;
		}

		Case caseRec = new case(id = escalationCaseId, Escalated_By_Task_Us__c = true);

		try {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Database.update(caseRec, dmo);
		} catch (exception ex) {
			return;
		}
	}
}