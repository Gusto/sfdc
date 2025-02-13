/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_NewEditProjectCtrl_Test>>
 * Description...........: <<This class is used to create/edit UXR Scout record and used to add team member in project.>>
 *-------------------------------------------------------------------------------*/
public without sharing class UR_NewEditProjectCtrl {
	public boolean isEditable { get; set; }
	public Research_Project_Master__c projectMaster { get; set; }
	public Map<Integer, Research_Project_Teams__c> projectTeamMap { get; set; }
	public Integer rowIndex { get; set; }
	public Integer deleteRowIndex { get; set; }
	public Set<Id> userId { get; set; }
	public Set<Id> existingUserId { get; set; }
	public boolean isNewRecord { get; set; }
	public boolean isOwnerPartOfTeam { get; set; }
	public List<Research_Project_Teams__c> deleteList { get; set; }
	public Boolean isOwnerChanged { get; set; }
	public Research_Project_Teams__c projectTeamObj { get; set; }
	public List<selectOption> selBufferTimeList { get; set; }
	public Boolean isApprover { get; set; }
	public String approverComment { get; set; }
	public boolean isProjectEditAccess { get; set; }
	public boolean isEditTeam { get; set; }
	public static String RQ_PARTICIPANT_PROFILE = 'Personal / Participant profile(s): Required field missing.';
	public static String RQ_PROJECT_BRIEF_URL = 'Project Brief URL / UX Research Plan URL: Required field missing.';
	public static String UNMODERATED_SURVEY = 'Unmoderated - Survey';
	public static String OTHER_SURVEY = 'Other';
	public static String MODERATED_REMOTE_INTERVIEW = 'Moderated - Remote interview';
	public boolean blnApprovalCodeVisible { get; set; }
	public Date dtObj { get; set; }
	public UR_NewEditProjectCtrl(ApexPages.StandardController st) {
		try {
			Research_Configuration__c objConfig = UR_UtilityCtrl.RetriveResearchConfiguration();
			if (objConfig.Approval_Code_Applied_Date__c != null) {
				dtObj = objConfig.Approval_Code_Applied_Date__c;
			} else {
				dtObj = Date.newInstance(2022, 5, 1);
			}
			projectMaster = new Research_Project_Master__c();
			String projectId = apexPages.currentPage().getParameters().get('id');
			string sts = ApexPages.CurrentPage().getparameters().get('st');
			string strEditTeam = ApexPages.CurrentPage().getparameters().get('isEditTeam');
			if (string.isBlank(strEditTeam)) {
				isEditTeam = false;
			} else {
				isEditTeam = true;
			}

			if (string.isBlank(projectId)) {
				isEditable = true;
				isProjectEditAccess = true;
			} else {
				isEditable = UR_UtilityCtrl.IsEditAccess(projectId);
				isProjectEditAccess = UR_UtilityCtrl.IsProjectEditAccess(projectId);
			}
			checkApprover();
			approverComment = '';
			userId = new Set<Id>();
			rowIndex = 0;
			deleteRowIndex = 0;
			existingUserId = new Set<Id>();
			//Populate Buffer time list
			selBufferTimeList = new List<selectOption>();
			selBufferTimeList.add(new selectOption('', 'Please select'));
			selBufferTimeList.addAll(UR_UtilityCtrl.getPickValues(new Research_Project_Master__c(), 'Time_for_Post_interview_discussion__c'));

			projectTeamMap = new Map<Integer, Research_Project_Teams__c>();
			isOwnerPartOfTeam = false;
			deleteList = new List<Research_Project_Teams__c>();
			isOwnerChanged = false;
			projectTeamObj = new Research_Project_Teams__c();
			if (String.isNotBlank(projectId)) {
				isNewRecord = false;
				projectMaster.id = projectId;
				fetchResearchProjectDetails();

				if (projectMaster.CreatedDate >= dtObj || String.isNotBlank(projectMaster.Project_Approval_Code__c)) {
					blnApprovalCodeVisible = true;
				} else {
					blnApprovalCodeVisible = false;
				}
			} else {
				isNewRecord = true;
				blnApprovalCodeVisible = true;
			}
			//Check record has edit access or not
			/*if(sts==null && isEditable==false){
                string error='You do not have edit access to this project.';
                if(UR_UtilityCtrl.isProjectWriteAccess==true && projectMaster.Project_Status__c=='Complete'){
                    error='Project is marked as completed. To make changes or contact participants, re-open project.';
                }
                if(isApprover==true && projectMaster.Additional_Participant_Status__c=='In progress'){
                    // Do not show any messsage.
                }else{
                	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,error));
                }
            }*/
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
		}
	}

	// Once project is marked as completed then this method shows success message.
	public PageReference CompleteProjectMsg() {
		string st = ApexPages.CurrentPage().getparameters().get('st');
		if (string.isNotBlank(st)) {
			if (st == 'ct') {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Your project is now marked as complete. Congrats!'));
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Your project is now open again.'));
			}
			return null;
		}
		return null;
	}

	// This method fetch saved, UXR Scout record information.
	public void fetchResearchProjectDetails() {
		List<Research_Project_Master__c> list_ProjectMasters = [
			SELECT
				Id,
				NDA_URL__c,
				Calendly_EventId__c,
				Name,
				OwnerId,
				Additional_Participant_Status__c,
				Project_End_Date__c,
				Project_Start_Date__c,
				Primary_calendly_URL__c,
				Description__c,
				Number_of_Participants_to_Add_to_Project__c,
				Incentive_Amount__c,
				Number_of_Expected_Participant__c,
				Customer_Types__c,
				Plan_to_offer_incentives__c,
				Product_Area__c,
				Project_Brief_URL__c,
				Project_Id__c,
				Project_Leads__c,
				Project_Status__c,
				Survey_Id__c,
				Researcher_Name__c,
				Screener_URL__c,
				Time_for_Post_interview_discussion__c,
				Total_Participants_In_Research__c,
				Total_Project_Incentive__c,
				Type_of_people_are_you_hoping_to_contact__c,
				Type_of_Research__c,
				UX_Research_Plan_URL__c,
				Zoom_link_for_participant_interviews__c,
				Zoom_link_for_post_interview_discussions__c,
				LastModifiedDate,
				LastModifiedBy.Name,
				How_long_will_your_interviews_be__c,
				Number_of_Allowed_Participant__c,
				Approver_Comment__c,
				Describe_Incentive_Type__c,
				Segment__c,
				Project_Approval_Code__c,
				CreatedDate
			FROM Research_Project_Master__c
			WHERE Id = :projectMaster.id
			LIMIT 1
		];

		if (list_ProjectMasters.size() > 0) {
			projectMaster = list_ProjectMasters[0];
			fetchExistingMember();
			if (isEditTeam) {
				addTeamMember();
			}
		}
	}

	// This method redirect us to edit project details page.
	public PageReference editProject() {
		PageReference pageRef = new PageReference('/apex/UR_NewEditProject?id=' + projectMaster.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	// This method redirect us to edit project team member page.
	public PageReference editProjectTeam() {
		//PageReference pageRef = new PageReference('/apex/UR_ProjectTeam?id='+projectMaster.Id+'&isEditTeam=Y');
		PageReference pageRef = new PageReference('/apex/UR_NewEditProject?id=' + projectMaster.Id + '&isEditTeam=Y');
		pageRef.setRedirect(true);
		return pageRef;
	}

	// This method redirect us to add Participant page.
	public PageReference addParticipants() {
		PageReference pageRef = null;
		Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(projectMaster.Id);
		if (isParticipantExist) {
			pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + projectMaster.Id);
		} else {
			pageRef = new PageReference('/apex/UR_AddParticipants?projectId=' + projectMaster.Id);
		}
		pageRef.setRedirect(true);
		return pageRef;
	}

	// Once new UXR Scout record is created then click on next button this method redirect us to add Team member page.
	public PageReference nextFromProject() {
		PageReference pageRef = null;
		if (checkRequiredField()) {
			return pageRef;
		}

		if (projectMaster.Id != null) {
			pageRef = new PageReference('/apex/UR_ProjectTeam?id=' + projectMaster.Id);
		} else {
			pageRef = new PageReference('/apex/UR_ProjectTeam');
		}
		pageRef.setRedirect(false);
		return pageRef;
	}

	// This method redirect us to edit project details page.
	public PageReference backToProject() {
		PageReference pageRef = null;
		if (projectMaster.Id != null) {
			pageRef = new PageReference('/apex/UR_NewEditProject?id=' + projectMaster.Id);
		} else {
			pageRef = new PageReference('/apex/UR_NewEditProject');
		}
		return pageRef;
	}

	// This method redirect us to UXR Scout record details page.
	public PageReference cancelProject() {
		PageReference pageRef = null;
		if (projectMaster.Id != null) {
			pageRef = new PageReference('/apex/UR_ProjectDetail?id=' + projectMaster.Id);
		}
		pageRef.setRedirect(true);
		return pageRef;
	}

	// We are calling this method, when we update Project Master record.
	public PageReference saveProjectMaster() {
		PageReference pageRef = null;
		if (checkRequiredField()) {
			return pageRef;
		}
		// try{
		if (projectMaster.id == null) {
			projectMaster.Project_Status__c = 'Initiated';
		}

		/*
			 if(projectMaster.Type_of_Research__c!=null && projectMaster.Type_of_Research__c=='Survey_only'){
				projectMaster.Primary_calendly_URL__c = '';
				projectMaster.Calendly_EventId__c = '';
				projectMaster.Zoom_link_for_participant_interviews__c = '';
				projectMaster.Zoom_link_for_post_interview_discussions__c = '';
				projectMaster.Time_for_Post_interview_discussion__c = '';
			}
			*/
		string surveyURL = projectMaster.Screener_URL__c;
		if (String.isNotBlank(surveyURL) && surveyURL.indexOf('sID') < 0) {
			surveyURL = surveyURL + '?sID=';
		}
		projectMaster.Screener_URL__c = surveyURL;

		upsert projectMaster;

		pageRef = new PageReference('/apex/UR_ProjectDetail?id=' + projectMaster.Id);
		/*}catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,ex.getMessage()));
            return null;
        }*/
		return pageRef;
	}

	// We are calling this method, when New Project record would be created.
	public PageReference saveProject() {
		PageReference pageRef = null;
		if (validateTeamMember()) {
			return pageRef;
		}
		try {
			pageRef = saveProjectMaster();
			if (pageRef == null) {
				return pageRef;
			}
			pageRef = saveTeamMember();
			if (pageRef != null) {
				pageRef.setRedirect(true);
			}
		} catch (Exception ex) {
			pageRef = null;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
		}
		return pageRef;
	}

	// This method fetch existing team member related to UXR Scout project.
	public void fetchExistingMember() {
		if (projectMaster != null && projectMaster.id != null) {
			for (Research_Project_Teams__c obj : [
				SELECT id, Research_Project_Master__c, Project_Creator__c, Invite_for_Interviews__c, Edit_Access__c, Project_Role__c, User__c, LastModifiedDate, LastModifiedBy.Name
				FROM Research_Project_Teams__c
				WHERE Research_Project_Master__c = :projectMaster.Id
			]) {
				if (rowIndex == 0) {
					projectTeamObj = obj;
				}
				rowIndex = rowIndex + 1;
				projectTeamMap.put(rowIndex, obj);
				if (projectMaster.OwnerId != obj.User__c) {
					existingUserId.add(obj.User__c);
				} else {
					isOwnerPartOfTeam = true;
				}
			}
		}
	}

	// This method remove team member from UXR Scout project.
	public void deleteTeamMember() {
		try {
			if (projectTeamMap.containsKey(deleteRowIndex)) {
				Research_Project_Teams__c obj = projectTeamMap.get(deleteRowIndex);
				Boolean isFoundNewOwner = false;
				Id newOwnerId = null;
				if (obj.id != null) {
					deleteList.add(obj);
					if (projectMaster.OwnerId == obj.User__c) {
						isOwnerChanged = true;
					}
				}
				projectTeamMap.remove(deleteRowIndex);
			}
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex + ''));
		}
	}

	// This method add team member in UXR Scout prject.
	public void addTeamMember() {
		Research_Project_Teams__c obj = new Research_Project_Teams__c();
		if (projectMaster.Id != null) {
			obj.Research_Project_Master__c = projectMaster.Id;
		}
		rowIndex = rowIndex + 1;
		projectTeamMap.put(rowIndex, obj);
	}

	// This method validate team members permissions.
	public boolean validateTeamMember() {
		boolean flag = false;
		if (isNewRecord == false && projectTeamMap.values().size() == 0) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Add at least one project team member.'));
			flag = true;
		} else if (isNewRecord == false && projectTeamMap.values().size() > 0) {
			Research_Project_Teams__c obj1 = new Research_Project_Teams__c();
			Boolean isEditAccess = false;
			Boolean isInviteAccess = false;

			if (UR_NewEditProjectCtrl.UNMODERATED_SURVEY == projectMaster.Type_of_Research__c) {
				isInviteAccess = true;
			}
			for (Integer rowIndex : projectTeamMap.keySet()) {
				obj1 = projectTeamMap.get(rowIndex);
				if (obj1.User__c != null) {
					if (obj1.Edit_Access__c == true) {
						isEditAccess = true;
					}
					if (obj1.Invite_for_Interviews__c == true) {
						isInviteAccess = true;
					}
				}
			}

			if (isEditAccess == false) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'At least one team member can edit this project & contact customers on behalf of this project.'));
				flag = true;
			}
			if (isInviteAccess == false) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'At least one team member should be invited to any customer interviews scheduled.'));
				flag = true;
			}
		}
		return flag;
	}

	// We are calling this method, when we updated any exiting Team.
	public PageReference saveTeamMember() {
		PageReference pageRef = null;
		if (validateTeamMember()) {
			return pageRef;
		}

		userId.clear();
		if (projectMaster.Id != null) {
			Id newOwnerId = null;

			pageRef = new PageReference('/apex/UR_ProjectDetail?id=' + projectMaster.Id);
			List<Research_Project_Teams__c> lstUpdateTeam = new List<Research_Project_Teams__c>();
			Set<id> setNewUserid = new Set<Id>();
			if (projectTeamMap.values().size() > 0) {
				//Check at least one Team member have edit access.
				Research_Project_Teams__c obj1 = new Research_Project_Teams__c();
				Boolean isFoundNewOwner = false;

				for (Integer rowIndex : projectTeamMap.keySet()) {
					obj1 = projectTeamMap.get(rowIndex);
					if (obj1.User__c != null && projectMaster.OwnerId != obj1.User__c && obj1.Edit_Access__c == true && isFoundNewOwner == false) {
						isFoundNewOwner = true;
						newOwnerId = obj1.User__c;
					} else if (obj1.User__c != null && projectMaster.OwnerId == obj1.User__c && obj1.Edit_Access__c == false) {
						isOwnerChanged = true;
					}
				}

				if (isOwnerChanged == true) {
					projectMaster.OwnerId = newOwnerId;
					if (existingUserId.contains(newOwnerId)) {
						existingUserId.remove(newOwnerId);
					}
					update projectMaster;
				}

				// Create Project Team.
				for (Research_Project_Teams__c rpd : projectTeamMap.values()) {
					if (rpd.Research_Project_Master__c == null) {
						rpd.Research_Project_Master__c = projectMaster.Id;
					}
					if (rpd.User__c != null) {
						lstUpdateTeam.add(rpd);
						if (rpd.User__c != projectMaster.OwnerId) {
							userId.add(rpd.User__c);
						}
						//Send Email to All newly added user
						if (rpd.id == null || Test.isRunningTest() == true) {
							setNewUserid.add(rpd.User__c);
						}
					}
				}
			}

			//If record is newly created or Project Owner Not part of team.
			if (isNewRecord == true || isOwnerPartOfTeam == false && newOwnerId == null) {
				Research_Project_Teams__c recOwner = new Research_Project_Teams__c(
					Edit_Access__c = true,
					Invite_for_Interviews__c = true,
					User__c = userinfo.getUserId(),
					Research_Project_Master__c = projectMaster.Id,
					Project_Creator__c = true
				);
				lstUpdateTeam.add(recOwner);
			}

			if (lstUpdateTeam.size() > 0) {
				upsert lstUpdateTeam;
				if (setNewUserid != null && setNewUserid.size() > 0) {
					sendEmailToUser(setNewUserid, projectMaster.Id);
				}
			}

			if (deleteList.size() > 0) {
				delete deleteList;
			}

			shareResearchProjectMasterRecord();
		}
		return pageRef;
	}

	private void sendEmailToUser(set<Id> setUserid, string projectId) {
		UR_UtilityCtrl.skipTriggerLogic();
		ContactTriggerHelper.skipTrigger = true;
		//Need to create contact for every user to send email including what id and target object id
		//We can not user what id with user as target object id
		List<Contact> lstContact = new List<Contact>();
		set<string> setUserEmail = new Set<string>();
		for (User usr : [SELECT id, Email, FirstName, LastName, UserName FROM user WHERE Id IN :setUserid]) {
			setUserEmail.add(usr.Email);
		}
		if (setUserEmail != null && setUserEmail.size() > 0) {
			//Check if any contact related to this user or not
			map<string, Contact> mapEmailContact = new Map<string, Contact>();
			for (Contact ct : [SELECT id, Name, EMail FROM Contact WHERE email IN :setUserEmail]) {
				mapEmailContact.put(ct.EMail, ct);
			}
			for (User usr : [SELECT id, Email, FirstName, LastName, UserName FROM user WHERE Id IN :setUserid]) {
				//get Contact assovcited with email else create new
				Contact ct = mapEmailContact.get(usr.Email);
				if (ct == null) {
					ct = new Contact(AccountId = Label.UR_GustoAccountId, Email = usr.Email, FirstName = usr.FirstName, LastName = usr.LastName);
				}
				lstContact.add(ct);
			}
			if (lstContact != null && lstContact.size() > 0) {
				upsert lstContact;
				//Send Email
				List<EmailTemplate> emailTemplateList = [
					SELECT id, Name, Body, HTMLValue, Subject
					FROM EmailTemplate
					WHERE DeveloperName = 'UXR_Add_in_Project_Notification' AND Folder.DeveloperName = 'UX_Research'
				];

				List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
				for (Contact ct : lstContact) {
					Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
					msg.setWhatId(projectMaster.Id);
					msg.setTargetObjectId(ct.Id);
					msg.setTemplateId(emailTemplateList[0].Id);
					msg.setSaveAsActivity(false);
					if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
						msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
					}
					if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
						msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
					}
					mail.add(msg);
				}
				//Send email notification
				if (mail != null && mail.size() > 0) {
					if(OrganizationUtilities.canSendEmails()){
						Messaging.sendEmail(mail);
					}
				}
			}
		}
	}
	// This method will given UXR Scout project permission to the Team member.
	public void shareResearchProjectMasterRecord() {
		if (existingUserId.size() > 0) {
			delete [SELECT Id FROM Research_Project_Master__share WHERE ParentId = :projectMaster.Id AND UserOrGroupId IN :existingUserId];
		}

		List<Research_Project_Master__share> shareProjecttoTeamList = new List<Research_Project_Master__share>();
		if (projectTeamMap.values().size() > 0) {
			for (Research_Project_Teams__c rpd : projectTeamMap.values()) {
				if (rpd.User__c != null) {
					if (rpd.User__c != projectMaster.OwnerId) {
						Research_Project_Master__share objShare = new Research_Project_Master__share();
						objShare.ParentId = projectMaster.Id;
						objShare.UserOrGroupId = rpd.User__c;

						if (rpd.Edit_Access__c == true) {
							objShare.AccessLevel = 'edit';
						} else {
							objShare.AccessLevel = 'read';
						}
						shareProjecttoTeamList.add(objShare);
					}
				}
			}
		}

		if (shareProjecttoTeamList.size() > 0) {
			upsert shareProjecttoTeamList;
		}
		existingUserId.clear();
		existingUserId.addAll(userId);
	}

	// This method validate all the required field.
	public boolean checkRequiredField() {
		boolean flag = false;
		ApexPages.getMessages().clear();

		Boolean isValidURL = true;
		try {
			if (String.isNotBlank(projectMaster.Project_Brief_URL__c)) {
				URL checkURL = new URL(projectMaster.Project_Brief_URL__c);
			}
		} catch (Exception e) {
			isValidURL = false;
		}

		if (projectMaster.Name == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Project Name: Required field missing.'));
		} else if (projectMaster.Project_Start_Date__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Anticipated Study Start Date: Required field missing.'));
		} else if (projectMaster.Project_End_Date__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Anticipated Study End Date: Required field missing. '));
		} else if (projectMaster.Project_Start_Date__c != null && projectMaster.Project_End_Date__c != null && projectMaster.Project_Start_Date__c > projectMaster.Project_End_Date__c) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, '"Anticipated Study Start Date" should be less than or equals to "Anticipated Study End Date"'));
		} else if (projectMaster.Type_of_Research__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Type of Research: Required field missing. '));
		} else if (projectMaster.Description__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Project Goal: Required field missing.'));
		} else if (projectMaster.Number_of_Participants_to_Add_to_Project__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Desired # of Participants: Required field missing.'));
		} else if (projectMaster.Plan_to_offer_incentives__c == null) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Plan to offer incentives?: Required field missing.'));
		} else if (blnApprovalCodeVisible && String.isBlank(projectMaster.Project_Approval_Code__c)) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Project Approval Code: Required field missing.'));
		} else if (isValidURL == false) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Project Brief URL / UX Research Plan URL: Invalid URL.'));
		} else if (String.isBlank(projectMaster.Project_Brief_URL__c)) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, RQ_PROJECT_BRIEF_URL));
		} else if (String.isBlank(projectMaster.Customer_Types__c)) {
			flag = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, RQ_PARTICIPANT_PROFILE));
		}

		return flag;
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

	public void approveRequest() {
		projectMaster.Additional_Participant_Status__c = 'Approved';
		projectMaster.Approver_Comment__c = approverComment;
		update projectMaster;
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Request succesfully approved.'));
	}

	public void rejectRequest() {
		projectMaster.Additional_Participant_Status__c = 'Rejected';
		projectMaster.Approver_Comment__c = approverComment;
		update projectMaster;
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Request has been rejected.'));
	}
}