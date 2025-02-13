/**********************************************************************
Name: CX_Engagement_MassEmailController
Copyright © 2020  Gusto
============================================================================================================
Purpose:                                                           
-------  
This class is an controller of CX_Engagement_MassEmail page.                                                         
============================================================================================================
History                                                           
-------                                                           
VERSION        AUTHOR            DATE               CHANGE REQUEST           DETAIL
  1.0 -        Dhir           03/April/2020      Initial Development  
*********************************************************************/
global class CX_Engagement_MassEmailController {
	//public Boolean boolHasBenefits {get; set;} // Need to be picked up from Account **
	//Case Reason from names of Routing_Case_Reason_Classification__c
	public String strCaseReason { get; set; }
	//Agatha Confidence number
	public Integer intConfidencePercentage { get; set; }
	//List of Cases
	public List<Case> list_Cases { get; set; }
	//the selected email template folder
	public String strSelectedEmailFolder { get; set; }
	//the selected email template
	public String strSelectedEmailTemplate { get; set; }
	//List of email template select options from the selected folder
	public List<SelectOption> list_EmailTemplatesByFolderName { get; set; }
	//the selected email template
	public EmailTemplate emailTemplateRec { get; set; }
	//list of Case Wrapper records
	public List<CaseWrapper> list_CaseWrappers { get; set; }
	//the list of select options for case reason classifications
	public List<SelectOption> list_CaseReasonClassifications { get; set; }
	//the mass email cases queue
	public Group massEmailQueue { get; set; }
	//the support@gusto org wide email address
	public List<OrgWideEmailAddress> list_SupportEmailAddress { get; set; }
	//dummy Case object to search owners
	public Case dummyCase { get; set; }
	//boolean to disable/enable case search button
	public Boolean boolDisableSearchButton { get; set; }
	//boolean to disable/enable send email button
	public Boolean boolDisableSendButton { get; set; }
	//boolean to switch between preview and editor template view. False is editor view
	public Boolean boolPreview { get; set; }
	//the id of the mass email template folder
	public Id idMassEmailFolder { get; set; }
	//the name of the email template being saved
	public String strMassEmailName { get; set; }
	//the HTML body to save onto new email template
	public String strHtmlBody { get; set; }
	//boolean to keep cases open and in current queue
	public Boolean boolKeepOpen { get; set; }
	/*
        Class Constructor
    */
	public CX_Engagement_MassEmailController() {
		strCaseReason = '';
		list_Cases = new List<Case>();
		list_CaseWrappers = new List<CaseWrapper>();
		list_EmailTemplatesByFolderName = new List<SelectOption>();
		list_CaseReasonClassifications = new List<SelectOption>();
		massEmailQueue = [SELECT Id FROM Group WHERE Name = 'Mass Email Cases'];
		list_SupportEmailAddress = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');
		dummyCase = new Case();
		boolDisableSearchButton = true;
		boolDisableSendButton = true;
		boolPreview = true;
		strMassEmailName = '';
		boolKeepOpen = false;
	}

	/*
        Author: Alex
        Date: 4/9/2020
        Desc: this method sets boolPreview to false, making editor visible
    */

	public void switchToEditor() {
		boolPreview = false;
	}

	//this method determines if the search button is disabled/enabled
	public void toggleSearchButton() {
		if (list_CaseReasonClassifications.size() == 0) {
			boolDisableSearchButton = true;
		} else {
			boolDisableSearchButton = false;
		}
	}

	/*
        gets Case Reason Classifications based on Case Type__c and owner id
    */
	public void fetchCaseReasonClassifications() {
		list_CaseReasonClassifications = new List<SelectOption>();
		if (dummyCase.OwnerId != null && String.valueOf(dummyCase.OwnerId).startsWith('00G')) {
			Group q = [SELECT Name, Type FROM Group WHERE Id = :dummyCase.OwnerId];

			//When Queue is selected, search for Cases that belong to it with the chosen case type and get field Routing Case Reason (Case_Reason_Classification__c) from all of those Cases
			for (Case c : [
				SELECT Id, Routing_Case_Reason_Classification__c, Routing_Case_Reason_Classification__r.Name
				FROM Case
				WHERE Routing_Case_Reason_Classification__r.Active__c = TRUE AND Owner.Name = :q.Name
			]) {
				SelectOption so = new SelectOption(c.Routing_Case_Reason_Classification__c, c.Routing_Case_Reason_Classification__r.Name);
				if (!list_CaseReasonClassifications.contains(so)) {
					list_CaseReasonClassifications.add(so);
				}
			}

			if (list_CaseReasonClassifications.size() > 0) {
				list_CaseReasonClassifications = selectOptionSortByLabel(list_CaseReasonClassifications);
			}
			toggleSearchButton();
		} else if (dummyCase.OwnerId != null && !String.valueOf(dummyCase.OwnerId).startsWith('00G')) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please search for a Queue'));
		}
	}

	/*
        @Param:List of selectOption to be sort.
        @Return: Sorted list of selectOptions by Label
    */
	public List<SelectOption> selectOptionSortByLabel(List<SelectOption> list_SelectOptionsToSort) {
		if (list_SelectOptionsToSort == null || list_SelectOptionsToSort.size() <= 1) {
			return list_SelectOptionsToSort;
		}
		List<SelectOption> list_LessSelectOption = new List<SelectOption>();
		List<SelectOption> list_GreaterSelectOption = new List<SelectOption>();
		Integer intPivot = list_SelectOptionsToSort.size() / 2;

		//save the pivot and remove it from the selectOption list
		SelectOption pivotValue = list_SelectOptionsToSort[intPivot];
		list_SelectOptionsToSort.remove(intPivot);
		for (SelectOption so : list_SelectOptionsToSort) {
			if (so.getLabel() <= pivotValue.getLabel()) {
				list_LessSelectOption.add(so);
			} else if (so.getLabel() > pivotValue.getLabel()) {
				list_GreaterSelectOption.add(so);
			}
		}
		List<SelectOption> list_SortedSelectOptions = new List<SelectOption>();
		list_SortedSelectOptions.addAll(selectOptionSortByLabel(list_LessSelectOption));
		list_SortedSelectOptions.add(pivotValue);
		list_SortedSelectOptions.addAll(selectOptionSortByLabel(list_GreaterSelectOption));
		return list_SortedSelectOptions;
	}

	/*
        This method is developed to search the cases based on the conditions as to be shown on the page.
    */
	public void searchCases(Boolean showMessage) {
		list_Cases = new List<Case>();
		list_CaseWrappers = new List<CaseWrapper>();
		String strCaseQuery =
			'SELECT Subject, Owner.Name, OwnerId, Type, Description, CaseNumber, Agatha_Confidence__c,' +
			' Contact.Name, ContactId, Last_out_bound_email__c, Routing_Case_Reason__c, Routing_Case_Reason_Classification__c, Mass_Email_Template_Applied__c' +
			' FROM Case' +
			' WHERE (Last_out_bound_email__c = null OR Reopened_After_Mass_Email__c = true)' +
			' AND ContactId != null' +
			' AND Owner.type = \'Queue\'' +
			' AND Status not in (\'Solved\' , \'Closed\' , \'Cancelled\')' +
			' AND Owner.Name NOT IN (\'Engagement - Payroll Unauthorized\', \'Engagement - Benefits Unauthorized\', \'Full-Stack Care - Non Actionable\')' +
			' AND OwnerId = \'' +
			dummyCase.OwnerId +
			'\'';
		String strTypeClause = ' AND (RecordType.Name = \'Benefits Care\' OR RecordType.Name = \'Payroll Care\' OR RecordType.Name = \'Tax Res\')';

		strCaseQuery = strCaseQuery + strTypeClause;
		if (strCaseReason != '') {
			strCaseQuery = strCaseQuery + ' AND Routing_Case_Reason_Classification__c = \'' + strCaseReason + '\'';
		}
		if (intConfidencePercentage != null && intConfidencePercentage != 0) {
			strCaseQuery = strCaseQuery + ' AND Agatha_Confidence__c > ' + intConfidencePercentage;
		}
		strCaseQuery += ' LIMIT 100';
		//NOTE: ADD A PAGE MESSAGE SAYING SHOWING FIRST 100 RESULTS
		list_Cases = Database.query(strCaseQuery);
		if (list_Cases.size() > 0) {
			list_Cases.sort();
			if (list_Cases.size() == 100) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Search returned first 100 Cases'));
			}
			for (Case rec : list_Cases) {
				list_CaseWrappers.add(new CaseWrapper(rec));
			}
		}
		if (showMessage == true) {
			if (list_CaseWrappers.size() > 0) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Search successfull'));
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'No Record Found'));
			}
		}
	}

	//show page message when searching (normal use)
	public void searchCasesShowMessage() {
		searchCases(true);
	}

	//Get email template folders. Mass Email Template will be first
	public List<SelectOption> getEmailTemplateFolderOpts() {
		List<SelectOption> list_Opts = new List<SelectOption>();
		list_Opts.add(new SelectOption('--None--', '--None--'));
		Folder fldrMassEmail = [SELECT Id, Name FROM Folder WHERE Name = 'Mass Email Templates'];
		idMassEmailFolder = fldrMassEmail.Id;
		list_Opts.add(new SelectOption(fldrMassEmail.Id, fldrMassEmail.Name));

		for (Folder f : [SELECT Id, Name FROM Folder WHERE Type = 'Email' ORDER BY Name ASC]) {
			if (f.Name != 'Mass Email Templates') {
				list_Opts.add(new SelectOption(f.Id, f.Name));
			}
		}
		list_Opts.add(new SelectOption(UserInfo.getOrganizationId(), 'Unfiled Public Classic Email Templates'));
		return list_Opts;
	}

	/*
        Author: Alex
        Date: 4/9/2020
        Desc: This method queries email templates from a folder
    */
	public void queryTemplates() {
		List<SelectOption> list_TemplateSelect = new List<SelectOption>();
		List<EmailTemplate> list_Template = new List<EmailTemplate>();

		for (EmailTemplate f : [SELECT Id,Name,Description FROM EmailTemplate WHERE FolderId = :strSelectedEmailFolder ORDER BY Name ASC]) {
			if (f.Description == null) {
				list_TemplateSelect.add(new SelectOption(f.Id, f.Name));
			} else {
				list_TemplateSelect.add(new SelectOption(f.Id, f.Description));
			}
		}

		list_EmailTemplatesByFolderName.add(new SelectOption('--None--', '--None--'));
		list_EmailTemplatesByFolderName.addAll(selectOptionSortByLabel(list_TemplateSelect));
	}

	/*
        This method is to fetch the email templates according to the email folder selected on page
    */
	public void fetchEmailTemplatesByFolderName() {
		list_EmailTemplatesByFolderName = new List<SelectOption>();
		if (strSelectedEmailFolder != '' && strSelectedEmailFolder != null) {
			queryTemplates();
			emailTemplateRec = null;
			strSelectedEmailTemplate = '';
			strHtmlBody = null;
		}
	}

	/*
        Assigns emailTemplateRec the selected Email Template from strSelectedEmailTemplate
    */
	public void displayEmailTemplate() {
		if (strSelectedEmailTemplate != '' && strSelectedEmailTemplate != '--None--') 
		{
			emailTemplateRec = [SELECT Id, Name, Subject, FolderId, BrandTemplateId, TemplateStyle, DeveloperName, Encoding, HtmlValue FROM EmailTemplate WHERE Id = :strSelectedEmailTemplate Limit 1];
					strHtmlBody = emailTemplateRec.HtmlValue;
			strMassEmailName = emailTemplateRec.Name;
			dummyCase.Subject = emailTemplateRec.Name;
			if (emailTemplateRec.HtmlValue != null && !emailTemplateRec.HtmlValue.contains('{!Case.Thread_Id}')) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Email template does not contain Thread Id. Please click Modify, change the template name, and click Save.'));
			} else {
				boolDisableSendButton = false;
			}
		}
	}

	/*
        Author: Alex
        Date: 4/9/2020
        Desc: saves email template to Mass Email Template folder. Appends Thread Id.
    */
	public void saveTemplate() {
		String strTemplateDevName = strMassEmailName.replace(' ', '_');
		EmailTemplate emailTemp = new EmailTemplate(
			FolderId = idMassEmailFolder,
			Name = strMassEmailName,
			TemplateType = 'Custom',
			HtmlValue = strHtmlBody + '<br></br><font color="white">{!Case.Thread_Id}</font>',
			Subject = emailTemplateRec.Subject,
			Encoding = emailTemplateRec.Encoding,
			IsActive = true
		);
		try {
			if (validateName(emailTemp.Name) == true) {
				emailTemp.DeveloperName = emailTemp.Name.replace(' ', '');
				insert emailTemp;
				boolPreview = true;
				emailTemplateRec = emailTemp;
				strSelectedEmailFolder = idMassEmailFolder;
				queryTemplates();
				strSelectedEmailTemplate = emailTemp.Id;
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
		}
	}

	/*
        Author: Alex
        Date: 4/9/2020
        Desc: this method validates the string entered to be alphanumeric and sees if email already exists
    */
	public Boolean validateName(String strName) {
		if (!strName.isAlphanumericSpace()) {
			ApexPages.addMessage(
				new ApexPages.message(
					ApexPages.severity.WARNING,
					'The Template Name can only contain underscores and alphanumeric characters. It must be unique, begin with a letter, not include spaces, not end with an underscore, and not contain two consecutive underscores.'
				)
			);
			return false;
		} else {
			List<EmailTemplate> list_Templates = [SELECT Id, Name FROM EmailTemplate WHERE Name = :strName];
			if (!list_Templates.isEmpty()) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'An email template already exists with this name, please rename your template'));
				return false;
			} else {
				return true;
			}
		}
	}

	/*
        Sends emails from the support@gusto org wide email address
        creates an email message record on the case(s)
    */
	public void sendEmail() {
		Boolean blnSelected = false;
		for (CaseWrapper cw : list_CaseWrappers) {
			if (cw.check == true) {
				blnSelected = true;
				break;
			}
		}
		if (emailTemplateRec != null && list_CaseWrappers != null && list_CaseWrappers.size() > 0) {
			List<Messaging.SingleEmailMessage> list_SingleEmailMessage = new List<Messaging.SingleEmailMessage>();
			List<EmailMessage> list_EmailMessage = new List<EmailMessage>();
			List<Case> list_CasesToUpdate = new List<Case>();
			List<Id> caseWrapIds = new List<Id>();
			for (CaseWrapper cw : list_CaseWrappers) {
				caseWrapIds.add(cw.caseRec.Id);
			}

			List<Case> list_RecipientCases = [
				SELECT Id, CaseNumber, Mass_Email_Template_Applied__c, ContactId, Subject, Routing_Case_Reason_Classification__c, Routing_Case_Reason__c, Status, OwnerId
				FROM Case
				WHERE Id IN :caseWrapIds
			];
			Map<Id, Case> map_RecipientCases = new Map<Id, Case>(list_RecipientCases);
			for (CaseWrapper rec : list_CaseWrappers) {
				Id idOriginalOwner;
				if (rec.caseRec.OwnerId != null) {
					idOriginalOwner = rec.caseRec.OwnerId;
				}
				if (Test.isRunningTest()) {
					rec.check = true;
				}
				if (rec.check) {
					if (map_RecipientCases.get(rec.caseRec.Id).Mass_Email_Template_Applied__c == emailTemplateRec.Name) {
						ApexPages.addmessage(
							new ApexPages.message(ApexPages.severity.ERROR, 'Case ' + rec.caseRec.CaseNumber + ' has already been sent this email template. Please deselect it before you continue.')
						);
					} else {
						Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
						mail.setTemplateId(emailTemplateRec.Id);
						mail.setTargetObjectId(rec.caseRec.contactId);
						mail.setSaveAsActivity(false);
						mail.setUseSignature(false);
						mail.setWhatId(rec.caseRec.Id);
						if (!list_SupportEmailAddress.isEmpty()) {
							mail.setOrgWideEmailAddressId(list_SupportEmailAddress[0].Id);
						}

						list_SingleEmailMessage.add(mail);

						EmailMessage emailMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
						emailMsg.ToAddress = rec.caseRec.contactId;
						emailMsg.Subject = emailTemplateRec.Subject;
						emailMsg.HtmlBody = emailTemplateRec.HtmlValue;
						emailMsg.ParentId = rec.caseRec.Id; //Attaching with the case
						emailMsg.MessageDate = System.now();
						emailMsg.Status = '0';
						if (!list_SupportEmailAddress.isEmpty()) {
							emailMsg.fromAddress = list_SupportEmailAddress[0].Address;
						}

						list_EmailMessage.add(emailMsg);

						rec.caseRec.Last_out_bound_email__c = System.now();
						rec.caseRec.Mass_Email_Template_Applied__c = emailTemplateRec.Name;
						if (rec.caseRec.Routing_Case_Reason_Classification__c != null) {
							rec.caseRec.Confirm_Case_Reason_Classification__c = rec.caseRec.Routing_Case_Reason_Classification__c;
						}
						if (rec.caseRec.Routing_Case_Reason__c != null) {
							rec.caseRec.Confirm_Case_Reason__c = rec.caseRec.Routing_Case_Reason__c;
						}
						rec.caseRec.Benefits_and_Payroll_Care_Support_Needed__c = 'No';
						rec.caseRec.status = 'Solved';
						rec.caseRec.Reopened_after_mass_email__c = boolKeepOpen;
						if (massEmailQueue != null) {
							rec.caseRec.OwnerId = massEmailQueue.Id;
						}
						//if true, keep the case(s) open and in the same queue - prevent auto solve of mass email
						if (boolKeepOpen) {
							rec.caseRec.status = 'Open';
							rec.caseRec.OwnerId = idOriginalOwner;
						}
						list_CasesToUpdate.add(rec.caseRec);
					}
				}
			}
			try {
				if (blnSelected) {
					update list_CasesToUpdate;
					Messaging.sendEmail(list_SingleEmailMessage, false);
					insert list_EmailMessage;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail Send successfull'));
				} else
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select a Case'));
			} catch (Exception e) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
				ExceptionLogUtil.logException('CX_Engagement_MassEmailController', 'sendEmail', e.getMessage(), e.getStackTraceString());
			}
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select Email Template'));
		}
	}

	/*
        Case Wrapper class
    */
	public class CaseWrapper {
		//to see if the Case has been selected to send an email to
		public Boolean check { get; set; }
		//the Case record
		public Case caseRec { get; set; }

		/*
            Class constructor
        */
		public CaseWrapper(Case caseRec) {
			this.caseRec = caseRec;
			this.check = false;
		}
	}
}