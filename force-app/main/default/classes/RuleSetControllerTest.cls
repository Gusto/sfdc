/**
 * @description  Used for testing NBA Rule Set Configuration Functtionality
 * @author       Praveen Sethu
 * @date         09-06-2023
 * @see          nbaRuleSetConfig LWC
 **/
@isTest
public class RuleSetControllerTest {
	/**
	 * @author      Praveen Sethu
	 * @description Setup needed for all test methods. Creates NBA Rule Set Configuration record for logged in user's user role
	 **/
	@testSetup
	static void setup() {
		// Get logged in user role Id
		Id idLoggedInUserRoleId = UserInfo.getUserRoleId();
		String strUserRole = '';
		// Check if logged in user has a role
		if (idLoggedInUserRoleId != null) {
			// Query from user role object
			UserRole objUserRole = [SELECT Id, Name FROM UserRole WHERE Id = :idLoggedInUserRoleId];
			if (objUserRole != null && String.isNotBlank(objUserRole.Name)) {
				strUserRole = objUserRole.Name;
			}
		}

		// create rule set configuration record for logged in user's user role
		NBA_Rule_Set_Configuration__c objRuleSetConfig = new TestDataFactory.NBARuleSetConfigBuilder().setConfigName('Test Config').setUserRoles(strUserRole).setAbbreviation('TEST').build();
		insert objRuleSetConfig;
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setIntNBAEnforceBatchingRuleSetSize(2).setIntNBADefaultRulesPerExecution(1).build();
		insert objConfigSettings;
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test retrieval of rule sets. Insert a rule set and use getRuleSet method to validate the retrieval.
	 **/
	@isTest
	static void testGetRuleSet() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// insert an active rule set
		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder()
			.setDescription('Test Description')
			.setActive(true)
			.setPriority(1)
			.setRuleName('Test Rule Name')
			.setRuleSetName('Test Rule Set Name')
			.setWeighting(100)
			.setRuleSetConfig(objRuleSetConfig.Id)
			.build();
		insert objRuleSet;

		// start test and retrieve the rule set
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.getRuleSet(objRuleSetConfig.Name);
		Test.stopTest();

		// assert if the retrieval was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Unable to retrieve rule sets');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if updating rule set is successful
	 **/
	@isTest
	static void testUpdateRuleSet() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// insert an active rule set
		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder()
			.setDescription('Test Description')
			.setActive(true)
			.setPriority(1)
			.setRuleName('Test Rule Name')
			.setRuleSetName('Test Rule Set Name')
			.setWeighting(100)
			.setRuleSetConfig(objRuleSetConfig.Id)
			.build();
		insert objRuleSet;

		// start test method and call update rule set method
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.updateRuleSets(new List<NBA_Rule_Set__c>{ objRuleSet }, null);
		Test.stopTest();

		// assert if the update was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Unable to update rule set record');
	}

	/**
	 * @author      Omar Benitez
	 * @description Test if updating rule set is successful for batching defaults
	 **/
	@isTest
	static void testUpdateRuleSetWithBatching() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// insert an active rule set
		List<NBA_Rule_Set__c> listRuleSet = new List<NBA_Rule_Set__c>();
		listRuleSet.add(
			new TestDataFactory.NBARuleSetBuilder()
				.setDescription('Test Description')
				.setActive(false)
				.setPriority(1)
				.setRuleName('Test Rule Name')
				.setRuleSetName('Test Rule Set Name')
				.setWeighting(100)
				.setRuleSetConfig(objRuleSetConfig.Id)
				.build()
		);
		listRuleSet.add(
			new TestDataFactory.NBARuleSetBuilder()
				.setDescription('Test Description')
				.setActive(false)
				.setPriority(1)
				.setRuleName('Test Rule Name')
				.setRuleSetName('Test Rule Set Name')
				.setWeighting(100)
				.setRuleSetConfig(objRuleSetConfig.Id)
				.build()
		);
		insert listRuleSet;
		objRuleSetConfig = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		System.assertEquals(null, objRuleSetConfig.Rules_per_Execution__c);
		listRuleSet[0].Is_Active__c = true;
		listRuleSet[1].Is_Active__c = true;
		// start test method and call update rule set method
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.updateRuleSets(listRuleSet, null);
		Test.stopTest();
		objRuleSetConfig = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// assert if the update was successful
		System.assertEquals(1, objRuleSetConfig.Rules_per_Execution__c, 'Value needs to be the same than the configuration setting');
	}

	/**
	 * @author      Omar Benitez
	 * @description Test if updating rule set is successful for batching defaults
	 **/
	@isTest
	static void testUpdateRuleSetWithBatchingToNull() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// insert an active rule set
		List<NBA_Rule_Set__c> listRuleSet = new List<NBA_Rule_Set__c>();
		listRuleSet.add(
			new TestDataFactory.NBARuleSetBuilder()
				.setDescription('Test Description')
				.setActive(false)
				.setPriority(1)
				.setRuleName('Test Rule Name')
				.setRuleSetName('Test Rule Set Name')
				.setWeighting(100)
				.setRuleSetConfig(objRuleSetConfig.Id)
				.build()
		);
		listRuleSet.add(
			new TestDataFactory.NBARuleSetBuilder()
				.setDescription('Test Description')
				.setActive(false)
				.setPriority(1)
				.setRuleName('Test Rule Name')
				.setRuleSetName('Test Rule Set Name')
				.setWeighting(100)
				.setRuleSetConfig(objRuleSetConfig.Id)
				.build()
		);
		insert listRuleSet;
		objRuleSetConfig = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		System.assertEquals(null, objRuleSetConfig.Rules_per_Execution__c);
		listRuleSet[0].Is_Active__c = true;
		listRuleSet[1].Is_Active__c = true;
		// start test method and call update rule set method
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.updateRuleSets(listRuleSet, null);
		objRuleSetConfig = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		System.assertEquals(1, objRuleSetConfig.Rules_per_Execution__c, 'Value needs to be the same than the configuration setting');
		listRuleSet[1].Is_Active__c = false;
		objRuleSetWrapper = RuleSetController.updateRuleSets(listRuleSet, null);
		Test.stopTest();
		objRuleSetConfig = [SELECT Id, Rules_per_Execution__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// assert if the update was successful
		System.assertEquals(null, objRuleSetConfig.Rules_per_Execution__c, 'Value needs to be null');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test retrieval of unique rule set names.
	 **/
	@isTest
	static void getRuleSetNames() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// insert an active rule set with valid rule set name
		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder()
			.setDescription('Test Description')
			.setActive(true)
			.setPriority(1)
			.setRuleName('Test Rule Name')
			.setRuleSetName('Test Rule Set Name')
			.setWeighting(100)
			.setRuleSetConfig(objRuleSetConfig.Id)
			.build();
		insert objRuleSet;

		// start test method and call get rule set names method
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.getRuleSets();
		Test.stopTest();

		// assert if the retrieval was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Unable to retrieve rule set names');
		// assert if the rule set name is retrieved
		System.assertEquals(true, objRuleSetWrapper.list_TeamNames.size() > 0, 'Unable to retrieve rule set names');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if we are able to fetch leads and opportunity records successfully
	 **/
	@isTest
	static void testGetRecordsFromRule() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id != NULL ORDER BY Opportunity__r.CreatedDate DESC';
		objRequestWrapper.servingObject = 'Opportunity';
		objRequestWrapper.servingField = 'Opportunity__c';
		objRequestWrapper.baseObject = 'Opportunity_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		List<NBARequestWrapper.DisplayFieldsList> displayFieldsList = new List<NBARequestWrapper.DisplayFieldsList>{
			new NBARequestWrapper.DisplayFieldsList(),
			new NBARequestWrapper.DisplayFieldsList()
		};
		displayFieldsList[0].selectedFieldAPI = 'id';
		displayFieldsList[0].selectedField = 'Lead Related Tracking > Record ID';
		displayFieldsList[0].customText = 'Record ID';

		displayFieldsList[1].selectedFieldAPI = 'opportunity__r.name';
		displayFieldsList[1].selectedField = 'Lead Related Tracking > Lead Name';
		displayFieldsList[1].customText = 'Lead Name';

		objRequestWrapper.displayFieldsList = displayFieldsList;

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Opportunity_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

		// create a new company account and an open company opportunity
		Account objCompAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('NBA Demo Account').setZPCompanyId('1234567890').build();
		insert objCompAcc;

		// create new company opportunity
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('NBA Demo Opp - Payroll')
			.setAccountId(objCompAcc.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		// start test method and call the method we are validating
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.getRecordsFromRuleNew(objRuleSet.Id);
		RuleSetController.RuleSetWrapper objCountWrapper = RuleSetController.getRecordCount(objRuleSet.Id);
		Test.stopTest();

		// Assert if method call was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Error in retrieving modal leads and opportunities');
		System.assertEquals(true, objRuleSetWrapper.list_ViewRecords.size() > 0, 'No records were returned');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test positive use case of updating rule set configuration and validate to receieve success message
	 **/
	@isTest
	static void testRuleSetConfigUpdatePositive() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name, User_Roles__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// Add a new role to the existing user role and validate if the update was successful
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.saveRuleSetConfig(objRuleSetConfig.Name, objRuleSetConfig.User_Roles__c + ',user role 2');
		Test.stopTest();

		// Assert if method call was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Error in updating rule set configuration');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test negative use case of updating rule set configuration and validate to receieve error flag and message
	 **/
	@isTest
	static void testRuleSetConfigUpdateNegative() {
		// update user role on the rule set configuration record
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name, User_Roles__c FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		objRuleSetConfig.User_Roles__c = objRuleSetConfig.User_Roles__c + ',user role 2';
		update objRuleSetConfig;

		// create a second configuration record and update the same user role, you should get an error message
		NBA_Rule_Set_Configuration__c objRuleSetConfig2 = new TestDataFactory.NBARuleSetConfigBuilder().setConfigName('Test Config 2').setAbbreviation('AAA').build();
		insert objRuleSetConfig2;

		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.saveRuleSetConfig(objRuleSetConfig2.Name, 'user role 2');
		Test.stopTest();

		// Assert if method call was successful and returned an error message
		System.assertEquals(false, objRuleSetWrapper.blnIsSuccess, 'Rule set configuration update was successful');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test cloning of rule set record and validate if the cloned record is created successfully
	 **/
	@isTest
	static void testCloningRuleSet() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id != NULL ORDER BY Opportunity__r.CreatedDate DESC';
		objRequestWrapper.servingObject = 'Opportunity';
		objRequestWrapper.servingField = 'Opportunity__c';
		objRequestWrapper.baseObject = 'Opportunity_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		List<NBARequestWrapper.DisplayFieldsList> displayFieldsList = new List<NBARequestWrapper.DisplayFieldsList>{
			new NBARequestWrapper.DisplayFieldsList(),
			new NBARequestWrapper.DisplayFieldsList()
		};
		displayFieldsList[0].selectedFieldAPI = 'id';
		displayFieldsList[0].selectedField = 'Lead Related Tracking > Record ID';
		displayFieldsList[0].customText = 'Record ID';

		displayFieldsList[1].selectedFieldAPI = 'opportunity__r.name';
		displayFieldsList[1].selectedField = 'Lead Related Tracking > Lead Name';
		displayFieldsList[1].customText = 'Lead Name';

		objRequestWrapper.displayFieldsList = displayFieldsList;

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Opportunity_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

		Test.startTest();
		NBA_Rule_Set__c objNewRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		RuleSetController.createNewRuleSet(objNewRuleSet, objRuleSet.Id);
		Test.stopTest();

		// Assert if method call was successful
		NBA_Rule_Set__c objClonedRuleSet = [SELECT Id, Rule_Name__c, (SELECT Id FROM NBA_Rule_Criteria__r) FROM NBA_Rule_Set__c WHERE Rule_Name__c = 'Test Rule Set 2'];
		System.assertEquals(1, objClonedRuleSet.NBA_Rule_Criteria__r.size(), 'Cloned rule set was not created successfully');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test creation of new rule set record and validate if the record is created successfully
	 **/
	@isTest
	static void testRuleSetConfig() {
		Test.startTest();
		NBA_Rule_Set_Configuration__c objRuleSetConfig = new TestDataFactory.NBARuleSetConfigBuilder().setConfigName('Test Rule Set Config 2').setAbbreviation('SBOB1').build();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.createNewRuleConfig(objRuleSetConfig);
		Test.stopTest();

		// Assert if method call was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'Error in creating new rule set configuration');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test validation of hold out field on serving object
	 **/
	@isTest
	static void testHoldOutValidation() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id != NULL ORDER BY Opportunity__r.CreatedDate DESC';
		objRequestWrapper.servingObject = 'Opportunity';
		objRequestWrapper.servingField = 'Opportunity__c';
		objRequestWrapper.baseObject = 'Opportunity_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		List<NBARequestWrapper.DisplayFieldsList> displayFieldsList = new List<NBARequestWrapper.DisplayFieldsList>{
			new NBARequestWrapper.DisplayFieldsList(),
			new NBARequestWrapper.DisplayFieldsList()
		};
		displayFieldsList[0].selectedFieldAPI = 'id';
		displayFieldsList[0].selectedField = 'Lead Related Tracking > Record ID';
		displayFieldsList[0].customText = 'Record ID';

		displayFieldsList[1].selectedFieldAPI = 'opportunity__r.name';
		displayFieldsList[1].selectedField = 'Lead Related Tracking > Lead Name';
		displayFieldsList[1].customText = 'Lead Name';

		objRequestWrapper.displayFieldsList = displayFieldsList;

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Opportunity_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.holdOutValidation(new List<NBA_Rule_Set__c>{ objRuleSet });
		Test.stopTest();

		System.assertEquals(true, objRuleSetWrapper.map_HoldOutErrors.isEmpty(), 'Error in validating hold out field');
	}

	/**
	 * @author      Omar Benitez
	 * @description Test if we are able to refresh all rules successfully
	 **/
	@isTest
	static void testRefreshAllRules() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id != NULL ORDER BY Opportunity__r.CreatedDate DESC';
		objRequestWrapper.servingObject = 'Opportunity';
		objRequestWrapper.servingField = 'Opportunity__c';
		objRequestWrapper.baseObject = 'Opportunity_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		List<NBARequestWrapper.DisplayFieldsList> displayFieldsList = new List<NBARequestWrapper.DisplayFieldsList>{
			new NBARequestWrapper.DisplayFieldsList(),
			new NBARequestWrapper.DisplayFieldsList()
		};
		displayFieldsList[0].selectedFieldAPI = 'id';
		displayFieldsList[0].selectedField = 'Lead Related Tracking > Record ID';
		displayFieldsList[0].customText = 'Record ID';

		displayFieldsList[1].selectedFieldAPI = 'opportunity__r.name';
		displayFieldsList[1].selectedField = 'Lead Related Tracking > Lead Name';
		displayFieldsList[1].customText = 'Lead Name';

		objRequestWrapper.displayFieldsList = displayFieldsList;
		List<NBA_Rule_Set__c> list_RuleSet = new List<NBA_Rule_Set__c>();
		list_RuleSet.add(new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 1').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build());
		list_RuleSet.add(new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build());
		list_RuleSet.add(new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 3').setPriority(3).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build());
		list_RuleSet.add(new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 4').setPriority(4).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build());

		insert list_RuleSet;
		List<NBA_Rule_Criteria__c> list_Criteria = new List<NBA_Rule_Criteria__c>();
		list_Criteria.add(
			new TestDataFactory.NBARuleCriteriaBuilder()
				.setBaseObject('Opportunity_Related_Tracking__c')
				.setCurrentCriteria(JSON.serialize(objRequestWrapper))
				.setPreviousCriteria(JSON.serialize(objRequestWrapper))
				.setTalkingPoints('Test Talking Points')
				.setRuleSet(list_RuleSet[0].Id)
				.build()
		);
		list_Criteria.add(
			new TestDataFactory.NBARuleCriteriaBuilder()
				.setBaseObject('Opportunity_Related_Tracking__c')
				.setCurrentCriteria(JSON.serialize(objRequestWrapper))
				.setPreviousCriteria(JSON.serialize(objRequestWrapper))
				.setTalkingPoints('Test Talking Points')
				.setRuleSet(list_RuleSet[1].Id)
				.build()
		);
		list_Criteria.add(
			new TestDataFactory.NBARuleCriteriaBuilder()
				.setBaseObject('Opportunity_Related_Tracking__c')
				.setCurrentCriteria(JSON.serialize(objRequestWrapper))
				.setPreviousCriteria(JSON.serialize(objRequestWrapper))
				.setTalkingPoints('Test Talking Points')
				.setRuleSet(list_RuleSet[2].Id)
				.build()
		);
		list_Criteria.add(
			new TestDataFactory.NBARuleCriteriaBuilder()
				.setBaseObject('Opportunity_Related_Tracking__c')
				.setCurrentCriteria(JSON.serialize(objRequestWrapper))
				.setPreviousCriteria(JSON.serialize(objRequestWrapper))
				.setTalkingPoints('Test Talking Points')
				.setRuleSet(list_RuleSet[3].Id)
				.build()
		);
		insert list_Criteria;

		// create a new company account and an open company opportunity
		Account objCompAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('NBA Demo Account').setZPCompanyId('1234567890').build();
		insert objCompAcc;

		// create new company opportunity
		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.COMPANY_OPPTY_RT_ID)
			.setName('NBA Demo Opp - Payroll')
			.setAccountId(objCompAcc.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		// start test method and call the method we are validating
		Test.startTest();
		RuleSetController.RuleSetWrapper objRuleSetWrapper = RuleSetController.refreshAllRules(objRuleSetConfig.Id);
		Test.stopTest();
		// Assert if method call was successful
		System.assertEquals(true, objRuleSetWrapper.blnIsSuccess, 'It should refresh all the rules without issue');
	}
}