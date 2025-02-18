/**
 * @name         : HIGroupEventBatchTest
 * @author       : Sanjay Paryani
 * @date         : 09/07/2021
 * @description  : Unit tests for HIGroupEventBatch
 * @test classes : NA
 **/
@isTest
private class HIGroupEventBatchTest {
  /**
   * @Author      : Sanjay Paryani
   * @Description : Sets common data for all the test methods
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @testSetup
  static void testData() {
    Utils.skipTrigger(true);
    // insert org default tier config settings
    Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder()
      .build();
    insert objTierConfig;

    List<Email_Macro__c> list_EmailMacros = new List<Email_Macro__c>();
    Email_Macro__c objMacro = new Email_Macro__c();
    objMacro.Macro_Identifier__c = 'OA-INTRO-EMAIL-SUBJECT-1';
    objMacro.Body__c = 'Action required: Response needed to set up benefits for [ACCOUNT NAME]';
    list_EmailMacros.add(objMacro);

    objMacro = new Email_Macro__c();
    objMacro.Macro_Identifier__c = 'OA-INTRO-EMAIL-SUBJECT-2';
    objMacro.Body__c = 'Please read: Let’s start renewing [ACCOUNT NAME]’s benefits!';
    list_EmailMacros.add(objMacro);
    insert list_EmailMacros;

    State__c objState = new State__c(
      Name = 'California',
      Abbreviation__c = 'CA',
      Key__c = 'CA'
    );
    insert objState;

    Opportunity objOpp = TestUtility.BenefitsNewPlanOpportunity();
    Account objAcc = new Account(
      Id = objOpp.AccountId,
      ZP_Company_Id__c = '72239',
      Tier__c = objTierConfig.New_Tier_1__c,
      AM_Tier__c = 'Gold',
      ShippingState = 'California',
      BillingState = 'California'
    );
    update objAcc;

    objOpp.Source_ID__c = 'hawaiian_ice-new_plans_application-11001';
    objOpp.HI_Effective_Date__c = System.today().addDays(2);
    objOpp.Benefits_Current_Setup_Step__c = 'Verifying Eligibility';
    update objOpp;

    Carrier__c objCarrier = TestUtility.Carrier();
    Policy__c objPolicy = (Policy__c) Policy__c.SObjectType.newSObject();
    objPolicy.Name = 'TEST POLICY';
    objPolicy.Opportunity__c = objOpp.Id;
    objPolicy.Carrier__c = objCarrier.Id;
    objPolicy.Is_Selected__c = true;
    objPolicy.State__c = objState.Id;
    insert objPolicy;

    //Create Contact
    Contact objContact = new Contact(
      FirstName = 'Test',
      LastName = 'User01',
      recordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID,
      AccountId = objOpp.AccountId,
      Email = 'testuser01@gusto.com',
      Zp_User_Id__c = '75001'
    );
    insert objContact;

    //Create TTF record.
    NewTransitionToFulfillmentController.BO_order_type = new List<String>();
    NewTransitionToFulfillmentController.BO_order_type.add('Carrier Switch');
    Id idTTFRecordType = cache.getRecordTypeId(
      'Transition_to_Fulfillment__c',
      'Benefits New Plan'
    );
    TestUtility.createTestTransitionToFulfillment(
      objOpp.AccountId,
      objContact.Id,
      objOpp.Id,
      idTTFRecordType,
      true
    );

    List<Role__c> list_Roles = new List<Role__c>();
    list_Roles.add(
      new Role__c(
        Name = 'Implementation Advocate',
        Skill_Type__c = 'Implementation Advocate',
        Team__c = 'Core'
      )
    );
    list_Roles.add(
      new Role__c(
        Name = 'Qualification',
        Skill_Type__c = 'Qualification',
        Team__c = 'Core'
      )
    );
    list_Roles.add(
      new Role__c(
        Name = 'Submission',
        Skill_Type__c = 'Submission',
        Team__c = 'Core'
      )
    );
    insert list_Roles;

    List<Skill__c> list_Skills = new List<Skill__c>();
    list_Skills.add(
      new Skill__c(
        Role__c = list_Roles[0].Id,
        Tier__c = objTierConfig.New_Tier_1__c,
        State_Group__c = 'California',
        Partner__c = 'Gold',
        Order_Type__c = 'New to Gusto'
      )
    );
    list_Skills.add(
      new Skill__c(
        Role__c = list_Roles[1].Id,
        Tier__c = objTierConfig.New_Tier_1__c,
        State_Group__c = 'California',
        Partner__c = 'Gold',
        Order_Type__c = 'New to Gusto'
      )
    );
    list_Skills.add(
      new Skill__c(
        Role__c = list_Roles[2].Id,
        Tier__c = objTierConfig.New_Tier_1__c,
        State_Group__c = 'California',
        Partner__c = 'Gold',
        Order_Type__c = 'New to Gusto'
      )
    );
    insert list_Skills;

    List<User> list_Users = TestUtility.createUsers('Benefits Fulfillment', 3);
    List<User_Role__c> list_UserRoles = new List<User_Role__c>();
    list_UserRoles.add(
      new User_Role__c(
        User_Skill_Team__c = 'Implementation Advocate',
        User_Skill_Type__c = 'Core',
        User__c = list_Users[0].Id
      )
    );
    list_UserRoles.add(
      new User_Role__c(
        User_Skill_Team__c = 'Qualification',
        User_Skill_Type__c = 'Core',
        User__c = list_Users[1].Id
      )
    );
    list_UserRoles.add(
      new User_Role__c(
        User_Skill_Team__c = 'Submission',
        User_Skill_Type__c = 'Core',
        User__c = list_Users[2].Id
      )
    );
    insert list_UserRoles;

    List<User_Skill__c> list_UserSkills = new List<User_Skill__c>();
    list_UserSkills.add(
      new User_Skill__c(
        User_Role__c = list_UserRoles[0].Id,
        Skill__c = list_Skills[0].Id,
        Active__c = true
      )
    );
    list_UserSkills.add(
      new User_Skill__c(
        User_Role__c = list_UserRoles[1].Id,
        Skill__c = list_Skills[1].Id,
        Active__c = true
      )
    );
    list_UserSkills.add(
      new User_Skill__c(
        User_Role__c = list_UserRoles[2].Id,
        Skill__c = list_Skills[2].Id,
        Active__c = true
      )
    );
    insert list_UserSkills;
    Utils.skipTrigger(false);
  }

  /**
   * @Author      : Sanjay Paryani
   * @Description : Test batch class picking up errorred records
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @isTest
  static void tesHIGroupEventOAIntroEmailEventInfo() {
    
    Case objCase = [
      SELECT Id, ContactId, AccountId
      FROM Case
      WHERE Benefit_Order__c != NULL AND Integration_Id__c LIKE 'hippo-%'
      LIMIT 1
    ];

    Utils.skipTrigger(true);
    List<Contact> list_Contact = new List<Contact>();
    Contact objContact1 = new TestDataFactory.ContactBuilder()
      .setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
      .setFirstName('User 1')
      .setLastName('Test')
      .setEmail('mycaseuser1@gusto.com')
      .setAccountId(objCase.AccountId)
      .build();
    list_Contact.add(objContact1);

    Contact objContact2 = new TestDataFactory.ContactBuilder()
      .setRecordTypeId(ContactUtil.COMPANY_RT_NAME)
      .setFirstName('User 2')
      .setLastName('Test')
      .setEmail('mycaseuser2@gusto.com')
      .setAccountId(objCase.AccountId)
      .build();
    list_Contact.add(objContact2);
    insert list_Contact;

    List<CaseTeamRole> list_CaseTeamRoles = [
      SELECT Id
      FROM CaseTeamRole
      WHERE Name = 'Customer Contact'
    ];
    Id idCaseTeamRole = null;
    if (list_CaseTeamRoles != null && list_CaseTeamRoles.size() > 0) {
      idCaseTeamRole = list_CaseTeamRoles[0].Id;
    }

    Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
    List<CaseTeamMember> list_CaseTeams = new List<CaseTeamMember>();
    CaseTeamMember objCaseTeamMember = new TestDataFactory.CaseTeamMemberBuilder()
      .setMemberId(list_Contact[0].Id)
      .setParentId(objCase.Id)
      .setTeamRoleId(idCaseTeamRole)
      .build();
    list_CaseTeams.add(objCaseTeamMember);

    CaseTeamMember objCaseTeamMember2 = new TestDataFactory.CaseTeamMemberBuilder()
      .setMemberId(list_Contact[1].Id)
      .setParentId(objCase.Id)
      .setTeamRoleId(idCaseTeamRole)
      .build();
    list_CaseTeams.add(objCaseTeamMember2);

    insert list_CaseTeams;

    HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_email')
      .setApplicationId('11001')
      .setApplicationType('New Plan')
      .setCompanyId('72239')
      .setEventId('11001')
      .setEventType('OA_intro_email')
      .setProcessingState('Error')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    insert objHIGroupEvent;
    

    HIGroupEvent__c objHIGroupEvent2 = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_emails')
      .setApplicationId('11002')
      .setApplicationType('New Plan')
      .setCompanyId('72239')
      .setEventId('11002')
      .setEventType('OA_intro_email')
      .setProcessingState('Dead')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    objHIGroupEvent2.Processed_At__c = System.now().addDays(-90);
    insert objHIGroupEvent2;

    HIGroupEvent__c objHIGroupEvent3 = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_email')
      .setApplicationId('11003')
      .setApplicationType('New Plan')
      .setCompanyId('722393')
      .setEventId('11003')
      .setEventType('OA_intro_email')
      .setProcessingState('Error')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    insert objHIGroupEvent3;
    Test.setCreatedDate(objHIGroupEvent3.Id, Date.today().addDays(-11));

    HIGroupEvent__c objHIGroupEvent4 = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_email')
      .setApplicationId('11004')
      .setApplicationType('New Plan')
      .setCompanyId('722394')
      .setEventId('11004')
      .setEventType('OA_intro_email')
      .setProcessingState('Dead')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    insert objHIGroupEvent4;
    Test.setCreatedDate(objHIGroupEvent4.Id, Date.today().addDays(-160));

    HIGroupEvent__c objHIGroupEvent5 = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_email')
      .setApplicationId('11003')
      .setApplicationType('New Plan')
      .setCompanyId('722393')
      .setEventId('11003')
      .setEventType('OA_intro_email')
      .setProcessingState('Error')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    insert objHIGroupEvent5;
    Test.setCreatedDate(objHIGroupEvent5.Id, Date.today().addDays(-1));

    System.assertEquals(
      [
        SELECT Processing_State__c
        FROM HIGroupEvent__c
        WHERE Id = :objHIGroupEvent2.Id
      ]
      .Processing_State__c,
      'Dead',
      'Processing State should be matched'
    );

    Utils.skipTrigger(false);
    Test.startTest();
    HIGroupEventBatch objBatch = new HIGroupEventBatch();
    Database.executeBatch(objBatch);
    Test.stopTest();

    List<HIGroupEvent__c> list_QueriedEvents = [
      SELECT Id, Processing_State__c, Processed_At__c
      FROM HIGroupEvent__c
      WHERE Application_Id__c = '11001'
    ];
    System.assertEquals(
      list_QueriedEvents.get(0).Processing_State__c,
      'Error',
      'Processing State should be matched'
    );

    List<HIGroupEvent__c> list_QueriedEvent = [
      SELECT Id, Processing_State__c, Processed_At__c
      FROM HIGroupEvent__c
      WHERE Application_Id__c = '11002'
    ];

    if (!list_QueriedEvents.IsEmpty()) {
      for (HIGroupEvent__c objHIGroupEvents : list_QueriedEvents) {
        if (objHIGroupEvents.Processing_State__c == 'Error') {
          objHIGroupEvents.Processing_State__c = 'Dead';
        }
      }

      update list_QueriedEvents;
      System.assertEquals(
        list_QueriedEvents.get(0).Processing_State__c,
        'Dead',
        'Processing State should be matched'
      );
    }

    List<HIGroupEvent__c> List_newGroup = new List<HIGroupEvent__c>();

    for (HIGroupEvent__c objHIGroupsEvents : list_QueriedEvent) {
      if (
        objHIGroupsEvents.Processing_State__c == 'Dead' &&
        objHIGroupsEvents.Processed_At__c < System.now().addDays(-90)
      ) {
        List_newGroup.add(objHIGroupsEvents);
      }
    }
    if (!List_newGroup.IsEmpty()) {
      delete List_newGroup;
    }
  }

  /**
   * @Author      : Sanjay Paryani
   * @Description : Test scheduler for batch class picking up errorred records
   * @Parm        : N/A
   * @Return      : N/A
   **/
  @isTest
  static void testSchedulerExecution() {
    Utils.skipTrigger(true);
    HIGroupEvent__c objHIGroupEvent = new TestDataFactory.HIGroupEventBuilder()
      .setName('OA_intro_email')
      .setApplicationId('11001')
      .setApplicationType('New Plan')
      .setCompanyId('72239')
      .setEventId('11001')
      .setEventType('OA_intro_email')
      .setProcessingState('Error')
      .setMessage(
        '{~opportunity}# unable to obtain exclusive access to this record or 1 records: 0011M00002WC2tZQAT'
      )
      .setEventInfo(
        '{"event_id":11001,"company_id":72239,"application_id":11001,"application_type":"New Plan","email_body":"test email body","event_type":"OA_intro_email"}'
      )
      .build();
    insert objHIGroupEvent;
    Utils.skipTrigger(false);

    Test.startTest();
    String CRON_EXP = '0 0 * * * ?';
    HIGroupEventBatch sch = new HIGroupEventBatch();
    System.schedule(
      'HIGroupEventBatchScheduler Hourly Example Batch Schedule job',
      CRON_EXP,
      sch
    );
    Test.stopTest();

    List<HIGroupEvent__c> list_QueriedEvents = [
      SELECT Id, Processing_State__c
      FROM HIGroupEvent__c
      WHERE Application_Id__c = '11001'
    ];
    System.assertEquals(list_QueriedEvents.size() > 0, true);
  }
}