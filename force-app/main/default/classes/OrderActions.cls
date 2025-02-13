/**
 * Created by brent.johnson on 11/25/16.
 */

public without sharing class OrderActions {
	public class OrderActionsException extends Exception {
	}

	abstract class OrderActionBase implements Actionable {
		Order order;

		OrderActionBase(Order order) {
			this.order = order;
		}
	}

	class PricebookAssigner extends OrderActions.OrderActionBase {
		PricebookAssigner(Order order) {
			super(order);
		}

		public void execute() {
			Id opportunityPricebookId = getOpportunityPricebookId();
			if (opportunityPricebookId != null) {
				setPricebook(opportunityPricebookId);
			} else {
				Id accountPricebookId = getAccountPricebookId();
				if (accountPricebookId != null) {
					setPricebook(accountPricebookId);
				}
			}
		}

		void setPricebook(Id pricebookId) {
			order.Pricebook2Id = pricebookId;
		}

		Id getOpportunityPricebookId() {
			if (order == null) {
				return null;
			} else {
				return getOpportunityPricebookId(order);
			}
		}

		Id getOpportunityPricebookId(Order order) {
			Id opportunityId = order.OpportunityId;
			if (opportunityId == null) {
				return null;
			} else {
				return getOpportunityPricebookId(opportunityId);
			}
		}

		Id getOpportunityPricebookId(Id opportunityId) {
			Opportunity opportunity = getOpportunity();
			if (opportunity == null) {
				return null;
			} else {
				return getOpportunityPricebookId(opportunity);
			}
		}

		Id getOpportunityPricebookId(Opportunity opportunity) {
			Id opportunityPricebookId = opportunity.Pricebook2Id;
			if (opportunityPricebookId == null) {
				return null;
			} else {
				return opportunityPricebookId;
			}
		}

		Id getAccountPricebookId() {
			if (order == null) {
				return null;
			} else {
				return getAccountPricebookId(order);
			}
		}

		Id getAccountPricebookId(Order order) {
			Id accountId = order.AccountId;
			if (accountId == null) {
				return null;
			} else {
				return getAccountPricebookId(accountId);
			}
		}

		Id getAccountPricebookId(Id accountId) {
			Account account = getAccount();
			if (account == null) {
				return null;
			} else {
				return getAccountPricebookId(account);
			}
		}

		Id getAccountPricebookId(Account account) {
			Id accountPricebookId = account.Pricebook2__c;
			if (accountPricebookId == null) {
				return null;
			} else {
				return accountPricebookId;
			}
		}

		Account getAccount() {
			Account account = Program.getAccount(order.AccountId);
			if (account == null) {
				Program.loadAccounts(new Set<Id>{ order.AccountId });
				return Program.getAccount(order.AccountId);
			}
			return account;
		}

		Opportunity getOpportunity() {
			Opportunity opportunity = Program.getOpportunity(order.OpportunityId);
			if (opportunity == null) {
				Program.loadOpportunities(new Set<Id>{ order.OpportunityId });
				return Program.getOpportunity(order.OpportunityId);
			}
			return opportunity;
		}
	}

	class StandardPackageCreator extends OrderActions.OrderActionBase {
		StandardPackageCreator(Order order) {
			super(order);
			if (order.Pricebook2Id == null)
				throw new OrderActionsException('Order must have a pricebook before adding items');
		}

		public void execute() {
			Set<Id> missingOrderItemKeys = getMissingOrderItemKeys();
			if (missingOrderItemKeys.isEmpty())
				return;
			for (Id pricebookEntryId : missingOrderItemKeys) {
				OrderItem orderItem = createOrderItem(pricebookEntryId);
				forInsert(orderItem);
			}
		}

		Set<Id> getMissingOrderItemKeys() {
			Set<Id> orderItemKeySet = new Set<Id>();
			Order orderWithItems = Program.getOrderWithOrderItems(order.Id);
			if (orderWithItems != null) {
				List<OrderItem> orderItems = orderWithItems.OrderItems;
				for (OrderItem item : orderItems) {
					orderItemKeySet.add(item.PricebookEntryId);
				}
			}
			return getMissingOrderItemKeys(orderItemKeySet);
		}

		Set<Id> getMissingOrderItemKeys(Set<Id> orderItemKeySet) {
			Set<Id> standardItemKeySet = getStandardPricebookEntryIds();
			return getMissingOrderItemKeys(orderItemKeySet, standardItemKeySet);
		}

		Set<Id> getMissingOrderItemKeys(Set<Id> orderItemKeySet, Set<Id> standardItemKeySet) {
			Set<Id> missingKeys = new Set<Id>();
			if (standardItemKeySet.isEmpty())
				return missingKeys;
			missingKeys.addAll(standardItemKeySet);
			missingKeys.removeAll(orderItemKeySet);

			return missingKeys;
		}

		OrderItem createOrderItem(Id pricebookEntryId) {
			Decimal quantity = getQuantity(pricebookEntryId);
			return createOrderItem(pricebookEntryId, quantity);
		}

		OrderItem createOrderItem(Id pricebookEntryId, Decimal quantity) {
			Decimal unitPrice = getUnitPrice(pricebookEntryId);
			return createOrderItem(pricebookEntryId, quantity, unitPrice);
		}

		OrderItem createOrderItem(Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
			Id orderId = order.Id;
			return createOrderItem(orderId, pricebookEntryId, quantity, unitPrice);
		}

		OrderItem createOrderItem(Id orderId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
			return new SObjectBuilder.OrderItemBuilder(orderId, pricebookEntryId, quantity, unitPrice).create();
		}

		Decimal getUnitPrice(Id pricebookEntryId) {
			return Program.pricebookEntries.get(pricebookEntryId).UnitPrice;
		}

		//todo get quantities
		Decimal getQuantity(Id pricebookEntryId) {
			Decimal quantity = 1;
			try {
				String productName = Program.pricebookEntries.get(pricebookEntryId).Product2.Name;
			} catch (Exception e) {
			}

			return quantity;
		}

		Set<Id> getStandardPricebookEntryIds() {
			Id pricebookId = order.Pricebook2Id;
			Set<Id> standardPricebookEntries = new Set<Id>();
			for (Id pbeId : Program.pricebookEntries.keySet()) {
				PricebookEntry pbe = Program.pricebookEntries.get(pbeId);
				if (pbe.Maintain__c)
					standardPricebookEntries.add(pbeId);
			}
			return standardPricebookEntries;
		}

		void forInsert(OrderItem forInsert) {
			Controllers.ordersItemsToInsert.add(forInsert);
		}
	}

	class OpportunityLinker extends OrderActions.OrderActionBase {
		OpportunityLinker(Order order) {
			super(order);
		}

		public void execute() {
			Id accountId = order.AccountId;
			List<Opportunity> opportunities = [SELECT Id FROM Opportunity WHERE IsClosed = FALSE AND AccountId = :accountId ORDER BY LastModifiedDate DESC];
			if (opportunities.isEmpty())
				return;
			Opportunity opportunity = opportunities[0];
			Id opportunityId = opportunity.Id;
			order.OpportunityId = opportunityId;
		}
	}

	class AccountSyncer extends OrderActions.OrderActionBase {
		Map<SObjectField, SObjectField> fieldReference = new Map<SObjectField, SObjectField>{
			//Schema.Account.Previous_Payroll_Provider__c => Schema.Order.Previous_Payroll_Provider__c,
			Schema.Account.BillingStreet => Schema.Order.BillingStreet,
			Schema.Account.BillingPostalCode => Schema.Order.BillingPostalCode,
			Schema.Account.BillingCity => Schema.Order.BillingCity,
			Schema.Account.BillingState => Schema.Order.BillingState,
			Schema.Account.BillingStateCode => Schema.Order.BillingStateCode,
			Schema.Account.BillingCountry => Schema.Order.BillingCountry,
			Schema.Account.BillingCountryCode => Schema.Order.BillingCountryCode,
			Schema.Account.ShippingStreet => Schema.Order.ShippingStreet,
			Schema.Account.ShippingPostalCode => Schema.Order.ShippingPostalCode,
			Schema.Account.ShippingCity => Schema.Order.ShippingCity,
			Schema.Account.ShippingState => Schema.Order.ShippingState,
			Schema.Account.ShippingStateCode => Schema.Order.ShippingStateCode,
			Schema.Account.ShippingCountry => Schema.Order.ShippingCountry,
			Schema.Account.ShippingCountryCode => Schema.Order.ShippingCountryCode
		};

		AccountSyncer(Order order) {
			super(order);
		}

		public void execute() {
			SObject objectReference = getAccount();
			for (SObjectField referenceField : fieldReference.keySet()) {
				Object value = objectReference.get(referenceField);
				SObjectField orderField = fieldReference.get(referenceField);
				order.put(orderField, value);
			}
		}

		Account getAccount() {
			Account account = Program.getAccount(order.AccountId);
			if (account == null) {
				Program.loadAccounts(new Set<Id>{ order.AccountId });
				return Program.getAccount(order.AccountId);
			}
			return account;
		}
	}

	public static void assignPricebook(Order order) {
		new PricebookAssigner(order).execute();
	}

	public static void createStandardPackage(Order order) {
		new StandardPackageCreator(order).execute();
	}

	public static void linkToOpportunity(Order order) {
		new OpportunityLinker(order).execute();
	}

	public static void syncAccount(Order order) {
		new AccountSyncer(order).execute();
	}
}