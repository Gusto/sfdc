/**
 * @description  Test Class for ChatBotGcorpPricingControllerTest
 * @author       Debasmita Rawooth
 **/
@isTest
public class ChatBotGcorpPricingControllerTest {
	@isTest
	public static void checkIsWithinHoopTest() {
		List<BusinessHours> list_bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);

		Test.startTest();
		List<ChatBotGcorpPricingController.PricingInput> list_ControllerInputs = new List<ChatBotGcorpPricingController.PricingInput>();
		ChatBotGcorpPricingController.PricingInput objControllerInput = new ChatBotGcorpPricingController.PricingInput();
		objControllerInput.strBusinessHourName = list_bizHours[0].Name;
		list_ControllerInputs.add(objControllerInput);
		List<ChatBotGcorpPricingController.PricingOutput> list_ControllerOutputs = ChatBotGcorpPricingController.checkIsWithinHoop(list_ControllerInputs);
		ChatBotGcorpPricingController.PricingOutput objControllerOutput = list_ControllerOutputs[0];
		Test.stopTest();

		//Assert that the check returns a value for business hours
		System.assertNotEquals(null, objControllerOutput.blnIsWithinHoop, 'Could not find relevant business hours record');
	}
}