/**
Created by : Robin
Created Date : 7/19/2017
**/
@isTest
public class OppRelatedTrackTriggerHelperTest {
	@testsetup
	static void setupTetData() {
		list<UserRole> roleList = [SELECT id FROM UserRole WHERE Name = 'sales_sdr_partner_xx' LIMIT 1];

		Id idUserRole;

		if (roleList != null && roleList.size() > 0)
			idUserRole = roleList.get(0).id;

		User objMdrUser = new TestDataFactory.UserBuilder()
          .setUserName('gusto2@Submission.gusto')
          .setExemptfromValidationRules(true)
          .setProfileId(UserInfo.getProfileId())
          .setIsActive(true)
          .setEmail('mdruser@testorg.com')
		  .setFirstName('mdr test fname')
		  .setLastName('mdr test lname')
		  .setUserRoleId(idUserRole)
          .build(); 
		
		insert objMdrUser;
	}

	static testMethod void newRecInsertTrigger() {
		list<User> usrList = [SELECT id FROM User WHERE UserRole.Name = 'sales_sdr_partner_xx' AND FirstName = 'mdr test fname' AND IsActive = TRUE];

		OpportunityTriggerHelper.skipTrigger = true;

		Opportunity oppRec = TestUtility.BenefitsRenewalOpportunity();
		oppRec.StageName = 'New';
		OpportunityTriggerHelper.skipTrigger = false;

		update oppRec;

		test.startTest();
		System.runAs(usrList.get(0)) {
			Task t = new Task(WhatId = oppRec.Id, RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call').getRecordTypeId(), Type = 'Outbound Call');
			insert t;

			System.assertEquals(1, [SELECT COUNT() FROM Opportunity_Related_Tracking__c]);
		}
		test.stopTest();

		delete [SELECT Id FROM Opportunity_Related_Tracking__c LIMIT 1];
	}
}