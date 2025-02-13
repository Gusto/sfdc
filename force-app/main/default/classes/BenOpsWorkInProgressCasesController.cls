public with sharing class BenOpsWorkInProgressCasesController {
    public class BenOpsWorkInProgressCaseResponse {

        @AuraEnabled
        public List<Case> list_Cases;

        @AuraEnabled
        public Boolean blnIsSuccess;

        @AuraEnabled
        public String strMessage;

        @AuraEnabled
        public Case objCase;

        public BenOpsWorkInProgressCaseResponse(List<Case> list_Cases, Case objCase, Boolean blnIsSuccess, String strMessage) {
            this.list_Cases = list_Cases;
            this.objCase = objCase;
            this.blnIsSuccess = blnIsSuccess;
            this.strMessage = strMessage;
        }
    }
	// This method returns similar work in progress cases for caseId's contact
    @AuraEnabled
    public static BenOpsWorkInProgressCaseResponse returnBenOpsWorkInProgressCases(Id idCase) {
		
        // Check if the call comes from LiveChatTranscript page or Chat Page
        // If LiveChatTranscript, fetch parent case
        String strObjectType = idCase.getSObjectType().getDescribe().getName();
        if(strObjectType.equals('LiveChatTranscript')) {
            idCase = [Select Id, CaseId from LiveChatTranscript Where Id = :idCase].CaseId;
        }
        
        Id idNpUservey = null;
        // list of benOps work in progress cases to return
        List<Case> list_Cases = new List<Case>();

        List<String> list_RecordTypeName = new List<String>{'Benefits BoR', 'Benefits BoR - NHE', 'Benefits BoR - QLE', 'Benefits BoR - Termination', 
                                           'Benefits Change Case', 'Benefits Compliance', 'Benefits Compliance - Read Only', 'Benefits New Plan Case',
                                           'Benefits Renewal Case', 'Member Fulfillment Emails', 'MF Audit', 'MF Member/Group Updates', 'MF NHE', 
                                           'MF QLE', 'MF Termination', 'MF Viking Master'};

        Case objCase = new Case();
        try {
            List<Case> list_ExistingCases = [
                    SELECT
                      Id,
                      ContactId,
                      RecordTypeId,
                      Record_Type_Name__c,
                      Contact.Name
                    FROM
                      Case
                    WHERE
                      Id = :idCase
            ];

            if (!list_ExistingCases.isEmpty()) {
                objCase = list_ExistingCases[0];

                for (Case objCaseRec : [SELECT Id,
                                        Subject, 
                                        OwnerId, 
                                        Owner.Name,
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
                                    WHERE ContactId = :objCase.ContactId
                                    AND RecordTypeId = :objCase.RecordTypeId
                                    AND Id != :objCase.Id
                                    AND Owner.Type = 'User'
                                    AND Status != 'Closed'
                                    AND Status != 'Solved'
                                    AND RecordType.Name IN :list_RecordTypeName]) {
                                        list_Cases.add(objCaseRec);
                }
            }
        } catch(Exception objException) {
            ExceptionLogUtil.logException('BenOpsWorkInProgressCasesController', 'returnBenOpsWorkInProgressCases', objException.getMessage(), objException.getStackTraceString());
            return new BenOpsWorkInProgressCaseResponse(null, objCase, false, objException.getMessage());
        }

        return new BenOpsWorkInProgressCaseResponse(list_Cases, objCase, true, null);
    }
}