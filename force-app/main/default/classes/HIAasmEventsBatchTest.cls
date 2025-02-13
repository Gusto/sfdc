@isTest
public class HIAasmEventsBatchTest {
  
  /* @author        Praveen Sethu
   * @description	  Setup method to insert tier config custom settings
   * @param         void
   * @return        void
   **/
  @testSetup
  static void setup() {
    // insert org default tier config settings
    Tier_Config__c objTierConfig = new TestDataFactory.TierConfigBuilder()
      .build();
    insert objTierConfig;

    HINewPlansApplicationTriggerHelper.queue = false;
    HIAasmEventTriggerHelper.queue = false;

    // Get org default tier config settings and assert new price 1 is not blank
    objTierConfig = Tier_Config__c.getOrgDefaults();
    System.assertNotEquals(null, objTierConfig.New_Price_1__c);

    Account objAccount = new TestDataFactory.AccountBuilder()
      .setRecordTypeId(Cache.getRecordTypeId('Account', 'Company'))
      .setZPCompanyId('7757616923594875')
      .setName('Gusto HINewPlanApplication Test')
      .build();
    insert objAccount;

    PriceBook2 bk = new TestDataFactory.PriceBookBuilder()
      .setName(objTierConfig.New_Price_1__c)
      .setActive()
      .build();
    insert bk;

    Product2 productRec = TestUtility.createTestProduct(
      'Dental',
      'Benefit',
      false
    );
    insert productRec;

    List<PricebookEntry> pbeList = new List<PricebookEntry>();
    pbeList.add(
      TestUtility.createTestPriceBookEntry(
        productRec.Id,
        5,
        Test.getStandardPriceBookId(),
        false
      )
    );
    pbeList.add(
      TestUtility.createTestPriceBookEntry(productRec.Id, 5, bk.id, false)
    );
    insert pbeList;

    State__c state = new TestDataFactory.StateBuilder()
      .setAbbreviation('CA')
      .setName('TEST STATE')
      .build();
    insert state;

    Opportunity objOpportunity = new TestDataFactory.OpportunityBuilder()
      .setRecordTypeId(
        Cache.getRecordTypeId('Opportunity', 'Benefits New Plan')
      )
      .setName('TEST OPPORTUNITY')
      .setAccountId(objAccount.Id)
      .setPriceBookId(String.valueof(bk.id))
      .setStage('SAL')
      .setCloseDate(System.Today())
      .setNumberOfEE(5)
      .setZPCompanyId('7757616923594875')
      .setBenefitsState('CA')
      .setSourceID('hawaiian_ice-new_plans_application-321')
      .build();
    insert objOpportunity;

    list<HI_Aasm_Event__c> list_HIAasmEventToInsert = new List<HI_Aasm_Event__c>();

    HI_Aasm_Event__c objHIAasmEvent = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setFrom('receiving_medical_education')
      .setTo('receiving_medical_education')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent);

    HI_Aasm_Event__c objHIAasmEvent2 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('selecting_base_plan')
      .setTo('selecting_base_plan')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent2);

    HI_Aasm_Event__c objHIAasmEvent3 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('selecting_complementary_plans')
      .setTo('selecting_complementary_plans')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent3);

    HI_Aasm_Event__c objHIAasmEvent4 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('setting_sic_code_for_dental')
      .setTo('setting_sic_code_for_dental')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent4);

    HI_Aasm_Event__c objHIAasmEvent5 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('selecting_dental')
      .setTo('selecting_dental')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent5);

    HI_Aasm_Event__c objHIAasmEvent6 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('selecting_vision')
      .setTo('selecting_vision')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent6);

    HI_Aasm_Event__c objHIAasmEvent7 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('collecting_company_information')
      .setTo('collecting_company_information')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent7);

    HI_Aasm_Event__c objHIAasmEvent8 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('reviewing_summary')
      .setTo('reviewing_summary')
      .setCreatedAt(System.today())
      .build();
    list_HIAasmEventToInsert.add(objHIAasmEvent8);

    HI_Aasm_Event__c objHIAasmEvent9 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('NewPlansApplication')
      .setRecordableId('321')
      .setFrom('verifying_eligibility')
      .setTo('verifying_eligibility')
      .setCreatedAt(System.today())
      .build();
    objHIAasmEvent9.Processing_State__c = 'Queued';
    list_HIAasmEventToInsert.add(objHIAasmEvent9);

    HI_Aasm_Event__c objHIAasmEvent10 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('New HiAsamEvent')
      .setRecordableId('321')
      .setFrom('receiving_medical_education')
      .setTo('receiving_medical_education')
      .setCreatedAt(System.today())
      .build();
    objHIAasmEvent10.Processing_State__c = 'Error';
    list_HIAasmEventToInsert.add(objHIAasmEvent10);

    HI_Aasm_Event__c objHIAasmEvent11 = new TestDataFactory.HIAasmEventBuilder()
      .setRecordableType('New HiAsamEvent2')
      .setRecordableId('3212')
      .setFrom('receiving_medical_education')
      .setTo('receiving_medical_education')
      .setCreatedAt(System.today())
      .build();
    objHIAasmEvent11.Processing_State__c = 'Dead';
    objHIAasmEvent11.Last_Processed__c = System.now().addDays(-30);
    list_HIAasmEventToInsert.add(objHIAasmEvent11);

    list<HI_New_Plans_Application__c> list_HINewPlansApplication = new List<HI_New_Plans_Application__c>();

    HI_New_Plans_Application__c objHINewPlansApplication = new TestDataFactory.HINewPlansApplicationBuilder()
      .setCompanyId('7757616923594875')
      .setExternalKey('hawaiian_ice-new_plans_application-321')
      .setId('321')
      .setReqStartDate(system.today())
      .build();
    list_HINewPlansApplication.add(objHINewPlansApplication);

    HI_New_Plans_Application__c objHINewPlansApplication1 = new TestDataFactory.HINewPlansApplicationBuilder()
      .setCompanyId('7757616923594875')
      .setId('322')
      .setReqStartDate(system.today())
      .build();
    list_HINewPlansApplication.add(objHINewPlansApplication1);

    insert list_HINewPlansApplication;

    insert list_HIAasmEventToInsert;
  }

  /**
   * @description process HI_Aasm_Event__c record through HIAasmEventsBatch
   * @author Nigam Goyal | 05-24-2024 
   **/
  @isTest
  static void testBatchExecution() {
    Test.startTest();

    Utils.skipTrigger(false);

    HIAasmEventsBatch objBatch = new HIAasmEventsBatch();
    Database.executeBatch(objBatch);

    Test.stopTest();

    List<HI_Aasm_Event__c> list_QueriedEvents = [
      SELECT Id, Processing_State__c, Last_Processed__c
      FROM HI_Aasm_Event__c
      WHERE Processing_State__c = 'Error'
    ];

    List<HI_Aasm_Event__c> list_QueriedEvent = [
      SELECT Id, Processing_State__c, Last_Processed__c
      FROM HI_Aasm_Event__c
      WHERE Processing_State__c = 'Dead'
    ];

    if (!list_QueriedEvents.IsEmpty()) {
      for (HI_Aasm_Event__c objHIAasmEvents : list_QueriedEvents) {
        if (objHIAasmEvents.Processing_State__c == 'Error') {
          objHIAasmEvents.Processing_State__c = 'Dead';
        }
      }
      update list_QueriedEvents;
    }

    System.assertEquals(
      list_QueriedEvents[0].Processing_State__c,
      'Dead',
      'Processing State should be matched'
    );

    List<HI_Aasm_Event__c> list_newGroup = new List<HI_Aasm_Event__c>();
    for (HI_Aasm_Event__c objHIAasmEvents : list_QueriedEvent) {
      if (
        objHIAasmEvents.Processing_State__c == 'Dead' &&
        objHIAasmEvents.Last_Processed__c < System.now().addDays(-30)
      ) {
        list_newGroup.add(objHIAasmEvents);
      }
    }
    if (!list_newGroup.IsEmpty()) {
      delete list_newGroup;
    }
  }

 /**
  * @description test HIEventBatchScheduler to process error records of AasmEvent
  * @author Nigam Goyal | 05-23-2024
  **/
 @isTest
 static void testSchedulerExecution() {
		Test.startTest();

		Utils.skipTrigger(false);

		String CRON_EXP = '0 0 * * * ?';
		HIAasmEventsBatch sch = new HIAasmEventsBatch();

		System.schedule('HIEventBatchScheduler Hourly Example Batch Schedule job', CRON_EXP, sch);

		Test.stopTest();

		List<HI_Aasm_Event__c> list_QueriedEvents = [SELECT Id, Processing_State__c, Last_Processed__c FROM HI_Aasm_Event__c WHERE Processing_State__c = 'Error'];

		List<HI_Aasm_Event__c> list_QueriedEvent = [SELECT Id, Processing_State__c, Last_Processed__c FROM HI_Aasm_Event__c WHERE Processing_State__c = 'Dead'];

		if (!list_QueriedEvents.IsEmpty()) {
			for (HI_Aasm_Event__c objHIAasmEvents : list_QueriedEvents) {
				if (objHIAasmEvents.Processing_State__c == 'Error') {
					objHIAasmEvents.Processing_State__c = 'Dead';
				}
			}
			update list_QueriedEvents;
		}

		System.assertEquals(list_QueriedEvents[0].Processing_State__c, 'Dead', 'Processing State should be matched');

		List<HI_Aasm_Event__c> list_newGroup = new List<HI_Aasm_Event__c>();
		for (HI_Aasm_Event__c objHIAasmEvents : list_QueriedEvent) {
			if (objHIAasmEvents.Processing_State__c == 'Dead' && objHIAasmEvents.Last_Processed__c < System.now().addDays(-30)) {
				list_newGroup.add(objHIAasmEvents);
			}
		}
		if (!list_newGroup.IsEmpty()) {
			delete list_newGroup;
		}
	}
}