/**
 * @name         : HICompanyActiveBenefitsBatchTest
 * @date         : 09-27-2023
 * @description  : Handle test cases to update the HI Is Active Benefits field of each HI Company Active Benefits record to False
 **/
@isTest
public class HICompanyActiveBenefitsBatchTest {
    /**
      * @description Setup Test Data
   	**/
	@testSetup
    static void setupData(){
        HI_Company_Active_Benefits__c objHICompanyActiveBenefits = new TestDataFactory.HICompanyActiveBenefitsBuilder()
			.setHIIsActiveBenefits('True')
			.setCreatedDate(Date.today().addDays(-4))
            .setLastModifiedDate(Date.today().addDays(-4))
			.build();
        
        insert objHICompanyActiveBenefits;
    }
    
    /**
    	* @description Update the HI Is Active Benefits field of each HI Company Active Benefits record to False positive case
    **/
    @isTest
    static void testHICompanyActiveBenefitsBatchToFalsePositive(){
        Test.startTest();
        Database.executeBatch(new HICompanyActiveBenefitsBatch());
        Test.stopTest();
        
        for(HI_Company_Active_Benefits__c objHICompanyActiveBenefits : [
            SELECT Id, HI_Is_Active_Benefits__c 
            FROM HI_Company_Active_Benefits__c
        ]){
            System.assertEquals('False', objHICompanyActiveBenefits.HI_Is_Active_Benefits__c, 'HI Is Active Benefits should be False'); 
        }
    }
    
    /**
    	* @description Update the HI Is Active Benefits field of each HI Company Active Benefits record to False negative case
    **/
    @isTest
    static void testHICompanyActiveBenefitsBatchToFalseNegative(){
        HICompanyActiveBenefitsTriggerHelper.blnTestException = true;
        
        Test.startTest();
        Database.executeBatch(new HICompanyActiveBenefitsBatch());
        Test.stopTest();
        
        System.assertEquals([SELECT Id FROM Exception_Log__c].size(), 1, 'There should be a exceptionlog record');
    }
}