/**
 * @name         DailyLimitsMonitoringTest
 * @author       David Schach
 * @date         11/10/2021
 * @description  Test class for DailyLimitsMonitoringController
 **/
@isTest
public class DailyLimitsMonitoringTest {
	@IsTest
	/**
	 * Tests for new VF realtime stats page
	 * @author David Schach
	 */
	static void runPage() {
		Test.startTest();
		Test.setCurrentPage(Page.DailyLimitsMonitoringPage);
		DailyLimitsMonitoringController objDLMController = new DailyLimitsMonitoringController();

		List<OrgLimitWrapper> list_wrapper = objDLMController.map_Limits.values();
		list_wrapper.sort();

		Test.stopTest();
		objDLMController.refreshPage();
		System.assertEquals(OrganizationUtilities.isProduction(), objDLMController.getIsProduction(), 'Failed to determine if org is production');

		System.assert(objDLMController.getRefreshTime() <= System.now(), 'Refresh time is off');
	}

	/*
	 * @author:         Veeresh Kumar
	 * @description:    Tests Staging Object Limits of Dashboard
	 * @param:          N/A
	 * @return:         N/A
	 */
	@isTest
	static void testSetStagingObjectAndExceptionLogLimits() {
		List<Staging_Object_Dashboard_Limits__c> list_StagingObjLimits = new List<Staging_Object_Dashboard_Limits__c>();

		Staging_Object_Dashboard_Limits__c objZPCompanyStageLimit = new TestDataFactory.StagingObjectDashboardLimitsBuilder()
			.setName('ZP_Company_Staging_Limits')
			.setSObjectName('ZP_Company__c')
			.setMaxLimit(1000)
			.setType(DailyLimitsMonitoringController.CHART_TYPE_STAGING_OBJECT)
			.setTitle('ZP Company Title')
			.setSubtitle('ZP Company Subitle')
			.setActive(true)
			.build();
		list_StagingObjLimits.add(objZPCompanyStageLimit);

		Staging_Object_Dashboard_Limits__c objAccTriggerHandlerLimit = new TestDataFactory.StagingObjectDashboardLimitsBuilder()
			.setName('AccountTriggerHandler_Limits')
			.setClassName('AccountTriggerHandler')
			.setMaxLimit(100)
			.setType(DailyLimitsMonitoringController.CHART_TYPE_EXCEPTION_LOG)
			.setTitle('AccountTriggerHandler Title')
			.setSubtitle('AccountTriggerHandler Subitle')
			.setActive(true)
			.build();
		list_StagingObjLimits.add(objAccTriggerHandlerLimit);

		Staging_Object_Dashboard_Limits__c objConTriggerHandlerLimit = new TestDataFactory.StagingObjectDashboardLimitsBuilder()
			.setName('ContactTriggerHandler_Limits')
			.setClassName('ContactTriggerHandler')
			.setMaxLimit(100)
			.setType(DailyLimitsMonitoringController.CHART_TYPE_EXCEPTION_LOG)
			.setTitle('ContactTriggerHandler Title')
			.setSubtitle('ContactTriggerHandler Subitle')
			.setActive(false)
			.build();
		list_StagingObjLimits.add(objConTriggerHandlerLimit);

		insert list_StagingObjLimits;

		ExceptionLogUtil.logException('ContactTriggerHandler', 'beforeInsert', 'Exception On Line ', 'Test StackTrace');
		ExceptionLogUtil.logException('AccountTriggerHandler', 'beforeInsert', 'Exception On Line ', 'Test StackTrace');

		// Insert ZP_Company Staging Object
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('companyId1')
			.setCompanyLeadId('companyLeadId1')
			.setName('Test ZP Company 1')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setJoinedDate(System.today().addDays(-5))
			.build();

		ZPCompanyTriggerHelper.skipTrigger = true;
		insert objZPCompany;
		ZPCompanyTriggerHelper.skipTrigger = false;

		Test.startTest();

		Test.setCurrentPage(Page.DailyLimitsMonitoringPage);
		DailyLimitsMonitoringController objDLMController = new DailyLimitsMonitoringController();
		objDLMController.queryStagingObjectLimits();
		objDLMController.queryExceptionLogLimits();

		Test.stopTest();
		// Assert Staging Object Limits
		System.assertEquals(1, objDLMController.list_StagingObjects.size());
		for (OrgLimitWrapper objLimit : objDLMController.list_StagingObjects) {
			if (objLimit.strLName == 'ZP_Company__c') {
				System.assertEquals(1, objLimit.intLValue);
			}
		}
		// Assert Exception Log Limits
		System.assertEquals(1, objDLMController.list_ExceptionLogs.size());
		for (OrgLimitWrapper objLimit : objDLMController.list_ExceptionLogs) {
			if (objLimit.strLName == 'AccountTriggerHandler') {
				System.assertEquals(1, objLimit.intLValue);
			}
		}
	}
}