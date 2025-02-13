/**
* @Author       :   Pradeep Chary
* @CreatedDate  :   11/22/2022
* @Desc         :   Batch Job to process the duplicate case reasons classifications with the Original ones
* @TestClass    :   CleanUpCaseReasonsBatchTest
**/
public class CleanUpCaseReasonClassificationsBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    String strQuery;
    String strOriginalCaseReasonClassificationId;
    String strDuplicateCaseReasonClassificationId;
    String strCaseReasonClassificationAPIName;
    
    public CleanUpCaseReasonClassificationsBatch(
        String strOriginalCaseReasonClassificationId,
        String strDuplicateCaseReasonClassificationId,
        String strCaseReasonClassificationAPIName
    ) {
        this.strOriginalCaseReasonClassificationId = strOriginalCaseReasonClassificationId;
        this.strDuplicateCaseReasonClassificationId = strDuplicateCaseReasonClassificationId;
        this.strCaseReasonClassificationAPIName = strCaseReasonClassificationAPIName;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (String.isBlank(strQuery)) {
            strQuery = 'SELECT Id, ' + strCaseReasonClassificationAPIName + ' FROM Case ' + 
                'WHERE ' + strCaseReasonClassificationAPIName + ' = \'' + strDuplicateCaseReasonClassificationId + '\'' +
                'AND Status <> \'Closed\' AND (NOT RecordType.Name LIKE \'%Read Only\')';
        }
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> list_Cases) {
        List<Case> list_CasesToUpdate = new List<Case>();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = false;
        
        for (Case objCase : list_Cases) {
            objCase.put(strCaseReasonClassificationAPIName, strOriginalCaseReasonClassificationId);
            objCase.setOptions(dmo);
            list_CasesToUpdate.add(objCase);
        }
        
        try {
            if (!list_CasesToUpdate.isEmpty()) {
                CaseTriggerHelper.skipTrigger = true;
                update list_CasesToUpdate;
                CaseTriggerHelper.skipTrigger = false;
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('CleanUpCaseReasonClassificationsBatch', 'execute', null, objException);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        
    }
}