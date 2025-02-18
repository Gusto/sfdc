/**
 * @author      	Soujanya Nentur
 * @description 	Batch class for updating owner on Engagement closed cases				
 * @see		        AutoUpdateEngagementClosedCasesTest		
 **/
public class AutoUpdateEngagementClosedCases implements Database.Batchable<sObject>, Schedulable{
    public static final String PAYROLL_CARE_NON_ACTIONABLE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Payroll_Care_Non_Actionable');
    public static final String ENGAGEMENT_CASES_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Engagement_Cases');

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String StrCaseStatus = CaseUtils.STATUS_CLOSED;
        String StrEngagementRecordType = CaseUtils.RECTYPE_ENGAGEMENT;
        String strAutoUpdateEngagementQuery = 'SELECT Id, RecordTypeId, OwnerId, Status ' +
                                       'FROM Case ' +
            			       'WHERE Status =  \'' + StrCaseStatus + '\'' +
            			       'AND RecordTypeId = \'' + StrEngagementRecordType + '\'' +
            		               'AND OwnerId = \'' + ENGAGEMENT_CASES_QUEUE_ID + '\' ';
        return Database.getQueryLocator(strAutoUpdateEngagementQuery);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        try {
            List<String> list_ConsolidatedDMLErrors = new List<String>();
            List<Case> list_Cases = (List<Case>) scope;
            Map<Id, Case> map_UpdateCases = new Map<Id, Case>();

            for (Case objCase : list_Cases) {
                if (objCase.RecordTypeId != null) {
                    objCase.OwnerId = PAYROLL_CARE_NON_ACTIONABLE_QUEUE_ID;
                    map_UpdateCases.put(objCase.Id, objCase);
                }
            }

            if (!map_UpdateCases.isEmpty()) {
		List<Database.SaveResult> list_UpdateResults = Database.update(map_UpdateCases.values(), false);
		list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResults, 'Update'));
		}

            if (!list_ConsolidatedDMLErrors.isEmpty()) {
		//Create exception log when errors occur.
		ExceptionLogUtil.logException(UserInfo.getUserId(), 'AutoUpdateEngagementClosedCases', 'processDML', list_ConsolidatedDMLErrors, '');
		}
        } catch (Exception e) {
            ExceptionLogUtil.logException('AutoUpdateEngagementClosedCases', 'execute', e);
        }
    }

    public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
		if (objAsyncJob.NumberOfErrors > 0) {
		Utils.processBatchFinish(objAsyncJob, '', false);
		}
	}

	public void execute(SchedulableContext sc) {
		Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
		Integer intBatch = objConfigSettings?.AutoUpdateEngagementClosedCasesBatchSize__c != null ? (Integer) objConfigSettings.AutoUpdateEngagementClosedCasesBatchSize__c : 20;
		Database.executeBatch(new AutoUpdateEngagementClosedCases(), intBatch);
	}
}