/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * File..................: <<UR_ProjectCloserCtrl>>
 * Created by............: <<Lirik>>
 * Description...........: <<This class is used to update Research_Project_Detail__c status.>>
 *-------------------------------------------------------------------------------*/
public with sharing class UR_ProjectCloserCtrl {
	public Research_Project_Master__c objProject { get; set; }
	public Integer totalRecord { get; set; }
	public boolean isEditable { get; set; }
	public boolean isProjectEditAccess { get; set; }
	public static final Integer PAGE_SIZE = 500;
	public ApexPages.StandardSetController setCon { get; set; }
	public String searchString { get; set; }
	public String sortbyFieldAPIName { get; set; }
	public String prevSortbyFieldAPIName { get; set; }
	public String orderAs { get; set; }
	public list<ResearchProjectDetailWrapper> lstResearchProjectDetailWrapper { get; set; }
	public string selectedStatus { get; set; }
	public List<selectOption> statusList { get; set; }
	public Integer totalParticipant { get; set; }
	public Boolean isSurveyExist { get; set; }
	public boolean isConstructor = true;
	public boolean isApproval { get; set; }
	public String approverComment { get; set; }
	public boolean isApprover { get; set; }
	public Integer newSurveyCount { get; set; }
	public String strNotAttendedMsg { get; set; }
	public boolean isParticipantExist { get; set; }
	public boolean addNote { get; set; }
	public Note objNote { get; set; }
	public Research_Configuration__c objResearch { get; set; }
	public Integer INT_MAX_INCENTIVE { get; set; }
	public boolean isApprovedOrRejected { get; set; }
	public Integer intMultiIncentive { get; set; }
	public Integer intTotalParticipantSelected { get; set; }
	public Integer intTotalAttended { get; set; }
	public Set<Id> set_ParticipantIds { get; set; }
	public static final String STATUS_ATTENDED = 'Attended';
	public static final String MSG_SUCCESS = 'You’ve requested incentives successfully for # people';
	public static final String MSG_MAX_INCENTIVE_LIMIT = 'has reached maximum untaxable incentive for this tax year. Scout admin will send them a 1099-MISC form when incentives are processed. Contact the UXR Ops team with any questions.';

	public UR_ProjectCloserCtrl(apexPages.StandardController stdcon) {
		intMultiIncentive = 0;
		intTotalParticipantSelected = 0;
		intTotalAttended = 0;
		set_ParticipantIds = new Set<Id>();
		isApprovedOrRejected = false;
		isConstructor = true;
		addNote = false;
		string checkApproval = ApexPages.CurrentPage().getparameters().get('isApproval');
		if (String.isNotBlank(checkApproval) && checkApproval == 'true') {
			isApproval = true;
		} else {
			isApproval = false;
		}
		string currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		orderAs = ApexPages.CurrentPage().getparameters().get('orderas');
		if (String.isBlank(orderAs)) {
			orderAs = 'asc';
		}
		sortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('sortby');
		if (String.isBlank(sortbyFieldAPIName)) {
			sortbyFieldAPIName = 'Research_Participant_Status_Number__c';
		}
		prevSortbyFieldAPIName = sortbyFieldAPIName;

		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		isProjectEditAccess = UR_UtilityCtrl.IsProjectEditAccess(currentRecordId);
		objProject = new Research_Project_Master__c();
		if (String.isNotBlank(currentRecordId)) {
			objProject.Id = currentRecordId;
		}
		lstResearchProjectDetailWrapper = new List<ResearchProjectDetailWrapper>();
		totalRecord = 0;
		fetchProjectDetails(true);
		isSurveyExist = UR_UtilityCtrl.surveyExist(currentRecordId);

		statusList = new List<selectOption>();
		statusList.add(new selectOption('', 'Update status'));
		for (selectOption objOption : UR_UtilityCtrl.getPickValues(new Research_Project_Detail__c(), 'Research_Participant_Status__c')) {
			if (objOption.getValue() != 'Contact Pending') {
				statusList.add(objOption);
			}
		}

		isConstructor = false;
		checkApprover();
		strNotAttendedMsg = 'Mark participant "Attended" first';
		isParticipantExist = UR_UtilityCtrl.participantExist(objProject.Id);
		RetriveNotes();
		objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();
		INT_MAX_INCENTIVE = 0;
		if (objResearch.Max_Incentive_of_Current_Year__c != null) {
			INT_MAX_INCENTIVE = Integer.valueOf(objResearch.Max_Incentive_of_Current_Year__c);
		}
	}

	public class ResearchProjectDetailWrapper {
		public Research_Project_Detail__c prjDetail { get; set; }
		public Boolean attended { get; set; }
		public Boolean noshow { get; set; }
		public Boolean flag { get; set; }
		public string strComment { get; set; }
		public string strIncentive { get; set; }
		public Boolean giftCardStatus { get; set; }
		public Boolean isInlineEdit { get; set; }
		public Boolean isEditIncentive { get; set; }
		public Boolean incentiveStatus { get; set; }
		public String strApprovalMsg { get; set; }
		public Boolean isAppliedForNewIncentive { get; set; }
		public Integer intCurrentYearIncentive { get; set; }
		public ResearchProjectDetailWrapper() {
			prjDetail = new Research_Project_Detail__c();
			attended = false;
			noshow = false;
			flag = false;
			strComment = '';
			strIncentive = '';
			giftCardStatus = false;
			isInlineEdit = false;
			isEditIncentive = false;
			incentiveStatus = false;
			strApprovalMsg = '';
			isAppliedForNewIncentive = false;
			intCurrentYearIncentive = 0;
		}
	}

	public PageReference backToProject() {
		PageReference pageRef = null;
		pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}
	public String getSubQuery(String searchValue) {
		String subString = '';
		if (String.isNotBlank(searchValue)) {
			searchValue = searchValue.trim();
			subString =
				' and (Contact__r.Name like \'%' +
				searchValue +
				'%\' or ' +
				' Contact__r.Email like \'%' +
				searchValue +
				'%\' or ' +
				' Research_Participant_Status__c like \'%' +
				searchValue +
				'%\') ';
		}
		return subString;
	}

	public void fetchProjectDetails(boolean flag) {
		lstResearchProjectDetailWrapper = new List<ResearchProjectDetailWrapper>();
		ResearchProjectDetailWrapper wrapperObj = null;

		Id projectId = objProject.Id;
		String strQueryString =
			'SELECT id, Research_Participant_Status_Number__c,Name, Company_Name__c, ' +
			'Contact__c,Contact__r.Email, Contact__r.Name, Contact__r.AccountId, Contact__r.UXResearch_Blacklist__c, Applicable_for_Incentive__c, ' +
			'Contact__r.Account.Name, Blacklist__c, Incentive__c, Reason__c, Proposed_Incentive__c, ' +
			'Comment__c, Blacklist_Reason__c, Research_Participant_Status__c, Opt_Out__c, Contact__r.Current_Year_Incentive__c, ' +
			'Research_Project_Master__c, Date_of_Attended__c, Participant_Email__c, Gift_card_swag_sent__c, Incentive_Apporved_by_UXR_Admin__c ' +
			'FROM Research_Project_Detail__c ' +
			'WHERE Research_Project_Master__c =: projectId  ';
		if (isApproval) {
			strQueryString = strQueryString + ' and Research_Participant_Status__c=\'Attended\' and Applicable_for_Incentive__c=true and Proposed_Incentive__c>0 ';
		}
		strQueryString = strQueryString + getSubQuery(searchString);
		strQueryString = strQueryString + ' order by ' + sortbyFieldAPIName + ' ' + orderAs + ' NULLS LAST';

		if (flag) {
			List<Research_Project_Master__c> projectMasterList = [
				SELECT
					Project_Id__c,
					NDA_URL__c,
					Calendly_EventId__c,
					CreatedDate,
					Customer_Types__c,
					Description__c,
					Last_View_Survey_Date__c,
					Id,
					Name,
					Number_of_Participants_to_Add_to_Project__c,
					Number_of_Allowed_Participant__c,
					Survey_Id__c,
					Primary_calendly_URL__c,
					Product_Area__c,
					Project_End_Date__c,
					Incentive_Amount__c,
					Incentive_Approval_Comment__c,
					Incentive_Approval_Status__c,
					Project_Start_Date__c,
					Project_Status__c,
					Researcher_Name__c,
					Screener_URL__c,
					Type_of_Research__c
				FROM Research_Project_Master__c
				WHERE Id = :projectId
			];
			if (projectMasterList.size() > 0) {
				objProject = projectMasterList[0];
			}
			approverComment = objProject.Incentive_Approval_Comment__c;

			if (String.isNotBlank(objProject.Incentive_Approval_Status__c) && (objProject.Incentive_Approval_Status__c == 'Approved' || objProject.Incentive_Approval_Status__c == 'Rejected')) {
				isApprovedOrRejected = true;
			}

			if (isApproval) {
				totalParticipant = [
					SELECT COUNT()
					FROM Research_Project_Detail__c
					WHERE Research_Project_Master__c = :projectId AND Research_Participant_Status__c = 'Attended' AND Applicable_for_Incentive__c = TRUE AND Proposed_Incentive__c > 0
				];
			} else {
				totalParticipant = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId];
			}

			Date lastViewDate = objProject.Last_View_Survey_Date__c;
			if (lastViewDate == null) {
				lastViewDate = System.today();
				newSurveyCount = [
					SELECT COUNT()
					FROM Research_Survey__c
					WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate >= :lastViewDate
				];
			} else {
				newSurveyCount = [
					SELECT COUNT()
					FROM Research_Survey__c
					WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate > :lastViewDate
				];
			}

			setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQueryString));
			setCon.setPageSize(PAGE_SIZE);
		}

		for (Research_Project_Detail__c projectDetailObj : (List<Research_Project_Detail__c>) setCon.getRecords()) {
			wrapperObj = new ResearchProjectDetailWrapper();
			wrapperObj.prjDetail = projectDetailObj;
			wrapperObj.strComment = wrapperObj.prjDetail.Blacklist_Reason__c;
			wrapperObj.strIncentive = String.valueOf(wrapperObj.prjDetail.Proposed_Incentive__c);
			wrapperObj.incentiveStatus = projectDetailObj.Applicable_for_Incentive__c;
			wrapperObj.giftCardStatus = wrapperObj.prjDetail.Gift_card_swag_sent__c;

			if (String.isBlank(wrapperObj.strIncentive)) {
				wrapperObj.strIncentive = '0';
			}

			if (wrapperObj.prjDetail.Incentive__c == null) {
				wrapperObj.prjDetail.Incentive__c = 0;
			}

			if (projectDetailObj.Incentive_Apporved_by_UXR_Admin__c && projectDetailObj.Incentive__c > 0) {
				wrapperObj.strApprovalMsg = '$' + projectDetailObj.Incentive__c + ' Approved by UXR Admin';
				if (projectDetailObj.Proposed_Incentive__c != null && projectDetailObj.Proposed_Incentive__c > 0) {
					wrapperObj.isAppliedForNewIncentive = true;
				} else {
					wrapperObj.isAppliedForNewIncentive = false;
				}
			}

			wrapperObj.intCurrentYearIncentive = Integer.valueOf(wrapperObj.prjDetail.Contact__r.Current_Year_Incentive__c);

			lstResearchProjectDetailWrapper.add(wrapperObj);
		}

		totalRecord = lstResearchProjectDetailWrapper.size();
		if (totalRecord == 0 && isConstructor == false) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No participants exist in this project. To add, go to "Manage Participants".'));
		}
	}

	public Boolean isReasonExist() {
		Boolean reasonFlag = false;
		for (ResearchProjectDetailWrapper wrapperObj : lstResearchProjectDetailWrapper) {
			if (wrapperObj.flag == true || wrapperObj.isInlineEdit == true || wrapperObj.isEditIncentive == true) {
				wrapperObj.prjDetail.Reason__c = wrapperObj.strComment;
				if (wrapperObj.prjDetail.Blacklist__c == true && String.isBlank(wrapperObj.strComment)) {
					reasonFlag = true;
				}
			}
		}
		return reasonFlag;
	}

	public PageReference saveProjectDetails() {
		saveProject();
		return null;
	}
	public PageReference saveProject() {
		//Boolean searchAll
		ContactTriggerHelper.skipTrigger = true;
		try {
			if (isReasonExist()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please enter reason for blocklist.'));
				selectedStatus = '';
				return null;
			}
			List<Research_Project_Detail__c> projectDetailList = new List<Research_Project_Detail__c>();
			List<Contact> lstUpdateContact = new List<Contact>();
			for (ResearchProjectDetailWrapper wrapperObj : lstResearchProjectDetailWrapper) {
				if (wrapperObj.flag == true || wrapperObj.isInlineEdit == true || wrapperObj.isEditIncentive == true) {
					if (String.isNotBlank(selectedStatus) && wrapperObj.flag == true) {
						wrapperObj.prjDetail.Research_Participant_Status__c = selectedStatus;
						if ('Attended' == selectedStatus) {
							if (wrapperObj.prjDetail.Date_of_Attended__c == null) {
								wrapperObj.prjDetail.Date_of_Attended__c = Date.today();
							}
						}

						if ('Attended' != wrapperObj.prjDetail.Research_Participant_Status__c) {
							if (wrapperObj.prjDetail.Incentive_Apporved_by_UXR_Admin__c == false) {
								wrapperObj.prjDetail.Incentive__c = 0;
								wrapperObj.prjDetail.Gift_card_swag_sent__c = false;
								wrapperObj.giftCardStatus = false;
							}
							wrapperObj.strIncentive = '0';
							wrapperObj.prjDetail.Proposed_Incentive__c = 0;
							wrapperObj.prjDetail.Applicable_for_Incentive__c = false;
							wrapperObj.incentiveStatus = false;
							//if(wrapperObj.prjDetail.Incentive_Apporved_by_UXR_Admin__c){
							//wrapperObj.prjDetail.Gift_card_swag_sent__c = false;
							//wrapperObj.giftCardStatus = false;
							//}
							//wrapperObj.prjDetail.Incentive_Apporved_by_UXR_Admin__c=false;
						}
					}

					//Changes as on 15th feb related to blacklist
					//If participant is blacklist then mark on related contact level also as blacklist
					if (wrapperObj.prjDetail.Blacklist__c == true) {
						Contact objPartContact = new Contact(id = wrapperObj.prjDetail.Contact__c);
						objPartContact.UXResearch_Blacklist__c = true;
						lstUpdateContact.add(objPartContact);
					} else if (wrapperObj.prjDetail.Blacklist__c == false && wrapperObj.prjDetail.Contact__r.UXResearch_Blacklist__c == true) {
						Contact objPartContact = new Contact(id = wrapperObj.prjDetail.Contact__c);
						objPartContact.UXResearch_Blacklist__c = false;
						lstUpdateContact.add(objPartContact);
					}

					//***************Incentive logic Start********
					wrapperObj.prjDetail.Applicable_for_Incentive__c = wrapperObj.incentiveStatus;
					if (String.isNotBlank(wrapperObj.strIncentive) && wrapperObj.incentiveStatus == true) {
						wrapperObj.prjDetail.Proposed_Incentive__c = Integer.valueOf(wrapperObj.strIncentive);
					} else {
						wrapperObj.prjDetail.Proposed_Incentive__c = 0;
						wrapperObj.strIncentive = '0';
					}

					//***************Incentive logic End********

					wrapperObj.prjDetail.Blacklist_Reason__c = wrapperObj.strComment;
					projectDetailList.add(wrapperObj.prjDetail);
				}
			}

			if (projectDetailList.size() > 0) {
				update projectDetailList;
			}
			if (lstUpdateContact.size() > 0) {
				update lstUpdateContact;
			}
			for (ResearchProjectDetailWrapper wrapperObj : lstResearchProjectDetailWrapper) {
				if (wrapperObj.flag == true || wrapperObj.isInlineEdit == true || wrapperObj.isEditIncentive == true) {
					wrapperObj.isInlineEdit = false;
					wrapperObj.isEditIncentive = false;
				}
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Attendance recorded successfully.'));
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
		}
		selectedStatus = '';
		return null;
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

	public Integer getTotalRecord() {
		Decimal totalSize = 0;
		if (setCon != null) {
			totalSize = setCon.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
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
		saveSetControler();
		setCon.first();
		fetchProjectDetails(false);
	}

	/** returns the last page of the page set*/
	public void last() {
		saveSetControler();
		setCon.last();
		fetchProjectDetails(false);
	}

	/** returns the previous page of the page set*/
	public void previous() {
		saveSetControler();
		setCon.previous();
		fetchProjectDetails(false);
	}

	/** returns the next page of the page set*/
	public void next() {
		saveSetControler();
		setCon.next();
		fetchProjectDetails(false);
	}

	public PageReference saveSetControler() {
		try {
			Integer currentPageNumber = pageNumber;
			setCon.save();
			if (currentPageNumber != 1) {
				setCon.setPageNumber(currentPageNumber - 1);
				setCon.next();
			}
		} catch (Exception e) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage());
			ApexPages.addMessage(myMsg);
		}
		return null;
	}

	public pageReference sortParticipantList() {
		setSortingFilter();
		PageReference pageRef = new PageReference('/apex/UR_ProjectCloser?projectId=' + objProject.Id + '&orderas=' + orderAs + '&sortby=' + sortbyFieldAPIName);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void setSortingFilter() {
		if (sortbyFieldAPIName != prevSortbyFieldAPIName) {
			orderAs = 'asc';
		} else {
			if ('asc' == orderAs) {
				orderAs = 'desc';
			} else {
				orderAs = 'asc';
			}
		}
	}

	public pageReference UpdatePartDetail() {
		saveProject();
		return null;
	}

	public void searchParticipantFromList() {
		fetchProjectDetails(true);
	}

	public PageReference updateGiftCardStatus() {
		string strPartId = ApexPages.CurrentPage().getparameters().get('strPartId');
		try {
			List<Research_Project_Detail__c> projectDetailList = new List<Research_Project_Detail__c>();
			List<Contact> lstUpdateContact = new List<Contact>();
			String errorMsg = '';
			ResearchProjectDetailWrapper currentWrapperObj = null;
			for (ResearchProjectDetailWrapper wrapperObj : lstResearchProjectDetailWrapper) {
				if (strPartId != null && strPartId == wrapperObj.prjDetail.Id) {
					if (isEditable) {
						currentWrapperObj = wrapperObj;
						wrapperObj.prjDetail.Reason__c = wrapperObj.strComment;
						if (wrapperObj.prjDetail.Blacklist__c == true && String.isBlank(wrapperObj.prjDetail.Reason__c)) {
							errorMsg = 'Blacklist reason is blank';
						} else if (wrapperObj.prjDetail.Blacklist__c == true && String.isNotBlank(wrapperObj.prjDetail.Reason__c)) {
							Contact objPartContact = new Contact(id = wrapperObj.prjDetail.Contact__c);
							objPartContact.UXResearch_Blacklist__c = true;
							lstUpdateContact.add(objPartContact);
						} else if (wrapperObj.prjDetail.Blacklist__c == false && wrapperObj.prjDetail.Contact__r.UXResearch_Blacklist__c == true) {
							Contact objPartContact = new Contact(id = wrapperObj.prjDetail.Contact__c);
							objPartContact.UXResearch_Blacklist__c = false;
							lstUpdateContact.add(objPartContact);
						}

						//***************Incentive logic Start********
						wrapperObj.prjDetail.Applicable_for_Incentive__c = wrapperObj.incentiveStatus;
						if (String.isNotBlank(wrapperObj.strIncentive) && wrapperObj.incentiveStatus == true) {
							wrapperObj.prjDetail.Proposed_Incentive__c = Integer.valueOf(wrapperObj.strIncentive);
						} else {
							wrapperObj.prjDetail.Proposed_Incentive__c = 0;
							wrapperObj.strIncentive = '0';
						}
						//***************Incentive logic End********
						wrapperObj.prjDetail.Blacklist_Reason__c = wrapperObj.strComment;
					}
					projectDetailList.add(wrapperObj.prjDetail);
				}
			}
			if (String.isNotBlank(errorMsg)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please enter reason for blocklist.'));
				return null;
			}

			if (projectDetailList.size() > 0) {
				update projectDetailList;
				if (currentWrapperObj != null) {
					currentWrapperObj.isInlineEdit = false;
					currentWrapperObj.isEditIncentive = false;
				}
			}
			if (lstUpdateContact.size() > 0) {
				update lstUpdateContact;
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
		}
		return null;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : update incentive amount on attended participant.
	 * @Parm        : N/A
	 * @Return      : void
	 **/
	public void updateIncentiveStatus() {
		try {
			String strParticipantId = ApexPages.CurrentPage().getparameters().get('strPartId');
			List<Research_Project_Detail__c> list_projectDetails = new List<Research_Project_Detail__c>();
			List<ResearchProjectDetailWrapper> list_AttenedParticipants = new List<ResearchProjectDetailWrapper>();
			String strParticipant = '';
			Id idParticipant = null;
			Boolean blnMassUpdate = false;
			if (set_ParticipantIds.size() > 0) {
				blnMassUpdate = true;
			}
			for (ResearchProjectDetailWrapper objWrapper : lstResearchProjectDetailWrapper) {
				idParticipant = objWrapper.prjDetail.Id;

				if ((set_ParticipantIds.size() > 0 && set_ParticipantIds.contains(idParticipant)) || (strParticipantId != null && strParticipantId == idParticipant)) {
					if (blnMassUpdate) {
						objWrapper.strIncentive = intMultiIncentive + '';
					}

					list_AttenedParticipants.add(objWrapper);
					objWrapper.prjDetail.Applicable_for_Incentive__c = true;
					objWrapper.incentiveStatus = true;

					//Check Maximum incentive limit.
					if (INT_MAX_INCENTIVE != null && INT_MAX_INCENTIVE > 0 && objWrapper.prjDetail.Contact__r.Current_Year_Incentive__c != null && Integer.valueOf(objWrapper.strIncentive) > 0) {
						Integer intTotalIncentiveApplied = Integer.valueOf(objWrapper.strIncentive) + Integer.valueOf(objWrapper.prjDetail.Contact__r.Current_Year_Incentive__c);

						if (intTotalIncentiveApplied > INT_MAX_INCENTIVE) {
							strParticipant = strParticipant + objWrapper.prjDetail.Contact__r.Name + ', ';
						}
					}

					objWrapper.prjDetail.Proposed_Incentive__c = Integer.valueOf(objWrapper.strIncentive);

					//Set second level incentive flag.
					if (
						objWrapper.prjDetail.Incentive_Apporved_by_UXR_Admin__c &&
						objWrapper.prjDetail.Incentive__c > 0 &&
						objWrapper.prjDetail.Proposed_Incentive__c != null &&
						objWrapper.prjDetail.Proposed_Incentive__c > 0
					) {
						objWrapper.isAppliedForNewIncentive = true;
					} else {
						objWrapper.isAppliedForNewIncentive = false;
					}

					list_projectDetails.add(objWrapper.prjDetail);
				}
			}

			if (String.isNotBlank(strParticipant)) {
				strParticipant = strParticipant.removeEnd(',');
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, strParticipant + MSG_MAX_INCENTIVE_LIMIT));
			}

			if (list_projectDetails.size() > 0) {
				update list_projectDetails;

				if (list_AttenedParticipants.size() > 0) {
					for (ResearchProjectDetailWrapper objWrapper : list_AttenedParticipants) {
						objWrapper.isInlineEdit = false;
						objWrapper.isEditIncentive = false;
					}
				}

				if (blnMassUpdate) {
					String strMsg = MSG_SUCCESS;
					strMsg = strMsg.replace('#', intTotalAttended + '');
					ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, strMsg));
				}
			}
		} catch (Exception objExp) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, objExp + ''));
		}
	}

	public void approveRequest() {
		//Check apex job limit.
		//On delete, one batch will be execute.
		if (UR_UtilityCtrl.checkApexJobLimit(1)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, UR_UtilityCtrl.EXCEED_APEX_JOB_MSG));
			return;
		}

		objProject.Incentive_Approval_Status__c = 'Approved';
		objProject.Incentive_Approval_Comment__c = approverComment + '\n' + 'Approved by: ' + UserInfo.getName() + '\n' + 'Approved on : ' + System.today();
		update objProject;
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Request succesfully approved.'));

		//Call batch class to update gift card status flag value as true
		UR_UpdateIncentiveAmountBatch batchObj = new UR_UpdateIncentiveAmountBatch();
		batchObj.projectId = objProject.Id;
		Database.executeBatch(batchObj, 500);
		isApprovedOrRejected = true;
	}

	public void rejectRequest() {
		objProject.Incentive_Approval_Status__c = 'Rejected';
		objProject.Incentive_Approval_Comment__c = approverComment + '\n' + 'Rejected by: ' + UserInfo.getName() + '\n' + 'Rejected on : ' + System.today();
		update objProject;
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Request has been rejected.'));
		isApprovedOrRejected = true;
	}

	public void checkApprover() {
		isApprover = false;
		List<Group> groupList = [SELECT Id FROM Group WHERE DeveloperName = 'UXR_Admin_Group'];
		List<Id> queueMemberList = new List<Id>();
		if (groupList.size() > 0) {
			Id groupId = groupList[0].Id;
			Id loginUserId = UserInfo.getUserId();
			List<GroupMember> groupMemberList = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId AND UserOrGroupId = :loginUserId];
			if (groupMemberList.size() > 0) {
				isApprover = true;
			}
		}
	}

	private PageReference RetriveNotes() {
		objNote = new Note();
		List<Note> lstNote = [
			SELECT Body, Id, ParentId, LastModifiedDate, LastModifiedBy.Name, Title
			FROM Note
			WHERE ParentId = :objProject.Id AND Title LIKE '%-Result'
			LIMIT 1
		];
		if (lstNote != null && lstNote.size() > 0) {
			objNote = lstNote[0];
		}
		return null;
	}

	public void AddNote() {
		addNote = true;
	}
	public void CancelNote() {
		addNote = false;
		RetriveNotes();
	}
	public void SaveNotes() {
		if (objNote.Id == null) {
			objNote.ParentId = objProject.Id;
			objNote.Title = objProject.Name + '-Result';
		}
		upsert objNote;
		addNote = false;
		RetriveNotes();
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Count selected attended participant.
	 * @Parm        : N/A
	 * @Return      : void
	 **/
	public void countAttendedParticipant() {
		intMultiIncentive = Integer.valueOf(objProject.Incentive_Amount__c);
		intTotalParticipantSelected = 0;
		intTotalAttended = 0;
		for (ResearchProjectDetailWrapper objWrapper : lstResearchProjectDetailWrapper) {
			if (objWrapper.flag) {
				intTotalParticipantSelected = intTotalParticipantSelected + 1;
				if (STATUS_ATTENDED == objWrapper.prjDetail.Research_Participant_Status__c) {
					intTotalAttended = intTotalAttended + 1;
				}
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Allow incentive to attended participant.
	 * @Parm        : N/A
	 * @Return      : void
	 **/
	public void allowIncentive() {
		set_ParticipantIds = new Set<Id>();
		for (ResearchProjectDetailWrapper objWrapper : lstResearchProjectDetailWrapper) {
			if (objWrapper.flag && STATUS_ATTENDED == objWrapper.prjDetail.Research_Participant_Status__c) {
				set_ParticipantIds.add(objWrapper.prjDetail.Id);
			}
		}

		updateIncentiveStatus();
		set_ParticipantIds.clear();
	}
}