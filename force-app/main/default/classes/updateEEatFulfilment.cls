/**
 * @name         UpdateEEatFulfilment
 * @author       Praveen Sethu
 * @date         02-18-2021
 * @description  Updates Opportunity Number of Employees and Line Items after Benefit Order is Fulfilled
 * @test classes updateEEatFulfilmentBatchTest
 **/
public with sharing class updateEEatFulfilment implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext bc) {
		Datetime dtYesterday = System.now() - 1;
		// Query Benefit Orders that were fulfilled in the past one day
		String strQuery = 'SELECT Id, Opportunity__c, EE_at_Fulfillment__c, Opportunity__r.NumberOfEmployees__c, Opportunity__r.PriceBook2Id FROM Benefit_Order__c WHERE Order_Status__c =\'Fulfilled\' AND Order_Fulfilled_Timestamp__c > :dtYesterday';
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<Benefit_Order__c> list_Orders) {
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		List<OpportunityLineItem> list_LineItemsToUpdate = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_LineItemsToDelete = new List<OpportunityLineItem>();
		Map<Id, Map<String, PriceBookEntry>> map_PBIdToMapOfProdNameToPBE = new Map<Id, Map<String, PriceBookEntry>>();

		try {
			// Iterate over list of orders and check if 'EE at Fulfillment' on Benefit Order does not match with 'Number of Employees' on Opportunity
			for (Benefit_Order__c objOrder : list_Orders) {
				if (
					objOrder.EE_at_Fulfillment__c != null &&
					objOrder.Opportunity__c != null &&
					objOrder.EE_at_Fulfillment__c != objOrder.Opportunity__r.NumberOfEmployees__c
				) {
					Id idOpptyPriceBook = objOrder.Opportunity__r.PriceBook2Id;
					map_OpptysToUpdate.put(
						objOrder.Opportunity__c,
						new Opportunity(Id = objOrder.Opportunity__c, NumberOfEmployees__c = objOrder.EE_at_Fulfillment__c)
					);
					// Create a map of Price Book Id and (Map of Product Name and Prices)
					if (idOpptyPriceBook != null && !map_PBIdToMapOfProdNameToPBE.containsKey(idOpptyPriceBook)) {
						PriceBook2 objPB = OpportunityUtil.getPriceBookById(idOpptyPriceBook);

						if (objPB != null) {
							Map<String, PriceBookEntry> map_TempPriceBookEntry = new Map<String, PriceBookEntry>();
							for (PriceBookEntry objPBE : objPB.PriceBookEntries) {
								map_TempPriceBookEntry.put(objPBE.Product2.Name, objPBE);
							}

							map_PBIdToMapOfProdNameToPBE.put(objPB.Id, map_TempPriceBookEntry);
						}
					}
				}
			}

			// Update Opportunities where 'Number of Employees' does not match with 'EE at Fulfillment' from Benefit Order
			// Update Opportunity Line Item with respective Quantity and Price
			if (!map_OpptysToUpdate.isEmpty()) {
				update map_OpptysToUpdate.values();

				List<OpportunityLineItem> list_OpptyLineItems = [
					SELECT Id, OpportunityId, Opportunity.PriceBook2Id, Product2.Name, Quantity
					FROM OpportunityLineItem
					WHERE OpportunityId IN :map_OpptysToUpdate.values()
				];

				// Iterate over all opportunity line items whose opportunity was just updated.
				// Update Line Item's Quantity and Price when Quantity does not match Opportunity's Number of Employees
				for (OpportunityLineItem objLineItem : list_OpptyLineItems) {
					Id idOpptyPriceBook = objLineItem.Opportunity.PriceBook2Id;
					if (
						map_OpptysToUpdate.containsKey(objLineItem.OpportunityId) &&
						map_PBIdToMapOfProdNameToPBE.containsKey(idOpptyPriceBook)
					) {
						String strProduct = objLineItem.Product2.Name;
						Opportunity objOppty = map_OpptysToUpdate.get(objLineItem.OpportunityId);
                        if (objOppty.NumberOfEmployees__c == 0) {
                            list_LineItemsToDelete.add(objLineItem);
                        } else if (objLineItem.Quantity != objOppty.NumberOfEmployees__c) {
							if (map_PBIdToMapOfProdNameToPBE.get(idOpptyPriceBook).containsKey(strProduct)) {
								PriceBookEntry objPBE = map_PBIdToMapOfProdNameToPBE.get(idOpptyPriceBook).get(strProduct);

								objLineItem.Quantity = objOppty.NumberOfEmployees__c;
								objLineItem.UnitPrice = objPBE.UnitPrice;
								list_LineItemsToUpdate.add(objLineItem);
							}
						}
					}
				}

				if (!list_LineItemsToUpdate.isEmpty()) {
					OpportunityTriggerHelper.skipTrigger = true;
					update list_LineItemsToUpdate;
				}

				// BTC-1352 - Delete OLI when EE is 0
                if (!list_LineItemsToDelete.isEmpty()) {
					OpportunityTriggerHelper.skipTrigger = true;
					delete list_LineItemsToDelete;
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('UpdateEEAtFulfillment','execute','Exception On Line ' +objException.getLineNumber() +'-' +objException.getMessage(),objException.getStackTraceString()
			);
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [ SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'UpdateEEatFulfilment', false);
	}
}