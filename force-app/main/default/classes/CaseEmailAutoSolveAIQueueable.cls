/**
 * @name         CaseEmailAutoSolveAIQueueable
 * @author       Sahil Goyal
 * @date         11/13/2024
 * @description	 Queueable class for Gusto Internal AI API Callouts (Email Auto-Solve)
 **/
public class CaseEmailAutoSolveAIQueueable implements Queueable, Database.AllowsCallouts {
    private Id caseId;
    //Get default settings from custom settings
    private Chima_AI_Config__c objConfig = Chima_AI_Config__c.getOrgDefaults();

    // Constructor
    public CaseEmailAutoSolveAIQueueable(Id caseId) {
            this.caseId = caseId;
    }

    // Execute method
    public void execute(QueueableContext context) {
            try {
                    Case caseRecord = getCaseDetails(caseId);
                    InternalAISolveEmailConversation__c emailConversation = new InternalAISolveEmailConversation__c();
                    if (caseRecord == null) {
                            ExceptionLogUtil.logException('CaseEmailAutoSolveAIQueueable', 'Queueable_ExecuteMethod', 'Case not found for ID: ' + caseId, '');
                            return;
                    }

                    HttpRequest request = createHttpRequest(caseRecord);
                    HttpResponse response = sendHttpRequest(request);
                    //System.debug('===============' + response.getBody());

                    if (response != null && response.getStatusCode() == 200) {
                        emailConversation = createInternalAISolveEmailConversation(response.getBody(), caseRecord.Id);
                        if(emailConversation!=null && emailConversation.Return_Response__c && emailConversation.Valid_Request__c == CaseUtils.INTERNAL_VALID_REQUEST){
                                updateSolveStatusOnCase(caseRecord.Id, 'Yes', CaseUtils.AUTO_SOLVE_STATUS_ELIGIBLE);
                        } else {
                                updateSolveStatusOnCase(caseRecord.Id, 'Yes',CaseUtils.AUTO_SOLVE_STATUS_INELIGIBLE);
                        }
                    } else {
                            ExceptionLogUtil.logException(
                                    'CaseEmailAutoSolveAIQueueable',
                                    'Queueable_ExecuteMethod',
                                    'Failed to get a valid response. Case ID: ' + caseId + ' Status Code: ' + response.getStatusCode(),
                                    'Response Body: ' + response.getBody()
                            );
                            updateSolveStatusOnCase(caseRecord.Id, 'No',caseUtils.AUTO_SOLVE_STATUS_INELIGIBLE);
                            //System.debug('Failed to get a valid response. Status Code: ' +  response.getStatusCode());
                    }
            } catch (Exception e) {
                    ExceptionLogUtil.logException('CaseEmailAutoSolveAIQueueable', 'Queueable_ExecuteMethod', caseId, e);
                    updateSolveStatusOnCase(caseId, 'No',caseUtils.AUTO_SOLVE_STATUS_INELIGIBLE);
            }
    }

    // Fetch Case details
    private Case getCaseDetails(Id caseId) {
            return [SELECT Id, Subject, Description, CreatedDate FROM Case WHERE Id = :caseId];
    }

    // Create HTTP request
    private HttpRequest createHttpRequest(Case caseRecord) {
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setEndpoint(objConfig.Mulesoft_AI_Email_AutoSolve_Endpoint__c);
            request.setHeader('Authorization', 'Basic ' + objConfig.Mulesoft_Authorization__c);
            request.setHeader('Content-Type', 'application/json');

            // Set request body
            request.setBody(JSON.serialize(new RequestWrapper(caseRecord)));
            return request;
    }

    // Send HTTP request
    private HttpResponse sendHttpRequest(HttpRequest request) {
            try {
                    Http http = new Http();
                    return http.send(request);
            } catch (CalloutException expt) {
                    ExceptionLogUtil.logException('CaseEmailAutoSolveAIQueueable', 'sendHttpRequest', caseId, expt);
                    return null;
            }
    }

    // Deserialize response and dynamically create record
    private InternalAISolveEmailConversation__c createInternalAISolveEmailConversation(String responseBody, Id caseId) {
            try {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

                    InternalAISolveEmailConversation__c emailConversation = new InternalAISolveEmailConversation__c();
                    emailConversation.Case__c = caseId;

                    // Define the mapping between API response keys and Salesforce field API names
                    Map<String, String> fieldMapping = getAPIResponseSFMapping();

                    Schema.SObjectType objectType = InternalAISolveEmailConversation__c.SObjectType;
                    Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();

                    for (String key : responseMap.keySet()) {
                            if (fieldMapping.containsKey(key)) {
                                    String salesforceField = fieldMapping.get(key);
                                    if (fieldsMap.containsKey(salesforceField)) {
                                            Object value = responseMap.get(key);
                                            if (value != null) {
                                                    if (fieldsMap.get(salesforceField).getDescribe().getType() == Schema.DisplayType.MULTIPICKLIST && value instanceof List<Object>) {
                                                            List<String> stringValues = (List<String>) value;
                                                            emailConversation.put(salesforceField, String.join(stringValues, ';'));
                                                    } else if (
                                                            fieldsMap.get(salesforceField).getDescribe().getType() == Schema.DisplayType.STRING ||
                                                            fieldsMap.get(salesforceField).getDescribe().getType() == Schema.DisplayType.TEXTAREA
                                                    ) {
                                                            emailConversation.put(salesforceField, String.valueOf(value));
                                                    } else {
                                                            emailConversation.put(salesforceField, value);
                                                    }
                                            }
                                    }
                            }
                    }
                    insert emailConversation;
                    return emailConversation;
            } catch (Exception e) {
                    ExceptionLogUtil.logException('CaseEmailAutoSolveAIQueueable', 'createInternalAISolveEmailConversation', caseId, e);
                    return null;
            }
    }

    //For now, we will keep it static
    private Map<String, String> getAPIResponseSFMapping() {
            Map<String, String> fieldMapping = new Map<String, String>{
                    'case_id' => 'Case__c',
                    'avg_questions_similarities' => 'Avg_Questions_Similarities__c',
                    'contact_classification' => 'Contact_Classification__c',
                    'contact_classification_explanation' => 'Contact_Classification_Explanation__c',
                    'creation_timestamp' => 'Creation_Timestamp__c',
                    'first_user_email' => 'First_User_Email__c',
                    'max_questions_similarities' => 'Max_Questions_Similarities__c',
                    'request_summary' => 'Request_Summary__c',
                    'response' => 'Response__c',
                    'response_confidence' => 'Response_Confidence__c',
                    'response_explanation' => 'Response_Explanation__c',
                    'response_perplexity_score' => 'Response_Perplexity_Score__c',
                    'return_response' => 'Return_Response__c',
                    'selected_recipes' => 'Selected_Recipes__c',
                    'specific_intent' => 'Specific_Intent__c',
                    'use_case' => 'Use_Case__c',
                    'use_macro' => 'Use_Macro__c',
                    'valid_request' => 'Valid_Request__c',
                    'valid_request_explanation' => 'Valid_Request_Explanation__c',
                    'original_instructions' => 'Original_Instructions__c',
                    'original_instructions' => 'Original_Instructions__c',
                    'missing_context' => 'Missing_Context__c',
                    'auto_send' => 'Auto_Send___c',
                    'quality_score' => 'Quality_Score__c',
                    'html_response' => 'HTML_Response__c'
            };

            return fieldMapping;
    }

    private void updateSolveStatusOnCase(Id idCase, String strStatus, String strEligibility) {
            try {
                    Case objCase = new Case(Id = idCase);
                    objCase.Internal_AI_Processed__c = strStatus;
                    if(strEligibility == CaseUtils.AUTO_SOLVE_STATUS_ELIGIBLE){
                        objCase.Auto_Solve_Status__c = strEligibility;
                    }
                    update objCase;
            } catch (Exception e) {
                    ExceptionLogUtil.logException('CaseEmailAutoSolveAIQueueable', 'updateSolveStatusOnCase', idCase, e);
            }
    }

    // Request Wrapper Class
    public class RequestWrapper {
            public String case_id;
            public String subject;
            public String text_body;
            public String created_date;

            public RequestWrapper(Case caseRecord) {
                    this.case_id = caseRecord.Id;
                    this.subject = caseRecord.Subject;
                    this.text_body = caseRecord.Description;
                    this.created_date = caseRecord.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
            }
    }
}