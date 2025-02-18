/**
 * @description  Test Class for RetrieveAgentWaitTimeController
 * @author       Debasmita Rawooth
 **/
@isTest
public class RetrieveAgentWaitTimeControllerTest {
	/**
	 * @author      Debasmita Rawooth
	 * @description Test method for getEstimatedWaitTime
	 **/
	@isTest
	static void getEstimatedWaitTimeTest() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new RetrieveAgentWaitTimeMockTest());

		RetrieveAgentWaitTimeController.WaitTimeInput objWaitTimeInput = new RetrieveAgentWaitTimeController.WaitTimeInput();
		RetrieveAgentWaitTimeController.WaitTimeOutput objWaitTimeOutput = new RetrieveAgentWaitTimeController.WaitTimeOutput();

		objWaitTimeInput.strEndpointUrl = 'https://d.la5-c1cs-ia4.salesforceliveagent.com/chat/rest/Visitor/Availability?org_id=00D780000000Mjc&deployment_id=57278000000CaW2&Availability.ids=57378000000CaWv&Availability.needEstimatedWaitTime=1';
		List<RetrieveAgentWaitTimeController.WaitTimeInput> list_WaitTimeInput = new List<RetrieveAgentWaitTimeController.WaitTimeInput>();
		list_WaitTimeInput.add(objWaitTimeInput);

		List<RetrieveAgentWaitTimeController.WaitTimeOutput> list_WaitTimeOutput = new List<RetrieveAgentWaitTimeController.WaitTimeOutput>();
		list_WaitTimeOutput = RetrieveAgentWaitTimeController.getEstimatedWaitTime(list_WaitTimeInput);
		Test.stopTest();

		System.assertNotEquals(0, list_WaitTimeOutput.size(), 'Chat API response is empty.');
		System.assertEquals(2, list_WaitTimeOutput[0].intEstimatedWaitTimeMinutes, 'Estimated Wait Time is not retrieved correctly.');
	}
}