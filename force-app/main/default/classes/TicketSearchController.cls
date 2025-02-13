public with sharing class TicketSearchController {
	public ApexPages.StandardSetController setCon { get; set; }
	public Ticket__c searchTicketVar { get; set; }
	public string selectedcompanyContactFilterStr { get; set; }
	public string selectedRecordTypeStr { get; set; }
	public string searchCriteriaStr { get; set; }
	public Ticket__c selectedTicketDetails { get; set; }
	public string selectedTicketId { get; set; }

	public string sortField { get; set; }
	String preSortField;
	String previousSortOrder;

	public List<String> recordTypeLeftSelected { get; set; }
	public List<String> recordTypeRightSelected { get; set; }
	Set<String> recordTypePicklistValues = new Set<String>();
	Set<String> recordTypeleftValues = new Set<String>();
	Set<String> recordTypeRightValues = new Set<String>();

	public List<String> statusLeftSelected { get; set; }
	public List<String> statusRightSelected { get; set; }
	Set<String> statusPicklistValues = new Set<String>();
	Set<String> statusLeftValues = new Set<String>();
	Set<String> statusRightValues = new Set<String>();

	string currentCaseId;

	public TicketSearchController() {
		searchTicketVar = new Ticket__c();
		selectedTicketDetails = new Ticket__c();

		//populateRecordType Filter set
		for (RecordType rec : [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Ticket__c' AND IsActive = TRUE]) {
			recordTypePicklistValues.add(rec.Name);
		}
		recordTypeLeftSelected = new List<String>();
		recordTypeRightSelected = new List<String>();
		recordTypeleftValues.addAll(recordTypePicklistValues);
		userDefaultRecordType();
		getSelectRecordType();

		statusPicklistValues = getStatusPickListValuesIntoList();
		statusLeftSelected = new List<String>();
		statusRightSelected = new List<String>();
		statusLeftValues.addAll(statusPicklistValues);
		selectedTicketId = userinfo.getUserId();
	}

	public List<SelectOption> getCommentDescriptionFilterList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('CommentDescription', 'Comments & Description'));
		options.add(new SelectOption('Comments', 'Comments'));
		options.add(new SelectOption('Description', 'Description'));
		return options;
	}

	public PageReference getSelectRecordType() {
		recordTypeRightSelected.clear();
		for (String s : recordTypeLeftSelected) {
			recordTypeleftValues.remove(s);
			recordTypeRightValues.add(s);
		}
		return null;
	}

	public PageReference getDeselectRecordType() {
		recordTypeLeftSelected.clear();
		for (String s : recordTypeRightSelected) {
			recordTypeRightValues.remove(s);
			recordTypeleftValues.add(s);
		}
		return null;
	}

	public List<SelectOption> getDeselectedRecordTypeValues() {
		List<SelectOption> options = new List<SelectOption>();
		List<String> objList = new List<String>();
		objList.addAll(recordTypeleftValues);
		objList.sort();
		for (String s : objList) {
			options.add(new SelectOption(s, s));
		}
		return options;
	}

	public List<SelectOption> getSelectedrecordTypeValues() {
		List<SelectOption> options = new List<SelectOption>();
		List<String> objList = new List<String>();
		objList.addAll(recordTypeRightValues);
		objList.sort();
		for (String s : objList) {
			options.add(new SelectOption(s, s));
		}
		return options;
	}

	public void userDefaultRecordType() {
		Schema.DescribeSObjectResult R = Ticket__c.SObjectType.getDescribe();
		List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
		for (Schema.RecordTypeInfo rec : RT) {
			if (rec.isDefaultRecordTypeMapping()) {
				recordTypeLeftSelected.add(rec.getName());
				break;
			}
		}
	}
	//========================
	public PageReference getSelectStatus() {
		StatusRightSelected.clear();
		for (String s : statusLeftSelected) {
			statusleftValues.remove(s);
			statusRightValues.add(s);
		}
		return null;
	}

	public PageReference getDeselectStatus() {
		statusLeftSelected.clear();
		for (String s : statusRightSelected) {
			statusRightValues.remove(s);
			statusLeftValues.add(s);
		}
		return null;
	}

	public List<SelectOption> getDeselectedStatusValues() {
		List<SelectOption> options = new List<SelectOption>();
		List<String> objList = new List<String>();
		objList.addAll(statusleftValues);
		objList.sort();
		for (String s : objList) {
			options.add(new SelectOption(s, s));
		}
		return options;
	}

	public List<SelectOption> getSelectedStatusValues() {
		List<SelectOption> options = new List<SelectOption>();
		List<String> objList = new List<String>();
		objList.addAll(statusRightValues);
		objList.sort();
		for (String s : objList) {
			options.add(new SelectOption(s, s));
		}
		return options;
	}
	//===========================
	public set<String> getStatusPickListValuesIntoList() {
		set<String> pickListValuesList = new Set<String>();
		Schema.DescribeFieldResult fieldResult = Ticket__c.Status__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			pickListValuesList.add(pickListVal.getLabel());
		}
		return pickListValuesList;
	}

	public void searchRecords() {
		if (string.isBlank(sortField)) {
			sortField = 'createdDate';
		}

		set<id> ticketRecIdSet = new Set<id>();
		string tempQueryStr;
		if (string.isNotBlank(searchTicketVar.Description__c)) {
			if (searchTicketVar.Description__c.length() == 1) {
				apexPages.addMessage(new apexPages.message(apexPages.severity.error, 'Search string should be more than one character long.'));
				return;
			}

			if (String.isNotBlank(searchCriteriaStr) && searchCriteriaStr.indexOf('Description') > -1) {
				tempQueryStr = 'Find {*' + searchTicketVar.Description__c + '*}  RETURNING Ticket__c(id) ';
				for (Ticket__c rec : (Ticket__c[]) search.query(tempQueryStr).get(0)) {
					ticketRecIdSet.add(rec.id);
				}
			}

			if (String.isNotBlank(searchCriteriaStr) && searchCriteriaStr.indexOf('Comment') > -1) {
				tempQueryStr = 'Find {*' + searchTicketVar.Description__c + '*}  RETURNING FeedItem(id,parentId) ';
				String ticketPrifix = Ticket__c.getSObjectType().getDescribe().getKeyPrefix();
				for (FeedItem rec : (FeedItem[]) search.query(tempQueryStr).get(0)) {
					if (rec.parentId != null && String.valueof(rec.parentId).indexof(ticketPrifix) == 0) {
						ticketRecIdSet.add(rec.parentId);
					}
				}
			}
		}

		String strFilter = '';

		string queryStr = ' SELECT Id, name, Description__c,CreatedDate FROM ticket__c WHERE ownerId != null ';

		if (searchTicketVar.Due_Date__c != null) {
			Datetime startDateTime = datetime.newInstance(searchTicketVar.Due_Date__c.year(), searchTicketVar.Due_Date__c.month(), searchTicketVar.Due_Date__c.day());
			strFilter = strFilter + ' AND CreatedDate >: startDateTime ';
		}

		if (searchTicketVar.Close_Date__c != null) {
			Datetime endDateTime = datetime.newInstance(searchTicketVar.Close_Date__c.year(), searchTicketVar.Close_Date__c.month(), searchTicketVar.Close_Date__c.day());
			strFilter = strFilter + ' AND CreatedDate <: endDateTime ';
		}

		if (statusRightValues != null && statusRightValues.size() > 0) {
			strFilter += ' and Status__c IN: statusRightValues ';
		}

		if (recordTypeRightValues != null && recordTypeRightValues.size() > 0) {
			strFilter += ' and recordType.Name IN: recordTypeRightValues ';
		}

		if (ticketRecIdSet.size() > 0) {
			strFilter += ' and id IN: ticketRecIdSet ';
		}

		string reportingTeamStr = searchTicketVar.Reporting_Team__c;
		string errorOriginStr = searchTicketVar.Reporting_Team__c;
		string escalationReasonStr = searchTicketVar.Escalation_Reason__c;
		string escalationreasonDetailStr = searchTicketVar.Escalation_Reason_Detail__c;

		if (string.isNotBlank(searchTicketVar.Reporting_Team__c)) {
			strFilter += ' and Reporting_Team__c =: reportingTeamStr ';
		}

		if (string.isNotBlank(searchTicketVar.Error_Origin__c)) {
			strFilter += ' and Error_Origin__c =: errorOriginStr ';
		}

		if (string.isNotBlank(searchTicketVar.Escalation_Reason__c)) {
			strFilter += ' and Escalation_Reason__c =: escalationReasonStr ';
		}

		if (string.isNotBlank(searchTicketVar.Escalation_Reason_Detail__c)) {
			strFilter += ' and Escalation_Reason_Detail__c =: escalationreasonDetailStr ';
		}

		queryStr = queryStr + strFilter;

		if (string.isNotBlank(sortField)) {
			if (preSortField == sortField && previousSortOrder == 'ASC') {
				previousSortOrder = 'DESC';
			} else {
				previousSortOrder = 'ASC';
			}
			preSortField = sortField;
			queryStr += ' order by ' + sortField + ' ' + previousSortOrder + ' NULLS LAST ';
		}

		setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr));
		setCon.setPageSize(20);
	}

	public list<TicketWrapper> ticketList {
		get {
			if (setCon != null) {
				list<TicketWrapper> list_TicketWrapper = new List<TicketWrapper>();
				for (Ticket__c rec : (List<Ticket__c>) setCon.getRecords()) {
					TicketWrapper wrapperRec = new TicketWrapper();
					wrapperRec.objTicketRec = rec;
					if (string.isNotBlank(rec.Description__c) && rec.Description__c.length() > 80) {
						wrapperRec.strDescription = rec.Description__c.substring(0, 80);
					} else {
						wrapperRec.strDescription = rec.Description__c;
					}
					list_TicketWrapper.add(wrapperRec);
				}
				return list_TicketWrapper;
			} else {
				return null;
			}
		}
		set;
	}

	public class TicketWrapper {
		public Ticket__c objTicketRec { get; set; }
		public string strDescription { get; set; }

		public TicketWrapper() {
		}
	}
}