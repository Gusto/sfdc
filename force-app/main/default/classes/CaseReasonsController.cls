public with sharing class CaseReasonsController {
	id accountId;
	public id contactId { get; private set; }
	Contact cntct;
	public ApexPages.StandardSetController caseSet { get; set; }
	public case filterCase { get; set; }
	public boolean filterByContact { get; set; }

	public string recordTypeFilter { get; set; }

	public list<selectOption> recordTypeOptionList { get; set; }
	public list<selectOption> caseStatusOptionList { get; set; }
	public list<selectOption> caseOriginOptionList { get; set; }

	public CaseReasonsController(apexPages.standardController sc) {
		cntct = new Contact();
		filterByContact = false;
		String recordId = sc.getId();
		if (recordId.indexOf('001') == 0) {
			accountId = sc.getId();
		} else if (recordId.indexOf('003') == 0) {
			cntct = (Contact) sc.getRecord();
			accountId = cntct.AccountId;
			contactId = cntct.Id;
			filterByContact = true;
		}

		filterCase = new Case();

		recordTypeOptionList = new List<selectOption>();
		caseStatusOptionList = new List<selectOption>();
		caseOriginOptionList = new List<selectOption>();

		recordTypeOptionList.add(new SelectOption('1', '--None--'));
		caseStatusOptionList.add(new SelectOption('1', '--None--'));
		caseOriginOptionList.add(new SelectOption('1', '--None--'));

		for (RecordType rec : [SELECT SobjectType, Name, IsActive, Id, DeveloperName FROM RecordType WHERE SobjectType = 'Case' AND IsActive = TRUE]) {
			recordTypeOptionList.add(new SelectOption(rec.id, rec.Name));
		}

		caseStatusOptionList.addAll(getCaseStatusList());
		caseOriginOptionList.addAll(getCaseOriginList());
		getCaseList();
	}

	public List<SelectOption> getCaseStatusList() {
		List<SelectOption> options = new List<SelectOption>();

		Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), f.getValue()));
		}
		return options;
	}

	public List<SelectOption> getCaseOriginList() {
		List<SelectOption> options = new List<SelectOption>();

		Schema.DescribeFieldResult fieldResult = Case.Origin.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for (Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), f.getValue()));
		}
		return options;
	}

	public PageReference getCaseList() {
		String query = '';
		query = 'select id, caseNumber, RecordTypeId, RecordType.Name, Status,Origin, CreatedDate, subject ';
		query += ' from Case where AccountId =:accountId ';

		// = string.valueof(filterCase.RecordTypeId);
		string statusFilter = filterCase.Status;
		string originFilter = filterCase.origin;
		date cdateFilter = filterCase.Created_At_Date__c;

		if (!string.isblank(recordTypeFilter) && recordTypeFilter.length() >= 15) {
			query += '  and RecordTypeId=:recordTypeFilter ';
		} else {
			filterCase.RecordTypeId = null;
		}

		if (!string.isblank(statusFilter) && statusFilter != '1') {
			query += '  and Status=:statusFilter ';
		}

		if (!string.isblank(originFilter) && originFilter != '1') {
			query += '  and Origin=:originFilter ';
		}

		if (filterByContact == true) {
			query += '  and ContactId=:contactId ';
		}

		if (!string.isblank(string.valueof(cdateFilter))) {
			DateTime startOfDT = DateTime.newInstanceGMT(cdateFilter.year(), cdateFilter.month(), cdateFilter.day(), 0, 0, 0);
			DateTime endOfDT = DateTime.newInstanceGMT(cdateFilter.year(), cdateFilter.month(), cdateFilter.day(), 23, 59, 59);

			Timezone tz = UserInfo.getTimeZone();
			query += '  and CreatedDate>=:startOfDT and CreatedDate<=:endOfDT ';
		}

		query += ' order by createddate desc';
		caseSet = new ApexPages.StandardSetController(Database.getQueryLocator(query));
		caseSet.setPageSize(20);
		return null;
	}

	public List<Case> accountCaseList {
		get {
			if (caseSet != null) {
				return (List<Case>) caseSet.getRecords();
			} else
				return null;
		}
		set;
	}

	public void searchCase() {
		getCaseList();
	}
}