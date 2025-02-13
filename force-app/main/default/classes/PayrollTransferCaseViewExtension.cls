public without sharing class PayrollTransferCaseViewExtension {
    public Case theCase {get; private set;}

    public PayrollTransferCaseViewExtension(ApexPages.StandardController controller) {
        theCase = (Case) controller.getRecord();
        theCase = [Select Id,RFI_Type__c, Termination_Date__c, AccountId, RFI_Status__c,Anticipated_Effective_Date__c,Submission_Method__c,Special_Instructions__c,Follow_Up_Date__c, carrier__r.Submission_Email__c, Contact.Email,Status,Status_Detail__c,Requires_Action__c,Carrier__c, Description from Case where Id=:theCase.id FOR UPDATE];
       
    }
    
    public pageReference SavePayrollTransferCase(){
        theCase.OwnerId=UserInfo.getUserId();
        Database.SaveResult result =  Database.update(theCase);
        if(result.success){
        	PageReference pgref = new PageReference('/apex/PayrollTransferCasePage?id='+theCase.id+'&refreshPage=true');
            return pgref;
        } else {
            apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR,Utils.ConsolidateErrors(result.errors)));
            return null;
        }
    }
}