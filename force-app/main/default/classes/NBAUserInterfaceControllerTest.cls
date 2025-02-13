/**
 * @description  Test class used to test features of the user interface controller
 * @author       Praveen Sethu
 **/
@isTest
public class NBAUserInterfaceControllerTest {
	/**
	 * @description Test functionality when a base object is added to the user interface
	 **/
	static testMethod void testHandleAddBaseObject() {
		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setActive(true).build();
		insert objRuleSet;

		Test.startTest();
		NBAUserInterfaceController.NBAUserInterfaceWrapper objWrapper = NBAUserInterfaceController.handleAddBaseObject('Lead', 'Lead', objRuleSet.Id);
		Test.stopTest();

		System.assertEquals(objWrapper.blnError != true, true, 'Assert if no error is thrown');
		System.assertEquals(objWrapper.map_AllFields.size() > 0, true, 'Assert if fields are returned');
	}

	/**
	 * @description Test functionality when nba user interface page is loaded and all the data is available
	 **/
	static testMethod void testLoadUserInterface() {
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

		Test.startTest();

		NBA_Rule_Set__c objRuleSet = new TestDataFactory.NBARuleSetBuilder().setRuleName('Test Rule Set').setPriority(1).setActive(true).build();
		insert objRuleSet;

		NBA_Rule_Criteria__c objCriteria = new TestDataFactory.NBARuleCriteriaBuilder()
			.setBaseObject('Lead')
			.setCurrentCriteria(JSON.serialize(objRequestWrapper))
			.setPreviousCriteria(JSON.serialize(objRequestWrapper))
			.setTalkingPoints('Test Talking Points')
			.setRuleSet(objRuleSet.Id)
			.build();
		insert objCriteria;
		NBAUserInterfaceController.NBAUserInterfaceWrapper objWrapper = NBAUserInterfaceController.loadUserInterface(objRuleSet.Id);

		List<NBARequestWrapper> list_Requests = new List<NBARequestWrapper>{ objRequestWrapper };
		NBAUserInterfaceController.NBAUserInterfaceWrapper objSaveWrapper = NBAUserInterfaceController.handleSaveObjects(objRuleSet.Id, JSON.serialize(list_Requests), false, 0);
		Test.stopTest();

		System.assertEquals(objWrapper.blnError != true, true, 'Assert if no error is thrown');
		System.assertEquals(objWrapper.list_Requests.size() > 0, true, 'Assert if current requests are returned');
		System.assertEquals(objWrapper.list_OldRequests.size() > 0, true, 'Assert if old requests are returned');
		System.assertEquals(objWrapper.map_ObjectFields.size() > 0, true, 'Assert map of objects and fields are available');

		// Assert if save was successful
		System.assertEquals(objSaveWrapper.blnError != true, true, 'Assert if no error is thrown');
	}

	/**
	 * @description Test if validating SOQL feature is working correctly
	 **/
	static testMethod void testValidateSOQL() {
		String strQuery = 'SELECT Id FROM Lead WHERE CreatedDate >= n_business_days_ago:1 LIMIT 0';

		Test.startTest();
		NBAUserInterfaceController.NBAUserInterfaceWrapper objWrapper = NBAUserInterfaceController.validateSOQLQuery(strQuery, null, null);
		Test.stopTest();

		System.assertEquals(objWrapper.blnError != true, true, 'Assert if validation was successful');
	}

	/**
	 * @description Test displaying fields from template
	 **/
	static testMethod void testDisplayFieldsFromTemplete() {
		Test.startTest();
		List<NBARequestWrapper.DisplayFieldsList> list_DisplayFields = NBAUserInterfaceController.getDisplayFieldsFromTemplate(null);
		Test.stopTest();

		System.assertEquals(2, list_DisplayFields.size(), 'Display fields list not fetched properly');
	}
}