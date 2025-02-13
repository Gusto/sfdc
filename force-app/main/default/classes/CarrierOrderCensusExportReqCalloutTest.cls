/**
 * @name         CarrierOrderCensusExportReqCalloutTest
 * @author       Ajay Kumar Vijay
 * @date         08/24/2023
 * @description  Test class for CarrierOrderCensusExportReqKafkaCallout
 **/
@isTest
public class CarrierOrderCensusExportReqCalloutTest {
    @isTest
    private static void testCensusExportRequestCalloutWithoutException() {
        try {
            Account objAccount = new TestDataFactory.AccountBuilder()
                .setRecordTypeId('Company')
                .setName('Test Account1')
                .setZPCompanyId('123456789')
                .build();
            insert objAccount;

            Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
                .setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
                .setAccountId(objAccount.Id)
                .setName('TEST OPPORTUNITY')
                .setStage('Open')
                .setCloseDate(System.Today())
                .setSourceID('testSourceId')
                .build();
            insert objOpp;

            Benefit_Order__c objBO = new TestDataFactory.BenefitOrderBuilder()
                .setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
                .setOpp(objOpp.Id)
                .setStatus('Ready for Qualification')
                .setOwnerID(UserInfo.getUserId())
                .build();

            Carrier__c objCarrierRec = new TestDataFactory.CarrierBuilder()
                .setName('Test123')
                .setKey('test123')
                .setId('test123')
                .setCarrierId('28272728')
                .build();
            insert objCarrierRec;

            Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
                .setName('TestCarrierOrder')
                .setRecordTypeId(Cache.getRecordTypeId('Carrier_Order__c', 'Renewal'))
                .setCarrier(objCarrierRec.Id)
                .setOwnerID(UserInfo.getUserId())
                .setBenefitOrder(objBO.Id)
                .setOrderType('Carrier Switch')
                .setStartDate(System.today() - 50)
                .setImplementationStage('Ready for Submission Prep')
                .build();
            insert objCarrierOrder;

            Test.startTest();
            CarrierOrderCensusExportReqKafkaCallout.carrierOrderCensusExportRequest(
                new List<CarrierOrderCensusExportReqKafkaCallout.Request> {
                    new CarrierOrderCensusExportReqKafkaCallout.Request(
                        objCarrierOrder.Carrier_Group_Number__c,
                        objCarrierOrder.HI_Carrier_Id__c,
                        objCarrierOrder.ZP_Company_Id__c
                    )
                }
            );
            Test.stopTest();
        } catch(Exception e) {
            System.assert(false, e.getMessage());
        }
    }
}