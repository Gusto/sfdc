/**
 * @name         : HIBenefitApplicationUserBatchTest
 * @author       : Udit Jain
 * @date         : 22/03/2024
 * @description  : Unit tests for HIBenefitApplicationUserBatch
 * @test classes : NA
 **/
@isTest
private class HIBenefitApplicationUserBatchTest {
  /**
   * @Author      : Udit Jain
   * @Description : Sets common data for all the test methods
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @testSetup
  static void testSetup() {
    Account acc = new TestDataFactory.AccountBuilder()
      .setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
      .setZPCompanyId('11111111111111')
      .setName('Gusto HIBenefitApplicationUserBatch Test')
      .build();
    insert acc;

    ZP_User__c zpUser = new TestDataFactory.ZPUserBuilder()
      .setEmail('test@gusto.com')
      .setCustomId('8888')
      .setCreatedAt(system.today())
      .setUpdatedAt(system.today())
      .build();
    insert zpUser;

    ZP_User_Role__c zpUserRole = new TestDataFactory.ZPUserRoleBuilder()
      .setUserId('8888')
      .setFirstName('Test')
      .setLastName('Test')
      .build();
    insert zpUserRole;

    HI_BoR_Transfer__c hiBORRec = new TestDataFactory.HIBoRTransferBuilder()
      .setCompanyId('11111111111111')
      .setExternalKey('Opportunity321')
      .setId('newBor321')
      .build();
    insert hiBORRec;

    HIBenefitApplicationUserTriggerHelper.skipTrigger = true;
    HIBenefitApplicationUserTriggerHelper.queue = true;
    HI_Benefit_Application_User__c usr = new TestDataFactory.HIBenefitApplicationUserBuilder()
      .setApplicationId('newBor321')
      .setUserId('8888')
      .setId('1234')
      .setApplicationType('BorTransfer')
      .setProcessingState('Error')
      .build();
    insert usr;

    HIBenefitApplicationUserTriggerHelper.queue = true;
    HI_Benefit_Application_User__c usr1 = new TestDataFactory.HIBenefitApplicationUserBuilder()
      .setApplicationId('newBor322')
      .setUserId('888')
      .setId('123')
      .setApplicationType('BorTransfer')
      .setProcessingState('Dead')
      .build();
    usr1.Last_Processed__c = System.now().addDays(-30);
    insert usr1;
    HIBenefitApplicationUserTriggerHelper.skipTrigger = false;

    System.assertEquals(
      usr.Processing_State__c != null,
      true,
      'Processing State should be matched'
    );

    System.assertEquals(
      usr1.Processing_State__c != null,
      true,
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
  static void testHIBenefitApplicationUser() {
    Test.startTest();
    Utils.skipTrigger(false);
    HIBenefitApplicationUserBatch objBatch = new HIBenefitApplicationUserBatch();
    Database.executeBatch(objBatch);
    Test.stopTest();

    List<HI_Benefit_Application_User__c> list_BenefitApps = [
      SELECT Id, Processing_State__c, Last_Processed__c
      FROM HI_Benefit_Application_User__c
    ];

    System.assertEquals(
      list_BenefitApps.get(0).Processing_State__c,
      'Dead',
      'Processing State should be matched'
    );

    List<HI_Benefit_Application_User__c> list_BenefitApps2 = [
      SELECT Id, Processing_State__c, Last_Processed__c
      FROM HI_Benefit_Application_User__c
      WHERE Processing_State__c = 'Dead'
    ];

    if (!list_BenefitApps.IsEmpty()) {
      for (
        HI_Benefit_Application_User__c objHIbenefitApplication : list_BenefitApps
      ) {
        if (objHIbenefitApplication.Processing_State__c == 'Error') {
          objHIbenefitApplication.Processing_State__c = 'Dead';
        }
      }

      update list_BenefitApps;
    }

    List<HI_Benefit_Application_User__c> List_BenefitApplication = new List<HI_Benefit_Application_User__c>();

    for (HI_Benefit_Application_User__c objHIBenefitApps : list_BenefitApps2) {
      if (
        objHIBenefitApps.Processing_State__c == 'Dead' &&
        objHIBenefitApps.Last_Processed__c < System.now().addDays(-30)
      ) {
        List_BenefitApplication.add(objHIBenefitApps);
      }
    }
    if (!List_BenefitApplication.IsEmpty()) {
      delete List_BenefitApplication;
    }
  }
}