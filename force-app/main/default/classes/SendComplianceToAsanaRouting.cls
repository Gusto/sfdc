/**
     * @description  The below Class is for Sending Tax_Compliance__c Record to Asana (External System)
     * @author       Sindhu
     * @date         06-10-2024 
     * @see          SendComplianceToAsanaRoutingTest, ComplianceAsanaUpdateResponse ,ComplianceAsanaIntegrationResponse
     **/
    public with sharing class SendComplianceToAsanaRouting implements Queueable, Database.AllowsCallouts {
    public Map<Id, Tax_Compliance__c> map_Compliance = new Map<Id, Tax_Compliance__c>();
    public Boolean blnIsInsert;
    // Default Constructor
    public SendComplianceToAsanaRouting() {
    }

    /**
     * @description Parameterized Constructor
     * @param       Collection of compliances needing callout
     **/
    public SendComplianceToAsanaRouting(Map<Id, Tax_Compliance__c> map_Compliance, Boolean blnInsert) {
        this.map_Compliance = map_Compliance;
        this.blnIsInsert = blnInsert;
    }

    /**
     * @description Request Wrapper used for sending JSON payload to Asana when an Salesforce case is created in sfdc.
     **/
    public class RequestWrapperInsert {
        public String case_id;
        public String compliance_id;
        public String assignee;
        public String status;
        public String subject;
        public String description;
        public String parent_task_id;
        public String agency_information;
        public String due_date;
        public String follow_up_date;
        public String eng_status;
        public String who_owns_this_initiative;
        public String tier;
        public String eng_due_date;
        public String in_app_content;
        public String customer_comms;
        public String help_center_ikb_link;
        public String cx_comms;
        public String impacted_change_type;
        public String system_impacted;
        public String frequency_of_update;
        public String epdd_dri;
        public String google_drive;
        public String classification_type;
        public String compliance_team_poc;
        public String project_id;
        public Double compliance_risk_score;
        public Double customer_count;
        public Boolean help_center_ikb_ready_to_publish;
        public Boolean knowledge_management_readiness;
        public String created_date;

        /**
         * @description Parameterized Constructor for callout request wrapper
         * @param       Tax_Compliance__c details to be sent in payload
         * @param       Case details to be sent in payload
         **/
        public RequestWrapperInsert(Tax_Compliance__c objCompliance, Case objCase, String projectId, String assigneeGid) {
            if (objCase != null && objCompliance != null && projectId !=null) {
                this.case_id = objCase.Id;
                this.compliance_id = objCompliance.Id;
                this.assignee =  assigneeGid;// Assigned like GID's of corresponding Users Name
                this.status = objCase.Status;
                this.subject = objCase.Subject;
                this.description = objCase.Description != null ? objCase.Description : '';
                this.parent_task_id = objCase.Batch_Id__c != null ? objCase.Batch_Id__c : '';
                this.agency_information = objCase.Agency_Information__r.Name != null ? objCase.Agency_Information__r.Name : '';
                this.compliance_risk_score = objCase.Compliance_Score__c;
                this.due_date = strFormatAsanaDate(objCompliance.Agency_Due_Date__c);
                this.follow_up_date = strFormatAsanaDate(objCompliance.Follow_up_Date__c);
                this.eng_status = objCompliance.Eng_Status__c != null ? objCompliance.Eng_Status__c : '';
                this.who_owns_this_initiative = objCompliance.Who_Owns_this_Initiative__c != null ? objCompliance.Who_Owns_this_Initiative__c : '';
                this.tier = objCompliance.Tier__c != null ? objCompliance.Tier__c : '';
                this.eng_due_date = strFormatAsanaDate(objCompliance.Eng_Due_Date__c);
                this.in_app_content = objCompliance.In_App_content__c != null ? objCompliance.In_App_content__c : '';
                this.customer_comms = objCompliance.Customer_Comms__c != null ? objCompliance.Customer_Comms__c : '';
                this.knowledge_management_readiness = objCompliance.Knowledge_Management_Readiness__c;
                this.help_center_ikb_link = objCompliance.Help_Center_IKB_Internal__c != null ? objCompliance.Help_Center_IKB_Internal__c : '';
                this.help_center_ikb_ready_to_publish = objCompliance.Help_Center_IKB_External__c;
                this.cx_comms = objCompliance.CX_Comms__c != null ? objCompliance.CX_Comms__c : '';
                this.impacted_change_type = objCompliance.Impacts__c != null ? objCompliance.Impacts__c : '';
                this.system_impacted = objCompliance.System_impacted__c != null ? objCompliance.System_impacted__c : '';
                this.frequency_of_update = objCompliance.Frequency_of_Update__c != null ? objCompliance.Frequency_of_Update__c : '';
                this.epdd_dri = objCompliance.EPDD_DRI__c != null ? objCompliance.EPDD_DRI__c : '';
                this.google_drive = objCompliance.Resource_Link__c != null ? objCompliance.Resource_Link__c : '';
                this.customer_count = objCompliance.Customer_Count__c; 
                this.classification_type = objCompliance.Classification_Type__c != null ? objCompliance.Classification_Type__c : '';
                this.compliance_team_poc = objCompliance.Compliance_Team_POC__c != null ? objCompliance.Compliance_Team_POC__c : '';
                this.project_id = projectId; // Assigned Project ID (default) for Asana Project Name - Gusto Compliance Watchlist RoadMap   
            	this.created_date= strFormatAsanaDate(Date.valueOf(objCase.CreatedDate));
            }
        }
    }

    /**
     * @description Request Wrapper used for sending JSON payload to Asana when an salesforce case is updated in sfdc 
     **/
    public class RequestWrapperUpdate {
        public String task_id;
        public String case_id;
        public String compliance_id;
        public String assignee;
        public String status;
        public String subject;
        public String description;
        public String agency_information;
        public String due_date;
        public String follow_up_date;
        public String eng_status;
        public String who_owns_this_initiative;
        public String tier;
        public String eng_due_date;
        public String in_app_content;
        public String customer_comms;
        public String help_center_ikb_link;
        public String cx_comms;
        public String impacted_change_type;
        public String system_impacted;
        public String frequency_of_update;
        public String epdd_dri;
        public String google_drive;
        public String classification_type;
        public String compliance_team_poc;
        public Double customer_count;
        public Double compliance_risk_score;
        public Boolean knowledge_management_readiness;
        public Boolean help_center_ikb_ready_to_publish;
        public String created_date;

        /**
         * @description Parameterized Constructor for callout request wrapper
         * @param       Tax_Compliance__c details to be sent in payload
         **/
        public RequestWrapperUpdate(Tax_Compliance__c objCompliance, Case objCase, String assigneeGid) {
            if (objCase != null && objCompliance != null && assigneeGid!= null) {
                this.task_id = objCase.Batch_Id__c;
                this.case_id = objCase.Id;
                this.compliance_id = objCompliance.Id; 
                this.assignee = assigneeGid; //Assigned like GID's of corresponding Users Name
                this.status = objCase.Status;
                this.subject = objCase.Subject;
                this.description = objCase.Description != null ? objCase.Description : '';
                this.agency_information = objCase.Agency_Information__r.Name != null ? objCase.Agency_Information__r.Name : '';
                this.compliance_risk_score = objCase.Compliance_Score__c;
                this.due_date = strFormatAsanaDate(objCompliance.Agency_Due_Date__c);
                this.follow_up_date = strFormatAsanaDate(objCompliance.Follow_up_Date__c);
                this.eng_status = objCompliance.Eng_Status__c != null ? objCompliance.Eng_Status__c : '';
                this.who_owns_this_initiative = objCompliance.Who_Owns_this_Initiative__c != null ? objCompliance.Who_Owns_this_Initiative__c : '';
                this.tier = objCompliance.Tier__c != null ? objCompliance.Tier__c : '';
                this.eng_due_date = strFormatAsanaDate(objCompliance.Eng_Due_Date__c);
                this.in_app_content = objCompliance.In_App_content__c != null ? objCompliance.In_App_content__c : '';
                this.customer_comms = objCompliance.Customer_Comms__c != null ? objCompliance.Customer_Comms__c : '';
                this.knowledge_management_readiness = objCompliance.Knowledge_Management_Readiness__c;
                this.help_center_ikb_link = objCompliance.Help_Center_IKB_Internal__c != null ? objCompliance.Help_Center_IKB_Internal__c : '';
                this.help_center_ikb_ready_to_publish = objCompliance.Help_Center_IKB_External__c;
                this.cx_comms = objCompliance.CX_Comms__c != null ? objCompliance.CX_Comms__c : '';
                this.impacted_change_type = objCompliance.Impacts__c != null ? objCompliance.Impacts__c : '';
                this.system_impacted = objCompliance.System_impacted__c != null ? objCompliance.System_impacted__c : '';
                this.frequency_of_update = objCompliance.Frequency_of_Update__c != null ? objCompliance.Frequency_of_Update__c : '';
                this.epdd_dri = objCompliance.EPDD_DRI__c != null ? objCompliance.EPDD_DRI__c : '';
                this.google_drive = objCompliance.Resource_Link__c != null ? objCompliance.Resource_Link__c : '';
                this.customer_count = objCompliance.Customer_Count__c;
                this.classification_type = objCompliance.Classification_Type__c != null ? objCompliance.Classification_Type__c : '';
                this.compliance_team_poc = objCompliance.Compliance_Team_POC__c != null ? objCompliance.Compliance_Team_POC__c : ''; 
            	this.created_date= strFormatAsanaDate(Date.valueOf(objCase.CreatedDate));
            }
        }
    }

    /**
     * @description Execute method of queueable interface as entry point of queued job.
     * @param       An instance of a queueable context
     * @return      N/A
     **/
    public void execute(QueueableContext context) {
        try {
            map_Compliance = doCallout(map_Compliance, blnIsInsert);
            if (!map_Compliance.isEmpty() && !Test.isRunningTest()) {
                //if triggered by batch and callouts are remaining, call immediately.
                if (!map_Compliance.isEmpty() && System.isBatch() && (Limits.getLimitCallouts() - Limits.getCallouts() > 0)) {
                        map_Compliance = doCallout(map_Compliance, blnIsInsert);
                    if (!map_Compliance.isEmpty()) {
                        //if callouts are remaining, log exception.
                        String strMessage = '*****SendComplianceToAsanaRouting - remaining callouts failed due to insufficient resources*****';
                        ExceptionLogUtil.logExceptionWithId(
                            'SendComplianceToAsanaRouting',
                            'doCallout',
                            strMessage,
                            null,
                            new Set<String>((List<String>) new List<Id>(map_Compliance.keySet()))
                        );
                    }
                } else if (!map_Compliance.isEmpty() && System.isBatch() && (Limits.getLimitCallouts() - Limits.getCallouts() == 0)) {
                    //if triggered by batch and callouts are remaining, log exception.
                    String strMessage = '*****SendComplianceToAsanaRouting - remaining callouts failed due to insufficient resources*****';
                    ExceptionLogUtil.logExceptionWithId(
                        'SendComplianceToAsanaRouting',
                        'doCallout',
                        strMessage,
                        null,
                        new Set<String>((List<String>) new List<Id>(map_Compliance.keySet()))
                    );
                }
                //if triggered synchronously OR callouts are remaining post immediate processing and queuable resource available, enqueue new job to handle callouts.
                if (!map_Compliance.isEmpty() && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0)) {
                    Id idQueueJobId = System.enqueueJob(new SendComplianceToAsanaRouting(map_Compliance, blnIsInsert));
                } // if callouts are remaining and queuable resource unavailable, log exception.
                else if (!map_Compliance.isEmpty() && (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() == 0)) {
                    String strMessage = '*****SendComplianceToAsanaRouting - remaining callouts failed due to insufficient resources*****';
                    ExceptionLogUtil.logExceptionWithId(
                        'SendComplianceToAsanaRouting',
                        'doCallout',
                        strMessage,
                        null,
                        new Set<String>((List<String>) new List<Id>(map_Compliance.keySet()))
                    );
                } 
            }  
            
        } catch (Exception objException) {
            ExceptionLogUtil.logException('SendComplianceToAsanaRouting', 'doCallout', objException.getMessage(), objException.getStackTraceString());
        }
    }

    /**
     * @description Utility method to make callouts to Asana system for case processing.
     * @param       Map of Tax_Compliance__c needing processing
     * @return      Remaining compliances that were not called out due to insufficient resources.
     **/
    public static Map<Id, Tax_Compliance__c> doCallout(Map<Id, Tax_Compliance__c> map_Compliance, Boolean blnIsCaseInsert) {
        
        Map<Id, Tax_Compliance__c> map_TaxComplianceRemaining = new Map<Id, Tax_Compliance__c>();
        Map<String, String> map_UserGid = new Map<String, String>();
        
        // Query custom metadata to get project ID
        Asana_Project_Detail__mdt objAsanaProjectDetail = Asana_Project_Detail__mdt.getInstance(Label.Tax_Compliance_Asana_Project_Name);
        String strProjectId = objAsanaProjectDetail != null && objAsanaProjectDetail.Project_ID__c != null ? objAsanaProjectDetail.Project_ID__c : null;
        // Query custom metadata to get user Gids
        for (Asana_User_Detail__mdt objAsanaUserDetail : Asana_User_Detail__mdt.getAll().values()) {
                map_UserGid.put(objAsanaUserDetail.User_Name__c, objAsanaUserDetail.Gid__c);
        }
                
        // If callouts available, perform callout. Else add to remaining list.
        for (Id idCompliance : map_Compliance.keySet()) {
            Tax_Compliance__c objCompliance = map_Compliance.get(idCompliance);
            Case objCase = objCompliance.Case__r;
            
            if (Limits.getLimitCallouts() > 0) {
                String strAssigneeGid = map_UserGid != null && map_UserGid.containsKey(objCase.Owner.Name) ? map_UserGid.get(objCase.Owner.Name) : null;
                HttpRequest objRequest = new HttpRequest();
                Http objHttp = new Http();
                HTTPResponse objResponse = new HTTPResponse();
                
                if (blnIsCaseInsert) {
                    RequestWrapperInsert objRequestContent = new RequestWrapperInsert(objCompliance, objCase, strProjectId, strAssigneeGid);
                    objRequest.setEndpoint('callout:Tax_Compliance_Routing_Mulesoft2Asana');
                    objRequest.setMethod('POST');
                    objRequest.setBody(JSON.serialize(objRequestContent));
                    objRequest.setHeader('Content-Type', 'application/json');
                    objRequest.setTimeout(120000);
                    objResponse = objHttp.send(objRequest);
                    ComplianceAsanaIntegrationResponse objResponseWrapper; 
                    if (objResponse.getStatusCode() == 200) {
                        objResponseWrapper = (ComplianceAsanaIntegrationResponse) JSON.deserialize(objResponse.getBody(), ComplianceAsanaIntegrationResponse.class);
                        objCompliance.Asana_Integration_Message__c = 'Successfully created in Asana!';
                        objCompliance.Asana_Integration_Status__c = objResponseWrapper.status;
                        objCompliance.Asana_Integration_Event_Id__c = objResponseWrapper.event_id;
                        objCase.Batch_Id__c = objResponseWrapper.Message.asana_task_id;
                        update objCompliance;
                        update objCase;
                    } 
                    else {
                        objResponseWrapper = (ComplianceAsanaIntegrationResponse) JSON.deserialize(objResponse.getBody(), ComplianceAsanaIntegrationResponse.class);
                        objCompliance.Asana_Integration_Status__c = objResponseWrapper.status;
                        objCompliance.Asana_Integration_Message__c = objResponseWrapper.error_message;
                        objCompliance.Asana_Integration_Event_Id__c = objResponseWrapper.event_id;
                        update objCompliance;
                    }
                    
                    } else {
                    RequestWrapperUpdate objRequestContent = new RequestWrapperUpdate(objCompliance, objCase, strAssigneeGid);
                    objRequest.setEndpoint(String.format('callout:Tax_Compliance_Routing_Mulesoft2Asana/{0}',new String[]{objCase.Batch_Id__c}));
                    objRequest.setMethod('PATCH');
                    objRequest.setBody(JSON.serialize(objRequestContent));
                    objRequest.setHeader('Content-Type', 'application/json');
                    objRequest.setTimeout(120000);
                    objResponse = objHttp.send(objRequest);
                    ComplianceAsanaUpdateResponse objResponseUpdateWrapper;   
                    if (objResponse.getStatusCode() == 200) {
                        objResponseUpdateWrapper = (ComplianceAsanaUpdateResponse) JSON.deserialize(objResponse.getBody(), ComplianceAsanaUpdateResponse.class);
                        objCompliance.Asana_Integration_Status__c = objResponseUpdateWrapper.status;
                        objCompliance.Asana_Integration_Event_Id__c = objResponseUpdateWrapper.event_id;
                        objCompliance.Asana_Integration_Message__c = objResponseUpdateWrapper.message;    
                        Update objCompliance;
                    } else {
                        // Handle error response
                        objResponseUpdateWrapper = (ComplianceAsanaUpdateResponse) JSON.deserialize(objResponse.getBody(), ComplianceAsanaUpdateResponse.class);
                        objCompliance.Asana_Integration_Status__c = objResponseUpdateWrapper.status;
                        objCompliance.Asana_Integration_Message__c = objResponseUpdateWrapper.error_message;
                        objCompliance.Asana_Integration_Event_Id__c = objResponseUpdateWrapper.event_id;
                        Update objCompliance;
                    }
                }
            } else {
                map_TaxComplianceRemaining.put(idCompliance, objCompliance);
            }
        }
        
        return map_TaxComplianceRemaining;
    }


    /**
     * @description Helper method to format date to Asana format (YYYY/MM/DD)
     * @param       dateVal - The date to be formatted
     * @return      Formatted date string
     **/
    private static String strFormatAsanaDate(Date dateVal) {
        if (dateVal != null) {
            return DateTime.newInstance(dateVal.year(),dateVal.month(),dateVal.day()).format('yyyy/MM/dd');
        }
        return '';
    }

}