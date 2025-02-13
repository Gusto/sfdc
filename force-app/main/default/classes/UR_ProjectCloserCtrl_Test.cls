/**
 * @name         UR_ProjectCloserCtrl_Test
 * @author       Bhagat Singh
 * @date         15 July 2021
 * @description  Test class for UR_ProjectCloserCtrl class.
 **/
@isTest
private class UR_ProjectCloserCtrl_Test {
	/**
	 * @Author      : Bhagat Singh
	 * @Description : Test Class setup method
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@testSetup
	static void setupData() {
		skipTrigger(true);
		UR_TestDataUtil.createResearchConfig();
		Research_Project_Master__c objProject = UR_TestDataUtil.createResearchProjectMaster('Test Project');
		List<Contact> list_Contacts = UR_TestDataUtil.createContact(2);
		UR_TestDataUtil.ReturnParticipantListTest(objProject, list_Contacts);
		skipTrigger(false);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Update participant status.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testUpdateParticipantStatus() {
		Test.startTest();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		if (list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}
		List<Research_Project_Detail__c> list_ProjectDetails = [
			SELECT Id, Research_Participant_Status__c
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id
		];

		ApexPages.CurrentPage().getParameters().put('projectId', objProject.Id);
		ApexPages.StandardController objSC = new ApexPages.StandardController(objProject);
		UR_ProjectCloserCtrl objProjectCloser = new UR_ProjectCloserCtrl(objSC);
		objProjectCloser.searchString = 'Test';
		objProjectCloser.searchParticipantFromList();
		objProjectCloser.fetchProjectDetails(true);
		objProjectCloser.backToProject();
		objProjectCloser.isReasonExist();
		for (
			UR_ProjectCloserCtrl.ResearchProjectDetailWrapper objWrapper : objProjectCloser.lstResearchProjectDetailWrapper
		) {
			objWrapper.isInlineEdit = true;
			objWrapper.flag = true;
		}
		objProjectCloser.saveProjectDetails();
		objProjectCloser.sortParticipantList();
		ApexPages.CurrentPage().getparameters().put('strPartId', list_ProjectDetails[0].Id);
		objProjectCloser.updateGiftCardStatus();
		objProjectCloser.updateIncentiveStatus();
		objProjectCloser.rejectRequest();
		objProjectCloser.approveRequest();
		objProjectCloser.first();
		objProjectCloser.next();
		objProjectCloser.previous();
		objProjectCloser.last();
		objProjectCloser.getTotalRecord();
		objProjectCloser.getTotalPages();
		objProjectCloser.selectedStatus = 'Attended';
		objProjectCloser.UpdatePartDetail();

		Test.stopTest();

		list_ProjectDetails = [
			SELECT Id, Research_Participant_Status__c
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id
		];
		System.assert(list_ProjectDetails[0].Research_Participant_Status__c == 'Attended');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Allow incetive to mulitple Participant.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testAllowIncentive() {
		Test.startTest();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		if (list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		ApexPages.CurrentPage().getParameters().put('projectId', objProject.Id);
		ApexPages.StandardController objSC = new ApexPages.StandardController(objProject);
		UR_ProjectCloserCtrl objProjectCloser = new UR_ProjectCloserCtrl(objSC);
		for (
			UR_ProjectCloserCtrl.ResearchProjectDetailWrapper objWrapper : objProjectCloser.lstResearchProjectDetailWrapper
		) {
			objWrapper.isInlineEdit = true;
			objWrapper.flag = true;
		}
		objProjectCloser.selectedStatus = 'Attended';
		objProjectCloser.UpdatePartDetail();
		objProjectCloser.countAttendedParticipant();
		objProjectCloser.intMultiIncentive = 50;
		objProjectCloser.allowIncentive();

		Test.stopTest();

		List<Research_Project_Detail__c> list_ProjectDetails = [
			SELECT Id, Proposed_Incentive__c
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c = :objProject.Id
		];
		System.assert(list_ProjectDetails[0].Proposed_Incentive__c == 50);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Add notes on project closer tab.
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testAddNotes() {
		Test.startTest();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		if (list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		ApexPages.CurrentPage().getParameters().put('projectId', objProject.Id);
		ApexPages.StandardController objSC = new ApexPages.StandardController(objProject);
		UR_ProjectCloserCtrl objProjectCloser = new UR_ProjectCloserCtrl(objSC);
		objProjectCloser.AddNote();
		objProjectCloser.CancelNote();
		objProjectCloser.AddNote();
		objProjectCloser.objNote.Body = 'My first notes';
		objProjectCloser.SaveNotes();

		Test.stopTest();

		List<Note> list_Notes = [
			SELECT Id
			FROM Note
			WHERE ParentId = :objProject.Id AND Title LIKE '%-Result'
			LIMIT 1
		];
		System.assert(list_Notes.size() > 0);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Send Incentive Approval Request
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	static testMethod void testIncentiveApprovalRequest() {
		Test.startTest();
		List<Research_Project_Master__c> list_Projects = [SELECT Id FROM Research_Project_Master__c];
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		if (list_Projects.size() > 0) {
			objProject = list_Projects[0];
		}

		ApexPages.CurrentPage().getParameters().put('projectId', objProject.Id);
		ApexPages.StandardController objSC = new ApexPages.StandardController(objProject);
		UR_ProjectCloserCtrl objProjectCloser = new UR_ProjectCloserCtrl(objSC);
		for (
			UR_ProjectCloserCtrl.ResearchProjectDetailWrapper objWrapper : objProjectCloser.lstResearchProjectDetailWrapper
		) {
			objWrapper.isInlineEdit = true;
			objWrapper.flag = true;
		}
		objProjectCloser.selectedStatus = 'Attended';
		objProjectCloser.UpdatePartDetail();
		objProjectCloser.countAttendedParticipant();
		objProjectCloser.intMultiIncentive = 50;
		objProjectCloser.allowIncentive();

		UR_IncentiveApprovalProcess objApprovalProcess = new UR_IncentiveApprovalProcess();
		objApprovalProcess.sendApprovalEmail();

		Test.stopTest();

		list_Projects = [SELECT Id, Incentive_Approval_Status__c FROM Research_Project_Master__c];
		System.assert(list_Projects[0].Incentive_Approval_Status__c == 'In progress');
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip Trigger, which is not required for this functionality
	 * @Parm        : Boolean
	 * @Return      : N/A
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		ContactTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
	}
}