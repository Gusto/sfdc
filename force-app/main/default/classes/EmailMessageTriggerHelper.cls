/**
 * @description Handler for EmailMessageTrigger
 * @author      Aurobind Ravichandran
 * @date        30th March 2017
 * @see         EmailMessageTriggerHelperTest
 */
public without sharing class EmailMessageTriggerHelper {
	public static Boolean skipTrigger = false;
	private Boolean blnOutgoing = false;
	public static Boolean blnSkipPartnerPublishing = false;
	public static Integer intCounter = 0;
	public static Integer intClosingDays = 0;
	public static Boolean blnCreatedFromOtherCase = false;
	BusinessHours objBusinessHour = new BusinessHours();

	//Bypass as needed case status updates for Risk Assurance Record Type
	public static Boolean blnSkipStatusUpdateForRiskRecType = false;

	public static Set<Id> set_ClosedCaseNewRecordTypes = new Set<Id>();
	public static Set<Id> set_FulFillmentRecordTypes = new Set<Id>();
	public static Set<Id> set_CustomerResponseRecordTypeIds = new Set<Id>();
	public static Set<Id> set_LatestCustomerResponseRecordTypeIds = new Set<Id>();
	public static Set<String> set_InsertedEmailAddresses = new Set<String>();
	public Set<Id> set_populateCaseTypeIds = new Set<Id>();
	public static Set<Id> set_RFICaseRecordIds = new Set<Id>{ CaseUtils.RECTYPE_MF_QLE, CaseUtils.RECTYPE_RENEWAL };
	Set<Id> set_OutOfOfficeUserIds = new Set<Id>();
	Set<Id> set_RecordTypeIds = new Set<Id>();
	public static final String PAYROLL_TRANSFER_CASE_REC_TYPE = 'Payroll Transfer Case';
	public static final String CLOSED_REASON_MERGED = 'Merged Duplicate';

	// List of Case Audit Logs
	public List<Case_Audit_Log__c> list_CaseAuditLogs = new List<Case_Audit_Log__c>();
	// List of consolidated EmailMessages to be inserted
	public List<EmailMessage> list_EmailMessagesToInsert = new List<EmailMessage>();
	// List of GF_Ticket__c to be updated.
	public List<GF_Ticket__c> list_GFTicketsToUpdate = new List<GF_Ticket__c>();
	public List<Case> list_CasesToInsert = new List<Case>();
	Map<String, Id> map_ThreadIdentifiers = new Map<String, Id>();
	public List<Case> list_TaxResCases = new List<Case>();
	public Set<String> set_TaxResOpenCaseReminders = new Set<String>{
		EmailMessageUtil.TAXRES_OPENCASE_FIRST_REMINDER,
		EmailMessageUtil.TAXRES_OPENCASE_SECOND_REMINDER,
		EmailMessageUtil.TAXRES_OPENCASE_FINAL_REMINDER
	};
	private static Map<String, String> map_RecordTypeIdByName = new Map<String, String>();
	private static Map<String, String> map_RecordTypeNameById = new Map<String, String>();
	private Map<String, String> map_FulfilmentBlockCases = new Map<String, String>();
	public Map<Id, Case> map_CasesById = new Map<Id, Case>();
	public Map<String, Group> map_QueuesByName = new Map<String, Group>();
	public Map<Id, User> map_UsersById = new Map<Id, User>();
	public Map<String, Case_Reason_Classification__c> map_CaseReasonByName = new Map<String, Case_Reason_Classification__c>();
	// Map of Email Thread Id from Platform in Email To Email Message
	public Map<String, EmailMessage> map_ThreadIdToEmail = new Map<String, EmailMessage>();
	// Map of Email Thread Id from GF Ticket To GF Ticket
	public Map<String, GF_Ticket__c> map_ThreadIdToGFTicket = new Map<String, GF_Ticket__c>();
	// Map of To & CC Email Ids By Email Message
	public Map<Id, String> map_CCEmailIdsByEmailMessage = new Map<Id, String>();
	public Map<String, List<String>> map_CaseIdToEmailAddresses = new Map<String, List<String>>();
	public Map<String, Set<Id>> map_CaseIdsByToAddress = new Map<String, Set<Id>>();
	public Map<Id, EmailMessage> map_EmailMessageByCaseId = new Map<Id, EmailMessage>();
	public Map<Id, EmailMessage> map_NewEmailMessageByCaseId = new Map<Id, EmailMessage>();
	// Map of consolidated Cases to be udpated
	public Map<Id, Case> map_CasesToUpdate = new Map<Id, Case>();
	public Map<Id, Id> map_ClosedCaseWithOpenParent = new Map<Id, Id>();
	public Map<Id, Case> map_ExistingOpenCareCase = new Map<Id, Case>();
	public Map<String, EmailMessage> map_OldCaseEmail = new Map<String, EmailMessage>();
	public Map<String, Case_Audit_Log__c> map_CaseIdAuditLogRecord = new Map<String, Case_Audit_Log__c>();
	//Gusto - Denver BusinessHours
	public static final String BUSINESSHOURS_GUSTO_DENVER = 'Gusto - Denver';
	public static final BusinessHours objGustoDenverBusinessHour = GlobalQueryHelper.getBusinessHoursByName(BUSINESSHOURS_GUSTO_DENVER);

	public List<Case> list_BYBBenefitOrderFulfilledCases = new List<Case>();
	public Map<Id, EmailMessage> map_oldCaseIdToEmailMessageMap = new Map<Id, EmailMessage>();
	private List<Ticket__c> list_TicketsToUpdate = new List<Ticket__c>();
	private List<Task> list_TaskToInsert = new List<Task>();

	public Set<Id> set_AwaitingCustomerResponseRecTypes = new Set<Id>{
		EmailMessageUtil.RECTYPE_CHANGE,
		EmailMessageUtil.RECTYPE_RENEWAL,
		EmailMessageUtil.RECTYPE_NEW_PLAN,
		EmailMessageUtil.RECTYPE_BENEFITS_CARE,
		EmailMessageUtil.RECTYPE_PAYROLL_CARE,
		EmailMessageUtil.RECTYPE_PAYROLL_COMPLIANCE,
		EmailMessageUtil.RECTYPE_BENEFITS_COMPLIANCE,
		EmailMessageUtil.RECTYPE_TAX_OPS,
		EmailMessageUtil.RECTYPE_RISK_ASSURANCE,
		EmailMessageUtil.RECTYPE_SALES_CASES,
		EmailMessageUtil.RECTYPE_SALES_CASES_CLOSED,
		EmailMessageUtil.RECTYPE_MODERN_BANK,
		EmailMessageUtil.RECTYPE_RECOVERY,
		EmailMessageUtil.RECTYPE_PAYROLLOPS_AUDIT,
		EmailMessageUtil.RECTYPE_BYB,
		EmailMessageUtil.RECTYPE_ENGAGEMENT,
		EmailMessageUtil.RECTYPE_GEP_CX,
		EmailMessageUtil.RECTYPE_R_D_TAX_CREDITS,
		EmailMessageUtil.RECTYPE_CLIENT_RELATIONS
	};

	public static Set<Id> set_FirstResponseRecordTypes = new Set<Id>{
		EmailMessageUtil.RECTYPE_BENEFITS_CARE,
		EmailMessageUtil.RECTYPE_PAYROLL_CARE,
		EmailMessageUtil.RECTYPE_TAXRES,
		EmailMessageUtil.RECTYPE_TAXRES_READ_ONLY,
		EmailMessageUtil.RECTYPE_PAYROLL_COMPLIANCE,
		EmailMessageUtil.RECTYPE_TAX_OPS,
		EmailMessageUtil.RECTYPE_RISK_ASSURANCE,
		EmailMessageUtil.RECTYPE_SALES_CASES,
		EmailMessageUtil.RECTYPE_SALES_CASES_CLOSED,
		EmailMessageUtil.RECTYPE_MODERN_BANK,
		EmailMessageUtil.RECTYPE_RECOVERY,
		EmailMessageUtil.RECTYPE_PAYROLLOPS_AUDIT,
		EmailMessageUtil.RECTYPE_GEP_CX,
		EmailMessageUtil.RECTYPE_BYB,
		EmailMessageUtil.RECTYPE_ENGAGEMENT,
		EmailMessageUtil.RECTYPE_R_D_TAX_CREDITS
	};

	/*
	 * @author:         Ankit CS
	 * @description:    Handle operations for BeforeInsert trigger context
	 * @param:          list_EmailMessages - List of new Email Message records
	 */
	public void OnBeforeInsert(List<EmailMessage> list_EmailMessages) {
		intCounter++;

		if (list_EmailMessages.size() == 1) {
			EmailMessage objEmailMessage = list_EmailMessages[0];
			CaseTriggerHelper.context = objEmailMessage.FromAddress;
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Handle operations for AfterInsert trigger context
	 * @param:          map_NewEmailMessages - Map of new Email Message records
	 */
	public void OnAfterInsert(Map<Id, EmailMessage> map_NewEmailMessages) {
		intCounter++;
		map_RecordTypeIdByName = RecordTypes.getRecordTypeNameIdMap('Case');
		map_RecordTypeNameById = Cache.getAllRecordTypeMap('Case');
		map_CasesToUpdate = new Map<Id, Case>();
		list_CaseAuditLogs = new List<Case_Audit_Log__c>();
		list_EmailMessagesToInsert = new List<EmailMessage>();
		list_GFTicketsToUpdate = new List<GF_Ticket__c>();
		list_CasesToInsert = new List<Case>();
		createCollectionsAfterInsert(map_NewEmailMessages.values());
		processEOYSpotCheck();
		processCaseInfo();
		processBenefitOrderFulfilledCheck();
		processUniversalInbox(map_NewEmailMessages.values());
		processDuplicatePTCases();
		processDML();
		if (!list_TaskToInsert.isEmpty()) {
			insert list_TaskToInsert;
		}
	}

	public void OnBeforeUpdate(Map<Id, EmailMessage> map_OldEmailMessages, Map<Id, EmailMessage> map_NewEmailMessages) {
		intCounter++;
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Handle operations for AfterUpdate trigger context
	 * @param:          map_OldEmailMessages - Map of old Email Message records
	 					map_NewEmailMessages - Map of new Email Message records
	*/
	public void OnAfterUpdate(Map<Id, EmailMessage> map_OldEmailMessages, Map<Id, EmailMessage> map_NewEmailMessages) {
		intCounter++;
		map_CasesToUpdate = new Map<Id, Case>();
		list_CaseAuditLogs = new List<Case_Audit_Log__c>();
		list_EmailMessagesToInsert = new List<EmailMessage>();
		list_GFTicketsToUpdate = new List<GF_Ticket__c>();
		list_CasesToInsert = new List<Case>();
		map_RecordTypeIdByName = RecordTypes.getRecordTypeNameIdMap('Case');
		createCollectionsAfterUpdate(map_OldEmailMessages, map_NewEmailMessages);
		taxResCasesHandleSentEmails();
		processOutgoingDraft(map_OldEmailMessages);
		processDML();
	}

	public void OnBeforeDelete(List<EmailMessage> list_MessagesToDelete, Map<Id, EmailMessage> map_OldEmailMessages) {
		intCounter++;
	}

	public void OnAfterDelete(List<EmailMessage> list_DeletedMessages, Map<Id, EmailMessage> map_OldEmailMessages) {
		intCounter++;
	}

	public void OnUndelete(List<EmailMessage> list_RestoredMessages) {
		intCounter++;
	}

	/*
	 * @author:         Sourav Mitra
	 * @description:    To process incoming emails for EOY Spot Check.
	 */
	private void processEOYSpotCheck() {
		try {
			if (!map_ThreadIdToEmail.isEmpty()) {
				Id idAutoCloseQueue = map_QueuesByName.get(EmailMessageUtil.PAYROLL_CARE_AUTO_CLOSE_QUEUE).Id;

				for (String strThreadId : map_ThreadIdToEmail.keySet()) {
					EmailMessage objEmailMessage = map_ThreadIdToEmail.get(strThreadId);
					if (map_ThreadIdToGFTicket.containsKey(strThreadId)) {
						GF_Ticket__c objGFTicket = map_ThreadIdToGFTicket.get(strThreadId);
						// If a case is already associated with GF Ticket
						if (String.isNotBlank(objGFTicket.Case_Id__c)) {
							Id idCase = Id.valueOf(objGFTicket.Case_Id__c);
							/* If parent case of new email is different from case
							 associated with GF ticket then close new case. */
							if (idCase != objEmailMessage.ParentId) {
								if (map_CasesById.containsKey(objEmailMessage.ParentId)) {
									// Auto Close current case
									Case objCaseToUpdate = map_CasesById.get(objEmailMessage.ParentId);
									objCaseToUpdate.Status = CaseUtils.STATUS_CLOSED;
									objCaseToUpdate.ParentId = Id.valueOf(objGFTicket.Case_Id__c);
									objCaseToUpdate.Type = EmailMessageUtil.CASE_TYPE_SPOT_CHK_CLOSE;
									objCaseToUpdate.OwnerId = idAutoCloseQueue;
									map_CasesToUpdate.put(objCaseToUpdate.Id, objCaseToUpdate);
								}

								// Move Email to Original Case by cloning and creating a new record
								EmailMessage objCloneEmailMessage = objEmailMessage.clone();
								objCloneEmailMessage.Old_Parent_Email_Id__c = objEmailMessage.Id;
								objCloneEmailMessage.ParentId = idCase;
								list_EmailMessagesToInsert.add(objCloneEmailMessage);
							}
						} else {
							/* if no case associated then update GF ticket with current case and email and
							 update case with GF ticket values */
							objGFTicket.Case_Id__c = objEmailMessage.ParentId;
							objGFTicket.Email_Message_Id__c = objEmailMessage.Id;
							objGFTicket.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
							objGFTicket.Message__c = EmailMessageUtil.INFO_PROCESSED;
							objGFTicket.Last_Processed__c = System.now();
							list_GFTicketsToUpdate.add(objGFTicket);
						}
					} else {
						if (map_CasesById.containsKey(objEmailMessage.ParentId)) {
							// If no GF Ticket found with the Thread Id
							Case objCaseToUpdate = map_CasesById.get(objEmailMessage.ParentId);
							objCaseToUpdate.Type = EmailMessageUtil.CASE_TYPE_EOY_SPOT_CHK;
							map_CasesToUpdate.put(objCaseToUpdate.Id, objCaseToUpdate);
						}
					}
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('EmailMessageTriggerHelper', 'processEOYSpotCheck', objException.getMessage(), objException.getStackTraceString());
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Called from "After Update", update case's "Email Status" field, and
	 * 				  creates "Case Audit Log" object records.
	 * @Parm        : N/A
	 * @Return      : void
	 **/
	private void taxResCasesHandleSentEmails() {
		try {
			if (!map_CasesById.isEmpty()) {
				for (Case objCase : map_CasesById.values()) {
					if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
						objCase.Email_Status__c = CaseUtils.EMAILSTATUS_AWAITING_RESPONSE;
						if (map_NewEmailMessageByCaseId?.containsKey(objCase.Id)) {
							EmailMessage objEmailMessage = map_NewEmailMessageByCaseId?.get(objCase.Id);
							if (
								objGustoDenverBusinessHour != null &&
								objEmailMessage != null &&
								(objEmailMessage.Incoming == false && (objEmailMessage.Status == '3' || objEmailMessage.Status == '2')) &&
								(String.isBlank(objEmailMessage.Email_Template_Name__c) ||
								(String.isNotBlank(objEmailMessage.Email_Template_Name__c) && !set_TaxResOpenCaseReminders.contains(objEmailMessage.Email_Template_Name__c)))
							) {
								// 2 business days after Last_out_bound_email__c
								objCase.X2_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 16 * 60 * 60 * 1000);
								// 4 business days after Last_out_bound_email__c
								objCase.X5_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 32 * 60 * 60 * 1000);
								// 6 business days after Last_out_bound_email__c
								objCase.XN_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 48 * 60 * 60 * 1000);
							}
						}
					}

					objCase.Last_out_bound_email__c = System.now();
					map_CasesToUpdate.put(objCase.Id, objCase);
				}
			}

			if (!list_TaxResCases.isEmpty()) {
				createTaxResAuditLogs(list_TaxResCases);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('EmailMessageTriggerHelper ', 'taxResCasesHandleSentEmails', objException.getMessage(), 'High');
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Create an instance of new Case_Audit_Log__c for EmailMessage
	 * @param:          objEmailMessage - New Email Message record
	 * @return:			Instance of Case_Audit_Log__c
	 */
	private Case_Audit_Log__c getNewCaseAuditLog(EmailMessage objEmailMessage) {
		Case_Audit_Log__c objCaseAuditLog;
		if (objEmailMessage.Status != '5') {
			objCaseAuditLog = new Case_Audit_Log__c();
			objCaseAuditLog.Case__c = objEmailMessage.ParentId;
			objCaseAuditLog.Event_Type__c = 'Email';
			if (objEmailMessage.Incoming) {
				objCaseAuditLog.Direction__c = EmailMessageUtil.CASE_DIRECTION_INBOUND;
			} else {
				objCaseAuditLog.Direction__c = EmailMessageUtil.CASE_DIRECTION_OUTBOUND;
			}

			objCaseAuditLog.Advocate__c = UserInfo.getUserId();
			objCaseAuditLog.From_Status__c = 'New Message';
			objCaseAuditLog.Email_Message_Id__c = objEmailMessage.Id;
		}

		return objCaseAuditLog;
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Process updates on Case
	 */
	private void processCaseInfo() {
		Map<Id, EmailMessage> map_PublishToZendesk = new Map<Id, EmailMessage>();
		Map<String, String> map_EmailAddressToCaseRecordType = new Map<String, String>();
		Group objPayrollOpsAuditQueue = new Group();
		Map<String, Pattern_Matching__mdt> map_PatternMatchingByName = EmailMessageUtil.getPatternMatchingByRecordtype(CaseUtils.TYPE_ENGAGEMENT);

		if (map_QueuesByName.containsKey(EmailMessageUtil.PAYROLL_OPS_AUDIT_QUEUE)) {
			objPayrollOpsAuditQueue = map_QueuesByName.get(EmailMessageUtil.PAYROLL_OPS_AUDIT_QUEUE);
		}

		User objCurrentUser = map_UsersById.get(UserInfo.getUserId());
		Date dtCurrentDate = Date.today();

		getRecordTypesToCloneCase();
		setFulfillmentRecordTypeSet();
		setFulfillmentBlockCases();
		getCaseRecordTypeBehaviors();

		Database.DMLOptions objDMLOptions = new Database.DMLOptions();
		objDMLOptions.assignmentRuleHeader.useDefaultRule = true;

		Set<Id> set_ClosedCaseIdUponCreation = CaseTriggerHelper.closedCaseIdSetUponCreation;
		// Get Map of EmailAddress - Case RecordType to Case Type from Email Case Type Metadata Records
		map_EmailAddressToCaseRecordType = EmailMessageHelperFunctions.getEmailCaseTypeMetadata();
		Set<String> set_CaseRecordTypes = new Set<String>{ EmailMessageUtil.CASE_RT_TAX_OPS, EmailMessageUtil.CASE_RT_RISK_ASSURANCE, EmailMessageUtil.CASE_RT_RISK_ASSURANCE_READ_ONLY };

		for (Case objCase : map_CasesById.values()) {
			if (map_EmailMessageByCaseId.containsKey(objCase.Id)) {
				/**
				 * Author: Alex
				 * Date: 9/15/2020
				 * Desc: if case is being responded to after mass email, reopened after mass email = true
				 */
				if (objCase.Mass_Email_Template_Applied__c != null && objCase.Reopened_After_Mass_Email__c == false) {
					objCase.Reopened_After_Mass_Email__c = true;
				}

				EmailMessage objEmailMessage = map_EmailMessageByCaseId.get(objCase.Id);
				if (objCase.Shared_with__c == 'ApIntego') {
					map_PublishToZendesk.put(objEmailMessage.Id, objEmailMessage);
				}

				if (map_CCEmailIdsByEmailMessage.containsKey(objEmailMessage.Id)) {
					objCase.CCEmailAddress__c = map_CCEmailIdsByEmailMessage.get(objEmailMessage.Id);
				}

				objCase.Case_Updated__c = System.now();
				// 2 (Replied), 3 (Sent)
				if (objEmailMessage.Incoming == false && (objEmailMessage.Status == '3' || objEmailMessage.Status == '2')) {
					objCase.Last_out_bound_email__c = System.now();
				}

				// In case of emails sent from in-app it is incoming to SFDC but 'Sent' to customer
				if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
					if (objEmailMessage.Incoming == false && (objEmailMessage.Status == '3' || objEmailMessage.Status == '2')) {
						objCase.Email_Status__c = 'Awaiting response';
						if (
							objGustoDenverBusinessHour != null && String.isBlank(objEmailMessage.Email_Template_Name__c) ||
							(String.isNotBlank(objEmailMessage.Email_Template_Name__c) && !set_TaxResOpenCaseReminders.contains(objEmailMessage.Email_Template_Name__c))
						) {
							// 2 business days after Last_out_bound_email__c
							objCase.X2_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 16 * 60 * 60 * 1000);
							// 4 business days after Last_out_bound_email__c
							objCase.X5_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 32 * 60 * 60 * 1000);
							// 6 business days after Last_out_bound_email__c
							objCase.XN_Business_Days_From_Last_Notification__c = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), 48 * 60 * 60 * 1000);
						}
					} else if (objEmailMessage.Incoming && objEmailMessage.Status != '3') {
						objCase.Email_Status__c = 'Response received';
						if (objCase.Status == CaseUtils.STATUS_SOLVED) {
							objCase.Status = CaseUtils.CASE_STATUS_READY_FOR_RESEARCH;
						}
					}
				}

				if (
					!EmailMessageUtil.ADVISING_EMAIL_TEMPLATE_SET.contains(objEmailMessage.Email_Template_Name__c) &&
					set_AwaitingCustomerResponseRecTypes.contains(objCase.RecordTypeId) &&
					objEmailMessage.Incoming == false &&
					objEmailMessage.Status == '3' &&
					objCase.Status != CaseUtils.STATUS_CLOSED &&
					objCase.Status != CaseUtils.STATUS_SOLVED &&
					!objCurrentUser?.Data_Migration_Validation__c &&
					!objCurrentUser?.Name.contains(EmailMessageUtil.AGATHA_USER) && 
                    !objEmailMessage.TextBody.startsWithIgnoreCase(EmailMessageUtil.CHAT_STARTED)
				) {
					objCase.Status = CaseUtils.STATUS_AWAITING_RESPONSE;
					if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_CLIENT_RELATIONS) {
						objCase.Auto_Close_Date_Time__c = null;
					}
				}

				if (
					(objCase.Origin == CaseUtils.ORIGIN_CHAT || (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT)) &&
					objEmailMessage.Incoming == false &&
					objEmailMessage.Status == '3' &&
					!objEmailMessage.TextBody.startsWithIgnoreCase(EmailMessageUtil.CHAT_STARTED)
				) {
					objCase.Origin = CaseUtils.ORIGIN_EMAIL;
					if (String.isBlank(objCase.Type)) {
						objCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
					}
					if (String.isBlank(objCase.Support_Level__c)) {
						objCase.Support_Level__c = CaseUtils.TIER_1;
					}
				}

				map_CasesToUpdate.put(objCase.Id, objCase);
				if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT) {
					evaluatePartnerRedirects(objEmailMessage);
				}

				// Populate Case Type
				if (objCurrentUser == null || (!objCurrentUser?.Data_Migration_Validation__c)) {
					if (!map_CaseIdToEmailAddresses.isEmpty() && map_CaseIdToEmailAddresses?.containsKey(objCase.Id)) {
						for (String strEmailAddress : map_CaseIdToEmailAddresses?.get(objCase.Id)) {
							String strEmailAddreesAndCaseRecordType = strEmailAddress + '-' + objCase.RecordType?.Name;
							if (!map_EmailAddressToCaseRecordType.isEmpty() && map_EmailAddressToCaseRecordType?.containsKey(strEmailAddreesAndCaseRecordType)) {
								objCase.Type = map_EmailAddressToCaseRecordType?.get(strEmailAddreesAndCaseRecordType);
								map_CasesToUpdate.put(objCase.Id, objCase);
								break;
							}
						}
					}

					// Update Case Type based on ToAddress in EmailMessage
					if (set_populateCaseTypeIds.contains(objCase.Id) && set_CaseRecordTypes.contains(objCase.RecordType.Name)) {
						if (objCase.RecordType.Name == EmailMessageUtil.CASE_RT_TAX_OPS) {
							if (
								map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT) &&
								map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT)?.contains(objCase.Id)
							) {
								objCase.Type = EmailMessageUtil.CASE_TYPE_GARNISHMENTS;
								map_CasesToUpdate.put(objCase.Id, objCase);
							} else if (
								map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT) &&
								map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT)?.contains(objCase.Id)
							) {
								objCase.Type = EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX;
								map_CasesToUpdate.put(objCase.Id, objCase);
							}
						} else if (
							map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT) && objCase.RecordType.Name == EmailMessageUtil.CASE_RT_RISK_ASSURANCE ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_RISK_ASSURANCE_READ_ONLY
						) {
							if (map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT)?.contains(objCase.Id)) {
								objCase.Type = EmailMessageUtil.CASE_TYPE_UNDERWRITING;
								map_CasesToUpdate.put(objCase.Id, objCase);
							}
						}
					}
				}

				Boolean blnIsBlockFulFillmentCase = map_FulfilmentBlockCases.containsKey(map_RecordTypeNameById.get(objCase.RecordTypeId))
					? map_FulfilmentBlockCases.get(map_RecordTypeNameById.get(objCase.RecordTypeId)) == objCase.Subject ? true : false
					: false;
				/**
				 * if case is closed
				 * if email is incoming
				 * if email's case has an open parent, clone email and put it on the open parent. Remove Ticket_Id__c
				 */
				if (
					objCase.Status == CaseUtils.STATUS_CLOSED &&
					objCase.Type != EmailMessageUtil.CASE_TYPE_SPOT_CHK_CLOSE &&
					((objCase.Authorized_User__c == CaseUtils.ANSWER_IQ_PROCESSED_YES &&
					map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE) != objCase.RecordTypeId &&
					map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_BYB) != objCase.RecordTypeId) ||
					set_FulFillmentRecordTypes.contains(objCase.RecordTypeId) ||
					(map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE) == objCase.RecordTypeId &&
					objCase.Type != EmailMessageUtil.CASE_TYPE_DOC_MAPPING) ||
					objCase.Type == EmailMessageUtil.CASE_TYPE_COBRA ||
					(map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY) == objCase.RecordTypeId))
				) {
					if (
						objEmailMessage.Incoming &&
						(set_ClosedCaseNewRecordTypes.contains(objCase.RecordTypeId) ||
						set_FulFillmentRecordTypes.contains(objCase.RecordTypeId) ||
						map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE) == objCase.RecordTypeId)
					) {
						// check if any of the parent is opened then copy emailmessage and assign to open case
						if (map_ClosedCaseWithOpenParent.containsKey(objEmailMessage.ParentId) && set_ClosedCaseIdUponCreation.contains(objEmailMessage.ParentId)) {
							EmailMessage objNewMsg = objEmailMessage.clone();
							objNewMsg.Old_Parent_Email_Id__c = objEmailMessage.Id;
							objNewMsg.ParentId = map_ClosedCaseWithOpenParent.get(objEmailMessage.ParentId);
							objNewMsg.Ticket_Id__c = '';
							list_EmailMessagesToInsert.add(objNewMsg);
						} else if (!blnIsBlockFulFillmentCase && !set_ClosedCaseIdUponCreation.contains(objEmailMessage.ParentId)) {
							//create a new case as parent is closed
							// BY:PR: Date: 2/14/19 Desc: introduced the "set_ClosedCaseIdUponCreation" filter to stop recursion due to CaseTriggerHelper logic
							map_OldCaseEmail.put(objCase.Id, objEmailMessage);
							Case objNewCase = objCase.clone();

							Date dtCloseDate = objCase.ClosedDate.date();
							Integer inNumberDaysDue = dtCloseDate.daysBetween(dtCurrentDate);

							Boolean isParentCaseClosed =
								objCase.Type == CaseUtils.TYPE_CARRIER_SUBMISSION &&
								objCase.Status == CaseUtils.STATUS_CLOSED &&
								objCase.Carrier_Order__c != null &&
								objCase.Carrier_Order__r.Implementation_Stage__c == CarrierOrderUtil.CO_STATUS_APPROVED;
							if (isParentCaseClosed) {
								Task taskRecord = new Task(
									Subject = 'Carrier Response Received on Case Number ' + objCase.CaseNumber,
									Type__c = TaskUtil.TASK_TYPE_CARRIER_COMMUNICATION,
									Priority = TicketUtil.TICKET_PRIORITY_HIGH,
									Description = TaskUtil.PARENT_CARRIER_CASE_CLOSED_TASK_DESCRIPTION,
									Status = TaskUtil.TASK_STATUS_OPEN,
									ActivityDate = System.today(),
									RecordTypeId = TaskUtil.TASK_BENEFIT_FULFILLMENT_RT_ID,
									WhatId = objCase.Carrier_Order__c,
									OwnerId = objCase.Carrier_Order__r.OwnerId
								);
								list_TaskToInsert.add(taskRecord);
								continue;
							}

							/* Description: Added Below Logic to Create case with Status as Open for Engagement Record Types/Payroll Care Read-Only/Benefits Care Read-Only */
							if (
								objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT ||
								objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE_READ_ONLY ||
								objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE_READ_ONLY ||
								objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE ||
								objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE
							) {
								objNewCase.Status = CaseUtils.STATUS_IN_PROGRESS;
								if (map_PatternMatchingByName.containsKey(EmailMessageUtil.THANK_YOU)) {
									Pattern_Matching__mdt objPatternMatching = map_PatternMatchingByName.get(EmailMessageUtil.THANK_YOU);
									Boolean blnMatchFound = false;
									String strDomain = String.isNotBlank(objEmailMessage.FromAddress) ? objEmailMessage.FromAddress.split('@')[1] : '';
									if (
										(String.isNotBlank(objPatternMatching.Email_Domains__c) && objPatternMatching.Email_Domains__c.split(';').contains(strDomain)) ||
										String.isBlank(objPatternMatching.Email_Domains__c)
									) {
										blnMatchFound = EmailMessageHelperFunctions.checkEmailPatternMatch(objEmailMessage, objPatternMatching);
									}

									if (blnMatchFound) {
										objNewCase.Status = CaseUtils.STATUS_CLOSED;
									}
								}

								objNewCase.Type = String.isBlank(objNewCase.Type) 
									? CaseUtils.PAYROLL_CASE_PILLAR
									: objNewCase.Type;
								objNewCase.Support_Level__c = String.isBlank(objNewCase.Support_Level__c)
									? CaseUtils.TIER_1
									: objNewCase.Support_Level__c;
								objNewCase.Answer_IQ_Eligible__c = false;
								objNewCase.Answer_IQ_Processed__c = CaseUtils.ANSWER_IQ_PROCESSED_YES;
								objNewCase.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
								objNewCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
								objNewCase.ClosedDate = null;
								if (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_EMAIL) {
									objNewCase.Origin = CaseUtils.ORIGIN_EMAIL;
								}

								if (inNumberDaysDue > 14) {
									objNewCase = new Case();
									// Updated Subject and Description from new email message instead of old case for BTE-4188
									objNewCase.Subject =  map_EmailMessageByCaseId.containsKey(objCase.Id)
															? map_EmailMessageByCaseId.get(objCase.Id).Subject
															: objCase.Subject;
									objNewCase.Description = map_EmailMessageByCaseId.containsKey(objCase.Id)
																? map_EmailMessageByCaseId.get(objCase.Id).TextBody
																: objCase.Description;
									objNewCase.Status = CaseUtils.STATUS_OPEN;
									objNewCase.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
									objNewCase.Requires_Action__c = true;
									objNewCase.AccountId = objCase.AccountId;
									objNewCase.ContactId = objCase.ContactId;
									objNewCase.Answer_IQ_Eligible__c = true;
									objNewCase.setOptions(objDMLOptions); // Added for BTE-3251
								}
								objNewCase.Specialization__c = objCase.Specialization__c;
								objNewCase.RecordTypeId = EmailMessageUtil.RECTYPE_ENGAGEMENT;
							} else {
								objNewCase.Status = EmailMessageUtil.CASE_STATUS_NEW;
							}
							objNewCase.Direction__c = EmailMessageUtil.CASE_DIRECTION_INBOUND;
							objNewCase.First_Response_Time__c = null;
							// Blanking out Tax Res related fields
							objNewCase.Account_Specialist__c = null;
							objNewCase.Account_Specialist_Escalation_Notes__c = null;
							objNewCase.Account_Specialist_Out_Of_Office_Notes__c = null;
							if (set_ClosedCaseNewRecordTypes.contains(objCase.RecordTypeId)) {
								objNewCase.Related_Case__c = objCase.Id;
								mapCaseRecordType(objNewCase);

								if (
									(CaseUtils.RECTYPE_RENEWAL == objCase.RecordTypeId && objCase.Type == CaseUtils.TYPE_BENEFITS_RENEWAL_ALLIGNMENT) ||
									(set_RecordTypeIds.contains(objCase.RecordTypeId) &&
									objCase.Benefit_Order__c == null &&
									objCase.Opportunity__c == null)
								) {
									objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
									map_CasesToUpdate.put(objCase.Id, objCase);
									continue;
								}

								if (map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE) == objCase.RecordTypeId) {
									if (map_ExistingOpenCareCase.containsKey(objCase.Id)) {
										EmailMessage objNewEmailMessage = attachEmailToExistingCase(map_ExistingOpenCareCase.get(objCase.Id), objEmailMessage);
										list_EmailMessagesToInsert.add(objNewEmailMessage);
										continue;
									}

									objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_ENGAGEMENT);
									objNewCase.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
									objNewCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
									objNewCase.Support_Level__c = CaseUtils.TIER_1;
									objNewCase.ParentId = objCase.Id;
									objNewCase.Related_Case__c = null;
								}

								if (
									map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY) == objCase.RecordTypeId ||
									objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLLOPS_AUDIT
								) {
									objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLLOPS_AUDIT);
									objNewCase.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
									objNewCase.Type = EmailMessageUtil.CASE_TYPE_ONBOARDING_STATE_TAX_AUDIT;
									objNewCase.OwnerId = objPayrollOpsAuditQueue?.Id;
								}

								if (set_RecordTypeIds.contains(objCase.RecordTypeId)) {
									if (map_ExistingOpenCareCase.containsKey(objCase.Id)) {
										EmailMessage objNewEmailMessage = attachEmailToExistingCase(map_ExistingOpenCareCase.get(objCase.Id), objEmailMessage);
										list_EmailMessagesToInsert.add(objNewEmailMessage);
										continue;
									}

									//If Parent case has Carrier Order do not create a new Engagement case
									if (objCase.Carrier_Order__c != null) {
										continue;
									}

									objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_ENGAGEMENT);
									objNewCase.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
									objNewCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;
									objNewCase.ParentId = objCase.Id;
									objNewCase.Integration_Id__c = null;
									objNewCase.Routed_through_Onboarding__c = true;
									objNewCase.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
									objNewCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
									objNewCase.Related_Case__c = null;
									objNewCase.Origin = CaseUtils.ORIGIN_EMAIL;
								}
							} else {
								// Request from Ash to create a new case for Fulfilment. Reparing of email will take place in above block

								// objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_ENGAGEMENT); // Commented for BTE-3251
								objNewCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;
								objNewCase.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
								objNewCase.Routed_through_Onboarding__c = true;
								objNewCase.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
								objNewCase.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
							}
							if (objCase.SuppliedEmail != null) {
								objNewCase.SuppliedEmail = (objCase.SuppliedEmail.endsWith('.')) ? objCase.SuppliedEmail.removeEnd('.') : objCase.SuppliedEmail;
							}

							objNewCase.Integration_Id__c = null;

							/* Ignore Assignment for Benefits New Plan Case, Benefits Change Case, Benefits Renewal Case */
							Set<String> set_IgnoredCasedrecordType = new Set<String>{ 'Benefits_New_Plan_Case', ' Benefits_Change_Case', 'Benefits_Renewal_Case' };
							if (set_OutOfOfficeUserIds.contains(objCase.OwnerId) && set_IgnoredCasedrecordType.contains(objCase.RecordType.DeveloperName) == false && objCase.Status != CaseUtils.STATUS_CLOSED) {
								objNewCase.Status = CaseUtils.STATUS_OPEN;
								objNewCase.setOptions(objDMLOptions);
							}

							list_CasesToInsert.add(objNewCase);
						}
					}
					//BTE-4022
					if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_CLIENT_RELATIONS && objCase.Status == CaseUtils.STATUS_CLOSED) {
						Date dtCloseDateOfCR = objCase.Closeddate.date();
						Integer inNumberDaysDueCR = dtCloseDateOfCR.daysBetween(dtCurrentDate);
						if (inNumberDaysDueCR > 30) {
							map_OldCaseEmail.put(objCase.Id, objEmailMessage);
							Case objNewCaseCR = new Case();
							objNewCaseCR.Subject = objCase.Subject;
							objNewCaseCR.Description = objCase.Description;
							objNewCaseCR.Status = CaseUtils.STATUS_OPEN;
							objNewCaseCR.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
							objNewCaseCR.Requires_Action__c = true;
							objNewCaseCR.AccountId = objCase.AccountId;
							objNewCaseCR.ContactId = objCase.ContactId;
							objNewCaseCR.Answer_IQ_Eligible__c = true;
							objNewCaseCR.Related_Case__c = objCase.Id;
							objNewCaseCR.ParentId = objCase.Id;
							objNewCaseCR.RecordTypeId = EmailMessageUtil.RECTYPE_ENGAGEMENT;
							objNewCaseCR.setOptions(objDMLOptions);
							list_CasesToInsert.add(objNewCaseCR);
						} else {
							objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
							map_CasesToUpdate.put(objCase.Id, objCase);
						}
					}
				} else {
					if (objEmailMessage.Incoming) {
						Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
						Integer intConnectBrokerCaseReopenBizDay = objConfig?.Connect_Broker_Case_Reopen_Biz_Days__c?.intValue() != null &&
							objConfig?.Connect_Broker_Case_Reopen_Biz_Days__c?.intValue() != 0
							? objConfig.Connect_Broker_Case_Reopen_Biz_Days__c.intValue()
							: Test.isRunningTest() ? -5 : -5;
						Datetime dtXAgoDateTime = BusinessHours.add(objGustoDenverBusinessHour?.Id, System.now(), intConnectBrokerCaseReopenBizDay * 8 * 60 * 60 * 1000);
						Boolean blnIsBenefitOrderFulfilled = objCase.Benefit_Order__c != null
							? objCase.Benefit_Order__r.Order_Status__c == EmailMessageUtil.BO_STATUS_FULFILLED ||
							  objCase.Benefit_Order__r.Order_Status__c == BenefitOrderUtil.STATUS_CLOSED_ADMIN ||
							  objCase.Benefit_Order__r.Order_Status__c == BenefitOrderUtil.STATUS_CANCELLED ||
							  objCase.Benefit_Order__r.Order_Status__c == BenefitOrderUtil.STATUS_CLOSED_LOST
							: false;
						Boolean blnIsCaseClosed = objCase.Status == CaseUtils.STATUS_CLOSED;
						Boolean blnIsCaseRecordTypeBYB = objCase.RecordTypeId == CaseUtils.RECTYPE_BYB;
						Boolean blnIsClosedWithinXDays = objCase.ClosedDate > dtXAgoDateTime;
						Boolean blnIsIntegrationIdContainsHippo = objCase.Integration_Id__c != null ? objCase.Integration_Id__c.contains(BenefitOrderUtil.BO_CASE_INTEGRATION_ID_BYB) : false;
						if (blnIsCaseRecordTypeBYB) {
							//BBO-2056 If case is closed and parent case is open, then clone email and insert in parent case
							if (
								objCase.Status == CaseUtils.STATUS_CLOSED &&
								objCase.ParentId != null &&
								objCase.Closed_Reason__c == CLOSED_REASON_MERGED &&
								objCase.Parent.Status != CaseUtils.STATUS_CLOSED
							) {
								EmailMessage objNewEmailMessage = objEmailMessage.clone();
								objNewEmailMessage.ParentId = objCase.ParentId;
								list_EmailMessagesToInsert.add(objNewEmailMessage);
							} else if (
								//BBO-2056 If case is closed and parent case is close, then create new case
								objCase.Status == CaseUtils.STATUS_CLOSED &&
								objCase.ParentId != null &&
								objCase.Closed_Reason__c == CLOSED_REASON_MERGED &&
								objCase.Parent.Status == CaseUtils.STATUS_CLOSED
							) {
								list_BYBBenefitOrderFulfilledCases.add(objCase);
								map_oldCaseIdToEmailMessageMap.put(objCase.Id, objEmailMessage);
								blnCreatedFromOtherCase = true;
							} else if (blnIsBenefitOrderFulfilled && blnIsCaseClosed && (blnIsIntegrationIdContainsHippo || (!blnIsIntegrationIdContainsHippo && !blnIsClosedWithinXDays))) {
								list_BYBBenefitOrderFulfilledCases.add(objCase);
								map_oldCaseIdToEmailMessageMap.put(objCase.Id, objEmailMessage);
								blnCreatedFromOtherCase = true;
							} else if (blnIsCaseClosed && !blnIsIntegrationIdContainsHippo && !blnIsClosedWithinXDays) {
								list_BYBBenefitOrderFulfilledCases.add(objCase);
								map_oldCaseIdToEmailMessageMap.put(objCase.Id, objEmailMessage);
								blnCreatedFromOtherCase = true;
							} else if (!blnCreatedFromOtherCase) {
								objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
							}
						}

						if (objCase.Customer_Responses_Since_Last_Update__c == null) {
							objCase.Customer_Responses_Since_Last_Update__c = 0;
						}

						objCase.Customer_Responses_Since_Last_Update__c++;

						/* Ignore Assignment for Benefits New Plan Case, Benefits Change Case, Benefits Renewal Case */
						Set<String> set_IgnoredCasedrecordType = new Set<String>{ 'Benefits_New_Plan_Case', ' Benefits_Change_Case', 'Benefits_Renewal_Case' };
						if (set_OutOfOfficeUserIds.contains(objCase.OwnerId) && set_IgnoredCasedrecordType.contains(objCase.RecordType.DeveloperName) == false && objCase.Status != CaseUtils.STATUS_CLOSED) {
							objCase.Case_In_Route__c = true;
							objCase.setOptions(objDMLOptions);
						}

						if (set_RFICaseRecordIds.Contains(objCase.RecordTypeId) && objCase.Status != CaseUtils.STATUS_CLOSED && objCase.Automated_RFI_Flow__c == true) {
							objCase.Automated_RFI_Flow__c = false;
							if (objCase.RecordTypeId == CaseUtils.RECTYPE_MF_QLE) {
								objCase.Status = CaseUtils.STATUS_NEW;
							}
						}

						if (!map_UsersById.get(UserInfo.getUserId()).Data_Migration_Validation__c) {
							String strPriorCaseStatus = objCase.Status;
							if (
								set_LatestCustomerResponseRecordTypeIds.contains(objCase.RecordTypeId) &&
								objCase.CreatedDate != objEmailMessage.CreatedDate &&
								objCase.Status != CaseUtils.STATUS_NEW &&
								objCase.Status != CaseUtils.STATUS_CLOSED &&
								!(objCase.RecordTypeId == EmailMessageUtil.RECTYPE_RECOVERY &&
								String.isNotBlank(objEmailMessage.FromAddress) &&
								objEmailMessage.FromAddress.containsIgnoreCase(EmailMessageUtil.RECOVERY_CASE_INBOUND_EMAIL_FILTER))
							) {
								objCase.Latest_Customer_Response_Date_Time__c = System.now();

								//Updated Below Condition to bypass case status updates for Engagement Record Type
								if (
									set_CustomerResponseRecordTypeIds.contains(objCase.RecordTypeId) &&
									objCase.RecordTypeId != EmailMessageUtil.RECTYPE_ENGAGEMENT &&
									!blnSkipStatusUpdateForRiskRecType
								) {
									objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
								}
								// Description:Below condition is to Update Case Status from Awaiting Response/ Awaiting Internal Support to In Progress once response is received from customer for Engagement Record Type*/
								if (
									objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT &&
									(objCase.Status == CaseUtils.STATUS_AWAITING_RESPONSE ||
									objCase.Status == CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT)
								) {
									objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
									// BTE-3635, for custom replies update the case owner to 'Engagement cases' to trigger omni
									if (objCase.OwnerId == map_QueuesByName.get(EmailMessageUtil.AUTO_SOLVE_QUEUE).Id) {
										objCase.OwnerId = map_QueuesByName.get(EmailMessageUtil.ENGAGEMENT_CASES_QUEUE).Id;
									}
									// BTE-4290, for customer replies, update the status to 'Customer Responded'
									if(objCase.Auto_Solve_Status__c == CaseUtils.AUTO_SOLVE_STATUS_ATTEMPTED){
										objCase.Auto_Solve_Status__c = CaseUtils.AUTO_SOLVE_STATUS_CUSTOMER_RESPONDED;
									}
								}
							}

							if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT) {
								if (
									map_PatternMatchingByName.containsKey(EmailMessageUtil.THANK_YOU) &&
									strPriorCaseStatus != CaseUtils.STATUS_AWAITING_RESPONSE &&
									strPriorCaseStatus != CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT
								) {
									Pattern_Matching__mdt objPatternMatching = map_PatternMatchingByName.get(EmailMessageUtil.THANK_YOU);
									Boolean blnMatchFound = false;
									String strDomain = String.isNotBlank(objEmailMessage.FromAddress) ? objEmailMessage.FromAddress.split('@')[1] : '';
									if (
										(String.isNotBlank(objPatternMatching.Email_Domains__c) && objPatternMatching.Email_Domains__c.split(';').contains(strDomain)) ||
										String.isBlank(objPatternMatching.Email_Domains__c)
									) {
										blnMatchFound = EmailMessageHelperFunctions.checkEmailPatternMatch(objEmailMessage, objPatternMatching);
									}

									if (blnMatchFound) {
										objCase.Status = CaseUtils.STATUS_CLOSED;
									}
								}

								//If it's a auto response from vestwell, case needs to be auto-closed.
								if (map_PatternMatchingByName.containsKey(EmailMessageUtil.AUTO_RESPONSE_SUBJECT)) {
									Pattern_Matching__mdt objPatternMatching = map_PatternMatchingByName.get(EmailMessageUtil.AUTO_RESPONSE_SUBJECT);
									Boolean blnMatchFound = false;
									String strDomain = String.isNotBlank(objEmailMessage.FromAddress) ? objEmailMessage.FromAddress.split('@')[1] : '';

									if (
										(String.isNotBlank(objPatternMatching.Email_Domains__c) && objPatternMatching.Email_Domains__c.split(';').contains(strDomain)) ||
										String.isBlank(objPatternMatching.Email_Domains__c)
									) {
										blnMatchFound = EmailMessageHelperFunctions.checkEmailPatternMatch(objEmailMessage, objPatternMatching);
									}

									if (blnMatchFound) {
										objCase.Status = CaseUtils.STATUS_CLOSED;
									}
								}

								if (
									String.isNotBlank(objEmailMessage.FromAddress) &&
									objEmailMessage.FromAddress.length() > 80 &&
									objCase.Origin == CaseUtils.ORIGIN_EMAIL &&
									(String.isBlank(objCase.SuppliedEmail) || !Pattern.compile(EmailUtils.EMAIL_REGEX).matcher(objCase.SuppliedEmail).matches()) &&
									objCase.Status == CaseUtils.STATUS_OPEN
								) {
									objCase.SuppliedEmail = '';
                                    objCase.Audience__c = CaseUtils.AUDIENCE_OTHER;
                                    objCase.Confirm_Case_Reason_Classification__c = map_CaseReasonByName.get(CaseUtils.SPAM_CASE_REASON).Id;
									objCase.Authorized_User__c = CaseUtils.AUTHORIZED_USER_NO;
									objCase.Status = CaseUtils.STATUS_CLOSED;
									objCase.Routing_Case_Reason__c = CaseUtils.UNAUTHORIZED_USER_CASE_REASON;
								}

								if (objEmailMessage.ToAddress == EmailMessageUtil.COBRA_EMAIL && !objCase.EmailMessages.isEmpty() && objCase.EmailMessages[0].Id == objEmailMessage.Id) {
									objCase.Specialization__c = CaseUtils.COBRA_SPECIALIZATION;
									objCase.Type = CaseUtils.BENEFITS_CASE_PILLAR;
									objCase.Support_Level__c = CaseUtils.TIER_2;
									objCase.Answer_IQ_Processed__c = CaseUtils.ANSWER_IQ_PROCESSED_YES;
									objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
								}

								List<String> list_EmailSplit = String.isNotBlank(objCase.SuppliedEmail) ? objCase.SuppliedEmail.split('@') : new List<String>();
								if (
									!list_EmailSplit.isEmpty() &&
									list_EmailSplit[1] == CaseUtils.MIDDESK_EMAIL_DOMAIN &&
									!objCase.EmailMessages.isEmpty() &&
									objCase.EmailMessages[0].Id == objEmailMessage.Id &&
									map_CaseReasonByName.containsKey(CaseUtils.MIDDESK_REGISTRATION)
								) {
									objCase.Status = CaseUtils.STATUS_IN_PROGRESS;
									objCase.Routing_Case_Reason__c = map_CaseReasonByName.get(CaseUtils.MIDDESK_REGISTRATION).Name;
									objCase.Routing_Case_Reason_Classification__c = map_CaseReasonByName.get(CaseUtils.MIDDESK_REGISTRATION).Id;
									objCase.Type = map_CaseReasonByName.get(CaseUtils.MIDDESK_REGISTRATION).Case_Type_Pillar__c;
									objCase.Support_Level__c = map_CaseReasonByName.get(CaseUtils.MIDDESK_REGISTRATION).Support_Level__c;
									objCase.Routing_Team__c = map_CaseReasonByName.get(CaseUtils.MIDDESK_REGISTRATION).Routing_Team__c;
								}
							}

							if (
								objEmailMessage.ToAddress != EmailMessageUtil.GUSTO_SUPPORT_EMAIL &&
								(objCase.Status != CaseUtils.STATUS_CLOSED ||
								(objCase.RecordType.Name != EmailMessageUtil.CASE_RT_BENEFITS_NEW_PLAN &&
								objCase.RecordType.Name != EmailMessageUtil.CASE_RT_BENEFITS_RENEWAL &&
								objCase.RecordType.Name != EmailMessageUtil.CASE_RT_BENEFITS_CHANGE &&
								objCase.RecordType.Name != EmailMessageUtil.CASE_RT_BENEFITS_BOR))
							) {
								objCase.Incoming_Email_Received__c = true;
								objCase.Requires_Action__c = true;
								objCase.Incoming_Email_Received_Date__c = System.today();
							}

							if (
								objCase.Termination_Date__c == null &&
								(String.isBlank(objEmailMessage.ThreadIdentifier) && String.isNotBlank(objEmailMessage.ToAddress) ||
								(((String.isNotBlank(objEmailMessage.ToAddress) && objEmailMessage.ToAddress?.contains(EmailMessageUtil.RENEWAL_CARRIER_EMAIL)) ||
								(String.isNotBlank(objEmailMessage.CcAddress) && objEmailMessage.CcAddress?.contains(EmailMessageUtil.RENEWAL_CARRIER_EMAIL))) &&
								String.isNotBlank(objEmailMessage.ThreadIdentifier)))
							) {
								objCase.To_Email_Address__c = objEmailMessage?.ToAddress?.left(255);
							}

							if (
								objEmailMessage.CreatedDate != objCase.CreatedDate &&
								objCase.RecordType.Name == EmailMessageUtil.CASE_RT_RISK_ASSURANCE &&
								objCase.Status != CaseUtils.STATUS_CLOSED &&
								set_OutOfOfficeUserIds.contains(objCase.OwnerId) &&
								map_QueuesByName.containsKey(EmailMessageUtil.ASSURANCE_QUEUE)
							) {
								objCase.OwnerId = map_QueuesByName.get(EmailMessageUtil.ASSURANCE_QUEUE).Id;
							}
						}

						if (objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_RENEWAL) {
							objCase.Advising_IB_Email_TPs__c = (objCase.Advising_IB_Email_TPs__c == null) ? 1 : ++objCase.Advising_IB_Email_TPs__c;
						}
						//BTE-4022
						if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_CLIENT_RELATIONS && objCase.Status == CaseUtils.STATUS_CLOSED) {
							Date dtCloseDateOfCR = objCase.ClosedDate.date();
							Integer inNumberDaysDueCR = dtCloseDateOfCR.daysBetween(dtCurrentDate);
							if (inNumberDaysDueCR > 30) {
								map_OldCaseEmail.put(objCase.Id, objEmailMessage);
								Case objNewCaseCR = new Case();
								objNewCaseCR.Subject = objCase.Subject;
								objNewCaseCR.Description = objCase.Description;
								objNewCaseCR.Status = CaseUtils.STATUS_OPEN;
								objNewCaseCR.Priority = EmailMessageUtil.CASE_PRIORTY_MEDIUM;
								objNewCaseCR.Requires_Action__c = true;
								objNewCaseCR.AccountId = objCase.AccountId;
								objNewCaseCR.ContactId = objCase.ContactId;
								objNewCaseCR.Answer_IQ_Eligible__c = true;
								objNewCaseCR.Related_Case__c = objCase.Id;
								objNewCaseCR.ParentId = objCase.Id;
								objNewCaseCR.RecordTypeId = EmailMessageUtil.RECTYPE_ENGAGEMENT;
								objNewCaseCR.setOptions(objDMLOptions);
								list_CasesToInsert.add(objNewCaseCR);
							} else {
								objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
								map_CasesToUpdate.put(objCase.Id, objCase);
							}
						}
					} else {
						setFirstResponseTime(objCase, objEmailMessage, objCurrentUser);

						if (!objEmailMessage.Automated_Email__c && objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_RENEWAL) {
							objCase.Advising_OB_Email_TPs__c = (objCase.Advising_OB_Email_TPs__c == null) ? 1 : ++objCase.Advising_OB_Email_TPs__c;
						}

						if (
							(objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_BOR ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_RENEWAL ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_NEW_PLAN ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_CHANGE ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_BYB ||
							objCase.RecordType.Name == EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE) &&
							objEmailMessage.Status == '3' &&
							String.isBlank(objEmailMessage.Email_Template_Name__c) &&
							!map_UsersById.get(UserInfo.getUserId()).Data_Migration_Validation__c
						) {
							objCase.Incoming_Email_Received__c = false;
							objCase.Requires_Action__c = false;
						}

						objCase.Customer_Responses_Since_Last_Update__c = 0;
						blnOutgoing = true;
					}
					map_CasesToUpdate.put(objCase.Id, objCase);
				}
				//Process Sales Cases
				if (
					objEmailMessage.Incoming &&
					!map_UsersById.get(UserInfo.getUserId()).Data_Migration_Validation__c &&
					(objCase.RecordType.Name == EmailMessageUtil.CASE_RT_SALES_CASES_CLOSED ||
					objCase.RecordType.Name == EmailMessageUtil.CASE_RT_SALES_CASES)
				) {
					if (objCase.Status == CaseUtils.STATUS_CLOSED && objCase.RecordType.Name == EmailMessageUtil.CASE_RT_SALES_CASES) {
						objCase.Status = CaseUtils.STATUS_NEW;
						map_CasesToUpdate.put(objCase.Id, objCase);
						// updating the status for developer assigned cases
					} else if (
						objCase.RecordType.Name == EmailMessageUtil.CASE_RT_SALES_CASES &&
						((String.isNotBlank(objEmailMessage.ToAddress) && objEmailMessage.ToAddress?.contains(EmailMessageUtil.DEVELOPER_EMAIL)) ||
						(String.isNotBlank(objEmailMessage.CcAddress) && objEmailMessage.CcAddress?.contains(EmailMessageUtil.DEVELOPER_EMAIL))) &&
						objEmailMessage.Incoming &&
						objCase.Status != CaseUtils.STATUS_NEW &&
						objCase.Status != CaseUtils.STATUS_CLOSED &&
						objCase.Status != CaseUtils.STATUS_SOLVED &&
						!objCurrentUser?.Data_Migration_Validation__c
					) {
						objCase.Status = CaseUtils.STATUS_RESPONSE_RECEIVED;
						map_CasesToUpdate.put(objCase.Id, objCase);
					}
				} else if (
					!objEmailMessage?.Incoming &&
					!map_UsersById?.get(UserInfo.getUserId())?.Data_Migration_Validation__c &&
					objCase?.RecordType?.Name == EmailMessageUtil.CASE_RT_SALES_CASES &&
					!objEmailMessage.FromAddress.contains(EmailMessageUtil.DEVELOPER_EMAIL)
				) {
					objCase.Status = CaseUtils.STATUS_CLOSED;
					map_CasesToUpdate.put(objCase.Id, objCase);
				}

				if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT && objCase.Origin == CaseUtils.ORIGIN_PHONE && !objEmailMessage?.Incoming && objEmailMessage.Status == '3') {
					objCase.Origin = CaseUtils.ORIGIN_EMAIL;
					if (String.isBlank(objCase.Type)) {
						objCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
					}
					if (String.isBlank(objCase.Support_Level__c)) {
						objCase.Support_Level__c = CaseUtils.TIER_1;
					}

					if (String.isBlank(objCase.Routing_Team__c)) {
						if ((objCase.Persona__c == CaseUtils.ADMIN_PERSONA && objCase.Company_Size__c == CaseUtils.COMPANY_SIZE_MICRO) || objCase.Persona__c == CaseUtils.MEMBER_PERSONA) {
							objCase.Routing_Team__c = CaseUtils.EXTERNAL_TEAM;
						} else {
							objCase.Routing_Team__c = CaseUtils.INTERNAL_TEAM;
						}
					}

					intClosingDays = (Label.EngagementAutoCloseDays != null) ? Integer.valueOf(Label.EngagementAutoCloseDays) : 2;
					CaseTriggerHelper.setAutoCloseDateTime(objCase, intClosingDays);
					map_CasesToUpdate.put(objCase.Id, objCase);
				}
				//BTE-4313
				 if(ClientRelationsCaseHandler.isQualified(objEmailMessage, objCase)) { 
					Id ownerId = map_QueuesByName.get(EmailMessageUtil.CLIENT_RELATIONS_QUEUE).Id;
					Case caseToInsert = ClientRelationsCaseHandler.getClientRelationsCase(objEmailMessage, objCase,ownerId);
					list_CasesToInsert.add(caseToInsert);
				}
			}
		}

		if (!list_TaxResCases.isEmpty()) {
			createTaxResAuditLogs(list_TaxResCases);
		}

		if (!map_PublishToZendesk.isEmpty() && UserInfo.getUserName().toLowerCase().indexOf('apintego') < 0 && blnSkipPartnerPublishing == false) {
			insertIntoZendeskIntegrationLog(map_PublishToZendesk.values(), map_CasesById);
		}
	}

	/*
	 * @author:         Swati Arya
	 * @description:    Method to create a new case when an email is received on case and if the Benefit Order status is fulfilled
	 * @param:          null
	 * @return:			null
	 */
	private void processBenefitOrderFulfilledCheck() {
		String strConnectBrokerQueueId = GlobalQueryHelper.getQueueIdByDevName(EmailMessageUtil.CONNECT_BROKER_QUEUE_NAME);
		if (!list_BYBBenefitOrderFulfilledCases.isEmpty() && !map_oldCaseIdToEmailMessageMap.isEmpty()) {
			for (Case objCase : list_BYBBenefitOrderFulfilledCases) {
				Case objNewCase = new Case();
				if (map_oldCaseIdToEmailMessageMap.containsKey(objCase.Id) && map_oldCaseIdToEmailMessageMap.get(objCase.Id) != null) {
					map_OldCaseEmail.put(objCase.Id, map_oldCaseIdToEmailMessageMap.get(objCase.Id));

					objNewCase.Type = EmailMessageUtil.CASE_TYPE_BYOB;
					objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_BYB);
					objNewCase.Status = EmailMessageUtil.CASE_STATUS_NEW;
					objNewCase.Requires_Action__c = true;
					objNewCase.AccountId = objCase.AccountId;
					objNewCase.Opportunity__c = objCase.Opportunity__c;
					objNewCase.Benefit_Order__c = objCase.Benefit_Order__c;
					objNewCase.ContactId = objCase.ContactId;
					objNewCase.Related_Case__c = objCase.Id;
					if (strConnectBrokerQueueId != null) {
						objNewCase.OwnerId = strConnectBrokerQueueId;
					}

					objNewCase.Subject = objCase.Subject;
					objNewCase.Description = objCase.Description;
					list_CasesToInsert.add(objNewCase);
				}
			}
		}
	}

	private EmailMessage attachEmailToExistingCase(Case objCase, EmailMessage objOriginalEmail) {
		EmailMessage objNewEmail = objOriginalEmail.clone();
		objNewEmail.Old_Parent_Email_Id__c = objOriginalEmail.Id;
		objNewEmail.ParentId = objCase.Id;

		return objNewEmail;
	}

	private void setFulfillmentRecordTypeSet() {
		set_FulFillmentRecordTypes = new Set<Id>{
			map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_BOR),
			map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_NEW_PLAN),
			map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_CHANGE),
			map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_RENEWAL)
		};
	}

	private void setFulfillmentBlockCases() {
		if (map_FulfilmentBlockCases == null || map_FulfilmentBlockCases.isEmpty()) {
			map_FulfilmentBlockCases = new Map<String, String>();
			for (Fulfillment_Block_Cases__c objFulfillmentBlockCase : Fulfillment_Block_Cases__c.getall().values()) {
				map_FulfilmentBlockCases.put(objFulfillmentBlockCase.Record_Type__c, objFulfillmentBlockCase.Email_Subject__c);
			}
		}
	}

	private Case mapCaseRecordType(Case objNewCase) {
		if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_CARE_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_CARE);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_MODERN_BANK_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_MODERN_BANK);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_TAX_RES_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_TAX_RES);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_CARE_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_BENEFITS_CARE);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_SALES_CASES_CLOSED)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_SALES_CASES);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_COMPLIANCE_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLL_COMPLIANCE);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_RISK_ASSURANCE_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_RISK_ASSURANCE);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_TAX_OPS_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_TAX_OPS);
		} else if (objNewCase.RecordTypeId == map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLLOPS_AUDIT_READ_ONLY)) {
			objNewCase.RecordTypeId = map_RecordTypeIdByName.get(EmailMessageUtil.CASE_RT_PAYROLLOPS_AUDIT);
		}

		return objNewCase;
	}

	/**
	 * @description When invoked from flow, creates applicable email message
	 * @date        04-17-2023
	 * @param       list_Ids - list of ids triggering the flow
	 * @return      void
	 * @see Payroll Transfer Notifications Flow TTF
	 **/
	@InvocableMethod(label='Payroll Transfer Update Email Message' description='Log the email notifications on Parent record.')
	public static void logCaseEmailAlerts(List<Id> list_Ids) {
		Map<Id, EmailMessage> map_ParentIdEmailMessage = new Map<Id, EmailMessage>();
		Map<Id, String> map_ParentIdTemplateName = new Map<Id, String>();
		Map<Id, Set<Attachment>> map_ParentIdAttachmentRec = new Map<Id, Set<Attachment>>();
		List<Attachment> list_AttachmentsToInsert = new List<Attachment>();

		if (list_Ids == null || list_Ids.isEmpty()) {
			return;
		}

		for (EmailMessage objEmailMessage : [
			SELECT Id, HtmlBody, Subject, ToAddress, ParentId, RelatedToId, Email_Template_Name__c, FromAddress
			FROM EmailMessage
			WHERE ParentId IN :list_Ids OR RelatedToId IN :list_Ids
			ORDER BY CreatedDate DESC
		]) {
			if (!map_ParentIdEmailMessage.containsKey(objEmailMessage.ParentId) && list_Ids.contains(objEmailMessage.ParentId)) {
				map_ParentIdEmailMessage.put(objEmailMessage.ParentId, objEmailMessage);
				map_ParentIdTemplateName.put(objEmailMessage.ParentId, objEmailMessage.Email_Template_Name__c);
			} else if (!map_ParentIdEmailMessage.containsKey(objEmailMessage.RelatedToId) && list_Ids.contains(objEmailMessage.RelatedToId)) {
				map_ParentIdEmailMessage.put(objEmailMessage.RelatedToId, objEmailMessage);
				map_ParentIdTemplateName.put(objEmailMessage.RelatedToId, objEmailMessage.Email_Template_Name__c);
			}
		}
		Map<Id, Case> map_CaseIdRec;
		Map<Id, Order> map_OrderIdRec;
		Boolean blnCaseContext = false;
		Boolean blnOrderContext = false;
		if (list_Ids.get(0).getSobjectType() == Schema.Case.getSobjectType()) {
			map_CaseIdRec = new Map<Id, Case>(
				[SELECT Id, Contact.FirstName, ContactId, Contact.Email, RecordType.Name, (SELECT Id, MemberId, ParentId FROM TeamMembers) FROM Case WHERE Id IN :list_Ids]
			);
			blnCaseContext = true;
		} else if (list_Ids.get(0).getSobjectType() == Schema.Order.getSobjectType()) {
			map_OrderIdRec = new Map<Id, Order>([SELECT Id, Case__c, Case__r.TTF_Point_Of_Contact__c, Transition_to_Fulfillment__r.Contact__c FROM Order WHERE Id IN :list_Ids]);
			blnOrderContext = true;
		}

		//Related to BenefitBOR
		Set<CaseTeamMember> set_CaseTeamMemberId = new Set<CaseTeamMember>();
		Map<Id, String> map_CaseWithEmails = new Map<Id, String>();
		Map<Id, String> map_ContactWithEmailId = new Map<Id, String>();
		if (map_CaseIdRec != null) {
			for (Case objCase : map_CaseIdRec.values()) {
				if (objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_BOR && !objCase.TeamMembers.isEmpty()) {
					set_CaseTeamMemberId.add(objCase.TeamMembers);
				}
			}
		}

		if (!set_CaseTeamMemberId.isEmpty()) {
			Set<Id> set_ContactIds = new Set<Id>();
			Map<Id, Set<Id>> map_CaseWithContactId = new Map<Id, Set<Id>>();
			for (CaseTeamMember objTeamMember : set_CaseTeamMemberId) {
				Set<Id> set_TempContactId = new Set<Id>();
				if (map_CaseWithContactId.containsKey(objTeamMember.ParentId)) {
					set_TempContactId = map_CaseWithContactId.get(objTeamMember.ParentId);
				}

				set_TempContactId.add(objTeamMember.MemberId);
				set_ContactIds.add(objTeamMember.MemberId);
				map_CaseWithContactId.put(objTeamMember.ParentId, set_TempContactId);
			}

			if (!map_CaseWithContactId.isEmpty()) {
				for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Id IN :set_ContactIds]) {
					map_ContactWithEmailId.put(objContact.Id, objContact.Email);
				}

				if (!map_ContactWithEmailId.isEmpty()) {
					for (Id set_tempParentId : map_CaseWithContactId.keySet()) {
						String strEmailAddress = '';
						for (Id objContactId : map_CaseWithContactId.get(set_tempParentId)) {
							if (map_ContactWithEmailId.get(objContactId) != null)
								strEmailAddress = map_ContactWithEmailId.get(objContactId) + ', ';
						}

						if (String.isNotBlank(strEmailAddress)) {
							strEmailAddress = strEmailAddress.removeEnd(',');
						}

						map_CaseWithEmails.put(set_tempParentId, strEmailAddress);
					}
				}
			}
		}

		processAlertEmailMessages(map_CaseIdRec, map_OrderIdRec, blnCaseContext, blnOrderContext, map_CaseWithEmails, map_ParentIdTemplateName, map_ParentIdEmailMessage, list_AttachmentsToInsert);

		try {
			Boolean blnPreviousVal = EmailMessageTriggerHelper.skipTrigger;
			Boolean blnPreviousValTask = TaskTriggerHelper.skipTrigger;
			EmailMessageTriggerHelper.skipTrigger = true;
			TaskTriggerHelper.skipTrigger = true;

			Map<Id, EmailMessage> map_EmailMessagesToUpdate = new Map<Id, EmailMessage>();
			for (EmailMessage objMessage : map_ParentIdEmailMessage.values()) {
				EmailMessage objNewMessage = new EmailMessage(
					Id = objMessage.Id,
					HtmlBody = objMessage.HtmlBody,
					Subject = objMessage.Subject,
					ToAddress = objMessage.ToAddress,
					FromAddress = objMessage.FromAddress
				);
				map_EmailMessagesToUpdate.put(objNewMessage.Id, objNewMessage);
			}

			update map_EmailMessagesToUpdate.values();

			if (!list_AttachmentsToInsert.isEmpty()) {
				insert list_AttachmentsToInsert;
			}

			EmailMessageTriggerHelper.skipTrigger = blnPreviousVal;
			TaskTriggerHelper.skipTrigger = blnPreviousValTask;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('EmailMessageTriggerHelper', 'logCaseEmailAlerts', objException.getMessage(), objException.getStackTraceString());
		}
	}

	/**
	 * @description Helper method for logCaseEmailAlerts
	 * @date        04-17-2023
	 * @param       map of case/order with id, context case/order, map email message with template, list of attachments
	 **/
	public static void processAlertEmailMessages(
		Map<Id, Case> map_CaseIdRec,
		Map<Id, Order> map_OrderIdRec,
		Boolean blnCaseContext,
		Boolean blnOrderContext,
		Map<Id, String> map_CaseWithEmails,
		Map<Id, String> map_ParentIdTemplateName,
		Map<Id, EmailMessage> map_ParentIdEmailMessage,
		List<Attachment> list_AttachmentsToInsert
	) {
		Map<Id, Set<Attachment>> map_ParentIdAttachmentRec = new Map<Id, Set<Attachment>>();
		Map<String, Id> map_TemplateNameId = new Map<String, Id>();
		Map<Id, Messaging.SingleEmailMessage> map_ParentIdEmailRec = new Map<Id, Messaging.SingleEmailMessage>();
		Id idFromAddress;
		List<OrgWideEmailAddress> list_orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Payroll Transfer' LIMIT 1];
		if (!list_orgEmails.isEmpty()) {
			idFromAddress = list_orgEmails.get(0).Id;
		}
		for (EmailTemplate objEmailTemplate : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :map_ParentIdTemplateName.values()]) {
			map_TemplateNameId.put(objEmailTemplate.DeveloperName, objEmailTemplate.Id);
		}
		if (!map_TemplateNameId.isEmpty()) {
			for (Attachment objAttachment : [SELECT Id, Body, ParentId, Name FROM Attachment WHERE ParentId IN :map_TemplateNameId.values()]) {
				//Multiple Attachment with the Parent
				Set<Attachment> set_TempAttachment = new Set<Attachment>();
				if (map_ParentIdAttachmentRec.containsKey(objAttachment.ParentId)) {
					set_TempAttachment = map_ParentIdAttachmentRec.get(objAttachment.ParentId);
				}
				set_TempAttachment.add(objAttachment);
				map_ParentIdAttachmentRec.put(objAttachment.ParentId, set_TempAttachment);
			}
		}
		if (blnCaseContext) {
			for (Case objCase : map_CaseIdRec.values()) {
				Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
				objMail.TargetObjectId = objCase.ContactId;
				objMail.TemplateId = map_TemplateNameId.get(map_ParentIdTemplateName.get(objCase.Id));
				objMail.WhatId = objCase.Id;
				objMail.setTreatTargetObjectAsRecipient(true);
				map_ParentIdEmailRec.put(objCase.Id, objMail);
			}
		} else if (blnOrderContext) {
			for (Order objOrder : map_OrderIdRec.values()) {
				Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
				if (String.isNotBlank(idFromAddress)) {
					objMail.setOrgWideEmailAddressId(idFromAddress);
				}
				objMail.TargetObjectId = objOrder.Transition_to_Fulfillment__r.Contact__c;
				objMail.TemplateId = map_TemplateNameId.get(map_ParentIdTemplateName.get(objOrder.Id));
				objMail.WhatId = objOrder.Case__c;
				objMail.setTreatTargetObjectAsRecipient(true);
				map_ParentIdEmailRec.put(objOrder.Id, objMail);
			}
		}

		Boolean blnIsError = false;

		if (!Test.isRunningTest()) {
			try {
				Savepoint objSavePoint = Database.setSavepoint();
				List<Messaging.SendEmailResult> results = Messaging.sendEmail(map_ParentIdEmailRec.values());
				Database.rollback(objSavePoint);
				for (Messaging.SendEmailResult result : results) {
					if (!result.isSuccess()) {
						Messaging.SendEmailError[] errors = result.getErrors();
						for (Messaging.SendEmailError error : errors) {
							ExceptionLogUtil.logException('EmailMessageTriggerHelper', 'logCaseEmailAlerts', 'Email sending failed', '');
						}
					}
				}
			} catch (exception ex) {
				blnIsError = true;
			}
		}

		for (Id idParent : map_ParentIdEmailMessage.keySet()) {
			if (map_ParentIdEmailRec.containsKey(idParent) && map_ParentIdEmailMessage.containsKey(idParent)) {
				Messaging.SingleEmailMessage objEmail = map_ParentIdEmailRec.get(idParent);
				EmailMessage objEmailMessage = map_ParentIdEmailMessage.get(idParent);
				objEmailMessage.HtmlBody = objEmail.getHtmlBody();
				objEmailMessage.Subject = objEmail.getSubject();
				if (objEmail?.getToAddresses() != null && !objEmail?.getToAddresses()?.isEmpty()) {
					objEmailMessage.ToAddress = String.join(objEmail.getToAddresses(), ',');
				}
				if (String.isNotBlank(idFromAddress) && String.isBlank(objEmailMessage.FromAddress)) {
					objEmailMessage.FromAddress = list_orgEmails.get(0).Address;
				}
				if (map_CaseWithEmails != null && !map_CaseWithEmails.isEmpty() && map_CaseWithEmails.containsKey(idParent)) {
					objEmailMessage.ToAddress = objEmailMessage.ToAddress + ',' + map_CaseWithEmails.get(idParent);
				}

				map_ParentIdEmailMessage.put(idParent, objEmailMessage);
				if (map_ParentIdTemplateName.containsKey(idParent) && map_TemplateNameId.containsKey(map_ParentIdTemplateName.get(idParent))) {
					Id idTemplate = map_TemplateNameId.get(map_ParentIdTemplateName.get(idParent));
					if (map_ParentIdAttachmentRec.containsKey(idTemplate)) {
						for (Attachment objAttachment : map_ParentIdAttachmentRec.get(idTemplate)) {
							Attachment objAttachmentNew = new Attachment();
							objAttachmentNew.parentId = objEmailMessage.Id;
							objAttachmentNew.Body = objAttachment.Body;
							objAttachmentNew.Name = objAttachment.Name;
							list_AttachmentsToInsert.add(objAttachmentNew);
						}
					}
				}
			}
		}
	}

	public static void processUniversalInbox(List<EmailMessage> list_NewEmailMessages) {
		//Variables & Collections
		Boolean blnIsCustomerEmail = false;
		Boolean blnIsFromGustoEmail = false;
		Boolean blnIsUniversalInboxEmail = false;
		Boolean blnIsFromAddressIgnored = false;
		String strEmailBody = '';
		String strTempMatch = '';
		String strMatch = '';
		String strRegexReplacement = '';
		List<Email_Message__c> list_EmailMessagesToInsert = new List<Email_Message__c>();
		Set<String> set_EmailAddressesToIgnore = new Set<String>();
		Boolean blnIsCommonSubjectFound = false;
		Boolean blnIgnoreEmail = false;

		try {
			if (!list_NewEmailMessages.isEmpty()) {
				// Calls method to check for customer contacts matching from address of inbound emails
				if (!set_InsertedEmailAddresses.isEmpty()) {
					set_EmailAddressesToIgnore.addAll(EmailMessageHelperFunctions.getAllContactsToIgnoreList(set_InsertedEmailAddresses));
				}

				for (EmailMessage objMessage : list_NewEmailMessages) {
					Email_Message__c objEmailMessage = new Email_Message__c();
					objEmailMessage.Message_Identifier__c = objMessage.MessageIdentifier;
					objEmailMessage.Thread_Id__c = objMessage.ThreadIdentifier;

					if (objMessage.ToAddress != null) {
						if (objMessage.ToAddress.contains(EmailMessageUtil.NEW_PLANS_EMAIL) || (objMessage.CcAddress != null && objMessage.CcAddress.contains(EmailMessageUtil.NEW_PLANS_EMAIL))) {
							objEmailMessage.Inbox_Type__c = 'New_Plans';
							objEmailMessage.To_Address__c = EmailMessageUtil.NEW_PLANS_EMAIL;
							blnIsUniversalInboxEmail = true;
						} else if (
							objMessage.ToAddress.contains(EmailMessageUtil.RENEWAL_CARRIER_EMAIL) ||
							(objMessage.CcAddress != null && objMessage.CcAddress.contains(EmailMessageUtil.RENEWAL_CARRIER_EMAIL))
						) {
							objEmailMessage.Inbox_Type__c = 'Renewals';
							objEmailMessage.To_Address__c = EmailMessageUtil.RENEWAL_CARRIER_EMAIL;
							blnIsUniversalInboxEmail = true;
						} else if (
							objMessage.ToAddress.contains(EmailMessageUtil.MEMBER_FULFILLMENT_EMAIL) ||
							(objMessage.CcAddress != null && objMessage.CcAddress.contains(EmailMessageUtil.MEMBER_FULFILLMENT_EMAIL))
						) {
							objEmailMessage.Inbox_Type__c = 'Member_Fulfillment';
							objEmailMessage.To_Address__c = EmailMessageUtil.MEMBER_FULFILLMENT_EMAIL;
							blnIsUniversalInboxEmail = true;
						} else if (objMessage.ToAddress.contains(EmailMessageUtil.RENEWALS_EMAIL) || (objMessage.CcAddress != null && objMessage.CcAddress.contains(EmailMessageUtil.RENEWALS_EMAIL))) {
							objEmailMessage.Inbox_Type__c = 'Renewals';
							objEmailMessage.To_Address__c = EmailMessageUtil.RENEWALS_EMAIL;
							blnIsUniversalInboxEmail = true;
						} else if (
							objMessage.ToAddress.contains(EmailMessageUtil.BoR_TRANSFER_EMAIL) || (objMessage.CcAddress != null && objMessage.CcAddress.contains(EmailMessageUtil.BoR_TRANSFER_EMAIL))
						) {
							objEmailMessage.Inbox_Type__c = 'BOR_Transfer';
							objEmailMessage.To_Address__c = EmailMessageUtil.BoR_TRANSFER_EMAIL;
							blnIsUniversalInboxEmail = true;
						}

						objEmailMessage.To_Addresses__c = objMessage.ToAddress?.left(255)?.removeEnd(';');
					}

					if (objMessage.CcAddress != null) {
						objEmailMessage.CC_Address__c = objMessage.CcAddress.left(255);
					}

					if (blnIsUniversalInboxEmail) {
						objEmailMessage.From_Name__c = objMessage.FromName;
						objEmailMessage.From_Addresses__c = objMessage.FromAddress;
						objEmailMessage.EmailID__c = objMessage.Id;
						objEmailMessage.Parent_Case__c = objMessage.ParentId;

						if (objMessage.TextBody != null) {
							strEmailBody = objMessage.TextBody;
						} else if (objMessage.HtmlBody != null) {
							strEmailBody = objMessage.HtmlBody.stripHtmlTags();
						}

						// Check if email from address is in the ignore set and sets Ignore From Search true
						if (set_EmailAddressesToIgnore.contains(objMessage.FromAddress)) {
							objEmailMessage.Ignore_from_Search__c = true;
							objEmailMessage.Is_Customer_Email__c = true;
							blnIsCustomerEmail = true;
						}

						// Calls method to check for from address containing any gusto domain for inbound emails
						blnIsFromGustoEmail = EmailMessageHelperFunctions.checkForGustoEmails(objMessage.FromAddress, objMessage.FromAddress, objEmailMessage);
						// Calls method to check for any from address to be ignored
						blnIsFromAddressIgnored = EmailMessageHelperFunctions.checkForFromAddressesToIgnore(objMessage.FromAddress, objMessage.FromAddress, objEmailMessage);

						if (String.isNotBlank(objMessage.Subject)) {
							objEmailMessage.Subject__c = objMessage.Subject.left(255);
							//Only if the email is not a customer email or Gusto email then process it further else ignore it.
							//Also check for any from address to be ignored and skip it.
							// SJay - 06/04/2020 - Removed blnIsFromGustoEmail check as we want to do pattern matching even for gusto emails.
							if (!blnIsCustomerEmail && !blnIsFromAddressIgnored) {
								strMatch = EmailMessageHelperFunctions.doPatternMatching(objMessage.Subject, objEmailMessage, blnIgnoreEmail, strTempMatch, strEmailBody);
							}
						}

						if (objMessage.HtmlBody != null) {
							String strHtmlTextBody = EmailMessageHelperFunctions.replaceBase64URLFromHTMLBody(objMessage.HtmlBody.left(131072));
							objEmailMessage.HTML_Text_Body__c = strHtmlTextBody.left(131072);
							objEmailMessage.Text_Body_Long__c = objMessage.HtmlBody.left(131072);
						} else if (objMessage.HtmlBody == null && objMessage.TextBody != null) {
							objEmailMessage.HTML_Text_Body__c = objMessage.TextBody.left(131072);
							objEmailMessage.Text_Body_Long__c = objMessage.TextBody.left(131072);
						}

						objEmailMessage.Text_Body__c = EmailMessageHelperFunctions.replaceBase64URLFromHTMLBody(strEmailBody.left(131072));

						if (String.isNotBlank(objEmailMessage.Text_Body__c)) {
							objEmailMessage.Text_Body_Chunk_1__c = objEmailMessage.Text_Body__c.trim().left(255);
						}
						list_EmailMessagesToInsert.add(objEmailMessage);
					}
				}
			}

			if (!list_EmailMessagesToInsert.isEmpty()) {
				insert list_EmailMessagesToInsert;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'EmailMessageTriggerHelper',
				'processUniversalInbox',
				'Exception On Line ' +
				objException.getLineNumber() +
				'-' +
				objException.getMessage(),
				objException.getStackTraceString()
			);
		}
	}

	private void insertIntoZendeskIntegrationLog(List<EmailMessage> list_EmailMessages, Map<Id, Case> map_CasesById) {
		List<Zendesk_Integration_Queue__c> list_ZendeskQueues = new List<Zendesk_Integration_Queue__c>();
		for (EmailMessage objEmailMessage : list_EmailMessages) {
			String strParentId = objEmailMessage.ParentId;
			//MF tickets need not be created any more
			if (String.isNotBlank(strParentId) && strParentId.indexOf('500') == 0) {
				Zendesk_Integration_Queue__c objZendeskQueue = new Zendesk_Integration_Queue__c();
				Case objCase = map_CasesById.get(objEmailMessage.ParentId);
				objZendeskQueue.Case_Id__c = objEmailMessage.ParentId;
				objZendeskQueue.Object_Id__c = objEmailMessage.Id;
				objZendeskQueue.Object_Type__c = 'Email';
				objZendeskQueue.Processing_State__c = 'Queued';
				String strUserName = UserInfo.getUserName();
				if (objCase.Shared_With__c == 'ApIntego' && strUserName.indexOf('apintego') < 0) {
					objZendeskQueue.Zendesk_Instance__c = 'ApIntego';
					objZendeskQueue.Zendesk_Id__c = objCase.Partner_Record_Id__c;
					list_ZendeskQueues.add(objZendeskQueue);
				}
			}
		}

		if (!list_ZendeskQueues.isEmpty()) {
			insert list_ZendeskQueues;
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Creates various collections to be used in the After Insert context across different methods
	 * @param:          list_EmailMessages - List of new Email Message records
	 */
	private void createCollectionsAfterInsert(List<EmailMessage> list_EmailMessages) {
		map_QueuesByName = new Map<String, Group>();
		map_ThreadIdToGFTicket = new Map<String, GF_Ticket__c>();
		map_ThreadIdToEmail = new Map<String, EmailMessage>();
		list_CaseAuditLogs = new List<Case_Audit_Log__c>();
		set_InsertedEmailAddresses = new Set<String>();
		map_CaseIdToEmailAddresses = new Map<String, List<String>>();
		map_CaseIdsByToAddress = new Map<String, Set<Id>>();
		set_populateCaseTypeIds = new Set<Id>();
		map_EmailMessageByCaseId = new Map<Id, EmailMessage>();
		list_TaxResCases = new List<Case>();
		map_CaseIdAuditLogRecord = new Map<String, Case_Audit_Log__c>();
		map_CaseReasonByName = new Map<String, Case_Reason_Classification__c>();

		Set<Id> set_CaseIds = new Set<Id>();
		Set<String> set_CCAddresses = new Set<String>();
		Set<String> set_ToAddresses = new Set<String>();
		Set<String> set_UniqueEmailIds = new Set<String>();
		Set<Id> set_AccountIds = new Set<Id>();
		set_RecordTypeIds = new Set<Id>{ CaseUtils.RECTYPE_NEW_PLAN, CaseUtils.RECTYPE_BOR, CaseUtils.RECTYPE_CHANGE, CaseUtils.RECTYPE_RENEWAL };
		List<String> list_EmailIds = new List<String>();
		List<String> list_CCAndToAddresses = new List<String>();
		Set<Id> set_TicketIdsToTrackEmail = new Set<Id>();

		for (BusinessHours objBHour : GlobalQueryHelper.getAllBusinessHoursList()) {
			if (objBHour.Name == 'Gusto - Denver - Engagement') {
				objBusinessHour = objBHour;
				break;
			}
		}

		for (EmailMessage objEmailMessage : list_EmailMessages) {
			if (objEmailMessage.ParentId != null && String.valueOf(objEmailMessage.ParentId).indexOf('500') == 0) {
				set_CaseIds.add(objEmailMessage.ParentId);
				map_EmailMessageByCaseId.put(objEmailMessage.ParentId, objEmailMessage);
				Case_Audit_Log__c objAuditLog = getNewCaseAuditLog(objEmailMessage);
				if (objAuditLog != null) {
					list_CaseAuditLogs.add(objAuditLog);
				}

				set_InsertedEmailAddresses.add(objEmailMessage.FromAddress);
				String strThreadId = String.isNotBlank(objEmailMessage.TextBody) ? objEmailMessage.TextBody.substringBetween('id::{{', '}}') : null;
				if (objEmailMessage.ToAddress == EmailMessageUtil.GUSTO_SUPPORT_EMAIL && String.isNotBlank(strThreadId)) {
					map_ThreadIdToEmail.put(strThreadId, objEmailMessage);
				}

				list_CCAndToAddresses = new List<String>();
				if (objEmailMessage.CcAddress != null) {
					set_CCAddresses = new Set<String>(objEmailMessage.CcAddress.toLowerCase().trim().replaceAll(' ', '').split(';'));
					list_CCAndToAddresses.addAll(objEmailMessage.CcAddress.split(';'));
				}

				set_UniqueEmailIds = new Set<String>();

				if (objEmailMessage.ToAddress != null) {
					list_CCAndToAddresses.addAll(objEmailMessage.ToAddress.split(';'));
					set_ToAddresses = new Set<String>(objEmailMessage.ToAddress.toLowerCase().trim().replaceAll(' ', '').split(';'));
					for (String strToAddress : set_ToAddresses) {
						if (strToAddress.indexOf('gusto') < 0) {
							set_UniqueEmailIds.add(strToAddress);
						}
					}

					if (objEmailMessage.ToAddress.toLowerCase().contains(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT)) {
						set_populateCaseTypeIds.add(objEmailMessage.ParentId);
						if (!map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT)) {
							map_CaseIdsByToAddress.put(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT, new Set<Id>());
						}

						map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_GARNISHMENTS_SHORT).add(objEmailMessage.ParentId);
					} else if (objEmailMessage.ToAddress.toLowerCase().contains(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT)) {
						set_populateCaseTypeIds.add(objEmailMessage.ParentId);
						if (!map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT)) {
							map_CaseIdsByToAddress.put(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT, new Set<Id>());
						}

						map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_PAYROLL_OPS_TAX_SHORT).add(objEmailMessage.ParentId);
					} else if (objEmailMessage.ToAddress.toLowerCase().contains(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT)) {
						set_populateCaseTypeIds.add(objEmailMessage.ParentId);
						if (!map_CaseIdsByToAddress.containsKey(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT)) {
							map_CaseIdsByToAddress.put(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT, new Set<Id>());
						}

						map_CaseIdsByToAddress.get(EmailMessageUtil.CASE_TYPE_UNDERWRITING_SHORT).add(objEmailMessage.ParentId);
					}
				}

				map_CaseIdToEmailAddresses.put(objEmailMessage.ParentId, list_CCAndToAddresses);

				if (!set_CCAddresses.isEmpty()) {
					set_UniqueEmailIds.addAll(set_CCAddresses);
				}

				list_EmailIds = new List<String>(set_UniqueEmailIds);

				if (!list_EmailIds.isEmpty()) {
					map_CCEmailIdsByEmailMessage.put(objEmailMessage.Id, String.join(list_EmailIds, ';').left(255));
				}

				if (String.isNotBlank(objEmailMessage.ThreadIdentifier) && objEmailMessage.Incoming && objEmailMessage.ParentId != null) {
					map_ThreadIdentifiers.put(objEmailMessage.ThreadIdentifier, objEmailMessage.ParentId);
				}
			} else if (!objEmailMessage.Incoming && objEmailMessage.RelatedToId != null && String.valueOf(objEmailMessage.RelatedToId).startsWithIgnoreCase(TaskUtil.TICKET_PREFIX)) {
				set_TicketIdsToTrackEmail.add(objEmailMessage.RelatedToId);
			}
		}

		if (!map_ThreadIdToEmail.isEmpty()) {
			// Checking for GF Tickets created in last 180 days with Ids captured from emails
			for (GF_Ticket__c objGFTicket : [SELECT Id, Id__c, Case_Id__c FROM GF_Ticket__c WHERE Id__c IN :map_ThreadIdToEmail.keySet() AND CreatedDate = LAST_N_DAYS:180]) {
				map_ThreadIdToGFTicket.put(objGFTicket.Id__c, objGFTicket);
			}
		}

		map_CasesById = new Map<Id, Case>(
			[
				SELECT
					Id,
					CCEmailAddress__c,
					Subject,
					Description,
					Email_Status__c,
					Status,
					RecordTypeId,
					OwnerId,
					Account_Specialist__c,
					Agency_Information__c,
					Last_out_bound_email__c,
					ContactId,
					Auto_Response_Email_Sent__c,
					Mass_Email_Template_Applied__c,
					Reopened_After_Mass_Email__c,
					Customer_Responses_Since_Last_Update__c,
					AccountId,
					Shared_With__c,
					From_Email__c,
					Opportunity__c,
					Benefit_Order__c,
					Benefit_Order__r.Order_Status__c,
					Origin,
					Channel__c,
					Authorized_User__c,
					Partner_Record_Id__c,
					Type,
					SuppliedEmail,
					RecordType.Name,
					RecordType.DeveloperName,
					ParentId,
					Parent.CaseNumber,
					Parent.Status,
					Parent.ParentId,
					Parent.Parent.Status,
					Parent.Parent.ParentId,
					Parent.Parent.Parent.Status,
					Parent.Parent.Parent.ParentId,
					Parent.Parent.Parent.Parent.Status,
					Parent.Parent.Parent.Parent.ParentId,
					Parent.Parent.Parent.Parent.Parent.Status,
					Integration_Id__c,
					Automated_RFI_Flow__c,
					Parent.Integration_Id__c,
					Latest_Customer_Response_Date_Time__c,
					Advising_IB_Email_TPs__c,
					Incoming_Email_Received__c,
					Requires_Action__c,
					Incoming_Email_Received_Date__c,
					To_Email_Address__c,
					Advising_OB_Email_TPs__c,
					First_Response_Time__c,
					CreatedDate,
					ClosedDate,
					Specialization__c,
					Termination_Date__c,
					Status_Change_Date_Time__c,
					In_App_Notice__c,
					BusinessHoursId,
					Auto_Close_Date_Time__c,
					Submit_AI_Feedback__c,
					Support_Level__c,
					Routing_Team__c,
					Company_Size__c,
					Persona__c,
					Answer_IQ_Processed__c,
					Partner_Case_Type__c,
					Carrier_Order__c,
					Carrier_Order__r.OwnerId,
					Carrier_Order__r.Implementation_Stage__c,
					CaseNumber,
					Closed_Reason__c,
					Auto_Solve_Status__c, 
					(SELECT Id, Status, Closed_Payroll_Run__c FROM Orders__r),
					(SELECT Id FROM EmailMessages WHERE Incoming = TRUE ORDER BY CreatedDate LIMIT 1)
				FROM Case
				WHERE Id IN :set_CaseIds
			]
		);

		for (Group objQueue : GlobalQueryHelper.getGroupsByType('Queue')) {
			map_QueuesByName.put(objQueue.DeveloperName, objQueue);
		}

		for (Case_Reason_Classification__c objCaseReason : GlobalQueryHelper.getAllCaseReasonClassification()) {
			map_CaseReasonByName.put(objCaseReason.Name, objCaseReason);
		}

		map_UsersById = GlobalQueryHelper.queryActiveUsers();

		if (!map_CasesById.isEmpty()) {
			for (Case objCase : map_CasesById.values()) {
				//Get Case to Account mapping and AccountIds of associated Cases
				if (set_RecordTypeIds.contains(objCase.RecordTypeId) && objCase.ParentId == null) {
					set_AccountIds.add(objCase.AccountId);
				}

				if (map_UsersById.containsKey(objCase.OwnerId) && map_UsersById.get(objCase.OwnerId).Out_Of_Office__c) {
					set_OutOfOfficeUserIds.add(map_UsersById.get(objCase.OwnerId).Id);
				}

				//Create & check a map of opened case id for the case id on email
				if (objCase.Status == 'Closed' && (objCase.Type == EmailMessageUtil.CASE_TYPE_COBRA || objCase.Authorized_User__c == 'Yes')) {
					if (objCase?.Parent?.Parent?.Parent?.Parent?.ParentId != null && objCase?.Parent?.Parent?.Parent?.Parent?.Parent?.Status != 'Closed') {
						map_ClosedCaseWithOpenParent.put(objCase.Id, objCase.Parent.Parent.Parent.Parent.ParentId);
					} else if (objCase?.Parent?.Parent?.Parent?.ParentId != null && objCase?.Parent?.Parent?.Parent?.Parent?.Status != 'Closed') {
						map_ClosedCaseWithOpenParent.put(objCase.Id, objCase.Parent.Parent.Parent.ParentId);
					} else if (objCase?.Parent?.Parent?.ParentId != null && objCase?.Parent?.Parent?.Parent?.Status != 'Closed') {
						map_ClosedCaseWithOpenParent.put(objCase.Id, objCase.Parent.Parent.ParentId);
					} else if (objCase?.Parent?.ParentId != null && objCase?.Parent?.Parent?.Status != 'Closed') {
						map_ClosedCaseWithOpenParent.put(objCase.Id, objCase.Parent.ParentId);
					} else if (objCase?.ParentId != null && objCase?.Parent?.Status != 'Closed') {
						map_ClosedCaseWithOpenParent.put(objCase.Id, objCase.ParentId);
					}
				}

				if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
					list_TaxResCases.add(objCase);
				}
			}

			if (!list_TaxResCases.isEmpty()) {
				for (Case_Audit_Log__c objLog : [
					SELECT Id, To_Status__c, To_Date_Time__c, CreatedDate, Case__c, To_Owner__c
					FROM Case_Audit_Log__c
					WHERE Event_Type__c = :CaseUtils.EMAIL_STATUS_CHANGE AND Case__c IN :list_TaxResCases
					ORDER BY CreatedDate DESC
				]) {
					Case_Audit_Log__c objLatestLogRecord;
					if (map_CaseIdAuditLogRecord.containsKey(objLog.Case__c)) {
						objLatestLogRecord = map_CaseIdAuditLogRecord.get(objLog.Case__c);
						if (objLatestLogRecord.CreatedDate < objLog.CreatedDate) {
							objLatestLogRecord = new Case_Audit_Log__c();
							objLatestLogRecord = objLog;
						}
					} else {
						objLatestLogRecord = objLog;
					}

					map_CaseIdAuditLogRecord.put(objLog.Case__c, objLatestLogRecord);
				}
			}

			//Fetch Existing Care Cases for specified Accounts Or which are related to the closed Customer Case
			for (Case objCase : [
				SELECT ParentId, AccountId
				FROM Case
				WHERE
					Status != :CaseUtils.STATUS_CLOSED
					AND (ParentId IN :map_CasesById.keySet()
					OR AccountId IN :set_AccountIds)
					AND ((RecordTypeId = :CaseUtils.RECTYPE_BENEFITS_CARE
					AND Parent.Integration_Id__c != NULL
					AND Parent.Integration_Id__c LIKE 'hippo-%')
					OR RecordTypeId = :CaseUtils.RECTYPE_PAYROLL_CARE)
				ORDER BY CreatedDate DESC
			]) {
				if (String.isNotBlank(objCase.ParentId) && !map_ExistingOpenCareCase.containsKey(objCase.ParentId)) {
					map_ExistingOpenCareCase.put(objCase.ParentId, objCase);
					map_ExistingOpenCareCase.put(objCase.AccountId, objCase);
				}
			}
		}

		if (!set_TicketIdsToTrackEmail.isEmpty()) {
			list_TicketsToUpdate = updateTicketCommunicationStatus(queryTickets(set_TicketIdsToTrackEmail, new List<Id>{ TaskUtil.ARDIUS_TICKET_RT_ID }));
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Creates various collections to be used across different methods
	 * @param:          map_OldEmailMessages - EmailMessage old map,
	 					map_NewEmailMessages - EmailMessage new map
	*/
	private void createCollectionsAfterUpdate(Map<Id, EmailMessage> map_OldEmailMessages, Map<Id, EmailMessage> map_NewEmailMessages) {
		map_CasesById = new Map<Id, Case>();
		Set<Id> set_CaseIds = new Set<Id>();
		list_TaxResCases = new List<Case>();
		map_CaseIdAuditLogRecord = new Map<String, Case_Audit_Log__c>();
		map_NewEmailMessageByCaseId = new Map<Id, EmailMessage>();
		map_UsersById = GlobalQueryHelper.queryActiveUsers();
		User objCurrentUser = map_UsersById.get(UserInfo.getUserId());

		for (BusinessHours objBHour : GlobalQueryHelper.getAllBusinessHoursList()) {
			if (objBHour.Name == 'Gusto - Denver - Engagement') {
				objBusinessHour = objBHour;
				break;
			}
		}

		for (EmailMessage objEmailMessage : map_NewEmailMessages.values()) {
			EmailMessage objOldEmailMessage = map_OldEmailMessages.get(objEmailMessage.Id);
			if (String.valueOf(objEmailMessage.ParentId)?.indexOf('500') == 0) {
				map_NewEmailMessageByCaseId.put(objEmailMessage.ParentId, objEmailMessage);
				if (objOldEmailMessage.Status == '5' && objEmailMessage.Incoming == false && (objEmailMessage.Status == '2' || objEmailMessage.Status == '3')) {
					set_CaseIds.add(objEmailMessage.ParentId);

					//if outbound email has a status of Sent (3) and old status was Draft (5)
					//create case audit log
					if (objEmailMessage.Status == '3') {
						Case_Audit_Log__c objAuditLog = getNewCaseAuditLog(objEmailMessage);
						map_CaseIdAuditLogRecord.put(objAuditLog.Case__c, objAuditLog);
						list_CaseAuditLogs.add(objAuditLog);
					}
				}
			}
		}

		if (!set_CaseIds.isEmpty()) {
			map_CasesById = new Map<Id, Case>(
				[
					SELECT
						Id,
						CCEmailAddress__c,
						Subject,
						Description,
						Email_Status__c,
						Status,
						RecordTypeId,
						OwnerId,
						Account_Specialist__c,
						Agency_Information__c,
						Last_out_bound_email__c,
						ContactId,
						RecordType.Name,
						First_Response_Time__c,
						Incoming_Email_Received__c,
						Requires_Action__c,
						Origin,
						Channel__c,
						BusinessHoursId,
						Auto_Close_Date_Time__c,
						Type,
						Support_Level__c,
						Routing_Team__c,
						Company_Size__c,
						Persona__c,
						Partner_Case_Type__c,
						Auto_Solve_Status__c 
					FROM Case
					WHERE Id IN :set_CaseIds
				]
			);

			for (Case objCase : map_CasesById.values()) {
				if (objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
					list_TaxResCases.add(objCase);
				}
				EmailMessage objEmailMessage = map_NewEmailMessageByCaseId.get(objCase.Id);

				setFirstResponseTime(objCase, objEmailMessage, objCurrentUser);

				if (
					set_AwaitingCustomerResponseRecTypes.contains(objCase.RecordTypeId) &&
					objEmailMessage.Incoming == false &&
					objEmailMessage.Status == '3' &&
					objCase.Status != 'Closed' &&
					objCase.Status != 'Solved' &&
					!objCurrentUser?.Data_Migration_Validation__c
				) {
					objCase.Status = 'Awaiting Response';
					if (objCase.RecordTypeId == EmailMessageUtil.RECTYPE_CLIENT_RELATIONS) {
						objCase.Auto_Close_Date_Time__c = null;
					}
				}

				if (
					(objCase.Origin == CaseUtils.ORIGIN_CHAT || (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT)) &&
					objEmailMessage.Incoming == false &&
					objEmailMessage.Status == '3' &&
					!objEmailMessage.TextBody.startsWithIgnoreCase(EmailMessageUtil.CHAT_STARTED)
				) {
					objCase.Origin = CaseUtils.ORIGIN_EMAIL;
					if (String.isBlank(objCase.Type)) {
						objCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
					}
					if (String.isBlank(objCase.Support_Level__c)) {
						objCase.Support_Level__c = CaseUtils.TIER_1;
					}
				}

				map_CasesToUpdate.put(objCase.Id, objCase);
			}

			if (!list_TaxResCases.isEmpty()) {
				for (Case_Audit_Log__c objLog : [
					SELECT Id, To_Status__c, To_Date_Time__c, CreatedDate, Case__c, To_Owner__c
					FROM Case_Audit_Log__c
					WHERE Event_Type__c = :CaseUtils.EMAIL_STATUS_CHANGE AND Case__c IN :list_TaxResCases
					ORDER BY CreatedDate DESC
				]) {
					Case_Audit_Log__c objLatestLogRecord;
					if (map_CaseIdAuditLogRecord.containsKey(objLog.Case__c)) {
						objLatestLogRecord = map_CaseIdAuditLogRecord.get(objLog.Case__c);
						if (objLatestLogRecord.CreatedDate < objLog.CreatedDate) {
							objLatestLogRecord = new Case_Audit_Log__c();
							objLatestLogRecord = objLog;
						}
					} else {
						objLatestLogRecord = objLog;
					}

					map_CaseIdAuditLogRecord.put(objLog.Case__c, objLatestLogRecord);
				}
			}
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Perform DML operations on Case & EmailMessage
	 */
	private void processDML() {
		List<String> list_ConsolidatedDMLErrors = new List<String>();

		//Insert Cases
		if (!list_CasesToInsert.isEmpty()) {
			Database.SaveResult[] list_SaveResults = Database.insert(list_CasesToInsert, false);
			List<Case> list_FailedCases = new List<Case>();

			for (Integer intI = 0; intI < list_SaveResults.size(); intI++) {
				Database.SaveResult objSaveResult = list_SaveResults[intI];

				if (!objSaveResult.isSuccess()) {
					Case objFailedCase = list_CasesToInsert[intI];
					for (Database.Error objError : objSaveResult.getErrors()) {
						List<String> list_Fields = objError.getFields();

						for (String strFieldApi : list_Fields) {
							// Get the field type using describe information
							Schema.DescribeFieldResult fieldDescribe = Case.SObjectType.getDescribe().fields.getMap().get(strFieldApi).getDescribe();
							Schema.DisplayType fieldType = fieldDescribe.getType();
 
							// Assign default values based on the field type
							if (fieldType == Schema.DisplayType.DATETIME) {
								objFailedCase.put(strFieldApi, null); // Set null for Datetime fields
							} else if (fieldType == Schema.DisplayType.DATE) {
								objFailedCase.put(strFieldApi, null); // Set null for Date fields
							} else if (fieldType == Schema.DisplayType.INTEGER) {
								objFailedCase.put(strFieldApi, 0); // Set 0 for Integer fields
							} else if (fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.CURRENCY) {
								objFailedCase.put(strFieldApi, 0.0); // Set 0.0 for Decimal/Currency fields
							} else if (fieldType == Schema.DisplayType.STRING) {
								objFailedCase.put(strFieldApi, ''); // Set empty string for String fields
							} else if (fieldType == Schema.DisplayType.BOOLEAN) {
								objFailedCase.put(strFieldApi, false); // Set false for Boolean fields
							} else {
								objFailedCase.put(strFieldApi, null); // Set null for other types
							}
						}
					}

					list_FailedCases.add(objFailedCase);
				}
			}

			if (!list_FailedCases.isEmpty()) {
				List<Database.SaveResult> list_InsertResults = Database.insert(list_FailedCases, false);
				list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_InsertResults, 'Insert'));
			}

			for (Case objCase : list_CasesToInsert) {
				String strOldCaseId = objCase.Related_Case__c != null ? objCase.Related_Case__c : objCase.ParentId;
				EmailMessage objEmailMessage = map_OldCaseEmail.get(strOldCaseId);
				EmailMessage objNewEmailMessage = objEmailMessage.clone();
				objNewEmailMessage.Old_Parent_Email_Id__c = objEmailMessage.Id;
				objNewEmailMessage.ParentId = objCase.Id;
				list_EmailMessagesToInsert.add(objNewEmailMessage);

				if (objCase.Related_Case__c != null) {
					Case objCaseToUpdate = map_CasesById.get(strOldCaseId);
					objCaseToUpdate.ParentId = objCase.Id;
					map_CasesToUpdate.put(strOldCaseId, objCaseToUpdate);
				}
			}
		}

		//Process DML on EmailMessage
		if (!list_EmailMessagesToInsert.isEmpty()) {
			List<Database.SaveResult> list_InsertResults = Database.insert(list_EmailMessagesToInsert, false);

			list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_InsertResults, 'Insert'));
		}

		//Process DML on Case
		if (!map_CasesToUpdate.isEmpty()) {
			CaseTriggerHelper.processStatusChange = true;
			List<Database.SaveResult> list_UpdateResults = Database.update(map_CasesToUpdate.values(), false);
			list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResults, 'Update'));
		}

		if (!list_GFTicketsToUpdate.isEmpty()) {
			// The presence of case id drives the update logic in GF Ticket Helper updating the existing case
			GFTicketTriggerHelper.blnIsFirstEOYSpotCase = true;
			List<Database.SaveResult> list_UpdateResults = Database.update(list_GFTicketsToUpdate, false);
			list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResults, 'Update'));
		}

		if (!list_CaseAuditLogs.isEmpty()) {
			List<Database.SaveResult> list_InsertResults = Database.insert(list_CaseAuditLogs, false);
			list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_InsertResults, 'Insert'));
		}

		//Process DML - Tickets
		if (list_TicketsToUpdate != null && !list_TicketsToUpdate.isEmpty()) {
			List<Database.SaveResult> list_UpdateResult = Database.update(list_TicketsToUpdate, false);
			list_ConsolidatedDMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResult, 'Update'));
		}

		if (!list_ConsolidatedDMLErrors.isEmpty()) {
			//do not log errors about email addresses being too long
			for (Integer intIndex = 0; intIndex < list_ConsolidatedDMLErrors.size(); intIndex++) {
				if (list_ConsolidatedDMLErrors[intIndex].contains(EmailMessageUtil.INVALIDEMAILERROR) || list_ConsolidatedDMLErrors[intIndex].contains(EmailMessageUtil.CLOSED_CASE_VAL_RULE)) {
					list_ConsolidatedDMLErrors.remove(intIndex);
				}
			}
			//after removing the invalid email address errors, check if list is still not empty before sending emails and logging the error - BTE-2923.
			if (!list_ConsolidatedDMLErrors.isEmpty()) {
				ExceptionLogUtil.logException(UserInfo.getUserId(), 'EmailMessageTriggerHelper', 'processDML', list_ConsolidatedDMLErrors, 'Medium');
				Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
				objMail.setToAddresses(new List<String>{ 'biztech-logs@gusto.com' });
				objMail.setSubject('EmailMessageTriggerHelper Error');
				objMail.setPlainTextBody('Erorr in processDML() :  <<<<<<< ' + list_ConsolidatedDMLErrors);
				Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objMail });
			}
		}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    Create Case Audit Logs for TaxRes Cases with Email Status Change
	 * @param:          list_Cases - List of Tax Res Cases
	 */
	public void createTaxResAuditLogs(List<Case> list_Cases) {
		if (!list_Cases.isEmpty()) {
			for (Case objCase : list_Cases) {
				Case_Audit_Log__c objAuditLog;
				Case_Audit_Log__c objNewAuditLog = new Case_Audit_Log__c();
				if (map_CaseIdAuditLogRecord.containsKey(objCase.Id)) {
					objAuditLog = map_CaseIdAuditLogRecord.get(objCase.Id);
				}

				objNewAuditLog.Case__c = objCase.Id;
				objNewAuditLog.To_Date_Time__c = System.now();
				objNewAuditLog.Event_Type__c = CaseUtils.EMAIL_STATUS_CHANGE;
				objNewAuditLog.To_Status__c = objCase.Email_Status__c;
				if (objCase.OwnerId == objCase.Account_Specialist__c) {
					objNewAuditLog.Current_Role__c = CaseUtils.TAXRES_ACCOUNT_SPECIALIST;
				}

				if (objAuditLog?.Id != null) {
					objNewAuditLog.From_Status__c = objAuditLog.To_Status__c;
					if (objNewAuditLog.From_Status__c == objNewAuditLog.To_Status__c) {
						continue;
					}

					objNewAuditLog.From_Date_Time__c = objAuditLog.To_Date_Time__c;
				}

				if (objBusinessHour != null && objNewAuditLog.From_Date_Time__c != null && objNewAuditLog.To_Date_Time__c != null) {
					objNewAuditLog.Business_Hours__c = objBusinessHour.Id;
					Id idHours = objNewAuditLog.Business_Hours__c;
					DateTime dtmFromTime = objNewAuditLog.From_Date_Time__c;
					DateTime dtmToTime = objNewAuditLog.To_Date_Time__c;
					if (dtmFromTime != null) {
						Long lngMilliSeconds = BusinessHours.diff(idHours, dtmFromTime, dtmToTime);
						objNewAuditLog.Duration_in_seconds__c = lngMilliSeconds / 1000;
					}
				}

				objNewAuditLog.Current_Owner__c = String.valueOf(objCase.OwnerId).startsWith('005') ? objCase.OwnerId : null;
				list_CaseAuditLogs.add(objNewAuditLog);
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @description if an email is being sent on a Case with a certain record type, set First Response Time on the Case
	 * @param 	objCase - a Case record,
	 * 			objEmailMessage - an EmailMessage belonging to the Case
	 * 			objCurrentUser - the current user
	 */
	public static void setFirstResponseTime(Case objCase, EmailMessage objEmailMessage, User objCurrentUser) {
		if (
			set_FirstResponseRecordTypes.contains(objCase.RecordTypeId) &&
			objEmailMessage.Incoming == false &&
			objEmailMessage.Status == '3' &&
			objCase.First_Response_Time__c == null &&
			objCurrentUser.Data_Migration_Validation__c == false
		) {
			objCase.First_Response_Time__c = System.now();
		}
	}

	/**
	 * @author Alex Xiong
	 * @description query metadata records for cloning case record types, only include Active ones
	 */
	public void getRecordTypesToCloneCase() {
		Map<String, Id> map_CaseRecNameToId = RecordTypes.getRecordTypeDevNameIdMap('Case');

		for (Case_Record_Type_to_clone_from_Email__mdt objRecordType : Case_Record_Type_to_clone_from_Email__mdt.getAll().values()) {
			if (objRecordType.Active__c && map_CaseRecNameToId?.containsKey(objRecordType.Label)) {
				set_ClosedCaseNewRecordTypes.add(map_CaseRecNameToId.get(objRecordType.Label));
			}
		}
	}

	/**
	 * @author Alex Xiong
	 * @description query metadata records for case record type behavior
	 */
	public void getCaseRecordTypeBehaviors() {
		Map<String, Id> map_CaseRecNameToId = RecordTypes.getRecordTypeDevNameIdMap('Case');

		for (Case_Record_Type_Behavior__mdt objRecordType : Case_Record_Type_Behavior__mdt.getAll().values()) {
			if (String.isNotBlank(objRecordType.Label) && objRecordType.Active__c && map_CaseRecNameToId?.containsKey(objRecordType.Label)) {
				if (objRecordType.Status_Updates_to_Response_Received__c) {
					set_CustomerResponseRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
				}

				if (objRecordType.Latest_Customer_Response__c) {
					set_LatestCustomerResponseRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
				}
			}
		}
	}

	/**
	 * @JIRA BSS-1063
	 * @description if an email being sent on a Case with a certain record type is first saved as draft and later updated as sent,
	 * reset Requires Action on the case after update
	 * @param 	map_OldEmailMessages - EmailMessage Trigger oldMap
	 */
	private void processOutgoingDraft(Map<Id, EmailMessage> map_OldEmailMessages) {
		List<Case> list_CasesToUpdate = new List<Case>();
		for (Case objCase : map_CasesById.values()) {
			if (map_NewEmailMessageByCaseId.containsKey(objCase.Id)) {
				EmailMessage objEmailMessage = map_NewEmailMessageByCaseId.get(objCase.Id);
				if (map_OldEmailMessages.containsKey(objEmailMessage.Id)) {
					EmailMessage objOldEmailMessage = map_OldEmailMessages.get(objEmailMessage.Id);
					if (
						(objCase.RecordType.Name == EmailMessageUtil.CASE_RT_PAYROLL_TRANSFER_CASE ||
						objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_BYB) &&
						objCase.Requires_Action__c &&
						objOldEmailMessage.Status == '5' &&
						(objEmailMessage.Status == '3' ||
						objEmailMessage.Status == '2') &&
						String.isBlank(objEmailMessage.Email_Template_Name__c) &&
						!map_UsersById.get(UserInfo.getUserId()).Data_Migration_Validation__c
					) {
						objCase.Incoming_Email_Received__c = false;
						objCase.Requires_Action__c = false;
						if (objCase.RecordType.Name == EmailMessageUtil.CASE_RT_BENEFITS_BYB) {
							map_CasesToUpdate.put(objCase.Id, objCase);
						} else {
							list_CasesToUpdate.add(objCase);
						}
					}
					if (
						objCase.RecordTypeId == EmailMessageUtil.RECTYPE_ENGAGEMENT &&
						objCase.Origin == CaseUtils.ORIGIN_PHONE &&
						!objEmailMessage?.Incoming &&
						objOldEmailMessage.Status != objEmailMessage.Status &&
						objEmailMessage.Status == '3'
					) {
						objCase.Origin = CaseUtils.ORIGIN_EMAIL;
						if (String.isBlank(objCase.Type)) {
							objCase.Type = CaseUtils.PAYROLL_CASE_PILLAR;
						}
						if (String.isBlank(objCase.Support_Level__c)) {
							objCase.Support_Level__c = CaseUtils.TIER_1;
						}

						if (String.isBlank(objCase.Routing_Team__c)) {
							if ((objCase.Persona__c == CaseUtils.ADMIN_PERSONA && objCase.Company_Size__c == CaseUtils.COMPANY_SIZE_MICRO) || objCase.Persona__c == CaseUtils.MEMBER_PERSONA) {
								objCase.Routing_Team__c = CaseUtils.EXTERNAL_TEAM;
							} else {
								objCase.Routing_Team__c = CaseUtils.INTERNAL_TEAM;
							}
						}

						intClosingDays = (Label.EngagementAutoCloseDays != null) ? Integer.valueOf(Label.EngagementAutoCloseDays) : 2;
						CaseTriggerHelper.setAutoCloseDateTime(objCase, intClosingDays);
						list_CasesToUpdate.add(objCase);
					}
				}
			}
		}

		if (!list_CasesToUpdate.isEmpty()) {
			CaseTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> list_UpdateResults = Database.update(list_CasesToUpdate, false);
			List<String> list_DMLErrors = new List<String>();
			list_DMLErrors.addAll(EmailMessageUtil.processDMLErrors(list_UpdateResults, 'Update'));
			if (!list_DMLErrors.isEmpty()) {
				ExceptionLogUtil.logException(UserInfo.getUserId(), 'EmailMessageTriggerHelper', 'processOutgoingDraft', list_DMLErrors, 'Medium');
			}
		}
	}

	/**
	 * @description	Query Tickets
	 * @author	Ajay Krishna PU
	 * @param	set_TicketIds - Set of Ticket Ids related to Task
	 * @param	list_RecordTypeIds - List of RecordType Ids
	 * @return	List of Tickets having Id @set_TicketIds and RecordTypeId @list_RecordTypeIds
	 **/
	private List<Ticket__c> queryTickets(Set<Id> set_TicketIds, List<Id> list_RecordTypeIds) {
		return [SELECT Id, RecordTypeId, Communication_Status__c FROM Ticket__c WHERE Id IN :set_TicketIds AND RecordTypeId IN :list_RecordTypeIds];
	}

	/**
	 * @description	Updates Communication status
	 * @author	Ajay Krishna P U
	 * @param	list_Tickets List of Tickets in which communication status need to update
	 * @return	`List<Ticket__c>`
	 */
	private List<Ticket__c> updateTicketCommunicationStatus(List<Ticket__c> list_Tickets) {
		if (list_Tickets == null || list_Tickets.isEmpty()) {
			return new List<Ticket__c>();
		}

		for (Ticket__c objTicket : list_Tickets) {
			objTicket.Communication_Status__c = TicketUtil.COMM_STATUS_AWAITING_RESPONSE;
		}

		return list_Tickets;
	}

	/**
	 * @desc	Close duplicate Payroll Transfer Cases if there is another email thread attached to existing Payroll transfer case
	 * @author	Praveen Sethu
	 * @param	void
	 **/
	public void processDuplicatePTCases() {
		for (EmailMessage objEmail : [
			SELECT id, ThreadIdentifier
			FROM EmailMessage
			WHERE
				ThreadIdentifier IN :map_ThreadIdentifiers.keySet()
				AND ParentId NOT IN :map_ThreadIdentifiers.values()
				AND ParentId != NULL
				AND ThreadIdentifier != NULL
				AND Parent.RecordType.Name = :PAYROLL_TRANSFER_CASE_REC_TYPE
		]) {
			if (map_ThreadIdentifiers.containsKey(objEmail.ThreadIdentifier)) {
				map_CasesToUpdate.put(
					map_ThreadIdentifiers.get(objEmail.ThreadIdentifier),
					new Case(Id = map_ThreadIdentifiers.get(objEmail.ThreadIdentifier), Status = 'Closed', Description = 'Existing Payroll Transfer Case')
				);
			}
		}
	}

	/**
	 * @desc	If an Incoming emailmessagebody matches Partner Regex, update Partner_Case_Type__c field to Default value on Case.
	 * @param	objEmailMsg - EmailMessage Record
	 **/
	public void evaluatePartnerRedirects(EmailMessage objEmailMsg) {
		try {
			// Perform this check only on incoming emails
			if (objEmailMsg.Incoming) {
				for (Partner_Case_Setting__mdt partnerCaseConfig : [SELECT Id, RegEx_Pattern__c, MasterLabel, Email_Template_ID__c FROM Partner_Case_Setting__mdt]) {
					Case objCase = map_CasesToUpdate.containsKey(objEmailMsg.ParentId) ? map_CasesToUpdate.get(objEmailMsg.ParentId) : map_CasesById.get(objEmailMsg.ParentId);
					// Once a case has an email that matches the pattern, skip the logic for the rest of the emails on that case
					if (objEmailMsg.TextBody != null && String.IsBlank(objCase?.Partner_Case_Type__c)) {
						String strRegexPattern = String.isNotBlank(partnerCaseConfig.RegEx_Pattern__c) ? partnerCaseConfig.RegEx_Pattern__c.toLowerCase() : '';
						Pattern objPattern = Pattern.compile(strRegexPattern);
						String strLowerCaseEmailBody = objEmailMsg.TextBody.toLowerCase();
						// Find the index of the first occurrence of the delimiter
						Integer intDelimiterIndex = strLowerCaseEmailBody.indexOf(EmailMessageUtil.EMAIL_DELIMITER);
						String strEmailBody = (intDelimiterIndex != -1)
							? strLowerCaseEmailBody.substring(0, intDelimiterIndex + EmailMessageUtil.EMAIL_DELIMITER.length()).trim()
							: strLowerCaseEmailBody;
						Matcher objMatcher = objPattern.matcher(strEmailBody);
						if (objMatcher.find()) {
							objCase.Partner_Case_Type__c = partnerCaseConfig.MasterLabel;
						}
						map_CasesToUpdate.put(objCase.Id, objCase);
					}
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('EmailMessageTriggerHelper', 'evaluatePartnerRedirects', objException.getMessage(), objException.getStackTraceString());
		}
	}
}