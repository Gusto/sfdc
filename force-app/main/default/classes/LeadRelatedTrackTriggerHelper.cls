/*
 *   By : Robin
 *   Created Date : 14-07-2017
 *
 */
public with sharing class LeadRelatedTrackTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;

	public void OnBeforeInsert(List<Lead_Related_Tracking__c> listLeadRelTrack) {
		processInformation(listLeadRelTrack);
	}

	public void OnBeforeUpdate(Map<ID, Lead_Related_Tracking__c> oldLeadRelTrackMap, Map<ID, Lead_Related_Tracking__c> newLeadRelTrackMap) {
		counter++;
		processInformation(newLeadRelTrackMap.values());
	}

	private void processInformation(List<Lead_Related_Tracking__c> listLeadRelTrack) {
		Set<Id> setOwnerIds = new Set<Id>();
		Set<Id> setLeadIds = new Set<Id>();
		List<Lead_Related_Tracking__c> listLeadRelTrackRecs = new List<Lead_Related_Tracking__c>();
		Map<Id, LeadWrapper> mapLeadToWrapper = new Map<Id, LeadWrapper>();
		setOwnerIds.add(UserInfo.getUserId());
		for (Lead_Related_Tracking__c objLeadRelTrack : listLeadRelTrack) {
			setOwnerIds.add(objLeadRelTrack.Lead_Owner__c);
			setLeadIds.add(objLeadRelTrack.Lead__c);
		}

		//Create map for businessHours record Id
		Map<Id, Id> mapUserToBusinessHourId = new Map<Id, Id>();
		List<BusinessHours> listBusinessHours = GlobalQueryHelper.getAllBusinessHoursList();

		for (User objUser : GlobalQueryHelper.getUsersByIdMap(setOwnerIds).values()) {
			for (BusinessHours objBusinessHour : listBusinessHours) {
				if (objBusinessHour.TimeZoneSidKey == objUser.TimeZoneSidKey) {
					mapUserToBusinessHourId.put(objUser.Id, objBusinessHour.Id);
				} else if (objBusinessHour.IsDefault == true) {
					mapUserToBusinessHourId.put(objUser.Id, objBusinessHour.Id);
				}
			}
		}

		for (Lead objLead : [
			SELECT
				Id,
				CreatedDate,
				LastModifiedDate,
				OwnerId,
				MQL_Date__c,
				MQL_DateTime__c,
				(
					SELECT Id, OwnerId, CreatedDate, RecordType.Name, CreatedBy.UserName, Type, Status
					FROM Tasks
					WHERE NOT CreatedBy.UserName LIKE 'sfdc+marketo@zenpayroll.com%'
					ORDER BY CreatedDate ASC
				)
			FROM Lead
			WHERE Id IN :setLeadIds
		]) {
			//Getting first activity date and call date
			DateTime firstActivityDate = null;
			DateTime firstActivityDateOwner;
			DateTime firstCallDate = null;
			// Gaurav : 16-Sep-19
			Date mqlDate;
			DateTime mqlDateTime;
			DateTime firstCallTimePostMQL; // MQL date
			DateTime firstActivityTimePostMQL;
			// Added by Gaurav
			DateTime firstCallDateOwner;

			integer attemptCount = 0;
			integer connectCount = 0;
			integer voicemailCount = 0;
			// Added by Gaurav
			integer ownerAttemptcount = 0;
			integer ownerConnectCount = 0;
			integer ownerVoicemailCount = 0;
			mqlDate = objLead.MQL_Date__c;
			mqlDateTime = objLead.MQL_DateTime__c;

			for (Task objTask : objLead.Tasks) {
				if (firstActivityDate == null) {
					firstActivityDate = objTask.CreatedDate;
				}
				if (objTask.recordType.Name == 'Call' && firstCallDate == null) {
					firstCallDate = objTask.CreatedDate;
					break;
				}
			}

			// Gaurav: firstCallTimePostMQL
			for (Task objTask : objLead.Tasks) {
				if (objTask.recordType.Name == 'Call' && firstCallTimePostMQL == null) {
					if (mqlDate != null && objTask.CreatedDate > mqlDate) {
						firstCallTimePostMQL = objTask.CreatedDate;
					}
				}
				if (firstActivityTimePostMQL == null) {
					if (mqlDate != null && objTask.CreatedDate > mqlDate) {
						firstActivityTimePostMQL = objTask.CreatedDate;
					}
				}
			}
			// // Added by Gaurav: Get first firstCallDateOwner for owner
			for (Task objTask : objLead.Tasks) {
				if ((objTask.Status.equalsIgnoreCase('Attempt') || objTask.Status.equalsIgnoreCase('Connect') || objTask.Status.equalsIgnoreCase('Voicemail')) && objLead.OwnerId == objTask.OwnerId) {
					firstCallDateOwner = objTask.CreatedDate;
					break;
				}
			}
			for (Task objTask : objLead.Tasks) {
				// Added by Gaurav
				if (objTask.Status.equalsIgnoreCase('Attempt') && objLead.OwnerId == objTask.OwnerId) {
					ownerAttemptcount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Connect') && objLead.OwnerId == objTask.OwnerId) {
					ownerConnectCount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Voicemail') && objLead.OwnerId == objTask.OwnerId) {
					ownerVoicemailCount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Attempt')) {
					attemptCount += 1;
				} else if (objTask.Status.equalsIgnoreCase('Connect')) {
					connectCount += 1;
				} else if (objTask.Status.equalsIgnoreCase('Completed')) {
					String type = '';
					if (objTask.Type != null) {
						type = objTask.Type;
					}
					if (type.indexOf('Demo') > -1) {
						connectCount += 1;
					}
				} else if (objTask.Status.equalsIgnoreCase('Voicemail')) {
					voicemailCount += 1;
				}
			}

			//Getting business hour Id
			Id businessHoursId;
			if (mapUserToBusinessHourId.size() > 0 && mapUserToBusinessHourId.containsKey(objLead.OwnerId)) {
				businessHoursId = mapUserToBusinessHourId.get(objLead.OwnerId);
			} else {
				businessHoursId = mapUserToBusinessHourId.get(UserInfo.getUserId());
			}

			mapLeadToWrapper.put(
				objLead.Id,
				new LeadWrapper(
					businessHoursId,
					objLead.CreatedDate,
					firstActivityDate,
					firstCallDate,
					firstCallDateOwner,
					attemptCount,
					connectCount,
					voiceMailCount,
					ownerAttemptcount,
					ownerConnectCount,
					ownerVoicemailCount,
					mqlDate,
					mqlDateTime,
					firstCallTimePostMQL,
					firstActivityTimePostMQL
				)
			);
		}

		for (Lead_Related_Tracking__c objLeadRelTrack : listLeadRelTrack) {
			if (mapLeadToWrapper.containsKey(objLeadRelTrack.Lead__c)) {
				LeadWrapper wrap = mapLeadToWrapper.get(objLeadRelTrack.Lead__c);
				Id businessHoursId = wrap.BusinessHourId;
				DateTime leadCreatedDate = wrap.leadCreatedDate;
				DateTime firstActivityDate = wrap.FirstActivityDate;
				DateTime firstCallDate = wrap.FirstCallDate;
				DateTime firstCallDateOwner = wrap.firstCallDateOwner;
				// Gaurav : 16-Sep-19
				DateTime mqlDT = wrap.mqlDateTimeSt;

				DateTime firstCallTimePostMQL = wrap.firstCallTimePostMQL;
				DateTime firstActivityTimePostMQL = wrap.firstActivityTimePostMQL;

				// first activity date
				if (objLeadRelTrack.First_Activity_Date__c == null && firstActivityDate != null) {
					objLeadRelTrack.First_Activity_Date__c = firstActivityDate;
					objLeadRelTrack.Time_To_First_Activity__c = Utils.businessHours(businessHoursId, leadCreatedDate, firstActivityDate);
				}

				//first call date
				if (objLeadRelTrack.First_Call_Date__c == null && firstCallDate != null) {
					objLeadRelTrack.First_Call_Date__c = firstCallDate;
					objLeadRelTrack.Time_To_First_Call__c = Utils.businessHours(businessHoursId, leadCreatedDate, firstCallDate);
					objLeadRelTrack.Time_To_First_Call_minutes__c = Utils.businessminutes(businessHoursId, leadCreatedDate, firstCallDate);
				}
				// Added by Gaurav
				if (firstCallDateOwner != null) {
					objLeadRelTrack.Time_to_First_Call_by_Owner__c = Utils.businessminutes(businessHoursId, leadCreatedDate, firstCallDateOwner);
				}
				if (objLeadRelTrack.MQL_Datetime__c == null && mqlDT != null) {
					objLeadRelTrack.MQL_Datetime__c = mqlDT;
				}
				// Gaurav : 16-Sep-19
				if (mqlDT != null && firstCallTimePostMQL != null) {
					objLeadRelTrack.Time_to_first_call_post_MQL__c = Utils.businessminutes(businessHoursId, mqlDT, firstCallTimePostMQL);
				}
				if (objLeadRelTrack.First_call_time_post_MQL__c == null && firstCallTimePostMQL != null) {
					objLeadRelTrack.First_call_time_post_MQL__c = firstCallTimePostMQL;
				}
				if (objLeadRelTrack.First_activity_time_post_MQL__c == null && firstActivityTimePostMQL != null) {
					objLeadRelTrack.First_activity_time_post_MQL__c = firstActivityTimePostMQL;
				}
				objLeadRelTrack.Attempts__c = wrap.attemptCount;
				objLeadRelTrack.Connects__c = wrap.connectCount;
				objLeadRelTrack.Voicemails__c = wrap.voiceMailCount;
				// Added by Gaurav
				objLeadRelTrack.Attempts_by_Owner__c = wrap.ownerAttemptcount;
				objLeadRelTrack.Connects_by_Owner__c = wrap.ownerConnectCount;
				objLeadRelTrack.Voicemails_by_Owner__c = wrap.ownerVoicemailCount;
			}
		}
	}

	public class LeadWrapper {
		Id businessHourId;
		DateTime leadCreatedDate;
		DateTime firstActivityDate;
		DateTime firstCallDate;
		DateTime firstCallDateOwner;
		// Gaurav: 16-Sep-19
		Date mqlDate;
		DateTime mqlDateTimeSt;
		DateTime firstCallTimePostMQL;
		DateTime firstActivityTimePostMQL;
		Integer attemptCount;
		Integer connectCount;
		Integer voiceMailCount;
		// added : Gaurav
		Integer ownerAttemptcount;
		Integer ownerConnectCount;
		Integer ownerVoicemailCount;
		// Updated: Gaurav
		public LeadWrapper(
			Id businessHrId,
			DateTime leadCreated,
			DateTime firstActivity,
			DateTime firstCall,
			DateTime ownerfirstCallDate,
			Integer attempt,
			Integer connect,
			Integer voiceMail,
			Integer ownerAttempt,
			Integer ownerConnect,
			Integer ownerVoicemail,
			Date mqlDateTime,
			DateTime mqlDTSt,
			DateTime firstCallPostMQL,
			DateTime firstActivityPostMQL
		) {
			businessHourId = businessHrId;
			leadCreatedDate = leadCreated;
			firstActivityDate = firstActivity;
			firstCallDate = firstCall;
			attemptCount = attempt;
			connectCount = connect;
			voiceMailCount = voiceMail;
			// Added: Gaurav
			ownerAttemptcount = ownerAttempt;
			ownerConnectCount = ownerConnect;
			ownerVoicemailCount = ownerVoicemail;
			firstCallDateOwner = ownerfirstCallDate;
			mqlDate = mqlDateTime;
			mqlDateTimeSt = mqlDTSt;
			firstCallTimePostMQL = firstCallPostMQL;
			firstActivityTimePostMQL = firstActivityPostMQL;
		}
	}
}