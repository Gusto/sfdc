/**
 * @name         HIHSABenefitTriggerHelperTest
 * @author       Bhagat Singh
 * @date         30 May 2023
 * @description  Test class for HIHSABenefitTriggerHelper class.
 **/
@istest
private class HIHSABenefitTriggerHelperTest {
    /**
     * @Author      : Bhagat Singh
     * @Description : Test Class setup method
     **/
    @testSetup
    static void setupData() {
        Utils.skipTrigger(true);
        Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('7757616923607181').setName('Gusto HINewPlanApplication').build();
        
        Pricebook2 objPriceBook = new TestDataFactory.PriceBookBuilder().setName('Benefits 2017').setActive().build();
        insert objPriceBook;
        
        Product2 objProduct = new TestDataFactory.ProductBuilder().setName('HSA').setFamily('HSA').build();
        insert objProduct;
        
        List<PricebookEntry> list_PriceBookEntry = new List<PricebookEntry>();
        list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());
        list_PriceBookEntry.add(new TestDataFactory.PricebookEntryBuilder().setProductId(objProduct.Id).setUnitPrice(5).setPriceBookId(objPriceBook.Id).setIsActive(true).build());
        insert list_PriceBookEntry;
        
        State__c objState = new TestDataFactory.StateBuilder().setName('California').setId('12').setAbbreviation('CA').build();
        insert objState;
        
        List<Carrier__c> list_Carriers = New List<Carrier__c>();
        Carrier__c objCarrier1 = new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setId('Alegeus001').setState('AK').setKey('Alegeus').build();
        list_Carriers.add(objCarrier1);
        
        Carrier__c objCarrier2 = new TestDataFactory.CarrierBuilder().setName('elevate').setUniqueName('elevate').setId('elevate001').setState('AK').setKey('elevate').build();
        list_Carriers.add(objCarrier2);
        
        insert list_Carriers;
        
        List<Opportunity> list_Opportunity = new List<Opportunity>();
        list_Opportunity.add(
            new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
            .setName('Benefits New Plan')
            .setAccountId(objAccount.Id)
            .setNumberOfEE(5)
            .setBenefitsState('CA')
            .setStage('SAL')
            .setCloseDate(System.today().addDays(30))
            .setSourceID('hawaiian_ice-new_plans_application-321')
            .setPriceBookId(objPriceBook.Id)
            .build()
            );
        list_Opportunity.add(
            new TestDataFactory.OpportunityBuilder()
            .setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
            .setName('Benefits New Plan')
            .setAccountId(objAccount.Id)
            .setNumberOfEE(5)
            .setBenefitsState('CA')
            .setStage('SAL')
            .setCloseDate(System.today().addDays(30))
            .setSourceID('hawaiian_ice-renewal-322')
            .setPriceBookId(objPriceBook.Id)
            .build()
            );
        insert list_Opportunity;
        
        Utils.skipTrigger(false);
    }
    
    /**
     * @Author      : Bhagat Singh
     * @Description : Validate Source Type & Source Id
     **/
    @isTest
    static void validateRequiredFields() {
        Test.startTest();
        HIHSABenefitTriggerHelper.queue = true;
        HI_HSA_Benefit__c objHSA = new TestDataFactory.HIHSABenefitBuilder()
            .setId('101')
            .setCompanyId('7757616923607181')
            .setExternalKey('hawaiian_ice-hsa-101')
            .setCreatedAt(System.Now())
            .setSourceId('321')
            .build();
        insert objHSA;
        
        Test.stopTest();
        
        objHSA = [SELECT Id, Message__c, Processing_State__c FROM HI_HSA_Benefit__c WHERE Id = :objHSA.Id];
        System.assertEquals(IntegrationUtils.ERROR_STATE, objHSA.Processing_State__c, 'Invalid Source Id');
        System.assert(objHSA.Message__c.contains(HIHSABenefitTriggerHelper.strRequiredSourceId), 'Invalid Source Id');
    }
    
    /**
     * @Author      : Bhagat Singh
     * @Description : Create Alegeus Policy with respect to NewPlanApplication Opportunity
     **/
    @isTest
    static void HINewPlanApplicationHSA() {
        Test.startTest();
        HIHSABenefitTriggerHelper.queue = true;
        HIHSABenefitTriggerHelper.skipTrigger = true;
        HI_HSA_Benefit__c objHSA = new TestDataFactory.HIHSABenefitBuilder()
            .setId('101')
            .setCompanyId('7757616923607181')
            .setExternalKey('hawaiian_ice-hsa-101')
            .setCreatedAt(System.Now())
            .setSourceId('321')
            .setSourceType('NewPlansApplication')
            .build();
        insert objHSA;
        objHSA.Provider_Key__c = 'Alegeus';
        HIHSABenefitTriggerHelper.skipTrigger = false;
        update objHSA;
        
        Test.stopTest();
        //Added for BBO-1967
        Carrier__c AlegeusCarrier = [select Id from Carrier__c where Key__c = 'Alegeus'];
        Policy__c objPolicy = [SELECT Id, Carrier__c, Benefit_Type__c FROM Policy__c WHERE Opportunity__r.Source_Id__c = 'hawaiian_ice-new_plans_application-321'];
        System.assertEquals('HSA', objPolicy.Benefit_Type__c, 'No Policy exist with respect to HSA Benefit Type');
        //Modified for BBO-1967
        System.assertEquals(AlegeusCarrier.Id, objPolicy.Carrier__c, 'No Policy exist with respect to Alegeus carrier');
    }
    
    /**
     * @Author      : Bhagat Singh
     * @Description : Create Alegeus Policy with respect to Renewal Opportunity
     **/
    @isTest
    static void HIRenewalApplicationHSA() {
        Test.startTest();
        HIHSABenefitTriggerHelper.queue = true;
        HI_HSA_Benefit__c objHSA = new TestDataFactory.HIHSABenefitBuilder()
            .setId('101')
            .setCompanyId('7757616923607181')
            .setExternalKey('hawaiian_ice-hsa-101')
            .setCreatedAt(System.Now())
            .setSourceId('322')
            .setSourceType('Renewal')
            .build();
        objHSA.Provider_Key__c = 'elevate';
        insert objHSA;
        
        Test.stopTest();
        //Added for BBO-1967
        Carrier__c elevateCarrier = [select Id from Carrier__c where Key__c = 'elevate'];
        Policy__c objPolicy = [SELECT Id, Carrier__c, Benefit_Type__c FROM Policy__c WHERE Opportunity__r.Source_Id__c = 'hawaiian_ice-renewal-322'];
        System.assertEquals('HSA', objPolicy.Benefit_Type__c, 'No Policy exist with respect to HSA Benefit Type');
        //Modified for BBO-1967
        System.assertEquals(elevateCarrier.Id, objPolicy.Carrier__c, 'No Policy exist with respect to Alegeus carrier');
    }
}