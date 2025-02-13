/*
 * @name         TaxResAutoSolveUtil
 * @author       Pravesh Rana
 * @date         08-24-2022
 * @description  This class works as utility for "Taxres Auto Solve" functionality
 * @test classes TaxResAutoSolveUtilTest
 */
public with sharing class TaxResAutoSolveUtil {
	static final String NO_NOTICE_FIELD_SET = 'No_Notice_Case_Updates';
	//Added below for physical mail AutoSolve Packages
	public static final String DUPLICATE_NOTICE_CLOSED_CASE_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'Duplicate Notices Closed Case - Physical Mail';
	public static final String DUPLICATE_NOTICE_INPROGRESS_CASE_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'Duplicate Notices InProgress Case - Physical Mail';
	public static final String BEFORE_GUSTO_SERVICE_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'Before Gusto Service - Physical Mail';
	public static final String AFTER_GUSTO_SERVICE_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'After Gusto Service - Physical Mail';
	public static final String SUI_RATE_AUTO_SOLVE_PACKAGE_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'SUI Rate Auto Solve - Physical Mail';
	public static final String PREVIOUSLY_ANSWERED_IN_PROGRESS_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'Previously Answered InProgress Case - Physical Mail';
	public static final String PREVIOUSLY_ANSWERED_CLOSED_PHYSICAL_MAIL_AUTO_SOLVE_PACKAGE = 'Previously Answered Closed Case - Physical Mail';
	public static final String DUPLICATE_NOTICE_CLOSED_CASE_BED_AUTO_SOLVE_PACKAGE = 'Duplicate Notices Closed Case - BED';
	public static final String DUPLICATE_NOTICE_INPROGRESS_CASE_BED_AUTO_SOLVE_PACKAGE = 'Duplicate Notices InProgress Case - BED';
	public static final String BEFORE_GUSTO_SERVICE_BED_AUTO_SOLVE_PACKAGE = 'Before Gusto Service - BED';
	public static final String AFTER_GUSTO_SERVICE_BED_AUTO_SOLVE_PACKAGE = 'After Gusto Service - BED';
	public static final String SUI_RATE_AUTO_SOLVE_PACKAGE_BED_AUTO_SOLVE_PACKAGE = 'SUI Rate Auto Solve - BED';
	public static final String PREVIOUSLY_ANSWERED_IN_PROGRESS_BED_AUTO_SOLVE_PACKAGE = 'Previously Answered InProgress Case - BED';
	public static final String PREVIOUSLY_ANSWERED_CLOSED_BED_AUTO_SOLVE_PACKAGE = 'Previously Answered Closed Case - BED';
	public static final String BELOW_TOLERANCE_AUTO_SOLVE_PACKAGE = 'Below Tolerance Case';
	public static final String BELOW_TOLERANCE_BED_AUTO_SOLVE_PACKAGE = 'Below Tolerance Case - BED';
	public static final String PI_LATE_DEPOSIT_AUTOSOLVE_PACKAGE = 'P&I Late Deposit/Amendment Notice';
	public static final String PREVIOUSLY_ANSWERED_IN_PROGRESS_PACKAGE = 'Previously Answered InProgress Case';
	public static final String PREVIOUSLY_ANSWERED_CLOSED_PACKAGE = 'Previously Answered Closed Case';
	public static final String DUPLICATE_NOTICE_AUTO_SOLVED_FIRED = 'Duplicate Notice Auto-Solve fired';
	public static final String DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE = 'Duplicate Notices Closed Case';
	public static final String DUPLICATE_NOTICE_INPROGRESS_CASE_AUTO_SOLVE_PACKAGE = 'Duplicate Notices InProgress Case';
	public static final String NO_NOTICE_AUTO_SOLVE_PACKAGE = 'No Notice Attached';
	public static final String BEFORE_GUSTO_SERVICE = 'Before Gusto Service';
	public static final String AFTER_GUSTO_SERVICE = 'After Gusto Service';
	public static final String SUI_RATE_AUTO_SOLVE_PACKAGE = 'SUI Rate Auto Solve';
	public static final String AUTOSOLVE_RELATIVE_RT_NAME = 'Auto-Solve Relative';
	public static final String AUTOSOLVE_ACTIVE_STATUS = 'Active';
	public static final String CUSTOMER_ACTION_REQUIRED = 'No customer actions required';
	public static final String ACTION_TAKEN = 'Update filing requirement (rate/schedule)';
	public static final String DUPLICATE_NOTICE_CLOSED_REASON = 'Merged Duplicate';
	public static final String INDICATOR_YES = 'Y';
	public static final String STR_AUTO_GENERIC_EMAIL_CUSTOM_TEMPLATE = 'Auto_Generic_Email_Custom_Template';
	static final Set<String> set_CaseSwapPackages = new Set<String>{ DUPLICATE_NOTICE_CLOSED_CASE_AUTO_SOLVE_PACKAGE, DUPLICATE_NOTICE_INPROGRESS_CASE_AUTO_SOLVE_PACKAGE };

	public static Case handleFieldSync(Case objCase, Case objToUpdateCase, String strRecordName) {
		if (objCase != null && objCase.Id != null && objToUpdateCase != null && objToUpdateCase.Id != null) {
			String strAgencyName = !objCase.Tax_Notice_Indexs__r.isEmpty() ? objCase.Tax_Notice_Indexs__r[0].Agency_Information__r.Name : objCase.Agency_Information__r.Name;
			String strCustomerName = !objCase.Tax_Notice_Indexs__r.isEmpty() ? objCase.Tax_Notice_Indexs__r[0].Client_Name__r.Name : objCase.Account.Name;
			List<Auto_Solve_Package__c> list_autoSolvePackage = getAutoSolvePackage(strRecordName);

			if (list_autoSolvePackage.size() > 0) {
				Auto_Solve_Package__c objPackage = list_autoSolvePackage[0];
				for (Schema.FieldSetMember objField : getFields(objPackage.Field_Set_Used__c)) {
					if (objField.getFieldPath() == 'Mass_Email_Step__c') {
						objToUpdateCase.Mass_Email_Step__c = objToUpdateCase.Mass_Email_Step__c + ';' + objToUpdateCase.Mass_Email_Step__c;
					}
					objToUpdateCase.put(objField.getFieldPath(), objPackage.get(objField.getFieldPath()));
				}

				if (objPackage.Email_Template__c.contains('[AGENCY]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[AGENCY]', strAgencyName);
				}

				if (objPackage.Email_Template__c.contains('[CUSTOMER_NAME]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[CUSTOMER_NAME]', strCustomerName);
				}

				if (objPackage.Email_Template__c.contains('[CASE_NUMBER]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[CASE_NUMBER]', objCase.CaseNumber);
					if (set_CaseSwapPackages.contains(strRecordName)) {
						objToUpdateCase.Related_Case__c = objCase.Id;
						objToUpdateCase.Closed_Reason__c = DUPLICATE_NOTICE_CLOSED_REASON;
					}
				}

				if (objPackage.Email_Template__c.contains('[LATE_DEPOSIT_AMOUNT]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[LATE_DEPOSIT_AMOUNT]', String.valueOf(objCase.Tax_Notice_Indexs__r[0].Late_Deposit_Amount__c));
				}

				if (objPackage.Email_Template__c.contains('[TOTAL_AMOUNT_DUE]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[TOTAL_AMOUNT_DUE]', String.valueOf(objCase.Tax_Notice_Indexs__r[0].Tax_Notice_Amount_Total__c));
				}

				if (objPackage.Email_Template__c.contains('[DATE_TIME_SOLVED]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[DATE_TIME_SOLVED]', objCase.Solved_Closed_Date_Time__c.format('MMMMM dd, yyyy'));
				}

				if (objPackage.Email_Template__c.contains('[YR_QTR]')) {
					objPackage.Email_Template__c = objPackage.Email_Template__c.replace('[YR_QTR]', objCase.Notice_Period__c);
				}

				objToUpdateCase.Auto_Response_Email_Content__c = objPackage.Email_Template__c;

				if (String.isNotBlank(strRecordName) && !set_CaseSwapPackages.contains(strRecordName)) {
					objToUpdateCase.Customer_Actions_Required__c = CUSTOMER_ACTION_REQUIRED;
					objToUpdateCase.Action_Taken__c = ACTION_TAKEN;
				}
				TaxResNoticeIndexDetailsController.blnIsInactiveAutoSolvePkg = false;
			} else {
				TaxResNoticeIndexDetailsController.blnIsInactiveAutoSolvePkg = true;
			}
		}
		return objToUpdateCase;
	}

	public static List<Auto_Solve_Package__c> getAutoSolvePackage(string strRecordName) {
		return String.isNotBlank(strRecordName)
			? [
					SELECT
						Id,
						OwnerId,
						Name,
						RecordTypeId,
						AutoSolvePackageStatus__c,
						Agency_Information__c,
						Customer_Journey__c,
						Email_Template__c,
						Status__c,
						Tax_Notice_Amount_Total__c,
						Tax_Notice_Date__c,
						Tax_Notice_Form_Number__c,
						Tax_Notice_Numeration__c,
						Tax_Notice_Type__c,
						Root_Cause__c,
						Sub_Root_Cause__c,
						Automation_Message__c,
						Automation_Status__c,
						Target_Status__c,
						SUI_Rate_Form_Numbers__c,
						Trigger_Field__c,
						Field_Set_Used__c,
						Priority__c,
						Mass_Email_Step__c
					FROM Auto_Solve_Package__c
					WHERE RecordType.Name = :AUTOSOLVE_RELATIVE_RT_NAME AND AutoSolvePackageStatus__c = :AUTOSOLVE_ACTIVE_STATUS AND Name = :strRecordName
			  ]
			: new List<Auto_Solve_Package__c>();
	}

	public static List<Schema.FieldSetMember> getFields(string strFieldSetName) {
		return String.isNotBlank(strFieldSetName) ? Schema.SObjectType.Auto_Solve_Package__c.fieldSets.getMap().get(strFieldSetName).getFields() : new List<Schema.FieldSetMember>();
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : fetch queries for duplicate notice
	 * @Return      : dWill Return queries for duplicate notice
	 **/
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> getTNDCQueryConfigurationRecords() {
		try {
			Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_TaxResNoticeConfigDetail = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
			for (Tax_Res_Play_Mode_Configuration__mdt objConfig : [
				SELECT Id, Label, Filter_Value__c, Order_by_records__c, Priority__c
				FROM Tax_Res_Play_Mode_Configuration__mdt
				WHERE Active__c = TRUE AND (Label LIKE 'Duplicate Notice%' OR Label LIKE 'Previously Answered%' OR Label LIKE 'Duplicate Case%')
			]) {
				map_TaxResNoticeConfigDetail.put(objConfig.Label, objConfig);
			}
			return map_TaxResNoticeConfigDetail;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxResAutoSolveUtil', 'getTNDCQueryConfigurationRecords', objException);
			return null;
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   Send the email alerts with attachments
	 * @param         instance of Case
	 */
	@InvocableMethod(label='Send Auto Solve Email' description='send auto solve email alerts to the customer')
	public static void sendAutoSolveEmail(List<Case> list_Cases) {
		List<OrgWideEmailAddress> list_objOrgEmailAddressSupport = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');

		EmailTemplate objEmailTemplate = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = :STR_AUTO_GENERIC_EMAIL_CUSTOM_TEMPLATE];

		Map<Id, Case> map_CaseIdToCase = new Map<Id, Case>();
		Map<String, String> map_CaseIdToPackageName = new Map<String, String>();
		Map<String, Auto_Solve_Package__c> map_AutoSolvePackage = new Map<String, Auto_Solve_Package__c>();
		Set<Id> set_ContentDocParentIds = new Set<Id>();
		Map<Id, Set<Id>> map_ParentToContenDocumentIds = new Map<Id, Set<Id>>();
		Set<Id> set_ContentDocumentIds = new Set<Id>();
		Set<Id> set_AutoSolveFailedCaseIds = new Set<Id>();
		Map<Id, Id> map_ContDocIdToContentVersionIds = new Map<Id, Id>();
		Map<Id, ContentVersion> map_ContentVersions = new Map<Id, ContentVersion>();
		List<Case> list_CasesToUpdate = new List<Case>();
		List<Messaging.SingleEmailMessage> list_Emails = new List<Messaging.SingleEmailMessage>();
		List<Attachment> list_AttachmentsToInsert = new List<Attachment>();
		Map<Id, Id> map_CaseToEmailMessages = new Map<Id, Id>();
		Map<Id, List<String>> map_CaseToAttachments = new Map<Id, List<String>>();
		Map<Id, List<Id>> map_ContactIdCaseIds = new Map<Id, List<Id>>();
		Map<Id, Attachment> map_CaseAttachments = new Map<Id, Attachment>();

		Map<Id, Id> map_EmailMessageIdToCaseId = new Map<Id, Id>();
		Map<Id, Set<Attachment>> map_CaseIdToAttachmentIdsFromEmailMsg = new Map<Id, Set<Attachment>>();
		Map<Id, Set<Attachment>> map_CaseIdToAttachmentIds = new Map<Id, Set<Attachment>>();
		Set<Id> set_CaseIds = new Set<Id>();
		Map<Id, String> map_CaseIdvsFilesToIgnore = new Map<Id, String>();

		//creating map of case Id with related latest Mass Email Step
		for (Case objCase : list_Cases) {
			List<String> list_PackageNames = new List<String>();
			for (String strPackageName : objCase.Mass_Email_Step__c.split(';')) {
				if (String.isNotBlank(strPackageName)) {
					list_PackageNames.add(strPackageName);
				}
			}
			map_CaseIdToPackageName.put(objCase.Id, list_PackageNames.get(list_PackageNames.Size() - 1));
			map_CaseIdToCase.put(objCase.Id, objCase);
		}

		//getting file names which need to be ignored while sending the emails (Files created after IDP Capture Complete)
		for (Case objCase : [
			SELECT Id, (SELECT Id, Attachment_Names__c FROM Tax_Notice_Indexs__r WHERE RecordType.DeveloperName = 'OCR')
			FROM Case
			WHERE Id IN :map_CaseIdToCase.keySet()
			AND Baby_Case_Identifier__c = NULL
		]) {
			String strFileNames = '';
			if (objCase.Tax_Notice_Indexs__r != null) {
				for (Tax_Notice_Index__c objNotice : objCase.Tax_Notice_Indexs__r) {
					if (objNotice.Attachment_Names__c != null && !String.isBlank(objNotice.Attachment_Names__c)) {
						if (String.isBlank(strFileNames)) {
							strFileNames = objNotice.Attachment_Names__c;
						} else {
							strFileNames += ',' + objNotice.Attachment_Names__c;
						}
					}
				}
				if (!String.isBlank(strFileNames)) {
					map_CaseIdvsFilesToIgnore.put(objCase.Id, strFileNames);
				}
			}
		}

		//getting Email Messages from which Cases are created
		for (EmailMessage objEmailMessage : [SELECT Id, ParentId, CreatedDate, Subject, Status FROM EmailMessage WHERE ParentId IN :map_CaseIdToCase.keySet() ORDER BY CreatedDate ASC]) {
			if ((objEmailMessage.CreatedDate).date() == (map_CaseIdToCase.get(objEmailMessage.ParentId).CreatedDate).date() &&
			objEmailMessage.Subject == map_CaseIdToCase.get(objEmailMessage.ParentId).Subject && objEmailMessage.Status == '1') {
				map_EmailMessageIdToCaseId.put(objEmailMessage.Id, objEmailMessage.ParentId);
			}
		}

		//fetching Attachments from first email messages
		if (!map_EmailMessageIdToCaseId.isEmpty()) {
			for (Attachment objAttachment : [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :map_EmailMessageIdToCaseId.keySet()]) {
				Set<Attachment> set_AttachmentIds = new Set<Attachment>();
				if (map_CaseIdToAttachmentIdsFromEmailMsg.get(map_EmailMessageIdToCaseId.get(objAttachment.ParentId)) != null) {
					set_AttachmentIds = map_CaseIdToAttachmentIdsFromEmailMsg.get(map_EmailMessageIdToCaseId.get(objAttachment.ParentId));
				}
				set_AttachmentIds.add(objAttachment);
				map_CaseIdToAttachmentIdsFromEmailMsg.put(map_EmailMessageIdToCaseId.get(objAttachment.ParentId), set_AttachmentIds);
			}
		}

		//getting Auto Solve package to create map of its name to record and set of it's Ids
		for (Auto_Solve_Package__c objAutoSolvePackage : [SELECT Id, Name, Gusto_Is_Addressee_Of_Record__c FROM Auto_Solve_Package__c WHERE Name IN :map_CaseIdToPackageName.Values()]) {
			map_AutoSolvePackage.put(objAutoSolvePackage.Name, objAutoSolvePackage);
			set_ContentDocParentIds.add(objAutoSolvePackage.Id);
		}

		//get the case Ids whose Physical mail is true and Gusto Addressee fo Auto Solve is true
		if (!map_AutoSolvePackage?.isEmpty()) {
			for (Case objCase : list_Cases) {
				set_ContentDocParentIds.add(objCase.Id);
				set_CaseIds.add(objCase.Id);
			}
		}

		//fetching attachments related with cases and Auto Solve Packages and getting their ContentDocumentIds
		if (!set_ContentDocParentIds.isEmpty()) {
			for (ContentDocumentLink objContentDoc : [
				SELECT Id, ContentDocumentId, LinkedEntityId, ContentDocument.FileExtension, ContentDocument.FileType, ContentDocument.Title, ContentDocument.LatestPublishedVersion.VersionData
				FROM ContentDocumentLink
				WHERE LinkedEntityId IN :set_ContentDocParentIds
			]) {
				Set<Id> set_ContentDocIds = new Set<Id>();
				if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objContentDoc.LinkedEntityId)) {
					set_ContentDocIds = map_ParentToContenDocumentIds.get(objContentDoc.LinkedEntityId);
				}

				set_ContentDocIds.add(objContentDoc.ContentDocumentId);
				map_ParentToContenDocumentIds.put(objContentDoc.LinkedEntityId, set_ContentDocIds);

				//Adding AutoSolvePackage's ContentDocumentIDs in the set.
				if (!String.valueof(objContentDoc.LinkedEntityId).startsWith(CaseUtils.CASE_ID_PREFIX)) {
					set_ContentDocumentIds.add(objContentDoc.ContentDocumentId);
				}
			}

			//fetching attachments from attachment object for Case
			for (Attachment objAttachment : [SELECT Id, ParentId, Body, Name, ContentType FROM Attachment WHERE ParentId IN :set_CaseIds AND Name != NULL ORDER BY CreatedDate ASC]) { 
				Set<Attachment> set_AttachmentIds = new Set<Attachment>();

				if (map_CaseIdvsFilesToIgnore.containsKey(objAttachment.ParentId) && map_CaseIdvsFilesToIgnore.get(objAttachment.ParentId) != null && (map_CaseIdvsFilesToIgnore.get(objAttachment.ParentId)).contains(objAttachment.Name)) {
					//Do not add attachment if it contains in FilesToIgnore
				} else {
				if (map_CaseIdToAttachmentIds.get(objAttachment.ParentId) != null) { 
						set_AttachmentIds = map_CaseIdToAttachmentIds.get(objAttachment.ParentId);
					}
					set_AttachmentIds.add(objAttachment);
					map_CaseIdToAttachmentIds.put(objAttachment.ParentId, set_AttachmentIds);
				}
			}
		}

		/* segregate the cases on the basis of the attachment size. If case attachment is greater than 3 then that case
		 * added in the AutoSolveFailed set and other cases aatachment IDs are added in the set_ContentDocumentIds for processing.
		 */
		for (Case objCase : list_Cases) {
			if (map_ParentToContenDocumentIds != null && map_ParentToContenDocumentIds.containsKey(objCase.Id)) {
				if (map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) != null && map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id).size() > 3) {
					set_AutoSolveFailedCaseIds.add(objCase.Id);
				} else if (map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) == null && (map_ParentToContenDocumentIds.containsKey(objCase.Id) || map_CaseIdToAttachmentIds.containsKey(objCase.Id))) {
					if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objCase.Id) && map_ParentToContenDocumentIds?.get(objCase.Id)?.size() > 3) {
						set_AutoSolveFailedCaseIds.add(objCase.Id);
					} else if (!map_CaseIdToAttachmentIds.isEmpty() && map_CaseIdToAttachmentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.get(objCase.Id).size() > 3) {
						set_AutoSolveFailedCaseIds.add(objCase.Id);
					} else if (!map_ParentToContenDocumentIds.isEmpty() && !map_CaseIdToAttachmentIds.isEmpty() && map_ParentToContenDocumentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.containsKey(objCase.Id) &&
					(map_ParentToContenDocumentIds?.get(objCase.Id)?.size() + map_CaseIdToAttachmentIds.get(objCase.Id).size()) > 3) {
						set_AutoSolveFailedCaseIds.add(objCase.Id);
					} else if (!map_ParentToContenDocumentIds.isEmpty() && map_ParentToContenDocumentIds?.get(objCase.Id)?.size() <= 3) {
						set_ContentDocumentIds.addAll(map_ParentToContenDocumentIds.get(objCase.Id));
					}
				}
			}
		}

		//create map of ContentVerion's ContenetDocumentIds with it's Id
		if (!set_ContentDocumentIds.isEmpty()) {
			for (ContentVersion objContentVersion : [SELECT Id, VersionData, Title, FileExtension, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :set_ContentDocumentIds]) {
				map_ContDocIdToContentVersionIds.put(objContentVersion.ContentDocumentId, objContentVersion.Id);
				map_ContentVersions.put(objContentVersion.Id, objContentVersion);
			}
		}

		//processing the cases. If the case present in AutoSolveFailed set then Status and Automation Status of case will update , otherwise AutoSolve process will proceed and email will sent.
		for (Case objCase : list_Cases) {
			if (set_AutoSolveFailedCaseIds.Contains(objCase.Id)) {
				
				// Revert the Case Status and Automation Status
				if (objCase.Status != CaseUtils.CASE_STATUS_READY_FOR_RESEARCH && objCase.Status != CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS) {
					objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE;
					objCase.OwnerId = TaxResNoticeIndexDetailsController.SPECIALIST_QUEUE_ID;
				}
				objCase.Automation_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
				objCase.Tax_Res_Auto_Response_Sent__c = false;

				if (objCase.Automation_Message_Follow_Up__c == null) {
					objCase.Automation_Message_Follow_Up__c = CaseUtils.CASE_AUTO_SOLVE_ERROR_MULTIPLE_ATTACHMENTS;
				} else {
					objCase.Automation_Message_Follow_Up__c = objCase.Automation_Message_Follow_Up__c + ';' + CaseUtils.CASE_AUTO_SOLVE_ERROR_MULTIPLE_ATTACHMENTS;
				}
				list_CasesToUpdate.add(objCase);
			} else {
				Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
				objMail.TemplateId = objEmailTemplate.Id;
				objMail.TargetObjectId = objCase.ContactId;
				objMail.WhatId = objCase.Id;
				objMail.setUseSignature(false);

				if (String.isNotBlank(objCase.ContactEmail)) {
					objMail.setToAddresses(new List<String>{ objCase.ContactEmail });
				}

				if (String.isNotBlank(objCase.SuppliedEmail)) {
					objMail.setCcAddresses(new List<String>{ objCase.SuppliedEmail });
				}

				if (!Test.isRunningTest()) {
					objMail.setOrgWideEmailAddressId(list_objOrgEmailAddressSupport.get(0).Id);
				}

				List<Messaging.EmailFileAttachment> list_attachments = new List<Messaging.EmailFileAttachment>();

				if (!map_CaseIdToAttachmentIdsFromEmailMsg.isEmpty() && map_CaseIdToAttachmentIdsFromEmailMsg.containsKey(objCase.Id) && map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id) != null) { 
					for (Attachment objAttachment : map_CaseIdToAttachmentIdsFromEmailMsg.get(objCase.Id)) {
						Messaging.EmailFileAttachment objFileAttachment = new Messaging.EmailFileAttachment();
						objFileAttachment.setFileName(objAttachment.Name);
						objFileAttachment.setBody(objAttachment.Body);
						objFileAttachment.setContentType(objAttachment.ContentType);
						objFileAttachment.setInline(false);
						list_attachments.add(objFileAttachment);
					}
				} else if (!map_CaseIdToAttachmentIds.isEmpty() && map_CaseIdToAttachmentIds.containsKey(objCase.Id) && map_CaseIdToAttachmentIds.get(objCase.Id) != null) {
					for (Attachment objAttachment : map_CaseIdToAttachmentIds.get(objCase.Id)) {
						Messaging.EmailFileAttachment objFileAttachment = new Messaging.EmailFileAttachment();
						objFileAttachment.setFileName(objAttachment.Name);
						objFileAttachment.setBody(objAttachment.Body);
						objFileAttachment.setContentType(objAttachment.ContentType);
						objFileAttachment.setInline(false);
						list_attachments.add(objFileAttachment);
					}
				}

				if (list_attachments != null && !list_attachments.isEmpty()) {
					objMail.setFileAttachments(list_attachments);
				}

				//Add attachment if the criteria matched and Package and Case have attachments.
				if (!map_ContDocIdToContentVersionIds.isEmpty() && !map_ParentToContenDocumentIds.isEmpty() && 
				(map_ParentToContenDocumentIds?.containsKey(objCase.Id) || map_ParentToContenDocumentIds.containsKey(map_AutoSolvePackage.get(map_CaseIdToPackageName.get(objCase.Id)).Id))) {
					List<String> list_RelContentVerIds = new List<String>();
					Auto_Solve_Package__c objAutoSolvePack = map_AutoSolvePackage.get(map_CaseIdToPackageName.get(objCase.Id));

					if (map_ParentToContenDocumentIds?.containsKey(objAutoSolvePack.Id)) {
						for (Id idContentDoc : map_ParentToContenDocumentIds.get(objAutoSolvePack.Id)) {
							if (map_ContDocIdToContentVersionIds.containsKey(idContentDoc)) {
								list_RelContentVerIds.add(map_ContDocIdToContentVersionIds.get(idContentDoc));
							}
						}
					}

					if (map_ParentToContenDocumentIds?.containsKey(objCase.Id) && !map_CaseIdToAttachmentIdsFromEmailMsg?.containsKey(objCase.Id)) {
						for (Id idContentDoc : map_ParentToContenDocumentIds.get(objCase.Id)) {
							if (map_ContDocIdToContentVersionIds.containsKey(idContentDoc)) {
								list_RelContentVerIds.add(map_ContDocIdToContentVersionIds.get(idContentDoc));
							}
						}
					}

					if (!list_RelContentVerIds.isEmpty()) {
						objMail.setEntityAttachments(list_RelContentVerIds);
						map_CaseToAttachments.put(objCase.Id, list_RelContentVerIds);
					}
				}

				if (String.isNotBlank(objCase.ContactEmail) || String.isNotBlank(objCase.SuppliedEmail)) {
					list_Emails.add(objMail);
				}

				if (map_ContactIdCaseIds.containsKey(objCase.ContactId)) {
					map_ContactIdCaseIds.get(objCase.ContactId).add(objCase.Id);
				} else {
					map_ContactIdCaseIds.put(objCase.ContactId, new List<Id>{ objCase.Id });
				}
			}
		}

		try {
			if (!list_Emails?.isEmpty()) {
				Set<Id> set_FailedCaseId = new Set<Id>();
				Messaging.SendEmailResult[] list_sendEmails = Messaging.sendEmail(list_Emails, false);

				for (Messaging.SendEmailResult objEmail : list_sendEmails) {
					if (!objEmail.isSuccess()) {
						for (Messaging.SendEmailError objError : objEmail.getErrors()) {
							Id idContactId = objError.getTargetObjectId();
							if (map_ContactIdCaseIds.containsKey(idContactId)) {
								set_FailedCaseId.addAll(map_ContactIdCaseIds.get(idContactId));
							}

							if (String.valueOf(objError.getStatusCode()) == 'EMAIL_ADDRESS_BOUNCED') {
								if (idContactId != null && map_ContactIdCaseIds.containsKey(idContactId)) {
									for (Case objCase : list_Cases) {
										if (map_ContactIdCaseIds.get(idContactId).contains(objCase.Id)) {
											if (objCase.Automation_Message_Follow_Up__c == null) {
												objCase.Automation_Message_Follow_Up__c = CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
											} else {
												objCase.Automation_Message_Follow_Up__c = objCase.Automation_Message_Follow_Up__c + '; ' + CaseUtils.EMAIL_ADDRESS_BOUNCED_ERROR_MSG;
											}
										}
									}
								}
							}

							ExceptionLogUtil.logException(
								'TaxResAutoSolveUtil',
								'sendAutoSolveEmail for ' + idContactId,
								objError.getStatusCode() +
								'-' +
								objError.getFields() +
								'-' +
								objError.getMessage(),
								''
							);
						}
					}
				}

				List<Case> list_CasesToRevert = new List<Case>();
				if (!set_FailedCaseId.isEmpty()) {
					for (Case objCase : list_Cases) {
						if (set_FailedCaseId.contains(objCase.Id)) {
							list_CasesToRevert.add(objCase);
						}
					}
				}

				if (Test.isRunningTest() && TaxResAutoSolveUtilTest.blnTestRevertCases) {
					list_CasesToRevert.addAll(list_Cases);
				}

				if (!list_CasesToRevert.isEmpty()) {
					revertCaseRecords(list_CasesToRevert);
				}
			}

			//update the AutoSolve Process failed Cases
			if (!list_CasesToUpdate?.isEmpty()) {
				updateCases(list_CasesToUpdate);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxResAutoSolveUtil', 'sendAutoSolveEmail', objException);
			revertCaseRecords(list_Cases);
		}
	}

	/**
	 * @author        Rushi R
	 * @description   Revert the Case Records in case of failures to send email or Exception
	 * @param         List of Cases to update
	 */
	public static void revertCaseRecords(List<Case> list_Cases) {
		if (list_Cases.isEmpty()) {
			return;
		}

		for (Case objCase : list_Cases) {
			// Revert the Case Status and Automation Status
			if (objCase.Status != CaseUtils.CASE_STATUS_READY_FOR_RESEARCH && objCase.Status != CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS) {
				objCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE;
				objCase.OwnerId = TaxResNoticeIndexDetailsController.SPECIALIST_QUEUE_ID;
			}
			objCase.Automation_Status__c = CaseUtils.STR_IB_FAILED_STATUS;
			objCase.Tax_Res_Auto_Response_Sent__c = false;
		}

		updateCases(list_Cases);
	}

	/**
	 * @author        Rushi R
	 * @description   Update Case records skipping Case and Account triggers
	 * @param         List of Cases to update
	 */
	public static void updateCases(List<Case> list_Cases) {
		if (list_Cases.isEmpty()) {
			return;
		}

		Boolean blnSkipCaseTrigger = CaseTriggerHelper.skipTrigger;
		Boolean blnSkipAcctTrigger = AccountTriggerHelper.skipTrigger;

		CaseTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		update list_Cases;
		CaseTriggerHelper.skipTrigger = blnSkipCaseTrigger;
		AccountTriggerHelper.skipTrigger = blnSkipAcctTrigger;
	}
}