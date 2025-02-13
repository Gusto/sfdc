/**
 * @description  To test WalletBotHOOPCheck
 * @author       Praveen Sethu
 * @date         10-07-2022
 **/
@isTest
public with sharing class WalletBotHOOPCheckTest {
	/**
	 * @Author:			Praveen Sethu
	 * @Description:	Tests if invocable is able to send a flag for HOOP hour check
	 * @Parms:			NA
	 */
	@isTest
	public static void testHOOPHours() {
		List<Boolean> list_Response = WalletBotHOOPCheck.isBusinessHour();
		System.assertEquals(true, list_Response.get(0));
	}
}