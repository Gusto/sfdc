/**
 * Created by brent.johnson on 11/24/16.
 */

public without sharing virtual class Program {
	public static Map<Id, Pricebook2> pricebook2s {
		get {
			if (pricebook2s == null) {
				pricebook2s = new Map<Id, Pricebook2>([SELECT Id, Name, IsActive FROM Pricebook2]);
			}
			return pricebook2s;
		}
		private set;
	}

	public static Map<Id, Product2> product2s {
		get {
			if (product2s == null) {
				product2s = new Map<Id, Product2>([SELECT Id, Name, IsActive FROM Product2]);
			}
			return product2s;
		}
		private set;
	}

	public static Map<Id, PricebookEntry> pricebookEntries {
		get {
			if (pricebookEntries == null) {
				pricebookEntries = new Map<Id, PricebookEntry>([SELECT Id, Pricebook2Id, Product2Id, IsActive, Maintain__c, UnitPrice, Pricebook2.Name, Product2.Name FROM PricebookEntry]);
			}
			return pricebookEntries;
		}
		private set;
	}

	static Map<Schema.SObjectType, Map<Id, SObject>> ProgramCache = new Map<Schema.SObjectType, Map<Id, SObject>>();

	public static void loadAccounts(Set<Id> accountIds) {
		load(
			[
				SELECT
					Id,
					Previous_Payroll_Provider__c,
					BillingStreet,
					BillingPostalCode,
					BillingCity,
					BillingState,
					BillingStateCode,
					BillingCountry,
					BillingCountryCode,
					ShippingStreet,
					ShippingPostalCode,
					ShippingCity,
					ShippingState,
					ShippingStateCode,
					ShippingCountry,
					ShippingCountryCode,
					Pricebook2__c
				FROM Account
				WHERE Id IN :accountIds
			]
		);
	}

	public static void loadOpportunities(Set<Id> opportunityIds) {
		load([SELECT Id, Pricebook2Id FROM Opportunity WHERE Id IN :opportunityIds]);
	}

	public static void loadOrdersWithOrderItems(Set<Id> orderIds) {
		load([SELECT Id, (SELECT Id, PricebookEntryId FROM OrderItems) FROM Order WHERE Id IN :orderIds]);
	}

	public static Account getAccount(Id accountId) {
		return (Account) getSObject(Schema.Account.SObjectType, accountId);
	}

	public static Order getOrderWithOrderItems(Id orderId) {
		return (Order) getSObject(Schema.Order.SObjectType, orderId);
	}

	public static Opportunity getOpportunity(Id opportunityId) {
		return (Opportunity) getSObject(Schema.Opportunity.SObjectType, opportunityId);
	}

	static SObject getSObject(Schema.SObjectType sObjType, Id sObjId) {
		SObject sObj = null;
		if (ProgramCache.containsKey(sObjType)) {
			Map<Id, SObject> sObjMap = ProgramCache.get(sObjType);
			if (sObjMap.containsKey(sObjId)) {
				sObj = sObjMap.get(sObjId);
			}
		}
		return sObj;
	}

	static void load(List<SObject> sObjs) {
		load(sObjs.getSObjectType(), sObjs);
	}

	static void load(Schema.SObjectType sObjType, List<SObject> sObjs) {
		if (!ProgramCache.containsKey(sObjType))
			ProgramCache.put(sObjType, new Map<Id, SObject>());
		ProgramCache.get(sObjType).putAll(sObjs);
	}
}