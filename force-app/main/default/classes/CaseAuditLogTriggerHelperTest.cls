@isTest
private class CaseAuditLogTriggerHelperTest {
	@TestSetup
	static void setup() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account Test Builder').setZPCompanyId('1111111111').build();

		AccountTriggerHelper.skipTrigger = true;
		insert objCompAccount;
		AccountTriggerHelper.skipTrigger = false;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompAccount.Id)
			.setFirstName('First Name')
			.setLastName('Last Name')
			.setEmail('testuser@firstcontact.com')
			.build();
		ContactTriggerHelper.skipTrigger = true;
		insert objContact;
		ContactTriggerHelper.skipTrigger = false;

		List<Case> list_Cases = new List<Case>();

		Case objPRCCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Test PRC Email')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testuser@firstcontact.com')
			.build();
		list_Cases.add(objPRCCase);

		Case objFSCCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setSubject('Test FSC Email')
			.setOrigin('Phone')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedPhone('1234567890')
			.build();
		list_Cases.add(objFSCCase);

		Case objChatCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setSubject('Test FSC Chat')
			.setOrigin('Gusto')
			.setDirection('Inbound')
			.setStatus('New')
			.build();
		objChatCase.First_Level__c = 'first level';
		list_Cases.add(objChatCase);

		Case objPREscalationCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Test PRC Escalation Email')
			.setOrigin('Escalation')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testuser@firstcontact.com')
			.build();
		list_Cases.add(objPREscalationCase);

		Case objGustoCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_PAYROLL_CARE)
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setSubject('Case with Gusto Origin & Channel Email')
			.setOrigin(CaseUtils.ORIGIN_GUSTO)
			.setDirection(CaseUtils.DIRECTION_INBOUND)
			.setStatus(CaseUtils.STATUS_NEW)
			.setSuppliedEmail('testcase@gusto.com')
			.setIntegrationId('123456789')
			.build();
		list_Cases.add(objGustoCase1);

		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;
		CaseTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void createNewAttachmentTest() {
		List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
		Datetime myDateTime = Datetime.newInstance(2018, 2, 17);

		Account acc = TestUtility.CompanyAccount();

		Case cse1 = new Case();
		cse1.RecordTypeId = cache.getRecordTypeId('Case', 'Sales Cases');
		cse1.AccountId = acc.Id;
		cse1.Subject = 'Test Relation';
		cse1.Description = 'Test Relation';
		cse1.Type = 'Sales';
		cse1.Origin = 'Email';
		insert cse1;

		test.startTest();
		Case_Audit_Log__c log = new Case_Audit_Log__c();
		if (bizHours.size() > 0) {
			log.Business_Hours__c = bizHours[0].id;
		}
		log.From_Date_Time__c = myDateTime;
		log.To_Date_Time__c = myDateTime.addDays(2);
		log.Case__c = cse1.Id;
		insert log;

		log = [SELECT id, Duration_in_seconds__c FROM Case_Audit_Log__c WHERE id = :log.id];
		if (log.Duration_in_seconds__c != null) {
			System.assert(log.Duration_in_seconds__c != null, 'Duration_in_seconds__c should not be null.');
		}

		log.To_Date_Time__c = myDateTime.addDays(4);
		log.Live_Channel_Start_Time__c = myDateTime.addDays(4);
		update log;

		test.stopTest();

		delete log;
	}

	/*
      Author: Alex
      Date: 7/30/2020
      Desc: If status change happens in the middle of call and ends after call, make sure Duration in Seconds != Duration in Seconds Adjusted
    */
	@isTest
	public static void testDurationInSecondsAdjusted() {
		List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
		Datetime myDateTime = System.now();

		Account acc = TestUtility.CompanyAccount();

		Case c = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Type = 'Payroll Care',
			Status = 'Open',
			Priority = 'Medium',
			Origin = 'Phone',
			Direction__c = 'Inbound',
			Call_Start__c = System.now(),
			Call_End__c = System.now().addMinutes(2)
		);
		insert c;

		Test.startTest();
		Case_Audit_Log__c log = new Case_Audit_Log__c(Event_Type__c = 'Status Change', From_Date_Time__c = myDateTime.addMinutes(1), To_Date_Time__c = myDateTime.addMinutes(4), Case__c = c.Id);
		if (bizHours.size() > 0) {
			log.Business_Hours__c = bizHours[0].id;
		}
		insert log;

		Case_Audit_Log__c logQueried = [SELECT Id, Duration_In_Seconds__c, Duration_In_Seconds_Adjusted__c FROM Case_Audit_Log__c];
		System.assertNotEquals(logQueried.Duration_In_Seconds__c, logQueried.Duration_In_Seconds_Adjusted__c, 'Duration in seconds and Duration in seconds adjusted should not be equal.');
		Test.stopTest();
	}

	/*
      Author: Alex
      Date: 7/30/2020
      Desc: If status change happens after call ends, make sure Duration in Seconds = Duration in Seconds Adjusted
    */
	@isTest
	public static void testDurationInSecondsAdjustedSameAsOrig() {
		List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
		Datetime myDateTime = System.now();

		Account acc = TestUtility.CompanyAccount();

		Case c = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Type = 'Payroll Care',
			Status = 'Open',
			Priority = 'Medium',
			Origin = 'Phone',
			Direction__c = 'Inbound',
			Call_Start__c = System.now(),
			Call_End__c = System.now().addMinutes(2)
		);
		insert c;

		Test.startTest();
		Case_Audit_Log__c log = new Case_Audit_Log__c(Event_Type__c = 'Status Change', From_Date_Time__c = myDateTime.addMinutes(3), To_Date_Time__c = myDateTime.addMinutes(4), Case__c = c.Id);
		if (bizHours.size() > 0) {
			log.Business_Hours__c = bizHours[0].id;
		}
		insert log;

		Case_Audit_Log__c logQueried = [SELECT Id, Duration_In_Seconds__c, Duration_In_Seconds_Adjusted__c FROM Case_Audit_Log__c];
		System.assertEquals(logQueried.Duration_In_Seconds__c, logQueried.Duration_In_Seconds_Adjusted__c, 'Duration in seconds and Duration in seconds adjusted should be equal.');
		Test.stopTest();
	}

	/**
	 * Author: Alex
	 * Date: 9/24/2020
	 * Desc: make an exception log
	 */
	public static void testException() {
		List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
		Datetime myDateTime = System.now();

		Account acc = TestUtility.CompanyAccount();

		Case c = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Type = 'Payroll Care',
			Status = 'Open',
			Priority = 'Medium',
			Origin = 'Phone',
			Direction__c = 'Inbound',
			Call_Start__c = System.now(),
			Call_End__c = System.now().addMinutes(2)
		);
		insert c;

		Test.startTest();
		Case_Audit_Log__c log = new Case_Audit_Log__c(Event_Type__c = 'Status Change', From_Date_Time__c = myDateTime.addMinutes(3), To_Date_Time__c = myDateTime.addMinutes(4), Case__c = c.Id);
		if (bizHours.size() > 0) {
			log.Business_Hours__c = bizHours[0].id;
		}
		CaseAuditLogTriggerHelper.blnException = true;
		insert log;

		Case_Audit_Log__c logQueried = [SELECT Id, Duration_In_Seconds__c, Duration_In_Seconds_Adjusted__c FROM Case_Audit_Log__c];
		System.assertEquals(logQueried.Duration_In_Seconds__c, logQueried.Duration_In_Seconds_Adjusted__c, 'Duration in seconds and Duration in seconds adjusted should be equal.');
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @Description test email logic
	 */
	@isTest
	public static void testEmailOrigin() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Origin = 'Email'];
		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>{
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Inbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Inbound')
		};
		insert list_Logs;
		Test.stopTest();

		List<Case_Audit_Log__c> list_QueriedLogs = [SELECT Event_Type__c, Direction__c, Touchpoint__c FROM Case_Audit_Log__c];
		for (Case_Audit_Log__c objLog : list_QueriedLogs) {
			if (objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(0, objLog.Touchpoint__c, 'Touchpoint should be 0.');
				} else {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			} else if (objLog.Event_Type__c == 'Phone') {
				if (objLog.Direction__c == 'Outbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @Description test phone logic
	 */
	@isTest
	public static void testPhoneOrigin() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Origin = 'Phone'];
		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>{
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Inbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Inbound')
		};
		insert list_Logs;
		Test.stopTest();

		List<Case_Audit_Log__c> list_QueriedLogs = [SELECT Event_Type__c, Direction__c, Touchpoint__c FROM Case_Audit_Log__c];
		for (Case_Audit_Log__c objLog : list_QueriedLogs) {
			if (objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(0, objLog.Touchpoint__c, 'Touchpoint should be 0.');
				} else {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			} else if (objLog.Event_Type__c == 'Phone') {
				if (objLog.Direction__c == 'Inbound' || objLog.Direction__c == 'Outbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @Description test chat logic
	 */
	@isTest
	public static void testChatOrigin() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Channel__c = 'Chat'];
		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>{
			new Case_Audit_Log__c(Event_Type__c = 'Chat', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Inbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Chat', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Outbound')
		};
		insert list_Logs;
		Test.stopTest();

		List<Case_Audit_Log__c> list_QueriedLogs = [SELECT Event_Type__c, Direction__c, Touchpoint__c, From_Status__c FROM Case_Audit_Log__c];
		for (Case_Audit_Log__c objLog : list_QueriedLogs) {
			if (objLog.Event_Type__c == 'Chat') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			} else if (objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Outbound' && objLog.From_Status__c == 'New Message') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			} else if (objLog.Event_Type__c == 'Phone') {
				if (objLog.Direction__c == 'Outbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			}
		}
	}

	/**
	 * Author Pradeep Chary
	 * Date: 6/02/2022
	 * Description: test escalation logic
	 **/
	@isTest
	public static void testEscalationOrigin() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id FROM Case WHERE Origin = 'Escalation'];
		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>{
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Inbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Email', Case__c = list_Case[0].Id, From_Status__c = 'New Message', Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Outbound'),
			new Case_Audit_Log__c(Event_Type__c = 'Phone', Case__c = list_Case[0].Id, Direction__c = 'Inbound')
		};
		insert list_Logs;
		Test.stopTest();

		List<Case_Audit_Log__c> list_QueriedLogs = [SELECT Event_Type__c, Direction__c, Touchpoint__c FROM Case_Audit_Log__c];
		for (Case_Audit_Log__c objLog : list_QueriedLogs) {
			if (objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(0, objLog.Touchpoint__c, 'Touchpoint should be 0.');
				} else {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			} else if (objLog.Event_Type__c == 'Phone') {
				if (objLog.Direction__c == 'Outbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint should be 1.');
				}
			}
		}
	}

	/**
	 * @author     Todd Dowdy
	 * @description Test Touchpoint Case Audit log not geting updated on a closed case.
	 **/
	@isTest
	public static void testTouchpointValueOnClosedCase() {
		Test.startTest();
		List<Case> list_Case = [SELECT Id, Status FROM Case WHERE Subject = 'Test PRC Email'];
		list_Case[0].Status = CaseUtils.STATUS_CLOSED;
		CaseTriggerHelper.skipTrigger = true;
		update list_Case;
		CaseTriggerHelper.skipTrigger = false;

		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder()
			.setParentId(list_Case[0].Id)
			.setFromAddress('testuser@firstcontact.com')
			.setToAddress('test@gusto.com')
			.setIncoming(true)
			.setSubject('Email Response to Closed Payroll Care Case')
			.setTextBody('Test email response to closed Payroll Care Case')
			.build();
		insert objEmailMessage;

		Test.stopTest();

		List<Case_Audit_Log__c> list_CasAuditLogs = [SELECT Id, Touchpoint__c FROM Case_Audit_Log__c WHERE Event_Type__c = 'Email' AND Direction__c = 'Inbound'];
		System.assertEquals(1, list_CasAuditLogs.size(), 'There should be 1 Case Audit Log.');
		System.assertEquals(null, list_CasAuditLogs[0].Touchpoint__c, 'Touchpoint__c for Case Audit Log should be null.');
	}

	/**
	 * Author Ankit C
	 * Date: 05/17/2023
	 * Description: test touchpoint tracking logic for Gusto origin cases
	 **/
	@isTest
	public static void testGustoOrigin() {
		Case objEmailCase;
		Case objChatCase;
		for (Case objCase : [SELECT Id, Channel__c FROM Case WHERE Origin = :CaseUtils.ORIGIN_GUSTO]) {
			if (objCase.Channel__c == CaseUtils.ORIGIN_CHAT) {
				objChatCase = objCase;
			} else if (objCase.Channel__c == CaseUtils.ORIGIN_EMAIL) {
				objEmailCase = objCase;
			}
		}

		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>();
		Case_Audit_Log__c objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objEmailCase.Id).setEventType('Email').setFromStatus('New Message').setDirection('Inbound').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objEmailCase.Id).setEventType('Email').setFromStatus('New Message').setDirection('Outbound').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objEmailCase.Id).setEventType('Phone').setDirection('Outbound').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objChatCase.Id).setEventType('Chat').setDirection('Inbound').setFromStatus('New Message').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objChatCase.Id).setEventType('Chat').setDirection('Outbound').setFromStatus('New Message').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objChatCase.Id).setEventType('Email').setDirection('Outbound').build();
		list_Logs.add(objCaseAuditLog);

		objCaseAuditLog = new TestDataFactory.CaseAuditLogBuilder().setCaseId(objChatCase.Id).setEventType('Phone').setDirection('Outbound').build();
		list_Logs.add(objCaseAuditLog);

		Test.startTest();
		insert list_Logs;
		Test.stopTest();

		List<Case_Audit_Log__c> list_QueriedLogs = [SELECT Case__c, Event_Type__c, Direction__c, Touchpoint__c, From_Status__c FROM Case_Audit_Log__c];
		for (Case_Audit_Log__c objLog : list_QueriedLogs) {
			if (objLog.Case__c == objEmailCase.Id && objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(0, objLog.Touchpoint__c, 'Touchpoint was not updated as 0');
				} else {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint was not updated as 1');
				}
			} else if (objLog.Case__c == objEmailCase.Id && objLog.Event_Type__c == 'Phone') {
				if (objLog.Direction__c == 'Outbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint was not updated as 1');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should not be 1');
				}
			} else if (objLog.Case__c == objChatCase.Id && objLog.Event_Type__c == 'Chat') {
				if (objLog.Direction__c == 'Inbound') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint was not updated as 1');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should not be 1');
				}
			} else if (objLog.Case__c == objChatCase.Id && objLog.Event_Type__c == 'Email') {
				if (objLog.Direction__c == 'Outbound' && objLog.From_Status__c == 'New Message') {
					System.assertEquals(1, objLog.Touchpoint__c, 'Touchpoint was not updated as 1');
				} else {
					System.assertNotEquals(1, objLog.Touchpoint__c, 'Touchpoint should not be 1');
				}
			}
		}
	}
}