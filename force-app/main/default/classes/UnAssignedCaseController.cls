public with sharing class UnAssignedCaseController {
    public class UnAssignedCaseResponse {
        @AuraEnabled
        public List<Case> list_Cases;

        @AuraEnabled
        public Boolean blnIsSuccess;

        @AuraEnabled
        public String strMessage;

        @AuraEnabled
        public Case objCase;

        public UnAssignedCaseResponse(List<Case> list_Cases, Case objCase, Boolean blnIsSuccess, String strMessage) {
            this.list_Cases = list_Cases;
            this.objCase = objCase;
            this.blnIsSuccess = blnIsSuccess;
            this.strMessage = strMessage;
        }
    }
    // This method returns similar unassigned cases for caseId's contact
    @AuraEnabled
    public static UnAssignedCaseResponse returnUnAssignedCases(Id idCase) {
        // Check if the call comes from LiveChatTranscript page or Chat Page
        // If LiveChatTranscript, fetch parent case
        String strObjectType = idCase.getSObjectType().getDescribe().getName();
        if (strObjectType.equals('LiveChatTranscript')) {
            idCase = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :idCase].CaseId;
        }

        Id idNpUservey = null;
        // list of unassgined cases to return
        List<Case> list_Cases = new List<Case>();
        List<String> list_RecordTypeName = new List<String>{
            'Payroll Care',
            'Payroll Care - Read Only',
            'Benefits Care - Read Only',
            'Tax Res',
            'Tax Res - Read Only',
            'GEP CX',
            'Modern Bank',
            'Modern Bank - Read Only'
        };

        Case objCase = new Case();
        try {
            List<Case> list_ExistingCases = [
                SELECT Id, ContactId, RecordTypeId, Record_Type_Name__c, Contact.Name
                FROM Case
                WHERE Id = :idCase
            ];

            if (!list_ExistingCases.isEmpty()) {
                objCase = list_ExistingCases[0];

                List<String> list_GroupNames = new List<String>{
                    'Payroll Care - Non Actionable',
                    'Payroll Care - Auto Close',
                    'Phone Routing',
                    'Full-Stack Care - Non Actionable',
                    'NPS Survey Response',
                    'Mass Email Cases'
                };

                // Iterate over cases whose contactId is common
                if (objCase.ContactId != null) {
                    for (Case objCaseRec : [
                        SELECT
                            Id,
                            Subject,
                            OwnerId,
                            Owner.Username,
                            CreatedDate,
                            Total_Number_of_Touchpoints__c,
                            CaseNumber,
                            Class__c,
                            Classification_formula__c,
                            Status,
                            Origin,
                            Priority,
                            Record_Type_Name__c,
                            Routing_Case_Reason__c,
                            Type
                        FROM Case
                        WHERE
                            ContactId = :objCase.ContactId
                            AND Id != :objCase.Id
                            AND Owner.Type = 'Queue'
                            AND OwnerId != :idNpUservey
                            AND Owner.Name NOT IN :list_GroupNames
                            AND Status != 'Closed'
                            AND Status != 'Solved'
                            AND RecordType.Name IN :list_RecordTypeName
                            AND Origin != 'Phone'
                            AND Origin != 'Chat'
                        LIMIT 20
                    ]) {
                        list_Cases.add(objCaseRec);
                    }
                }
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException(
                'UnAssignedCaseController',
                'returnUnAssignedCases',
                objException.getMessage(),
                objException.getStackTraceString()
            );
            
            return new UnAssignedCaseResponse(null, objCase, false, objException.getMessage());
        }

        return new UnAssignedCaseResponse(list_Cases, objCase, true, null);
    }
}