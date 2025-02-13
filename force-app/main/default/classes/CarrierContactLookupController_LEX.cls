/**
 * Author: Lakshey Mendiratta
 * Date: 9/17/2020
 * Desc: Controller for CarrierContactLookUp LWC
 */
public with sharing class CarrierContactLookupController_LEX {
	@AuraEnabled(Cacheable=true)
	public static List<Contact> getContacts(String strSearchText, Id idAccount) {
		//Method to fetch contacts related to carrier account
		String strContactName = '%' + strSearchText + '%';
		return [SELECT Id, Name, Email, Account.Name FROM Contact WHERE Name LIKE :strContactName AND AccountId = :idAccount];
	}
}