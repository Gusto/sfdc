/** @name       TaxComplianceController
* @author       Sindhu
* @date         29th Feburary 2024
* @description  Handles assigning fields from parent cases to child cases based on configured mappings.
* @test class   TaxComplianceControllerTest
* @revisions    Date ------------ Name ------------ Comments
**/

public class TaxComplianceController {
    
    @InvocableMethod(label='Get Compliance Parent Case Values' description='Updates Child Complaince Case values from Parent Complaince cases' category='Case')
    public static void prePopulateComplianceChildCaseDetails(List<Case> list_ChildCases) {

        Set<Id> set_ParentCaseIds = new Set<Id>();
        Set<Id> set_AllCaseIds = new Set<Id>();
        Map<Id, Case> map_ChildMap = new Map<Id, Case>(); // case id as a key and case as a value
        Map<Id, Tax_Compliance__c> map_ComplianceMap = new Map<Id, Tax_Compliance__c>(); // case id as a key and compliance record as a value
        List<Tax_Compliance__c> list_ChildCompliances = new List<Tax_Compliance__c>(); // list to have records to be updated
        Map<Id, Tax_Questionnaire__c> map_QuestionnaireMap = new Map<Id, Tax_Questionnaire__c>(); // case id as a key and questionnaire record as a value
        List<Tax_Questionnaire__c> list_ChildQuestionnaires = new List<Tax_Questionnaire__c>(); // list to have questionnaire records to be updated
        
        
        for (Case objCase : list_ChildCases) {
            if (String.isNotBlank(objCase.ParentId)) {
                set_ParentCaseIds.add(objCase.ParentId);
                map_ChildMap.put(objCase.Id, objCase);
                set_AllCaseIds.add(objCase.Id);
                set_AllCaseIds.add(objCase.ParentId);
            }
        }
        
        Compliance_CaseMapping__mdt objQuestionnaireMetadata = [SELECT Id, DeveloperName, ObjectName__c, FieldNames__c FROM Compliance_CaseMapping__mdt WHERE ObjectName__c =:CaseUtils.STR_OBJ_NAME_TAX_QUESTIONNAIRE LIMIT 1];
        List<String> list_QuestionnaireFieldsToCopy = objQuestionnaireMetadata.FieldNames__c != null ? objQuestionnaireMetadata.FieldNames__c.split(',') : null;
        String strQuesQuery = 'SELECT Id, Case__c, ' + objQuestionnaireMetadata.FieldNames__c + ' FROM Tax_Questionnaire__c WHERE Case__c IN :set_AllCaseIds';
        for (Tax_Questionnaire__c objQuestionnaire : Database.query(strQuesQuery)) {
            map_QuestionnaireMap.put(objQuestionnaire.Case__c, objQuestionnaire);
        }
        
        // Retrieve the mapping metadata for field assignments
        Compliance_CaseMapping__mdt objComplianceMetadata = [SELECT Id, DeveloperName, ObjectName__c, FieldNames__c FROM Compliance_CaseMapping__mdt WHERE ObjectName__c =:CaseUtils.STR_OBJ_NAME_TAX_COMPLIANCE LIMIT 1];
        List<String> list_FieldsToCopy = objComplianceMetadata.FieldNames__c.split(',');
        
        // query metadata and assign it to map
        String strQuery = 'SELECT Id,' + objComplianceMetadata.FieldNames__c + ' FROM Tax_Compliance__c WHERE Case__c IN :set_AllCaseIds';
        for (Tax_Compliance__c objCompliance : Database.query(strQuery)) {
            map_ComplianceMap.put(objCompliance.Case__c, objCompliance);
        }
        
        // Assign fields from parent to child cases
        for (Case objChildCase : list_ChildCases) {
            Tax_Compliance__c objParentCompliance = map_ComplianceMap.get(objChildCase.ParentId);
            Tax_Compliance__c objChildCompliance = map_ComplianceMap.get(objChildCase.Id);
            
            if (objParentCompliance != null) { 
                for (String strField : list_FieldsToCopy) {
                    Schema.SObjectType targetObjType = objChildCase.getSObjectType();
                    Schema.DescribeSObjectResult targetObjDescribe = targetObjType.getDescribe();
                    Map<String, Schema.SObjectField> fieldMap = targetObjDescribe.fields.getMap();
                    
                    if (strField.contains('__r')) {
                        List<String> list_RelationshipAndField = strField.split('\\.');
                        Object fieldValue = objParentCompliance.getSObject('Case__r').get(list_RelationshipAndField[1]);
                        String strValue = String.valueOf(fieldValue);
                        
                        Schema.SObjectField targetField = fieldMap.get(list_RelationshipAndField[1]);
                        Schema.DescribeFieldResult fieldDescribe = targetField.getDescribe();
                        Schema.DisplayType fieldType = fieldDescribe.getType();
                        
                        // Handling Decimal fields
                        if (fieldType == Schema.DisplayType.Double && !list_RelationshipAndField[1].contains(CaseUtils.STR_ID) && !list_RelationshipAndField[1].equals(CaseUtils.STR_OBJ_NAME_AGENCY_INFORMATION)) {
                            objChildCase.put(list_RelationshipAndField[1], (Double)fieldValue);
                        } 
                        // Handling String fields
                        else if (fieldType == Schema.DisplayType.STRING) {
                            objChildCase.put(list_RelationshipAndField[1], (String)fieldValue);
                        }
                        // Handling Integer fields
                        else if (fieldType == Schema.DisplayType.INTEGER) {
                            objChildCase.put(list_RelationshipAndField[1], (Integer)fieldValue);
                        } 
                        // Handling Boolean fields
                        else if (fieldType == Schema.DisplayType.BOOLEAN) {
                            objChildCase.put(list_RelationshipAndField[1], (Boolean)fieldValue);
                        } 
                        // Handling Date fields
                        else if (fieldType == Schema.DisplayType.DATE) {
                            objChildCase.put(list_RelationshipAndField[1], (Date)fieldValue);
                        } 
                        // Handling DateTime fields
                        else if (fieldType == Schema.DisplayType.DATETIME) {
                            objChildCase.put(list_RelationshipAndField[1], (DateTime)fieldValue);
                        } 
                        
                        else {
                            objChildCase.put(list_RelationshipAndField[1], (String)fieldValue);
                        }
                        
                    } else {
                        objChildCompliance.put(strField, objParentCompliance.get(strField));
                    }
                    
                }
                
                list_ChildCompliances.add(objChildCompliance);
            }
            
            Tax_Questionnaire__c objParentQuestionnaire = map_QuestionnaireMap.get(objChildCase.ParentId);
            if (objParentQuestionnaire != null) {
                Tax_Questionnaire__c objChildQuestionnaire = objParentQuestionnaire.clone(false, true, true, true); // Adjust clone flags as needed
                objChildQuestionnaire.Case__c = objChildCase.Id; // Associate with the cloned case
                list_ChildQuestionnaires.add(objChildQuestionnaire); // Add to list for bulk DML
            }
        }
        // attachments
        
        // Assume set_ParentCaseIds contains all the parent case IDs derived from list_ChildCases
        List<ContentDocumentLink> list_ParentDocLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :set_ParentCaseIds];
        
        Map<Id, Set<Id>> map_parentDocIdToChildCaseIds = new Map<Id, Set<Id>>();
        for (ContentDocumentLink objLink : list_ParentDocLinks) {
            for (Case obj_childCase : list_ChildCases) {
                if (obj_childCase.ParentId == objLink.LinkedEntityId) {
                    if (!map_parentDocIdToChildCaseIds.containsKey(objLink.ContentDocumentId)) {
                        map_parentDocIdToChildCaseIds.put(objLink.ContentDocumentId, new Set<Id>());
                    }
                    map_parentDocIdToChildCaseIds.get(objLink.ContentDocumentId).add(obj_childCase.Id);
                }
            }
        }
        
        // Prepare to clone ContentVersion for each parent ContentDocument
        List<ContentVersion> list_NewVersions = new List<ContentVersion>();
        // Collect all ContentDocumentId values from list_ParentDocLinks
        Set<Id> set_contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink objDocLink : list_ParentDocLinks) {
            set_contentDocumentIds.add(objDocLink.ContentDocumentId);
        }
        
        // Query for the latest ContentVersion of each ContentDocumentId outside the loop
        Map<Id, ContentVersion> map_latestContentVersions = new Map<Id, ContentVersion>();
        for (ContentVersion objVersion : [SELECT Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :set_contentDocumentIds AND IsLatest = true]) {
            map_latestContentVersions.put(objVersion.ContentDocumentId, objVersion);
        }
        
        // Create new ContentVersion records based on the queried latest versions
        for (Id contentDocumentId : set_contentDocumentIds) {
            ContentVersion objLatestVersion = map_latestContentVersions.get(contentDocumentId);
            if (objLatestVersion != null) {
                ContentVersion objNewVersion = new ContentVersion(
                    Title = objLatestVersion.Title,
                    PathOnClient = objLatestVersion.PathOnClient,
                    VersionData = objLatestVersion.VersionData,
                    FlowCreated__c = true
                );
                list_NewVersions.add(objNewVersion);
            }
        }
        
        try{
        // Insert the new ContentVersion records in bulk
        insert list_NewVersions;
        
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'prePopulateComplianceChildCaseDetails', objException.getMessage(), objException.getStackTraceString());
        }
        
        
        // Query back to get ContentDocumentId for new ContentVersions
        Map<Id, ContentVersion> map_newVersionMap = new Map<Id, ContentVersion>();
        for (ContentVersion objVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :list_NewVersions]) {
            map_newVersionMap.put(objVersion.Id, objVersion);
        }
        
        // Create ContentDocumentLink for each new ContentDocument and child case
        List<ContentDocumentLink> list_newDocLinks = new List<ContentDocumentLink>();
        for (ContentDocumentLink objParentLink : list_ParentDocLinks) {
            // Find child cases for each parent case
            Set<Id> set_childCaseIds = map_parentDocIdToChildCaseIds.get(objParentLink.ContentDocumentId);
            if (set_childCaseIds != null) {
                for (Id childCaseId : set_childCaseIds) {
                    // For each new version, create a link to the child case
                    for (ContentVersion objNewVersion : list_NewVersions) {
                        ContentDocumentLink objNewLink = new ContentDocumentLink(
                            ContentDocumentId = map_newVersionMap.get(objNewVersion.Id).ContentDocumentId,
                            LinkedEntityId = childCaseId,
                            ShareType = CaseUtils.STR_V, // Adjust ShareType as necessary
                            Visibility = CaseUtils.STR_ALLUSERS // Adjust Visibility as necessary
                        );
                        
                        if(!list_newDocLinks.contains(objNewLink)){
                            list_newDocLinks.add(objNewLink);
                        }
                    }
                }
            }
        }

        try {
            
            if (!list_ChildQuestionnaires.isEmpty()) {
                insert list_ChildQuestionnaires;
            }
            insert list_newDocLinks;

            Boolean caseTriggerFlag = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			update list_ChildCases;  
			CaseTriggerHelper.skipTrigger = caseTriggerFlag;

            update list_ChildCompliances;
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'prePopulateComplianceChildCaseDetails', objException.getMessage(), objException.getStackTraceString());
        }
    }
    
    // Method for Email-to-case Tax compliance class & Payrollproductcomplianceemailhandler class
    public static Case populateEmailToCaseForCompliance(String strFromAddress, String strSubject, Case objCase, String strServiceEmail) {
        try {
            String strEmailDomain = '';
            if (String.isNotBlank(strFromAddress) ) {
                List<String> list_Parts = strFromAddress.split('@');
                if (list_Parts.size() > 1 && String.isNotBlank(list_Parts[1])) {
                    strEmailDomain = list_Parts[1].trim();
                }
            }
            List<Compliance_Incoming_Email_Settings__mdt> list_CaseFieldMapping = new List<Compliance_Incoming_Email_Settings__mdt>();
            String strCaseQueue;
            Boolean blnDomainFound = true;
            //Querying from domain
            if (String.isNotBlank(strEmailDomain)) {
                list_CaseFieldMapping = [SELECT Id,Domain_Name__c,OCR_Message__c,Origin__c,Priority__c,Queue_Name__c,Record_Type_Name__c,Service_Email__c,Status__c,Subject__c,Type__c FROM Compliance_Incoming_Email_Settings__mdt WHERE Domain_Name__c= :strEmailDomain AND Service_Email__c= :strServiceEmail];
            }
            //if domain doesn't exist, querying from 'All' entry
            if (list_CaseFieldMapping.isEmpty()) {  
                blnDomainFound = false;
                list_CaseFieldMapping = [SELECT Id,Domain_Name__c,OCR_Message__c,Origin__c,Priority__c,Queue_Name__c,Record_Type_Name__c,Service_Email__c,Status__c,Subject__c,Type__c FROM Compliance_Incoming_Email_Settings__mdt WHERE Domain_Name__c='All' AND Service_Email__c= :strServiceEmail];
                for (Compliance_Incoming_Email_Settings__mdt objSubMap : list_CaseFieldMapping) {
                    if (String.isNotBlank(objSubMap.Subject__c)) {
                        for (String strSub : objSubMap.Subject__c.split(',')) {
                            if (strSubject.containsIgnoreCase(strSub)) {
                                strCaseQueue = objSubMap.Queue_Name__c;  
                            }
                        }
                    }
                }

            }
            objCase.Priority = CaseUtils.STRG_MEDIUM;

            for (String strSubPriority : CaseUtils.LIST_HIGH_PRIORITY) {
                if (strSubject.containsIgnoreCase(strSubPriority)) {
                    objCase.Priority = CaseUtils.PRIORITY_HIGH;
                }
            }
            if (strCaseQueue == null) {
                if (blnDomainFound) {
                    strCaseQueue = list_CaseFieldMapping[0].Queue_Name__c;
                } else {
                    strCaseQueue = caseutils.STRG_PAYROLL_COMP_QUEUE;
                } 
            }
            
            if (!list_CaseFieldMapping.isEmpty()) {
                objCase.Origin = list_CaseFieldMapping[0].Origin__c;
                objCase.OwnerId = GlobalQueryHelper.getGroupIdByQueueName(strCaseQueue);
                objCase.Subject = strSubject;
                objCase.Type = list_CaseFieldMapping[0].Type__c;
                objCase.OCR_Message__c = list_CaseFieldMapping[0].OCR_Message__c;
                objCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(list_CaseFieldMapping[0].Record_Type_Name__c).getRecordTypeId();
                objCase.Status = list_CaseFieldMapping[0].Status__c;
            }
            return objCase;
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'populateEmailToCaseForCompliance', objException.getMessage(), objException.getStackTraceString()); 
            Case objErrorCase = new Case();
    		objErrorCase.Description = 'Error in creating the case via Email to case'; 
    		return objErrorCase;
        }
    }

    //Assigning case attachments
    public static void insertCaseAttachments(Case objCase,List<Messaging.InboundEmail.BinaryAttachment> binaryAttachments) {
        try {
            if (binaryAttachments != null) {
                Set<Id> set_ContentVersionIds = new Set<Id>();
                List<ContentVersion> list_ContentVersionToInsert = new List<ContentVersion>();
                for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : binaryAttachments) {
                    ContentVersion objContentVersion = new ContentVersion();
                    objContentVersion.PathOnClient = binaryAttachment.fileName;
                    objContentVersion.Title = binaryAttachment.fileName;
                    objContentVersion.VersionData = binaryAttachment.body;
                    list_ContentVersionToInsert.add(objContentVersion);
                }
                insert list_ContentVersionToInsert;

                for (ContentVersion insertedVersion : list_ContentVersionToInsert) {
                    set_ContentVersionIds.add(insertedVersion.Id);
                }

                if (!set_ContentVersionIds.isEmpty()) {
                    List<ContentDocumentLink> list_ContentDocLinks = new List<ContentDocumentLink>();
                    for (ContentDocument objContentDocument : [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :set_ContentVersionIds]) {
                        ContentDocumentLink objNewLink = new ContentDocumentLink();
                        objNewLink.ContentDocumentId = objContentDocument.Id;
                        objNewLink.LinkedEntityId = objCase.Id;
                        objNewLink.ShareType = CaseUtils.STRG_VIEWER;
                        list_ContentDocLinks.add(objNewLink);
                    }
                    insert list_ContentDocLinks;
                }
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'insertCaseAttachments', objException.getMessage(), objException.getStackTraceString()); 
        } 
    }

    //Handles Tax Compliance child records to Case
    public static void insertComplianceRecords(Case objCase) {
        try {
            List<Tax_Compliance__c> list_NewComplianceRecords = new List<Tax_Compliance__c>();
            Tax_Compliance__c objTaxComplianceRecord = new Tax_Compliance__c();
            objTaxComplianceRecord.Case__c = objCase.Id;
            objTaxComplianceRecord.Tier__c = CaseUtils.STRG_TIER;
            objTaxComplianceRecord.Frequency_of_Update__c = CaseUtils.STRG_FREQUENCT_OF_UPDATE;
            objTaxComplianceRecord.Classification_Type__c = CaseUtils.STRG_ClASSIFICATION_TYPE;
            list_NewComplianceRecords.add(objTaxComplianceRecord);

            // Insert the new Tax Compliance records
            if (!list_NewComplianceRecords.isEmpty()) {
                insert list_NewComplianceRecords;
            }

        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'insertComplianceRecords', objException.getMessage(), objException.getStackTraceString()); 
        } 
    }
    
     //Assigning EmailMessage attachments
    public static void insertEmailMessageAttachments(EmailMessage objEmailMessage, Case objCase, List<Messaging.InboundEmail.BinaryAttachment> binaryAttachments) {
        try {
            if (binaryAttachments != null) {
                Set<Id> set_ContentVersionIds = new Set<Id>();
                List<ContentVersion> list_ContentVersionToInsert = new List<ContentVersion>();
                for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : binaryAttachments) {
                    ContentVersion objContentVersion = new ContentVersion();
                    objContentVersion.PathOnClient = binaryAttachment.fileName;
                    objContentVersion.Title = binaryAttachment.fileName;
                    objContentVersion.VersionData = binaryAttachment.body;
                    list_ContentVersionToInsert.add(objContentVersion);
                }
                insert list_ContentVersionToInsert;

                for (ContentVersion insertedVersion : list_ContentVersionToInsert) {
                    set_ContentVersionIds.add(insertedVersion.Id);
                }

                if (!set_ContentVersionIds.isEmpty()) {
                    List<ContentDocumentLink> list_ContentDocLinks = new List<ContentDocumentLink>();
                    for (ContentDocument objContentDocument : [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :set_ContentVersionIds]) {
                        ContentDocumentLink objNewEmailMessageLink = new ContentDocumentLink();
                        objNewEmailMessageLink.ContentDocumentId = objContentDocument.Id;
                        objNewEmailMessageLink.LinkedEntityId = objEmailMessage.Id;
                        objNewEmailMessageLink.ShareType = CaseUtils.STRG_VIEWER;
                        list_ContentDocLinks.add(objNewEmailMessageLink);
                    }
                    insert list_ContentDocLinks;
                }
            }
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceController', 'insertEmailMessageAttachments', objException.getMessage(), objException.getStackTraceString()); 
        } 
    }
    
    //creates emailMessage for e2c case
    public static void createEmailMessage(Case ObjCase, Messaging.InboundEmail email) {
        
        EmailMessage objEmailMessage = new EmailMessage();
        objEmailMessage.FromAddress = email.fromAddress;
        objEmailMessage.subject = email.subject;
        if (String.isNotBlank(email.htmlBody)) {
            objEmailMessage.HtmlBody = email.HtmlBody;
        } else if (String.isNotBlank(email.plainTextBody)) {
            objEmailMessage.TextBody = email.plainTextBody;
        }
        
        if(email.toAddresses != null && !email.toAddresses.IsEmpty()) {
         	objEmailMessage.ToAddress =  String.join(email.toAddresses,',');  
        }
        
        if(email.ccAddresses != null && !email.ccAddresses.IsEmpty()) {
         	objEmailMessage.ccAddress =  String.join(email.ccAddresses,','); 
        }
        objEmailMessage.ParentId = objCase.Id;
		insert objEmailMessage;
        
        if (email.binaryAttachments != null) {
            TaxComplianceController.insertEmailMessageAttachments(objEmailMessage, ObjCase, email.binaryAttachments);
        }
        
    }
}