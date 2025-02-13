public class UR_EmailMappingCtrl {
	public List<String> emailTempList;
	public String selectedStatus { get; set; }
	public list<EmailTemplateWrapper> EmailTemplateWrapperList { get; set; }

	public UR_EmailMappingCtrl() {
		EmailTemplateWrapperList = new List<EmailTemplateWrapper>();
		emailTempList = new List<String>();
		RetriveEmailTemplate();
	}
	// populating CTA status
	public List<selectOption> getPopulateCTAStatusPicklist() {
		List<selectOption> options = new List<selectOption>();
		options.addAll(UR_UtilityCtrl.getEmailStatusList());
		return options;
	}
	public void RetriveEmailTemplate() {
		emailTempList = new List<String>();
		for (EmailTemplate objEmail : [SELECT id, name FROM EmailTemplate WHERE Folder.DeveloperName = 'UX_Research' AND IsActive = TRUE ORDER BY name ASC]) {
			EmailTemplateWrapperList.add(new EmailTemplateWrapper(objEmail));
		}
	}
	public pagereference CreateStatusTemplate() {
		if (selectedStatus == null) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please Select a Status'));
			return null;
		}
		list<Research_Email_Template__c> mangeEmailTemplateList = new List<Research_Email_Template__c>();
		for (EmailTemplateWrapper etw : EmailTemplateWrapperList) {
			if (etw.selct == true) {
				Research_Email_Template__c met = new Research_Email_Template__c();
				met.Email_Template__c = etw.etemplate.id;
				met.Email_Template_Name__c = etw.etemplate.name;
				met.Status__c = selectedStatus;
				mangeEmailTemplateList.add(met);
			}
		}
		if (mangeEmailTemplateList.size() > 0 && mangeEmailTemplateList != null) {
			//Delete Existing
			delete [SELECT id, Status__c FROM Research_Email_Template__c WHERE Status__c = :selectedStatus];
			insert mangeEmailTemplateList;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'Successfully updated'));
		} else {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Select template to Map'));
		}
		return null;
	}
	public void selectstatus() {
		set<string> setExistingTempId = new Set<string>();
		List<Research_Email_Template__c> templatelist = [
			SELECT id, Status__c, Email_Template__c
			FROM Research_Email_Template__c
			WHERE Status__c = :selectedStatus
		];

		for (Research_Email_Template__c met : templatelist) {
			string st = met.Email_Template__c + '~' + met.Status__c;
			setExistingTempId.add(st);
		}
		//Update Email wrapper based on selected value
		for (EmailTemplateWrapper etw : EmailTemplateWrapperList) {
			string st1 = etw.etemplate.Id + '~' + selectedStatus;
			etw.selct = false;
			if (setExistingTempId != null && setExistingTempId.contains(st1) == true) {
				etw.selct = true;
			}
		}
	}
	public PageReference CreateNewTemplate() {
		string folderId = null;
		//Get Folder for UX Research
		List<Folder> folderlist = [
			SELECT ID, DeveloperName, Name
			FROM Folder
			WHERE DeveloperName = 'UX_Research' AND (Type = 'Email' OR Type = 'EmailTemplate')
		];
		if (folderlist.size() > 0) {
			folderId = folderlist[0].id;
		}
		PageReference pageRef = new PageReference('/' + folderId);
		return pageRef;
	}
	public class EmailTemplateWrapper {
		public boolean selct { get; set; }
		public EmailTemplate etemplate { get; set; }
		public EmailTemplateWrapper(EmailTemplate et) {
			selct = false;
			etemplate = et;
		}
	}
}