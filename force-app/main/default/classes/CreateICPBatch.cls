/**
 * This class is responsible for creating a batch process to update Account records.
 * It implements the Database.Batchable interface and the Database.Stateful interface.
 * The batch process queries for Account records that meet certain criteria and updates them accordingly.
 * The process temporarily disables a trigger to avoid recursion.
 */

public class CreateICPBatch implements Database.Batchable<SObject>, Database.Stateful {
	// Map to store Account Id and Product Interest
	Map<String, String> map_AccIDAndInterest = new Map<String, String>();

	// Start method to query for the records to be processed
	public Database.QueryLocator start(Database.BatchableContext bc) {
		// Query for the records to be processed
		return Database.getQueryLocator(
			[
				SELECT Id, Product_Interest__c
				FROM Account
				WHERE
					Product_Interest__c INCLUDES (
						'international_contractor_payment_onboarding',
						'international_contractor_payment_landing_page',
						'international_contractor_payment_onboarded',
						'international_contractor_payment_add_IC',
						'international_contractor_payment_paid',
						'international_contractor_payment_logacall'
					)
					AND Id NOT IN (SELECT AccountId FROM Opportunity WHERE RecordType.DeveloperName = 'Tier_Upsell_Opportunity' AND Type = 'Cross Sell')
			]
		);
	}

	// Execute method to process the records
	public void execute(Database.BatchableContext bc, List<Account> scope) {
		System.debug('Scope size: ' + scope.size());
		List<Account> list_AccountToUpdate = new List<Account>();
		// Process the records
		for (Account objAccount : scope) {
			if (String.isNotBlank(objAccount.Product_Interest__c)) {
				map_AccIDAndInterest.put(objAccount.Id, objAccount.Product_Interest__c);
			}
			System.debug('map_AccIDAndInterest: ' + map_AccIDAndInterest);
			// Remove the international_contractor from the Product Interest field
			if (String.isNotBlank(objAccount.Product_Interest__c) && objAccount.Product_Interest__c.containsIgnoreCase('international_contractor')) {
				Set<String> set_ProdInt = new Set<String>();
				// Split the Product Interest field value by semicolon and add to the set
				for (String strProdInt : objAccount.Product_Interest__c.split(';')) {
					if (!strProdInt.containsIgnoreCase('international_contractor')) {
						set_ProdInt.add(strProdInt);
					}
				}
				// Update the Account record with the new Product Interest field value
				if (!set_ProdInt.isEmpty()) {
					// Join the set elements with semicolon
					objAccount.Product_Interest__c = String.join(new List<String>(set_ProdInt), ';');
				} else {
					// Set the Product Interest field to null if the set is empty
					objAccount.Product_Interest__c = null;
				}
				// Add the Account record to the list to be updated
				list_AccountToUpdate.add(objAccount);
			}
		}

		System.debug('list_AccountToUpdate: ' + list_AccountToUpdate);
		// Temporarily disable the trigger
		AccountTriggerHelper.skipTrigger = true;
		update list_AccountToUpdate;
		AccountTriggerHelper.skipTrigger = false;

		// Clear the list
		list_AccountToUpdate.clear();

		// Update the Account records with the original Product Interest field value
		for (String strAccId : map_AccIDAndInterest.keySet()) {
			Account objAccount = new Account(Id = strAccId, Product_Interest__c = map_AccIDAndInterest.get(strAccId));
			list_AccountToUpdate.add(objAccount);
		}

		System.debug('list_AccountToUpdate1: ' + list_AccountToUpdate);
		update list_AccountToUpdate;
	}

	public void finish(Database.BatchableContext bc) {
		// Any final actions after the batch completes
	}
}