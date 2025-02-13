/**
 * @name             TaxResCreateNewCaseController
 * @author           Pravesh Rana
 * @date             07/17/2021
 * @description      Controller related with "TaxResCreateNewCase" lwc component.
 * @Test class       TaxResCreateNewCaseControllerTest
 * @revisions        Date ------------ Name ------------ Comments
 **/
public with sharing class TaxResCreateNewCaseController {
	public static final String SPECIALIST_FIELD_SET_NAME = 'Tax_Res_Create_New_Case';
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');
	public static final Id RECTYPE_TAXRES = Cache.getRecordTypeId('Case', 'Tax Res');
	public static final String CASE_STATUS_DATACAPTURE_IN_PROGRESS = 'Data Capture in Progress';
	public static final String CASE_STATUS_READY_FOR_DATA_CAPTURE = 'Ready for Data Capture';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : return Case information by populating "CaseDetail" wrapper
	 * @Parm        : String [case id]
	 * @Return      : CaseDetail [instance]
	 **/
	@AuraEnabled(cacheable=true)
	public static CaseDetail getCaseDetails(String idCase) {
		CaseDetail objCaseDetails = new CaseDetail();
		List<Attachment> list_RelatedAttachments = new List<Attachment>();
		Set<Id> set_EmailMessageIds = new Set<Id>();
		Set<Id> set_RelatedObjectIds = new Set<Id>();

		for (Case objParentCase : [SELECT Id, CaseNumber, AccountId, ContactId, Status, (SELECT Id, Name FROM Attachments), (SELECT Id FROM EmailMessages) FROM Case WHERE Id = :idCase]) {
			objCaseDetails.strParentCaseNumber = objParentCase.CaseNumber;
			objCaseDetails.strParentCaseAccountId = objParentCase.AccountId;
			objCaseDetails.strParentCaseContactId = objParentCase.ContactId;
			objCaseDetails.strTaxResQueue = TAXRESDATACAPTURE_QUEUE_ID;
			objCaseDetails.strCaseStatus = CASE_STATUS_READY_FOR_DATA_CAPTURE;

			set_RelatedObjectIds.add(objParentCase.Id);
			list_RelatedAttachments = objParentCase.Attachments;
			if (objParentCase.EmailMessages?.size() > 0) {
				for (EmailMessage objEmailMessage : objParentCase.EmailMessages) {
					set_EmailMessageIds.add(objEmailMessage.Id);
					set_RelatedObjectIds.add(objEmailMessage.Id);
				}
			}
		}

		if (set_EmailMessageIds.size() > 0) {
			for (Attachment objAttachment : [SELECT Id, Name FROM Attachment WHERE ParentId IN :set_EmailMessageIds]) {
				list_RelatedAttachments.add(objAttachment);
			}
		}

		for (Attachment objAttachment : list_RelatedAttachments) {
			CaseAttachmentDetails objCaseAttachment = new CaseAttachmentDetails();
			objCaseAttachment.value = objAttachment.Id;
			objCaseAttachment.label = objAttachment.Name;
			objCaseDetails.list_Attachments.add(objCaseAttachment);
		}

		for (ContentDocumentLink objContentLink : [SELECT Id, ContentDocumentId, ContentDocument.Title, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :set_RelatedObjectIds]) {
			CaseAttachmentDetails objCaseAttachment = new CaseAttachmentDetails();
			objCaseAttachment.value = objContentLink.ContentDocumentId;
			objCaseAttachment.label = objContentLink.ContentDocument.Title;
			objCaseDetails.list_Attachments.add(objCaseAttachment);
		}

		List<String> list_fieldAPINames = new List<String>();
		Schema.FieldSet objFieldSet = Schema.SObjectType.Case.fieldSets.getMap().get(SPECIALIST_FIELD_SET_NAME);
		for (Schema.FieldSetMember objFieldMember : objFieldSet.getFields()) {
			list_fieldAPINames.add(objFieldMember.getFieldPath());
		}
		objCaseDetails.list_APIName = list_fieldAPINames;
		objCaseDetails.strRecordTypeId = RECTYPE_TAXRES;

		return objCaseDetails;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : calls a future method to create attachment record
	 *                  to the case
	 * @Parm        : String [case Id] + String [Attachment Id]
	 * @Return      : void
	 **/
	@AuraEnabled
	public static void updateCaseAttachment(String strCaseId, String strAttachmentId) {
		processAttachments(strCaseId, strAttachmentId);
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : asynchronous method to create Attachment/ContentDocumentLink records
	 * @Parm        : String [case Id] + String [Attachment Id]
	 * @Return      : void
	 **/
	@future
	public static void processAttachments(String strCaseId, String strAttachmentId) {
		if (String.isNotBlank(strCaseId) && String.isNotBlank(strAttachmentId)) {
			List<Attachment> list_Attachment = new List<Attachment>();
			Set<Id> set_attachmentIds = new Set<Id>();
			List<ContentDocumentLink> list_ContentDocumentLink = new List<ContentDocumentLink>();
			for (String idObj : strAttachmentId.split(',')) {
				if (String.isNotBlank(idObj)) {
					if (idObj.startsWith('00P')) {
						set_attachmentIds.add(idObj);
					}

					if (idObj.startsWith('069')) {
						list_ContentDocumentLink.add(new ContentDocumentLink(ContentDocumentId = Id.valueOf(idObj), LinkedEntityId = Id.valueOf(strCaseId)));
					}
				}
			}

			if (set_attachmentIds.size() > 0) {
				for (Attachment objAttachment : [SELECT Id, Body, Name FROM Attachment WHERE Id IN :set_attachmentIds]) {
					Attachment objNewAtt = objAttachment.clone();
					objNewAtt.ParentId = strCaseId;
					list_Attachment.add(objNewAtt);
				}
			}

			if (list_Attachment.size() > 0) {
				insert list_Attachment;
			}

			if (list_ContentDocumentLink.size() > 0) {
				insert list_ContentDocumentLink;
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : wrapper class
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public class CaseDetail {
		@AuraEnabled
		public List<String> list_APIName = new List<String>();
		@AuraEnabled
		public String strRecordTypeId;
		@AuraEnabled
		public String strTaxResQueue;
		@AuraEnabled
		public String strParentCaseAccountId;
		@AuraEnabled
		public String strParentCaseContactId;
		@AuraEnabled
		public String strParentCaseNumber;
		@AuraEnabled
		public List<CaseAttachmentDetails> list_Attachments = new List<CaseAttachmentDetails>();
		@AuraEnabled
		public String strCaseStatus;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : wrapper class
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public class CaseAttachmentDetails {
		@AuraEnabled
		public String value;
		@AuraEnabled
		public String label;
	}
}