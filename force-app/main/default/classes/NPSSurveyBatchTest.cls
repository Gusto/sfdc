/*
@Author -Midhuna KB
@CreateDate 27-01-2021
@Description - Test class for NPSSurveyBatch
*/
@isTest
public with sharing class NPSSurveyBatchTest {
	@testSetup
	static void setUp() {
		Account objAccount = TestUtility.CompanyAccount();
		List<Contact> lst_Contacts = new List<Contact>();
		objAccount.Firm_Inactive__c = false;
		objAccount.Joined_Date_Panda__c = System.today();
		objAccount.ZP_Company_Overall_Status__c = 'Active';
		objAccount.RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID;
		AccountTriggerHelper.skipTrigger = true;
		update objAccount;

		//Insert Contact record
		Contact objContact1 = new Contact();
		objContact1.LastName = 'Test Contact 1';
		objContact1.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact1.AccountId = objAccount.Id;
		objContact1.Email = 'testuser1email@abccompany.com';
		objContact1.ZP_Phone__c = '9687777771';
		objContact1.Session_Id__c = 'testSesssionId';
		objContact1.Is_UX_Active__c = true;
		objContact1.ZP_User_Role__c = 'Payroll Admin';
		objContact1.NPS_Survey_Date__c = System.today();
		lst_Contacts.add(objContact1);

		Contact objContact2 = new Contact();
		objContact2.LastName = 'Test Contact 2';
		objContact2.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact2.AccountId = objAccount.Id;
		objContact2.Email = 'testuser2email@abccompany.com';
		objContact2.ZP_Phone__c = '9687777772';
		objContact2.Session_Id__c = 'testSesssionId';
		objContact2.Is_UX_Active__c = true;
		objContact2.ZP_User_Role__c = 'Accountant';
		objContact2.NPS_Survey_Date__c = System.today();
		lst_Contacts.add(objContact2);

		//does not meet criteria
		Contact objContact3 = new Contact();
		objContact3.LastName = 'Test Contact 3';
		objContact3.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact3.AccountId = objAccount.Id;
		objContact3.Email = 'testuser3email@abccompany.com';
		objContact3.ZP_Phone__c = '9687777773';
		objContact3.Session_Id__c = 'testSesssionId';
		objContact3.Is_UX_Active__c = false;
		objContact3.ZP_User_Role__c = 'Employee';
		objContact3.NPS_Survey_Date__c = System.today();
		objContact3.HasOptedOutOfEmail = true;
		objContact3.Survey_Opt_Out__c = true;
		lst_Contacts.add(objContact3);

		Contact objContact4 = new Contact();
		objContact4.LastName = 'Test Contact 4';
		objContact4.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact4.AccountId = objAccount.Id;
		objContact4.Email = 'testuser4email@abccompany.com';
		objContact4.ZP_Phone__c = '9687777774';
		objContact4.Session_Id__c = 'testSesssionId';
		objContact4.Is_UX_Active__c = true;
		objContact4.ZP_User_Role__c = 'Employee';
		objContact4.NPS_Survey_Date__c = System.today();
		lst_Contacts.add(objContact4);

		//does not meet criteria
		Contact objContact5 = new Contact();
		objContact5.LastName = 'Test Contact 5';
		objContact5.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact5.AccountId = objAccount.Id;
		objContact5.Email = 'testuser5email@abccompany.com';
		objContact5.ZP_Phone__c = '9687777775';
		objContact5.Session_Id__c = 'testSesssionId';
		objContact5.Is_UX_Active__c = false;
		objContact5.ZP_User_Role__c = 'Payroll Admin';
		objContact5.NPS_Survey_Date__c = System.today();
		objContact5.HasOptedOutOfEmail = true;
		objContact5.Survey_Opt_Out__c = true;

		lst_Contacts.add(objContact5);

		//test contact for survey date as null

		Contact objContact6 = new Contact();
		objContact6.LastName = 'Test Contact 6';
		objContact6.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
		objContact6.AccountId = objAccount.Id;
		objContact6.Email = 'testuser6email@abccompany.com';
		objContact6.ZP_Phone__c = '9687777776';
		objContact6.Session_Id__c = 'testSesssionId';
		objContact6.Is_UX_Active__c = false;
		objContact6.ZP_User_Role__c = 'Primary Payroll Admin';
		objContact6.HasOptedOutOfEmail = true;
		objContact6.Survey_Opt_Out__c = true;

		lst_Contacts.add(objContact6);

		insert lst_Contacts;
	}

	static testMethod void testNPSSurveyBatch() {
		Test.startTest();
		NPSSurveyJob job = new NPSSurveyJob();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		Contact[] list_Contacts = [SELECT Id, NPS_Survey_Criteria__c, NPS_Status__c, NPS_Customer_Category_Formula__c, NPS_Survey_Date__c FROM Contact WHERE NPS_Survey_Criteria__c = TRUE];
		Contact[] list_ContactNotMeetCriteria = [
			SELECT Id, Account.RecordTypeId, Account.Joined_Date_Panda__c, Account.Cohort_Date__c, LastName, NPS_Survey_Criteria__c, NPS_Status__c, NPS_Customer_Category_Formula__c, NPS_Survey_Date__c
			FROM Contact
			WHERE NPS_Survey_Criteria__c = FALSE
		];

		for (Contact objCont : list_Contacts) {
			System.assert(objCont.NPS_Status__c.Equals('Processed'));
		}

		for (Contact objCont : list_ContactNotMeetCriteria) {
			if (objCont.LastName != 'Test Contact 6') {
				//not new gustomers
				if (objCont.NPS_Customer_Category_Formula__c.contains('Employee')) {
					System.assertEquals(System.today().addMonths(12), objCont.NPS_Survey_Date__c, 'Employees should be pushed out a year from today -- ' + objCont.LastName);
				} else {
					System.assertEquals(System.today().addMonths(6), objCont.NPS_Survey_Date__c, 'Admins/Accountants should be pushed out 6 months from today -- ' + objCont.LastName);
				}
			} else {
				Date dtCaluclated = Date.Today();
				if (objCont.Account.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
					dtCaluclated = objCont.Account.Joined_Date_Panda__c;
				} else {
					dtCaluclated = objCont.Account.Cohort_Date__c;
				}
				//new gustomers
				System.assertEquals(objCont.NPS_Survey_Date__c >= dtCaluclated.addDays(90), true, 'Random generated more than 90 days for new Gustomers');
			}
		}
	}

	static testMethod void testPopulateSurveyRandomDate() {
		Contact objCon = [SELECT Id, Account.RecordTypeId, Account.RecordType.Name, Account.Joined_Date_Panda__c, Account.Cohort_Date__c FROM Contact LIMIT 1];

		Test.startTest();
		Date dtReturned = AccountUtil.populateSurveyRandomDate(objCon);
		Test.stopTest();

		System.assertEquals(dtReturned >= Date.today().addDays(90), true, 'Random generated more than 90 days for new Gustomers');
	}
}