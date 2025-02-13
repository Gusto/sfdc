/**
 * @name         ContentVersionTriggerHelper
 * @author       Neha Dabas
 * @date         19th June 2020
 * @description  Methods to execute on ContentVersionTrigger events
 * @test class   ContentVersionTriggerTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public without sharing class ContentVersionTriggerHelper {
	public static Boolean skipTrigger = false;
	public static String strBatch = 'batch';
	public static String strStatusProcessed = 'Processed';
	public static final String ERRORMSG_CASE_NOT_FOUND = 'Case doesnot exist.', SUCCESSMSG_FORM_ATTACHED = 'Form attached to Event and Case';
	public void onBeforeInsert(List<ContentVersion> list_ContentVersions) {
		if (list_ContentVersions == null || list_ContentVersions.isEmpty()) {
			return;
		}
		Map<String, List<ContentVersion>> map_ContentVersionPerCarrierEvent = new Map<String, List<ContentVersion>>();
		for (ContentVersion objCV : list_ContentVersions) {
			List<ContentVersion> list_CVCarrierEvent;
			if (
				objCV.HI_Fulfillment_Event_Id__c != null &&
				String.isNotBlank(objCV.HI_Fulfillment_Event_Id__c) &&
				objCV.State_Carrier_Key__c != null &&
				String.isNotBLank(objCV.State_Carrier_Key__c)
			) {
				String strCarrierEventKey = objCV.HI_Fulfillment_Event_Id__c + '-' + objCV.State_Carrier_Key__c;
				if (map_ContentVersionPerCarrierEvent.containsKey(strCarrierEventKey)) {
					list_CVCarrierEvent = map_ContentVersionPerCarrierEvent.get(strCarrierEventKey);
				} else {
					list_CVCarrierEvent = new List<ContentVersion>();
				}
				list_CVCarrierEvent.add(objCV);
				map_ContentVersionPerCarrierEvent.put(strCarrierEventKey, list_CVCarrierEvent);
			}
		}

		if (!map_ContentVersionPerCarrierEvent.isEmpty()) {
			linkFormWithCase(map_ContentVersionPerCarrierEvent, 'trigger');
		}
		for (ContentVersion objCV : list_ContentVersions) {
			if (objCV.Processing_State__c != strStatusProcessed) {
				objCV.Message__c = ERRORMSG_CASE_NOT_FOUND;
				objCV.Processing_State__c = 'Error';
			}
		}
	}

	public void linkFormWithCase(Map<String, List<ContentVersion>> map_ContentVersionPerCarrierEvent, String strSource) {
		if (map_ContentVersionPerCarrierEvent == null && map_ContentVersionPerCarrierEvent.isEmpty()) {
			return;
		}
		//get case for the event ids
		List<Case> list_Cases = new List<Case>();
		list_Cases = [SELECT Id, Integration_Key__c FROM Case WHERE Integration_Key__c IN :map_ContentVersionPerCarrierEvent.keySet()];
		if (list_Cases == null || list_Cases.isEmpty()) {
			return;
		}

		//Create ContentLink for each Form, to link it to the corresponsing HI_Fulfillment_Event
		List<Attachment> list_Attachments = new List<Attachment>();
		List<ContentVersion> list_CVersionToUpdate = new List<ContentVersion>();
		for (Case objCase : list_Cases) {
			List<ContentVersion> list_CV = map_ContentVersionPerCarrierEvent.get(objCase.Integration_Key__c);
			for (ContentVersion objCV : list_CV) {
				Attachment objAttachment = new Attachment(Body = objCV.VersionData, ParentId = objCase.Id, Name = objCV.PathOnClient);

				if (objCV.FileType != null && objCV.FileType.containsIgnoreCase('pdf')) {
					objAttachment.ContentType = 'application/pdf';
				}
				list_Attachments.add(objAttachment);

				if (strSource.equalsIgnoreCase(strBatch)) {
					ContentVersion objUpdatedCV = new ContentVersion();
					objUpdatedCV.Id = objCV.Id;
					objUpdatedCV.Message__c = SUCCESSMSG_FORM_ATTACHED;
					objUpdatedCV.Processing_State__c = strStatusProcessed;
					list_CVersionToUpdate.add(objUpdatedCV);
				} else {
					objCV.Message__c = SUCCESSMSG_FORM_ATTACHED;
					objCV.Processing_State__c = strStatusProcessed;
				}
			}
		}
		if (strSource.equalsIgnoreCase(strBatch) && !list_CVersionToUpdate.isEmpty()) {
			update list_CVersionToUpdate;
		}
		if (!list_Attachments.isEmpty()) {
			insert list_Attachments;
		}
	}
}