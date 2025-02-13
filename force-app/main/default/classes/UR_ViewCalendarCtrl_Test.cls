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
private class UR_ViewCalendarCtrl_Test {

    static testMethod void ViewCalendarTest() {
        // TO DO: implement unit test
         ContactTriggerHelper.skipTrigger = true;
		 AccountTriggerHelper.skipTrigger=true;
         UR_TestDataUtil.createResearchConfig();
         Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Project');
         //Create Contact 
         List<Contact> lstTestContact=UR_TestDataUtil.createContact(3);
         //Create Project Participant
         List<Research_Project_Detail__c> lstPartDetail=UR_TestDataUtil.ReturnParticipantListTest(projectObj,lstTestContact);
         //Create Notes
         UR_TestDataUtil.createProjectNotesTest(projectObj,3);
         //Create Event
         List<Event> eventList=UR_TestDataUtil.createParticipantEventTest(lstPartDetail);
         
         //Create Note for 
         ApexPages.CurrentPage().getparameters().put('projectId',projectObj.id);
         ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
         UR_ViewCalendarCtrl uv=new UR_ViewCalendarCtrl(sc);
         uv.objNote.Body='test Body';
         uv.AddNote();
         uv.SaveNotes();
         uv.CancelNote();
         uv.eventdata();
         uv.BackToProjectVF();
         ApexPages.currentPage().getParameters().put('currentEventId',eventList[0].Id);
         uv.getobjEventWrapper();
         uv.updateViewCalendarDate();
    }
    
}