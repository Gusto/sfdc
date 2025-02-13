public class CaseAuditLogTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	public static boolean blnException = false; //only for testing
	Map<Id, Case> map_IdToCase;

	private static final String NEW_MESSAGE = 'New Message';
	private static final String STATUS_CHANGE = 'Status Change';

	public void OnBeforeInsert(List<Case_Audit_Log__c> logs) {
		counter++;
		processInfo(logs);
	}

	public void OnAfterInsert(Map<ID, Case_Audit_Log__c> newLogMap) {
		if (CaseTriggerHelper.processStatusChange == true) {
			casetriggerhelper.skipTrigger = true;
		}
	}

	public void OnBeforeUpdate(Map<ID, Case_Audit_Log__c> oldLogMap, Map<ID, Case_Audit_Log__c> newLogMap) {
		counter++;
		processInfo(newLogMap.values());
	}

	public void OnBeforeDelete(Case_Audit_Log__c[] logToDelete, Map<ID, Case_Audit_Log__c> oldLogMap) {
		counter++;
	}

	public void OnAfterDelete(Case_Audit_Log__c[] deletedLogs, Map<ID, Case_Audit_Log__c> oldLogMap) {
		counter++;
	}

	public void OnUndelete(Case_Audit_Log__c[] restoredLogs) {
		counter++;
	}

	private void processInfo(List<Case_Audit_Log__c> list_Logs) {
		createCollections(list_Logs);

		for (Case_Audit_Log__c objLog : list_Logs) {
			/*
			if case origin = email and case record type = payroll care or benefits care
				if event type = email and from status = new message and direction = inbound then touchpoint = 0
				if event type = email and from status = new message and direction = outbound then touchpoint = 1
				if event type = phone and direction = outbound then touchpoint = 1

			if case origin = phone and case record type = payroll care or benefits care
				if event type = phone and direction = inbound then touchpoint = 1
				if event type = phone and direction = outbound then touchpoint = 1
				if event type = email and direction = outbound and from status = new message then touchpoint = 1
				if event type = email and direction = inbound and from status = new message then touchpoint = 0

			if case origin = chat and case record type = payroll care or benefits care
				if event type = chat and from status = new message and direction = inbound then touchpoint = 1
				if event type = email and from status = new message and direction = outbound then touchpoint = 1
				if event type = phone and direction = outbound then touchpoint = 1
			*/
			Case objCase = map_IdToCase.get(objLog.Case__c);
			if (
				(objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE || objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE || objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT) &&
				objCase.Status != CaseUtils.STATUS_CLOSED
			) {
				if (
					objCase.Origin == CaseUtils.ORIGIN_EMAIL || 
					objCase.Origin == CaseUtils.ORIGIN_FOLLOW_UP_EMAIL || 
					objCase.Origin == CaseUtils.ORIGIN_ESCALATION ||
					(objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_EMAIL)
				) {
					if (objLog.Event_Type__c == CaseUtils.ORIGIN_EMAIL && objLog.From_Status__c == NEW_MESSAGE) {
						if (objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_INBOUND) {
							objLog.Touchpoint__c = 0;
						} else if (objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_OUTBOUND) {
							objLog.Touchpoint__c = 1;
						}
					} else if (objLog.Event_Type__c == CaseUtils.ORIGIN_PHONE && objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_OUTBOUND) {
						objLog.Touchpoint__c = 1;
					}
				} else if (objCase.Origin == CaseUtils.ORIGIN_PHONE) {
					if (objLog.Event_Type__c == CaseUtils.ORIGIN_PHONE) {
						if (String.isNotBlank(objLog.Direction__c)) {
							objLog.Touchpoint__c = 1;
						}
					} else if (objLog.Event_Type__c == CaseUtils.ORIGIN_EMAIL) {
						if (objLog.From_Status__c == NEW_MESSAGE) {
							if (objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_INBOUND) {
								objLog.Touchpoint__c = 0;
							} else if (objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_OUTBOUND) {
								objLog.Touchpoint__c = 1;
							}
						}
					}
				} else if (
					objCase.Channel__c == CaseUtils.ORIGIN_CHAT ||
					(objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT)
				) {
					if (objLog.Event_Type__c == CaseUtils.ORIGIN_CHAT && objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_INBOUND) {
						objLog.Touchpoint__c = 1;
					} else if (objLog.Event_Type__c == CaseUtils.ORIGIN_EMAIL && objLog.From_Status__c == NEW_MESSAGE && objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_OUTBOUND) {
						objLog.Touchpoint__c = 1;
					} else if (objLog.Event_Type__c == CaseUtils.ORIGIN_PHONE && objLog.Direction__c == EmailMessageUtil.CASE_DIRECTION_OUTBOUND) {
						objLog.Touchpoint__c = 1;
					}
				}
			}

			if (objLog.Business_Hours__c != null && objLog.From_Date_Time__c != null && objLog.To_Date_Time__c != null) {
				Id hoursId = objLog.Business_Hours__c;
				DateTime fromTime = objLog.From_Date_Time__c;
				DateTime toTime = objLog.To_Date_Time__c;

				Long milliSeconds = 0;
				/* calculating duration in seconds for all event types */
				milliSeconds = objLog.To_Date_Time__c.getTime() - objLog.From_Date_Time__c.getTime();

				if (milliSeconds > 0) {
					objLog.Duration_in_seconds__c = milliSeconds / 1000;
				}

				/*
					Author: Alex
					Date: 7/30/2020
					Desc: populate new Duration in Seconds Adjusted field
				*/
				try {
					Decimal decDIS = 0;
					if (!map_IdToCase.isEmpty()) {
						if (
							objLog.Case__c != null &&
							objLog.From_Date_Time__c != null &&
							map_IdToCase.get(objLog.Case__c).Call_Start__c != null &&
							objLog.To_Date_Time__c != null &&
							map_IdToCase.get(objLog.Case__c).Call_End__c != null
						) {
							if (
								Math.max(objLog.From_Date_Time__c.getTime(), map_IdToCase.get(objLog.Case__c).Call_Start__c.getTime()) <
								Math.min(objLog.To_Date_Time__c.getTime(), map_IdToCase.get(objLog.Case__c).Call_End__c.getTime())
							) {
								//if CAL started after call start and before call end and ends after call end
								//take difference of Call End and log's To Date Time
								//set Duration in Seconds Adjusted to difference
								if (objLog.Event_Type__c == STATUS_CHANGE) {
									Decimal decBefore = (map_IdToCase.get(objLog.Case__c).Call_Start__c.getTime() - objLog.From_Date_Time__c.getTime()) / 1000;
									if (decBefore > 0) {
										decDis = decBefore;
									}

									Decimal decAfter = (objLog.To_Date_Time__c.getTime() - map_IdToCase.get(objLog.Case__c)?.Call_End__c.getTime()) / 1000;
									if (decAfter > 0) {
										decDIS += decAfter;
									}
								}
							} else {
								decDIS = objLog.Duration_in_seconds__c;
							}
						}
					}
					//if we did not have Call Start/Call End
					if (map_IdToCase.get(objLog.Case__c).Call_Start__c == null || map_IdToCase.get(objLog.Case__c).Call_End__c == null) {
						decDIS = objLog.Duration_in_seconds__c;
					}
					objLog.Duration_In_Seconds_Adjusted__c = decDIS;
					if (Test.isRunningTest() && blnException == true) {
						Integer i = 0 / 0;
					}
				} catch (Exception objExcept) {
					ExceptionLogUtil.logException('CaseAuditLogTriggerHelper', 'processInfo', objExcept.getMessage(), objExcept.getStackTraceString());
				}
			}
			if (objLog.Business_Hours__c != null && objLog.Live_Channel_Start_Time__c != null && objLog.From_Date_Time__c != null) {
				Id hoursId = objLog.Business_Hours__c;
				DateTime fromTime = objLog.Live_Channel_Start_Time__c;
				DateTime toTime = objLog.From_Date_Time__c;
				Long milliSeconds = BusinessHours.diff(hoursId, fromTime, toTime);
				objLog.Live_Channel_Wait_Time_In_Seconds__c = milliSeconds / 1000;
			}
		}
	}
	/**
	 * @author Alex Xiong
	 * @description method for building collection variables
	 */
	private void createCollections(List<Case_Audit_Log__c> list_Logs) {
		Set<Id> set_CaseIds = new Set<Id>();

		for (Case_Audit_Log__c objCal : list_Logs) {
			set_CaseIds.add(objCal.Case__c);
		}
		queryCases(set_CaseIds);
	}

	/**
	 * @author Alex Xiong
	 * @description queries cases
	 */
	private void queryCases(Set<Id> set_CaseIds) {
		map_IdToCase = new Map<Id, Case>();

		for (Case objCase : [SELECT Id, Status, Call_Start__c, Call_End__c, Origin, Channel__c, RecordTypeId FROM Case WHERE Id IN :set_CaseIds]) {
			map_IdToCase.put(objCase.Id, objCase);
		}
	}
}