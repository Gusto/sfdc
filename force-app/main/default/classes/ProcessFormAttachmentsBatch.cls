/**
 * @name         ProcessFormAttachmentsBatch
 * @author       Neha Dabas
 * @date         22nd June 2020
 * @description  Process the form attachments in ContentVersion object and link them with Events and Cases
 * @test class   ProcessFormAttachmentsSchedulerTest
 * @revisions    Date ------------ Name ------------ Comments
 */
global with sharing class ProcessFormAttachmentsBatch implements Database.Batchable<SObject> {
	global Database.QueryLocator start(Database.BatchableContext bContext) {
		//to get the no. of days for which we want to process ContentVersion records
		Configuration_Settings__c configRec = Configuration_Settings__c.getOrgDefaults();

		String strQuery = 'SELECT PathOnClient,ContentDocumentId,Title,FileType,Message__c,HI_Fulfillment_Event_Id__c,State_Carrier_Key__c,VersionData FROM ContentVersion';
		strQuery += ' WHERE Processing_State__c = \'Error\' AND State_Carrier_Key__c != NULL AND HI_Fulfillment_Event_Id__c != NULL';

		if (configRec != null && configRec.Process_Form_Automation_n_Days__c != null) {
			strQuery += ' AND CreatedDate = LAST_N_DAYS:' + Integer.valueOf(configRec.Process_Form_Automation_n_Days__c);
		} else {
			strQuery += ' AND CreatedDate = LAST_N_DAYS:4';
		}

		return Database.getQueryLocator(strQuery);
	}
	global void Execute(Database.BatchableContext bContext, List<ContentVersion> list_ContentVersions) {
		try {
			if (list_ContentVersions == null || list_ContentVersions.isEmpty()) {
				return;
			}
			ContentVersionTriggerHelper helper = new ContentVersionTriggerHelper();
			Map<String, List<ContentVersion>> map_ContentVersionPerCarrierEvent = new Map<String, List<ContentVersion>>();

			for (ContentVersion objCV : list_ContentVersions) {
				List<ContentVersion> list_CVCarrierEvent;
				String strCarrierEventKey = objCV.HI_Fulfillment_Event_Id__c + '-' + objCV.State_Carrier_Key__c;
				if (map_ContentVersionPerCarrierEvent.containsKey(strCarrierEventKey)) {
					list_CVCarrierEvent = map_ContentVersionPerCarrierEvent.get(strCarrierEventKey);
				} else {
					list_CVCarrierEvent = new List<ContentVersion>();
				}
				list_CVCarrierEvent.add(objCV);
				map_ContentVersionPerCarrierEvent.put(strCarrierEventKey, list_CVCarrierEvent);
			}

			if (!map_ContentVersionPerCarrierEvent.isEmpty()) {
				helper.linkFormWithCase(map_ContentVersionPerCarrierEvent, 'batch');
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('ProcessFormAttachmentsBatch', 'Execute', objEx.getMessage(), objEx.getStackTraceString());
		}
	}
	global void finish(Database.BatchableContext bContext) {
	}
}