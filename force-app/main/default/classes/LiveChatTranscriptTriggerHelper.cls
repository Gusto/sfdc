/**********************************************************************
 Name:  LiveChatTranscriptTriggerHelper()
Copyright © 2020  Gusto
============================================================================================================
Purpose:                                                           
-------  
This class is an helper class for the LiveChatTranscript object triggers.                             
Test Class:     TestLiveChatTranscriptTriggerHelper                       
============================================================================================================
History                                                           
-------                                                           
VERSION  AUTHOR            DATE              DETAIL                       Change Request
   1.0 -  Dhir          20/05/2020        INITIAL DEVELOPMENT          
***********************************************************************/
public class LiveChatTranscriptTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean boolTestThis = false;
	List<BusinessHours> bizHours = new List<BusinessHours>([SELECT Id, Name FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement']);
	public static List<String> list_Specializations = String.isNotBlank(Label.Engagement_Specializations) ? Label.Engagement_Specializations.split(';') : new List<String>();
	public static Set<String> set_CompanyIds = new Set<String>();
	public static Set<String> set_VisitorEmailAddresses = new Set<String>();
	public static Map<String, Id> map_CompanyIdToAccId = new Map<String, Id>();
	public static Map<String, Id> map_AccountIdOpportunityId = new Map<String, Id>();
	public static Map<String, Id> map_VisitorEmailAddressesToLeadId = new Map<String, Id>();
	public static Map<String, Contact> map_VisitorEmailAddressesToContactId = new Map<String, Contact>();
	public static Map<String, Case_Pillar_Mapping__c> map_PillarMappingByKey = new Map<String, Case_Pillar_Mapping__c>();
	public static Map<String, Case_Pillar_Mapping__c> map_PillarWOCompanySize = new Map<String, Case_Pillar_Mapping__c>();
	public final static String GCORP_V2_BUTTON = 'GcorpV2';
	public final static String GCORP_PRICING_BUTTON = 'GCorpPricing';
	public static String NOT_PREDICTED = 'not_predicted';
	public static final Id RECTYPE_ENGAGEMENT = Cache.getRecordTypeId('Case', 'Engagement');

	public void OnBeforeInsert(List<LiveChatTranscript> list_LiveChatTranscripts) {
		createCollectionsBefore(list_LiveChatTranscripts, null);

		getMapCompanyIDtoAccountID(set_CompanyIds);
		getMapAccountIDWithOpportunityID(map_CompanyIdToAccId.values());
		getMapVisitorEmailAddressToLeadID(set_VisitorEmailAddresses);
		getMapVisitorEmailAddressToContactID(set_VisitorEmailAddresses);
		for (LiveChatTranscript objLiveChat : list_LiveChatTranscripts) {
			setRelatedFieldToChatTranscript(objLiveChat, null);
		}
		processInformation(list_LiveChatTranscripts);
	}

	public void createCollectionsBefore(List<LiveChatTranscript> list_LiveChatTranscripts, Map<Id, LiveChatTranscript> map_OldLiveChatTranscripts) {
		if (!skipTrigger) {
			for (LiveChatTranscript objLiveChat : list_LiveChatTranscripts) {
				if (String.isNotBlank(objLiveChat.Visitor_Email_Address__c)) {
					set_VisitorEmailAddresses.add(objLiveChat.Visitor_Email_Address__c);
				}
				if (String.isNotBlank(objLiveChat.Company_ID__c)) {
					set_CompanyIds.add(objLiveChat.Company_ID__c);
				}
			}
		}
	}

	public void setRelatedFieldToChatTranscript(LiveChatTranscript objLiveChat, LiveChatTranscript objOldLiveChat) {
		if (!map_CompanyIdToAccId.isEmpty() || !map_VisitorEmailAddressesToContactId.isEmpty() || !map_AccountIdOpportunityId.isEmpty() || !map_VisitorEmailAddressesToLeadId.isEmpty()) {
			if (String.isNotBlank(objLiveChat.Company_Id__c) && String.isNotBlank(objLiveChat.Visitor_Email_Address__c)) {
				if (map_CompanyIdToAccId?.get(objLiveChat.Company_Id__c) == map_VisitorEmailAddressesToContactId?.get(objLiveChat.Visitor_Email_Address__c).AccountId) {
					objLiveChat.ContactId = map_VisitorEmailAddressesToContactId?.get(objLiveChat.Visitor_Email_Address__c).Id;
				}
				objLiveChat.AccountId = map_CompanyIdToAccId?.get(objLiveChat.Company_ID__c);

				if (map_AccountIdOpportunityId != null && map_CompanyIdToAccId != null && !map_AccountIdOpportunityId.isEmpty()) {
					objLiveChat.Opportunity__c = map_AccountIdOpportunityId.get(map_CompanyIdToAccId?.get(objLiveChat.Company_ID__c));
				}
			}
			if (String.isBlank(objLiveChat.ContactId) && String.isBlank(objLiveChat.AccountId) && String.isBlank(objLiveChat.LeadId) && String.isNotBlank(objLiveChat.Visitor_Email_Address__c)) {
				objLiveChat.LeadId = map_VisitorEmailAddressesToLeadId?.get(objLiveChat.Visitor_Email_Address__c);
			}
		}
	}

	/**
	 * @author      Lalitha Kasturi
	 * @description Set AccountID From ChatTranscript
	 *
	 **/
	public void getMapCompanyIDtoAccountID(Set<String> set_CompanyIds) {
		if (!set_CompanyIds.isEmpty()) {
			List<Account> list_Accounts = queryZPCompanyID(set_CompanyIds);
			for (Account objAcc : list_Accounts) {
				if (String.isNotBlank(objAcc.ZP_Company_ID__c)) {
					map_CompanyIdToAccId.put(objAcc.ZP_Company_ID__c, objAcc.Id);
				}
			}
		}
	}

	/**
	 * @author      Lalitha Kasturi
	 * @description Set Opportunity
	 *
	 **/
	public void getMapAccountIDWithOpportunityID(List<String> companyIDs) {
		for (Opportunity objOpp : queryCompanyOpportunity(companyIDs)) {
			if (objOpp.AccountId != null) {
				map_AccountIdOpportunityId.put(objOpp.AccountId, objOpp.Id);
			}
		}
	}

	/**
	 * @author      Nigam Goyal
	 * @description Get LeadID
	 *
	 **/

	public void getMapVisitorEmailAddressToLeadID(Set<String> set_VisitorEmailAddresses) {
		if (!set_VisitorEmailAddresses.isEmpty()) {
			for (Lead objLead : queryLeads(set_VisitorEmailAddresses)) {
				if (String.isNotBlank(objLead.Email)) {
					map_VisitorEmailAddressesToLeadId.put(objLead.Email, objLead.Id);
				}
			}
		}
	}

	/**
	 * @author      Lalitha Kasturi
	 * @description Set ContactID
	 *
	 **/

	public void getMapVisitorEmailAddressToContactID(Set<String> set_VisitorEmailAddresses) {
		if (!set_VisitorEmailAddresses.isEmpty()) {
			for (Contact objCon : queryContacts(set_VisitorEmailAddresses)) {
				if (String.isNotBlank(objCon.Email)) {
					map_VisitorEmailAddressesToContactId.put(objCon.Email, objCon);
				}
			}
		}
	}

	public static List<Account> queryZPCompanyID(Set<String> set_CompanyIds) {
		return [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :set_CompanyIds];
	}

	public static List<Opportunity> queryCompanyOpportunity(List<String> set_AccountIds) {
		return [
			SELECT Id, AccountId
			FROM Opportunity
			WHERE
				AccountId IN :set_AccountIds
				AND (RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
				OR (RecordTypeId = :OpportunityUtil.ACQUISITION_OPPTY_RT_ID
				AND Type = :OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS))
		];
	}

	public static List<Contact> queryContacts(Set<String> set_VisitorEmailAddresses) {
		return [SELECT Id, Email, AccountId FROM Contact WHERE Email IN :set_VisitorEmailAddresses];
	}

	public static List<Lead> queryLeads(Set<String> set_VisitorEmailAddresses) {
		return [SELECT Id, Email FROM Lead WHERE Email IN :set_VisitorEmailAddresses];
	}

	//add chat button name - chat to recent queue name
	//put chat button id in recent queue id
	public void OnAfterInsert(Map<Id, LiveChatTranscript> newLiveChatTranscriptMap) {
		if (!skipTrigger) {
			List<Case_Audit_Log__c> caseAuditlogList = new List<Case_Audit_Log__c>();

			if (null != newLiveChatTranscriptMap && newLiveChatTranscriptMap.size() > 0) {
				for (LiveChatTranscript calRec : newLiveChatTranscriptMap.values()) {
					Case_Audit_Log__c logToInsert = new Case_Audit_Log__c();
					logToInsert.Case__c = calRec.caseId;
					logToInsert.Event_Type__c = 'Chat';
				}
			}
		}
	}

	public void OnBeforeUpdate(Map<Id, LiveChatTranscript> oldLiveChatTranscriptMap, Map<Id, LiveChatTranscript> newLiveChatTranscriptMap) {
		if (!skipTrigger) {
			/*
                Author: Alex
                Date: 8/4/2020
                Desc: if chat transcript is done, look through body
                look for first and last occurances of '<br>(' these are first and last chat times. CHANGED TO '>('
                parse the next couple of characters
                ( HHh MMm SSs )
            */
			Map<Id, ChatTime> map_ChatIdToTimes = new Map<Id, ChatTime>();
			for (LiveChatTranscript newChat : newLiveChatTranscriptMap.values()) {
				LiveChatTranscript oldChat = oldLiveChatTranscriptMap.get(newChat.Id);
				if (
					(newChat.Status == 'Completed' && oldChat.Status != 'Completed' || newChat.Biztech_test__c != oldChat.Biztech_test__c) &&
					newChat.RecordTypeId == Cache.getRecordTypeId('LiveChatTranscript', 'External')
				) {
					if (!String.isBlank(newChat.Body)) {
						List<String> list_ChatMsgs = newChat.Body.split('>\\(');
						if (!list_chatMsgs.isEmpty()) {
							list_chatMsgs.remove(0); //first string is junk
							if (!list_chatMsgs.isEmpty()) {
								ChatTime ct = new ChatTime();
								ct.startTime = list_ChatMsgs[0].substringBefore(')');
								ct.endTime = list_ChatMsgs[list_ChatMsgs.size() - 1].substringBefore(')');

								map_ChatIdToTimes.put(newChat.Id, ct);
							}
						}
					}
				}
			}

			//split the times by space and get list that can be Hours, Minutes, Seconds
			//or Minutes, Seconds
			//or just Seconds
			Map<Id, Integer> map_ChatIdToDuration = new Map<Id, Integer>();

			for (Id chatId : map_ChatIdToTimes.keySet()) {
				ChatTime ct = map_ChatIdToTimes.get(chatId);
				List<String> list_StartTimeParts = ct.startTime.split(' ');
				List<String> list_EndTimeParts = ct.endTime.split(' ');

				Integer intStart = calculateTimeFromParts(list_StartTimeParts);
				Integer intEnd = calculateTimeFromParts(list_EndTimeParts);
				Integer intDuration = intEnd - intStart;
				map_ChatIdToDuration.put(chatId, intDuration);
			}

			for (LiveChatTranscript newChat : newLiveChatTranscriptMap.values()) {
				if (map_ChatIdToDuration.keySet().contains(newChat.Id)) {
					newChat.Chat_Duration_parsed__c = map_ChatIdToDuration.get(newChat.Id);
				}
			}
		}
	}

	public static Integer calculateTimeFromParts(List<String> list_TimeParts) {
		Integer intDuration = 0;
		for (String strTimePart : list_TimeParts) {
			if (strTimePart.endsWith('h')) {
				strTimePart = strTimePart.removeEnd('h');
				Integer intHour = Integer.valueOf(strTimePart) * 60 * 60;
				intDuration += intHour;
			} else if (strTimePart.endsWith('m')) {
				strTimePart = strTimePart.removeEnd('m');
				Integer intMin = Integer.valueOf(strTimePart) * 60;
				intDuration += intMin;
			} else if (strTimePart.endsWith('s')) {
				strTimePart = strTimePart.removeEnd('s');
				Integer intSec = Integer.valueOf(strTimePart);
				intDuration += intSec;
			}
		}
		return intDuration;
	}

	public void OnAfterUpdate(Map<Id, LiveChatTranscript> map_OldChatById, Map<Id, LiveChatTranscript> map_ChatById) {
		if (skipTrigger) {
			return;
		}

		Map<Id, LiveChatTranscript> map_ChatTranscriptById = new Map<Id, LiveChatTranscript>();
		Map<Id, AgentWork> map_AgentWorkByChatId = new Map<Id, AgentWork>();
		List<LiveChatTranscript> list_ChatTranscriptsToUpdate = new List<LiveChatTranscript>();
		List<Case> list_Cases = new List<Case>();
		List<Lead> list_Leads = new List<Lead>();
		List<Case_Audit_Log__c> list_CaseAuditLogs = new List<Case_Audit_Log__c>();

		if (map_ChatById != null && !map_ChatById.isEmpty()) {
			List<Id> list_ChatButtonIds = new List<Id>();
			Set<Id> set_CaseIds = new Set<Id>();
			Set<Id> set_LeadIds = new Set<Id>();

			for (LiveChatTranscript objChat : map_ChatById.values()) {
				list_ChatButtonIds.add(objChat.LiveChatButtonId);
				if (objChat.CaseId != null) {
					set_CaseIds.add(objChat.CaseId);
				}
				if (objChat.LeadId != null) {
					set_LeadIds.add(objChat.LeadId);
				}
			}

			Map<Id, LiveChatButton> map_ChatButtonsById = new Map<Id, LiveChatButton>([SELECT Id, MasterLabel FROM LiveChatButton WHERE Id IN :list_ChatButtonIds]);
			Map<String, Case> map_CaseById = queryCases(set_CaseIds);
			Map<String, Lead> map_LeadById = queryChatLeads(set_LeadIds);
			Map<String, LiveChatTranscriptEvent> map_ChatEventByChatId = queryChatEvents(map_ChatById.keySet());
			getCasePillarMappings();

			List<AgentWork> list_AgentWorks = [
				SELECT Id, Activetime, CloseDateTime, WorkItemId, UserId, AcceptDateTime, HandleTime, RequestDateTime
				FROM AgentWork
				WHERE WorkItemId IN :map_ChatById.keySet()
				ORDER BY CreatedDate ASC
			];

			List<Case_Reason_Classification__c> list_NoActionCaseReasons = CaseQueryHelper.queryCaseReason(CaseUtils.STR_AUTO_SOLVED_CASE_REASON);

			for (AgentWork objAgentWork : list_AgentWorks) {
				map_AgentWorkByChatId.put(objAgentWork.WorkItemId, objAgentWork);
			}

			for (LiveChatTranscript objChat : [
				SELECT
					Id,
					Status,
					CaseId,
					LeadId,
					Case.CaseNumber,
					Active_Time__c,
					DIVR_Id__c,
					Body,
					RecordType.Name,
					LiveChatButtonId,
					OwnerId,
					Phone__c,
					Lead_Source__c,
					ZP_Lead_Campaign__c,
					Trk_UTM_Medium__c,
					Trk_UTM_Content__c,
					Trk_Placement__c,
					Trk_network__c,
					Trk_matchtype__c,
					Trk_Keyword__c,
					Trk_gclid__c,
					Trk_Device__c,
					Trk_creative__c,
					msclkid__c,
					Landing_Page__c,
					adgroup__c,
					Visitor_Id__c,
					Session_Id__c,
					Last_Form_Fill_URL__c,
					Lead_Creation_Offer__c,
					Recent_Campaign__c,
					Recent_Content__c,
					Recent_Source__c,
					URL_of_Conversion__c,
					Referring_Url__c,
					Request_Type__c,
					Support_Level__c,
					Persona__c,
					Company_Size__c,
					Biztech_test__c,
					ORCA_Predicted_Case_Reason_Confidence__c,
					ORCA_Predicted_Specialization_Confidence__c,
					ORCA_Predicted_Support_Level_Confidence__c,
					ORCA_Predicted_Type_Confidence__c,
					ORCA_Predicted_Case_Reason__c,
					ORCA_Predicted_Specialization__c,
					ORCA_Predicted_Support_Level__c,
					Second_Level__c
				FROM LiveChatTranscript
				WHERE Id IN :map_ChatById.keySet()
			]) {
				map_ChatTranscriptById.put(objChat.Id, objChat);
				LiveChatTranscript objOldChat = map_OldChatById.get(objChat.Id);

				if (objChat.CaseId != null && map_CaseById.containsKey(objChat.CaseId)) {
					Case objCase = map_CaseById.get(objChat.CaseId);
					if (objChat.Request_Type__c != null && objChat.Support_Level__c != null && objChat.Persona__c != null && !objCase.IsClosed) {
						objCase.Type = objChat.Request_Type__c;
						objCase.Support_Level__c = objChat.Support_Level__c;
						objCase.Persona__c = objChat.Persona__c;
						objCase.Company_Size__c = objChat.Company_Size__c;
						objCase.RecordTypeId = RECTYPE_ENGAGEMENT;
					}

					if (objChat.RecordTypeId == Utils.CHAT_EXTERNAL_RT_ID && !objCase.IsClosed && objCase.RecordTypeId == RECTYPE_ENGAGEMENT) {
						if (
							(objOldChat.Request_Type__c != objChat.Request_Type__c ||
							objOldChat.Company_Size__c != objChat.Company_Size__c ||
							objOldChat.Persona__c != objChat.Persona__c ||
							objOldChat.Support_Level__c != objChat.Support_Level__c) || (String.isBlank(objOldChat.CaseId) && String.isNotBlank(objChat.CaseId))
						) {
							objCase = updatePillarMapping(objCase, objChat, map_PillarMappingByKey, map_PillarWOCompanySize);
							objChat.WFM_Queue_Tag__c = objCase.WFM_Queue_Tag__c;
							list_ChatTranscriptsToUpdate.add(objChat);
						}

						if (String.isBlank(objOldChat.CaseId) && String.isNotBlank(objChat.CaseId)) {
							objCase.ORCA_Predicted_Specialization__c = objChat.ORCA_Predicted_Specialization__c;
							objCase.ORCA_Predicted_Support_Level__c = objChat.ORCA_Predicted_Support_Level__c;
							objCase.Second_Level__c = objChat.Second_Level__c;
							objCase.ORCA_Predicted_Case_Reason__c = objChat.ORCA_Predicted_Case_Reason__c;
							objCase.ORCA_Predicted_Case_Reason_Confidence__c = objChat.ORCA_Predicted_Case_Reason_Confidence__c;
							objCase.ORCA_Predicted_Specialization_Confidence__c = objChat.ORCA_Predicted_Specialization_Confidence__c;
							objCase.ORCA_Predicted_Support_Level_Confidence__c = objChat.ORCA_Predicted_Support_Level_Confidence__c;
							objCase.ORCA_Predicted_Type_Confidence__c = objChat.ORCA_Predicted_Type_Confidence__c;
						}
					}

					if (
						objChat.Status == Utils.CHAT_STATUS_MISSED &&
						objChat.RecordTypeId == Utils.CHAT_EXTERNAL_RT_ID &&
						!objCase.IsClosed &&
						objCase.RecordTypeId != CaseUtils.RECTYPE_R_D_TAX_CREDITS
					) {
						String strEngCancelOwnerId = GlobalQueryHelper.getQueueIdByDevName(CaseUtils.QUEUE_NAME_ENGAGEMENT_CANCELED_CHATS);
						String strVisitorCancelChatOwnerId = GlobalQueryHelper.getQueueIdByDevName(CaseUtils.QUEUE_NAME_CARE_VISITOR_ABANDONED_CHATS);
						if (
							map_ChatEventByChatId?.containsKey(objChat.Id) &&
							objCase.RecordTypeId == RECTYPE_ENGAGEMENT &&
							(String.isNotBlank(strEngCancelOwnerId) || String.isNotBlank(strVisitorCancelChatOwnerId))
						) {
							objCase.OwnerId = (map_ChatEventByChatId.get(objChat.Id).Type == Utils.CHAT_EVENT_TYPE_CANCELNOAGENT) ? strEngCancelOwnerId : strVisitorCancelChatOwnerId;
							objCase.Audience__c = CaseUtils.AUDIENCE_OTHER;
							if (!list_NoActionCaseReasons.isEmpty()) {
								objCase.Confirm_Case_Reason_Classification__c = list_NoActionCaseReasons[0].Id;
							}
							if(map_ChatEventByChatId.get(objChat.Id).Type == Utils.CHAT_EVENT_TYPE_DURATION_TIME_OUT){
								objCase.Status = CaseUtils.STATUS_OPEN;
								objCase.OwnerId = strVisitorCancelChatOwnerId;
							}
						}

						objCase.Status = CaseUtils.STATUS_CLOSED;
					}

					if (objChat.RecordType.Name != CaseUtils.INTERNAL_TEAM && !objCase.IsClosed) {
						objCase.Direction__c = CaseUtils.DIRECTION_INBOUND;
						objCase.Recent_Queue_Id__c = (String) objChat.LiveChatButtonId;
						objCase.Recent_Queue_Name__c = map_ChatButtonsById.get(objChat.LiveChatButtonId)?.MasterLabel + ' - ' + CaseUtils.ORIGIN_CHAT;

						if (Test.isRunningTest() && boolTestThis) {
							objChat.Status = 'Missed';
						}

						objCase.Recent_Queue_Name__c += ' - ' + objChat.Status;

						if (String.isNotBlank(objChat.Body)) {
							objCase.Description = objChat.Body.stripHtmlTags(); // to be only handle for external
						}
					}

					if (map_AgentWorkByChatId.containsKey(objChat.Id) && (objChat.Status != objOldChat.Status || (objChat.CaseId != null && objOldChat.CaseId == null))) {
						AgentWork objAgentWork = map_AgentWorkByChatId.get(objChat.Id);

						Case_Audit_Log__c objAuditLog = new Case_Audit_Log__c();
						objAuditLog.Case__c = objCase.Id;
						objAuditLog.Direction__c = CaseUtils.DIRECTION_INBOUND;

						if (objChat.RecordType.Name == CaseUtils.INTERNAL_TEAM) {
							objAuditLog.Event_Type__c = CaseUtils.INTERNAL_TEAM + ' ' + CaseUtils.ORIGIN_CHAT;
						} else {
							objAuditLog.Event_Type__c = CaseUtils.ORIGIN_CHAT;
						}

						objAuditLog.Advocate__c = objAgentWork.UserId;
						objAuditLog.To_Date_Time__c = objAgentWork.CloseDateTime;
						objAuditLog.From_Date_Time__c = objAgentWork.AcceptDateTime;
						objAuditLog.Live_Channel_Start_Time__c = objAgentWork.RequestDateTime;

						if (bizHours != null && !bizHours.isEmpty()) {
							objAuditLog.Business_Hours__c = bizHours[0].Id;

							if (!Test.isRunningTest() && objAgentWork.RequestDateTime != null && objAgentWork.AcceptDateTime != null) {
								Long milliSeconds = BusinessHours.diff(bizHours[0].Id, objAgentWork.RequestDateTime, objAgentWork.AcceptDateTime);
								objAuditLog.Live_Channel_Wait_Time_In_Seconds__c = milliSeconds / 1000;
							}
						}

						if (objChat.Status == Utils.CHAT_STATUS_COMPLETED) {
							objChat.Case_Number__c = objChat.Case.CaseNumber;
							objChat.Active_Time__c = objAgentWork.Activetime;
							objChat.Tab_Close_Time__c = objAgentWork.CloseDateTime;
							list_ChatTranscriptsToUpdate.add(objChat);
						}

						list_CaseAuditLogs.add(objAuditLog);
					}

					list_Cases.add(objCase);
				}

				if (objChat.LeadId != null && map_LeadById.containsKey(objChat.LeadId)) {
					Lead objLead = map_LeadById.get(objChat.LeadId);

					// update Phone on lead from chat transcript when Phone on lead is blank
					if (String.isNotBlank(objChat.Phone__c) && String.isBlank(objLead.Phone)) {
						objLead.Phone = objChat.Phone__c;
					}
					// update Alternate_Phone__c if Phone on transcript is different from Phone on related Lead
					if (String.isNotBlank(objChat.Phone__c) && String.isNotBlank(objLead.Phone) && (objChat.Phone__c != objLead.Phone)) {
						objLead.Alternate_Phone__c = objChat.Phone__c;
					}

					if (objLead.Createdby.Name == LeadUtil.PLATFORM_INTEGRATION_USER) {
						if (
							String.isNotBlank(objChat.Lead_Source__c) &&
							(String.isBlank(objLead.LeadSource) ||
							objLead.LeadSource == LeadUtil.LEADSOURCE_SRC_ERROR ||
							objLead.LeadSource == LeadUtil.LEADSOURCE_OUTBOUND)
						) {
							objLead.LeadSource = objChat.Lead_Source__c;
						}
						// update attribution fields on Lead if they are blank
						if (String.isNotBlank(objChat.ZP_Lead_Campaign__c) && (String.isBlank(objLead.ZP_Lead_Campaign__c) || objLead.ZP_Lead_Campaign__c == LeadUtil.LABEL_LEAD_CAMP_OTHER)) {
							objLead.ZP_Lead_Campaign__c = objChat.ZP_Lead_Campaign__c;
						}
						if (String.isNotBlank(objChat.Trk_UTM_Medium__c) && String.isBlank(objLead.Trk_UTM_Medium__c)) {
							objLead.Trk_UTM_Medium__c = objChat.Trk_UTM_Medium__c;
						}
						if (String.isNotBlank(objChat.Trk_UTM_Content__c) && String.isBlank(objLead.Trk_UTM_Content__c)) {
							objLead.Trk_UTM_Content__c = objChat.Trk_UTM_Content__c;
						}
						if (String.isNotBlank(objChat.Trk_Placement__c) && String.isBlank(objLead.Trk_Placement__c)) {
							objLead.Trk_Placement__c = objChat.Trk_Placement__c;
						}
						if (String.isNotBlank(objChat.Trk_network__c) && String.isBlank(objLead.Trk_network__c)) {
							objLead.Trk_network__c = objChat.Trk_network__c;
						}
						if (String.isNotBlank(objChat.Trk_matchtype__c) && String.isBlank(objLead.Trk_matchtype__c)) {
							objLead.Trk_matchtype__c = objChat.Trk_matchtype__c;
						}
						if (String.isNotBlank(objChat.Trk_Keyword__c) && String.isBlank(objLead.Trk_Keyword__c)) {
							objLead.Trk_Keyword__c = objChat.Trk_Keyword__c;
						}
						if (String.isNotBlank(objChat.Trk_gclid__c) && String.isBlank(objLead.Trk_gclid__c)) {
							objLead.Trk_gclid__c = objChat.Trk_gclid__c;
						}
						if (String.isNotBlank(objChat.Trk_Device__c) && String.isBlank(objLead.Trk_Device__c)) {
							objLead.Trk_Device__c = objChat.Trk_Device__c;
						}
						if (String.isNotBlank(objChat.Trk_creative__c) && String.isBlank(objLead.Trk_creative__c)) {
							objLead.Trk_creative__c = objChat.Trk_creative__c;
						}
						if (String.isNotBlank(objChat.msclkid__c) && String.isBlank(objLead.msclkid__c)) {
							objLead.msclkid__c = objChat.msclkid__c;
						}
						if (String.isNotBlank(objChat.Landing_Page__c) && String.isBlank(objLead.Landing_Page__c)) {
							objLead.Landing_Page__c = objChat.Landing_Page__c;
						}
						if (String.isNotBlank(objChat.adgroup__c) && String.isBlank(objLead.adgroup__c)) {
							objLead.adgroup__c = objChat.adgroup__c;
						}
						if (String.isNotBlank(objChat.Visitor_Id__c) && String.isBlank(objLead.Visitor_Id__c)) {
							objLead.Visitor_Id__c = objChat.Visitor_Id__c;
						}
						if (String.isNotBlank(objChat.Session_Id__c) && String.isBlank(objLead.Session_Id__c)) {
							objLead.Session_Id__c = objChat.Session_Id__c;
						}
						if (String.isNotBlank(objChat.Last_Form_Fill_URL__c) && String.isBlank(objLead.Last_Form_Fill_URL__c)) {
							objLead.Last_Form_Fill_URL__c = objChat.Last_Form_Fill_URL__c;
						}
						if (
							objChat.LiveChatButtonId != null &&
							map_ChatButtonsById.containsKey(objChat.LiveChatButtonId) &&
							(String.isBlank(objLead.Lead_Creation_Offer__c) || objLead.Lead_Creation_Offer__c == LeadUtil.LEADCREATION_OFFER_PROD_GEN)
						) {
							if (map_ChatButtonsById.get(objChat.LiveChatButtonId).MasterLabel == GCORP_V2_BUTTON) {
								objLead.Lead_Creation_Offer__c = LeadUtil.LEADSOURCE_LIVE_CHAT;
							} else if (map_ChatButtonsById.get(objChat.LiveChatButtonId).MasterLabel == GCORP_PRICING_BUTTON) {
								objLead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PROACTIVE_CHAT;
							}
						}
						if (String.isNotBlank(objChat.Recent_Campaign__c) && String.isBlank(objLead.Recent_Campaign__c)) {
							objLead.Recent_Campaign__c = objChat.Recent_Campaign__c;
						}
						if (String.isNotBlank(objChat.Recent_Content__c) && String.isBlank(objLead.Recent_Content__c)) {
							objLead.Recent_Content__c = objChat.Recent_Content__c;
						}
						if (String.isNotBlank(objChat.Recent_Source__c) && String.isBlank(objLead.Recent_Source__c)) {
							objLead.Recent_Source__c = objChat.Recent_Source__c;
						}
						if (String.isNotBlank(objChat.URL_of_Conversion__c) && String.isBlank(objLead.URL_of_Conversion__c)) {
							objLead.URL_of_Conversion__c = objChat.URL_of_Conversion__c;
						}
						if (String.isNotBlank(objChat.Referring_Url__c) && String.isBlank(objLead.Referring_Url__c)) {
							objLead.Referring_Url__c = objChat.Referring_Url__c;
						}
						if (String.isBlank(objLead.MQL_Reason__c)) {
							objLead.MQL_Reason__c = LeadUtil.MQL_REASON_IB_CHAT;
						}
					}

					list_Leads.add(objLead);
				}
			}

			try {
				if (!list_ChatTranscriptsToUpdate.isEmpty()) {
					Boolean blnSkipFlag = LiveChatTranscriptTriggerHelper.skipTrigger;
					LiveChatTranscriptTriggerHelper.skipTrigger = true;
					Database.update(list_ChatTranscriptsToUpdate, false);
					LiveChatTranscriptTriggerHelper.skipTrigger = blnSkipFlag;
				}

				if (!list_Cases.isEmpty()) {
					CaseTriggerHelper.skipTrigger = true;
					Database.update(list_Cases, false);
					CaseTriggerHelper.skipTrigger = false;
				}

				if (!list_CaseAuditLogs.isEmpty()) {
					insert list_CaseAuditLogs;
				}

				if (!list_Leads.isEmpty()) {
					TriggerHandler.bypass('LeadTriggerHandler');
					update list_Leads;
					TriggerHandler.clearBypass('LeadTriggerHandler');
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('LiveChatTranscriptTriggerHelper', 'OnAfterUpdate', ex.getMessage(), ex.getStackTraceString());
			}
		}
	}

	/*
        Class that stores chat start and end time strings
    */
	public class ChatTime {
		public String startTime;
		public String endTime;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Query for Cases
	 * @Parm        : set_CaseIds - Set of Case IDs
	 * @Return      : Map of case Id and case
	 **/
	public Map<String, Case> queryCases(Set<Id> set_CaseIds) {
		Map<String, Case> map_CaseIdVsCase = new Map<String, Case>();
		if (set_CaseIds.size() > 0) {
			for (Case objCase : [SELECT Id, IsClosed, RecordTypeId, Origin, Channel__c FROM Case WHERE Id IN :set_CaseIds]) {
				map_CaseIdVsCase.put(objCase.Id, objCase);
			}
		}
		return map_CaseIdVsCase;
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Query for Leads
	 * @Parm        : set_LeadIds - Set of Lead IDs
	 * @Return      : Map of Lead Id and Lead
	 **/
	public Map<String, Lead> queryChatLeads(Set<Id> set_LeadIds) {
		Map<String, Lead> map_LeadById = new Map<String, Lead>();
		if (!set_LeadIds.isEmpty()) {
			for (Lead objLead : [
				SELECT
					Id,
					LeadSource,
					Phone,
					Status,
					Alternate_Phone__c,
					ZP_Lead_Campaign__c,
					Trk_UTM_Medium__c,
					Trk_UTM_Content__c,
					Trk_Placement__c,
					Trk_network__c,
					Trk_matchtype__c,
					Trk_Keyword__c,
					Trk_gclid__c,
					Trk_Device__c,
					Trk_creative__c,
					msclkid__c,
					Landing_Page__c,
					adgroup__c,
					Visitor_Id__c,
					Session_Id__c,
					Last_Form_Fill_URL__c,
					Lead_Creation_Offer__c,
					Recent_Campaign__c,
					Recent_Content__c,
					Recent_Source__c,
					URL_of_Conversion__c,
					Referring_Url__c,
					MQL_Reason__c,
					CreatedBy.Name
				FROM Lead
				WHERE Id IN :set_LeadIds
			]) {
				map_LeadById.put(objLead.Id, objLead);
			}
		}
		return map_LeadById;
	}

	/**
	 * @Author      : Pradeep Chary
	 * @Description : Query for Live Chat Transcript Events
	 * @Parm        : set_ChatIds - Set of Live Chat Transcript Ids
	 * @Return      : Map of Live Chat Transcript Id and Live Chat Transcript Event
	 **/
	public Map<String, LiveChatTranscriptEvent> queryChatEvents(Set<Id> set_ChatIds) {
		Map<String, LiveChatTranscriptEvent> map_ChatEventByChatId = new Map<String, LiveChatTranscriptEvent>();
		Set<String> liveChatTranscripteventTypes = new Set<String>{Utils.CHAT_EVENT_TYPE_DURATION_TIME_OUT,Utils.CHAT_EVENT_TYPE_CANCELNOAGENT,Utils.CHAT_EVENT_TYPE_CANCELVISITOR};
		if (!set_ChatIds.isEmpty()) {
			for (LiveChatTranscriptEvent objEvent : [
				SELECT Id, Type, LiveChatTranscriptId
				FROM LiveChatTranscriptEvent
				WHERE LiveChatTranscriptId IN :set_ChatIds AND Type IN :liveChatTranscripteventTypes
			]) {
				map_ChatEventByChatId.put(objEvent.LiveChatTranscriptId, objEvent);
			}
		}
		return map_ChatEventByChatId;
	}

	/**
	 * @Author      : Ankit C
	 * @Description : This method will update the Pillar,Sub-Pillar & WFM Queue Tag fields on the associated Case
	 * @Parm        : objCase - Case associated to the Chat, map_PillarMappingByKey - Map of CasePillarMapping by unique key,
	 *                map_PillarWOCompanySize - Map of CasePillarMapping by unique key without comapany size
	 * 				  objChat - LiveChatTranscript from trigger.new
	 * @Return      : objCase - Case associated to the Chat
	 **/
	private Case updatePillarMapping(
		Case objCase,
		LiveChatTranscript objChat,
		Map<String, Case_Pillar_Mapping__c> map_PillarMappingByKey,
		Map<String, Case_Pillar_Mapping__c> map_PillarWOCompanySize
	) {
		objCase.Type = objChat.Request_Type__c;
		objCase.Support_Level__c = objChat.Support_Level__c;
		objCase.Persona__c = objChat.Persona__c;
		objCase.Company_Size__c = objChat.Company_Size__c;
		String strKey = '';
		if ((objCase.Origin == CaseUtils.ORIGIN_EMAIL || (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_EMAIL))) {
			strKey = CaseUtils.ORIGIN_EMAIL;
		} else if ((objCase.Origin == CaseUtils.ORIGIN_CHAT || (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT))) {
			strKey = CaseUtils.ORIGIN_CHAT;
		}

		//If the Specialization value is configured in the Engagement_Specializations custom label, consider the Persona and Company Size for pillar mapping
		if (String.isNotBlank(objChat.ORCA_Predicted_Specialization__c) && objChat.ORCA_Predicted_Specialization__c != NOT_PREDICTED) {
			if (list_Specializations.contains(objChat.ORCA_Predicted_Specialization__c)) {
				strKey += objChat.ORCA_Predicted_Specialization__c + '' + objChat.Persona__c;
				if (objChat.Persona__c != CaseUtils.MEMBER_PERSONA && objChat.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
					strKey += objChat.Company_Size__c;
				}
			} else {
				strKey += objChat.ORCA_Predicted_Specialization__c;
			}
		} else {
			strKey += objCase.Type + '' + objCase.Persona__c + '' + objCase.Support_Level__c;
			if (objCase.Persona__c != CaseUtils.MEMBER_PERSONA && objCase.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
				strKey += objCase.Company_Size__c;
			}
		}

		strKey = strKey.toLowerCase();

		if ((objCase.Persona__c == CaseUtils.MEMBER_PERSONA || objCase.Persona__c == CaseUtils.ACCOUNTANT_PERSONA) && map_PillarWOCompanySize.containsKey(strKey)) {
			objCase.Case_Pillar__c = map_PillarWOCompanySize.get(strKey).Pillar__c;
			objCase.Sub_Pillar__c = map_PillarWOCompanySize.get(strKey).Sub_Pillar__c;
			objCase.WFM_Queue_Tag__c = map_PillarWOCompanySize.get(strKey).WFM_Queue_Tag__c;
			objCase.Pillar_Key__c = map_PillarWOCompanySize.get(strKey).Pillar_Key__c;
			objCase.Sub_Pillar_Key__c = map_PillarWOCompanySize.get(strKey).Sub_Pillar_Key__c;
		} else if (map_PillarMappingByKey.containsKey(strKey)) {
			objCase.Case_Pillar__c = map_PillarMappingByKey.get(strKey).Pillar__c;
			objCase.Sub_Pillar__c = map_PillarMappingByKey.get(strKey).Sub_Pillar__c;
			objCase.WFM_Queue_Tag__c = map_PillarMappingByKey.get(strKey).WFM_Queue_Tag__c;
			objCase.Pillar_Key__c = map_PillarMappingByKey.get(strKey).Pillar_Key__c;
			objCase.Sub_Pillar_Key__c = map_PillarMappingByKey.get(strKey).Sub_Pillar_Key__c;
		} else {
			objCase.Case_Pillar__c = objCase.Sub_Pillar__c = objCase.WFM_Queue_Tag__c = objCase.Pillar_Key__c = objCase.Sub_Pillar_Key__c = '';
		}

		return objCase;
	}

	/*
	* @Author      : Sirisha Kodi
	* @Description : In the following method we are setting up the Routing Case Reason,
					 Based on Case Reason Code present in the ORCA predicted values 
	* @Param       : New Chat Transcript records that are of External Record Type
	*/
	private void processInformation(List<LiveChatTranscript> newChatTranscriptList) {
		try {
			Set<String> reasoncodeSet = new Set<String>();
			Map<String, Case_Reason_Classification__c> map_CaseReasonClassification = new Map<String, Case_Reason_Classification__c>();
			getCasePillarMappings();

			for (LiveChatTranscript eachChatRec : newChatTranscriptList) {
				if (
					eachChatRec.ORCA_Predicted_Case_Reason__c != null &&
					eachChatRec.ORCA_Predicted_Case_Reason__c != '' &&
					eachChatRec.ORCA_Predicted_Case_Reason__c != AgathaPredictionTriggerHelper.AGATHAPREDICTION_NOT_PREDICTED
				) {
					reasoncodeSet.add(eachChatRec.ORCA_Predicted_Case_Reason__c);
				}
			}

			if (!reasoncodeSet.isEmpty()) {
				map_CaseReasonClassification = getReasonClassificationMap(reasoncodeSet);
			}

			for (LiveChatTranscript eachChatRec : newChatTranscriptList) {
				if (
					eachChatRec.ORCA_Predicted_Case_Reason__c != null &&
					eachChatRec.ORCA_Predicted_Case_Reason__c != '' &&
					eachChatRec.ORCA_Predicted_Case_Reason__c != AgathaPredictionTriggerHelper.AGATHAPREDICTION_NOT_PREDICTED &&
					map_CaseReasonClassification.containsKey(eachChatRec.ORCA_Predicted_Case_Reason__c)
				) {
					// If ORCA predicts the chat with a reason code that matches with the CRC object, update the following fields
					Case_Reason_Classification__c objReason = map_CaseReasonClassification.get(eachChatRec.ORCA_Predicted_Case_Reason__c);
					eachChatRec.Routing_Case_Reason_Classification__c = objReason.Id;
					eachChatRec.Request_Type__c = objReason.Case_Type_Pillar__c;
					eachChatRec.Support_Level__c = objReason.Support_Level__c;
					eachChatRec.Team__c = objReason.Routing_Team__c;
				}

				String strKey = CaseUtils.ORIGIN_CHAT;

				//If the Specialization value is configured in the Engagement_Specializations custom label, consider the Persona and Company Size for pillar mapping
				if (String.isNotBlank(eachChatRec.ORCA_Predicted_Specialization__c) && eachChatRec.ORCA_Predicted_Specialization__c != NOT_PREDICTED) {
					if (list_Specializations.contains(eachChatRec.ORCA_Predicted_Specialization__c)) {
						strKey += eachChatRec.ORCA_Predicted_Specialization__c + '' + eachChatRec.Persona__c;
						if (eachChatRec.Persona__c != CaseUtils.MEMBER_PERSONA && eachChatRec.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
							strKey += eachChatRec.Company_Size__c;
						}
					} else {
						strKey += eachChatRec.ORCA_Predicted_Specialization__c;
					}
				} else {
					strKey += eachChatRec.Request_Type__c + '' + eachChatRec.Persona__c + '' + eachChatRec.Support_Level__c;
					if (eachChatRec.Persona__c != CaseUtils.MEMBER_PERSONA && eachChatRec.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
						strKey += eachChatRec.Company_Size__c;
					}
				}

				strKey = strKey.toLowerCase();

				if ((eachChatRec.Persona__c == CaseUtils.MEMBER_PERSONA || eachChatRec.Persona__c == CaseUtils.ACCOUNTANT_PERSONA) && map_PillarWOCompanySize.containsKey(strKey)) {
					eachChatRec.WFM_Queue_Tag__c = map_PillarWOCompanySize.get(strKey).WFM_Queue_Tag__c;
				} else if (map_PillarMappingByKey.containsKey(strKey)) {
					eachChatRec.WFM_Queue_Tag__c = map_PillarMappingByKey.get(strKey).WFM_Queue_Tag__c;
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LiveChatTranscriptTriggerHelper', 'processInformation', ex.getMessage(), ex.getStackTraceString());
		}
	}

	/**
	 * @Author      : Sirisha Kodi
	 * @Description : returns the map of CaseReasons and their respective CaseReasonClassifications
	 * @Param       : reason code - unique identifier on CRC object
	 * @Return      : Map of CaseReasons and their respective CaseReasonClassifications,
	 * 				  referred from AgathaPredictionTriggerHelper for Email cases and
	 * 				  LiveChatTranscriptTriggerHelper for Chat cases
	 */
	private map<String, Case_Reason_Classification__c> getReasonClassificationMap(Set<String> reasonSet) {
		map<String, Case_Reason_Classification__c> reasonIdMap = new Map<String, Case_Reason_Classification__c>();
		for (Case_Reason_Classification__c classification : [
			SELECT
				Id,
				Reason_Code__c,
				Name,
				Type__c,
				Class__c,
				Priority__c,
				Task_Us__c,
				Survey_Eligible__c,
				Auto_Email_Behavior__c,
				Email_Content__c,
				Do_Not_Auto_Solve_for_Auto_Email__c,
				Confidence_Threshold__c,
				Email_Signature__c,
				Override_Email_Signature__c,
				Generic_Routing_Reason__c,
				Default_Type__c,
				Case_Type_Pillar__c,
				Routing_Team__c,
				Support_Level__c,
				Specialization__c
			FROM Case_Reason_Classification__c
			WHERE Reason_Code__c IN :reasonSet
		]) {
			if (String.isNotBlank(classification.Reason_Code__c)) {
				reasonIdMap.put(classification.Reason_Code__c.toLowerCase(), classification);
			}
		}
		return reasonidMap;
	}

	/**
	 * @Author      : Ankit C
	 * @Description : Created the maps for Case_Pillar_Mapping__c
	 * @Param       : None
	 * @Return      : NA
	 */
	private void getCasePillarMappings() {
		for (Case_Pillar_Mapping__c objMapping : Case_Pillar_Mapping__c.getAll().values()) {
			String strKey = objMapping.Case_Origin__c;
			String strKey2 = objMapping.Case_Origin__c;
			if (String.isNotBlank(objMapping.Specialization__c)) {
				strKey += objMapping.Specialization__c;
				if (list_Specializations.contains(objMapping.Specialization__c)) {
					strKey += objMapping.Persona__c + '' + objMapping.Company_Size__c;
					strKey2 += objMapping.Persona__c;
				}
			} else {
				strKey += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c + '' + objMapping.Company_Size__c;
				strKey2 += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c;
			}

			map_PillarMappingByKey.put(strKey.toLowerCase(), objMapping);
			map_PillarWOCompanySize.put(strKey2.toLowerCase(), objMapping);
		}
	}
}