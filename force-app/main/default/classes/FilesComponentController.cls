/*************************************************************************************************************
 * @name			FilesComponentController
 * @author			Dhir Kumar
 * @created			16 / 09 / 2020
 * @description		This class captures the all files information of the case record and displays the files records on the Page. *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-09-16		Dhir Kumar		        Initial Development *
 **************************************************************************************************************/

global class FilesComponentController {
	/*********************************************************************************************************
	 * @name			renameFile
	 * @author			Dhir Kumar
	 * @created			16 / 09 / 2020
	 * @description		This method renames the file or the attachment name
	 **********************************************************************************************************/
	@AuraEnabled
	public static Boolean renameFile(String strNewName, Id idDoc, boolean blnIsfileAttach) {
		try {
			// checking whethere the selected file is ContentDocument or Attachment
			if (blnIsfileAttach) {
				Attachment obj_Att = new Attachment(id = idDoc);
				obj_Att.Name = strNewName;
				update obj_Att;
			} else {
				ContentDocument Obj_ContDoc = new ContentDocument(id = idDoc);
				Obj_ContDoc.Title = strNewName;
				update Obj_ContDoc;
			}
			return true;
		} catch (exception ex) {
			ExceptionLogUtil.logException('FilesComponentController', 'renameFile', ex.getMessage(), ex.getStackTraceString());
		}
		return false;
	}
	/*********************************************************************************************************
	 * @name			returnFilesList
	 * @author			Dhir Kumar
	 * @created			16 / 09 / 2020
	 * @description		This method return all the files and attachment record related to a case.
	 **********************************************************************************************************/
	@AuraEnabled
	public static WrapperAttachment returnFilesList(Id IdCaseRecord, boolean checksize) {
		WrapperAttachment objWrapperResponse;
		Map<String, Object> Map_Response = new Map<String, Object>();
		try {
			// Check whether SObject Type is Case or LiveChatTranscript
			// Case actions component can be placed either on LiveChatTranscript or Case Record Page
			String strSObjectType = IdCaseRecord.getSObjectType().getDescribe().getName();
			// If SObject Type is LiveChatTranscript, fetch Parent Case Id and override the parameter value
			if (strSObjectType.equals('LiveChatTranscript')) {
				// SOQL #1
				IdCaseRecord = [SELECT Id, CaseId FROM LiveChatTranscript WHERE Id = :IdCaseRecord].CaseId;
			}

			Set<id> set_ContentDocumentIds = new Set<id>();
			map<id, AttachmentWrapper> map_AttachmentWrapperMap = new Map<id, AttachmentWrapper>();
			AttachmentWrapper Obj_AttachmentWrapper;

			String StrInstance = System.URL.getSalesforceBaseUrl().toExternalForm();

			String strQueryCaseString =
				'SELECT id,' +
				' (SELECT FileExtension, ContentSize, Title, SharingOption, Id, ParentId, LastModifiedDate FROM CombinedAttachments) ' +
				' FROM Case WHERE id = : IdCaseRecord';
			String strQueryEmailMessageStr =
				'SELECT Id, hasattachment, (SELECT Id, Name, ContentType, BodyLength, lastModifiedDate,Description, IsPrivate FROM Attachments), ' +
				' (SELECT FileExtension, ContentSize, Title, SharingOption, Id, ParentId, LastModifiedDate FROM CombinedAttachments)' +
				' FROM EmailMessage WHERE ParentId = : IdCaseRecord and hasattachment = true';

			for (Case c : database.query(strQueryCaseString)) {
				if (c.combinedattachments != null && c.combinedattachments.size() > 0) {
					for (combinedattachment cAtt : c.combinedattachments) {
						if (checksize) {
							if (cAtt.ContentSize > 10240) {
								Obj_AttachmentWrapper = new AttachmentWrapper(cAtt.ContentSize, cAtt.Id, cAtt.Title, cAtt.LastModifiedDate, cAtt.FileExtension, StrInstance);
								if (!map_AttachmentWrapperMap.containsKey(cAtt.Id)) {
									map_AttachmentWrapperMap.put(cAtt.Id, Obj_AttachmentWrapper);
									set_ContentDocumentIds.add(cAtt.Id);
								}
							}
						} else {
							Obj_AttachmentWrapper = new AttachmentWrapper(cAtt.ContentSize, cAtt.Id, cAtt.Title, cAtt.LastModifiedDate, cAtt.FileExtension, StrInstance);
							if (!map_AttachmentWrapperMap.containsKey(cAtt.Id)) {
								map_AttachmentWrapperMap.put(cAtt.Id, Obj_AttachmentWrapper);
								set_ContentDocumentIds.add(cAtt.Id);
							}
						}
					}
				}
			}

			for (EmailMessage em : database.query(strQueryEmailMessageStr)) {
				if (em.Attachments != null && em.Attachments.size() > 0 && em.hasattachment) {
					for (Attachment att : em.Attachments) {
						if (checksize) {
							if (att.BodyLength > 10240) {
								Obj_AttachmentWrapper = new AttachmentWrapper(
									att.BodyLength,
									att.Id,
									att.Name,
									att.LastModifiedDate,
									att.ContentType,
									StrInstance + '/servlet/servlet.FileDownload?file=' + att.Id
								);
								if (!map_AttachmentWrapperMap.containsKey(att.Id)) {
									map_AttachmentWrapperMap.put(att.Id, Obj_AttachmentWrapper);
								}
							}
						} else {
							Obj_AttachmentWrapper = new AttachmentWrapper(
								att.BodyLength,
								att.Id,
								att.Name,
								att.LastModifiedDate,
								att.ContentType,
								StrInstance + '/servlet/servlet.FileDownload?file=' + att.Id
							);
							if (!map_AttachmentWrapperMap.containsKey(att.Id)) {
								map_AttachmentWrapperMap.put(att.Id, Obj_AttachmentWrapper);
							}
						}
					}
				}
				if (em.combinedattachments != null && em.combinedattachments.size() > 0 && em.hasattachment) {
					for (combinedattachment cat : em.combinedattachments) {
						if (checksize) {
							if (cat.ContentSize > 10240) {
								Obj_AttachmentWrapper = new AttachmentWrapper(cat.ContentSize, cat.Id, cat.Title, cat.LastModifiedDate, cat.FileExtension, StrInstance);
								if (!map_AttachmentWrapperMap.containsKey(cat.Id)) {
									map_AttachmentWrapperMap.put(cat.Id, Obj_AttachmentWrapper);
									set_ContentDocumentIds.add(cat.Id);
								}
							}
						} else {
							Obj_AttachmentWrapper = new AttachmentWrapper(cat.ContentSize, cat.Id, cat.Title, cat.LastModifiedDate, cat.FileExtension, StrInstance);
							if (!map_AttachmentWrapperMap.containsKey(cat.Id)) {
								map_AttachmentWrapperMap.put(cat.Id, Obj_AttachmentWrapper);
								set_ContentDocumentIds.add(cat.Id);
							}
						}
					}
				}
			}
			if (map_AttachmentWrapperMap.size() > 0) {
				Map_Response.put('attachments', map_AttachmentWrapperMap.values());
				Map_Response.put('StrInstance', StrInstance);
				objWrapperResponse = new WrapperAttachment(Map_Response, true, 'Success ');
				objWrapperResponse.idCase = IdCaseRecord;
			} else {
				objWrapperResponse = new WrapperAttachment(null, false, 'No Record Found');
				objWrapperResponse.idCase = IdCaseRecord;
			}
		} catch (Exception ex) {
			objWrapperResponse = new WrapperAttachment(null, false, ex.getMessage());
		}
		return objWrapperResponse;
	}
	/*********************************************************************************************************
	 * @name			AttachmentWrapper
	 * @author			Dhir Kumar
	 * @created			16 / 09 / 2020
	 * @description		This wrapper captures the value of the files and attachment record from multiple objects
	 **********************************************************************************************************/
	public class AttachmentWrapper {
		@AuraEnabled
		public Integer fileSize;

		@AuraEnabled
		public Id id;

		@AuraEnabled
		public String name;

		@AuraEnabled
		public DateTime lastModifiedDate;

		@AuraEnabled
		public String fileType;

		@AuraEnabled
		public boolean fileAttachmentType;

		@AuraEnabled
		public String fileUrl;

		@AuraEnabled
		public String contentType;

		@AuraEnabled
		public Blob attachmentBody;

		@AuraEnabled
		public Attachment objAttachment;

		@AuraEnabled
		public String strEncodedString;

		@AuraEnabled
		public Boolean blnIsSuccess;

		@AuraEnabled
		public String strMessage;

		public AttachmentWrapper(Integer fileSize, Id Id, String Name, DateTime LastModifiedDate, String fileType, String fileUrl) {
			this.fileSize = fileSize;
			this.id = Id;
			this.name = Name;
			this.lastModifiedDate = LastModifiedDate;
			this.fileType = fileType;
			this.fileAttachmentType = false;
			this.fileUrl = fileUrl;
			this.contentType = fileType;
		}

		public AttachmentWrapper(Attachment objAttachment, String strEncodedString, Boolean blnIsSuccess, String strMessage) {
			this.objAttachment = objAttachment;
			this.strEncodedString = strEncodedString;
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
		}
	}

	public class WrapperAttachment {
		@AuraEnabled
		public map<String, Object> map_ResponseData;

		@AuraEnabled
		public Boolean blnIsSuccess;

		@AuraEnabled
		public string strMessage;

		@AuraEnabled
		public Id idCase;

		public WrapperAttachment(Map<String, Object> map_ResponseData, Boolean blnIsSuccess, String Map_ResponseMessage) {
			this.map_ResponseData = map_ResponseData;
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = Map_ResponseMessage;
		}
	}

	/*********************************************************************************************************
	 * @name			getAttachmentRecord
	 * @author			Dhir Kumar
	 * @created			16 / 09 / 2020
	 * @description		This method return the selected attachment record
	 **********************************************************************************************************/
	@AuraEnabled
	public static AttachmentWrapper getAttachmentRecord(String attId) {
		try {
			Attachment objAttachment = [SELECT Id, Name, Description, BodyLength, Body, ContentType FROM Attachment WHERE id = :attId];
			return new AttachmentWrapper(objAttachment, EncodingUtil.base64Encode(objAttachment.Body), true, null);
		} catch (exception objException) {
			return new AttachmentWrapper(null, null, false, objException.getMessage());
		}
	}
}