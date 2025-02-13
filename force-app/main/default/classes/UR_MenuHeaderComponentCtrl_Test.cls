/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UR_MenuHeaderComponentCtrl_Test {

    static testMethod void MenuHeaderComponentCtrlTest() {
        // TO DO: implement unit test
         // TO DO: implement unit test
         ContactTriggerHelper.skipTrigger = true;
		 AccountTriggerHelper.skipTrigger=true;
         UR_TestDataUtil.createResearchConfig();
         Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Project');
         //Create Contact 
         List<Contact> lstTestContact=UR_TestDataUtil.createContact(1);
         //Create Project Participant
         UR_TestDataUtil.createProjectParticipantTest(projectObj,lstTestContact);
         
         UR_MenuHeaderComponentCtrl objMenu=new UR_MenuHeaderComponentCtrl();
         objMenu.setprojectId(projectObj.id);
         objMenu.getprojectId();
         objMenu.mainTab='Project Details';
         objMenu.ManageMenu();
         objMenu.mainTab='Participants';
         objMenu.subTab='MP';
         objMenu.ManageMenu();
         objMenu.subTab='SS';
         objMenu.ManageMenu();
         objMenu.subTab='VSR';
         objMenu.ManageMenu();
         objMenu.subTab='ITI';
         objMenu.ManageMenu();
         objMenu.subTab='SFUI';
         objMenu.ManageMenu();
         objMenu.subTab='RA';
         objMenu.ManageMenu();
         objMenu.mainTab='Emails';
         objMenu.ManageMenu();
         objMenu.mainTab='Incentive Approval';
         objMenu.ManageMenu();
         objMenu.mainTab='Calendar';
         objMenu.ManageMenu();
         objMenu.mainTab='Help';
         objMenu.ManageMenu();
         objMenu.mainTab='Results';
         objMenu.subTab='RA';
         objMenu.ManageMenu();
         objMenu.subTab='VSR';
         objMenu.ManageMenu();
         objMenu.markProjectCompleted();
         objMenu.ReOpenProject();
         objMenu.RedirectToAttendance();
         objMenu.blankSendSurvey();
         objMenu.blankInviteToInterview();
         objMenu.blankSendFollowUp();
         objMenu.addParticipantsSearch();
         objMenu.addParticipantsCSV();
         objMenu.fetchProjectDetails();
         objMenu.resetApproval();
         objMenu.resetIncentiveApproval();
         objMenu.closeScheduleErrorMessage();
         objMenu.closeSendEmailErrorMessage();
         objMenu.closeCSVErrorMessage();
    }
}