public with sharing class MemberFulfillmentEscalationController {
    
    public Case selectedCaseRec{get;set;}
    public boolean caseInsertSuccessfully{get;set;}
    public boolean transferExistingCase{get;set;}
    public boolean setEmployer{get;set;}
    public list<SelectOption> reasonList {get;private set;}
    public String reason{get;set;} 
        
    public MemberFulfillmentEscalationController(apexPages.StandardController sc){
        
        id caseId = sc.getId();
        selectedCaseRec = new Case();
        caseInsertSuccessfully = false;
        transferExistingCase = false;
        reason = 'None';
        setReasonOptions();
        
        if(caseId != null && string.valueof(caseId).length()>0){
            setCaseInfo(caseId);
        }
        
        if(selectedCaseRec.id == null){
            apexPages.addMessage(new apexPages.Message(apexPages.severity.error,'Invalid url.'));
        }
    }
    
    private void setCaseInfo(String caseId) {
        selectedCaseRec = [SELECT Id,
                           Subject,
                           Description,
                           AccountId,
                           Account.Name,
                           CaseNumber,
                           ContactId,
                           Contact.Name
                           FROM Case
                           WHERE Id = :caseId
                           LIMIT 1];
    }
    
    public void setReasonOptions() {
        reasonList = new List<SelectOption>();
        reasonList.add(new SelectOption('None', 'None'));
        reasonList.add(new SelectOption('BenCare-Benefits Reversal', 'BenCare-Benefits Reversal'));
    }
    
    public void setSubjectAndDescription() {
        List<EmailTemplate> list_Templates = new List<EmailTemplate>([SELECT Id, Subject, Body FROM EmailTemplate WHERE Name = :reason]);
        if (!list_Templates.isEmpty()) {
            selectedCaseRec.Subject = list_Templates[0].Subject;
            selectedCaseRec.Subject += ' - ' + selectedCaseRec.Contact.Name;
            selectedCaseRec.Description = list_Templates[0].Body;
        }
        setEmployer = true;
    }
    
    public void createNewCase() {
        if (reason == 'None') {
            return;
        }
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;

        Case objCase = new Case();
        objCase.Subject = selectedCaseRec.Subject;
        objCase.Description = selectedCaseRec.Description;
        objCase.AccountId = selectedCaseRec.AccountId;
        if (setEmployer == false) {
            objCase.ContactId = selectedCaseRec.ContactId;
        }
        objCase.Status = CaseUtils.STATUS_OPEN;
        objCase.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
        objCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;
        objCase.Support_Level__c = CaseUtils.TIER_2;
        objCase.Answer_IQ_Eligible__c = false;
        objCase.Routing_Case_Reason__c = CaseUtils.BENEFIT_REVERSAL_CASE_REASON;
        objCase.Confirm_Case_Reason__c = CaseUtils.BENEFIT_REVERSAL_CASE_REASON;
        objCase.setOptions(dmo);
        try {
            insert objCase;

            selectedCaseRec = [SELECT Id, CaseNumber FROM Case WHERE Id = :objCase.Id LIMIT 1];
        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, ex.getMessage()));
            return;
        }

        caseInsertSuccessfully = true;
    }
}