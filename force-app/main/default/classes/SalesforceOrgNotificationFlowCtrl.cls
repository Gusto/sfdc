/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 * @description This class will be used to execute dynamic count soql query.
 * Test class: SalesforceOrgNotificationFlowCtrlTest
 **/
public class SalesforceOrgNotificationFlowCtrl {
	/**
	 * @description : It will be used to execute dynamic count soql query and return the count.
	 * @author Yogesh Kherajani
	 * @param lst_SFOrgNotificationInputWrapper
	 * @return List of SFOrgNotificationOutputWrapper
	 */
	@InvocableMethod(label='Execute Dynamic SOQL')
	public static List<SFOrgNotificationOutputWrapper> executeDynamicSOQL(List<SFOrgNotificationInputWrapper> lst_SFOrgNotificationInputWrapper) {
		List<SFOrgNotificationOutputWrapper> lst_SFOrgNotificationOutputWrapper = new List<SFOrgNotificationOutputWrapper>();

		for (SFOrgNotificationInputWrapper objSFOrgNotification : lst_SFOrgNotificationInputWrapper) {
			SFOrgNotificationOutputWrapper objSFOrgNotificationOutput = new SFOrgNotificationOutputWrapper();

			objSFOrgNotificationOutput.intTotalRecCount = Database.countQuery(objSFOrgNotification.strSOQL);

			lst_SFOrgNotificationOutputWrapper.add(objSFOrgNotificationOutput);
		}

		return lst_SFOrgNotificationOutputWrapper;
	}

	public class SFOrgNotificationInputWrapper {
		@InvocableVariable
		public String strSOQL;
	}

	public class SFOrgNotificationOutputWrapper {
		@InvocableVariable
		public Integer intTotalRecCount;
	}
}