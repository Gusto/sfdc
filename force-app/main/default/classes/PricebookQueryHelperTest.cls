/* 
@Author:        Yuvraj Brock
@Created Date:  05/22/2020
@Description:   to cover PricebookQueryHelper
*/ 
@isTest
private class PricebookQueryHelperTest {
 static testMethod void testPricebookQueryMethods() {
     PricebookQueryHelper.getActivePricebooksMap();
     PricebookQueryHelper.queryActivePricebooksMap();
     Set<String> set_productNames= new Set<String>();
     set_productNames.add('test product name');
     PricebookQueryHelper.getPricebookEntryRecords(set_productNames);
 }
}