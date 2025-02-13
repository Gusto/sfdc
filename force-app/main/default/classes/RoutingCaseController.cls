/*
    Description: This class contains functions related to Case Detail Play - a feature
    used by captains and PEs to route cases.
    Author: Praveen Sethu
    Date: 09/16/2020
*/
public with sharing class RoutingCaseController {
 
    public class CaseDetailPlayRoutingWrapper {
        
        @AuraEnabled public List<Case> list_CasesToBeRouted;
        @AuraEnabled public String strMessage;
        @AuraEnabled public Boolean blnIsSuccess;
        @AuraEnabled public Boolean blnIsSkip;
        
        public CaseDetailPlayRoutingWrapper(
            List<Case> list_CasesToBeRouted, 
            String strMessage, 
            Boolean blnIsSuccess,
            Boolean blnIsSkip
        ) {
            this.list_CasesToBeRouted = list_CasesToBeRouted;
            this.strMessage = strMessage;
            this.blnIsSuccess = blnIsSuccess;
            this.blnIsSkip = blnIsSkip;
        }
    }
    
    // Fetching Related Cases to a particular Queue
    @AuraEnabled
    public static CaseDetailPlayRoutingWrapper fetchCasesRelatedToQueue(String strQueueName){
        try {
            // SOQL to fetch number of cases
            List<Case> list_CasesToBeRouted = [SELECT Id, CaseNumber FROM Case WHERE Owner.Name = :strQueueName];
            // Return back with blnIsSuccess to be true
            return new CaseDetailPlayRoutingWrapper(list_CasesToBeRouted, null, true, false);
        } catch(Exception objException){
            // In case of an exception, log them
            ExceptionLogUtil.logException('RoutingCaseController', 'fetchCasesRelatedToQueue', objException.getMessage(), objException.getStackTraceString());
            return new CaseDetailPlayRoutingWrapper(null, objException.getMessage(), false, false);
        }
    }
    
    // Update Case_In_Route__c flg
    @AuraEnabled
    public static CaseDetailPlayRoutingWrapper updateCaseInRoute(Case objCase, Boolean isRoute, Case objPreviousCase) {
        List<Case> list_CasesToUpdate = new List<Case>();
        try {
            // If Case in Route is TRUE, skip the case
            Boolean blnIsSkip = false;
            // Fetch case record
            List<Case> list_Cases = [SELECT Id, Case_In_Route__c FROM Case WHERE Id = :objCase.Id];
            // maintaining unique Ids
            Set<Id> set_CaseIds = new Set<Id>();

            // create a list of cases to be updated
            if (!list_Cases.isEmpty()) {
                Case objCaseToUpdate = list_Cases.get(0);
                if (objCaseToUpdate.Case_In_Route__c != isRoute) {
                    objCase.Case_In_Route__c = isRoute;
                    set_CaseIds.add(objCase.Id);
                    list_CasesToUpdate.add(objCase);
                } else {
                    blnIsSkip = true;
                }
            }
            // Check if there is a previous case. Set Case In Route to False
            if (String.isNotBlank(objPreviousCase.Id) && !blnIsSkip && !set_CaseIds.contains(objPreviousCase.Id)) {
                objPreviousCase.Case_In_Route__c = false;
                list_CasesToUpdate.add(objPreviousCase);
            }
            // Update cases and skip Trigger
            if (!list_CasesToUpdate.isEmpty()) {
                Boolean caseTriggerSkipFlag = CaseTriggerHelper.skipTrigger;
                CaseTriggerHelper.skipTrigger = true;
                update list_CasesToUpdate;
                CaseTriggerHelper.skipTrigger = caseTriggerSkipFlag;
            }
            // No exceptions, send with blnIsSuccess = true
            return new CaseDetailPlayRoutingWrapper(null, null, true, blnIsSkip);
        } catch (Exception objException) {
            //If exception occurs make another attempt to update the records
            CaseTriggerHelper.skipTrigger = true;
            update list_CasesToUpdate;
            CaseTriggerHelper.skipTrigger = false;
            // In case of an exception, log them
            ExceptionLogUtil.logException('RoutingCaseController', 'updateCaseInRoute', objException.getMessage(), objException.getStackTraceString());
            return new CaseDetailPlayRoutingWrapper(null, objException.getMessage(), false, false);
        }
    }
    
    /**
     * Author: Alex
     * Date: 11/17/2020
     * Desc: does the current user have permission to see the QA Play component
     */
    @AuraEnabled
    public static TabPermissions getTabVisibilityPermissions(){
        TabPermissions objTabPermissions = new TabPermissions();
        List<String> list_QAPlayPSA = Label.Engagement_QA_Play_Permission_Sets.replace(' ', '').split(',');
        Boolean blnHasCaseDetailPlayAccess = Utils.checkTabAccessGeneric(Utils.ENGAGEMENT_CASE_ROUTING_GROUP);
        //check for QA permission
        List<PermissionSetAssignment> list_QAPlayAssignment = GlobalQueryHelper.getPermSetAssignments(list_QAPlayPSA);
        
        if (blnHasCaseDetailPlayAccess) {
            objTabPermissions.blnCaseDetailPlayPermission = true;
        }

        if (!list_QAPlayAssignment.isEmpty()) {
            objTabPermissions.blnQAPlayPermission = true;
        }
        return objTabPermissions;
    }

    public class TabPermissions {
        @AuraEnabled
        public Boolean blnQAPlayPermission { get; set; }
        
        @AuraEnabled
        public Boolean blnCaseDetailPlayPermission { get; set; }
        
        public TabPermissions() {
            this.blnQAPlayPermission = false;
            this.blnCaseDetailPlayPermission = false;
        }
    }
}