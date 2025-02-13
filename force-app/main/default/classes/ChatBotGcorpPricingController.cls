/**
 * @description  Used for GCorp Pricing Chatbot for checking HOOP
 * @author       Debasmita Rawooth
 * @see          ChatBotGcorpPricingControllerTest
 **/
public class ChatBotGcorpPricingController {
	/**
	 * @description  Invocable class to share output with bot
	 * @see          ChatBotGcorpPricingControllerTest
	 **/
	public class PricingOutput {
		@InvocableVariable(required=true)
		public Boolean blnIsWithinHoop;
	}

	/**
	 * @description  Invocable class to get input from bot
	 * @see          ChatBotGcorpPricingControllerTest
	 **/
	public class PricingInput {
		@InvocableVariable(required=true)
		public String strBusinessHourName;
	}

	/**
	 * @description Gets business hour name and return true if current time is within HOOP
	 * @param       list_PricingInputs - List of objects of PricingInput type
	 * @return      list_PricingOutputs - List of objects of PricingOutput type
	 **/
	@InvocableMethod(label='Check HOOP')
	public static List<PricingOutput> checkIsWithinHoop(List<PricingInput> list_PricingInputs) {
		List<PricingOutput> list_PricingOutputs = new List<PricingOutput>();
		PricingOutput objPricingOutput = new PricingOutput();
		Set<String> set_BusinessHourNames = new Set<String>();

		for (PricingInput objInput : list_PricingInputs) {
			set_BusinessHourNames.add(objInput.strBusinessHourName);
		}

		// Get Business hours based on name, input from bot
		BusinessHours objBusinessHour = [SELECT Id FROM BusinessHours WHERE Name IN :set_BusinessHourNames LIMIT 1];
		// Create Datetime with current date/time in local time zone
		Datetime currentTime = Datetime.now();
		// Find whether the time is within business hours
		if (objBusinessHour != null) {
			objPricingOutput.blnIsWithinHoop = BusinessHours.isWithin(objBusinessHour.id, currentTime);
			list_PricingOutputs.add(objPricingOutput);
		}
		return list_PricingOutputs;
	}
}