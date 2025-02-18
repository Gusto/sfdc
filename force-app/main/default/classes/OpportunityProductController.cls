public class OpportunityProductController {
    

    // get opportunity data
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityData(Id opportunityId) {
        return [SELECT Id, Name, AccountId, Account.Name, Account.Tier__c, StageName, CloseDate,PriceBook2.Name,RecordType.Name,RecordTypeId FROM Opportunity WHERE Id = :opportunityId];
    }
	// Fetch Opportunity Products
	@AuraEnabled(cacheable=true)
	public static List<OpportunityLineItem> getOpportunityProducts(Id opportunityId) {
		List<OpportunityLineItem> list_OpportunityLineItems = new List<OpportunityLineItem>();
		for (OpportunityLineItem objOLI : [
			SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, Base_Price__c, Unit_Price__c, Product2Id, Opportunity.Name, Description, CreatedBy.Name, LastModifiedBy.Name,Opportunity.PriceBook2.Name
			FROM OpportunityLineItem
			WHERE OpportunityId = :opportunityId
		]) {
			list_OpportunityLineItems.add(objOLI);
		}
		return list_OpportunityLineItems;
	}

	// Search Products for adding to the Opportunity
	@AuraEnabled(cacheable=true)
	public static List<PriceBookEntryWrapper> searchPriceBookEntries(String strSearchTerm, Id opportunityId) {
		Set<String> set_Product2Ids = new Set<String>();
		String strPriceBookName = 'Payroll Product Catalog';
		for (OpportunityLineItem objOpportunityLineItem : getOpportunityProducts(opportunityId)) {
			set_Product2Ids.add(objOpportunityLineItem.Product2Id);
			strPriceBookName = objOpportunityLineItem.Opportunity.PriceBook2.Name;
		}

		System.debug('strPriceBookName: ' + strPriceBookName);
		if (strPriceBookName == null) {
			strPriceBookName = 'Payroll Product Catalog';
		}
		
		List<PriceBookEntry> list_PriceBookEntries = new List<PriceBookEntry>();
		List<PriceBookEntryWrapper> list_PriceBookEntryWrapper = new List<PriceBookEntryWrapper>();
		for (PriceBookEntry objPBE : [
			SELECT
				Id,
				UnitPrice,
				Product2Id,
				Product2.Name,
				Product2.Product_Type__c,
				toLabel(Product2.Product_Category__c),
				Product2.Discounts_Available__c,
				Base_Price__c,
				PriceBook2Id,
				PriceBook2.Name
			FROM PriceBookEntry
			WHERE PriceBook2.Name =: strPriceBookName AND PriceBook2.IsActive = TRUE AND Product2.Name LIKE :('%' + strSearchTerm + '%')
		]) {
			if (!set_Product2Ids.contains(objPBE.Product2Id)) {
				list_PriceBookEntries.add(objPBE);
				list_PriceBookEntryWrapper.add(
					new PriceBookEntryWrapper(
						objPBE.Id,
						objPBE.UnitPrice,
						objPBE.Product2Id,
						objPBE.Product2.Name,
						objPBE.Product2.Product_Type__c,
						objPBE.Product2.Product_Category__c,
						objPBE.Product2.Discounts_Available__c,
						objPBE.Base_Price__c,
						objPBE.PriceBook2Id,
						objPBE.PriceBook2.Name,
						1
					)
				);
			}
		}
		return list_PriceBookEntryWrapper;
	}

	// Search Products for adding to the Opportunity
	@AuraEnabled(cacheable=true)
	public static List<PriceBookEntryWrapper> loadPriceBookEntries(Id opportunityId) {
		Set<String> set_Product2Ids = new Set<String>();
		String strPriceBookName = 'Payroll Product Catalog';
		for (OpportunityLineItem objOpportunityLineItem : getOpportunityProducts(opportunityId)) {
			set_Product2Ids.add(objOpportunityLineItem.Product2Id);
			strPriceBookName = objOpportunityLineItem.Opportunity.PriceBook2.Name;
		}

		List<PriceBookEntry> list_PriceBookEntries = new List<PriceBookEntry>();
		List<PriceBookEntryWrapper> list_PriceBookEntryWrapper = new List<PriceBookEntryWrapper>();
		for (PriceBookEntry objPBE : [
			SELECT
				Id,
				UnitPrice,
				Product2Id,
				Product2.Name,
				Product2.Product_Type__c,
				toLabel(Product2.Product_Category__c),
				Product2.Discounts_Available__c,
				Base_Price__c,
				PriceBook2Id,
				PriceBook2.Name
			FROM PriceBookEntry
			WHERE PriceBook2.Name =: strPriceBookName AND PriceBook2.IsActive = TRUE
		]) {
			if (!set_Product2Ids.contains(objPBE.Product2Id)) {
				list_PriceBookEntries.add(objPBE);
				list_PriceBookEntryWrapper.add(
					new PriceBookEntryWrapper(
						objPBE.Id,
						objPBE.UnitPrice,
						objPBE.Product2Id,
						objPBE.Product2.Name,
						objPBE.Product2.Product_Type__c,
						objPBE.Product2.Product_Category__c,
						objPBE.Product2.Discounts_Available__c,
						objPBE.Base_Price__c,
						objPBE.PriceBook2Id,
						objPBE.PriceBook2.Name,
						1
					)
				);
			}
		}
		return list_PriceBookEntryWrapper;
	}

	// Add Products to Opportunity
	@AuraEnabled
	public static void addOpportunityProducts(String strOpportunityId, List<PriceBookEntryWrapper> list_SelectedPriceBookEntries, Map<String, String> map_DraftValues) {
		List<OpportunityLineItem> list_OLIToInsert = new List<OpportunityLineItem>();
		System.debug('opportunityId: ' + strOpportunityId);
		System.debug('map_DraftValues: ' + map_DraftValues);
		System.debug('list_SelectedPriceBookEntries: ' + list_SelectedPriceBookEntries);
		if (!list_SelectedPriceBookEntries.isEmpty()) {
			for (PriceBookEntryWrapper priceBookEntry : list_SelectedPriceBookEntries) {
				//System.debug();
				System.debug('map_DraftValues.get(priceBookEntry.pbeId):' + map_DraftValues.get(priceBookEntry.pbeId));

				OpportunityLineItem objOpportunityLineItem = new OpportunityLineItem();
				objOpportunityLineItem.OpportunityId = strOpportunityId;
				objOpportunityLineItem.Product2Id = priceBookEntry.product2Id;
				objOpportunityLineItem.PricebookEntryId = priceBookEntry.pbeId;
				
				if (priceBookEntry.unitPrice != null) {
					objOpportunityLineItem.Unit_Price__c = priceBookEntry.unitPrice;
				} else {
					objOpportunityLineItem.Unit_Price__c = 0;

				}

				System.debug('priceBookEntry.basePrice: ' + priceBookEntry.basePrice);
				if (priceBookEntry.basePrice != null) {
					objOpportunityLineItem.Base_Price__c = priceBookEntry.basePrice;
				} else {
					objOpportunityLineItem.Base_Price__c = 0;
				}

				objOpportunityLineItem.Quantity = map_DraftValues.get(priceBookEntry.pbeId) != null ? Integer.valueOf(map_DraftValues.get(priceBookEntry.pbeId)) : 1;
				objOpportunityLineItem.TotalPrice = objOpportunityLineItem.Unit_Price__c * objOpportunityLineItem.Quantity + objOpportunityLineItem.Base_Price__c;
				list_OLIToInsert.add(objOpportunityLineItem);
			}
			System.debug('list_OLIToInsert: ' + list_OLIToInsert);

			try {
				insert list_OLIToInsert;
			} catch (Exception e) {
				if (e.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY')) {
					throw new AuraHandledException('You do not have permission to add products to this opportunity.');
				} else {
					throw new AuraHandledException(e.getMessage());
				}
			}
		}
	}

	// Update Opportunity Products
	@AuraEnabled
	public static void updateOpportunityProducts(List<OpportunityLineItem> list_OpportunityLineItemsToUpdate) {
		List<OpportunityLineItem> list_OpportunityLineItems = new List<OpportunityLineItem>();
		// SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice,Base_Price__c,Unit_Price__c
		Map<Id, OpportunityLineItem> map_OLI = new Map<Id, OpportunityLineItem>();
		Set<Id> set_OLIId = new Set<Id>();
		for (OpportunityLineItem oli : list_OpportunityLineItemsToUpdate) {
			set_OLIId.add(oli.Id);
		}

		for (OpportunityLineItem objOLI : [SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, Base_Price__c, Unit_Price__c FROM OpportunityLineItem WHERE Id IN :set_OLIId]) {
			map_OLI.put(objOLI.Id, objOLI);
		}

		for (OpportunityLineItem oli : list_OpportunityLineItemsToUpdate) {
			OpportunityLineItem objOLI = map_OLI.get(oli.Id);
			if (objOLI != null) {
				objOLI.Quantity = oli.Quantity;

				if (objOLI.Unit_Price__c == null) {
					objOLI.Unit_Price__c = 0;
				}

				if (objOLI.Base_Price__c == null) {
					objOLI.Base_Price__c = 0;
				}

				if (objOLI.Quantity == null) {
					objOLI.Quantity = 1;
				}

				objOLI.TotalPrice = objOLI.Unit_Price__c * objOLI.Quantity + objOLI.Base_Price__c;
				list_OpportunityLineItems.add(objOLI);
			}
		}

		System.debug('list_OpportunityLineItems: ' + list_OpportunityLineItems);
		if (list_OpportunityLineItems == null || list_OpportunityLineItems.isEmpty()) {
			throw new AuraHandledException('No updates provided.');
		}

		try {
			update list_OpportunityLineItems;
		} catch (Exception e) {
			if (e.getMessage().contains('INSUFFICIENT_ACCESS_OR_READONLY')) {
				throw new AuraHandledException('You do not have permission to update products on this opportunity.');
			} else {
				throw new AuraHandledException(e.getMessage());
			}
		}
	}

	@AuraEnabled
	public static String validateSelectedProducts(Id opportunityId, List<Id> selectedProductIds) {
		System.debug('opportunityId: ' + opportunityId);
		System.debug('selectedProductIds: ' + selectedProductIds);
		Opportunity opp = [SELECT Account.Tier__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
		List<OpportunityLineItem> currentProducts = [SELECT Product2.Name FROM OpportunityLineItem WHERE OpportunityId = :opportunityId];

		System.debug('currentProducts: ' + currentProducts);

		List<String> currentProductNames = new List<String>();
		for (OpportunityLineItem oli : currentProducts) {
			currentProductNames.add(oli.Product2.Name);
		}

		System.debug('currentProductNames: ' + currentProductNames);
		List<Product2> selectedProducts = [SELECT Name FROM Product2 WHERE Id IN :selectedProductIds];
		List<String> selectedProductNames = new List<String>();
		for (Product2 product : selectedProducts) {
			selectedProductNames.add(product.Name);
		}

		System.debug('selectedProductNames: ' + selectedProductNames);
		List<Product_Configuration__mdt> productConfigurations = [SELECT MasterLabel, Excluded_Account_Tier__c, Excluded_Opportunity_Product__c FROM Product_Configuration__mdt];

		for (Product_Configuration__mdt config : productConfigurations) {
			String excludedTiers = config.Excluded_Account_Tier__c;
			String excludedProducts = config.Excluded_Opportunity_Product__c;
			for (String productName : selectedProductNames) {
				System.debug('excludedTiers: ' + excludedTiers);
				System.debug('excludedProducts: ' + excludedProducts);
				System.debug('config.MasterLabel: ' + config.MasterLabel);
				if (config.MasterLabel == productName) {
					// Validate Account Tier
					if (!String.isEmpty(excludedTiers) && opp.Account.Tier__c != null && excludedTiers.contains(opp.Account.Tier__c)) {
						return 'Error: The "' + productName + '" product cannot be added as it conflicts with "' + opp.Account.Tier__c + '" is excluded.';
					}

					// Validate other products
					List<String> excludedProductList = new List<String>();
					if (!String.isEmpty(excludedProducts)) {
						for (String excludedProduct : excludedProducts.split(',')) {
							excludedProductList.add(excludedProduct.trim());
						}
					}

					System.debug('excludedProductList: ' + excludedProductList);
					System.debug('currentProductNames1: ' + currentProductNames);
					System.debug('selectedProductNames: ' + selectedProductNames);

					for (String excludedProduct : excludedProductList) {
						if (currentProductNames.contains(excludedProduct) || selectedProductNames.contains(excludedProduct)) {
							return 'Error: The "' + productName + '" product cannot be added as it conflicts with "' + excludedProduct + '" is excluded.';
						}
					}
				}
			}
		}

		return null; // Validation passed
	}

	@AuraEnabled
	public static String deleteOpportunityLineItem(Id recordId) {
		OpportunityLineItem oli = [SELECT Id, Opportunity.Account.Tier__c, Product2.Name FROM OpportunityLineItem WHERE Id = :recordId];
		if (String.isNotBlank(oli.Opportunity.Account.Tier__c) && oli.Opportunity.Account.Tier__c.equalsIgnoreCase(oli.Product2.Name)) {
			return ' Cannot delete a plan:' + oli.Product2.Name + ' Plan on an Acquisition Opportunity cannot be deleted.';
		}
		delete oli;
		return null;
	}

	public class PriceBookEntryWrapper {
		@AuraEnabled
		public String pbeId { get; set; }

		@AuraEnabled
		public Decimal unitPrice { get; set; }

		@AuraEnabled
		public String product2Id { get; set; }

		@AuraEnabled
		public String productName { get; set; }

		@AuraEnabled
		public String productType { get; set; }

		@AuraEnabled
		public String productCategory { get; set; }

		@AuraEnabled
		public String discountsAvailable { get; set; }

		@AuraEnabled
		public Decimal basePrice { get; set; }

		@AuraEnabled
		public String priceBookId { get; set; }

		@AuraEnabled
		public Integer quantity { get; set; }

		@AuraEnabled
		public String priceBookName;
		public PriceBookEntryWrapper() {
		}
		public PriceBookEntryWrapper(
			String pbeId,
			Decimal unitPrice,
			String product2Id,
			String productName,
			String productType,
			String productCategory,
			String discountsAvailable,
			Decimal basePrice,
			String priceBookId,
			String priceBookName,
			Integer quantity
		) {
			this.pbeId = pbeId;
			this.unitPrice = unitPrice;
			this.product2Id = product2Id;
			this.productName = productName;
			this.productType = productType;
			this.productCategory = productCategory;
			this.discountsAvailable = discountsAvailable;
			this.basePrice = basePrice;
			this.priceBookId = priceBookId;
			this.priceBookName = priceBookName;
			this.quantity = quantity;
		}
	}
}