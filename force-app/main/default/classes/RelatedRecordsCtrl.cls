/**
 * @description  Find the related records
 * @author       Bhagat Singh
 * @date         07/15/2024
 * @see          RelatedRecordsCtrlTest.cls
 **/
public with sharing class RelatedRecordsCtrl {
	public static String strBlankURLMsg = 'Please enter a URL.';
	public static String strInvalidURLMsg = 'This url format is not recognized, please update and try again.';
	public static String strLWCToClassicMsg = 'Your lightning link has successfully been converted to a classic link!';
	public static String strClassicToLWCMsg = 'Your classic link has successfully been converted to a lightning link!';
	public static String strClassicURL = URL.getOrgDomainURL().toExternalForm();
	//public static String strBenefitsFulfillmentRT = TaskUtil.TASK_BENEFIT_FULFILLMENT_RT_ID;
	public static String strBenefitsFulfillmentRT = 'Benefits Fulfillment';
	public static String strCompleted = TaskUtil.TASK_STATUS_COMPLETE;

	/**
	 * @description Returns a open ticket related to carrier order.
	 * @author      Bhagat Singh
	 * @param       Id of Carrier Order.
	 * @return      Object of Ticket record.
	 **/
	@AuraEnabled
	public static Ticket__c getOpenTicketIdWithCO(Id idCORecord) {
		Ticket__c objOpenTicket = new Ticket__c();
		String strClosedStatus = TicketUtil.TICKET_STATUS_CLOSED;
		if (idCORecord != null) {
			for (Carrier_Order__c objCO : [
				SELECT Id, OwnerId, Ticket_Action_Required__c, (SELECT Id, Name, OwnerId FROM Tickets__r WHERE Status__c != :strClosedStatus)
				FROM Carrier_Order__c
				WHERE Id = :idCORecord
			]) {
				if (objCO.Tickets__r?.size() > 0) {
					for (Ticket__c objTicket : objCO.Tickets__r) {
						if (objTicket.OwnerId == objCO.OwnerId) {
							objOpenTicket = objTicket;
						}
					}
				}
			}
		}

		return objOpenTicket;
	}

	/**
	 * @description Convert classic links into lightning and vice versa
	 * @author      Bhagat Singh
	 * @param       String of URL
	 * @return      Object of WrapperUrl record.
	 **/
	@AuraEnabled
	public static WrapperUrl convertURL(String strInputUrl, String strBaseURL) {
		WrapperUrl objWrapper = new WrapperUrl();
		List<String> list_URLElements = new List<String>();
		String strObjectAPIName = '';

		if (String.isBlank(strInputUrl)) {
			objWrapper.blnValidUrl = false;
			objWrapper.strOutputUrl = '';
			objWrapper.strMessage = strBlankURLMsg;
		} else {
			strInputUrl = strInputUrl.trim();
			objWrapper.strOutputUrl = '';
			objWrapper.blnValidUrl = false;
			objWrapper.strMessage = strInvalidURLMsg;
			String strInputValue = '';

			if (strInputUrl.contains(strBaseURL)) {
				strInputValue = strInputUrl.replace(strBaseURL, '');
				list_URLElements = strInputValue.split('/');
				if (list_URLElements?.size() > 4) {
					if (list_URLElements[4].contains('list')) {
						objWrapper.strOutputUrl = strClassicURL + '/'  + getObjectKeyPrefix(list_URLElements[3]);
					} else {
						objWrapper.strOutputUrl = strClassicURL + '/'  + list_URLElements[4];
					}
					objWrapper.blnValidUrl = true;
					objWrapper.strMessage = strLWCToClassicMsg;
				}
			} else if (strInputUrl.contains(strClassicURL)) {
				strInputValue = strInputUrl.replace(strClassicURL, '');
				list_URLElements = strInputValue.split('/');
				if (list_URLElements?.size() > 1) {
					try {
						if (list_URLElements[1].length() == 15 || list_URLElements[1].length() == 18) {
							Id idRecord = list_URLElements[1]; 
							strObjectAPIName = idRecord.getsobjecttype() + '';
							objWrapper.strOutputUrl = strBaseURL + '/lightning/r/' + strObjectAPIName + '/'  + list_URLElements[1] + '/view';
							objWrapper.blnValidUrl = true;
							objWrapper.strMessage = strClassicToLWCMsg;
						}
					} catch (Exception objExp) {
						objWrapper.strMessage = strInvalidURLMsg;
					}
				}
			}
		}

		return objWrapper;
	}

	public static String getObjectKeyPrefix(String strObjectName){
		Schema.sObjectType objType = Schema.getGlobalDescribe().get(strObjectName);
		return objType.getDescribe().getKeyPrefix();
	}

	/**
	 * @description Returns a open Task related to carrier order.
	 * @author      Bhagat Singh
	 * @param       Id of Carrier Order.
	 * @return      Object of Ticket record.
	 **/
	@AuraEnabled
	public static List<TaskWrapper> getOpenTaskWithCO(Id idCORecord) {
		List<TaskWrapper> list_Task = new List<TaskWrapper>();
		
		if (idCORecord != null) {
			for (Task objTask :[
				SELECT Id, Status, TaskSubtype, Type__c, ActivityDate, WhatId, Subject
				FROM Task
				WHERE WhatId = :idCORecord AND RecordType.Name = :strBenefitsFulfillmentRT AND Status != :strCompleted
			]) {
				TaskWrapper objWrapper = new TaskWrapper();
				objWrapper.idTask = objTask.Id;
				objWrapper.strSubject = objTask.Subject;
				objWrapper.strInfo = 'Status: ' + objTask.Status + '   -   Type: ' + objTask.Type__c;
				list_Task.add(objWrapper);
			}
		}

		return list_Task;
	}

	public class WrapperUrl {
		@AuraEnabled public String strOutputUrl;
		@AuraEnabled public Boolean blnValidUrl;
		@AuraEnabled public String strMessage;
	}

	public class TaskWrapper {
		@AuraEnabled public Id idTask;
		@AuraEnabled public String strInfo;
		@AuraEnabled public String strSubject;
	}
}