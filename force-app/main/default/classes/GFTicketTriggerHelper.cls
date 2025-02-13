/**
 * @name         : GFTicketTriggerHelper
 * @author       : Alex Xiong
 * @date         : 04/20/2021
 * @description  : The trigger helper for processing GF Tickets
 * @test classes : GFTicketTriggerHelperTest
 **/
public class GFTicketTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean blnQueue = false;

	// Flag set when GF Ticket is updated from Email Message Trigger
	public static Boolean blnIsFirstEOYSpotCase = false;

	public Map<String, Account> map_ZPCompanyIdToAccount;
	public Map<String, Account> map_ZPFirmIdToAccount = new Map<String, Account>();
	public Map<String, Contact> map_UserIdToContact = new Map<String, Contact>();
	public Map<String, Contact> map_EmailToContact = new Map<String, Contact>();
	public Map<String, Case> map_Cases;
	Map<String, Case_Reason_Classification__c> map_Classification = new Map<String, Case_Reason_Classification__c>();
	Map<String, EmailMessage> map_ExistingMsg;
	Set<String> set_TicketIds;
	Set<String> set_ZPCompanyIds;
	Set<String> set_Reasons;
	Set<String> set_ZPUserIds;
	Set<String> set_RequesterEmails;
	Set<String> set_AccountingFirmIds;
	List<Contact> list_CreateContacts;
	Set<String> set_AgencySlug;
	Map<String, Agency_Information__c> map_AgenciesInformationData;

	List<Case> list_UpsertCase;
	Map<String, String> map_DMLUpsertErrors;
	Map<String, String> map_DMLMsgUpsertErrors;
	Map<String, Case> map_ProcessedCases;
	Map<String, EmailMessage> map_ProcessedEmails;
	Map<String, Group> map_QueueByDeveloperName;

	public GFTicketTriggerHelper() {
		set_TicketIds = new Set<String>();
		map_ExistingMsg = new Map<String, EmailMessage>();
		map_Cases = new Map<String, Case>();
		map_ZPCompanyIdToAccount = new Map<String, Account>();
		set_ZPCompanyIds = new Set<String>();
		set_Reasons = new Set<String>();
		set_ZPUserIds = new Set<String>();
		set_RequesterEmails = new Set<String>();
		set_AccountingFirmIds = new Set<String>();
		list_CreateContacts = new List<Contact>();
		list_UpsertCase = new List<Case>();
		map_DMLUpsertErrors = new Map<String, String>();
		map_DMLMsgUpsertErrors = new Map<String, String>();
		map_ProcessedCases = new Map<String, Case>();
		map_ProcessedEmails = new Map<String, EmailMessage>();
		map_Classification = new Map<String, Case_Reason_Classification__c>();
		set_AgencySlug = new Set<String>();
		map_AgenciesInformationData = new Map<String, Agency_Information__c>();
		map_QueueByDeveloperName = new Map<String, Group>();
	}

	public void processBeforeInsert(List<GF_Ticket__c> list_Tickets) {
		if (blnQueue == true) {
			processInformation(list_Tickets);
		} else {
			try {
				for (GF_Ticket__c objTicket : list_Tickets) {
					if (objTicket.Attachments__c != null) {
						String strAttachment = objTicket.Attachments__c.replaceAll('%(?![0-9a-fA-F]{2})', '%25');
						strAttachment = strAttachment.replaceAll('\\+', '%2B');
						objTicket.Attachments__c = EncodingUtil.urlDecode(strAttachment, 'UTF-8');
					}
					objTicket.Processing_State__c = IntegrationUtils.QUEUED_STATE;
					objTicket.Message__c = '';
				}
			} catch (Exception ex) {
				List<String> list_ExceptionString = new List<String>();
				list_ExceptionString.add(ex.getStackTraceString());
				list_ExceptionString.add('Exception');
				ExceptionLogUtil.logException(
					(Id) UserInfo.getUserId(),
					null,
					'GFTicketTriggerHelper',
					'processBeforeInsert - Attachments',
					list_ExceptionString,
					ex.getLineNumber(),
					ex.getMessage(),
					'High'
				);
			}
		}
	}

	public void processAfterInsert(Map<Id, GF_Ticket__c> map_Tickets) {
		if (blnQueue == false) {
			GFTicketQueue objUpdateJob = new GFTicketQueue(map_Tickets.values());
			Id idJob = System.enqueueJob(objUpdateJob);
		}
	}

	public void processBeforeUpdate(Map<Id, GF_Ticket__c> map_OldTickets, Map<Id, GF_Ticket__c> map_newTickets) {
		if (blnQueue == true || blnIsFirstEOYSpotCase) {
			processInformation(map_newTickets.values());
		} else {
			//for exception logging. Finding which GF Ticket record is hitting an error
			GF_Ticket__c objCurrentTicket;
			try {
				for (GF_Ticket__c objTicket : map_newTickets.values()) {
					objCurrentTicket = objTicket;
					if (objTicket.Attachments__c != null) {
						String strAttachment = objTicket.Attachments__c.replaceAll('%(?![0-9a-fA-F]{2})', '%25');
						strAttachment = strAttachment.replaceAll('\\+', '%2B');
						objTicket.Attachments__c = EncodingUtil.urlDecode(strAttachment, 'UTF-8');
					}
					objTicket.Processing_State__c = IntegrationUtils.QUEUED_STATE;
					objTicket.Message__c = '';
				}
			} catch (Exception ex) {
				List<String> list_ExceptionString = new List<String>();
				//logException() needs a list size > 3 or else an exception occurs
				list_ExceptionString.add(ex.getStackTraceString());
				list_ExceptionString.add(ex.getStackTraceString());
				list_ExceptionString.add('Exception');
				setProcessingState(IntegrationUtils.ERROR_STATE, ex.getMessage(), objCurrentTicket);
				ExceptionLogUtil.logException(
					(Id) UserInfo.getUserId(),
					objCurrentTicket.Id,
					'GFTicketTriggerHelper',
					'processBeforeUpdate - Attachments',
					list_ExceptionString,
					ex.getLineNumber(),
					ex.getMessage(),
					'High'
				);
			}
		}
	}

	public void processAfterUpdate(Map<Id, GF_Ticket__c> map_OldTickets, Map<Id, GF_Ticket__c> map_newTickets) {
		if (blnQueue == false && !blnIsFirstEOYSpotCase) {
			GFTicketQueue objUpdateJob = new GFTicketQueue(map_newTickets.values());
			Id idJob = System.enqueueJob(objUpdateJob);
		}
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Main method for processing GF Tickets
	 * @Parm:            list_Tickets: GF Tickets to process,
	 * @Return:          N/A
	 */
	private void processInformation(List<GF_Ticket__c> list_Tickets) {
		createCollections(list_Tickets);
		map_QueueByDeveloperName = GlobalQueryHelper.getAllQueuesByDevNameMap();

		//create contacts if they don't exist. DML.
		createContacts(list_Tickets);

		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		for (GF_Ticket__c objTicket : list_Tickets) {
			if (objTicket.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			GFTicketAdditionalInfoJSON objParsedJson = new GFTicketAdditionalInfoJSON();
			if (String.isNotBlank(objTicket.Additional_Data__c)) {
				String strAddData = objTicket.Additional_Data__c.replace('"public"', '"isPublic"').replaceall('=>nil', ': null').replaceall('=>', ': ');
				objParsedJson = GFTicketAdditionalInfoJSON.parse(strAddData);
			}

			Case objCase = objTicket.Case_Id__c != null ? new Case(Id = objTicket.Case_Id__c) : new Case();

			if (map_Cases.containsKey(objTicket.Id__c)) {
				objCase = map_Cases.get(objTicket.Id__c);
			}

			setCaseInfo(objCase, objParsedJson, objTicket);

			if (objTicket.Ticket_Type__c == GFTicketUtil.EOY_SPOT_CHECK_TICKET_TYPE) {
				objCase = getEOYSpotCheckInfo(objTicket, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			} else if (objTicket.Ticket_Type__c == GFTicketUtil.SUPPORT_FORM_TICKET_TYPE) {
				objCase = getSupportFormInfo(objTicket, map_AgenciesInformationData, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			} else if (objTicket.Ticket_Type__c == GFTicketUtil.DOCUMENT_MAPPING_TICKET_TYPE) {
				objCase = getDocumentMappingInfo(objTicket, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			} else if (objTicket.Ticket_Type__c == GFTicketUtil.ACH_UPDATE_FAILED_TICKET_TYPE) {
				objCase = getDangerZoneCaseInfo(objTicket, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			} else if (objTicket.Ticket_Type__c == GFTicketUtil.DEFER_PAYMENTS_TICKET_TYPE) {
				objCase = getDeferRepaymentCaseInfo(objTicket, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			} else if (objTicket.Ticket_Type__c == GFTicketUtil.ADDRESS_CHANGE_TICKET_TYPE) {
				objCase = getAddressChangeCaseInfo(objTicket, objParsedJson, objCase, dmo);
				list_UpsertCase.add(objCase);
			}

			processDIVR(objCase, objTicket);
		}

		// ********** Start : DML ************
		if (list_UpsertCase.size() > 0) {
			// Cases
			List<Database.UpsertResult> list_SaveResult;
			if (blnIsFirstEOYSpotCase) {
				list_SaveResult = Database.upsert(list_UpsertCase, false);
			} else {
				list_SaveResult = Database.upsert(list_UpsertCase, Case.Fields.Integration_Id__c, false);
			}

			map_DMLUpsertErrors = Utils.processUpsertResult(list_SaveResult, list_UpsertCase, 'Integration_Id__c', true, 'GFTicketTriggerHelper-processInformation');

			if (!blnIsFirstEOYSpotCase) {
				List<EmailMessage> list_Msg = new List<EmailMessage>();
				List<FeedItem> list_Item = new List<FeedItem>();

				for (Case objCase : list_UpsertCase) {
					if (objCase.Id != null) {
						EmailMessage objMsg = new EmailMessage();
						if (!map_ExistingMsg.containsKey(objCase.Integration_Id__c)) {
							objMsg.ParentId = objCase.Id;
							objMsg.Incoming = true;
							objMsg.FromAddress = objCase.SuppliedEmail;
							objMsg.FromName = objCase.SuppliedName;
							objMsg.Subject = objCase.Subject;

							if (String.isNotBlank(objCase.html_Description__c)) {
								objMsg.HtmlBody = objCase.html_description__c;
							} else {
								objMsg.TextBody = objCase.Description;
							}
							objMsg.Ticket_Id__c = objCase.Integration_Id__c;
							list_Msg.add(objMsg);
						}

						if (objCase.Type == GFTicketUtil.EOY_SPOT_CHECK_CASE_TYPE) {
							FeedItem objItem = new FeedItem();
							objItem.ParentId = objCase.Id;
							objItem.Body = objCase.Description;
							list_Item.add(objItem);
						}
						map_ProcessedCases.put(objCase.Integration_Id__c, objCase);
					}
				}

				// Chatter Feed Items
				if (list_Item.size() > 0) {
					insert list_Item;
				}

				// Email Messages
				if (list_Msg.size() > 0) {
					List<Database.UpsertResult> list_SaveMsgResult = database.upsert(list_Msg, EmailMessage.Fields.Ticket_Id__c, false);
					map_DMLMsgUpsertErrors = Utils.processUpsertResult(list_SaveMsgResult, list_Msg, 'Ticket_Id__c', true, 'GFTicketTriggerHelper-processInformation');
					for (EmailMessage objMsg : list_Msg) {
						if (objMsg.Id != null) {
							map_ProcessedEmails.put(objMsg.Ticket_Id__c, objMsg);
						}
					}
				}

				// GF Ticket
				for (GF_Ticket__c objTicket : list_Tickets) {
					String strExternalKey = objTicket.Id__c;
					if (map_ProcessedCases.containsKey(strExternalKey)) {
						objTicket.Case_Id__c = map_ProcessedCases.get(strExternalKey).Id;
					}
					if (map_ProcessedEmails.containsKey(strExternalKey)) {
						objTicket.Email_Message_Id__c = map_ProcessedEmails.get(strExternalKey).Id;
					}
					if (map_DMLUpsertErrors.containsKey(strExternalKey)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLUpsertErrors.get(strExternalKey), objTicket);
					} else if (map_DMLMsgUpsertErrors.containsKey(strExternalKey)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLMsgUpsertErrors.get(strExternalKey), objTicket);
					} else {
						setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', objTicket);
					}
				}
			}
		}
		// ********** Stop : DML ************
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     If GF Ticket's type is defer_payments, set fields on Case being created.
    * @Parm:            objTicket: GF Ticket to process, 
                        GFTicketAdditionalInfoJSON: GF Ticket's Additional_Data__c cleaned
                        objCase: Case being created from objTicket
                        dmo: DML Option
    * @Return:          N/A
    */
	private Case getDeferRepaymentCaseInfo(GF_Ticket__c objTicket, GFTicketAdditionalInfoJSON objJson, Case objCase, Database.DMLOptions dmo) {
		if (objCase.Id == null) {
			objCase.RecordTypeId = GFTicketUtil.ENGAGEMENT_RT_ID;
			objCase.Type = GFTIcketUtil.PAYROLL_CASE_TYPE;
			objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;
			if (map_QueueByDeveloperName.containsKey(GFTicketUtil.DEFAULT_ROUTING_QUEUE)) {
				objCase.OwnerId = map_QueueByDeveloperName.get(GFTicketUtil.DEFAULT_ROUTING_QUEUE).Id;
			}
		}

		objCase.SuppliedEmail = objTicket.Requester_Email__c;
		objCase.SuppliedName = objTicket.Requester_User_Name__c;

		if (map_UserIdToContact.containsKey(objTicket.Requester_User_Id__c)) {
			objCase.ContactId = map_UserIdToContact.get(objTicket.Requester_User_Id__c).Id;
		} else if (map_EmailToContact.containsKey(objTicket.Requester_Email__c)) {
			objCase.ContactId = map_EmailToContact.get(objTicket.Requester_Email__c).Id;
		}

		if (map_Classification.size() > 0 && String.isNotBlank(objTicket.Reason__c)) {
			objCase.Confirm_Case_Reason_Classification__c = map_Classification.get(objTicket.Reason__c).Id;
			objCase.Confirm_Case_Reason__c = map_Classification.get(objTicket.Reason__c).Name;
			objCase.Routing_Case_Reason_Classification__c = map_Classification.get(objTicket.Reason__c).Id;
			objCase.Routing_Case_Reason__c = map_Classification.get(objTicket.Reason__c).Name;
		}

		return objCase;
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     If GF Ticket's type is ach_update_failed, set fields on Case being created.
    * @Parm:            objTicket: GF Ticket to process, 
                        GFTicketAdditionalInfoJSON: GF Ticket's Additional_Data__c cleaned
                        objCase: Case being created from objTicket
                        dmo: DML Option
    * @Return:          N/A
    */
	private Case getDangerZoneCaseInfo(GF_Ticket__c objTicket, GFTicketAdditionalInfoJSON objJson, Case objCase, Database.DMLOptions dmo) {
		objCase.Description = objTicket.Body__c?.replace('{"public"=>false, "body"=>"', '')?.replace('}', '')?.unescapeXml();
		objCase.html_description__c = objTicket.Body__c;

		if (objCase.Id == null) {
			objCase.RecordTypeId = GFTicketUtil.ENGAGEMENT_RT_ID;
			objCase.Type = GFTicketUtil.PAYROLL_CASE_TYPE;
			objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;
			if (map_QueueByDeveloperName.containsKey(GFTicketUtil.DEFAULT_ROUTING_QUEUE)) {
				objCase.OwnerId = map_QueueByDeveloperName.get(GFTicketUtil.DEFAULT_ROUTING_QUEUE).Id;
			}
		}

		objCase.Routing_Case_Reason__c = GFTicketUtil.ACH_FAILURE_REASON;
		objCase.Confirm_Case_Reason__c = GFTicketUtil.ACH_FAILURE_REASON;

		return objCase;
	}

	/* 
    * @Author:          Sanjay Paryani
    * @Description:     If GF Ticket's type is emp_address_change, set fields on Case being created.
    * @Parm:            objTicket: GF Ticket to process, 
                        GFTicketAdditionalInfoJSON: GF Ticket's Additional_Data__c cleaned
                        objCase: Case being created from objTicket
                        dmo: DML Option
    * @Return:          N/A
    */
	private Case getAddressChangeCaseInfo(GF_Ticket__c objTicket, GFTicketAdditionalInfoJSON objJson, Case objCase, Database.DMLOptions dmo) {
		if (objCase.Id == null) {
			objCase.RecordTypeId = GFTicketUtil.ENGAGEMENT_RT_ID;
			objCase.Type = GFTicketUtil.TYPE_TAXES;
			objCase.Support_Level__c = GFTicketUtil.SUPPORTLEVEL_TIER2;
			objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;
			if (map_QueueByDeveloperName.containsKey(GFTicketUtil.DEFAULT_ROUTING_QUEUE)) {
				objCase.OwnerId = map_QueueByDeveloperName.get(GFTicketUtil.DEFAULT_ROUTING_QUEUE).Id;
			}
		}

		objCase.html_description__c = objTicket.Body__c;
		objCase.SuppliedEmail = objTicket.Requester_Email__c;
		objCase.SuppliedName = objTicket.Requester_User_Name__c;

		if (map_UserIdToContact.containsKey(objTicket.Requester_User_Id__c)) {
			objCase.ContactId = map_UserIdToContact.get(objTicket.Requester_User_Id__c).Id;
		} else if (map_EmailToContact.containsKey(objTicket.Requester_Email__c)) {
			objCase.ContactId = map_EmailToContact.get(objTicket.Requester_Email__c).Id;
		}

		if (
			!map_Classification.isEmpty() && 
			String.isNotBlank(objTicket.Reason__c) && 
			map_Classification.containsKey(objTicket.Reason__c)
		) {
			Case_Reason_Classification__c objCaseReason = map_Classification.get(objTicket.Reason__c);
			objCase.Confirm_Case_Reason_Classification__c = objCaseReason.Id;
			objCase.Confirm_Case_Reason__c = objCaseReason.Name;
			objCase.Routing_Case_Reason_Classification__c = objCaseReason.Id;
			objCase.Routing_Case_Reason__c = objCaseReason.Name;
			if (String.isNotBlank(objCaseReason.Case_Type_Pillar__c)) {
				objCase.Type = objCaseReason.Case_Type_Pillar__c;
			}

			if (String.isNotBlank(objCaseReason.Support_Level__c)) {
				objCase.Support_Level__c = objCaseReason.Support_Level__c;
			}
		}

		return objCase;
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     If GF Ticket's type is eoy_spot_check, set fields on Case being created.
    * @Parm:            objTicket: GF Ticket to process, 
                        GFTicketAdditionalInfoJSON: GF Ticket's Additional_Data__c cleaned
                        objCase: Case being created from objTicket
                        dmo: DML Option
    * @Return:          N/A
    */
	private Case getEOYSpotCheckInfo(GF_Ticket__c objTicket, GFTicketAdditionalInfoJSON objJson, Case objCase, Database.DMLOptions dmo) {
		objCase.Description = objTicket.Body__c?.replace('{"public"=>false, "body"=>"', '')?.replace('}', '')?.unescapeXml();
		objCase.html_description__c = objJson?.external_comment?.html_body;
		objCase.Integration_Id__c = objTicket.Id__c;

		Id idClassification = caseClassificationReason(GFTicketUtil.EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON);
		if (map_QueueByDeveloperName.containsKey(GFTicketUtil.DEFAULT_ROUTING_QUEUE)) {
			objCase.OwnerId = map_QueueByDeveloperName.get(GFTicketUtil.DEFAULT_ROUTING_QUEUE).Id;
		}
		
		objCase.RecordTypeId = GFTicketUtil.ENGAGEMENT_RT_ID;
		objCase.Type = GFTicketUtil.PAYROLL_CASE_TYPE;
		objCase.Confirm_Case_Reason_Classification__c = idClassification;
		objCase.Routing_Case_Reason_Classification__c = idClassification;
		objCase.Routing_Case_Reason__c = GFTicketUtil.EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON;
		objCase.Confirm_Case_Reason__c = GFTicketUtil.EOY_SPOT_CHECK_SQUAD_ACTION_REQUIRED_REASON;
		objCase.SuppliedName = objTicket.Requester_User_Name__c;
		objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;

		return objCase;
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     If GF Ticket's type is support_form, set fields on Case being created.
    * @Parm:            objTicket: GF Ticket to process, 
                        GFTicketAdditionalInfoJSON: GF Ticket's Additional_Data__c cleaned
                        objCase: Case being created from objTicket
                        dmo: DML Option
    * @Return:          The Case being created
    */
	private Case getSupportFormInfo(
		GF_Ticket__c objTicket,
		Map<String, Agency_Information__c> map_AgenciesInformationDataTemp,
		GFTicketAdditionalInfoJSON objJson,
		Case objCase,
		Database.DMLOptions dmo
	) {
		if (objJson.notice_period != null) {
			objCase.Notice_Period__c = objJson.notice_period;
		}

		if (objJson.is_in_app_notice != null && objJson.is_in_app_notice == 'true') {
			objCase.In_App_Notice__c = true;
		}

		if (String.isNotBlank(objJson.payment_due_date)) {
			objCase.Payment_Due_Date__c = Date.parse(objJson.payment_due_date);
		}

		if (String.isNotBlank(objJson.penalty_amount) && objJson.penalty_amount != '.') {
			String strPenaltyAmt = objJson.penalty_amount.remove(',')?.left(16);
			Decimal decPenaltyAmt = Decimal.valueOf(strPenaltyAmt);
			objCase.Penalty_Amount__c = decPenaltyAmt;
		}

		if (objJson.agency_slug != null && map_AgenciesInformationDataTemp != null && map_AgenciesInformationDataTemp.get(objJson.agency_slug) != null) {
			objCase.Agency_Information__c = map_AgenciesInformationDataTemp.get(objJson.agency_slug).Id;
		}

		if (objJson.notice_type != null) {
			objCase.Notice_Type__c = objJson.notice_type;
		}

		if (String.isNotBlank(objJson.benefit_adjustment_request_id)) {
			objCase.Integration_Key__c = objJson.benefit_adjustment_request_id;
		}

		if (objCase.Id == null) {
			// Default to Engagement RT. Will change based on Reason
			objCase.RecordTypeId = GFTicketUtil.ENGAGEMENT_RT_ID;

			if (map_Classification.containsKey(objTicket.Reason__c)) {
				if (map_Classification.get(objTicket.Reason__c).Default_Type__c == System.Label.Engagement_RecordType_Name) {
					objCase.Support_Level__c = String.isNotBlank(map_Classification.get(objTicket.Reason__c).Support_Level__c)
						? map_Classification.get(objTicket.Reason__c).Support_Level__c
						: GFTicketUtil.SUPPORTLEVEL_TIER1;
					objCase.Type = map_Classification.get(objTicket.Reason__c).Case_Type_Pillar__c;
				} else {
					objCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(map_Classification.get(objTicket.Reason__c).Default_Type__c).getRecordTypeId();
					objCase.Type = map_Classification.get(objTicket.Reason__c).Default_Type__c;
				}
			} else {
				if (String.isNotBlank(objTicket.Product_Area__c)) {
					objCase.Type = objTicket.Product_Area__c;
				} else {
					objCase.Type = GFTicketUtil.TYPE_PAYROLL;
				}
				objCase.Support_Level__c = GFTicketUtil.SUPPORTLEVEL_TIER1;
			}

			objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;	
		}

		objCase.SuppliedEmail = objTicket.Requester_Email__c;
		objCase.SuppliedName = objTicket.Requester_User_Name__c?.left(80);

		if (String.isNotBlank(objTicket.Tags__c) && objTicket.Tags__c.indexOf(GFTicketUtil.IN_APP_SUSPENSION_TAG) > -1) {
			objCase.Routing_Case_Reason__c = GFTicketUtil.SUSPEND_ACCOUNT_REASON;
			objCase.Answer_IQ_Processed__c = 'Yes';
		}

		if (map_UserIdToContact.containsKey(objTicket.Requester_User_Id__c)) {
			objCase.ContactId = map_UserIdToContact.get(objTicket.Requester_User_Id__c).Id;
		} else if (map_EmailToContact.containsKey(objTicket.Requester_Email__c)) {
			objCase.ContactId = map_EmailToContact.get(objTicket.Requester_Email__c).Id;
		}

		if (map_Classification.size() > 0 && String.isNotBlank(objTicket.Reason__c) && map_Classification.containsKey(objTicket.Reason__c)) {
			objCase.Answer_IQ_Processed__c = 'Yes';
			objCase.Confirm_Case_Reason_Classification__c = map_Classification.get(objTicket.Reason__c).Id;
			objCase.Confirm_Case_Reason__c = map_Classification.get(objTicket.Reason__c).Name;
			objCase.Routing_case_reason_Classification__c = map_Classification.get(objTicket.Reason__c).Id;
			objCase.Routing_Case_Reason__c = map_Classification.get(objTicket.Reason__c).Name;
		}

		if (String.isNotBlank(objTicket.Body__c)) {
			objCase.HTML_Description__c = objTicket.Body__c;
		}

		if (objJson.is_wallet_app != null && objJson.is_wallet_app == 'true') {
			objCase.Origin = GFTicketUtil.GUSTO_WALLET_ORIGIN;
			objCase.RecordTypeId = GFTicketUtil.MODERN_BANK_RT_ID;
			objCase.Type = GFTicketUtil.MODERN_BANK_CASE_RECORD_TYPE;
		}

		if (objCase.Id == null) {
			if (objCase.RecordTypeId == GFTicketUtil.ENGAGEMENT_RT_ID) {
				if (map_QueueByDeveloperName.containsKey(GFTicketUtil.DEFAULT_ROUTING_QUEUE)) {
					objCase.OwnerId = map_QueueByDeveloperName.get(GFTicketUtil.DEFAULT_ROUTING_QUEUE).Id;
				}
			} else {
				objCase.setOptions(dmo);
			}
		}	

		return objCase;
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     If GF Ticket's type is document_mapping, set fields on Case being created.
    * @Parm:            objTicket - GF Ticket to process, 
                        GFTicketAdditionalInfoJSON - GF Ticket's Additional_Data__c cleaned
                        objCase - Case being created from objTicket
                        dmo - DML Option
    * @Return:          The Case being created
    */
	private Case getDocumentMappingInfo(GF_Ticket__c objTicket, GFTicketAdditionalInfoJSON objJson, Case objCase, Database.DMLOptions dmo) {
		objCase.Authorized_User__c = 'Yes';

		if (objCase.Id == null) {
			objCase.RecordTypeId = GFTicketUtil.PAYROLL_TRANSFER_CASE_RT_ID;
			objCase.Type = GFTicketUtil.DOCUMENT_MAPPING_CASE_TYPE;
			objCase.Origin = GFTicketUtil.GUSTO_ORIGIN;
			objCase.setOptions(dmo);
		}

		objCase.SuppliedEmail = objTicket.Requester_Email__c;
		objCase.SuppliedName = objTicket.Requester_User_Name__c;

		if (map_UserIdToContact.containsKey(objTicket.Requester_User_Id__c)) {
			objCase.ContactId = map_UserIdToContact.get(objTicket.Requester_User_Id__c).Id;
		} else if (map_EmailToContact.containsKey(objTicket.Requester_Email__c)) {
			objCase.ContactId = map_EmailToContact.get(objTicket.Requester_Email__c).Id;
		}

		objCase.Doc_Request_Status__c = objJson.doc_request_status;

		return objCase;
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Query Cases based on a set of Integration Ids and put them into map_Cases
	 * @Parm:            set_TicketIds - set of GF Ticket integration ids
	 * @Return:          N/A
	 */
	public void getMapCases(Set<String> set_TicketIds) {
		if (set_TicketIds != null && set_TicketIds.size() > 0) {
			for (Case objCase : [SELECT Id, Integration_Id__c, Integration_Key__c, Routing_Case_Reason_Classification__c, Type, RecordTypeId, Origin FROM Case WHERE Integration_Id__c IN :set_TicketIds]) {
				map_Cases.put(objCase.Integration_Id__c, objCase);
			}
		}
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     Query Accounts based on a set of ZP Company and Firm ids
    * @Parm:            set_CompanyIds - set of ZP Company Ids
						set_FirmIds - set of ZP Firm Ids
    * @Return:          N/A
    */
	public void getAccounts(Set<String> set_CompanyIds, Set<String> set_FirmIds) {
		if ((set_CompanyIds != null && set_CompanyIds.size() > 0) || (set_FirmIds != null && set_FirmIds.size() > 0)) {
			for (Account objAcct : [
				SELECT Id, Name, ZP_Company_ID__c, ZP_Firm_ID__c
				FROM Account
				WHERE (ZP_Company_ID__c IN :set_CompanyIds AND ZP_Company_ID__c != NULL) OR (ZP_Firm_ID__c IN :set_FirmIds AND ZP_Firm_ID__c != NULL)
			]) {
				if (set_CompanyIds.contains(objAcct.ZP_Company_ID__c)) {
					map_ZPCompanyIdToAccount.put(objAcct.ZP_Company_ID__c, objAcct);
				} else if (set_FirmIds.contains(objAcct.ZP_Firm_ID__c)) {
					map_ZPFirmIdToAccount.put(objAcct.ZP_Firm_ID__c, objAcct);
				}
			}
		}
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     Query Contacts based on a set of ZP user ids and email addresses
    * @Parm:            set_UserIds - set of ZP User Ids
						set_Emails - set of email addresses
    * @Return:          N/A
    */
	public void getContacts(Set<String> set_UserIds, Set<String> set_Emails) {
		if ((set_UserIds != null && set_UserIds.size() > 0) || (set_Emails != null && set_Emails.size() > 0)) {
			for (Contact objContact : [
				SELECT Id, Name, ZP_user_id__c, Account.ZP_Company_Id__c, Email
				FROM Contact
				WHERE (ZP_User_ID__c IN :set_UserIds AND ZP_User_ID__c != NULL) OR (Email IN :set_Emails AND Email != NULL)
			]) {
				if (set_UserIds.contains(objContact.ZP_User_ID__c)) {
					map_UserIdToContact.put(objContact.ZP_User_ID__c, objContact);
				} else if (set_Emails.contains(objContact.Email)) {
					map_EmailToContact.put(objContact.Email, objContact);
				}
			}
		}
	}

	/* 
    * @Author:          Alex Xiong
    * @Description:     populate ZP_Recovery_Case__c object fields
    * @Parm:            strProcessingState - The processing state after GF Ticket is processed
						strMessage - The message after GF Ticket is processed 
						objTicket - the GF Ticket
    * @Return:          The GF Ticket after being processed
    */
	private GF_Ticket__c setProcessingState(String strProcessingState, String strMessage, GF_Ticket__c objTicket) {
		objTicket.Processing_State__c = strProcessingState;
		objTicket.Message__c = strMessage;
		objTicket.Last_Processed__c = System.now();

		return objTicket;
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     Get Case Reason Classification Id from a name
	 * @Parm:            strReasonName - the Case Reason name to search
	 * @Return:          The Case Reason Classification Id
	 */
	public Id caseClassificationReason(String strReasonName) {
		List<Case_Reason_Classification__c> list_CaseReasons = [SELECT Id FROM Case_Reason_Classification__c WHERE Name = :strReasonName LIMIT 1];

		if (list_CaseReasons.size() > 0) {
			return list_CaseReasons[0].Id;
		} else {
			return null;
		}
	}

	/*
	 * @Author:          Alex Xiong
	 * @Description:     query Case Reason Classifications from set of Reason Codes from GF Tickets
	 * @Parm:            set_ReasonCode: set of Reason Codes
	 * @Return:          N/A
	 */
	private void setCaseReasonClassification(Set<String> set_ReasonCode) {
		for (Case_Reason_Classification__c objReason : [
			SELECT Id, Reason_Code__c, Name, Default_Type__c, Support_Level__c, Case_Type_Pillar__c
			FROM Case_Reason_Classification__c
			WHERE Reason_Code__c IN :set_ReasonCode AND Active__c = true
		]) {
			map_Classification.put(objReason.Reason_Code__c, objReason);
		}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Queries Email Messages based on Ticket_Id__c
	 * @Parm        : set_TicketIds - set of GF Ticket Ids
	 * @Return      : list of Email Messages
	 */
	public static List<EmailMessage> queryEmailMessages(Set<String> set_TicketIds) {
		return [SELECT Id, Ticket_Id__c FROM EmailMessage WHERE Ticket_Id__c IN :set_TicketIds];
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : populate collection variables for the class
	 * @Parm        : list_Tickets - list of GF Tickets
	 * @Return      : N/A
	 */
	public void createCollections(List<GF_Ticket__c> list_Tickets) {
		for (GF_Ticket__c objTicket : list_Tickets) {
			set_TicketIds.add(objTicket.Id__c);

			if (objTicket.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (String.isNotBlank(objTicket.Reason__c)) {
				set_Reasons.add(objTicket.Reason__c);
			}

			if (String.isNotBlank(objTicket.Company_Id__c)) {
				set_ZPCompanyIds.add(objTicket.Company_Id__c);
			}

			if (String.isNotBlank(objTicket.Requester_User_Id__c)) {
				set_ZPUserIds.add(objTicket.Requester_User_Id__c);
			}

			if (String.isNotBlank(objTicket.Requester_Email__c)) {
				set_RequesterEmails.add(objTicket.Requester_Email__c);
			}

			GFTicketAdditionalInfoJSON objParsedJson = new GFTicketAdditionalInfoJSON();
			if (String.isNotBlank(objTicket.Additional_Data__c)) {
				String strAddData = objTicket.Additional_Data__c.replace('"public"', '"isPublic"').replaceall('=>nil', ': null').replaceall('=>', ': ');
				objParsedJson = GFTicketAdditionalInfoJSON.parse(strAddData);

				if (objParsedJson.accounting_firm_id != null) {
					set_AccountingFirmIds.add(objParsedJson.accounting_firm_id);
				}

				if (objParsedJson != null && objParsedJson.agency_slug != null) {
					set_AgencySlug.add(objParsedJson.agency_slug);
				}
			}
		}

		for (EmailMessage objMsg : queryEmailMessages(set_TicketIds)) {
			map_ExistingMsg.put(objMsg.Ticket_Id__c, objMsg);
		}

		getMapCases(set_TicketIds);
		getAccounts(set_ZPCompanyIds, set_AccountingFirmIds);
		getContacts(set_ZPUserIds, set_RequesterEmails);

		if (set_Reasons.size() > 0) {
			setCaseReasonClassification(set_Reasons);
		}

		getAgencyData(set_AgencySlug);
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Go through list of GF Tickets. If Tickets have Requester User Id
	 * 				  and org does not have a Contact with this ZP User Id nor Email provided,
	 * 				  then create the Contact record
	 * @Parm        : list_TicketIds - list of GF Tickets
	 * @Return      : N/A
	 */
	public void createContacts(List<GF_Ticket__c> list_Tickets) {
		Boolean blnContactsCreated = false;

		for (GF_Ticket__c objTicket : list_Tickets) {
			if (objTicket.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (String.isNotBlank(objTicket.Company_Id__c) && objTicket.Company_Id__c != 'undefined') {
				if (!map_ZPCompanyIdToAccount.containsKey(objTicket.Company_Id__c) || map_ZPCompanyIdToAccount.get(objTicket.Company_Id__c) == null) {
					setProcessingState(IntegrationUtils.ERROR_STATE, 'Company record does not exist.', objTicket);
					continue;
				}
			}

			if (
				String.isNotBlank(objTicket.Requester_User_Id__c) &&
				!map_UserIdToContact.containsKey(objTicket.Requester_User_Id__c) &&
				!map_EmailToContact.containsKey(objTicket.Requester_Email__c) &&
				map_ZPCompanyIdToAccount.containsKey(objTicket.Company_Id__c)
			) {
				Contact objContact = new Contact();
				objContact.AccountId = map_ZPCompanyIdToAccount.get(objTicket.Company_Id__c)?.Id;
				List<String> list_Requesters = objTicket.Requester_User_Name__c?.split(' ');

				//In case Last Name is null
				objContact.LastName = '-';

				if (list_Requesters?.size() > 0) {
					objContact.FirstName = list_Requesters[0];
				}

				if (list_Requesters?.size() > 1) {
					objContact.LastName = list_Requesters[1];
				}

				objContact.Email = objTicket.Requester_Email__c;
				objContact.ZP_User_Id__c = objTicket.Requester_User_Id__c;
				list_CreateContacts.add(objContact);
			}
		}

		if (list_CreateContacts.size() > 0) {
			try {
				blnContactsCreated = true;

				insert list_CreateContacts;
			} catch (Exception ex) {
				ExceptionLogUtil.logException('GFTicketTriggerHelper', 'processInformation - Contact Creation', ex.getMessage(), ex.getStackTraceString());
			}
		}

		//if record(s) were successfully created, add them to map_UserIdToContact and map_EmailToContact
		if (blnContactsCreated == true && !list_CreateContacts.isEmpty()) {
			for (Contact objContact : list_CreateContacts) {
				if (String.isNotBlank(objContact.Email)) {
					map_EmailToContact.put(objContact.Email, objContact);
				} else if (String.isNotBlank(objContact.ZP_User_Id__c)) {
					map_UserIdToContact.put(objContact.ZP_User_Id__c, objContact);
				}
			}
		}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Set fields on Case
	 * @Parm        : objCase - Case being created
	 * 				  objJson - JSON data from GF Ticket
	 * 				  objTicket - The GF Ticket creating the Case
	 * @Return      : N/A
	 */
	public void setCaseInfo(Case objCase, GFTicketAdditionalInfoJSON objJson, GF_Ticket__c objTicket) {
		Account objAcct = new Account();

		if (String.isNotBlank(objTicket.Company_Id__c) && map_ZPCompanyIdToAccount.containsKey(objTicket.Company_Id__c)) {
			objAcct = map_ZPCompanyIdToAccount.get(objTicket.Company_Id__c);
		}

		objCase.AccountId = objAcct.Id;

		if (objJson.accounting_firm_id != null) {
			if (map_ZPFirmIdToAccount.containsKey(objJson.accounting_firm_id)) {
				objCase.AccountId = map_ZPFirmIdToAccount.get(objJson.accounting_firm_id).Id;
				objCase.Related_Company__c = objAcct.Id;
			}

			// update the accounting firm url on case
			objCase.Accounting_Firm_URL__c = 'https://app.gusto.com/panda/accounting_firms/' + objJson.accounting_firm_id;
		}

		// update the company url on case
		if (String.isNotBlank(objTicket.Company_Id__c)) {
			objCase.Company_URL__c = 'https://app.gusto.com/panda/companies/' + objTicket.Company_Id__c;
		}

		objCase.Subject = objTicket.Subject__c?.unescapeXml().left(255);
		objCase.Authorized_User__c = 'Yes';
		objCase.Integration_Id__c = objTicket.Id__c;
		objCase.Direction__c = 'Inbound';
		objCase.Description = objTicket.Body__c?.unescapeXml();
		objCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
		objCase.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
		if (objTicket.Ticket_Type__c != GFTicketUtil.SUPPORT_FORM_TICKET_TYPE) {
			objCase.Answer_IQ_Processed__c = 'Yes';
		}

		if (String.isNotBlank(objTicket.User_Role_Id__c)) {
			objCase.User_Role_Id__c = objTicket.User_Role_Id__c;
		}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : process DIVR fields from GF Ticket and populate Case fields
	 * @Parm        : objCase - Case being created
	 * 				  objTicket - The GF Ticket creating the Case
	 * @Return      : N/A
	 */
	public void processDIVR(Case objCase, GF_Ticket__c objTicket) {
		// [SM] Populating info about Digital IVR from GF Ticket to Case
		// Alex: if we can't find a Digital IVR by external id, search for one by record Id
		if (String.isNotBlank(objTicket.DIVR_Id__c)) {
			if (String.isNotBlank(objTicket.First_Level__c) || String.isNotBlank(objTicket.Second_Level__c) || String.isNotBlank(objTicket.Third_Level__c)) {
				objCase.Description = (String.isBlank(objCase.Description) ? '' : (objCase.Description + '\n\n')) + 'Digital IVR Flow\n';
				objCase.Description += String.isNotBlank(objTicket.First_Level__c) ? ('First Level : ' + objTicket.First_Level__c + '\n') : '';
				objCase.Description += String.isNotBlank(objTicket.Second_Level__c) ? ('Second Level : ' + objTicket.Second_Level__c + '\n') : '';
				objCase.Description += String.isNotBlank(objTicket.Third_Level__c) ? ('Third Level : ' + objTicket.Third_Level__c + '\n') : '';

				//Alex: populate level fields
				objCase.First_Level__c = String.isNotBlank(objTicket.First_Level__c) ? objTicket.First_Level__c : '';
				objCase.Second_Level__c = String.isNotBlank(objTicket.Second_Level__c) ? objTicket.Second_Level__c : '';
				objCase.Third_Level__c = String.isNotBlank(objTicket.Third_Level__c) ? objTicket.Third_Level__c : '';
			}
		}

		if (String.isNotBlank(objTicket.DIVR_Id__c)) {
			objCase.DIVR_Id__c = objTicket.DIVR_Id__c;
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : querying Agency Information object, updates map_AgenciesInformationData
	 * @Parm        : set_AgencySlugTemp - set of Agency keys/slugs
	 * @Return      : N/A
	 */
	private void getAgencyData(Set<String> set_AgencySlugTemp) {
		if (set_AgencySlugTemp != null && set_AgencySlugTemp.size() > 0) {
			for (Agency_Information__c objAgency : [SELECT Id, Agency_Slug__c FROM Agency_Information__c WHERE Agency_Slug__c != NULL AND Agency_Slug__c IN :set_AgencySlugTemp]) {
				map_AgenciesInformationData.put(objAgency.Agency_Slug__c, objAgency);
			}
		}
	}
}