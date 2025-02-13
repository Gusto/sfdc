/**
 * @name         IVRRoutingLogDetailCustomController
 * @author       Sanjay Paryani
 * @date         10/23/2019
 * @description  Class to show IVR Routing logs with Case Feed on the VF page IVRRoutingLogDetailCustom
 * @revisions    Date ------------ Name ------------ Comments
 *				11/05/2019		  SanjayP			Added method skipAndSave() to skip a record and go to the next one.
 *				11/05/2019		  SanjayP			Added locking mechanism to the IVR Routing Logs play mode.
 **/
public with sharing class IVRRoutingLogDetailCustomController {
	public string selectedQueueId { get; set; }
	public boolean isPlay { get; set; } //indicates that user has clicked play or not
	public boolean isPlayEmpty { get; set; } //indicates that current queue is empty
	public string currentIVRRLogId { get; set; }
	public string currentIntentGrouping { get; set; }
	public List<String> intentGroupings { get; set; }
	public IVR_Routing_Log__c selectedIVRRLog { get; set; }
	// using this for scenario when  user is in "Play mode" and clicked on "Save" button
	public boolean isNext = false;
	// this indicates if Skip button is clicked for a particualr IVR record
	public boolean isSkipped = false;
	public List<IVR_Routing_Log__c> IVRRecords { get; set; }
	public set<id> alreadyPlayedIVRRLogIdSet = new Set<id>();
	list<SelectOption> userQueueList = new List<SelectOption>();

	public IVRRoutingLogDetailCustomController() {
		isPlay = false;
		isPlayEmpty = false;
		selectedIVRRLog = new IVR_Routing_Log__c();
		this.getIVRs();
	}

	public void getIntentGroupings() {
		intentGroupings = new List<String>();
		for (IVR_Intent_Grouping__c ivrg : [SELECT Id, Name, Intent_Code__c, Skill__c FROM IVR_Intent_Grouping__c ORDER BY Name ASC LIMIT 999]) {
			intentGroupings.add(ivrg.Name);
		}
	}

	public void getIVRDetail() {
		List<IVR_Routing_Log__c> tempIVRRecordPlayList = new List<IVR_Routing_Log__c>();
		if (!isPlay && String.isNotBlank(currentIVRRLogId)) {
			tempIVRRecordPlayList = [
						SELECT
							Bot_Review_Skipped__c,
							Case_Reason__c,
							isIVRinPlay__c,
							IVR_Intent_Grouping__r.Name,
							Case_Skill__c,
							Skill__c,
							CreatedDate,
							Type__c,
							ConversationId__c,
							CIP_Queue_Name__c,
							ANI__c,
							CIP_Auth__c,
							Company_Name__c,
							CIP_Customer_Name__c,
							Lex_Transcript__c,
							Id,
							IVR_Intent_Grouping__c,
							OwnerId,
							Call_Recording__c,
							Correct_Intent_Grouping__c,
							Case__c,
							Case__r.CaseNumber,
							Utterance__c,
							Approved__c,
							Name,
							Correct_Intent_Grouping__r.Name
						FROM IVR_Routing_Log__c
						WHERE Id = :currentIVRRLogId
						LIMIT 1
				];
		} else if(isPlay) {
				if (string.isblank(selectedQueueId) || selectedQueueId == '1') {
					selectedQueueId = userInfo.getUserId();
				}

			tempIVRRecordPlayList = [
					SELECT
						Bot_Review_Skipped__c,
						Case_Reason__c,
						isIVRinPlay__c,
						IVR_Intent_Grouping__r.Name,
						Case_Skill__c,
						Skill__c,
						CreatedDate,
						Type__c,
						ConversationId__c,
						CIP_Queue_Name__c,
						CIP_Auth__c,
						CIP_Customer_Name__c,
						Lex_Transcript__c,
						Id,
						IVR_Intent_Grouping__c,
						OwnerId,
						Call_Recording__c,
						Correct_Intent_Grouping__c,
						Case__c,
						Case__r.CaseNumber,
						Utterance__c,
						Approved__c,
						Name,
						Correct_Intent_Grouping__r.Name
					FROM IVR_Routing_Log__c
					WHERE Transcript_Reviewed__c = FALSE AND isIVRinPlay__c = FALSE AND Bot_Review_Skipped__c = FALSE AND OwnerId = :selectedQueueId AND Id NOT IN :alreadyPlayedIVRRLogIdSet
					ORDER BY CreatedDate ASC
					LIMIT 20
				];
		}
		if (!tempIVRRecordPlayList.isEmpty()) {
			selectedIVRRLog = tempIVRRecordPlayList.get(0);
				} else {
					selectedIVRRLog = new IVR_Routing_Log__c();
					return;
				}
			getIntentGroupings();
		}

	public list<SelectOption> getIVRQueueList() {
		list<SelectOption> queueList = new List<SelectOption>();
		queueList.add(new SelectOption('1', 'My IVR Routing Logs'));

		for (QueueSobject qu : [SELECT Id, SobjectType, QueueId, Queue.Name, Queue.Type, Queue.RelatedId FROM QueueSobject WHERE SobjectType = 'IVR_Routing_Log__c' AND Queue.Type = 'Queue']) {
			queueList.add(new SelectOption(qu.QueueId, qu.Queue.Name));
		}

		return queueList;
	}

	public PageReference getIVRs() {
		isPlayEmpty = false;
		String query = '';
		query = 'select Bot_Review_Skipped__c,isIVRinPlay__c,Case_Reason__c,IVR_Intent_Grouping__r.Name,Case_Skill__c,Skill__c,CreatedDate,Type__c,ConversationId__c,CIP_Queue_Name__c,CIP_Auth__c,CIP_Customer_Name__c,Lex_Transcript__c,Id,IVR_Intent_Grouping__c,OwnerId,Call_Recording__c,Correct_Intent_Grouping__c,Case__c,Case__r.CaseNumber,Utterance__c,Approved__c,Name,Correct_Intent_Grouping__r.Name';
		query += ' from IVR_Routing_Log__c where Transcript_Reviewed__c = false and isIVRinPlay__c = false and Bot_Review_Skipped__c = false ';
		if (!string.isBlank(selectedQueueId) && selectedQueueId != '1') {
			query += ' and ownerId=:selectedQueueId ';
		} else {
			id userIdd = userInfo.getUserId();
			query += ' and ownerId=:userIdd ';
		}
		query += ' order BY CreatedDate asc limit 1000 ';

		IVRRecords = Database.query(query);
		return null;
	}

	public void saveIVRRecord() {
		List<IVR_Routing_Log__c> ivrToUpdateList = new List<IVR_Routing_Log__c>();

		try {
			if (isPlay && isNext) {
				selectedIVRRLog.isIVRinPlay__c = false;
				selectedIVRRLog.Transcript_Reviewed__c = true;
			}
			if (isSkipped) {
				selectedIVRRLog.Bot_Review_Skipped__c = true;
				selectedIVRRLog.Transcript_Reviewed__c = false;
			}
			if (!String.isBlank(currentIntentGrouping)) {
				List<IVR_Intent_Grouping__c> intentGroupingsList = [SELECT ID, Name FROM IVR_Intent_Grouping__c WHERE Name = :currentIntentGrouping];
				if (intentGroupingsList.size() > 0) {
					selectedIVRRLog.Correct_Intent_Grouping__c = intentGroupingsList.get(0).Id;
				} else {
					selectedIVRRLog.Correct_Intent_Grouping__c = null;
				}
			}
			ivrToUpdateList.add(selectedIVRRLog);
			Database.update(ivrToUpdateList);
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.error, ex.getMessage()));
		}

		if (!apexPages.hasMessages()) {
			if (!isPlay) {
				selectedIVRRLog = new IVR_Routing_Log__c();
			}
		}
	}

	public void cancelUpdate() {
		try {
			selectedIVRRLog.Transcript_Reviewed__c = false;
			selectedIVRRLog.isIVRinPlay__c = false;
			update selectedIVRRLog;
		} catch (exception ex) {
		}

		selectedIVRRLog = new IVR_Routing_Log__c();
		isPlay = false;
	}

	public void saveNextRecord() {
		isNext = true;
		saveIVRRecord();
		isNext = false;

		if (apexPages.hasMessages()) {
			return;
		}

		alreadyPlayedIVRRLogIdSet.add(selectedIVRRLog.id);
		getIVRs();
		startPlay();
	}

	public void skipAndSave() {
		isSkipped = true;
		saveIVRRecord();
		isSkipped = false;

		if (apexPages.hasMessages()) {
			return;
		}

		alreadyPlayedIVRRLogIdSet.add(selectedIVRRLog.id);
		getIVRs();
		startPlay();
	}

	public void startPlay() {
		getIVRs();
		if (IVRRecords.size() > 0) {
			isPlay = true;
			isPlayEmpty = false;
			getIVRDetail();
			if (selectedIVRRLog != null && selectedIVRRLog.id != null) {
					selectedIVRRLog.isIVRinPlay__c = false;
					try {
						update selectedIVRRLog;
					} catch (exception ex) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
					}
				
			} else {
				isPlayEmpty = true;
				isPlay = false;
			}
		} else {
			isPlayEmpty = true;
			isPlay = false;
			selectedIVRRLog = new IVR_Routing_Log__c();
		}
	}
}