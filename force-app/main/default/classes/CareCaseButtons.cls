/**
 * Author: Alex
 * Desc: methods for Care Lightning components
 */
public with sharing class CareCaseButtons {
	public static Set<String> set_AllNestedGroupMemberIds = new Set<String>();
	public static List<GroupMember> list_GroupMembers;

	/**
	 * Desc: query case based on an id
	 */
	@AuraEnabled
	public static Case queryCase(String strId) {
		Id strIdToId = (Id) strId;
		String strSObjectType = strIdToId?.getSObjectType()?.getDescribe()?.getName();
		if (String.isNotBlank(strSObjectType) && strSObjectType.equals('LiveChatTranscript')) {
			strId = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :strId].CaseId;
		}
		Case objCase = [
			SELECT
				Id,
				Subject,
				CaseNumber,
				ContactId,
				AccountId,
				Account.Name,
				OwnerId,
				Origin,
				Status,
				RecordTypeId,
				RecordType.Name,
				Panda_Company_URL__c,
				Account_Company_Id__c,
				Contact_Employee_Id__c,
				Contact_User_Id__c,
				Assigned_by_Play_Mode__c,
				Account.RecordType.Name,
				Account.HI_Active_Benefits__c,
				Agency_Information__c,
				Agency_Information__r.Name,
				Company_URL__c,
				Accounting_Firm_URL__c,
				Channel__c,
				Account_Specialist__c,
				Account.ZP_Company_ID__c,
				Account.ZP_Firm_ID__c,
				Notice_Period__c,
				Show_Create_Follow_Up_Button__c,
				IsClosed
			FROM Case
			WHERE Id = :strId
		];
		return objCase;
	}

	/**
	 * Desc: check user role against custom label of roles allowed to escalate cases
	 */
	@AuraEnabled
	public static Boolean canUserEscalate() {
		String strEscalateRoles = Label.Escalate_Case_Roles;
		List<String> list_EscalateRoles = new List<String>();

		if (strEscalateRoles != '') {
			list_EscalateRoles = strEscalateRoles.split(',');
		}

		User currentUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
		String strUserRole = currentUser.UserRole.Name;
		if (!list_EscalateRoles.isEmpty() && list_EscalateRoles.contains(strUserRole)) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * changed by: Midhuna KB
	 * date: 20-01-2021
	 * desc: method to control the visibility of the "Create Escalation Case" button on the Case header
	 **/
	@AuraEnabled
	public static CaseEsclalationWrapper canUserCreateEscalationCase() {
		CaseEsclalationWrapper objWrapper = new CaseEsclalationWrapper();
		List<Userrole> list_CurrentUserRoles = new List<Userrole>();
		list_CurrentUserRoles = [SELECT Id, Name FROM UserRole WHERE Id = :UserInfo.getUserRoleId()];
		if (!list_CurrentUserRoles.isEmpty()) {
			for (Create_Escalation_Case_Role__mdt objMetadata : [
				SELECT Id, Label, Escalation_Type__c, Escalation_Queue_Name__c
				FROM Create_Escalation_Case_Role__mdt
			]) {
				if (list_CurrentUserRoles[0].Name.containsIgnoreCase(objMetadata.Label)) {
					objWrapper.blnCaseEscalationAccess = true;
					objWrapper.strEscalationType = objMetadata.Escalation_Type__c;
					objWrapper.strEscalationQueueName = objMetadata.Escalation_Queue_Name__c;
					return objWrapper;
				}
			}
		}
		return objWrapper;
	}

	@AuraEnabled
	public static Boolean canUserChangeOwner() {
		List<String> list_Roles = new List<String>();
		String strChangeOwnerRoles = Label.Change_Owner_Roles;
		if (String.isNotBlank(strChangeOwnerRoles)) {
			list_Roles = strChangeOwnerRoles.split(',');
		}

		User currentUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
		String strUserRole = currentUser.UserRole.Name;
		if (!list_Roles.isEmpty() && list_Roles.contains(strUserRole)) {
			return false;
		} else {
			return true;
		}
	}

	/**
	 * @description Check if the user is added to the Social & Executive Escalations Queue
	 * @author      Ankit CS
	 * @param       NA
	 * @return      Boolean
	 **/
	@AuraEnabled
	public static Boolean getSocialEscalationPermission() {
		List<GroupMember> list_GroupMembers = [
			SELECT Id
			FROM GroupMember
			WHERE Group.Name = 'Social & Executive Escalations Queue' AND Group.Type = 'Queue' AND UserOrGroupId = :UserInfo.getUserId()
		];

		return !list_GroupMembers.isEmpty();
	}

	@AuraEnabled
	public static PermissionWrapper getPermissions() {
		try {
			PermissionWrapper objWrapper = new PermissionWrapper();

			objWrapper.blnReroutePerm = canUserEscalate();
			objWrapper.objEscalatePerm = canUserCreateEscalationCase();
			objWrapper.blnChangeOwnerPerm = canUserChangeOwner();
			objWrapper.blnSurveyOverride = setSurveyOverride();
			objWrapper.blnSocialEscalationPermission = getSocialEscalationPermission();
			return objWrapper;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Desc: query for an sobject based on an Id
	 */
	@AuraEnabled
	public static String queryRecord(Id idRec) {
		String strSObjectType = idRec.getSObjectType().getDescribe().getName();
		String strSObjectLabel = idRec.getSObjectType().getDescribe().getLabel();
		String strQuery = 'SELECT Id, Name FROM ' + strSObjectType + ' WHERE Id = \'' + (String) idRec + '\'';
		SObject obj = Database.query(strQuery);

		SObjectWrap wrap = new SObjectWrap();
		wrap.strSObjectName = strSObjectLabel;
		wrap.sobj = obj;
		String strWrap = JSON.serialize(wrap);
		return strWrap;
	}

	/**
	 * get a case from an id
	 */
	@AuraEnabled
	public static Map<String, SObject> queryCaseRefFields(Id strId) {
		Map<String, SObject> map_Case = new Map<String, SObject>();
		if (strId != null) {
			String strQuery = 'SELECT Id, RecordType.Name FROM Case WHERE Id = : strId';
			Case obj = Database.query(strQuery);
			map_Case.put('CaseRec', obj);
			return map_Case;
		}
		return null;
	}

	/**
	 * Desc: query Account from an Id
	 */
	@AuraEnabled
	public static Account queryAccount(String strId) {
		Account objAcct = [
			SELECT
				Id,
				Account.Name,
				Account.Tier__c,
				Account.AM_Tier__c,
				(
					SELECT Id, CaseNumber, Type, Subject
					FROM Cases
					ORDER BY CreatedDate DESC
					LIMIT 2
				),
				(
					SELECT Id, Title, TextPreview, CreatedDate
					FROM AttachedContentNotes
					ORDER BY CreatedDate DESC
					LIMIT 2
				)
			FROM Account
			WHERE Id = :strId
		];
		return objAcct;
	}

	/**
	 * Desc: query a contact from an Id
	 */
	@AuraEnabled
	public static Contact queryContact(String strId) {
		Contact objCont = [
			SELECT Id, Contact.Name, Contact.Email, Contact.Phone
			FROM Contact
			WHERE Id = :strId
		];
		return objCont;
	}

	/**
	 * Desc: set owner of case to current user and set status to in progress
	 */
	@AuraEnabled
	public static void acceptCase(Case objCase) {
		if (objCase.OwnerId != UserInfo.getUserId()) {
			objCase.OwnerId = UserInfo.getUserId();
			objCase.Status = 'In Progress';
			try {
				update objCase;
			} catch (Exception ex) {
				throw new AuraHandledException(ex.getMessage());
			}
		}
	}

	/**
	 * Desc: Skip the Case record. Generate a case skip history record
	 */
	@AuraEnabled
	public static void skipCaseRecord(String strCaseId, String strSkipComment) {
		Case_Skip_History__c objSkip = new Case_Skip_History__c();
		objSkip.Case__c = strCaseId;
		objSkip.User__c = userInfo.getUserId();
		objSkip.Skip_Comment__c = strSkipComment;

		try {
			insert objSkip;
		} catch (exception ex) {
			return;
		}

		Case objCase = new case(id = strCaseId, Assigned_by_Play_Mode__c = false);

		try {
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			Database.update(objCase, dmo);
		} catch (exception ex) {
			return;
		}
	}

	/**
	 * Desc: change the case owner
	 */
	@AuraEnabled
	public static void changeOwner(String strCaseId, String strOwnerId) {
		if (strCaseId != null && strOwnerId != null) {
			Case objCase = new Case(Id = strCaseId, OwnerId = strOwnerId);
			try {
				update objCase;
			} catch (Exception e) {
				throw new AuraHandledException(e.getMessage());
			}
		}
	}

	/**
	 * Desc: update the Case's Account
	 */
	@AuraEnabled
	public static void updateAccount(String strCaseId, String strAccountId) {
		if (strCaseId != null && strAccountId != null) {
			Case objCase = new Case(Id = strCaseId, AccountId = strAccountId);
			update objCase;
		}
	}

	/**
	 * Desc: update the case's contact
	 */
	@AuraEnabled
	public static void updateContact(String strCaseId, String strContactId) {
		if (strCaseId != null && strContactId != null) {
			Case objCase = new Case(Id = strCaseId, ContactId = strContactId);
			update objCase;
		}
	}

	/**
	 * Desc: set the record type on a Case, set to open, and blank our Closed Reason
	 */
	@AuraEnabled
	public static string updateCaseOnUnmerge(String strCaseId, String strRecordTypeName, Boolean blnIsClosed) {
		if (strCaseId != null && strCaseId != '') {
			Case objCase = new Case(id = strCaseId);
			String strReadOnly = strRecordTypeName;
			String strWithoutReadOnly = strReadOnly.SubStringBefore(' - Read Only');
			for (RecordType rt : [SELECT Id, Name, DeveloperName FROM RecordType WHERE sObjectType = 'Case']) {
				if (rt.Name == strWithoutReadOnly) {
					objCase.RecordTypeId = rt.id;
				}
			}

			if (blnIsClosed) {
				if (strWithoutReadOnly == 'Tax Res') {
					objCase.Status = 'Ready for Research';
				} else {
					objCase.Status = 'Open';
				}

				objCase.Closed_Reason__c = '';
			}

			try {
				update objCase;
				return 'Success';
			} catch (Exception ex) {
				return 'Failure';
			}
		}
		return null;
	}

	/**
	 * @description : does the current user have permission to set survey override
	 * @param       : NA
	 * @return      : Boolean
	 */
	@AuraEnabled
	public static Boolean setSurveyOverride() {
		List<String> list_EngPSA = new List<String>{ CaseUtils.SOCIAL_ESCALATION_PERMISSION_SET };
		List<PermissionSetAssignment> list_Assignment = GlobalQueryHelper.getPermSetAssignments(list_EngPSA);
		if (!list_Assignment.isEmpty()) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * @description : set the skip survey flag
	 * @param       : strCaseId- case id
	 * @return      : NA
	 */
	@AuraEnabled
	public static void skipSurvey(String strCaseId) {
		Case objCase = new Case(Id = strCaseId, Skip_Survey__c = true);

		CaseTriggerHelper.skipTrigger = true;
		update objCase;
		CaseTriggerHelper.skipTrigger = false;
	}

	public class SObjectWrap {
		@AuraEnabled
		public string strSObjectName;
		@AuraEnabled
		public SObject sobj;
	}

	/**
	 * @name         : CaseEsclalationWrapper
	 * @author       : Ankit CS
	 * @date         : 05-18-2021
	 * @description  : Wrapper class to return response from canUserCreateEscalationCase
	 * @test classes : CareCaseButtonsTest
	 **/
	public class CaseEsclalationWrapper {
		@AuraEnabled
		public String strEscalationType { get; set; }
		@AuraEnabled
		public String strEscalationQueueName { get; set; }
		@AuraEnabled
		public Boolean blnCaseEscalationAccess { get; set; }
		public CaseEsclalationWrapper() {
			this.strEscalationType = '';
			this.strEscalationQueueName = '';
			this.blnCaseEscalationAccess = false;
		}
	}

	public class PermissionWrapper {
		@AuraEnabled
		public Boolean blnReroutePerm { get; set; }

		@AuraEnabled
		public CaseEsclalationWrapper objEscalatePerm { get; set; }

		@AuraEnabled
		public Boolean blnChangeOwnerPerm { get; set; }

		@AuraEnabled
		public Boolean blnSurveyOverride { get; set; }

		@AuraEnabled
		public Boolean blnSocialEscalationPermission { get; set; }

		public PermissionWrapper() {
			this.blnReroutePerm = false;
			this.objEscalatePerm = new CaseEsclalationWrapper();
			this.blnChangeOwnerPerm = false;
			this.blnSocialEscalationPermission = false;
		}
	}
}