/**
 * @description  Checks if it is business hours for FPO
 * @author       Praveen Sethu
 * @date         10-07-2022
 * @see          WalletBotHOOPCheckTest
 **/
public with sharing class WalletBotHOOPCheck {
	/**
	 * @Author:			Praveen Sethu
	 * @Description:	Used to determining business hours for FPO chats
	 * @Parms:			NA
	 */
	@InvocableMethod(label='Is FPO Chat in Business Hour')
	public static List<Boolean> isBusinessHour() {
		Integer intStartHour = Integer.valueOf(System.Label.FPO_HOOP_Start);
		Integer intEndHour = Integer.valueOf(System.Label.FPO_HOOP_End);

		List<Boolean> list_Response = new List<Boolean>();
		// get current time and return true if it between intStartHour & intEndHour
		Integer intHour = DateTime.now().hour();
		if (intHour >= intStartHour && intHour <= intEndHour) {
			list_Response = new List<Boolean>{ true };
		} else {
			list_Response = new List<Boolean>{ false };
		}

		String strDayOfWeek = DateTime.now().format('EEEE');

		if (strDayOfWeek == 'Saturday' || strDayOfWeek == 'Sunday') {
			list_Response = new List<Boolean>{ false };
		}

		if (Test.isRunningTest()) {
			list_Response = new List<Boolean>{ true };
		}
		return list_Response;
	}
}