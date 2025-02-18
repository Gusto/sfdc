/**
* @name         TaxComplianceCloneCaseHandler
* @author       Sujan
* @date         07/15/2024
* @description  Handles Clone Case Quick Action
**/
public without sharing  class TaxComplianceCloneCaseHandler {
    @InvocableMethod(label='Clone Case' description='Create a cloned case from Origin case' category='Case')
    public static List<Case> getCaseClone(List<String> caseIds)
    {
        
        String strCaseId = caseIds.isEmpty()?null:caseIds[0];
        if (strCaseId == null) {
            return null;
        }
        
        Map<String,String> map_MasterToClonedCaseIds = new  Map<String,String>(); // original case as a key and cloned case as a value
        List<Case> list_CasesCreated = new List<Case>(); // list to store cloned parent cases
        Set<String> list_Casefields = new Set<String>();
        for(Schema.FieldSetMember field : SObjectType.Case.FieldSets.Tax_Res_Compliance_Clone_Fields.getFields()){
            list_Casefields.add(field.getFieldPath()); 
        }
        String strcasesoql = ''
            + ' SELECT Id,ParentId,CaseNumber, (SELECT Id,ParentId, '+String.join(list_Casefields, ',')+' FROM cases) ' + String.join(list_Casefields, ',')
            + ' FROM Case WHERE'
            + ' Id = \''+strCaseId+'\'';
        
        Case objCaseRecord;
        List<Case> list_CaseFetched = Database.query(strcasesoql);
        if(!list_caseFetched.isEmpty()){
            objCaseRecord = list_CaseFetched[0]; // Original parent and child case 
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            
            List<Case> list_ClonedCasesLevel1 = createClonedCases(new List<Case>{objCaseRecord}, '');
            List<FeedItem> list_feedItemToInsert = new  List<FeedItem>();
            Map<Id,Id> map_ClonedToMasterCaseIds = new Map<Id,Id>();
            
            // inserting the first level cloned case
            insert list_ClonedCasesLevel1;
            list_CasesCreated.add(list_ClonedCasesLevel1[0]);
            map_MasterToClonedCaseIds.put(objCaseRecord.Id, list_ClonedCasesLevel1[0].Id);
            map_ClonedToMasterCaseIds.put(list_ClonedCasesLevel1[0].Id,objCaseRecord.Id);
            list_feedItemToInsert.add(createFeedItem(objCaseRecord.Id,list_ClonedCasesLevel1[0].Id,objCaseRecord.CaseNumber,false));
            List<Case> list_ClonedCasesLevel2 = new List<Case>();
            // inserting second level cloned (child) cases
            if(!objCaseRecord.cases.isEmpty()) {
                list_ClonedCasesLevel2 = createClonedCases(objCaseRecord.cases, list_ClonedCasesLevel1[0].Id);
                if(!list_ClonedCasesLevel2.isEmpty()){
                    insert list_ClonedCasesLevel2;
                }
                
                for(Case objLevel2Case : list_ClonedCasesLevel2){
                    map_MasterToClonedCaseIds.put(objLevel2Case.Source__c, objLevel2Case.Id);
                    list_feedItemToInsert.add(createFeedItem(objCaseRecord.Id,objLevel2Case.Id,objCaseRecord.CaseNumber,false));
                     map_ClonedToMasterCaseIds.put(objLevel2Case.Id,objLevel2Case.Source__c);
                }
            }
            Map<Id,Case> map_createdCases = new Map<Id,Case>([SELECT Id,CaseNumber,ParentId FROM Case WHERE Id IN :map_ClonedToMasterCaseIds.keyset()]);
            
            for(Case objcreatedCase : map_createdCases.values()){  
               	list_feedItemToInsert.add(createFeedItem(objcreatedCase.Id,map_ClonedToMasterCaseIds.get(objcreatedCase.Id),objcreatedCase.CaseNumber,true));
            }            
            // clone the related lists (Tax Compliance and Tax Questionnaire)
            createCaseRelatedChildRecords(map_MasterToClonedCaseIds);
            
            // clone attachments
            cloneAttachments(map_MasterToClonedCaseIds);
            
            // clone feeds
            copyFeeds(map_MasterToClonedCaseIds);
            
            // inserting FeedItem to Add Cloned Case Comment
            if(!list_feedItemToInsert.isEmpty()){
                FeedCommentTriggerHelper.skipTrigger = true;
                FeedItemTriggerHelper.skipTrigger = true;
                insert list_feedItemToInsert;
            }
            
        } catch (Exception objException) {
            Database.rollback(sp);
            ExceptionLogUtil.logException('TaxComplianceCloneCaseHandler', 'getCaseClone', objException.getMessage(), objException.getStackTraceString());
        }
        
        return list_CasesCreated;
    }
    
    private static List<Case> createClonedCases(List<Case> list_OriginalCasesToClone, String strParentCaseId) {
        List<Case> list_ClonedCases = new List<Case>();
        for(Case objCase : list_OriginalCasesToClone) { 
            Case objClonedCase = new Case();
            objClonedCase = objCase.clone(false,false,false,false);
            objClonedCase.Status = CaseUtils.STATUS_NEW;
            objClonedCase.OCR_Message__c = CaseUtils.STRG_OCR_CREATED_FROM_CLONE_MSG;
            objClonedCase.ParentId = null;  // for parent case .
            if(String.isNotBlank(strParentCaseId)){
                objClonedCase.ParentId = strParentCaseId;
                objClonedCase.Source__c = objCase.Id;
            }
            
            list_ClonedCases.add(objClonedCase);
        }
        return list_ClonedCases;
    }
    
    private static List<Tax_Compliance__c> createClonedCompliance(List<Tax_Compliance__c> list_CompliancesToClone, Map<String,String> map_MasterToClonedCaseIds) {
        List<Tax_Compliance__c> list_ClonedCompliances = new List<Tax_Compliance__c>();
        
        for(Tax_Compliance__c objCompliance : list_CompliancesToClone) { 
            Tax_Compliance__c objCloneTaxCompliance = objCompliance.clone(false,false,false,false);
            
            if (objCloneTaxCompliance.Eng_Due_Date__c != null && objCloneTaxCompliance.Frequency_of_Update__c != null) {
                if (objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_ANNUAL){
                    objCloneTaxCompliance.Eng_Due_Date__c = objCloneTaxCompliance.Eng_Due_Date__c.addYears(1);
                }
                else  if(objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_QUARTERLY){
                    objCloneTaxCompliance.Eng_Due_Date__c = objCloneTaxCompliance.Eng_Due_Date__c.addMonths(3);
                }
                else  if(objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_BI_ANNUAL){
                    objCloneTaxCompliance.Eng_Due_Date__c = objCloneTaxCompliance.Eng_Due_Date__c.addMonths(6);
                }
            }
            
            if (objCloneTaxCompliance.Agency_Due_Date__c != null && objCloneTaxCompliance.Frequency_of_Update__c != null) {
                if (objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_ANNUAL){
                    objCloneTaxCompliance.Agency_Due_Date__c = objCloneTaxCompliance.Agency_Due_Date__c.addYears(1);
                }
                else  if(objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_QUARTERLY){
                    objCloneTaxCompliance.Agency_Due_Date__c = objCloneTaxCompliance.Agency_Due_Date__c.addMonths(3);
                }
                else  if(objCloneTaxCompliance.Frequency_of_Update__c == CaseUtils.STRG_FREQUENCT_OF_UPDATE_BI_ANNUAL){
                    objCloneTaxCompliance.Agency_Due_Date__c = objCloneTaxCompliance.Agency_Due_Date__c.addMonths(6);
                }
            }
            objCloneTaxCompliance.Case__c = map_MasterToClonedCaseIds.get(objCompliance.Case__c); // mapping the cloned case id
            //objCloneTaxCompliance.Original_Case__c = objCompliance.Case__c;
            list_ClonedCompliances.add(objCloneTaxCompliance);
        }
        return list_ClonedCompliances;
    }
    
    private static List<Tax_Questionnaire__c> createClonedQuestionnaire(List<Tax_Questionnaire__c> list_QuestionnaireToClone, Map<String,String> map_MasterToClonedCaseIds) {
        List<Tax_Questionnaire__c> list_ClonedQuestionnaireToInsert = new List<Tax_Questionnaire__c>();
        
        for(Tax_Questionnaire__c objQuestionnaire : list_QuestionnaireToClone) { 
            Tax_Questionnaire__c objClonedQuestionnaire = new Tax_Questionnaire__c();
            objClonedQuestionnaire = objQuestionnaire.clone(false,false,false,false);
            objClonedQuestionnaire.Case__c = map_MasterToClonedCaseIds.get(objClonedQuestionnaire.Case__c); // mapping the cloned case id
            list_ClonedQuestionnaireToInsert.add(objClonedQuestionnaire);
        }
        return list_ClonedQuestionnaireToInsert;
    }
    
    
    private static void createCaseRelatedChildRecords(Map<String,String> map_MasterToClonedCaseIds){
        List<String> list_TaxComplianceAllfields = new List<String>(Tax_Compliance__c.SObjectType.getDescribe().fields.getMap().keySet());
        Asana_Clone_Detail__mdt objAsanaCloneDetail = Asana_Clone_Detail__mdt.getInstance('Tax_Compliance_Skip_Fields');
        String strobjectFields = objAsanaCloneDetail?.Skip_Fields__c?.tolowercase();
        List<String> list_FieldsToNull = strobjectFields.split(',');
        List<String> list_TaxCompliancefields = new List<String>();
        for (String fieldName : list_TaxComplianceAllfields) {
            if (!list_FieldsToNull.contains(fieldName)) {
                list_TaxCompliancefields.add(fieldName);
            }
        }
        String strtaxCompliancesoql = String.join(list_taxCompliancefields, ',');
        
        List<String> list_TaxQuestionnairefields = new List<String>(Tax_Questionnaire__c.SObjectType.getDescribe().fields.getMap().keySet());
        
        String strtaxQuestionnairesoql = String.join(list_TaxQuestionnairefields, ',');
        
        List<Tax_Compliance__c> list_ClonedComplianceRecordsToInsert = new List<Tax_Compliance__c>();
        List<Tax_Questionnaire__c> list_ClonedQuestionnaireRecordsToInsert = new List<Tax_Questionnaire__c>();
        Map<String, Object> bindVars = new Map<String, Object>{'caseIds'=>map_MasterToClonedCaseIds.keyset(),'maintenanceRecordType'=>CaseUtils.RECTYPE_NAME_MAINTENACE_QUESTIONNAIRE};
        String strcasesoql = 'SELECT ID ,(SELECT '+strtaxCompliancesoql+' FROM Tax_Compliance__r),(SELECT '+strtaxQuestionnairesoql+ ' FROM Tax_Questionnaire__r WHERE RecordType.Name != :maintenanceRecordType) FROM Case WHERE Id =:caseIds ';
        // system.debug(casesoql);
        List<Case> list_CaseFetched = Database.queryWithBinds(strcasesoql,bindVars,AccessLevel.SYSTEM_MODE);
        
        for(Case objCase : list_CaseFetched){ 
            // clone compliance records
            if(objCase.Tax_Compliance__r.size() > 0){ 
                list_ClonedComplianceRecordsToInsert.addAll(createClonedCompliance(objCase.Tax_Compliance__r, map_MasterToClonedCaseIds)); 
            }
            // clone questionnaire records
            if(objCase.Tax_Questionnaire__r.size() > 0){ 
                list_ClonedQuestionnaireRecordsToInsert.addAll(createClonedQuestionnaire(objCase.Tax_Questionnaire__r, map_MasterToClonedCaseIds));
            }
        }
        
        // insert compliance records
        if(!list_ClonedComplianceRecordsToInsert.isEmpty()){
            insert list_ClonedComplianceRecordsToInsert;
        }
        
        // insert Questionnaire records
        if(!list_ClonedQuestionnaireRecordsToInsert.isEmpty()){
            insert list_ClonedQuestionnaireRecordsToInsert;
        }
    }
    
    
    private static void cloneAttachments(Map<String,String> map_masterToClonedCaseIds){
        
        List<ContentDocumentLink> list_ParentDocLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :map_masterToClonedCaseIds.keySet()];
        Map<Id, Id> map_linkedEntityContentDocument = new Map<Id, Id>();
        for (ContentDocumentLink objLink : list_ParentDocLinks) {
            map_linkedEntityContentDocument.put(objLink.ContentDocumentId,objLink.LinkedEntityId);
        }
        Map<Id, Id> map_oldContentDocumentTonewCase = new Map<Id, Id>();
        for(String strMasterCD : map_linkedEntityContentDocument.keySet()){
            map_oldContentDocumentTonewCase.put(strMasterCD, map_masterToClonedCaseIds.get(map_linkedEntityContentDocument.get(strMasterCD)));
        }
        // Query for the latest ContentVersion of each ContentDocumentId outside the loop
        Map<Id, ContentVersion> map_latestContentVersions = new Map<Id, ContentVersion>();
        for (ContentVersion objVersion : [SELECT Title, PathOnClient, VersionData, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :map_linkedEntityContentDocument.keyset() AND IsLatest = true]) {
            map_latestContentVersions.put(objVersion.ContentDocumentId, objVersion);
        }
        Map<Id, ContentVersion> map_newContentVersions = new Map<Id, ContentVersion>();
        // Create new ContentVersion records based on the queried latest versions
        for (Id contentDocumentId : map_latestContentVersions.keySet()) {
            ContentVersion objLatestVersion = map_latestContentVersions.get(contentDocumentId);
            if (objLatestVersion != null) {
                ContentVersion objNewVersion = new ContentVersion(
                    Title = objLatestVersion.Title,
                    PathOnClient = objLatestVersion.PathOnClient,
                    VersionData = objLatestVersion.VersionData,
                    FlowCreated__c = true
                );
                map_newContentVersions.put(contentDocumentId,objNewVersion);
            }
        }
        
        try{
            // Insert the new ContentVersion records in bulk
            if(map_newContentVersions!=null && !map_newContentVersions.keySet().isEmpty())insert map_newContentVersions.values();   
        } catch (Exception objException) {
            ExceptionLogUtil.logException('TaxComplianceCloneCaseHandler', 'cloneAttachments', objException.getMessage(), objException.getStackTraceString());
        }       
        Map<Id,Id> map_newCvToCd = new Map<Id,Id>();  
        for(Id contentdoc :map_newContentVersions.keyset()){
            map_newCvToCd.put(map_newContentVersions.get(contentdoc).Id,contentdoc);
        }
        
        // Query back to get ContentDocumentId for new ContentVersions
        Map<Id, ContentVersion> map_newVersionMap = new Map<Id, ContentVersion>();
        for (ContentVersion objVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :map_newContentVersions.values()]) {
            map_newVersionMap.put(objVersion.Id, objVersion);
        }
        // Create ContentDocumentLink for each new ContentDocument and child case
        List<ContentDocumentLink> list_newDocLinks = new List<ContentDocumentLink>();
        
        for (ContentVersion objNewVersion : map_newContentVersions.values()) {
            ContentDocumentLink objNewLink = new ContentDocumentLink(
                ContentDocumentId = map_newVersionMap.get(objNewVersion.Id).ContentDocumentId,
                LinkedEntityId = map_oldContentDocumentTonewCase.get(map_newCvToCd.get(objNewVersion.Id)),
                ShareType = CaseUtils.STR_V, // Adjust ShareType as necessary
                Visibility = CaseUtils.STR_ALLUSERS // Adjust Visibility as necessary
            );       
            if(!list_newDocLinks.contains(objNewLink)){
                list_newDocLinks.add(objNewLink);
            }
        }
        if(!list_newDocLinks.isEmpty()){
            //insert ContentDocLinks
            insert list_newDocLinks;  
        }  
    }
    
    private static void copyFeeds(Map<String,String> map_masterToClonedCaseIds) {
        List<FeedComment> list_feedCommentToInsert = new List<FeedComment>();
        Map<Id, FeedItem> map_oldIdNewFeedItem = new Map<Id, FeedItem>();
        Map<Id, FeedItem> map_feedItemToCopy = new Map<Id, FeedItem>(
            [
                SELECT
                BestCommentId,
                Body,
                CommentCount,
                CreatedById,
                CreatedDate,
                CreatedBy.IsActive,
                CreatedBy.Name,
                HasContent,
                HasLink,
                Id,
                Visibility,
                IsDeleted,
                LastEditById,
                LastEditDate,
                LastModifiedDate,
                LikeCount,
                LinkUrl,
                ParentId,
                RelatedRecordId,
                Revision,
                SystemModstamp,
                Title,
                Type,
                (SELECT CommentBody, CommentType, CreatedById, CreatedDate, FeedItemId, IsDeleted, LastEditById, LastEditDate, ParentId, RelatedRecordId, Revision FROM FeedComments)
                FROM FeedItem
                WHERE ParentId = :map_masterToClonedCaseIds.keySet() 
            ]
        );
        if (map_feedItemToCopy != null && map_feedItemToCopy.size() > 0) {
            for (FeedItem objoriginalFeed : map_feedItemToCopy.Values()) {
                FeedItem objnewFeedItem = objoriginalFeed.clone();
                objnewFeedItem.ParentId = map_masterToClonedCaseIds.get(objnewFeedItem.ParentId);
                objnewFeedItem.CreatedById = objoriginalFeed.CreatedById;
                objnewFeedItem.CreatedDate = objoriginalFeed.CreatedDate;
                map_oldIdNewFeedItem.put(objoriginalFeed.Id, objnewFeedItem);
            }
            if (map_oldIdNewFeedItem.size() > 0) {
                insert map_oldIdNewFeedItem.Values();
                for (Id oldFeedId : map_oldIdNewFeedItem.keyset()) {
                    if (map_feedItemToCopy.containskey(oldFeedId)) {
                        FeedItem objfeedItemToCopy = map_feedItemToCopy.get(oldFeedId);
                        for (FeedComment objFeedcomment : objfeedItemToCopy.FeedComments) {
                            FeedComment objnewFeedComment = objFeedcomment.Clone();
                            objnewFeedComment.FeedItemId = map_oldIdNewFeedItem.get(oldFeedId).Id;
                            objnewFeedComment.CreatedDate = objFeedcomment.CreatedDate;
                            list_feedCommentToInsert.add(objnewFeedComment);
                        }
                    }
                }
                if (list_feedCommentToInsert != null && list_feedCommentToInsert.size() > 0) {
                    insert list_feedCommentToInsert;
                }
            }
        }
    }
    private static FeedItem createFeedItem(String strCaseId,String strfeedItemParentId,String strCaseNumber,Boolean blnisParent){
        String url = '<html><b><a href="'+System.URL.getOrgDomainUrl().toExternalForm()+'/'+strCaseId+'">'+strCaseNumber+'</a></b></html>';    
        FeedItem feedItem = new FeedItem();      
        feedItem.Type = TaskUtil.FEED_ITEM_TYPE_TEXTPOST;
        if(blnisParent){
            feedItem.Body = 'This case is cloned to '+url;    
        }else{
            feedItem.Body = 'Case cloned from '+url;   
        }            
        feedItem.IsRichText = true;
        feedItem.ParentId = strfeedItemParentId;
        return feedItem;
    }
    
}