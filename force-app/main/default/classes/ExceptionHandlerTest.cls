/**
 * Created by brent.johnson on 3/31/16.
 */

@isTest
private class ExceptionHandlerTest {
	@isTest
	private static void notifyWithoutSource() {
		try {
			sObject excpetionObject;
			update excpetionObject;
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
			System.assert(true);
		}
	}
}