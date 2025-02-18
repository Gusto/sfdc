/**
 * @name         : MessagingSessionTriggerHelper
 * @author       : Pradeep Chary
 * @date         : 09-09-2024
 * @description  : Helper Class for trigger on Messaging Session object
 * @test classes : MessagingSessionTriggerHelperTest
**/
public class MessagingSessionTriggerHelper {
    public static Boolean skipTrigger = false;
    public static Map<String, Account> map_AccountByCompanyId = new Map<String, Account>();
    public static Map<String, Contact> map_ContactByVisitorEmail = new Map<String, Contact>();
    public static Map<String, Case_Reason_Classification__c> map_CaseReasonByReasonCode = new Map<String, Case_Reason_Classification__c>();
    public static final String DEFAULT_CHAT_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Default_Chat_Routing_Queue');
    List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
    
    public void OnBeforeInsert(List<MessagingSession> list_MessagingSessions) {}
    
    public void OnAfterInsert(Map<Id, MessagingSession> map_MessagingSessionById) {}
    
    public void OnBeforeUpdate(Map<Id, MessagingSession> map_OldMessagingSessionById, Map<Id, MessagingSession> map_MessagingSessionById) {
        Map<Id, Id> map_OpportunityIdByAccountId = new Map<Id, Id>();
        Map<String, Id> map_LeadIdByVisitorEmail = new Map<String, Id>();
        Set<String> set_VisitorEmailAddresses = new Set<String>();
        Set<String> set_CompanyIds = new Set<String>();
        Set<String> set_CaseReasons = new Set<String>();
        
        for (MessagingSession objMessage : map_MessagingSessionById.values()) {
            MessagingSession objOldMessage = map_OldMessagingSessionById.get(objMessage.Id);
            if (String.isNotBlank(objMessage.Visitor_Email_Address__c) &&
                objMessage.Visitor_Email_Address__c != objOldMessage.Visitor_Email_Address__c) {
                    set_VisitorEmailAddresses.add(objMessage.Visitor_Email_Address__c);
                }
            if (String.isNotBlank(objMessage.Company_ID__c) &&
                objMessage.Company_ID__c != objOldMessage.Company_ID__c) {
                    set_CompanyIds.add(objMessage.Company_ID__c);
                }
            
            if (String.isNotBlank(objMessage.ORCA_Predicted_Case_Reason__c) &&
                objMessage.ORCA_Predicted_Case_Reason__c != objOldMessage.ORCA_Predicted_Case_Reason__c &&
                objMessage.ORCA_Predicted_Case_Reason__c != AgathaPredictionTriggerHelper.AGATHAPREDICTION_NOT_PREDICTED) {
                    set_CaseReasons.add(objMessage.ORCA_Predicted_Case_Reason__c);
                }
        }
        
        if (!set_CompanyIds.isEmpty()) {
            Set<Id> set_AccountIds = new Set<Id>();
            for (Account objAccount : queryAccounts(set_CompanyIds)) {
                map_AccountByCompanyId.put(objAccount.ZP_Company_ID__c, objAccount);
                set_AccountIds.add(objAccount.Id);
            }
            
            for (Opportunity objOpportunity : queryOpportunities(set_AccountIds)) {
                map_OpportunityIdByAccountId.put(objOpportunity.AccountId, objOpportunity.Id);
            }
        }
        
        if (!set_VisitorEmailAddresses.isEmpty()) {
            for (Lead objLead : queryLeads(set_VisitorEmailAddresses)) {
                map_LeadIdByVisitorEmail.put(objLead.Email, objLead.Id);
            }
            
            for (Contact objContact : queryContacts(set_VisitorEmailAddresses)) {
                map_ContactByVisitorEmail.put(objContact.Email, objContact);
            }
        }
        
        if (!set_CaseReasons.isEmpty()) {
            for (Case_Reason_Classification__c objCaseReason : queryCaseReasonClassifications(set_CaseReasons)) {
                map_CaseReasonByReasonCode.put(objCaseReason.Reason_Code__c.toLowerCase(), objCaseReason);
            }
        }
        
        for (MessagingSession objMessage : map_MessagingSessionById.values()) {
            if (String.isBlank(objMessage.RecordTypeId)) {
                objMessage.RecordTypeId = MessagingSessionUtils.RECTYPE_CUSTOMER_CARE;
            }
            
            Boolean blnCompanyId = String.isNotBlank(objMessage.Company_ID__c);
            Boolean blnVisitorEmail = String.isNotBlank(objMessage.Visitor_Email_Address__c);
            String strAccountId;
            String strContactId;
            
            if (blnCompanyId && blnVisitorEmail && map_AccountByCompanyId.containsKey(objMessage.Company_ID__c)) {
                Account objAccount = map_AccountByCompanyId.get(objMessage.Company_ID__c);
                
                if (map_ContactByVisitorEmail.containsKey(objMessage.Visitor_Email_Address__c)) {
                    Contact objContact = map_ContactByVisitorEmail.get(objMessage.Visitor_Email_Address__c);
                    objMessage = assignSkillPersona(objMessage, objContact, objAccount);
                    objMessage = assignSkillCompanySize(objMessage, objAccount);
                    objMessage = assignSkillRequestType(objMessage);
                    objMessage = assignSkillGustoGlobal(objMessage, objAccount);
                    objMessage = assignDefaultOwner(objMessage);
                    
                    if (objAccount.Id == objContact.AccountId) {
                        strContactId = objContact.Id;
                        strAccountId = objAccount.Id;
                    }
                }
                
                if (map_OpportunityIdByAccountId.containsKey(objAccount.Id)) {
                    objMessage.OpportunityId = map_OpportunityIdByAccountId.get(objAccount.Id);
                }
            }
            
            Boolean blnIdentifiers = String.isBlank(strContactId) && 
                String.isBlank(strAccountId) && 
                String.isBlank(objMessage.LeadId);
            
            if (blnIdentifiers && blnVisitorEmail && map_LeadIdByVisitorEmail.containsKey(objMessage.Visitor_Email_Address__c)) {
                objMessage.LeadId = map_LeadIdByVisitorEmail.get(objMessage.Visitor_Email_Address__c);
            }
            
            if (String.isNotBlank(objMessage.ORCA_Predicted_Case_Reason__c) &&
                objMessage.ORCA_Predicted_Case_Reason__c != AgathaPredictionTriggerHelper.AGATHAPREDICTION_NOT_PREDICTED &&
                map_CaseReasonByReasonCode.containsKey(objMessage.ORCA_Predicted_Case_Reason__c)) {
                    // If ORCA predicts the chat with a reason code that matches with the CRC object, update the following fields 
                    Case_Reason_Classification__c objReason = map_CaseReasonByReasonCode.get(objMessage.ORCA_Predicted_Case_Reason__c);
                    objMessage.Routing_Case_Reason_Classification__c  = objReason.Id;
                    objMessage.Request_Type__c = objReason.Case_Type_Pillar__c;
                    objMessage.Support_Level__c = objReason.Support_Level__c;
                    objMessage.Team__c = objReason.Routing_Team__c;
                }
        }
    }
    
    public void OnAfterUpdate(Map<Id, MessagingSession> map_OldMessagingSessionById, Map<Id, MessagingSession> map_MessagingSessionById) {
        Set<Id> set_CaseIds = new Set<Id>();
        Set<Id> set_LeadIds = new Set<Id>();
        Set<Id> set_MessagingEndUserIds = new Set<Id>();
        List<MessagingEndUser> list_MessagingEndUsers = new List<MessagingEndUser>();
        List<Case> list_Cases = new List<Case>();
        List<Lead> list_Leads = new List<Lead>();
        List<Case_Audit_Log__c> list_CaseAuditLogs = new List<Case_Audit_Log__c>();
        Map<Id, AgentWork> map_AgentWorkByMessageId = new Map<Id, AgentWork>();
        
        for (MessagingSession objMessage : map_MessagingSessionById.values()) {
            if (objMessage.CaseId != null) {
                set_CaseIds.add(objMessage.CaseId);
            }
            if (objMessage.LeadId != null) {
                set_LeadIds.add(objMessage.LeadId);
            }
            if (objMessage.MessagingEndUserId != null) {
                set_MessagingEndUserIds.add(objMessage.MessagingEndUserId);
            }
        }
        
        Map<Id, MessagingEndUser> map_MessagingEndUserById = queryMessagingEndUsers(set_MessagingEndUserIds);
        Map<Id, Case> map_CaseById = queryCases(set_CaseIds);
        
        Map<String, Case_Pillar_Mapping__c> map_PillarMappingByKey = new Map<String, Case_Pillar_Mapping__c>();
        Map<String, Case_Pillar_Mapping__c> map_PillarWOCompanySize = new Map<String, Case_Pillar_Mapping__c>();
        for (Case_Pillar_Mapping__c objMapping : Case_Pillar_Mapping__c.getAll().values()) {
            String strKey = objMapping.Case_Origin__c;
            String strKey2 = objMapping.Case_Origin__c;
            strKey += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c + '' + objMapping.Company_Size__c;
            strKey2 += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c;
            map_PillarMappingByKey.put(strKey.toLowerCase(), objMapping);
            map_PillarWOCompanySize.put(strKey2.toLowerCase(), objMapping);
        }
        
        for (AgentWork objAgentWork : queryAgentWorks(map_MessagingSessionById.keySet())) {
            map_AgentWorkByMessageId.put(objAgentWork.WorkItemId, objAgentWork);
        }
        
        // Auto-Solve Case Reason Classification
        List<Case_Reason_Classification__c> list_NoActionCaseReasons = CaseQueryHelper.queryCaseReason(CaseUtils.STR_AUTO_SOLVED_CASE_REASON);
        
        for (MessagingSession objMessage : map_MessagingSessionById.values()) {
            MessagingSession objOldMessage = map_OldMessagingSessionById.get(objMessage.Id);
            String strAccountId;
            String strContactId;
            Boolean blnCompanyId = String.isNotBlank(objMessage.Company_ID__c);
            Boolean blnVisitorEmail = String.isNotBlank(objMessage.Visitor_Email_Address__c);
            
            if (blnCompanyId && blnVisitorEmail && map_AccountByCompanyId.containsKey(objMessage.Company_ID__c)) {
                Account objAccount = map_AccountByCompanyId.get(objMessage.Company_ID__c);
                
                if (map_ContactByVisitorEmail.containsKey(objMessage.Visitor_Email_Address__c)) {
                    Contact objContact = map_ContactByVisitorEmail.get(objMessage.Visitor_Email_Address__c);
                    
                    if (objAccount.Id == objContact.AccountId) {
                        MessagingEndUser objMessagingEndUser = map_MessagingEndUserById.get(objMessage.MessagingEndUserId);
                        objMessagingEndUser.ContactId = objContact.Id;
                        objMessagingEndUser.AccountId = objAccount.Id;
                        strAccountId = objAccount.Id;
                        strContactId = objContact.Id;
                        list_MessagingEndUsers.add(objMessagingEndUser);
                    }
                }
            }
            
            if (objMessage.CaseId != null && map_CaseById.containsKey(objMessage.CaseId)) {
                Case objCase = map_CaseById.get(objMessage.CaseId);
                if (objCase.IsClosed) {
                    continue;
                }

                if (String.isBlank(objOldMessage.CaseId) && String.isNotBlank(objMessage.CaseId)) {
                    objCase.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;

                    if (String.isNotBlank(strAccountId) && String.isNotBlank(strContactId)) {
                        objCase.AccountId = strAccountId;
                        objCase.ContactId = strContactId;
                    }
                }

                if (objOldMessage.Request_Type__c != objMessage.Request_Type__c ||
                    String.isNotBlank(objMessage.Request_Type__c) && String.isBlank(objCase.Type)) {
                        objCase.Type = objMessage.Request_Type__c;
                }
                if (objOldMessage.Support_Level__c != objMessage.Support_Level__c ||
                    String.isNotBlank(objMessage.Support_Level__c) && String.isBlank(objCase.Support_Level__c)) {
                        objCase.Support_Level__c = objMessage.Support_Level__c;
                }
                if (objOldMessage.Persona__c != objMessage.Persona__c ||
                    String.isNotBlank(objMessage.Persona__c) && String.isBlank(objCase.Persona__c)) {
                        objCase.Persona__c = objMessage.Persona__c;
                }
                if (objOldMessage.Company_Size__c != objMessage.Company_Size__c ||
                    String.isNotBlank(objMessage.Company_Size__c) && String.isBlank(objCase.Company_Size__c)) {
                        objCase.Company_Size__c = objMessage.Company_Size__c;
                }
                
                if (
                    objMessage.RecordTypeId == MessagingSessionUtils.RECTYPE_CUSTOMER_CARE &&
                    objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT &&
                    String.isBlank(objOldMessage.CaseId) && String.isNotBlank(objMessage.CaseId)
                ) {
                    objCase = updatePillarMapping(objCase, objMessage, map_PillarMappingByKey, map_PillarWOCompanySize);
                    
                    if (
                        String.isNotBlank(objMessage.ORCA_Predicted_Case_Reason__c) &&
                        objMessage.ORCA_Predicted_Case_Reason__c != AgathaPredictionTriggerHelper.AGATHAPREDICTION_NOT_PREDICTED &&
                        map_CaseReasonByReasonCode.containsKey(objMessage.ORCA_Predicted_Case_Reason__c)
                    ) {
                        objCase.Routing_Case_Reason__c = map_CaseReasonByReasonCode.get(objMessage.ORCA_Predicted_Case_Reason__c).Name;
                        objCase.Routing_Case_Reason_Classification__c = map_CaseReasonByReasonCode.get(objMessage.ORCA_Predicted_Case_Reason__c).Id;
                    }
                }
/*
                if (objMessage.Status == MessagingSessionUtils.STATUS_ERROR &&
                    objMessage.RecordTypeId == MessagingSessionUtils.RECTYPE_CUSTOMER_CARE && 
                    !objCase.IsClosed &&
                    objCase.RecordTypeId != CaseUtils.RECTYPE_R_D_TAX_CREDITS) {
                        String strOwnerId = GlobalQueryHelper.getQueueIdByDevName(CaseUtils.QUEUE_NAME_ENGAGEMENT_CANCELED_CHATS);
                        if (map_ChatEventByChatId?.containsKey(objMessage.Id) && 
                            String.isNotBlank(strOwnerId) && 
                            objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT) {
                            objCase.OwnerId = strOwnerId;
                            objCase.Audience__c = CaseUtils.AUDIENCE_OTHER;
                            if (!list_NoActionCaseReasons.isEmpty()) {
                                objCase.Confirm_Case_Reason_Classification__c = list_NoActionCaseReasons[0].Id;
                            }
                        }

                        objCase.Status = CaseUtils.STATUS_CLOSED;
                    }

                if (objMessage.RecordType.Name != CaseUtils.INTERNAL_TEAM &&
                    !objCase.IsClosed) {
                        objCase.Direction__c =  CaseUtils.DIRECTION_INBOUND;
                        objCase.Recent_Queue_Id__c = (String) objMessage.LiveChatButtonId;
                        objCase.Recent_Queue_Name__c = map_ChatButtonsById.get(objMessage.LiveChatButtonId)?.MasterLabel + ' - ' + CaseUtils.ORIGIN_CHAT;

                        if (Test.isRunningTest() && boolTestThis) {
                            objMessage.Status = 'Missed';
                        }

                        objCase.Recent_Queue_Name__c += ' - ' + objMessage.Status;

                        if (String.isNotBlank(objMessage.Body)) {
                            objCase.Description = objMessage.Body.stripHtmlTags(); // to be only handle for external
                        }
                    }
*/
                if (map_AgentWorkByMessageId.containsKey(objMessage.Id) &&
                    (objMessage.Status != objOldMessage.Status)) {
                        AgentWork objAgentWork = map_AgentWorkByMessageId.get(objMessage.Id);
                        
                        Case_Audit_Log__c objAuditLog = new Case_Audit_Log__c();
                        objAuditLog.Case__c = objCase.Id;
                        objAuditLog.Direction__c = CaseUtils.DIRECTION_INBOUND;
                        
                        if (objMessage.RecordType.Name == CaseUtils.INTERNAL_TEAM) {
                            objAuditLog.Event_Type__c = CaseUtils.INTERNAL_TEAM + ' ' + CaseUtils.ORIGIN_CHAT;
                        } else {
                            objAuditLog.Event_Type__c = CaseUtils.ORIGIN_CHAT;
                        }
                        
                        objAuditLog.Advocate__c = objAgentWork.UserId;
                        objAuditLog.To_Date_Time__c = objAgentWork.CloseDateTime;
                        objAuditLog.From_Date_Time__c = objAgentWork.AcceptDateTime;
                        objAuditLog.Live_Channel_Start_Time__c = objAgentWork.RequestDateTime;

                        // Assign the owner of the case to the agent who worked on the chat
                        objCase.OwnerId = objAgentWork.UserId;
                        
                        if (bizHours != null && !bizHours.isEmpty()) {
                            objAuditLog.Business_Hours__c = bizHours[0].Id;
                            
                            if (!Test.isRunningTest() && objAgentWork.RequestDateTime != null && objAgentWork.AcceptDateTime != null) {
                                Long milliSeconds = BusinessHours.diff(bizHours[0].Id, objAgentWork.RequestDateTime, objAgentWork.AcceptDateTime);
                                objAuditLog.Live_Channel_Wait_Time_In_Seconds__c = milliSeconds / 1000;
                            }
                        }
/*
                        if (objMessage.Status == MessagingSessionUtils.STATUS_ENDED) {
                            objMessage.Case_Number__c = objMessage.Case.CaseNumber;
                            objMessage.Active_Time__c = objAgentWork.Activetime;
                            objMessage.Tab_Close_Time__c = objAgentWork.CloseDateTime;
                            list_ChatTranscriptsToUpdate.add(objMessage);
                        }
*/
                        list_CaseAuditLogs.add(objAuditLog);
                    }
                
                list_Cases.add(objCase);
            }
        }
        
        try {
            if (!list_MessagingEndUsers.isEmpty()) {
                update list_MessagingEndUsers;
            }
            
            if (!list_Cases.isEmpty()) {
                CaseTriggerHelper.skipTrigger = true;
                Database.update(list_Cases, false);
                CaseTriggerHelper.skipTrigger = false;
            }
            
            if (!list_CaseAuditLogs.isEmpty()) {
                insert list_CaseAuditLogs;
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('MessagingSessionTriggerHelper', 'OnAfterUpdate', objException.getMessage(), objException.getStackTraceString());
        }
    }
    
    public void OnBeforeDelete(List<MessagingSession> list_MessagingSessions, Map<Id, MessagingSession> map_MessagingSessionById) {}
    
    private static MessagingSession assignSkillPersona(MessagingSession objMessage, Contact objContact, Account objAccount) {
        if (String.isBlank(objContact.ZP_User_Role__c)) {
            return objMessage;
        }
        
        if (objContact.ZP_User_Role__c == ContactUtil.ZPUSERROLE_ACCOUNTANT) {
            objMessage.Persona__c = MessagingSessionUtils.PERSONA_ACCOUNTANT;
        } else if (objContact.ZP_User_Role__c.contains(ContactUtil.ZPUSERROLE_ADMIN) ||
                   objContact.ZP_User_Role__c == ContactUtil.ZPUSERROLE_SIGNATORY) {
                       objMessage.Persona__c = MessagingSessionUtils.PERSONA_ADMIN;
        } else if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID &&
                   (objContact.ZP_User_Role__c.contains(ContactUtil.ZPUSERROLE_CONTRACTOR) ||
                    objContact.ZP_User_Role__c.contains(ContactUtil.ZPUSERROLE_EMPLOYEE))) {
                        objMessage.Persona__c = MessagingSessionUtils.PERSONA_MEMBER;
        } else {
            objMessage.Persona__c = MessagingSessionUtils.PERSONA_ADMIN;
        }
        
        return objMessage;
    }
    
    private static MessagingSession assignSkillCompanySize(MessagingSession objMessage, Account objAccount) {
        if (objMessage.Persona__c != MessagingSessionUtils.PERSONA_ADMIN || objAccount.Number_of_Active_Employees__c == null) {
            return objMessage;
        }
        
        if (objAccount.Number_of_Active_Employees__c <= 4) {
            objMessage.Company_Size__c = MessagingSessionUtils.COMPANY_SIZE_MICRO;
        } else if (objAccount.Number_of_Active_Employees__c >= 5 && objAccount.Number_of_Active_Employees__c <= 24) {
            objMessage.Company_Size__c = MessagingSessionUtils.COMPANY_SIZE_STANDARD;
        } else if (objAccount.Number_of_Active_Employees__c >= 25 && objAccount.Number_of_Active_Employees__c <= 49) {
            objMessage.Company_Size__c = MessagingSessionUtils.COMPANY_SIZE_GROWER_25_49;
        } else if (objAccount.Number_of_Active_Employees__c >= 50) {
            objMessage.Company_Size__c = MessagingSessionUtils.COMPANY_SIZE_GROWER_50;
        } else {
            objMessage.Company_Size__c = MessagingSessionUtils.COMPANY_SIZE_STANDARD;
        }
        
        return objMessage;
    }
    
    private static MessagingSession assignSkillRequestType(MessagingSession objMessage) {
        if (objMessage.ORCA_Predicted_Type__c == null) {
            return objMessage;
        }
        
        objMessage.Request_Type__c = objMessage.ORCA_Predicted_Type__c;
        return objMessage;
    }
    
    private static MessagingSession assignSkillGustoGlobal(MessagingSession objMessage, Account objAccount) {
        if (String.isNotBlank(objAccount.Help_Journey_Routing__c) &&
            objAccount.Help_Journey_Routing__c.contains(MessagingSessionUtils.STR_GUSTO_GLOBAL)) {
                objMessage.Request_Type__c = MessagingSessionUtils.STR_GUSTO_GLOBAL;
            }
        
        return objMessage;
    }
    
    private static MessagingSession assignDefaultOwner(MessagingSession objMessage) {
        if (objMessage.Persona__c == null || objMessage.Support_Level__c == null || objMessage.Request_Type__c == null) {
            return objMessage;
        }
        
        objMessage.OwnerId = DEFAULT_CHAT_QUEUE_ID;
        return objMessage;
    }
    
    /**
     * @Author      : Ankit C
     * @Description : This method will update the Pillar,Sub-Pillar & WFM Queue Tag fields on the associated Case
     * @Parm        : objCase - Case associated to the Chat, map_PillarMappingByKey - Map of CasePillarMapping by unique key,
     *                map_PillarWOCompanySize - Map of CasePillarMapping by unique key without comapany size
     * 				  objMessage - MessagingSession from trigger.new
     * @Return      : objCase - Case associated to the Chat
    **/
    private Case updatePillarMapping(Case objCase, MessagingSession objMessage, Map<String, Case_Pillar_Mapping__c> map_PillarMappingByKey, Map<String, Case_Pillar_Mapping__c> map_PillarWOCompanySize) {
        String strKey = '';
        if (
            (objCase.Origin == CaseUtils.ORIGIN_EMAIL || 
             (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_EMAIL))
        ) {
            strKey = CaseUtils.ORIGIN_EMAIL;
        } else if (
            (objCase.Origin == CaseUtils.ORIGIN_CHAT || 
             (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT))
        ) {
            strKey = CaseUtils.ORIGIN_CHAT;
        }
        
        strKey += objCase.Type + '' + objCase.Persona__c + '' + objCase.Support_Level__c;
        if (objCase.Persona__c != CaseUtils.MEMBER_PERSONA && objCase.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
            strKey += objCase.Company_Size__c;
        }
        
        strKey = strKey.toLowerCase();
        
        if (
            (objCase.Persona__c == CaseUtils.MEMBER_PERSONA || objCase.Persona__c == CaseUtils.ACCOUNTANT_PERSONA) && 
            map_PillarWOCompanySize.containsKey(strKey)
        ) {
            objCase.Case_Pillar__c = map_PillarWOCompanySize.get(strKey).Pillar__c;
            objCase.Sub_Pillar__c = map_PillarWOCompanySize.get(strKey).Sub_Pillar__c;
            objCase.WFM_Queue_Tag__c = map_PillarWOCompanySize.get(strKey).WFM_Queue_Tag__c;
        } else if (map_PillarMappingByKey.containsKey(strKey)) {
            objCase.Case_Pillar__c = map_PillarMappingByKey.get(strKey).Pillar__c;
            objCase.Sub_Pillar__c = map_PillarMappingByKey.get(strKey).Sub_Pillar__c;
            objCase.WFM_Queue_Tag__c = map_PillarMappingByKey.get(strKey).WFM_Queue_Tag__c;
        } else {
            objCase.Case_Pillar__c = '';
            objCase.Sub_Pillar__c = '';
            objCase.WFM_Queue_Tag__c = '';
        }
        
        return objCase;
    }
    
    private static List<Account> queryAccounts(Set<String> set_CompanyIds) {
        return [SELECT 
                    Id,
                    RecordTypeId,
                    ZP_Company_ID__c,
                    Number_of_Active_Employees__c,
                    Help_Journey_Routing__c
                FROM Account 
                WHERE ZP_Company_ID__c IN :set_CompanyIds];
    }
    
    private static List<Contact> queryContacts(Set<String> set_VisitorEmailAddresses) {
        return [SELECT Id, Email, AccountId, ZP_User_Role__c FROM Contact WHERE Email IN :set_VisitorEmailAddresses];
    }
    
    private static Map<Id, Case> queryCases(Set<Id> set_CaseIds) {
        return new Map<Id, Case>([SELECT 
                                    Id,
                                    IsClosed,
                                    RecordTypeId,
                                    Origin,
                                    Type,
                                    Channel__c,
                                    Support_Level__c,
                                    Persona__c,
                                    Company_Size__c
                                    FROM Case
                                    WHERE Id IN :set_CaseIds]);
    }
    
    private static List<Lead> queryLeads(Set<Id> set_LeadIds) {
        return [SELECT
                    Id,
                    LeadSource,
                    Phone,
                    Status,
                    Alternate_Phone__c,
                    ZP_Lead_Campaign__c,
                    Trk_UTM_Medium__c,
                    Trk_UTM_Content__c,
                    Trk_Placement__c,
                    Trk_network__c,
                    Trk_matchtype__c,
                    Trk_Keyword__c,
                    Trk_gclid__c,
                    Trk_Device__c,
                    Trk_creative__c,
                    msclkid__c,
                    Landing_Page__c,
                    adgroup__c,
                    Visitor_Id__c,
                    Session_Id__c,
                    Last_Form_Fill_URL__c,
                    Lead_Creation_Offer__c,
                    Recent_Campaign__c,
                    Recent_Content__c,
                    Recent_Source__c,
                    URL_of_Conversion__c,
                    Referring_Url__c,
                    MQL_Reason__c,
                    CreatedBy.Name
                FROM Lead
                WHERE Id IN :set_LeadIds];
    }
    
    private static List<Lead> queryLeads(Set<String> set_VisitorEmailAddresses) {
        return [SELECT Id, Email FROM Lead WHERE Email IN :set_VisitorEmailAddresses];
    }
    
    private static List<Opportunity> queryOpportunities(Set<Id> set_AccountIds) {
        return [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :set_AccountIds AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID];
    }
    
    private static List<Case_Reason_Classification__c> queryCaseReasonClassifications(Set<String> set_Reasons) {
        return [SELECT
                    Id,
                    Reason_Code__c,
                    Name,
                    Type__c,
                    Class__c,
                    Priority__c,
                    Task_Us__c,
                    Survey_Eligible__c,
                    Auto_Email_Behavior__c,
                    Email_Content__c,
                    Do_Not_Auto_Solve_for_Auto_Email__c,
                    Confidence_Threshold__c,
                    Email_Signature__c,
                    Override_Email_Signature__c,
                    Generic_Routing_Reason__c,
                    Default_Type__c,
                    Case_Type_Pillar__c,
                    Routing_Team__c,
                    Support_Level__c,
                    Specialization__c
                FROM Case_Reason_Classification__c
                WHERE Reason_Code__c IN :set_Reasons];
    }
    
    private static Map<Id, MessagingEndUser> queryMessagingEndUsers(Set<Id> set_MessagingEndUserIds) {
        return new Map<Id, MessagingEndUser>([SELECT Id, AccountId, ContactId FROM MessagingEndUser WHERE Id IN :set_MessagingEndUserIds]);
    }
    
    private static List<AgentWork> queryAgentWorks(Set<Id> set_MessagingSessionIds) {
        return [SELECT 
                    Id,
                    Activetime,
                    CloseDateTime,
                    WorkItemId,
                    UserId,
                    AcceptDateTime,
                    HandleTime,
                    RequestDateTime
                FROM AgentWork
                WHERE WorkItemId IN :set_MessagingSessionIds
                ORDER BY CreatedDate ASC];
    }
}