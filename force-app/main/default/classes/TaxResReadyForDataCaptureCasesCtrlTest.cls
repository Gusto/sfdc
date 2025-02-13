/**
 * @name         TaxResReadyForDataCaptureCasesCtrlTest
 * @author       Pravesh Rana
 * @date         May 30 2022
 * @description  Test class for TaxResReadyForDataCaptureCasesController class.
 **/
@isTest
public with sharing class TaxResReadyForDataCaptureCasesCtrlTest {
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@TestSetup
	static void handleTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		// insert org default tier config settings
		Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder().build();
		insert objTierConfig;

		Account objAccount = TestDataFactory.CompanyAccount();
		objAccount.Tier__c = objTierConfig.New_Tier_2__c;
		update objAccount;

		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		List<Case> list_cases = new List<Case>();
		Case objCase = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase.Status = TaxResReadyForDataCaptureCasesController.CASE_STATUS_READYFORDATACAPTURE;
		objCase.Is_OCR_Processed__c = false;
		list_cases.add(objCase);

		Case objCase2 = TestDataFactory.createTestCase(objAccount.Id, objContact.Id);
		objCase2.Status = TaxResReadyForDataCaptureCasesController.CASE_STATUS_READYFORDATACAPTURE;
		objCase2.Is_OCR_Processed__c = false;
		objCase2.Notice_Type__c = 'Credit listed or refund check';
		list_cases.add(objCase2);
		update list_cases;
		Case objCaseRec = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setSubject('Test Tax Res Case with attachments')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('Ready for Research')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test Tax Res Case with attachments')
			.build();
		insert objCaseRec;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getCasesTestPositiveMethod() {
		Test.startTest();
		case objCase = [SELECT Id, SuppliedEmail FROM case WHERE SuppliedEmail = 'test@gusto.com'];
		EmailMessage objEmailMessage = new TestDataFactory.EmailMessageBuilder().setParentId(objCase.Id).setToAddress('testemail@test.com').setIncoming(true).build();
		insert objEmailMessage;
		Attachment objAttachment = new Attachment();
		objAttachment.Name = 'AgencyA';
		objAttachment.Body = Blob.valueOf('Test agency piece');
		objAttachment.ParentId = objEmailMessage.id;
		insert objAttachment;

		list<Case> list_QueriedCase = [SELECT ID, Status, Owner.Name, Owner.Type FROM Case];

		List<Case> list_Cases = TaxResReadyForDataCaptureCasesController.getCases(1, 0, 'CreatedDate', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		//because the limit is defined as 1
		system.assertEquals(list_Cases.size(), 1);

		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(5, 0, 'CreatedDate', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		//because the limit is defined as 5 so we should get all the records
		system.assertEquals(list_Cases.size(), 2);

		list_QueriedCase.get(0).Notice_Type__c = 'Credit listed or refund check';
		update list_QueriedCase;
		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(
			5,
			0,
			'CreatedDate',
			'ASC',
			null,
			null,
			null,
			null,
			null,
			null,
			'Credit listed or refund check',
			UserInfo.getUserId(),
			null,
			null
		);
		system.assertEquals(list_Cases.size(), 2);
		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(5, 0, 'accountName', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		system.assertEquals(list_Cases.size(), 2);
		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(5, 0, 'agencyInfo', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		system.assertEquals(list_Cases.size(), 2);
		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(5, 0, 'segment', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		system.assertEquals(list_Cases.size(), 2);
		list_Cases = TaxResReadyForDataCaptureCasesController.getCases(5, 0, 'age', 'ASC', null, null, null, null, null, null, null, UserInfo.getUserId(), null, null);
		system.assertEquals(list_Cases.size(), 2);
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getCasesTestNegativeMethod() {
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		List<Case> list_Cases = TaxResReadyForDataCaptureCasesController.getCases(1, 0, null, null, objTierConfig.New_Tier_1__c, 'Gold', null, null, null, null, null, null, null, null);
		System.assertEquals(list_Cases, null);
		Test.stopTest();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Update case Owner : Postive case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void updateCaseTestPositiveMethod() {
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();

		Test.startTest();
		String strOwnerId = UserInfo.getUserId();
		List<Case> list_Cases = TaxResReadyForDataCaptureCasesController.getCases(
			1,
			0,
			'CreatedDate',
			'ASC',
			objTierConfig.New_Tier_2__c,
			'Gold',
			null,
			null,
			null,
			null,
			null,
			UserInfo.getUserId(),
			null,
			null
		);
		//because the limit is defined as 1
		system.assertEquals(list_Cases.size(), 1);
		List<String> list_SelectedCaseIds = new List<String>();
		list_SelectedCaseIds.add(list_Cases[0].Id);
		String strMessage = TaxResReadyForDataCaptureCasesController.updateCaseOwner(list_SelectedCaseIds, strOwnerId);
		System.assertEquals(strMessage, 'success');
		Test.stopTest();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Update case Owner : Negative case
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void getUpdateTestNegativeMethod() {
		Tier_Config__c objTierConfig = Tier_Config__c.getOrgDefaults();
		Test.startTest();
		String strOwnerId = UserInfo.getUserId();
		List<String> list_SelectedCaseIds = new List<String>();
		String strMessage = TaxResReadyForDataCaptureCasesController.updateCaseOwner(list_SelectedCaseIds, strOwnerId);
		System.assertEquals(strMessage, null);
		List<Case> list_CaseIds = [SELECT Id FROM Case];
		String strOwner = 'invalid user';
		String strMsg = TaxResReadyForDataCaptureCasesController.updateCaseOwner(new List<string>{ list_CaseIds[0].Id }, strOwner);
		system.Assert(strMsg.contains('Invalid'));
		Test.stopTest();
	}
}