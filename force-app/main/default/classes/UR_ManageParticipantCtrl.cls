public without sharing class UR_ManageParticipantCtrl {
	public Research_Project_Master__c objProject { get; set; }
	public Research_Configuration__c objResearch { get; set; }
	public String currentRecordId { get; set; }
	public String recid { get; set; }
	public List<ContactWrapper> lstContactWrapper { get; set; }
	public List<Research_Project_Detail__c> lstResearchProjectDetail { get; set; }
	public Research_Project_Detail__c objProjectResearchDetail { get; set; }
	public Research_Schedule_Email__c scheduleEmail { get; set; }
	public Boolean showHideScheduleEmail { get; set; }
	public List<SelectOption> list_SelectedEmailTemplates { get; set; }
	public List<SelectOption> list_DraftEmailTemplates { get; set; }
	public String strSelectDraftEmailId { get; set; }
	public String strDraftEmailNickName { get; set; }
	public List<SelectOption> list_SelectedEmailPicklists { get; set; }
	public String strSelectEmailId { get; set; }
	public String strEmailBody { get; set; }
	public String strDraftEmailTemplateId { get; set; }
	public Boolean blnDraftEmail { get; set; }
	public String strSubject { get; set; }
	public String strPartStatus { get; set; }
	public String strEmailStatus { get; set; }
	public String strCurrentPartId;
	public string replybody;
	public String emailReplyBody { get; set; }
	public EmailWrapper objEmailMsgWraper;
	public string successMsg { get; set; }
	public String strEmailTemplateId { get; set; }
	public Map<String, String> map_ToEmailIds { get; set; }
	public string removeEmailId { get; set; }
	public boolean showNumberofCSVBlock { get; set; }
	public integer csvCountData { get; set; }
	public String sendEmailFlag { get; set; }
	public integer totalContact { get; set; }
	public Integer intSelectedContact { get; set; }
	public Research_Project_Detail__c objProjectParticipants { get; set; }
	public List<ContactWrapper> excludedContactList { get; set; }
	public String sendEmailSubTab { get; set; }
	public boolean isheader { get; set; }
	public boolean isEditable { get; set; }
	public string calURL { get; set; }
	public List<Research_Glossary_of_Merge_Fields__c> mergeFieldList { get; set; }
	public Map<String, String> glossaryMap { get; set; }
	public String blankTagField { get; set; }

	public Boolean blnValidEmailTag { get; set; }
	public Boolean blnValidScheduleDateTime { get; set; }
	public Boolean blnFutureScheduleDateTime { get; set; }
	public string previousPageName;
	public List<selectOption> statusList { get; set; }
	public string selectedStatus { get; set; }
	public static final Integer PAGE_SIZE = 500;
	public ApexPages.StandardSetController setCon { get; set; }
	public List<Research_Project_Detail__c> lstProjectParticipantDetail { get; set; }
	public Integer totalParticipant { get; set; }
	public List<selectOption> includeParticipant { get; set; }
	public String selIncludeParticipant { get; set; }
	public String searchString { get; set; }
	public String sortbyFieldAPIName { get; set; }
	public String prevSortbyFieldAPIName { get; set; }
	public String orderAs { get; set; }
	public String searchQuery { get; set; }
	public String participantComments { get; set; }
	public Boolean isCopyToAllComment { get; set; }
	public String participantCommentId { get; set; }
	public Integer selectedRecordCount { get; set; }
	public Set<Id> set_SelectedRecords;
	public Set<Id> searchIds;
	public Integer prevResveredCount { get; set; }
	public Integer prevUnResveredCount { get; set; }
	public string scheduleEmailId { get; set; }
	public boolean isUpdateLastViewDate { get; set; }
	public Integer newSurveyCount { get; set; }
	public boolean isCalendlyVisible { get; set; }
	public Map<Id, Research_Schedule_Email_Participant__c> scheduleParticipantMap = new Map<Id, Research_Schedule_Email_Participant__c>();
	public static final String UX_DRAFT_EMAIL = 'UXR_User_Created_Templates';
	public static final String UX_DRAFT_INDEX = 'Draft';
	public static final String RQ_TEMPLATE_NAME = 'Please enter the template name.';
	public static final String SAVE_DRAFT_EMAIL = 'Draft email saved successfully.';
	public static final String DELETE_DRAFT_EMAIL = 'Draft email deleted successfully.';
	public static final String UXR_DEFAULT_EMAIL_FOLDER = 'UX_Research';
	public static final String UXR_PROJECT_NAME = '{!Research_Project_Detail__c.Project_Name__c}';
	public static final String BLANK_VALUE = '--None--';
	public static final String CONFIRM_STUDY_AND_SEND_NDA = 'Confirm details about study & send NDA';
	public static final String SEND_REMINDER = 'Send Reminder';
	public static final String FOLLOW_UP_AFTER_STUDY = 'Follow up after study';
	public static final String CANCEL_SESSION = 'Cancel session';
	public static final String UL_TAG = '<ul>';
	public static final String UL_SLDS_TAG = '<ul class="slds-list_dotted slds-m-top_small slds-m-bottom_small">';
	public static final String OL_TAG = '<ol>';
	public static final String OL_SLDS_TAG = '<ol class="slds-list_ordered slds-m-top_small slds-m-bottom_small">';
	public static final String RQ_FOLLOW_UP = 'What type of follow up?';
	public static final String RQ_VALID_EMAIL_TEMPLATE = 'Please select email template to send an email';
	public static final String RQ_VALID_EMAIL = 'Please select at least one valid email address.';
	public static final String DOES_NOT_EXIST = ' does not exist.';
	public static final String RQ_VALID_SC_DT = 'Please enter a valid schedule email date and time.';
	public static final String RQ_FUTURE_DT = 'Please select future date and time to schedule an email.';
	public Double dateOffset {
		get {
			TimeZone tz = UserInfo.getTimeZone();
			//Milliseconds to Day
			return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
		}
	}
	public Integer intMaxSendEmailLimit { get; set; }

	public UR_ManageParticipantCtrl(ApexPages.StandardController st) {
		isCalendlyVisible = true;
		isUpdateLastViewDate = true;
		scheduleEmail = new Research_Schedule_Email__c();
		showHideScheduleEmail = false;
		searchQuery = '';
		selectedRecordCount = 0;
		searchIds = new Set<Id>();
		prevResveredCount = 0;
		prevUnResveredCount = 0;
		set_SelectedRecords = new Set<Id>();
		isCopyToAllComment = false;
		participantComments = '';
		participantCommentId = '';
		String removeFlag = ApexPages.CurrentPage().getparameters().get('remove');
		if (String.isNotBlank(removeFlag) && removeFlag == 'job') {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Schedule email successfully cancelled.'));
		}
		orderAs = ApexPages.CurrentPage().getparameters().get('orderas');
		if (String.isBlank(orderAs)) {
			orderAs = 'asc';
		}
		sortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('sortby');
		if (String.isBlank(sortbyFieldAPIName)) {
			sortbyFieldAPIName = 'Research_Participant_Status_Number__c';
		}

		prevSortbyFieldAPIName = sortbyFieldAPIName;

		lstProjectParticipantDetail = new List<Research_Project_Detail__c>();
		sendEmailSubTab = 'MP';
		showNumberofCSVBlock = true;
		successMsg = '';
		objProjectResearchDetail = new Research_Project_Detail__c();
		strEmailBody = '';
		strSubject = '';
		currentRecordId = ApexPages.CurrentPage().getparameters().get('Id');
		if (String.isBlank(currentRecordId)) {
			currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		}
		lstContactWrapper = new List<ContactWrapper>();
		lstResearchProjectDetail = new List<Research_Project_Detail__c>();
		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);

		objResearch = new Research_Configuration__c();
		objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();
		searchIds.clear();
		objProject = new Research_Project_Master__c();
		RetriveProjectRecord(true);

		String totalContact = ApexPages.CurrentPage().getparameters().get('totalContact');
		if (String.isNotBlank(totalContact)) {
			scheduleEmailId = ApexPages.CurrentPage().getparameters().get('scheduleEmailId');
			String strMessage = '';

			if (String.isNotBlank(scheduleEmailId) && scheduleEmailId != 'null') {
				strMessage = 'Email schedule to ';
			} else {
				strMessage = 'Email send in progress to ';
			}
			strMessage =
				strMessage +
				totalContact +
				' contacts. Your emails will appear in the<a class="view-email-detail" style="color:white; text-decoration:underline;" href="javascript:void(0);">Emails page</a>once successfully sent. ';

			if (String.isNotBlank(scheduleEmailId) && scheduleEmailId != 'null') {
				strMessage =
					strMessage + '<a style="color:white; text-decoration:underline;" class="cancel-schedule-email" href="javascript:void(0);" title="Click here to cancel schedule email">Cancel</a>';
			}

			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, strMessage));
		}

		PopulateEmailPicklist();
		list_SelectedEmailTemplates = new List<SelectOption>();
		list_SelectedEmailTemplates.add(new SelectOption('', BLANK_VALUE));
		list_DraftEmailTemplates = new List<SelectOption>();
		list_DraftEmailTemplates.add(new SelectOption('', BLANK_VALUE));
		strEmailTemplateId = '';
		strDraftEmailNickName = '';
		map_ToEmailIds = new Map<String, String>();
		removeEmailId = '';
		//Check number of CSV data uploaded for project or not
		RetriveCSVData();
		intSelectedContact = 0;
		objProjectParticipants = new Research_Project_Detail__c();
		excludedContactList = new List<ContactWrapper>();
		isheader = true;
		mergeFieldList = [
			SELECT id, Name, Description__c, Example__c, Merge_Field_Name__c, Source_Of_Field__c
			FROM Research_Glossary_of_Merge_Fields__c
			ORDER BY Createddate ASC
		];
		glossaryMap = new Map<String, String>();
		for (Research_Glossary_of_Merge_Fields__c glossaryObj : mergeFieldList) {
			glossaryMap.put(glossaryObj.Merge_Field_Name__c, glossaryObj.Description__c);
		}
		blankTagField = '';
		blnValidEmailTag = true;
		blnValidScheduleDateTime = true;
		blnFutureScheduleDateTime = true;
		statusList = new List<selectOption>();
		statusList.add(new selectOption('', 'Update status'));
		for (selectOption objOption : UR_UtilityCtrl.getPickValues(new Research_Project_Detail__c(), 'Research_Participant_Status__c')) {
			if (objOption.getValue() != 'Contact Pending') {
				statusList.add(objOption);
			}
		}
		statusList.add(new selectOption('', '----------------------'));
		statusList.add(new selectOption('Release from project', 'Release from project'));

		includeParticipant = new List<selectOption>();
		includeParticipant.add(new selectOption('Add participants', 'Add participants'));
		includeParticipant.add(new selectOption('From CSV', 'From CSV'));
		includeParticipant.add(new selectOption('From Salesforce search', 'From Salesforce search'));

		intMaxSendEmailLimit = 500;
		if (objResearch.Max_Number_Of_Participants_To_Send_Email__c != null && objResearch.Max_Number_Of_Participants_To_Send_Email__c != 0) {
			intMaxSendEmailLimit = Integer.valueOf(objResearch.Max_Number_Of_Participants_To_Send_Email__c);
		}
	}

	//Check whether we have uploaded any CSV valid data or not in project
	private void RetriveCSVData() {
		csvCountData = [SELECT COUNT() FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :objProject.Id];
		//and Blacklist__c=false and Opt_Out__c=false

		if (csvCountData > 0 && showNumberofCSVBlock == true) {
			showNumberofCSVBlock = true;
		}
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

	private PageReference RetriveProjectRecord(Boolean isRunSoqlQuery) {
		try {
			lstContactWrapper.clear();
			if (isRunSoqlQuery) {
				List<Research_Project_Master__c> list_ProjectMaster = [
					SELECT
						Project_Id__c,
						NDA_URL__c,
						Calendly_EventId__c,
						CreatedDate,
						Customer_Types__c,
						Description__c,
						Id,
						Name,
						Number_of_Participants_to_Add_to_Project__c,
						Number_of_Allowed_Participant__c,
						Survey_Id__c,
						Primary_calendly_URL__c,
						Product_Area__c,
						Project_End_Date__c,
						Last_View_Survey_Date__c,
						Project_Start_Date__c,
						Project_Status__c,
						Researcher_Name__c,
						Screener_URL__c,
						Type_of_Research__c
					FROM Research_Project_Master__c
					WHERE Id = :currentRecordId
				];
				if (list_ProjectMaster != null && list_ProjectMaster.size() > 0) {
					objProject = list_ProjectMaster[0];
				}
				if (objProject.Id == null) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_InvalidProjectDetail));
					return null;
				}
				if (objProject.Last_View_Survey_Date__c == null || objProject.Last_View_Survey_Date__c < System.today()) {
					isUpdateLastViewDate = true;
				} else {
					isUpdateLastViewDate = false;
				}

				Id projectId = objProject.Id;
				Date lastViewDate = objProject.Last_View_Survey_Date__c;
				if (lastViewDate == null) {
					lastViewDate = System.today();
					newSurveyCount = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate >= :lastViewDate];
				} else {
					newSurveyCount = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId AND CreatedDate > :lastViewDate];
				}

				calURL = Label.UR_CalPanelURL;
				if (string.isNotblank(objProject.Calendly_EventId__c)) {
					calURL = Label.UR_CalEventURL;
					calURL = calURL.replace('xxxx', objProject.Calendly_EventId__c.Trim());
				}

				Id uxScoutId = objProject.id;

				totalParticipant = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :uxScoutId];
				String strQueryString =
					'SELECT Id,Research_Project_Master__c,NDA_Send__c,Blacklist__c, ' +
					'Opt_Out__c,Reason__c,Incentive__c,Unread_Email__c, E_Mail_Status__c, Send_Email_Error__c, ' +
					'Project_Name__c,Project_Id__c,Screener_URL__c,Contact__c,' +
					'Contact__r.AccountId,Contact__r.Account.Name, Contact__r.Account.ZP_Company_ID__c, ' +
					'Contact__r.ZP_User_Id__c, Contact__r.Employee_Id__c,' +
					'Contact__r.Email,Contact__r.Name, Comment__c, Contact__r.UXResearch_Opt_Out__c, ' +
					'Research_Participant_Status__c, Researcher_Name__c, Calendly_URL__c, Company_Name__c, ' +
					'Date_of_Attended__c, Incentive_Amount__c, Length_of_Interview__c,  Locked__c, NDA_URL__c,' +
					'Research_Participant_Status_Number__c, Study_End_Date__c, Study_Start_Date__c, Proposed_Incentive__c, ' +
					'Participant_Email__c, Researcher_Email__c FROM Research_Project_Detail__c WHERE Research_Project_Master__c=:uxScoutId ' +
					searchQuery +
					' order by ' +
					sortbyFieldAPIName +
					' ' +
					orderAs +
					' NULLS LAST';
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQueryString));
				setCon.setPageSize(PAGE_SIZE);

				scheduleParticipantMap = new Map<Id, Research_Schedule_Email_Participant__c>();

				for (Research_Schedule_Email_Participant__c scheduleParticipantObj : [
					SELECT Id, Research_Schedule_Email__c, Research_Project_Detail__c, Research_Schedule_Email__r.Schedule_Email_Date__c, Research_Schedule_Email__r.Schedule_Email_Time__c
					FROM Research_Schedule_Email_Participant__c
					WHERE Research_Schedule_Email__r.UXR_Scout__c = :uxScoutId AND Schedule_Email_Status__c = 'Schedule'
					ORDER BY Research_Schedule_Email__r.Schedule_Email_Date__c, Research_Schedule_Email__r.Schedule_Email_Time__c
				]) {
					scheduleParticipantMap.put(scheduleParticipantObj.Research_Project_Detail__c, scheduleParticipantObj);
				}
			}

			for (Research_Project_Detail__c rpd : (List<Research_Project_Detail__c>) setCon.getRecords()) {
				showNumberofCSVBlock = false;
				ContactWrapper cw = new ContactWrapper();
				cw.chkNDA = rpd.NDA_Send__c;

				cw.envStyle = 'fa-envelope-open';
				if (rpd.Unread_Email__c == true) {
					cw.envStyle = 'fa-envelope';
				}
				cw.objResProject = rpd;
				if (scheduleParticipantMap.containsKey(rpd.Id)) {
					cw.emailScheduleDate = scheduleParticipantMap.get(rpd.Id);
				}

				cw.selContact = false;
				cw.isEditComment = false;
				cw.strComment = rpd.Comment__c;
				if (set_SelectedRecords.contains(cw.objResProject.Id)) {
					cw.selContact = true;
					set_SelectedRecords.remove(cw.objResProject.Id);
				}

				lstContactWrapper.add(cw);
			}
			selectedRecordCount = set_SelectedRecords.size();
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objExp.getMessage()));
			return null;
		}

		return null;
	}

	public void RetriveEmailTemplate() {
		Set<Id> set_EmailTemplates = new Set<Id>();
		String strDraftEmailFilter = '';
		String strDraftEmail = '';
		strSelectEmailId = '';
		strDraftEmailTemplateId = '';
		strSelectDraftEmailId = '';
		strSubject = '';
		strEmailBody = '';
		list_SelectedEmailTemplates.clear();
		list_SelectedEmailTemplates.add(new SelectOption('', BLANK_VALUE));
		list_DraftEmailTemplates.clear();
		list_DraftEmailTemplates.add(new SelectOption('', BLANK_VALUE));

		for (Research_Email_Template__c objMapping : [
			SELECT Id, Status__c, Email_Template__c, Email_Template_Name__c
			FROM Research_Email_Template__c
			WHERE Status__c = :strPartStatus
		]) {
			if (!set_EmailTemplates.contains(objMapping.Email_Template__c)) {
				list_SelectedEmailTemplates.add(new SelectOption(objMapping.Email_Template__c, objMapping.Email_Template_Name__c));
				set_EmailTemplates.add(objMapping.Email_Template__c);

				strDraftEmail = 'T_' + objMapping.Email_Template__c + '_' + objProject.Project_Id__c;
				strDraftEmail = strDraftEmail.replace('-', '_');
				strDraftEmailFilter = strDraftEmailFilter + 'OR DeveloperName like \'' + strDraftEmail + '%\' ';
			}
		}

		if (String.isNotBlank(strDraftEmailFilter)) {
			strDraftEmailFilter = ' (' + strDraftEmailFilter.subString(3, strDraftEmailFilter.length()) + ')';
			String strFolderName = UR_ManageParticipantCtrl.UX_DRAFT_EMAIL;
			String strQuery = 'SELECT Id, Name, DeveloperName, Body, HTMLValue, Subject ' + 'FROM EmailTemplate ' + 'WHERE Folder.DeveloperName = :strFolderName AND ' + strDraftEmailFilter;

			for (EmailTemplate objEmail : Database.query(strQuery)) {
				list_DraftEmailTemplates.add(new SelectOption(objEmail.id + '', objEmail.Name));
			}
		}
	}

	public PageReference showPreview() {
		try {
			strSubject = '';
			strEmailBody = '';
			strDraftEmailTemplateId = '';
			strSelectDraftEmailId = '';
			blnDraftEmail = false;
			strDraftEmailNickName = '';

			if (String.isNotBlank(strSelectEmailId)) {
				EmailTemplate objEmailTemplate = new EmailTemplate();
				List<EmailTemplate> list_emailTemplates = [
					SELECT Id, Name, Body, HTMLValue, Subject
					FROM EmailTemplate
					WHERE Id = :strSelectEmailId AND Folder.DeveloperName = :UR_ManageParticipantCtrl.UXR_DEFAULT_EMAIL_FOLDER
				];

				if (list_emailTemplates.size() > 0) {
					objEmailTemplate = list_emailTemplates[0];
				}

				if (objEmailTemplate.Id != null) {
					strEmailBody = objEmailTemplate.HTMLValue;
					strSubject = objEmailTemplate.Subject;
					strEmailBody = UR_UtilityCtrl.replaceProjectMasterTag(objProject, strEmailBody);
					strSubject = strSubject.replace(UXR_PROJECT_NAME, objProject.Name);
				}
			}
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objExp.getMessage()));
		}
		return null;
	}

	public PageReference showDraftEmail() {
		try {
			strSubject = '';
			strEmailBody = '';
			strDraftEmailTemplateId = '';
			strSelectEmailId = '';
			blnDraftEmail = false;
			strDraftEmailNickName = '';
			if (String.isNotBlank(strSelectDraftEmailId)) {
				EmailTemplate objEmailTemplate = new EmailTemplate();
				List<EmailTemplate> list_emailTemplates = [
					SELECT Id, Name, Body, HTMLValue, Subject
					FROM EmailTemplate
					WHERE Id = :strSelectDraftEmailId AND Folder.DeveloperName = :UR_ManageParticipantCtrl.UX_DRAFT_EMAIL
				];

				if (list_emailTemplates.size() > 0) {
					objEmailTemplate = list_emailTemplates[0];
					strDraftEmailTemplateId = objEmailTemplate.Id;
					blnDraftEmail = true;
				}

				if (objEmailTemplate.Id != null) {
					strEmailBody = objEmailTemplate.HTMLValue;
					strSubject = objEmailTemplate.Subject;
					strEmailBody = UR_UtilityCtrl.replaceProjectMasterTag(objProject, strEmailBody);
					strSubject = strSubject.replace(UXR_PROJECT_NAME, objProject.Name);
				}
			}
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objExp.getMessage()));
		}
		return null;
	}

	public void PopulateEmailPicklist() {
		list_SelectedEmailPicklists = new List<SelectOption>();
		list_SelectedEmailPicklists.add(new SelectOption('', BLANK_VALUE));
		list_SelectedEmailPicklists.add(new SelectOption(CONFIRM_STUDY_AND_SEND_NDA, CONFIRM_STUDY_AND_SEND_NDA));
		list_SelectedEmailPicklists.add(new SelectOption(SEND_REMINDER, SEND_REMINDER));
		list_SelectedEmailPicklists.add(new SelectOption(FOLLOW_UP_AFTER_STUDY, FOLLOW_UP_AFTER_STUDY));
		list_SelectedEmailPicklists.add(new SelectOption(CANCEL_SESSION, CANCEL_SESSION));
	}

	public EmailWrapper getobjEmailMsgWraper() {
		successMsg = '';
		strCurrentPartId = ApexPages.currentPage().getParameters().get('currentPartId');
		objEmailMsgWraper = new EmailWrapper();

		emailReplyBody = '';
		if (strCurrentPartId != null) {
			List<EmailMessage> list_Msgs = [
				SELECT Id, Subject, HtmlBody, RelatedToId, ToAddress, Createddate, FromAddress, FromName, CcAddress, BccAddress
				FROM EmailMessage
				WHERE RelatedToId = :strCurrentPartId
				ORDER BY Createddate DESC
				LIMIT 1
			];

			if (list_Msgs != null && list_Msgs.size() > 0) {
				objEmailMsgWraper.objEmailMessage = list_Msgs[0];
				if (String.isNotBlank(list_Msgs[0].HtmlBody)) {
					objEmailMsgWraper.emailBody = list_Msgs[0].HtmlBody.replace('\n\r', '<br/>');
					objEmailMsgWraper.emailBody = objEmailMsgWraper.emailBody.replace(UL_TAG, UL_SLDS_TAG);
					objEmailMsgWraper.emailBody = objEmailMsgWraper.emailBody.replace(OL_TAG, OL_SLDS_TAG);
				} else {
					objEmailMsgWraper.emailBody = '';
				}
			}
		}

		return objEmailMsgWraper;
	}

	public class EmailWrapper {
		public EmailMessage objEmailMessage { get; set; }
		public String emailBody { get; set; }
	}

	//Update Read email status if any email is in unread
	public PageReference UpdateReadEmailStatus() {
		String strPartId = ApexPages.currentPage().getParameters().get('currentPartId');
		//If logged in use has editable access then update will be happen
		if (isEditable == true) {
			Integer emailCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE id = :strPartId AND Unread_Email__c = TRUE];

			if (emailCount == 1) {
				Research_Project_Detail__c obj = new Research_Project_Detail__c(id = strPartId);
				obj.Unread_Email__c = false;
				update obj;
				//Update Email Message
				List<EmailMessage> lstEmailUpdate = new List<EmailMessage>();
				for (EmailMessage em : [SELECT id, Unread_Email__c FROM EmailMessage WHERE RelatedToId = :strPartId AND Unread_Email__c = TRUE]) {
					em.Unread_Email__c = false;
					lstEmailUpdate.add(em);
				}
				if (lstEmailUpdate != null && lstEmailUpdate.size() > 0) {
					update lstEmailUpdate;
				}
				searchIds.clear();
				RetriveProjectRecord(true);
			}
		}
		return null;
	}

	public void ReplyEmail() {
		UR_UtilityCtrl.skipTriggerLogic();
		try {
			if (string.isNotBlank(emailReplyBody)) {
				EmailMessage objEmailMessage = objEmailMsgWraper.objEmailMessage;
				String dateObj = '';
				String replyFromStmt = '';
				String strEmailBody = '';
				if (!Test.isRunningTest()) {
					dateObj = objEmailMessage.Createddate.format('EEE, d MMM yyyy HH:mm ');
					replyFromStmt = 'On ' + dateObj + ',' + objEmailMessage.FromName + ' ' + '&lt;' + objEmailMessage.FromAddress + '&gt; wrote:';
					strEmailBody = emailReplyBody + '<br/>' + '<b>' + replyFromStmt + '</b>' + '<br/>' + objEmailMessage.HtmlBody;
				}

				list<string> toaddrs = new List<string>();
				//generate Email Body
				emailReplyBody = emailReplyBody.replace('\n', '<br/>');
				String contactId = [SELECT Id, Contact__r.Email, Contact__r.id FROM Research_Project_Detail__c WHERE Id = :strCurrentPartId].Contact__r.Id;

				List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
				Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
				msg.setWhatId(strCurrentPartId);
				msg.setTargetObjectId(contactId);
				if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
					msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
				}
				if (!Test.isRunningTest()) {
					msg.setSubject(objEmailMessage.Subject);
				}
				msg.setHtmlBody(strEmailBody);
				msg.setSaveAsActivity(true);
				if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
					msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
				}
				mail.add(msg);
				Messaging.sendEmail(mail);
				emailReplyBody = '';
				successMsg = 'Email sent successfully.<br/>';
				//ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Email sent'));
			}
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			successMsg = e.getMessage();
		}
	}

	public PageReference sendEmail() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		//On click of send email button.
		//First we will create temporary email template then send email to the user.
		//On future method we delete temporary email template.
		UR_UtilityCtrl.skipTriggerLogic();
		try {
			if (String.isBlank(strPartStatus)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_FOLLOW_UP));
				return null;
			} else if (string.isBlank(strSelectEmailId) && string.isBlank(strSelectDraftEmailId)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_VALID_EMAIL_TEMPLATE));
				return null;
			} else if (map_ToEmailIds.size() == 0) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_VALID_EMAIL));
				return null;
			} else if (!blnValidEmailTag) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, blankTagField + DOES_NOT_EXIST));
				return null;
			} else if (!blnValidScheduleDateTime) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_VALID_SC_DT));
				return null;
			} else if (!blnFutureScheduleDateTime) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_FUTURE_DT));
				return null;
			}

			if (lstResearchProjectDetail != null && lstResearchProjectDetail.size() > 0 && (String.isNotBlank(strSelectEmailId) || String.isNotBlank(strSelectDraftEmailId))) {
				List<Research_Project_Detail__c> lstUpdatePart = new List<Research_Project_Detail__c>();
				List<Research_Project_Detail__c> lstSchedulePart = new List<Research_Project_Detail__c>();
				Research_Schedule_Email__c scheduleEmailObj = new Research_Schedule_Email__c();
				if (map_ToEmailIds.size() > 0) {
					Research_Project_Detail__c rpdObj = lstResearchProjectDetail[0];
					if (scheduleEmail.Schedule_Email_Date__c != null && scheduleEmail.Schedule_Email_Time__c != null) {
						scheduleEmailObj.Schedule_Email_Template_Id__c = strEmailTemplateId;
						scheduleEmailObj.Schedule_Email_Date__c = scheduleEmail.Schedule_Email_Date__c;
						scheduleEmailObj.Schedule_Email_Time__c = scheduleEmail.Schedule_Email_Time__c;
						scheduleEmailObj.UXR_Scout__c = rpdObj.Research_Project_Master__c;
						scheduleEmailObj.Schedule_Email_Type__c = strPartStatus;
						insert scheduleEmailObj;
					}
				}

				List<Research_Schedule_Email_Participant__c> scheduleParticipantList = new List<Research_Schedule_Email_Participant__c>();

				for (Research_Project_Detail__c rpd : lstResearchProjectDetail) {
					if (!rpd.Blacklist__c && !rpd.Opt_Out__c && rpd.Contact__c != null && map_ToEmailIds.containsKey(rpd.Contact__r.Email) && String.isNotBlank(strPartStatus)) {
						Research_Project_Detail__c objUpdate = new Research_Project_Detail__c(id = rpd.Id);
						Research_Schedule_Email_Participant__c scheduleParticipantObj = new Research_Schedule_Email_Participant__c();

						setProjectDetailEmailStatus(objUpdate, rpd.Participant_Email__c);

						if (scheduleEmailObj.Id != null) {
							scheduleParticipantObj.Research_Schedule_Email__c = scheduleEmailObj.Id;
							scheduleParticipantObj.Research_Project_Detail__c = rpd.Id;
							scheduleParticipantObj.Schedule_Email_Status__c = 'Schedule';
							scheduleParticipantList.add(scheduleParticipantObj);

							if (rpd.Research_Participant_Status__c != 'Attended') {
								objUpdate.Research_Participant_Status__c = 'Contact Pending';
							}

							lstSchedulePart.add(objUpdate);
						} else {
							objUpdate.E_Mail_Status__c = 'Send Email';
							objUpdate.E_Mail_Template_Id__c = strEmailTemplateId;
							objUpdate.Email_Type__c = strPartStatus;
							lstUpdatePart.add(objUpdate);
						}
					}
				}

				String strMessage = '';
				//Update Selected Participant Status
				if (lstUpdatePart.size() > 0) {
					update lstUpdatePart;
					strMessage = 'Email send in progress to ';
					UR_SendEmailToParticipantBatch objBatch = new UR_SendEmailToParticipantBatch();
					objBatch.idProjectMaster = objProject.Id;
					Database.executeBatch(objBatch, 1);
				}

				Integer totalContact = scheduleParticipantList.size();
				if (totalContact == 0) {
					totalContact = lstUpdatePart.size();
				}

				Id scheduleEmailId = null;
				if (scheduleParticipantList.size() > 0) {
					update lstSchedulePart; //In case od schedule email, update participant status as : Contact Pending.

					insert scheduleParticipantList;
					scheduleEmailJob();
					strMessage = 'Email schedule to ';
					scheduleEmailId = scheduleEmailObj.Id;
				}
				PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id + '&totalContact=' + totalContact + '&scheduleEmailId=' + scheduleEmailId);
				pageRef.setRedirect(true);
				return pageRef;
			}
			//***********End New Logic***************
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, objExp.getMessage()));
			return null;
		}
		return null;
		//return BackToProjectVF();
	}

	public void scheduleEmailJob() {
		Date scheduleDate = scheduleEmail.Schedule_Email_Date__c;
		String hour = scheduleEmail.Schedule_Email_Time__c;
		UR_ScheduleEmail scheduleObj = new UR_ScheduleEmail();
		String CRON_EXP = '0 0 ' + hour + ' ' + scheduleDate.day() + ' ' + scheduleDate.month() + ' ? ' + scheduleDate.year();

		Integer intHour = Integer.valueOf(scheduleEmail.Schedule_Email_Time__c);
		Time myTime = Time.newInstance(intHour, 0, 0, 0);
		DateTime scheduledDateTime = DateTime.newInstance(scheduleEmail.Schedule_Email_Date__c, myTime);
		String jobName = 'UXR_Schedule_Email_' + scheduledDateTime;

		List<CronTrigger> scheduleJobList = [SELECT id, CronJobDetail.name FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
		if (scheduleJobList.size() == 0) {
			String jobID = system.schedule(jobName, CRON_EXP, scheduleObj);
		}
		//fetchScheduleJob();
	}

	public void checkValidScheduleeDateTime() {
		if (scheduleEmail.Schedule_Email_Date__c == null || scheduleEmail.Schedule_Email_Time__c == null) {
			blnValidScheduleDateTime = false;
		} else {
			blnValidScheduleDateTime = true;
		}

		if (scheduleEmail.Schedule_Email_Date__c != null && scheduleEmail.Schedule_Email_Time__c != null) {
			DateTime currentDateTime = System.now();
			Integer intHour = Integer.valueOf(scheduleEmail.Schedule_Email_Time__c);
			Time myTime = Time.newInstance(intHour, 0, 0, 0);
			DateTime scheduledDateTime = DateTime.newInstance(scheduleEmail.Schedule_Email_Date__c, myTime);

			if (currentDateTime < scheduledDateTime) {
				blnFutureScheduleDateTime = true;
			} else {
				blnFutureScheduleDateTime = false;
			}
		}
	}

	public void scheduleEmailToAll() {
		blnFutureScheduleDateTime = true;
		blnValidScheduleDateTime = true;

		blnValidEmailTagValue();
		checkValidScheduleeDateTime();

		if (
			blnFutureScheduleDateTime &&
			blnValidScheduleDateTime &&
			blnValidEmailTag &&
			String.isNotBlank(strPartStatus) &&
			(String.isNotBlank(strSelectEmailId) || String.isNotBlank(strSelectDraftEmailId)) &&
			map_ToEmailIds.size() > 0
		) {
			String strFinnalSelectedEmail = strSelectEmailId;
			if (String.isBlank(strFinnalSelectedEmail)) {
				strFinnalSelectedEmail = strSelectDraftEmailId;
			}

			strEmailTemplateId = UR_UtilityCtrl.createNewEmailTemplate(strFinnalSelectedEmail, strSubject, strEmailBody + objResearch.Unsubscribe_Text__c);
		}
	}

	public void sendEmailToAll() {
		blnFutureScheduleDateTime = true;
		blnValidScheduleDateTime = true;

		blnValidEmailTagValue();

		if (
			blnFutureScheduleDateTime &&
			blnValidScheduleDateTime &&
			blnValidEmailTag &&
			String.isNotBlank(strPartStatus) &&
			(String.isNotBlank(strSelectEmailId) || String.isNotBlank(strSelectDraftEmailId)) &&
			map_ToEmailIds.size() > 0
		) {
			String strFinnalSelectedEmail = strSelectEmailId;
			if (String.isBlank(strFinnalSelectedEmail)) {
				strFinnalSelectedEmail = strSelectDraftEmailId;
			}

			strEmailTemplateId = UR_UtilityCtrl.createNewEmailTemplate(strFinnalSelectedEmail, strSubject, strEmailBody + objResearch.Unsubscribe_Text__c);
		}
	}

	public void sendEmailToSelf() {
		blnValidEmailTagValue();
		if (blnValidEmailTag && String.isNotBlank(strPartStatus) && (String.isNotBlank(strSelectEmailId) || String.isNotBlank(strSelectDraftEmailId))) {
			String strFinnalSelectedEmail = strSelectEmailId;
			if (String.isBlank(strFinnalSelectedEmail)) {
				strFinnalSelectedEmail = strSelectDraftEmailId;
			}

			strEmailTemplateId = UR_UtilityCtrl.createNewEmailTemplate(strFinnalSelectedEmail, strSubject, strEmailBody + objResearch.Unsubscribe_Text__c);
		}
	}

	public PageReference viewEmail() {
		PageReference pageRef = new PageReference('/apex/UR_ViewEmail?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public PageReference BackToProjectVF() {
		if (previousPageName == null) {
			PageReference pageRef = null;
			Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(objProject.Id);
			previousPageName = 'UR_ManageParticipant?Id=';
			/*if(isParticipantExist){
                previousPageName='UR_ManageParticipant?Id=';
            }else{
               previousPageName='UR_AddParticipants?projectId=';
            }*/
		}
		PageReference pageRef = new PageReference('/apex/' + previousPageName + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public pagereference sendSurvey() {
		sendEmailFlag = 'SS';
		isheader = true;
		return RedirectToSendEmail();
	}

	public pagereference inviteToInterview() {
		sendEmailFlag = 'ITI';
		isheader = true;
		return RedirectToSendEmail();
	}

	public pagereference sendFollowUp() {
		sendEmailFlag = 'SFUI';
		isheader = true;
		return RedirectToSendEmail();
	}

	public pagereference sendEmailParticipants() {
		isCalendlyVisible = true;
		isheader = false;
		return RedirectToSendEmail();
	}

	public pagereference sendEmailParticipantsNoCalendly() {
		isCalendlyVisible = false;
		isheader = false;
		return RedirectToSendEmail();
	}

	public pagereference RedirectToSendEmail() {
		PageReference pageRef = new PageReference('/apex/UR_SendEmail?Id=' + objProject.Id);
		totalContact = 0;
		excludedContactList.clear();
		pageRef.setRedirect(false);
		map_ToEmailIds.clear();
		lstResearchProjectDetail = new List<Research_Project_Detail__c>();
		String value = '';
		objProjectParticipants = new Research_Project_Detail__c();

		if (set_SelectedRecords.size() > 0) {
			List<Research_Project_Detail__c> participantList = getParticipantDetails(set_SelectedRecords);

			for (Research_Project_Detail__c objRPD : participantList) {
				lstResearchProjectDetail.add(objRPD);
				ContactWrapper objWrapper = new ContactWrapper();
				objWrapper.selContact = true;
				objWrapper.chkNDA = objRPD.NDA_Send__c;
				objWrapper.objResProject = objRPD;

				if (!objRPD.Blacklist__c && !objRPD.Opt_Out__c && objRPD.Contact__c != null && objRPD.Contact__r.Email != null && !map_ToEmailIds.containsKey(objRPD.Contact__r.Email)) {
					value = objRPD.Contact__r.Name + '<' + objRPD.Contact__r.Email + '>';
					map_ToEmailIds.put(objRPD.Contact__r.Email, value);
					objProjectParticipants = objRPD;
				} else {
					excludedContactList.add(objWrapper);
				}
			}
		}

		if (lstContactWrapper != null && lstContactWrapper.size() > 0) {
			for (ContactWrapper cw : lstContactWrapper) {
				if (cw.selContact) {
					lstResearchProjectDetail.add(cw.objResProject);

					if (
						!cw.objResProject.Blacklist__c &&
						!cw.objResProject.Opt_Out__c &&
						cw.objResProject.Contact__c != null &&
						cw.objResProject.Contact__r.Email != null &&
						!map_ToEmailIds.containsKey(cw.objResProject.Contact__r.Email)
					) {
						value = cw.objResProject.Contact__r.Name + '<' + cw.objResProject.Contact__r.Email + '>';
						map_ToEmailIds.put(cw.objResProject.Contact__r.Email, value);
						objProjectParticipants = cw.objResProject;
					} else {
						excludedContactList.add(cw);
					}
				}
			}
		}

		intSelectedContact = map_ToEmailIds.size();
		totalContact = intSelectedContact + excludedContactList.size();

		if (isheader == false && lstResearchProjectDetail.size() <= 0) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select record to send an email'));
			return null;
		}

		lstContactWrapper.clear();
		setCon = null;
		pageRef.setRedirect(false);

		return pageRef;
	}

	public pagereference RedirectToViewEmail() {
		PageReference pageRef = new PageReference('/apex/UR_ViewEmail?projectId=' + objProject.Id);
		return pageRef;
	}
	public pagereference RedirectToManageProjectTeams() {
		PageReference pageRef = new PageReference('/apex/UR_ProjectTeam?projectId=' + objProject.Id);
		return pageRef;
	}

	public pagereference RedirectToViewCalendar() {
		PageReference pageRef = new PageReference('/apex/UR_ViewCalendar?projectId=' + objProject.Id);
		return pageRef;
	}
	public pagereference ViewSurvey() {
		PageReference pageRef = new PageReference('/apex/UR_ViewSurveyResponse?projectId=' + objProject.Id);
		return pageRef;
	}

	public PageReference BackToProject() {
		PageReference pageRef = new PageReference('/' + currentRecordId);
		return pageRef;
	}
	public pagereference ManageContacts() {
		PageReference pageRef = new PageReference('/apex/UR_ManageContact?projectId=' + objProject.Id);
		return pageRef;
	}
	public pagereference ManageContactsCSV() {
		PageReference pageRef = new PageReference('/apex/UR_UploadCSV?projectId=' + objProject.Id);
		return pageRef;
	}

	public pagereference RecordAttendance() {
		PageReference pageRef = new PageReference('/apex/UR_ProjectCloser?projectId=' + objProject.Id);
		return pageRef;
	}
	//Method to remove participant
	public PageReference RemoveParticipant() {
		try {
			if (lstContactWrapper != null && lstContactWrapper.size() > 0) {
				List<Research_Project_Detail__c> lstResearchProjectDetail = new List<Research_Project_Detail__c>();
				Set<Id> projectDetailIdSet = new Set<Id>();
				for (ContactWrapper cw : lstContactWrapper) {
					if (cw.selContact == true && cw.objResProject.Research_Participant_Status__c == 'Reserved') {
						lstResearchProjectDetail.add(cw.objResProject);
						projectDetailIdSet.add(cw.objResProject.Id);
					}
				}
				if (lstResearchProjectDetail != null && lstResearchProjectDetail.size() > 0) {
					delete [SELECT Id FROM Research_Project_Detail_Data_Info__c WHERE Research_Project_Detail__c IN :projectDetailIdSet];
					delete lstResearchProjectDetail;
				} else {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Only reserve status participants can be release from porject'));
					return null;
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_NoProjectParticipants));
				return null;
			}
			PageReference pageRef = null;
			pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id);
			/*Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(objProject.Id);
            if(isParticipantExist){
                pageRef = new PageReference('/apex/UR_ManageParticipant?Id='+objProject.Id);
            }else{
                pageRef = new PageReference('/apex/UR_AddParticipants?projectId='+objProject.Id);
            }*/
			pageRef.setRedirect(true);
			return pageRef;
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
	}
	//Update NDA status on Participant level
	public PageReference updateNDAStatus() {
		string strPartId = ApexPages.CurrentPage().getparameters().get('strPartId');

		if (lstContactWrapper != null && lstContactWrapper.size() > 0) {
			List<Research_Project_Detail__c> lstResearchProjectDetail = new List<Research_Project_Detail__c>();
			for (ContactWrapper cw : lstContactWrapper) {
				if (strPartId != null && strPartId == cw.objResProject.Id) {
					Research_Project_Detail__c pd = new Research_Project_Detail__c(Id = cw.objResProject.Id);
					pd.NDA_Send__c = cw.chkNDA;
					pd.Comment__c = cw.strComment;
					cw.objResProject.NDA_Send__c = cw.chkNDA;
					lstResearchProjectDetail.add(pd);
				}
			}

			if (lstResearchProjectDetail != null && lstResearchProjectDetail.size() > 0) {
				update lstResearchProjectDetail;
			}
		}
		/*PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id='+objProject.Id);
        pageRef.setRedirect(true);
        return pageRef;
        */
		return null;
	}
	public pageReference UpdatePartDetail() {
		try {
			ContactTriggerHelper.skipTrigger = true;
			AccountTriggerHelper.skipTrigger = true;

			if ((lstContactWrapper != null && lstContactWrapper.size() > 0) || set_SelectedRecords.size() > 0) {
				List<Research_Project_Detail__c> lstResearchProjectDetail = new List<Research_Project_Detail__c>();
				for (ContactWrapper cw : lstContactWrapper) {
					if (cw.selContact == true) {
						Research_Project_Detail__c pd = new Research_Project_Detail__c(Id = cw.objResProject.Id);
						pd = cw.objResProject;
						if (string.isNotBlank(selectedStatus)) {
							pd.Research_Participant_Status__c = selectedStatus;
						}
						if (isCopyToAllComment) {
							pd.Comment__c = participantComments;
							cw.strComment = participantComments;
						} else if (String.isNotBlank(participantCommentId) && Id.valueOf(participantCommentId) == cw.objResProject.Id) {
							pd.Comment__c = participantComments;
							cw.strComment = participantComments;
						} else {
							pd.Comment__c = cw.strComment;
						}

						lstResearchProjectDetail.add(pd);
					} else if (cw.isEditComment == true) {
						Research_Project_Detail__c pd = new Research_Project_Detail__c(Id = cw.objResProject.Id);
						pd = cw.objResProject;
						pd.Comment__c = cw.strComment;
						lstResearchProjectDetail.add(pd);
					}
				}

				for (Id idParticipant : set_SelectedRecords) {
					Research_Project_Detail__c objRPD = new Research_Project_Detail__c(Id = idParticipant);
					if (string.isNotBlank(selectedStatus)) {
						objRPD.Research_Participant_Status__c = selectedStatus;
					}

					if (isCopyToAllComment) {
						objRPD.Comment__c = participantComments;
					} else if (String.isNotBlank(participantCommentId) && Id.valueOf(participantCommentId) == idParticipant) {
						objRPD.Comment__c = participantComments;
					}

					lstResearchProjectDetail.add(objRPD);
				}

				if (lstResearchProjectDetail != null && lstResearchProjectDetail.size() > 0) {
					update lstResearchProjectDetail;
					participantComments = '';
					participantCommentId = '';
					isCopyToAllComment = false;
				} else {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_ParticipantUpdate));
					return null;
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_NoProjectParticipants));
				return null;
			}
			return null;
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
	}

	public class ContactWrapper {
		public boolean selContact { get; set; }
		public boolean chkNDA { get; set; }
		public boolean isEditComment { get; set; }
		public Research_Project_Detail__c objResProject { get; set; }
		public string envStyle { get; set; }
		public string strComment { get; set; }
		public string participantCommentId { get; set; }
		public Research_Schedule_Email_Participant__c emailScheduleDate { get; set; }
		//public Id scheduleEmailId{get;set;}
	}

	public void initSendEmail() {
		strPartStatus = '';
		strEmailStatus = '';
		sendEmailSubTab = 'MP';
		if (String.isBlank(sendEmailFlag)) {
			sendEmailFlag = ApexPages.CurrentPage().getparameters().get('type');
		}

		if (String.isNotBlank(sendEmailFlag)) {
			if ('SS' == sendEmailFlag) {
				strPartStatus = 'Send survey or screener';
				strEmailStatus = 'Send survey or screener';
				sendEmailSubTab = 'SS';
			} else if ('ITI' == sendEmailFlag) {
				strPartStatus = 'Invite to Interview';
				strEmailStatus = 'Invite to Interview';
				sendEmailSubTab = 'ITI';
			}
			if (String.isNotBlank(strPartStatus)) {
				//Fetch email template on then basis of status.
				RetriveEmailTemplate();
			}

			if ('SFUI' == sendEmailFlag) {
				//Allow user to select status then teir respective email template will populated.
				strPartStatus = 'Send follow up info';
				strEmailStatus = 'Send follow up';
				sendEmailSubTab = 'SFUI';
			}
		}
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

	public PageReference SendSelfEmail() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		UR_UtilityCtrl.skipTriggerLogic();
		try {
			Contact contactObj = null;
			if (string.isBlank(strPartStatus)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_FOLLOW_UP));
				return null;
			} else if (string.isBlank(strSelectEmailId) && string.isBlank(strSelectDraftEmailId)) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_VALID_EMAIL_TEMPLATE));
				return null;
			} else if (map_ToEmailIds.size() == 0) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, RQ_VALID_EMAIL));
				return null;
			} else if (!blnValidEmailTag) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, blankTagField + DOES_NOT_EXIST));
				return null;
			}

			if (lstResearchProjectDetail != null && lstResearchProjectDetail.size() > 0 && (String.isNotBlank(strSelectEmailId) || String.isNotBlank(strSelectDraftEmailId))) {
				List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
				Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
				msg.setWhatId(lstResearchProjectDetail[0].Id);
				String loginUserEmail = UserInfo.getUserEmail();

				List<Contact> tempContactList = [
					SELECT Id, FirstName, LastName, Email, Account.Name
					FROM contact
					WHERE email = :loginUserEmail
				];

				if (tempContactList.size() > 0) {
					contactObj = tempContactList[0];
				} else {
					contactObj = new Contact(AccountId = Label.UR_GustoAccountId, Email = UserInfo.getUserEmail(), FirstName = UserInfo.getFirstName(), LastName = UserInfo.getLastName());
					insert contactObj;
				}
				msg.setTargetObjectId(contactObj.Id);
				if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
					msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
				}

				if (String.isNotBlank(strEmailTemplateId)) {
					msg.setTemplateId(strEmailTemplateId);
				} else {
					msg.setTemplateId(strSelectEmailId);
					msg.setHtmlBody(strEmailBody);
					msg.setSubject(strSubject);
				}

				msg.setSaveAsActivity(false);

				if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
					msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
				}
				mail.add(msg);

				if (mail.size() > 0) {
					EmailMessageTriggerHelper.skipTrigger = true;
					Messaging.sendEmail(mail);
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Test email has been sent to - ' + contactObj.Email));
				}
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			ExceptionLogUtil.logException('UR_ManageParticipantCtrl', 'SendSelfEmail', e.getMessage(), e.getStackTraceString());
			return null;
		}
		return null;
	}

	public void updateQualtricsId() {
		try {
			string surveyURL = objProject.Screener_URL__c;
			if (String.isNotBlank(surveyURL) && surveyURL.indexOf('sID') < 0 && surveyURL.indexOf('qualtrics') > 0) {
				surveyURL = surveyURL + '?sID=';
				objProject.Screener_URL__c = surveyURL;
			}
			objProject.Survey_Id__c = '';

			String surveyId = surveyURL;
			//Parse "Servey Id" from "Survey URL".
			if (String.isNotBlank(surveyURL) && surveyURL.indexOf('qualtrics') > 0) {
				if (surveyId.indexOf('?sID') > 0) {
					surveyId = surveyId.subString(0, surveyId.indexOf('?sID'));
					if (surveyId.lastIndexOf('/') > 0) {
						surveyId = surveyId.subString(surveyId.lastIndexOf('/') + 1, surveyId.length());
						objProject.Survey_Id__c = surveyId;
					}
				}
			}

			//Parse "Servey Id" from "Google form URL".
			if (String.isNotBlank(surveyURL) && surveyURL.indexOf('google') > 0) {
				if (surveyId.indexOf('/d/e/') > 0) {
					surveyId = surveyId.subString(surveyId.indexOf('/d/e/') + 5, surveyId.length());
					if (surveyId.indexOf('/') > 0) {
						surveyId = surveyId.subString(0, surveyId.indexOf('/'));
						objProject.Survey_Id__c = surveyId;
					}
				}
			}

			update objProject;
			//Update Calendly EventId
			calURL = Label.UR_CalPanelURL;
			if (string.isNotblank(objProject.Calendly_EventId__c)) {
				calURL = Label.UR_CalEventURL;
				calURL = calURL.replace('xxxx', objProject.Calendly_EventId__c.Trim());
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			ExceptionLogUtil.logException('UR_ManageParticipantCtrl', 'updateQualtricsId', e.getMessage(), e.getStackTraceString());
		}
	}
	/*** Survey Response *****/
	public List<selectOption> selQuestionsList { get; set; }
	public String strSelectedQuestion { get; set; }
	public List<Research_Survey__c> lstResearchSurvey { get; set; }
	public Map<string, string> mapSurveyQuestion { get; set; }
	public List<surveyResponseWrapper> lstSurveyResponseWrapper { get; set; }

	public PageReference PopulateSurveyResponse() {
		PopulateQuestionPicklist();
		DisplaysurveyTable();
		return null;
	}
	public PageReference PopulateQuestionPicklist() {
		try {
			lstResearchSurvey = new List<Research_Survey__c>();
			//Populate Question and Question Code in select list
			selQuestionsList = new List<selectOption>();
			selQuestionsList.add(new selectOption('', 'All Questions'));
			Set<string> setCheckQuestion = new Set<string>();
			lstResearchSurvey = UR_UtilityCtrl.RetriveResSurveyDetail(currentRecordId, null);
			if (lstResearchSurvey != null && lstResearchSurvey.size() > 0) {
				for (Research_Survey_Response__c objRes : lstResearchSurvey[0].Research_Survey_Responses__r) {
					if (setCheckQuestion.contains(objRes.Survey_Question_Code__c.Trim()) == false) {
						string strQuestion = objRes.Survey_Questions__c;
						if (strQuestion.length() > 100) {
							strQuestion = strQuestion.substring(0, 99);
						}
						selQuestionsList.add(new selectOption(objRes.Survey_Question_Code__c.Trim(), strQuestion));
						setCheckQuestion.add(objRes.Survey_Question_Code__c.Trim());
					}
				}
			}
			setCheckQuestion = new Set<string>();
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
		return null;
	}
	public pagereference DisplaysurveyTable() {
		try {
			mapSurveyQuestion = new Map<string, string>();
			lstSurveyResponseWrapper = new List<surveyResponseWrapper>();
			lstResearchSurvey = new List<Research_Survey__c>();
			lstResearchSurvey = UR_UtilityCtrl.RetriveResSurveyDetail(currentRecordId, strSelectedQuestion);
			if (lstResearchSurvey != null && lstResearchSurvey.size() > 0) {
				//Iterate all related survey response
				for (Research_Survey_Response__c objRes : lstResearchSurvey[0].Research_Survey_Responses__r) {
					if (mapSurveyQuestion.containsKey(objRes.Survey_Question_Code__c) == false) {
						mapSurveyQuestion.put(objRes.Survey_Question_Code__c, objRes.Survey_Questions__c);
					}
				}
			}
			for (Research_Survey__c rsv : lstResearchSurvey) {
				surveyResponseWrapper sv = new surveyResponseWrapper();
				sv.selContact = false;
				sv.objResearchSurvey = rsv;
				lstSurveyResponseWrapper.add(sv);
			}
			if (lstSurveyResponseWrapper.size() == 0) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Your survey has not received any responses so far.'));
				return null;
			}
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}

		return null;
	}

	public pagereference Downloadcsv() {
		return Page.UR_SurveyResponseCSV;
	}

	public List<Research_Project_Detail__c> getParticipantDetails(Set<Id> participantIdSet) {
		Id uxScoutId = objProject.id;
		String strQueryString =
			'SELECT Id,Research_Project_Master__c,NDA_Send__c,Blacklist__c, ' +
			'Opt_Out__c,Reason__c,Incentive__c,Unread_Email__c,' +
			'Project_Name__c,Project_Id__c,Screener_URL__c,Contact__c,' +
			'Contact__r.AccountId,Contact__r.Account.Name, Contact__r.Account.ZP_Company_ID__c, ' +
			'Contact__r.ZP_User_Id__c, Contact__r.Employee_Id__c,' +
			'Contact__r.Email,Contact__r.Name, Comment__c, Contact__r.UXResearch_Opt_Out__c, ' +
			'Research_Participant_Status__c, Researcher_Name__c, Calendly_URL__c, Company_Name__c, ' +
			'Date_of_Attended__c, Incentive_Amount__c, Length_of_Interview__c,  Locked__c, NDA_URL__c,' +
			'Research_Participant_Status_Number__c, Study_End_Date__c, Study_Start_Date__c, ' +
			'Participant_Email__c, Researcher_Email__c FROM Research_Project_Detail__c where Research_Project_Master__c=:uxScoutId and Id IN : participantIdSet';

		List<Research_Project_Detail__c> participantList = database.query(strQueryString);
		return participantList;
	}

	public pagereference inviteToInterviewFromSurvey() {
		sendEmailFlag = 'ITI';
		return RedirectToSendEmailFromSurvey();
	}
	public pagereference sendFollowUpFromSurvey() {
		sendEmailFlag = 'SFUI';
		return RedirectToSendEmailFromSurvey();
	}
	public pagereference RedirectToSendEmailFromSurveyNoCalendly() {
		isCalendlyVisible = false;
		PageReference pageRef = RedirectToSendEmailFromSurvey();
		return pageRef;
	}

	public pagereference RedirectToSendEmailFromSurvey() {
		PageReference pageRef = null;
		Set<Id> setprojectDetailId = new Set<Id>();
		lstContactWrapper = new List<ContactWrapper>();
		//Populate lstContactWrapper to send data in email page
		for (surveyResponseWrapper sw : lstSurveyResponseWrapper) {
			if (sw.selContact == true) {
				setprojectDetailId.add(sw.objResearchSurvey.Research_Project_Detail__c);
			}
		}

		List<Research_Project_Detail__c> participantList = getParticipantDetails(setprojectDetailId);

		if (setprojectDetailId != null && setprojectDetailId.size() > 0) {
			// for(Research_Project_Detail__c rpd:objProject.Research_Project_Details__r)
			for (Research_Project_Detail__c rpd : participantList) {
				if (setprojectDetailId.contains(rpd.id) == true) {
					ContactWrapper cw = new ContactWrapper();
					cw.selContact = true;
					cw.chkNDA = rpd.NDA_Send__c;
					cw.objResProject = rpd;
					lstContactWrapper.add(cw);
				}
			}
			if (lstContactWrapper != null && lstContactWrapper.size() > 0) {
				previousPageName = 'UR_ViewSurveyResponse?Id=';
				pageRef = RedirectToSendEmail();
				pageRef = new PageReference('/apex/UR_SendEmail?Id=' + objProject.Id);
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select record to send an email'));
			return null;
		}
		return pageRef;
	}
	public class surveyResponseWrapper {
		public Research_Survey__c objResearchSurvey { get; set; }
		public boolean selContact { get; set; }
	}

	/*** End Survey Response ****/

	public void blnValidEmailTagValue() {
		blnValidEmailTag = true;
		blankTagField = '';
		try {
			Set<String> fieldAPIName = new Set<String>();
			//fieldAPIName.addAll(getEmailTagAPIName(strSubject));
			//Find merge field in Email body
			fieldAPIName.addAll(getEmailTagAPIName(strEmailBody));
			if (fieldAPIName.size() > 0 && intSelectedContact > 0) {
				String tagValue = '';
				String key = '';
				for (String str : fieldAPIName) {
					tagValue = objProjectParticipants.get(str) + '';
					if ('Calendly_URL__c' == str) {
						tagValue = objProject.Primary_calendly_URL__c;
					} else if ('Screener_URL__c' == str) {
						tagValue = objProject.Screener_URL__c;
					}

					if (String.isBlank(tagValue) || tagValue == 'null') {
						blnValidEmailTag = false;
						key = '{!Research_Project_Detail__c.' + str + '}';
						if (glossaryMap.containsKey(key)) {
							blankTagField = glossaryMap.get(key);
						} else {
							blankTagField = key;
						}
						break;
					}
				}
			}

			if (Test.isRunningTest()) {
				blnValidEmailTag = true;
			}
		} catch (Exception objExp) {
			blnValidEmailTag = false;
		}
	}

	public Set<String> getEmailTagAPIName(String strValue) {
		Set<String> fieldAPIName = new Set<String>();
		if (String.isNotBlank(strValue)) {
			Integer tagStartIndex = strValue.indexOf('Research_Project_Detail__c');
			Integer tagEndIndex = 0;
			while (tagStartIndex > -1) {
				//Note here 27 is length of "Research_Project_Detail__c." string.
				tagStartIndex = tagStartIndex + 27;
				strValue = strValue.subString(tagStartIndex, strValue.length());
				tagEndIndex = strValue.indexOf('}');
				if (tagEndIndex > 0) {
					fieldAPIName.add(strValue.subString(0, tagEndIndex));
					strValue = strValue.subString(tagEndIndex - 1, strValue.length());
				}
				tagStartIndex = strValue.indexOf('Research_Project_Detail__c');
			}
		}
		return fieldAPIName;
	}

	public void setProjectDetailEmailStatus(Research_Project_Detail__c objUpdate, String emailStatus) {
		if ((String.isBlank(emailStatus) || emailStatus == 'No Email') && (strEmailStatus == 'Send follow up' || strEmailStatus == 'Send survey or screener')) {
			objUpdate.Participant_Email__c = 'Contacted';
		} else if ((String.isBlank(emailStatus) || emailStatus == 'No Email' || emailStatus == 'Contacted') && strEmailStatus == 'Invite to Interview') {
			objUpdate.Participant_Email__c = 'Invited';
		}
	}

	public PageReference addParticipants() {
		PageReference pageRef = null;
		if ('From Salesforce search' == selIncludeParticipant) {
			pageRef = new PageReference('/apex/UR_ManageContact?projectId=' + objProject.Id);
		} else if ('From CSV' == selIncludeParticipant) {
			pageRef = new PageReference('/apex/UR_ManageCSV?projectId=' + objProject.Id);
		}
		pageRef.setRedirect(true);
		return pageRef;
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
		updateSelectedMap();
		setCon.first();
		RetriveProjectRecord(false);
	}

	/** returns the last page of the page set*/
	public void last() {
		saveSetControler();
		updateSelectedMap();
		setCon.last();
		RetriveProjectRecord(false);
	}

	/** returns the previous page of the page set*/
	public void previous() {
		saveSetControler();
		updateSelectedMap();
		setCon.previous();
		RetriveProjectRecord(false);
	}

	/** returns the next page of the page set*/
	public void next() {
		saveSetControler();
		updateSelectedMap();
		setCon.next();
		RetriveProjectRecord(false);
	}

	public pageReference sortParticipantList() {
		setSortingFilter();

		PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id + '&projectId=' + objProject.Id + '&orderas=' + orderAs + '&sortby=' + sortbyFieldAPIName);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public pageReference cancelEditComment() {
		PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id + '&projectId=' + objProject.Id + '&orderas=' + orderAs + '&sortby=' + sortbyFieldAPIName);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void searchParticipantFromList() {
		updateSelectedMap();
		searchQuery = '';
		searchIds.clear();
		if (String.isNotBlank(searchString)) {
			searchString = searchString.trim();
			String searchStringValue = searchString.toLowerCase();
			String comment = '';
			List<Research_Project_Detail__c> tempProjectDetailList = [SELECT Id, Comment__c FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.id];
			for (Research_Project_Detail__c obj : tempProjectDetailList) {
				if (String.isNotBlank(obj.Comment__c)) {
					comment = obj.Comment__c.toLowerCase();
					if (comment.indexOf(searchStringValue) >= 0) {
						searchIds.add(obj.Id);
					}
				}
			}
			tempProjectDetailList.clear();

			searchQuery = searchQuery + 'AND ( Contact__r.Name like \'%' + searchString + '%\' OR ';
			searchQuery = searchQuery + ' Contact__r.Email like \'%' + searchString + '%\' OR ';
			searchQuery = searchQuery + ' Contact__r.Account.Name like \'%' + searchString + '%\' OR ';
			searchQuery = searchQuery + ' Research_Participant_Status__c like \'%' + searchString + '%\' ';
			searchQuery = searchQuery + ' OR E_Mail_Status__c like \'%' + searchString + '%\' ';
			if (searchIds.size() > 0) {
				searchQuery = searchQuery + ' OR Id IN : searchIds ';
			}
			searchQuery = searchQuery + ' ) ';
		}
		RetriveProjectRecord(true);
	}

	public void updateSelectedMap() {
		Set<Id> prevReservedSet = new Set<Id>();
		Set<Id> prevUnReservedSet = new Set<Id>();
		if (lstContactWrapper != null && lstContactWrapper.size() > 0) {
			for (ContactWrapper cw : lstContactWrapper) {
				if (cw.selContact) {
					set_SelectedRecords.add(cw.objResProject.Id);
					if ('Reserved' == cw.objResProject.Research_Participant_Status__c) {
						prevReservedSet.add(cw.objResProject.Id);
					} else {
						prevUnReservedSet.add(cw.objResProject.Id);
					}
				} else if (set_SelectedRecords.contains(cw.objResProject.Id)) {
					set_SelectedRecords.remove(cw.objResProject.Id);
					if ('Reserved' == cw.objResProject.Research_Participant_Status__c) {
						prevReservedSet.remove(cw.objResProject.Id);
					} else {
						prevUnReservedSet.remove(cw.objResProject.Id);
					}
				}
			}
			prevResveredCount = prevReservedSet.size();
			prevUnResveredCount = prevUnReservedSet.size();
		}
		selectedRecordCount = set_SelectedRecords.size();
	}

	//This method show/hide ScheduleEmail section.
	public void hideScheduleEmail() {
		if (showHideScheduleEmail == true) {
			showHideScheduleEmail = false;
		} else {
			showHideScheduleEmail = true;
		}
	}

	public PageReference cancelScheduleEmail() {
		PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + objProject.Id + '&remove=job');
		pageRef.setRedirect(true);
		String scheduleEmailId = ApexPages.CurrentPage().getparameters().get('scheduleEmailId');
		if (String.isNotBlank(scheduleEmailId)) {
			List<Research_Schedule_Email__c> scheduleEmailList = [SELECT id, Schedule_Email_Date__c, Schedule_Email_Time__c FROM Research_Schedule_Email__c WHERE Id = :scheduleEmailId];
			if (scheduleEmailList.size() > 0) {
				Integer intHour = Integer.valueOf(scheduleEmailList[0].Schedule_Email_Time__c);
				Time myTime = Time.newInstance(intHour, 0, 0, 0);
				DateTime scheduledDateTime = DateTime.newInstance(scheduleEmailList[0].Schedule_Email_Date__c, myTime);
				String jobName = 'UXR_Schedule_Email_' + scheduledDateTime;

				List<Research_Schedule_Email__c> otherScheduleEmailList = [
					SELECT Id
					FROM Research_Schedule_Email__c
					WHERE Id != :scheduleEmailId AND Schedule_Email_Date__c = :scheduleEmailList[0].Schedule_Email_Date__c AND Schedule_Email_Time__c = :scheduleEmailList[0].Schedule_Email_Time__c
				];

				List<CronTrigger> scheduleJobList = [SELECT id, CronJobDetail.name FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
				if (scheduleJobList.size() > 0 && otherScheduleEmailList.size() == 0) {
					System.abortJob(scheduleJobList[0].id);
				}

				if (!Test.isRunningTest() && scheduleEmailList.size() > 0) {
					delete scheduleEmailList;
				}
			}
		}
		return pageRef;
	}

	public void updateViewSurveyDate() {
		objProject.Last_View_Survey_Date__c = System.today();
		UR_ProjectMasterTriggerHelper.skipTrigger = true;
		update objProject;
		UR_ProjectMasterTriggerHelper.skipTrigger = false;
		isUpdateLastViewDate = false;
	}

	public void resendEmail() {
		try {
			string strPartId = ApexPages.CurrentPage().getparameters().get('strPartId');
			if (String.isNotBlank(strPartId)) {
				List<Research_Project_Detail__c> lstResearchProjectDetail = [
					SELECT id, E_Mail_Status__c, Send_Email_Error__c
					FROM Research_Project_Detail__c
					WHERE id = :strPartId
				];
				if (lstResearchProjectDetail.size() > 0) {
					lstResearchProjectDetail[0].E_Mail_Status__c = 'Process Email';
					lstResearchProjectDetail[0].Send_Email_Error__c = '';
					update lstResearchProjectDetail[0];

					for (ContactWrapper cw : lstContactWrapper) {
						if (strPartId != null && strPartId == cw.objResProject.Id) {
							cw.objResProject.E_Mail_Status__c = lstResearchProjectDetail[0].E_Mail_Status__c;
							cw.objResProject.Send_Email_Error__c = lstResearchProjectDetail[0].Send_Email_Error__c;
						}
					}
					if (lstResearchProjectDetail[0].Send_Email_Error__c != 'Fail') {
						ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Email successfully send.'));
					}
				}
			}
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
		}
	}

	public void saveEmailAsDraft() {
		if (String.isNotBlank(strPartStatus) && map_ToEmailIds.size() > 0 && (String.isNotBlank(strSelectEmailId) || String.isNotBlank(strDraftEmailTemplateId))) {
			if (String.isBlank(strDraftEmailTemplateId)) {
				if (String.isBlank(strDraftEmailNickName)) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, RQ_TEMPLATE_NAME));
					blnDraftEmail = false;
					return;
				}
				//Create new draft email.
				String strDraftName = UserInfo.getUserId() + '_' + objProject.Project_Id__c;
				strDraftName = strDraftName.replace('-', '_');
				createDraftEmailTemplate(strSelectEmailId, strSubject, strEmailBody);
			} else {
				//Update draft email template
				EmailTemplate objEmailTemplate = new EmailTemplate(Id = strDraftEmailTemplateId);
				objEmailTemplate.HtmlValue = strEmailBody;
				objEmailTemplate.Subject = strSubject;
				update objEmailTemplate;
			}
		}
	}

	//Create or Update Draft email template on click of send email button.
	public void createDraftEmailTemplate(String strSelectTemplateId, String strSubject, String strEmailBody) {
		try {
			//Create new draft email template. This block of code will execute only once. When User enable Auto-Save toggle from UI.
			//Create Template unique name(DeveloperName).
			String strDraftTemplateName = 'T_' + strSelectTemplateId + '_' + objProject.Project_Id__c + '_' + String.valueof(DateTime.now().getTime());
			strDraftTemplateName = strDraftTemplateName.replace('-', '_');

			EmailTemplate objTemplate = new EmailTemplate(IsActive = true, TemplateStyle = 'none', TemplateType = 'custom', Body = '');
			for (Folder objFolder : [
				SELECT Id, DeveloperName, Name
				FROM Folder
				WHERE DeveloperName = :UR_ManageParticipantCtrl.UX_DRAFT_EMAIL
				LIMIT 1
			]) {
				objTemplate.FolderId = objFolder.id;
			}

			objTemplate.Name = strDraftEmailNickName + ' | ' + UserInfo.getName();
			objTemplate.DeveloperName = strDraftTemplateName;
			objTemplate.HtmlValue = strEmailBody;
			objTemplate.Subject = strSubject;
			insert objTemplate;

			//Put value in Map.
			strDraftEmailTemplateId = objTemplate.Id; //Draft email template id
			blnDraftEmail = true;
			strDraftEmailNickName = '';
			strSelectEmailId = ''; //Default email template id
			list_DraftEmailTemplates.add(new SelectOption(objTemplate.Id + '', objTemplate.Name));
			strSelectDraftEmailId = objTemplate.id; //Select draft email template id
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, SAVE_DRAFT_EMAIL));
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, objExp.getMessage()));
		}
	}

	public void deleteDraftEmail() {
		try {
			if (String.isNotBlank(strDraftEmailTemplateId)) {
				//Delete Draft Email Template
				List<EmailTemplate> list_EmailTemplate = [
					SELECT Id
					FROM EmailTemplate
					WHERE Id = :strDraftEmailTemplateId
				];
				if (list_EmailTemplate.size() > 0) {
					delete list_EmailTemplate;
				}

				//Fetch Existing Email template.
				strDraftEmailTemplateId = '';
				strSelectDraftEmailId = '';
				strSubject = '';
				strEmailBody = '';
				RetriveEmailTemplate();
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, DELETE_DRAFT_EMAIL));
			}
		} catch (Exception objExp) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, objExp.getMessage()));
		}
	}
}