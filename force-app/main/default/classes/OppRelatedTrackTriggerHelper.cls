/*
 *   By : Robin
 *   Created Date : 14-07-2017
 *
 */
public with sharing class OppRelatedTrackTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;

	public OppRelatedTrackTriggerHelper() {
	}

	public void OnBeforeInsert(List<Opportunity_Related_Tracking__c> listOppRelTrack) {
		processInformation(listOppRelTrack);
	}

	public void OnBeforeUpdate(Map<ID, Opportunity_Related_Tracking__c> oldOppRelTrackMap, Map<ID, Opportunity_Related_Tracking__c> newOppRelTrackMap) {
		counter++;
		processInformation(newOppRelTrackMap.values());
	}

	private void processInformation(List<Opportunity_Related_Tracking__c> listOppRelTrack) {
		Set<Id> setOwnerIds = new Set<Id>();
		Set<Id> setOppIds = new Set<Id>();
		List<Opportunity_Related_Tracking__c> listOppRelTrackRecs = new List<Opportunity_Related_Tracking__c>();
		Map<Id, OppWrapper> mapOppToWrapper = new Map<Id, OppWrapper>();

		for (Opportunity_Related_Tracking__c objOppRelTrack : listOppRelTrack) {
			setOwnerIds.add(objOppRelTrack.Opportunity_Owner__c);
			setOppIds.add(objOppRelTrack.Opportunity__c);
		}

		//Create map for businessHours record Id
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

		for (Opportunity objOpp : [
			SELECT
				Id,
				CreatedDate,
				Lead_Created_Date_Time__c,
				LastModifiedDate,
				StageName,
				OwnerId,
				(SELECT NewValue, OldValue, Field, OpportunityId, Id, CreatedDate FROM Histories WHERE Field = 'StageName' ORDER BY CreatedDate ASC LIMIT 2),
				(SELECT Id, CreatedDate, recordType.Name, Type, Status FROM Tasks ORDER BY CreatedDate ASC)
			FROM opportunity
			WHERE Id IN :setOppIds
		]) {
			//Getting first activity date and call date
			DateTime firstActivityDate;
			DateTime firstCallDate;
			DateTime oppDateTime;

			Integer attemptCount = 0;
			Integer connectCount = 0;
			Integer voicemailCount = 0;

			oppDateTime = objOpp.CreatedDate;

			for (Task objTask : objOpp.Tasks) {
				if (firstActivityDate == null) {
					firstActivityDate = objOpp.Tasks[0].CreatedDate;
				}
				if (objTask.recordType.Name == 'Call' && firstCallDate == null) {
					firstCallDate = objTask.CreatedDate;
					break;
				}
			}
			for (Task objTask : objOpp.Tasks) {
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

			//Getting first stage change date
			DateTime firstStageChangeDate;
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

			//Getting business hour Id
			Id businessHoursId;
			if (mapUserToBusinessHourId.size() > 0 && mapUserToBusinessHourId.containsKey(objOpp.OwnerId)) {
				businessHoursId = mapUserToBusinessHourId.get(objOpp.OwnerId);
			}

			mapOppToWrapper.put(objOpp.Id, new OppWrapper(businessHoursId, oppDateTime, firstActivityDate, firstCallDate, firstStageChangeDate, attemptCount, connectCount, voiceMailCount));
		}

		for (Opportunity_Related_Tracking__c objOppRelTrack : listOppRelTrack) {
			if (mapOppToWrapper.containsKey(objOppRelTrack.Opportunity__c)) {
				OppWrapper wrap = mapOppToWrapper.get(objOppRelTrack.Opportunity__c);
				Id businessHoursId = wrap.BusinessHourId;
				DateTime oppCreatedDate = wrap.OppCreatedDate;
				DateTime firstActivityDate = wrap.FirstActivityDate;
				DateTime firstCallDate = wrap.FirstCallDate;
				DateTime firstStageChangeDate = wrap.FirstStageChangeDate;

				// first activity date
				if (objOppRelTrack.First_Activity_Date__c == null && firstActivityDate != null) {
					objOppRelTrack.First_Activity_Date__c = firstActivityDate;
					objOppRelTrack.Time_To_First_Activity__c = Utils.businessHours(businessHoursId, oppCreatedDate, firstActivityDate);
				}

				//first call date
				if (objOppRelTrack.First_Call_Date__c == null && firstCallDate != null) {
					objOppRelTrack.First_Call_Date__c = firstCallDate;
					objOppRelTrack.Time_To_First_Call__c = Utils.businessHours(businessHoursId, oppCreatedDate, firstCallDate);
					objOppRelTrack.Time_To_First_Call_Minutes__c = Utils.businessminutes(businessHoursId, oppCreatedDate, firstCallDate);
				}

				//first stage change date
				if (objOppRelTrack.First_Stage_Change_Date__c == null && firstStageChangeDate != null && objOppRelTrack.Opp_Stage_Changed__c == true) {
					objOppRelTrack.First_Stage_Change_Date__c = firstStageChangeDate;
					objOppRelTrack.Time_To_stage_Change__c = Utils.businessHours(businessHoursId, oppCreatedDate, firstStageChangeDate);
				}
				objOppRelTrack.Attempts__c = wrap.attemptCount;
				objOppRelTrack.Connects__c = wrap.connectCount;
				objOppRelTrack.Voicemails__c = wrap.voiceMailCount;
			}
		}
	}

	public class OppWrapper {
		Id businessHourId;
		DateTime oppCreatedDate;
		DateTime firstActivityDate;
		DateTime firstCallDate;
		DateTime firstStageChangeDate;
		Integer attemptCount;
		Integer connectCount;
		Integer voiceMailCount;

		public OppWrapper(Id businessHrId, DateTime oppCreated, DateTime firstActivity, DateTime firstCall, DateTime firstStageChange, Integer attempt, Integer connect, Integer voiceMail) {
			businessHourId = businessHrId;
			oppCreatedDate = oppCreated;
			firstActivityDate = firstActivity;
			firstCallDate = firstCall;
			firstStageChangeDate = firstStageChange;
			attemptCount = attempt;
			connectCount = connect;
			voiceMailCount = voiceMail;
		}
	}
}