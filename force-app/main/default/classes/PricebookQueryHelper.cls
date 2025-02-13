/* 
@Author:        Sean DesMarteau
@Created Date:  05/19/2020
@Description:   Data layer for the Pricebook2 and PriceBookEntry objects - The following pattern should be followed when adding queries,
                Query once and return map/list/set. If we need to query again we should be returning the map/list/set and not running another query.
*/
public without sharing class PricebookQueryHelper {
	// Static Variable Declarations
	public static Set<String> payrollProductNameSet = new Set<String>{ 'Company', 'Active Employee', 'Contractor' };

	// Static Map/List/Set Declarations
	public static Map<String, PriceBook2> map_ActivePricebooks;
	public static Map<Id, PriceBook2> map_ActivePricebooksById;
	public static Map<String, PriceBookEntry> map_PricebookIdPlusProductToPricebookEntry;

	/* 
    @Author:        Sean DesMarteau
    @Created Date:  05/19/2020
    @Asana:         https://app.asana.com/0/1145194070800865/1173475444858537
    @Description:   Queries all Active Pricebooks
    @Return:        Map of Pricebook.Name to Pricebook Record
    */
	public static Map<String, PriceBook2> getActivePricebooksMap() {
		if (map_ActivePricebooks == null || map_ActivePricebooks.isEmpty()) {
			map_ActivePricebooks = queryActivePricebooksMap();
		}

		return map_ActivePricebooks;
	}

	public static Map<String, PriceBook2> queryActivePricebooksMap() {
		Map<String, PriceBook2> map_ActivePricebooksTemp = new Map<String, PriceBook2>();

		for (PriceBook2 objPricebook : [SELECT Id, Name, IsActive, Product_Tier__c, (SELECT Id, Product2Id FROM PriceBookEntries) FROM PriceBook2 WHERE IsActive = TRUE]) {
			map_ActivePricebooksTemp.put(objPricebook.Name, objPricebook);
		}

		return map_ActivePricebooksTemp;
	}

	/* 
    @Author:        Sean DesMarteau
    @Created Date:  05/19/2020
    @Asana:         https://app.asana.com/0/1145194070800865/1173475444858537
    @Description:   Queries pricebook entry records for a given set of product names.
    @Parm:          set_ProductNames - Set of Product Names that should be queried for.
    @Return:        Map of Pricebook.Name and Product Name to the respective Pricebook Entry Record
    */
	public static Map<String, PriceBookEntry> getPricebookEntryRecords(Set<String> set_ProductNames) {
		if (map_PricebookIdPlusProductToPricebookEntry == null || map_PricebookIdPlusProductToPricebookEntry.keySet().size() == 0) {
			map_PricebookIdPlusProductToPricebookEntry = queryPricebookEntryRecords(set_ProductNames);
		}

		return map_PricebookIdPlusProductToPricebookEntry;
	}

	public static Map<String, PriceBookEntry> queryPricebookEntryRecords(Set<String> set_ProductNames) {
		Map<String, PricebookEntry> map_PricebookIdPlusProductToPricebookEntryTemp = new Map<String, PricebookEntry>();

		for (PricebookEntry objPricebookEntry : [SELECT Id, UnitPrice, Product2.Name, PriceBook2Id FROM PriceBookEntry WHERE Product2.Name IN :set_ProductNames]) {
			map_PricebookIdPlusProductToPricebookEntryTemp.put(objPricebookEntry.PriceBook2Id + '-' + objPricebookEntry.Product2.Name, objPricebookEntry);
		}

		return map_PricebookIdPlusProductToPricebookEntryTemp;
	}
}