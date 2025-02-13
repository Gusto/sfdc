/**
 * @description       : Test Class for Controller CaseRoutingEmailPublisherController
 * @author            : Pradeep Chary
 * @group             :
 * @last modified on  : 01-14-2021
 * @last modified by  : Pradeep Chary
 * Modifications Log
 * Ver   Date         Author            Modification
 * 1.0   01-14-2021   Pradeep Chary     Initial Version
 **/
@isTest
private class CaseRoutingEmailPublisherControllerTest {
	@testsetup
	static void setupTestData() {
		AccountTriggerHelper.skipTrigger = true;
		contactTriggerHelper.skipTrigger = true;
		ZPUserTriggerHelper.skipTrigger = true;
		ZPUserRoleTriggerHelper.skipTrigger = true;

		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Email__c = 'CaseRelatedTicketsController@gusto.com';
		zpUser.Created_At__c = Date.newInstance(2016, 11, 9);
		zpUser.Updated_At__c = Date.newInstance(2016, 12, 9);
		zpUser.Last_Sign_In_At__c = Date.newInstance(2018, 1, 1);
		zpUser.Id__c = '78787878123';
		insert zpUser;

		ZP_User_Role__c zpUserRole = new ZP_User_Role__c();
		zpUserRole.User_Id__c = '78787878123';
		zpUserRole.Company_id__c = '78787878';
		insert zpUserRole;

		Account acc = TestUtility.CompanyAccount();
		acc.ZP_Company_id__c = '78787878';
		update acc;

		Contact cont = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(acc.id)
			.setFirstName('Test')
			.setLastName('CaseRelatedTicketsController')
			.setZPUserId('78787878123')
			.setEmail('CaseRelatedTicketsController@gusto.com')
			.setPhone('7878787899')
			.build();
		insert cont;

		Case_Reason_Classification__c clas = new Case_Reason_Classification__c();
		clas.Type__c = 'Benefits Care';
		clas.Name = 'Routing Case Reason Classification';
		clas.Class__c = 'Class 1';
		clas.Reason_Code__c = 'State_Notice';
		clas.Active__c = true;
		clas.Auto_Email_Behavior__c = 'Recommend';
		clas.Email_Content__c = 'Test';
		insert clas;

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Benefits Care');
		cse.AccountId = acc.Id;
		cse.Routing_Case_Reason_Classification__c = clas.Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'Benefits Care';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'test.test1@test.com';
		cse.Authorized_User__c = 'No';
		insert cse;
	}

	@isTest
	static void testMethodPositive() {
		Test.startTest();
		Map<String, Map<Id, Case_Reason_Classification__c>> map_CaseReasons = CaseRoutingEmailPublisherController.queryReasons();
		System.assertNotEquals(0, map_CaseReasons.values().size(), 'Map cannot be null');
		Case record = [SELECT Id FROM Case LIMIT 1];
		Map<String, String> map_Response = CaseRoutingEmailPublisherController.getCaseInformation(record.Id);
		System.assertEquals(4, map_Response.size(), 'Expected four records');
		Test.stopTest();
	}

	@isTest
	static void testMethodNegative() {
		Test.startTest();
		Map<String, String> map_Response = CaseRoutingEmailPublisherController.getCaseInformation('Test');
		System.assertEquals(0, map_Response.size(), 'Expected no records');
		Test.stopTest();
	}
}