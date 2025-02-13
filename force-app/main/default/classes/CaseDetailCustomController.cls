public with sharing class CaseDetailCustomController {
	public string selectedCaseQueueId { get; set; }
	public integer totalRecordsQueried { get; set; }
	public string currentCaseId { get; set; }
	public Case selectedCaseRec { get; set; }
	public List<SelectOption> paginationSizeOptions { get; set; }
	public List<SelectOption> customViewList { get; set; }
	public string selectedViewId { get; set; }
	public List<SelectOption> caseTypeOption { get; private set; }
	public string caseType { get; set; }
	public List<String> caseReasons { get; set; }
	public List<String> caseTypeList { get; set; }
	public ApexPages.StandardSetController setCon { get; set; }
	public boolean isPlay { get; set; } //indicates that user has clicked play or not
	public boolean isPlayEmpty { get; set; } //indicates that current queue is empty
	public integer selectedQueueSize { get; set; }
	set<id> alreadyPlayedCaseIdSet = new Set<id>();

	list<SelectOption> userQueueList = new List<SelectOption>();
	map<string, list<string>> recordTypeNameCaseTypeListMap = new Map<string, list<string>>();

	//using this for locking functionality looping
	list<Case> tempCasePlayList = new List<case>();
	// using this for scenario when  user is in "Play mode" and clicked on "Save" button
	boolean isNext = false;

	public CaseDetailCustomController(apexPages.standardSetController setController) {
		isPlay = false;
		isPlayEmpty = false;
		selectedQueueSize = 0;
		selectedCaseRec = new Case();
		paginationSizeOptions = new List<SelectOption>();
		paginationSizeOptions.add(new SelectOption('5', '5'));
		paginationSizeOptions.add(new SelectOption('10', '10'));
		paginationSizeOptions.add(new SelectOption('20', '20'));
		paginationSizeOptions.add(new SelectOption('50', '50'));
		paginationSizeOptions.add(new SelectOption('100', '100'));

		caseTypeOption = new List<SelectOption>();
		caseTypeOption.add(new SelectOption('Payroll Care', 'Payroll Care'));
		caseTypeOption.add(new SelectOption('Benefits Care', 'Benefits Care'));
		caseTypeOption.add(new SelectOption('Tax Res', 'Tax Res'));
		caseTypeOption.add(new SelectOption('Modern Bank', 'Modern Bank'));

		recordTypeNameCaseTypeListMap.put('Payroll Care', new List<string>{ 'Otter Case', 'EOY Spot Check', 'Payroll Care' });
		recordTypeNameCaseTypeListMap.put(
			'Benefits Care',
			new List<string>{ 'Benefits Care', 'Cobra', 'Suspension Audit', 'EE Status Audit', 'Shareholder Audit', 'Company Taxability Audit', 'Owner Status Audit' }
		);
		recordTypeNameCaseTypeListMap.put('Tax Res', new List<string>{ 'Tax Res' });
		recordTypeNameCaseTypeListMap.put('Modern Bank', new List<string>{ 'Modern Bank' });

		caseTypeList = new List<string>();
		caseList = new List<Case>();
		this.getCases();
	}

	public void getCaseDetail() {
		if (!string.isBlank(currentCaseId) || isPlay) {
			if (!isPlay) {
				selectedCaseRec = [
						SELECT
							CaseNumber,
							id,
							RecordTypeId,
							RecordType.Name,
							Type,
							Non_English_Preferred_Language__c,
							Routing_Case_Reason__c,
							Confirm_Case_Reason__c,
							Agency_Information__c,
							LSI__c,
							Priority,
							Subject,
							Description,
							isCaseInPlay__c,
							OwnerId,
							Account.Has_Benefits__c,
							Root_Cause__c,
							Account.HI_Active_Benefits__c,
							Customer_journey__c
						FROM Case
						WHERE Id = :currentCaseId
						LIMIT 1
					]
					.get(0);
			} else {
				if (string.isblank(selectedCaseQueueId) || selectedCaseQueueId == '1') {
					selectedCaseQueueId = userInfo.getUserId();
				}

				tempCasePlayList = new List<case>();

				list<Case> tempList = [
					SELECT
						CaseNumber,
						id,
						RecordTypeId,
						RecordType.Name,
						Type,
						Routing_Case_Reason__c,
						Non_English_Preferred_Language__c,
						Confirm_Case_Reason__c,
						Customer_journey__c,
						Subject,
						Description,
						isCaseInPlay__c,
						OwnerId,
						Account.Has_Benefits__c,
						Root_Cause__c,
						Account.HI_Active_Benefits__c
					FROM Case
					WHERE ownerId = :selectedCaseQueueId AND isCaseInPlay__c = FALSE AND ID NOT IN :alreadyPlayedCaseIdSet
					ORDER BY CreatedDate ASC
					LIMIT 20
				];
				if (tempList != null && tempList.size() > 0) {
					tempCasePlayList = tempList;
					selectedCaseRec = tempList.get(0);
					selectedQueueSize = tempList.size();
				} else {
					selectedCaseRec = new Case();
					return;
				}
			}

			if (selectedCaseRec.RecordType.Name.indexOf('Payroll') > -1) {
				caseType = 'Payroll Care';
			} else if (selectedCaseRec.RecordType.Name.indexOf('Ben') > -1) {
				caseType = 'Benefits Care';
			} else if (selectedCaseRec.RecordType.Name.indexOf('Tax') > -1) {
				caseType = 'Tax Res';
			} else if (selectedCaseRec.RecordType.Name.indexOf('Modern') > -1) {
				caseType = 'Modern Bank';
			}

			getCaseReasons();
		}
	}

	public void getCaseReasons() {
		caseReasons = new List<String>();
		for (Case_Reason_Classification__c crc : [SELECT Id, Name, Class__c FROM Case_Reason_Classification__c WHERE type__c = :caseType AND Active__c = TRUE ORDER BY Name ASC LIMIT 999]) {
			caseReasons.add(crc.Name);
		}

		caseTypeList = new List<string>();
		caseTypeList = recordTypeNameCaseTypeListMap.get(caseType);
		selectedCaseRec.type = caseType;
	}

	public void saveCaseRecord() {
		List<case> tempcaseList = [SELECT Id, RecordTypeId, OwnerId FROM Case WHERE id = :selectedCaseRec.Id];
		Case c = new Case();
		if (tempcaseList != null && tempcaseList.size() > 0) {
			c = tempcaseList.get(0);
		}

		try {
			if (isPlay && isNext) {
				selectedCaseRec.isCaseInPlay__c = false;
			}

			selectedCaseRec.Answer_IQ_Processed__c = 'Yes';
			if (caseType != selectedCaseRec.RecordType.Name) {
				if (caseType == 'Tax Res') {
					CaseUtils.RouteCaseToTaxRes(selectedCaseRec);
				} else if (caseType == 'Payroll Care') {
					CaseUtils.RouteCaseToPayrollCare(selectedCaseRec);
				} else if (caseType == 'Benefits Care') {
					CaseUtils.RouteCaseToBenefitsCare(selectedCaseRec);
				} else if (caseType == 'Modern Bank') {
					CaseUtils.RouteCaseToModernBank(selectedCaseRec);
				}
			}
			String ownerId = selectedCaseRec.OwnerId;
			if (ownerId.indexOf('00G') == 0) {
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				Database.update(selectedCaseRec, dmo);
			} else {
				Database.update(selectedCaseRec);
			}
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.error, ex.getMessage()));
		}

		if (!apexPages.hasMessages()) {
			if (!isPlay) {
				selectedCaseRec = new Case();
			}
		}
	}

	public list<SelectOption> getcaseQueueList() {
		list<SelectOption> queueList = new List<SelectOption>();
		queueList.add(new SelectOption('1', 'My Cases'));

		for (QueueSobject qu : [SELECT Id, SobjectType, QueueId, Queue.Name, Queue.Type, Queue.RelatedId FROM QueueSobject WHERE SobjectType = 'Case' AND Queue.Type = 'Queue']) {
			queueList.add(new SelectOption(qu.QueueId, qu.Queue.Name));
		}

		return queueList;
	}

	public PageReference getCases() {
		isPlayEmpty = false;
		String query = '';
		query = 'select id,casenumber,OwnerId,Account.Name,Contact.Name,RecordType.Name,Non_English_Preferred_Language__c,CreatedDate,Subject,Description,Routing_Case_Reason__c,Confirm_Case_Reason__c ';
		query += ' from Case where isCaseInPlay__c = false ';
		if (!string.isBlank(selectedCaseQueueId) && selectedCaseQueueId != '1') {
			query += ' and ownerId=:selectedCaseQueueId ';
		} else {
			id userIdd = userInfo.getUserId();
			query += ' and ownerId=:userIdd ';
		}
		query += ' order BY CreatedDate asc limit 1000 ';

		setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
		selectedQueueSize = setCon.getResultSize();
		setCon.setPageSize(100);
		return null;
	}

	public List<Case> caseList {
		get {
			if (setCon != null) {
				return (List<Case>) setCon.getRecords();
			} else
				return null;
		}
		set;
	}

	public void cancelUpdate() {
		try {
			selectedCaseRec.isCaseInPlay__c = false;
			update selectedCaseRec;
		} catch (exception ex) {
		}

		selectedCaseRec = new Case();
		isPlay = false;
	}

	public void startPlay() {
		if (setCon.getRecords().size() > 0) {
			isPlay = true;
			isPlayEmpty = false;
			getCaseDetail();
			if (selectedCaseRec != null && selectedCaseRec.id != null && tempCasePlayList != null && tempCasePlayList.size() > 0) {
				List<Case> caseList = new List<Case>();
				for (Case rec : tempCasePlayList) {
					selectedCaseRec = rec;
					selectedCaseRec.isCaseInPlay__c = true;
					caseList.add(selectedCaseRec);
					break;
				}
				try {
					caseTriggerHelper.playmode_caseRouting = true;
					update caseList;
				} catch (exception ex) {
					apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
				}

			} else {
				isPlayEmpty = true;
				isPlay = false;
			}
		} else {
			isPlayEmpty = true;
			isPlay = false;
			selectedCaseRec = new case();
		}
	}

	public void saveNextRecord() {
		isNext = true;
		saveCaseRecord();
		isNext = false;

		if (apexPages.hasMessages()) {
			return;
		}

		alreadyPlayedCaseIdSet.add(selectedCaseRec.id);
		getCases();
		startPlay();
	}

	public integer getselectedQueueRecCount() {
		string userIdd;

		if (!string.isBlank(selectedCaseQueueId) && selectedCaseQueueId != '1')
			userIdd = selectedCaseQueueId;
		else
			userIdd = userInfo.getUserId();

		list<Case> tempCaseList = [SELECT id FROM Case WHERE OwnerId = :userIdd];

		if (tempCaseList.size() > 0) {
			return tempCaseList.size();
		}

		return 0;
	}
}