/*  
        @CreaedBy     ::: Prashant Bhatt (Lirik)
        @CreatedDate  ::: 09/12/2019
        Desc          ::: Test Class for PrivacyRequestSendDataExt Class.  Page Used -PrivacyRequestSendData.

*/

@isTest
public with sharing class PrivacyRequestSendDataExtTest {
	@isTest
	public static void testPrivacyRequestEmailData() {
		//create a account, case and data collection record.
		Account acc = TestUtility.CompanyAccount();

		//BusinessHours bnHrs = [Select id from BusinessHours where TimeZoneSidKey ='America/Los_Angeles'];

		test.startTest();

		Case cse1 = new Case();
		cse1.RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request');

		cse1.Subject = 'Test Privacy Request';
		cse1.Description = 'Test Relation';
		cse1.Type = 'Benefits Care';
		cse1.Origin = 'Email';
		cse1.status = 'Ready to Disclose';
		cse1.Privacy_Requester_First_Name__c = 'testFirstName';
		cse1.Privacy_Requester_Last_Name__c = 'testLastName';
		cse1.Privacy_Requester_Data__c = 'testPrivacydata';
		cse1.Privacy_Requester_Email__c = 'test@test.com';
		//cse1.BusinessHoursId = bnHrs.id;
		cse1.CreatedDate = system.today();
		cse1.Date_Time_Solved__c = system.now().addHours(6);
		cse1.Routing_Case_Reason__c = 'Test Reason';
		insert cse1;

		Data_Collection__c dc = new Data_Collection__c();
		dc.Case__c = cse1.Id;
		dc.Exclude_From_Disclosure__c = false;
		dc.Data_Use_Case__c = 'Raw Leads';
		insert dc;

		ContentVersion cv = new ContentVersion(Title = 'Test', PathOnClient = 'Test.jpg', VersionData = blob.valueof('Test Content Data'), IsMajorVersion = true);
		insert cv;

		ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
		List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

		ContentDocumentLink contentlink = new ContentDocumentLink();
		contentlink.LinkedEntityId = dc.id;
		contentlink.ShareType = 'i';
		contentlink.ContentDocumentId = documents[0].Id;
		contentlink.Visibility = 'AllUsers';
		insert contentlink;

		//call the extension controller
		ApexPages.StandardController sc = new ApexPages.StandardController(cse1);
		PrivacyRequestSendDataExt testPrivacyData = new PrivacyRequestSendDataExt(sc);

		//provide the Visualforce page reference
		PageReference pageRef = Page.PrivacyRequestSendData;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('Id', String.valueOf(cse1.Id));

		testPrivacyData.sendData();
		List<Case> cases = [SELECT Id, (SELECT parentId, FromAddress, ToAddress FROM EmailMessages) FROM Case WHERE Id = :cse1.Id];
		System.assertEquals(cse1.Id, cases[0].EmailMessages[0].parentId);
		test.stopTest();
	}
}