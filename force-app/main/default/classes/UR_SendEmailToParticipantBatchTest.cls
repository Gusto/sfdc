/**
 * @name         UR_SendEmailToParticipantBatchTest
 * @author       Bhagat Singh
 * @date         18 Oct 2021
 * @description  Test class for UR_SendEmailToParticipantBatch class.
 **/
@isTest
private class UR_SendEmailToParticipantBatchTest {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		UR_TestDataUtil.createResearchConfig();
		UR_TestDataUtil.createEmailMapping();
		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contacts = UR_TestDataUtil.createContact(1);
		Research_Project_Master__c objProject = UR_TestDataUtil.createResearchProjectMaster('Test Case 01');
		UR_TestDataUtil.createProjectParticipantTest(objProject, list_Contacts);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Send Email to participants : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testSendEmailPositiveUserCase() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		List<Research_Project_Detail__c> list_Participants = [
			SELECT Id
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id
		];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);
		for (UR_ManageParticipantCtrl.ContactWrapper objCW : objController.lstContactWrapper) {
			objCW.selContact = true;
		}

		objController.RedirectToSendEmail();
		objController.strPartStatus = 'Send survey or screener';
		objController.RetriveEmailTemplate();
		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}

		objController.sendEmail();

		Test.stopTest();
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_Msgs = [
			SELECT RelatedToId
			FROM EmailMessage
			WHERE
				RelatedToId IN (
					SELECT Id
					FROM Research_Project_Detail__c
					WHERE Research_Project_Master__c = :objProject.Id
				)
			];
			System.assert(list_Msgs.size() > 0);
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Send Email to participants : Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testSendEmailNegativeUserCase() {
		Test.startTest();
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		if (list_Projects != null && list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		List<Research_Project_Detail__c> list_Participants = [
			SELECT Id
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id
		];

		ApexPages.StandardController objStdCon = new ApexPages.StandardController(objProject);
		ApexPages.currentPage().getParameters().put('id', objProject.Id);
		UR_ManageParticipantCtrl objController = new UR_ManageParticipantCtrl(objStdCon);

		objController.RedirectToSendEmail();
		objController.strPartStatus = 'Send survey or screener';
		objController.RetriveEmailTemplate();
		if (objController.list_SelectedEmailtemplates.size() > 1) {
			objController.strSelectEmailId = objController.list_SelectedEmailtemplates[1].getValue();
		}

		objController.sendEmail();

		Test.stopTest();

		List<EmailMessage> list_Msgs = [
			SELECT RelatedToId
			FROM EmailMessage
			WHERE
				RelatedToId IN (
					SELECT Id
					FROM Research_Project_Detail__c
					WHERE Research_Project_Master__c = :objProject.Id
				)
		];
		System.assert(list_Msgs.size() == 0);
	}
}