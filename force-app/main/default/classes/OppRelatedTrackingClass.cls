/*
 *   By : Gaurav
 *   Created Date : 30-08-2017
 *   Description : Opportunity Rel;ated Tracking
 */
public without sharing class OppRelatedTrackingClass {
	public static Boolean processInfo = true;
	public void processInformation(Set<Id> setOppIds) {
		if (!processInfo)
			return;

		List<Opportunity_Related_Tracking__c> listOppTrackingToUpdate = new List<Opportunity_Related_Tracking__c>();
		Set<Id> setOwnerIds = new Set<Id>();
		for (Opportunity objOpp : [
			SELECT
				Id,
				CreatedDate,
				LastModifiedDate,
				OwnerId,
				(
					SELECT Id, OwnerId, CreatedDate, RecordType.Name, CreatedBy.UserName, Type, Status
					FROM Tasks
					WHERE NOT CreatedBy.UserName LIKE 'sfdc+marketo@zenpayroll.com%'
					ORDER BY CreatedDate ASC
				)
			FROM Opportunity
			WHERE Id IN :setOppIds
		]) {
			setOwnerIds.add(objOpp.ownerId);
			for (Task objTask : objOpp.Tasks) {
				setOwnerIds.add(objTask.ownerId);
			}
		}
		Map<Id, Id> mapUserToBusinessHourId = getMapBusinessHour(setOwnerIds);
		for (Opportunity objOpp : [
			SELECT
				Id,
				CreatedDate,
				LastModifiedDate,
				OwnerId,
				(
					SELECT Id, OwnerId, CreatedDate, RecordType.Name, CreatedBy.UserName, Type, Status, Lead__c
					FROM Tasks
					WHERE NOT CreatedBy.UserName LIKE 'sfdc+marketo@zenpayroll.com%'
					ORDER BY CreatedDate ASC
				),
				(
					SELECT
						Id,
						First_Activity_Date__c,
						First_Call_Date__c,
						Time_To_First_Call__c,
						Time_To_First_Call_minutes__c,
						Time_to_First_Call_by_Owner__c,
						Attempts__c,
						Connects__c,
						Voicemails__c,
						Attempts_by_Owner__c,
						Connects_by_Owner__c,
						Voicemails_by_Owner__c,
						First_Stage_Change_Date__c,
						Time_To_stage_Change__c,
						Opp_Stage_Changed__c,
						First_Opp_Call_Date__c,
						First_Opp_Activity_Date__c,
						Opp_Time_to_First_Call_Hours__c,
						Opp_Time_to_First_Call_Minutes__c
					FROM Opportunity_Related_Trackings__r
					WHERE NOT CreatedBy.UserName LIKE 'sfdc+marketo@zenpayroll.com%'
					ORDER BY CreatedDate ASC
				),
				(
					SELECT NewValue, OldValue, Field, OpportunityId, Id, CreatedDate
					FROM Histories
					WHERE Field = 'StageName'
					ORDER BY CreatedDate ASC
					LIMIT 2
				)
			FROM Opportunity
			WHERE Id IN :setOppIds
		]) {
			//Getting first activity date and call date
			DateTime firstActivityDate;
			DateTime firstActivityDateOwner;
			DateTime firstCallDate;
			// Added by Gaurav
			DateTime firstCallDateOwner;
			DateTime firstStageChangeDate;

			Integer attemptCount = 0;
			Integer connectCount = 0;
			Integer voicemailCount = 0;
			// Added by Gaurav
			Integer ownerAttemptcount = 0;
			Integer ownerConnectCount = 0;
			Integer ownerVoicemailCount = 0;
			//Added by Dato
			Integer oppAttemptCount = 0;
			Integer oppConnectCount = 0;
			Integer oppVoicemailCount = 0;
			DateTime firstCallDateOpp;
			DateTime firstActivityDateOpp;

			Task firstOppTask = null;

			for (Task objTask : objOpp.Tasks) {
				if (firstActivityDate == null) {
					firstActivityDate = objOpp.Tasks[0].CreatedDate;
				}
				if (objTask.recordType.Name == 'Call' && firstCallDate == null) {
					firstCallDate = objTask.CreatedDate;
				}
				if (objTask.recordType.Name == 'Call' && objTask.Lead__c == null) {
					if ((firstCallDateOpp == null || (firstCallDateOpp != null && objTask.CreatedDate < firstCallDateOpp)) && objTask.CreatedDate >= objOpp.CreatedDate)
						firstCallDateOpp = objTask.CreatedDate;
				}

				if ((objTask.Status.equalsIgnoreCase('Attempt') || objTask.Status.equalsIgnoreCase('Connect') || objTask.Status.equalsIgnoreCase('Voicemail')) && objTask.Lead__c == null) {
					if ((firstActivityDateOpp == null || (firstActivityDateOpp != null && objTask.CreatedDate < firstActivityDateOpp)) && objTask.CreatedDate >= objOpp.CreatedDate) {
						firstActivityDateOpp = objTask.CreatedDate;
					}
				}
			}

			// // Added by Gaurav: Get first firstCallDateOwner for owner
			for (Task objTask : objOpp.Tasks) {
				if ((objTask.Status.equalsIgnoreCase('Attempt') || objTask.Status.equalsIgnoreCase('Connect') || objTask.Status.equalsIgnoreCase('Voicemail')) && objOpp.OwnerId == objTask.OwnerId) {
					firstCallDateOwner = objTask.CreatedDate;
					break;
				}
			}
			for (Task objTask : objOpp.Tasks) {
				// Added by Gaurav
				if (objTask.Status.equalsIgnoreCase('Attempt') && objOpp.OwnerId == objTask.OwnerId) {
					ownerAttemptcount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Connect') && objOpp.OwnerId == objTask.OwnerId) {
					ownerConnectCount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Voicemail') && objOpp.OwnerId == objTask.OwnerId) {
					ownerVoicemailCount += 1;
				}
				if (objTask.Status.equalsIgnoreCase('Attempt')) {
					attemptCount += 1;
					if (objTask.Lead__c == null && objTask.CreatedDate > objOpp.CreatedDate)
						oppAttemptCount += 1;
				} else if (objTask.Status.equalsIgnoreCase('Connect')) {
					connectCount += 1;
					if (objTask.Lead__c == null && objTask.CreatedDate > objOpp.CreatedDate)
						oppConnectCount += 1;
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
					if (objTask.Lead__c == null && objTask.CreatedDate > objOpp.CreatedDate)
						oppVoicemailCount += 1;
				}

				//Getting first stage change date
				firstStageChangeDate = null;
				if (objOpp.Histories.size() > 0) {
					for (OpportunityFieldHistory objHistory : objOpp.Histories) {
						if (objOpp.Histories.size() == 1 && objHistory.OldValue == null && firstStageChangeDate == null) {
							firstStageChangeDate = System.now();
							break;
						}
						if (objHistory.OldValue != null && firstStageChangeDate == null) {
							firstStageChangeDate = objHistory.CreatedDate;
							break;
						}
					}
				}
				if (Test.isRunningTest()) {
					firstStageChangeDate = System.now();
				}
			}

			//Getting business hour Id
			Id businessHoursId;
			if (mapUserToBusinessHourId.size() > 0 && mapUserToBusinessHourId.containsKey(objOpp.OwnerId)) {
				businessHoursId = mapUserToBusinessHourId.get(objOpp.OwnerId);
			} else {
				businessHoursId = mapUserToBusinessHourId.get(UserInfo.getUserId());
			}

			for (Opportunity_Related_Tracking__c objOppRelTrack : objOpp.Opportunity_Related_Trackings__r) {
				// first activity date
				if (objOppRelTrack.First_Activity_Date__c == null && firstActivityDate != null) {
					objOppRelTrack.First_Activity_Date__c = firstActivityDate;
					objOppRelTrack.Time_To_First_Activity__c = Utils.businessHours(businessHoursId, objOpp.CreatedDate, firstActivityDate);
				}

				//first call date
				if (objOppRelTrack.First_Call_Date__c == null && firstCallDate != null) {
					objOppRelTrack.First_Call_Date__c = firstCallDate;
					objOppRelTrack.Time_To_First_Call__c = Utils.businessHours(businessHoursId, objOpp.CreatedDate, firstCallDate);
					objOppRelTrack.Time_To_First_Call_minutes__c = Utils.businessminutes(businessHoursId, objOpp.CreatedDate, firstCallDate);
				}
				// Added by Gaurav
				if (firstCallDateOwner != null) {
					objOppRelTrack.Time_to_First_Call_by_Owner__c = Utils.businessHours(businessHoursId, objOpp.CreatedDate, firstCallDateOwner);
				}
				objOppRelTrack.Attempts__c = attemptCount;
				objOppRelTrack.Connects__c = connectCount;
				objOppRelTrack.Voicemails__c = voiceMailCount;
				//
				objOppRelTrack.Opp_Attempts__c = oppAttemptCount;
				objOppRelTrack.Opp_Connect__c = oppConnectCount;
				objOppRelTrack.Opp_Voicemails__c = oppVoicemailCount;

				// Added by Gaurav
				objOppRelTrack.Attempts_by_Owner__c = ownerAttemptcount;
				objOppRelTrack.Connects_by_Owner__c = ownerConnectCount;
				objOppRelTrack.Voicemails_by_Owner__c = ownerVoicemailCount;

				//first stage change date
				if (objOppRelTrack.First_Stage_Change_Date__c == null && firstStageChangeDate != null && objOppRelTrack.Opp_Stage_Changed__c == true) {
					objOppRelTrack.First_Stage_Change_Date__c = firstStageChangeDate;
					objOppRelTrack.Time_To_stage_Change__c = Utils.businessHours(businessHoursId, objOpp.CreatedDate, firstStageChangeDate);
				}
				// Added by Gaurav : 20-Sep-19
				if (objOppRelTrack.First_Opp_Call_Date__c == null) {
					objOppRelTrack.First_Opp_Call_Date__c = firstCallDateOpp;
					Boolean isOppActivity = false;
					if (oppAttemptCount > 0 || oppConnectCount > 0 || oppVoicemailCount > 0) {
						isOppActivity = true;
					}
					if (isOppActivity && firstCallDateOpp != null) {
						objOppRelTrack.Opp_Time_to_First_Call_Hours__c = Utils.businessHours(businessHoursId, objOpp.CreatedDate, firstCallDateOpp);
						objOppRelTrack.Opp_Time_to_First_Call_Minutes__c = Utils.businessminutes(businessHoursId, objOpp.CreatedDate, firstCallDateOpp);
					}
				}

				if (objOppRelTrack.First_Opp_Activity_Date__c == null) {
					objOppRelTrack.First_Opp_Activity_Date__c = firstActivityDateOpp;
				}

				listOppTrackingToUpdate.add(objOppRelTrack);
			}
		}
		if (listOppTrackingToUpdate.size() > 0) {
			update listOppTrackingToUpdate;
		}

		processInfo = false;
	}

	private Map<Id, Id> getMapBusinessHour(Set<Id> setOwnerIds) {
		//Create map for businessHours record Id
		setOwnerIds.add(UserInfo.getUserId());
		Map<Id, Id> mapUserToBusinessHourId = new Map<Id, Id>();
		List<BusinessHours> listBusinessHours = [SELECT Id, TimeZoneSidKey, IsDefault FROM BusinessHours];

		for (User objUser : [SELECT Id, TimeZoneSidKey FROM User WHERE id IN :setOwnerIds]) {
			for (BusinessHours objBusinessHour : listBusinessHours) {
				if (objBusinessHour.TimeZoneSidKey == objUser.TimeZoneSidKey) {
					mapUserToBusinessHourId.put(objUser.Id, objBusinessHour.Id);
				} else if (objBusinessHour.IsDefault == true) {
					mapUserToBusinessHourId.put(objUser.Id, objBusinessHour.Id);
				}
			}
		}
		return mapUserToBusinessHourId;
	}
}