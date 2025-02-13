public with sharing class LiveChatTranscriptEventTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean blnTestException = false;
	public static final String TYPE_IDLETIMEOUTWARNINGTRIGGERED = 'ChasitorIdleTimeoutWarningTriggered';
	public static final String TYPE_IDLETIMEOUT = 'ChasitorIdleTimeout';

	public void OnAfterInsert(Map<ID, LiveChatTranscriptEvent> map_NewEvent) {
		/**
		 * Author: Alex
		 * Date: 8/26/2020
		 * Desc: if event is idle warning or time out, update chat transcript idle fields
		 */
		try {
			Map<Id, LiveChatTranscript> map_Chats = new Map<Id, LiveChatTranscript>();

			for (LiveChatTranscriptEvent objChatEvent : map_NewEvent.values()) {
				if (objChatEvent.Type == TYPE_IDLETIMEOUTWARNINGTRIGGERED || objChatEvent.Type == TYPE_IDLETIMEOUT) {
					if (map_Chats.containsKey(objChatEvent.LiveChatTranscriptId)) {
						if (objChatEvent.Type == TYPE_IDLETIMEOUTWARNINGTRIGGERED) {
							//if multiple idle warnings, make sure latest one is on chat transcript
							if (objChatEvent.Time > map_Chats.get(objChatEvent.LiveChatTranscriptId).Customer_Idle_Warning__c) {
								map_Chats.get(objChatEvent.LiveChatTranscriptId).Customer_Idle_Warning__c = objChatEvent.Time;
							}
						} else {
							map_Chats.get(objChatEvent.LiveChatTranscriptId).Customer_Idle_Timeout__c = objChatEvent.Time;
						}
					} else {
						LiveChatTranscript objChat = new LiveChatTranscript(Id = objChatEvent.LiveChatTranscriptId);
						if (objChatEvent.Type == TYPE_IDLETIMEOUTWARNINGTRIGGERED) {
							objChat.Customer_Idle_Warning__c = objChatEvent.Time;
						} else {
							objChat.Customer_Idle_Timeout__c = objChatEvent.Time;
						}

						map_Chats.put(objChat.Id, objChat);
					}
				}
			}

			if (map_Chats != null && map_Chats.values().size() > 0) {
				Boolean blnSkipTrigger = LiveChatTranscriptTriggerHelper.skipTrigger;
				LiveChatTranscriptTriggerHelper.skipTrigger = true;
				Database.update(map_Chats.values(), false);
				LiveChatTranscriptTriggerHelper.skipTrigger = blnSkipTrigger;
			}

			if (Test.isRunningTest() && blnTestException) {
				Integer intI = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('LiveChatTranscriptEventTrigger', 'OnAfterInsert', objEx.getMessage(), objEx.getStackTraceString());
		}
	}
}