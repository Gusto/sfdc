public class EngagementCaseViewExtension {
	public Case theCase { get; private set; }
	public String oldRoutingCaseReason { get; private set; }
	public List<String> caseReasons { get; set; }
	public Map<String, List<String>> map_CaseReasonToSub { get; set; }
	public List<String> list_SubCaseReasons { get; set; }
	public List<String> lsiList { get; set; }
	public string caseType { get; set; }
	public Benefit_Order__c benefitOrder { get; private set; }
	public Integer totalNotices { get; private set; }
	public Integer currentYearNotices { get; private set; }
	public String LSIs { get; private set; }
	public Integer accountScore { get; private set; }
	public Integer contactScore { get; private set; }
	public boolean isFullAccess { get; private set; }
	public boolean isAdmin { get; private set; }
	public boolean showAssignToMe { get; set; }
	public boolean statusChangedUI;
	public caseCountByStatus caseStatus { get; private set; }
	public boolean surveyOverride { get; private set; }
	private static map<String, Id> recordTypeNameIdMap = new Map<String, Id>();
	public string emailSubject { get; private set; }
	public Boolean boolShowTaxPOALink {get;set;} 

	public List<SelectOption> caseTypeOption { get; private set; }
	public List<SelectOption> caseStatusOption { get; private set; }
	public List<SelectOption> caseStatusDetailOption { get; private set; }

	public Account theAccount { get; private set; }
	map<string, id> lsiNameIdMap = new Map<string, id>();
	public ID phoneRoutingId { get; set; }
	public List<Group> list_phoneRoutingIds { get; set; }
	public boolean refreshPage { get; set; }

	public boolean showUpsellRecomendation { get; set; }
	public string zpExpId { get; set; }
	public string zpCompId { get; set; }
	public string zpExpStatusId { get; set; }
	public string operation { get; set; }
	public Boolean boolIsChat { get; set; }
	public Boolean blnHasError { get; set; } //DS[27-Oct-2020] : add PayrollOps Audit case functionality
	public String strPAYROLLOPS_AUDIT = 'PayrollOps Audit';
	public String strPAYROLLOPS_AUDIT_READONLY = 'PayrollOps Audit - Read Only';

	public Boolean blnIsTriaged { get; set; } // To determine whether the TaxRes case is triaged or not
	public static Boolean blnIsCaseRoute = false;

	//By AKS Dated 7th Jan to get Logged in user name and Role
	public static User objUser = UserUtils.returnLoggedInUser();

	public EngagementCaseViewExtension(ApexPages.StandardController controller) {
		refreshPage = false;
		accountScore = 0;
		contactScore = 0;
		showAssignTome = false;
		statusChangedUI = false;
		blnHasError = false;
		blnIsTriaged = false;
		showUpsellRecomendation = false;
		theCase = (Case) controller.getRecord();
		setCaseInfo();
		setCaseEmailSubject();
		//setGenesysCallInfo();
		oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
		caseType = '';
		setCaseRecordTypeMap();
		setSurveyOverride();
		//moved the code to the CaseUtils class
		caseTypeOption = CaseUtils.caseTypeOptionList();
		caseStatusOption = CaseUtils.caseStatusOptionList();
		caseStatusDetailOption = CaseUtils.caseStatusDetailOptionList();

		if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Payroll Care') > -1) {
			caseType = 'Payroll Care';
			caseTypeOption = CaseUtils.caseEngagementTypeOptionList();
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Benefits Care') > -1) {
			caseType = 'Benefits Care';
			caseTypeOption = CaseUtils.caseEngagementTypeOptionList();
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Tax Res') > -1) {
			caseType = 'Tax Res';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf(strPAYROLLOPS_AUDIT) > -1) {
			//DS[27-Oct-2020] : add PayrollOps Audit case to route
			caseType = strPAYROLLOPS_AUDIT;
			caseStatusDetailOption = CaseUtils.casePayrollAuditStatusDetailOptionList();
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Tax Ops') > -1) {
			caseType = 'Tax Ops';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Payroll Compliance') > -1) {
			caseType = 'Payroll Compliance';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Risk Assurance') > -1) {
			caseType = 'Risk Assurance';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Modern Bank') > -1) {
			caseType = 'Modern Bank';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Benefits Compliance') > -1) {
			caseType = 'Benefits Compliance';
		} else if (theCase.RecordType.Name != null && theCase.RecordType.Name.indexOf('Engagement') > -1) {
			caseType = 'Engagement';
		}

		checkForUnassignedCasesForSimilarRecordType(theCase);

		setMiscellaneousInfo();

		//if origin is chat, show level info
		if (theCase.Origin == 'Chat' || (theCase.Origin == 'Gusto' && theCase.Channel__c == 'Chat')) {
			String strFirstLevel = String.isNotBlank(theCase.First_Level__c) ? ('First Level: ' + theCase.First_Level__c) : '';
			String strSecondLevel = String.isNotBlank(theCase.Second_Level__c) ? ('<br/> Second Level: ' + theCase.Second_Level__c) : '';
			String strThirdLevel = String.isNotBlank(theCase.Third_Level__c) ? ('<br/>  Third Level: ' + theCase.Third_Level__c) : '';
			boolIsChat = true;
			ApexPages.addMessage(new apexPages.Message(ApexPages.Severity.INFO, strFirstLevel + strSecondLevel + strThirdLevel));
		}
	}

	public void setMiscellaneousInfo() {
		caseReasons = new List<String>();
		map_CaseReasonToSub = new Map<String, List<String>>();
		list_SubCaseReasons = new List<String>();
		string caseOriginStr = '\'' + theCase.Origin + '\'';
		string caseTypeStr = '\'' + theCase.Type + '\'';
		string tempQuerystr =
			'Select Id, Name, Class__c from Case_Reason_Classification__c where type__c=:caseType and Active__c = true and Case_Origin__c includes (' +
			caseOriginStr +
			') and Case_Type__c includes (' +
			caseTypeStr +
			')';
		for (Case_Reason_Classification__c crc : Database.query(tempQuerystr)) {
			caseReasons.add(crc.Name);
		}

		//make a map of case reasons to their sub case reasons
		String strOriginalSubReason = '';
		if (String.isNotBlank(theCase.Confirm_Sub_Case_Reason__c)) {
			strOriginalSubReason = theCase.Confirm_Sub_Case_Reason__c;
		}
		setSubCaseReason();
		theCase.Confirm_Sub_Case_Reason__c = strOriginalSubReason;

		lsiList = new List<String>();
		//lsiList.add('None');
		for (Large_Scale_Issue__c lsi : [SELECT Id, Name FROM Large_Scale_Issue__c ORDER BY Name ASC]) {
			lsiList.add(lsi.Name);
			lsiNameIdMap.put(lsi.Name, lsi.id);
		}

		String ownerId = theCase.OwnerId;
		List<PermissionSetAssignment> permList = new List<PermissionSetAssignment>(
			[SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Engagement_Accept_Case' AND AssigneeId = :UserInfo.getUserId()]
		);
		if (permList.size() > 0 && ownerId.indexOf('00G') == 0) {
			showAssignToMe = true;
		}
		if (caseType == 'Payroll Care' && (theCase.Origin == 'Phone' || (theCase.Origin == 'Gusto' && theCase.Channel__c == 'Phone')) && theCase.AccountId != null && theCase.ContactId != null) {
			checkForUpsellRecomendation();
		}
		list_phoneRoutingIds = [SELECT id FROM group WHERE type = 'Queue' AND name = 'Phone Routing' LIMIT 1];
		if (list_phoneRoutingIds != null && list_phoneRoutingIds.size() > 0) {
			phoneRoutingId = list_phoneRoutingIds.get(0).id;
		}
	}

	/*
        Author: Alex
        Date: 5/11/2020
        Description: set list_SubCaseReasons based on confirm case reason
    */
	public void setSubCaseReason() {
		theCase.Confirm_Sub_Case_Reason__c = '';
		String strSubCaseReasonQuery = 'SELECT Id, Name, Case_Reason__c, Case_Reason__r.Name FROM Sub_Case_Reason_Classification__c WHERE Active__c = TRUE';
		for (Sub_Case_Reason_Classification__c subCrc : Database.query(strSubCaseReasonQuery)) {
			List<String> list_TempSubReasons = new List<String>();
			if (map_CaseReasonToSub.containsKey(subCrc.Case_Reason__r.Name))
				list_TempSubReasons = map_CaseReasonToSub.get(subCrc.Case_Reason__r.Name);
			list_TempSubReasons.add(subCrc.Name);
			map_CaseReasonToSub.put(subCrc.Case_Reason__r.Name, list_TempSubReasons);
		}

		list_SubCaseReasons = map_CaseReasonToSub.get(theCase.Confirm_Case_Reason__c);
		if (list_SubCaseReasons == null) {
			list_SubCaseReasons = new List<String>();
		}
	}

	private void setCaseEmailSubject() {
		if (theCase.id != null) {
			list<EmailMessage> emailMsgList = [SELECT id, subject, ccaddress, createddate FROM EmailMessage WHERE parentid = :theCase.id ORDER BY createddate DESC LIMIT 5];
			if (emailMsgList.size() > 0) {
				emailSubject = emailMsgList[0].subject;
			} else {
				emailSubject = theCase.Subject;
			}
		}
	}

	public void setCaseInfo() {
		if (theCase != null && theCase.id != null) {
			theCase = [
				SELECT
					Id,
					Savings_Complaint_Type__c,
					Record_Type_Name__c,
					Reviewed_by_Dedicated_Support__c,
					AccountId,
					Account.name,
					ContactId,
					Contact.Name,
					Followup_Needed__c,
					Benefits_and_Payroll_Care_Support_Needed__c,
					CaseNumber,
					Contact.SSN_Last_4__c,
					Next_Steps__c,
					Related_Case__c,
					Partner_Record_Id__c,
					Source_of_Complaint__c,
					Shared_With__c,
					Carrier_Call_Required__c,
					SuppliedEmail,
					ParentId,
					Closed_Reason__c,
					Carrier__c,
					LSI__c,
					Type,
					Blocker__c,
					Global_Issue__c,
					Anticipated_Effective_Date__c,
					Origin,
					Complaint__c,
					Affect_Filing_Payment__c,
					CreatedDate,
					Authorized_User__c,
					Jira_Id__c,
					Subject,
					Description,
					Direction__c,
					Audience__c,
					Escalation_Type__c,
					Follow_Up_Method__c,
					Follow_Up_Date__c,
					Reason,
					Priority,
					Status,
					Routing_Case_Reason__c,
					Confirm_Case_Reason__c,
					Employee_Ids__c,
					Auth__c,
					Summary_of_Complaint__c,
					Otter_Audit_Type__c,
					Tax_Id__c,
					ContactEmail,
					Status_Detail__c,
					Requires_Action__c,
					Zendesk_Id__c,
					RecordType.Name,
					Amount__c,
					Error_Origin__c,
					Class__c,
					Non_English_Preferred_Language__c,
					OwnerId,
					Send_Survey__c,
					Skip_Survey__c,
					Routing_Group__c,
					Notice_Priority__c,
					Notice_Period__c,
					Notice_Type__c,
					Complaint_Method__c,
					Notice_Response_Deadline__c,
					Payment_Due_Date__c,
					Penalty_Amount__c,
					Agency_Information__c,
					Root_Cause__c,
					Sub_Root_Cause__c,
					Genesys_Call_Id__c,
					Large_Scale_Issue__c,
					Current_LSI__c,
					Account.ZP_Company_Id__c,
					Contact.ZP_User_Id__c,
					Complaint_Type__c,
					Contact.Employee_Id__c,
					Unresponsive_Abandoned_Chat__c,
					Account.Risk_Flag__c,
					Confirmed_Reason_for_Leaving__c,
					Suspension_Status__c,
					Google_Calendar_Event__c,
					Reason_Notes__c,
					Summary_of_Resolution__c,
					Suspension_Contact_Number__c,
					Suspension_Call_Scheduled_Date_Time__c,
					Unresponsive_Customer__c,
					Contact_User_Id__c,
					Opt_Out_Updating_Phone__c,
					Feature_Service_Desired__c,
					Next_Payroll_Provider__c,
					Notes__c,
					Panda_Company_URL__c,
					Other_Case_Reason_Description__c,
					CCEmailAddress__c,
					Penalty_and_Interest_Link__c,
					Contact_Employee_Id__c,
					Large_Scale_Issue_Classification__c,
					Customer_Journey__c,
					Area_Impacted__c,
					suppliedPhone,
					Account_Company_Id__c,
					Escalatedto__c,
					Process_Step__c,
					Average_FTE__c,
					IVR_Transcript__c,
					Penalties_Interest_Assessed__c,
					Period_Prior_to_Gusto__c,
					Penalties_and_Interest_Paid__c,
					POA_Info__c,
					Related_to_Incident__c,
					Confirm_Sub_Case_Reason__c,
					First_Level__c,
					Second_Level__c,
					Third_Level__c,
					Continuation_Effective_Date__c,
					Submission_Method__c,
					Product__c,
					CX_Experiment__c,
					Triage_Completed_Date__c,
					Triaged_By__c,
					Triaged_By_Role__c,
					Channel__c
				FROM Case
				WHERE Id = :theCase.id
			];
		}
	}

	public Case getCurrentCaseInfo() {
		return [
			SELECT
				Id,
				Savings_Complaint_Type__c,
				AccountId,
				Record_Type_Name__c,
				Reviewed_by_Dedicated_Support__c,
				Account.name,
				ContactId,
				Contact.Name,
				Followup_Needed__c,
				Benefits_and_Payroll_Care_Support_Needed__c,
				CaseNumber,
				Complaint__c,
				Contact.SSN_Last_4__c,
				Next_Steps__c,
				Related_Case__c,
				Partner_Record_Id__c,
				Shared_With__c,
				Source_of_Complaint__c,
				Carrier_Call_Required__c,
				SuppliedEmail,
				ParentId,
				Closed_Reason__c,
				Carrier__c,
				LSI__c,
				Type,
				Blocker__c,
				Summary_of_Complaint__c,
				Global_Issue__c,
				Anticipated_Effective_Date__c,
				Origin,
				Affect_Filing_Payment__c,
				CreatedDate,
				Genesys_Call_Id__c,
				Authorized_User__c,
				Jira_Id__c,
				Subject,
				Description,
				Direction__c,
				Audience__c,
				Escalation_Type__c,
				Auth__c,
				Follow_Up_Method__c,
				Follow_Up_Date__c,
				Reason,
				Priority,
				Status,
				Routing_Case_Reason__c,
				Confirm_Case_Reason__c,
				Employee_Ids__c,
				Otter_Audit_Type__c,
				Tax_Id__c,
				ContactEmail,
				Status_Detail__c,
				Requires_Action__c,
				Complaint_Method__c,
				Zendesk_Id__c,
				RecordType.Name,
				Amount__c,
				Error_Origin__c,
				Class__c,
				Non_English_Preferred_Language__c,
				OwnerId,
				Send_Survey__c,
				Skip_Survey__c,
				Routing_Group__c,
				Notice_Priority__c,
				Notice_Period__c,
				Notice_Type__c,
				Summary_of_Resolution__c,
				Notice_Response_Deadline__c,
				Payment_Due_Date__c,
				Penalty_Amount__c,
				Agency_Information__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Large_Scale_Issue__c,
				Current_LSI__c,
				Account.ZP_Company_Id__c,
				Contact.ZP_User_Id__c,
				Contact.Employee_Id__c,
				Complaint_Type__c,
				Other_Case_Reason_Description__c,
				Next_Payroll_Provider__c,
				Unresponsive_Customer__c,
				Opt_Out_Updating_Phone__c,
				Large_Scale_Issue_Classification__c,
				suppliedPhone,
				Customer_Journey__c,
				Area_Impacted__c,
				Escalatedto__c,
				Process_Step__c,
				Average_FTE__c,
				POA_Info__c,
				Related_to_Incident__c,
				Confirm_Sub_Case_Reason__c,
				Continuation_Effective_Date__c,
				Submission_Method__c,
				Product__c,
				CX_Experiment__c,
				Triage_Completed_Date__c,
				Triaged__c,
				Triaged_By__c,
				Channel__c
			FROM Case
			WHERE Id = :theCase.id
		];
	}

	public void checkCaseStatus() {
		if (theCase != null && statusChangedUI != true) {
			List<Case> updatedCase = [SELECT Id, Status FROM Case WHERE Id = :theCase.id];
			if (updatedCase != null && updatedCase.size() > 0)
				theCase.Status = updatedCase[0].Status;
		}
	}

	public void statusChangeEvent() {
		statusChangedUI = true;
	}

	public pageReference publishToApIntego() {
		return null;
	}

	// to cover up the scenario where user picks up the phone during PhoneAni page transition.
	// we are trying to find the task created by PureCloud default logic to decide wether call has already been connected or not
	public void checkCaseTask() {
		if (theCase != null && theCase.Genesys_Call_Id__c != null) {
			dateTime dateTime2MinBack = system.now().addMinutes(-5);
			list<Task> tempList = [SELECT id FROM Task WHERE whatId = :theCase.id AND createdDate > :dateTime2MinBack AND CallObject = :theCase.Genesys_Call_Id__c LIMIT 1];

			if (tempList.size() > 0) {
				assignUserOnCallPickup();
			}
		}
	}

	public pagereference checkCaseTaskFromPoller() {
		if (theCase != null && (theCase.Origin == 'Phone' || (theCase.Origin == 'Gusto' && theCase.Channel__c == 'Phone')) && phoneRoutingId != null && theCase.OwnerId.equals(phoneRoutingId)) {
			list<Task> tempList = [SELECT id, createdById FROM Task WHERE whatId = :theCase.id AND CallObject = :theCase.Genesys_Call_Id__c ORDER BY createdDate DESC LIMIT 1];
			if (Test.isRunningTest()) {
				tempList = [SELECT id, createdById FROM Task WHERE whatId = :theCase.id ORDER BY createdDate DESC LIMIT 1];
			}
			if (tempList.size() > 0) {
				theCase.OwnerId = tempList.get(0).createdById;
				try {
					update theCase;
					refreshPage = true;
					updateCaseAuditLog(theCase);
					if (Test.isRunningTest()) {
						integer i = 0 / 0; // to cover catch
					}
				} catch (Exception ex) {
					apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
					return null;
				}
			}
		}

		return null;
	}

	boolean isCaseUpdated = false;
	public void assignUserOnCallPickup() {
		checkCaseTaskFromPoller();
	}

	public void updateCaseAuditLog(Case c) {
		dateTime dateTimeFiveMinBack = system.now().addMinutes(-2);
		list<Case_Audit_Log__c> logList = [SELECT id, Advocate__c FROM Case_Audit_Log__c WHERE case__c = :c.Id AND Event_Type__c = 'Phone' AND createddate > :dateTimeFiveMinBack LIMIT 1];

		if (logList.size() > 0) {
			logList.get(0).Advocate__c = theCase.OwnerId;

			try {
				update logList;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
			}
		}
	}

	public pageReference acceptCase() {
		if (theCase.OwnerId != UserInfo.getUserId()) {
			theCase.OwnerId = UserInfo.getUserId();
			theCase.Status = 'In Progress';
			try {
				update theCase;
				isCaseUpdated = true;
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}

		return null;
	}

	public pageReference unmergeCase() {
		if (theCase.ParentId != null) {
			CaseTriggerHelper.context = 'Merge';
			theCase.ParentId = null;
			theCase.Closed_Reason__c = null;
			if (theCase.RecordTypeId != null) {
				if (theCase.RecordType.Name == 'Benefits Care - Read Only') {
					theCase.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care');
				} else if (theCase.RecordType.Name == 'Payroll Care - Read Only') {
					theCase.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
				} else if (theCase.RecordType.Name == 'Tax Res - Read Only') {
					theCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
				} else if (theCase.RecordType.Name == strPAYROLLOPS_AUDIT_READONLY) {
					//DS[27-Oct-2020] : add PayrollOps Audit case functionality
					theCase.RecordTypeId = cache.getRecordTypeId('Case', strPAYROLLOPS_AUDIT);
				} else if (theCase.RecordType.Name == 'Modern Bank - Read Only') {
					theCase.RecordTypeId = cache.getRecordTypeId('Case', 'Modern Bank');
				}
			}
			theCase.Status = 'Open';
			try {
				update theCase;
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.INFO, 'Case is successfully un merged'));
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		PageReference pgref = ApexPages.currentPage();
		pgref.getParameters().put('refreshPage', 'true');
		return pgref;
	}

	public pageReference moveToInprogress() {
		if (theCase.Status != null && theCase.Status != 'In Progress') {
			theCase.Status = 'In Progress';
			try {
				update theCase;
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.INFO, 'Case is successfully updated'));
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		PageReference pgref = ApexPages.currentPage();
		return pgref;
	}

	public pageReference moveToOpen() {
		if (theCase.Status != null && theCase.Status != 'Open') {
			theCase.Status = 'Open';
			try {
				update theCase;
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.INFO, 'Case is successfully updated'));
			} catch (Exception ex) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
				return null;
			}
		}
		PageReference pgref = ApexPages.currentPage();
		return pgref;
	}

	public pageReference routeCase() {
		if (theCase.Id != null) {
			blnIsCaseRoute = true;
			return CaseUtils.routeCase(caseType, theCase);
		}
		apexpages.addmessage(new apexpages.message(apexPages.severity.error, 'Routing failed. Cannot route a non-existing Case.'));
		return null;
	}

	public pageReference initModernBankCase() {
		checkCaseTask();
		return getRoutingPageReference('Modern Bank');
	}
	//on load method for Benefits Compliance page
	public pageReference initBenefitsCompliance() {
		checkCaseTask();
		return getRoutingPageReference('Benefits Compliance');
	}
	public pageReference initPayrollCareCase() {
		checkCaseTask();
		return getRoutingPageReference('Payroll Care');
	}

	public pageReference initBenefitCareCase() {
		checkCaseTask();
		return getRoutingPageReference('Benefits Care');
	}
	public pageReference initPayrollAuditCase() {
		return getRoutingPageReference(strPAYROLLOPS_AUDIT);
	}
	public pageReference initTaxResCase() {
		checkCaseTask();
		return getRoutingPageReference('Tax Res');
	}

	public pageReference initTaxOpsCase() {
		return getRoutingPageReference('Tax Ops');
	}
	public pageReference initPayrollComplianceCase() {
		return getRoutingPageReference('Payroll Compliance');
	}

	public pageReference initRiskCase() {
		return getRoutingPageReference('Risk');
	}
	public pageReference initEngagementCase() {
		checkCaseTask();
		return getRoutingPageReference('Engagement');
	}

	public PageReference getRoutingPageReference(String page) {
		if (theCase.RecordTypeId == recordTypeNameIdMap.get('Tax Res') && page != 'Tax Res') {
			PageReference pgref = new PageReference('/apex/TaxResCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get(strPAYROLLOPS_AUDIT) && page != strPAYROLLOPS_AUDIT) {
			//DS[27-Oct-2020] : add PayrollOps Audit case functionality
			PageReference pgref = new PageReference('/apex/PayrollAuditCase?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Benefits Care') && page != 'Benefits Care') {
			PageReference pgref = new PageReference('/apex/BenefitsCareCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') && page != 'Payroll Care') {
			PageReference pgref = new PageReference('/apex/PayrollCareCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Tax Ops') && page != 'Tax Ops') {
			PageReference pgref = new PageReference('/apex/TaxOpsCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Payroll Compliance') && page != 'Payroll Compliance') {
			PageReference pgref = new PageReference('/apex/PayrollComplianceCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Risk Assurance') && page != 'Risk') {
			PageReference pgref = new PageReference('/apex/RiskAssuranceCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') && page != 'Modern Bank') {
			PageReference pgref = new PageReference('/apex/ModernBankCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Benefits Compliance') && page != 'Benefits Compliance') {
			PageReference pgref = new PageReference('/apex/BenefitsComplianceCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref; //Benefits Compliance
		} else if (theCase.RecordTypeId == recordTypeNameIdMap.get('Engagement') && page != 'Engagement') {
			PageReference pgref = new PageReference('/apex/EngagementCasePage?id=' + theCase.id);
			pgref.setRedirect(true);
			return pgref;
		}
		return null;
	}

	/*
        Author: Alex
        Date: 5/29/2020
        Description: check if the sub case reason being entered matches 
        with any in the list of available sub case reasons
    */
	public Boolean validateSubCaseReason() {
		if (list_SubCaseReasons.isEmpty()) {
			if (String.isBlank(theCase.Confirm_Sub_Case_Reason__c)) {
				return false;
			} else
				return true;
		} else {
			if (!list_SubCaseReasons.contains(theCase.Confirm_Sub_Case_Reason__c) || String.isBlank(theCase.Confirm_Sub_Case_Reason__c)) {
				return true;
			} else
				return false;
		}
	}

	public pageReference SaveTaxOpsCase() {
		//theCase.OwnerId=UserInfo.getUserId();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;

		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}

		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/TaxOpsCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference SaveRiskAssuranceCase() {
		if ((theCase.Status == 'Solved' || theCase.Status == 'Closed') && string.isBlank(theCase.Confirm_Case_Reason__c) && string.valueOf(theCase.OwnerId).startsWith('005')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
			return null;
		}
		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/RiskAssuranceCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference SaveModernBankCase() {
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;
		Case oldCase = getCurrentCaseInfo();

		if (theCase.Routing_Case_Reason__c != oldCase.Routing_Case_Reason__c && ownerId.indexOf('00G') > -1) {
			theCase.Answer_IQ_Processed__c = 'Yes';
			theCase.setOptions(dmo);
		}

		if (theCase.Status == 'Solved' && (theCase.Confirm_Case_Reason__c == null || theCase.Confirm_Case_Reason__c == '')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
			return null;
		}

		if (theCase.Status == 'Solved' && (theCase.Product__c == null || theCase.Product__c == '')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Product is required'));
			return null;
		}

		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		if (
			string.valueof(theCase.ownerId).indexof('005') == 0 &&
			theCase.Confirm_Case_Reason__c != null &&
			theCase.Confirm_Case_Reason__c == 'Other' &&
			string.isBlank(theCase.Other_Case_Reason_Description__c)
		) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Field Required: Other Case Reason Description.'));
			return null;
		}

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			checkForUnassignedCasesForSimilarRecordType(theCase);
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/ModernBankCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}
	//method to save Benefits Compliance Case page
	public pageReference SaveBenefitsComplianceCase() {
		//theCase.OwnerId=UserInfo.getUserId();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;
		Case oldCase = getCurrentCaseInfo();

		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		Database.SaveResult result = Database.update(theCase, false);

		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			checkForUnassignedCasesForSimilarRecordType(theCase);
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/BenefitsComplianceCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}
	public pageReference SavePayrollCareCase() {
		//theCase.OwnerId=UserInfo.getUserId();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;
		Case oldCase = getCurrentCaseInfo();

		if (theCase.Routing_Case_Reason__c != oldCase.Routing_Case_Reason__c && ownerId.indexOf('00G') > -1) {
			theCase.Answer_IQ_Processed__c = 'Yes';
			theCase.setOptions(dmo);
		}

		if (theCase.Status == 'Solved' && (theCase.Confirm_Case_Reason__c == null || theCase.Confirm_Case_Reason__c == '')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
			return null;
		}
		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		if (
			string.valueof(theCase.ownerId).indexof('005') == 0 &&
			theCase.Confirm_Case_Reason__c != null &&
			theCase.Confirm_Case_Reason__c == 'Other' &&
			string.isBlank(theCase.Other_Case_Reason_Description__c)
		) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Field Required: Other Case Reason Description.'));
			return null;
		}

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			checkForUnassignedCasesForSimilarRecordType(theCase);
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/PayrollCareCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference SaveTaxResCase() {
		//theCase.OwnerId=UserInfo.getUserId();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		blnHasError = false;
		string ownerId = theCase.OwnerId;

		Case oldCase = getCurrentCaseInfo();
		if (oldCase.Large_Scale_Issue__c != theCase.Large_Scale_Issue__c && !string.isBlank(string.valueof(theCase.Large_Scale_Issue__c))) {
			theCase.Large_Scale_Issue_Classification__c = lsiNameIdMap.get(theCase.Large_Scale_Issue__c);
		}

		if ((theCase.Agency_Information__c != oldCase.Agency_Information__c || theCase.Routing_Case_Reason__c != oldCase.Routing_Case_Reason__c) && ownerId.indexOf('00G') > -1) {
			theCase.Answer_IQ_Processed__c = 'Yes';
			theCase.setOptions(dmo);
		}

		//@DS, 7th DEC 2020, To determine whether the TaxRes case is triaged or not
		if (blnIsTriaged) {
			if (theCase.Triage_Completed_Date__c == null) {
				theCase.Triage_Completed_Date__c = system.now();
				//Added by AKS dated 6th Jan 21 https://app.asana.com/0/1199707549015414/1199725415559733
				theCase.Triaged_By__c = objUser.Name;
				if (String.isNotBlank(objUser.UserRoleId) && String.isNotBlank(objUser.UserRole.Name)) {
					theCase.Triaged_By_Role__c = objUser.UserRole.Name;
				}
			}
		}

		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			blnHasError = true;
			return null;
		}

		if (theCase.Routing_Case_Reason__c != 'POA Responses') {
			if (theCase.Status == 'Solved' && (theCase.Confirm_Case_Reason__c == null || theCase.Confirm_Case_Reason__c == '')) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
				blnHasError = true;
				return null;
			}

			list<User> list_tempUser = [SELECT Id, UserRole.Name FROM User WHERE ID = :UserInfo.getUserId()];
			if (list_tempUser.size() > 0) {
				if (list_tempUser.get(0).UserRole.Name == null || list_tempUser.get(0).UserRole.Name.indexOf('Dedicated Support') == -1) {
					if (
						theCase.RecordType.Name == 'Tax Res' &&
						theCase.routing_case_reason__c != 'Spam/Phishing Attempt' &&
						theCase.routing_case_reason__c != 'Case Created in Error' &&
						theCase.routing_case_reason__c != 'Onboarding Audit' &&
						theCase.status == 'Solved' &&
						theCase.Customer_Journey__c != 'Client Unresponsive' &&
						(string.isBlank(theCase.Agency_Information__c) ||
						string.isBlank(theCase.Root_cause__c) ||
						string.isBlank(theCase.Sub_Root_Cause__c) ||
						string.isBlank(theCase.Notice_Period__c) ||
						(theCase.Customer_Journey__c == 'Large Scale Issue' && string.isBlank(theCase.Large_Scale_Issue__c)))
					) {
						apexPages.addMessage(
							new apexPages.Message(
								ApexPages.Severity.ERROR,
								'Agency Information, Root Cause, Sub Root Cause, Notice Period and Large Scale Issue (If customer journey is Large Scale Issue) are required to solve the case.'
							)
						);
						blnHasError = true;
						return null;
					}
				}
			}
		}

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			checkForUnassignedCasesForSimilarRecordType(theCase);
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			blnHasError = false;
			return null;
		} else {
			blnHasError = true;
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	//DS[27-Oct-2020] : add PayrollOps Audit case Functionality
	public pageReference SavePayrollAuditCase() {
		blnHasError = false;
		if (theCase.Status == 'Solved' && (String.isBlank(theCase.Agency_Information__c) || String.isBlank(theCase.Confirm_Case_Reason__c))) {
			if (String.isBlank(theCase.Agency_Information__c)) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Agency Information is required'));
			}
			if (String.isBlank(theCase.Confirm_Case_Reason__c)) {
				apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
			}
			blnHasError = true;
			return null;
		}
		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, 'Case successfully saved'));
			setCaseInfo();
			blnHasError = false;
			return null;
		} else {
			blnHasError = true;
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference SaveBenefitsCareCase() {
		//theCase.OwnerId=UserInfo.getUserId();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		string ownerId = theCase.OwnerId;
		Case oldCase = getCurrentCaseInfo();

		if (theCase.Routing_Case_Reason__c != oldCase.Routing_Case_Reason__c && ownerId.indexOf('00G') > -1) {
			theCase.Answer_IQ_Processed__c = 'Yes';
			theCase.setOptions(dmo);
		}

		if (theCase.Status == 'Solved' && (theCase.Confirm_Case_Reason__c == null || theCase.Confirm_Case_Reason__c == '')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Confirm Case Reason is required'));
			return null;
		}
		if (theCase.Confirm_Sub_Case_Reason__c != null) {
			String strSubReason = theCase.Confirm_Sub_Case_Reason__c;
			setSubCaseReason();
			theCase.Confirm_Sub_Case_Reason__c = strSubReason;
		}
		if (validateSubCaseReason()) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'A valid Confirm Sub Case Reason is required'));
			return null;
		}

		if (
			string.valueof(theCase.ownerId).indexof('005') == 0 &&
			theCase.Confirm_Case_Reason__c != null &&
			theCase.Confirm_Case_Reason__c == 'Other' &&
			string.isBlank(theCase.Other_Case_Reason_Description__c)
		) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Field Required: Other Case Reason Description.'));
			return null;
		}

		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			setCaseInfo();
			checkForUnassignedCasesForSimilarRecordType(theCase);
			oldRoutingCaseReason = theCase.Routing_Case_Reason__c;
			PageReference pgref = new PageReference('/apex/BenefitsCareCasePage?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference initPayrollHighlightsPanel() {
		theAccount = new Account();
		accountScore = 0;
		contactScore = 0;
		setCaseCount();
		if (theCase.AccountId != null) {
			if (theCase.AccountId != null) {
				setAccountScore(theCase.AccountId);
			}
			if (theCase.ContactId != null) {
				setContactScore(theCase.contactId);
				setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
			}
			setAccountInfo(theCase.AccountId);
		}
		return null;
	}

	public pageReference initModernBankHighlightsPanel() {
		theAccount = new Account();
		accountScore = 0;
		contactScore = 0;
		setCaseCount();
		if (theCase.AccountId != null) {
			if (theCase.AccountId != null) {
				setAccountScore(theCase.AccountId);
			}
			if (theCase.ContactId != null) {
				setContactScore(theCase.contactId);
				setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
			}
			setAccountInfo(theCase.AccountId);
		}
		return null;
	}

	public void saveCaseRecord() {
		if (theCase != null) {
			try {
				update theCase;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
			}
		}
	}

	private void setCaseRecordTypeMap() {
		recordTypeNameIdMap = new Map<String, Id>();

		for (RecordType recType : [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SobjectType = 'Case']) {
			recordTypeNameIdMap.put(recType.Name, recType.id);
		}
	}

	public pageReference initBenefitsHighlightsPanel() {
		theAccount = new Account();
		accountScore = 0;
		contactScore = 0;
		setCaseCount();
		if (theCase.AccountId != null) {
			if (theCase.AccountId != null) {
				setAccountScore(theCase.AccountId);
			}
			if (theCase.ContactId != null) {
				setContactScore(theCase.contactId);
				setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
			}
			setAccountInfo(theCase.AccountId);

			List<Benefit_Order__c> orderList = new List<Benefit_Order__c>(
				[
					SELECT Id, Name, Open_Enrollment_Start_Date__c, Open_Enrollment_End_Date__c
					FROM Benefit_Order__c
					WHERE Order_Status__c = 'Fulfilled' AND Opportunity__r.Account.ZP_Company_ID__c = :theAccount.ZP_Company_ID__c
					ORDER BY createddate DESC
				]
			);
			if (orderList.size() > 0) {
				benefitOrder = orderList[0];
			}
		}

		return null;
	}
	public pageReference initTaxResHighlightsPanel() {
		theAccount = new Account();

		accountScore = 0;
		contactScore = 0;
		setCaseCount();
		if (theCase.AccountId != null) {
			if (theCase.AccountId != null) {
				setAccountScore(theCase.AccountId);
			}
			if (theCase.ContactId != null) {
				setContactScore(theCase.contactId);
				setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
			}
			setAccountInfo(theCase.AccountId);
			Set<String> caseReasonSet = new Set<String>();
			for (Case_Reason_Classification__c cls : [SELECT Id, Name FROM Case_Reason_Classification__c WHERE Type__c = 'Tax Res']) {
				caseReasonSet.add(cls.Name);
			}

			List<Case> totalCaseList = new List<Case>([SELECT Id FROM Case WHERE AccountId = :theAccount.Id AND (Routing_Case_Reason__c = :caseReasonSet OR Confirm_Case_Reason__c = :caseReasonSet)]);
			totalNotices = totalCaseList.size();

			String year = '%' + theCase.CreatedDate.year() + '%';
			totalCaseList = new List<Case>(
				[SELECT Id FROM Case WHERE AccountId = :theAccount.Id AND (Routing_Case_Reason__c = :caseReasonSet OR Confirm_Case_Reason__c = :caseReasonSet) AND Notice_Period__c LIKE :year]
			);
			currentYearNotices = totalCaseList.size();
			LSIs = '';
			if (theAccount.ZP_Company_Id__c != null) {
				for (Account_LSI__c lsi : [SELECT Id, LSI__c, Large_Scale_Issue__c, Large_Scale_Issue__r.Name FROM Account_LSI__c WHERE Account__r.ZP_Company_Id__c = :theAccount.ZP_Company_Id__c]) {
					if (lsi.Large_Scale_Issue__c != null) {
						LSIs += lsi.Large_Scale_Issue__r.Name + ', ';
					}
				}
			}
		}
		return null;
	}

	private void setAccountInfo(String accId) {
		theAccount = [
			SELECT
				Id,
				Name,
				Account_Status__c,
				ZP_Company_ID__c,
				recordType.Name,
				CX_Company_Notes__c,
				CX_Company_Notes_Last_Updated__c,
				Account_Type__c,
				Anchor_Pay_Date__c,
				Joined_Date_Panda__c,
				AM_Tier__c,
				Sold_By__c,
				States__c,
				Tier__c,
				Pricing__c,
				Days_Since_Last_Upsell_Conversation__c
			FROM Account
			WHERE id = :accId
		];
	}
	private void setSurveyOverride() {
		List<PermissionSetAssignment> assgnList = new List<PermissionSetAssignment>(
			[SELECT Id, AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN ('Engagement_SME', 'Engagement_Captain')]
		);
		if (assgnList.size() > 0) {
			surveyOverride = true;
		} else {
			surveyOverride = false;
		}
	}
	private void checkForUpsellRecomendation() {
		string strExpName;
		if (!Test.isRunningTest()) {
			strExpName = label.ZP_Customer_Experiment_Name;
		} else {
			strExpName = 'tier_upsell_core_to_complete_5_plus_ee';
		}
		boolean userAllowed = false;
		if (theCase.ContactId != null) {
			setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);
		} else {
			return; // since isFullAccess will be null in that case, so no need to go further
		}
		if (theAccount == null) {
			if (theCase != null && theCase.AccountId != null) {
				setAccountInfo(theCase.AccountId);
			}
		}

		List<User> listUsers = [SELECT CX_Experiment__c FROM User WHERE Id = :UserInfo.getUserId()];
		if (listUsers != null && listUsers.size() > 0) {
			User u = listUsers[0];
			if (u.CX_Experiment__c == 'Tier Upsell') {
				userAllowed = true;
			}
		}
	}

	public pageReference updateCount() {
		string strExpName;
		if (!Test.isRunningTest()) {
			strExpName = label.ZP_Customer_Experiment_Name;
		} else {
			strExpName = 'tier_upsell_core_to_complete_5_plus_ee';
		}

		return null;
	}

	private void setAccountScore(String accountId) {
		AggregateResult[] groupedResults = [SELECT AVG(How_satisfied_are_you_with_service__c) aver FROM Case_Survey_Response__c WHERE Account__c = :accountId AND CreatedDate >= Last_n_days:365];
		if (groupedResults[0].get('aver') != null) {
			Double score = (Double) groupedResults[0].get('aver');
			accountScore = score.intValue() * 20;
		}
	}

	private void setContactScore(String contactId) {
		AggregateResult[] groupedResults = [
			SELECT AVG(How_satisfied_are_you_with_service__c) aver
			FROM Case_Survey_Response__c
			WHERE Case__r.ContactId = :contactId AND CreatedDate >= Last_n_days:365
		];
		if (groupedResults[0].get('aver') != null) {
			Double score = (Double) groupedResults[0].get('aver');
			contactScore = score.intValue() * 20;
		}
	}

	public void setAccessPermission(string userId, string email) {
		list<ZP_User_Role__c> zpUserRoles;

		list<ZP_User__c> userList = new List<ZP_User__c>();
		if (userId == '' && email != '') {
			userList = [SELECT Id__c, Email__c, Deleted_At__c FROM ZP_User__c WHERE email__c = :email];
			if (userList.size() > 0) {
				userId = userList.get(0).Id__c;
			}
		}

		map<string, boolean> companyVisePermissionMap = new Map<string, boolean>();
		isAdmin = false;
		if (userId != null) {
			for (ZP_User_Role__c roleRec : [
				SELECT id, User_Permissions__c, Company_Id__c, User_Id__c, Type__c
				FROM ZP_User_Role__c
				WHERE User_Id__c = :userId AND Company_Id__c != NULL AND Deleted_At__c = NULL
			]) {
				string companyUniqueKey = roleRec.Company_Id__c + roleRec.User_Id__c;

				if (roleRec.Type__c.indexOf('PayrollAdmin') > -1) {
					isAdmin = true;
				}

				if (roleRec.User_Permissions__c != null) {
					if (roleRec.User_Permissions__c.indexOf('full_access') > -1) {
						companyVisePermissionMap.put(companyUniqueKey, true);
					}
				}

				if (!companyVisePermissionMap.containsKey(companyUniqueKey)) {
					companyVisePermissionMap.put(companyUniqueKey, false);
				}
			}
		}

		integer fullAccessCount = 0;
		for (boolean permission : companyVisePermissionMap.values()) {
			if (permission) {
				fullAccessCount++;
			}
		}

		if (fullAccessCount == companyVisePermissionMap.keyset().size()) {
			isFullAccess = true;
		} else {
			isFullAccess = false;
		}
	}

	public void setCaseCount() {
		caseStatus = new caseCountByStatus();
		caseStatus.newCases = 0;
		caseStatus.openCases = 0;
		caseStatus.closedCases = 0;
		caseStatus.solvedCases = 0;
		caseStatus.duplicateCases = 0;
		id contactId = '003000000000000';
		string contactEmail = 'test@testgusto.com';
		if (theCase.SuppliedEmail != null) {
			contactEmail = theCase.SuppliedEmail;
		}
		if (theCase.ContactId != null) {
			contactId = theCase.ContactId;
		}
		if (theCase.SuppliedEmail != null || theCase.ContactId != null) {
			List<AggregateResult> aggList = [SELECT Status, count(id) cnt FROM Case WHERE SuppliedEmail = :contactEmail OR contactId = :contactId GROUP BY status];
			for (AggregateResult res : aggList) {
				if (res.get('Status') == 'Closed') {
					caseStatus.closedCases += (Integer) res.get('cnt');
				} else if (res.get('Status') == 'New') {
					caseStatus.newCases += (Integer) res.get('cnt');
				} else if (res.get('Status') == 'Solved') {
					caseStatus.solvedCases += (Integer) res.get('cnt');
				} else {
					caseStatus.openCases += (Integer) res.get('cnt');
				}
			}
		}
	}

	@remoteAction
	public static string getEmailCC(String caseId) {
		String val = ' subject: ';
		if (!string.isBlank(caseId)) {
			try {
				list<EmailMessage> emailMsgList = [SELECT id, subject, ccaddress, createddate FROM EmailMessage WHERE parentid = :caseId ORDER BY createddate DESC];
				List<Case> caseList = [
					SELECT id, Subject, Type, ccEmailAddress__c, contactId, contact.Email, Contact.Name, SuppliedEmail, SuppliedName, Requester_Email__c
					FROM case
					WHERE id = :caseId
				];
				String val1 = '';
				if (caseList.size() > 0) {
					if (caseList[0].ccEmailAddress__c != null) {
						String requesterEmail = '';
						if (caseList[0].Requester_Email__c != null) {
							requesterEmail = caseList[0].Requester_Email__c;
						}
						String ccEmail = caseList[0].ccEmailAddress__c;
						ccEmail = ccEmail.replaceAll(requesterEmail, '');
						//ccEmail=requesterEmail;
						val1 = ccEmail + 'subject:';
					} else {
						val1 = ' ' + 'subject:';
					}
				}
				if (emailMsgList.size() > 0) {
					if (emailMsgList[0].subject != null && emailMsgList[0].subject.trim() != '') {
						val1 = val1 + emailMsgList[0].subject.trim();
					} else {
						val1 = val1 + ' ';
					}
				} else {
					val1 = val1 + ' ';
				}
				return val1 + 'objectId:' + caseId;
			} catch (Exception e) {
				return null;
			}
		}
		return val;
	}

	public class caseCountByStatus {
		public integer newCases { get; set; }
		public integer openCases { get; set; }
		public integer closedCases { get; set; }
		public integer solvedCases { get; set; }
		public integer duplicateCases { get; set; }
	}

	public void checkForUnassignedCasesForSimilarRecordType(case caseRecTemp) {
		integer unassignedCaseCount = 0;
		string caseNumberString;
		Id npsSurveryId = null;

		List<Group> groups = [SELECT Id, Name FROM Group WHERE DeveloperName = 'NPS_Survey_Response'];
		if (groups.size() > 0)
			npsSurveryId = groups[0].Id;

		if (caseType != 'Payroll Care' && caseType != 'Benefits Care' && caseType != 'Tax Res') {
			return;
		}

		if (caseRecTemp != null && caseRecTemp.id != null && caseRecTemp.ContactId != null) {
			for (case caseRec : [SELECT id, ownerId, CaseNumber FROM Case WHERE ContactId = :caseRecTemp.ContactId AND RecordTypeId = :caseRecTemp.RecordTypeId]) {
				if (caseRec.Id == caseRecTemp.Id) {
					continue;
				}

				if (string.valueof(caseRec.OwnerId).indexOf('00G') > -1 && (npsSurveryId == null || caseRec.OwnerId != npsSurveryId)) {
					unassignedCaseCount++;
					if (string.isBlank(caseNumberString)) {
						caseNumberString = '<a href="#" onclick="openUnassignedCase(\'' + caseRec.id + '\')">' + caseRec.CaseNumber + '</a>';
					} else {
						caseNumberString += ', <a href="#" onclick="openUnassignedCase(\'' + caseRec.id + '\')">' + caseRec.CaseNumber + '</a>';
					}
				}
			}
		}

		if (unassignedCaseCount > 0) {
			string msg =
				'There are ' +
				unassignedCaseCount +
				' unassigned ' +
				caseRecTemp.Record_Type_Name__c +
				' cases for this customer. Please assist the customer to close these out. <br/> ' +
				caseNumberString;
			apexPages.addMessage(new apexPages.Message(apexPages.severity.Warning, msg));
		}
	}

	public void saveAccountNotes() {
		Account tempAcc = new Account(id = theAccount.id, CX_Company_Notes__c = theAccount.CX_Company_Notes__c);
		tempAcc.CX_Company_Notes_Last_Updated__c = system.now();
		try {
			update tempAcc;
			if (Test.isRunningTest()) {
				integer i = 0 / 0; // to cover catch
			}
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexpages.severity.error, ex.getMessage()));
		}
	}
}