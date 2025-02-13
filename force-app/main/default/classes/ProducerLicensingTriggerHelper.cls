/**
 * @description  Handler class used for consolidating user licenses and updating on User object
 * @author       Praveen Sethu
 * @date         03-16-2023
 * @see          ProducerLicensingTriggerHelperTest
 **/
public with sharing class ProducerLicensingTriggerHelper {
	// initialize all variables here
	Map<Id, User> map_UsersToUpdate = new Map<Id, User>();
	Map<Id, User> map_Users = new Map<Id, User>();
	Map<Id, List<agentsync__Producer_Licensing__c>> map_ActiveProducerLicenses = new Map<Id, List<agentsync__Producer_Licensing__c>>();

	public static String STATUS_ACTIVE = 'Active';

	/**
	 * @description Process After Insert Context
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void processAfterInsert(Map<Id, agentsync__Producer_Licensing__c> map_NewProducerLicenses) {
		createCollectionsAfter(map_NewProducerLicenses, null);

		for (agentsync__Producer_Licensing__c objProducerLicense : map_NewProducerLicenses.values()) {
			setActiveLicense(objProducerLicense);
		}

		// process all updates
		if (!map_UsersToUpdate.isEmpty()) {
			UserTriggerHelper.skipTrigger = true;
			update map_UsersToUpdate.values();
			UserTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * @description Run After Update Context
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void processAfterUpdate(Map<Id, agentsync__Producer_Licensing__c> map_NewProducerLicenses, Map<Id, agentsync__Producer_Licensing__c> map_OldProducerLicenses) {
		// query records and populate collection variables
		createCollectionsAfter(map_NewProducerLicenses, map_OldProducerLicenses);

		// iterate over each producer licensing record
		for (agentsync__Producer_Licensing__c objProducerLicense : map_NewProducerLicenses.values()) {
			List<agentsync__Producer_Licensing__c> list_ProducerLicenses = new List<agentsync__Producer_Licensing__c>{ objProducerLicense };
			agentsync__Producer_Licensing__c objOldProducerLicense = new agentsync__Producer_Licensing__c();

			// if old record exist, check if agentsync user changes
			if (map_OldProducerLicenses != null && map_OldProducerLicenses?.containsKey(objProducerLicense.Id)) {
				// get old record from trigger old map
				objOldProducerLicense = map_OldProducerLicenses.get(objProducerLicense.Id);

				// check if user reference exist - update the list
				if (objProducerLicense.agentsync__User__c != objOldProducerLicense.agentsync__User__c) {
					list_ProducerLicenses.add(objOldProducerLicense);
				}
			}

			// iterate over old and new producer licensing record and update active license on User object
			for (agentsync__Producer_Licensing__c objProdLicense : list_ProducerLicenses) {
				setActiveLicense(objProdLicense);
			}
		}

		// process all updates
		if (!map_UsersToUpdate.isEmpty()) {
			UserTriggerHelper.skipTrigger = true;
			update map_UsersToUpdate.values();
			UserTriggerHelper.skipTrigger = false;
		}
	}

	/**
	 * @description Consolidates all active producer licensing records and updates it on the User record
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void setActiveLicense(agentsync__Producer_Licensing__c objProducerLicense) {
		// check user is available in map of active producer license
		if (map_ActiveProducerLicenses.containsKey(objProducerLicense.agentsync__User__c)) {
			// get list of active producer licenses from map
			List<agentsync__Producer_Licensing__c> list_ActiveProducerLicenses = map_ActiveProducerLicenses.get(objProducerLicense.agentsync__User__c);

			// check if user exist in map of users
			if (map_Users.containsKey(objProducerLicense.agentsync__User__c)) {
				User objUser = map_Users.get(objProducerLicense.agentsync__User__c);

				// update active license only if user is active
				if (objUser.IsActive) {
					Set<String> set_States = new Set<String>();

					// iterate over active producer license record and update set of states
					for (agentsync__Producer_Licensing__c objActiveProducerLicense : list_ActiveProducerLicenses) {
						if (String.isNotBlank(objActiveProducerLicense.agentsync__STATE__c)) {
							set_States.add(objActiveProducerLicense.agentsync__STATE__c);
						}
					}

					String strActiveLicenses = String.join(new List<String>(set_States), ';');

					// update active license on user record if does not match
					if (objUser.Active_License__c != strActiveLicenses) {
						objUser.Active_License__c = strActiveLicenses;
						map_UsersToUpdate.put(objUser.Id, objUser);
					}
				} else {
					if (String.isNotBlank(objUser.Active_License__c)) {
						objUser.Active_License__c = '';
						map_UsersToUpdate.put(objUser.Id, objUser);
					}
				}
			}
		} else {
			// no active license found - reset active license on user
			if (map_Users.containsKey(objProducerLicense.agentsync__User__c)) {
				User objUser = map_Users.get(objProducerLicense.agentsync__User__c);

				if (String.isNotBlank(objUser.Active_License__c)) {
					objUser.Active_License__c = '';
					map_UsersToUpdate.put(objUser.Id, objUser);
				}
			}
		}
	}

	/**
	 * @description Populating collection variables needed for processing producer licensing
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void createCollectionsAfter(Map<Id, agentsync__Producer_Licensing__c> map_NewProducerLicenses, Map<Id, agentsync__Producer_Licensing__c> map_OldProducerLicenses) {
		Set<Id> set_Users = new Set<Id>();

		for (agentsync__Producer_Licensing__c objProducerLicense : map_NewProducerLicenses.values()) {
			agentsync__Producer_Licensing__c objOldProducerLicense = new agentsync__Producer_Licensing__c();

			if (map_OldProducerLicenses != null && map_OldProducerLicenses?.containsKey(objProducerLicense.Id)) {
				objOldProducerLicense = map_OldProducerLicenses.get(objProducerLicense.Id);
			}

			// add user ids from old and new producer licensing records
			if (objProducerLicense.agentsync__User__c != null) {
				set_Users.add(objProducerLicense.agentsync__User__c);
			}

			if (objOldProducerLicense != null && objOldProducerLicense.agentsync__User__c != null) {
				set_Users.add(objOldProducerLicense.agentsync__User__c);
			}
		}
		// query users & active producer licensing records linked to their user records
		if (!set_Users.isEmpty()) {
			queryUsers(set_Users);
			queryActiveProducerLicenses(set_Users);
		}
	}

	/**
	 * @description Query users from a user and populate a map of user id and user object
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void queryUsers(Set<Id> set_Users) {
		for (User objUser : [SELECT Id, Active_License__c, IsActive FROM User WHERE Id IN :set_Users]) {
			map_Users.put(objUser.Id, objUser);
		}
	}

	/**
	 * @description Query all active producer licenses and build a map of user id and list of active producer licenses
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public void queryActiveProducerLicenses(Set<Id> set_Users) {
		for (agentsync__Producer_Licensing__c objProducerLicense : [
			SELECT Id, agentsync__Related_Producer_Tracking__c, agentsync__STATE__c, agentsync__User__c
			FROM agentsync__Producer_Licensing__c
			WHERE agentsync__User__c IN :set_Users AND agentsync__Related_Producer_Tracking__c = :STATUS_ACTIVE
		]) {
			// if user already exists in map, append to existing a list of producer licenses
			if (map_ActiveProducerLicenses.containsKey(objProducerLicense.agentsync__User__c)) {
				List<agentsync__Producer_Licensing__c> list_TempProducerLicenses = map_ActiveProducerLicenses.get(objProducerLicense.agentsync__User__c);
				list_TempProducerLicenses.add(objProducerLicense);
				map_ActiveProducerLicenses.put(objProducerLicense.agentsync__User__c, list_TempProducerLicenses);
			} else {
				// if user does not exist - add new values to map
				map_ActiveProducerLicenses.put(objProducerLicense.agentsync__User__c, new List<agentsync__Producer_Licensing__c>{ objProducerLicense });
			}
		}
	}
}