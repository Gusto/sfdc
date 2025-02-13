/*  
        @CreaedBy     ::: Prashant Bhatt (Lirik)
        @CreatedDate  ::: 11/12/2019
        Desc          ::: test class for PrivacyRequestsPortalCtrl class. Page Used  -PrivacyRequestsPortal   
*/
@isTest
public with sharing class PrivacyRequestsPortalCtrlTest {
	@isTest
	public static void testPrivacyFRequestsPortal() {
		//create a account, case and data collection record.
		Account acc = TestUtility.CompanyAccount();

		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request');
		objCase.Type = 'Benefits Care';
		objCase.Request_Type__c = 'Deletion';
		objCase.Origin = 'Email';
		objCase.Privacy_Request_Info_Confirmation__c = false;
		objCase.Privacy_Request_Deletion_Confirmation__c = true;
		objCase.Status = 'Request Denied';
		objCase.Status_Detail__c = 'Location';
		objCase.Privacy_Requester_First_Name__c = 'testFirstName';
		objCase.Privacy_Requester_Last_Name__c = 'testLastName';
		objCase.Privacy_Requester_Data__c = 'testPrivacydata';
		objCase.Privacy_Requester_Email__c = 'test@test.com';
		objCase.CreatedDate = system.today();
		objCase.Date_Time_Solved__c = system.now().addHours(6);
		objCase.Routing_Case_Reason__c = 'Test Reason';
		insert objCase;

		Test.startTest();
		String action = EncodingUtil.base64Encode(Blob.valueOf('testcookie'));
		Cookie cookie = new Cookie('prAuth', action, null, 31536000, false);

		PageReference pageRef = Page.PrivacyRequestsPortal;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('id', String.valueOf(objCase.Id));
		ApexPages.currentPage().setCookies(new List<Cookie>{ cookie });

		PrivacyRequestsPortalCtrl privacyRequestsPortalTestobj = new PrivacyRequestsPortalCtrl();
		privacyRequestsPortalTestobj.requestCase = objCase;
		privacyRequestsPortalTestobj.blobFile = blob.valueOf('blobtestvalue');
		privacyRequestsPortalTestobj.validateCookie();
		privacyRequestsPortalTestobj.toggleShowInformation();
		privacyRequestsPortalTestobj.toggleSubmitButton();

		privacyRequestsPortalTestobj.strFileName = 'testcontentfilename';
		privacyRequestsPortalTestobj.blobFile = Blob.valueof('blobtestversion');

		privacyRequestsPortalTestobj.uploadFile2();
		privacyRequestsPortalTestobj.save();
		privacyRequestsPortalTestobj.saveAndSubmit();
		Test.stopTest();
	}
	@isTest
	public static void testPrivacyFRequestsPortal1() {
		//create a account, case and data collection record.
		Account acc = TestUtility.CompanyAccount();

		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request');
		objCase.Type = 'Benefits Care';
		objCase.Request_Type__c = 'Disclosure';
		objCase.Origin = 'Email';
		objCase.Privacy_Request_Info_Confirmation__c = true;
		objCase.Privacy_Request_Deletion_Confirmation__c = true;
		objCase.Status = 'Ready to Disclose';
		objCase.Privacy_Requester_First_Name__c = 'testFirstName';
		objCase.Privacy_Requester_Last_Name__c = 'testLastName';
		objCase.Privacy_Requester_Data__c = 'testPrivacydata';
		objCase.Privacy_Requester_Email__c = 'test@test.com';
		objCase.CreatedDate = system.today();
		objCase.Date_Time_Solved__c = system.now().addHours(6);
		objCase.Routing_Case_Reason__c = 'Test Reason';
		insert objCase;

		Test.startTest();
		PageReference pageRef = Page.PrivacyRequestsPortal;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('id', String.valueOf(objCase.Id));

		PrivacyRequestsPortalCtrl privacyRequestsPortalTestobj = new PrivacyRequestsPortalCtrl();
		privacyRequestsPortalTestobj.requestCase = objCase;
		privacyRequestsPortalTestobj.blobFile = blob.valueOf('blobtestvalue');
		//validate Cookie method test for actual page reference vs return page reference
		PageReference returnPageUrl = privacyRequestsPortalTestobj.validateCookie();
		PageReference expectedPage = new PageReference('/apex/PrivacyRequestsPortalEntrance');
		System.assertEquals(expectedPage.getUrl(), returnPageUrl.getUrl());

		privacyRequestsPortalTestobj.toggleShowInformation();
		privacyRequestsPortalTestobj.toggleSubmitButton();

		privacyRequestsPortalTestobj.strFileName = 'testcontentfilename';
		privacyRequestsPortalTestobj.blobFile = Blob.valueof('blobtestversion');

		privacyRequestsPortalTestobj.uploadFile();
		privacyRequestsPortalTestobj.save();
		privacyRequestsPortalTestobj.saveAndSubmit();

		privacyRequestsPortalTestobj.boolIsDelete = true;
		privacyRequestsPortalTestobj.save();
		privacyRequestsPortalTestobj.saveAndSubmit();

		Test.stopTest();
	}

	@isTest
	public static void testPrivacyFRequestsPortalException() {
		//create a account, case and data collection record.
		Account acc = TestUtility.CompanyAccount();

		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Privacy Request');
		objCase.Type = 'Benefits Care';
		objCase.Request_Type__c = 'Disclosure';
		objCase.Origin = 'Email';
		objCase.Privacy_Request_Info_Confirmation__c = true;
		objCase.Privacy_Request_Deletion_Confirmation__c = true;
		objCase.Status = 'Request Denied';
		objCase.Privacy_Requester_First_Name__c = 'testFirstName';
		objCase.Privacy_Requester_Last_Name__c = 'testLastName';
		objCase.Privacy_Requester_Data__c = 'testPrivacydata';
		objCase.Privacy_Requester_Email__c = 'test@test.com';
		objCase.CreatedDate = system.today();
		objCase.Date_Time_Solved__c = system.now().addHours(6);
		objCase.Routing_Case_Reason__c = 'Test Reason';
		insert objCase;

		Test.startTest();
		PageReference pageRef = Page.PrivacyRequestsPortal;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('id', String.valueOf(objCase.Id));

		PrivacyRequestsPortalCtrl privacyRequestsPortalTestobj = new PrivacyRequestsPortalCtrl();
		objCase.Status = 'Request_Denied';
		privacyRequestsPortalTestobj.requestCase = objCase;
		privacyRequestsPortalTestobj.blobFile = blob.valueOf('blobtestvalue');
		//validate Cookie method test for actual page reference vs return page reference
		PageReference returnPageUrl = privacyRequestsPortalTestobj.validateCookie();
		PageReference expectedPage = new PageReference('/apex/PrivacyRequestsPortalEntrance');
		System.assertEquals(expectedPage.getUrl(), returnPageUrl.getUrl());

		privacyRequestsPortalTestobj.boolInfoConfirm = false;
		privacyRequestsPortalTestobj.toggleShowInformation();
		privacyRequestsPortalTestobj.toggleSubmitButton();

		privacyRequestsPortalTestobj.strFileName = 'testcontentfilename';
		privacyRequestsPortalTestobj.blobFile = Blob.valueof('blobtestversion');
		privacyRequestsPortalTestobj.save();
		privacyRequestsPortalTestobj.saveAndSubmit();

		Test.stopTest();
	}
}