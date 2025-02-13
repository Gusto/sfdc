@isTest
private class HIStateCarrierTriggerHelperTest {
    @testSetup
    static void setup() {
        Carrier_Info__c objCarrierInfo = new TestDataFactory.CarrierInfoBuilder().setId('48').build();
        insert objCarrierInfo;

        HI_Carrier_Detail__c objHICarrierDetail = new TestDataFactory.HICarrierDetailBuilder().setId('48').setName('Principal').build();
        insert objHICarrierDetail;
    }

    /**
     * @Author      : Bhagat singh
     * @Description : Process HI_State_Carrier__c Record : Insert HI State Carrier record
     **/
    @isTest
    static void insertHIStateCarrierRecord() {
        Test.startTest();
        HIStateCarrierTriggerHelper.queue = true;
        HI_State_Carrier__c objHIStateCarrier = new TestDataFactory.HIStateCarrierBuilder().setId('48').setKey('principal_ca').setState('CA').setCarrierId('48').setCarrierDetailId('48').build();
        insert objHIStateCarrier;

        Test.stopTest();

        List<Carrier__c> list_Carrier = [SELECT Id__c, Name, Carrier_Id__c FROM Carrier__c WHERE Carrier_Id__c = '48' LIMIT 1];
        System.assertEquals(list_Carrier[0].Carrier_Id__c, '48', 'Create Carrier record with respect to HI State Carrier & Carrier Info');
        System.assertEquals(list_Carrier[0].Name, 'Principal', 'Create Carrier record with respect to HI State Carrier & HI Carrier Detail');
    }

    /**
     * @Author      : Bhagat singh
     * @Description : Process HI_State_Carrier__c Record : Update HI State Carrier record
     **/
    @isTest
    static void updateHIStateCarrierRecord() {
        Test.startTest();
        HIStateCarrierTriggerHelper.queue = true;
        HIStateCarrierTriggerHelper.skipTrigger = true;
        HI_State_Carrier__c objHIStateCarrier = new TestDataFactory.HIStateCarrierBuilder().setId('48').setKey('principal_ca').setState('CA').setCarrierId('48').setCarrierDetailId('48').build();
        insert objHIStateCarrier;

        HIStateCarrierTriggerHelper.skipTrigger = false;
        update objHIStateCarrier;

        Test.stopTest();

        List<Carrier__c> list_Carrier = [SELECT Id__c, Name, Carrier_Id__c FROM Carrier__c WHERE Carrier_Id__c = '48' LIMIT 1];
        System.assertEquals(list_Carrier[0].Carrier_Id__c, '48', 'Create Carrier record with respect to HI State Carrier & Carrier Info');
        System.assertEquals(list_Carrier[0].Name, 'Principal', 'Create Carrier record with respect to HI State Carrier & HI Carrier Detail');
    }

    /**
     * @Author      : Bhagat singh
     * @Description : Process HI_State_Carrier__c Record : Validate Carrier Info
     **/
    @isTest
    static void validateHIStateCarrierRecord() {
        Test.startTest();
        HIStateCarrierTriggerHelper.queue = true;
        HI_State_Carrier__c objHIStateCarrier = new TestDataFactory.HIStateCarrierBuilder().setId('36').setKey('kaiser_ca').setState('CA').setCarrierId('36').setCarrierDetailId('36').build();
        insert objHIStateCarrier;

        Test.stopTest();

        List<HI_State_Carrier__c> list_HIStateCarriers = [SELECT Id__c, Processing_State__c, Message__c FROM HI_State_Carrier__c WHERE Id = :objHIStateCarrier.Id];
        System.assertEquals(list_HIStateCarriers[0].Processing_State__c, IntegrationUtils.ERROR_STATE, 'Carrier Info not found.');
        System.assertEquals(list_HIStateCarriers[0].Message__c, 'Carrier Info does not exist.', 'Carrier Info not found.');
    }
}