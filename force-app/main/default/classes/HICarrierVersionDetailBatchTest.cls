/**
 * @name         : HICarrierVersionDetailBatchTest
 * @author       : Udit Jain
 * @date         : 22/03/2024
 * @description  : Unit tests for HICarrierVersionDetailBatch
 * @test classes : NA
 **/
@isTest
private class HICarrierVersionDetailBatchTest {
  /**
   * @Author      : Udit Jain
   * @Description : Sets common data for all the test methods
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @testSetup
  static void testSetup() {
    Carrier__C objCarrier = new TestDataFactory.CarrierBuilder()
      .setName('Aetna')
      .setId('1')
      .setCarrierId('1')
      .build();
    insert objCarrier;

    HICarrierVersionDetail__c objHICarrierVersion = new TestDataFactory.HICarrierVersionDetailBuilder()
      .setEventId('Ttta2w23')
      .setEventType('carrier_metadata')
      .setStateCarrierId('1')
      .setEffectiveDate(System.today())
      .setNewPlanEmailList('Test')
      .setNoEnrollees('no')
      .setStateEmployees('yes')
      .setStateFTECount('["o","p"]')
      .setProcessingState('Error')
      .build();
    HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
    insert objHICarrierVersion;
    HICarrierVersionDetailTriggerHandler.blnSkipTrigger = false;
    Test.setCreatedDate(objHICarrierVersion.Id, System.now().addDays(-30));

    HICarrierVersionDetail__c objHICarrierVersion2 = new TestDataFactory.HICarrierVersionDetailBuilder()
      .setEventId('Ttta2w24')
      .setEventType('carrier_metadata')
      .setStateCarrierId('1')
      .setEffectiveDate(System.today())
      .setNewPlanEmailList('Test')
      .setNoEnrollees('no')
      .setStateEmployees('yes')
      .setStateFTECount('["o","p"]')
      .setProcessingState('Dead')
      .build();
    objHICarrierVersion2.Processed_At__c = System.now().addDays(-35);
    HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
    insert objHICarrierVersion2;
    HICarrierVersionDetailTriggerHandler.blnSkipTrigger = false;
    Test.setCreatedDate(objHICarrierVersion2.Id, System.now().addDays(-30));

    System.assertEquals(
      [
        SELECT Processing_State__c
        FROM HICarrierVersionDetail__c
        WHERE Id = :objHICarrierVersion.Id
      ]
      .Processing_State__c,
      'Error',
      'Processing State should be matched'
    );

    System.assertEquals(
      [
        SELECT Processing_State__c
        FROM HICarrierVersionDetail__c
        WHERE Id = :objHICarrierVersion2.Id
      ]
      .Processing_State__c,
      'Dead',
      'Processing State should be matched'
    );
  }

  /**
   * @Author      : Udit Jain
   * @Description : Test batch class picking up errorred records
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @isTest
  static void tesHIGroupEventOAIntroEmailEventInfo() {
    Test.startTest();
    Utils.skipTrigger(false);
    HICarrierVersionDetailBatch objBatch = new HICarrierVersionDetailBatch();
    Database.executeBatch(objBatch);
    Test.stopTest();

    List<HICarrierVersionDetail__c> list_CarrierVersion = [
      SELECT Id, Processing_State__c, Processed_At__c
      FROM HICarrierVersionDetail__c
    ];

    System.assertEquals(
      list_CarrierVersion.get(0).Processing_State__c,
      'Processed',
      'Processing State should be matched'
    );

    List<HICarrierVersionDetail__c> list_CarrierVersion2 = [
      SELECT Id, Processing_State__c, Processed_At__c
      FROM HICarrierVersionDetail__c
      WHERE Processing_State__c = 'Dead'
    ];

    if (!list_CarrierVersion.IsEmpty()) {
      for (
        HICarrierVersionDetail__c objHICarrierVersionDetails : list_CarrierVersion
      ) {
        if (objHICarrierVersionDetails.Processing_State__c == 'Error') {
          objHICarrierVersionDetails.Processing_State__c = 'Dead';
        }
      }
      HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
      update list_CarrierVersion;
      HICarrierVersionDetailTriggerHandler.blnSkipTrigger = false;
    }

    list<HICarrierVersionDetail__c> List_CarrierDetail = new List<HICarrierVersionDetail__c>();

    for (HICarrierVersionDetail__c objHICarrierDetail : list_CarrierVersion2) {
      if (
        objHICarrierDetail.Processing_State__c == 'Dead' &&
        objHICarrierDetail.Processed_At__c < System.now().addDays(-30)
      ) {
        List_CarrierDetail.add(objHICarrierDetail);
      }
    }
    if (!List_CarrierDetail.IsEmpty()) {
      delete List_CarrierDetail;
    }
  }

  /**
   * @Author      : Udit Jain
   * @Description : Test scheduler for batch class picking up errorred records
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @isTest
  static void testSchedulerExecution() {
    Utils.skipTrigger(true);
    HICarrierVersionDetail__c objHICarrierVersionDetail = new TestDataFactory.HICarrierVersionDetailBuilder()
      .setEventId('Ttta2w25')
      .setEventType('carrier_metadata')
      .setStateCarrierId('1')
      .setEffectiveDate(System.today())
      .setNewPlanEmailList('Test')
      .setNoEnrollees('no')
      .setStateEmployees('yes')
      .setStateFTECount('["o","p"]')
      .setProcessingState('Error')
      .build();
    objHICarrierVersionDetail.Processed_At__c = System.now().addDays(-30);
    insert objHICarrierVersionDetail;
    Test.setCreatedDate(
      objHICarrierVersionDetail.Id,
      System.now().addDays(-30)
    );
    Utils.skipTrigger(false);

    Test.startTest();
    String CRON_EXP = '0 0 * * * ?';
    HICarrierVersionDetailBatch sch = new HICarrierVersionDetailBatch();
    System.schedule(
      'HICarrierVersionDetailBatchScheduler Hourly Example Batch Schedule job',
      CRON_EXP,
      sch
    );
    Test.stopTest();

    List<HICarrierVersionDetail__c> list_CarrierVersion = [
      SELECT Id, Processing_State__c
      FROM HICarrierVersionDetail__c
      WHERE Event_Id__c = 'Ttta2w25'
    ];
    System.assertEquals(list_CarrierVersion.size() > 0, true);
  }
}