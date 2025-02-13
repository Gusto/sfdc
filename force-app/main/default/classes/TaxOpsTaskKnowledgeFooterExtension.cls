public with sharing class TaxOpsTaskKnowledgeFooterExtension {
	public string searchStr { get; set; }
	public String primaryCaseId { get; set; }
	public string selectedSortFilter { get; set; }
	public List<String> aticlesTitleList { get; set; }
	public boolean isTaxOpsTask { get; set; }
	boolean isPageLoad;

	public ApexPages.StandardSetController articleController { get; set; }

	//constructor
	public TaxOpsTaskKnowledgeFooterExtension() {
		selectedSortFilter = 'Title: A to Z';
		isPageLoad = true;
		isTaxOpsTask = false;
		getKnowledgeArticle();
	}

	public void getKnowledgeArticle() {
		articleKnowledgeDetailList = new List<articleDetail>();
		aticlesTitleList = new List<string>();
	}

	/* this method is getting called from page via jquery document ready event
        In this method we are creating the query string based on planned logic and querying the knowledge articles 
        in the end.
    */
	public void populateArticleDetails() {
		string queryStr;

		if (primaryCaseId != null && primaryCaseId.indexof(Case.SObjectType.getDescribe().getKeyPrefix()) == 0) {
			queryStr = 'Select id,Article_Category__c,Description__c,External_Id__c, UrlName, FirstPublishedDate, ' + ' Title,KnowledgeArticleId From Help__kav  WHERE PublishStatus = \'Online\'  ';
		} else if (primaryCaseId != null && primaryCaseId.indexof(Tax_Ops_Task__c.SObjectType.getDescribe().getKeyPrefix()) == 0) {
			queryStr = 'Select id,Article_Category__c,Description__c, UrlName, FirstPublishedDate, ' + ' Title,KnowledgeArticleId From Tax_Ops_Instructions__kav  WHERE PublishStatus = \'Online\'  ';
		} else {
			return;
		}

		boolean searchFromCase = false;
		//for the first time on page load we want to show relevent article records
		list<Case> caseList = new List<Case>();
		list<Tax_Ops_Task__c> taxopstaskList = new List<Tax_Ops_Task__c>();
		if (primaryCaseId != null && string.isBlank(searchStr) && isPageLoad) {
			if (primaryCaseId != null && primaryCaseId.indexof(Case.SObjectType.getDescribe().getKeyPrefix()) == 0) {
				caseList = [SELECT id, Subject, Routing_Case_Reason__c FROM Case WHERE id = :primaryCaseId];
				if (caseList.size() > 0) {
					searchStr = caseList.get(0).Subject;
					searchFromCase = true;
				}
			} else {
				if (primaryCaseId != null && primaryCaseId.indexof(Tax_Ops_Task__c.SObjectType.getDescribe().getKeyPrefix()) == 0) {
					taxopstaskList = [SELECT id, Tax_Code__c, Process_Step__c, Filing_Method__c, Form_Code__c FROM Tax_Ops_Task__c WHERE id = :primaryCaseId];
					if (taxopstaskList.size() > 0) {
						searchStr = taxopstaskList.get(0).Tax_Code__c;
						searchFromCase = true;
						isTaxOpsTask = true;
					}
				}
			}
		}

		string tempSearchString = searchStr;

		if (tempSearchString != null) {
			tempSearchString = '% ' + tempSearchString + '%';
			string firstWord = searchStr + '%';
			if (!(taxopstaskList.size() > 0)) {
				queryStr += ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
			}

			if (searchFromCase && caseList.size() > 0) {
				if (caseList.get(0).Routing_Case_Reason__c != null && caseList.get(0).Routing_Case_Reason__c.length() > 0) {
					string crrStr = '% ' + caseList.get(0).Routing_Case_Reason__c + '%';
					string crrFirstWord = caseList.get(0).Routing_Case_Reason__c + '%';
					queryStr += ' and (Title Like:tempSearchString or Title Like: firstWord or Title like:crrStr or Title like: crrFirstWord ) ';
				} else {
					queryStr += ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
				}
			} else if (searchFromCase && taxopstaskList.size() > 0) {
				integer presenceDegree = getTaxOpsTaskArticlesPresenceInfo(taxopstaskList.get(0));
				string formCodeStr = taxopstaskList.get(0).Form_Code__c;
				string taxcodeStr = taxopstaskList.get(0).Tax_Code__c;
				string processStepStr = taxopstaskList.get(0).Process_Step__c;
				string filingMethodStr = taxopstaskList.get(0).Filing_Method__c;
				if (presenceDegree == 4) {
					queryStr +=
						' and (Form_Code__c like \'' +
						formCodeStr +
						'\' and Tax_Code__c like \'' +
						taxcodeStr +
						'\' and Process_Step__c like \'' +
						processStepStr +
						'\' and Filing_Method__c like \'' +
						filingMethodStr +
						'\' ) ';
				} else if (presenceDegree == 3) {
					queryStr +=
						' and (Tax_Code__c like \'' +
						taxcodeStr +
						'\' and Process_Step__c like \'' +
						processStepStr +
						'\' and Filing_Method__c like \'' +
						filingMethodStr +
						'\' and Form_Code__c = null) ';
				} else if (presenceDegree == 2) {
					queryStr += ' and (Process_Step__c like \'' + processStepStr + '\' and Filing_Method__c like \'' + filingMethodStr + '\' and Form_Code__c = null and Tax_Code__c = null) ';
				} else if (presenceDegree == 1) {
					queryStr += ' and (Process_Step__c like \'' + processStepStr + '\' and Form_Code__c = null and Tax_Code__c = null and Filing_Method__c = null) ';
				} else {
					queryStr += ' and (Tax_Code__c Like \'Generic\' ) ';
				}
			} else {
				queryStr += ' and (Title Like:tempSearchString or Title Like: firstWord ) ';
			}
		}

		queryStr += ' and language=\'en_US\' ';

		if (selectedSortFilter == 'Title: A to Z') {
			queryStr += ' Order By Title ASC ';
		} else if (selectedSortFilter == 'Title: Z to A') {
			queryStr += ' Order By Title Desc ';
		} /*
        else if(selectedSortFilter == 'Published Date'){
            queryStr += ' Order By FirstPublishedDate ASC ';
        }*/
		else if (selectedSortFilter == 'External') {
			queryStr += ' and Article_Category__c != \'Internal\' Order By Title ASC ';
		} else if (selectedSortFilter == 'Internal') {
			queryStr += ' and Article_Category__c = \'Internal\' Order By Title ASC ';
		}

		string autocompleteQueryStr;
		if (primaryCaseId != null && primaryCaseId.indexof(Case.SObjectType.getDescribe().getKeyPrefix()) == 0) {
			autocompleteQueryStr = 'select id,Title from Help__kav where PublishStatus=\'Online\' and language=\'en_US\' ';
		} else {
			autocompleteQueryStr = 'select id,Title from Tax_Ops_Instructions__kav where PublishStatus=\'Online\' and language=\'en_US\' ';
		}

		if (selectedSortFilter == 'External') {
			autocompleteQueryStr += ' and Article_Category__c != \'Internal\' Order By Title ASC ';
		} else if (selectedSortFilter == 'Internal') {
			autocompleteQueryStr += ' and Article_Category__c = \'Internal\' Order By Title ASC ';
		}

		aticlesTitleList = new List<string>();
		if (primaryCaseId != null && primaryCaseId.indexof(Case.SObjectType.getDescribe().getKeyPrefix()) == 0) {
			for (Help__kav rec : database.query(autocompleteQueryStr)) {
				aticlesTitleList.add(rec.title);
			}
		} else {
			for (Tax_Ops_Instructions__kav rec : database.query(autocompleteQueryStr)) {
				aticlesTitleList.add(rec.title);
			}
		}

		articleController = new ApexPages.StandardSetController(Database.getQueryLocator(queryStr));
		articleController.setPageSize(9);

		if (searchFromCase) {
			searchStr = null;
		}

		isPageLoad = false;
	}

	public void searchArticle() {
		if (!string.isBlank(searchStr)) {
			populateArticleDetails();
		}
	}

	/*
    we want to show the most relevent article to the user. Relevence is based on following logic
    1 Where Form Code, Tax Code, Filing Method, Process Step matches
    2 where Tax Code, Filing Method, Process Step matches and Form Code is blank
    3 where Filing Method, Process Step matches and Form Code, Tax Code are blank
    4 where Process Step matches and Form Code, Tax Code, Filing Method are blank
    We query the articles based on above logic and if we find any records the following method returns relevent information back
    */
	public integer getTaxOpsTaskArticlesPresenceInfo(Tax_Ops_Task__c taskRec) {
		if (taskRec != null && taskRec.id != null) {
			Database.QueryLocator helpList;

			string queryTempStr;
			Database.QueryLocatorIterator it;

			if (taskRec.Form_Code__c != null && taskRec.Tax_Code__c != null && taskRec.Filing_Method__c != null && taskRec.Process_Step__c != null) {
				queryTempStr =
					'select id from Tax_Ops_Instructions__kav where PublishStatus=\'Online\' and (Form_code__c like \'' +
					taskRec.Form_Code__c +
					'\' and Tax_Code__c like \'' +
					taskRec.Tax_Code__c +
					'\' and Process_Step__c like \'' +
					taskRec.Process_Step__c +
					'\' and Filing_Method__c like ' +
					'\'' +
					taskRec.Filing_Method__c +
					'\')  and language=\'en_US\'';
				helpList = database.getQueryLocator(queryTempStr);
				it = helpList.iterator();
				if (it.hasNext()) {
					return 4;
				}
			}

			if (taskRec.Tax_Code__c != null && taskRec.Filing_Method__c != null && taskRec.Process_Step__c != null) {
				queryTempStr =
					'select id from Tax_Ops_Instructions__kav where PublishStatus=\'Online\' and (Tax_Code__c like \'' +
					taskRec.Tax_Code__c +
					'\' and Process_Step__c like \'' +
					taskRec.Process_Step__c +
					'\' and Filing_Method__c like ' +
					'\'' +
					taskRec.Filing_Method__c +
					'\' and Form_Code__c = null)  and language=\'en_US\'';
				helpList = database.getQueryLocator(queryTempStr);
				it = helpList.iterator();
				if (it.hasNext()) {
					return 3;
				}
			}

			if (taskRec.Filing_Method__c != null && taskRec.Process_Step__c != null) {
				queryTempStr =
					'select id from Tax_Ops_Instructions__kav where PublishStatus=\'Online\' and ( Process_Step__c like \'' +
					taskRec.Process_Step__c +
					'\' and Filing_Method__c like \'' +
					taskRec.Filing_Method__c +
					'\' and Tax_Code__c = null and Form_Code__c = null)  and language=\'en_US\'';
				helpList = database.getQueryLocator(queryTempStr);
				it = helpList.iterator();
				if (it.hasNext()) {
					return 2;
				}
			}

			queryTempStr =
				'select id from Tax_Ops_Instructions__kav where PublishStatus=\'Online\' and ( Process_Step__c like \'' +
				taskRec.Process_Step__c +
				'\' and Tax_Code__c = null and Filing_Method__c = null and Form_Code__c = null)  and language=\'en_US\'';
			helpList = database.getQueryLocator(queryTempStr);
			it = helpList.iterator();
			if (it.hasNext()) {
				return 1;
			}
		}
		return 0;
	}

	public class articleDetail {
		public string articleCategory { get; set; }
		public string description { get; set; }
		public string externalId { get; set; }
		public string title { get; set; }
		public id kaId { get; set; }
		public id recId { get; set; }

		public articleDetail(string articleCat, string des, string extId, string titl, id kaIdd, id idd) {
			if (articleCat == null) {
				articleCat = 'Internal';
			}
			articleCategory = articleCat;
			description = (des != null ? des.replaceAll('</p>', '</p><br/>') : des);
			externalId = extId;
			title = titl;
			kaId = kaIdd;
			recId = idd;
		}
	}

	// this is a getter method, in this method we are traversing "article" standard Controller list and
	//populating  "articleDetail" wrapper
	public List<articleDetail> articleKnowledgeDetailList {
		get {
			if (articleController != null) {
				list<articleDetail> templist = new List<articleDetail>();
				if (primaryCaseId != null && primaryCaseId.indexof(Case.SObjectType.getDescribe().getKeyPrefix()) == 0) {
					for (Help__kav rec : (list<Help__kav>) articleController.getRecords()) {
						articleDetail tempRec = new articleDetail(rec.Article_Category__c, rec.Description__c, rec.UrlName, rec.title, rec.KnowledgeArticleId, rec.id);
						templist.add(tempRec);
					}
				} else {
					for (Tax_Ops_Instructions__kav rec : (list<Tax_Ops_Instructions__kav>) articleController.getRecords()) {
						articleDetail tempRec = new articleDetail(null, rec.Description__c, rec.UrlName, rec.title, rec.KnowledgeArticleId, rec.id);
						templist.add(tempRec);
					}
				}

				return templist;
			} else
				return null;
		}
		set;
	}
	//========================================
	//following methods are used to implement pagination
	public Boolean hasNext {
		get {
			return articleController.getHasNext();
		}
		set;
	}
	public Boolean hasPrevious {
		get {
			return articleController.getHasPrevious();
		}
		set;
	}
	public Integer pageNumber {
		get {
			return articleController.getPageNumber();
		}
		set;
	}
	public void previous() {
		articleController.previous();
	}

	public void next() {
		articleController.next();
	}
}