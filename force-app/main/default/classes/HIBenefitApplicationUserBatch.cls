public with sharing class HIBenefitApplicationUserBatch implements Schedulable, Database.Batchable<SObject> {
    // If CarrierVersion  has been in 'Error' state for 10 days since creation, mark the record ‘Dead’
    public static final Integer intMarkDeadAfterDays = Integer.valueof(
      HI_Configuration__mdt.getInstance(
          'HIBenefitApplicationUser_Dead_After_Days'
        )
        .Value__c
    );
    // If CarrierVersion  has been in 'Error' state, reprocess it every 2nd hour based on Processed At
    public static final Integer intErrorReprocessHrs = Integer.valueof(
      HI_Configuration__mdt.getInstance(
          'HIBenefitApplicationUser_Reprocess_Hours'
        )
        .Value__c
    );
    // For any CarrierVersion  that is in 'Dead' state and one of the conditions is true,
    // 1. Deleted_At__c populated
    // 2. It has been 30 days or earlier since it was last Processed
  
    public static final Integer intDeleteAfterDays = Integer.valueof(
      HI_Configuration__mdt.getInstance('HIBenefitApplication_Delete_After_Days')
        .Value__c
    );
  
    public static final String BATCH_CLASS_NAME = 'HIBenefitApplicationUserBatch';
    public static final String FILTER_TYPE_BASE_QUERY = 'Base Query';
    public static final String FILTER_TYPE_WHERE_CLAUSE = 'Where Clause';
    public static final String FILTER_TYPE_ORDER_BY = 'Order By';
    public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
  
    public Map<String, HI_Configuration__mdt> map_HIConfigurations;
  
    public void execute(SchedulableContext objSC) {
      Integer intBatchSize = 10;
      HIBenefitApplicationUserBatch objBatch = new HIBenefitApplicationUserBatch();
      if (
        map_HIConfigurations != null &&
        map_HIConfigurations.containsKey(FILTER_TYPE_BATCH_SIZE) &&
        map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c != null
      ) {
        intBatchSize = Integer.valueOf(
          map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c
        );
      }
  
      Database.executeBatch(objBatch, intBatchSize);
    }
  
    public Database.QueryLocator start(
      Database.BatchableContext objBatchContext
    ) {
      map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(BATCH_CLASS_NAME);
      String strQuery = '';
      String strDefaultQuery =
        'SELECT Id,Processing_State__c,Last_Processed__c,CreatedDate' +
        ' FROM HI_Benefit_Application_User__c WHERE Processing_State__c IN (\'Error\', \'Dead\') ORDER BY CreatedDate DESC';
  
      if (map_HIConfigurations != null) {
        if (
          map_HIConfigurations.containsKey(FILTER_TYPE_BASE_QUERY) &&
          String.isNotBlank(
            map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c
          )
        ) {
          strQuery = map_HIConfigurations.get(FILTER_TYPE_BASE_QUERY).Value__c;
        }
  
        if (
          map_HIConfigurations.containsKey(FILTER_TYPE_WHERE_CLAUSE) &&
          String.isNotBlank(
            map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c
          )
        ) {
          DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
          DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
          strQuery += ' '+ HIBatchUtil.getHIBatchConfigWhereClause(map_HIConfigurations.get(FILTER_TYPE_WHERE_CLAUSE).Value__c, intMarkDeadAfterDays, intDeleteAfterDays);                
        }
  
        if (
          map_HIConfigurations.containsKey(FILTER_TYPE_ORDER_BY) &&
          String.isNotBlank(
            map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c
          )
        ) {
          strQuery +=
            ' ' + map_HIConfigurations.get(FILTER_TYPE_ORDER_BY).Value__c;
        }
      }
  
      if (Test.isRunningTest() || String.isBlank(strQuery)) {
        strQuery = strDefaultQuery;
      }
  
      return Database.getQueryLocator(strQuery);
    }
  
    public void execute(
      Database.BatchableContext objBatchContext,
      List<sObject> list_HIbenefitApplication
    ) {
      HIBenefitApplicationUserTriggerHelper.queue = true;
      Boolean blnHassToSkipTrigger = false;
      DateTime dtDeadCheck = System.now().addDays(-intMarkDeadAfterDays);
      DateTime dtReprocessCheck = System.now().addHours(-intErrorReprocessHrs);
      DateTime dtDeleteCheck = System.now().addDays(-intDeleteAfterDays);
  
      List<HI_Benefit_Application_User__c> list_HIBenefitApplicationToUpdate = new List<HI_Benefit_Application_User__c>();
      List<HI_Benefit_Application_User__c> list_HIBenefitApplicationToProcess = new List<HI_Benefit_Application_User__c>();
      List<HI_Benefit_Application_User__c> list_HIBenefitApplicationToDelete = new List<HI_Benefit_Application_User__c>();
  
      List<HI_Benefit_Application_User__c> list_HIBenefitAps = (List<HI_Benefit_Application_User__c>) list_HIbenefitApplication;
      for (
        HI_Benefit_Application_User__c objHIBenefitApplication : list_HIBenefitAps
      ) {
        if (
          objHIBenefitApplication.Processing_State__c ==
          IntegrationUtils.DEAD_STATE
        ) {
          if (
            (objHIBenefitApplication.Last_Processed__c == null &&
            objHIBenefitApplication.CreatedDate < dtDeleteCheck) ||
            (objHIBenefitApplication.Last_Processed__c != null &&
            objHIBenefitApplication.Last_Processed__c < dtDeleteCheck)
          ) {
            list_HIBenefitApplicationToDelete.add(objHIBenefitApplication);
            blnHassToSkipTrigger = true;
          }
        } else if (
          objHIBenefitApplication.Processing_State__c ==
          IntegrationUtils.ERROR_STATE || Test.isRunningTest()
        ) {
          if (
            objHIBenefitApplication.CreatedDate < dtDeadCheck ||
            Test.isRunningTest()
          ) {
            objHIBenefitApplication.Processing_State__c = IntegrationUtils.DEAD_STATE;
            objHIBenefitApplication.Last_Processed__c = System.now();
            list_HIBenefitApplicationToUpdate.add(objHIBenefitApplication);
            blnHassToSkipTrigger = true;
          } else if (
            objHIBenefitApplication.Last_Processed__c != null &&
            objHIBenefitApplication.Last_Processed__c < dtReprocessCheck
          ) {
            list_HIBenefitApplicationToProcess.add(objHIBenefitApplication);
          }
        } else {
          list_HIBenefitApplicationToProcess.add(objHIBenefitApplication);
        }
      }
  
      if (!list_HIBenefitApplicationToProcess.isEmpty()) {
        update list_HIBenefitApplicationToProcess;
      }
  
      if (blnHassToSkipTrigger) {
        Boolean blnHISkipTriggerFlag = HICarrierVersionDetailTriggerHandler.blnSkipTrigger;
        HICarrierVersionDetailTriggerHandler.blnSkipTrigger = true;
        if (!list_HIBenefitApplicationToDelete.isEmpty()) {
          delete list_HIBenefitApplicationToDelete;
        }
  
        if (!list_HIBenefitApplicationToUpdate.isEmpty()) {
          update list_HIBenefitApplicationToUpdate;
        }
        HIBenefitApplicationUserTriggerHelper.skipTrigger = blnHISkipTriggerFlag;
      }
    }
  
    public void finish(Database.BatchableContext objBatchContext) {
      AsyncApexJob objAsyncJob = [
        SELECT Id, Status, NumberOfErrors, TotalJobItems
        FROM AsyncApexJob
        WHERE Id = :objBatchContext.getJobId()
      ];
      Utils.processBatchFinish(
        objAsyncJob,
        'HIBenefitApplicationUserBatch',
        false
      );
    }
  }