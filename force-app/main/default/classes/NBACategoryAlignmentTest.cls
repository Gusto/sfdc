/**
 * @description  Test class to retrieve primary and secondary NBA categories for lead or opportunity
 * @author       Praveen Sethu
 * @date         07-19-2023
 **/
@isTest
public class NBACategoryAlignmentTest {
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
	 * @description Test retrieval of primary and secondary NBA categories for Lead record
	 **/
	@isTest
	static void testLeadCategoryAlignment() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setRuleSetConfig(objRuleSetConfig.Id).setActive(true).build();
		insert objRuleSet;

		// insert criteria for opportunity related tracking
		NBARequestWrapper objRequestWrapper = new NBARequestWrapper();
		objRequestWrapper.talkingPoints = null;
		objRequestWrapper.soqlQuery = 'Lead__r.Id != NULL ORDER BY CreatedDate DESC';
		objRequestWrapper.servingObject = 'Lead';
		objRequestWrapper.servingField = 'Lead__c';
		objRequestWrapper.baseObject = 'Lead_Related_Tracking__c';

		NBARequestWrapper.OrderByField objOrderByField = new NBARequestWrapper.OrderByField();
		objOrderByField.selectedRelationField = null;
		objOrderByField.selectedOrder = 'DESC';
		objOrderByField.selectedFieldType = 'DATETIME';
		objOrderByField.selectedFieldLabel = 'Created Date';
		objOrderByField.selectedField = 'createddate';
		objRequestWrapper.list_OrderByFields = new List<NBARequestWrapper.OrderByField>{ objOrderByField };

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead_Related_Tracking__c')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;

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
		NBACategoryAlignment.NBACategoryAlignmentResponse objResponse = NBACategoryAlignment.getServedCategories(objLead.Id);
		Test.stopTest();

		// Assert response is successful
		System.assertEquals(true, objResponse.blnSuccess, 'Response should be successful');
		System.assertEquals(true, !objResponse.list_RuleSets.isEmpty(), 'Response should have rule sets');
	}

	/**
	 * @author      Praveen Sethu
	 * @description Test retrieval of primary and secondary NBA categories for Opportunity record
	 **/
	@isTest
	static void testOpportunityCategoryAlignment() {
		NBA_Rule_Set_Configuration__c objRuleSetConfig = [SELECT Id, Name FROM NBA_Rule_Set_Configuration__c LIMIT 1];
		// Created rule set record with valid Opportunity query
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
		NBACategoryAlignment.NBACategoryAlignmentResponse objResponse = NBACategoryAlignment.getServedCategories(objOppty.Id);
		Test.stopTest();

		// Assert response is successful
		System.assertEquals(true, objResponse.blnSuccess, 'Response should be successful');
		System.assertEquals(true, !objResponse.list_RuleSets.isEmpty(), 'Response should have rule sets');
	}
}