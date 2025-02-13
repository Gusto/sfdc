/**
 * Created by brent.johnson on 11/24/16.
 */

public without sharing class SObjectBuilder {
	abstract class BaseBuilder {
		Map<SObjectField, Object> fieldValueMap = new Map<SObjectField, Object>();

		abstract SObjectType getSObjectType();

		protected BaseBuilder setFieldValue(SObjectField field, Object value) {
			fieldValueMap.put(field, value);
			return this;
		}

		protected SObject newSObject() {
			return getSObjectType().newSObject(null, true);
		}

		protected SObject build() {
			SObject sobj = getSObjectType().newSObject(null, true);
			for (SObjectField field : fieldValueMap.keySet()) {
				Object value = fieldValueMap.get(field);
				sobj.put(field, value);
			}
			return sobj;
		}

		protected List<SObject> buildList(Integer numToBuild) {
			List<SObject> sobjList = new List<SObject>();
			SObject sObj = build();
			for (Integer i = 0; i < numToBuild; i++) {
				sobjList.add(sObj.clone());
			}
			return sobjList;
		}
	}

	public class OrderBuilder extends SObjectBuilder.BaseBuilder {
		public OrderBuilder(Id accountId) {
			setStatus('Drafted');
			setEffectiveDate(System.today());
			setAccountId(accountId);
		}

		public Order create() {
			return (Order) super.build();
		}

		public OrderBuilder setAccountId(Id accountId) {
			return (OrderBuilder) super.setFieldValue(Order.AccountId, accountId);
		}

		public OrderBuilder setStatus(String status) {
			return (OrderBuilder) super.setFieldValue(Order.Status, status);
		}

		public OrderBuilder setEffectiveDate(Date effectiveDate) {
			return (OrderBuilder) super.setFieldValue(Order.EffectiveDate, effectiveDate);
		}

		public OrderBuilder setOwnerId(Id ownerId) {
			return (OrderBuilder) super.setFieldValue(Order.OwnerId, ownerId);
		}

		override SObjectType getSObjectType() {
			return Order.SObjectType;
		}
	}

	public class OrderItemBuilder extends SObjectBuilder.BaseBuilder {
		public OrderItemBuilder(Id orderId, Id pricebookEntryId, Decimal quantity, Decimal unitPrice) {
			setOrderId(orderId);
			setPricebookEntryId(pricebookEntryId);
			setQuantity(quantity);
			setUnitPrice(unitPrice);
		}

		public OrderItem create() {
			return (OrderItem) super.build();
		}

		public OrderItemBuilder setOrderId(Id orderId) {
			return (OrderItemBuilder) super.setFieldValue(OrderItem.OrderId, orderId);
		}

		public OrderItemBuilder setPricebookEntryId(Id pricebookEntryId) {
			return (OrderItemBuilder) super.setFieldValue(OrderItem.PricebookEntryId, pricebookEntryId);
		}

		public OrderItemBuilder setQuantity(Decimal quantity) {
			return (OrderItemBuilder) super.setFieldValue(OrderItem.Quantity, quantity);
		}

		public OrderItemBuilder setUnitPrice(Decimal unitPrice) {
			return (OrderItemBuilder) super.setFieldValue(OrderItem.UnitPrice, unitPrice);
		}

		override SObjectType getSObjectType() {
			return OrderItem.SObjectType;
		}
	}
}