/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 **/
@isTest
public class SalesforceOrgNotificationFlowCtrlTest {
	@isTest
	private static void executeDynamicSOQLUnitTest() {
		List<SalesforceOrgNotificationFlowCtrl.SFOrgNotificationInputWrapper> lst_SFOrgNotificationInputWrapper = new List<SalesforceOrgNotificationFlowCtrl.SFOrgNotificationInputWrapper>();

		for (Salesforce_Org_Notifications__mdt objSalesforceOrgNotification : [
			SELECT Id, DeveloperName, SOQL_Query__c
			FROM Salesforce_Org_Notifications__mdt
			WHERE DeveloperName = 'Org_Notification_1'
		]) {
			SalesforceOrgNotificationFlowCtrl.SFOrgNotificationInputWrapper objSFOrgNotificationInputWrapper = new SalesforceOrgNotificationFlowCtrl.SFOrgNotificationInputWrapper();
			objSFOrgNotificationInputWrapper.strSOQL = objSalesforceOrgNotification.SOQL_Query__c;
			lst_SFOrgNotificationInputWrapper.add(objSFOrgNotificationInputWrapper);
		}

		List<SalesforceOrgNotificationFlowCtrl.SFOrgNotificationOutputWrapper> lst_Output = SalesforceOrgNotificationFlowCtrl.executeDynamicSOQL(lst_SFOrgNotificationInputWrapper);
		System.assert(lst_Output.size() > 0);
	}
}