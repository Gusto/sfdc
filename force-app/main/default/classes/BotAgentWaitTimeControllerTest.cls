/**
 * @description  Test Class for BotAgentWaitTimeController_LEX
 * @author       Debasmita Rawooth
 **/
@isTest
public class BotAgentWaitTimeControllerTest {
	/**
	 * @author      Debasmita Rawooth
	 * @description Test method for getEstimatedWaitTime
	 **/
	@isTest
	static void getEstimatedWaitTimeTest() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new BotAgentWaitTimeControllerMockTest());

		String strEndpointUrl = System.Label.PricingBotURL;
		Integer intWaitTime = BotAgentWaitTimeController_LEX.getEstimatedWaitTime(strEndpointUrl);
		Test.stopTest();

		System.assertNotEquals(null, intWaitTime, 'Chat API response is empty.');
		System.assertEquals(120, intWaitTime, 'Estimated Wait Time is not retrieved correctly.');
	}
}