/**
 * @name         ContentDocumentTriggerHelper
 * @author       Sindhu
 * @date         27th March 2024
 * @description  Methods to execute on ContentDocumentTrigger events
 * @test class   ContentDocumentTriggerTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public without sharing class ContentDocumentTriggerHelper {
    public static Boolean skipTrigger = false;
    public static final String ERRORMSG_CASE_NOT_FOUND = 'Case doesnot exist.';
    public static final String SUCCESSMSG_FORM_ATTACHED = 'Form attached to Event and Case';

    public void processBeforeDelete(List<ContentDocument> list_ContentDocuments) {
        if (list_ContentDocuments == null || list_ContentDocuments.isEmpty()) {
                return;
        }
        
        Set<Id> set_DocIds = new Set<Id>();
        for(ContentDocument objContentDocument : list_ContentDocuments) { 
            set_DocIds.add(objContentDocument.Id);
        }

        List<ContentVersion> list_ContentVersions = [SELECT Id, ContentDocumentId, FlowCreated__c FROM ContentVersion WHERE ContentDocumentId IN :set_DocIds];
        
        Map<String, Boolean> map_ContentDocs = new Map<String,boolean>(); // Map with content document id as a key and flow created as a value
        for(ContentVersion objContentVersion : list_ContentVersions) {

            if (objContentVersion.FlowCreated__c) {
                map_ContentDocs.put(objContentVersion.ContentDocumentId,true);
            } else {
                map_ContentDocs.put(objContentVersion.ContentDocumentId,false);
            }
        }

        for (ContentDocument objContentDocument : list_ContentDocuments) {
            if (map_ContentDocs.containsKey(objContentDocument.Id)) {
                if (map_ContentDocs.get(objContentDocument.Id)) {
                    objContentDocument.addError('This ContentVersion cannot be deleted because it is Copied from Parent Case.');
                }
            }
        }
    }
 }