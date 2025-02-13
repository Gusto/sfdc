/*
 * To cover unit test scenarios of BTCarrierOrderAnalyticsBatch
 */

@isTest
private class BTCarrierOrderAnalyticsBatchTest {
    @testsetup
    private static void setupTestData(){
    	Opportunity objOppty = TestUtility.BenefitsBoROpportunity();
    	
    	//Create Benefit Order Data
    	Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id,'Test BO ', true);
    	//Carrier
		Carrier__c objCarrier = new Carrier__c();
        objCarrier.Name ='TestCarrier';
        objCarrier.State__c='AL;AK';
        
        insert objCarrier;
    	
		CArrier_Order__c objCO = TestUtility.createTestCArrierOrder(objCarrier.Id, 'Test Carrier Order ',objBO.Id, false);
		objCO.Implementation_Stage__c = 'Ready for Qualification';
    	objCO.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c','Benefits BoR');
        objCO.Benefit_Types__c ='testBenefit type';
    	insert objCO;
    	
    	
    	objCO.Implementation_Stage__c = 'Ready for Document Collection';
    	update objCO;
    	
    	objCO.Implementation_Stage__c = 'Ready for Implementing Plans';
    	update objCO;
    }
    
    private static testmethod void testBenefitOrderAnalyticsBatch(){
    	test.startTest();
    		BTCarrierOrderAnalyticsBatch batchCO = new BTCarrierOrderAnalyticsBatch();
			database.executeBatch(batchCO);
    	test.stopTest();
    	system.assert([SELECT count() FROM Analytics_Time_Tracker__c WHERE RecordType.Name = 'Benefits Transfer'] > 0);
    }
}