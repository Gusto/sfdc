/**
 * @name         UR_ManageParticipantCtrl_Test
 * @author       Bhagat Singh
 * @date         14 Dec 2021
 * @description  Test class for UR_ManageParticipantCtrl class.
 **/
@isTest
private class UR_ManageParticipantCtrl_Test {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void createTestData() {
		UR_TestDataUtil.createResearchConfig();
		UR_TestDataUtil.createEmailMapping();
		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contacts = UR_TestDataUtil.createContact(2);
		Research_Project_Master__c objProject = UR_TestDataUtil.createResearchProjectMaster('Test Case 01');
		UR_TestDataUtil.createProjectParticipantTest(objProject, list_Contacts);

		Research_Schedule_Email__c objSCEmail = new Research_Schedule_Email__c();
		objSCEmail.Schedule_Email_Date__c = Date.today().addDays(1);
		objSCEmail.Schedule_Email_Time__c = '10';
		objSCEmail.UXR_Scout__c = objProject.Id;
		insert objSCEmail;

		List<EmailTemplate> list_Template = [SELECT Id, Name FROM EmailTemplate WHERE Folder.Name = 'UX Research' LIMIT 1];
		Research_Email_Template__c objEmailSetting = new Research_Email_Template__c();
		objEmailSetting.Email_Template__c = list_Template[0].Id;
		objEmailSetting.Email_Template_Name__c = list_Template[0].Name;
		objEmailSetting.Status__c = 'Send survey or screener';
		insert objEmailSetting;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Send Survey Email
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void sendSurveyEmailTest() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}
		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);
		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
		}

		objController.inviteToInterview();
		objController.initSendEmail();

		objController.sendFollowUp();
		objController.initSendEmail();

		objController.sendSurvey();
		objController.initSendEmail();

		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}

		objController.showPreview();

		if (list_Participants.size() > 0) {
			objController.strCurrentPartId = list_Participants[0].id;
			ApexPages.currentPage().getParameters().put('currentPartId', list_Participants[0].id);
		}

		objController.getobjEmailMsgWraper();
		objController.currentRecordId = objProject.Id + '';
		objController.PopulateSurveyResponse();
		objController.strSelectedQuestion = 'Ques_1';
		objController.DisplaysurveyTable();

		for (UR_ManageParticipantCtrl.surveyResponseWrapper objSRW : objController.lstSurveyResponseWrapper) {
			objSRW.selContact = true;
		}

		objController.RedirectToSendEmailFromSurvey();
		objController.UpdateReadEmailStatus();
		objController.emailReplyBody = 'Test';
		objController.ReplyEmail();
		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.objResProject.Research_Participant_Status__c = 'Reserved';
		}

		objController.RemoveParticipant();
		objController.inviteToInterviewFromSurvey();
		objController.sendFollowUpFromSurvey();
		objController.updateViewSurveyDate();
		ApexPages.currentPage().getParameters().put('strPartId', list_Participants[0].id);
		objController.resendEmail();

		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_Msgs = [SELECT RelatedToId FROM EmailMessage WHERE RelatedToId IN (SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id)];
			System.assert(list_Msgs.size() > 0);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Send Self Email
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void sendSelfEmailTest() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);

		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
			break;
		}

		objController.getTotalRecord();
		objController.getTotalPages();
		objController.first();
		objController.last();
		objController.previous();
		objController.next();

		objController.sendFollowUp();
		objController.initSendEmail();

		objController.sendSurvey();
		objController.initSendEmail();

		objController.inviteToInterview();
		objController.initSendEmail();

		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}
		objController.showPreview();
		objController.sendEmailToAll();
		objController.sendEmail();

		objController.RedirectToSendEmail();
		objController.scheduleEmail.Schedule_Email_Date__c = Date.today().addDays(1);
		objController.scheduleEmail.Schedule_Email_Time__c = '10';
		objController.strPartStatus = 'Send survey or screener';
		objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();

		objController.scheduleEmailToAll();
		objController.sendEmail();
		Id idProject = objController.objProject.Id;

		List<Research_Schedule_Email__c> scheduleEmailsList = [SELECT id, Schedule_Email_Date__c, Schedule_Email_Time__c FROM Research_Schedule_Email__c WHERE UXR_Scout__c = :idProject];
		if (scheduleEmailsList.size() > 0) {
			ApexPages.CurrentPage().getparameters().put('scheduleEmailId', scheduleEmailsList[0].Id);
		}

		objController.cancelScheduleEmail();
		objController.hideScheduleEmail();

		if (list_Participants.size() > 0) {
			objController.strCurrentPartId = list_Participants[0].id;
			ApexPages.currentPage().getParameters().put('currentPartId', list_Participants[0].id);
		}
		objController.getobjEmailMsgWraper();
		
		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
		}
		objController.RedirectToSendEmail();
		objController.strPartStatus = 'Send survey or screener';
		objController.sendFollowUp();
		objController.initSendEmail();
		objController.RetriveEmailTemplate();
		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}
		objController.sendEmailToSelf();
		objController.SendSelfEmail();

		objController.sortbyFieldAPIName = 'Contact__r.Email';
		objController.setSortingFilter();
		objController.setSortingFilter();
		//objController.sortlist_Participant();
		objController.cancelEditComment();
		objController.searchString = 'Test';
		objController.searchParticipantFromList();
		objController.selIncludeParticipant = 'From Salesforce search';
		objController.addParticipants();
		objController.viewEmail();
		objController.sendEmailParticipants();
		objController.sendEmailParticipantsNoCalendly();

		Test.stopTest();

		List<EmailMessage> list_Msgs = [SELECT RelatedToId FROM EmailMessage WHERE RelatedToId IN (SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id)];
		System.assert(list_Msgs.size() == 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Manage Participant Redirect
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void manageParticipantRedirect() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}
		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);

		objController.BackToProjectVF();
		objController.RedirectToViewEmail();
		objController.RedirectToManageProjectTeams();
		objController.RedirectToViewCalendar();
		objController.ViewSurvey();
		objController.BackToProject();
		objController.ManageContacts();
		objController.ManageContactsCSV();
		objController.RecordAttendance();
		objController.Downloadcsv();
		objController.sortParticipantList();
		objController.getEmailTagAPIName('{!Research_Project_Detail__c.Name}');
		Boolean blnFlag = objController.hasNext;
		blnFlag = objController.hasPrevious;

		Test.stopTest();

		list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];
		System.assert(list_Participants.size() > 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Remove Participant
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void removeParticipantTest() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}
		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);
		Integer intCount = 0;
		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			if (intCount == 0) {
				objCW.isEditComment = true;
				//objController.selectedRecord.put(objCW.objResProject.Id, objCW);
			} else {
				objCW.selContact = true;
			}
			intCount = intCount + 1;
		}

		ApexPages.currentPage().getParameters().put('strPartId', objController.lstContactWrapper[0].objResProject.Id);
		objController.updateNDAStatus();
		objController.selectedStatus = 'Attended';
		objController.UpdatePartDetail();
		objController.updateQualtricsId();

		if (list_Participants != null && list_Participants.size() > 0) {
			delete list_Participants;
		}

		Test.stopTest();

		list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];
		System.assert(list_Participants.size() == 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Save Email As Draft
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void saveEmailAsDraftTest() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		ApexPages.currentPage().getParameters().put('type', 'SS');

		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);

		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
			//objController.selectedRecord.put(objCW.objResProject.Id, objCW);
		}
		objController.strPartStatus = 'Send survey or screener';
		objController.sendFollowUp();
		objController.initSendEmail();
		objController.RetriveEmailTemplate();
		objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();

		objController.strDraftEmailNickName = 'First Draft Email';
		objController.saveEmailAsDraft();

		List<EmailTemplate> list_EmailsTemplate = [SELECT Id, Name, Body, HTMLValue, Subject FROM EmailTemplate WHERE Name LIKE 'First Draft Email%'];
		System.assert(list_EmailsTemplate.size() > 0);

		if (list_EmailsTemplate.size() > 0) {
			objController.strSelectDraftEmailId = list_EmailsTemplate[0].Id;
		}

		objController.showDraftEmail();
		objController.deleteDraftEmail();

		Test.stopTest();

		list_EmailsTemplate = [SELECT id, Name, Body, HTMLValue, Subject FROM EmailTemplate WHERE Name LIKE 'First Draft Email%'];
		System.assert(list_EmailsTemplate.size() == 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test ScheduleEmail
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void scheduleEmailTest() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		List<Research_Project_Detail__c> list_Participants = [SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :objProject.Id];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		ApexPages.currentPage().getParameters().put('type', 'SS');

		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);

		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
		}

		objController.strPartStatus = 'Send survey or screener';
		objController.sendFollowUp();
		objController.initSendEmail();
		objController.RetriveEmailTemplate();

		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}

		Date dtObj = Date.today().addDays(2);
		objController.scheduleEmail.Schedule_Email_Date__c = dtObj;
		objController.scheduleEmail.Schedule_Email_Time__c = '10';
		objController.sendEmail();

		objController.SendSelfEmail();

		Test.stopTest();

		List<Research_Schedule_Email__c> list_ScheduleEmail = [SELECT Id, Schedule_Email_Date__c FROM Research_Schedule_Email__c WHERE Schedule_Email_Date__c = :dtObj];
		System.assert(list_ScheduleEmail.size() > 0);
	}
}