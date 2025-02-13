/**
 * @description Test class for OrganizationUtilities
 * @author @dschach David Schach
 * @date 2021-11-17
 */
@IsTest
private class OrganizationUtilitiesTest {
	@isTest
	private static void getInstance() {
		String strInstance = '';
		Organization objOrgO = [SELECT OrganizationType, isSandbox, InstanceName FROM Organization LIMIT 1];
		String strOrgType = objOrgO.OrganizationType;
		String strInsName = objOrgO.InstanceName;

		//Set this header to test it
		ApexPages.currentPage().getHeaders().put('Host', strInsName + '.visual.force.com');

		if (strOrgType == 'Developer Edition') {
			List<String> list_parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
			strInstance = list_parts[list_parts.size() - 4] + '.';
		}

		System.assertEquals(objOrgO.InstanceName, OrganizationUtilities.getInstance());

		OrganizationUtilities.orgThisOrg = null;
		System.assertEquals(objOrgO.isSandbox, OrganizationUtilities.isSandbox());
		System.assertEquals(!objOrgO.isSandbox, OrganizationUtilities.isProduction());

		System.assert(OrganizationUtilities.getBaseURL().startsWithIgnoreCase('https'));
	}

	@isTest
	private static void getSubdomainPrefix() {
		//This will always be empty unless it's sandbox
		if (OrganizationUtilities.isProduction()) {
			System.assertEquals('', OrganizationUtilities.getSubdomainPrefix());
		} else {
			System.assertNotEquals('', OrganizationUtilities.getSubdomainPrefix());
		}
	}

	@isTest
	private static void runEmailMethods() {
		OrganizationUtilities.canSendEmails();
		OrganizationUtilities.canSendEmails(1);
	}
}