/**
 * @name         : EmailToCaseRecoveryEmlSvc
 * @author       : Sean DesMarteau
 * @date         : 03-05-2021
 * @description  : Test class for EmailToCaseRecoveryEmlSvc
 * @test classes : EmailToCaseRecoveryEmlSvcTest
 **/
@isTest
private class EmailToCaseRecoveryEmlSvcTest {
	static testMethod void testEmailToCaseRecoverEmlSvcSuccess() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		String strBody =
			'---------- Forwarded message ---------' +
			'\n' +
			'From: \'support@salesforce.com\' via BizTech Dev <biztech-dev@gusto.com>' +
			'\n' +
			'Date: Fri, Mar 5, 2021 at 10:55 AM' +
			'\n' +
			'Subject: Sandbox: Email-to-Case: Error(s) encountered while processing' +
			'\n' +
			'To: biztech-dev@gusto.com <biztech-dev@gusto.com>' +
			'\n' +
			'\n' +
			'\n' +
			'The following errors were encountered while processing an incoming email:' +
			'\n' +
			'\n' +
			'CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY : EmailMessageTrigger: execution of AfterInsert' +
			'\n' +
			'\n' +
			'caused by: System.QueryException: List has no rows for assignment to SObject' +
			'\n' +
			'\n' +
			'Class.UserUtils.returnLoggedInUser: line 139, column 1' +
			'\n' +
			'Class.EmailMessageTriggerHelper.populateCaseType: line 1196, column 1' +
			'\n' +
			'Class.EmailMessageTriggerHelper.OnAfterInsert: line 66, column 1' +
			'\n' +
			'Trigger.EmailMessageTrigger: line 10, column 1' +
			'\n' +
			'\n' +
			'\n' +
			'From: john.doe@gusto.com' +
			'\n' +
			'(John Doe)' +
			'\n' +
			'Sent: Fri Mar 05 17:55:41 GMT 2021' +
			'\n' +
			'To: [support@gusto.com,' +
			'\n' +
			'success@gusto.com]' +
			'\n' +
			'Subject: TEST EMAIL TO CASE' +
			'\n' +
			'SPLIT SUBJECT' +
			'\n' +
			'\n' +
			'TESTING';

		email.subject = 'Email-to-Case: Error(s) encountered while processing';
		email.plainTextBody = strBody;

		env.fromAddress = 'support@salesforce.com';

		Test.startTest();
		EmailToCaseRecoveryEmlSvc obj = new EmailToCaseRecoveryEmlSvc();
		obj.handleInboundEmail(email, env);
		Test.stopTest();

		List<BizTech_Temp_Obj__c> list_TempObj = [
			SELECT Id, To_Address__c, Text_Body__c, Subject__c, From_Addresses__c, From_Name__c
			FROM BizTech_Temp_Obj__c
			LIMIT 1
		];

		System.assertEquals(1, list_TempObj.size());

		for (BizTech_Temp_Obj__c objBizTechTemp : list_TempObj) {
			System.assertEquals('john.doe@gusto.com', objBizTechTemp.From_Addresses__c);
			System.assertEquals('John Doe', objBizTechTemp.From_Name__c);
			System.assertEquals('support@gusto.com, success@gusto.com', objBizTechTemp.To_Address__c);
			System.assertEquals('TEST EMAIL TO CASE SPLIT SUBJECT', objBizTechTemp.Subject__c);
			System.assertEquals('TESTING', objBizTechTemp.Text_Body__c);
		}
	}

	static testMethod void testEmailToCaseRecoverEmlSvcFailure() {
		// Create a new email and envelope object.
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		// Test with the subject that matches the unsubscribe statement.
		String strBody =
			'The following errors were encountered while processing an incoming email:' +
			'\n' +
			'\n' +
			'CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY : EmailMessageTrigger: execution of AfterInsert' +
			'\n' +
			'\n' +
			'caused by: System.QueryException: List has no rows for assignment to SObject' +
			'\n' +
			'\n' +
			'Class.UserUtils.returnLoggedInUser: line 139, column 1' +
			'\n' +
			'Class.EmailMessageTriggerHelper.populateCaseType: line 1196, column 1' +
			'\n' +
			'Class.EmailMessageTriggerHelper.OnAfterInsert: line 66, column 1' +
			'\n' +
			'Trigger.EmailMessageTrigger: line 10, column 1' +
			'\n' +
			'\n' +
			'\n' +
			'From: john.doe@gusto.com(John Doe)' +
			'\n' +
			'Sent: Fri Mar 05 17:55:41 GMT 2021' +
			'\n' +
			'To: [support@gusto.com]' +
			'\n' +
			'Subject: TEST EMAIL TO CASE' +
			'\n' +
			'SPLIT SUBJECT' +
			'\n' +
			'\n' +
			'TESTING';

		email.subject = 'Email-to-Case: Error(s) encountered while processing';
		email.plainTextBody = strBody;

		env.fromAddress = 'support@salesforce.com';

		Test.startTest();
		EmailToCaseRecoveryEmlSvc obj = new EmailToCaseRecoveryEmlSvc();
		obj.handleInboundEmail(email, env);
		Test.stopTest();

		List<BizTech_Temp_Obj__c> list_TempObj = [
			SELECT Id, Full_Email__c, To_Address__c, Text_Body__c, Subject__c, From_Addresses__c, From_Name__c
			FROM BizTech_Temp_Obj__c
			LIMIT 1
		];

		System.assertEquals(1, list_TempObj.size());

		for (BizTech_Temp_Obj__c objBizTechTemp : list_TempObj) {
			System.assertNotEquals(null, objBizTechTemp.Full_Email__c);
			System.assertEquals(null, objBizTechTemp.From_Addresses__c);
			System.assertEquals(null, objBizTechTemp.From_Name__c);
			System.assertEquals(null, objBizTechTemp.To_Address__c);
			System.assertEquals(null, objBizTechTemp.Subject__c);
			System.assertEquals(null, objBizTechTemp.Text_Body__c);
		}
	}
}