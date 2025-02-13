/*
 *   By : Robin
 *   Created Date : 14-07-2017
 *
 */
public with sharing class AccountRelatedTrackingTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;
	public static String EMAIL_TASK = 'Email';
	public static Id EMAIL_TASK_REC_TYPE_ID = Cache.getRecordTypeId('Task', 'Email');

	public void OnBeforeInsert(List<Account_Related_Tracking__c> listAccountRelTrack) {
		processInformation(listAccountRelTrack);
	}

	public void OnBeforeUpdate(Map<Id, Account_Related_Tracking__c> oldAccountRelTrackMap, Map<Id, Account_Related_Tracking__c> newAccountRelTrackMap) {
		processInformation(newAccountRelTrackMap.values());
	}

	private void processInformation(List<Account_Related_Tracking__c> listAccountRelTrack) {
		Set<Id> setAccountIds = new Set<Id>();
		List<Account_Related_Tracking__c> listAccountRelTrackRecs = new List<Account_Related_Tracking__c>();
		Map<Id, AccountWrapper> mapAccountToWrapper = new Map<Id, AccountWrapper>();
		Map<Id, List<Task>> accountTaskMap = new Map<Id, List<Task>>();
		Set<Id> set_OwnerIds = new Set<Id>{ UserInfo.getUserId() };
		Map<Id, Id> map_UserToBusinessHourId = new Map<Id, Id>();
		List<User> list_Users = new List<User>();
		List<BusinessHours> list_BusinessHours = GlobalQueryHelper.getAllBusinessHoursList();

		for (Account_Related_Tracking__c objAccountRelTrack : listAccountRelTrack) {
			set_OwnerIds.add(objAccountRelTrack.Account_Owner_Id__c);
		}

		list_Users = GlobalQueryHelper.getUsersByIdMap(set_OwnerIds).values();

		for (User objUser : list_Users) {
			for (BusinessHours objBusinessHour : list_BusinessHours) {
				if (objUser != null && objBusinessHour.TimeZoneSidKey == objUser.TimeZoneSidKey || objBusinessHour.IsDefault == true) {
					map_UserToBusinessHourId.put(objUser.Id, objBusinessHour.Id);
				}
			}
		}
		for (Account_Related_Tracking__c track : listAccountRelTrack) {
			setAccountIds.add(track.Account__c);
		}

		for (Task tsk : [
			SELECT Id, AccountId, CreatedDate, RecordType.Name, CreatedBy.UserName, Type, Status, OwnerId
			FROM Task
			WHERE accountId IN :setAccountIds AND RecordTypeId != :EMAIL_TASK_REC_TYPE_ID AND Type != :EMAIL_TASK
			WITH SECURITY_ENFORCED
		]) {
			if (tsk.CreatedBy.UserName.indexOf('sfdc+marketo@zenpayroll.com') > -1) {
				continue;
			}
			List<Task> tskList = new List<Task>();
			if (accountTaskMap.containsKey(tsk.AccountId)) {
				tskList = accountTaskMap.get(tsk.AccountId);
			}
			tskList.add(tsk);
			accountTaskMap.put(tsk.AccountId, tskList);
		}
		for (Account objAccount : [SELECT Id, CreatedDate, LastModifiedDate, OwnerId FROM Account WHERE Id IN :setAccountIds WITH SECURITY_ENFORCED]) {
			DateTime dtmAccountCreatedDate = objAccount.CreatedDate;
			//Getting first activity date and call date
			DateTime dtmFirstActivityDate;
			DateTime firstCallDate;

			Integer attemptCount = 0;
			Integer connectCount = 0;
			Integer voicemailCount = 0;
			Integer followUpCount = 0;
			Id idBusinessHours;
			Integer intOwnerCallsAttempted = 0;
			Integer intOwnerVoicemails = 0;
			Integer intOwnerConnected = 0;

			if (map_UserToBusinessHourId.size() > 0 && map_UserToBusinessHourId.containsKey(objAccount.OwnerId)) {
				idBusinessHours = map_UserToBusinessHourId.get(objAccount.OwnerId);
			} else {
				idBusinessHours = map_UserToBusinessHourId.get(UserInfo.getUserId());
			}

			List<Task> taskList = new List<Task>();
			if (accountTaskMap.containsKey(objAccount.Id)) {
				taskList = accountTaskMap.get(objAccount.Id);
			}
			for (Task objTask : taskList) {
				if ((dtmFirstActivityDate == null || dtmFirstActivityDate < objTask.CreatedDate) && objTask.RecordType.Name == 'Call') {
					dtmFirstActivityDate = objTask.CreatedDate;
				}
				if (String.isNotBlank(objTask.Status) && objTask.Status.equalsIgnoreCase('Attempt') && objAccount.OwnerId == objTask.OwnerId) {
					intOwnerCallsAttempted += 1;
				}
				if (String.isNotBlank(objTask.Status) && objTask.Status.equalsIgnoreCase('Connect') && objAccount.OwnerId == objTask.OwnerId) {
					intOwnerConnected += 1;
				}
				if (String.isNotBlank(objTask.Status) && objTask.Status.equalsIgnoreCase('Voicemail') && objAccount.OwnerId == objTask.OwnerId) {
					intOwnerVoicemails += 1;
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

				// Follow Up
				if (
					objTask.recordTypeId == Cache.getRecordTypeId('Task', 'Standard') &&
					(String.isNotBlank(objTask.Type) && objTask.Type.equalsIgnoreCase('Follow Up')) &&
					(String.isNotBlank(objTask.Status) && objTask.Status.equalsIgnoreCase('Open'))
				) {
					followUpCount += 1;
				}
			}

			mapAccountToWrapper.put(
				objAccount.Id,
				new AccountWrapper(
					attemptCount,
					connectCount,
					voiceMailCount,
					followUpCount,
					dtmFirstActivityDate,
					dtmAccountCreatedDate,
					idBusinessHours,
					intOwnerCallsAttempted,
					intOwnerVoicemails,
					intOwnerConnected
				)
			);
		}

		for (Account_Related_Tracking__c objAccountRelTrack : listAccountRelTrack) {
			if (mapAccountToWrapper.containsKey(objAccountRelTrack.Account__c)) {
				AccountWrapper wrap = mapAccountToWrapper.get(objAccountRelTrack.Account__c);
				objAccountRelTrack.Attempts__c = wrap.attemptCount;
				objAccountRelTrack.Connects__c = wrap.connectCount;
				objAccountRelTrack.Voicemails__c = wrap.voiceMailCount;
				objAccountRelTrack.No_of_Follow_Ups__c = wrap.followUpCount;
				if ((objAccountRelTrack.Time_To_First_Call_Minutes__c == null || objAccountRelTrack.Time_To_First_Call_Minutes__c == 0) && wrap.dtmFirstActivityDate != null) {
					objAccountRelTrack.Time_To_First_Call_Minutes__c = Utils.businessMinutes(wrap.IdbusinessHours, wrap.dtmAccountCreatedDate, wrap.dtmfirstActivityDate);
					objAccountRelTrack.Time_To_First_Call__c = Utils.businessHours(wrap.IdbusinessHours, wrap.dtmAccountCreatedDate, wrap.dtmfirstActivityDate);
				}
				objAccountRelTrack.Attempts_by_Owner__c = wrap.intOwnerCallsAttempted;
				objAccountRelTrack.Connects_by_Owner__c = wrap.intOwnerConnected;
				objAccountRelTrack.Voicemails_by_Owner__c = wrap.intOwnerVoicemails;
			}
		}
	}

	public class AccountWrapper {
		Integer attemptCount;
		Integer connectCount;
		Integer voiceMailCount;
		Integer followUpCount = 0;
		DateTime dtmFirstActivityDate;
		DateTime dtmAccountCreatedDate;
		Id IdBusinessHours;
		Integer intOwnerCallsAttempted = 0;
		Integer intOwnerVoicemails = 0;
		Integer intOwnerConnected = 0;

		public AccountWrapper(
			Integer attempt,
			Integer connect,
			Integer voiceMail,
			Integer followUp,
			DateTime dtmFirstActivity,
			DateTime dtmAccountCreated,
			Id idBusiness,
			Integer intOwnerCallAttempt,
			Integer intOwnerVoicemail,
			Integer intOwnerConnect
		) {
			attemptCount = attempt;
			connectCount = connect;
			voiceMailCount = voiceMail;
			followUpCount = followUp;
			dtmFirstActivityDate = dtmFirstActivity;
			dtmAccountCreatedDate = dtmAccountCreated;
			idBusinessHours = idBusiness;
			intOwnerCallsAttempted = intOwnerCallAttempt;
			intOwnerVoicemails = intOwnerVoicemail;
			intOwnerConnected = intOwnerConnect;
		}
	}
}