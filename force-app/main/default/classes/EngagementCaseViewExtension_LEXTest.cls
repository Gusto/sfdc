@isTest
public class EngagementCaseViewExtension_LEXTest {
	@TestSetup
	static void setup() {
		List<Product_Area__c> list_productAreas = new List<Product_Area__c>();
		Product_Area__c objProductArea = new TestDataFactory.ProductAreaBuilder().setName('Test Product Area Payroll Care').build();
		list_productAreas.add(objProductArea);

		objProductArea = new TestDataFactory.ProductAreaBuilder().setName('Test Product Area Benefits Care').build();
		list_productAreas.add(objProductArea);
		insert list_productAreas;

		List<Sub_Product_Area__c> list_subProductAreas = new List<Sub_Product_Area__c>();
		Sub_Product_Area__c objSubProductArea = new TestDataFactory.SubProductAreaBuilder().setName('Test Sub Product Area Payroll Care').setProductArea(list_productAreas[0].Id).build();
		list_subProductAreas.add(objSubProductArea);

		objSubProductArea = new TestDataFactory.SubProductAreaBuilder().setName('Test Sub Product Area Benefits Care').setProductArea(list_productAreas[1].Id).build();
		list_subProductAreas.add(objSubProductArea);
		insert list_subProductAreas;

		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
		Case_Reason_Classification__c objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Payroll Care Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setProductArea(list_productAreas[0].Id)
			.setSubProductArea(list_subProductAreas[0].Id)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Payroll Care Reason With Required Fields')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setRequiredFields('BizDev Account')
			.setProductArea(list_productAreas[0].Id)
			.setSubProductArea(list_subProductAreas[0].Id)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Case Reason with incorrect field name')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setProductArea(list_productAreas[0].Id)
			.setSubProductArea(list_subProductAreas[0].Id)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder().setName('Tax Ops').setIsActive(true).setClass('Class 1').setType('Tax Ops').build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		objCaseReasonClassification = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Benefits Care Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Benefits Care')
			.setProductArea(list_productAreas[1].Id)
			.setSubProductArea(list_subProductAreas[1].Id)
			.build();
		list_CaseReasonClassifications.add(objCaseReasonClassification);

		Case_Reason_Classification__c objTaxResCRC = new TestDataFactory.CaseReasonClassificationBuilder().setName('Route to Tax Res').setIsActive(true).setClass('Class 3').setType('Tax Res').build();
		objTaxResCRC.Reason_Code__c = 'route_to_taxres';
		list_CaseReasonClassifications.add(objTaxResCRC);
		insert list_CaseReasonClassifications;

		Sub_Case_Reason_Classification__c objSubReasonClassification = new Sub_Case_Reason_Classification__c(Case_Reason__c = list_CaseReasonClassifications[0].Id);
		insert objSubReasonClassification;
	}

	@isTest
	static void testSetCaseInfo() {
		// Create a new Payroll Care Case
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);

		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		objLiveChatTranscript.CaseId = objCase.Id;
		insert objLiveChatTranscript;

		// Create Case Actions Field Config for Case Output Fields
		// Create a new Config JSON and insert a new criteria
		String strConfigJSON = '[{"size":"6","overrideLabel":"","label":"Follow Up Date","isVisible":true,"isRequired":false,"input":true,"criteriaList":null,"api":"Follow_Up_Date__c"},{"size":"6","overrideLabel":"","label":"Shared With","isVisible":false,"isRequired":false,"input":true,"criteriaList":null,"api":"Shared_With__c"},{"size":"6","overrideLabel":"Non English","label":"Non English Preferred Language","isVisible":false,"isRequired":false,"input":true,"criteriaList":null,"api":"Non_English_Preferred_Language__c"},{"size":"6","overrideLabel":"","label":"Escalated to","isVisible":false,"isRequired":false,"input":true,"criteriaList":null,"api":"Escalatedto__c"},{"size":"6","overrideLabel":"","label":"Related Incident:","isVisible":false,"isRequired":false,"input":true,"criteriaList":null,"api":"Related_to_Incident__c"},{"size":"6","overrideLabel":"Record Type","label":"Record Type ID","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"RecordTypeId"},{"size":"6","overrideLabel":"","label":"Class","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Class__c"},{"size":"6","overrideLabel":"","label":"Case Type","isVisible":false,"isRequired":false,"input":false,"criteriaList":[],"api":"Type"},{"size":"6","overrideLabel":"","label":"Case Origin","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Origin"},{"size":"6","overrideLabel":"","label":"Created Date","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"CreatedDate"},{"size":"12","overrideLabel":"","label":"Genesys Call Id","isVisible":false,"isRequired":false,"input":false,"criteriaList":[{"value":"","operator":"Not Equals","name":"Genesys Call Id","key":"criteria 0","api":"Genesys_Call_Id__c"}],"api":"Genesys_Call_Id__c"},{"size":"6","overrideLabel":"","label":"Send Survey","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Send_Survey__c"},{"size":"6","overrideLabel":"","label":"Priority","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Priority"},{"size":"6","overrideLabel":"","label":"Don’t Auto Solve","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Do_not_Auto_Solve__c"},{"size":"6","overrideLabel":"","label":"Task Us","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Task_Us__c"},{"size":"6","overrideLabel":"","label":"Routing Case Reason","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Routing_Case_Reason__c"},{"size":"6","overrideLabel":"","label":"Routing Case Reason Classification","isVisible":false,"isRequired":false,"input":false,"criteriaList":null,"api":"Routing_Case_Reason_Classification__c"},{"size":"6","overrideLabel":"","label":"Case Number","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"123","operator":"Not Contains","name":"Case Number","key":"criteria 0","api":"CaseNumber"}],"api":"CaseNumber"},{"size":"6","overrideLabel":"","label":"Status","isVisible":true,"isRequired":false,"input":true,"criteriaList":[{"value":"sol","operator":"Contains Ignore Case","name":"Status","key":"criteria 0","api":"Status"}],"api":"Status"}]';
		Case_Action_Fields__c objCaseOutputConfigForPayrollCare = new Case_Action_Fields__c(
			Is_Active__c = true,
			Display_Type__c = 'Action',
			SObject_Type__c = 'Case',
			Record_Type__c = 'Payroll Care',
			Configuration_JSON__c = strConfigJSON
		);
		insert objCaseOutputConfigForPayrollCare;

		// Insert two new case action fields config
		Case_Action_Fields__c objCaseOutputConfigForPayrollCareReadOnly = new Case_Action_Fields__c(
			Is_Active__c = true,
			Display_Type__c = 'Action',
			SObject_Type__c = 'Case',
			Record_Type__c = ' Payroll Care - Read Only',
			Configuration_JSON__c = strConfigJSON
		);
		insert objCaseOutputConfigForPayrollCareReadOnly;

		EngagementCaseViewExtension_LEX.CaseWrapper objWrapper = EngagementCaseViewExtension_LEX.setCaseInfo(objLiveChatTranscript.Id, true);
		Case objCaseRetrieved = EngagementCaseViewExtension_LEX.getCurrentCaseInfo(objCase.Id);
		List<Case_Reason_Classification__c> list_CaseReasonClassifications = [SELECT Id, Name, Active__c, Type__c, Fields_To_Require__c FROM Case_Reason_Classification__c];
		System.assertEquals(true, objWrapper.objCase != null, 'Engagement Case View Extension LEX - Unable to fetch case record');
		System.assert(!objWrapper.map_RequiredFieldsByCaseReason.containsKey(list_CaseReasonClassifications[0].Id));
		System.assert(objWrapper.map_RequiredFieldsByCaseReason.get(list_CaseReasonClassifications[1].Id).keySet().contains('Biz_Dev_Account__c'));
		System.assert(objWrapper.map_RequiredFieldsByCaseReason.get(list_CaseReasonClassifications[2].Id) == null);

		EngagementCaseViewExtension_LEX.CaseWrapper objWrapperSolveCase = EngagementCaseViewExtension_LEX.setCaseActionInfo(objCase.Id, '', '', true, true);
		System.assert(!objWrapperSolveCase.map_RequiredFieldsByCaseReason.containsKey(list_CaseReasonClassifications[0].Id));
	}

	@isTest
	static void testAcceptCase() {
		// Create a new Payroll Care Case
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		EngagementCaseViewExtension_LEX.CaseAuraResponse objResponse = EngagementCaseViewExtension_LEX.acceptCase(objCase);
		System.assertEquals(UserInfo.getUserId(), objResponse.objCase.OwnerId, 'Engagment Case View Extension LEX - Case not assigned to logged in user');
	}

	@isTest
	static void testGetSubCaseReason() {
		List<String> list_subCaseReason = EngagementCaseViewExtension_LEX.getConfirmSubCaseReason('Test Payroll Care Reason', 'Payroll Care');
		System.assertEquals(true, list_subCaseReason.size() > 0, 'Engagment Case View Extension LEX - Not able to sub case reason');
	}

	/**
	 * @author      : Elavarasan Nagarathinam
	 * @description : test if product area and sub product area records are available
	 */
	@isTest
	static void testGetProductSubproductArea() {
		EngagementCaseViewExtension_LEX.ProductAndSubproductAreaWrapper wrapper = EngagementCaseViewExtension_LEX.getProductSubproductArea();
		System.assertEquals(true, wrapper.list_ProductArea.size() > 0, 'No Product Area Found');
		System.assertEquals(true, wrapper.list_SubproductArea.size() > 0, 'No Sub Product Area Found');
	}

	/**
	 * @author      : Elavarasan Nagarathinam
	 * @description : test if there are sub case reasons for the given case reason
	 */
	@isTest
	static void testGetConfirmSubCaseReasonByCaseReason() {
		List<Case_Reason_Classification__c> list_CaseReasonClassificationRecords = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = 'Test Payroll Care Reason'];
		List<String> list_subCaseReasons = EngagementCaseViewExtension_LEX.getConfirmSubCaseReasonByCaseReason(list_CaseReasonClassificationRecords[0].Id);
		System.assertEquals(true, list_subCaseReasons.size() > 0, 'No Sub Case Reasons Found');
	}

	@isTest
	static void testSaveCaseRecord() {
		// Create a new Payroll Care Case
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);

		// Insert a new case reason classification
		Case_Reason_Classification__c objCaseReasonClassification = new Case_Reason_Classification__c(
			Active__c = true,
			Class__c = 'Class 1',
			Type__c = 'Payroll Care',
			Name = 'Test Payroll Care Reason'
		);
		insert objCaseReasonClassification;
		Sub_Case_Reason_Classification__c objSubCaseReasonClassification = new Sub_Case_Reason_Classification__c(
			Active__c = true,
			Name = 'Test Payroll Sub Care Reason1',
			Case_Reason__c = objCaseReasonClassification.id
		);
		upsert objSubCaseReasonClassification;
		objCase.Confirm_Sub_Case_Reason__c = objSubCaseReasonClassification.Name;
		objCase.Confirm_Case_Reason_Classification__c = objCaseReasonClassification.id;
		update objCase;
		EngagementCaseViewExtension_LEX.CaseAuraResponse objResponse = EngagementCaseViewExtension_LEX.saveCaseRecord(objCase, 'Payroll Care');
		objCase = [SELECT Id, Confirm_Sub_Case_Reason_Classification__c FROM Case WHERE Id = :objCase.Id];
		System.assert(objResponse.blnIsSuccess, 'Case was not updated.');
		System.assertEquals(objSubCaseReasonClassification.Id, objCase.Confirm_Sub_Case_Reason_Classification__c, 'No Sub Case Reasons Found');
	}

	/**
	 * @author      : Sanjay Paryani
	 * @description : test if confirm case reason belongs to Tax Res, status is from Tax Res
	 */
	static testMethod void testSaveCaseRecordTaxRes() {
		// Create a new Payroll Care Case
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', false);
		// And then the case is routed to Tax Res due to the Confirm Case Reason belonging to Tax Res type CRC.
		objCase.Confirm_Case_Reason__c = 'Route to Tax Res';
		insert objCase;

		Test.startTest();
		EngagementCaseViewExtension_LEX.CaseAuraResponse objResponse = EngagementCaseViewExtension_LEX.saveCaseRecord(objCase, 'Tax Res');
		Case objUpdatedCaseTX = [SELECT Id, Type, Status FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(objUpdatedCaseTX.Type, 'Tax Res');
		System.assertEquals(objUpdatedCaseTX.Status, 'Ready for Data Capture');

		Test.stopTest();
	}

	public static List<String> returnPickListValues(String strObjectName, String strFieldName) {
		List<String> lst_pickListValues = new List<String>();
		Schema.SObjectType s = Schema.getGlobalDescribe().get(strObjectName);
		Schema.DescribeSObjectResult r = s.getDescribe();
		Map<String, Schema.SObjectField> fields = r.fields.getMap();
		Schema.DescribeFieldResult fieldResult = fields.get(strFieldName).getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			lst_pickListValues.add(pickListVal.getValue());
		}
		return lst_pickListValues;
	}

	/**
	 * @author      : Alex Xiong
	 * @description : test if different users with different record type access see different case reason classifications
	 */
	@isTest
	public static void testCaseReasonAccess() {
		Test.startTest();
		Profile objPRC = [SELECT Id FROM Profile WHERE Name = 'Vendor CX'];
		Profile objZP = [SELECT Id FROM Profile WHERE Name = 'ZP System Administrator'];

		User objPRCUser = new User(
			Alias = 'testU',
			Email = 'prc@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'prc@test.com',
			ProfileId = objPRC.Id
		);

		User objZPUser = new User(
			Alias = 'testU2',
			Email = 'zp@test.com',
			LastName = 'Testing',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = 'zp@test.com',
			ProfileId = objZP.Id
		);
		Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
		Integer intNumberOfCaseReasonTypesPRC = 0;
		Integer intNumberOfCaseReasonTypesZP = 0;

		System.runAs(objPRCUser) {
			EngagementCaseViewExtension_LEX.CaseWrapper objWrapper = EngagementCaseViewExtension_LEX.setCaseInfo(objCase.Id, true);
			intNumberOfCaseReasonTypesPRC = objWrapper.map_caseReasonToGroupMap.keySet().size();
		}

		System.runAs(objZPUser) {
			EngagementCaseViewExtension_LEX.CaseWrapper objWrapper = EngagementCaseViewExtension_LEX.setCaseInfo(objCase.Id, true);
			intNumberOfCaseReasonTypesZP = objWrapper.map_caseReasonToGroupMap.keySet().size();
		}
		Test.stopTest();

		System.assertNotEquals(intNumberOfCaseReasonTypesPRC, intNumberOfCaseReasonTypesZP, 'Payroll Care and ZP System Admin should not have the same access');
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Test if case create eligibility method is working fine
	 */
	@isTest
	public static void testCheckCaseCreateFromTranscript() {
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		insert objLiveChatTranscript;

		Test.startTest();
		Boolean blnCaseCreateEligible = EngagementCaseViewExtension_LEX.checkCaseCreateFromTranscript(objLiveChatTranscript.Id);
		Test.stopTest();

		System.assertEquals(false, blnCaseCreateEligible);
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Test if case is created from chat transcript
	 */
	@isTest
	public static void testCaseCreateFromTranscript() {
		// Insert a new LiveChat Visitor (Required field for LiveChatTranscript)
		LiveChatVisitor objLiveChatVisitor = new LiveChatVisitor();
		insert objLiveChatVisitor;

		// Insert a new LiveChatTranscript record and link to the Case
		LiveChatTranscript objLiveChatTranscript = new LiveChatTranscript();
		objLiveChatTranscript.LiveChatVisitorId = objLiveChatVisitor.Id;
		insert objLiveChatTranscript;

		Test.startTest();
		String strCaseId = EngagementCaseViewExtension_LEX.createCaseFromTranscript(objLiveChatTranscript.Id, 'Modern Bank');
		Test.stopTest();

		LiveChatTranscript objTranscriptAssert = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :objLiveChatTranscript.Id];
		System.assertEquals(strCaseId, objTranscriptAssert.CaseId);
	}
}