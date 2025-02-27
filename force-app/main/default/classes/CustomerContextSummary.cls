public with sharing class CustomerContextSummary {
    public PromptRequest promptRequestInstance = new PromptRequest();
    private String namedCredentialEndpoint = '';
    private List<Id> accountIds = new List<Id>();

    // assuming bulk of SAME type of record
    public CustomerContextSummary(List<Id> accountIds, PromptRequest promptRequestInstance) {
       this.accountIds = accountIds;
       this.promptRequestInstance = promptRequestInstance;
        //getObjectApiName();
        //getRecords(); 
        //formatRequestBody();
        this.namedCredentialEndpoint = 'http://ai-chat-summary-api.us-w2.cloudhub.io/chat-summary';
    }

    public PromptResponse getCutomerSummary() {
        // create request 
        System.debug('JSON.serializePretty(this.promptRequestInstance)'+ JSON.serializePretty(this.promptRequestInstance));
        String methodName = 'chat-summary';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(this.namedCredentialEndpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        request.setBody(JSON.serializePretty(this.promptRequestInstance));
        HttpResponse response;     
        try {
            response = http.send(request);
            System.debug('request' + request);
            System.debug('response' + response);
            if (response.getStatusCode() == 200) {
                PromptResponse promptResponseRecord = new promptResponse();
                String responseBody = response.getBody();
                promptResponseRecord = (PromptResponse)JSON.deserialize(responseBody, PromptResponse.class);
                System.debug('promptResponseRecord'+ JSON.serializePretty(promptResponseRecord));
                return promptResponseRecord;
            } 
        } catch (Exception postException) {
            System.debug(postException.getMessage());
            createLog(methodName, postException);
        }
        return null;
    }

    private void createLog(String methodName, Exception thisException){
        String className = CustomerContextSummary.class.getName();
        //ExceptionLogUtil.logException(className, methodName, this.workItemIdList[0], thisException);
    } 
    
    
    public class PromptRequest {
        @AuraEnabled public List<ContextInformation> body {get;set;}
    }

    public class ContextInformation {
        @AuraEnabled public String role {get;set;}
        @AuraEnabled public String content {get;set;}

        public void setContextInformation(String role, String content) {
            this.role = role;
            this.content = content;
        }
    }
    public class PromptResponse {
        @AuraEnabled public String ai_summary {get;set;}
    }

    private void getRecords() {
        try{

            List<Account> accountList = new List<Account>();
            accountList = [SELECT Type, Tier__c, States__c, Previous_Tier__c, Open_Cases__c, Number_of_Active_Employees__c, Medical_Renewal_Date__c, Days_Since_Last_Upsell_Conversation__c, Date_of_Last_Upsell_Conversation__c, 
                Customer_Health_Score__c, Competitor__c, Churn_Risk__c, Brokerage__c, Benefits_State__c, Benefits_401k__c, Average_Salary__c, Name, Benefits_Notes__c, CX_Company_Notes__c, Id, 
                Number_Of_Won_Benefits_Renewal_Opps__c, Number_Of_Won_Benefits_New_Plan_Opps__c, Number_Of_Won_Benefits_BoR_Opps__c, Number_of_Open_Benefits_Renewal_Opps__c, Number_of_Open_Benefits_New_Plan_Opps__c, 
                Number_of_Open_Benefits_Change_Opps__c, Number_of_Open_Benefits_BoR_Opps__c, No_of_EE_with_Active_Benefits__c,
                    (SELECT Subject, Description, Customer_Intent__c, Confirm_Case_Reason__c, 
                        Action_Correction_Needed__c, Notes__c, Problem_Statement__c, CreatedDate,
                    (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QA_Issues__r),
                    (SELECT id, ParentId, FromAddress,ToAddress,Subject,TextBody,CreatedDate FROM EmailMessages)
                    FROM Cases WHERE Not (Reason like '%payroll%' and Reason like '%time tracking%' and Reason like '%verification%' and Reason like '%reports%' and Reason like '%inquiry%' and Reason like '%state notice%' and Reason like '%state tax setup%' and Type like '%payroll%' and Type like '%verification%' and Type like '%verification%' and Type LIKE '%inquiry%' and Type LIKE '%state%')
                )
             FROM Account WHERE ID IN :this.accountIds];

            List<Opportunity> opportunityList = new List<Opportunity>();
            opportunityList = [SELECT Want_to_switch_brokers__c, Submission_Deadline__c, Stage_Detail__c, Stage_Detail_2__c, StageName, Special_Enrollment__c, Renewal_Date__c, 
                Recommended_Benefits__c, Priority_Reason__c, Outbound_PRE_Result__c, Outbound_PRE_Details__c, Outbound_PRE__c, Needs_Recertification__c, Experiment__c, Description, Benefits_Notes__c, Notes__c, Id, 
                RecordType.Name, CreatedDate, 
                (SELECT Type__c, 
                    Order_Fulfilled_Timestamp__c, Open_Enrollment_Start_Date__c, Open_Enrollment_End_Date__c, Follow_Up_Notes__c, Fulfilled_Before_Effective_Date__c, Blocked_Notes__c, Name, Id, Additional_Details__c, 
                    Action_Necessary_Notes__c, CreatedDate, 
                    (SELECT HI_Submission_Automation_Status__c, HI_Submission_Automation_Message__c, HI_Confirmation_Automation_Status__c, HI_Confirmation_Automation_Message__c, Follow_Up_Notes__c, Escalated_Reason__c, 
                        Escalated_Customer__c, Name, Id, Benefit_Types__c, Automation_Status__c, Automation_Message__c, Automation_Message_Details__c, 
                        Approval_Notes__c, Additional_Details__c, CreatedDate, 
                        (SELECT Time_to_Resolve__c, Time_to_Resolution__c, Escalation_Reason__c, Escalation_Reason_Detail__c, Ticket_Description__c, Summary__c, 
                            Sub_Error_Type__c,
                            Description__c, Error_Type__c, CreatedDate,
                            (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QC_Errors__r)
                            FROM Tickets__r
                        ),
                        (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QC_Errors__r)
                        FROM Carrier_Orders__r
                    ),
                    (SELECT Time_to_Resolve__c, Time_to_Resolution__c, Escalation_Reason__c, Escalation_Reason_Detail__c, Ticket_Description__c, Summary__c, 
                        Sub_Error_Type__c, 
                        Description__c, Error_Type__c, CreatedDate, 
                        (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QC_Errors__r)
                        FROM Tickets__r
                    ),
                    (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QC_Errors__r)
                    FROM Benefit_Orders__r
                    ), 
                    (SELECT Time_to_Resolve__c, Time_to_Resolution__c, Escalation_Reason__c, Escalation_Reason_Detail__c, Ticket_Description__c, Summary__c, 
                        Sub_Error_Type__c, 
                        Description__c, Error_Type__c, CreatedDate, 
                        (SELECT Summary__c, Error_Type__c, Error_Type_Detail__c, Description__c, CreatedDate FROM QC_Errors__r)
                        FROM Tickets__r
                    ) 
                FROM Opportunity WHERE RecordType.DeveloperName IN ('Benefits_Change', 'Benefits_Renewal', 'Benefits_New_Plan', 'Benefits_BYOB', 'Benefits_BoR') 
                AND AccountId IN :this.accountIds];
        }catch(Exception queryException){
            String methodName = 'getRecords';
            System.debug(queryException.getMessage());
            createLog(methodName, queryException);
        }
    }

    // // TODO: Adjust logic to handle multiple records in one payload
    // // I did not do this since current request must only have a single record
    // private void formatRequestBody(){
    //     Integer count = 0;
    //     for(sObject thisWorkItem : this.workItemList){
    //         String jsonKeyValuePair = '{';
    //         for(Work_Item_Summary__mdt workItemSetting : this.workItemSettingsList){
    //             String objectName = workItemSetting.Object__c;
    //             String fieldApiName = workItemSetting.Field_API_Name__c;
    //             String fieldValue = (String) thisWorkItem.get(fieldApiName);
    //             jsonKeyValuePair = jsonKeyValuePair + '"' + fieldApiName + '"' + ' : ' + '"' + fieldValue + '"' + ' , ';
    //         }
    //         Integer lastCommmaPosition = jsonKeyValuePair.lastIndexOf(',');
    //         jsonKeyValuePair = jsonKeyValuePair.subString(0, lastCommmaPosition);
    //         jsonKeyValuePair = jsonKeyValuePair + '}';
    //         this.requestBody = jsonKeyValuePair;
    //     }
    // }
}