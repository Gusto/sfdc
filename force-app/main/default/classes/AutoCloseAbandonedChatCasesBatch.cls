/**
 * @Author       :   Pradeep Chary
 * @CreatedDate  :   02/08/2024
 * @Desc         :   Auto Close Abandoned Chat Origin Cases
 * @TestClass    :   AutoCloseAbandonedChatCasesBatchTest
**/
public class AutoCloseAbandonedChatCasesBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Set<String> set_OwnerIds = new Set<String>();
    public Set<String> set_RecordTypeIds = new Set<String>();
    public Set<String> set_Statuses = new Set<String>();

    public AutoCloseAbandonedChatCasesBatch(Set<String> set_OwnerIds, Set<String> set_RecordTypeIds, Set<String> set_Statuses) {
        this.set_OwnerIds = set_OwnerIds;
        this.set_RecordTypeIds = set_RecordTypeIds;
        this.set_Statuses = set_Statuses;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strOriginChat = CaseUtils.ORIGIN_CHAT;
        String strOriginGusto = CaseUtils.ORIGIN_GUSTO;
        
        String strQuery = 'SELECT Id, OwnerId, Status, BusinessHoursId FROM Case WHERE ';
        if (!set_OwnerIds.isEmpty()) {
            strQuery = strQuery + 'OwnerId IN :set_OwnerIds AND ';
        }
        strQuery = strQuery + 'RecordTypeId IN :set_RecordTypeIds ' +
            'AND (Origin = :strOriginChat ' +
            'OR (Origin = :strOriginGusto AND Channel__c = :strOriginChat)) ' +
            'AND Status IN :set_Statuses ';// +
           // 'AND CreatedDate <= N_DAYS_AGO:3';
        
        return Database.getQueryLocator(strQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> list_Cases) {
        List<Case> list_CasesToUpdate = new List<Case>();
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_UserIds = new Set<Id>();
        Map<Id, LiveChatTranscript> caseIdToTranscriptMap = new Map<Id, LiveChatTranscript>();
        
        for (Case objCase : list_Cases) {
            set_CaseIds.add(objCase.Id);
        }
        
        for (LiveChatTranscript objChatTranscript : [
            SELECT Id, OwnerId, CaseId, Status, StartTime 
            FROM LiveChatTranscript 
            WHERE CaseId IN :set_CaseIds
            AND OwnerId NOT IN :set_OwnerIds 
            ORDER BY CreatedDate DESC
        ]) {
            if (!caseIdToTranscriptMap.containsKey(objChatTranscript.CaseId)) {
                set_UserIds.add(objChatTranscript.OwnerId);
                caseIdToTranscriptMap.put(objChatTranscript.CaseId, objChatTranscript);
            }
        }
        
        Map<Id, User> map_UserById = GlobalQueryHelper.getUsersByIdMap(set_UserIds);
        
        for (Case objCase : list_Cases) {
            if (caseIdToTranscriptMap.containsKey(objCase.Id) && map_UserById.containsKey( caseIdToTranscriptMap.get(objCase.Id).OwnerId )) {
                objCase.OwnerId = caseIdToTranscriptMap.get(objCase.Id).OwnerId;
                
                // Close the case immeidately if chat is missed by agent or visitor left before it started
                if(caseIdToTranscriptMap.get(objCase.Id).Status == Utils.CHAT_STATUS_MISSED 
                   && caseIdToTranscriptMap.get(objCase.Id).StartTime == NULL) {
                        objCase.Status = CaseUtils.STATUS_CLOSED;
                   } else {
                        // Updating the Auto_Close_Date_Time__c field on the remaining cases.
                        // The AutoUpdateCaseStatusBatch job, which runs every hour, will handle closing these cases.
                        setAutoCloseDateTime(objCase);
                   }
                
            } else {
                objCase.Status = CaseUtils.STATUS_CLOSED;
            }
            
            list_CasesToUpdate.add(objCase);
        }
        
        try {
            if (!list_CasesToUpdate.isEmpty()) {
                update list_CasesToUpdate;
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('AutoCloseAbandonedChatCasesBatch', 'execute', objException.getMessage(), objException.getStackTraceString());
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
    
    //Description: Calculating Auto-Close Datetime
    public static void setAutoCloseDateTime(Case objCase) {
        if (objCase.BusinessHoursId != null) {
            Integer intClosureDays = (Label.EngagementAutoCloseDays != null) ? Integer.valueOf(Label.EngagementAutoCloseDays) : 2;
            objCase.Auto_Close_Date_Time__c = BusinessHours.add(objCase.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * intClosureDays);
        }
    }
}