/**
* @name         BTBenefitOrderAnalyticsBatchTest
* @author       Neha Dabas
* @date         03/03/2020
* @description  Test class for BTBenefitOrderAnalyticsBatch
* @revisions    Date ------------ Name ------------ Comments       
**/
@isTest
private class BTBenefitOrderAnalyticsBatchTest {
    @testsetup
    private static void setupTestData(){
    	Opportunity objOppty = TestUtility.BenefitsBoROpportunity();
    	
    	//Create Benefit Order Data
    	List<Benefit_Order__c> lst_BO = new List<Benefit_Order__c>();
    	
    	for(Integer counter = 0;counter<5;counter++){
    		Benefit_Order__c objBO = TestUtility.createTestBenefitOrder('Benefits BoR', objOppty.Id,'Test BO '+counter, false);
    		objBO.Order_Status__c = 'Ready for Qualification';
    		lst_BO.add(objBO);
    	}
    	
    	insert lst_BO;
    	
    	
    	for(Benefit_Order__c objBO : lst_BO){
    		objBO.Order_Status__c = 'Ready for Document Collection';
    	}
    	update lst_BO;
    	
    	for(Benefit_Order__c objBO : lst_BO){
    		objBO.Order_Status__c = 'Ready for Implementing Plans';
    	}
    	update lst_BO;
    }
    
    private static testmethod void testBenefitOrderAnalyticsBatch(){
    	test.startTest();
    		BTBenefitOrderAnalyticsBatch batchBO = new BTBenefitOrderAnalyticsBatch();
			database.executeBatch(batchBO);
    	test.stopTest();
    	system.assert([SELECT count() FROM Analytics_Time_Tracker__c WHERE RecordType.Name = 'Benefits Transfer'] > 0);
    }
}