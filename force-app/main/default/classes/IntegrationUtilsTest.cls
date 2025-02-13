@isTest
public class IntegrationUtilsTest {
	@isTest
	static void testIntegrationUtilFieldValueMap() {
		Map<String, String> map_Integrations = IntegrationUtils.getIntegrationValueMap('Opportunity', 'ZP_Company_Setup_Step__c');

		System.assert(map_Integrations.size() > 1);
	}

	@isTest
	static void parseJSON() {
		String strOriginalJsonString =
			'{"waiting_period":"first_of_month_30_days_after_hire", "secretary_of_state_status":"active_option", "has_recent_or_upcoming_new_hires":true, ' +
			' "does_your_company_file_taxes_as_scorp":false, "has_active_workers_compensation_policy":true, "active_workers_compensation_policy_name":"ABC", ' +
			' "does_your_company_want_to_contribute_entire_premium":""}';

		String strWaitingPeriod = IntegrationUtils.getJsonParsedMap(strOriginalJsonString, 'waiting_period');
		System.assertEquals('first_of_month_30_days_after_hire', strWaitingPeriod);
	}

	@isTest
	static void getIntegrationSystemInfo() {
        Integration_System_Information__c objISI = new TestDataFactory.IntSystemInfoBuilder()
			.setName('Test')
			.setURL('Test')
			.setUserName('Test')
			.setPassword('Test')
			.build();

        insert objISI;

		Test.startTest();
		Integration_System_Information__c objIntegrationInfo = IntegrationUtils.getIntegrationSystemInfo('Test');
		System.assertEquals(objIntegrationInfo.User_name__c, 'Test');
		Test.stopTest();
	}
}