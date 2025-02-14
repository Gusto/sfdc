/**
 * @description  Test class to test serving of leads and opportunities
 * @author       Praveen Sethu
 * @date         07-19-2023
 **/
@isTest
public class NBAServeRecordTest {
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
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test get opportunity record from rule sets
	 **/
	@isTest
	static void testGetOpportunityFromRuleSet() {
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

		NBA_Rule_Set__c objRuleSet2 = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet2;

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Opportunity_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet2.Id)
			.build();
		insert objCriteria2;

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

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		System.assertEquals(true, objWrapper.blnSuccess, 'Wrapper class should return success flag as true');

		// assert if record Id is the same as the opportunity record inserted
		System.assertEquals(objOppty.Id, objWrapper.objRecord.Id, 'Wrapper class should return the same record Id as the opportunity record inserted');

		// assert if served up details are updated on the Opportunity
		Opportunity objAssert = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Opportunity WHERE Id = :objOppty.Id];
		System.assertEquals(true, objAssert.Served_Up_Rule__c != null, 'Served Up Rule on Opportunity should not be null');
		System.assertEquals(true, objAssert.Served_Up_Time__c != null, 'Served Up Time on Opportunity should not be null');
		System.assertEquals(true, objAssert.Served_Other_Rules__c != null, 'Served Other Rules on Opportunity should not be null');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test get lead record from rule sets
	 **/
	@isTest
	static void testGetLeadsFromRuleSets() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'lead__c != null AND Lead__r.Id != null AND Lead__r.Sold_By__r.Id = null ORDER BY Lead__r.Sold_By__r.createddate DESC';
		objRequestWrapper.servingObject = 'Lead';
		objRequestWrapper.servingField = 'lead__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';

		List<NBARequestWrapper.InnerTables> list_InnerTables = new List<NBARequestWrapper.InnerTables>{
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables()
		};
		list_InnerTables[0].strFieldLabel = 'Lead Related Tracking';
		list_InnerTables[1].strRelationshipName = 'Lead__r';
		list_InnerTables[1].strReferenceObject = 'Lead';
		list_InnerTables[1].strObjectLabel = 'Lead';
		list_InnerTables[1].strFieldLabel = 'Lead';
		list_InnerTables[1].selectedField = 'Id';
		list_InnerTables[2].strRelationshipName = 'Sold_By__r';
		list_InnerTables[2].strReferenceObject = 'Account';
		list_InnerTables[2].strObjectLabel = 'Account';
		list_InnerTables[2].strFieldLabel = 'Sold By';
		list_InnerTables[2].selectedField = 'createddate';

		objOrderByField.innerTables = list_InnerTables;
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		objRequestWrapper.objectLabel = 'Lead Related Tracking';

		List<NBARequestWrapper.FilterFieldsList> list_FilterFieldsList = new List<NBARequestWrapper.FilterFieldsList>{
			new NBARequestWrapper.FilterFieldsList(),
			new NBARequestWrapper.FilterFieldsList()
		};
		list_FilterFieldsList[0].selectedOperator = 'Not Equals to';
		list_FilterFieldsList[0].selectedField = 'Id';

		list_FilterFieldsList[0].innerTables = new List<NBARequestWrapper.InnerTables>{ new NBARequestWrapper.InnerTables(), new NBARequestWrapper.InnerTables() };

		list_FilterFieldsList[0].innerTables[0].strFieldLabel = 'Lead Related Tracking';
		list_FilterFieldsList[0].innerTables[1].strRelationshipName = 'Lead__r';
		list_FilterFieldsList[0].innerTables[1].strReferenceObject = 'Lead';
		list_FilterFieldsList[0].innerTables[1].strObjectLabel = 'Lead';
		list_FilterFieldsList[0].innerTables[1].strFieldLabel = 'Lead';
		list_FilterFieldsList[0].innerTables[1].selectedField = 'Id';

		list_FilterFieldsList[1].selectedOperator = 'Equals to';
		list_FilterFieldsList[1].selectedField = 'Id';
		list_FilterFieldsList[1].innerTables = new List<NBARequestWrapper.InnerTables>{ new NBARequestWrapper.InnerTables(), new NBARequestWrapper.InnerTables(), new NBARequestWrapper.InnerTables() };

		list_FilterFieldsList[1].innerTables[0].strFieldLabel = 'Lead Related Tracking';
		list_FilterFieldsList[1].innerTables[1].strRelationshipName = 'Lead__r';
		list_FilterFieldsList[1].innerTables[1].strReferenceObject = 'Lead';
		list_FilterFieldsList[1].innerTables[1].strObjectLabel = 'Lead';
		list_FilterFieldsList[1].innerTables[1].strFieldLabel = 'Lead';
		list_FilterFieldsList[1].innerTables[1].selectedField = 'Id';
		list_FilterFieldsList[1].innerTables[2].strRelationshipName = 'Sold_By__r';
		list_FilterFieldsList[1].innerTables[2].strReferenceObject = 'Account';
		list_FilterFieldsList[1].innerTables[2].strObjectLabel = 'Account';
		list_FilterFieldsList[1].innerTables[2].strFieldLabel = 'Sold By';
		list_FilterFieldsList[1].innerTables[2].selectedField = 'Id';

		objRequestWrapper.filterFieldsList = list_FilterFieldsList;

		List<NBARequestWrapper.DisplayFieldsList> displayFieldsList = new List<NBARequestWrapper.DisplayFieldsList>{ new NBARequestWrapper.DisplayFieldsList() };
		displayFieldsList[0].selectedFieldAPI = 'id';
		displayFieldsList[0].selectedField = 'Lead Related Tracking > Record ID';
		displayFieldsList[0].customText = 'Record ID';

		objRequestWrapper.displayFieldsList = displayFieldsList;

		objRequestWrapper.criteriaLogic = '1 AND 2';
		objRequestWrapper.baseObject = 'Lead_Related_Tracking__c';

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

		NBA_Rule_Set__c objRuleSet2 = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet2;

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet2.Id)
			.build();
		insert objCriteria2;

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		Lead objLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead2@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert new List<Lead>{ objLead };

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		System.assertEquals(true, objWrapper.blnSuccess, 'Wrapper class should return success flag as true');

		// assert if record Id is the same as the lead record inserted
		System.assertEquals(objLead.Id, objWrapper.objRecord.Id, 'Wrapper class should return the same record Id as the lead record inserted');

		// assert if served up details are updated on the Lead
		Lead objAssert = [SELECT Id, Served_Up_Rule__c, Served_Up_Time__c, Served_Other_Rules__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objAssert.Served_Up_Rule__c != null, 'Served Up Rule on Lead should not be null');
		System.assertEquals(true, objAssert.Served_Up_Time__c != null, 'Served Up Time on Lead should not be null');
		System.assertEquals(true, objAssert.Served_Other_Rules__c != null, 'Served Other Rules on Lead should not be null');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test creating NBA rule sets with both lead and opportunity criteria
	 **/
	@isTest
	static void testNBARuleWithLeadAndOppty() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
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

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

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

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		System.assertEquals(true, objWrapper.blnSuccess, 'Wrapper class should return success flag as true');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test creating NBA rule sets with both lead and opportunity criteria
	 **/
	@isTest
	static void testNBARuleWithSkillAssignment() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder().setSkillRuleSet(objRuleSet.Id).setSkillOperator('!=').setSkillLevel('1').setSkillName('Test skill').build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// Assert lead should not be served as there is no skill assignment
		Lead objLeadAssert = [SELECT Id, Served_Up_Rule__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(null, objLeadAssert.Served_Up_Rule__c, 'Lead should not be served as there is no skill assignment');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test records hold out functionality
	 **/
	@isTest
	static void testRecordsHoldOut() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder()
			.setRuleName('Test Rule Set')
			.setPriority(1)
			.setRuleSetConfig(objRuleSetConfig.Id)
			.setActive(true)
			.setHoldOutPercentage(100)
			.build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		// insert two leads and validate if one of them got hold out

		// create a new unconverted lead
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo1.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert new List<Lead>{ objLead1 };

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// check if the lead record was held out
		Lead objLeadAssert = [SELECT Id, Hold_Out_Record__c FROM Lead WHERE Id = :objLead1.Id];
		System.assertEquals(true, String.isNotBlank(objLeadAssert.Hold_Out_Record__c), 'Record was not hold out');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test serving records when order by field is null
	 **/
	@isTest
	static void testRecordWithNullOrderByField() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper.servingObject = 'Opportunity';
		objRequestWrapper.servingField = 'Opportunity__c';
		objRequestWrapper.baseObject = 'Opportunity_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';

		List<NBARequestWrapper.InnerTables> list_InnerTables1 = new List<NBARequestWrapper.InnerTables>{
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables()
		};
		list_InnerTables1[0].strFieldLabel = 'Opportunity Related Tracking';
		list_InnerTables1[1].strRelationshipName = 'Opportunity__r';
		list_InnerTables1[1].strReferenceObject = 'Opportunity';
		list_InnerTables1[1].strObjectLabel = 'Opportunity';
		list_InnerTables1[1].strFieldLabel = 'Opportunity';
		list_InnerTables1[1].selectedField = 'Id';
		list_InnerTables1[2].strRelationshipName = 'Sold_By__r';
		list_InnerTables1[2].strReferenceObject = 'Account';
		list_InnerTables1[2].strObjectLabel = 'Account';
		list_InnerTables1[2].strFieldLabel = 'Sold By';
		list_InnerTables1[2].selectedField = 'createddate';

		objOrderByField.innerTables = list_InnerTables1;
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Opportunity_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';

		List<NBARequestWrapper.InnerTables> list_InnerTables = new List<NBARequestWrapper.InnerTables>{
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables(),
			new NBARequestWrapper.InnerTables()
		};
		list_InnerTables[0].strFieldLabel = 'Lead Related Tracking';
		list_InnerTables[1].strRelationshipName = 'Lead__r';
		list_InnerTables[1].strReferenceObject = 'Lead';
		list_InnerTables[1].strObjectLabel = 'Lead';
		list_InnerTables[1].strFieldLabel = 'Lead';
		list_InnerTables[1].selectedField = 'Id';
		list_InnerTables[2].strRelationshipName = 'Sold_By__r';
		list_InnerTables[2].strReferenceObject = 'Account';
		list_InnerTables[2].strObjectLabel = 'Account';
		list_InnerTables[2].strFieldLabel = 'Sold By';
		list_InnerTables[2].selectedField = 'createddate';

		objOrderByField2.innerTables = list_InnerTables;
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		// insert two leads and validate if one of them got hold out

		// create a new unconverted lead
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo1.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();

		insert new List<Lead>{ objLead1 };

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

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// one of opportunity or lead should have been served - because both order by fields are null - we will pick a random record out of the opportunity or the lead
		Integer intServedRecords = 0;

		for (Opportunity objOpptyAssert : [SELECT Id, Served_Up_Rule__c FROM Opportunity WHERE Id = :objOppty.Id]) {
			if (String.isNotBlank(objOpptyAssert.Served_Up_Rule__c)) {
				intServedRecords++;
			}
		}

		for (Lead objLeadAssert : [SELECT Id, Served_Up_Rule__c FROM Lead WHERE Id = :objLead1.Id]) {
			if (String.isNotBlank(objLeadAssert.Served_Up_Rule__c)) {
				intServedRecords++;
			}
		}

		System.assertEquals(1, intServedRecords, 'One of the records should have been served');

		NBARequestWrapper objWrapper1 = new NBARequestWrapper();
		NBARequestWrapper.DisplayFieldsList objDisplayFields = new NBARequestWrapper.DisplayFieldsList();
		objDisplayFields = new NBARequestWrapper.DisplayFieldsList('test', 'test', 'test');
	}

	/**
	 * @description Test serve record with skills assignment logic OR
	 **/
	@isTest
	static void testNBARuleWithAnyServiceResourceSkill() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		Skill objSalesSkill = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel = 'Test skill'][0];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(objSalesSkill.Id)
			.build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating a ServiceResourceSkill
		ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
		objServiceResourceSkill.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill.SkillId = objSalesSkill.Id;
		objServiceResourceSkill.EffectiveStartDate = System.today().addDays(-1);
		objServiceResourceSkill.EffectiveEndDate = System.today().addDays(+2);
		objServiceResourceSkill.SkillLevel = 2;
		insert objServiceResourceSkill;

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// Assert lead should be served as there is atleast one skill assignment
		Lead objLeadAssert = [SELECT Id, Served_Up_Rule__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadAssert.Served_Up_Rule__c, 'Lead should be served as any of the skill assignments are met');
	}

	/**
	 * @description Test serve record with skills assignment logic AND
	 **/
	@isTest
	static void testNBARuleWithAllServiceResourceSkill() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		List<Skill> list_Skills = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel IN ('Test skill', 'Placeholder Skill') ORDER BY MasterLabel];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill1 = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Placeholder skill')
			.setSkillId(list_Skills[0].Id)
			.build();
		NBA_Rule_Set_Skill__c objSkill2 = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(list_Skills[1].Id)
			.build();
		insert new List<NBA_Rule_Set_Skill__c>{ objSkill1, objSkill2 };

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill1, objSkill2 }, 'AND');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating ServiceResourceSkills
		ServiceResourceSkill objServiceResourceSkill1 = new ServiceResourceSkill();
		objServiceResourceSkill1.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill1.SkillId = list_Skills[0].Id;
		objServiceResourceSkill1.EffectiveStartDate = System.today().addDays(-1);
		objServiceResourceSkill1.EffectiveEndDate = System.today().addDays(+2);
		objServiceResourceSkill1.SkillLevel = 2;

		ServiceResourceSkill objServiceResourceSkill2 = new ServiceResourceSkill();
		objServiceResourceSkill2.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill2.SkillId = list_Skills[1].Id;
		objServiceResourceSkill2.EffectiveStartDate = System.today().addDays(-1);
		objServiceResourceSkill2.EffectiveEndDate = System.today().addDays(+2);
		objServiceResourceSkill2.SkillLevel = 2;
		insert new List<ServiceResourceSkill>{ objServiceResourceSkill1, objServiceResourceSkill2 };

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// Assert lead should be served as all skill assignments are met
		Lead objLeadAssert = [SELECT Id, Served_Up_Rule__c FROM Lead WHERE Id = :objLead.Id];
		System.assertNotEquals(null, objLeadAssert.Served_Up_Rule__c, 'Lead should be served as all skill assignments are met');
	}

	/**
	 * @description Test serve record with skills assignment logic AND - Negative scenario
	 **/
	@isTest
	static void testNBARuleWithAllServiceResourceSkillNegative() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper2.servingObject = 'Lead';
		objRequestWrapper2.servingField = 'Lead__c';
		objRequestWrapper2.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria2;

		List<Skill> list_Skills = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel IN ('Test skill', 'Placeholder Skill') ORDER BY MasterLabel];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill1 = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('>')
			.setSkillLevel('1')
			.setSkillName('Placeholder skill')
			.setSkillId(list_Skills[0].Id)
			.build();
		NBA_Rule_Set_Skill__c objSkill2 = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('=')
			.setSkillLevel('2')
			.setSkillName('Test skill')
			.setSkillId(list_Skills[1].Id)
			.build();
		insert new List<NBA_Rule_Set_Skill__c>{ objSkill1, objSkill2 };

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill1, objSkill2 }, 'AND');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating ServiceResourceSkills
		ServiceResourceSkill objServiceResourceSkill1 = new ServiceResourceSkill();
		objServiceResourceSkill1.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill1.SkillId = list_Skills[0].Id;
		objServiceResourceSkill1.EffectiveStartDate = System.today();
		objServiceResourceSkill1.EffectiveEndDate = System.today();
		objServiceResourceSkill1.SkillLevel = 2;

		//Following skill level is 1, which is not meeting the criteria
		ServiceResourceSkill objServiceResourceSkill2 = new ServiceResourceSkill();
		objServiceResourceSkill2.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill2.SkillId = list_Skills[1].Id;
		objServiceResourceSkill2.EffectiveStartDate = System.today();
		objServiceResourceSkill2.EffectiveEndDate = System.today();
		objServiceResourceSkill2.SkillLevel = 1;
		insert new List<ServiceResourceSkill>{ objServiceResourceSkill1, objServiceResourceSkill2 };

		// create a new unconverted lead
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newlead@nbademo.com')
			.setPhone('123456789')
			.setCompany('NBA Demo')
			.setStatus(LeadUtil.LEAD_STATUS_AQL)
			.build();
		insert objLead;

		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// Assert lead should not be served as all skill assignments are not met
		Lead objLeadAssert = [SELECT Id, Served_Up_Rule__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(null, objLeadAssert.Served_Up_Rule__c, 'Lead should not be served as all skill assignments are not met');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if last run with zero records is updated on serve record
	 **/
	@isTest
	static void testZeroRecordsRunUpdate() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		// Insert a criteria with no records
		objRequestWrapper.soqlQuery = 'Opportunity__r.Id = NULL ORDER BY Opportunity__r.CreatedDate DESC';
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
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		objRuleSet = [SELECT Id, Last_Ran_With_Zero_Records__c FROM NBA_Rule_Set__c WHERE Id = :objRuleSet.Id];
		// Assert if last run with zero records is updated
		System.assertEquals(true, objRuleSet.Last_Ran_With_Zero_Records__c != null, 'Last run with zero records should be updated');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test if last run with zero records is updated on a rule that contains myself criteria
	 **/
	@isTest
	static void testZeroRecordsRunUpdateWithMyselfRule() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		// Insert a criteria with no records
		objRequestWrapper.soqlQuery = 'Opportunity__r.OwnerId = \'MYSELF\' AND CreatedDate = NULL';
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
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		objRuleSet = [SELECT Id, Last_Ran_With_Zero_Records__c, User_Last_Ran_With_Zero_Records__c FROM NBA_Rule_Set__c WHERE Id = :objRuleSet.Id];
		System.assertEquals(true, objRuleSet.Last_Ran_With_Zero_Records__c == null, 'Last run with zero records should not be updated');
		System.assertEquals(true, objRuleSet.User_Last_Ran_With_Zero_Records__c != null, 'User Last run with zero records should be updated');
		System.assertEquals(true, objRuleSet.User_Last_Ran_With_Zero_Records__c.containsIgnoreCase(UserInfo.getUserId()), 'User Last run with zero records should be updated with logged in user');
	}

	static void skipTriggers() {
		BenefitOrderHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;
		CaseTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;
		CarrierTriggerHelper.skipTrigger = true;
	}

	/**
	 * @author      Omar Benitez
	 * @description Test creating NBA rule sets with user lookups
	 **/
	@isTest
	static void testNBARuleWithUserLookupFields() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';


		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = NBAServeRecord.ANY_VALUE;
		mapping.toValue = NBAServeRecord.LOGGED_IN_USER;
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'audit_owner__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals(1, objCarrierOrder.size());
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c FROM Carrier_Order__c LIMIT 1];
		System.assertNotEquals(null, objCarrierOrder[0].audit_owner__c);
	}

	/**
	 * @author      Omar Benitez
	 * @description Test creating NBA rule sets with picklist field
	 **/
	@isTest
	static void testNBARuleWithPicklistFields() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setImplementationStage('Qualification')
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		//Adding Picklist Values Mapping
		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = 'Qualification';
		mapping.toValue = 'Blocked';
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'Implementation_Stage__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c);
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Blocked', objCarrierOrder[0].Implementation_Stage__c);
	}

	/**
	 * @author      Omar Benitez
	 * @description Test No Skip Server Other Rules
	 **/
	@isTest
	static void testNoSkipServedOtherRules() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		NBA_Rule_Set__c objRuleSet2 = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert new List<NBA_Rule_Set__c>{ objRuleSet, objRuleSet2 };

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet2.Id)
			.build();
		insert new List<NBA_Rule_Criteria__c>{ objCriteria, objCriteria2 };
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();
		String servedRule = (String) objWrapper.objRecord.get('Served_Up_Rule__c');
		String servedOtherRule = (String) objWrapper.objRecord.get('Served_Other_Rules__c');
		System.assertNotEquals(servedRule, servedOtherRule, 'Server Other Rules should have 2 rules');
	}
	/**
	 * @author      Omar Benitez
	 * @description Test Skip Server Other Rules
	 **/
	@isTest
	static void testSkipServedOtherRules() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		objRuleSetConfig.Exclude_Served_Other_Rules__c = true;
		update objRuleSetConfig;
		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		NBA_Rule_Set__c objRuleSet2 = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert new List<NBA_Rule_Set__c>{ objRuleSet, objRuleSet2 };

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet2.Id)
			.build();
		insert new List<NBA_Rule_Criteria__c>{ objCriteria, objCriteria2 };
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();
		String servedRule = (String) objWrapper.objRecord.get('Served_Up_Rule__c');
		String servedOtherRule = (String) objWrapper.objRecord.get('Served_Other_Rules__c');
		System.assertEquals(servedRule, servedOtherRule, 'Both fields should have same value');
	}
	/**
	 * @author      Omar Benitez
	 * @description Test Batching Rules, second
	 **/
	@isTest
	static void testBatchingRules() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		objRuleSetConfig.Exclude_Served_Other_Rules__c = true;
		objRuleSetConfig.Rules_per_Execution__c = 1;
		update objRuleSetConfig;
		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'Not Found\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper2 = new NBARequestWrapper();
		objRequestWrapper2.talkingPoints = null;
		objRequestWrapper2.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper2.servingObject = 'Carrier_Order__c';
		objRequestWrapper2.servingField = 'id';
		objRequestWrapper2.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper2.baseObject = 'Carrier_Order__c';

		NBARequestWrapper.OrderByField objOrderByField2 = new NBARequestWrapper.OrderByField();
		objOrderByField2.selectedRelationField = null;
		objOrderByField2.selectedOrder = 'DESC';
		objOrderByField2.selectedFieldType = 'DATETIME';
		objOrderByField2.selectedFieldLabel = 'Created Date';
		objOrderByField2.selectedField = 'createddate';
		objRequestWrapper2.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField2 };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		NBA_Rule_Set__c objRuleSet2 = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set 2').setPriority(2).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert new List<NBA_Rule_Set__c>{ objRuleSet, objRuleSet2 };

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		NBA_Rule_Criteria__c objCriteria2 = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper2))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper2))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet2.Id)
			.build();
		insert new List<NBA_Rule_Criteria__c>{ objCriteria, objCriteria2 };
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		System.assertEquals(null, objWrapper.objRecord, 'should be null since there is no record in the first chunk');
		System.assertEquals(1, objWrapper.intExecutionNumber, 'should be 1 since it was the first chunk');
		System.assertNotEquals(null, objWrapper.objRuleConfig, 'should not be null since it was the first chunk');
		System.assertNotEquals(null, objWrapper.list_RuleSets, 'should not be null since it was the first chunk');
		System.assertNotEquals(null, objWrapper.list_ServiceResourceSkills, 'should not be null since it was the first chunk');
		objWrapper.intExecutionNumber = (objWrapper.intExecutionNumber + 1);
		NBAServeRecord.NBAServeRecordWrapper objWrapper2 = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(
			NBAServeRecord.serveNextRecord(JSON.serialize(objWrapper)),
			NBAServeRecord.NBAServeRecordWrapper.class
		);
		Test.stopTest();

		System.assertNotEquals(null, objWrapper2.objRecord, 'should not be null since the record should be served in the second chunk');
	}

	@isTest
	static void testSkillDateEligibility() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setImplementationStage('Qualification')
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		//Adding Picklist Values Mapping
		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = 'Qualification';
		mapping.toValue = 'Blocked';
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'Implementation_Stage__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		Skill objSalesSkill = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel = 'Test skill'][0];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(objSalesSkill.Id)
			.build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating a ServiceResourceSkill
		ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
		objServiceResourceSkill.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill.SkillId = objSalesSkill.Id;
		objServiceResourceSkill.EffectiveStartDate = System.today().addDays(-5);
		objServiceResourceSkill.EffectiveEndDate = System.today().addDays(+5);
		objServiceResourceSkill.SkillLevel = 2;
		insert objServiceResourceSkill;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c);
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Blocked', objCarrierOrder[0].Implementation_Stage__c, 'Stage should change properly');
	}

	@isTest
	static void testSkillDateEligibilityFalseEndDateInPast() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setImplementationStage('Qualification')
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		//Adding Picklist Values Mapping
		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = 'Qualification';
		mapping.toValue = 'Blocked';
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'Implementation_Stage__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		Skill objSalesSkill = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel = 'Test skill'][0];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(objSalesSkill.Id)
			.build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating a ServiceResourceSkill
		ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
		objServiceResourceSkill.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill.SkillId = objSalesSkill.Id;
		objServiceResourceSkill.EffectiveStartDate = System.today().addDays(-5);
		objServiceResourceSkill.EffectiveEndDate = System.today().addDays(-1);
		objServiceResourceSkill.SkillLevel = 2;
		insert objServiceResourceSkill;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c);
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c, 'Stage should not change since the date is in the past');
	}
	@isTest
	static void testSkillDateEligibilityNullEndDate() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setImplementationStage('Qualification')
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		//Adding Picklist Values Mapping
		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = 'Qualification';
		mapping.toValue = 'Blocked';
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'Implementation_Stage__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		Skill objSalesSkill = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel = 'Test skill'][0];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(objSalesSkill.Id)
			.build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating a ServiceResourceSkill
		ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
		objServiceResourceSkill.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill.SkillId = objSalesSkill.Id;
		objServiceResourceSkill.EffectiveStartDate = System.today().addDays(-5);
		objServiceResourceSkill.EffectiveEndDate = null;
		objServiceResourceSkill.SkillLevel = 2;
		insert objServiceResourceSkill;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c);
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Blocked', objCarrierOrder[0].Implementation_Stage__c, 'Stage should change properly');
	}

	@isTest
	static void testSkillDateEligibilityFalseStartDateInFuture() {
		//Creating Carrier Order
		skipTriggers();
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		State__c objState = new TestDataFactory.StateBuilder().setName('TEST STATE').setAbbreviation('TS').build();
		insert objState;

		List<Carrier__c> list_Carriers = new List<Carrier__c>();
		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('TS').build();
		list_Carriers.add(objCarrier);
		insert list_Carriers;

		// BOR Records
		List<Account> list_Accounts = new List<Account>();
		Account objAccount = new TestDataFactory.AccountBuilder().setName('Test Account').setZPCompanyId('100989002').setRecordTypeId('Company').build();
		list_Accounts.add(objAccount);

		insert list_Accounts;

		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Id OPP_RT_BENEFITS_NEW_PLAN = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan');
		Opportunity objParentOppNewPlan = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OPP_RT_BENEFITS_NEW_PLAN)
			.setAccountId(objAccount.Id)
			.setStage('SAL')
			.setCloseDate(System.Today())
			.setName('Test Opp')
			.build();
		list_Opportunities.add(objParentOppNewPlan);

		QASheetHelper.createOrUpdateQASheet(new List<Opportunity>{ objParentOppNewPlan });

		List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
		Id BO_RT_NEW_PLAN = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');

		Benefit_Order__c objParentBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BO_RT_NEW_PLAN)
			.setName('TEST BENEFIT ORDER 1')
			.setOpp(objParentOppNewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(false)
			.build();
		list_BenefitOrders.add(objParentBONewPlan);
		insert list_BenefitOrders;
		Id CO_RT_NEW_PLAN = Cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
		Carrier_Order__c objParentCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setName('NBA Carrier Order')
			.setCarrier(objCarrier.Id)
			.setRecordTypeId(CO_RT_NEW_PLAN)
			.setBenefitOrder(objParentBONewPlan.Id)
			.setOwnerID(UserInfo.getUserId())
			.setIsMultiEIN(true)
			.setImplementationStage('Qualification')
			.build();
		list_CarrierOrders.add(objParentCarrierOrder);

		insert list_CarrierOrders;

		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'id != null AND (name = \'NBA Carrier Order\') ORDER BY id DESC';
		objRequestWrapper.servingObject = 'Carrier_Order__c';
		objRequestWrapper.servingField = 'id';
		objRequestWrapper.userFieldsAssignment = new List<String>{ 'audit_owner__c', 'confirmation_owner__c' };
		objRequestWrapper.baseObject = 'Carrier_Order__c';

		//Adding Picklist Values Mapping
		objRequestWrapper.fieldMapping = new List<NBARequestWrapper.FieldMapping>();
		NBARequestWrapper.FieldMapping fieldMapping = new NBARequestWrapper.FieldMapping();
		fieldMapping.mapping = new List<NBARequestWrapper.Mapping>();
		NBARequestWrapper.Mapping mapping = new NBARequestWrapper.Mapping();
		mapping.fromValue = 'Qualification';
		mapping.toValue = 'Blocked';
		fieldMapping.mapping.add(mapping);
		fieldMapping.selectedField = 'Implementation_Stage__c';
		objRequestWrapper.fieldMapping.add(fieldMapping);

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		Skill objSalesSkill = [SELECT Id, DeveloperName, MasterLabel FROM Skill WHERE MasterLabel = 'Test skill'][0];

		// insert NBA Rule Set Skill record
		NBA_Rule_Set_Skill__c objSkill = new TestDataFactory.NBARuleSetSkillBuilder()
			.setSkillRuleSet(objRuleSet.Id)
			.setSkillOperator('!=')
			.setSkillLevel('1')
			.setSkillName('Test skill')
			.setSkillId(objSalesSkill.Id)
			.build();
		insert objSkill;

		// update rule set with skill assignment criteria configuration json
		objRuleSet.Rule_Skills_Criteria_Logic__c = RuleSetController.generateSkillsCriteriaJson(new List<NBA_Rule_Set_Skill__c>{ objSkill }, 'OR');
		update objRuleSet;

		//creating a ServiceResource
		ServiceResource objServiceResource = new ServiceResource();
		objServiceResource.Name = 'Test Resource';
		objServiceResource.RelatedRecordId = UserInfo.getUserId();
		objServiceResource.ResourceType = 'A';
		objServiceResource.IsActive = true;
		insert objServiceResource;

		//creating a ServiceResourceSkill
		ServiceResourceSkill objServiceResourceSkill = new ServiceResourceSkill();
		objServiceResourceSkill.ServiceResourceId = objServiceResource.Id;
		objServiceResourceSkill.SkillId = objSalesSkill.Id;
		objServiceResourceSkill.EffectiveStartDate = System.today().addDays(+5);
		objServiceResourceSkill.EffectiveEndDate = System.today().addDays(+7);
		objServiceResourceSkill.SkillLevel = 2;
		insert objServiceResourceSkill;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Carrier_Order__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		List<Carrier_Order__c> objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c);
		Test.startTest();
		NBAServeRecord.NBAServeRecordWrapper objWrapper = (NBAServeRecord.NBAServeRecordWrapper) JSON.deserialize(NBAServeRecord.serveNextRecord(null), NBAServeRecord.NBAServeRecordWrapper.class);
		Test.stopTest();

		// assert success flag from wrapper class
		objCarrierOrder = [SELECT Id, audit_owner__c, Implementation_Stage__c FROM Carrier_Order__c LIMIT 1];
		System.assertEquals('Qualification', objCarrierOrder[0].Implementation_Stage__c, 'Stage should not change since the date is in the future');
	}
}