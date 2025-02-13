/**
 By : Pravesh Rana
 Date : 07-03-2017 
 */
@isTest
private class HICarrierTriggerHelperTest {

    @isTest
    static void hiIntegrationCoverageMethod() {
        
        HI_Carrier_Detail__c hiCarrierDetail = new HI_Carrier_Detail__c();
        hiCarrierDetail.Name__c = 'hiCarrier Detail';
        hiCarrierDetail.Address_Addressed_To__c = 'to address';
        hiCarrierDetail.Address_City__c = 'city address';
        hiCarrierDetail.Address_State__c = 'CA';
        hiCarrierDetail.Address_Street__c = 'street address';
        hiCarrierDetail.Address_Zip__c = '12345';
        hiCarrierDetail.Email__c = 'testHIIntegration@gusto.com';
        hiCarrierDetail.Lidi_Census_Email__c = 'testHIIntegration@gusto.com';
        hiCarrierDetail.id__c = '333111';
        insert hiCarrierDetail;
        
        HI_Carrier__c hicarrier = new HI_Carrier__c();
        hiCarrier.Carrier_Detail_Id__c = '333111';
        hiCarrier.Id__c = '333111';
        hiCarrier.key__c = '1234';
        hiCarrier.External_Key__c = '4321';
        insert  hicarrier;
        
        list<Carrier_Info__c> carrierInfoList = [select id__c from Carrier_Info__c where Id__c =:hiCarrier.Id__c];
        //Commented out by David (Dato) Tsamalashvili - 05/31/2019
        //system.assert(carrierInfoList.size()>0);
        
        update hicarrier;
        delete hicarrier;
    }
}