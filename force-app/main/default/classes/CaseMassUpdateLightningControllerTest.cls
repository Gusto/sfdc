@isTest
public class CaseMassUpdateLightningControllerTest {
	static final Id ID_LOGGED_USER = UserInfo.getUserId();

	@TestSetup
	static void setup() {
		Configuration_Settings__c objConfig = new TestDataFactory.ConfigurationSettingsBuilder().setCloseOppsBatchSize(10).build();
		objConfig.TaxRes_Round_Robin_Case_DML_Limit__c = 5;
		insert objConfig;

		List<Case> list_Cases = new List<Case>();
		Case objCase1 = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Subject = 'Test Chatter 1',
			Description = 'Test Chatter',
			SuppliedEmail = 'test.test@gusto.com',
			Type = 'Payroll Care',
			Origin = 'Email',
			Direction__c = 'Inbound'
		);
		list_Cases.add(objCase1);

		Case objCase2 = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Subject = 'Test Chatter 2',
			Description = 'Test Chatter',
			SuppliedEmail = 'test.test@gusto.com',
			Type = 'Payroll Care',
			Origin = 'Email',
			Direction__c = 'Inbound'
		);
		list_Cases.add(objCase2);

		Case objCase3 = new Case(
			RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care'),
			Subject = 'Test Chatter 3',
			Description = 'Test Chatter',
			SuppliedEmail = 'test.test@gusto.com',
			Type = 'Payroll Care',
			Origin = 'Email',
			Direction__c = 'Inbound'
		);
		list_Cases.add(objCase3);

		Case objCase4 = new TestDataFactory.CaseBuilder().setRecordTypeId('MF NHE').setOrigin('Phone').setStatus('Pending').build();
		list_Cases.add(objCase4);
		Case objCase5 = new TestDataFactory.CaseBuilder().setRecordTypeId('MF Member/Group Updates').setOrigin('Phone').setStatus('Pending').build();
		list_Cases.add(objCase5);
		CaseTriggerHelper.skipTrigger = true;
		insert list_Cases;

		List<Case_RecordType_FieldSet_Setting__c> list_CaseRecordTypeFieldSetting = new List<Case_RecordType_FieldSet_Setting__c>();

		Case_RecordType_FieldSet_Setting__c obj = new Case_RecordType_FieldSet_Setting__c();
		obj.Name = 'MF Member/Group Updates';
		obj.Field_Set_API_Name__c = 'MF_Mass_Update';

		list_CaseRecordTypeFieldSetting.add(obj);

		Case_RecordType_FieldSet_Setting__c obj1 = new Case_RecordType_FieldSet_Setting__c();
		obj1.Name = 'MF NHE';
		obj1.Field_Set_API_Name__c = 'MF_Mass_Update';

		list_CaseRecordTypeFieldSetting.add(obj1);

		Case_RecordType_FieldSet_Setting__c obj2 = new Case_RecordType_FieldSet_Setting__c();
		obj2.Name = 'MF Termination';
		obj2.Field_Set_API_Name__c = 'MF_Mass_Update';

		list_CaseRecordTypeFieldSetting.add(obj2);

		insert list_CaseRecordTypeFieldSetting;
	}

	static testMethod void testFetchRelatedCases() {
		//Method to fetch cases
		List<String> caseIdList = new List<String>();
		Case caseObj = new Case(Status = 'New', Origin = 'Phone');
		insert caseObj;
		caseIdList.add(caseObj.Id);

		Test.startTest();
		List<Case> caseList = CaseMassUpdateLightningController.fetchRelatedCases(caseIdList);
		System.assertEquals(true, caseList.size() > 0);
		Test.stopTest();
	}

	static testMethod void testMassUpdateEligibility() {
		//Method to check whether case record type is eligible for mass update or not
		Case caseObj = new Case(Status = 'New', Origin = 'Phone');
		insert caseObj;

		Test.startTest();
		CaseMassUpdateLightningController.CaseMassUpdateAuraResponse objResponse = CaseMassUpdateLightningController.checkMassUpdateEligibility(caseObj.Id);
		System.assertEquals(true, objResponse != null);
		Test.stopTest();
	}

	static testMethod void testMassUpdateAndRouteCase() {
		//Method to mass update and route cases
		List<String> caseIdList = new List<String>();
		Case caseObj = new Case(Status = 'New', Origin = 'Phone');
		insert caseObj;
		caseIdList.add(caseObj.Id);
		List<String> attributeList = new List<String>();
		attributeList.add('Status');

		Test.startTest();
		CaseMassUpdateLightningController.CaseMassUpdateAuraResponse objResponse = CaseMassUpdateLightningController.massUpdateAndRouteCase(
			caseObj,
			true,
			attributeList,
			caseIdList,
			false,
			'',
			'',
			'',
			'',
			'',
			false
		);
		System.assertEquals(true, objResponse != null);
		Test.stopTest();
	}

	static testMethod void testGetFieldAPIName() {
		//Method to fetch field api name
		Case_RecordType_FieldSet_Setting__c obj = new Case_RecordType_FieldSet_Setting__c();
		obj.Name = 'Benefits Care';
		obj.Field_Set_API_Name__c = 'BenefitCareMassUpdate';
		insert obj;

		List<String> caseIdList = new List<String>();
		Case caseObj = new Case(Status = 'New', Origin = 'Phone');
		insert caseObj;
		caseIdList.add(caseObj.Id);

		Test.startTest();
		CaseMassUpdateLightningController.CaseFieldSetResponse objResponse = CaseMassUpdateLightningController.returnFieldNameAPIList(obj.Name);
		System.assertEquals(true, objResponse != null);
		Test.stopTest();
	}

	static testMethod void testGetLsiList() {
		//Method to Populate values from Large_Scale_Issue__c when record type is Tax Res
		Large_Scale_Issue__c lsiObj = new Large_Scale_Issue__c(Name = 'Test');
		insert lsiObj;

		Test.startTest();
		List<String> listList = CaseMassUpdateLightningController.getlsiList();
		System.assertEquals(true, listList.size() > 0);
		Test.stopTest();
	}

	static testMethod void testGetCaseReasons() {
		String rtName = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Benefits Care').getName();
		Case_Reason_Classification__c caseReasonObj = new Case_Reason_Classification__c(Name = 'test', Class__c = 'Class 1');
		insert caseReasonObj;
		Test.startTest();
		List<String> caseReasonList = CaseMassUpdateLightningController.getCaseReasons(rtName);
		System.assertEquals(false, caseReasonList.size() > 0);
		Test.stopTest();
	}

	/**
	 * @Author:         Alex Xiong
	 * @Description:    Tests massUpdateAndRouteCase() ConnectAPI postFeedElementBatch() function with mocking from ConnectAPIMock.cls
	 */
	@isTest
	public static void testMassUpdateAndRouteCaseChatter() {
		List<Case> list_Cases = [SELECT Id FROM Case];
		List<Id> list_Ids = new List<Id>();

		// Set the test data
		ConnectApi.FeedElementPage objTestPage = new ConnectApi.FeedElementPage();
		List<ConnectApi.FeedItem> list_TestItem = new List<ConnectApi.FeedItem>();

		for (Case objCse : list_Cases) {
			list_Ids.add(objCse.Id);
			list_TestItem.add(new ConnectApi.FeedItem());
		}

		objTestPage.Elements = list_TestItem;
		ConnectApi.ChatterFeeds.setTestGetFeedElementsFromFeed(null, ConnectApi.FeedType.RECORD, 'me', objTestPage);

		Case objCase = new Case(Status = 'In Progress');
		List<String> list_Attr = new List<String>();
		list_Attr.add('Status');
		CaseMassUpdateLightningController.massUpdateAndRouteCase(objCase, true, list_Attr, list_Ids, true, 'hello world', '', '', '', '', false);

		Test.startTest();
		System.assertEquals(list_Cases.size(), ConnectAPIMock.getFeedCount());
		Test.stopTest();
	}

	/**
	 * @Author:         Pravesh Rana
	 * @Description:    Tests MassUpdateAndRouteCase() for taxRes Cases
	 */
	@isTest
	public static void testMassUpdateAndRouteCaseTaxRes() {
		List<String> list_AttributeList = new List<String>();
		list_AttributeList.add('Status');
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.createAgencyInformation();
		Role__c objRole = TestDataFactory.createRole('Account Specialist');
		Region_POD__c objRegionPOD = TestDataFactory.createAgencyRegion('Test AS Region', 'Account Specialist');
		List<Region_POD_mapping__c> list_RegionPODMappings = TestDataFactory.createAgencyRegionPODMapping(objRegionPOD, list_AgencyInformations);

		List<String> list_CaseIds = new List<String>();
		Case objCase = new Case(Status = 'New', Origin = 'Phone');
		objCase.RecordTypeId = CaseUtils.RECTYPE_TAXRES;
		objCase.Agency_Information__c = list_AgencyInformations[0].Id;
		insert objCase;
		list_CaseIds.add(objCase.Id);

		List<Skill__c> list_Skills = TestDataFactory.createSkill(objRole, list_RegionPODMappings);
		User_Role__c objUsereRole = TestDataFactory.createUserRole('Account Specialist');
		List<User_Skill__c> list_UserSkills = TestDataFactory.createUserSkill(objUsereRole, list_Skills);

		Test.startTest();
		CaseMassUpdateLightningController.CaseMassUpdateAuraResponse objResponse = CaseMassUpdateLightningController.massUpdateAndRouteCase(
			objCase,
			false,
			list_AttributeList,
			list_CaseIds,
			false,
			'',
			ID_LOGGED_USER,
			'Account Specialist',
			'Ready for Research',
			'ic_assignment',
			false
		);
		System.assertEquals(true, objResponse != null);

		ListView objListView = CaseMassUpdateLightningController.getListViews('Case', 'Tax Res - My Cases Requires Action');
		System.assertEquals(true, objListView != null);

		CaseMassUpdateLightningController.CaseUpdateChatterWrapper objWrapper = new CaseMassUpdateLightningController.CaseUpdateChatterWrapper(list_CaseIds, 'test');
		CaseMassUpdateLightningController.postChatterFuture(JSON.serialize(objWrapper));

		Test.stopTest();

		List<Case> list_QueriedCases = [SELECT Id, Account_Specialist__c, OwnerId, Status FROM Case WHERE RecordType.Name = 'Tax Res'];
		System.assertEquals(list_QueriedCases[0].Account_Specialist__c, ID_LOGGED_USER);
		System.assertEquals(list_QueriedCases[0].OwnerId, ID_LOGGED_USER);
		System.assertEquals(list_QueriedCases[0].Status, 'Ready for Research');
	}
	/**
	 * @Author:         Pawan Kumar
	 * @Description:    Tests testMassUpdateAndRouteCaseMFRT() for MFRT Cases
	 */
	@isTest
	public static void testMassUpdateAndRouteCaseMFRT() {
		CaseTriggerHelper.skipTrigger = true;
		List<String> list_AttributeList = new List<String>();
		list_AttributeList.add('Status');
		list_AttributeList.add('Submission_Method__c');
		List<Id> list_CaseIds = new List<Id>();
		for (case objCase : [SELECT Id FROM Case WHERE recordType.Name LIKE 'MF%']) {
			list_CaseIds.add(objCase.Id);
		}
		Case objCaseRecord = new Case(RecordTypeId = cache.getRecordTypeId('Case', 'MF Termination'), Status = 'New', Submission_Method__c = 'Mapped Form');
		Test.startTest();
		CaseMassUpdateLightningController.CaseMassUpdateAuraResponse objResponse = CaseMassUpdateLightningController.massUpdateAndRouteCase(
			objCaseRecord,
			false,
			list_AttributeList,
			list_CaseIds,
			false,
			'',
			'',
			'',
			'Closed',
			'',
			true
		);
		List<Case> list_MFRTCases = [SELECT Id, Status, Submission_Method__c, ownerId FROM Case WHERE Id IN :list_CaseIds];
		System.assertEquals(list_MFRTCases[0].Submission_Method__c, 'Mapped Form', 'Did Not Match');
		System.assertEquals(list_MFRTCases[0].OwnerId, GlobalQueryHelper.getGroupsByName('MF_Completed').get(0).Id, 'Did Not Match');
		System.assertEquals(list_MFRTCases[0].Status, 'New', 'Did Not Match');
		Test.stopTest();
	}
}