@isTest
public class AgathaPredictionTriggerHelperTest {
	@TestSetup
	static void setup() {
		List<Configuration_Settings__c> configSettingList = [SELECT id, TaxRes_Agencies_to_Ignore__c, TaxRes_Prediction_Score__c FROM Configuration_Settings__c];
		if (configSettingList.size() == 0) {
			Configuration_Settings__c configObj = new Configuration_Settings__c(TaxRes_Agencies_to_Ignore__c = 'Dummy;Dummy1', TaxRes_Prediction_Score__c = '0.9', Route_tax_res_cases__c = true);
			insert configObj;
		}

		List<User> list_Users = new List<User>();
		Profile objProfile = [SELECT Id, Name FROM Profile WHERE Name = 'API Integration'];
		UserRole objRole = [SELECT Id FROM UserRole WHERE Name = 'Integration Users'];

		User objIntegrationUser = new TestDataFactory.UserBuilder()
			.setAlias('APTAPI')
			.setEmail('testApiUser@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('AgathaAPITest')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(objProfile.Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testApiUser@testorg.com')
			.setIsAPIIntegration(true)
			.setUserRoleId(objRole.Id)
			.build();
		list_Users.add(objIntegrationUser);

		Profile objProfile2 = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];
		UserRole objCCRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
		User objUser = new TestDataFactory.UserBuilder()
			.setUserName('aptriggerhelpertest@gusto.com')
			.setFirstName('agathatriggerhelper')
			.setLastName('test')
			.setEmail('aptriggerhelpertest@gusto.com')
			.setProfileId(objProfile2.Id)
			.setUserRoleId(objCCRole.Id)
			.setTimeZoneSidKey('America/Denver')
			.setLocaleSidKey('en_US')
			.setLanguageLocaleKey('en_US')
			.setEmailEncoding('ISO-8859-1')
			.setAlias('test')
			.setIsActive(true)
			.build();
		objUser.Class_Queue__c = 'Class 1';
		objUser.Benefits_Class__c = 'Class 2';

		list_Users.add(objUser);
		User objCurrentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0];
		System.runAs(objCurrentUser) {
			insert list_Users;
		}

		List<Case_Reason_Classification__c> list_Crc = new List<Case_Reason_Classification__c>();

		Case_Reason_Classification__c objPRCCaseReason = new Case_Reason_Classification__c();
		objPRCCaseReason.Type__c = 'Payroll Care';
		objPRCCaseReason.Name = 'Route to PRC';
		objPRCCaseReason.Class__c = 'Class 1';
		objPRCCaseReason.Reason_Code__c = 'routePRC';
		objPRCCaseReason.Active__c = true;
		list_Crc.add(objPRCCaseReason);

		Case_Reason_Classification__c objPRCCaseReason2 = new Case_Reason_Classification__c();
		objPRCCaseReason2.Type__c = 'Payroll Care';
		objPRCCaseReason2.Name = 'Generic PRC';
		objPRCCaseReason2.Class__c = 'Class 1';
		objPRCCaseReason2.Reason_Code__c = 'genericPRC';
		objPRCCaseReason2.Active__c = true;
		objPRCCaseReason2.Generic_Routing_Reason__c = true;
		list_Crc.add(objPRCCaseReason2);

		Case_Reason_Classification__c objPRCCaseReason3 = new Case_Reason_Classification__c();
		objPRCCaseReason3.Type__c = 'Benefits Care';
		objPRCCaseReason3.Name = 'S-Corp Shareholder Status';
		objPRCCaseReason3.Class__c = 'Class 3';
		objPRCCaseReason3.Reason_Code__c = 's_corp_shareholder_status';
		objPRCCaseReason3.Priority__c = 'Medium';
		objPRCCaseReason3.Active__c = true;
		list_Crc.add(objPRCCaseReason3);

		Case_Reason_Classification__c objPRCCaseReason4 = new Case_Reason_Classification__c();
		objPRCCaseReason4.Type__c = 'GEP CX';
		objPRCCaseReason4.Name = 'S-Corp Shareholder Status';
		objPRCCaseReason4.Class__c = 'Class 2';
		objPRCCaseReason4.Reason_Code__c = 'S-Corp_Shareholder_Status';
		objPRCCaseReason3.Priority__c = 'Low';
		objPRCCaseReason4.Active__c = true;
		list_Crc.add(objPRCCaseReason4);

		Case_Reason_Classification__c objCaseTypePillarReason1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Payroll pillar case reason')
			.setIsActive(true)
			.setReasonCode('test_payroll_pillar')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.build();
		list_Crc.add(objCaseTypePillarReason1);

		Case_Reason_Classification__c objCaseTypePillarReason2 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Benefits pillar case reason')
			.setIsActive(true)
			.setReasonCode('test_benefits_pillar')
			.setCaseTypePillar(CaseUtils.BENEFITS_CASE_PILLAR)
			.setType('Engagement')
			.build();
		list_Crc.add(objCaseTypePillarReason2);

		Case_Reason_Classification__c objCaseTypePillarReason3 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Taxes pillar case reason')
			.setIsActive(true)
			.setReasonCode('test_taxes_pillar')
			.setCaseTypePillar(CaseUtils.TAXES_CASE_PILLAR)
			.setType('Engagement')
			.build();
		list_Crc.add(objCaseTypePillarReason3);

		Case_Reason_Classification__c objCaseTypePillarReason4 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test TAdA case reason')
			.setIsActive(true)
			.setReasonCode('test_tada')
			.setCaseTypePillar(CaseUtils.TYPE_TADA)
			.setType('Engagement')
			.build();
		list_Crc.add(objCaseTypePillarReason4);

		Case_Reason_Classification__c objCaseSpecializationReason1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Integrations')
			.setIsActive(true)
			.setReasonCode('zp_giving_or_charity')
			.setCaseTypePillar(CaseUtils.PAYROLL_CASE_PILLAR)
			.setType('Engagement')
			.setSpecialization('Integrations')
			.setSupportLevel(CaseUtils.TIER_1)
			.build();
		list_Crc.add(objCaseSpecializationReason1);
		
		Case_Reason_Classification__c objCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('State Notice')
			.setIsActive(true)
			.setReasonCode('state_notice_reset')
			.setType(CaseUtils.TYPE_ENGAGEMENT)
			.setClass('Class 1')
			.setSpecialization('')
			.build();
		objCaseReason.Auto_Email_Behavior__c = 'Send';
		objCaseReason.Email_Content__c = 'Test Content';
		objCaseReason.Confidence_Threshold__c = 0.5;
		list_Crc.add(objCaseReason);

		insert list_Crc;

		Account objCompAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID)
			.setName('Company Account Test Builder')
			.setZPCompanyId('1111111111')
			.setNumberOfActiveEEs(4)
			.build();

		AccountTriggerHelper.skipTrigger = true;
		insert objCompAccount;
		AccountTriggerHelper.skipTrigger = false;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objCompAccount.Id)
			.setFirstName('First Name1')
			.setLastName('Last Name1')
			.setEmail('testuser1@firstcontact.com')
			.setZPUserRole('Payroll Admin')
			.build();
		insert objContact;

		List<Case> list_Case = new List<Case>();

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setSubject('Test PRC API route')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('test api route')
			.build();
		list_Case.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('QLE')
			.setSubject('Test')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('Test')
			.build();

		objCase2.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase2);

		//Engagement case created to cover the code of US-107
		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setType('Benefits')
			.setSubject('Test Engagement Benefits')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test2@gusto.com')
			.setDescription('Test Engagement')
			.build();
		list_Case.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test case for Payroll pillar')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testcasepillar1@gusto.com')
			.setDescription('Test case for Payroll pillar')
			.build();

		objCase4.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase4);

		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test case for benefits pillar')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testcasepillar2@gusto.com')
			.setDescription('Test case for benefits pillar')
			.build();

		objCase5.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase5);

		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test case for taxes pillar')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testcasepillar3@gusto.com')
			.setDescription('Test case for taxes pillar')
			.build();

		objCase6.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase6);

		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test case for TAdA')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('In Progress')
			.setSuppliedEmail('testcasepillar4@gusto.com')
			.setDescription('Test case for TAdA')
			.build();

		objCase7.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase7);

		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setAccountId(objCompAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setSubject('Test auto close datetime')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('testautoclosedatetime@gusto.com')
			.setDescription('Test auto close datetime')
			.build();

		objCase8.Answer_IQ_Eligible__c = true;
		list_Case.add(objCase8);

		CaseTriggerHelper.skipTrigger = true;
		objCase.OwnerId = objIntegrationUser.Id;
		objCase.Case_Owner_Role__c = 'Integration Users';
		objCase.Answer_IQ_Eligible__c = true;
		insert list_Case;
		CaseTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testIntegrationQueCreation() {
		Account acc = TestUtility.CompanyAccount();

		Case_Reason_Classification__c clas = new Case_Reason_Classification__c();
		clas.Type__c = 'Payroll Care';
		clas.Name = 'State Notice';
		clas.Class__c = 'Class 1';
		clas.Reason_Code__c = 'State_Notice';
		clas.Active__c = true;
		insert clas;

		Case cse = [SELECT Id FROM Case WHERE Subject = 'Test' AND RecordType.Name = 'Tax Res'];

		test.startTest();
		EmailMessage incomingMail = new EmailMessage();
		incomingMail.fromaddress = 'test@email.com';
		incomingMail.toAddress = 'test@test.com';
		incomingMail.subject = 'Test Message';
		incomingMail.TextBody = 'This is the message body ';
		incomingMail.RelatedToId = cse.id;
		incomingMail.incoming = true;
		insert incomingMail;
		test.stopTest();
		Attachment attach = new Attachment(ParentId = incomingMail.Id);
		attach.Name = 'Unit Test Attachment';
		Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
		attach.body = bodyBlob;
		insert attach;

		Agatha_Prediction__c pred = new Agatha_Prediction__c();
		pred.Case__c = cse.Id;
		pred.Case_Reason_Code__c = 'State_Notice';
		insert pred;

		Case c = [SELECT Id, Routing_Case_Reason__c, Confirm_Case_Reason__c, RecordType.Name FROM Case WHERE Id = :cse.Id];
		//if(c.Routing_Case_Reason__c != null)
		System.assertEquals('State Notice', c.Routing_Case_Reason__c, 'Incorrect Case Reason');
		System.assertEquals('State Notice', c.Confirm_Case_Reason__c, 'Incorrect Case Reason');
		pred.Case_Reason_Code__c = 'State_Notice_1';
		update pred;
		delete pred;
	}

	/**
	 * @Author      : Alex Xiong
	 * @escription : verify agency information
	 */
	@isTest
	static void testAgencyInformation() {
		Test.startTest();
		Account objAcc = TestUtility.CompanyAccount();

		Case_Reason_Classification__c objCrc = new Case_Reason_Classification__c();
		objCrc.Type__c = 'Tax Res';
		objCrc.Name = 'State Notice';
		objCrc.Class__c = 'Class 1';
		objCrc.Reason_Code__c = 'State_Notice';
		objCrc.Active__c = true;
		insert objCrc;

		Case objCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAcc.Id)
			.setRecordTypeId('Tax Res')
			.setType('QLE')
			.setSubject('testAgencyInformation')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test@gusto.com')
			.setDescription('test')
			.build();
		objCase.Answer_IQ_Eligible__c = true;

		insert objCase;

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Agency_Information__c = 'test agency info';
		insert objPred;

		Test.stopTest();

		Case objCaseQueried = [SELECT Id, Agency_Info_Agatha__c FROM Case WHERE Subject = 'testAgencyInformation'];
		System.assertEquals(objPred.Agency_Information__c, objCaseQueried.Agency_Info_Agatha__c, 'Agency Information is incorrect');
	}

	@isTest
	static void testAutoEmail() {
		Test.startTest();
		Account objAcct = TestUtility.CompanyAccount();

		Case_Reason_Classification__c objCaseReason = new Case_Reason_Classification__c();
		objCaseReason.Type__c = 'Payroll Care';
		objCaseReason.Name = 'State Notice';
		objCaseReason.Class__c = 'Class 1';
		objCaseReason.Reason_Code__c = 'State_Notice';
		objCaseReason.Active__c = true;
		objCaseReason.Auto_Email_Behavior__c = 'Send';
		objCaseReason.Email_Content__c = 'Test Content';
		objCaseReason.Confidence_Threshold__c = 0.3;
		insert objCaseReason;

		Case objCase = new Case();
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
		objCase.AccountId = objAcct.Id;
		objCase.Subject = 'Test';
		objCase.Description = 'Test';
		objCase.Type = 'QLE';
		objCase.Answer_IQ_Eligible__c = true;
		insert objCase;

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Confidence__c = 31;
		objPred.Case_Reason_Code__c = 'State_Notice';
		insert objPred;

		Test.stopTest();

		List<Case> list_Case = [SELECT Id, Auto_Response_Email_Content__c, Auto_Email_Behavior__c FROM Case WHERE Id = :objCase.Id];
		if (!list_Case.isEmpty()) {
			String strAutoResponseEmailContent = list_Case[0].Auto_Response_Email_Content__c;
			if (String.isNotBlank(strAutoResponseEmailContent)) {
				System.assert(strAutoResponseEmailContent.contains(objCaseReason.Email_Content__c), 'Enter appropriate Email Content');
			}
		}
	}

	/**
	 * @Author          : Alex Xiong
	 * @Description     : confirm cases owned by integration users will route
	 */
	@isTest
	public static void testIntegrationUserRouting() {
		Test.startTest();

		User objAPIUser = [SELECT Id FROM User WHERE UserName = 'testApiUser@testorg.com'][0];
		Case objCase = [SELECT Id, Case_Owner_Role__c FROM Case WHERE Subject = 'Test PRC API route'][0];

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Confidence__c = 31;
		objPred.Case_Reason_Code__c = 'routePRC';
		insert objPred;

		Test.stopTest();

		Case objCase2 = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE Subject = 'Test PRC API route'][0];
		System.assertNotEquals(objAPIUser.Id, objCase2.OwnerId, 'Inappropriate Case Owner');
	}

	/**
	 * @Author          : Alex Xiong
	 * @Description     : Assert Confirm Case Reason Classification is set when a prediction record is inserted
	 * 					  with a non-generic case reason
	 */
	@isTest
	public static void testConfirmCaseReasonBehaviorNonGeneric() {
		Test.startTest();
		Case objCase = [SELECT Id, Case_Owner_Role__c FROM Case WHERE Subject = 'Test PRC API route'][0];

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Confidence__c = 31;
		objPred.Case_Reason_Code__c = 'routeprc';
		insert objPred;

		Test.stopTest();

		Case objCase2 = [SELECT Id, Confirm_Case_Reason__c FROM Case WHERE Subject = 'Test PRC API route'][0];
		System.assertNotEquals(null, objCase2.Confirm_Case_Reason__c, 'Confirm Case Reason should be set');
	}

	/**
	 * @Author          : Alex Xiong
	 * @Description     : Assert Confirm Case Reason Classification is set when a prediction record is inserted
	 * 					  with a non-generic case reason
	 */
	@isTest
	public static void testConfirmCaseReasonBehaviorGeneric() {
		Test.startTest();
		Case objCase = [SELECT Id, Case_Owner_Role__c FROM Case WHERE Subject = 'Test PRC API route'][0];

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Confidence__c = 31;
		objPred.Case_Reason_Code__c = 'genericPRC';
		insert objPred;

		Test.stopTest();

		Case objCase2 = [SELECT Id, Confirm_Case_Reason__c FROM Case WHERE Subject = 'Test PRC API route'][0];
		System.assertEquals(null, objCase2.Confirm_Case_Reason__c, 'Confirm Case Reason should not be set');
	}

	/**
	 * @author Alex Xiong
	 * @description assert correct class is set when there are more than 1 case reason classification with same name
	 */
	@isTest
	static void testSameNameCaseReasons() {
		Test.startTest();
		Case objCase = [SELECT Id FROM Case WHERE Subject = 'Test PRC API route'][0];

		Agatha_Prediction__c objPred = new Agatha_Prediction__c();
		objPred.Case__c = objCase.Id;
		objPred.Confidence__c = 31;
		objPred.Case_Reason_Code__c = 's_corp_shareholder_status';
		insert objPred;

		List<User> list_User = [SELECT Id FROM User WHERE Email = 'aptriggerhelpertest@gusto.com'];
		System.runAs(list_User[0]) {
			List<Case> list_Case = [SELECT Id, Class__c, Routing_Case_Reason_Classification__c, Confirm_Case_Reason_Classification__c FROM Case WHERE Subject = 'Test PRC API route'];
			System.assertEquals('Class 3', list_Case[0].Class__c, 'Incorrect Class set');

			list_Case[0].OwnerId = list_User[0].Id;
			list_Case[0].Audience__c = 'Employee';
			list_Case[0].Confirm_Case_Reason__c = 'S-Corp Shareholder Status';
			list_Case[0].Status = 'Solved';

			CaseTriggerHelper.skipTrigger = false;
			update list_Case;
		}

		List<Case> list_CaseSolved = [SELECT Id, Class__c, Owner_Class__c, Benefits_Owner_Class__c FROM Case WHERE Subject = 'Test PRC API route'];
		Test.stopTest();

		System.assertEquals('Class 1', list_CaseSolved[0].Owner_Class__c, 'Incorrect Class set');
		System.assertEquals('Class 2', list_CaseSolved[0].Benefits_Owner_Class__c, 'Incorrect Class set');
		System.assertEquals('Class 3', list_CaseSolved[0].Class__c, 'Incorrect Class set');
	}

	/**
	 * @author 			Ankit C
	 * @description 	Test if the case type is updated based on case type pillar
	 */
	@isTest
	static void testCaseTypePillar() {
		List<User> list_User = [SELECT Id FROM User WHERE Email = 'aptriggerhelpertest@gusto.com'];
		Map<String, Case> map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		List<Agatha_Prediction__c> list_AgathaPredictions = new List<Agatha_Prediction__c>();
		Agatha_Prediction__c objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(map_CaseByEmail.get('testcasepillar1@gusto.com').Id)
			.setReasonCode('test_payroll_pillar')
			.setSupportLevel('Tier 1')
			.setCaseType('Payroll')
			.build();
		list_AgathaPredictions.add(objAgathaPrediction);

		objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(map_CaseByEmail.get('testcasepillar2@gusto.com').Id)
			.setReasonCode('test_benefits_pillar')
			.setSupportLevel('Tier 2')
			.setCaseType('Benefits')
			.build();
		list_AgathaPredictions.add(objAgathaPrediction);

		objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(map_CaseByEmail.get('testcasepillar3@gusto.com').Id)
			.setReasonCode('test_taxes_pillar')
			.setSupportLevel('Tier 1')
			.setCaseType('Taxes')
			.build();
		list_AgathaPredictions.add(objAgathaPrediction);

		objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder().setCaseId(map_CaseByEmail.get('testcasepillar4@gusto.com').Id).setReasonCode('test_tada').setSupportLevel('Tier 1').build();
		list_AgathaPredictions.add(objAgathaPrediction);

		Test.startTest();
		System.runAs(list_User[0]) {
			insert list_AgathaPredictions;
		}
		Test.stopTest();

		map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail, Type, RecordTypeId, Support_Level__c FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		System.assertEquals(map_CaseByEmail.get('testcasepillar1@gusto.com').RecordTypeId, CaseUtils.RECTYPE_ENGAGEMENT, 'Record type not updated to Engagement');
		System.assertEquals(map_CaseByEmail.get('testcasepillar1@gusto.com').Type, CaseUtils.PAYROLL_CASE_PILLAR, 'Type not updated to Payroll');
		System.assertEquals(map_CaseByEmail.get('testcasepillar2@gusto.com').RecordTypeId, CaseUtils.RECTYPE_ENGAGEMENT, 'Record type not updated to Engagement');
		System.assertEquals(map_CaseByEmail.get('testcasepillar2@gusto.com').Type, CaseUtils.BENEFITS_CASE_PILLAR, 'Type not updated to Benefits');
		System.assertEquals(map_CaseByEmail.get('testcasepillar3@gusto.com').RecordTypeId, CaseUtils.RECTYPE_ENGAGEMENT, 'Record type not updated to Engagement');
		System.assertEquals(map_CaseByEmail.get('testcasepillar3@gusto.com').Type, CaseUtils.TAXES_CASE_PILLAR, 'Type not updated to Taxes');
	}

	/**
	 * @author 			Ankit C
	 * @description 	Test if the case type is updated based on case type pillar
	 */
	@isTest
	static void testCaseTypePillar2() {
		List<User> list_User = [SELECT Id FROM User WHERE Email = 'aptriggerhelpertest@gusto.com'];
		Map<String, Case> map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		List<Agatha_Prediction__c> list_AgathaPredictions = new List<Agatha_Prediction__c>();

		Agatha_Prediction__c objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(map_CaseByEmail.get('testcasepillar4@gusto.com').Id)
			.setReasonCode('test_tada')
			.setSupportLevel(CaseUtils.TIER_2)
			.setCaseType(CaseUtils.BENEFITS_CASE_PILLAR)
			.build();
		list_AgathaPredictions.add(objAgathaPrediction);

		Test.startTest();
		System.runAs(list_User[0]) {
			insert list_AgathaPredictions;
		}
		Test.stopTest();

		map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail, Type, RecordTypeId, Support_Level__c FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		System.assertEquals(map_CaseByEmail.get('testcasepillar4@gusto.com').Type, CaseUtils.TYPE_TADA, 'Type not updated to TAdA');
	}

	/**
	 * @author 			Pradeep Chary
	 * @description 	Test the case Auto Close Date time is updated if Case Reason Auto Email Behavior is Send
	 */
	@isTest
	static void testCaseAutoCloseDatetime() {
		Set<String> set_RoutingConfigNames = new Set<String> {
			'Engagement_Case',
			'Engagement_Case_Offline_Re_Route',
			'Engagement_Case_Route_Prior_Agent'
		};
		Map<String, QueueRoutingConfig> map_RoutingConfigByName = new Map<String, QueueRoutingConfig>();
		Map<String, Group> map_QueueByName = new Map<String, Group>();

		for (Group objGroup : [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name IN ('Engagement - Auto First Response Queue', 'Engagement Cases')]) {
			map_QueueByName.put(objGroup.Name, objGroup);
		}
		
		for (QueueRoutingConfig objRoutingConfig : [SELECT Id, DeveloperName FROM QueueRoutingConfig WHERE DeveloperName IN :set_RoutingConfigNames]) {
			map_RoutingConfigByName.put(objRoutingConfig.DeveloperName, objRoutingConfig);
		}

		Engagement_Flow_Configuration__c objFlowConfiguration = new TestDataFactory.FlowConfigurationBuilder()
			.setOwnerId(UserInfo.getOrganizationId())
			.setAcceptedValues('Payroll,Benefits,TAdA,Taxes,Gusto Global,Cancel,Cobra,Workers Comp,Retirement')
			.setFirstResponseQueueId(map_QueueByName.get('Engagement - Auto First Response Queue').Id)
			.setEngagementQueueId(map_QueueByName.get('Engagement Cases').Id)
			.setOmniRecordTypes('Engagement,Payroll_Care,Benefits_Care')
			.setIneligibleOrigins('Phone,Chat')
			.setEngagementRecordTypeId(CaseUtils.RECTYPE_ENGAGEMENT)
			.setEngagementRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case').Id)
			.setOfflineRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case_Offline_Re_Route').Id)
			.setPriorAgentRoutingConfigId(map_RoutingConfigByName.get('Engagement_Case_Route_Prior_Agent').Id)
			.build();

		insert objFlowConfiguration;

		Case objCase = [SELECT Id, Answer_IQ_Processed__c FROM Case WHERE Subject = 'Test auto close datetime' LIMIT 1];
		Case_Reason_Classification__c objCaseReason = [SELECT Id FROM Case_Reason_Classification__c WHERE Reason_Code__c = 'state_notice_reset'];

		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('state_notice_reset')
			.setSupportLevel('Tier 1')
			.setCaseType(CaseUtils.TYPE_ENGAGEMENT)
			.setCaseReasonConfidence(0.8)
			.build();

		Test.startTest();
		insert objPrediction;
		Test.stopTest();

		List<Case> list_Cases = [SELECT Id, Status, Auto_Close_Date_Time__c FROM Case WHERE Id = :objCase.Id];
		Assert.areNotEqual(null, list_Cases[0].Auto_Close_Date_Time__c, 'Close Date is null');
	}

	/**
	 * @author 			Sanjay Paryani
	 * @description 	Test if the case reasons specialization is updated on the case
	 */
	@isTest
	static void testCaseSpecialization1() {
		List<User> list_User = [SELECT Id FROM User WHERE Email = 'aptriggerhelpertest@gusto.com'];
		Map<String, Case> map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		List<Agatha_Prediction__c> list_AgathaPredictions = new List<Agatha_Prediction__c>();

		Agatha_Prediction__c objAgathaPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(map_CaseByEmail.get('testcasepillar4@gusto.com').Id)
			.setReasonCode('zp_giving_or_charity')
			.setSupportLevel('Tier 1')
			.build();
		list_AgathaPredictions.add(objAgathaPrediction);

		Test.startTest();
		System.runAs(list_User[0]) {
			insert list_AgathaPredictions;
		}
		Test.stopTest();

		map_CaseByEmail = new Map<String, Case>();
		for (Case objCase : [SELECT Id, SuppliedEmail, Type, RecordTypeId, Support_Level__c, Specialization__c FROM Case WHERE SuppliedEmail LIKE '%testcasepillar%']) {
			map_CaseByEmail.put(objCase.SuppliedEmail, objCase);
		}

		System.assertNotEquals(map_CaseByEmail.get('testcasepillar4@gusto.com').Specialization__c, null , 'Specialization not updated from case reason.');
	}	

	 /**
	 * @Author      : Soujanya N.j
	 * @Description : To test when agatha prediction is 'not_predicted'
	*/
	@isTest
	static void testProcessinformation() {        
        Case objCase = [SELECT Id, Answer_IQ_Eligible__c FROM Case WHERE Subject = 'Test case for Payroll pillar'];

		Agatha_Prediction__c objPrediction = new TestDataFactory.AgathaPredictionBuilder()
			.setCaseId(objCase.Id)
			.setReasonCode('not_predicted')
			.setSupportLevel('not_predicted')
			.setCaseType('not_predicted')
			.build();

		Test.startTest();
		insert objPrediction;
		Test.stopTest();

		Case objCaseQueried = [SELECT Id, Support_Level__c, Type FROM Case WHERE Subject = 'Test case for Payroll pillar'];
		System.assertEquals(objCaseQueried.Support_Level__c, 'Tier 1','Support level not updated to Tier 1');

	}
}