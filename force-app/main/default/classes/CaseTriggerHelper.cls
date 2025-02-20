/**
 * @name         CaseTriggerHelper
 * @author       Aurobind Ravichandran
 * @date         03/30/2017
 * @description
 **/
public class CaseTriggerHelper {
	public static boolean playmode = false;
	public static boolean playmode_caseRouting = false;
	public static boolean skipTrigger = false;
	public static boolean blnFormAutomationBatch = false;
	public static integer counter = 0;
	public static integer intClosingDays = 0;
	public static boolean processStatusChange = false;
	public static string fromEmailAddress = '';
	private static boolean zendeskInfoProcessed = false;
	public static string context = '';
	public static Boolean blnIsVendorCXUser = false;
	public static Map<String, String> recordTypeNameIdMap = new Map<String, String>();
	private static Map<String, String> recordTypeIdNameMap = new Map<String, String>();
	private static Map<Id, Account> map_Accounts;
	private static Map<Id, Case> map_ParentCaseDetails;
	private static Map<String, Account> map_CompanyIdAccounts;
	private static Map<String, Entitlement> map_Entitlement;
	private Map<String, Email_Subject_AutoClosed__c> map_AutoCloseSubjectMap = new Map<String, Email_Subject_AutoClosed__c>();
	private Map<String, Email_Subject_AutoClosed__c> map_PartialMatchAutoCloseSubject = new Map<String, Email_Subject_AutoClosed__c>();
	private static List<Case_Audit_Log__c> caseAuditLogList = new List<Case_Audit_Log__c>();
	private set<String> zendeskIdSet = new Set<String>(); //used for historical conversion
	public static map<string, string> zendeskMigrationCaseMap = new Map<string, string>(); //used for historical conversion
	public static boolean fromAgatha = false;
	private static set<String> selectionIdSet = new Set<String>();
	public static String strLaunchedFrom = '';

	map<String, ZP_User__c> zpUserInfoMap = new Map<String, ZP_User__c>();
	map<String, Lead> leadInfoMap = new Map<String, Lead>();
	Set<String> emailSet = new Set<String>();
	map<String, map<String, Case_Reason_Classification__c>> classMap = new Map<String, map<String, Case_Reason_Classification__c>>();
	Map<String, Map<String, Case_Reason_Classification__c>> map_TypeToReasonsLowerCase = new Map<String, Map<String, Case_Reason_Classification__c>>();
	map<String, Large_Scale_Issue__c> lsiMap = new Map<String, Large_Scale_Issue__c>();
	map<String, Case_Reason_Classification__c> allClassMap = new Map<String, Case_Reason_Classification__c>();
	map<String, String> caseReasonTypeMapSet = new Map<String, String>();
	static map<Id, Agency_Information__c> agencyMap = new Map<Id, Agency_Information__c>();
	map<String, Agency_Information__c> agencyDomainMap = new Map<String, Agency_Information__c>();
	map<String, Agency_Information__c> agencyEmailMap = new Map<String, Agency_Information__c>();
	public static Map<Id, Group> map_Queues = new Map<Id, Group>();
	public static Map<String, Id> nameIdQueueMap = setQueueInformation();
	List<Group> qTypesGroups = new List<Group>();
	public static Set<Id> closedCaseIdSetUponCreation = new Set<id>();
	public static Configuration_Settings__c objConfigSettings = CaseUtils.objConfigSettings;
	public static String BIZTECH_ERROR_EMAIL = System.Label.BizTech_Error_Email;

	//MB case "Complaint Type" values for which we want to create a Ticket object record.
	Set<string> set_MBComplaintTypesForTicketCreation = new Set<string>();

	public static final Set<String> set_PilotAgencies = CaseUtils.getRingLeadEligibleAgencies();
	public static final String AUTO_EMAIL_SIGNATURE_NAME = 'Auto_Email_Signature';
	public static List<String> list_EmailTemplatesToQuery = new List<String>{
			Label.Suspension_Case_Audit_Email_Template_Unique_Name,
			AUTO_EMAIL_SIGNATURE_NAME,
			CaseUtils.GEP_CX_AUTO_CLOSE_EMAIL_TEMPLATE
	};
	public static Map<String, EmailTemplate> map_EmailTemplates = CaseQueryHelper.getEmailTemplates(list_EmailTemplatesToQuery);
	public static List<Case_Merge_Exclusion__mdt> list_CaseMergeExclusionMdt = CaseQueryHelper.getCaseMergeExclusionMetaData();
	public static Set<Id> set_ConfirmReasonReadOnlyRecordTypes = new Set<Id>{
			Cache.getRecordTypeId('Case', 'Modern Bank - Read Only'),
			Cache.getRecordTypeId('Case', 'Payroll Care - Read Only'),
			Cache.getRecordTypeId('Case', 'Benefits Care - Read Only')
	};

	static final String CONFIRM_CASE_REASON = 'Client Unresponsive';
	static final String CASE_STATUS_AWAITING = 'Awaiting Response';
	static final String CASE_STATUS_SOLVED = 'Solved';
	static final String CASE_TAXRES_RECORDTYPE = 'Tax Res';
	static final String CASE_ROUTING_REASON = 'Payroll Suspension Audit';
	static final String CASE_STATUS_READY_FOR_RESEARCH = CaseUtils.CASE_STATUS_READY_FOR_RESEARCH;
	public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE;
	public static final String CASE_STATUS_READY_FOR_OCR_CAPTURE = CaseUtils.CASE_STATUS_READY_FOR_OCR_CAPTURE;
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');
	public static final String TAXRES_AUTO_CLOSE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Tax_Res_Auto_Close');
	public static final Set<String> set_SpecialistSpecificAgencies = new Set<String>{ 'Social Security Administration', 'Washington LnI', 'CAWR' };
	public Map<Id, Case_Reason_Classification__c> map_CaseReasonsById;
	public Map<Id, List<Sub_Case_Reason_Classification__c>> map_SubCaseReasons;
	public static Set<Id> set_AutoInProgressRecordTypeIds = new Set<Id>();
	public static final Set<String> set_OCRQueueAgencies = new Set<String>{
			'Internal Revenue Service',
			'CA-EDD',
			'Texas Workforce Commission',
			'Washington State Employment Security Department',
			'Federal Unemployment'
	};
	public static Set<Id> set_AuthorizedUserRecordTypeIds = new Set<Id>();
	public static Set<Id> set_AutoSolveRecordTypeIds = new Set<Id>();
	public static Set<Id> set_AutoCloseRecordTypeIds = new Set<Id>();
	public static Set<Id> set_AnswerIQEligible = new Set<Id>();
	public static final String STR_TAXRES_RICOH_QUEUE = 'TaxRes Ricoh Users';
	public static Map<String, Set<Id>> MAP_TAXRES_RICOH_USERS = GlobalQueryHelper.getGroupMembersByName(STR_TAXRES_RICOH_QUEUE);

	public static final Set<Id> set_EligibleSubmittedRecordTypes = new Set<Id>{
			CaseUtils.RECTYPE_MF_AUDIT,
			CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES,
			CaseUtils.RECTYPE_MF_NHE,
			CaseUtils.RECTYPE_MF_QLE,
			CaseUtils.RECTYPE_MF_TERMINATION,
			CaseUtils.RECTYPE_MF_CANCELLATION,
			CaseUtils.RECTYPE_GROUP_TERMINATION
	};

	public static final Set<Id> set_PendingAutomationStatusRT = new Set<Id>{ CaseUtils.RECTYPE_MF_NHE, CaseUtils.RECTYPE_MF_TERMINATION, CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES };

	public static final Set<String> set_UpdateFRTRecordTypes = new Set<String>{ CaseUtils.RECTYPE_MF_QLE, CaseUtils.RECTYPE_MF_TERMINATION, CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES };
	public static Set<String> set_CancelationRecordTypes = new Set<String>{ CaseUtils.RECTYPE_MF_NHE, CaseUtils.RECTYPE_MF_TERMINATION };
	public static Integer intDaysDifference = -23;

	//Collection variables
	private static Map<Id, Contact> map_Contacts;
	private static Map<Id, Contact> map_SMSContacts;
	private static Set<String> set_SuppliedPhoneNumbers;
	private static Map<String, Id> map_PhoneToContacts;
	private static List<Case> list_MigrationCaseForOrderAssignment; //tagging email to orders
	private static Set<Id> set_AccoundIdsForAssigningOrderToCase;
	private static List<Account> list_AccountsForAssigningOrderToCase;
	private static Set<Id> set_AccountIdBOR;
	private static Set<String> set_ZPCompanyIdsFBED;
	private static List<Account> list_AccountsForFulfillmentCaseRouting;
	private static Map<Id, User> map_AllUsers;
	private static Map<Id, Case> map_LeadCase;
	private static Map<Id, Case> map_AccCase;
	private static List<Account> list_AccountsForUpdateAccLeadActivityDate;
	private static Map<String, Case_Pillar_Mapping__c> map_PillarMappingByKey;
	private static Map<String, Case_Pillar_Mapping__c> map_PillarWOCompanySize;
	private static List<String> list_Specializations;
	public static Set<Id> set_TAdACarrierIds = Utils.set_TAdACarrierIds;

	//Constructor
	public CaseTriggerHelper() {
			set_SuppliedPhoneNumbers = new Set<String>();
			map_PhoneToContacts = new Map<String, Id>();
			set_AccoundIdsForAssigningOrderToCase = new Set<Id>();
			list_MigrationCaseForOrderAssignment = new List<Case>();
			set_AccountIdBOR = new Set<Id>();
			set_ZPCompanyIdsFBED = new Set<String>();
			map_AllUsers = new Map<Id, User>();
			map_LeadCase = new Map<Id, Case>();
			map_AccCase = new Map<Id, Case>();
			list_AccountsForUpdateAccLeadActivityDate = new List<Account>();
			map_ParentCaseDetails = new Map<Id, Case>();
	}

	/**
	 * @author Alex Xiong
	 * @description Create data collections to be used across functions
	 */
	public static void createCollectionsBefore(List<Case> list_Cases, Map<Id, Case> map_Cases) {
			map_AllUsers = GlobalQueryHelper.queryActiveUsers();
			Set<String> set_ContactIds = new Set<String>();
			Set<Id> set_AccountIds = new Set<Id>();
			Set<Id> set_ParentCaseIds = new Set<Id>();

			for (Case objCase : list_Cases) {
					if (objCase.ContactId != null) {
							set_ContactIds.add(objCase.ContactId);
					}

					if (String.isNotBlank(objCase.SuppliedPhone)) {
							set_SuppliedPhoneNumbers.add(objCase.SuppliedPhone);
					}

					//collect all Account Ids
					if (objCase.AccountId != null && !set_AccountIds.contains(objCase.AccountId)) {
							set_AccountIds.add(objCase.AccountId);
					}

					//for assigningOrderToCase()
					if (
							objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_TRANSFER_CASE &&
							objCase.Origin == CaseUtils.ORIGIN_EMAIL &&
							objCase.Order__c == null &&
							objCase.Direction__c == CaseUtils.STR_INBOUND &&
							objCase.AccountId != null &&
							objCase.Type != CaseUtils.TYPE_DOC_MAPPING
					) {
							list_MigrationCaseForOrderAssignment.add(objCase);
							set_AccoundIdsForAssigningOrderToCase.add(objCase.AccountId);
					}

					//for setFulfillmentCaseRouting()
					if (objCase.SuppliedEmail != null && objCase.Skip_Assignment__c == false && objCase.RecordTypeId == CaseUtils.RECTYPE_BOR && objCase.AccountId != null) {
							set_AccountIdBOR.add(objCase.AccountId);
					}

					//for FBED
					if (objCase.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE && objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
							if (String.isNotBlank(objCase.Company_ID__c)) {
									set_ZPCompanyIdsFBED.add(objCase.Company_ID__c);
							}
							if (String.isNotBlank(objCase.ParentId)) {
									set_ParentCaseIds.add(objCase.ParentId);
							}
					}
			}

			if (map_PillarMappingByKey == null) {
                getPillarMapping();
			}

			setEntitlementMap(set_AccountIds);
			queryContacts(set_ContactIds, set_SuppliedPhoneNumbers);
			queryAccounts(set_AccountIds);
			getParentCaseDetails(set_ParentCaseIds);
	}

	/**
	 * @author Alex Xiong
	 * @description Create data collections to be used across functions
	 */
	public static void createCollectionsAfter(List<Case> list_Cases, Map<Id, Case> map_OldCases) {
			map_AllUsers = GlobalQueryHelper.queryActiveUsers();
			Set<Id> set_AccountIds = new Set<Id>();

			for (Case objCase : list_Cases) {
					if (objCase.AccountId != null) {
							set_AccountIds.add(objCase.AccountId);
					}

					//for updateAccLeadActivityDate()
					if (map_AllUsers.containsKey(objCase.OwnerId)) {
							String strUserRole = map_AllUsers.get(objCase.OwnerId).UserRole.Name;

							if (!String.isBlank(strUserRole)) {
									if (
											strUserRole.containsIgnoreCase(CaseUtils.TYPE_SALES) &&
											(objCase.Origin == CaseUtils.ORIGIN_CHAT || (objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.ORIGIN_CHAT))
									) {
											if (objCase.Lead__c != null) {
													map_LeadCase.put(objCase.Lead__c, objCase);
											}
											if (objCase.Account != null) {
													map_AccCase.put(objCase.AccountId, objCase);
											}
									}
							}
					}
			}

			queryAccounts(set_AccountIds);
	}

	public void processBeforeInsert(List<Case> cases) {
			createCollectionsBefore(cases, null);
			counter++;
			set<id> accIdSet = new Set<id>();
			list<case> suspensionAuditCases = new List<case>();
			list<Case> lst_PTEmailCase = new List<Case>();
			List<Case> list_nonPrivacyCases = new List<Case>();
			List<Case> list_PhoneCases = new List<Case>();
			List<Case> list_MFCases = new List<Case>();
			Set<Id> set_CarrierIds = new Set<Id>();
			User objCurrentUser = GlobalQueryHelper.getUserInfoById(UserInfo.getUserId());
			Set<Id> set_UserIdFromRicohGroup = new Set<Id>();
			if (MAP_TAXRES_RICOH_USERS != null && MAP_TAXRES_RICOH_USERS.containsKey(GlobalQueryHelper.USER_PREFIX)) {
					set_UserIdFromRicohGroup.addAll(MAP_TAXRES_RICOH_USERS.get(GlobalQueryHelper.USER_PREFIX));
			}
			// SJay - 08/06/2020 - Added a method to throw exceptions for CaseTriggerHelperTest
			if (Test.isRunningTest()) {
					throwTestException();
			}

			//Alex: if Case is Privacy Request record type, do not run any logic before insert
			setAgencyMapInformation();
			setAutoCloseValues();
			getCaseRecordTypeBehaviors();
			setCaseRecordTypeMap();

			for (Case c : cases) {
					User objCaseOwner;
					String strCompanyName = '';
					Case objParentCase = map_ParentCaseDetails?.get(c?.ParentId);
					if (c.OwnerId != null && String.valueOf(c.OwnerId).startsWith(CaseUtils.USER_ID_PREFIX)) {
							objCaseOwner = GlobalQueryHelper.getUserInfoById(c.OwnerId);
					}

					//setting update email status on case creation
					if (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES) {
							c.Email_Status__c = CaseUtils.EMAILSTATUS_OPEN;
							if (set_UserIdFromRicohGroup.Contains(UserInfo.getUserId())) {
									//
									c.Physical_Mail__c = true;
							}

							/**Electronic Notice logic to update Account, Contact, Subject, Origin fields*/
							if (c.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
									if (String.isBlank(c.AccountId) && String.isNotBlank(c.Company_ID__c) && map_CompanyIdAccounts.containsKey(c.Company_ID__c)) {
											Account objAccount = map_CompanyIdAccounts.get(c.Company_ID__c);
											strCompanyName = objAccount.Name;
											c.AccountId = objAccount.Id;
											if (objAccount.ZP_User_Roles__r?.size() > 0) {
													c.ContactId = objAccount.ZP_User_Roles__r[0].Contact__c;
											}
									} else if (String.isBlank(c.AccountId)) {
											c.AccountId = Label.FBED_Dummy_Account;
									} else if (String.isNotBlank(c.AccountId) && map_Accounts?.containsKey(c.AccountId)) {
											strCompanyName = map_Accounts.get(c.AccountId).Name;
									}

									c.Subject = CaseUtils.STR_FBED_SUBJECT + ' ' + strCompanyName + '.';
									//update origin of "All the child" cases if "Parent" case ORIGIN is 'Electronic Notice'
									if (c.ParentId != null && objParentCase?.Id != null && objParentCase.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE) {
											c.Origin = objParentCase.Origin;
									}
							}
					}

					//Ela: Added logic to collect the MF cases
					if (c.RecordTypeId != null && (recordTypeIdNameMap?.get(c.RecordTypeId)?.startsWith('MF') || set_EligibleSubmittedRecordTypes.contains(c.RecordTypeId))) {
							list_MFCases.add(c);
							if (String.isNotBlank(c.Carrier__c)) {
									set_CarrierIds.add(c.Carrier__c);
							}
					}

					//Ela: Convert Paroll care Auto Close Class 0 Cases WF
					if (c.RecordTypeId != null && c.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE && c.Status != CaseUtils.STATUS_CLOSED && c.Class__c == CaseUtils.CASE_CLASS_CLASS_0) {
							c.RecordTypeId = CaseUtils.RECTYPE_PAYROLL_CARE_READ_ONLY;
							c.Status = CaseUtils.STATUS_CLOSED;
							c.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_PAYROLL_CARE_AUTO_CLOSE);
					}

					// Update the WF Rule logic here "Update First Response Start Time <30"
					Boolean blnBasicIntegrationKey = String.isNotBlank(c.Integration_Key__c) && c.Integration_Key__c.contains(CaseUtils.STR_BASIC);
					if (
							c.Status == CaseUtils.STATUS_DRAFT &&
							c.RecordTypeId != null &&
							set_UpdateFRTRecordTypes.contains(c.RecordTypeId) &&
							String.isBlank(c.Historical_Data__c) &&
							!blnBasicIntegrationKey &&
							c.First_Response_Start_Time__c == null &&
							(c.Anticipated_Effective_Date__c <= System.today() + 30 ||
							c.Termination_Date__c <= System.today() + 30)
					) {
							c.Status = CaseUtils.STATUS_NEW;
							c.First_Response_Start_Time__c = System.now();
					}

					//update the WF rule field update logic "New Plan Case - Assign"
					if (
							c.RecordTypeId != null &&
							c.RecordTypeId == CaseUtils.RECTYPE_NEW_PLAN &&
							String.isBlank(c.Historical_Data__c) &&
							objCaseOwner != null &&
							objCaseOwner.Profile.Name == CaseUtils.TYPE_BENEFITS_CARE &&
							nameIdQueueMap != null &&
							nameIdQueueMap.containsKey(CaseUtils.QUEUE_NAME_NEWPLAN_BENEFITS_OPERATIONS)
					) {
							c.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_NEWPLAN_BENEFITS_OPERATIONS);
					}

					//Update the owner when the case is closed and risk assurance
					if (
							c.RecordTypeId != null &&
							(c.RecordTypeId == CaseUtils.RECTYPE_RISK_ASSURANCE ||
							c.RecordTypeId == CaseUtils.RECTYPE_RISK_ASSURANCE_READ_ONLY) &&
							c.Status == CaseUtils.STATUS_CLOSED &&
							objCaseOwner != null &&
							objCaseOwner.Name == CaseUtils.SYSTEM_USER &&
							nameIdQueueMap != null &&
							nameIdQueueMap.containsKey(CaseUtils.QUEUE_NAME_RISK_UNAUTHORIZED)
					) {
							c.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_RISK_UNAUTHORIZED);
					}

					//Pradeep: WFRule Migration, Vitals Expedite Case to Priority High
					if (
							CaseUtils.set_RenewInQueueRecordTypes.contains(c?.RecordTypeId) &&
							String.isNotBlank(c.Subject) &&
							c?.Subject?.contains(CaseUtils.STR_EXPEDITE) &&
							!objCurrentUser.Data_Migration_Validation__c
					) {
							c.Priority = CaseUtils.PRIORITY_HIGH;
					}

					//update case WF rule "Vitals Risk update to Closed from Solved	"
					if (
							c.RecordTypeId == CaseUtils.RECTYPE_RISK_ASSURANCE &&
							c.Status == CaseUtils.STATUS_SOLVED &&
							!objCurrentUser.Data_Migration_Validation__c &&
							set_AutoCloseRecordTypeIds.contains(c.RecordTypeId)
					) {
							c.Auto_Close_Date_Time__c = System.now().addDays(2);
					}

					// EOY Spot Check Changes
					if ((c.Origin == 'Email' || c.Origin == 'Payroll Care Email') && String.isNotBlank(c.Description) && String.isNotBlank(c.Description.substringBetween('id::{{', '}}'))) {
							c.Skip_Auto_Response__c = true;
					} else if (c.Origin == 'Phone' || (c.Origin == 'Gusto' && c.Channel__c == 'Phone')) {
							/**
							 * Author: Alex
							 * Date: 8/19/2020
							 * Desc: get IVR Routing Log based on Genesys Call Id
							 */
							list_PhoneCases.add(c);
					}
					String caseRecordType = cache.getRecordTypeName('Case', c.RecordTypeId);

					//only run this logic if the Case is not a Privacy Request
					if (caseRecordType != null && caseRecordType != 'Privacy Request') {
							c.Status_Change_Date_Time__c = System.now();
							setEntitlementId(c, caseRecordType);
							list_nonPrivacyCases.add(c);

							if (c.Origin == 'Email' || c.Origin == 'Payroll Care Email') {
									setZendeskTicketMap(c.Id, c.Description);
									c.Direction__c = 'Inbound';
							}
							// rolling back the changes made for  BTE-2907 due to cobra issue - BT-51228
							if (c.Origin == 'Cobra Email') {
									c.Direction__c = 'Inbound';
									c.Origin = 'Email';
									c.Type = 'Cobra';
							}

							/*
			Author: Alex
			Date: 5/28/2020
			Description: update to savings if MB Savings Email
			*/
							if (c.Origin == 'MB Savings Email') {
									c.Direction__c = 'Inbound';
									c.Origin = 'Email';
									c.Type = 'Savings';
							}

							// Moved the code from workflow as suggested by BS
							if (c.Origin == 'Gusto' && c.Subject != null && c.Subject.equalsIgnoreCase('Company Account Suspension Requested')) {
									c.Type = 'Payroll Suspension';
							}

							/*
				By: PR
				Date: 6/26/2018
				Description: what to set the case direction to Inbound if origin contains the word 'Email'
						in it.
			*/
							if (c.Origin != null && c.Origin.tolowercase().indexof('email') > -1 && c.Direction__c != 'Outbound') {
									c.Direction__c = 'Inbound';
							}

							/*
				By: Swati Arya
				Description: Auto Close the case when the subject contains Your one-time passcode to view the message for BYB Cases
			*/
							if (
									c.RecordTypeId == CaseUtils.RECTYPE_BYB &&
									map_AutoCloseSubjectMap != null &&
									map_AutoCloseSubjectMap.containskey(caseRecordType + '-' + c.Subject) &&
									map_AutoCloseSubjectMap.get(caseRecordType + '-' + c.Subject).Auto_Close__c &&
									c.Subject != null &&
									c.Subject.contains(CaseUtils.ONE_TIME_PASSCODE_SUBJECT)
							) {
									c.Status = CaseUtils.STATUS_CLOSED;
									c.Status_Detail__c = CaseUtils.INACTIONABLE_REQ_STATUS_DETAIL;
							}

							//check in custom setting for Email
							if (c.Origin != 'Email' && Label.Email_Subject_Routing_Address != null && c.Origin != null && Label.Email_Subject_Routing_Address.indexOf(c.Origin) > -1) {
									if (!map_PartialMatchAutoCloseSubject.isEmpty() && String.isNotBlank(c.Subject)) {
											Email_Subject_AutoClosed__c objAutoClosePartialMatchRec = getPartialMatchCustomSetting(c);
											if (objAutoClosePartialMatchRec?.Auto_Close__c) {
													c.Status = 'Closed';
													c.RecordTypeId = CaseUtils.RECTYPE_TAXRES_READ_ONLY;
											}

											if (
													objAutoClosePartialMatchRec.Queue_Name__c != null &&
													nameIdQueueMap.containsKey(objAutoClosePartialMatchRec.Queue_Name__c) &&
													nameIdQueueMap.get(objAutoClosePartialMatchRec.Queue_Name__c) != null
											) {
													c.OwnerId = nameIdQueueMap.get(objAutoClosePartialMatchRec.Queue_Name__c);
											}
									}

									if (map_AutoCloseSubjectMap.containskey(caseRecordType + '-' + c.Subject)) {
											//get custom settings
											Email_Subject_AutoClosed__c objAutoClose = map_AutoCloseSubjectMap.get(caseRecordType + '-' + c.Subject);
											String queueName = objAutoClose.Queue_Name__c;
											if (objAutoClose.Auto_Close__c) {
													c.Status = 'Closed';
											}
											if (objAutoClose.Confirm_Case_Reason__c != null) {
													c.Confirm_Case_Reason__c = objAutoClose.Confirm_Case_Reason__c;
											}

											if (nameIdQueueMap.containsKey(queueName)) {
													c.OwnerId = nameIdQueueMap.get(queueName);
											}
											c.Email_Subject_Routed__c = true;
									}
									c.Type = c.Origin.ReplaceAll(' Email', '');
									c.Origin = 'Email';
							}

							if (c.AccountId != null) {
									accIdSet.add(c.AccountId);
							}

							if (c.RecordTypeId == recordTypeNameIdMap.get('Benefits Care') && (String.isNotBlank(context) && Label.Cobra_Email.indexOf(context) == 0)) {
									c.Type = 'Cobra';
							}
							if (c.Routing_Case_Reason__c != null && c.Routing_Case_Reason__c != '') {
									c.Answer_IQ_Processed__c = 'Yes';
							}
					} else {
							if (c.Origin != CaseUtils.ORIGIN_WEB) {
									//Set the class to Class 2 for Risk team
									//set owner to privacy request queue
									c.Class__c = 'Class 2';
									c.OwnerId = nameIdQueueMap.get('Privacy_Request');
							}
					}

					if (
							c.Historical_Data__c == null && (c.SuppliedEmail == CaseUtils.NO_REPLY_GLIC && c.Subject == CaseUtils.GUARDIAN_BIZ_SUBJECT) ||
							(c.Subject == CaseUtils.AUTO_RESPONDER_SUBJECT && (c.RecordTypeId == CaseUtils.RECTYPE_RENEWAL || c.RecordTypeId == CaseUtils.RECTYPE_CHANGE)) ||
							(c.SuppliedEmail == CaseUtils.SBS_HUMANA &&
							c.Subject == CaseUtils.THANK_YOU_SUBJECT &&
							(c.RecordTypeId == CaseUtils.RECTYPE_RENEWAL ||
							c.RecordTypeId == CaseUtils.RECTYPE_CHANGE))
					) {
							c.Status = CaseUtils.STATUS_CLOSED;
					}

					recentQueueUpdate(c, null);
					if (
							c.RecordTypeId != null &&
							c.Origin != CaseUtils.ORIGIN_CHAT &&
							c.Origin != CaseUtils.ORIGIN_PHONE &&
							set_AnswerIQEligible.contains(c.RecordTypeId) &&
							!objCurrentUser?.Data_Migration_Validation__c &&
							c.SuppliedEmail != CaseUtils.ALEGEUS_FRESHDESK &&
							c.Status != CaseUtils.STATUS_CLOSED &&
							!c.Routed_through_Onboarding__c &&
							c.Routing_Case_Reason__c != CaseUtils.BENEFIT_REVERSAL_CASE_REASON &&
							c.Confirm_Case_Reason__c != CaseUtils.BENEFIT_REVERSAL_CASE_REASON
					) {
							c.Answer_IQ_Eligible__c = true;
					}
					updateTaxResOBMessageTrigger(c);
					stampSalesCasesChanges(c, null);
			}

			// Ela: MF Related field updates
			if (list_MFCases != null && !list_MFCases.isEmpty()) {
					updateMFCaseOwnerFields(list_MFCases, null);
					updateMFCaseFields(list_MFCases, null, set_CarrierIds);
			}

			mergeDuplicateCases(cases);

			initialize(cases);
			isAuthorizedUser(cases, objCurrentUser);
			if (!fromAgatha) {
					setCaseReasonId(cases, null);
			}

			setSubCaseReasonId(cases, null);

			setAgencyInformationOnCase(cases, null);
			closeDuplicateCases(cases);
			stopEmailToCaseLoop(cases);
			setSalesCaseCurrentStep(cases, null);

			Set<String> skipAutoResponseSet = getAutoResponseValues();
			for (Case c : cases) {
					if (c.RecordTypeId != recordTypeNameIdMap.get('Privacy Request')) {
							Account acc = new Account();
							Contact cnt = new Contact();

							if (c.RecordTypeId == cache.getRecordTypeId('Case', 'Benefits Care') && c.Type == 'Suspension Audit' && c.ContactId == null) {
									suspensionAuditCases.add(c);
							} else if (c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && c.Type == CaseUtils.BENEFITS_CASE_PILLAR && c.Routing_Case_Reason__c == CASE_ROUTING_REASON) {
									suspensionAuditCases.add(c);
							}

							if (c.Origin == 'Email') {
									setSkipAutoResponse(c, skipAutoResponseSet);
							}

							if (c.AccountId != null) {
									acc = map_Accounts?.get(c.AccountId);
									c.Tier_Created__c = acc?.Tier__c;
									c.VIP_Tier_Created__c = acc?.AM_Tier__c;
									c.CX_Experiment__c = acc?.CX_Experiment__c;
									c.Experiment_Pilot__c = String.valueOf(acc?.Experiment_Pilot__c);
							}

							if (c.contactId != null && map_Contacts != null && map_Contacts.containsKey(c.ContactId)) {
									cnt = map_Contacts.get(c.ContactId);
									if (cnt?.Account?.Experiment_Pilot__c != null) {
											c.Experiment_Pilot__c = String.valueOf(cnt.Account.Experiment_Pilot__c);
									}
							}

							SetEntitlementInfo(c);

							//DS[27-Oct-2020] : add PayrollOps Audit case Functionality
							if (set_AutoSolveRecordTypeIds.contains(c.RecordTypeId) || set_AutoCloseRecordTypeIds.contains(c.RecordTypeId)) {
									if (c.Status == CaseUtils.STATUS_AWAITING_RESPONSE && set_AutoSolveRecordTypeIds.contains(c.RecordTypeId)) {
											setAutoSolveDateTime(c);

											//reset Auto Close Date Time if Status is set to Awaiting Response again
											c.Auto_Close_Date_Time__c = null;
									}

									if (c.Status == 'Solved' && set_AutoCloseRecordTypeIds.contains(c.RecordTypeId)) {
											setAutoCloseDateTime(c);
									}

									if (c.Status != CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE) {
											if (c.Agency_Information__c != null && c.Status != CaseUtils.STATUS_CLOSED && c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE)) {
													String strAgencyName = agencyMap?.get(c.Agency_Information__c)?.Name;
													//Shyam: Boolean check for OCR TDNC for agency instead of Agency Name
													Boolean blnIsOCREnabledAgency = agencyMap?.get(c.Agency_Information__c)?.OCR_Enabled__c;
													Boolean blnOCRCheck = false;
													//Shyam: Added boolean flag for checking OCR agency instead of Agency Name

													//original logic AND (Non "Electronic Notice" Case OR "Electronic Notice" case and Not null contactId, non MRR and AccountId != dummy
													if (
															blnIsOCREnabledAgency &&
															String.isBlank(c.Baby_Case_Identifier__c) &&
															(c.Origin != CaseUtils.ORIGIN_ELECTRONIC_NOTICE ||
															(c.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE &&
															!c.Electronic_Notice_MRR__c &&
															c.AccountId != Label.FBED_Dummy_Account))
													) {
															blnOCRCheck = true;
													}

													if (blnOCRCheck) {
															c.Status = CASE_STATUS_READY_FOR_OCR_CAPTURE;
															c.OwnerId = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
															c.Type = CaseUtils.TYPE_TAX_RES;
													} else {
															c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
															c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
															c.Type = CaseUtils.TYPE_TAX_RES;
													}
											} else if (c.Status != CaseUtils.STATUS_CLOSED && c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE)) {
													c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
													c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
													c.Type = CaseUtils.TYPE_TAX_RES;
											}
									}
							}
							c.Description = c.Description;
							boolean hasBenefits = false;
							String careAccManager = '';
							if (acc?.id != null) {
									hasBenefits = acc.Has_Benefits__c;
									if (acc.Care_Account_Manager__c != null) {
											careAccManager = acc.Care_Account_Manager__c;
									}
							} else if (cnt.Id != null) {
									if (cnt.Account != null) {
											hasBenefits = cnt.Account.Has_Benefits__c;
											if (cnt.Account.Care_Account_Manager__c != null) {
													careAccManager = cnt.Account.Care_Account_Manager__c;
											}
									}
							}

							setCaseReadOnlyRecType(c);

							if (
									(c.Status == 'Closed' && c.Date_Time_Submitted__c == null) ||
									((c.Status == CaseUtils.STATUS_SOLVED ||
									c.Status == CaseUtils.STATUS_CLOSED) &&
									CaseUtils.set_DatTimeSolveRecordTypes.contains(c.RecordTypeId) &&
									!objCurrentUser.Data_Migration_Validation__c)
							) {
									c.Date_Time_Solved__c = System.now();
							}

							if (c.RecordTypeId == recordTypeNameIdMap.get('Payroll Transfer Case') && c.Origin == 'Email' && c.Direction__c == 'Inbound') {
									lst_PTEmailCase.add(c);
							}

							setAutomatedEmailSent(c);
					}
			}

			if (suspensionAuditCases.size() > 0) {
					populateAdminContactId(cases);
			}

			//By:PR, Date:7/10/19, Desc: calling methods to replace Inactive Owners with correct Queue
			updateInActiveOwners(cases);

			if (lst_PTEmailCase.size() > 0) {
					handleResellerEmailCaseForBMR(lst_PTEmailCase);
			}
			//@Neha Dabas, 22 April 2020, Case Routing for TaxRes
			handleEmailToCaseForCustomerResponses(cases);

			setTypeOnBORCarrierComm(cases);
			if (list_nonPrivacyCases.size() > 0) {
					updateCasePartnerSalesDetails(list_nonPrivacyCases);
			}

			/**
			 * Author: Alex
			 * Date: 8/19/2020
			 * Desc: Get IVR Routing Log based on Genesys Call Id
			 * if no IVR Routing Log found, use SuppliedPhone to search for contact and populate on Case
			 */
			getIVR(list_PhoneCases);
			gepCxCase(cases);
			updateCaseOwnerInformation(cases, null);
			setCaseOwnerWhenEmailSenderIsNBKC(cases);
	}

	public void processAfterInsert(Map<ID, Case> newCaseMap) {
			createCollectionsAfter(newCaseMap.values(), null);

			if (label.Modern_Bank_case_eligible_Complaint_Type_for_ticket_creation != null) {
					set_MBComplaintTypesForTicketCreation.addAll(Label.Modern_Bank_case_eligible_Complaint_Type_for_ticket_creation.split(','));
			}

			InsertCaseEmailLeadQueue(newCaseMap);

			List<Case_Audit_Log__c> logList = new List<Case_Audit_Log__c>();
			list<Case> suspensionAuditCaseList = new List<Case>();
			list<Case> lsiCaseList = new List<Case>();
			Set<Id> setAccountId = new Set<Id>();
			set<string> followUpCompletedIntegrationIdSet = new Set<string>();
			list<Id> lst_MBRecordsForTicketCreation = new List<Id>();
			List<Case> privacyRequestList = new List<Case>();
			//the email addresses from the newly created privacy requests
			List<String> list_EmailAddresses = new List<String>();
			//Alex: if we're inserting a Privacy Request, generate a 10 digit confirmation code
			//and append that to the Case's number then store in Confirmation_Code__c
			//send an email to the requester's email address with the link to the portal
			//along witn the confirmation code
			List<Case> privacyRequestsToUpdate = new List<Case>();
			List<Case> list_TaxResNewCases = new List<Case>();

			//the bodies of the emails we will send
			List<String> list_EmailBodies = new List<String>();

			//the subjects of the emails we will send
			List<String> list_EmailSubjects = new List<String>();

			//the emails to attach to the privacy requests
			List<EmailMessage> list_EmailsToAttach = new List<EmailMessage>();

			//BTE-4057: Check Entry Criteria To callout Email-AutoSolve AI using Mulesoft API in Queueable (Only runs for single record - After Insert)
			if (newCaseMap.values().size() == 1) {
					checkEmailAutoSolveAIProcess(newCaseMap.values().get(0));
			}

			for (Case c : newCaseMap.values()) {
					if (c.Origin != 'Phone' && c.Origin != 'Chat') {
							Case_Audit_Log__c log = getNewCaseAuditLog(c);
							logList.add(log);
					}
					if (c.Status == 'Closed') {
							closedCaseIdSetUponCreation.add(c.Id);
					}

					if (c.RecordTypeId == cache.getRecordTypeId('Case', 'Benefits Care') && c.Type == 'Suspension Audit') {
							suspensionAuditCaseList.add(c);
					} else if (c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && c.Type == CaseUtils.BENEFITS_CASE_PILLAR && c.Routing_Case_Reason__c == CASE_ROUTING_REASON) {
							suspensionAuditCaseList.add(c);
					}

					if (c.Large_Scale_Issue_Classification__c != null && c.AccountId != null) {
							lsiCaseList.add(c);
					}

					//BY:PR, Desc: HI Fulfillment Event Completed Date functionality
					if (
							c.Follow_Up_Completed_by__c != null &&
							c.Integration_Id__c != null &&
							(c.RecordTypeId == recordTypeNameIdMap.get('MF Audit') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Member/Group Updates') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF NHE') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF QLE') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Termination') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Viking Master') ||
							c.RecordTypeId == recordTypeNameIdMap.get('Member Fulfillment Emails'))
					) {
							followUpCompletedIntegrationIdSet.add(c.Integration_Id__c);
					}

					if (c.AccountId != null) {
							setAccountId.add(c.AccountId);
					}

					//By: PR, Date: 7/10/19, Desc: For "Modern Bank" if "Complaint Type" changes we want to create Ticket if not already exist
					if (c.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') && string.isNotBlank(c.Complaint_Type__c) && set_MBComplaintTypesForTicketCreation.contains(c.Complaint_Type__c)) {
							lst_MBRecordsForTicketCreation.add(c.id);
					}

					//Alex: add privacy requests to a list of Cases to update after insert
					if (c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request')) {
							privacyRequestList.add(c);
							list_EmailAddresses.add(c.Privacy_Requester_Email__c);
					}

					//setting update email status on case creation
					if (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES && c.Email_Status__c == CaseUtils.EMAILSTATUS_OPEN) {
							list_TaxResNewCases.add(c);
					}
			}
			if (logList.size() > 0) {
					insert logList;
			}

			if (suspensionAuditCaseList.size() > 0) {
					autoResponseEmailForSuspensionAuditCases(suspensionAuditCaseList);
			}

			if (lsiCaseList.size() > 0) {
					createAccountLSIRecords(lsiCaseList);
			}

			//BY:PR, Desc: HI Fulfillment Event Completed Date functionality
			if (followUpCompletedIntegrationIdSet.size() > 0) {
					populateFulfillmentEventCompletedDate(followUpCompletedIntegrationIdSet);
			}

			//By:PR, Date:7/10/19, Desc: Calling Ticket creation method is we have some eligible MB cases
			if (lst_MBRecordsForTicketCreation.size() > 0) {
					createTicketForMBComplaint(lst_MBRecordsForTicketCreation);
			}

			if (list_TaxResNewCases.size() > 0) {
					createTaxResAuditLogs(list_TaxResNewCases, CaseUtils.EMAIL_STATUS_CHANGE, false, false);
			}

			updateLeadContactEngagementBiz(newCaseMap.values());

			Map<String, Case> map_EmailAndParentCase = CaseQueryHelper.getDuplicatePrivacyRequests(list_EmailAddresses);

			for (Case privacyRequest : privacyRequestList) {
					//if this is a duplicate, mark it as closed and send an email saying a case was already created
					//and to contact privacy@gusto.com, don't send a confirmation code
					Case parentCase = map_EmailAndParentCase.get(privacyRequest.Privacy_Requester_Email__c);

					Case c = new Case(Id = privacyRequest.Id);

					//the email body
					String strEmailBody = '';
					//the email to add to the case's email related list
					EmailMessage emailMsg = new EmailMessage();

					//if the case we're inserting is a duplicate (there is a parent case id)
					//then set the Status to Closed and tell the requester to contact an email address for help
					//else generate a confirmation code and send it along with login address
					if (parentCase != null && parentCase.Id != privacyRequest.Id) {
							//if parent is not closed, then mark the duplicate as closed
							if (parentCase.IsClosed == false) {
									c.Status = 'Closed';
							}

							c.ParentId = parentCase.Id;
							emailMsg.Subject = 'Duplicate California Consumer Privacy Act request';
							strEmailBody = '<html><body>This email address is already associated with an open request that has been submitted through Gusto\'s California Consumer Privacy Act Request Portal.';
							strEmailBody += '</body></html>';
					} else {
							String strConfirm = generateConfirmationCode(privacyRequest);
							c.Confirmation_Code__c = strConfirm;

							emailMsg.Subject = 'Your California Consumer Privacy Act Request Portal confirmation code';
							strEmailBody = '<html><body>You recently initiated a request through Gusto\'s California Consumer Privacy Act Request Portal. <br/>';
							strEmailBody += 'Here is your confirmation code: ' + strConfirm + '<br/><br/>';
							strEmailBody +=
									'Please log in to the California Consumer Privacy Act Request Portal <a href="' +
									Label.Privacy_Request_Site_URL +
									'">here</a> to complete and submit your request. Please note that we are required by law to verify your identity before we can process your request.';
							strEmailBody += '</body></html>';
					}

					privacyRequestsToUpdate.add(c);
					list_EmailBodies.add(strEmailBody);
					list_EmailSubjects.add(emailMsg.Subject);
					emailMsg.FromAddress = 'no-reply@gusto.com';
					emailMsg.ToAddress = privacyRequest.Privacy_Requester_Email__c;
					emailMsg.ParentId = privacyRequest.Id; //Attach with the case
					emailMsg.MessageDate = System.now();
					emailMsg.Status = '3';
					list_EmailsToAttach.add(emailMsg);
			}

			try {
					update privacyRequestsToUpdate;
					sendPrivacyRequestEmail(list_EmailAddresses, list_EmailBodies, list_EmailSubjects);
					insert list_EmailsToAttach;
			} catch (Exception e) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'OnAfterInsert', e.getMessage(), e.getStackTraceString());
			}

			updateAccLeadActivityDate(newcasemap.values());
			autoCloseGEPCXLeakageCases(newcasemap.values());
			updatePartnerAccount(newcasemap.values());
	}

	public void processBeforeUpdate(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			createCollectionsBefore(newCaseMap.values(), null);
			counter++;
			TaxResCaseHelper objHelper = new TaxResCaseHelper();
			set<id> accIdSet = new Set<id>();
			list<Case> lst_PTEmailCase = new List<Case>();
			Group phoneRoutingGroupObj = new Group();
			Group objGroupPayrollCareNonActionable = new Group();
			List<Case> list_nonPrivacyCases = new List<Case>();
			//Specialist round-robin variables
			List<Case> list_SpecialistAssignmentEligibleCases = new List<Case>();
			Set<String> set_oldSpecialistIds = new Set<String>();
			List<Case> list_SMSCases = new List<Case>();
			Map<String, Group> map_QueuesByName = new Map<String, Group>();
			list<Case> list_SolvedCasesForPhoneUpdate = new List<Case>();
			Map<Id, Case> map_OCRProcessedCases = new Map<Id, Case>();
			List<Case> list_MFCases = new List<Case>();
			Map<Id, Case> map_MFOldCases = new Map<Id, Case>();
			Set<Id> set_CarrierIds = new Set<Id>();
			Map<Id, Case> map_OCRProcessedCasesToOwnerUpdate = new Map<Id, Case>();
			getCaseRecordTypeBehaviors();
			setAgencyMapInformation();
			if (map_CaseReasonsById == null || map_CaseReasonsById.isEmpty()) {
					setCaseReasonClassification();
			}
			//Users who cannot re-open cases
			Set<String> set_IntegrationUsers = new Set<String>{ CaseUtils.SYSTEM_USER, CaseUtils.WORKATO_USER, CaseUtils.BIZTECH_INTEGRATION_USER, CaseUtils.API_HEROKU_USER };

			/*
			 * Neha Dabas, 27th March 2020
			 * Copy Action_Required__c from Case to Ticket if Case is of Record Type is Benefits New Plan Case
			 */
			Set<Id> set_CaseWithActionRequiredTrue = new Set<Id>();

			setCaseRecordTypeMap();

			List<Group> list_OfQueueGroup = GlobalQueryHelper.getGroupsByType('queue');
			User objCurrentUser = GlobalQueryHelper.getUserInfoById(UserInfo.getUserId());

			if (list_OfQueueGroup.size() > 0) {
					for (Group objGroup : list_OfQueueGroup) {
							map_QueuesByName.put(objGroup.DeveloperName, objGroup);
							if (objGroup.DeveloperName == 'Phone_Routing') {
									phoneRoutingGroupObj = objGroup;
							}
							if (objGroup.DeveloperName == 'Payroll_Care_Non_Actionable') {
									objGroupPayrollCareNonActionable = objGroup;
							}
					}
			}

			for (Case c : newCaseMap.values()) {
					Case oldCase = oldCaseMap.get(c.Id);
					String strAgencyName = agencyMap?.get(c.Agency_Information__c)?.Name;
					//Shyam: Boolean check for Autosolve flag for agency instead of Agency Name
					Boolean blnIsAutosolveEnabled = agencyMap?.get(c.Agency_Information__c)?.AutoSolve_Enabled__c;
					Case objParentCase = map_ParentCaseDetails?.get(c?.ParentId);

					// When case is routed to GEP CX set default status New
					if (c.RecordTypeId != null && c.RecordTypeId != oldCase.RecordTypeId && c.RecordTypeId == CaseUtils.RECTYPE_GEP_CX) {
							c.Status = CaseUtils.STATUS_NEW;
					}

					//Added below logic to throw Error when Realted Sub Reason is not popualted on Record
					if (
							context != 'AutoUpdateCaseStatusBatch' &&
							c.RecordTypeId != null &&
							c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT &&
							c.Status != oldCase.Status &&
							c.Status == CaseUtils.STATUS_CLOSED &&
							String.isNotBlank(c.Confirm_Case_Reason_Classification__c) &&
							String.isBlank(c.Confirm_Sub_Case_Reason_Classification__c) &&
							map_SubCaseReasons.get(c.Confirm_Case_Reason_Classification__c) != null &&
							map_SubCaseReasons.containskey(c.Confirm_Case_Reason_Classification__c)
					) {
							c.adderror('Sub Case Reason is required');
					}
					//Updating Case Type and Support Level on case from case reason classification
					if (
							c.RecordTypeId != null &&
							c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT &&
							c.Status != oldCase.Status &&
							c.Status == CaseUtils.STATUS_CLOSED &&
							String.isNotBlank(c.Confirm_Case_Reason_Classification__c) &&
							map_CaseReasonsById.containskey(c.Confirm_Case_Reason_Classification__c) &&
							(c.Type != map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Case_Type_Pillar__c ||
							c.Support_Level__c != map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Support_Level__c)
					) {
						c.Type = String.isNotBlank(map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Case_Type_Pillar__c) 
							? map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Case_Type_Pillar__c
							: c.Type;
						c.Support_Level__c = String.isNotBlank(map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Support_Level__c)
							? map_CaseReasonsById.get(c.Confirm_Case_Reason_Classification__c).Support_Level__c
							: c.Support_Level__c;
					}

					//BBO-2154: Update Closed By for Engagement closed case
					if (
						c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT &&
						c.Closed_By__c != UserInfo.getUserId() &&
						c.Status != oldCase.Status &&
						c.Status == CaseUtils.STATUS_CLOSED) {
						c.Closed_By__c = UserInfo.getUserId();
					}


					//Ela: Added logic to collect the MF cases
					if (c.RecordTypeId != null && (recordTypeIdNameMap?.get(c.RecordTypeId)?.startsWith('MF') || set_EligibleSubmittedRecordTypes.contains(c.RecordTypeId))) {
							list_MFCases.add(c);
							map_MFOldCases.put(oldCase.Id, oldCase);
							if (String.isNotBlank(c.Carrier__c)) {
									set_CarrierIds.add(c.Carrier__c);
							}
					}

					//Alex: run this logic only if the Case is not a privacy request
					if (c.RecordTypeId != recordTypeNameIdMap.get('Privacy Request')) {
							list_nonPrivacyCases.add(c);
							if (c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) && c.OwnerId == TAXRES_AUTO_CLOSE_QUEUE_ID && c.OwnerId != oldCase.OwnerId) {
									c.Status = 'Closed';
							}

							if (playmode == true) {
									String ownerId = oldCase.OwnerId;
									if (ownerId.indexOf('00G') < 0) {
											c.addError('Case is already assigned');
									}
							}
							if (playmode_caseRouting == true) {
									if (oldCase.isCaseInPlay__c) {
											c.addError('Case is already in-process.');
									}
							}

							// Moved the code from workflow as suggested by BS
							if (
									(c.Origin != oldCase.Origin && c.Origin == 'Gusto') &&
									(c.Subject != oldCase.Subject &&
									c.Subject != null &&
									c.Subject.equalsIgnoreCase('Company Account Suspension Requested'))
							) {
									c.Type = 'Payroll Suspension';
							}

							if (c.AccountId != null) {
									accIdSet.add(c.AccountId);
							}

							if (c.Routing_Case_Reason__c != null && c.Routing_Case_Reason__c != '' && c.Routing_Case_Reason__c != oldCase.Routing_Case_Reason__c) {
									c.Answer_IQ_Processed__c = 'Yes';
							}
							c.Case_Updated__c = System.now();
							String userName = userInfo.getName();
							if (c.Shared_With__c == 'ApIntego' && oldCase.Shared_With__c != 'ApIntego' && userName.toLowerCase().indexOf('workato') < 0) {
									c.Shared_By__c = userName;
							}

							// we are saving the date/time when Case gets assigned to a User for the first time.
							if (
									c.OwnerId != oldCase.OwnerId &&
									string.valueof(oldCase.OwnerId).IndexOf('00G') == 0 &&
									string.valueof(c.OwnerId).indexOf('005') == 0 &&
									c.Date_Time_Assigned_to_User__c == null
							) {
									c.Date_Time_Assigned_to_User__c = system.now();
							}

							if (c.OwnerId != oldCase.OwnerId && (c.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') || c.RecordTypeId == recordTypeNameIdMap.get('Benefits Care'))) {
									c.Internal_Support_Requested_From__c = null;
							}

							/*By: PR, Date: Aug,14,19
			if origin is phone,owner is phone routing and status is solved or confirm case reason is changed for the first time
			then update the case owner field with logged in user*/
							if (phoneRoutingGroupObj.Id != null) {
									if (
											(c.Origin == 'Phone' || (c.Origin == 'Gusto' && c.Channel__c == 'Phone')) &&
											c.Direction__c == 'Inbound' &&
											c.OwnerId == phoneRoutingGroupObj.Id &&
											(((c.RecordTypeId != CaseUtils.RECTYPE_ENGAGEMENT && c.Status == CaseUtils.STATUS_SOLVED) ||
											(c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && c.Status == CaseUtils.STATUS_CLOSED) && c.Status != oldCase.Status) ||
											(c.Confirm_Case_Reason__c != null &&
											oldCase.Confirm_Case_Reason__c == null))
									) {
											c.OwnerId = UserInfo.getUserId();
									}
							}
							/*
			Author: Alex
			Date: 4/28/2020
			if case is not owned by a user (in the phone routing queue)
			case type = Phone
			and owner id has not been changed
			then owner = current user
			*/
							if (
									Label.PhoneANI_Update == 'true' &&
									strLaunchedFrom == 'PhoneANI' &&
									(c.Origin == 'Phone' || (c.Origin == 'Gusto' && c.Channel__c == 'Phone')) &&
									c.Direction__c == 'Inbound'
							) {
									c.OwnerId = UserInfo.getUserId();
							}
					}
					// If case is of type Benefits New Plan and Requires Action is set to true
					if (c.RecordTypeId == recordTypeNameIdMap.get('Benefits New Plan Case') && c.Requires_Action__c && !oldCase.Requires_Action__c) {
							set_CaseWithActionRequiredTrue.add(c.Id);
					}

					//If Case is of Renewal type and Automated RFI Flow is false
					if (c.RecordTypeId == CaseUtils.RECTYPE_RENEWAL && c.Automated_RFI_Flow__c == false && c.Automated_RFI_Flow__c != oldCase.Automated_RFI_Flow__c) {
							set_CaseWithActionRequiredTrue.add(c.Id);
					}

					if (
							c.Origin == 'Phone' &&
							oldCase.Status != 'Closed' &&
							oldCase.Status != 'Solved' &&
							set_ConfirmReasonReadOnlyRecordTypes.contains(c.RecordTypeId) &&
							(c.Status == 'Solved' ||
							c.Status == 'Closed') &&
							(c.OwnerId == phoneRoutingGroupObj.Id ||
							c.OwnerId == objGroupPayrollCareNonActionable.Id)
					) {
							c.Confirm_Case_Reason__c = 'No Action Required';
					}

					if (oldCase.Status != c.Status) {
							processStatusChange = true;
					}

					if (oldCase.Status != c.Status && c.Status == 'Solved' && c.Opt_Out_Updating_Phone__c == false) {
							list_SolvedCasesForPhoneUpdate.add(c);
					}

					if (oldCase.OwnerId != c.OwnerId && !c.IsClosed && !objCurrentUser.Data_Migration_Validation__c) {
							if (
									(c.OwnerId != UserInfo.getUserId() || String.valueOf(c.OwnerId).startsWith(CaseUtils.QUEUE_ID_PREFIX)) &&
									String.valueOf(oldCase.OwnerId).startsWith(CaseUtils.USER_ID_PREFIX) &&
									CaseUtils.set_ReopenInQueueRecordTypes.contains(oldCase.RecordTypeId) &&
									c.Type != CaseUtils.TYPE_COBRA &&
									oldCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES &&
									!set_IntegrationUsers.contains(objCurrentUser.Name)
							) {
									c.Status = c.RecordTypeId == CaseUtils.RECTYPE_MODERN_BANK ? CaseUtils.STATUS_ACTIVE : CaseUtils.STATUS_OPEN;
							}

							if (
									String.isNotBlank(c.RecordTypeId) &&
									CaseUtils.set_RenewInQueueRecordTypes.contains(c.RecordTypeId) &&
									!String.valueOf(c.OwnerId).startsWith(CaseUtils.QUEUE_ID_PREFIX)
							) {
									c.Status = CaseUtils.STATUS_OPEN;
							}
					}

					String strOwnerId = String.valueOf(c.OwnerId);

					if (
							CaseUtils.set_RenewInQueueRecordTypes.contains(c.RecordTypeId) &&
							!c.IsClosed &&
							c.OwnerId != oldCase.OwnerId &&
							strOwnerId.startsWith(CaseUtils.QUEUE_ID_PREFIX) &&
							!objCurrentUser.Data_Migration_Validation__c
					) {
							c.Status = CaseUtils.STATUS_NEW;
					}

					recentQueueUpdate(c, oldCase);
					updateTaxResOBMessageTrigger(c);
					

					// If OCR is success we process the case and create manual TNDC and/or baby cases
					if (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES && c.Status == CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE && c.Status != oldCase.Status) {
							if (c.Electronic_Notice_MRR__c) {
									c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
									c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
									c.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_FAILED;
							} else {
									map_OCRProcessedCases.put(c.Id, c);
							}
					}

					if (
							c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT &&
							c.IsEscalated != oldCase.IsEscalated &&
							c.IsEscalated &&
							map_QueuesByName.containsKey(CaseUtils.QUEUE_ENGAGEMENT_ESCALATIONS) &&
							c.Status != CaseUtils.STATUS_CLOSED
					) {
							c.OwnerId = map_QueuesByName.get(CaseUtils.QUEUE_ENGAGEMENT_ESCALATIONS).Id;
					}

					//update origin of "All the child" cases if "Parent" case ORIGIN is 'Electronic Notice'
					// INDEXING LOGIC STARTS
					Map<String, String> map_MRRReasonIndexingStatus = GlobalQueryHelper.getMRRReasonIndexingStatusMap();
					
					if (
						c.RecordTypeId == CaseUtils.RECTYPE_TAXRES &&
						//c.OCR_Status__c == CaseUtils.STR_IB_SUCCESS_STATUS &&
						c.Status == CaseUtils.CASE_STATUS_OCR_CAPTURE_COMPLETE &&
						c.Status != oldCase.Status
					) {
						if (c.Electronic_Notice_MRR__c) {
							c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
							c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
							c.Is_OCR_Processed__c = true;
							c.OCR_Message__c = c.Automation_Message_Details__c;
							c.OCR_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
								
							if(String.isNotBlank(c.Automation_Message_Details__c) && map_MRRReasonIndexingStatus != null && map_MRRReasonIndexingStatus.containsKey(c.Automation_Message_Details__c)) {
								c.Auto_Indexing_Status__c = map_MRRReasonIndexingStatus.get(c.Automation_Message_Details__c);
							} else {
								c.Auto_Indexing_Status__c = TaxResIDPNoticeController.AUTO_INDEX_STATUS_FAILED;
							}
						} else {
							map_OCRProcessedCases.put(c.Id, c);
						}
					}

					//update origin of "All the child" cases if "Parent" case ORIGIN is 'Electronic Notice'
					if (
							c.RecordTypeId == CaseUtils.RECTYPE_TAXRES &&
							oldCase.ParentId != c.ParentId &&
							c.ParentId != null &&
							objParentCase?.Id != null &&
							objParentCase.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE
					) {
							c.Origin = objParentCase.Origin;
					}
			}

			Map<Id, String> map_OCRTriggerdCaseIdWithRelevantCases = new Map<Id, String>();
			// Calling processOCRTNDCRecords for successfully OCR'd Tax Res cases
			if (map_OCRProcessedCases?.size() > 0) {            
				map_OCRTriggerdCaseIdWithRelevantCases = objHelper.getAllTNDCGrouping(map_OCRProcessedCases);
			}

			// Ela: MF Related field updates
			if (list_MFCases != null && !list_MFCases.isEmpty()) {
					updateMFCaseOwnerFields(list_MFCases, map_MFOldCases);
					updateMFCaseFields(list_MFCases, map_MFOldCases, set_CarrierIds);
			}

			setSalesCaseCurrentStep(newCaseMap.values(), oldCaseMap);
			setBusinessDay(oldCaseMap, newCaseMap);
			if (!fromAgatha) {
					setCaseReasonId(newCaseMap.values(), oldCaseMap);
			}

			setSubCaseReasonId(newCaseMap.values(), oldCaseMap);

			processStatusChangeRecType(oldCaseMap, newCaseMap);
			if (counter == 1 || processStatusChange == true) {
					processStatusChangeAuditLog(oldCaseMap, newCaseMap);
			}

			setAgencyInformationOnCase(newCaseMap.values(), oldCaseMap);

			if (list_SolvedCasesForPhoneUpdate.size() > 0) {
					updateCaseContactPhoneDetails(list_SolvedCasesForPhoneUpdate);
			}

			// contains solved cases for which trigger has fired
			list<Case> list_solvedCases = new List<Case>();
			Id idUserId = UserInfo.getUserId();
			User objUserDetails = GlobalQueryHelper.queryActiveUsers(new Set<Id>{ idUserId })?.get(idUserId);

			for (case c : newCaseMap.values()) {
					String strAgencyName = agencyMap?.get(c.Agency_Information__c)?.Name;
					//Shyam: Boolean check for OCR TDNC for agency instead of Agency Name
					Boolean blnIsOCREnabledAgency = agencyMap?.get(c.Agency_Information__c)?.OCR_Enabled__c;
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (c.RecordTypeId != recordTypeNameIdMap.get('Privacy Request')) {
							Case oldCase = new Case();
							if (oldCaseMap.containsKey(c.Id)) {
									oldCase = oldCaseMap.get(c.Id);
							}

							String strProfileName = String.isNotBlank(objUserDetails.Profile.Name) ? objUserDetails.Profile.Name : '';
							blnIsVendorCXUser = strProfileName.containsIgnoreCase(CaseUtils.PROFILE_VENDOR_CX_USER);

							if (oldCase != null && c.RecordTypeId != oldCase.RecordTypeId && c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && !blnIsVendorCXUser) {
									c.Case_In_Route__c = true;
									c.OwnerId = map_QueuesByName.get(CaseUtils.QUEUE_NAME_ENGAGEMENT_CASES).Id;
							}

							if (oldCase != null && c.RecordTypeId != oldCase.RecordTypeId && c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && blnIsVendorCXUser) {
									if (c.Status == CaseUtils.STATUS_ACTIVE) {
											c.Status = CaseUtils.STATUS_NEW;
									} else {
											c.Status = CaseUtils.STATUS_IN_PROGRESS;
									}
							}

							if (
									oldCase != null &&
									c.OwnerId != oldCase.OwnerId &&
									map_QueuesByName.containsKey(CaseUtils.QUEUE_NAME_ENGAGEMENT_CASES) &&
									c.OwnerId == map_QueuesByName.get(CaseUtils.QUEUE_NAME_ENGAGEMENT_CASES).Id
							) {
									c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
							}

							Account acc = map_Accounts.get(c.AccountId);
							if (
									c.Is_Customer__c == false &&
									c.RecordTypeId != null &&
									oldCase.RecordTypeId != null &&
									cache.getRecordTypeName('Case', c.RecordTypeId)?.IndexOf('Sales Cases') < 0 &&
									cache.getRecordTypeName('Case', oldCase.RecordTypeId)?.IndexOf('Sales Cases') > -1
							) {
									c.Is_Customer__c = true;
							}
							if (c.AccountId != oldCase.AccountId && c.AccountId != null && acc != null) {
									c.Tier_Created__c = acc.Tier__c;
									c.VIP_Tier_Created__c = acc.AM_Tier__c;
									c.CX_Experiment__c = acc.CX_Experiment__c;
							}
							if (
									c.AccountId != null &&
									c.Status != oldCase.Status &&
									(c.Status == 'Solved' || (c.Status == 'Closed' && c.Tier_Created__c == null && c.VIP_Tier_Created__c == null)) &&
									acc != null
							) {
									c.Tier_Solved__c = acc.Tier__c;
									c.VIP_Tier_Solved__c = acc.AM_Tier__c;
							}
							if (
									(c.OwnerId != oldCase.OwnerId ||
									c.Latest_Customer_Response_Date_Time__c != oldCase.Latest_Customer_Response_Date_Time__c) &&
									c.OwnerId == Label.VIP_Partner_QueueId &&
									acc != null
							) {
									if (acc.Care_Account_Manager__c != null) {
											if (acc.Care_Account_Manager__r.Out_Of_office__c == false && acc.Care_Account_Manager__r.IsActive == true) {
													c.OwnerId = acc.Care_Account_Manager__c;
											}
									}
							}
							if (c.First_Response_Time__c != null && c.BusinessHoursId != null && oldCase.First_Response_Time__c != c.First_Response_Time__c) {
									c.Time_To_First_Response_Hours__c = (Decimal) (c.First_Response_Time__c.getTime() - c.CreatedDate.getTime()) / (1000 * 60 * 60);
							}

							if (
									((c.Status == CaseUtils.STATUS_SOLVED && oldCase.Status != CaseUtils.STATUS_SOLVED) ||
									(c.Status == CaseUtils.STATUS_CLOSED &&
									c.Date_Time_Solved__c == null)) && CaseUtils.set_DatTimeSolveRecordTypes.contains(oldCase.RecordTypeId)
							) {
									c.Date_Time_Solved__c = System.now();
							}

							if (c.RecordTypeId == CaseUtils.R_D_TAX_CREDITS && c.Date_Time_Solved__c != null && c.BusinessHoursId != null && oldCase.Date_Time_Solved__c != c.Date_Time_Solved__c) {
									Integer intNonWorkingDays = Utils.getNumberOfNonWorkingDays(c.CreatedDate.date(), c.Date_Time_Solved__c.date());
									c.Time_To_Resolution_Hours__c = (Decimal) (c.Date_Time_Solved__c.getTime() - c.CreatedDate.getTime()) / (1000 * 60 * 60);
									if (intNonWorkingDays > 0) {
											c.Time_To_Resolution_Hours__c = c.Time_To_Resolution_Hours__c - (24 * intNonWorkingDays);
									}
							} else if (c.Date_Time_Solved__c != null && c.BusinessHoursId != null && oldCase.Date_Time_Solved__c != c.Date_Time_Solved__c) {
									c.Time_To_Resolution_Hours__c = (Decimal) (c.Date_Time_Solved__c.getTime() - c.CreatedDate.getTime()) / (1000 * 60 * 60);
							} else if (c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && c.Status == CaseUtils.STATUS_CLOSED && c.BusinessHoursId != null && oldCase.Status != c.Status) {
									c.Time_To_Resolution_Hours__c = (Decimal) (System.now().getTime() - c.CreatedDate.getTime()) / (1000 * 60 * 60);
							}  else if (c.RecordTypeId == CaseUtils.RECTYPE_CLIENT_RELATIONS && c.Status == CaseUtils.STATUS_CLOSED && c.BusinessHoursId != null && oldCase.Status != c.Status) {
								c.Time_To_Resolution_Hours__c = (Decimal) (System.now().getTime() - c.CreatedDate.getTime()) / (1000 * 60 * 60);
						    }

							if (c.AccountId != oldCase.AccountId || c.RecordTypeId != oldCase.RecordTypeId) {
									SetEntitlementInfo(c);
							}
							//DS[27-Oct-2020] : add PayrollOps Audit case Functionality
							if (
									((c.Status != oldCase.Status) || (c.Last_out_bound_email__c != oldCase.Last_out_bound_email__c)) &&
									(((c.Status == CaseUtils.STATUS_AWAITING_RESPONSE || c.Status == 'Solved') &&
									(set_AutoSolveRecordTypeIds.contains(c.RecordTypeId) || set_AutoCloseRecordTypeIds.contains(c.RecordTypeId))) ||
									(c.Status == CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT && set_AutoInProgressRecordTypeIds.contains(c.RecordTypeId)))
							) {
									/* Description: calling setAutoCloseDateTime for engagement and payroll care record type
									 *             if case is in 'Awaiting Response' status for more than 10 days*/
									if (
											c.Status == CaseUtils.STATUS_AWAITING_RESPONSE &&
											set_AutoCloseRecordTypeIds.contains(c.RecordTypeId) &&
											(c.recordTypeId == CaseUtils.RECTYPE_ENGAGEMENT ||
											c.recordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE)
									) {
											intClosingDays = (Label.EngagementAutoCloseDays != null) ? Integer.valueOf(Label.EngagementAutoCloseDays) : 2;
											setAutoCloseDateTime(c, intClosingDays);
									} else {
											if (c.Status == CaseUtils.STATUS_AWAITING_RESPONSE && set_AutoSolveRecordTypeIds.contains(c.RecordTypeId)) {
													setAutoSolveDateTime(c);

													//reset Auto Close Date Time if Status is set to Awaiting Response again
													c.Auto_Close_Date_Time__c = null;
											}

											if (
													c.Status == CaseUtils.STATUS_AWAITING_INTERNAL_SUPPORT &&
													set_AutoInProgressRecordTypeIds.contains(c.RecordTypeId) &&
													c.recordTypeId == CaseUtils.RECTYPE_ENGAGEMENT
											) {
													if (c.Internal_Support_Requested_From__c == CaseUtils.ENGAGEMENT_PARKED || c.Internal_Support_Requested_From__c == CaseUtils.CAPTAIN_SME) {
															c.Follow_Up_Date_Time__c = Utils.nextBusinessHoursDateTime();
													} else if (
															c.Internal_Support_Requested_From__c != CaseUtils.ENGAGEMENT_PARKED &&
															c.Internal_Support_Requested_From__c != CaseUtils.CAPTAIN_SME &&
															c.OwnerId == UserInfo.getUserId() &&
															!objCurrentUser.Data_Migration_Validation__c
													) {
															setAutoInProgressDateTime(c, 5);
													}
											}
											if (c.Status == 'Solved' && set_AutoCloseRecordTypeIds.contains(c.RecordTypeId) && c.recordTypeId != CaseUtils.RECTYPE_PAYROLL_CARE) {
													setAutoCloseDateTime(c);
											}
									}
							}

							//update case WF rule "Vitals Risk update to Closed from Solved	"
							if (
									(c.RecordTypeId != oldCase.RecordTypeId ||
									c.Status != oldCase.Status) &&
									c.RecordTypeId == CaseUtils.RECTYPE_RISK_ASSURANCE &&
									c.Status == CaseUtils.STATUS_SOLVED &&
									!objCurrentUser.Data_Migration_Validation__c &&
									set_AutoCloseRecordTypeIds.contains(c.RecordTypeId)
							) {
									c.Auto_Close_Date_Time__c = System.now().addDays(2);
							}

							if (
									c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
									c.Status != oldCase.Status &&
									c.Status == CASE_STATUS_SOLVED &&
									oldCase.Status == CASE_STATUS_AWAITING &&
									string.isBlank(c.Customer_Journey__c)
							) {
									c.Customer_Journey__c = CONFIRM_CASE_REASON;
							}

							if (
									c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
									c.Origin == CaseUtils.ORIGIN_ELECTRONIC_NOTICE &&
									c.IsClosed == false &&
									oldCase.AccountId != c.AccountId &&
									oldCase.AccountId == Label.FBED_Dummy_Account
							) {
									c.Subject = CaseUtils.STR_FBED_SUBJECT + ' ' + acc.Name + '.';
							}

							//move the case to manual index when the agency is updated fom OCR to non OCR
							if (!c.Is_OCR_Processed__c && c.Agency_Information__c != oldCase.Agency_Information__c && blnIsOCREnabledAgency && c.Status == CASE_STATUS_READY_FOR_DATA_CAPTURE) {
								c.Status = CASE_STATUS_READY_FOR_OCR_CAPTURE;
								c.OwnerId = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
							}
							//move the case to OCR queue when the agenc is updated from non OCR to OCR
							if (!c.Is_OCR_Processed__c && c.Agency_Information__c != oldCase.Agency_Information__c && oldCase.Agency_Information__c != null && !blnIsOCREnabledAgency && c.Status == CASE_STATUS_READY_FOR_OCR_CAPTURE) {
								c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
								c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
							}

							if (c.Status != CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE) {
									if (
											(oldCase.RecordTypeId != recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
											c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
											c.Agency_Information__c != null) ||
											(oldCase.Agency_Information__c == null &&
											c.Agency_Information__c != null &&
											c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
											String.isBlank(oldCase.Agency_Info_Agatha__c) &&
											String.isNotBlank(c.Agency_Info_Agatha__c) &&
											c.Status == CASE_STATUS_READY_FOR_DATA_CAPTURE)
									) {
											// when case is moved to tax res type, assign it to ocr queue if the case is previously not ocr processed
											if (blnIsOCREnabledAgency && String.isBlank(c.Baby_Case_Identifier__c)) {
													//Shyam: Added OCR enabled check flag
													if (!c.Is_OCR_Processed__c) {
															c.Status = CASE_STATUS_READY_FOR_OCR_CAPTURE;
															c.OwnerId = CaseUtils.TAXRES_OCR_CAPTURE_QUEUE_ID;
															c.Type = CaseUtils.TYPE_TAX_RES;
													} else {
															map_OCRProcessedCasesToOwnerUpdate.put(c.Id, c);
													}
											} else {
													c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
													c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
													c.Type = CaseUtils.TYPE_TAX_RES;
											}
									} else if (oldCase.RecordTypeId != recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) && c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE)) {
											c.Status = CASE_STATUS_READY_FOR_DATA_CAPTURE;
											c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
											c.Type = CaseUtils.TYPE_TAX_RES;
									}
							}

							if (c.Status != oldCase.Status) {
									setCaseReadOnlyRecType(c);
							}

							// filtering all the recently solved cases for further processing
							if (c.Status != oldCase.Status && c.Status == 'Solved' && string.isNotBlank(c.Confirm_Case_Reason__c)) {
									list_solvedCases.add(c);
							}

							if (
									c.RecordTypeId == recordTypeNameIdMap.get('Payroll Transfer Case') &&
									c.Origin == 'Email' &&
									c.Requires_Action__c != oldCase.Requires_Action__c &&
									c.requires_Action__c == true
							) {
									lst_PTEmailCase.add(c);
							}

							if (
									c.RecordTypeId == recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE) &&
									(c.Status != oldCase.Status ||
									c.Error_Message__c == CaseMassUpdateLightningController.FROM_MASSUPDATE) &&
									c.Status == CASE_STATUS_READY_FOR_RESEARCH &&
									c.Agency_Information__c != null
							) {
									list_SpecialistAssignmentEligibleCases.add(c);
									if (c.Account_Specialist__c != null) {
											set_oldSpecialistIds.add(c.Account_Specialist__c);
									}
							}

							//Prepare SMS Records
							if (
									CaseUtils.set_SMSRecordTypes.contains(c.RecordTypeId) &&
									c.SuppliedPhone != null &&
									(c.Origin == CaseUtils.ORIGIN_PHONE || (c.Origin == CaseUtils.ORIGIN_GUSTO && c.Channel__c == CaseUtils.CHANNEL_PHONE)) &&
									c.Send_Survey__c &&
									!c.Skip_Survey__c &&
									!c.Survey_Sent__c
							) {
									// Description: Below Logic is for Engagement and Payroll Care RecordTypes to create SMS record on CLOSED Status
									if (CaseUtils.set_EngagementRecordTypes.contains(c.RecordTypeId) && c.Status == CaseUtils.STATUS_CLOSED) {
											list_SMSCases.add(c);
									} else if (c.Status == CaseUtils.STATUS_SOLVED) {
											list_SMSCases.add(c);
									}
							}

							String strEmailDomain = '';
							if (String.isNotBlank(c.SuppliedEmail)) {
									List<String> list_EmailSplits = c.SuppliedEmail.split('@');
									if (list_EmailSplits?.size() > 1) {
											strEmailDomain = list_EmailSplits[1];
									}
							}

							if (
									Cache.getRecordTypeName(CaseUtils.CASE_OBJ_NAME, c.RecordTypeId) != CaseUtils.TYPE_TAX_RES &&
									(c.Class__c != oldCase.Class__c ||
									c.RecordTypeId != oldCase.RecordTypeId) &&
									c.Class__c == CaseUtils.CASE_CLASS_CLASS_0 &&
									c.Status != CaseUtils.STATUS_CLOSED &&
									Label.Inbound_Email_Exception_Domains.IndexOf(strEmailDomain) == -1
							) {
									c.Status = CaseUtils.STATUS_CLOSED;
									setCaseReadOnlyRecType(c);
									if (Cache.getRecordTypeName('Case', c.RecordTypeId) == 'Payroll Care - Read Only' && map_QueuesByName.containsKey('Payroll_Care_Auto_Close')) {
											c.OwnerId = map_QueuesByName.get('Payroll_Care_Auto_Close').Id;
									} else if (Cache.getRecordTypeName('Case', c.RecordTypeId) == 'Modern Bank - Read Only' && map_QueuesByName.containsKey('Modern_Bank_Auto_Close')) {
											c.OwnerId = map_QueuesByName.get('Modern_Bank_Auto_Close').Id;
									} else if (Cache.getRecordTypeName('Case', c.RecordTypeId) == 'Tax Ops - Read Only' && map_QueuesByName.containsKey('TaxOps_Auto_Closed_Queue')) {
											c.OwnerId = map_QueuesByName.get('TaxOps_Auto_Closed_Queue').Id;
									}
							}

							if (c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && !c.IsClosed) {
                                c = updateCasePillar(c, oldCase);
							}
					}
					stampSalesCasesChanges(c, oldCaseMap?.get(c.Id));

					if(map_OCRTriggerdCaseIdWithRelevantCases != null && !map_OCRTriggerdCaseIdWithRelevantCases.isEmpty() && map_OCRTriggerdCaseIdWithRelevantCases.containsKey(c.Id) &&  map_OCRTriggerdCaseIdWithRelevantCases.get(c.Id) != null) {
						c.Relevant_Cases__c = map_OCRTriggerdCaseIdWithRelevantCases.get(c.Id);
					}
			
			}

			if (list_SMSCases.size() > 0) {
					createSMSRecords(list_SMSCases);
			}

			playmode = false;
			if (counter == 2) {
					setFulfillmentCaseRouting(newCaseMap.values(), oldCaseMap);
			}

			formatCaseDescription(newCaseMap, oldCaseMap);

			//BY:PR, Date: 6/4/19, Desc: If we have recently solved cases we are calling method for furhter processing
			if (list_solvedCases.size() > 0) {
					checkCaseEscalations(list_solvedCases);
					updateClassInfoOnceCaseIsSolved(list_solvedCases);
			}

			//By:PR, Date:7/10/19, Desc: calling methods to replace Inactive Owners with correct Queue
			updateInActiveOwners(newCaseMap.values());

			//Update case owner to queue if follow update getting changed
			UpdateCaseOwner(newCaseMap.values(), oldCaseMap);
			updateCaseOwnerInformation(newCaseMap.values(), oldCaseMap);

			/*
	  By: PR, Date 8/21/2019.
	  Desc: we are assigning order to Case if the case is of type "payroll transfer case"
	*/
			if (list_MigrationCaseForOrderAssignment.size() > 0) {
					assigningOrderToCase(list_MigrationCaseForOrderAssignment);
			}

			if (lst_PTEmailCase.size() > 0) {
					handleResellerEmailCaseForBMR(lst_PTEmailCase);
			}
			HIFulfillmentEventHelperFunctions.setCaseGroupNumber(newCaseMap, oldCaseMap);

			//Date 9 April 2020 : Agatha predicted tax res cases change the ownership to a queue where previous owner was another queue
			checkOwnerId(oldCaseMap, newCaseMap);

			//Neha Dabas, 27th March 2020, Set Requires_Action on related Ticket
			if (!set_CaseWithActionRequiredTrue.isEmpty()) {
					setRequiresActionOnTicket(set_CaseWithActionRequiredTrue);
			}

			setTypeOnBORCarrierComm(newCaseMap.values());
			if (list_nonPrivacyCases.size() > 0) {
					updateCasePartnerSalesDetails(list_nonPrivacyCases);
			}

			gepCxCase(newCaseMap.values());
			updateSendSurvey(newCaseMap.values(), oldCaseMap);
			if (list_SpecialistAssignmentEligibleCases.size() > 0) {
					taxResSpecialistCaseAssignment(list_SpecialistAssignmentEligibleCases, set_oldSpecialistIds, false);
			}

			memberOpsCaseStatusHandler(newCaseMap.values(), oldCaseMap);

			if (map_OCRProcessedCasesToOwnerUpdate != null && !map_OCRProcessedCasesToOwnerUpdate.isEmpty()) {
					CaseUtils.taxResCaseOwnerUpdate(map_OCRProcessedCasesToOwnerUpdate, null);
			}
			updatePartnerAccountBeforeUpdate(newCaseMap.values(), oldCaseMap);
	}

	public void processAfterUpdate(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			createCollectionsAfter(newCaseMap.values(), oldCaseMap);

			if (label.Modern_Bank_case_eligible_Complaint_Type_for_ticket_creation != null) {
					set_MBComplaintTypesForTicketCreation.addAll(Label.Modern_Bank_case_eligible_Complaint_Type_for_ticket_creation.split(','));
			}

			map<Id, String> caseMilestoneMap = new Map<Id, String>();
			list<Case> lsiCaseList = new List<Case>();
			Set<Id> setAccountId = new Set<Id>();
			set<string> followUpCompletedIntegrationIdSet = new Set<string>();
			list<Id> lst_MBRecordsForTicketCreation = new List<Id>();
			list<Case> lst_PTBulkCase = new List<Case>();
			List<Id> list_PrivacyRequestsApprovedForDisclosure = new List<Id>();
			List<Id> list_PrivacyRequestsClosed = new List<Id>();
			List<Id> list_AutoEmailQueues = new List<Id>();
			Set<Id> set_AutoEmailCases = new Set<Id>();
			Set<Id> set_CaseIdsForBusinessHours = new Set<Id>();
			List<Case> list_TaxResCasesWithOwnerUpdate = new List<Case>();
			List<Case> list_TaxResCasesWithASUpdate = new List<Case>();
			List<Case> list_TaxResCasesWithStatusUpdate = new List<Case>();
			Map<Id, Case> map_TaxResClosedCases = new Map<Id, Case>();
			List<Case> list_CasesWithOwnerChange = new List<Case>();
			Set<Id> set_CaseIdsToUpdateToAsana = new Set<Id>();
			Set<Id> set_CaseIdsToInsertToAsana = new Set<Id>();

			handleRquiresAction(newCaseMap, oldCaseMap);
			if (zendeskInfoProcessed == false) {
					insertIntoZendeskIntegrationLog(newCaseMap.values(), oldCaseMap);
					zendeskInfoProcessed = true;
			}
			/*
	Author: Alex
	Date: 4/7/2020
	Desc: get Mass Email queue
	*/
			List<Group> list_Queues = GlobalQueryHelper.getGroupsByType('queue');
			for (Group queue : list_Queues) {
					if (queue.DeveloperName == 'Mass_Email_Cases' || queue.DeveloperName == 'Engagement_Auto_First_Response_Queue') {
							list_AutoEmailQueues.add(queue.Id);
					}
			}

			for (Case c : newCaseMap.values()) {
					Case oldCase = oldCaseMap.get(c.Id);
					if (c.First_Response_Time__c != oldCase.First_Response_Time__c) {
							caseMilestoneMap.put(c.Id, 'First Response Deadline');
					}

					if (
							(oldCase.Large_Scale_Issue_Classification__c != c.Large_Scale_Issue_Classification__c ||
							oldCase.AccountId != c.AccountId) &&
							c.Large_Scale_Issue_Classification__c != null &&
							c.AccountId != null
					) {
							lsiCaseList.add(c);
					}

					// There could be 3 possibilities, case status =  closed or opened, Priority is changed from High or vice versa
					// or account is changed
					// Modified: By Prashant (High priority case field update ticket)
					// Desc: it should update if account is updated or anything else is updated

					if (oldCase.AccountId != null) {
							setAccountId.add(oldCase.AccountId);
					}

					if (c.AccountId != null && oldCase.AccountId != c.AccountId) {
							// then evaluate for both accounts
							setAccountId.add(c.AccountId);
					}

					//BY:PR, Desc: HI Fulfillment Event Completed Date functionality
					if (
							oldCase.Follow_Up_Completed_by__c != c.Follow_Up_Completed_by__c &&
							c.Integration_Id__c != null &&
							c.Follow_Up_Completed_by__c != null &&
							(c.RecordTypeId == recordTypeNameIdMap.get('MF Audit') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Member/Group Updates') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF NHE') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF QLE') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Termination') ||
							c.RecordTypeId == recordTypeNameIdMap.get('MF Viking Master') ||
							c.RecordTypeId == recordTypeNameIdMap.get('Member Fulfillment Emails'))
					) {
							followUpCompletedIntegrationIdSet.add(c.Integration_Id__c);
					}

					//By: PR, Date: 7/10/19, Desc: For "Modern Bank" if "Complaint Type" changes we want to create Ticket if not already exist
					if (
							c.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') &&
							string.isNotBlank(c.Complaint_Type__c) &&
							oldCase.Complaint_Type__c != c.Complaint_Type__c &&
							set_MBComplaintTypesForTicketCreation.contains(c.Complaint_Type__c)
					) {
							lst_MBRecordsForTicketCreation.add(c.id);
					}

					if (
							c.recordTypeId == recordTypeNameIdMap.get('Payroll Transfer Case') &&
							c.Origin == 'Bulk' &&
							c.Requires_Action__c != oldCase.Requires_Action__c &&
							c.Requires_Action__c == true &&
							c.Bulk_Migration__c != null
					) {
							lst_PTBulkCase.add(c);
					}
					//Alex: if the privacy request's status gets changed to Identity Verified, add it to the list for processing
					if (c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request')) {
							if (c.Status == 'Identity Verified' && oldCase.Status != 'Identity Verified') {
									list_PrivacyRequestsApprovedForDisclosure.add(c.Id);
							}
							if (c.Status == 'Closed' && oldCase.Status != 'Closed') {
									list_PrivacyRequestsClosed.add(c.Id);
							}
					}
					//Alex: if queue is mass email cases and status is Response Received, update with assignment rules
					if (list_AutoEmailQueues.contains(c.OwnerId) && c.Status == 'Response Received') {
							set_AutoEmailCases.add(c.Id);
					}

					if ((c.RecordTypeId == CaseUtils.RECTYPE_TAXRES || c.RecordTypeId == CaseUtils.RECTYPE_TAXRES_READ_ONLY) && c.Status != oldCase.Status && c.Status == CaseUtils.STATUS_SOLVED) {
							map_TaxResClosedCases.put(c.Id, c);
					}

					/*Pravesh: if owner other than NA or AS changes or notice analyst or account specialist changes
					 *            We want to create a "Case Audit Log" record. To track the changes for Analytics
					 *           This functionality is only for "Tax Resolution" Cases
					 */
					if (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES && c.OwnerId != oldCase.OwnerId && c.OwnerId != c.Account_Specialist__c && !String.valueOf(c.OwnerId).startsWith('00G')) {
							list_TaxResCasesWithOwnerUpdate.add(c);
					} else if (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES && c.Account_Specialist__c != oldCase.Account_Specialist__c) {
							list_TaxResCasesWithASUpdate.add(c);
					} else if (c.Status != oldCase.Status && (c.RecordTypeId == CaseUtils.RECTYPE_TAXRES || c.RecordTypeId == CaseUtils.RECTYPE_TAXRES_READ_ONLY)) {
							list_TaxResCasesWithStatusUpdate.add(c);
					}

					if (c.OwnerId != oldCase.OwnerId && c.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && String.valueOf(c.OwnerId).startsWith('005')) {
							list_CasesWithOwnerChange.add(c);
					}
					Set<String> set_byPassStatuses = new Set<String> {CaseUtils.STATUS_CLOSED,CaseUtils.STR_DELETE,CaseUtils.STR_UN_SUPPORTED,CaseUtils.STR_NO_CHANGE};
					Boolean bln_byPassAsanaIntegration = false;
					if (oldCase.Status == CaseUtils.STATUS_NEW && set_byPassStatuses.contains(c.Status)){
							bln_byPassAsanaIntegration = true;
					}
					// compliance cases: check asana eligibility cases for inserting to asana
					if (
							!bln_byPassAsanaIntegration &&
							String.IsBlank(c.Batch_Id__c) &&
							c.Owner.Type != CaseUtils.STRG_QUEUE &&
							c.Status != CaseUtils.STATUS_NEW &&
							c.Status != CaseUtils.STR_NO_LONGER_NEEDED &&
							c.RecordTypeId == CaseUtils.RECTYPE_CASE_COMPLIANCE &&
							(c.Status != oldCase.Status ||
							c.OwnerId != oldCase.OwnerId)
					) {
							set_CaseIdsToInsertToAsana.add(c.Id);
					}

					// compliance cases: check asana update on case update
					if (
							!bln_byPassAsanaIntegration &&
							String.IsNotBlank(c.Batch_Id__c) &&
							c.RecordTypeId == CaseUtils.RECTYPE_CASE_COMPLIANCE &&
							(c.Status != oldCase.Status ||
							c.Subject != oldCase.Subject ||
							c.OwnerId != oldCase.OwnerId ||
							c.Compliance_Score__c != oldCase.Compliance_Score__c ||
							c.Description != oldCase.Description ||
							c.Agency_Information__c != oldCase.Agency_Information__c)
					) {
							set_CaseIdsToUpdateToAsana.add(c.Id);
					}
			}
			if (caseMilestoneMap.size() > 0) {
					completeEntitlements(caseMilestoneMap, newCaseMap);
			}

			if (caseAuditLogList.size() > 0 && (counter == 1 || processStatusChange == true)) {
					insert caseAuditLogList;
					caseAuditLogList = new List<Case_Audit_Log__c>();
					processStatusChange = false;
			}

			if (lsiCaseList.size() > 0) {
					createAccountLSIRecords(lsiCaseList);
			}

			//BY:PR, Desc: HI Fulfillment Event Completed Date functionality
			if (followUpCompletedIntegrationIdSet.size() > 0) {
					populateFulfillmentEventCompletedDate(followUpCompletedIntegrationIdSet);
			}

			//By:PR, Date:7/10/19, Desc: Calling Ticket creation method is we have some eligible MB cases
			if (lst_MBRecordsForTicketCreation.size() > 0) {
					createTicketForMBComplaint(lst_MBRecordsForTicketCreation);
			}
			//commented by PR
			processCaseFulfillmentStatus(oldCaseMap, newCaseMap);

			if (lst_PTBulkCase.size() > 0) {
					handleBulkCaseRequiresAction(lst_PTBulkCase);
			}

			if (counter == 1) {
					createDataCollectionRecords(list_PrivacyRequestsApprovedForDisclosure);
					closeDataCollectionRecords(list_PrivacyRequestsClosed);
			}

			if (list_TaxResCasesWithOwnerUpdate.size() > 0) {
					createTaxResAuditLogs(list_TaxResCasesWithOwnerUpdate, CaseUtils.OWNER_CHANGE, false, false);
			}

			if (list_TaxResCasesWithASUpdate.size() > 0) {
					createTaxResAuditLogs(list_TaxResCasesWithASUpdate, CaseUtils.OWNER_CHANGE, false, true);
			}

			if (list_TaxResCasesWithStatusUpdate.size() > 0) {
					createTaxResAuditLogs(list_TaxResCasesWithStatusUpdate, CaseUtils.STATUS_CHANGE, false, false);
			}

			if (!map_TaxResClosedCases.isEmpty()) {
					updateTaxResPreviouslyAnsweredCases(map_TaxResClosedCases);
			}

			if (!list_CasesWithOwnerChange.isEmpty()) {
					processownerChangeAuditLog(list_CasesWithOwnerChange);
			}

			/*
	Author: Alex
	Date: 4/7/2020
	Desc: update mass email cases with assignment rules
	*/
			if (!set_AutoEmailCases.isEmpty()) {
					Map<Id, Boolean> map_CaseIdToSendSurvey = new Map<Id, Boolean>();
					List<Id> list_CaseReasonClassIds = new List<Id>();
					List<Case> list_AutoEmailCasesWithSurvey = CaseQueryHelper.getMassEmailCases(set_AutoEmailCases);

					for (Case c : list_AutoEmailCasesWithSurvey) {
							if (c.Routing_Case_Reason_Classification__r.Survey_Eligible__c != null) {
									map_CaseIdToSendSurvey.put(c.Id, c.Routing_Case_Reason_Classification__r.Survey_Eligible__c);
							}
					}
					doAssignmentRuleUpdate(map_CaseIdToSendSurvey);
			}
			// Asana call out to create a new case record
			if (!set_CaseIdsToInsertToAsana.isEmpty()) {
					Map<Id, Tax_Compliance__c> map_Compliance = getTaxCompliance(set_CaseIdsToInsertToAsana);
					if (!map_Compliance.isEmpty()) {
							System.enqueueJob(new SendComplianceToAsanaRouting(map_Compliance, true));
					}
			}

			// Asana call out to update a case record
			if (!set_CaseIdsToUpdateToAsana.isEmpty()) {
					Map<Id, Tax_Compliance__c> map_Compliance = getTaxCompliance(set_CaseIdsToUpdateToAsana);
					if (!map_Compliance.isEmpty()) {
							System.enqueueJob(new SendComplianceToAsanaRouting(map_Compliance, false));
					}
			}
	}
	/*
Author: Sujan Kumar
Date: 06/25/2020
Get the related compliance records for a given case records
*/
	public Map<Id, Tax_Compliance__c> getTaxCompliance(Set<Id> set_CaseIds) {
			Map<Id, Tax_Compliance__c> map_Compliance = new Map<Id, Tax_Compliance__c>(
					[
							SELECT
									Id,
									Case__c,
									Case__r.Id,
									Case__r.OwnerId,
									Case__r.CreatedDate,
									Case__r.Owner.Name,
									Case__r.Status,
									Case__r.Case_Owner_Name__c,
									Case__r.Subject,
									Case__r.Description,
									Case__r.Batch_Id__c,
									Case__r.Parent.Batch_Id__c,
									Case__r.Agency_Information__r.Name,
									Case__r.Compliance_Score__c,
									Agency_Due_Date__c,
									Follow_up_Date__c,
									Eng_Status__c,
									Who_Owns_this_Initiative__c,
									Tier__c,
									Eng_Due_Date__c,
									In_App_content__c,
									Customer_Comms__c,
									Knowledge_Management_Readiness__c,
									Help_Center_IKB_Internal__c,
									Help_Center_IKB_External__c,
									CX_Comms__c,
									Impacts__c,
									System_impacted__c,
									Frequency_of_Update__c,
									EPDD_DRI__c,
									Resource_Link__c,
									Customer_Count__c,
									Classification_Type__c,
									Compliance_Team_POC__c
							FROM Tax_Compliance__c
							WHERE Case__c IN :set_CaseIds
					]
			);
			return map_Compliance;
	}

	public void processBeforeDelete(Case[] caseToDelete, Map<ID, Case> oldCaseMap) {
			counter++;
			for (Case c : caseToDelete) {
					c.addError('Case cannot be deleted.');
			}
			if (Test.isRunningTest()) {
					throwTestException();
			}
	}

	/*
	Author: SJay
	Date: 8/06/2020
	In test context throw an exception
*/
	public void throwTestException() {
			if (Test.isRunningTest() && CaseTriggerHelperTest.blnRunCatchTest == true) {
					throw new NullPointerException();
			}
	}

	/**
	 * @Author      : Sahil Goyal
	 * @Description : Check eligibility for Email-AutoSolve AI Callout and enqueue the 'CaseEmailAutoSolveAIQueueable' job (BTE-4057)
	 * @Parm        : objNewCase[single new case]
	 * @Return      : N/A
	 **/
	private void checkEmailAutoSolveAIProcess(Case objNewCase) {

		// BTE-4230 - Exclude Replies to Closed Cases from Internal Callout
		Boolean hasValidRelatedCase = objNewCase.Related_Case__c != null;
		Boolean hasValidParentCase = objNewCase.ParentId != null;
		if (
				objNewCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && !hasValidRelatedCase && !hasValidParentCase &&
				!(objNewCase.Origin == CaseUtils.ORIGIN_PHONE || (objNewCase.Origin == CaseUtils.ORIGIN_GUSTO && objNewCase.Channel__c == CaseUtils.CHANNEL_PHONE)) &&
				!(objNewCase.Origin == CaseUtils.ORIGIN_CHAT || (objNewCase.Origin == CaseUtils.ORIGIN_GUSTO && objNewCase.Channel__c == CaseUtils.ORIGIN_CHAT))
			) {
				if ( String.isNotBlank(objNewCase.Subject) && String.isNotBlank(objNewCase.Description) ) {
					System.enqueueJob(new CaseEmailAutoSolveAIQueueable(objNewCase.Id));
				} else {
					Case updateCase = new Case(Id = objNewCase.Id, Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO);
					
					Boolean skipTrigger = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;
					update updateCase;
					CaseTriggerHelper.skipTrigger = skipTrigger;
				}
			}
	}


	/**
	 * @Author      : Swati Arya
	 * @Description : Check if the Case Subject contains the Partial match from the custom settings map
	 *                  and return the matched custom setting record
	 * @Parm        : cse[Case record]
	 * @Return      : Email_Subject_AutoClosed__c custom setting record
	 **/
	public Email_Subject_AutoClosed__c getPartialMatchCustomSetting(Case objCase) {
			Email_Subject_AutoClosed__c objAutoClosePartialMatchRec;
			for (String strName : map_PartialMatchAutoCloseSubject.keySet()) {
					String strNameWORecType = strName.substringAfter('-');
					if (String.isNotBlank(strNameWORecType)) {
							List<String> list_MultiPartialMatch = strNameWORecType?.split(';');
							if (!list_MultiPartialMatch.isEmpty()) {
									for (String strToMatch : list_MultiPartialMatch) {
											if (objCase?.Subject?.contains(strToMatch) && map_PartialMatchAutoCloseSubject.get(strName) != null) {
													objAutoClosePartialMatchRec = map_PartialMatchAutoCloseSubject.get(strName);
											} else {
													objAutoClosePartialMatchRec = new Email_Subject_AutoClosed__c();
													break;
											}
									}
							}
					}
			}
			return objAutoClosePartialMatchRec;
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Update Send Survey on update of Routing Case Reason
	 * @Parm        : list_Cases[new cases], map_OldCases [old cases map]
	 * @Return      : N/A
	 **/
	public void updateSendSurvey(List<Case> list_Cases, Map<Id, Case> map_OldCases) {
			if (allClassMap == null || allClassMap.isEmpty()) {
					setCaseReasonClassification();
			}

			for (Case objCase : list_Cases) {
					if (
							(objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES ||
							objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES_READ_ONLY) &&
							objCase.Confirm_Case_Reason_Classification__c != null &&
							objCase.Confirm_Case_Reason_Classification__c != map_OldCases.get(objCase.Id).Confirm_Case_Reason_Classification__c &&
							allClassMap?.containsKey(objCase.Confirm_Case_Reason__c)
					) {
							objCase.Send_Survey__c = allClassMap.get(objCase.Confirm_Case_Reason__c).Survey_Eligible__c;
					}
			}
	}

	/*
@Author      : Pravesh Rana
@Date        : 7/27/2021
@Description : handles Tax-Resolution status and Email-status changes
Required Fields: RecordTypeId, Id, Email_Status__c, Status, OwnerId, Notice_Analyst__c
					Account_Specialist
@Parm       : list_Cases[case records], strEventType[event type "Status change","Email Status Change", "Owner Change"],
				blnIsAnalystChange[is Notice Analyst changes], blnIsSpecialistChange[is Account Specialist changes]
@Return     : void

*/
	public static void createTaxResAuditLogs(List<Case> list_Cases, String strEventType, Boolean blnIsAnalystChange, Boolean blnIsSpecialistChange) {
			String strEmailStatusChange = CaseUtils.EMAIL_STATUS_CHANGE;
			String strStatusChange = CaseUtils.STATUS_CHANGE;
			String strOwnerChange = CaseUtils.OWNER_CHANGE;
			Set<Id> set_CaseIds = new Set<Id>();
			Map<String, Case_Audit_Log__c> map_CaseIdAuditLogRecord = new Map<String, Case_Audit_Log__c>();
			List<Case_Audit_Log__c> list_InsertAuditLogs = new List<Case_Audit_Log__c>();

			if (list_Cases?.size() > 0 && String.isNotBlank(strEventType)) {
					List<BusinessHours> list_BizHours = new List<BusinessHours>();
					for (BusinessHours objBh : GlobalQueryHelper.getAllBusinessHoursList()) {
							if (objBh.Name == 'Gusto - Denver - Engagement') {
									list_BizHours.add(objBh);
							}
					}

					for (Case objCase : list_Cases) {
							if (objCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES && objCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES_READ_ONLY) {
									continue;
							}

							set_CaseIds.add(objCase.Id);
					}

					if (strEventType == strEmailStatusChange || strEventType == strStatusChange || strEventType == strOwnerChange) {
							String strMainQuery = 'SELECT Id, To_Status__c, To_Date_Time__c, CreatedDate, Case__c, To_Owner__c FROM Case_Audit_Log__c ';
							String strOrderBy = ' ORDER BY CreatedDate DESC ';
							String strWhereClause = ' WHERE Event_Type__c = :strEventType AND Case__c IN :set_CaseIds ';
							if (strEventType == strOwnerChange) {
									if (blnIsSpecialistChange) {
											strWhereClause += ' AND To_Role__c = \'' + CaseUtils.TAXRES_ACCOUNT_SPECIALIST + '\'';
									}
							}

							strMainQuery = strMainQuery + strWhereClause + strOrderBy;
							for (Case_Audit_Log__c objLog : Database.query(strMainQuery)) {
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

							for (Case objCase : list_Cases) {
									if (objCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES && objCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES_READ_ONLY) {
											continue;
									}

									Case_Audit_Log__c objAuditLog;
									Case_Audit_Log__c objNewAuditLog = new Case_Audit_Log__c();
									if (map_CaseIdAuditLogRecord.containsKey(objCase.Id)) {
											objAuditLog = map_CaseIdAuditLogRecord.get(objCase.Id);
									}

									objNewAuditLog.Case__c = objCase.Id;
									objNewAuditLog.To_Date_Time__c = System.now();
									objNewAuditLog.Event_Type__c = strEventType;

									if (strEventType == strEmailStatusChange) {
											objNewAuditLog.To_Status__c = objCase.Email_Status__c;
									} else if (strEventType == strStatusChange) {
											objNewAuditLog.To_Status__c = objCase.Status;
									} else if (strEventType == strOwnerChange) {
											if (blnIsSpecialistChange) {
													objNewAuditLog.To_Role__c = CaseUtils.TAXRES_ACCOUNT_SPECIALIST;
													objNewAuditLog.To_Owner__c = objCase.Account_Specialist__c;
											}
									}

									if (strEventType != strOwnerChange) {
											if (objCase.OwnerId == objCase.Account_Specialist__c) {
													objNewAuditLog.Current_Role__c = CaseUtils.TAXRES_ACCOUNT_SPECIALIST;
											} else {
													objNewAuditLog.Current_Role__c = 'Owner';
											}
									}

									if (objAuditLog?.Id != null) {
											if (strEventType == strEmailStatusChange || strEventType == strStatusChange) {
													objNewAuditLog.From_Status__c = objAuditLog.To_Status__c;
													if (objNewAuditLog.From_Status__c == objNewAuditLog.To_Status__c) {
															continue;
													}
											} else if (strEventType == strOwnerChange) {
													objNewAuditLog.From_Owner__c = objAuditLog.To_Owner__c;
													if (objNewAuditLog.From_Owner__c == objNewAuditLog.To_Owner__c) {
															continue;
													}
											}

											objNewAuditLog.From_Date_Time__c = objAuditLog.To_Date_Time__c;
									}

									if (list_BizHours?.size() > 0 && objNewAuditLog.From_Date_Time__c != null && objNewAuditLog.To_Date_Time__c != null) {
											objNewAuditLog.Business_Hours__c = list_BizHours[0].Id;
											Id idHours = objNewAuditLog.Business_Hours__c;
											DateTime dtFromTime = objNewAuditLog.From_Date_Time__c;
											DateTime dtToTime = objNewAuditLog.To_Date_Time__c;
											if (dtFromTime != null) {
													Long lngMilliSeconds = BusinessHours.diff(idHours, dtFromTime, dtToTime);
													objNewAuditLog.Duration_in_seconds__c = lngMilliSeconds / 1000;
											}
									}

									objNewAuditLog.Current_Owner__c = String.valueOf(objCase.OwnerId).startsWith('005') ? objCase.OwnerId : null;
									list_InsertAuditLogs.add(objNewAuditLog);
							}

							if (list_InsertAuditLogs?.size() > 0) {
									try {
											insert list_InsertAuditLogs;
									} catch (Exception objException) {
											ExceptionLogUtil.logException('CaseTriggerHelper', 'createTaxResAuditLogs', objException.getMessage(), 'High');
									}
							}
					}
			}
	}

	/**
	 * @author       Ankit C
	 * @description  This method created Case_Audit_Log__c records when owner changes for Engagement cases.
	 * @param        list_Cases - List of Case records
	 * @return       NA
	 **/
	public void processOwnerChangeAuditLog(List<Case> list_Cases) {
			String strOwnerChangeEvent = CaseUtils.OWNER_CHANGE;
			Map<String, Case_Audit_Log__c> map_CaseAuditLogByCase = new Map<String, Case_Audit_Log__c>();
			List<Case_Audit_Log__c> list_InsertAuditLogs = new List<Case_Audit_Log__c>();
			for (Case_Audit_Log__c objCaseAuditLog : [
					SELECT Id, To_Status__c, To_Date_Time__c, CreatedDate, Case__c, To_Owner__c
					FROM Case_Audit_Log__c
					WHERE Event_Type__c = :strOwnerChangeEvent AND Case__c IN :list_Cases
					ORDER BY CreatedDate
			]) {
					map_CaseAuditLogByCase.put(objCaseAuditLog.Case__c, objCaseAuditLog);
			}

			List<BusinessHours> list_BizHours = [SELECT Id, Name, TimeZoneSidKey, IsDefault FROM BusinessHours WHERE Name = 'Gusto - Denver - Engagement'];

			for (Case objCase : list_Cases) {
					Case_Audit_Log__c objAuditLog;
					Case_Audit_Log__c objNewAuditLog = new Case_Audit_Log__c();

					objNewAuditLog.Case__c = objCase.Id;
					objNewAuditLog.To_Date_Time__c = System.now();
					objNewAuditLog.Event_Type__c = strOwnerChangeEvent;
					objNewAuditLog.To_Owner__c = objCase.OwnerId;

					if (map_CaseAuditLogByCase.containsKey(objCase.Id)) {
							objAuditLog = map_CaseAuditLogByCase.get(objCase.Id);
							objNewAuditLog.From_Owner__c = objAuditLog.To_Owner__c;
							objNewAuditLog.From_Date_Time__c = objAuditLog.To_Date_Time__c;
					}

					if (!list_BizHours.isEmpty() && objNewAuditLog.From_Date_Time__c != null && objNewAuditLog.To_Date_Time__c != null) {
							objNewAuditLog.Business_Hours__c = list_BizHours[0].Id;
							Id idHours = objNewAuditLog.Business_Hours__c;
							DateTime dtFromTime = objNewAuditLog.From_Date_Time__c;
							DateTime dtToTime = objNewAuditLog.To_Date_Time__c;
							if (dtFromTime != null) {
									Long lngMilliSeconds = BusinessHours.diff(idHours, dtFromTime, dtToTime);
									objNewAuditLog.Duration_in_seconds__c = lngMilliSeconds / 1000;
							}
					}

					objNewAuditLog.Current_Owner__c = objCase.OwnerId;
					list_InsertAuditLogs.add(objNewAuditLog);
			}

			if (!list_InsertAuditLogs.isEmpty()) {
					insert list_InsertAuditLogs;
			}
	}

	//By AKS dated : 13th May 2020  Asana Ticket:- https://app.asana.com/0/1149920908637905/1175386681047195
	//when Carrier Case for Benefits BoR is created, then type should be Benefits BOR Carrier Case
	private void setTypeOnBORCarrierComm(list<Case> caseList) {
			for (Case caseObj : caseList) {
					if (
							caseObj.Origin == 'Email' &&
							caseObj.Direction__c == 'Inbound' &&
							(caseObj.To_Email_Address__c == 'bor-transfer@gusto.com' ||
							caseObj.CCEmailAddress__c == 'bor-transfer@gusto.com') &&
							caseObj.recordTypeId == recordTypeNameIdMap.get('Benefits BoR') &&
							caseObj.Type == 'BOR' &&
							caseObj.Status != 'Closed'
					) {
							caseObj.Type = 'Benefits BOR Carrier Case';
					}
			}
	}

	/*
	By: PR, Date 8/21/2019.
	Desc: we are assigning order to Case and changing Case owner to Order owner 
		if the case recordtype "payroll transfer case", type != document mapping, origin : Email , direction = inbound and account != null
*/
	public void assigningOrderToCase(list<Case> caseList) {
			Map<Id, Case> map_UnassignedCaseAccount = new Map<Id, Case>(); //Key:AccountId and value is Case record

			for (Case caseObj : caseList) {
					if (null != caseObj.AccountId) {
							map_UnassignedCaseAccount.put(caseObj.AccountId, caseObj);
					}
			}

			map<id, Order> map_accountIdLatestOrder = new Map<id, Order>();
			map<Id, Case> map_UnassignedCaseContact = new Map<Id, Case>();

			for (Account objAcc : list_AccountsForAssigningOrderToCase) {
					if (objAcc.RecordType.Name == 'Company' && objAcc.Orders.size() > 0) {
							map_accountIdLatestOrder.put(objAcc.Id, objAcc.Orders.get(0));
					} else if (objAcc.RecordType.Name == 'Reseller') {
							Case objCase = map_UnassignedCaseAccount.get(objAcc.Id);
							if (test.isRunningTest() || objCase.OwnerId == null || !String.valueOf(objCase.OwnerId).startsWith('005')) {
									map_UnassignedCaseContact.put(objCase.ContactId, objCase);
							}
					}
			}

			for (Case cs : caseList) {
					if (map_accountIdLatestOrder.containsKey(cs.AccountId)) {
							cs.Order__c = map_accountIdLatestOrder.get(cs.AccountId).id;
							cs.OwnerId = map_accountIdLatestOrder.get(cs.AccountId).OwnerId;
							cs.Order_Payroll_Run_Date__c = map_accountIdLatestOrder.get(cs.AccountId).Payroll_Run_Date__c;
							if (cs.OwnerId != null && string.valueOf(cs.OwnerId).startsWith('005')) {
									cs.Order_Owner_Name__c = map_accountIdLatestOrder.get(cs.AccountId).Owner.FirstName;
							}
					}
			}
			if (map_UnassignedCaseContact.size() > 0) {
					assignOwnerToResellerAccountCase(map_UnassignedCaseContact, 'Payroll Transfer Case');
			}
	}

	/*
Author      : Pravesh Rana
Date        : 7/11/2022
Description : Send Eligible cases to tax Res Account Specialist Assignment
@Parm       : list_Cases[eligible case object records]
@Return     : N/A
*/
	public static void taxResSpecialistCaseAssignment(List<Case> list_Cases, Set<String> set_oldSpecialistIds, Boolean blnPerformDML) {
			Set<String> set_eligibleSpecialistIds = new Set<String>();
			list<Case> list_EligibleCasesForOwnerAssignment = new List<Case>();
			TaxResPlayModeUtil controller = new TaxResPlayModeUtil();
			if (list_Cases.isEmpty()) {
					return;
			}

			set_eligibleSpecialistIds = validateEligibleUsers(set_oldSpecialistIds, CaseUtils.TAXRES_ACCOUNT_SPECIALIST);

			for (Case objCase : list_Cases) {
					if (objCase.RecordTypeId != CaseUtils.RECTYPE_TAXRES) {
							continue;
					}

					if (objCase.Account_Specialist__c != null && set_eligibleSpecialistIds?.contains(objCase.Account_Specialist__c)) {
							objCase.OwnerId = objCase.Account_Specialist__c;
					} else {
							list_EligibleCasesForOwnerAssignment.add(objCase);
					}
			}

			if (list_EligibleCasesForOwnerAssignment?.size() > 0) {
					controller.runIRSpecialistAssignment(list_EligibleCasesForOwnerAssignment, blnPerformDML);
			}
	}

	/*
Author      : Pravesh Rana
Date        : 1/4/2022
Description : returns UserIds having Coordinator Skills and are in office
@Parm       : set_UserIds[User Ids], strTeamName[team name]
@Return     : N/A
*/
	private static Set<String> validateEligibleUsers(Set<String> set_UserIds, String strTeamName) {
			Set<String> set_eligibleUserIds = new Set<String>();

			if (set_UserIds?.size() > 0 && String.isNotBlank(strTeamName)) {
					for (User_Role__c objUserRole : [
							SELECT Id, User_Skill_Team__c, User__c, User__r.Out_Of_Office__c
							FROM User_Role__c
							WHERE User__c IN :set_UserIds AND User_Skill_Team__c = :strTeamName AND User__r.Out_Of_Office__c = FALSE AND User__r.IsActive = TRUE
					]) {
							set_eligibleUserIds.add(objUserRole.User__c);
					}
			}

			return set_eligibleUserIds;
	}

	//Chnages By AKS Dated 10th Sept 2019
	//Given by Ashveej
	private void UpdateCaseOwner(List<Case> lstCases, Map<ID, Case> oldCaseMap) {
			if (oldCaseMap != null) {
					//get QueueId
					string mwQueueId = Label.MF_FollowUp_QueueId;
					for (Case cse : lstCases) {
							if (
									(cse.RecordTypeId == recordTypeNameIdMap.get('MF Member/Group Updates') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('MF NHE') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('MF QLE') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('MF Termination')) &&
									cse.Status == 'Submitted' &&
									cse.Follow_Up_Date__c != null &&
									cse.Follow_Up_Date__c != oldCaseMap.get(cse.id).Follow_Up_Date__c &&
									cse.OwnerId != mwQueueId &&
									UserUtils.setMOpsIntegrationUsers.contains(cse.OwnerId)
							) {
									cse.OwnerId = mwQueueId;
							}
					}
			}
	}

	/*
Author: Pradeep Chary
Date: 02/09/2023
Desc: Update Case Owner information with User Details
*/
	public void updateCaseOwnerInformation(List<Case> list_Cases, Map<Id, Case> map_OldCaseById) {
			User objCurrentUser = GlobalQueryHelper.getUserInfoById(UserInfo.getUserId());
			if (map_OldCaseById != null) {
					for (Case objCase : list_Cases) {
							Case objOldCase = map_OldCaseById.get(objCase.Id);
							if (
									((objOldCase != null && objCase.OwnerId != objOldCase.OwnerId) || objCase.Case_Owner_Role__c == null) &&
									String.valueOf(objCase.OwnerId).startsWith('005') &&
									objCurrentUser.Data_Migration_Validation__c == false
							) {
									User objUser = map_AllUsers.get(objCase.OwnerId);

									// sometimes when the owner is inactive, GlobalQueryHelper.getUserInfoById will return null
									if (objUser != null) {
											objCase.Owner_Class__c = objUser.Class_Queue__c;
											objCase.Benefits_Owner_Class__c = objUser.Benefits_Class__c;
											if (objUser.Secondary_Role__c == null) {
													objCase.Case_Owner_Role__c = objUser.UserRole.Name;
											} else {
													objCase.Case_Owner_Role__c = objUser.Secondary_Role__c;
											}
									}
							} else if (objCase.OwnerId != objOldCase.OwnerId && String.valueOf(objCase.OwnerId).startsWith('00G') && objCurrentUser.Data_Migration_Validation__c == false) {
									objCase.Owner_Class__c = '';
									objCase.Benefits_Owner_Class__c = '';
									objCase.Case_Owner_Role__c = '';
									objCase.Closed_Owner_Role__c = '';
							} else if (
									objOldCase != null &&
									objCase.Status != objOldCase.Status &&
									!CaseUtils.set_ClosedCaseStatuses.contains(objOldCase.Status) &&
									CaseUtils.set_ClosedCaseStatuses.contains(objCase.Status) &&
									String.valueOf(objCase.OwnerId).startsWith('005')
							) {
									User objUser = map_AllUsers.get(objCase.OwnerId);
									if (objUser != null) {
											objCase.Closed_Owner_Role__c = objUser.UserRole.Name;
									}
							}
					}
			} else {
					for (Case objCase : list_Cases) {
							if (String.valueOf(objCase.OwnerId).startsWith('005') && objCurrentUser.Data_Migration_Validation__c == false) {
									User objUser = map_AllUsers.get(objCase.OwnerId);

									// sometimes when the owner is inactive, GlobalQueryHelper.getUserInfoById will return null
									if (objUser != null) {
											objCase.Owner_Class__c = objUser.Class_Queue__c;
											objCase.Benefits_Owner_Class__c = objUser.Benefits_Class__c;
											objCase.Closed_Owner_Role__c = objUser.UserRole.Name;
											if (objUser.Secondary_Role__c == null) {
													objCase.Case_Owner_Role__c = objUser.UserRole.Name;
											} else {
													objCase.Case_Owner_Role__c = objUser.Secondary_Role__c;
											}
									}
							} else if (String.valueOf(objCase.OwnerId).startsWith('00G') && objCurrentUser.Data_Migration_Validation__c == false) {
									objCase.Owner_Class__c = '';
									objCase.Benefits_Owner_Class__c = '';
									objCase.Case_Owner_Role__c = '';
									objCase.Closed_Owner_Role__c = '';
							}
					}
			}
	}

	/*
	Author: Atul Hinge
	Date: 03/20/2024
	Desc: Update Partner Account field on Case with Reseller Account or If Account is Embedded Company then populate  Sold By
	*/
	public void updatePartnerAccountBeforeUpdate(List<Case> list_Cases, Map<Id, Case> map_Oldcase) {
		for (Case objCase : list_Cases) {
			Case objOldcase = map_Oldcase.get(objCase.Id);
			if (
				objCase.RecordTypeId == CaseUtils.RECTYPE_GEP_CX && (objCase.RecordTypeId != objOldCase.RecordTypeId || objCase.AccountId != objOldCase.AccountId || objCase.Partner_Account__c == null)
			) {
				Id idEmbeddedPartner = getEmbeddedPartnerId(objCase);
				if (idEmbeddedPartner != null) {
					objCase.Partner_Account__c = idEmbeddedPartner;
				}
			}
		}
	}

	/**
	 * @description   Identify Embedded Parter
	 * @param objCase New verion of Case
	 * @return		`Id`
	 */
	private Id getEmbeddedPartnerId(Case objCase) {
		Account objAccount = map_Accounts.get(objCase.AccountId);
		if (objAccount == null) {
			return null;
		}

		if (objAccount.Date_of_GEP_Live__c == null || objAccount.Date_of_GEP_Live__c <= Date.today()) {
			return objAccount.Sold_By__c ?? objAccount.Referred_By__c;
		}

		return null;
	}

	/*
	Author: Atul Hinge
	Date: 03/20/2024
	Desc: Update Partner Account field on Case with Reseller Account or If Account is Embedded Company then populate  Sold By
	*/
	public void updatePartnerAccount(List<Case> list_Cases) {
		List<Case> list_partnerAccountCases = new List<Case>();
		for (Case objCase : list_Cases) {
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_GEP_CX) {
				Id idEmbeddedPartner = getEmbeddedPartnerId(objCase);
				if (idEmbeddedPartner != null) {
					list_partnerAccountCases.add(new Case(Id = objCase.Id, Partner_Account__c = idEmbeddedPartner));
				}
			}
		}
			if (list_partnerAccountCases.size() > 0) {
					Boolean skipTrigger = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;
					CaseTriggerHandler.blnSkipBeforeUpdate = true;
					CaseTriggerHandler.blnSkipAfterUpdate = true;
					update list_partnerAccountCases;
					CaseTriggerHelper.skipTrigger = skipTrigger;
					CaseTriggerHandler.blnSkipBeforeUpdate = false;
					CaseTriggerHandler.blnSkipAfterUpdate = false;
			}
	}
	/*
Author: Atul Hinge
Date: 05/30/2024
Desc: Update Partner Account field on Case with Reseller Account or If Account is Embedded Company then populate  Sold By
*/
	public void autoCloseGEPCXLeakageCases(List<Case> list_Cases) {
			setCaseReasonClassification();
			List<Case> autoCloseGEPCXLeakageCaseList = new List<Case>();
			List<Case> list_autoRouteGEPCXLeakageCaseList = new List<Case>();
			List<Messaging.SingleEmailMessage> list_mails = new List<Messaging.SingleEmailMessage>();
			List<OrgWideEmailAddress> list_OrgWideEmail = GlobalQueryHelper.getOrgWideEmailByAdd(CaseUtils.NO_REPLY_EMAIL);
			Map<String, GEPPartnerDetails__c> ardiusPartnerDetailsMap = new Map<String, GEPPartnerDetails__c>();
			List<GEPPartnerDetails__c> ardiusPartnerDetailsList = GEPPartnerDetails__c.getall().values();
			EmailTemplate empTemplateRec = map_EmailTemplates.get(CaseUtils.GEP_CX_AUTO_CLOSE_EMAIL_TEMPLATE);
			for (GEPPartnerDetails__c apdObject : ardiusPartnerDetailsList) {
					ardiusPartnerDetailsMap.put(apdObject.Account_Id__c, apdObject);
			}

			for (Case objCase : list_Cases) {
					Account objAccount = map_Accounts.get(objCase.AccountId);
					Contact objContact = map_Contacts.get(objCase.ContactId);
					if (
							objAccount != null &&
							objAccount.RecordTypeId == AccountUtil.EMBEDDED_COMPANY_ACCOUNT_RT_ID &&
							objContact != null &&
							(
                           	 objCase.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT ||
                             (objCase.RecordTypeId != CaseUtils.RECTYPE_ENGAGEMENT && objCase.Origin == CaseUtils.ORIGIN_GUSTO && objCase.Channel__c == CaseUtils.CHANNEL_EMAIL)
                        	) &&
							objCase.Status != CaseUtils.STATUS_CLOSED &&
							ardiusPartnerDetailsMap.containsKey(objAccount.Sold_By__c)
					) {
							GEPPartnerDetails__c apdObject = ardiusPartnerDetailsMap.get(objAccount.Sold_By__c);
							autoCloseGEPCXLeakageCaseList.add(
									new Case(
											Id = objCase.Id,
											Status = CaseUtils.STATUS_CLOSED,
											Audience__c = CaseUtils.AUDIENCE_OTHER,
											Skip_Survey__c = true,
											Confirm_Case_Reason__c = CaseUtils.STR_GEP_ER_AUTOCLOSE_CASE_REASON,
											Confirm_Case_Reason_Classification__c = allClassMap.get(CaseUtils.STR_GEP_ER_AUTOCLOSE_CASE_REASON)?.Id,
											OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_PAYROLL_CARE_NON_ACTIONABLE)
									)
							);
							Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
							List<String> sendTo = new List<String>();
							sendTo.add(objContact.Email);
							mail.setToAddresses(sendTo);
							mail.setOrgWideEmailAddressId(list_OrgWideEmail[0].Id);
							String subject = empTemplateRec.Subject;
							subject = subject.replaceAll('\\{!Case.CaseNumber\\}', objCase.CaseNumber);
							mail.setSubject(subject);
							String strEmailBody = empTemplateRec.HtmlValue;
							String strPartnerName = apdObject.Partner_Name__c ?? apdObject.Name ?? '';
							String strPartnerPhoneNumber = apdObject.PartnerPhoneNumber__c ?? '';
							String strPartnerSupportEmailAddress = apdObject.PartnerSupportEmailAddress__c ?? '';
							strEmailBody = strEmailBody.replaceAll('\\{!Contact.FirstName\\}', objContact.Name);
							strEmailBody = strEmailBody.replaceAll('\\{!PartnerName\\}', strPartnerName);
                			strEmailBody = strEmailBody.replaceAll('\\{!PartnerPhoneNumber\\}', strPartnerPhoneNumber);
                			strEmailBody = strEmailBody.replaceAll('\\{!PartnerSupportEmailAddress\\}', strPartnerSupportEmailAddress);

							mail.setHtmlBody(strEmailBody);
							mail.setWhatId(objCase.id);
							mail.setSaveAsActivity(true);
							mail.setUseSignature(false);
							list_mails.add(mail);
					}
					if (
							objAccount != null &&
							(objAccount.RecordTypeId == AccountUtil.PARTNER_RT_ID ||
							objAccount.RecordTypeID == AccountUtil.RESELLER_ACCOUNT_RT_ID) &&
							objAccount.Type == AccountUtil.EMBEDDED_PARTNER_TYPE &&
							objCase.RecordTypeId != CaseUtils.RECTYPE_GEP_CX
					) {
							list_autoRouteGEPCXLeakageCaseList.add(
									new Case(
											Id = objCase.Id,
											Status = CaseUtils.STATUS_NEW,
											RecordTypeID = CaseUtils.RECTYPE_GEP_CX,
											OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_GEP_CX_QUEUE),
											Type = CaseUtils.TYPE_GEP_PAYROLL
									)
							);
					}
			}

			Boolean skipCaseTrigger = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;

			if (OrganizationUtilities.canSendEmails() && list_mails.size() > 0) {
					EmailMessageTriggerHelper.skipTrigger = true;
					Messaging.sendEmail(list_mails);
			}
			if (autoCloseGEPCXLeakageCaseList.size() > 0) {
					update autoCloseGEPCXLeakageCaseList;
			}
			CaseTriggerHelper.skipTrigger = skipCaseTrigger;
			if (list_autoRouteGEPCXLeakageCaseList.size() > 0) {
					update list_autoRouteGEPCXLeakageCaseList;
			}
	}
	/*
Author: Alex
Date: 4/7/2020
Desc: update case with assignment rule and check the Send Survey field
*/
	@future
	public static void doAssignmentRuleUpdate(Map<Id, Boolean> map_CaseIdsToSendSurvey) {
			List<Case> list_CasesToUpdate = new List<Case>();
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			for (Id caseId : map_CaseIdsToSendSurvey.keySet()) {
					Case caseToUpdate = new Case(Id = caseId, Deflection_Status__c = 'Reopened', Send_Survey__c = map_CaseIdsToSendSurvey.get(caseId));
					caseToUpdate.setOptions(dmo);
					list_CasesToUpdate.add(caseToUpdate);
			}
			Boolean skipTrigger = CaseTriggerHelper.skipTrigger;
			CaseTriggerHelper.skipTrigger = true;
			update list_CasesToUpdate;
			CaseTriggerHelper.skipTrigger = skipTrigger;
	}

	//Alex: generate a 10 digit string to make privacy request confirmation code
	//append total string to the field
	public static String generateConfirmationCode(Case caseRecord) {
			Integer codeLength = 10;
			Blob blobKey = crypto.generateAesKey(128);
			String key = EncodingUtil.convertToHex(blobKey);
			String code = key.substring(0, codeLength);
			String confirmationCode = caseRecord.caseNumber + code;

			return confirmationCode;
	}
	//Alex: create and send an email for the privacy requester
	//with link to portal and confirmation code
	public static void sendPrivacyRequestEmail(List<String> list_EmailAddresses, List<String> list_EmailBodies, List<String> list_EmailSubjects) {
			List<Messaging.SingleEmailMessage> list_mails = new List<Messaging.SingleEmailMessage>();

			List<OrgWideEmailAddress> list_OrgWideEmail = GlobalQueryHelper.getOrgWideEmailByAdd('no-reply@gusto.com'); //Alex: in UAT and Production should be no-reply@gusto.com
			for (Integer i = 0; i < list_EmailAddresses.size(); i++) {
					if (!String.isBlank(list_EmailSubjects[i])) {
							Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
							List<String> sendTo = new List<String>();
							sendTo.add(list_EmailAddresses[i]);
							mail.setToAddresses(sendTo);
							mail.setOrgWideEmailAddressId(list_OrgWideEmail[0].Id);
							mail.setSubject(list_EmailSubjects[i]);
							mail.setHtmlBody(list_EmailBodies[i]);
							mail.setUseSignature(false);
							list_mails.add(mail);
					}
			}
			if (OrganizationUtilities.canSendEmails()) {
					Messaging.sendEmail(list_mails);
			}
	}

	/*
Author: Alex
go through privacy requests changed to Identity Verified
create new Data Collection records on the request
*/
	public void createDataCollectionRecords(List<Id> list_Approved) {
			//get Data Use Case Values
			List<String> list_DataUseCaseValues = new List<String>();
			Schema.DescribeFieldResult fieldResult = Data_Collection__c.Data_Use_Case__c.getDescribe();
			List<Schema.PicklistEntry> list_ple = fieldResult.getPicklistValues();
			for (Schema.PicklistEntry pickListVal : list_ple) {
					list_DataUseCaseValues.add(pickListVal.getLabel());
			}
			List<Data_Collection__c> list_DataCollectionRecords = new List<Data_Collection__c>();
			List<Id> list_PrivacyRequestsApproved = CaseQueryHelper.getPrivacyRequestsApprovedForDisclosure(list_Approved);
			for (Id caseId : list_PrivacyRequestsApproved) {
					for (String useCase : list_DataUseCaseValues) {
							Data_Collection__c dc = new Data_Collection__c(Case__c = caseId, Data_Use_Case__c = useCase, Status__c = 'New');
							list_DataCollectionRecords.add(dc);
					}
			}
			insert list_DataCollectionRecords;
	}

	/*
Author: Alex
Close all Data Collection Records that belong to this case
*/
	public void closeDataCollectionRecords(List<Id> list_Closed) {
			List<Data_Collection__c> list_DataCollectionsToClose = CaseQueryHelper.getDataCollection(list_Closed);
			if (!list_DataCollectionsToClose.isEmpty()) {
					for (Data_Collection__c dc : list_DataCollectionsToClose) {
							if (dc.Status__c != 'Completed') {
									dc.Status__c = 'Closed';
							}
					}
			}
			update list_DataCollectionsToClose;
	}

	public void processCaseFulfillmentStatus(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			List<Case_Fulfillment_Selection_Status__c> fulfillmentStatusList = new List<Case_Fulfillment_Selection_Status__c>();
			Map<Id, List<String>> map_caseIdSelectionIds = new Map<Id, List<String>>();
			Map<Id, List<String>> map_caseIdSelectionUUIds = new Map<Id, List<String>>();

			List<Case> list_caseToProcess = new List<Case>();
			for (Case newCase : newCaseMap.values()) {
					Case oldCase = oldCaseMap.get(newCase.Id);
					if (
							(newCase.Type == 'NHE' ||
							newCase.Type == 'Termination') &&
							((newCase.Automation_Status__c != null &&
							(newCase.Automation_Status__c == 'Completed' ||
							newCase.Automation_Status__c == 'Failed') &&
							newCase.Automation_Status__c != oldCase.Automation_Status__c) ||
							(newCase.Status != 'Followup Completed' &&
							newCase.Automation_Status_Follow_Up__c != null &&
							newCase.Automation_Status_Follow_Up__c == 'Completed' &&
							newCase.Automation_Status_Follow_Up__c != oldCase.Automation_Status_Follow_Up__c &&
							!newCase.Form_Sent_Automatically__c)) &&
							newCase.RecordTypeId != recordTypeNameIdMap.get(CASE_TAXRES_RECORDTYPE)
					) {
							list_caseToProcess.add(newCase);
					}
			}

			if (list_caseToProcess.isEmpty()) {
					return;
			}

			Map<Id, Case> map_caseToProcess = new Map<Id, Case>(list_caseToProcess);

			for (Case_Fulfillment_Selection_Status__c objEachRecord : [
					SELECT Case__c, Selection_Id__c, Selection_UUID__c
					FROM Case_Fulfillment_Selection_Status__c
					WHERE Case__c IN :map_caseToProcess.keySet()
			]) {
					if (String.isNotBlank(objEachRecord.Selection_UUID__c)) {
							if (!map_caseIdSelectionUUIds.containsKey(objEachRecord.Case__c)) {
									map_caseIdSelectionUUIds.put(objEachRecord.Case__c, new List<String>{ objEachRecord.Selection_UUID__c });
							} else {
									map_caseIdSelectionUUIds.get(objEachRecord.Case__c).add(objEachRecord.Selection_UUID__c);
							}
					}

					if (String.isNotBlank(objEachRecord.Selection_Id__c)) {
							if (!map_caseIdSelectionIds.containsKey(objEachRecord.Case__c)) {
									map_caseIdSelectionIds.put(objEachRecord.Case__c, new List<String>{ objEachRecord.Selection_Id__c });
							} else {
									map_caseIdSelectionIds.get(objEachRecord.Case__c).add(objEachRecord.Selection_Id__c);
							}
					}
			}

			for (Case c : list_caseToProcess) {
					//Create Case_Fulfillment_Selection_Status__c records, when case.Selection_UUIds__c is not blank and case is not submitted.
					if (c.Selection_UUIds__c != null) {
							List<String> list_caseUUIds = new List<String>();
							if (map_caseIdSelectionUUIds.containsKey(c.Id)) {
									list_caseUUIds = map_caseIdSelectionUUIds.get(c.Id);
							}
							for (String strUUId : c.Selection_UUIds__c.split(';')) {
									if (list_caseUUIds.contains(strUUId)) {
											continue;
									}

									fulfillmentStatusList.add(new Case_Fulfillment_Selection_Status__c(Case__c = c.Id, Selection_UUID__c = strUUId, Processing_State__c = 'Queued'));
							}
					} else if (c.Selection_Ids__c != null) {
							List<String> list_caseSelectIds = new List<String>();
							if (map_caseIdSelectionIds.containsKey(c.Id)) {
									list_caseSelectIds = map_caseIdSelectionIds.get(c.Id);
							}
							for (String strSelectId : c.Selection_Ids__c.split(';')) {
									if (list_caseSelectIds.contains(strSelectId)) {
											continue;
									}

									fulfillmentStatusList.add(new Case_Fulfillment_Selection_Status__c(Case__c = c.Id, Selection_Id__c = strSelectId, Processing_State__c = 'Queued'));
							}
					}
			}

			if (fulfillmentStatusList.size() > 0) {
					insert fulfillmentStatusList;
			}
	}

	/*By: PR, Date:7/10/2019, 
Desc: if MB cases "Complaint Type" field value changes to any value present in "set_MBComplaintTypesForTicketCreation" we want to create
Ticket record but only if no previous ticket record is present for that Case    
*/
	public void createTicketForMBComplaint(list<Id> lst_CaseIds) {
			if (lst_CaseIds != null && lst_CaseIds.size() > 0) {
					set<id> set_CasesWithExisitingTicket = new Set<id>();
					list<Ticket__c> lst_toInsertTickets = new List<Ticket__c>();

					for (Ticket__c ticketObj : [SELECT id, Case__c FROM Ticket__c WHERE Case__c IN :lst_CaseIds]) {
							set_CasesWithExisitingTicket.add(ticketObj.Case__c);
					}

					if (set_CasesWithExisitingTicket.size() != lst_CaseIds.size()) {
							for (ID caseIdStr : lst_CaseIds) {
									if (!set_CasesWithExisitingTicket.contains(caseIdStr)) {
											Ticket__c ticketObj = new Ticket__c();
											ticketObj.Case__c = caseIdStr;
											ticketObj.Status__c = 'New';
											ticketObj.RecordTypeId = cache.getRecordTypeId('Ticket__c', 'MB Compliance');
											lst_toInsertTickets.add(ticketObj);
									}
							}

							if (lst_toInsertTickets.size() > 0) {
									try {
											insert lst_toInsertTickets;
									} catch (exception ex) {
											ExceptionLogUtil.logException('CaseTriggerHelper', 'createTicketForMBComplaint', ex.getMessage(), ex.getStackTraceString());
									}
							}
					}
			}
	}

	/**
	 * @Author          : Alex Xiong
	 * @Description     : If Case Owner is Inactive, reassign Case to Care Routing or Auto close queue
	 * @Parm            : list_Case - a list of Cases
	 * @Return          : N/A
	 */
	public void updateInactiveOwners(list<Case> list_Case) {
			Set<Id> set_OwnerId = new Set<Id>();
			Set<Id> set_InactiveUserIds = new Set<Id>();

			for (Case objCase : list_Case) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(objCase.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							if (String.valueOf(objCase.OwnerId).startsWith('005')) {
									set_OwnerId.add(objCase.OwnerId);
							}
					}
			}

			if (!set_OwnerId.isEmpty()) {
					for (Id idOwner : set_OwnerId) {
							if (!map_AllUsers.containsKey(idOwner)) {
									set_InactiveUserIds.add(idOwner);
							}
					}

					if (!set_InactiveUserIds.isEmpty()) {
							Map<String, UserRole> map_UserRolesByName = GlobalQueryHelper.getNameUserRoleMap();
							UserRole objEngagementRole = map_UserRolesByName.get('Engagement');
							Set<Id> set_SubordinateRoleIds = GlobalQueryHelper.getSubordinateRoles(new Set<Id>{ objEngagementRole.Id });
							set_SubordinateRoleIds.add(objEngagementRole.Id);
							Id idCareRoutingQueue = nameIdQueueMap.get('Care_Routing');

							for (Case objCase : list_Case) {
									if (set_InactiveUserIds.contains(objCase.OwnerId)) {
											String strCaseRecTypeName = Cache.getRecordTypeName('Case', objCase.RecordTypeId);
											if (
													(objCase.Origin == 'Phone' || (objCase.Origin == 'Gusto' && objCase.Channel__c == 'Phone')) &&
													map_AllUsers.containsKey(objCase.OwnerId) &&
													set_SubordinateRoleIds.contains(map_AllUsers.get(objCase.OwnerId).UserRoleId)
											) {
													objCase.OwnerId = nameIdQueueMap.get('Payroll_Care_Auto_Close');
											} else {
													if (strCaseRecTypeName?.equalsIgnoreCase(CaseUtils.TYPE_ENGAGEMENT)) {
															objCase.OwnerId = nameIdQueueMap.get('Engagement_Cases');
															objCase.Case_In_Route__c = true;
													} else if (strCaseRecTypeName?.equalsIgnoreCase(CaseUtils.TYPE_MODERN_BANK)) {
															objCase.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_NAME_MODERN_BANK_ROUTING);
													}
											}
									}
							}
					}
			}
	}

	/**
	 * @author Alex Xiong
	 * @description update Class fields when Cases are solved
	 * @param list of solved cases
	 */
	public void updateClassInfoOnceCaseIsSolved(List<Case> list_CaseRecords) {
			if (list_CaseRecords?.size() > 0) {
					if (map_CaseReasonsById == null || map_CaseReasonsById.isEmpty()) {
							setCaseReasonClassification();
					}

					for (Case objCase : list_CaseRecords) {
							if (String.isNotBlank(objCase.Confirm_Case_Reason_Classification__c)) {
									objCase.Class__c = map_CaseReasonsById.get(objCase.Confirm_Case_Reason_Classification__c).Class__c;
									// BTE-1227 : Set priority when confirm case reason is updated on solve a case
									objCase.Priority = map_CaseReasonsById.get(objCase.Confirm_Case_Reason_Classification__c).Priority__c;
							}

							if (String.valueOf(objCase.OwnerId).startsWith('005')) {
									User objUser = GlobalQueryHelper.getUserInfoById(objCase.OwnerId);

									objCase.Owner_Class__c = objUser?.Class_Queue__c;
									objCase.Benefits_Owner_Class__c = objUser?.Benefits_Class__c;
							}
					}
			}
	}

	/*
	By: PR
	Date: 5/27/2019
	Description: Following method is receiving Integration_id set of cases with modified "Follow_Up_Completed_by__c" field.
		When every case with same integration id has “Follow up Completed by” != null update "HI_Fulfillment_Event_Completed_Date__c" field value for latest case.
*/
	public void populateFulfillmentEventCompletedDate(set<string> caseIntegrationIdSet) {
			if (caseIntegrationIdSet != null && caseIntegrationIdSet.size() > 0) {
					map<string, case> latestIntegrationIdCasemap = new Map<string, case>();
					set<string> notEligibleIntegrationIdSet = new Set<string>();

					for (Case rec : [SELECT id, Integration_Id__c, Follow_Up_Completed_by__c, createdDate FROM Case WHERE Integration_Id__c IN :caseIntegrationIdSet ORDER BY createdDate DESC]) {
							if (rec.Follow_Up_Completed_by__c != null && !notEligibleIntegrationIdSet.contains(rec.Integration_Id__c)) {
									if (latestIntegrationIdCasemap.containsKey(rec.Integration_Id__c)) {
											if (latestIntegrationIdCasemap.get(rec.Integration_Id__c).CreatedDate < rec.CreatedDate) {
													latestIntegrationIdCasemap.put(rec.Integration_Id__c, rec);
											}
									} else {
											latestIntegrationIdCasemap.put(rec.Integration_Id__c, rec);
									}
							} else {
									notEligibleIntegrationIdSet.add(rec.Integration_Id__c);
									if (latestIntegrationIdCasemap.containsKey(rec.Integration_Id__c)) {
											latestIntegrationIdCasemap.remove(rec.Integration_Id__c);
									}
							}
					}

					if (latestIntegrationIdCasemap.keyset().size() > 0) {
							list<Case> toUpdateCaseList = new List<Case>();
							set<string> caseIdProcessed = new Set<string>();
							for (Case caseRec : latestIntegrationIdCasemap.values()) {
									if (!caseIdProcessed.contains(caseRec.Id)) {
											caseIdProcessed.add(caseRec.Id);
											Case csRec = new Case(id = caseRec.Id, HI_Fulfillment_Event_Completed_Date__c = system.now());
											toUpdateCaseList.add(csRec);
									}
							}

							if (toUpdateCaseList.size() > 0) {
									try {
											caseTriggerHelper.skipTrigger = true;
											update toUpdateCaseList;
									} catch (exception ex) {
											ExceptionLogUtil.logException('CaseTriggerHelper', 'populateFulfillmentEventCompletedDate', ex.getMessage(), ex.getStackTraceString());
									}
							}
					}
			}
	}

	/*
	By: PR
	Date: Aug 9 2018
	Description: This method is accepting list of case records that fullfill following condition as a parameter
					RecordType = Benefits Care and Type = Suspension Audit
					
				 Further down in the method we are querying Account COntact Relationship object record using Case Account
				 as a filter. And we are sending Auto response email to all the contacts having Admin relationship
				 
				 We are using   Custom label Suspension_Case_Audit_Email_Template_Unique_Name for Email Template ID
				 and Custom label Suspension_Case_Audit_Email_From_Address to get from address
				 
				 We are calling this method from After Insert method
*/
	public void autoResponseEmailForSuspensionAuditCases(list<Case> suspensionCaseList) {
			set<string> companyIdSet = new Set<string>();
			set<Id> contactIdSet = new Set<id>();
			list<Case> eligibleCaseList = new List<Case>();
			map<id, id> accountIdPrimaryAdminContactIdMap = new Map<id, id>();
			map<string, string> companyIdAdminContactIdMap = new Map<string, string>();
			map<id, id> contactToCaseIdMap = new Map<id, id>();

			id emailTemplateId;
			id orgwideEmailId;

			for (Case cas : suspensionCaseList) {
					if (cas.ZP_Company_Id__c != null) {
							companyIdSet.add(cas.ZP_Company_Id__c);
					}

					if (cas.ContactId != null) {
							contactIdSet.add(cas.ContactId);
							eligibleCaseList.add(cas);
							contactToCaseIdMap.put(cas.ContactId, cas.Id);
					}
			}

			if (companyIdSet.size() > 0 && eligibleCaseList.size() > 0) {
					companyIdAdminContactIdMap = getCompanyIdAdminContactRelationShip(suspensionCaseList);

					//querying Email-Template details based on Custom label : "Suspension_Case_Audit_Email_Template_Unique_Name" value
					if (map_EmailTemplates.containsKey(Label.Suspension_Case_Audit_Email_Template_Unique_Name)) {
							emailTemplateId = map_EmailTemplates.get(Label.Suspension_Case_Audit_Email_Template_Unique_Name).Id;
					}

					List<OrgWideEmailAddress> owEmailist = GlobalQueryHelper.getOrgWideEmailByAdd(Label.Suspension_Case_Audit_Email_From_Address);

					if (owEmailist.size() > 0) {
							orgwideEmailId = owEmailist.get(0).id;
					}

					list<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();

					for (Case cas : eligibleCaseList) {
							Messaging.SingleEmailMessage emailRec = new Messaging.SingleEmailMessage();
							emailRec.setTemplateId(emailTemplateId);

							if (cas.ZP_Company_Id__c != null && companyIdAdminContactIdMap.containsKey(cas.ZP_Company_Id__c) && companyIdAdminContactIdMap.get(cas.ZP_Company_Id__c) != null) {
									List<id> ccList = companyIdAdminContactIdMap.get(cas.ZP_Company_Id__c).split(',');

									/* we only want to send the email 
				1) if contact is attached with the case and
				2) contact attached is an Admin
				*/
									if (cas.ContactId != null && ccList.contains(cas.ContactId)) {
											emailRec.setToAddresses(new List<string>{ cas.ContactId });
											emailRec.settargetObjectId(cas.ContactId);
									} else {
											continue;
									}

									if (ccList != null && ccList.size() > 0 && ccList.contains(cas.ContactId)) {
											set<id> ccTempSet = new Set<id>();
											ccTempSet.addAll(ccList);
											ccTempSet.remove(cas.ContactId);
											ccList = new List<id>();
											ccList.addAll(ccTempSet);
									}

									if (ccList.size() > 0) {
											emailRec.setccAddresses(ccList);
									}
							}

							emailRec.setWhatId(cas.id);
							emailRec.setSaveAsActivity(true);
							emailRec.setOrgWideEmailAddressId(orgwideEmailId);
							singleEmailList.add(emailRec);
					}

					if (singleEmailList.size() > 0) {
							List<User> userList = GlobalQueryHelper.getListOfUserbyEmail(BIZTECH_ERROR_EMAIL);
							String errorDetailStr;
							List<Case> caseListToUpdate = new List<Case>();
							Set<String> set_CaseIds = new Set<String>();

							Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
							if (userList.size() > 0) {
									String[] toAddresses = new List<String>{ userList.get(0).id };
									mail.setToAddresses(toAddresses);
									mail.setSubject('Suspension Case Error Log');
							}

							List<Messaging.SendEmailResult> list_MessagingResults = new List<Messaging.SendEmailResult>();
							if (OrganizationUtilities.canSendEmails()) {
									list_MessagingResults = Messaging.sendEmail(singleEmailList, false);
							}

							/*Error handling code*/
							if (list_MessagingResults != null && !list_MessagingResults.isEmpty()) {
									for (Messaging.SendEmailResult objMessagingResult : list_MessagingResults) {
											if (!objMessagingResult.isSuccess()) {
													List<Messaging.SendEmailError> list_EmailErrors = objMessagingResult.getErrors();

													for (Messaging.SendEmailError objEmailError : list_EmailErrors) {
															String strCaseId = contactToCaseIdMap.get(objEmailError.getTargetObjectId());

															if (!set_CaseIds.contains(strCaseId)) {
																	set_CaseIds.add(strCaseId);

																	Case objTempCase = new Case(Id = strCaseId, Suspension_Audit_Email_Failed__c = true);
																	caseListToUpdate.add(objTempCase);
															}

															String strErrorMessage = ' Email Failure CaseId: ' + strCaseId + '. \n\r Error Message: ' + objEmailError.getMessage();
															if (String.isBlank(errorDetailStr)) {
																	errorDetailStr = strErrorMessage;
															} else {
																	errorDetailStr += '\n\r ' + strErrorMessage;
															}
													}
											}
									}
							}

							if (errorDetailStr != null && userList.size() > 0) {
									mail.setHTMLBody(errorDetailStr);
									if (OrganizationUtilities.canSendEmails()) {
											Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
									}
							}

							if (caseListToUpdate.size() > 0) {
									CasetriggerHelper.SkipTrigger = true;
									update caseListToUpdate;
									CasetriggerHelper.SkipTrigger = false;
							}
					}
			}
	}

	/*
	By: PR
	Date: 10/23/18
	Description: Following method is receving list of Case records as a parameter
				and returns map of (ZP_CompanyId : rmk1) and (Comma separated string of related Contact ids: rmk2)
				if primary admin for z company exists then first value on "rmk2" will be primary contact id.
				
	Logic: We are extracting Zp_company_id from case in a set: s1.
		   we are querying related ZP_User_role records to get related User Id set: s2 using set s1 from above.
		   We are querying related Contact records to get related Contact id set: s3 using set s2 from above.
		   
		   Finally using s2 and s3 we are establishing the relation between Company Id and related ContactIds
		   
   Note: We are making sure that primary contact Id is always first value for a company id.
						 

*/
	public map<string, string> getCompanyIdAdminContactRelationShip(list<Case> caseList) {
			set<string> companyIdSet = new Set<string>();
			map<string, string> companyIdAdminContactIdMap = new Map<string, string>();

			for (Case cas : caseList) {
					if (cas.ZP_Company_Id__c != null) {
							companyIdSet.add(cas.ZP_Company_Id__c);
					}
			}

			if (companyIdSet.size() > 0) {
					map<string, list<string>> companyIdUserIDMap = new Map<string, list<string>>();
					map<string, string> primaryUserIDContactIdMap = new Map<string, string>();
					map<string, string> userIDContactIdMap = new Map<string, string>();
					set<string> userIdSet = new Set<string>();

					// we only want to query user role records where type has Admin word present in it.
					List<ZP_User_Role__c> list_ZProlesList = CaseQueryHelper.getListofZpUserRoles(companyIdSet, '%Admin%');
					for (ZP_User_Role__c rec : list_ZProlesList) {
							if (rec.Is_Primary__c) {
									primaryUserIDContactIdMap.put(rec.User_Id__c, '');
							}

							List<String> tempUserIdMap = new List<String>();
							if (companyIdUserIDMap.containsKey(rec.Company_Id__c)) {
									tempUserIdMap = companyIdUserIDMap.get(rec.Company_Id__c);
							}
							tempUserIdMap.add(rec.User_Id__c);

							companyIdUserIDMap.put(rec.Company_Id__c, tempUserIdMap);
							userIdSet.add(rec.User_Id__c);
					}

					if (userIdSet.size() > 0) {
							List<Contact> list_userIdConList = CaseQueryHelper.getContactbyZPUserId(userIdSet);
							for (Contact con : list_userIdConList) {
									if (primaryUserIDContactIdMap.containsKey(con.ZP_User_Id__c)) {
											primaryUserIDContactIdMap.put(con.ZP_User_Id__c, con.id);
											continue;
									}

									String contactIdString = '';
									if (userIDContactIdMap.containsKey(con.ZP_User_Id__c)) {
											contactIdString = userIDContactIdMap.get(con.ZP_User_Id__c);
									}

									if (string.isBlank(contactIdString)) {
											contactIdString = con.id;
									} else {
											contactIdString += ',' + con.Id;
									}
									userIDContactIdMap.put(con.ZP_User_Id__c, contactIdString);
							}
					}

					// Only execute the below code if we have Company To User and User to Contact details
					if (companyIdUserIDMap.keyset().size() > 0 && (userIDContactIdMap.keyset().size() > 0 || primaryUserIDContactIdMap.size() > 0)) {
							for (string companyId : companyIdUserIDMap.keyset()) {
									string contactIdString = '';
									if (companyIdUserIDMap.get(companyId).size() > 0) {
											for (string userId : companyIdUserIDMap.get(companyId)) {
													if (primaryUserIDContactIdMap.containsKey(userId)) {
															if (string.isBlank(contactIdString)) {
																	contactIdString = primaryUserIDContactIdMap.get(userId);
															} else {
																	contactIdString += ',' + primaryUserIDContactIdMap.get(userId);
															}
													}
													if (userIDContactIdMap.containsKey(userId)) {
															if (string.isBlank(contactIdString)) {
																	contactIdString = userIDContactIdMap.get(userId);
															} else if (!contactIdString.endsWith(',')) {
																	contactIdString += ',' + userIDContactIdMap.get(userId);
															} else {
																	contactIdString += userIDContactIdMap.get(userId);
															}
													}
											}
									}

									if (!string.isBlank(contactIdString)) {
											companyIdAdminContactIdMap.put(companyId, contactIdString);
									}
							}
					}
			}

			return companyIdAdminContactIdMap;
	}

	/*
	By: PR
	Date: 10/23/18
	Description : this method is receiving list of case as a parameter
					This method is called from beforeInsert method of this class
					This method is populating empty ContactId field value for a newly created Case record.
*/
	public void populateAdminContactId(list<Case> caseList) {
			if (caseList != null && caseList.size() > 0) {
					list<Case> caseswithoutContactid = new List<Case>();

					for (case rec : caseList) {
							//Alex: don't run if we're inserting a Privacy Request
							if (!(rec.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
									if (rec.ContactId == null) {
											caseswithoutContactid.add(rec);
									}
							}
					}

					if (caseswithoutContactid.size() > 0) {
							map<string, string> CompanyidAdminContactIdMap = getCompanyIdAdminContactRelationShip(caseswithoutContactid);

							for (case cas : caseswithoutContactid) {
									if (
											cas.ZP_Company_Id__c != null &&
											CompanyidAdminContactIdMap.containsKey(cas.ZP_Company_Id__c) &&
											CompanyidAdminContactIdMap.get(cas.ZP_Company_Id__c) != null
									) {
											List<id> ccList = companyIdAdminContactIdMap.get(cas.ZP_Company_Id__c).split(',');

											if (cas.ContactId == null && ccList.size() > 0) {
													cas.ContactId = ccList.get(0);
											}
									}
							}
					}
			}
	}

	/*
	By: PR
	DOC: Sep 4, 2018
	Desc: Below method is inserting "Account LSI" object records based on 
		   case "Large_Scale_Issue_Classification__c" field.
*/
	public void createAccountLSIRecords(list<Case> lsiCaseList) {
			list<Account_LSI__c> toInsertAccountLsiList = new List<Account_LSI__c>();

			for (Case cas : lsiCaseList) {
					if (cas.Large_Scale_Issue_Classification__c != null && cas.AccountId != null) {
							Account_LSI__c accLsiRec = new Account_LSI__c();
							accLsiRec.Account__c = cas.AccountId;
							accLsiRec.Large_Scale_Issue__c = cas.Large_Scale_Issue_Classification__c;
							toInsertAccountLsiList.add(accLsiRec);
					}
			}

			if (toInsertAccountLsiList.size() > 0) {
					try {
							insert toInsertAccountLsiList;
					} catch (exception ex) {
							ExceptionLogUtil.logException('CaseTriggerHelper', 'createAccountLSIRecords', ex.getMessage(), ex.getStackTraceString());
					}
			}
	}

	private void setEntitlementId(Case objCase, String caseRecordType) {
			if (String.isNotBlank(caseRecordType)) {
					if (caseRecordType.indexOf('Payroll Care') > -1 && String.isNotBlank(objConfigSettings.PayrollCareEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.PayrollCareEntitlementId__c;
							objCase.BusinessHoursId = Label.DefaultBusinessHoursId;
					} else if (caseRecordType.indexOf('Modern Bank') > -1 && String.isNotBlank(objConfigSettings.PayrollCareEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.PayrollCareEntitlementId__c;
							objCase.BusinessHoursId = Label.DefaultBusinessHoursId;
					} else if (caseRecordType.indexOf('Benefits Care') > -1 && String.isNotBlank(objConfigSettings.PayrollCareEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.PayrollCareEntitlementId__c;
							objCase.BusinessHoursId = Label.DefaultBusinessHoursId;
					} else if (caseRecordType.indexOf('Tax Res') > -1) {
							objCase.BusinessHoursId = Label.DefaultBusinessHoursId;
					} else if (caseRecordType.indexOf('PayrollOps Audit') > -1) {
							//DS[27-Oct-2020] : add PayrollOps Audit case Functionality
							objCase.BusinessHoursId = Label.DefaultBusinessHoursId;
					} else if (caseRecordType.indexOf('Tax Ops') > -1 && String.isNotBlank(objConfigSettings.TaxOpsEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.TaxOpsEntitlementId__c;
					} else if (caseRecordType.indexOf('Risk Assurance') > -1 && String.isNotBlank(objConfigSettings.RiskEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.RiskEntitlementId__c;
					} else if (caseRecordType.indexOf('Payroll Compliance') > -1 && String.isNotBlank(objConfigSettings.PayrollComplianceEntitlementId__c)) {
							objCase.EntitlementId = objConfigSettings.PayrollComplianceEntitlementId__c;
					}
			}
	}

	private void closeDuplicateCases(List<Case> caseList) {
			map<String, Case> zendeskCaseMap = new Map<String, Case>();

			if (zendeskIdSet.size() > 0) {
					for (Case c : [SELECT Id, Zendesk_Id__c, Integration_Id__c, Status, ownerId FROM Case WHERE Integration_Id__c IN :zendeskIdSet AND isClosed = FALSE]) {
							zendeskCaseMap.put(c.Integration_Id__c, c);
					}
					for (Case c : caseList) {
							//Alex: don't run if we're inserting a Privacy Request
							if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
									String zendeskId = getZendeskIdFromDescription(c.Description);
									if (zendeskId != '') {
											if (zendeskCaseMap.containsKey(zendeskId)) {
													Case parentCase = zendeskCaseMap.get(zendeskId);
													c.Status = 'Closed';
													c.OwnerId = parentCase.OwnerId;
													c.Closed_Reason__c = 'Merged Duplicate';
													c.ParentId = parentCase.Id;
											}
									}
							}
					}
			}
	}

	private String getZendeskIdFromDescription(String description) {
			if (description == null) {
					description = '';
			}
			integer startPos = description.indexOf('[~~~');
			integer endPos = description.indexOf('~~~]');
			if ((endPos - startPos) > 0) {
					return 'Zendesk-' + description.substring(startPos + 4, endPos);
			} else {
					return '';
			}
	}

	public void setZendeskTicketMap(String caseId, String description) {
			String zendeskId = getZendeskIdFromDescription(description);
			if (zendeskId != '') {
					zendeskIdSet.add(zendeskId);
			}
	}

	public Case_Audit_Log__c getNewCaseAuditLog(Case c) {
			Case_Audit_Log__c log = new Case_Audit_Log__c();
			log.Case__c = c.id;
			log.Event_Type__c = c.Origin;
			log.From_Status__c = 'New Case Created';
			log.Business_Hours__c = c.BusinessHoursId;

			return log;
	}

	public void processStatusChangeRecType(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			List<BusinessHours> bizHours = new List<BusinessHours>();
			for (BusinessHours ObjBh : GlobalQueryHelper.getAllBusinessHoursList()) {
					if (ObjBh.Name == 'Gusto - Denver - Engagement') {
							bizHours.add(ObjBh);
					}
			}

			for (Case c : newCaseMap.values()) {
					Case oldCase = oldCaseMap.get(c.Id);

					if (c.Status != oldCase.Status && c.Status == 'Closed') {
							if (c.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') && c.Type != 'Payroll Suspension') {
									c.RecordTypeId = recordTypeNameIdMap.get('Payroll Care - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Modern Bank')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Modern Bank - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Benefits Compliance')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Benefits Compliance - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Benefits Care')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Benefits Care - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Tax Res')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Tax Res - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Risk Assurance')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Risk Assurance - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Payroll Compliance')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Payroll Compliance - Read Only');
							}
							if (c.RecordTypeId == recordTypeNameIdMap.get('Tax Ops')) {
									c.RecordTypeId = recordTypeNameIdMap.get('Tax Ops - Read Only');
							}
					}
			}
	}

	public void processStatusChangeAuditLog(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			List<BusinessHours> bizHours = new List<BusinessHours>();
			for (BusinessHours ObjBh : GlobalQueryHelper.getAllBusinessHoursList()) {
					if (ObjBh.Name == 'Gusto - Denver - Engagement') {
							bizHours.add(ObjBh);
					}
			}

			List<Case_Audit_Log__c> logList = new List<Case_Audit_Log__c>();
			for (Case c : newCaseMap.values()) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							Case oldCase = oldCaseMap.get(c.Id);
							DateTime statusChange = c.Status_Change_Date_Time__c;
							//DS[27-Oct-2020] : add PayrollOps Audit case Functionality
							//Neha[3-Dec-2020] : Add Case Audit feature for OA tracking
							if (
									oldCase.Status != c.Status &&
									(c.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Payroll Care - Read Only') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Benefits Care') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Benefits Care - Read Only') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Tax Res') ||
									c.RecordTypeId == recordTypeNameIdMap.get('PayrollOps Audit') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Benefits Change Case') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Benefits New Plan Case') ||
									c.RecordTypeId == recordTypeNameIdMap.get('Benefits Renewal Case') ||
									c.RecordTypeId == recordTypeNameIdMap.get(System.Label.Engagement_RecordType_Name))
							) {
									Case_Audit_Log__c log = new Case_Audit_Log__c();
									log.Case__c = c.id;
									log.Event_Type__c = 'Status Change';
									log.From_Status__c = oldCase.Status;
									log.To_Status__c = c.Status;
									log.From_Date_Time__c = statusChange;
									log.To_Date_Time__c = System.now();
									string ownerId = c.ownerId;
									if (ownerId.indexOf('005') == 0) {
											log.Advocate__c = c.ownerId;
									}
									if (bizHours.size() > 0) {
											log.Business_Hours__c = bizHours[0].Id;
											Id hoursId = log.Business_Hours__c;
											DateTime fromTime = log.From_Date_Time__c;
											DateTime toTime = log.To_Date_Time__c;
											if (fromTime != null) {
													Long milliSeconds = BusinessHours.diff(hoursId, fromTime, toTime);
													log.Duration_in_seconds__c = milliSeconds / 1000;
											}
									}
									caseAuditLogList.add(log);
									c.Status_Change_Date_Time__c = System.now();
							}
					}
			}
	}

	private void setCaseRecordTypeMap() {
			recordTypeNameIdMap = new Map<String, String>();
			recordTypeIdNameMap = new Map<String, String>();

			for (RecordType recType : GlobalQueryHelper.getRecordTypeBySObjectName('Case')) {
					recordTypeNameIdMap.put(recType.Name, recType.id);
					recordTypeIdNameMap.put(recType.Id, recType.Name);
			}
	}

	private void insertIntoZendeskIntegrationLog(List<Case> caseList, map<Id, Case> oldCaseMap) {
			List<Zendesk_Integration_Queue__c> queueList = new List<Zendesk_Integration_Queue__c>();
			for (Case c : caseList) {
					Case oldCase = oldCaseMap.get(c.Id);
					if (
							c.Status != oldCase.Status &&
							c.Partner_Record_Id__c != null &&
							c.Shared_With__c == 'ApIntego' &&
							(c.Status == 'Awaiting Response' ||
							c.Status == 'Response Received' ||
							c.Status == 'Solved' ||
							c.Status == 'Closed' ||
							oldCase.Status == 'Awaiting Response' ||
							oldCase.Status == 'Response Received' ||
							oldCase.Status == 'Solved' ||
							oldCase.Status == 'Closed')
					) {
							Zendesk_Integration_Queue__c queue = new Zendesk_Integration_Queue__c();
							queue.Zendesk_Instance__c = 'ApIntego';
							queue.Zendesk_Id__c = c.Partner_Record_Id__c;
							queue.Case_Id__c = c.Id;
							queue.Object_Type__c = 'Status Change';
							queue.Processing_State__c = 'Queued';
							queue.Additional_Info__c = 'Status changed from ' + oldCase.Status + ' to ' + c.Status;
							queueList.add(queue);
					}
					String userName = userInfo.getUserName();
					if (c.Shared_By__c != null && c.Shared_With__c == 'ApIntego' && c.Partner_Record_Id__c != null && oldCase.Partner_Record_Id__c == null) {
							Zendesk_Integration_Queue__c queue = new Zendesk_Integration_Queue__c();
							queue.Zendesk_Instance__c = 'ApIntego';
							queue.Zendesk_Id__c = c.Partner_Record_Id__c;
							queue.Case_Id__c = c.Id;
							queue.Object_Type__c = 'Status Change';
							queue.Processing_State__c = 'Queued';
							queue.Additional_Info__c = c.Shared_By__c + '(Gusto) shared the case';
							queueList.add(queue);
					}
			}
			if (queueList.size() > 0) {
					insert queueList;
			}
	}

	private void isAuthorizedUser(List<Case> cases, User objCurrentUser) {
			Set<String> caseEmailSet = new Set<String>();
			//only match on selected record types
			map<Id, case> matchedCases = new Map<Id, Case>();
			//Alex: don't do anything if it's a privacy requeset
			for (Case cse : cases) {
					if (!(cse.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
							if (cse.Origin == 'Email' && cse.Authorized_User__c != 'Yes') {
									String emailDomain = '';
									String suppliedEmail = '';
									if (cse.SuppliedEmail != null) {
											List<String> list_EmailSplits = cse.SuppliedEmail.split('@');
											if (list_EmailSplits.size() > 1) {
													emailDomain = list_EmailSplits[1];
													suppliedEmail = cse.SuppliedEmail;
											}
									}
									if (set_AuthorizedUserRecordTypeIds.contains(cse.RecordTypeId)) {
											//if contact present then its authorized
											if (cse.contactId != null) {
													cse.Authorized_User__c = 'Yes';
											} else if (Label.Inbound_Email_Exception_Domains.IndexOf(emailDomain) > -1) {
													cse.Authorized_User__c = 'Yes';
											} else if (agencyDomainMap.containsKey(emailDomain) || agencyEmailMap.containsKey(cse.SuppliedEmail) || suppliedEmail.endsWith('.gov')) {
													cse.Authorized_User__c = 'Yes';
											} else {
													caseEmailSet.add(cse.SuppliedEmail);
													matchedCases.put(cse.id, cse);
											}

											if (emailDomain == CaseUtils.MIDDESK_EMAIL_DOMAIN) {
													cse.Answer_IQ_Eligible__c = false;
											}
									} else if (cse.RecordTypeId == recordTypeNameIdMap.get('Tax Ops')) {
											if (agencyDomainMap.containsKey(emailDomain)) {
													Agency_Information__c agency = agencyDomainMap.get(emailDomain);
													cse.Agency_Information__c = agency.Id;

													if (agency.Agency_Rep__c != null) {
															cse.OwnerId = agency.Agency_Rep__c;
													}
											} else {
													caseEmailSet.add(cse.SuppliedEmail);
													matchedCases.put(cse.id, cse);
											}
									}
							} else {
									cse.Authorized_User__c = 'Yes';
							}

							if (cse.Authorized_User__c != 'Yes') {
									cse.Answer_IQ_Eligible__c = false;
							}
					}
			}

			if (!matchedCases.isEmpty()) {
					Map<String, ZP_User__c> zpAuthorizedMap = getZPUserEmailMap(caseEmailSet);
					List<String> list_BypassUnauthorizedUserAutoCloseQueues = Label.Bypass_Unauthorized_User_Auto_Close_Queues.split(',');
					List<String> list_UpdatedBypassUnauthorizedUserAutoCloseQueues = new List<String>();

					for (String strOwnerName : list_BypassUnauthorizedUserAutoCloseQueues) {
							list_UpdatedBypassUnauthorizedUserAutoCloseQueues.add(strOwnerName.trim());
					}

					for (Case cse : matchedCases.values()) {
							String strQueueDeveloperName = '';

							for (String strQueueName : nameIdQueueMap.keySet()) {
									if (Id.valueOf(cse.OwnerId) == nameIdQueueMap.get(strQueueName)) {
											strQueueDeveloperName = strQueueName;
											break;
									}
							}

							if (zpAuthorizedMap.containskey(cse.SuppliedEmail)) {
									cse.Authorized_User__c = 'Yes';
							}

							if (
									cse.Authorized_User__c == 'No' &&
									cse.Type != 'Cobra' &&
									!(list_UpdatedBypassUnauthorizedUserAutoCloseQueues.contains(strQueueDeveloperName)) &&
									(cse.RecordTypeId == recordTypeNameIdMap.get('Tax Res') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('Benefits Care') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('Risk Assurance') ||
									cse.RecordTypeId == recordTypeNameIdMap.get('Engagement'))
							) {
									if (cse.RecordTypeId == recordTypeNameIdMap.get('Engagement') && cse.Type != 'Otter Case' && cse.Type != 'EOY Spot Check') {
											cse.Skip_Survey__c = true;
											cse.Confirm_Case_Reason_Classification__c = allClassMap.get('No Action or Wrong Email')?.Id;
											cse.Routing_Case_Reason_Classification__c = allClassMap.get('No Action or Wrong Email')?.Id;
									}

									if (
											cse.RecordTypeId == recordTypeNameIdMap.get('Engagement') &&
											cse.Type != 'Suspension Audit' &&
											cse.Type != 'EE Status Audit' &&
											cse.Type != 'Shareholder Audit' &&
											cse.Type != 'Company Taxability Audit' &&
											cse.Type != 'Owner Status audit'
									) {
											cse.Skip_Survey__c = true;
											cse.Confirm_Case_Reason_Classification__c = allClassMap.get('Carrier Reply - Non-actionable')?.Id;
											cse.Routing_Case_Reason_Classification__c = allClassMap.get('Carrier Reply - Non-actionable')?.Id;
									}

									cse.Status = 'Closed';
									cse.Routing_Case_Reason__c = 'Unauthorized User';
							}

							if (list_UpdatedBypassUnauthorizedUserAutoCloseQueues.contains(strQueueDeveloperName)) {
									cse.Authorized_User__c = 'Yes';
							}

							if (cse.Authorized_User__c != 'Yes') {
									cse.Answer_IQ_Eligible__c = false;
							} else if (
									cse.RecordTypeId != null &&
									cse.Origin != CaseUtils.ORIGIN_CHAT &&
									cse.Origin != CaseUtils.ORIGIN_PHONE &&
									cse.Channel__c != CaseUtils.ORIGIN_PHONE &&
									cse.Channel__c != CaseUtils.ORIGIN_CHAT &&
									set_AnswerIQEligible.contains(cse.RecordTypeId) &&
									!objCurrentUser?.Data_Migration_Validation__c &&
									cse.SuppliedEmail != CaseUtils.ALEGEUS_FRESHDESK &&
									cse.Status != CaseUtils.STATUS_CLOSED &&
									!cse.Routed_through_Onboarding__c
							) {
									cse.Answer_IQ_Eligible__c = true;
							}
					}
			}
	}

	private void setAgencyMapInformation() {
			agencyMap = GlobalQueryHelper.getAllAgencyInformation();
			for (Agency_Information__c agency : agencyMap.values()) {
					agencyDomainMap.Put(agency.Domain__c, agency);
					agencyEmailMap.Put(agency.Email__c, agency);
			}
	}

	private void setAgencyInformationOnCase(List<Case> cases, map<id, Case> oldCaseMap) {
			setCaseReasonClassification();
			Set<Id> agencyInformationIdSet = new Set<Id>();
			for (Case cse : cases) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(cse.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							if (cse.Agency_Information__c != null) {
									agencyInformationIdSet.add(cse.Agency_Information__c);
							}
					}
			}
			if (agencyInformationIdSet.size() > 0) {
					for (Case cse : cases) {
							boolean setDetails = false;
							if (oldCaseMap == null) {
									setDetails = true;
							} else {
									Case oldCase = oldCaseMap.get(cse.id);
									if (cse.Agency_Information__c != oldCase.Agency_Information__c) {
											setDetails = true;
									}
							}
							if (setDetails == true) {
									if (cse.Agency_Information__c == null) {
											cse.Routing_Group__c = '';
											cse.SLA_Days__c = '';
									} else if (agencyMap.containsKey(cse.Agency_Information__c)) {
											Agency_Information__c agencyInfo = agencyMap.get(cse.Agency_Information__c);
											cse.Routing_Group__c = agencyInfo.Routing_Queue__c;
											cse.SLA_Days__c = agencyInfo.SLA_Business_Days__c;
									}
							}
					}
			}
	}

	private void setCaseReasonId(List<Case> cases, Map<Id, Case> oldCaseMap) {
			setCaseReasonClassification();
			for (Case objCse : cases) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(objCse.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							Boolean routingCaseReasonFlag = true;
							Boolean confirmCaseReasonFlag = false;
							Account acc = map_Accounts.get(objCse.AccountId);

							if (userInfo.getUserName() == Label.AnswerIQUser) {
									if (String.isNotBlank(objCse.Routing_Case_Reason__c) && allClassMap.containsKey(objCse.Routing_Case_Reason__c)) {
											Case_Reason_Classification__c clsn = allClassMap.get(objCse.Routing_Case_Reason__c);
											if (objCse.RecordTypeId != cache.getRecordTypeId('Case', clsn.Type__c)) {
													if (clsn.Type__c == 'Engagement' && acc.Has_Benefits__c == false) {
															continue;
													} else {
															objCse.RecordTypeId = cache.getRecordTypeId('Case', clsn.Type__c);
															objCse.Type = clsn.Type__c;
															if (objCse.RecordTypeId == CaseUtils.RECTYPE_GEP_CX && objCse.status == CaseUtils.STATUS_OPEN) {
																	objCse.status = CaseUtils.STATUS_ASSIGNED;
															} else if (objCse.RecordTypeId == CaseUtils.RECTYPE_GEP_CX && objCse.status == CaseUtils.STATUS_IN_PROGRESS) {
																	objCse.status = CaseUtils.STATUS_ACTIVE;
															} else if (objCse.RecordTypeId == CaseUtils.R_D_TAX_CREDITS && objCse.status == CaseUtils.STATUS_IN_PROGRESS) {
																	objCse.status = CaseUtils.STATUS_IN_PROCESS;
															}
													}
											}
									}
							}

							String caseType = recordTypeIdNameMap.get(objCse.RecordTypeId);
							caseType = String.isNotBlank(caseType) && caseType.contains(CaseUtils.READ_ONLY_RECORD_TYPE)
									? caseType.replace('- ' + CaseUtils.READ_ONLY_RECORD_TYPE, '').trim()
									: caseType;

							if (classMap.containsKey(caseType)) {
									if (oldCaseMap != null) {
											Case objOldCase = oldCaseMap.get(objCse.Id);
											if (objCse.Routing_Case_Reason__c == objOldCase.Routing_Case_Reason__c) {
													routingCaseReasonFlag = false;
											}

											if (
													(objCse.Confirm_Case_Reason__c != objOldCase.Confirm_Case_Reason__c) ||
													(objCse.Confirm_Case_Reason_Classification__c != null &&
													String.isNotBlank(objCse.Confirm_Case_Reason__c) &&
													objCse.Status == CaseUtils.STATUS_CLOSED)
											) {
													confirmCaseReasonFlag = true;
											}
									}
									Map<String, Case_Reason_Classification__c> map_Reasons = classMap.get(caseType);
									Map<String, Case_Reason_Classification__c> map_ReasonsLower = map_TypeToReasonsLowerCase.get(caseType);

									if (routingCaseReasonFlag == true) {
											if (String.isNotBlank(objCse.Routing_Case_Reason__c)) {
													if (map_Reasons.containsKey(objCse.Routing_Case_Reason__c) || map_ReasonsLower.containsKey(objCse.Routing_Case_Reason__c?.toLowerCase())) {
															Case_Reason_Classification__c objCrc;
															if (map_Reasons.containsKey(objCse.Routing_Case_Reason__c)) {
																	objCrc = map_Reasons.get(objCse.Routing_Case_Reason__c);
															} else {
																	objCrc = map_ReasonsLower.get(objCse.Routing_Case_Reason__c);
															}

															if (objCrc != null) {
																	objCse.Routing_Case_Reason_Classification__c = objCrc.Id;
																	objCse.Class__c = objCrc.Class__c;
																	objCse.Priority = objCrc.Priority__c;
																	objCse.Task_Us__c = objCrc.Task_Us__c;
																	objCse.Send_Survey__c = objCrc.Survey_Eligible__c;
																	objCse.Do_not_Auto_Solve__c = objCrc.Do_not_Auto_Solve__c;
																	objCse.Routing_Case_Reason__c = objCrc.Name;

																	if (oldCaseMap == null && objCse.RecordTypeId == CaseUtils.RECTYPE_ENGAGEMENT && String.isNotBlank(objCrc.Specialization__c)) {
																			objCse.Specialization__c = objCrc.Specialization__c;
																	}

																	/**
																	 * Author: Alex
																	 * Date: 12/3/2020
																	 * Desc: Copy text from case reason to case
																	 */
																	Case objOldCse = null;
																	if (oldCaseMap != null) {
																			objOldCse = oldCaseMap.get(objCse.Id);
																	}
																	prepareCaseReasonAutoEmail(objCrc, objCse, objOldCse, false);
															}
													} else {
															if (
																	(objCse.Id == null && objCse.Origin == CaseUtils.ORIGIN_EMAIL) ||
																	objCse.Routing_Case_Reason__c == CaseUtils.UNAUTHORIZED_USER_CASE_REASON
															) {
																	continue;
															} else if (context != 'wiseio') {
																	objCse.Routing_Case_Reason__c.addError('Invalid value');
															}
													}
											} else {
													objCse.Routing_Case_Reason_Classification__c = null;
											}
									}
									if (confirmCaseReasonFlag == true) {
											if (String.isNotBlank(objCse.Confirm_Case_Reason__c)) {
													if (map_Reasons.containsKey(objCse.Confirm_Case_Reason__c) || map_ReasonsLower.containsKey(objCse.Confirm_Case_Reason__c?.toLowerCase())) {
															Case_Reason_Classification__c objCrc;
															if (map_Reasons.containsKey(objCse.Confirm_Case_Reason__c)) {
																	objCrc = map_Reasons.get(objCse.Confirm_Case_Reason__c);
															} else {
																	objCrc = map_ReasonsLower.get(objCse.Confirm_Case_Reason__c);
															}

															if (objCrc != null) {
																	objCse.Confirm_Case_Reason_Classification__c = objCrc.Id;
																	objCse.Class__c = objCrc.Class__c;
																	objCse.Priority = objCrc.Priority__c;
																	objCse.Task_Us__c = objCrc.Task_Us__c;
																	objCse.Send_Survey__c = objCrc.Survey_Eligible__c;
																	objCse.Do_not_Auto_Solve__c = objCrc.Do_not_Auto_Solve__c;
																	objCse.Confirm_Case_Reason__c = objCrc.Name;

																	if (objCrc.Reason_Category__c != null) {
																			objCse.Case_Reason_Category__c = objCrc.Reason_Category__c;
																			objCse.Confirm_Case_Reason_Category_Value__c = objCrc.Reason_Category__r.Name;
																	}

																	/**
																	 * Author: Alex
																	 * Date: 1/4/2021
																	 * Desc: if confirm case reason code is in custom label, auto close the case
																	 */
																	List<String> list_AutoCloseReasons = Label.Auto_Close_Chat_Case_Reasons.split(',');
																	if (String.isNotBlank(objCrc.Reason_Code__c) && list_AutoCloseReasons.contains(objCrc.Reason_Code__c)) {
																			objCse.Status = 'Closed';
																			objCse.Unresponsive_Abandoned_Chat__c = true;
																	}
															}
													} else {
															if (
																	context != 'wiseio' &&
																	context != 'AutoUpdateCaseStatusBatch' &&
																	(objCse.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') ||
																	objCse.RecordTypeId == recordTypeNameIdMap.get('Modern Bank') ||
																	objCse.RecordTypeId == recordTypeNameIdMap.get('Benefits Care') ||
																	objCse.RecordTypeId == recordTypeNameIdMap.get('Tax Res'))
															) {
																	objCse.Confirm_Case_Reason__c.addError('Invalid value');
															}
													}
											} else {
													objCse.Confirm_Case_Reason_Classification__c = null;
											}
									}
							}
					}
			}
	}

	/**
	 * Author: Alex
	 * Date: 12/3/2020
	 * Desc: Copy text from case reason to case
	 */
	public static void prepareCaseReasonAutoEmail(Case_Reason_Classification__c objCrc, Case objCse, Case objOldCse, Boolean blnFromAgatha) {
			try {
					if (
							String.isNotBlank(objCrc.Email_Content__c) &&
							String.isNotBlank(objCrc.Auto_Email_Behavior__c) &&
							objCse.Auto_Email_Behavior__c != 'Not Eligible - Parent has Auto Response'
					) {
							List<EmailMessage> list_EmailMsg = new List<EmailMessage>();
							if (String.isNotBlank(objCse.Id)) {
									list_EmailMsg = CaseQueryHelper.getEmailMessages(objCse.Id, 1);
							}

							String strEmailBody = '';
							strEmailBody = objCrc.Email_Content__c;

							String strSignatureToUse = '';
							/**
							 * if case reason is not overriding email signature or its Email Signature is blank,
							 * query for Auto Email Signature email template and use it for email signature.
							 * Else use the case reason's Email Signature
							 */
							if (!objCrc.Override_Email_Signature__c || String.isBlank(objCrc.Email_Signature__c)) {
									if (map_EmailTemplates.containsKey(AUTO_EMAIL_SIGNATURE_NAME)) {
											EmailTemplate objEmailSigTemp = map_EmailTemplates.get(AUTO_EMAIL_SIGNATURE_NAME);
											if (objEmailSigTemp != null && String.isNotBlank(objEmailSigTemp.HtmlValue)) {
													strSignatureToUse = objEmailSigTemp.HtmlValue;
											}
									}
							} else {
									strSignatureToUse = objCrc.Email_Signature__c;
							}

							strEmailBody += '\n' + strSignatureToUse;

							if (!list_EmailMsg.isEmpty()) {
									strEmailBody += '<br/>--------------- Original Message ---------------';
									if (String.isNotBlank(list_EmailMsg[0].FromName)) {
											strEmailBody += '<br/><b>From:</b> ' + list_EmailMsg[0].FromName + ' [' + list_EmailMsg[0].FromAddress + ']';
									} else {
											strEmailBody += '<br/><b>From:</b> ' + list_EmailMsg[0].FromAddress + ' [' + list_EmailMsg[0].FromAddress + ']';
									}
									strEmailBody += '<br/><b>Sent:</b> ' + list_EmailMsg[0].MessageDate;
									strEmailBody += '<br/><b>To:</b> ' + list_EmailMsg[0].ToAddress;
									strEmailBody += '<br/><b>Subject:</b> ' + list_EmailMsg[0].Subject + '<br/><br/>';

									if (String.isNotBlank(list_EmailMsg[0].HtmlBody)) {
											strEmailBody += list_EmailMsg[0].HtmlBody;
									} else {
											strEmailBody += list_EmailMsg[0].TextBody;
									}
							}

							//if last out bound email is null  and auto response email content is filled, auto email behavior is send, fill in the email content field
							if (
									objCse.Last_out_bound_email__c == null &&
									(objCse.Auto_Response_Email_Content__c == null ||
									(objCse.Auto_Response_Email_Content__c != null && !objCse.Auto_Response_Email_Content__c.contains(objCrc.Email_Content__c)))
							) {
									objCse.Auto_Response_Email_Content__c = strEmailBody.left(131072);
							}

							//if routing case reason is changed or we're inserting a case, set auto email behavior
							if (String.isNotBlank(objCrc.Auto_Email_Behavior__c)) {
									if (objCrc.Auto_Email_Behavior__c == 'Send') {
											String strSend = '';
											if (blnFromAgatha) {
													strSend = 'Send - Predicted';
											} else {
													strSend = 'Send - Manually Routed';
											}

											objCse.Auto_Email_Behavior__c = strSend;
									}
							}
					}
			} catch (Exception ex) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'prepareCaseReasonAutoEmail', ex.getMessage(), ex.getStackTraceString() + '. line number: ' + ex.getLineNumber());
			}
	}

	/*
Author: Alex
Date: 5/11/2020
Description: set Case Confirm_Sub_Case_Reason_Classification__c field based on Case Confirm_Sub_Case_Reason__c
*/
	public void setSubCaseReasonId(List<Case> list_Cases, Map<Id, Case> map_OldCases) {
			List<String> list_ConfirmSubReason = new List<String>();
			Map<String, Sub_Case_Reason_Classification__c> map_SubReason = new Map<String, Sub_Case_Reason_Classification__c>();

			//for each case, if its Confirm_Sub_Case_Reason__c is not blank and has changed, query for the respective Sub_Case_Reason_Classification__c
			for (Case c : list_Cases) {
					if (String.isNotBlank(c.Confirm_Sub_Case_Reason__c) && c.RecordTypeId != recordTypeNameIdMap.get('Privacy Request')) {
							list_ConfirmSubReason.add(c.Confirm_Sub_Case_Reason__c);
					} else if (String.isBlank(c.Confirm_Sub_Case_Reason__c)) {
							c.Confirm_Sub_Case_Reason_Classification__c = null;
					}

					if (map_OldCases != null) {
							//do not clear sub case reason if case is solved/closed while record type is changed
							if (c.RecordTypeId != map_OldCases.get(c.Id).RecordTypeId && c.Status != 'Solved' && c.Status != 'Closed') {
									c.Confirm_Sub_Case_Reason__c = null;
									c.Confirm_Sub_Case_Reason_Classification__c = null;
									list_ConfirmSubReason.clear();
							}
					}
			}

			if (!list_ConfirmSubReason.isEmpty()) {
					Map<String, Sub_Case_Reason_Classification__c> map_TempSubReason = CaseQueryHelper.getSubCaseReason(list_ConfirmSubReason);
					for (String strSubReason : map_TempSubReason.keySet()) {
							map_SubReason.put(strSubReason.toLowerCase(), map_TempSubReason.get(strSubReason));
					}
					map_TempSubReason.clear();

					for (Case c : list_Cases) {
							//if inserting a case
							if (map_OldCases == null) {
									if (String.isNotBlank(c.Confirm_Sub_Case_Reason__c) && map_SubReason.get(c.Confirm_Sub_Case_Reason__c.toLowerCase()) != null) {
											c.Confirm_Sub_Case_Reason_Classification__c = map_SubReason.get(c.Confirm_Sub_Case_Reason__c.toLowerCase()).Id;
									} else {
											c.Confirm_Sub_Case_Reason_Classification__c = null;
									}
							} else {
									//if updating a case
									Case oldCase = map_OldCases.get(c.Id);
									if (c.Confirm_Sub_Case_Reason__c != oldCase.Confirm_Sub_Case_Reason__c) {
											if (
													String.isNotBlank(c.Confirm_Sub_Case_Reason__c) &&
													c.Confirm_Sub_Case_Reason__c != oldCase.Confirm_Sub_Case_Reason__c &&
													map_SubReason.get(c.Confirm_Sub_Case_Reason__c.toLowerCase()) != null
											) {
													c.Confirm_Sub_Case_Reason_Classification__c = map_SubReason.get(c.Confirm_Sub_Case_Reason__c.toLowerCase()).Id;
											} else if (String.isBlank(c.Confirm_Sub_Case_Reason__c) || map_SubReason.get(c.Confirm_Sub_Case_Reason__c.toLowerCase()) == null) {
													c.Confirm_Sub_Case_Reason_Classification__c = null;
											}
									}
							}
					}
			}
	}

	private void initialize(List<Case> cases) {
			Set<Id> accountIdSet = new Set<id>();
			for (Case cse : cases) {
					//Alex: don't run when inserting privacy requests
					if (!(cse.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
							DateTime dtm = DateTime.newInstance(system.today().year(), system.today().month(), system.today().day(), 9, 0, 0);
							if (system.now().hour() > 15) {
									dtm = DateTime.newInstance((system.today() + 1).year(), (system.today() + 1).month(), (system.today() + 1).day(), 9, 0, 0);
							} else if (system.now().hour() > 9) {
									dtm = system.now();
							}
							cse.Recovery_Case_Date_Time__c = dtm;
							cse.Next_Business_Day__c = Utils.getNextBusinessDay();
							if (cse.Origin == 'Email' && cse.RecordTypeId == Label.Sales_Case_Record_Type_Id) {
									emailSet.add(cse.SuppliedEmail);
							}
							if (cse.AccountId != null) {
									accountIdSet.add(cse.AccountId);
							}
					}
			}
	}

	/**
	 * @author Alex Xiong
	 * @description set case record type to read only and status to Closed
	 * @param a Case record
	 */
	private void setCaseReadOnlyRecType(Case objCase) {
			if (objCase.RecordTypeId == recordTypeNameIdMap.get('Risk Assurance') && objCase.Status == 'Closed') {
					objCase.RecordTypeId = recordTypeNameIdMap.get('Risk Assurance - Read Only');
			}
			if (objCase.RecordTypeId == recordTypeNameIdMap.get('Payroll Compliance') && objCase.Status == 'Closed') {
					objCase.RecordTypeId = recordTypeNameIdMap.get('Payroll Compliance - Read Only');
			}
			if (objCase.RecordTypeId == recordTypeNameIdMap.get('Tax Ops') && objCase.Status == 'Closed') {
					objCase.RecordTypeId = recordTypeNameIdMap.get('Tax Ops - Read Only');
			}
			if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE && objCase.Status == CaseUtils.STATUS_CLOSED) {
					objCase.RecordTypeId = CaseUtils.RECTYPE_PAYROLL_CARE_READ_ONLY;
			}
	}

	private void SetEntitlementInfo(Case cse) {
			Set<Id> accountIdSet = new Set<id>();

			if (
					cse.RecordTypeId == CaseUtils.RECTYPE_MF_AUDIT ||
					cse.RecordTypeId == CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES ||
					cse.RecordTypeId == CaseUtils.RECTYPE_MF_NHE ||
					cse.RecordTypeId == CaseUtils.RECTYPE_MF_QLE ||
					cse.RecordTypeId == CaseUtils.RECTYPE_MF_TERMINATION
			) {
					if (map_Entitlement.containsKey(cse.AccountId + CaseUtils.REC_TYPE_STR_MF_SUBMISSION)) {
							cse.EntitlementId = map_Entitlement.get(cse.AccountId + CaseUtils.REC_TYPE_STR_MF_SUBMISSION).Id;
					}
			}
	}

	private void completeEntitlements(map<Id, String> caseMilestoneMap, map<Id, Case> caseMap) {
			List<CaseMilestone> milestoneList = new List<CaseMilestone>(
					[SELECT Id, completiondate, MilestoneTypeId, MilestoneType.Name, CaseId FROM CaseMilestone WHERE caseId IN :caseMilestoneMap.keySet()]
			);
			for (CaseMilestone milestone : milestoneList) {
					String milestoneName = caseMilestoneMap.get(milestone.CaseId);
					Case c = caseMap.get(milestone.CaseId);
					if (milestone.MilestoneType.Name == milestoneName && milestone.MilestoneType.Name == 'First Response Deadline') {
							milestone.CompletionDate = c.First_Response_Time__c;
					}
			}
			update milestoneList;
	}

	private void setAutoSolveDateTime(Case c) {
			if (c.BusinessHoursId != null) {
					c.Auto_Solve_Date_Time__c = BusinessHours.add(c.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 11 * 4);
			}
	}
	private void setAutoCloseDateTime(Case c) {
			if (c.BusinessHoursId != null) {
					c.Auto_Close_Date_Time__c = BusinessHours.add(c.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 11 * 5);
			}
	}
	//Description: Calculating Auto-close date based on given closure days for ex:closureDays = 10
	public static void setAutoCloseDateTime(Case objCase, Integer intClosureDays) {
			if (objCase.BusinessHoursId != null) {
					objCase.Auto_Close_Date_Time__c = BusinessHours.add(objCase.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * intClosureDays);
			}
	}
	private void setAutoInProgressDateTime(Case objCase, Integer intInProgressDays) {
			if (objCase.BusinessHoursId != null) {
					objCase.Follow_Up_Date_Time__c = BusinessHours.add(objCase.BusinessHoursId, System.Now(), 1000 * 60 * 60 * 9 * intInProgressDays);
			}
	}
	private static void setEntitlementMap(Set<Id> set_AccIds) {
			if (map_Entitlement == null) {
					map_Entitlement = new Map<String, Entitlement>();
					if (set_AccIds != null && set_AccIds.size() > 0) {
							for (Entitlement objEntl : [SELECT Id, AccountId, Type, BusinessHoursid FROM Entitlement WHERE AccountId IN :set_AccIds AND Status = 'Active' AND AccountId != NULL]) {
									map_Entitlement.put(objEntl.AccountId + objEntl.Type, objEntl);
							}
					}
			}
	}

	private void handleRquiresAction(Map<ID, Case> newCaseMap, Map<ID, Case> oldCaseMap) {
			List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();
			List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();
			Map<Id, Order> map_UpdateOrders = new Map<Id, Order>();

			for (Case objCase : newCaseMap.values()) {
					Case objOldCase = oldCaseMap.get(objCase.Id);
					if ((objCase.Requires_Action__c != objOldCase.Requires_Action__c) || (objCase.Benefit_Order__c != objOldCase.Benefit_Order__c && objCase.Benefit_Order__c != null)) {
							if (
									(objCase.RecordTypeId == CaseUtils.RECTYPE_CHANGE ||
									objCase.RecordTypeId == CaseUtils.RECTYPE_NEW_PLAN ||
									objCase.RecordTypeId == CaseUtils.RECTYPE_RENEWAL ||
									objCase.RecordTypeId == CaseUtils.RECTYPE_BOR ||
									objCase.RecordTypeId == CaseUtils.RECTYPE_BYB)
							) {
									if (
											objCase.Benefit_Order__c != null &&
											(objCase.Type != CaseUtils.TYPE_CARRIER_SUBMISSION &&
											objCase.Type != CaseUtils.TYPE_BENEFITS_BOR_CARRIER) &&
											(objCase.ContactId != null || (objCase.ContactId == null && objCase.RecordTypeId == CaseUtils.RECTYPE_BYB))
									) {
											Benefit_Order__c objBO = new Benefit_Order__c(Id = objCase.Benefit_Order__c);
											objBO.Requires_Action__c = objCase.Requires_Action__c;
											list_benefitOrders.add(objBO);
									}
									if (objCase.Carrier_Order__c != null) {
											Carrier_Order__c objCO = new Carrier_Order__c(Id = objCase.Carrier_Order__c);
											objCO.CO_Requires_Action__c = objCase.Requires_Action__c;
											list_carrierOrders.add(objCO);
									}
							}

							//By: PR, Date:OCt-23-2019, Desc: Order-Requires Action field sync with Case.requires action field.
							if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_TRANSFER_CASE && objCase.Order__c != null) {
									Order objOrder = new Order(Id = objCase.Order__c);
									objOrder.Requires_Actions__c = objCase.Requires_Action__c;
									map_UpdateOrders.put(objCase.Order__c, objOrder);
							}
					}
			}

			try {
					if (list_benefitOrders.size() > 0) {
							BenefitOrderHelper.skipTrigger = true;
							CarrierOrderTriggerHelper.skipTrigger = true;
							Database.update(list_benefitOrders, false);
							BenefitOrderHelper.skipTrigger = false;
							CarrierOrderTriggerHelper.skipTrigger = false;
					}

					if (list_carrierOrders != null && list_carrierOrders.size() > 0) {
							BenefitOrderHelper.skipTrigger = true;
							CarrierOrderTriggerHelper.skipTrigger = true;
							Database.update(list_carrierOrders, false);
							BenefitOrderHelper.skipTrigger = false;
							CarrierOrderTriggerHelper.skipTrigger = false;
					}

					if (map_UpdateOrders.keyset().size() > 0) {
							Boolean blnPreviousVal = OrderTriggerHelper.skipTrigger;
							OrderTriggerHelper.skipTrigger = true;
							Database.Update(map_UpdateOrders.values(), false);
							OrderTriggerHelper.skipTrigger = blnPreviousVal;
					}
			} catch (Exception objEx) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'handleRquiresAction', objEx.getMessage(), objEx.getStackTraceString());
			}
	}

	//By:PR, Date:Oct-24-22019, Desc: Following code is handling incoming email to reseller and related BMR Requires Action sync.
	public void handleResellerEmailCaseForBMR(list<Case> lst_cases) {
			if (lst_cases == null || lst_cases.size() == 0) {
					return;
			}

			set<Id> set_PRCaseRelatedAccount = new Set<Id>();
			map<Id, Bulk_Migration_Request__c> map_toUpdateBMRs = new Map<Id, Bulk_Migration_Request__c>();

			for (case caseRec : lst_cases) {
					if (caseRec.AccountId != null) {
							set_PRCaseRelatedAccount.add(caseRec.AccountId);
					}
			}

			if (set_PRCaseRelatedAccount.size() > 0) {
					map<id, Bulk_Migration_Request__c> map_accountIdBMRId = new Map<Id, Bulk_Migration_Request__c>();
					string resellerRecordTypeId = cache.getRecordTypeId('Account', 'Reseller');
					for (Bulk_Migration_Request__c bmrRec : [SELECT Id, Reseller_Account__c, OwnerId FROM Bulk_Migration_Request__c WHERE Reseller_Account__c IN :set_PRCaseRelatedAccount]) {
							map_accountIdBMRId.put(bmrRec.Reseller_Account__c, bmrRec);
					}

					map<Id, Case> map_UnassignedCaseId = new Map<Id, Case>();

					for (Case caseRec : lst_cases) {
							if (map_accountIdBMRId.size() > 0 && map_accountIdBMRId.containsKey(caseRec.AccountId)) {
									Bulk_Migration_Request__c bmrRec = new Bulk_Migration_Request__c(id = map_accountIdBMRId.get(caseRec.AccountId).Id);
									bmrRec.Requires_Action__c = caseRec.requires_Action__c;
									caseRec.OwnerId = map_accountIdBMRId.get(caseRec.AccountId).OwnerId;
									map_toUpdateBMRs.put(bmrRec.id, bmrRec);
							} else if (null != caseRec.AccountId && (test.isRunningTest() || caseRec.OwnerId == null || !String.valueOf(caseRec.OwnerId).startsWith('005'))) {
									map_UnassignedCaseId.put(caseRec.AccountId, caseRec);
							}
					}
					//By : ND, 21 Nov 2019, Get latest payroll transfer case in case Account is reseller account and assign current case to existing case's owner
					if (map_UnassignedCaseId.size() > 0) {
							Map<Id, Case> map_UnassignedCaseContact = new Map<Id, Case>();
							//Get contact on cases whose Account is of type Reseller
							for (Account acc : [SELECT Id FROM Account WHERE Id IN :map_UnassignedCaseId.keySet() AND RecordType.Name = 'Reseller']) {
									Case objCase = map_UnassignedCaseId.get(acc.Id);
									map_UnassignedCaseContact.put(objCase.ContactId, objCase);
							}
							if (map_UnassignedCaseContact.size() > 0) {
									assignOwnerToResellerAccountCase(map_UnassignedCaseContact, 'Payroll Transfer Case');
							}
					}
			}

			try {
					if (map_toUpdateBMRs.values().size() > 0) {
							boolean previousVal = BulkMigrationRequestTriggerHelper.skipTrigger;
							BulkMigrationRequestTriggerHelper.skipTrigger = true;
							database.update(map_toUpdateBMRs.values(), false);
							BulkMigrationRequestTriggerHelper.skipTrigger = false;
					}
			} catch (exception ex) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'handleResellerEmailCaseForBMR', ex.getMessage(), ex.getStackTraceString());
			}
	}
	//By : ND, 22 Nov 2019, To assign Owner to Case Associated with Reseller Account
	private void assignOwnerToResellerAccountCase(Map<Id, Case> map_UnassignedCaseContact, String strRecordTypeName) {
			Map<Id, Case> map_LatestContactCase = new Map<Id, Case>();
			//fetch latest existing case for the contact on current case

			//Chaitanya Kurra - 09-18-2020 Aggregate Query Exception Changes
			for (Case objCase : [
					SELECT CaseNumber, OwnerId, ContactId
					FROM Case
					WHERE
							RecordType.Name = :strRecordTypeName
							AND Status != 'Closed'
							AND Owner.Type = 'User'
							AND Owner.IsActive = TRUE
							AND ContactId != NULL
							AND ContactId IN :map_UnassignedCaseContact.keySet()
					ORDER BY CreatedDate DESC
			]) {
					if (!map_LatestContactCase.containsKey(objCase.ContactId)) {
							map_LatestContactCase.put(objCase.ContactId, objCase);
					}
			}

			/*
			 - Chaitanya Changes ended 09-18-2020*/
			//Assign currentCase.Owner as latestCase.Owner
			if (map_LatestContactCase.size() > 0) {
					for (Case objCse : map_UnassignedCaseContact.values()) {
							if (map_LatestContactCase.containsKey(objCse.ContactId)) {
									Case objExistingCase = map_LatestContactCase.get(objCse.ContactId);

									objCse.OwnerId = objExistingCase.OwnerId;
							}
					}
			}
	}
	//By:PR, Date:Oct-24-22019, Desc: Following code is handling incoming email to reseller and related BMR Requires Action sync.
	public void handleBulkCaseRequiresAction(list<Case> lst_cases) {
			if (lst_cases == null || lst_cases.size() == 0) {
					return;
			}

			map<Id, Bulk_Migration_Request__c> map_toUpdateBMRs = new Map<Id, Bulk_Migration_Request__c>();

			for (case caseRec : lst_cases) {
					if (caseRec.Bulk_Migration__c != null) {
							Bulk_Migration_Request__c bmrRec = new Bulk_Migration_Request__c(id = caseRec.Bulk_Migration__c);
							bmrRec.Requires_Action__c = caseRec.requires_Action__c;
							map_toUpdateBMRs.put(bmrRec.id, bmrRec);
					}
			}

			try {
					if (map_toUpdateBMRs.values().size() > 0) {
							boolean previousVal = BulkMigrationRequestTriggerHelper.skipTrigger;
							BulkMigrationRequestTriggerHelper.skipTrigger = true;
							database.update(map_toUpdateBMRs.values(), false);
							BulkMigrationRequestTriggerHelper.skipTrigger = false;
					}
			} catch (exception ex) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'handleBulkCaseRequiresAction', ex.getMessage(), ex.getStackTraceString());
			}
	}

	private void InsertCaseEmailLeadQueue(Map<ID, Case> newCaseMap) {
			List<Case> caseList = new List<Case>();
			List<Sales_Case_Email_Lead_Queue__c> caseEmailList = new List<Sales_Case_Email_Lead_Queue__c>();
			for (Case c : newCaseMap.values()) {
					if (c.RecordTypeId == recordTypeNameIdMap.get('Sales Cases') && c.Type != 'Escalated From Zendesk') {
							Sales_Case_Email_Lead_Queue__c cel = new Sales_Case_Email_Lead_Queue__c();
							cel.Case__c = c.id;
							caseEmailList.add(cel);
					}
			}

			if (caseEmailList.size() > 0) {
					Map<String, String> dmlInsertErrorsMap = new Map<String, String>();
					List<Database.SaveResult> saveResult = database.insert(caseEmailList, false);
					dmlInsertErrorsMap = Utils.processSaveResult(saveResult, caseEmailList, 'case__c', true, 'caseTriggerHelper - Before Insert');
			}
	}

	private Map<String, Map<String, Case_Reason_Classification__c>> setCaseReasonClassification() {
			classMap = new Map<String, Map<String, Case_Reason_Classification__c>>();
			map_TypeToReasonsLowerCase = new Map<String, Map<String, Case_Reason_Classification__c>>();
			allClassMap = new Map<String, Case_Reason_Classification__c>();
			map_CaseReasonsById = new Map<Id, Case_Reason_Classification__c>();
			map_SubCaseReasons = new Map<Id, List<Sub_Case_Reason_Classification__c>>();

			List<Case_Reason_Classification__c> list_CaseReasonClassification = GlobalQueryHelper.getAllCaseReasonClassification();
			List<Sub_Case_Reason_Classification__c> list_SubCaseReasonClassifications = GlobalQueryHelper.getAllSubCaseReasons();
			for (Case_Reason_Classification__c objCaseReason : list_CaseReasonClassification) {
					Map<String, Case_Reason_Classification__c> map_Reasons = new Map<String, Case_Reason_Classification__c>();
					Map<String, Case_Reason_Classification__c> map_ReasonsLowerCase = new Map<String, Case_Reason_Classification__c>();

					if (classMap.containsKey(objCaseReason.Type__c)) {
							map_Reasons = classMap.get(objCaseReason.Type__c);
							map_ReasonsLowerCase = classMap.get(objCaseReason.Type__c);
					}
					map_CaseReasonsById.put(objCaseReason.Id, objCaseReason);
					map_Reasons.put(objCaseReason.Name, objCaseReason);
					map_ReasonsLowerCase.put(objCaseReason.Name.toLowerCase(), objCaseReason);
					classMap.put(objCaseReason.Type__c, map_Reasons);
					map_TypeToReasonsLowerCase.put(objCaseReason.Type__c, map_ReasonsLowerCase);
					allClassMap.put(objCaseReason.Name, objCaseReason);
			}

			for (Sub_Case_Reason_Classification__c objSubReason : list_SubCaseReasonClassifications) {
					if (!map_SubCaseReasons.containsKey(objSubReason.Case_Reason__c)) {
							map_SubCaseReasons.put(objSubReason.Case_Reason__c, new List<Sub_Case_Reason_Classification__c>());
					}
					map_SubCaseReasons.get(objSubReason.case_reason__c).add(objSubReason);
			}

			return classMap;
	}

	private void setBusinessDay(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			for (Case cse : newCaseMap.values()) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(cse.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							Case oldCase = oldCaseMap.get(cse.Id);
							if (cse.RFI_Status__c != oldCase.RFI_Status__c && cse.RFI_Status__c == 'Requested') {
									integer i = 1;
									Date dte = system.today();
									for (i = 1; i <= 10; i++) {
											dte = Utils.getNextBusinessDayFromDate(dte);
											if (i == 3) {
													cse.RFI_3rd_Business_Day__c = dte;
											}
											if (i == 6) {
													cse.RFI_6th_Business_Day__c = dte;
											}
											if (i == 9) {
													cse.RFI_9th_Business_Day__c = dte;
											}
									}
							}
					}
			}
	}

	private map<String, ZP_User__c> getZPUserEmailMap(Set<String> emailSet) {
			map<String, ZP_User__c> userMap = new Map<String, ZP_User__c>();
			for (ZP_User__c usr : [SELECT Id, Email__c FROM ZP_User__c WHERE Email__c IN :emailSet]) {
					userMap.put(usr.Email__c, usr);
			}
			return userMap;
	}

	private void setAutoCloseValues() {
			map_AutoCloseSubjectMap = new Map<String, Email_Subject_AutoClosed__c>();
			map_PartialMatchAutoCloseSubject = new Map<String, Email_Subject_AutoClosed__c>();

			for (Email_Subject_AutoClosed__c objAutoClose : Email_Subject_AutoClosed__c.getAll().values()) {
					if (objAutoClose.Is_Partial_Match__c) {
							map_PartialMatchAutoCloseSubject.put(objAutoClose.Record_Type__c + '-' + objAutoClose.Email_Subject__c, objAutoClose);
					} else {
							map_AutoCloseSubjectMap.put(objAutoClose.Record_Type__c + '-' + objAutoClose.Email_Subject__c, objAutoClose);
					}
			}
	}

	private set<String> getAutoResponseValues() {
			set<String> autoResSet = new Set<String>();
			for (Auto_Reply_Setting__c autoRes : Auto_Reply_Setting__c.getall().values()) {
					autoResSet.add(autoRes.Name.toLowerCase());
			}
			return autoResSet;
	}

	private void setSkipAutoResponse(Case c, set<String> autoResponseSet) {
			String subject = '';
			String description = '';
			if (c.Subject != null) {
					subject = c.Subject.toLowerCase();
			}
			if (c.Description != null) {
					description = c.Description.toLowerCase();
			}
			for (String res : autoResponseSet) {
					if (subject.indexOf(res) > -1) {
							c.Skip_Auto_Response__c = true;
					}
			}
	}

	private static Map<String, Id> setQueueInformation() {
			Map<String, Id> map_QueuesById = new Map<String, Id>();

			for (Group objQueue : GlobalQueryHelper.getGroupsByType('Queue')) {
					map_QueuesById.put(objQueue.DeveloperName, objQueue.Id);
					map_Queues.put(objQueue.Id, objQueue);
			}
			return map_QueuesById;
	}

	public static void stopEmailToCaseLoop(List<Case> newList) {
			DateTime dt = System.now();
			//gets all cases created in the last 10 minutes only to compare against
			DateTime dateTimeRange = dt.addMinutes(-10), fullHour = dt.addMinutes(-dt.minute()).addSeconds(-dt.second());
			Set<String> emailSet = new Set<String>();
			for (Case c : newList) {
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
							if (c.SuppliedEmail != null) {
									emailSet.add(c.SuppliedEmail);
							}
					}
			}
			if (emailSet.size() > 0) {
					List<Case> latestCasesList = [
							SELECT ID, CreatedDate, Subject, SuppliedEmail
							FROM Case
							WHERE isclosed = FALSE AND SuppliedEmail != NULL AND SuppliedEmail IN :emailSet AND CreatedDate > :dateTimeRange
							LIMIT 10000
					];

					//string will be the from email in this case to return a record to check
					Map<String, List<Case>> fromEmailToCaseMap = new Map<String, List<Case>>();

					for (Case cse : latestCasesList) {
							if (fromEmailToCaseMap.containsKey(cse.SuppliedEmail)) {
									List<Case> caseToAdd = fromEmailToCaseMap.get(cse.SuppliedEmail);
									caseToAdd.add(cse);
									fromEmailToCaseMap.put(cse.SuppliedEmail, caseToAdd);
							} else {
									fromEmailToCaseMap.put(cse.SuppliedEmail, new List<Case>{ cse });
							}
					}

					for (Case cse : newList) {
							if (cse.Subject != null && cse.SuppliedEmail != null) {
									//We have a subject, proceed.
									if (!cse.subject.contains(' ref:')) {
											List<Case> casesFromRecipientList = fromEmailToCaseMap.get(cse.SuppliedEmail);

											if (casesFromRecipientList != null) {
													if (casesFromRecipientList.size() > 1) {
															Integer emailMatchCount = 0;
															for (Case check : casesFromRecipientList) {
																	if (check.subject != null && check.subject.contains(cse.subject)) {
																			cse.Skip_Auto_Response__c = true;
																			break;
																	}
															}
													}
											}
									}
							}
					}
			}
	}

	/*
	By: PR
	Date: July 5, 2018
	Description: When a case gets solved, we are searching the SuppliedPhone number
				in the related Contact record, If suppliedPhone number is not already mentioned in the contact
				we are populating the phone number in the blank Phone, OtherPhone, MobilePhone, ZP_Phone and finally
				if all the already mentioned fields are populated then in the Additional Phone Number field in a 
				simcolom ; separated String. 
*/
	public void updateCaseContactPhoneDetails(list<Case> caseList) {
			list<Contact> contactListToUpdate = new List<Contact>();

			if (caseList != null && caseList.size() > 0) {
					set<id> contactIdSet = new Set<id>();
					for (case csRec : caseList) {
							contactIdSet.add(csRec.ContactId);
					}

					if (contactIdSet.size() > 0) {
							for (Case caseRec : caseList) {
									Contact objContact = map_Contacts.get(caseRec.ContactId);
									if (caseRec.suppliedPhone != null && caseRec.ContactId != null && objContact != null) {
											Contact conRec = updateContactPhoneDetails(objContact, caseRec.SuppliedPhone);

											if (conrec != null && conrec.id != null) {
													contactListToUpdate.add(conRec);
													map_SMSContacts.put(conRec.Id, conRec);
											}
									}
							}
					}
			}

			if (contactListToUpdate.size() > 0) {
					update contactListToUpdate;
			}
	}

	private void setFulfillmentCaseRouting(List<Case> caseList, map<Id, Case> oldCaseMap) {
			Set<String> accountIdSet = new Set<String>();
			map<Id, Opportunity> mapRenewalOpportunity = new Map<Id, Opportunity>();
			map<Id, Opportunity> mapRenewalClosedOpportunity = new Map<Id, Opportunity>();
			map<Id, Benefit_Order__c> mapRenewalBenefit = new Map<Id, Benefit_Order__c>();
			map<Id, Opportunity> map_ChangeOpportunity = new Map<Id, Opportunity>();
			map<Id, Benefit_Order__c> map_ChangeBenefit = new Map<Id, Benefit_Order__c>();
			Set<String> accountIdNewPlanSet = new Set<String>();
			map<Id, Benefit_Order__c> mapBenefitNewPlan = new Map<Id, Benefit_Order__c>();
			map<Id, Account> map_AccountBOR = new Map<Id, Account>();
			map<Id, Opportunity> mapOpportunityBOR = new Map<Id, Opportunity>();
			map<id, Benefit_Order__c> map_ToUpdateBoRtransfer = new Map<id, Benefit_Order__c>();
			User userObj;
			Map<String, Id> map_Queue = new Map<String, Id>();
			Map<Id, Case> map_UnassignedCaseAccount = new Map<Id, Case>();
			Map<Id, Case> map_UnassignedCaseContact = new Map<Id, Case>();
			set<string> set_OrderStatus = new Set<String>{ 'Fulfilled', 'Denied', 'Canceled', 'Closed Lost', 'Closed Admin' };

			Map<Id, Opportunity> map_RenewalOpenOpportunity = new Map<Id, Opportunity>();
			Map<Id, Opportunity> map_ChangeOpenOpportunity = new Map<Id, Opportunity>();
			Map<Id, Benefit_Order__c> map_BORenewalClosedOpportunity = new Map<Id, Benefit_Order__c>();
			Map<Id, Benefit_Order__c> map_BOChangeClosedOpportunity = new Map<Id, Benefit_Order__c>();
			Set<Id> set_FulfilledOpportunity = new Set<Id>();
			List<Benefit_Order__c> lst_BenefitOrder = new List<Benefit_Order__c>();
			Set<String> set_BrokerQueueIds = new Set<String>();
			for (String strQueueName : Label.Engagement_Broker_Queues.split(',')) {
					if (nameIdQueueMap.containsKey(strQueueName)) {
							set_BrokerQueueIds.add(nameIdQueueMap.get(strQueueName));
					}
			}
			for (Case objCase : caseList) {
					if (
							objCase.SuppliedEmail != null &&
							objCase.Skip_Assignment__c == false &&
							objCase.RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits Renewal Case') &&
							objCase.AccountId != null &&
							!set_BrokerQueueIds.contains(objCase.OwnerId)
					) {
							accountIdSet.add(objCase.AccountId);
					} else if (
							objCase.SuppliedEmail != null &&
							objCase.Skip_Assignment__c == false &&
							objCase.RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits New Plan Case') &&
							objCase.AccountId != null
					) {
							accountIdNewPlanSet.add(objCase.AccountId);
					} else if (
							objCase.SuppliedEmail != null &&
							objCase.Skip_Assignment__c == false &&
							objCase.RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits BoR') &&
							objCase.AccountId != null
					) {
							map_UnassignedCaseAccount.put(objCase.AccountId, objCase);
					}
			}

			if (!accountIdSet.isEmpty()) {
					Set<String> set_OppRecordType = new Set<String>{ 'Benefits Renewal', 'Benefits Change' };
					Set<String> set_BORecordType = new Set<String>{ 'Renewal', 'Change' };

					//updated group query from global class
					//Edited By:Prashant
					List<Group> list_queueGrp = GlobalQueryHelper.getGroupsByType('Queue');

					for (Group queueGrp : list_queueGrp) {
							if (queueGrp.Name == 'Renewal Benefits Operations') {
									map_Queue.put('Renewal Benefits Operations', queueGrp.Id);
							}
							if (queueGrp.Name == 'Change Benefit Operations') {
									map_Queue.put('Change Benefit Operations', queueGrp.Id);
							}
					}

					userObj = [SELECT Id FROM User WHERE Name = :Label.Benefits_Renewal_User_Name AND IsActive = TRUE];

					//**DS[20-Oct-2020] added the logic for renewal and change case*//
					//Get a list of Opp of record type renewal and Change
					for (Opportunity oppObj : [
							SELECT
									Id,
									OwnerId,
									IsClosed,
									AccountId,
									StageName,
									RecordType.Name,
									(
											SELECT Id, Account__c, Opportunity__c, RecordType.Name, Opportunity__r.OwnerId, OwnerId, Order_Status__c
											FROM Benefit_Orders__r
											WHERE RecordType.Name IN :set_BORecordType
									)
							FROM Opportunity
							WHERE AccountId IN :accountIdSet AND RecordType.Name IN :set_OppRecordType
							ORDER BY createdDate DESC
					]) {
							//Get the open Renewal opportunity
							if (oppObj.RecordType.Name == 'Benefits Renewal') {
									if (!map_RenewalOpenOpportunity.containsKey(oppObj.AccountId) && !oppObj.IsClosed) {
											map_RenewalOpenOpportunity.put(oppObj.AccountId, oppObj);
									}
							}
							//Get the open Change opportunity
							if (oppObj.RecordType.Name == 'Benefits Change') {
									if (!map_ChangeOpenOpportunity.containsKey(oppObj.AccountId) && !oppObj.IsClosed) {
											map_ChangeOpenOpportunity.put(oppObj.AccountId, oppObj);
									}
							}
							//Get the Benefit orders if the opportunity is closed
							if (oppObj.Benefit_Orders__r.size() > 0 && oppObj.IsClosed) {
									lst_BenefitOrder.addAll(oppObj.Benefit_Orders__r);
							}
					}

					if (lst_BenefitOrder != null && lst_BenefitOrder.size() > 0) {
							for (Benefit_Order__c objBOrder : lst_BenefitOrder) {
									//get the open Benefit order of the renewal or change opporunity
									if (
											String.isNotBlank(objBOrder.Order_Status__c) &&
											!set_OrderStatus.isEmpty() &&
											!set_OrderStatus.contains(objBOrder.Order_Status__c) &&
											objBOrder.Account__c != null
									) {
											if (objBOrder.RecordType.Name == 'Renewal') {
													map_BORenewalClosedOpportunity.put(objBOrder.Account__c, objBOrder);
											} else if (objBOrder.RecordType.Name == 'Change') {
													map_BOChangeClosedOpportunity.put(objBOrder.Account__c, objBOrder);
											}
									} else if (
											String.isNotBlank(objBOrder.Order_Status__c) &&
											!set_OrderStatus.isEmpty() &&
											set_OrderStatus.contains(objBOrder.Order_Status__c) &&
											objBOrder.Account__c != null
									) {
											//get the open Benefit order of the renewal or change opporunity
											set_FulfilledOpportunity.add(objBOrder.Account__c);
									}
							}
					}
			}

			if (accountIdNewPlanSet != null && accountIdNewPlanSet.size() > 0) {
					List<Benefit_Order__c> lstNewPlanBenefitOrder = [
							SELECT Id, Account__c, Opportunity__c, Opportunity__r.OwnerId, OwnerId, Order_Status__c
							FROM Benefit_Order__c
							WHERE Account__c = :accountIdNewPlanSet AND RecordTypeId = :Cache.getRecordTypeId('Benefit_Order__c', 'New Plan')
					];
					for (Benefit_Order__c orderPlanObj : lstNewPlanBenefitOrder) {
							if (!mapBenefitNewPlan.ContainsKey(orderPlanObj.Account__c)) {
									mapBenefitNewPlan.put(orderPlanObj.Account__c, orderPlanObj);
							}
					}
			}

			/*
		By: Deepak Tyagi
		Date: November 19, 2018
		Description: Query Benefit BoR Opportunity with open BoR Transfer.
	*/

			if (set_AccountIdBOR != null && set_AccountIdBOR.size() > 0) {
					for (Account objAcc : list_AccountsForFulfillmentCaseRouting) {
							if (objAcc.RecordType.Name == 'Company') {
									if (!map_AccountBOR.ContainsKey(objAcc.Id)) {
											map_AccountBOR.put(objAcc.Id, objAcc);
									}
							} else if (objAcc.RecordType.Name == 'Reseller') {
									Case objCase = map_UnassignedCaseAccount.get(objAcc.Id);
									map_UnassignedCaseContact.put(objCase.ContactId, objCase);
							}
					}
			}

			Set<String> set_QueueName = new Set<String>{ 'Engagement Cases' };
			Map<String, Id> map_QueueFullStack = GlobalQueryHelper.getNameQueueMap(set_QueueName);

			for (Case c : caseList) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							Id caseOwnerId;
							if (
									map_RenewalOpenOpportunity.containsKey(c.AccountId) ||
									map_ChangeOpenOpportunity.containsKey(c.AccountId) ||
									map_BORenewalClosedOpportunity.containsKey(c.AccountId) ||
									map_BOChangeClosedOpportunity.containsKey(c.AccountId) ||
									set_FulfilledOpportunity.contains(c.AccountId)
							) {
									//DS[20-oct-2020]: between the if condition, older code is not changed
									//first priorty is open Renewal opportunity
									if (!map_RenewalOpenOpportunity.isEmpty() && map_RenewalOpenOpportunity.containsKey(c.AccountId)) {
											Opportunity objRenewalOpp = map_RenewalOpenOpportunity.get(c.AccountId);
											//DS[21-oct-2020]:replace the below logic with common method
											updateOpenOpportunityOwnerToCase(objRenewalOpp, userObj, c, map_Queue, 'Renewal Benefits Operations');
									} else if (!map_BORenewalClosedOpportunity.isEmpty() && map_BORenewalClosedOpportunity.containsKey(c.AccountId)) {
											//second priorty is closed Renewal opportunity which is not fulfilled
											Benefit_Order__c objRenewalBenefit = map_BORenewalClosedOpportunity.get(c.AccountId);
											//DS[21-oct-2020]:replace the below logic with common method
											updateOpenBenefitOrderOwnerToCase(objRenewalBenefit, c, set_OrderStatus);
									} else if (!map_ChangeOpenOpportunity.isEmpty() && map_ChangeOpenOpportunity.containsKey(c.AccountId)) {
											//third priorty is open change opportunity
											Opportunity objChangeOpp = map_ChangeOpenOpportunity.get(c.AccountId);
											//DS[21-oct-2020]:replace the below logic with common method
											updateOpenOpportunityOwnerToCase(objChangeOpp, userObj, c, map_Queue, 'Change Benefits Operations');
									} else if (!map_BOChangeClosedOpportunity.isEmpty() && map_BOChangeClosedOpportunity.containsKey(c.AccountId)) {
											//fourth priorty is closed change opportunity which is not fulfilled
											Benefit_Order__c objChangeBenefit = map_BOChangeClosedOpportunity.get(c.AccountId);
											//DS[21-oct-2020]:replace the below logic with common method
											updateOpenBenefitOrderOwnerToCase(objChangeBenefit, c, set_OrderStatus);
									} else if (!set_FulfilledOpportunity.isEmpty() && set_FulfilledOpportunity.contains(c.AccountId)) {
											//last priorty is fulfilled BO
											c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
											c.Type = CaseUtils.BENEFITS_CASE_PILLAR;
											c.Routed_through_Onboarding__c = true;
											c.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
											c.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
									}
							} else if (mapBenefitNewPlan.ContainsKey(c.AccountId)) {
									Benefit_Order__c newPlanBenefit = mapBenefitNewPlan.get(c.AccountId);
									if (newPlanBenefit != null) {
											//DS[21-oct-2020]:replace the order status check with set values
											if (String.isNotBlank(newPlanBenefit.Order_Status__c) && !set_OrderStatus.isEmpty() && !set_OrderStatus.contains(newPlanBenefit.Order_Status__c)) {
													if (newPlanBenefit.Opportunity__c != null) {
															c.Opportunity__c = newPlanBenefit.Opportunity__c;
													}
													c.Benefit_Order__c = newPlanBenefit.Id;
													c.Skip_Assignment__c = true;
													String preFix = String.valueOf(newPlanBenefit.OwnerId).left(3).toLowercase();
													if (prefix == '005') {
															c.OwnerId = newPlanBenefit.OwnerId;
													}
											} else if (newPlanBenefit.Order_Status__c == 'Fulfilled') {
													c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
													c.Type = CaseUtils.BENEFITS_CASE_PILLAR;
													c.Routed_through_Onboarding__c = true;
													c.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
													c.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
											}
									}
							} else if (map_AccountBOR.ContainsKey(c.AccountId)) {
									//Lirik - Migration for BOR to BO -- Start ---
									Account objBenefitBORAcc = map_AccountBOR.get(c.AccountId);
									if (objBenefitBORAcc != null && objBenefitBORAcc.Benefit_Orders__r != null && objBenefitBORAcc.Benefit_Orders__r.size() > 0) {
											Benefit_Order__c objBenefitBOR = new Benefit_Order__c();
											objBenefitBOR.Id = objBenefitBORAcc.Benefit_Orders__r[0].Id;

											//DS[21-oct-2020]:replace the order status check with set values
											if (
													String.isNotBlank(objBenefitBORAcc.Benefit_Orders__r[0].Order_Status__c) &&
													!set_OrderStatus.isEmpty() &&
													!set_OrderStatus.contains(objBenefitBORAcc.Benefit_Orders__r[0].Order_Status__c)
											) {
													c.Opportunity__c = objBenefitBORAcc.Benefit_Orders__r[0].Opportunity__c;
													c.Benefit_Order__c = objBenefitBOR.Id;
													objBenefitBOR.Requires_Action__c = c.Requires_Action__c;
													String preFix = String.valueOf(objBenefitBORAcc.Benefit_Orders__r[0].OwnerId).left(3).toLowercase();
													if (prefix == '005') {
															c.OwnerId = objBenefitBORAcc.Benefit_Orders__r[0].OwnerId;
													}
													map_ToUpdateBoRtransfer.put(objBenefitBOR.id, objBenefitBOR);
											} else if (objBenefitBORAcc.Benefit_Orders__r[0].Order_Status__c == 'Fulfilled') {
													c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
													c.Type = CaseUtils.BENEFITS_CASE_PILLAR;
													c.Routed_through_Onboarding__c = true;
													c.Internal_AI_Processed__c = CaseUtils.INTERNAL_SOLVE_PROCESSED_NO;
													c.Solve_Processed__c = CaseUtils.SOLVE_PROCESSED_NO;
											}
									}
							}
							//if the Case are created from the Origin Email and Direction is Inbound and RecordType is(Newplan, Change, Renewal,BoR)
							//and the related case if closed then we are changing the record type of the case to Benefit Care in above logics
							// then we will update the owner is the case to Care Routing
							if (
									!oldCaseMap.isEmpty() &&
									oldCaseMap.containsKey(c.Id) &&
									oldCaseMap.get(c.Id).RecordTypeId != c.RecordTypeID &&
									c.RecordTypeID == Cache.getRecordTypeId('Case', 'Engagement') &&
									c.Direction__c == 'Inbound' &&
									c.Origin == 'Email' &&
									(oldCaseMap.get(c.Id).RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits Renewal Case') ||
									oldCaseMap.get(c.Id).RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits Change Case') ||
									oldCaseMap.get(c.Id).RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits New Plan Case') ||
									oldCaseMap.get(c.Id).RecordTypeId == Cache.getRecordTypeId('Case', 'Benefits BoR')) &&
									!map_QueueFullStack.isEmpty() &&
									map_QueueFullStack.containsKey('Engagement Cases')
							) {
									// Going forward move to Engagement Cases Queue
									c.OwnerId = map_QueueFullStack.get('Engagement Cases');
							}
					}
			}
			if (map_UnassignedCaseContact.size() > 0) {
					assignOwnerToResellerAccountCase(map_UnassignedCaseContact, 'Benefits BoR');
			}
			if (map_ToUpdateBoRtransfer.Keyset().size() > 0) {
					update map_ToUpdateBoRtransfer.values();
			}
	}
	public void updateOpenOpportunityOwnerToCase(Opportunity objOpp, User objUser, Case objCase, Map<String, Id> map_Queue, String strQueueName) {
			if (objOpp != null && !objCase.IsClosed && objCase.Status != 'Closed') {
					objCase.Opportunity__c = objOpp.Id;
					objCase.Skip_Assignment__c = true;
					if (objUser != null && objOpp.OwnerId != objUser.Id) {
							objCase.OwnerId = objOpp.OwnerId;
					} else {
							if (String.isNotBlank(strQueueName) && !map_Queue.isEmpty() && map_Queue.containsKey(strQueueName)) {
									objCase.OwnerId = map_Queue.get(strQueueName);
							}
					}
			}
	}
	public void updateOpenBenefitOrderOwnerToCase(Benefit_Order__c objBenefitOrder, Case objCase, Set<String> set_OrderStatus) {
			if (objBenefitOrder != null) {
					if (!set_OrderStatus.isEmpty() && !set_OrderStatus.contains(objBenefitOrder.Order_Status__c)) {
							if (objBenefitOrder.Opportunity__c != null) {
									objCase.Opportunity__c = objBenefitOrder.Opportunity__c;
							}
							objCase.Benefit_Order__c = objBenefitOrder.Id;
							objCase.Skip_Assignment__c = true;
							if (String.valueOf(objBenefitOrder.OwnerId).left(3).toLowercase() == '005') {
									objCase.OwnerId = objBenefitOrder.OwnerId;
							} else {
									objCase.OwnerId = objBenefitOrder.Opportunity__r.OwnerId;
							}
					}
			}
	}

	private void setSalesCaseCurrentStep(List<Case> caseList, map<id, Case> oldCaseMap) {
			Set<String> companyIdSet = new Set<String>();
			map<String, String> caseCompanyIdMap = new Map<String, String>();
			map<String, ZP_Company_Onboarding_Funnel__c> companyIdStepMap = new Map<String, ZP_Company_Onboarding_Funnel__c>();

			for (Case c : caseList) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							Case oldCase = new case();
							if (oldCaseMap != null) {
									oldCase = oldCaseMap.get(c.id);
							}
							if (c.RecordTypeId == Cache.getRecordTypeId('Case', 'Sales Cases') || c.RecordTypeId == Cache.getRecordTypeId('Case', 'Sales Cases - Closed')) {
									if (map_Accounts.containsKey(c.AccountId)) {
											Account acc = map_Accounts.get(c.AccountId);
											if (acc.ZP_Company_ID__c != null && acc.ZP_Company_ID__c != '') {
													companyIdSet.add(acc.ZP_Company_ID__c);
													caseCompanyIdMap.put(c.Id, acc.ZP_Company_ID__c);
											}
									}
							}
					}
			}
			if (companyIdSet.size() > 0) {
					companyIdStepMap = new Map<String, ZP_Company_Onboarding_Funnel__c>();
					for (ZP_Company_Onboarding_Funnel__c funnel : [
							SELECT
									Id,
									Company_Id__c,
									Sign__c,
									add_addresses_started_at__c,
									add_addresses_completed_at__c,
									add_employees_started_at__c,
									Add_employees_completed_at__c,
									federal_tax_setup_started_at__c,
									federal_tax_setup_completed_at__c,
									state_setup_started_at__c,
									State_setup_completed_at__c,
									add_bank_info_started_at__c,
									add_bank_info_completed_at__c,
									payroll_schedule_started_at__c,
									payroll_schedule_completed_at__c,
									previous_paystubs_started_at__c,
									previous_paystubs_completed_at__c,
									add_signatory_started_at__c,
									add_signatory_completed_at__c,
									sign_all_forms_started_at__c,
									Sign_all_forms_completed_at__c,
									verify_bank_info_started_at__c,
									verify_bank_info_completed_at__c,
									historical_liabilities_started_at__c,
									historical_liabilities_completed_at__c
							FROM ZP_Company_Onboarding_Funnel__c
							WHERE Company_Id__c IN :companyIdSet AND deleted_at__c = NULL
					]) {
							companyIdStepMap.put(funnel.Company_Id__c, funnel);
					}
			}
			for (Case c : caseList) {
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isInsert)) {
							if (caseCompanyIdMap.containsKey(c.Id)) {
									DateTime recentStepDate = null;
									String companyId = caseCompanyIdMap.get(c.Id);
									if (companyIdStepMap.containsKey(companyId)) {
											ZP_Company_Onboarding_Funnel__c funnel = companyIdStepMap.get(companyId);
											c.Onboarding_Steps__c = '';
											c.Recently_Completed_Step__c = '';
											if (
													funnel.add_addresses_started_at__c >= c.CreatedDate &&
													(funnel.add_addresses_completed_at__c <= c.CreatedDate ||
													funnel.add_addresses_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Add Company Addresses';
											}

											if (
													funnel.add_addresses_completed_at__c != null &&
													c.CreatedDate >= funnel.add_addresses_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.add_addresses_completed_at__c)
											) {
													recentStepDate = funnel.add_addresses_completed_at__c;
													c.Recently_Completed_Step__c = 'Add Company Addresses';
											}
											if (
													funnel.add_employees_started_at__c >= c.CreatedDate &&
													(funnel.Add_employees_completed_at__c <= c.CreatedDate ||
													funnel.Add_employees_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Add Employees';
											}

											if (
													funnel.Add_employees_completed_at__c != null &&
													c.CreatedDate >= funnel.Add_employees_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.Add_employees_completed_at__c)
											) {
													recentStepDate = funnel.Add_employees_completed_at__c;
													c.Recently_Completed_Step__c = 'Add Employees';
											}
											if (
													funnel.federal_tax_setup_started_at__c >= c.CreatedDate &&
													(funnel.federal_tax_setup_completed_at__c <= c.CreatedDate ||
													funnel.federal_tax_setup_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Set Up Federal Taxes';
											}

											if (
													funnel.federal_tax_setup_completed_at__c != null &&
													c.CreatedDate >= funnel.federal_tax_setup_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.federal_tax_setup_completed_at__c)
											) {
													recentStepDate = funnel.federal_tax_setup_completed_at__c;
													c.Recently_Completed_Step__c = 'Set Up Federal Taxes';
											}
											if (
													funnel.state_setup_started_at__c >= c.CreatedDate &&
													(funnel.State_setup_completed_at__c <= c.CreatedDate ||
													funnel.State_setup_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Set Up State Taxes';
											}

											if (
													funnel.State_setup_completed_at__c != null &&
													c.CreatedDate >= funnel.State_setup_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.State_setup_completed_at__c)
											) {
													recentStepDate = funnel.State_setup_completed_at__c;
													c.Recently_Completed_Step__c = 'Set Up State Taxes';
											}
											if (
													funnel.add_bank_info_started_at__c >= c.CreatedDate &&
													(funnel.add_bank_info_completed_at__c <= c.CreatedDate ||
													funnel.add_bank_info_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Set Up Company Bank Account';
											}

											if (
													funnel.add_bank_info_completed_at__c != null &&
													c.CreatedDate >= funnel.add_bank_info_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.add_bank_info_completed_at__c)
											) {
													recentStepDate = funnel.add_bank_info_completed_at__c;
													c.Recently_Completed_Step__c = 'Set Up Company Bank Account';
											}
											if (
													funnel.payroll_schedule_started_at__c >= c.CreatedDate &&
													(funnel.payroll_schedule_completed_at__c <= c.CreatedDate ||
													funnel.payroll_schedule_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Select a Payroll Schedule';
											}

											if (
													funnel.payroll_schedule_completed_at__c != null &&
													c.CreatedDate >= funnel.payroll_schedule_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.payroll_schedule_completed_at__c)
											) {
													recentStepDate = funnel.payroll_schedule_completed_at__c;
													c.Recently_Completed_Step__c = 'Select a Payroll Schedule';
											}
											if (
													funnel.previous_paystubs_started_at__c >= c.CreatedDate &&
													(funnel.previous_paystubs_completed_at__c <= c.CreatedDate ||
													funnel.previous_paystubs_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Report Previous Payrolls';
											}

											if (
													funnel.previous_paystubs_completed_at__c != null &&
													c.CreatedDate >= funnel.previous_paystubs_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.previous_paystubs_completed_at__c)
											) {
													recentStepDate = funnel.previous_paystubs_completed_at__c;
													c.Recently_Completed_Step__c = 'Report Previous Payrolls';
											}
											if (
													funnel.add_signatory_started_at__c >= c.CreatedDate &&
													(funnel.add_signatory_completed_at__c <= c.CreatedDate ||
													funnel.add_signatory_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Add Signatory';
											}

											if (
													funnel.add_signatory_completed_at__c != null &&
													c.CreatedDate >= funnel.add_signatory_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.add_signatory_completed_at__c)
											) {
													recentStepDate = funnel.add_signatory_completed_at__c;
													c.Recently_Completed_Step__c = 'Add Signatory';
											}
											if (
													funnel.sign_all_forms_started_at__c >= c.CreatedDate &&
													(funnel.Sign_all_forms_completed_at__c <= c.CreatedDate ||
													funnel.Sign_all_forms_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Sign Company Forms';
											}

											if (
													funnel.Sign_all_forms_completed_at__c != null &&
													c.CreatedDate >= funnel.Sign_all_forms_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.Sign_all_forms_completed_at__c)
											) {
													recentStepDate = funnel.Sign_all_forms_completed_at__c;
													c.Recently_Completed_Step__c = 'Sign Company Forms';
											}
											if (
													funnel.verify_bank_info_started_at__c >= c.CreatedDate &&
													(funnel.verify_bank_info_completed_at__c <= c.CreatedDate ||
													funnel.verify_bank_info_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Verify Company Bank Account';
											}

											if (
													funnel.verify_bank_info_completed_at__c != null &&
													c.CreatedDate >= funnel.verify_bank_info_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.verify_bank_info_completed_at__c)
											) {
													recentStepDate = funnel.verify_bank_info_completed_at__c;
													c.Recently_Completed_Step__c = 'Verify Company Bank Account';
											}
											if (
													funnel.historical_liabilities_started_at__c >= c.CreatedDate &&
													(funnel.historical_liabilities_completed_at__c <= c.CreatedDate ||
													funnel.historical_liabilities_completed_at__c == null)
											) {
													c.Onboarding_Steps__c += ';Enter Historical Paystubs';
											}

											if (
													funnel.historical_liabilities_completed_at__c != null &&
													c.CreatedDate >= funnel.historical_liabilities_completed_at__c &&
													(recentStepDate == null ||
													recentStepDate < funnel.historical_liabilities_completed_at__c)
											) {
													recentStepDate = funnel.historical_liabilities_completed_at__c;
													c.Recently_Completed_Step__c = 'Enter Historical Paystubs';
											}
									}
							}
					}
			}
	}

	/*
	By: PR
	Date: July 5, 2018
	Description: this method is getting a contact and suppliedPhone and if supplied Phone does not 
					matches with Contact phone number we are populating the next null field
*/
	public Contact updateContactPhoneDetails(Contact objContact, String strSuppliedPhone) {
			if (
					objContact.Normalized_Mobile_Phone__c == strSuppliedPhone ||
					objContact.Normalized_Other_Phone__c == strSuppliedPhone ||
					objContact.Normalized_Phone__c == strSuppliedPhone ||
					objContact.ZP_Phone__c == strSuppliedPhone ||
					(objContact.Additional_Phone_Numbers__c != null && objContact.Additional_Phone_Numbers__c.contains(strSuppliedPhone))
			) {
					return new Contact();
			}

			List<String> list_PhoneNumbers = new List<String>();

			for (Phone_Number_to_Not_Save__mdt objPhone : [SELECT Phone_Number__c FROM Phone_Number_to_Not_Save__mdt]) {
					list_PhoneNumbers.add(objPhone.Phone_Number__c);
			}

			if (!list_PhoneNumbers.contains(strSuppliedPhone)) {
					if (objContact.Phone == null) {
							objContact.Phone = strSuppliedPhone;
					} else if (objContact.MobilePhone == null) {
							objContact.MobilePhone = strSuppliedPhone;
					} else if (objContact.OtherPhone == null) {
							objContact.OtherPhone = strSuppliedPhone;
					} else if (String.isBlank(objContact.ZP_Phone__c)) {
							objContact.ZP_Phone__c = strSuppliedPhone;
					} else {
							if (String.isBlank(objContact.Additional_Phone_Numbers__c)) {
									objContact.Additional_Phone_Numbers__c = strSuppliedPhone;
							} else {
									/*
				Author: Alex
				Date: 4/17/2020
				Desc: check length of Additional Phone Numbers + strSuppliedPhone
					if length is greater than 255, don't add it to the field
				*/
									String strTempPhoneNumber = objContact.Additional_Phone_Numbers__c + ';' + strSuppliedPhone;
									if (strTempPhoneNumber.length() <= 255) {
											objContact.Additional_Phone_Numbers__c += ';' + strSuppliedPhone;
									}
							}
					}
			}

			return objContact;
	}

	public void formatCaseDescription(map<id, Case> newCaseMap, map<id, Case> oldCaseMap) {
			for (Case c : newCaseMap.values()) {
					//Alex: don't run logic before inserting/updating a Privacy Request
					if (!(c.RecordTypeId == recordTypeNameIdMap.get('Privacy Request') && Trigger.isBefore)) {
							if (c.Formating_Status__c == 'Pending') {
									c.Formating_Status__c = 'Processed';
									if (c.Description != null && c.Description.indexOf('SSN') > -1) {
											String descr = c.Description;
											List<String> strList = descr.split('\n');
											String newDescr = '';

											for (String line : strList) {
													if (line.indexOf('SSN') > -1 && line.indexOf('::') > -1) {
															line = ' - SSN : ' + line.split('::')[1];
															c.Formating_Status__c = 'Updated';
													}
													newDescr += line + '\n';
											}

											c.Description = newDescr;
									}
							}
					}
			}
	}

	@InvocableMethod(label='Skip Case Trigger' description='Sets the skipTrigger flag to true.')
	public static void skipCaseTrigger(List<boolean> booleanList) {
			if (booleanList.size() > 0) {
					skipTrigger = booleanList[0];
			}
	}

	/* -- Author: Pradeep Ponnam.
	-- Description: Partner Sales - Care transfer process
	-- Jira #: https://app.asana.com/0/1161024895662406/1165692802148235
	-- Date Created: 16-Mar-2020
	-- Modified: Date : NA
*/
	public void updateCasePartnerSalesDetails(List<Case> caseList) {
			Id id_accountCompanyRecordTypeId = Cache.getRecordTypeId('Account', 'Company');
			Id id_accountResellerRecordTypeId = Cache.getRecordTypeId('Account', 'Reseller');
			Map<Id, Id> mapAccountOwner = new Map<Id, Id>();

			if (caseList != null && caseList.size() > 0) {
					if (map_Contacts != null && !map_Contacts.isEmpty()) {
							for (Contact c : map_Contacts.values()) {
									if (
											(c.Account?.RecordTypeId == id_accountResellerRecordTypeId || c.Account?.RecordTypeId == id_accountCompanyRecordTypeId) &&
											(c.Account?.Sold_By__c != null ||
											c.Account?.Referred_By__c != null)
									) {
											if (c.Account.RecordTypeId == id_accountResellerRecordTypeId) {
													mapAccountOwner.put(c.Id, c.Account.ownerId);
											}

											if (c.Account.RecordTypeId == id_accountCompanyRecordTypeId) {
													if (c.Account.Sold_By__c != null) {
															mapAccountOwner.put(c.Id, c.Account.Sold_By__r.OwnerId);
													}

													if (c.Account.Referred_By__c != null) {
															mapAccountOwner.put(c.Id, c.Account.Referred_By__r.OwnerId);
													}
											}
									}
							}
					}
					for (Case caseRec : caseList) {
							if (caseRec.ContactId != null && mapAccountOwner != null && mapAccountOwner.containskey(caseRec.ContactId)) {
									caseRec.partner_related_case__c = true;
									caseRec.partner_sales_owner__c = mapAccountOwner.get(caseRec.ContactId);
							}
					}
			}
	}

	/**
	 * By :Prashant
	 * Date Created  : 27-05-2020
	 * Aasna Ticket : https://app.asana.com/0/1165890935117693/1177148576781777
	 * DESC : Update Lead or Contact Enagagement Biz field for Sales Cases.
	 */
	public void updateLeadContactEngagementBiz(List<Case> list_newCases) {
			Id caseRecordTypeSales = cache.getRecordTypeId('Case', 'Sales Cases');
			Id caseRecordTypeSalesClosed = cache.getRecordTypeId('Case', 'Sales Cases - Closed');
			Set<Id> set_contactIds = new Set<Id>();
			Set<Id> set_leadIds = new Set<Id>();
			Set<Id> set_CreatedByIds = new Set<Id>();
			Map<Id, String> map_ownerIdToRoleName = new Map<Id, String>();
			List<Contact> list_contactsToUpdate = new List<Contact>();
			List<Lead> list_leadsToUpdate = new List<Lead>();

			for (Case objCase : list_newCases) {
					set_CreatedByIds.add(objCase.CreatedById);
			}

			if (map_AllUsers.size() > 0) {
					for (User objUsr : map_AllUsers.values()) {
							if (set_CreatedByIds.contains(objUsr.Id)) {
									map_ownerIdToRoleName.put(objUsr.Id, objUsr.UserRole.Name);
							}
					}
			}

			for (Case objCase : list_newCases) {
					if (map_ownerIdToRoleName.containsKey(objCase.CreatedById)) {
							String str_roleName = map_ownerIdToRoleName.get(objCase.CreatedById);
							// Adding null check to ensure automated user is supported
							if (
									str_roleName != null &&
									(str_roleName.containsIgnoreCase('sales_sb_ib_xx') ||
									str_roleName.containsIgnoreCase('sales_sb_ob_xx') ||
									str_roleName.containsIgnoreCase('sales_sb_ib_sme') ||
									str_roleName.containsIgnoreCase('sales_sb_ob_sme'))
							) {
									if (
											(objCase.RecordTypeId == caseRecordTypeSales || objCase.RecordTypeId == caseRecordTypeSalesClosed) &&
											(objCase.Type == 'Sales Chat' ||
											objCase.Type == 'Sales Call' ||
											objCase.Type == 'Sales Email')
									) {
											if (objCase.ContactId != null) {
													set_contactIds.add(objCase.ContactId);
											}
											if (objCase.Lead__c != null) {
													set_leadIds.add(objCase.Lead__c);
											}
									}
							}
					}
			}

			if (set_contactIds.size() > 0) {
					List<Contact> list_contact = CaseQueryHelper.getCaseContacts(set_contactIds);

					for (Contact objCon : list_contact) {
							objCon.Small_Biz_Engagement__c = true;
							list_contactsToUpdate.add(objCon);
					}
					if (list_contactsToUpdate.size() > 0) {
							Boolean skipContactTrigger = ContactTriggerHelper.skipTrigger;
							ContactTriggerHelper.skipTrigger = true;
							update list_contactsToUpdate;
							ContactTriggerHelper.skipTrigger = skipContactTrigger;
					}
			}

			if (set_leadIds.size() > 0) {
					List<Lead> list_lead = CaseQueryHelper.getCaseLeadById(set_leadIds);
					for (Lead objLead : list_lead) {
							objLead.Small_Biz_Engagement__c = true;
							list_leadsToUpdate.add(objLead);
					}
					if (list_leadsToUpdate.size() > 0) {
							Boolean skipLeadTrigger = LeadTriggerHelper.skipTrigger;
							LeadTriggerHelper.skipTrigger = true;
							update list_leadsToUpdate;
							LeadTriggerHelper.skipTrigger = skipLeadTrigger;
					}
			}
	}
	/**
	 * By :Prashant
	 * Date Created  : 25-06-2020
	 * Aasna Ticket : https://app.asana.com/0/1165890935117693/1174138650528440
	 * DESC : Update Lead/Account Activity Fields.
	 */

	public void updateAccLeadActivityDate(List<Case> list_newCases) {
			List<Account> list_AccountToUpdate = new List<Account>();
			List<Lead> list_LeadToUpdate = new List<Lead>();
			List<Lead> list_leads = CaseQueryHelper.updateLeadsActivityFields(map_LeadCase.keySet());

			for (Lead objLead : List_leads) {
					if (map_LeadCase.containsKey(objLead.Id)) {
							objLead.Last_Rep_Activity_Date_New__c = map_LeadCase.get(objLead.Id).CreatedDate.date();
							objLead.Last_Lead_Activity_Date__c = map_LeadCase.get(objLead.Id).CreatedDate.date();
							list_LeadToUpdate.add(objLead);
					}
			}
			for (Account objAcc : list_AccountsForUpdateAccLeadActivityDate) {
					if (map_AccCase.containsKey(objAcc.Id)) {
							objAcc.Last_Rep_Activity_Date_New__c = map_LeadCase.get(objAcc.Id).CreatedDate.date();
							objAcc.Last_Account_Activity_Date__c = map_LeadCase.get(objAcc.Id).CreatedDate.date();
							list_AccountToUpdate.add(objAcc);
					}
			}
			if (list_LeadToUpdate.size() > 0) {
					LeadTriggerHelper.skipTrigger = true;
					update list_LeadToUpdate;
					LeadTriggerHelper.skipTrigger = false;
			}
			if (list_AccountToUpdate.size() > 0) {
					AccountTriggerHelper.skipTrigger = true;
					update list_AccountToUpdate;
					AccountTriggerHelper.skipTrigger = false;
			}
	}

	public void checkOwnerId(Map<ID, Case> oldCaseMap, Map<ID, Case> newCaseMap) {
			//Date : 9 April 2020
			//Change By : Bhagat and Ashveej
			//DS : Agatha predicted tax res cases change the ownership to a queue where previous owner was another queue

			for (Case caseObj : newCaseMap.values()) {
					Case oldCaseObj = oldCaseMap.get(caseObj.Id);
					if (caseObj.OwnerId != oldCaseObj.OwnerId) {
							String previousOwnerId = oldCaseObj.OwnerId;
							String currentOwnerId = caseObj.OwnerId;
							if (
									oldCaseObj.Agatha_TaxRes_Case_Routing__c == true &&
									caseObj.Agatha_TaxRes_Case_Routing__c == true &&
									previousOwnerId.indexOf('00G') == 0 &&
									currentOwnerId.indexOf('00G') == 0
							) {
									//Previous and Current OwnerId is a Queue then below mentioned flag value is set as true.
									caseObj.Agatha_TaxRes_Owner_Mismatch__c = true;
							}
					}
			}
	}

	/*
	 * Created By   : Neha Dabas
	 * Description  : To route cases created as a response of Covid-19 changes emails to customers
	 * Created Date : 22 April 2020*/

	private void handleEmailToCaseForCustomerResponses(List<Case> list_Cases) {
			//Fetch the list of Email Subjects which need for TaxRes Case Routing
			List<Tax_Res_Product_Email_Subject__c> list_Subjects = Tax_Res_Product_Email_Subject__c.getAll().values();
			for (Case c : list_Cases) {
					for (Tax_Res_Product_Email_Subject__c EmailSubject : list_Subjects) {
							if (
									recordTypeNameIdMap != null &&
									recordTypeNameIdMap.containsKey('Payroll Care') &&
									c.RecordTypeId == recordTypeNameIdMap.get('Payroll Care') &&
									c.Subject != null &&
									c.Subject.containsIgnoreCase(EmailSubject.Subject__c)
							) {
									if (recordTypeNameIdMap.containsKey('Tax Res')) {
											c.RecordTypeId = recordTypeNameIdMap.get('Tax Res');
									}

									c.Type = 'Tax Res';
									c.OwnerId = TAXRESDATACAPTURE_QUEUE_ID;
									c.Root_Cause__c = 'Informational';
									c.Customer_Journey__c = 'Accounts Update';

									break;
							}
					}
			}
	}
	/* Created by: Neha Dabas, 27th March 2020
	 * Set Requires Action field on related Ticket record to true
	 */
	private void setRequiresActionOnTicket(Set<Id> set_CaseId) {
			if (set_CaseId == null || set_CaseId.isEmpty()) {
					return;
			}
			List<Ticket__c> list_Tickets = CaseQueryHelper.getRelatedTickets(set_CaseId);
			if (list_Tickets != null && !list_Tickets.isEmpty()) {
					for (Ticket__c objTicket : list_Tickets) {
							if (objTicket.Fulfillment_Case__c != null && objTicket.Fulfillment_Case__r.RecordTypeId == CaseUtils.RECTYPE_NEW_PLAN) {
									objTicket.Requires_Action__c = true;
							} else if (
									objTicket.Case__c != null &&
									objTicket.Case__r.RecordTypeId == CaseUtils.RECTYPE_RENEWAL &&
									objTicket.Escalation_Reason__c == TicketUtil.TICKET_REASON_RECERTIFICATION
							) {
									objTicket.Recert_Status__c = TicketUtil.RECERT_STATUS_ADVISOR_ACTION_NEEDED;
							}
					}

					update list_Tickets;
			}
	}

	/**
	 * Author: Alex
	 * Date: 8/19/2020
	 * Desc: Get IVR Routing Log based on Genesys Call Id
	 * if no IVR Routing Log found, use SuppliedPhone to search for contact and populate on Case
	 */
	public static void getIVR(List<Case> list_Cases) {
			List<String> list_GenId = new List<String>();

			for (Case c : list_Cases) {
					if (String.isNotBlank(c.Genesys_Call_Id__c)) {
							list_GenId.add(c.Genesys_Call_Id__c);
					}
			}

			Map<String, IVR_Routing_Log__c> map_IVR = new Map<String, IVR_Routing_Log__c>();
			if (!list_GenId.isEmpty()) {
					map_IVR = CaseQueryHelper.getIVRLogs(list_GenId);
			}

			List<String> list_divrids = new List<String>();
			if (!map_IVR.isEmpty()) {
					for (IVR_Routing_Log__c ivr : map_IVR.values()) {
							if (String.isNotBlank(ivr.Divrid__c)) {
									list_divrids.add(ivr.Divrid__c);
							}
					}
			}

			//check if trigger is running b/c purecloud
			//if not, then check if user is API user
			Boolean blnIsAPIUser = false;
			if (strLaunchedFrom != 'PurecloudCTI') {
					User objUser = GlobalQueryHelper.getUserInfoById(UserInfo.getUserId());
					blnIsAPIUser = objUser.Is_Api_Integration__c;
			}

			for (Case c : list_Cases) {
					//don't allow trigger to override this value if PurecloudCTIExtension is inserting a case
					//or when current user is an integration user
					//if not from purecloud and is API user, set owner to phone routing queue
					if (strLaunchedFrom != 'PurecloudCTI' && blnIsAPIUser == true) {
							c.OwnerId = Label.Phone_Routing_Queue;
					}
					if (String.isNotBlank(c.SuppliedPhone) && (blnIsAPIUser == true || strLaunchedFrom == 'PurecloudCTI')) {
							c.Subject = '+1' + c.SuppliedPhone + ' Incoming call at ' + System.Now();
					}
					if (String.isNotBlank(c.Genesys_Call_Id__c)) {
							IVR_Routing_Log__c ivr;
							if (!map_IVR.isEmpty() && map_IVR.containsKey(c.Genesys_Call_Id__c)) {
									ivr = map_IVR.get(c.Genesys_Call_Id__c);
							}

							if (ivr != null) {
									c.IVR_Routing_Log__c = ivr.Id;
									if (ivr.CIP_Account__c != null) {
											c.AccountId = ivr.CIP_Account__c;
									}
									if (ivr.Contact__c != null) {
											c.ContactId = ivr.Contact__c;
									}
									if (String.isNotBlank(ivr.CIP_Auth__c)) {
											c.Auth__c = ivr.CIP_Auth__c;
									}
									if (String.isNotBlank(ivr.CIP_Auth_Path__c)) {
											c.AuthPath__c = ivr.CIP_Auth_Path__c;
									}
									if (String.isNotBlank(ivr.Skill__c)) {
											c.IVR_Skill__c = ivr.Skill__c;
									}
									if (String.isNotBlank(ivr.Source__c)) {
											c.Source__c = ivr.Source__c;
									}
									if (String.isNotBlank(ivr.Intent_Group_Code__c)) {
											c.IVR_Intent_Grouping__c = ivr.Intent_Group_Code__c;
									}
									if (String.isNotBlank(ivr.Lex_Transcript__c)) {
											c.IVR_Transcript__c = ivr.Lex_Transcript__c;
									}

									if (String.isNotBlank(ivr.Divrid__c)) {
											c.DIVR_Id__c = ivr.Divrid__c;
									}

									setRecordTypeFromIVR(c, ivr.InQueue_Queue_Name__c);
							} else {
									if (!map_PhoneToContacts.isEmpty()) {
											c.ContactId = map_PhoneToContacts.get(c.SuppliedPhone);
									}
							}
					}
			}
	}

	public static void setRecordTypeFromIVR(Case c, String strQueueName) {
			if (String.isNotBlank(strQueueName)) {
					if (strQueueName == 'Payroll Care') {
							c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
							c.Type = CaseUtils.PAYROLL_CASE_PILLAR;
					} else if (strQueueName == 'Full-Stack Care') {
							c.RecordTypeId = CaseUtils.RECTYPE_ENGAGEMENT;
							c.Type = CaseUtils.BENEFITS_CASE_PILLAR;
					} else if (strQueueName.contains('Modern Bank')) {
							c.RecordTypeId = Cache.getRecordTypeId('Case', 'Modern Bank');
							c.Type = CaseUtils.TYPE_MODERN_BANK;
					}
			}
	}

	/*
	* @Author:      Midhuna KB
	* @Description: Cases that have an existing case based off of Email, Subject, Origin, and RecordType should be merged together so we do not have duplicates.
					Cases that do not have an existing cases are processed as normal.
	* @Parm:        list_Cases - List of cases to attempt to merge.
	* @Return:      N/A
	* @Author:      Lalitha K
	* @Description: [Dec 25, 2021 changes] - made duplicate merge cases logic to handle cc emails when user replies all.
	*/
	private void mergeDuplicateCases(List<Case> list_Cases) {
			try {
					Set<String> set_Subject = new Set<String>();
					List<String> list_ExcludedEmails = new List<String>();
					List<String> list_ExcludedEmailSubjects = new List<String>();

					// Custom Metadata for Test execution
					if (Test.isRunningTest()) {
							list_CaseMergeExclusionMdt = CaseTriggerHelperTest.generateMetadata();
					}

					if (!list_CaseMergeExclusionMdt.isEmpty()) {
							for (Case_Merge_Exclusion__mdt objCMExclusion : list_CaseMergeExclusionMdt) {
									if (objCMExclusion.Matching_Criteria__c == 'Email') {
											list_ExcludedEmails.add(objCMExclusion.Email__c);
									}

									if (objCMExclusion.Matching_Criteria__c == 'Email+Subject') {
											list_ExcludedEmailSubjects.add(objCMExclusion.Email__c + objCMExclusion.Subject__c);
									}
							}
					}

					Map<String, Case> map_ExistingEmailsFieldSubjCase = new Map<String, Case>();
					Set<String> set_AllEmailAddresses = new Set<String>();

					for (Case objCase : list_Cases) {
							String strCleanedIncomingSubj = objCase.Subject?.removeStartIgnoreCase('re:').trim();
							set_Subject.add(strCleanedIncomingSubj);

							if (String.isNotBlank(objCase.SuppliedEmail)) {
									set_AllEmailAddresses.add(objCase.SuppliedEmail);
							}

							if (String.isNotBlank(objCase.To_Email_Address__c)) {
									set_AllEmailAddresses.addAll(objCase.To_Email_Address__c.trim().split(';'));
							}

							if (String.isNotBlank(objCase.CCEmailAddress__c)) {
									set_AllEmailAddresses.addAll(objCase.CCEmailAddress__c.trim().split(';'));
							}
					} //end of for loop

					Set<String> set_TmpAllEmailAddresses = new Set<String>();
					for (String strEmailAddress : set_AllEmailAddresses) {
							strEmailAddress = '%' + strEmailAddress + '%';
							set_TmpAllEmailAddresses.add(strEmailAddress);
					}

					set_AllEmailAddresses = set_TmpAllEmailAddresses;

					List<Case> list_ExistingDuplicateCases = new List<Case>();
					if (!set_Subject.isEmpty()) {
							list_ExistingDuplicateCases = CaseQueryHelper.getSubjectOpenDuplicateCases(set_Subject, 'CLOSED', false, set_AllEmailAddresses);
					}

					for (Case objCase : list_ExistingDuplicateCases) {
							String strExisingCleanedSubj = objCase.Subject?.removeStartIgnoreCase('re:').trim();

							if (!map_ExistingEmailsFieldSubjCase.containsKey(objCase.SuppliedEmail + strExisingCleanedSubj)) {
									map_ExistingEmailsFieldSubjCase.put(objCase.SuppliedEmail + strExisingCleanedSubj, objCase);
							}

							if (String.isNotBlank(objCase.To_Email_Address__c)) {
									for (String strEmailAddress : objCase.To_Email_Address__c.trim().split(';')) {
											map_ExistingEmailsFieldSubjCase.put(strEmailAddress + strExisingCleanedSubj, objCase);
									}
							}

							if (String.isNotBlank(objCase.CCEmailAddress__c)) {
									for (String strEmailAddress : objCase.CCEmailAddress__c.trim().split(';')) {
											map_ExistingEmailsFieldSubjCase.put(strEmailAddress + strExisingCleanedSubj, objCase);
									}
							}
					}

					for (Case objIncomingCase : list_Cases) {
							//by pass for some excluded emails
							if (list_ExcludedEmails.contains(objIncomingCase.SuppliedEmail)) {
									continue;
							}

							String strCleanedIncomingSubj = objIncomingCase.Subject?.removeStartIgnoreCase('re:').trim();
							Case objExistingCase;

							if (map_ExistingEmailsFieldSubjCase.keySet().contains(objIncomingCase.SuppliedEmail + strCleanedIncomingSubj)) {
									objExistingCase = map_ExistingEmailsFieldSubjCase.get(objIncomingCase.SuppliedEmail + strCleanedIncomingSubj);
									objIncomingCase.Status = 'Closed';
									objIncomingCase.Skip_Auto_Response__c = true;
									objIncomingCase.Closed_Reason__c = 'Merged Duplicate';
									objIncomingCase.ParentId = objExistingCase.Id;
							}
					}
			} catch (Exception ex) {
					ExceptionLogUtil.logException('CaseTriggerHelper', 'mergeDuplicateCases', ex.getMessage(), ex.getStackTraceString());
			}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : If Case Record Type is GEP CX, set Type to GEP Payroll
	 * @Parm        : List_Cases - List of Cases
	 * @Return      : N/A
	 */
	public void gepCxCase(List<Case> list_Cases) {
			for (Case c : list_Cases) {
					if (c.RecordTypeId == CaseUtils.RECTYPE_GEP_CX) {
							c.Type = CaseUtils.TYPE_GEP_PAYROLL;
					}
			}
	}

	/**
 * @Author      : Ankit C
 * @Description : This method prevents a case from being solved if it has a case 
					escalation having empty Root Cause value
 * @Parm        : List_Cases - List of solved cases
 * @Return      : N/A
*/
	public void checkCaseEscalations(List<Case> list_Cases) {
			Map<Id, Case_Escalation__c> map_CaseEscalationByCaseId = new Map<Id, Case_Escalation__c>();
			Id idSocialRecordTypeId = Cache.getRecordTypeId('Case_Escalation__c', 'Social & Executive');

			for (Case_Escalation__c objCaseEscalation : [
					SELECT Id, Case__c, Root_Cause_of_Complaint__c
					FROM Case_Escalation__c
					WHERE
							RecordTypeId = :idSocialRecordTypeId
							AND (Root_Cause_of_Complaint__c = NULL
							OR Type_of_Complaint__c = NULL
							OR Root_Cause_of_Escalation_Touchpoint__c = NULL
							OR Was_the_escalation_reasonable__c = NULL)
							AND Case__c IN :list_Cases
			]) {
					map_CaseEscalationByCaseId.put(objCaseEscalation.Case__c, objCaseEscalation);
			}

			for (Case objCase : list_Cases) {
					if (map_CaseEscalationByCaseId.containsKey(objCase.Id) && map_CaseEscalationByCaseId.get(objCase.Id)?.Id != null) {
							objCase.addError(Label.Engagement_Solve_Case_Validation_Message);
					}
			}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Validate and create SMS Records
	 * @Parm        : list_SMSCases
	 */
	public void createSMSRecords(List<Case> list_SMSCases) {
			List<SMS__c> list_SMSToCreate = new List<SMS__c>();
			String strSurveyMessage = Label.Survey_SMS_Text;
			Map<String, SMS__c> map_SMS = new Map<String, SMS__c>();

			//Query SMS records
			if (set_SuppliedPhoneNumbers.size() > 0) {
					for (SMS__c objSMS : [
							SELECT Id, Unformatted_Phone_Number__c
							FROM SMS__c
							WHERE CreatedDate = LAST_N_DAYS:30 AND Unformatted_Phone_Number__c IN :set_SuppliedPhoneNumbers AND Case__c != NULL
					]) {
							map_SMS.put(objSMS.Unformatted_Phone_Number__c, objSMS);
					}
			}

			for (Case objCase : list_SMSCases) {
					Contact objCont = map_SMSContacts?.containsKey(objCase.ContactId) ? map_SMSContacts.get(objCase.ContactId) : null;

					if (objCont != null) {
							if (!objCont.Survey_Opt_Out__c && (map_SMS == null || !map_SMS.containsKey(objCase.SuppliedPhone))) {
									SMS__c objSMS = new SMS__c();

									objSMS.Case__c = objCase.Id;
									objSMS.Direction__c = CaseUtils.SMS_DIRECTION_OB;
									objSMS.Status__c = CaseUtils.SMS_STATUS_QUEUED;
									objSMS.Phone_Number__c = (objCase.SuppliedPhone != null && !(objCase.SuppliedPhone.length() > 10) ? '+1' + objCase.SuppliedPhone : objCase.SuppliedPhone);
									objSMS.Unformatted_Phone_Number__c = objCase.SuppliedPhone;

									//format sms text
									if (String.isNotBlank(objCase.Owner_First_Name__c)) {
											strSurveyMessage = strSurveyMessage.replaceAll(CaseUtils.SMS_TEXT_FNAME, objCase.Owner_First_Name__c);
									} else {
											strSurveyMessage = strSurveyMessage.replaceAll(CaseUtils.SMS_TEXT_FNAME, CaseUtils.SMS_TEXT_FNAME_GUSTO);
									}

									strSurveyMessage = strSurveyMessage.replaceAll(CaseUtils.SMS_TEXT_CASE_ID, objCase.Id);
									strSurveyMessage = strSurveyMessage.replaceAll(CaseUtils.SMS_TEXT_OWNER_ID, objCase.OwnerId);

									objSMS.Message__c = strSurveyMessage;

									list_SMSToCreate.add(objSMS);

									objCase.Survey_Sent__c = true;
									objCase.Survey_Sent_Date_Time__c = System.now();
							}
					}
			}

			if (list_SMSToCreate.size() > 0) {
					try {
							insert list_SMSToCreate;
					} catch (Exception ex) {
							ExceptionLogUtil.logException('CaseTriggerHelper', 'createSMSRecords', ex.getMessage(), ex.getStackTraceString() + '. line number: ' + ex.getLineNumber());
					}
			}
	}

	/*
	 * @author:         Ankit CS
	 * @description:    This method sets the Automated_Email_Sent__c field on Case.
	 * @param:          objCase - Case from trigger.new
	 */
	private void setAutomatedEmailSent(Case objCase) {
			if (objCase.RecordTypeId != null) {
					if (
							objCase.Origin == 'Email' &&
							objCase.Authorized_User__c == 'No' &&
							objCase.Type != 'Cobra' &&
							String.isBlank(objCase.Historical_Data__c) &&
							!objCase.Skip_Auto_Response__c &&
							objCase.Routing_Case_Reason__c != 'Response to NPS Survey' &&
							(String.isNotBlank(objCase.Requester_Email__c) &&
							!objCase.Requester_Email__c.contains('guideline.com') &&
							!objCase.Requester_Email__c.contains('apintego.com') &&
							!objCase.Requester_Email__c.contains('myhrsupportcenter.com') &&
							!objCase.Requester_Email__c.contains('hranswerlink.com'))
					) {
							if (recordTypeIdNameMap.get(objCase.RecordTypeId).contains('Tax Res')) {
									objCase.Automated_Email_Sent__c = 'Payroll Care NOT Authorized';
							} else if (recordTypeIdNameMap.get(objCase.RecordTypeId).contains('Modern Bank')) {
									objCase.Automated_Email_Sent__c = 'Modern Bank NOT Authorized';
							} else if (recordTypeIdNameMap.get(objCase.RecordTypeId).contains('Benefits Care')) {
									objCase.Automated_Email_Sent__c = 'Ben Care NOT Authorized';
							}
					} else if (
							(recordTypeIdNameMap.get(objCase.RecordTypeId) == 'Payroll Care' ||
							recordTypeIdNameMap.get(objCase.RecordTypeId) == 'Tax Res') &&
							((objCase.Origin == 'Email' && objCase.Authorized_User__c != 'No') || objCase.Origin == 'Gusto') &&
							objCase.Type != 'Otter Case' &&
							objCase.Type != 'EOY Spot Check' &&
							String.isBlank(objCase.Historical_Data__c) &&
							!objCase.Skip_Auto_Response__c &&
							objCase.Routing_Case_Reason__c != 'Response to NPS Survey' &&
							(String.isNotBlank(objCase.Requester_Email__c) &&
							!objCase.Requester_Email__c.contains('guideline.com') &&
							!objCase.Requester_Email__c.contains('apintego.com') &&
							!objCase.Requester_Email__c.contains('myhrsupportcenter.com') &&
							!objCase.Requester_Email__c.contains('hranswerlink.com'))
					) {
							objCase.Automated_Email_Sent__c = 'Engagement Case Acknowledgement';
					} else if (recordTypeIdNameMap.get(objCase.RecordTypeId) == 'Modern Bank') {
							if (
									((objCase.Origin == 'Email' && objCase.Authorized_User__c != 'No') || objCase.Origin == 'Gusto') &&
									objCase.Type == 'Savings' &&
									objCase.Type != 'Modern Bank' &&
									!objCase.Skip_Auto_Response__c
							) {
									objCase.Automated_Email_Sent__c = 'Modern Bank Savings';
							} else if (
									((objCase.Origin == 'Email' && objCase.Authorized_User__c != 'No') || objCase.Origin == 'Gusto') &&
									!objCase.Skip_Auto_Response__c &&
									objCase.Type != 'Savings'
							) {
									objCase.Automated_Email_Sent__c = 'Modern bank Ack';
							}
					} else if (recordTypeIdNameMap.get(objCase.RecordTypeId) == 'Benefits Care') {
							if (
									objCase.Type != 'Suspension Audit' &&
									objCase.Type != 'EE Status Audit' &&
									objCase.Type != 'Shareholder Audit' &&
									objCase.Type != 'Company Taxability Audit' &&
									objCase.Type != 'Owner Status audit' &&
									!objCase.Skip_Auto_Response__c &&
									objCase.Routing_Case_Reason__c != 'Response to NPS Survey' &&
									(String.isNotBlank(objCase.Requester_Email__c) &&
									!objCase.Requester_Email__c.contains('guideline.com') &&
									!objCase.Requester_Email__c.contains('apintego.com') &&
									!objCase.Requester_Email__c.contains('myhrsupportcenter.com') &&
									!objCase.Requester_Email__c.contains('hranswerlink.com'))
							) {
									if (
											((objCase.Origin == 'Email' && objCase.Authorized_User__c != 'No' && objCase.Type != 'Cobra') || objCase.Origin == 'Gusto') &&
											String.isBlank(objCase.Historical_Data__c)
									) {
											objCase.Automated_Email_Sent__c = 'Engagement Case Acknowledgement';
									} else if (objCase.Type == 'Cobra') {
											objCase.Automated_Email_Sent__c = 'COBRA Case Acknowledgement';
									}
							}
					}
			}
	}

	/**
	 * @Author      : Anurag Gautam
	 * @Description : Implement Mops logic for Case Status Handler - Member Ops
	 * @Parm        : List new Cases & Map old Cases
	 * @Return      : NA
	 */
	public void memberOpsCaseStatusHandler(List<Case> list_NewCases, Map<Id, Case> map_OldCases) {
		String strCaseRTPrefix = 'MF';
		Set<Id> set_CarrierIds = new Set<Id>();
		Set<Id> set_MFRecordTypeIds = new Set<Id>();

		for (String strKey : recordTypeNameIdMap.Keyset()) {
				if (strKey?.startsWithIgnoreCase(strCaseRTPrefix)) {
						set_MFRecordTypeIds.add(Id.valueOf(recordTypeNameIdMap.get(strKey)));
				}
		}

		for (Case objNewCase : list_NewCases) {
				if (
						objNewCase.Carrier__c != null &&
						objNewCase.RecordTypeID != null &&
						set_MFRecordTypeIds.contains(objNewCase.RecordTypeID) &&
						objNewCase.Automation_Status__c == CaseUtils.STATUS_COMPLETED &&
						objNewCase.Automation_Status__c != map_OldCases.get(objNewCase.Id).Automation_Status__c
				) {
						set_CarrierIds.add(objNewCase.Carrier__c);
				}
		}
		if (set_CarrierIds.isEmpty()) {
				return;
		}

		Map<Id, Carrier__c> map_CaseWithCarriers = Utils.getCarrierInfo(set_CarrierIds); 
		Carrier__c objCarrier = new Carrier__c();
		for (Case objNewCase : list_NewCases) {
			if (map_CaseWithCarriers.containsKey(objNewCase.Carrier__c)) {
                
				objCarrier = map_CaseWithCarriers.get(objNewCase.Carrier__c);
				if (objCarrier.Name.equalsIgnoreCase(CaseUtils.CARRIER_FLORIDA_BLUE)) {
					objNewCase.Status = CaseUtils.STATUS_SUBMITTED;
					objNewCase.OwnerId = CaseUtils.ID_MF_MF_FOLLOW_UP_QUEUE;
				}
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
							if (objRecordType.Authorized_User__c) {
									set_AuthorizedUserRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
							}

							if (objRecordType.Auto_Solve_Date_Time__c) {
									set_AutoSolveRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
							}

							if (objRecordType.Auto_Close_Date_Time__c) {
									set_AutoCloseRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
							}
							if (objRecordType.Auto_In_Progress_Date_Time__c) {
									set_AutoInProgressRecordTypeIds.add(map_CaseRecNameToId.get(objRecordType.Label));
							}

							if (objRecordType.Answer_IQ_Eligible__c) {
									set_AnswerIQEligible.add(map_CaseRecNameToId.get(objRecordType.Label));
							}
					}
			}
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description Add Case Member Fulfilment process builder field updates logics here
	 */
	public void updateMFCaseFields(List<Case> list_MFCases, Map<Id, Case> map_OldObjCase, Set<Id> set_CarrierIds) {
			Map<Id, Carrier__c> map_Carrier = CaseQueryHelper.queryCaseCarrierData(set_CarrierIds);
			Map<Id, String> map_caseIDToMileStoneType = new Map<Id, String>();
			Map<String, Id> map_MileStoneTypeByName = CaseQueryHelper.queryMileStoneTypeData();
			Date dtFollowUpDate = null;
			Id idCaseCurrentOwner = null;
			String strCaseStatus = '';

			for (Case objCaseRecord : list_MFCases) {
					Case objOldCaseRecord = null;
					if (objCaseRecord.Id != null && map_OldObjCase != null) {
							objOldCaseRecord = map_OldObjCase?.containsKey(objCaseRecord.Id) ? map_OldObjCase.get(objCaseRecord.Id) : null;
					}

					Carrier__c objCarrierRecord = objCaseRecord.Carrier__c != null ? map_Carrier.get(objCaseRecord.Carrier__c) : null;

					dtFollowUpDate = objCaseRecord.Follow_Up_Date__c;
					idCaseCurrentOwner = objCaseRecord.OwnerId;
					strCaseStatus = objCaseRecord.Status;

					// Default Submission and Follow up
					Boolean blnFieldsUpdated =
							objOldCaseRecord != null &&
							(objCaseRecord.Carrier__c != objOldCaseRecord.Carrier__c ||
							objCaseRecord.Submission_Method__c != objOldCaseRecord.Submission_Method__c ||
							objCaseRecord.Historical_Data__c != objOldCaseRecord.Historical_Data__c ||
							objCaseRecord.Follow_Up_Method__c != objOldCaseRecord.Follow_Up_Method__c);
					if (objOldCaseRecord == null || blnFieldsUpdated) {
							if (objCaseRecord.Carrier__c != null && String.isBlank(objCaseRecord.Historical_Data__c) && String.isBlank(objCaseRecord.Submission_Method__c)) {
									//Update Case Submission Method
									if (
											objCaseRecord.Type == CaseUtils.TYPE_GROUP_UPDATES ||
											String.isBlank(objCaseRecord.Carrier__c) ||
											(objCarrierRecord != null && String.isNotBlank(objCarrierRecord.Submission_Method__c))
									) {
											objCaseRecord.Submission_Method__c = objCarrierRecord.Submission_Method__c;
									} else {
											objCaseRecord.Submission_Method__c = CaseUtils.STR_NON_MAPPED_FORM;
									}
							}

							if (objCaseRecord.Carrier__c != null && String.isBlank(objCaseRecord.Historical_Data__c) && String.isBlank(objCaseRecord.Follow_Up_Method__c)) {
									objCaseRecord.Follow_Up_Method__c = objCarrierRecord != null ? objCarrierRecord.Follow_Up_Method__c : '';
							}
					}

					if (objOldCaseRecord != null) {
							// Status is changed to submitted
							if (
									!blnFormAutomationBatch &&
									strCaseStatus == CaseUtils.STATUS_SUBMITTED &&
									objOldCaseRecord.Status != CaseUtils.STATUS_SUBMITTED &&
									set_EligibleSubmittedRecordTypes.contains(objCaseRecord.RecordTypeId)
							) {
									//Update Submitted By
									if (objCaseRecord.Date_Time_Submitted__c == null) {
											objCaseRecord.Date_Time_Submitted__c = System.now();
											objCaseRecord.Submitted_By__c = UserInfo.getUserId();
									}

									//Update Case To Closed For Member/Group Updates
									if (objCaseRecord.Type == CaseUtils.TYPE_MEMBER_UPDATES && dtFollowUpDate == null) {
											objCaseRecord.Status = CaseUtils.STATUS_CLOSED;

											if (nameIdQueueMap != null && nameIdQueueMap.containsKey(CaseUtils.QUEUE_MF_COMPLETED)) {
													objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED);
											}
									}

									if (dtFollowUpDate == null && objCaseRecord.Submission_Method__c == CaseUtils.STR_CARRIER_PORTAL && objCaseRecord.Type != CaseUtils.TYPE_QLE) {
											objCaseRecord.Status = CaseUtils.STATUS_CLOSED;
											objCaseRecord.Closed_By__c = UserInfo.getUserId();

											if (nameIdQueueMap != null && nameIdQueueMap.containsKey(CaseUtils.QUEUE_MF_COMPLETED)) {
													objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED);
											}
									}

									if (
											objCaseRecord.Type == CaseUtils.TYPE_QLE ||
											dtFollowUpDate != null ||
											(objCaseRecord.Submission_Method__c != CaseUtils.STR_CARRIER_PORTAL &&
											objCaseRecord.Automation_Status__c != CaseUtils.STATUS_SUBMITTED &&
											objCaseRecord.OwnerId != nameIdQueueMap.get(CaseUtils.QUEUE_MF_AUTOMATION_FOLLOWUP))
									) {
											objCaseRecord.Follow_Up_Date__c = System.today().addDays(7);

											if (
													nameIdQueueMap != null &&
													UserUtils.setMOpsIntegrationUsers.contains(objCaseRecord.OwnerId) &&
													nameIdQueueMap.containsKey(CaseUtils.QUEUE_MF_FOLLOWUP)
											) {
													objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_FOLLOWUP);
											}
									}

									//Update Submission Milestone Data
									map_caseIDToMileStoneType.put(objCaseRecord.Id, objCaseRecord.Id + '-' + map_MileStoneTypeByName.get(CaseUtils.STR_MILESTONE_SUBMISSION_DEADLINE));
							}

							//Status is changed to Followup Complete
							if (
									strCaseStatus == CaseUtils.CASE_STATUS_FOLLOWUP_COMPLETED &&
									objOldCaseRecord.Status != CaseUtils.CASE_STATUS_FOLLOWUP_COMPLETED &&
									set_EligibleSubmittedRecordTypes.contains(objCaseRecord.RecordTypeId)
							) {
									//Update Followup Date Time and Followed By
									objCaseRecord.Follow_Up_Completed_by__c = UserInfo.getUserId();
									objCaseRecord.Status = CaseUtils.STATUS_CLOSED;
									objCaseRecord.Closed_By__c = UserInfo.getUserId();

									if (nameIdQueueMap != null && nameIdQueueMap.containsKey(CaseUtils.QUEUE_MF_COMPLETED)) {
											objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED);
									}
							}

							//Status is Changed to Closed
							if (
									objCaseRecord.Status == CaseUtils.STATUS_CLOSED &&
									objOldCaseRecord.Status != CaseUtils.STATUS_CLOSED &&
									set_EligibleSubmittedRecordTypes.contains(objCaseRecord.RecordTypeId)
							) {
									//Move Case to Closed Queue
									if (nameIdQueueMap != null && nameIdQueueMap.containsKey(CaseUtils.QUEUE_MF_COMPLETED)) {
											objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED);
									}
				                    objCaseRecord.Closed_By__c = UserInfo.getUserId();
									//Update Submission Milestone Data
									map_caseIDToMileStoneType.put(objCaseRecord.Id, objCaseRecord.Id + '-' + map_MileStoneTypeByName.get(CaseUtils.STR_MILESTONE_SUBMISSION_DEADLINE));
							} else if (
									strCaseStatus != CaseUtils.CASE_STATUS_PENDING &&
									objOldCaseRecord.Status == CaseUtils.CASE_STATUS_PENDING &&
									String.isBlank(objCaseRecord.Historical_Data__c)
							) {
									map_caseIDToMileStoneType.put(objCaseRecord.Id, objCaseRecord.Id + '-' + map_MileStoneTypeByName.get(CaseUtils.STR_MILESTONE_PENDING_DEADLINE));
							}
					}

					if (objOldCaseRecord == null) {
							// When new MF Case record will be created.
							if (
									String.isBlank(objCaseRecord.MF_Group_Number__c) &&
									String.isBlank(objCaseRecord.Automation_Status__c) &&
									(objCaseRecord.Status == CaseUtils.STATUS_DRAFT ||
									objCaseRecord.Status == CaseUtils.STATUS_NEW)
							) {
								if (objCaseRecord.RecordTypeId == CaseUtils.RECTYPE_MF_MEMBER_GROUP_UPDATES && !set_TAdACarrierIds.contains(objCaseRecord.Carrier__c) && String.isNotBlank(objCaseRecord.Integration_Key__c)) {
									//Deprecate WFR - MF update: update the status to On Hold when case is created
									objCaseRecord.Status = CaseUtils.STATUS_ON_HOLD;
								} else if (
									set_CancelationRecordTypes.contains(objCaseRecord.RecordTypeId) &&
									Label.BASIC_Carrier != objCaseRecord.Carrier__c &&
									!set_TAdACarrierIds.contains(objCaseRecord.Carrier__c) &&
									objCaseRecord.MF_No_Of_Days_To_Effective_Date__c >= intDaysDifference &&
									String.isNotBlank(objCaseRecord.Integration_Id__c)
								) {
									//Deprecate WFR - MF NHE: update the status to On Hold when case is created
									objCaseRecord.Status = CaseUtils.STATUS_ON_HOLD;
								}
							}
					}

					if (
							(objOldCaseRecord == null ||
							objCaseRecord.Automation_Status__c != objOldCaseRecord.Automation_Status__c) &&
							set_PendingAutomationStatusRT.contains(objCaseRecord.RecordTypeId) &&
							objCaseRecord.Automation_Status__c == CaseUtils.STATUS_SUBMITTED
					) {
							objCaseRecord.Status = CaseUtils.CASE_STATUS_PENDING;
					}
			}

			if (!map_caseIDToMileStoneType.isEmpty()) {
					updateMFCaseMileStoneRecords(map_caseIDToMileStoneType);
			}
	}

	/**
	 * @author Elavarasan Nagarathinam
	 * @description Update milestone records for case
	 */
	public void updateMFCaseMileStoneRecords(Map<Id, String> map_caseIDToMileStoneType) {
			if (map_caseIDToMileStoneType == null || map_caseIDToMileStoneType.isEmpty()) {
					return;
			}

			List<CaseMilestone> list_MileStoneRecords = new List<CaseMilestone>();
			for (CaseMilestone objMileStone : CaseQueryHelper.queryCaseMileStoneData(map_caseIDToMileStoneType.keySet())) {
					List<String> list_caseMileStoneType = map_caseIDToMileStoneType.get(objMileStone.CaseId).split('-');
					String strMileStoneType = list_caseMileStoneType != null && list_caseMileStoneType.size() > 1 ? list_caseMileStoneType[1] : null;
					if (objMileStone.CompletionDate == null && objMileStone.MilestoneTypeId == strMileStoneType) {
							objMileStone.CompletionDate = System.now();
							list_MileStoneRecords.add(objMileStone);
					}
			}

			if (!list_MileStoneRecords.isEmpty()) {
					try {
							Boolean skipTrigger = CaseTriggerHelper.skipTrigger;
							CaseTriggerHelper.skipTrigger = true;
							update list_MileStoneRecords;
							CaseTriggerHelper.skipTrigger = skipTrigger;
					} catch (Exception e) {
							ExceptionLogUtil.logException('CaseTriggerHelper', 'updateMFCaseMileStoneRecords', e.getMessage(), e.getStackTraceString());
					}
			}
	}

	/**
	 * @author Alex Xiong
	 * @description if case is new or updated to be owned by a Queue,
	 * update Recent Case Owner Queue Id and Name fields
	 * @parm new Case and old Case
	 */
	public static void recentQueueUpdate(Case objNewCase, Case objOldCase) {
			String strOwnerId = objNewCase.OwnerId;

			if ((objOldCase == null || objNewCase.OwnerId != objOldCase.OwnerId) && strOwnerId.startsWith(CaseUtils.QUEUE_ID_PREFIX)) {
					objNewCase.Recent_Queue_Id__c = objNewCase.OwnerId;
					objNewCase.Recent_Queue_Name__c = map_Queues.get(objNewCase.OwnerId).Name;
			}
	}

	/**
	 * @author Alex Xiong
	 * @description update Tax Res OB Message Trigger to true if criteria is met
	 * @parm Case to check
	 */
	public static void updateTaxResOBMessageTrigger(Case objCase) {
			if (
					objCase.RecordTypeId == CaseUtils.RECTYPE_TAXRES &&
					objCase.Answer_IQ_Processed__c == 'Yes' &&
					!objCase.TaxRes_OBMsg_Trigger__c &&
					objCase.Status != CaseUtils.STATUS_SOLVED &&
					!objCase.In_App_Notice__c
			) {
					Boolean blnValue = false;

					//if Case Subject does not contain any of the subjects in the list, set TaxRes_OBMsg_Trigger__c to true
					for (String strSubject : CaseUtils.list_TaxResOBMsgTriggerSubjects) {
							if (String.isNotBlank(objCase.Subject) && objCase.Subject.contains(strSubject)) {
									blnValue = false;
									break;
							} else {
									blnValue = true;
							}
					}
					objCase.TaxRes_OBMsg_Trigger__c = blnValue;
			}
	}

	/**
	 * @author Alex Xiong
	 * @description query Contacts
	 */
	public static void queryContacts(Set<String> set_ContactIds, Set<String> set_PhoneNumbers) {
			if (map_Contacts == null) {
					map_Contacts = new Map<Id, Contact>();
					map_SMSContacts = new Map<Id, Contact>();
					map_PhoneToContacts = new Map<String, Id>();

					if (set_ContactIds.size() > 0 || set_PhoneNumbers.size() > 0) {
							map_Contacts = new Map<Id, Contact>(
									[
											SELECT
													Id,
													Name,
													Survey_Opt_Out__c,
													Normalized_Mobile_Phone__c,
													Normalized_Other_Phone__c,
													Normalized_Phone__c,
													ZP_Phone__c,
													Additional_Phone_Numbers__c,
													Phone,
													Email,
													OtherPhone,
													MobilePhone,
													AccountId,
													Account.Name,
													Account.Tier__c,
													Account.AM_Tier__c,
													Account.Care_Account_Manager__c,
													Account.Care_Account_Manager__r.IsActive,
													Account.Care_Account_Manager__r.Out_Of_Office__c,
													Account.Has_Benefits__c,
													Account.Experiment_Pilot__c,
													Small_Biz_Engagement__c,
													Account.RecordTypeId,
													Account.Sold_By__c,
													Account.Referred_By__c,
													Account.Sold_By__r.OwnerId,
													Account.Referred_By__r.OwnerId,
													Account.OwnerId
											FROM Contact
											WHERE
													Id IN :set_ContactIds
													OR (Normalized_Phone__c != NULL
													AND Normalized_Phone__c IN :set_PhoneNumbers)
													OR (Normalized_Other_Phone__c != NULL
													AND Normalized_Other_Phone__c IN :set_PhoneNumbers)
													OR (Normalized_Mobile_Phone__c != NULL
													AND Normalized_Mobile_Phone__c IN :set_PhoneNumbers)
													OR (ZP_Phone__c != NULL
													AND ZP_Phone__c IN :set_PhoneNumbers)
													OR (Phone != NULL
													AND Phone IN :set_PhoneNumbers)
													OR (MobilePhone != NULL
													AND MobilePhone IN :set_PhoneNumbers)
									]
							);

							//to prevent null pointers b/c map_Contacts can become null
							if (map_Contacts == null) {
									map_Contacts = new Map<Id, Contact>();
							}

							for (Contact objContact : map_Contacts.values()) {
									if (
											set_PhoneNumbers.contains(objContact.Normalized_Phone__c) ||
											set_PhoneNumbers.contains(objContact.Normalized_Other_Phone__c) ||
											set_PhoneNumbers.contains(objContact.Normalized_Mobile_Phone__c) ||
											set_PhoneNumbers.contains(objContact.ZP_Phone__c) ||
											set_PhoneNumbers.contains(objContact.Phone) ||
											set_PhoneNumbers.contains(objContact.MobilePhone)
									) {
											//SMS Contacts
											map_SMSContacts.put(objContact.Id, objContact);

											//IVR
											if (set_PhoneNumbers.contains(objContact.Normalized_Phone__c)) {
													map_PhoneToContacts.put(objContact.Normalized_Phone__c, objContact.Id);
											} else if (set_PhoneNumbers.contains(objContact.Normalized_Other_Phone__c)) {
													map_PhoneToContacts.put(objContact.Normalized_Other_Phone__c, objContact.Id);
											} else if (set_PhoneNumbers.contains(objContact.Normalized_Mobile_Phone__c)) {
													map_PhoneToContacts.put(objContact.Normalized_Mobile_Phone__c, objContact.Id);
											} else if (set_PhoneNumbers.contains(objContact.ZP_Phone__c)) {
													map_PhoneToContacts.put(objContact.ZP_Phone__c, objContact.Id);
											}
									}
							}
					}
			}
	}

	/**
	 * @author Alex Xiong
	 * @description query Accounts
	 */
	public static void queryAccounts(Set<Id> set_AccountIds) {
			if (map_Accounts == null || (map_Accounts.isEmpty() && !set_AccoundIdsForAssigningOrderToCase.isEmpty()) || (map_Accounts.isEmpty() && !set_AccountIds.isEmpty())) {
					map_Accounts = new Map<Id, Account>();
					list_AccountsForAssigningOrderToCase = new List<Account>();
					list_AccountsForFulfillmentCaseRouting = new List<Account>();

					if (set_AccountIds.size() > 0) {
							Set<String> set_OppStages = new Set<String>{ 'Closed Won', 'Pending PR' };

							String strAccountQueryFields = 'SELECT Id,RecordTypeId, RecordType.Name, Name, Tier__c, CX_Experiment__c, AM_Tier__c, Care_Account_Manager__c, Care_Account_Manager__r.IsActive, Care_Account_Manager__r.Out_Of_Office__c, Has_Benefits__c, ZP_Company_Id__c, Experiment_Pilot__c, Last_Rep_Activity_Date_New__c, Last_Account_Activity_Date__c, Last_Activity_Date__c,Date_of_GEP_Live__c,Sold_By__c,Type,Referred_By__r.Name';

							//for assigningOrderToCase()
							String strOrdersSubQuery = ', (SELECT Id, Name, Case__c, OwnerId, Owner.FirstName, Payroll_Run_Date__c, First_Check_Date__c FROM Orders ORDER BY CreatedDate DESC)';

							//for setFulfillmentCaseRouting()
							Id idBenOrderBOR = BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID;
							String strBenefitOrdersSubQuery = ', (SELECT Id, Order_Status__c, Requires_Action__c, OwnerId, Opportunity__c FROM Benefit_Orders__r WHERE RecordTypeId = :idBenOrderBOR AND Opportunity__r.StageName IN :set_OppStages)';
							String strFromAccount = ' FROM Account';
							String strWhereClause = ' WHERE Id IN :set_AccountIds';

							//build Account query string based on collections from createCollections
							String strAccountQuery = strAccountQueryFields;

							if (set_AccoundIdsForAssigningOrderToCase.size() > 0) {
									strAccountQuery += strOrdersSubQuery;
							}

							if (set_AccountIdBOR.size() > 0) {
									strAccountQuery += strBenefitOrdersSubQuery;
							}

							//FROM
							strAccountQuery += strFromAccount;

							//WHERE
							strAccountQuery += strWhereClause;

							map_Accounts = new Map<Id, Account>((List<Account>) Database.query(strAccountQuery));

							//to prevent null pointers b/c map_Accounts can become null
							if (map_Accounts == null) {
									map_Accounts = new Map<Id, Account>();
							}

							for (Account objAccount : map_Accounts.values()) {
									//for assigningOrderToCase()
									if (set_AccoundIdsForAssigningOrderToCase.size() > 0 && set_AccoundIdsForAssigningOrderToCase.contains(objAccount.Id)) {
											list_AccountsForAssigningOrderToCase.add(objAccount);
									}

									//for setFulfillmentCaseRouting()
									if (set_AccountIdBOR.size() > 0 && set_AccountIdBOR.contains(objAccount.Id)) {
											list_AccountsForFulfillmentCaseRouting.add(objAccount);
									}

									//for updateAccLeadActivityDate()
									if (!map_AccCase.isEmpty()) {
											list_AccountsForUpdateAccLeadActivityDate.add(objAccount);
									}
							}
					}
			}

			if (map_CompanyIdAccounts == null || map_CompanyIdAccounts.isEmpty()) {
					map_CompanyIdAccounts = new Map<String, Account>();
					if (set_ZPCompanyIdsFBED?.size() > 0) {
							for (Account objAccount : [
									SELECT
											Id,
											ZP_Company_Id__c,
											Name,
											(SELECT ID, Contact__c FROM ZP_User_Roles__r WHERE Role_Name__c = :CaseUtils.TAXRES_PRIMARY_PAYROLL_ADMIN AND Company_Id__c IN :set_ZPCompanyIdsFBED)
									FROM Account
									WHERE ZP_Company_Id__c IN :set_ZPCompanyIdsFBED
							]) {
									map_CompanyIdAccounts.put(objAccount.ZP_Company_Id__c, objAccount);
							}
					}
			}
	}

	/**
 * @author Pravesh Rana
 * @description make sure that 	map_ParentCaseDetails is populated based on 
				 Case	ParentId foeld value
	*/
	public static void getParentCaseDetails(Set<Id> set_ParentCaseIds) {
			if (!set_ParentCaseIds?.isEmpty() && map_ParentCaseDetails == null) {
					map_ParentCaseDetails = new Map<Id, Case>([SELECT Id, Origin, CaseNumber FROM Case WHERE ParentId = :set_ParentCaseIds]);
			}
	}

	/**
	 * @author Swati Arya
	 * @description Update the record type to Sales Cases and type to Sales Email
	 * 				when the Owner is changed and record type is not Sales Cases
	 */
	public static void stampSalesCasesChanges(Case objNewCase, Case objOldCase) {
			if (CaseUtils.map_SalesCasesQueues?.containsKey(CaseUtils.QUEUE_NAME_SALES_CASE) && objNewCase.OwnerId == CaseUtils.map_SalesCasesQueues?.get(CaseUtils.QUEUE_NAME_SALES_CASE)) {
					if ((objOldCase == null || objNewCase.OwnerId != objOldCase.OwnerId) && objNewCase.RecordTypeId != CaseUtils.RECTYPE_SALES_CASES) {
							objNewCase.RecordTypeId = CaseUtils.RECTYPE_SALES_CASES;
							objNewCase.Type = CaseUtils.TYPE_SALES_EMAIL;
					}

					if (
							(objOldCase == null ||
							objNewCase.OwnerId != objOldCase.OwnerId ||
							objNewCase.RecordTypeId != objOldCase.RecordTypeId ||
							objNewCase.Historical_Data__c != objOldCase.Historical_Data__c ||
							objNewCase.Origin != objOldCase.Origin) &&
							objNewCase.RecordTypeId == CaseUtils.RECTYPE_SALES_CASES &&
							objNewCase.Historical_Data__c == null &&
							objNewCase.Origin == CaseUtils.ORIGIN_PARTNER_SETUP &&
							CaseUtils.map_SalesCasesQueues?.containsKey(CaseUtils.QUEUE_NAME_SALES_PARTNER_TRANSFER_QUEUE) &&
							CaseUtils.map_SalesCasesQueues?.get(CaseUtils.QUEUE_NAME_SALES_PARTNER_TRANSFER_QUEUE) != null
					) {
							objNewCase.OwnerId = CaseUtils.map_SalesCasesQueues?.get(CaseUtils.QUEUE_NAME_SALES_PARTNER_TRANSFER_QUEUE);
					}
			}

			if ((objOldCase == null || objNewCase.Status != objOldCase.Status) && objNewCase.RecordTypeId == CaseUtils.RECTYPE_SALES_CASES && objNewCase.Status == CaseUtils.STATUS_CLOSED) {
					objNewCase.Auto_Close_Date_Time__c = System.today().addDays(7);
			}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Move case owner assignment WFR to apex
	 * @Parm        : Map new Cases & Map old Cases
	 * @Return      : NA
	 */
	public void updateMFCaseOwnerFields(List<Case> list_MFCases, Map<Id, Case> map_OldObjCase) {
			for (Case objCaseRecord : list_MFCases) {
					Case objOldCaseRecord = null;
					if (objCaseRecord.Id != null && map_OldObjCase != null) {
							objOldCaseRecord = map_OldObjCase?.containsKey(objCaseRecord.Id) ? map_OldObjCase.get(objCaseRecord.Id) : null;
					}

					if (objOldCaseRecord == null || objCaseRecord.Automation_Status__c != objOldCaseRecord.Automation_Status__c || blnFormAutomationBatch) {
							if (CaseUtils.STATUS_FAILED == objCaseRecord.Automation_Status__c && CaseUtils.set_RTAutomationStatusFailed.contains(objCaseRecord.RecordTypeId)) {
									checkBYOBCustomerAndSetOwner(objCaseRecord);
							} else if (CaseUtils.STATUS_COMPLETED == objCaseRecord.Automation_Status__c && CaseUtils.set_RTAutomationStatusCompleted.contains(objCaseRecord.RecordTypeId)) {
									if (CaseUtils.STR_EMAIL_SENT_TO_CARRIER.equalsIgnoreCase(objCaseRecord.Automation_Message__c)) {
											objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_FOLLOWUP);
											objCaseRecord.Status = CaseUtils.STATUS_SUBMITTED;
									} else {
											objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MF_COMPLETED);
											objCaseRecord.Status = CaseUtils.STATUS_CLOSED;
									}
							}
					}
			}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Set Case Owner on the basis of BYOB_Customer__c flag.
	 * @Parm        : Object of Case
	 * @Return      : NA
	 */
	public void checkBYOBCustomerAndSetOwner(Case objCaseRecord) {
			objCaseRecord.Status = CaseUtils.STATUS_NEW;
			objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MEMBER_FULFILLMENT);
			if (objCaseRecord.BYOB_Customer__c) {
					objCaseRecord.OwnerId = nameIdQueueMap.get(CaseUtils.QUEUE_MEMBER_OPS_BYB);
			}
	}

	/**
	 * @Author      : Elavarasan Nagarathinam
	 * @Description : Update all preivously answered auto solved case's customer journey, root cause and sub root cause when related parent case is closed
	 * @Parm        : Map[Case record]
	 * @Return      : void
	 **/
	public void updateTaxResPreviouslyAnsweredCases(Map<Id, Case> map_TaxResClosedCases) {
			if (map_TaxResClosedCases.isEmpty()) {
					return;
			}

			List<Case> list_CasesToUpdate = new List<Case>();
			for (Case objChildCase : [
					SELECT Id, Customer_Journey__c, Root_Cause__c, Sub_Root_Cause__c, Related_Case__c
					FROM Case
					WHERE
							Related_Case__c IN :map_TaxResClosedCases.keySet()
							AND Mass_Email_Step__c INCLUDES (:TaxResNoticeIndexDetailsController.PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED)
							AND Status = :CaseUtils.STATUS_CLOSED
			]) {
					Case objParentCase = map_TaxResClosedCases.get(objChildCase.Related_Case__c);
					objChildCase.Customer_Journey__c = objParentCase.Customer_Journey__c;
					objChildCase.Root_Cause__c = objParentCase.Root_Cause__c;
					objChildCase.Sub_Root_Cause__c = objParentCase.Sub_Root_Cause__c;
					list_CasesToUpdate.add(objChildCase);
			}

			if (!list_CasesToUpdate.isEmpty()) {
					try {
							CaseTriggerHandler.blnSkipBeforeUpdate = true;
							CaseTriggerHandler.blnSkipAfterUpdate = true;
							update list_CasesToUpdate;
							CaseTriggerHandler.blnSkipBeforeUpdate = false;
							CaseTriggerHandler.blnSkipAfterUpdate = false;
					} catch (Exception objException) {
							ExceptionLogUtil.logException('CaseTriggerHelper', 'updateTaxResPreviouslyAnsweredCases', objException.getMessage(), 'Low');
					}
			}
	}

    /**
     * Author: Pradeep Chary
     * Date: 12/10/2024
     * Desc: Get Case Pillar and Sub Pillar Mappings
    **/
    public static void getPillarMapping() {
        map_PillarMappingByKey = new Map<String, Case_Pillar_Mapping__c>();
        map_PillarWOCompanySize = new Map<String, Case_Pillar_Mapping__c>();
        list_Specializations = String.isNotBlank(Label.Engagement_Specializations) ? Label.Engagement_Specializations.split(';') : new List<String>();
        for (Case_Pillar_Mapping__c objMapping : Case_Pillar_Mapping__c.getAll().values()) {
            String strKey = objMapping.Case_Origin__c;
            String strKey2 = objMapping.Case_Origin__c;
            if (String.isNotBlank(objMapping.Specialization__c)) {
                strKey += objMapping.Specialization__c;
                if (list_Specializations.contains(objMapping.Specialization__c)) {
                        strKey += objMapping.Persona__c + '' + objMapping.Company_Size__c;
                }
            } else {
                strKey += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c + '' + objMapping.Company_Size__c;
                strKey2 += objMapping.Case_Type__c + '' + objMapping.Persona__c + '' + objMapping.Support_Level__c;
                map_PillarWOCompanySize.put(strKey2.toLowerCase(), objMapping);
            }

            map_PillarMappingByKey.put(strKey.toLowerCase(), objMapping);
        }
    }

	/**
	* Author: Pradeep Chary
	* Date: 12/10/2024
	* Desc: Map Case Pillar and Sub Pillar based on Case fields
	**/
	public static Case updateCasePillar(Case objCase, Case oldCase) {
		if (map_PillarMappingByKey == null) {
			getPillarMapping();
		}

		if (list_Specializations == null && list_Specializations.isEmpty()) {
			list_Specializations = String.isNotBlank(Label.Engagement_Specializations) ? Label.Engagement_Specializations.split(';') : new List<String>();
		} 

		String strKey = '';
		String strCaseOrigin = '';
		if (objCase.Origin == CaseUtils.ORIGIN_EMAIL || objCase.Channel__c == CaseUtils.ORIGIN_EMAIL) {
			strCaseOrigin = CaseUtils.ORIGIN_EMAIL;
		} else if (objCase.Origin == CaseUtils.ORIGIN_CHAT || objCase.Channel__c == CaseUtils.ORIGIN_CHAT) {
			strCaseOrigin = CaseUtils.ORIGIN_CHAT;
		}

		if (
			String.isNotBlank(objCase.Specialization__c) &&
			((oldCase != null && objCase.Specialization__c != oldCase.Specialization__c) || oldCase == null)
		) {
			strKey = strCaseOrigin + '' + objCase.Specialization__c;
			if (list_Specializations.contains(objCase.Specialization__c)) {
				strKey += objCase.Persona__c;
				if (objCase.Persona__c != CaseUtils.MEMBER_PERSONA && objCase.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
					strKey += objCase.Company_Size__c;
				}
			}
		} else if (
			(oldCase != null &&
			(objCase.Type != oldCase.Type ||
			objCase.Persona__c != oldCase.Persona__c ||
			objCase.Company_Size__c != oldCase.Company_Size__c ||
			objCase.Support_Level__c != oldCase.Support_Level__c ||
			(objCase.Origin == CaseUtils.ORIGIN_EMAIL && oldCase.Origin != CaseUtils.ORIGIN_EMAIL))) ||
			(oldCase == null)
		) {
			strKey = strCaseOrigin + '' + objCase.Type + '' + objCase.Persona__c + '' + objCase.Support_Level__c;
			if (objCase.Persona__c != CaseUtils.MEMBER_PERSONA && objCase.Persona__c != CaseUtils.ACCOUNTANT_PERSONA) {
				strKey += objCase.Company_Size__c;
			}
		}

		strKey = strKey.toLowerCase();
		if (String.isNotBlank(strKey)) {
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
		}

		return objCase;
	}

	/**
	 * @Author      : Jayesh Gawande
	 * @Description : Update Case Owner to Risk - FCI Queue if From Address is 'bsacompliance@nbkc.com'
	 * @Parm        : List[Case record]
	 * @Return      : void
	 **/
    private void setCaseOwnerWhenEmailSenderIsNBKC(List<Case> lstCases){
        //Fetch the Risk - FCI Queue Id
        Group Id_queueRiskFCIRec = [SELECT Id FROM Group WHERE Name = :CaseUtils.QUEUE_RISK_FCI LIMIT 1];
        
    	for (Case cse : lstCases) {
            if (cse.SuppliedEmail == Label.Case_NBKC_Investigation_From_Email && cse.origin==CaseUtils.ORIGIN_EMAIL){
                //Bypass case status updates for Risk Assurance Record Type 
                EmailMessageTriggerHelper.blnSkipStatusUpdateForRiskRecType=true;
                
                //Update the record type to Risk Assurance
                cse.RecordTypeId=CaseUtils.RECTYPE_RISK_ASSURANCE;
                cse.Type=CaseUtils.TYPE_INVESTIGATIONS;
               	cse.OwnerId = Id_queueRiskFCIRec.Id;
            }
        }
    }
}