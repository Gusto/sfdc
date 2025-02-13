global with sharing class createOptyButtonsController_LEX {
   
    
@AuraEnabled
    public static String getAccountDetails(String idCase){
       String strAccountId;
       List<Case> lst_Case = [SELECT Id,AccountId FROM Case WHERE Id=:idCase];
        for(Case caseObj : lst_Case){
            strAccountId = caseObj.AccountId;
        }
        return strAccountId;
        
    }

}