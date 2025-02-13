/*  
        @CreaedBy     ::: Prashant Bhatt (Lirik)
        @CreatedDate  ::: 09/12/2019
        Desc          ::: Test Class for PrivacyRequestRegenera Class.  Page Used -PrivacyRequestSendData.

*/
@isTest
public with sharing class PrivacyRequestRegenerateCodeExtTest {
	@isTest
	public static void testPrivacyRequestRegenaredCode() {
		//create a account, case and data collection record.
		Account acc = TestUtility.CompanyAccount();

		//BusinessHours bnHrs = [Select id from BusinessHours where TimeZoneSidKey ='America/Los_Angeles'];

		test.startTest();

		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request');

		cse.Subject = 'Test Privacy Request';
		cse.Description = 'Test Relation';
		cse.Type = 'Benefits Care';
		cse.Origin = 'Email';
		cse.status = 'Ready to Disclose';
		cse.Privacy_Requester_First_Name__c = 'testFirstName';
		cse.Privacy_Requester_Last_Name__c = 'testLastName';
		cse.Privacy_Requester_Data__c = 'testPrivacydata';
		cse.Privacy_Requester_Email__c = 'test@test.com';
		//cse.BusinessHoursId = bnHrs.id;
		cse.CreatedDate = system.today();
		cse.Date_Time_Solved__c = system.now().addHours(6);
		cse.Routing_Case_Reason__c = 'Test Reason';
		insert cse;

		//call the extension controller
		ApexPages.StandardController sc = new ApexPages.StandardController(cse);
		PrivacyRequestRegenerateCodeExt testPRRegeneratedCode = new PrivacyRequestRegenerateCodeExt(sc);

		//provide the Visualforce page reference
		PageReference pageRef = Page.PrivacyRequestRegenerateCode;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('Id', String.valueOf(cse.Id));
		testPRRegeneratedCode.regenerateCode();
		List<Case> cases = [SELECT Id, (SELECT parentId, FromAddress, ToAddress FROM EmailMessages) FROM Case WHERE Id = :cse.Id];

		System.assertEquals(cse.Id, cases[0].EmailMessages[0].parentId);

		test.stopTest();
	}
}