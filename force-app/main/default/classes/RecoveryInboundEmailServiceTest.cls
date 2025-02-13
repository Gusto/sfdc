/**
 * @name         : RecoveryInboundEmailServiceTest
 * @author       : Alex Xiong
 * @date         : 5/6/2021
 * @description  : Test class for RecoveryInboundEmailService
 **/
@isTest
public class RecoveryInboundEmailServiceTest {
	@testSetup
	static void setupData() {
		CaseTriggerHelper.skipTrigger = true;

		List<Case> list_Case = new List<Case>{
			new Case(Subject = 'test', Description = 'test', Integration_Key__c = 'zenpayroll-payroll-111111', RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases'), Event_Id__c = '11111'),
			new Case(
				Subject = 'testAssignNewCaseToNachaEntry',
				Description = 'testAssignNewCaseToNachaEntry',
				Integration_Key__c = 'zenpayroll-payroll-2222222',
				Event_Id__c = '2222222',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases')
			),
			new Case(
				Subject = 'testAssignNewCaseToNachaEntryContractor',
				Description = 'testAssignNewCaseToNachaEntryContractor',
				Integration_Key__c = 'zenpayroll-contractor-payment-2222222',
				Event_Id__c = '2222222',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases')
			),
			new Case(
				Subject = 'testAssignNewCaseToNachaEntryInternationalContractor',
				Description = 'testAssignNewCaseToNachaEntryInternationalContractor',
				Integration_Key__c = 'zenpayroll-international-contractor-payment-2222222',
				Event_Id__c = '2222222',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases')
			),
			new Case(
				Subject = 'testAssignNewCaseToNachaEntryClosed',
				Description = 'testAssignNewCaseToNachaEntry',
				Integration_Key__c = 'zenpayroll-payroll-00000',
				Event_Id__c = '00000',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases'),
				Status = 'Closed'
			),
			new Case(
				Subject = 'testIntegrationKeyCapitalization1',
				Description = 'testAssignNewCaseToNachaEntry',
				Integration_Key__c = 'zenpayroll-payroll-0i',
				Event_Id__c = '0i',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases')
			),
			new Case(
				Subject = 'testIntegrationKeyCapitalization2',
				Description = 'testAssignNewCaseToNachaEntry',
				Integration_Key__c = 'zenpayroll-payroll-0V',
				Event_Id__c = '0V',
				RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases')
			),
			new Case(Subject = 'recovery parent case', RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases'), Integration_Key__c = 'zenpayroll-payroll-333', Status = 'Open'),
			new Case(Subject = 'recovery child case', RecordTypeId = Cache.getRecordTypeId('Case', 'Recovery Cases'), Integration_Key__c = 'zenpayroll-payroll-444', Status = 'Closed')
		};

		insert list_Case;
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Creates email records
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	private static Messaging.InboundEmail createEmail() {
		Messaging.InboundEmail objEmail = new Messaging.InboundEmail();
		objEmail.subject = 'test';
		objEmail.fromName = 'test test';
		objEmail.plainTextBody = 'Hello, this a test email body. for testing purposes only.Phone:123456 Bye';
		objEmail.toAddresses = new List<String>{ 'recovery@gusto.com' };
		objEmail.ccAddresses = new List<String>{ 'admin@gusto.com' };

		Messaging.InboundEmail.BinaryAttachment[] list_BinaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.mimeTypeSubType = 'text/plain';

		String strAlgorithmName = 'HMacSHA1';
		Blob b = Crypto.generateMac(strAlgorithmName, Blob.valueOf('test'), Blob.valueOf('test_key'));
		objBinaryAttachment.Body = b;

		list_BinaryAttachments[0] = objBinaryAttachment;
		objEmail.binaryAttachments = list_BinaryAttachments;

		return objEmail;
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Creates ZP Nacha Entry returns records
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	private static List<ZP_Nacha_Entry_Returns__c> createZPNachaEntryReturn(String strEventId) {
		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = new List<ZP_Nacha_Entry_Returns__c>();

		ZP_Nacha_Entry_Returns__c objZPNacha1 = new TestDataFactory.ZPNachaEntryReturnsBuilder()
			.setCustomId('1111111111112')
			.setAmount(1234)
			.setCompanyId('11111')
			.setEventId(strEventId)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setTransactionType('Debit net pay')
			.setErrorCode('R01')
			.setEventType('Payroll')
			.setExpediteReason('Two day')
			.setErrorCodeDescription('Insufficient Funds')
			.setProcessingState('Queued')
			.build();

		ZP_Nacha_Entry_Returns__c objZPNacha2 = new TestDataFactory.ZPNachaEntryReturnsBuilder()
			.setCustomId('1111111111113')
			.setAmount(1234)
			.setCompanyId('11111')
			.setEventId(strEventId)
			.setCreatedAt(System.now())
			.setUpdatedAt(System.now())
			.setTransactionType('Debit net pay')
			.setErrorCode('R01')
			.setEventType('Payroll')
			.setExpediteReason('Two day')
			.setErrorCodeDescription('Insufficient Funds')
			.setProcessingState('Queued')
			.build();

		list_ZPNachaEntryReturns.add(objZPNacha1);
		list_ZPNachaEntryReturns.add(objZPNacha2);

		return list_ZPNachaEntryReturns;
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles InboundEnvelope with no reference Id
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testNewEmailCaseCreation() {
		Test.startTest();

		Messaging.InboundEmail objEmail = createEmail();
		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = 'user@acme.com';

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles InboundEnvelope with no reference Id for exception check
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testNewEmailCaseCreationTwo() {
		Test.startTest();

		Messaging.InboundEmail objEmail = createEmail();

		Messaging.InboundEmail.BinaryAttachment[] list_BinaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];
		Messaging.InboundEmail.BinaryAttachment objBinaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		objBinaryAttachment.Filename = 'test.txt';
		objBinaryAttachment.mimeTypeSubType = 'text/plain';

		String strAlgorithmName = 'HMacSHA1';
		Blob b = Crypto.generateMac(strAlgorithmName, Blob.valueOf('test'), Blob.valueOf('test_key'));
		objBinaryAttachment.Body = b;

		list_BinaryAttachments.add(objBinaryAttachment);
		objEmail.binaryAttachments = list_BinaryAttachments;

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles InboundEnvelope with reference Id
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testNewEmailCaseEmail() {
		Test.startTest();

		Messaging.InboundEmail objEmail = createEmail();
		objEmail.toAddresses = null;
		objEmail.plainTextBody = 'Hello, this a test email body. for testing purposes only.Phone:123456 Bye ref:_zenpayroll-payroll-121212:ref';

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		Messaging.InboundEmail.TextAttachment[] list_TextAttachments = new Messaging.InboundEmail.TextAttachment[1];
		Messaging.InboundEmail.TextAttachment objTextAttachment = new Messaging.InboundEmail.TextAttachment();
		objTextAttachment.Filename = 'test.txt';
		objTextAttachment.body = 'ddddd';
		objTextAttachment.mimeTypeSubType = 'texttwo/plain';
		objTextAttachment.headers = new Messaging.InboundEmail.Header[1];
		list_TextAttachments[0] = objTextAttachment;

		objEmail.textAttachments = list_TextAttachments;

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles Email InboundEnvelope checks for NachaEntryReturns under ZP NachaEntry and creates
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testZPNachaEntryReturnsOneProcessed() {
		Test.startTest();

		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('11111');

		ZPNachaEntryReturnsTriggerHelper.queue = true;
		insert list_ZPNachaEntryReturns[0];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
		insert list_ZPNachaEntryReturns[1];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;

		List<Nacha_Entry_Return__c> list_NachaEntryReturns = [SELECT Id FROM Nacha_Entry_Return__c];
		System.assertEquals(list_NachaEntryReturns.size(), 1);

		Messaging.InboundEmail objEmail = createEmail();
		objEmail.toAddresses = null;
		objEmail.plainTextBody = 'Hello, this a test email body. ref:_zenpayroll-payroll-111111:ref';

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		List<Nacha_Entry_Return__c> list_NachaEntryReturns2 = [SELECT Id FROM Nacha_Entry_Return__c];

		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles Email InboundEnvelope checks for NachaEntryReturns under ZP NachaEntry and creates
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testZPNachaEntryReturnsOneProcess() {
		Test.startTest();

		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('11111');

		ZPNachaEntryReturnsTriggerHelper.queue = true;
		insert list_ZPNachaEntryReturns[0];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
		insert list_ZPNachaEntryReturns[1];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;

		List<Nacha_Entry_Return__c> list_NachaEntryReturns = [SELECT Id FROM Nacha_Entry_Return__c];
		System.assertEquals(list_NachaEntryReturns.size(), 1);

		Messaging.InboundEmail objEmail = createEmail();
		objEmail.toAddresses = null;
		objEmail.plainTextBody = 'Hello, this a test email body. ref:_zenpayroll-payroll-111111:ref';

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		Test.stopTest();
	}

	/*
	 * @Author      : Pradeep Chary
	 * @Description : Test if the method handles Email InboundEnvelope checks for NachaEntryReturns under ZP NachaEntry and creates
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	static testMethod void testZPNachaEntryReturnsTwoProcessed() {
		Test.startTest();

		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('11111');

		ZPNachaEntryReturnsTriggerHelper.queue = true;
		insert list_ZPNachaEntryReturns;

		List<Nacha_Entry_Return__c> list_NachaEntryReturns = [SELECT Id FROM Nacha_Entry_Return__c];
		System.assertEquals(list_NachaEntryReturns.size(), 2);

		Messaging.InboundEmail objEmail = createEmail();
		objEmail.toAddresses = null;
		objEmail.plainTextBody = 'Hello, this a test email body. ref:_zenpayroll-payroll-111111:ref';

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.fromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		// setup controller object
		RecoveryInboundEmailService objController = new RecoveryInboundEmailService();
		Messaging.InboundEmailResult result = objController.handleInboundEmail(objEmail, objEnvelope);
		System.assertEquals(result.success, true);

		Test.stopTest();
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Test RecoveryInboundEmailService.assignNewCaseToNachaEntry()
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testAssignNewCaseToNachaEntry() {
		Test.startTest();
		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('2222222');
		ZPNachaEntryReturnsTriggerHelper.queue = true;
		insert list_ZPNachaEntryReturns[0];

		Map<String, Case> map_CasesBySubject = new Map<String, Case>();
		for (Case objCase : [SELECT Id, Subject FROM Case WHERE Event_Id__c = '2222222']) {
			map_CasesBySubject.put(objCAse.Subject, objCase);
		}

		RecoveryInboundEmailService objService = new RecoveryInboundEmailService();
		objService.assignNewCaseToNachaEntry(map_CasesBySubject.get('testAssignNewCaseToNachaEntry').Id, 'ref:_zenpayroll-payroll-2222222:ref');
		List<Nacha_Entry_Return__c> list_Nacha = [SELECT Case__c FROM Nacha_Entry_Return__c];
		System.assertEquals(1, list_Nacha.size());
		System.assertEquals(map_CasesBySubject.get('testAssignNewCaseToNachaEntry').Id, list_Nacha[0].Case__c, 'Method should have linked Nacha to Case');
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
		list_Nacha[0].Case__c = null;
		update list_Nacha;
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;

		objService.assignNewCaseToNachaEntry(map_CasesBySubject.get('testAssignNewCaseToNachaEntryContractor').Id, 'ref:_zenpayroll-contractor-payment-2222222:ref');
		list_Nacha = [SELECT Case__c FROM Nacha_Entry_Return__c];
		System.assertEquals(1, list_Nacha.size());
		System.assertEquals(map_CasesBySubject.get('testAssignNewCaseToNachaEntryContractor').Id, list_Nacha[0].Case__c, 'Method should have linked Nacha to Case');
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
		list_Nacha[0].Case__c = null;
		update list_Nacha;
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;

		objService.assignNewCaseToNachaEntry(map_CasesBySubject.get('testAssignNewCaseToNachaEntryInternationalContractor').Id, 'ref:_zenpayroll-international-contractor-payment-2222222:ref');
		list_Nacha = [SELECT Case__c FROM Nacha_Entry_Return__c];
		System.assertEquals(1, list_Nacha.size());
		System.assertEquals(map_CasesBySubject.get('testAssignNewCaseToNachaEntryInternationalContractor').Id, list_Nacha[0].Case__c, 'Method should have linked Nacha to Case');
		Test.stopTest();
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Test RecoveryInboundEmailService.getCaseInformation()
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testGetCaseInformation() {
		Test.startTest();
		Case objCaseFromMethod = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-111111:ref');
		Case objNullCase = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-0:ref');
		Case objClosedCase = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-00000:ref');
		Case objCapitalI = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-0I:ref');
		Case objCapitalV = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-0V:ref');

		List<Case> list_PreviouslyClosedCase = [
			SELECT Id, Status
			FROM Case
			WHERE Subject = 'testAssignNewCaseToNachaEntryClosed'
		];

		System.assertNotEquals(null, objCaseFromMethod, 'There should have been a case found with this reference');
		System.assertEquals(null, objNullCase, 'There should not have been a case');
		System.assertEquals('Open', list_PreviouslyClosedCase[0].Status, 'Case should have been reopened');
		System.assertEquals(null, objCapitalI, 'There should not be a case found because of incorrect capitalization of integration key');
		System.assertNotEquals(null, objCapitalV, 'There should be a case found');
		Test.stopTest();
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Test RecoveryInboundEmailService.checkR01NachaEntry()
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testCheckR01NachaEntry() {
		Test.startTest();
		//Test 1 unprocessed
		List<ZP_Nacha_Entry_Returns__c> list_ZPNachaEntryReturns = createZPNachaEntryReturn('12345');
		ZPNachaEntryReturnsTriggerHelper.queue = true;
		insert list_ZPNachaEntryReturns[0];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
		insert list_ZPNachaEntryReturns[1];
		ZPNachaEntryReturnsTriggerHelper.skipTrigger = false;

		String strNachaId = RecoveryInboundEmailService.checkR01NachaEntry('ref:_zenpayroll-payroll-12345:ref');
		System.assertNotEquals(null, strNachaId, 'Should have returned a Nacha Id');
		strNachaId = RecoveryInboundEmailService.checkR01NachaEntry('ref:_zenpayroll-contractor-payment-12345:ref');
		System.assertNotEquals(null, strNachaId, 'Should have returned a Nacha Id');
		strNachaId = RecoveryInboundEmailService.checkR01NachaEntry('ref:_zenpayroll-international-contractor-payment-12345:ref');
		System.assertNotEquals(null, strNachaId, 'Should have returned a Nacha Id');
		Test.stopTest();
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Test RecoveryInboundEmailService.createCase() when Case 
					  should be assigned to Recovery Case Queue.
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testRecoveryCase() {
		String strRecoveryCaseQueueId = GlobalQueryHelper.getQueueIdByName(RecoveryInboundEmailService.RECOVERY_CASE_QUEUE);
		Test.startTest();
		Messaging.InboundEmail objEmail = createEmail();
		objEmail.PlainTextBody = null;
		objEmail.HtmlBody = 'Hello, this a test email body. ref:_zenpayroll-payroll-12345:ref';

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.FromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		RecoveryInboundEmailService objInstance = new RecoveryInboundEmailService();
		objInstance.handleInboundEmail(objEmail, objEnvelope);

		List<Case> list_Case = [
			SELECT Id, Origin, Description, OwnerId
			FROM Case
			WHERE Integration_Key__c = 'zenpayroll-payroll-12345'
		];
		Test.stopTest();
		System.assertEquals('Email', list_Case[0].Origin);
		System.assertEquals(list_Case[0].Description, objEmail.HtmlBody);
		System.assertEquals(strRecoveryCaseQueueId, list_Case[0].OwnerId);
	}

	/*
	 * @Author      : Ankit CS
	 * @Description : Test RecoveryInboundEmailService.createCase() when Case should be 
					  assigned to Recovery Cases - Non-actionable queue.
	 */
	@isTest
	static void testRecoveryNonActionableCase() {
		String strNonRecoveryActionableQueueId = GlobalQueryHelper.getQueueIdByName(RecoveryInboundEmailService.RECOVERY_NON_ACTIONABLE_QUEUE);
		Test.startTest();
		Messaging.InboundEmail objEmail = createEmail();
		objEmail.HtmlBody = 'Test Email Body. We therefore changed the payment record in Gusto to be \'paid by check\'' + ' instead of Direct Deposit ref:_zenpayroll-payroll-123456:ref';
		objEmail.PlainTextBody = objEmail.HtmlBody;
		objEmail.FromName = RecoveryInboundEmailService.RECOVERY_EMAIL;
		objEmail.ToAddresses = new List<String>{ 'test@gusto.com' };

		Messaging.InboundEnvelope objEnvelope = new Messaging.InboundEnvelope();
		objEnvelope.FromAddress = RecoveryInboundEmailService.RECOVERY_EMAIL;

		RecoveryInboundEmailService objInstance = new RecoveryInboundEmailService();
		objInstance.handleInboundEmail(objEmail, objEnvelope);

		List<Case> list_Case = [
			SELECT Id, Origin, Description, OwnerId
			FROM Case
			WHERE Integration_Key__c = 'zenpayroll-payroll-123456'
		];
		Test.stopTest();
		System.assertEquals('Email', list_Case[0].Origin);
		System.assertEquals(list_Case[0].Description, objEmail.HtmlBody);
		System.assertEquals(strNonRecoveryActionableQueueId, list_Case[0].OwnerId);
	}

	/*
	 * @Author      : Alex Xiong
	 * @Description : Test RecoveryInboundEmailService.getCaseReference()
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	@isTest
	static void testGetCaseReference() {
		Test.startTest();
		String strBody = 'Test body ref:_zenpayroll-payroll-12345:ref test body';
		System.assertEquals('ref:_zenpayroll-payroll-12345:ref', RecoveryInboundEmailService.getCaseReference(strBody));

		String strNullBody;
		System.assertEquals('', RecoveryInboundEmailService.getCaseReference(strNullBody), 'should not throw exception on null body');
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description make sure getCaseInformation() does not reopen merged case
	 */
	@isTest
	static void testGetCaseInformationMergedCase() {
		Case objChildCase = [SELECT Id, Status FROM Case WHERE Subject = 'recovery child case'];
		Case objParentCase = [SELECT Id FROM Case WHERE Subject = 'recovery parent case'];
		String strClosed = objChildCase.Status;

		Case objChildCaseAfter = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-444:ref');

		System.assertNotEquals(strClosed, objChildCaseAfter.Status, 'Closed Case with no parent should reopen');
		objChildCase.ParentId = objParentCase.Id;
		update objChildCase;

		Test.startTest();

		Case objParent = RecoveryInboundEmailService.getCaseInformation('ref:_zenpayroll-payroll-444:ref');
		Case objChildWithParentQueried = [SELECT Id, Status FROM Case WHERE Id = :objChildCase.Id];

		System.assertEquals(strClosed, objChildWithParentQueried.Status, 'Closed Case with parent should stay closed');
		System.assertEquals(objParentCase.Id, objParent.Id, 'getCaseInformation should return parent id');
		Test.stopTest();
	}
}