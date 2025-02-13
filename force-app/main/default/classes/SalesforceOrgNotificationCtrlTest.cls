/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 **/
@isTest
public class SalesforceOrgNotificationCtrlTest {
	@isTest
	private static void getOrgLimiDetailsUnitTest() {
		List<SalesforceOrgNotificationCtrl.SalesforceOrgLimitWrapper> lst_SalesforceOrgLimitDetails = SalesforceOrgNotificationCtrl.getOrgLimiDetails();
		System.assert(lst_SalesforceOrgLimitDetails.size() > 0);
	}
}