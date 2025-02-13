/**
 * @name         : ServiceConsoleCaseTimerCtrlTest
 * @author       : Sean DesMarteau
 * @date         : 04-04-2022
 * @description  : Test class for ServiceConsoleCaseTimerCtrl Apex Class
 * @test classes : ServiceConsoleCaseTimerCtrlTest
 **/
@isTest
public with sharing class ServiceConsoleCaseTimerCtrlTest {
	public static Integer generateRandomId() {
		return Integer.valueOf(10000000 + Math.rint(Math.random() * 90000000));
	}

	@testSetup
	static void setup() {
		// Create Company Accounts
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('TEST ACCOUNT')
			.setZPCompanyId(String.valueOf(generateRandomId()))
			.setJoinedDate(System.today())
			.build();

		insert objAccount;

		// Create Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('TEST CONTACT')
			.setLastName('CONTACT')
			.setPhone('1234567890')
			.setEmail('test.contact@gusto.com')
			.setZPUserId(String.valueOf(generateRandomId()))
			.build();

		insert objContact;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setSubject('Payroll Care Case')
			.setDescription('Payroll Care Case')
			.setType('Payroll Care')
			.setOrigin('Email')
			.setDirection('Inbound')
			.build();

		insert objCase;
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Test class for ServiceConsoleCaseTimerCtrl.updateCaseSessionTime method
	 **/
	@isTest
	static void updateCaseSessionTimeTest() {
		Case objCase = [SELECT Id, Handle_Time_Seconds_New__c FROM Case WHERE Subject = 'Payroll Care Case'];
		System.assertEquals(null, objCase.Handle_Time_Seconds_New__c, 'Handle Time is Null');

		Test.startTest();
		List<Case> list_Cases = ServiceConsoleCaseTimerCtrl.updateCaseSessionTime(objCase.Id, '00:01:00');

		System.assertEquals(60, list_Cases[0].Handle_Time_Seconds_New__c, 'Handle Time is incorrect');

		list_Cases = ServiceConsoleCaseTimerCtrl.updateCaseSessionTime(objCase.Id, '00:01:00');
		System.assertEquals(120, list_Cases[0].Handle_Time_Seconds_New__c, 'Handle Time is incorrect');
		Test.stopTest();
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Test class for ServiceConsoleCaseTimerCtrl.grabCaseStatus method
	 **/
	@isTest
	static void grabCaseStatusTest() {
		Case objCase = [SELECT Id, Status FROM Case WHERE Subject = 'Payroll Care Case'];
		String strStatus = ServiceConsoleCaseTimerCtrl.grabCaseStatus(objCase.Id);

		System.assertEquals('New', objCase.Status);
	}
}