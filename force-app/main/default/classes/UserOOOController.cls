/*
 * Description: Contains methods to set and User OOO
 * Author: Omar Benitez
 * Date: 07/02/2024
 */
public without sharing class UserOOOController {
	/* Method will update the Out Of Offices from User */
	@AuraEnabled
	public static void updateUserOOO(String strUserId, Boolean blnIsOOO) {
		try {
			UserTriggerHelper.skipTrigger = true;
			update new User(Id = strUserId, Out_Of_Office__c = blnIsOOO);
		} catch (Exception objException) {
			throw new AuraHandledException('Something went wrong: ' + objException.getMessage());
		}
	}
}