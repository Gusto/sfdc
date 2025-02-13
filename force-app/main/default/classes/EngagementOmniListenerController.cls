/**
 * @name         : EngagementOmniListenerController
 * @author       : Sanjay Paryani
 * @date         : 08/24/2023
 * @description  : Omni Listener Controller to update case status to log the Agent Work records
 **/
public without sharing class EngagementOmniListenerController {
	public static final Decimal CASE_RECORD_UPDATE_LIMIT = Test.isRunningTest() ? 3 : 10;
	public static final String STATUS_CLOSED = 'Closed';
	public static final String STATUS_INPROGRESS = 'In Progress';
	public static final String STATUS_OPEN = 'Open';
	public static final String STATUS_OPENED = 'Opened';
	public static final String PRESENCE_STATUS_EMAIL_AVAILABLE = 'Email - Available';
	public static final Id RECTYPE_ENGAGEMENT = Cache.getRecordTypeId('Case', 'Engagement');
	public static final Id USER_ID = UserInfo.getUserId();
	public static final String ORIGIN_EMAIL = 'Email';
	public static final String ORIGIN_GUSTO = 'Gusto';
	public static final String CHANNEL_EMAIL = 'Email';
	public static final String SERVICE_CASE = 'Case';
	public static Map<String, ServiceChannel> map_AllServiceChannels = getAllServiceChannelsMap();
	public static final String SERVICECHANNEL_CASE = map_AllServiceChannels.get(SERVICE_CASE).Id;

	public EngagementOmniListenerController() {
	}

	/**
	 * @author      Sanjay Paryani
	 * @description Get all the service channels for the org
	 * @param       void
	 * @return      List of all ServiceChannels
	 **/
	public static Map<String, ServiceChannel> getAllServiceChannelsMap() {
		if (map_AllServiceChannels == null) {
			map_AllServiceChannels = new Map<String, ServiceChannel>();
			for (ServiceChannel objChannel : [SELECT Id, DeveloperName FROM ServiceChannel]) {
				map_AllServiceChannels.put(objChannel.DeveloperName, objChannel);
			}
		}

		return map_AllServiceChannels;
	}

	/*
	 * @Author:          Sanjay Paryani
	 * @Description:     Method to update Case Status based on Presence status of the Agent
	 * @Parm:            String strPresenceStatus
	 * @Return:          N/A
	 */
	@AuraEnabled
	public static void updateCaseStatus(String strPresenceStatus) {
		List<Case> list_Cases = new List<Case>();
		Set<Id> set_OpenCaseIds = new Set<Id>();
		Set<Id> set_CaseIds = new Set<Id>();

		try {
			if (strPresenceStatus == PRESENCE_STATUS_EMAIL_AVAILABLE) {
				for (Case objCase : [
					SELECT Id
					FROM Case
					WHERE OwnerId = :USER_ID AND Status = :STATUS_OPEN AND RecordTypeId = :RECTYPE_ENGAGEMENT AND (Origin = :ORIGIN_EMAIL OR (Origin = :ORIGIN_GUSTO AND Channel__c = :CHANNEL_EMAIL))
					ORDER BY LastModifiedDate DESC
				]) {
					objCase.Status = STATUS_INPROGRESS;

					list_Cases.add(objCase);
				}
			}

			if (!list_Cases.isEmpty()) {
				if (list_Cases.size() <= CASE_RECORD_UPDATE_LIMIT) {
					CaseTriggerHelper.skipTrigger = true;
					update list_Cases;
					CaseTriggerHelper.skipTrigger = false;
				} else if (list_Cases.size() > CASE_RECORD_UPDATE_LIMIT) {
					CaseTriggerHelper.skipTrigger = true;
					BatchDML.Operation objUpdate = BatchDML.Operation.UPD;
					ID jobID = System.enqueueJob(new BatchDML(objUpdate, list_Cases, false));
					CaseTriggerHelper.skipTrigger = false;
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('EngagementOmniListenerController', 'updateCaseStatus', objEx.getMessage(), objEx.getStackTraceString());
		}
	}
}