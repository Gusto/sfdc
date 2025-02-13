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
private class UR_OptOutCtrl_Test {
	static testMethod void OptOutCtrlTest() {
		// TO DO: implement unit test
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		UR_TestDataUtil.createResearchConfig();
		Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Project');
		//Create Contact
		List<Contact> lstTestContact = UR_TestDataUtil.createContact(1);
		//Create Project Participant
		UR_TestDataUtil.createProjectParticipantTest(projectObj, lstTestContact);

		//get Optout code from Contact
		List<Contact> lstCon = [SELECT UXR_Email_Code__c FROM Contact WHERE Id = :lstTestContact[0].Id LIMIT 1];

		ApexPages.CurrentPage().getparameters().put('optoutcode', lstCon[0].UXR_Email_Code__c);
		UR_OptOutCtrl objOpt = new UR_OptOutCtrl();
		objOpt.UnsubcribeEmail();
	}
}