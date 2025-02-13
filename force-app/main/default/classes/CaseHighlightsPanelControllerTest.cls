@isTest
public class CaseHighlightsPanelControllerTest {
	@TestSetup
	static void setupData() {
		List<Case> list_Cases = new List<Case>();
		List<Case_Reason_Classification__c> list_CaseReasons = new List<Case_Reason_Classification__c>();
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setName('Test Account')
			.setRecordTypeId('Company')
			.build();
		insert objAccount;

		Contact objContact = new TestDataFactory.ContactBuilder()
			.setAccountId(objAccount.Id)
			.setFirstName('Test')
			.setLastName('Contact')
			.setEmail('testContact@gusto.com')
			.setRecordTypeId('Company')
			.build();
		insert objContact;
		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;

		Case_Reason_Classification__c objPayrollCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Payroll Care Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.build();
		list_CaseReasons.add(objPayrollCaseReason);

		Case_Reason_Classification__c objTaxResCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Generic Routing Test')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Tax Res')
			.setReasonCode('route_to_taxres')
			.build();
		list_CaseReasons.add(objTaxResCaseReason);

		Case_Reason_Classification__c objModernBankCaseReason= new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Route to Modern Bank')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Modern Bank')
			.build();
		list_CaseReasons.add(objModernBankCaseReason);

		Case_Reason_Classification__c objQueueOverrideCaseReason = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Payroll Care Reason Queue Override')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setGenericReason(true)
			.setQueueOverride('Test_Group')
			.build();
		list_CaseReasons.add(objQueueOverrideCaseReason);

		Case_Reason_Classification__c objQueueOverrideCaseReason2 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Route to Tax Res')
			.setIsActive(true)
			.setClass('Class 3')
			.setType('Tax Res')
			.setGenericReason(true)
			.setQueueOverride('TaxRes_Special_Project')
			.setReasonCode('route_to_taxres2')
			.build();
		list_CaseReasons.add(objQueueOverrideCaseReason2);
		
		insert list_CaseReasons;

		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		list_Cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Email')
			.setType('Payroll')
			.setSubject('Engagement test case')
			.setStatus('In Progress')
			.setSuppliedEmail('testengagement1@gusto.com')
			.setDescription('Engagement test case 1')
			.build();
		list_Cases.add(objCase2);

		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setOrigin('Email')
			.setType('Payroll')
			.setSubject('Engagement test case 2')
			.setStatus('Open')
			.setSuppliedEmail('testengagement2@gusto.com')
			.setDescription('Engagement test case 2')
			.build();
		list_Cases.add(objCase3);

		insert list_Cases;

		Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Vendor CX'];
		User objUser = new TestDataFactory.UserBuilder()
			.setLastName('Testing')
			.setAlias('testU')
			.setEmail('prc@test.com')
			.setUserName('prc@test.com')
			.setProfileId(objProfile.Id)
			.setVendor('Task Us')
			.build();
		insert objUser;
	}
	
	static testMethod void testGetCaseReasonClassification() {
		Case_Reason_Classification__c objCaseReason = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Test Payroll Care Reason'];
		Test.startTest();
		Case_Reason_Classification__c objCaseReasonFetched = CaseHighlightsPanelController.returnCaseReasonClassification(objCaseReason.Id);
		Test.stopTest();
		System.assertEquals(true, objCaseReasonFetched != null, 'Case Highlights Panel Controller - Unable to fetch case reason classification from Id');
		CaseHighlightsPanelController.returnCaseReasonClassification('testId');
	}

	static testMethod void testGetCaseReasonClassificationFromLabel() {
		Test.startTest();
		Case_Reason_Classification__c objCaseReasonFetched = CaseHighlightsPanelController.returnCaseReasonClassificationFromLabel('Test Payroll Care Reason', 'Payroll Care');
		Case_Reason_Classification__c objCRCGenericRouting = CaseHighlightsPanelController.returnCaseReasonClassificationFromLabel('Generic Routing Test', 'Generic Routing');
		Test.stopTest();
		System.assertEquals(true, objCaseReasonFetched != null, 'Case Highlights Panel Controller - Unable to fetch case reason classification from label');
	}

	static testMethod void testUpdateCaseRoutingClassification() {
		Case_Reason_Classification__c objCaseReason = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Test Payroll Care Reason'];
		Case objCase = [SELECT Id, Type, OwnerId, Status, RecordTypeId, Support_Level__c, Specialization__c,
			Answer_IQ_Eligible__c, Routing_Case_Reason_Classification__c, Class__c, Send_Survey__c, 
			Routing_Case_Reason__c, Case_In_Route__c, Skip_Subject_Routing__c, Reviewed_by_Dedicated_Support__c, Toggle__c
			FROM Case LIMIT 1
		];

		Test.startTest();
		CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper = CaseHighlightsPanelController.updateCaseRoutingClassification(
			objCase,
			'Payroll Care',
			objCaseReason.Id,
			'Class 1',
			''
		);
		Test.stopTest();
		System.assertEquals(true, objWrapper.blnIsSuccess, 'Case Highlights Panel Controller - Case routing without queue override not successful');
	}

	static testMethod void testUpdateCaseRoutingClassificationWithQueueOverride() {
		// Insert Test Case Queues between Test.startTest() and Test.stopTest()
		// All async calls complete after Test.stopTest();
		// Isolating insertTestCaseQueue() to a future method to avoid MIXED_DML_ISSUE
		Test.startTest();
		insertTestCaseQueue();
		Test.stopTest();

		Case_Reason_Classification__c objCaseReason = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Test Payroll Care Reason Queue Override'];
		Case objCase = [SELECT Id, Type, OwnerId, Status, RecordTypeId, Support_Level__c, Specialization__c,
			Answer_IQ_Eligible__c, Routing_Case_Reason_Classification__c, Class__c, Send_Survey__c, 
			Routing_Case_Reason__c, Case_In_Route__c, Skip_Subject_Routing__c, Reviewed_by_Dedicated_Support__c, Toggle__c
			FROM Case LIMIT 1
		];
		CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper = CaseHighlightsPanelController.updateCaseRoutingClassification(
			objCase,
			'Payroll Care',
			objCaseReason.Id,
			'Class 1',
			''
		);
		System.assertEquals(true, objWrapper.blnIsSuccess, 'Case Highlights Panel Controller - Case routing with queue override not successful');
	}

	@future
	public static void insertTestCaseQueue() {
		Group objGroup = new Group(Name = 'Test Group', Type = 'Queue', DeveloperName = 'Test_Group');
		insert objGroup;

		QueuesObject objQueue = new QueueSObject(QueueId = objGroup.Id, SobjectType = 'Case');
		insert objQueue;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Test exception handling
	 **/
	static testMethod void testExceptionHandling() {
		User objUser = [SELECT Id FROM User WHERE Username = 'prc@test.com'];
		Case_Reason_Classification__c objCaseReason = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Route to Tax Res'];
		Group objTXSpecialProjectQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'TaxRes_Special_Project'];
		Case objCase = [SELECT Id, Type, OwnerId, Status, RecordTypeId, Support_Level__c, Specialization__c,
			Answer_IQ_Eligible__c, Routing_Case_Reason_Classification__c, Class__c, Send_Survey__c, 
			Routing_Case_Reason__c, Case_In_Route__c, Skip_Subject_Routing__c, Reviewed_by_Dedicated_Support__c, Toggle__c
			FROM Case LIMIT 1
		];
		Test.startTest();
		objCase.OwnerId = objUser.Id;
		objCase.Subject = 'Wallet iPhone Questions';
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		System.runAs(objUser) {
			CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper = CaseHighlightsPanelController.updateCaseRoutingClassification(
				objCase,
				'Payroll Care',
				objCaseReason.Id,
				'Class 1',
				'Route to Tax Res'
			);
			System.assert(!objWrapper.blnIsSuccess, 'Exception did not occur');
		}
		Test.stopTest();
	}

	/**
     * @Author      : Ankit CS
     * @Description : Test method for updateCaseRoutingClassification to check if 
                      Skip_Subject_Routing__c is true if Case Owner is Care Routing
    **/
	static testMethod void testUpdateCaseRoutingClassificationCareRouting() {
		Case_Reason_Classification__c objPayrollCaseReason = new Case_Reason_Classification__c();
		Case_Reason_Classification__c objTaxResCaseReason = new Case_Reason_Classification__c();
		Case objCase = [SELECT Id, Type, OwnerId, Status, RecordTypeId, Support_Level__c, Specialization__c,
			Answer_IQ_Eligible__c, Routing_Case_Reason_Classification__c, Class__c, Send_Survey__c, 
			Routing_Case_Reason__c, Case_In_Route__c, Skip_Subject_Routing__c, Reviewed_by_Dedicated_Support__c, Toggle__c
			FROM Case LIMIT 1
		];
		Group objModernBankQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Modern Bank Routing'];
		for (Case_Reason_Classification__c objReason : [SELECT Id, Name FROM Case_Reason_Classification__c WHERE Name IN ('Test Payroll Care Reason', 'Route to Tax Res')]) {
			if (objReason.Name == 'Test Payroll Care Reason') {
				objPayrollCaseReason = objReason;
			} else if (objReason.Name == 'Route to Tax Res') {
				objTaxResCaseReason = objReason;
			}
		}

		objCase.Subject = 'Wallet iPhone Questions';
		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;

		Test.startTest();
		CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper = CaseHighlightsPanelController.updateCaseRoutingClassification(
			objCase,
			'Payroll Care',
			objPayrollCaseReason.Id,
			'Class 1',
			''
		);
		System.assertEquals(true, objWrapper.blnIsSuccess, 'Case Highlights Panel Controller - Case routing without queue override not successful');
		Case objUpdatedCase = [SELECT Id, Skip_Subject_Routing__c, Owner.Name FROM Case WHERE Id = :objCase.Id];
		System.assertNotEquals(objUpdatedCase.OwnerId, objModernBankQueue.Id);

		// Testing if Tax Res CRCs update the status to Tax Res status and not to Open or New (these are for non-taxres RTs)
		objWrapper = CaseHighlightsPanelController.updateCaseRoutingClassification(objCase, 'Tax Res', objTaxResCaseReason.Id, 'Class 3', 'Route to Tax Res');
		Case objUpdatedCaseTX = [SELECT Id, Type, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUpdatedCaseTX.Type, 'Tax Res');
		System.assertEquals(objUpdatedCaseTX.Status, 'Ready for Data Capture');

		Test.stopTest();
	}

	/**
	 * @description Testing routing engagement cases to modern bank
	 * @author		Ankit C
	 */
	static testMethod void testModernBankReroute() {
		Case_Reason_Classification__c objCaseReason = [SELECT Id, Name FROM Case_Reason_Classification__c WHERE Name = 'Route to Modern Bank'];
		Case objInProgressCase = new Case();
		Case objOpenCase = new Case();
		for (Case objCase : [SELECT Id, Type, OwnerId, Status, RecordTypeId, Support_Level__c, Specialization__c,
			Answer_IQ_Eligible__c, Routing_Case_Reason_Classification__c, Class__c, Send_Survey__c, 
			Routing_Case_Reason__c, Case_In_Route__c, Skip_Subject_Routing__c, Reviewed_by_Dedicated_Support__c, Toggle__c 
			FROM Case 
			WHERE RecordType.Name = 'Engagement'
		]) {
			if (objCase.Status == CaseUtils.STATUS_IN_PROGRESS) {
				objInProgressCase = objCase;
			} else if (objCase.Status == CaseUtils.STATUS_OPEN) {
				objOpenCase = objCase;
			}
		}

		Test.startTest();
		CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper1 = CaseHighlightsPanelController.updateCaseRoutingClassification(
			objInProgressCase,
			'Modern Bank',
			objCaseReason.Id,
			'Class 1',
			''
		);

		CaseHighlightsPanelController.CaseHighlightsPanelResponseWrapper objWrapper2 = CaseHighlightsPanelController.updateCaseRoutingClassification(
			objOpenCase,
			'Modern Bank',
			objCaseReason.Id,
			'Class 1',
			''
		);
		Test.stopTest();
		objInProgressCase = [SELECT Id, Status FROM Case WHERE Id = :objInProgressCase.Id];
		objOpenCase = [SELECT Id, Status FROM Case WHERE Id = :objOpenCase.Id];
		System.assert(objWrapper1.blnIsSuccess, 'Routing failed');
		System.assert(objWrapper2.blnIsSuccess, 'Routing failed');
		System.assertEquals(CaseUtils.STATUS_WORKING, objInProgressCase.Status, 'Status was not updated to Working');
		System.assertEquals(CaseUtils.STATUS_ACTIVE, objOpenCase.Status, 'Status was not updated to Active');
	}
}