public with sharing class CaseContactSearchController {
	//component variables
	public String openCaseId { get; set; }
	public String initialPhone { get; set; }
	public String callbackSource { get; set; }
	public String userAuth { get; set; }
	public String userAuthColor { get; set; }
	public String authUserEmail { get; set; }
	public Contact newContact { get; set; }
	public String selectedContactAccount { get; set; }

	public String searchStr { get; set; }
	public String selectedContactId { get; set; }
	public Map<Id, String> conIdAccountRelationshipDetailMap { get; set; }

	List<Contact> contctList = new List<Contact>();
	private ApexPages.StandardSetController setCon { get; set; }
	private String parameters { get; set; }

	public list<SelectOption> contactSearchFilters { get; set; }

	public CaseContactSearchController() {
		newContact = new Contact();
		conIdAccountRelationshipDetailMap = new Map<id, String>();
		parameters = '' + ApexPages.currentPage().getParameters();

		if (String.isNotBlank(initialPhone) && initialPhone.length() > 9) {
			initialPhone = initialPhone.right(10);
		}

		if (ApexPages.currentPage().getParameters().get('ZPUseremail') != null) {
			authUserEmail = ApexPages.currentPage().getParameters().get('ZPUseremail');
		}

		callbackSource = '';
		if (ApexPages.currentPage().getParameters().get('src') != null) {
			callbackSource = ApexPages.currentPage().getParameters().get('src');
		}
		if (callbackSource == 'SF') {
			callbackSource = 'Salesforce Callback';
		} else if (callbackSource == 'Bot') {
			callbackSource = 'Support Bot';
		}

		contctList = new List<Contact>();

		if (userAuth != null) {
			String tempStr = userAuth;
			if (tempStr.equalsIgnoreCase('token match')) {
				userAuth = 'Token Match';
				userAuthColor = 'yellow';
			} else if (tempStr.equalsIgnoreCase('authenticated')) {
				userAuth = 'Autheticated';
				userAuthColor = 'lightgreen';
			} else {
				userAuth = 'Not Authenticated';
				userAuthColor = 'lightcoral';
			}
		}
		contactSearchFilters = new List<SelectOption>();
		contactSearchFilters.add(new SelectOption('Email', 'Email'));
		contactSearchFilters.add(new SelectOption('Full Name', 'Full Name'));
		contactSearchFilters.add(new SelectOption('Full Name', 'Full Name'));
	}

	public PageReference initialSearch() {
		return null;
	}

	public PageReference searchContact() {
		list<String> conIdList = new List<String>();
		String strFilter;

		if (String.isBlank(searchStr)) {
			searchStr = initialphone;
		}

		if (String.isnotBlank(searchStr)) {
			if (searchStr.length() == 1) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Search string should be more than one character long.'));
				setCon = new ApexPages.StandardSetController(new List<Contact>());
				return null;
			}

			String regexstr = '[a-zA-Z0-9@_. ]+';
			Pattern aplhaNumericPatternStr = Pattern.compile(regexstr);
			Matcher matcherStr = aplhaNumericPatternStr.matcher(searchStr);
			boolean matchResult = matcherStr.matches();

			if (!matchResult) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Please skip special characters while searching.'));
				setCon = new ApexPages.StandardSetController(new List<Contact>());
				return null;
			}

			String searchStr1 = '{*' + searchStr + '*}';
			String soslString = 'FIND  ' + searchStr1 + ' IN All Fields RETURNING Contact(Id) ';

			List<List<sObject>> searchQueryResults = search.query(soslString);
			if (searchQueryResults.size() > 0) {
				for (Contact conrec : (Contact[]) searchQueryResults.get(0)) {
					conIdList.add(conrec.id);
				}
			}

			if (conIdList.size() > 0) {
				strFilter = ' where id in: conIdList order by FirstName ASC NULLS LAST  limit 25 ';
			} else {
				strFilter = '';
			}
		} else {
			strFilter = '';
		}

		if (String.isNotBlank(strFilter)) {
			String queryStr =
				'SELECT Id, Name, FirstName, Phone, Otherphone, LastName, Birthdate, SSN_Last_4__c, Email, AccountId, Account.Name, Normalized_Phone__c, Normalized_Other_Phone__c, MobilePhone, Normalized_Mobile_Phone__c, Account.ZP_Firm_ID__c, Account.ZP_Company_ID__c,(Select id,CaseNumber from cases where isClosed=false),(select id,Account.name,ContactId,Roles from AccountContactRelations where IsActive=true) from Contact ' +
				strFilter;
			try {
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr));
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
			}

			//setCon.setPageSize(20);
		} else {
			//apexPages.StandardSetController
			setCon = new ApexPages.StandardSetController(new List<Contact>());
		}

		return null;
	}

	public List<Contact> contactSearchList {
		get {
			if (setCon != null) {
				contctList = (List<Contact>) setCon.getRecords().deepClone(true, true, true);
				for (Contact oldCnt : contctList) {
					conIdAccountRelationshipDetailMap.put(oldCnt.id, ' ');
					if (oldCnt.AccountContactRelations != null && oldCnt.AccountContactRelations.size() > 0) {
						String relationShipStr = ' ';
						for (AccountContactRelation rel : oldCnt.AccountContactRelations) {
							if (conIdAccountRelationshipDetailMap.containsKey(rel.ContactId) && String.isblank(relationShipStr)) {
								relationShipStr = conIdAccountRelationshipDetailMap.get(rel.ContactId);
							}
							if (String.isblank(relationShipStr)) {
								relationShipStr = '<b>' + rel.Account.name.escapeHtml4() + ':</b> ' + (rel.roles != null ? rel.roles : '-');
							} else {
								relationShipStr += ' |<b>' + rel.Account.name.escapeHtml4() + ':</b> ' + (rel.roles != null ? rel.roles : '-');
							}
						}
						conIdAccountRelationshipDetailMap.put(oldCnt.id, relationShipStr.trim());
					}
				}
				return contctList;
			} else
				return null;
		}
		set;
	}

	public void updateCaseWithContact() {
		if (String.isnotblank(selectedContactId) && String.isnotblank(openCaseId)) {
			Case tempCaseRec = new Case(id = openCaseId, ContactId = selectedContactId);

			update tempCaseRec;
		} else {
			// apexPages
		}
	}

	public void addUserPopulateField() {
		if (String.isNotBlank(selectedContactAccount)) {
			newContact.AccountId = selectedContactAccount;
		}
	}

	public void createAssignContact() {
		if (newContact.LastName != null) {
			try {
				insert newContact;
				selectedContactId = newContact.id;
				updateCaseWithContact();
			} catch (exception ex) {
				apexpages.addmessage(new apexPages.message(apexPages.severity.error, 'Unexpected error occured while creating new customer, Please contact system admin. ' + ex.getMessage()));
			}
		}
	}

	public void handleUnknowUser() {
		if (String.isnotblank(openCaseId)) {
			Case tempCaseRec = new Case(id = openCaseId, Status = 'Solved', Confirm_Case_Reason__c = 'Unknown Caller', Audience__c = 'Other/Unknown');
			try {
				update tempCaseRec;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
			}
		}
	}

	/*
	 * Wrapper Class used to nurture autocomplete
	 */
	public with sharing class searchContactWrapper {
		public String idd;
		public String accname;
		public String name;
		public String email;
		public String firstname;
		public String lastname;
		public String phone;
	}

	@RemoteAction
	public static set<searchContactWrapper> getPotentialContacts(String searchterm) {
		if (String.isBlank(searchterm)) {
			return null;
		}

		// to avoid duplicate results
		Map<String, searchContactWrapper> uniqueSearchResult = new Map<String, searchContactWrapper>();

		String searchtermWithWildcard = '%' + searchterm + '%';
		set<searchContactWrapper> contacts = new Set<searchContactWrapper>();

		// first, search in contacts

		for (Contact con : [
			SELECT Name, FirstName, LastName, Email, Phone, Account.Name, Normalized_Phone__c
			FROM Contact
			WHERE
				Email LIKE :searchtermWithWildcard
				OR Account.Name LIKE :searchtermWithWildcard
				OR Normalized_Phone__c LIKE :searchtermWithWildcard
				OR Name LIKE :searchtermWithWildcard
				OR firstName LIKE :searchtermWithWildcard
				OR lastName LIKE :searchtermWithWildcard
			ORDER BY FirstName ASC
			LIMIT 15
		]) {
			searchContactWrapper u = new searchContactWrapper();
			u.phone = con.Normalized_Phone__c;
			u.lastname = con.lastname;
			u.email = con.Email;
			u.name = con.name;
			u.idd = con.id;
			u.accname = con.Account.Name;

			contacts.add(u);
		}

		return contacts;
	}
}