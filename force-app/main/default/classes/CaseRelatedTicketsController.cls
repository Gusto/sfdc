public with sharing class CaseRelatedTicketsController {
	public ApexPages.StandardSetController setCon { get; set; }
	public Ticket__c searchTicketVar { get; set; }
	public String selectedcompanyContactFilterStr { get; set; }
	public String selectedRecordTypeStr { get; set; }
	public String sortField { get; set; }
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

	String currentCaseId;

	public CaseRelatedTicketsController() {
		searchTicketVar = new Ticket__c();
		currentCaseId = apexPages.currentPage().getparameters().get('id');
	}

	public List<SelectOption> getCompanyContactFilterList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Company', 'Company'));
		options.add(new SelectOption('Contact', 'Contact'));
		options.add(new SelectOption('CompanyContact', 'Company & Contact'));
		return options;
	}

	public void searchRecords() {
		if (currentCaseId != null && currentCaseId.indexof('500') == 0) {
			if (String.isBlank(sortField)) {
				sortField = 'createdDate';
			}

			if (String.isBlank(selectedcompanyContactFilterStr)) {
				selectedcompanyContactFilterStr = 'Company';
			}

			Case cseObj = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :currentCaseId];
			String AccountId = cseObj.AccountId;
			String ContactId = cseObj.ContactId;

			set<id> ticketRecIdSet = new Set<id>();
			if (String.isNotBlank(searchTicketVar.Description__c)) {
				String tempQueryStr = 'Find {*' + searchTicketVar.Description__c + '*}  RETURNING Ticket__c(id) ';
				for (Ticket__c rec : (Ticket__c[]) search.query(tempQueryStr).get(0)) {
					ticketRecIdSet.add(rec.id);
				}

				tempQueryStr = 'Find {*' + searchTicketVar.Description__c + '*}  RETURNING FeedItem(id,parentId) ';
				String ticketPrifix = Utils.getSObjectDescribe('Ticket__c').getKeyPrefix();
				for (FeedItem rec : (FeedItem[]) search.query(tempQueryStr).get(0)) {
					if (rec.parentId != null && String.valueof(rec.parentId).indexof(ticketPrifix) == 0) {
						ticketRecIdSet.add(rec.parentId);
					}
				}
			}

			String strFilter = '';

			String queryStr = ' select Id, name, Case__c,Case__r.CaseNumber, RecordTypeId, RecordType.Name,Description__c,Escalation_Reason__c,status__c,CreatedDate From ticket__c where Case__c != null ';
			if (String.isNotBlank(selectedcompanyContactFilterStr) && selectedcompanyContactFilterStr != '0') {
				if (selectedcompanyContactFilterStr == 'Contact') {
					strFilter = ' AND (Case__r.ContactId =: ContactId) ';
				} else if (selectedcompanyContactFilterStr == 'Company') {
					strFilter = ' AND (Case__r.AccountId =: AccountId) ';
				} else {
					strFilter = ' AND (Case__r.AccountId =: AccountId AND Case__r.ContactId =: ContactId) ';
				}
			}

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

			queryStr = queryStr + strFilter;

			if (String.isNotBlank(sortField)) {
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
	}

	public list<Ticket__c> ticketList {
		get {
			if (setCon != null) {
				list<Ticket__c> tempList = new List<Ticket__c>();
				for (Ticket__c rec : (List<Ticket__c>) setCon.getRecords()) {
					if (String.isNotBlank(rec.Description__c) && rec.Description__c.length() > 80) {
						rec.Description__c = rec.Description__c.subString(0, 80);
					}
					tempList.add(rec);
				}
				return tempList;
			} else {
				return null;
			}
		}
		set;
	}
}