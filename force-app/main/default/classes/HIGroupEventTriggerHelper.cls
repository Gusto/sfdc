/**
 * @name         HIGroupEventTriggerHelper
 * @author       Gireesh
 * @date         08/01/2020
 * @description  This class handels the HIGroupEvent__c record creation
 * @test class   HIGroupEventTriggerHelperTest, SubmissionAutomationHelperTest, ConfirmationAutomationHelperTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;

	public void OnBeforeInsert(List<HIGroupEvent__c> list_HiGroupEvents) {
		// Real-Time events
		//Updated Condition for BBO-2141
		if (
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_CONFIRMATION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_QUALIFICATION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_OA_INTRO_EMAIL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_REQUEST ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_GROUP_TERM_CASE || 
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW || 
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL || 
            list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL || 
            list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL
		) {
			queue = true;
			processEvents(list_HiGroupEvents);
		} else {
			for (HIGroupEvent__c objHIGroupEvent : list_HiGroupEvents) {
				objHIGroupEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}

		// Async events
		if (list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO || list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP) {
			queue = false;
		}
	}

	public void OnAfterInsert(List<HIGroupEvent__c> list_HiGroupEvents) {
		if (queue == false) {
			if (Limits.getQueueableJobs() == 0) {
				ID jobID = System.enqueueJob(new HIGroupEventQueue(list_HiGroupEvents));
			}
		}
	}

	public void OnBeforeUpdate(map<ID, HIGroupEvent__c> map_OldHiGroupEvents, List<HIGroupEvent__c> list_HiGroupEvents) {
		// Async events
		if (
			queue &&
			(list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS)
		) {
			processEvents(list_HiGroupEvents);
			// Real-Time events
		} else if (
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_CONFIRMATION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_QUALIFICATION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_OA_INTRO_EMAIL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_REQUEST ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_GROUP_TERM_CASE ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO ||
			list_HiGroupEvents.get(0).Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW
		) {
			queue = true;
			processEvents(list_HiGroupEvents);
		} else {
			//add logic needs to add to queue
			for (HIGroupEvent__c objHIGroupEvent : list_HiGroupEvents) {
				objHIGroupEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, HIGroupEvent__c> map_OldHIGroupEvent, List<HIGroupEvent__c> list_HiGroupEvents) {
		if (queue == false && Limits.getQueueableJobs() == 0) {
			ID jobID = System.enqueueJob(new HIGroupEventQueue(list_HiGroupEvents));
		}
	}

	private void processEvents(List<HIGroupEvent__c> list_Events) {
		List<HIGroupEvent__c> list_GroupConfirmationEvents = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_SubmissionAutomationEvents = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_DocCollectionStatusEvents = new List<HIGroupEvent__c>();
		List<HIEventWrapper> list_QaSheetEvent = new List<HIEventWrapper>();
		List<HIEventWrapper> list_AdvisingIntroEmail = new List<HIEventWrapper>();
		List<HIEventWrapper> list_AdvisingFollowUpEmail = new List<HIEventWrapper>();
		List<HIEventWrapper> list_AdvisingFinalEmail = new List<HIEventWrapper>();
        List<HIEventWrapper> list_AdvisingLevelFundedIntroEmail = new List<HIEventWrapper>();
        List<HIEventWrapper> list_AdvisingLevelFundedCheckinEmail = new List<HIEventWrapper>();
        List<HIEventWrapper> list_AdvisingLevelFundedAutoRenewalEmail = new List<HIEventWrapper>();
		List<HIGroupEvent__c> list_GroupIntroEmails = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_GroupRenewalsRequest = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_TTSNotesPostOEEmail = new List<HIGroupEvent__c>();
		List<HIGroupEvent__c> list_GroupTerminationCases = new List<HIGroupEvent__c>();
		List<HIEventWrapper> list_LevelFundedIntroEmail = new List<HIEventWrapper>();
		
		for (HIGroupEvent__c objEvent : list_Events) {
			if (objEvent.Processing_State__c == IntegrationUtils.DEAD_STATE || objEvent.Event_Id__c == null) {
				continue;
			}

			objEvent.Processing_State__c = IntegrationUtils.QUEUED_STATE;

			//In case of HI Advising Email Automation we need the message to reprocess if record get failed
			if (
				objEvent.Event_Type__c != HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO &&
				objEvent.Event_Type__c != HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP &&
				objEvent.Event_Type__c != HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL
			) {
				objEvent.Message__c = '';
			}

			String strDeCryptedText = objEvent.Event_Info__c;

			// Check based on event type collect them in separate lists and call their respective handler.
			if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO) {
				list_QaSheetEvent.add(new HIEventWrapper(strDeCryptedText, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_CONFIRMATION_AUTO) {
				list_GroupConfirmationEvents.add(objEvent);
			} else if (HIGroupEventUtil.EVENT_TYPE_SUBMISSION_AUTO.equalsIgnoreCase(objEvent.Event_Type__c)) {
				list_SubmissionAutomationEvents.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_DOC_COLLECTION_STATUS) {
				list_DocCollectionStatusEvents.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_INTRO) {
				list_AdvisingIntroEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_INTRO_EMAIL) {
				//Added for BBO-2141
                list_AdvisingLevelFundedIntroEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_TRANSITION_RENEWAL_CHECKIN_EMAIL) {
				//Added for BBO-2141
                list_AdvisingLevelFundedCheckinEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEWAL_EMAIL) {
				//Added for BBO-2141
                list_AdvisingLevelFundedAutoRenewalEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FOLLOWUP) {
				list_AdvisingFollowUpEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_FINAL) {
				list_AdvisingFinalEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c != null && objEvent.Event_Type__c.equalsIgnoreCase(HIGroupEventUtil.EVENT_TYPE_OA_INTRO_EMAIL)) {
				list_GroupIntroEmails.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_RENEWAL_REQUEST) {
				list_GroupRenewalsRequest.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_TTS_NOTE_POST_OE_EMAIL) {
				list_TTSNotesPostOEEmail.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_GROUP_TERM_CASE) {
				list_GroupTerminationCases.add(objEvent);
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_INTRO) {
				list_LevelFundedIntroEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			} else if (objEvent.Event_Type__c == HIGroupEventUtil.EVENT_TYPE_LEVEL_FUNDED_AUTO_RENEW) {
				list_LevelFundedIntroEmail.add(new HIEventWrapper(objEvent.Event_Info__c, objEvent));
			}
		}

		if (list_QaSheetEvent != null && !list_QaSheetEvent.isEmpty()) {
			new HIGroupEventQASheetHandler().processInformation(list_QaSheetEvent);
		}

		if (list_GroupConfirmationEvents != null && !list_GroupConfirmationEvents.isEmpty()) {
			ConfirmationAutomationHelper.processConfirmationAutomationEvents(list_GroupConfirmationEvents);
		}

		if (list_SubmissionAutomationEvents != null && !list_SubmissionAutomationEvents.isEmpty()) {
			SubmissionAutomationHelper.processSubmissionAutomationEvents(list_SubmissionAutomationEvents);
		}

		if (list_DocCollectionStatusEvents != null && !list_DocCollectionStatusEvents.isEmpty()) {
			HIGroupEventDocCollectionStatus.processEvents(list_DocCollectionStatusEvents);
		}

		//Added by AKS dated 11th Jan 2021 to process Advising email automation
		if (list_AdvisingIntroEmail != null && list_AdvisingIntroEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processIntroInformation(list_AdvisingIntroEmail);
		}

		if (list_AdvisingFollowUpEmail != null && list_AdvisingFollowUpEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processFollowupInformation(list_AdvisingFollowUpEmail);
		}

		if (list_AdvisingFinalEmail != null && list_AdvisingFinalEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processFinalInformation(list_AdvisingFinalEmail);
		}
        //added for BBO-2141 Start
        if (list_AdvisingLevelFundedIntroEmail != null && list_AdvisingLevelFundedIntroEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processIntroInformation(list_AdvisingLevelFundedIntroEmail);
		}
        if (list_AdvisingLevelFundedCheckinEmail != null && list_AdvisingLevelFundedCheckinEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processIntroInformation(list_AdvisingLevelFundedCheckinEmail);
		}
        if (list_AdvisingLevelFundedAutoRenewalEmail != null && list_AdvisingLevelFundedAutoRenewalEmail.size() > 0) {
			HIGroupEventAdvisingEmailAutomation.processIntroInformation(list_AdvisingLevelFundedAutoRenewalEmail);
		}
        //BBO-2141 ends
		if (list_GroupIntroEmails != null && list_GroupIntroEmails.size() > 0) {
			HIGroupEventOAIntroEmail.processEvents(list_GroupIntroEmails);
		}

		if (list_GroupRenewalsRequest != null && list_GroupRenewalsRequest.size() > 0) {
			HIGroupEventRenewalAlternateRequest.processEvents(list_GroupRenewalsRequest);
		}

		if (list_TTSNotesPostOEEmail?.size() > 0) {
			HIGroupEventTTSNotePostOEEmail.processEvents(list_TTSNotesPostOEEmail);
		}

		if (list_GroupTerminationCases != null && !list_GroupTerminationCases.isEmpty()) {
			HIGroupEventTerminationCases.processEvents(list_GroupTerminationCases);
		}

		if (list_LevelFundedIntroEmail != null && !list_LevelFundedIntroEmail.isEmpty()) {
			HIGroupEventAdvisingEmailAutomation.processIntroInformation(list_LevelFundedIntroEmail);
		}
	}

	public static HIGroupEvent__c setProcessingState(String ProcessingState, String message, HIGroupEvent__c objHIGroupEve) {
		objHIGroupEve.Processing_State__c = ProcessingState;
		objHIGroupEve.Message__c = message;
		objHIGroupEve.Processed_At__c = System.now();
		return objHIGroupEve;
	}
}