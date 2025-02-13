/*
@Author:        David (Dato) Tsamalashvili
@Created Date:  09/17/2019
@Description:   Data layer for Case Trigger helper - all queries needed for
                Case Trigger Helper - should be executed here - followed by
                Patern - Query only one itme - other time get List/Map. 
*/
public class CaseQueryHelper {
	public static Map<String, EmailTemplate> map_EmailTemplates;
	public static Map<String, Case> map_EmailsAndParentCase;
	public static List<Id> list_PrivacyRequestApprovedForDisclosure;
	public static List<Data_Collection__c> list_DataCollections;
	public static List<ZP_User_Role__c> list_ofZPUserRoles;
	public static List<ZP_User_Role__c> list_ofZPUserRolesByCompIdUsrId;
	public static List<Contact> list_ofZpUserContacts;
	public static List<Contact> list_caseRelatedContacts;
	public static Map<String, Sub_Case_Reason_Classification__c> map_SubReason;
	public static List<Lead> list_Caselead;
	public static List<Lead> list_LeadWithActivityfields;
	public static Map<String, IVR_Routing_Log__c> map_IVR;
	public static Map<String, Id> map_ContactsFromPhone;
	public static List<Case> list_MassEmailCases;
	//Neha Dabas, 27th March 2020, to get tickets related to case
	public static List<Ticket__c> list_Tickets;
	public static list<EmailMessage> list_EmailMessages;
	public static List<Case_Merge_Exclusion__mdt> list_CaseMergeExclusionMdt;
	public static Map<String, Inactive_Case_Routing__mdt> map_InactiveTaxResCaseRoutingMdtRecords;
	public static List<Case> list_ParentCasesForMergedDuplicates;
	public static List<CaseMilestone> list_MileStoneRecords;
	public static Map<String, Id> map_MileStoneTypeByName;
	public static Map<Id, Carrier__c> map_Carrier;
	public static List<Case_Reason_Classification__c> list_CaseReasons;
	public static Map<Id, Auto_Solve_Package__c> map_AutoSolvePackages;

	public static List<Ticket__c> getRelatedTickets(Set<Id> set_CaseId) {
		if (list_Tickets == null) {
			if (set_CaseId != null && !set_CaseId.isEmpty()) {
				list_Tickets = [
					SELECT Requires_Action__c, Recert_Status__c, Escalation_Reason__c, Case__r.RecordTypeId, Fulfillment_Case__r.RecordTypeId, Fulfillment_Case__c, Case__c
					FROM Ticket__c
					WHERE Fulfillment_Case__c IN :set_CaseId OR Case__c IN :set_CaseId
				];
			}
		}
		return list_Tickets;
	}

	public static Map<String, EmailTemplate> getEmailTemplates(List<String> list_TemplateNames) {
		if (map_EmailTemplates == null) {
			map_EmailTemplates = queryEmailTemplate(list_TemplateNames);
		}
		return map_EmailTemplates;
	}

	public static Map<String, EmailTemplate> queryEmailTemplate(List<String> list_TemplateNames) {
		Map<String, EmailTemplate> map_Templates = new Map<String, EmailTemplate>();
		for (EmailTemplate objTemplate : [SELECT Id, HtmlValue, DeveloperName, Subject FROM EmailTemplate WHERE DeveloperName IN :list_TemplateNames]) {
			map_Templates.put(objTemplate.DeveloperName, objTemplate);
		}
		return map_Templates;
	}

	/*
    Alex: Takes in a list of email addresses and returns a map
    of parent cases keyed by their emails
    */
	public static Map<String, Case> getDuplicatePrivacyRequests(List<String> list_EmailAddresses) {
		if (map_EmailsAndParentCase == null) {
			map_EmailsAndParentCase = new Map<String, Case>();
			List<Case> list_ParentCase = [
				SELECT Id, IsClosed, Status, Privacy_Requester_Email__c
				FROM Case
				WHERE Privacy_Requester_Email__c IN :list_EmailAddresses AND ParentId = NULL AND RecordType.Name = 'Privacy Request' AND IsClosed = FALSE
				ORDER BY CreatedDate ASC
				LIMIT 1
			];
			Map<String, Case> map_EmailAndParentCases = new Map<String, Case>();

			//put the queried cases in a map keyed by their emails
			for (Case prCase : list_ParentCase) {
				map_EmailAndParentCases.put(prCase.Privacy_Requester_Email__c, prCase);
			}

			//go through email inputs and find the parent case and
			//put the email and id in the map. If no case is found, put a blank string instead of an id
			for (String str_Email : list_EmailAddresses) {
				if (map_EmailAndParentCases.get(str_Email) == null) {
					map_EmailsAndParentCase.put(str_Email, null);
				} else
					map_EmailsAndParentCase.put(str_Email, map_EmailAndParentCases.get(str_Email));
			}
		}

		return map_EmailsAndParentCase;
	}

	/*
    Alex: get Data Collection objects for privacy request
    returns a list of privacy request ids that do not have
    data collection records
    */
	public static List<Id> getPrivacyRequestsApprovedForDisclosure(List<Id> list_PrivacyRequests) {
		if (list_PrivacyRequestApprovedForDisclosure == null) {
			list_PrivacyRequestApprovedForDisclosure = queryPrivacyRequestsApprovedForDisclosure(list_PrivacyRequests);
		}

		return list_PrivacyRequestApprovedForDisclosure;
	}

	public static List<Id> queryPrivacyRequestsApprovedForDisclosure(List<Id> list_PrivacyRequests) {
		List<Id> list_PrivacyRequestIds = new List<Id>();
		List<Case> privacyRequestsApproved = [SELECT Id FROM Case WHERE ID IN :list_PrivacyRequests AND ID NOT IN (SELECT Case__c FROM Data_Collection__c)];

		for (Case c : privacyRequestsApproved) {
			list_PrivacyRequestIds.add(c.Id);
		}
		return list_PrivacyRequestIds;
	}

	/*
    Author: Alex 
    get Data Collection objects for privacy request
    */
	public static List<Data_Collection__c> getDataCollection(List<Id> list_PrivacyRequests) {
		if (list_DataCollections == null) {
			list_DataCollections = queryDataCollection(list_PrivacyRequests);
		}

		return list_DataCollections;
	}

	public static List<Data_Collection__c> queryDataCollection(List<Id> list_PrivacyRequests) {
		List<Data_Collection__c> list_DataCollectionFromCase = [SELECT Id, Status__c FROM Data_Collection__c WHERE Case__c IN :list_PrivacyRequests];

		return list_DataCollectionFromCase;
	}

	public static List<Contact> getContactbyZPUserId(Set<String> userId) {
		if (list_ofZpUserContacts == null) {
			list_ofZpUserContacts = queryContactbyZPuserId(userId);
		}
		return list_ofZpUserContacts;
	}

	public static List<Contact> queryContactbyZPuserId(Set<String> userId) {
		list_ofZpUserContacts = new List<Contact>();

		list_ofZpUserContacts = [SELECT id, Email, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :userId];

		return list_ofZpUserContacts;
	}

	/*  -- Author: Gaurav Khare.
        -- Description: Queries extracted from GlobalQueryHelper and added here
                        getListofZpUserRoles()
                        queryZPusersRoles()
                        queryZpUserRolesByCompIdAndUserId()
        -- Jira #:
        -- Date Created: 30-Jan-2020
        -- Modified Date: 30-Jan-2020
    -- */
	public static List<ZP_User_Role__c> getListofZpUserRoles(Set<String> companyId, String roleType) {
		if (list_ofZPUserRoles == null) {
			list_ofZPUserRoles = queryZPusersRoles(companyId, roleType);
		}
		return list_ofZPUserRoles;
	}

	public static List<ZP_User_Role__c> queryZPusersRoles(Set<String> companyId, String roleType) {
		list_ofZPUserRoles = new List<ZP_User_Role__c>();

		list_ofZPUserRoles = [SELECT Id, User_Id__c, Company_Id__c, Type__c, Is_Primary__c FROM ZP_User_Role__c WHERE Company_Id__c IN :companyId AND Type__c LIKE :roleType];

		return list_ofZPUserRoles;
	}

	public static List<ZP_User_Role__c> queryZpUserRolesByCompIdAndUserId(List<String> companyId, List<String> userId) {
		list_ofZPUserRolesByCompIdUsrId = new List<ZP_User_Role__c>();

		list_ofZPUserRolesByCompIdUsrId = [
			SELECT Id, Type__c, Accounting_Firm_Id__c, Company_Id__c, User_Id__c, Is_Primary__c
			FROM ZP_User_Role__c
			WHERE Company_Id__c IN :companyId AND User_Id__c IN :userId AND Deleted_At__c = NULL
		];

		return list_ofZPUserRolesByCompIdUsrId;
	}
	/*  -- Author: David (Dato) Tsamalashvili.
        -- Description: Partner Sales - Care transfer process
        -- Jira #: https://app.asana.com/0/1161024895662406/1165692802148235
        -- Date Created: 17-Mar-2020
    */
	public static List<Contact> getCaseContacts(Set<Id> contactIdSet) {
		if (list_caseRelatedContacts == null) {
			list_caseRelatedContacts = queryCaseContacts(contactIdSet);
		}
		return list_caseRelatedContacts;
	}

	public static List<Contact> queryCaseContacts(Set<Id> contactIdSet) {
		List<Contact> list_cseConts = new List<Contact>();

		for (Contact con : [
			SELECT Id, Small_Biz_Engagement__c, AccountId, Account.RecordTypeId, Account.Sold_By__c, Account.Referred_By__c, Account.Sold_By__r.OwnerId, Account.Referred_By__r.OwnerId, Account.OwnerId
			FROM Contact
			WHERE Id IN :contactIdSet
		]) {
			list_cseConts.add(con);
		}

		return list_cseConts;
	}

	/*
	Description: Query the specific case reason
	Author: Elavarasan N
	*/
	public static List<Case_Reason_Classification__c> queryCaseReason(String strCaseReasonName) {
		if (list_CaseReasons == null) {
			list_CaseReasons = new List<Case_Reason_Classification__c>(
				[
					SELECT Id, Name, Type__c
					FROM Case_Reason_Classification__c
					WHERE Name = :strCaseReasonName AND Active__c = TRUE
					ORDER BY Name DESC
				]
			);
		}

		return list_CaseReasons;
	}

	public static Map<String, Sub_Case_Reason_Classification__c> getSubCaseReason(List<String> list_SubCaseReason) {
		if (map_SubReason == null) {
			map_SubReason = querySubCaseReason(list_SubCaseReason);
		}
		return map_SubReason;
	}

	public static Map<String, Sub_Case_Reason_Classification__c> querySubCaseReason(List<String> list_SubCaseReason) {
		Map<String, Sub_Case_Reason_Classification__c> map_TempConfirmSubReason = new Map<String, Sub_Case_Reason_Classification__c>();
		for (Sub_Case_Reason_Classification__c confirmSubCaseReason : [
			SELECT Id, Name
			FROM Sub_Case_Reason_Classification__c
			WHERE Name IN :list_SubCaseReason AND Active__c = TRUE
			ORDER BY Name DESC
		]) {
			map_TempConfirmSubReason.put(confirmSubCaseReason.Name, confirmSubCaseReason);
		}

		return map_TempConfirmSubReason;
	}

	/**
	 * By :Prashant
	 * Date Created : 27-05-2020
	 * Asana Ticket:https://app.asana.com/0/1165890935117693/1177148576781777
	 * Desc : Get Lead based on Cases
	 */
	public static List<Lead> getCaseLeadById(set<id> set_leadId) {
		if (list_Caselead == null) {
			list_Caselead = queryCaseLeadById(set_leadId);
		}
		return list_Caselead;
	}

	public static List<Lead> queryCaseLeadById(set<id> set_LeadId) {
		List<Lead> list_leads = new List<Lead>();
		for (Lead objLead : [SELECT Id, Small_Biz_Engagement__c FROM Lead WHERE Id = :set_LeadId]) {
			list_leads.add(objLead);
		}

		return list_leads;
	}
	/**
	 * By :Prashant
	 * Date Created : 25-06-2020
	 * Asana Ticket:https://app.asana.com/0/1165890935117693/1177148576781777
	 * Desc : Get Lead based on Cases
	 */
	public static List<Lead> updateLeadsActivityFields(set<Id> set_leadId) {
		if (list_LeadWithActivityfields == null) {
			list_LeadWithActivityfields = queryLeadsActivityFields(set_leadId);
		}
		return list_LeadWithActivityfields;
	}

	public static List<Lead> queryLeadsActivityFields(set<Id> set_LeadId) {
		List<Lead> list_leads = new List<lead>();
		for (Lead objLead : [SELECT Id, Last_Rep_Activity_Date__c, Last_Lead_Activity_Date__c, Last_Rep_Activity_Date_New__c FROM Lead WHERE id IN :set_LeadId]) {
			list_leads.add(objLead);
		}

		return list_leads;
	}

	/**
	 * Author: Alex
	 * Date: 8/19/2020
	 * Desc: get IVR Routing Logs from list of genesys call ids
	 */
	public static Map<String, IVR_Routing_Log__c> getIVRLogs(List<String> list_GenId) {
		if (map_IVR == null) {
			map_IVR = queryIVRLogs(list_GenId);
		}

		return map_IVR;
	}

	public static Map<String, IVR_Routing_Log__c> queryIVRLogs(List<String> list_GenId) {
		Map<String, IVR_Routing_Log__c> map_Logs = new Map<String, IVR_Routing_Log__c>();
		for (IVR_Routing_Log__c ivr : [
			SELECT Id, CIP_Account__c, Contact__c, CIP_Auth__c, CIP_Auth_Path__c, Skill__c, Source__c, Divrid__c, Lex_Transcript__c, Intent_Group_Code__c, ConversationId__c, InQueue_Queue_Name__c
			FROM IVR_Routing_Log__c
			WHERE ConversationId__c IN :list_GenId
		]) {
			map_Logs.put(ivr.ConversationId__c, ivr);
		}

		return map_Logs;
	}

	/**
	 * Author: Alex
	 * Date: 8/19/2020
	 * Desc: get Contacts from list of phone numbers
	 */
	public static Map<String, Id> getContactsFromPhone(List<String> list_PhoneNums) {
		if (map_ContactsFromPhone == null) {
			map_ContactsFromPhone = queryContactsFromPhone(list_PhoneNums);
		}

		return map_ContactsFromPhone;
	}

	public static Map<String, Id> queryContactsFromPhone(List<String> list_PhoneNums) {
		Map<String, Id> map_contacts = new Map<String, Id>();
		for (Contact c : [
			SELECT Id, Normalized_Phone__c, Normalized_Other_Phone__c, Normalized_Mobile_Phone__c, ZP_Phone__c
			FROM Contact
			WHERE Normalized_Phone__c IN :list_PhoneNums OR Normalized_Other_Phone__c IN :list_PhoneNums OR Normalized_Mobile_Phone__c IN :list_PhoneNums OR ZP_Phone__c IN :list_PhoneNums
		]) {
			if (list_PhoneNums.contains(c.Normalized_Phone__c)) {
				map_contacts.put(c.Normalized_Phone__c, c.Id);
			} else if (list_PhoneNums.contains(c.Normalized_Other_Phone__c)) {
				map_contacts.put(c.Normalized_Other_Phone__c, c.Id);
			} else if (list_PhoneNums.contains(c.Normalized_Mobile_Phone__c)) {
				map_contacts.put(c.Normalized_Mobile_Phone__c, c.Id);
			} else if (list_PhoneNums.contains(c.ZP_Phone__c)) {
				map_contacts.put(c.ZP_Phone__c, c.Id);
			}
		}

		return map_contacts;
	}

	public static List<Case> getMassEmailCases(Set<Id> set_CaseIds) {
		if (list_MassEmailCases == null) {
			list_MassEmailCases = queryMassEmailCases(set_CaseIds);
		}

		return list_MassEmailCases;
	}

	public static List<Case> queryMassEmailCases(Set<Id> set_CaseIds) {
		List<Case> list_MassEmailCasesWithSurvey = new List<Case>();
		for (Case c : [SELECT Id, Routing_Case_Reason_Classification__r.Survey_Eligible__c FROM Case WHERE Id IN :set_CaseIds]) {
			list_MassEmailCasesWithSurvey.add(c);
		}

		return list_MassEmailCasesWithSurvey;
	}

	/**
	 * Author: Alex
	 * Date: 12/7/2020
	 * Desc: get email message from case
	 */
	public static List<EmailMessage> getEmailMessages(Id idCase, Integer intNumberOfEmails) {
		if (list_EmailMessages == null) {
			list_EmailMessages = queryEmailMessages(idCase, intNumberOfEmails);
		}

		return list_EmailMessages;
	}

	public static List<EmailMessage> queryEmailMessages(Id idCase, Integer intNumberOfEmails) {
		if (idCase != null) {
			String strQuery =
				'SELECT Id, Subject, HtmlBody, TextBody, FromName, FromAddress, MessageDate, ToAddress, ThreadIdentifier ' +
				'FROM EmailMessage WHERE ParentId = \'' +
				idCase +
				'\' ORDER BY CreatedDate DESC';

			if (intNumberOfEmails != 0 && intNumberOfEmails != null) {
				strQuery += ' LIMIT ' + String.valueOf(intNumberOfEmails);
			}

			return (List<EmailMessage>) Database.query(strQuery);
		} else {
			return new List<EmailMessage>();
		}
	}

	/**
	 *Author: Midhuna KB
	 *Date: 17/02/2021
	 *Desc: get records from Custom Metadata - Case Merge Exclusion
	 */
	public static List<Case_Merge_Exclusion__mdt> getCaseMergeExclusionMetaData() {
		if (list_CaseMergeExclusionMdt == null)
			list_CaseMergeExclusionMdt = queryCaseMergeExclusionMetaData();

		return list_CaseMergeExclusionMdt;
	}

	public static List<Case_Merge_Exclusion__mdt> queryCaseMergeExclusionMetaData() {
		List<Case_Merge_Exclusion__mdt> list_CaseMergeExclusion = [SELECT Email__c, Is_Active__c, Matching_Criteria__c, Subject__c FROM Case_Merge_Exclusion__mdt WHERE Is_Active__c = TRUE];
		return list_CaseMergeExclusion;
	}

	public static List<Case> querySuppliedEmailDuplicateCases(Set<String> set_SuppliedEmail, Set<String> set_Subject) {
		List<String> list_SupportedOrigins = Label.Supported_Origins.split(',');
		List<String> list_SupportedRecordTypes = Label.Supported_Record_Types.split(',');
		List<Case> list_Cases = [
			SELECT Id, SuppliedEmail, Origin, RecordTypeId, Subject, Status, Skip_Auto_Response__c, Closed_Reason__c, ParentId
			FROM Case
			WHERE
				SuppliedEmail IN :set_SuppliedEmail
				AND Subject IN :set_Subject
				AND Origin IN :list_SupportedOrigins
				AND RecordType.Name IN :list_SupportedRecordTypes
				AND IsClosed = FALSE
				AND Status != 'Solved'
			ORDER BY CreatedDate ASC
		];

		return list_Cases;
	}

	/**
	 * @Author: Lalitha K
	 * @Date: 12/30/2021
	 * @Desc: get Cases that have an existing case based off of Email(cc, to and from), Subject, Origin, and RecordType
	 */
	public static List<Case> getSubjectOpenDuplicateCases(Set<String> set_Subject, String strStatus, Boolean blnIsClosed, Set<String> set_CaseIncomingEmails) {
		List<String> list_SupportedOrigins = Label.Supported_Origins.trim().split(',');
		List<String> list_SupportedRecordTypes = Label.Supported_Record_Types.trim().split(',');
		List<Case> list_ExistingCases = [
			SELECT Id, SuppliedEmail, CCEmailAddress__c, To_Email_Address__c, Origin, RecordTypeId, Subject, Status, Skip_Auto_Response__c, Closed_Reason__c, ParentId
			FROM Case
			WHERE
				Subject IN :set_Subject
				AND Origin IN :list_SupportedOrigins
				AND RecordType.Name IN :list_SupportedRecordTypes
				AND IsClosed = :blnIsClosed
				AND Status != :strStatus
				AND (SuppliedEmail LIKE :set_CaseIncomingEmails
				OR To_Email_Address__c LIKE :set_CaseIncomingEmails
				OR CCEmailAddress__c LIKE :set_CaseIncomingEmails)
			ORDER BY CreatedDate ASC
		];

		return list_ExistingCases;
	}

	/**
	 * @Author: Sanjay Paryani
	 * @Date: 08/15/2022
	 * @Desc: Get Case configuration for case routing for inactive case owners for Tax Res RT.
	 */
	public static Map<String, Inactive_Case_Routing__mdt> getInactiveCaseRoutingMetaDataForTaxRes() {
		if (map_InactiveTaxResCaseRoutingMdtRecords == null) {
			map_InactiveTaxResCaseRoutingMdtRecords = queryInactiveCaseRoutingMetaData(CaseUtils.RECTYPE_NAME_TAXRES);
		}

		return map_InactiveTaxResCaseRoutingMdtRecords;
	}

	/**
	 * @Author: Sanjay Paryani
	 * @Date: 08/15/2022
	 * @Desc: Query for all Case configuration for case routing for inactive case owners based on inputted record type.
	 */
	public static Map<String, Inactive_Case_Routing__mdt> queryInactiveCaseRoutingMetaData(String strRecordType) {
		Map<String, Inactive_Case_Routing__mdt> map_InactiveTaxResCaseRoutingRules = new Map<String, Inactive_Case_Routing__mdt>();

		for (Inactive_Case_Routing__mdt objRoutingRule : [
			SELECT From_Shelved_Reason__c, From_Status__c, Record_Type__c, Target_Owner__c, Target_Status__c
			FROM Inactive_Case_Routing__mdt
			WHERE Is_Active__c = TRUE AND Record_Type__c = :strRecordType
		]) {
			map_InactiveTaxResCaseRoutingRules.put(objRoutingRule.From_Status__c, objRoutingRule);
		}

		return map_InactiveTaxResCaseRoutingRules;
	}

	/**
	 * @Author: Elavarasan N
	 * @Date: 03/07/2023
	 * @Desc: Query the case milestone records
	 */
	public static List<CaseMilestone> queryCaseMileStoneData(Set<Id> set_MileStoneIds) {
		List<CaseMilestone> list_MileStoneRecords = new List<CaseMilestone>();

		if (set_MileStoneIds != null && !set_MileStoneIds.isEmpty()) {
			list_MileStoneRecords = [SELECT Id, CaseId, CompletionDate, IsCompleted, MilestoneTypeId FROM CaseMilestone WHERE ID IN :set_MileStoneIds AND CaseId != NULL];
		}

		return list_MileStoneRecords;
	}

	/**
	 * @Author: Elavarasan N
	 * @Date: 03/07/2023
	 * @Desc: Query the carrier records
	 */
	public static Map<Id, Carrier__c> queryCaseCarrierData(Set<Id> set_CarrierIds) {
		Map<Id, Carrier__c> map_Carrier = new Map<Id, Carrier__c>();

		if (set_CarrierIds != null && !set_CarrierIds.isEmpty()) {
			for (Carrier__c objCarrier : [SELECT Id, Submission_Method__c, Follow_Up_Method__c, Carrier_Id__c FROM Carrier__c WHERE Id IN :set_CarrierIds]) {
				map_Carrier.put(objCarrier.Id, objCarrier);
			}
		}

		return map_Carrier;
	}

	/**
	 * @Author: Elavarasan N
	 * @Date: 03/07/2023
	 * @Desc: Query the carrier records
	 */
	public static Map<String, Id> queryMileStoneTypeData() {
		if (map_MileStoneTypeByName == null) {
			map_MileStoneTypeByName = new Map<String, Id>();
			for (MileStoneType objMileStoneType : [SELECT Id, Name FROM MileStoneType WHERE Name != NULL]) {
				map_MileStoneTypeByName.put(objMileStoneType.Name, objMileStoneType.Id);
			}
		}

		return map_MileStoneTypeByName;
	}
}