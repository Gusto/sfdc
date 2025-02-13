public with sharing class ViewFullCaseController {
    
    @AuraEnabled
    public static Boolean updateCaseInRoute(Id idCase) {
        try {
            Case objCase = new Case(Id = idCase);
            objCase.Case_In_Route__c = false;
            update objCase;
            return true;
        } catch(Exception objException) {
            ExceptionLogUtil.logException('ViewFullCaseController', 'updateCaseInRoute', objException.getMessage(), objException.getStackTraceString());
            return false;
        }
    }
}