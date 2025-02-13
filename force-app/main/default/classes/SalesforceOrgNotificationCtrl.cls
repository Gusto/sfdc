/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 * @description This class will provide limit details about certain operations like Daily Async, Data Storage etc.
 * Test class: SalesforceOrgNotificationCtrlTest
 **/
public class SalesforceOrgNotificationCtrl {
	/**
	 * @description : It will be call from the flow and provide limit details about certain operations like Daily Async, Data Storage etc.
	 * @author Yogesh Kherajani
	 * @return List of SalesforceOrgLimitWrapper
	 */
	@InvocableMethod(label='Get Org Limit Details')
	public static List<SalesforceOrgLimitWrapper> getOrgLimiDetails() {
		Set<String> set_LimitTypes = new Set<String>{ 'DailyAsyncApexExecutions', 'DailyApiRequests', 'SingleEmail' };

		Map<String, System.OrgLimit> map_LimitsMap = OrgLimits.getMap();

		SalesforceOrgLimitWrapper objSalesforceOrgLimit = new SalesforceOrgLimitWrapper();
		SalesforceOrgLimitDetails objSalesforceOrgLimitDetails = new SalesforceOrgLimitDetails();

		for (String limitType : set_LimitTypes) {
			System.OrgLimit objApiRequestsLimit = map_LimitsMap.get(limitType);

			Decimal decMaxValue = objApiRequestsLimit.getLimit();
			Decimal decUsageValue = objApiRequestsLimit.getValue();
			Decimal decRemaningValue = decMaxValue - decUsageValue;

			Decimal decConsumptionValue = (decUsageValue / decMaxValue) * 100;

			if (limitType == 'DailyAsyncApexExecutions') {
				objSalesforceOrgLimitDetails.decAsyncLimitConsumption = decConsumptionValue;
				objSalesforceOrgLimitDetails.decAsyncLimitMax = decMaxValue;
				objSalesforceOrgLimitDetails.decAsyncLimitRemaning = decRemaningValue;
			}  else if (limitType == 'DailyApiRequests') {
				objSalesforceOrgLimitDetails.decDailyAPIRequestConsumption = decConsumptionValue;
				objSalesforceOrgLimitDetails.decDailyAPIRequestMax = decMaxValue;
				objSalesforceOrgLimitDetails.decDailyAPIRequestRemaning = decRemaningValue;
			} else if (limitType == 'SingleEmail') {
				objSalesforceOrgLimitDetails.decSingleEmailConsumption = decConsumptionValue;
				objSalesforceOrgLimitDetails.decSingleEmailMax = decMaxValue;
				objSalesforceOrgLimitDetails.decSingleEmailRemaning = decRemaningValue;
			}
		}

		objSalesforceOrgLimit.objSalesforceOrgLimitDetails = objSalesforceOrgLimitDetails;

		return new List<SalesforceOrgLimitWrapper>{ objSalesforceOrgLimit };
	}

	public class SalesforceOrgLimitWrapper {
		@InvocableVariable
		public SalesforceOrgLimitDetails objSalesforceOrgLimitDetails;
	}
}