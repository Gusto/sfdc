public with sharing class UR_MenuHeaderComponentCtrl {
	public string projectId;
	public Research_Project_Master__c objProject { get; set; }
	public list<Research_Project_Master__c> lstPM;
	public Research_Project_Detail__c objProjectDetail { get; set; }
	public string mainTab { get; set; }
	public string subTab { get; set; }
	public string activePD { get; set; }
	public string activePart { get; set; }
	public string activeEmail { get; set; }
	public string activeCal { get; set; }
	public string activeHelp { get; set; }
	public string activeResults { get; set; }

	public string subTabMP { get; set; }
	public string subTabSS { get; set; }
	public string subTabVSR { get; set; }
	public string subTabITI { get; set; }
	public string subTabSFUI { get; set; }
	public string subTabRA { get; set; }
	public boolean isProjectClosed { get; set; }
	public boolean isEditable { get; set; }
	public boolean isProjectEditAccess { get; set; }
	public string btnDivStyle { get; set; }
	public Integer totalAttended { get; set; }
	public Integer totalNoShowed { get; set; }
	public Integer totalBlacklisted { get; set; }
	//public boolean underApproval{get;set;}
	public String approvalStatus { get; set; }
	public string apColor { get; set; }
	public string helpTextKey { get; set; }
	public string helpTextValue { get; set; }
	public boolean helpTextRequired { get; set; }
	public boolean isParticipantExist { get; set; }
	public Integer csvUploadedCount { get; set; }
	public boolean isParticipantContacted { get; set; }
	public Integer intTotalScheduleEmail { get; set; }
	public Integer intFailScheduleEmail { get; set; }
	public Integer intFailScheduleJob { get; set; }
	public Integer intFailSendEmail { get; set; }
	public string cssGroupButton { get; set; }
	public string cssGroupButtonOutline { get; set; }
	public boolean isEmailExist { get; set; }
	public boolean isEventExist { get; set; }
	public Integer newSurveyCount { get; set; }
	public Integer newEventCount { get; set; }
	public Integer unreadEmailCount { get; set; }
	public Integer surveyCompleted { get; set; }
	public Research_Schedule_Email_Participant__c failScheduleObj { get; set; }

	public UR_MenuHeaderComponentCtrl() {
		isParticipantExist = false;
		csvUploadedCount = 0;
		isParticipantContacted = false;
		helpTextRequired = false;
		isProjectClosed = false;
		//underApproval=false;
		isEditable = true;
		isProjectEditAccess = true;
		btnDivStyle = '';
		objProject = new Research_Project_Master__c();
		lstPM = new List<Research_Project_Master__c>();
		totalAttended = 0;
		totalNoShowed = 0;
		totalBlacklisted = 0;
		helpTextValue = '';
		cssGroupButton = 'slds-button slds-button__icon--large slds-button-group-item slds-button_brand'; // JSK
		cssGroupButtonOutline = 'slds-button slds-button__icon--large slds-button-group-item slds-button_outline-brand'; // JSK
		objProjectDetail = new Research_Project_Detail__c();
	}
	public void setprojectId(String c) {
		projectId = c;
		string currentUserId = UserInfo.getUserId();

		if (lstPM == null || lstPM.size() == 0) {
			if (string.isBlank(projectId)) {
				isEditable = true;
				isProjectEditAccess = true;
			} else {
				isEditable = UR_UtilityCtrl.IsEditAccess(projectId);
				isProjectEditAccess = UR_UtilityCtrl.IsProjectEditAccess(projectId);
			}

			lstPM = [
				SELECT
					id,
					Name,
					Project_Status__c,
					Last_View_Survey_Date__c,
					Project_Id__c,
					Additional_Participant_Status__c,
					Approver_Comment__c,
					Incentive_Approval_Status__c,
					Incentive_Approval_Comment__c,
					Last_View_Calendar_Date__c,
					Closed_Schedule_Email_Error_Message__c,
					Closed_Send_Email_Error_Message__c,
					CSV_Error__c
				FROM Research_Project_Master__c
				WHERE Id = :projectId
				LIMIT 1
			];

			List<Research_Project_Detail__c> projectDetailList = [
				SELECT id, Research_Participant_Status__c, Blacklist__c
				FROM Research_Project_Detail__c
				WHERE Research_Project_Master__c = :projectId AND Research_Participant_Status__c != 'Reserved'
			];

			if (lstPM != null && lstPM.size() > 0) {
				objProject = lstPM[0];
				apColor = null;
				if (objProject.Additional_Participant_Status__c == 'Approved') {
					apColor = '#027e46';
				}
				if (objProject.Additional_Participant_Status__c == 'Rejected') {
					apColor = '#c23934';
				}
				//underApproval=Approval.isLocked(projectId);
				isProjectClosed = false;
				if (objProject.Project_Status__c == 'Complete') {
					isProjectClosed = true;
				}
				//Check logged in use has edit access on this project or not
				List<Research_Project_Teams__c> lstReasearchTeam = [
					SELECT id, Edit_Access__c
					FROM Research_Project_Teams__c
					WHERE User__c = :currentUserId AND Research_Project_Master__c = :projectId
					LIMIT 1
				];
				if (lstReasearchTeam != null && lstReasearchTeam.size() > 0) {
					isEditable = lstReasearchTeam[0].Edit_Access__c;
				}
				if (isEditable == false) {
					btnDivStyle = 'pc-btn-remove';
				}

				for (Research_Project_Detail__c detailObj : projectDetailList) {
					if (detailObj.Research_Participant_Status__c == 'No Show') {
						totalNoShowed = totalNoShowed + 1;
					}
					if (detailObj.Research_Participant_Status__c == 'Attended') {
						totalAttended = totalAttended + 1;
					}
					if (detailObj.Blacklist__c == true) {
						totalBlacklisted = totalBlacklisted + 1;
					}
				}
				isParticipantExist = UR_UtilityCtrl.participantExist(projectId);
				isParticipantContacted = participantContacted(projectId);
				isEmailExist = UR_UtilityCtrl.emailExist(projectId);
				isEventExist = UR_UtilityCtrl.calendarEventExist(projectId);
				Date lastViewDate = lstPM[0].Last_View_Survey_Date__c;
				if (lastViewDate == null) {
					lastViewDate = System.today();
					newSurveyCount = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate >= :lastViewDate];
				} else {
					newSurveyCount = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate > :lastViewDate];
				}

				csvUploadedCount = [SELECT COUNT() FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :projectId];

				Date lastViewCalendarDate = lstPM[0].Last_View_Calendar_Date__c;
				if (lastViewCalendarDate == null) {
					lastViewCalendarDate = System.today();
					newEventCount = [
						SELECT COUNT()
						FROM Event
						WHERE WhatId IN (SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId) AND CreatedDate >= :lastViewCalendarDate
					];
				} else {
					newEventCount = [
						SELECT COUNT()
						FROM Event
						WHERE WhatId IN (SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId) AND CreatedDate > :lastViewCalendarDate
					];
				}

				surveyCompleted = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId];

				unreadEmailCount = [
					SELECT COUNT()
					FROM EmailMessage
					WHERE RelatedToId IN (SELECT id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId) AND Unread_Email__c = TRUE
				];

				List<Research_Project_Detail__c> list_ProjectDetail = [
					SELECT id, E_Mail_Status__c, Send_Email_Error__c
					FROM Research_Project_Detail__c
					WHERE Research_Project_Master__c = :projectId AND E_Mail_Status__c = 'Fail'
				];

				if (list_ProjectDetail.size() > 0) {
					objProjectDetail = list_ProjectDetail[0];
				} else {
					objProjectDetail = new Research_Project_Detail__c();
				}
				intFailSendEmail = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId AND E_Mail_Status__c = 'Fail'];
			}
		}
		ManageMenu();
		fetchScheduleJob();
	}
	public string getprojectId() {
		return projectId;
	}
	@TestVisible
	private void ManageMenu() {
		helpTextKey = '';
		if (mainTab == 'Project Details') {
			subTab = null;
			activePD = 'slds-is-active';
			activePart = null;
			activeEmail = null;
			activeCal = null;
			activeHelp = null;
			helpTextKey = 'Project Details';
		}
		if (mainTab == 'Incentive Approval') {
			subTab = null;
			activePD = null;
			activePart = null;
			activeEmail = null;
			activeCal = null;
			activeResults = 'slds-is-active';
			activeHelp = null;
			helpTextKey = 'Incentive Approval Page';
		}
		if (mainTab == 'Results') {
			activePD = null;
			activePart = null;
			activeResults = 'slds-is-active';
			activeEmail = null;
			activeCal = null;
			activeHelp = null;

			if (subTab == 'RA') {
				subTabMP = 'slds-button_neutral';
				subTabSS = 'slds-button_neutral';
				subTabVSR = 'slds-button_neutral';
				subTabITI = 'slds-button_neutral';
				subTabSFUI = 'slds-button_neutral';
				subTabRA = 'slds-button_brand';
				helpTextKey = 'Report participation';
			}
			if (subTab == 'VSR') {
				subTabMP = 'slds-button_neutral';
				subTabSS = 'slds-button_neutral';
				subTabVSR = 'slds-button_brand';
				subTabITI = 'slds-button_neutral';
				subTabSFUI = 'slds-button_neutral';
				subTabRA = 'slds-button_neutral';
				helpTextKey = 'Survey Results';
			}
		}
		if (mainTab == 'Participants') {
			activePD = null;
			activePart = 'slds-is-active';
			activeEmail = null;
			activeCal = null;
			activeHelp = null;

			if (subTab == 'MP' || subTab == 'MP-CSV' || subTab == 'MP-SFDC') {
				subTabMP = 'slds-button_brand';
				subTabSS = 'slds-button_neutral';
				subTabVSR = 'slds-button_neutral';
				subTabITI = 'slds-button_neutral';
				subTabSFUI = 'slds-button_neutral';
				subTabRA = 'slds-button_neutral';
				if (subTab == 'MP') {
					if (isParticipantExist) {
						if (intTotalScheduleEmail > 0) {
							helpTextKey = 'Manage participants (Have people now, email is scheduled)';
						} else if (isParticipantContacted) {
							helpTextKey = 'Manage participants (Have people now, have been contacted)';
						} else {
							helpTextKey = 'Manage participants (Have people now, haven’t contacted)';
						}
					} else {
						helpTextKey = 'Manage participants (Don’t have anyone)';
					}
				} else if (subTab == 'MP-CSV') {
					helpTextKey = 'Manage CSV page';
				} else if (subTab == 'MP-SFDC') {
					helpTextKey = 'Salesforce Search page';
				}
			}
			if (subTab == 'SS') {
				subTabMP = 'slds-button_neutral';
				subTabSS = 'slds-button_brand';
				subTabVSR = 'slds-button_neutral';
				subTabITI = 'slds-button_neutral';
				subTabSFUI = 'slds-button_neutral';
				subTabRA = 'slds-button_neutral';
				helpTextKey = 'Send survey page (how to link up qualtrics+links)';
			}
			if (subTab == 'ITI') {
				subTabMP = 'slds-button_neutral';
				subTabSS = 'slds-button_neutral';
				subTabVSR = 'slds-button_neutral';
				subTabITI = 'slds-button_brand';
				subTabSFUI = 'slds-button_neutral';
				subTabRA = 'slds-button_neutral';
				helpTextKey = 'Invite to interview page (how to link up calendly+links)';
			}
			if (subTab == 'SFUI') {
				subTabMP = 'slds-button_neutral';
				subTabSS = 'slds-button_neutral';
				subTabVSR = 'slds-button_neutral';
				subTabITI = 'slds-button_neutral';
				subTabSFUI = 'slds-button_brand';
				subTabRA = 'slds-button_neutral';
				helpTextKey = 'Send Follow-up page';
			}
		}
		if (mainTab == 'Emails' || mainTab == 'ScheduleEmails') {
			subTab = null;
			activePD = null;
			activePart = null;
			activeEmail = 'slds-is-active';
			activeCal = null;
			activeHelp = null;
			if (mainTab == 'Emails') {
				helpTextKey = 'Emails page';
			}
			if (mainTab == 'ScheduleEmails') {
				helpTextKey = 'View Schedule Email';
			}
		}
		if (mainTab == 'Calendar') {
			subTab = null;
			activePD = null;
			activePart = null;
			activeEmail = null;
			activeCal = 'slds-is-active';
			activeHelp = null;
			helpTextKey = 'Calendar page';
		}
		if (mainTab == 'Help') {
			subTab = null;
			activePD = null;
			activePart = null;
			activeEmail = null;
			activeCal = null;
			activeHelp = 'slds-is-active';
		}
		if (objProject.Project_Status__c == 'Complete') {
			helpTextKey = 'Project is closed';
		}

		List<UXR_Scout_Help__c> helpTextList = [
			SELECT Help_Text__c, Tab_Name__c, Visible_by_Default__c
			FROM UXR_Scout_Help__c
			WHERE Tab_Name__c = :helpTextKey
		];
		if (helpTextList.size() > 0) {
			helpTextValue = helpTextList[0].Help_Text__c;
			helpTextRequired = helpTextList[0].Visible_by_Default__c;
			if (String.isNotBlank(helpTextValue) && helpTextValue.indexOf('{!Research_Project_Master__c.Project_Id__c}') > 0) {
				helpTextValue = helpTextValue.replace('{!Research_Project_Master__c.Project_Id__c}', objProject.Project_Id__c);
			}
		}
	}

	public PageReference markProjectCompleted() {
		//Check apex job limit.
		//Once user comlplete the project then 1 batch will be executed.
		if (UR_UtilityCtrl.checkApexJobLimit(1)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, UR_UtilityCtrl.EXCEED_APEX_JOB_MSG));
			return null;
		}

		//Release all reserved participants
		List<Research_Project_Detail_Data_Info__c> list_ProjectDetailInfoRecord = [
			SELECT id, Research_Project_Detail__r.Research_Participant_Status__c
			FROM Research_Project_Detail_Data_Info__c
			WHERE Research_Project_Detail__r.Research_Project_Master__c = :objProject.Id AND Research_Project_Detail__r.Research_Participant_Status__c = 'Reserved'
		];
		if (list_ProjectDetailInfoRecord.size() > 0) {
			delete list_ProjectDetailInfoRecord;
		}

		List<Research_Project_Detail__c> list_ProjectDetailRecord = [
			SELECT Id
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id AND Research_Participant_Status__c = 'Reserved'
		];
		if (list_ProjectDetailRecord.size() > 0) {
			delete list_ProjectDetailRecord;
		}

		objProject.Project_Status__c = 'Complete';
		objProject.Project_Completion_Date__c = Date.today();
		update objProject;

		UR_CloseProjectBatch batchObj = new UR_CloseProjectBatch();
		batchObj.projectId = objProject.Id;
		batchObj.projectStatus = 'Complete';
		Database.executeBatch(batchObj, 200);
		//UR_MenuHeaderComponentCtrl.UpdateProjectCompletionDateOnContact(objProject.Id, Date.Today());

		PageReference pageRef = new PageReference('/apex/UR_ProjectDetail?st=ct&id=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public PageReference ReOpenProject() {
		//Check apex job limit.
		//Once user re-open the project then 1 batch will be executed.
		if (UR_UtilityCtrl.checkApexJobLimit(1)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, UR_UtilityCtrl.EXCEED_APEX_JOB_MSG));
			return null;
		}

		objProject.Project_Status__c = 'Initiated';
		objProject.Re_Open_Date__c = System.today();
		if (objProject.Research_Project_Details__r != null && objProject.Research_Project_Details__r.size() > 0) {
			objProject.Project_Status__c = 'In-Progress';
		}
		update objProject;

		UR_CloseProjectBatch batchObj = new UR_CloseProjectBatch();
		batchObj.projectId = objProject.Id;
		batchObj.projectStatus = 'Re-Open';
		Database.executeBatch(batchObj, 200);
		//UR_MenuHeaderComponentCtrl.UpdateProjectCompletionDateOnContact(objProject.Id, null);

		PageReference pageRef = new PageReference('/apex/UR_ProjectDetail?st=open&id=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//Update date field on Contact to keep trak his last participated in any project
	//Track only project which is not Survey type
	/*
   	public static void UpdateProjectCompletionDateOnContact(Id projectMasterId, Date dt){
        enableDisableContactTrigger(true); //Disable contact related trigger.
    	List<Contact> lstUpdateContact=new List<Contact>();
        for(Research_Project_Detail__c rpd:[select Research_Project_Master__r.Type_of_Research__c, Contact__c 
    				from Research_Project_Detail__c  where Research_Project_Master__c=:projectMasterId and 
    			Research_Project_Master__r.Type_of_Research__c!='Survey_only']){
                    
			Contact ct=new Contact(id=rpd.Contact__c);
			ct.UR_Recent_Project_Completion_date__c=dt;
			lstUpdateContact.add(ct);	             
    	}
    	if(lstUpdateContact!=null && lstUpdateContact.size()>0){
    		update lstUpdateContact; 
    	}
        enableDisableContactTrigger(false); //Enable contact related trigger.
    }
    
    public static void enableDisableContactTrigger(boolean flag){
        ContactTriggerHelper.skipTrigger = flag;
	    AccountTriggerHelper.skipTrigger = flag;
        CampaignMemberTriggerHelper.skipTrigger = flag;
    }*/

	public PageReference resetApproval() {
		objProject.Additional_Participant_Status__c = null;
		update objProject;
		return null;
	}

	public PageReference resetIncentiveApproval() {
		objProject.Incentive_Approval_Status__c = null;
		update objProject;
		return null;
	}

	public PageReference RedirectToAttendance() {
		PageReference pageRef = new PageReference('/apex/UR_ProjectCloser?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public pagereference blankSendSurvey() {
		return blankEmailURL('SS');
	}

	public pagereference blankInviteToInterview() {
		return blankEmailURL('ITI');
	}

	public pagereference blankSendFollowUp() {
		return blankEmailURL('SFUI');
	}

	public pagereference blankEmailURL(String flagValue) {
		PageReference pageRef = new PageReference('/apex/UR_SendEmail?Id=' + objProject.Id + '&type=' + flagValue);
		pageRef.setRedirect(true);
		return pageRef;
	}
	public void fetchProjectDetails() {
		totalNoShowed = 0;
		totalAttended = 0;
		totalBlacklisted = 0;
		for (Research_Project_Detail__c detailObj : [SELECT id, Research_Participant_Status__c, Blacklist__c FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId]) {
			if (detailObj.Research_Participant_Status__c == 'No Show') {
				totalNoShowed = totalNoShowed + 1;
			}
			if (detailObj.Research_Participant_Status__c == 'Attended') {
				totalAttended = totalAttended + 1;
			}
			if (detailObj.Blacklist__c == true) {
				totalBlacklisted = totalBlacklisted + 1;
			}
		}
	}

	public void fetchScheduleJob() {
		String strStatus = 'Schedule';
		Date dateObj = Date.today();
		String timeObj = DateTime.now().hour() + '';
		Set<String> timeObjSet = new Set<String>();
		for (Integer iCount = Integer.valueOf(timeObj); iCount <= 23; iCount++) {
			timeObjSet.add(iCount + '');
		}

		intTotalScheduleEmail = [
			SELECT COUNT()
			FROM Research_Schedule_Email__c
			WHERE
				UXR_Scout__c = :projectId
				AND (Schedule_Email_Date__c >= :dateObj
				OR (Schedule_Email_Date__c = :dateObj
				AND Schedule_Email_Time__c IN :timeObjSet)
				OR Total_Fail_Email__c > 0
				OR (Total_Scheduled_Email__c > 0
				AND Schedule_Email_Date__c <= :dateObj))
		];

		intFailScheduleEmail = [
			SELECT COUNT()
			FROM Research_Schedule_Email__c
			WHERE UXR_Scout__c = :projectId AND Total_Fail_Email__c > 0
		];

		intFailScheduleJob = [
			SELECT COUNT()
			FROM Research_Schedule_Email__c
			WHERE
				UXR_Scout__c = :projectId
				AND Total_Scheduled_Email__c > 0
				AND (Schedule_Email_Date__c < :dateObj
				OR (Schedule_Email_Date__c = :dateObj
				AND Schedule_Email_Time__c NOT IN :timeObjSet))
		];

		failScheduleObj = new Research_Schedule_Email_Participant__c();
		List<Research_Schedule_Email_Participant__c> lstFailScheduleObj = [
			SELECT id, Error_Message__c
			FROM Research_Schedule_Email_Participant__c
			WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND Schedule_Email_Status__c = 'Fail'
		];
		if (lstFailScheduleObj.size() > 0) {
			failScheduleObj = lstFailScheduleObj[0];
		}
	}

	//This method redirect us to add Participant page.
	public PageReference addParticipantsSearch() {
		PageReference pageRef = new PageReference('/apex/UR_ManageContact?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method redirect us to add Participant page.
	public PageReference addParticipantsCSV() {
		PageReference pageRef = new PageReference('/apex/UR_ManageCSV?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void closeScheduleErrorMessage() {
		objProject.Closed_Schedule_Email_Error_Message__c = true;
		if (objProject.Id != null) {
			UR_ProjectMasterTriggerHelper.skipTrigger = true;
			update objProject;
			UR_ProjectMasterTriggerHelper.skipTrigger = false;
		}
	}

	public void closeSendEmailErrorMessage() {
		objProject.Closed_Send_Email_Error_Message__c = true;
		if (objProject.Id != null) {
			UR_ProjectMasterTriggerHelper.skipTrigger = true;
			update objProject;
			UR_ProjectMasterTriggerHelper.skipTrigger = false;
		}
	}

	public void closeCSVErrorMessage() {
		objProject.CSV_Error__c = '';
		if (objProject.Id != null) {
			UR_ProjectMasterTriggerHelper.skipTrigger = true;
			update objProject;
			UR_ProjectMasterTriggerHelper.skipTrigger = false;
		}
	}

	public boolean participantContacted(Id projectId) {
		//Check if project participant is available
		Boolean isRecordExist = false;
		integer partCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId AND Research_Participant_Status__c != 'Reserved'];
		if (partCount > 0) {
			isRecordExist = true;
		}
		return isRecordExist;
	}
}