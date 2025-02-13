/*  
        @CreaedBy     ::: Prashant Bhatt (Lirik)
        @CreatedDate  ::: 09/12/2019
        Desc          ::: Test Class for PrivacyRequestDisplayExt Class.  Page Used -PrivacyRequestDisplayData.

*/
@isTest
public with sharing class PrivacyRequestDisplayDataExtTest {
	@isTest
	public static void testPrivacyRequestDisplayData() {
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

		Data_Collection__c dc = new Data_Collection__c();
		dc.Case__c = cse.Id;
		dc.Exclude_From_Disclosure__c = false;
		dc.Details__c = 'test details testing content';
		insert dc;

		//create object for the extension class
		ApexPages.StandardController sc = new ApexPages.StandardController(cse);
		PrivacyRequestDisplayDataExt testDisplayData = new PrivacyRequestDisplayDataExt(sc);

		PageReference pageRef = Page.PrivacyRequestDisplayData;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('Id', String.valueOf(cse.Id));
		testDisplayData.displayData();
	}
}