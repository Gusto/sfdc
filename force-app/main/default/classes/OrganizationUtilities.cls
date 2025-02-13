/**
 * @author David Schach
 * @date 2021-11-17
 * @description Organization-level utility class. Running without sharing as need to run query on Organization table
 * @see OrganizationUtilitiesTest
 * @group Utilities
 */
public without sharing class OrganizationUtilities {
	/**
	 * @description Private method to query and memoize this org
	 * @author David Schach
	 * @return   this Organization record
	 */
	@TestVisible
	private static Organization orgThisOrg {
		get {
			if (orgThisOrg == null) {
				orgThisOrg = [SELECT Id, InstanceName, IsReadOnly, IsSandbox, FiscalYearStartMonth FROM Organization WHERE Id = :UserInfo.getOrganizationId() LIMIT 1];
			}
			return orgThisOrg;
		}
		set;
	}

	/**
	 * @description Get instance (likely unnecessary once URL stabilization release update is implemented)
	 * @author David Schach
	 * @return   org InstanceName
	 */
	public static String getInstance() {
		return orgThisOrg.InstanceName;
	}

	/**
	 * @description Needed in cases where current org is sandbox
	 *
	 * @return      Org subdomain prefix
	 */
	public static String getSubdomainPrefix() {
		if (orgThisOrg.isSandbox) {
			return UserInfo.getUserName().substringAfterLast('.') + '-';
		}
		return '';
	}

	/**
	 * @description Method to lazy-load organization start month to avoid extra queries in GlobalQueryHelper
	 *
	 * @author David Schach
	 * @return      `Integer` Month of start of fiscal year
	 */
	public static Integer getFiscalYearStartMonth() {
		return orgThisOrg.FiscalYearStartMonth;
	}

	/**
	 * @description Is this org a sandbox?
	 * @author David Schach
	 * @return   Boolean is true if the current org is a sandbox; false in production
	 */
	public static Boolean isSandbox() {
		return orgThisOrg.isSandbox;
	}
	/**
	 * @description Is this a sandbox or production?
	 * @author David Schach
	 * @return   Is Production (is not a sandbox)
	 */
	public static Boolean isProduction() {
		return !orgThisOrg.isSandbox;
	}

	/**
	 * @description Used to check if can send emails so we don't throw exceptions when turning deliverability off in a sandbox or hitting a limit
	 * @author David Schach
	 * @return   Can the org send emails? (Will we hit a limit, and is deliverability on?)
	 */
	public static Boolean canSendEmails() {
		return canSendEmails(1);
	}

	/**
	 * @description An attempt to reserve some email capacity is the only means available for determining permissions
					or limits issues. In the case of a lack of permissions, System.NoAccessException is thrown. If
					limits are exhausted then System.HandledException is thrown
	 * @author David Schach
	 * @param  intCount How many emails do we need to send?
	 * @return          `Boolean` true/false
	 */
	public static Boolean canSendEmails(Integer intCount) {
		Boolean boolOrgCanSendEmails;
		try {
			Messaging.reserveSingleEmailCapacity(intCount);
			boolOrgCanSendEmails = true;
		} catch (Exception e) {
			boolOrgCanSendEmails = false;
		}
		return boolOrgCanSendEmails;
	}

	/**
	 * @description Single point to get organization base URL for sharing links
	 * @author David Schach
	 * @return   BaseURL in external form
	 */
	private static String baseURL;
	public static String getBaseURL() {
		if (baseURL == null) {
			baseURL = URL.getSalesforceBaseUrl().toExternalForm();
		}
		return baseUrl;
	}
}