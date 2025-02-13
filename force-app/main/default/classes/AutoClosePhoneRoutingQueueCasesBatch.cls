/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   03/27/2023
 * @Desc         :   Engagement - Phone Routing Queue Case Updates
 * @TestClass    :   AutoClosePhoneRoutingQueueCasesBatchTest
**/
public class AutoClosePhoneRoutingQueueCasesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public AutoClosePhoneRoutingQueueCasesBatch() {}
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strBenefitsCareRecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Care');
        String strPayrollCareRecordTypeId = Cache.getRecordTypeId('Case', 'Payroll Care');
        String strPhoneRoutingQueueId = GlobalQueryHelper.getQueueIdByDevName('Phone_Routing');
        
        String strQuery = 'SELECT Id, Send_Survey__c, Status FROM Case ' +
            'WHERE (RecordTypeId = :strBenefitsCareRecordTypeId ' +
            'OR RecordTypeId = :strPayrollCareRecordTypeId) ' +
            'AND OwnerId = :strPhoneRoutingQueueId ' +
            'AND Status <> \'Closed\' ' +
            'AND CreatedDate <= N_DAYS_AGO:3';
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> list_Cases) {
        List<Case> list_CasesToUpdate = new List<Case>();
        
        for (Case objCase : list_Cases) {
            objCase.Send_Survey__c = false;
            objCase.Status = CaseUtils.STATUS_CLOSED;
            list_CasesToUpdate.add(objCase);
        }
        
        try {
            if (!list_CasesToUpdate.isEmpty()) {
                update list_CasesToUpdate;
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('AutoClosePhoneRoutingQueueCasesBatch', 'execute', objException.getMessage(), objException.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
}