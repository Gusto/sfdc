/**
 * Utility class for creating users for tests, giving them specific attributes
 * @author David Schach
 * @since 2021-12-09
 * @see TestDataFactory
 * @see UserUtils
 */
@isTest
public without sharing class TestUserUtility {
	private static User currentUser;
	private static User objAdminUser;
	private static User objIntegrationUser;
	private static User objMDRUser;
	private static User objPartnerAEUser;

	/**
	 * @description Lazy load / memoize the current user to avoid extra queries
	 *
	 * @return      `User` the running/current user
	 */
	public static User getRunningUser() {
		if (currentUser == null) {
			currentUser = UserUtils.returnLoggedInUser();
		}
		return currentUser;
	}

	/**
	 * @description Set up a user with ModifyAllData and default user values
	 * @author David Schach
	 * @param  doInsert If true, do insert and return record. If false, just return record.
	 * @return          return the assembled User
	 */
	public static User createAdminUser(Boolean doInsert) {
		if (objAdminUser != null) {
			return objAdminUser;
		}
		objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('adminu')
			.setEmail('gustoadminuser@testorg.com')
			.setEmailEncoding('ISO-8859-1')
			.setFirstName('Admin')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId([SELECT Id, Name, UserLicense.Name, UserLicenseId, UserType FROM Profile WHERE PermissionsModifyAllData = TRUE LIMIT 1].Id)
			.setUserRoleId([SELECT Id, Name FROM UserRole WHERE Name = 'admin' LIMIT 1].Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testAdminUser@testorg.com')
			.setIsAPIIntegration(false)
			.setExemptfromValidationRules(false)
			.build();

		if (doInsert) {
			System.runAs(getRunningUser()) {
				insert objAdminUser;
			}
		}
		return objAdminUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted Admin User
	 *
	 * @return  `User` the created Admin User
	 */
	public static User getAdminUser() {
		if (objAdminUser == null) {
			objAdminUser = getAdminUser(true);
		}
		return objAdminUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted Admin User
	 * <br>Gives us the option of getting the user if it exists, and of creating and optionally inserting if it does not
	 *
	 * @param create Should the created user be inserted, or should we just return the instantiated User
	 * @return       `User` the Admin user
	 */
	public static User getAdminUser(Boolean create) {
		if (objAdminUser == null) {
			objAdminUser = createAdminUser(create);
		}
		return objAdminUser;
	}

	/**
	 * @description Set up a User using TestDataFactory that can have the appropriate permissions for integration.
	 * <br>If inserted, we also add the permission set for Workato. If not, a base integration user record is created.
	 *
	 * @param doInsert If true, insert the User. Otherwise, just return the User record.
	 * @return         `User`
	 */
	public static User createIntegrationUser(Boolean doInsert) {
		if (objIntegrationUser != null) {
			return objIntegrationUser;
		}
		objIntegrationUser = new TestDataFactory.UserBuilder()
			.setAlias('intu')
			.setEmail('apientegration_user@testorg.com')
			.setEmailEncoding('ISO-8859-1')
			.setFirstName('Integration')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId([SELECT Id, Name, UserLicense.Name, UserLicenseId, UserType FROM Profile WHERE Profile.Name = 'API Integration' LIMIT 1].Id)
			.setUserRoleId([SELECT Id, Name FROM UserRole WHERE Name = 'Integration Users' LIMIT 1].Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testIntegUser@testorg.com')
			.setIsAPIIntegration(true)
			.setExemptfromValidationRules(true)
			.build();

		if (doInsert) {
			System.runAs(getRunningUser()) {
				insert objIntegrationUser;

				PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Workato_Integration' LIMIT 1];
				PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = objIntegrationUser.Id, PermissionSetId = ps.Id);
				insert psa;
			}
		}
		return objIntegrationUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted Integration User
	 *
	 * @return  `User` the created Integration User
	 */
	public static User getIntegrationUser() {
		if (objIntegrationUser == null) {
			objIntegrationUser = getIntegrationUser(true);
		}
		return objIntegrationUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted Integration User
	 * <br>Gives us the option of getting the user if it exists, and of creating and optionally inserting if it does not
	 *
	 * @param create Should the created user be inserted, or should we just return the instantiated User
	 * @return       `User` the integration user
	 */
	public static User getIntegrationUser(Boolean create) {
		if (objIntegrationUser == null) {
			objIntegrationUser = createIntegrationUser(create);
		}
		return objIntegrationUser;
	}

	/**
	 * @description Set up a User using TestDataFactory that has MDR profile and role
	 * @author David Schach
	 * @param  doInsert If true, insert the User. Otherwise, just return the User record.
	 * @return          return the assembled User
	 */
	public static User createMDRUser(Boolean doInsert) {
		if (objMDRUser != null) {
			return objMDRUser;
		}
		objMDRUser = new TestDataFactory.UserBuilder()
			.setAlias('mdru')
			.setEmail('mdruser@testorg.com')
			.setEmailEncoding('ISO-8859-1')
			.setFirstName('MDR')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId([SELECT Id, Name, UserLicense.Name, UserLicenseId, UserType FROM Profile WHERE Profile.Name = 'Gusto Direct MDR' LIMIT 1].Id)
			.setUserRoleId([SELECT Id, Name FROM UserRole WHERE Name = :LeadUtil.LABEL_SDR_PARTNER_USR_ROLE LIMIT 1].Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testMDRUsr@testorg.com')
			.setIsAPIIntegration(false)
			.setExemptfromValidationRules(false)
			.build();

		if (doInsert) {
			System.runAs(getRunningUser()) {
				insert objMDRUser;
			}
		}
		return objMDRUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted MDR User
	 *
	 * @return  `User` the created PartnerAE User
	 */
	public static User getMDRUser() {
		if (objMDRUser == null) {
			objMDRUser = getMDRUser(true);
		}
		return objMDRUser;
	}

	/**
	 * @description Lazy-load the admin user so we can call this to get the inserted MDR User
	 * <br>Gives us the option of getting the user if it exists, and of creating and optionally inserting if it does not
	 *
	 * @param create Should the created user be inserted, or should we just return the instantiated User
	 * @return       `User` the PartnerAE user
	 */
	public static User getMDRUser(Boolean create) {
		if (objMDRUser == null) {
			objMDRUser = createMDRUser(create);
		}
		return objMDRUser;
	}

	/**
	 * @description Set up a User using TestDataFactory that has MDR Profile & Partner AE role
	 * @author David Schach
	 * @param  doInsert If true, insert the User. Otherwise, just return the User record.
	 * @return          return the assembled User
	 */
	public static User createPartnerAEUser(Boolean doInsert) {
		if (objPartnerAEUser != null) {
			return objPartnerAEUser;
		}
		objPartnerAEUser = new TestDataFactory.UserBuilder()
			.setAlias('paeu')
			.setEmail('paeuser@testorg.com')
			.setEmailEncoding('ISO-8859-1')
			.setFirstName('PartnerAE')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId([SELECT Id, Name, UserLicense.Name, UserLicenseId, UserType FROM Profile WHERE Profile.Name = 'Gusto Direct MDR' LIMIT 1].Id)
			.setUserRoleId([SELECT Id, Name FROM UserRole WHERE Name = :LeadUtil.LABEL_PARTNER_AE_USR_ROLE LIMIT 1].Id)
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('testPAEUser@testorg.com')
			.setIsAPIIntegration(false)
			.setExemptfromValidationRules(false)
			.build();

		if (doInsert) {
			System.runAs(getRunningUser()) {
				insert objPartnerAEUser;
			}
		}
		return objPartnerAEUser;
	}

	/**
	 * @description Lazy-load the partner AE user so we can call this to get the inserted Admin User
	 *
	 * @return  `User` the created MDR User
	 */
	public static User getPartnerAEUser() {
		if (objPartnerAEUser == null) {
			objPartnerAEUser = getPartnerAEUser(true);
		}
		return objPartnerAEUser;
	}

	/**
	 * Lazy-load the admin user so we can call this to get the inserted partner AE User
	 * <br>Gives us the option of getting the user if it exists, and of creating and optionally inserting if it does not
	 *
	 * @param create Should the created user be inserted, or should we just return the instantiated User
	 * @return       `User` the MDR user
	 */
	public static User getPartnerAEUser(Boolean create) {
		if (objPartnerAEUser == null) {
			objPartnerAEUser = createPartnerAEUser(create);
		}
		return objPartnerAEUser;
	}

	/**
	 * @description Simple test method to ensure that users can be created with all required fields
	 * @author David Schach
	 */
	@isTest
	private static void testCreateUsers() {
		getAdminUser();
		getIntegrationUser();
		getMDRUser();
		getPartnerAEUser();
		getRunningUser();
		// Run twice to ensure we do not create users with duplicate usernames
		getAdminUser();
		getIntegrationUser();
		getMDRUser();
		getPartnerAEUser();
		getRunningUser();
		System.assertEquals(1, [SELECT COUNT() FROM User WHERE Alias = 'adminu']);
	}
}