public class AttachmentRelatedAccountCasesController {
	public ApexPages.StandardSetController setCon { get; set; }
	String caseId;
	public String strSearch { get; set; }
	public String filterQuery { get; set; }
	string sortField;
	String preSortField;
	String previousSortOrder;
	public String filter { get; set; }
	public Case objCase { get; set; }

	public List<SelectOption> getItems() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Company', 'Company'));
		options.add(new SelectOption('Contact', 'Contact'));
		options.add(new SelectOption('CompanyContact', 'Company & Contact'));
		return options;
	}

	public list<EmailMessage> allEmailMessageList {
		get {
			if (setCon != null) {
				List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
				List<EmailMessage> allEmailMessage = setCon.getRecords();
				if (allEmailMessage != null && allEmailMessage.size() > 0) {
					for (EmailMessage em : allEmailMessage) {
						if (em.Attachments != null && em.Attachments.size() > 0) {
							lstEmailMessage.add(em);
						}
					}
				}
				return lstEmailMessage;
			} else {
				return null;
			}
		}
		set;
	}

	public AttachmentRelatedAccountCasesController() {
		sortField = '';
		strSearch = '';
		objCase = new Case();
		caseId = apexPages.currentPage().getParameters().get('id');
		init();
	}

	public void init() {
		sortField = apexPages.currentPage().getParameters().get('sortField');
		Case cseObj = [SELECT Id, AccountId, ContactId FROM Case WHERE Id = :caseId];
		String AccountId = cseObj.AccountId;
		String ContactId = cseObj.ContactId;
		Boolean skipQuery = false;

		//string queryStr = 'select Id, Subject, Status, MessageDate, ParentId, Parent.Account.Name, Parent.Contact.Name, (Select Id, Name From Attachments) From EmailMessage Where (Parent.AccountId =: AccountId)';
		String strFilter = '';
		strFilter = ' where Name like \'%' + strSearch + '%\'';

		String queryStr =
			'SELECT Id, Subject, Status, MessageDate, ParentId, parent.CaseNumber, Parent.Account.Name, Parent.Contact.Name, Incoming, CreatedDate, (SELECT Id, Name FROM Attachments' +
			strFilter +
			') FROM EmailMessage WHERE HasAttachment = true';
		if (String.isNotBlank(filter)) {
			if (filter == 'Contact' && String.isNotBlank(ContactId)) {
				filterQuery = ' AND (Parent.ContactId =: ContactId)';
			} else if (filter == 'Company' && String.isNotBlank(AccountId)) {
				filterQuery = ' AND (Parent.AccountId =: AccountId)';
			} else if (String.isNotBlank(AccountId)) {
				filterQuery = ' AND (Parent.AccountId =: AccountId AND Parent.ContactId =: ContactId)';
			}
		} else if (String.isNotBlank(AccountId)) {
			filterQuery = ' AND (Parent.AccountId =: AccountId)';
		} else {
			skipQuery = true;
		}

		if (objCase.Created_At_Date__c != null) {
			Datetime startDateTime = datetime.newInstance(objCase.Created_At_Date__c.year(), objCase.Created_At_Date__c.month(), objCase.Created_At_Date__c.day());
			filterQuery = filterQuery + ' AND CreatedDate >: startDateTime';
		}

		if (objCase.Anticipated_Effective_Date__c != null) {
			Datetime endDateTime = datetime.newInstance(objCase.Anticipated_Effective_Date__c.year(), objCase.Anticipated_Effective_Date__c.month(), objCase.Anticipated_Effective_Date__c.day());
			filterQuery = filterQuery + ' AND CreatedDate <: endDateTime';
		}

		queryStr = queryStr + filterQuery;

		if (String.isNotBlank(sortField)) {
			if (preSortField == sortField && previousSortOrder == 'ASC') {
				previousSortOrder = 'DESC';
			} else {
				previousSortOrder = 'ASC';
			}
			preSortField = sortField;
			queryStr += ' order by ' + sortField + ' ' + previousSortOrder + ' NULLS LAST ';
		}
		if (!skipQuery) {
			setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr));
		}
	}

	// returns the previous page of records
	public void previous() {
		setCon.previous();
	}

	// returns the next page of records
	public void next() {
		setCon.next();
	}
}