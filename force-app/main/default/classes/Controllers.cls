/**
 * Created by brent.johnson on 11/27/16.
 */

public without sharing class Controllers {
	public static List<Order> ordersToInsert = new List<Order>();
	public static List<OrderItem> ordersItemsToInsert = new List<OrderItem>();

	public without sharing class Orders {
		List<Order> orders;

		public Orders(List<Order> orders) {
			this.orders = orders;
		}

		public void assignPricebook() {
			loadAccounts();
			loadOpportunities();
			for (Order order : orders) {
				if (order.Pricebook2Id == null)
					OrderActions.assignPricebook(order);
			}
		}

		public void linkToOpportunity() {
			loadOpportunities();
			for (Order order : orders) {
				if (order.OpportunityId == null)
					OrderActions.linkToOpportunity(order);
			}
		}

		public void syncAccount() {
			loadAccounts();
			for (Order order : orders) {
				if (order.AccountId != null)
					OrderActions.syncAccount(order);
			}
		}

		public void createStandardPackage() {
			loadOrderItems();
			for (Order order : orders) {
				if (order.Pricebook2Id != null)
					OrderActions.createStandardPackage(order);
			}
			finalize();
		}

		void loadAccounts() {
			Set<Id> accountIds = new Set<Id>();
			for (Order order : orders) {
				accountIds.add(order.AccountId);
			}
			if (accountIds.isEmpty())
				return;
			Program.loadAccounts(accountIds);
		}

		void loadOpportunities() {
			Set<Id> opportunityIds = new Set<Id>();
			for (Order order : orders) {
				opportunityIds.add(order.OpportunityId);
			}
			if (opportunityIds.isEmpty())
				return;
			Program.loadOpportunities(opportunityIds);
		}

		void loadOrderItems() {
			Set<Id> orderIds = new Set<Id>();
			for (Order order : orders) {
				orderIds.add(order.Id);
			}
			if (orderIds.isEmpty())
				return;
			Program.loadOrdersWithOrderItems(orderIds);
		}

		void finalize() {
			if (!ordersItemsToInsert.isEmpty()) {
				Utils.insertAndLog(ordersItemsToInsert, false);
				ordersItemsToInsert.clear();
			}
		}
	}
}