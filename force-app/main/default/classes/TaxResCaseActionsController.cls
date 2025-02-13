/**
 * @name         TaxResCaseActionsController
 * @author       Pravesh Rana
 * @date         07/04/2021
 * @description
 * @test class   TaxResCaseActionsControllerTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public with sharing class TaxResCaseActionsController {
	static final String SPECIALIST_FIELD_SET_NAME = 'Tax_Res_Specialist_Solve_Case_Fields';
	static final String CASE_UPDATABLE_FIELD_SET_NAME = 'Tax_Res_Case_Editable';
	static final Id LOGGED_IN_USER_ID = UserInfo.getUserId();
	static final String TAX_RES_ACCOUNT_SPECIALIST = 'Account Specialist';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Tax Res "Solve Case" functionality. returns EmailTemplate record based
	 *                  on DeveloperName provided as a parameter
	 * @Parm        : string [Email Template Developer name]
	 * @Return      : Object [Email Template object instance]
	 **/
	@AuraEnabled
	public static EmailTemplate getEmailTemplateBody(String strEmailUniqueName) {
		try {
			if (String.isNotBlank(strEmailUniqueName)) {
				List<EmailTemplate> list_objEmailTemplates = [SELECT Id, HtmlValue, Name FROM EmailTemplate WHERE DeveloperName = :strEmailUniqueName LIMIT 1];
				if (list_objEmailTemplates.size() > 0) {
					return list_objEmailTemplates[0];
				}
			}
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}

		return null;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Tax Res "Solve Case" functionality. Return list of field api names
	 *                  needed to be displayed for the "Solved Case" functionality
	 * @Parm        : NA
	 * @Return      : List of field api names
	 **/
	@AuraEnabled(cacheable=true)
	public static List<String> getSolveCaseFields() {
		List<String> list_FieldAPINames = new List<String>();
		Schema.FieldSet objFieldSet = Schema.SObjectType.Case.fieldSets.getMap().get(SPECIALIST_FIELD_SET_NAME);

		for (Schema.FieldSetMember objFieldMember : objFieldSet.getFields()) {
			list_FieldAPINames.add(objFieldMember.getFieldPath());
		}

		return list_FieldAPINames;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Tax Res "Update Case" functionality. For a case returns
	 *                  Updated fields api name list from the "field set" based on logged in user role
	 * @Parm        : String case Id
	 * @Return      : List of field api names
	 **/
	@AuraEnabled(cacheable=true)
	public static List<String> getUpdatableCaseFields(String strCaseId) {
		String strFieldSetName = CASE_UPDATABLE_FIELD_SET_NAME;
		List<String> list_FieldAPINames = new List<String>();

		Schema.FieldSet objFieldSet = Schema.SObjectType.Case.fieldSets.getMap().get(strFieldSetName);
		for (Schema.FieldSetMember objFieldMember : objFieldSet.getFields()) {
			if (objFieldMember.getFieldPath() != 'CaseNumber') {
				list_FieldAPINames.add(objFieldMember.getFieldPath());
			}
		}

		return list_FieldAPINames;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : this method is called when a user moves between tabs.
	 *                  Methods gets case Id that are in focus of the user
	 *                  and set the "Email Status" field value of the case.
	 * @Parm        : case id
	 * @Return      : String
	 **/
	@AuraEnabled
	public static String handleFocusedCaseEmailStatus(String strFocusedCaseId) {
		String strMessage = '';
		try {
			Set<String> set_CaseStatuses = new Set<String>{ CaseUtils.CASE_STATUS_SHELVED, CaseUtils.CASE_STATUS_READY_FOR_RESEARCH };
			List<Case> list_ToUpdateCases = new List<Case>();
			List<Case> list_Cases = [
				SELECT Id, Email_Status__c, Status, RecordTypeId, OwnerId, Account_Specialist__c, Follow_Up_Date__c
				FROM Case
				WHERE Id = :strFocusedCaseId AND Status IN :set_CaseStatuses AND RecordTypeId = :CaseUtils.RECTYPE_TAXRES AND OwnerId = :LOGGED_IN_USER_ID
				LIMIT 1
			];

			if (list_Cases?.size() > 0) {
				Case objCase = list_Cases[0];
				if (objCase.Status == CaseUtils.CASE_STATUS_READY_FOR_RESEARCH || (objCase.Status == CaseUtils.CASE_STATUS_SHELVED && objCase.Follow_Up_Date__c <= Date.today())) {
					//Validate Owner id and Logged In User id are same and they are active with AS role
					List<User_Role__c> list_ObjUserRoles = [
						SELECT Id, User__c
						FROM User_Role__c
						WHERE User__c = :LOGGED_IN_USER_ID AND User_Skill_Team__c = :TAX_RES_ACCOUNT_SPECIALIST AND User__r.IsActive = TRUE AND User__r.Out_Of_Office__c = FALSE
						LIMIT 1
					];

					if (list_ObjUserRoles?.size() > 0) {
						objCase.Status = CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS;
						objCase.Shelved_Reason__c = null;
						list_ToUpdateCases.add(objCase);
					} else {
						strMessage = 'Invalid Account Specialist';
					}
				} else {
					strMessage = 'Invalid case';
				}
			}

			if (list_ToUpdateCases.size() > 0) {
				CaseTriggerHelper.skipTrigger = true;
				update list_ToUpdateCases;
				strMessage = 'success';
				CaseTriggerHelper.skipTrigger = false;

				CaseTriggerHelper.createTaxResAuditLogs(list_ToUpdateCases, CaseUtils.STATUS_CHANGE, false, true);
			}
		} catch (Exception objException) {
			strMessage = objException.getMessage();
		}

		return strMessage;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : this method is called when a user moves between tabs.
	 *                  Methods gets list of case Ids that are not in focus of the user
	 *                  and set the "Email Status" field value of all the nfocused cases
	 * @Parm        : list of Case Ids
	 * @Return      : String
	 **/
	@AuraEnabled
	public static String handleUnFocusedCaseEmailStatus(List<String> list_StrNonFocusedCaseIds) {
		Map<String, Case_Audit_Log__c> map_CaseIdObjPreviousCaseAuditLogRecord = new Map<String, Case_Audit_Log__c>();
		List<Case> list_ToUpdateCases = new List<Case>();
		Set<String> set_ToExcludeCaseStatus = new Set<String>{ 'Solved', 'Closed' };
		set_ToExcludeCaseStatus.add(CaseUtils.EMAILSTATUS_IN_PROGRESS);
		String strMessage = '';
		try {
			if (list_StrNonFocusedCaseIds != null) {
				for (Case_Audit_Log__c objCaseAudit : [
					SELECT Id, From_Status__c, Case__c, CreatedDate
					FROM Case_Audit_Log__c
					WHERE To_Status__c = :CaseUtils.EMAILSTATUS_IN_PROGRESS AND Case__c IN :list_StrNonFocusedCaseIds
					ORDER BY CreatedDate DESC
				]) {
					Case_Audit_Log__c objAudit;
					if (map_CaseIdObjPreviousCaseAuditLogRecord.containsKey(objCaseAudit.Case__c)) {
						objAudit = map_CaseIdObjPreviousCaseAuditLogRecord.get(objCaseAudit.Case__c);
						if (objAudit.CreatedDate < objCaseAudit.CreatedDate) {
							objAudit = objCaseAudit;
						}
					} else {
						objAudit = objCaseAudit;
					}

					map_CaseIdObjPreviousCaseAuditLogRecord.put(objCaseAudit.Case__c, objAudit);
				}

				for (Case objCase : [
					SELECT Id, Email_Status__c, Status, RecordTypeId, OwnerId, Account_Specialist__c, Coordinator__c
					FROM Case
					WHERE Status NOT IN :set_ToExcludeCaseStatus AND Id IN :list_StrNonFocusedCaseIds AND RecordTypeId = :CaseUtils.RECTYPE_TAXRES
				]) {
					if (objCase.Email_Status__c == CaseUtils.EMAILSTATUS_IN_PROGRESS) {
						if (map_CaseIdObjPreviousCaseAuditLogRecord.containsKey(objCase.Id) && map_CaseIdObjPreviousCaseAuditLogRecord.get(objCase.Id).From_Status__c != null) {
							objCase.Email_Status__c = map_CaseIdObjPreviousCaseAuditLogRecord.get(objCase.Id).From_Status__c;
						} else {
							objCase.Email_Status__c = CaseUtils.EMAILSTATUS_OPEN;
						}
						list_ToUpdateCases.add(objCase);
					}
				}

				if (list_ToUpdateCases.size() > 0) {
					CaseTriggerHelper.skipTrigger = true;
					update list_ToUpdateCases;
					strMessage = 'success';
					CaseTriggerHelper.skipTrigger = false;

					CaseTriggerHelper.createTaxResAuditLogs(list_ToUpdateCases, CaseUtils.EMAIL_STATUS_CHANGE, false, false);
				}
			}
		} catch (Exception objException) {
			strMessage = objException.getMessage();
		}
		return strMessage;
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : This method is used to get all the files linked to the Case
	 * @Parm        : Case Id
	 * @Return      : Map of ContentDocumentId vs Title
	 **/
	@AuraEnabled
	public static Map<Id, String> getAvailableFiles(String strCaseId) {
		Map<Id, String> map_ContentDocIdvsTitle = new Map<Id, String>();
		Set<Id> set_ParentIds = new Set<Id>();
		set_ParentIds.add(strCaseId);
		for (EmailMessage objEmailMsg : [SELECT Id FROM EmailMessage WHERE ParentId = :strCaseId]) {
			set_ParentIds.add(objEmailMsg.Id);
		}

		for (ContentDocumentLink objLink : [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN :set_ParentIds]) {
			map_ContentDocIdvsTitle.put(objLink.ContentDocumentId, 'ContentDocument='+objLink.ContentDocument.Title);
		}

		for (Attachment objAttachment : [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :set_ParentIds AND Name != NULL]) {
			if(!map_ContentDocIdvsTitle.values().contains('Attachment='+objAttachment.Name))
				map_ContentDocIdvsTitle.put(objAttachment.Id, 'Attachment='+objAttachment.Name);
		}
		
		return map_ContentDocIdvsTitle;
	}
}