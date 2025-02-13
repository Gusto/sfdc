/*************************************************************************************************************
 * @name			LWC_MergeCaseController
 * @author			Dhir Kumar
 * @created			17 / 09 / 2020
 * @description		This class covers the functionality of the the merging of the case *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-09-17		Dhir Kumar			 Initial Development
 *
 **************************************************************************************************************/
global without sharing class LWC_MergeCaseController {
	/*********************************************************************************************************
	 * @name			returnCaseList
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		This method gets the list of the cases related to the contact of the current case record.
	 *                  Some filters are also involved based upon the search
	 **********************************************************************************************************/
	@AuraEnabled
	public static WrapperResponse returnCaseList(String idCaseRecord, String strCaseNumber, Boolean blnOpenCases) {
		WrapperResponse objWrapperResponse;
		Map<String, Object> map_StringToObjectResponse = new Map<String, Object>();
		List<Case> list_CaseRecords = new List<Case>();
		String strFilter = '';
		String strMasterCaseToMergeContact;
		String strMasterCaseToMergeAccount;
		String strMasterCaseToMergeSuppliedEmail;
		String strMasterCaseToMergeSuppliedPhone;
		try {
			//getting the current case record values
			Case currentCase = [
				SELECT CaseNumber, RecordTypeId, ContactId, AccountId, Account.Name, Status, Priority, Subject, Type, SuppliedEmail, SuppliedPhone, OwnerId, ParentId
				FROM Case
				WHERE id = :idCaseRecord
			];
			if (currentCase.ContactId != null) {
				strMasterCaseToMergeContact = currentCase.ContactId;
			}
			if (blnOpenCases) {
				strFilter = strFilter + ' IsClosed = false ';
			}
			Boolean blnIsCaseNumberPresentToSearch = false;
			if (strCaseNumber != null && strCaseNumber != '') {
				blnIsCaseNumberPresentToSearch = true;
				if (strFilter != '') {
					strFilter = strFilter + ' AND ';
				}
				strFilter = strFilter + ' CaseNumber = \'' + strCaseNumber + '\'';
			}
			String strQuery = '';
			if (currentCase.ContactId != null || strCaseNumber != '') {
				strQuery +=
					'SELECT CaseNumber, RecordTypeId, RecordType.Name, ContactId, AccountId, Account.Name, Contact.Name,' +
					' Status, Priority, Subject, SuppliedEmail, OwnerId, Owner.Name FROM Case ' +
					' WHERE Id != \'' +
					currentCase.Id +
					'\' ';

				String subStr = '';
				if (strFilter != '') {
					strQuery = strQuery + ' AND ' + strFilter;
				}
				if (!blnIsCaseNumberPresentToSearch && strMasterCaseToMergeContact != '') {
					strQuery += ' AND (ContactId = \'' + strMasterCaseToMergeContact + '\')';
				}
				strQuery += ' ORDER BY CreatedDate DESC LIMIT 50';
			}
			
			if (String.isNotBlank(strQuery)) {
				list_CaseRecords = Database.query(strQuery);
			}

			if (!list_CaseRecords.isEmpty()) {
				map_StringToObjectResponse.put('list_CaseRecords', list_CaseRecords);
				map_StringToObjectResponse.put('currentCase', currentCase);
				objWrapperResponse = new WrapperResponse(map_StringToObjectResponse, true, 'Success ');
			} else {
				map_StringToObjectResponse.put('currentCase', currentCase);
				objWrapperResponse = new WrapperResponse(map_StringToObjectResponse, false, 'No Record Found');
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', ex.getMessage(), ex.getStackTraceString());
			objWrapperResponse = new WrapperResponse(null, false, ex.getMessage());
			throw new AuraHandledException(ex.getMessage());
		}

		return objWrapperResponse;
	}
	/*********************************************************************************************************
	 * @name			getSelectedCaseRecord
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		Returns the selected case record.
	 **********************************************************************************************************/
	@AuraEnabled
	public static Case getSelectedCaseRecord(String strCaseNumber) {
		Case objCaseRec;
		try {
			objCaseRec = [SELECT id, CaseNumber, Status FROM Case WHERE CaseNumber = :strCaseNumber];
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', ex.getMessage(), ex.getStackTraceString());
			return null;
		}
		return objCaseRec;
	}

	/*********************************************************************************************************
	 * @name			mergeSeletedCase
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		This method is responsible for merging one case into another
	 *                  with all its related chatter feed and chatter comments
	 *                  along with the attachemts and email messages
	 **********************************************************************************************************/
	@AuraEnabled
	public static WrapperResponse mergeSeletedCase(List<Id> list_CaseIds, Case caseToMerge, List<String> list_CaseNumbers) {
		WrapperResponse wrapperResponseObj;
		EmailMessageTriggerHelper.skipTrigger = true;
		List<Case> list_CaseToCopy = new List<Case>();
		List<Case_Audit_Log__c> list_Logs = new List<Case_Audit_Log__c>();
		List<FeedItem> list_FeedItemParentList = new List<FeedItem>();
		List<FeedItem> list_FeedItemChildList = new List<FeedItem>();

		List<Id> list_CaseToCopyIds = new List<Id>();
		List<ConnectApi.BatchInput> list_BatchInputs = new List<ConnectApi.BatchInput>();

		//BY:PR, Date: 6/12/19, Desc: We are updating the custom setting to skip the "Cant_Change_Read_Only_Case_Status" case validation.
		Case_Merge_Skip_Validation__c obj_SkipValidationRec = Case_Merge_Skip_Validation__c.getOrgDefaults();
		if (obj_SkipValidationRec != null && obj_SkipValidationRec.id != null) {
			obj_SkipValidationRec.Disable_Validation__c = true;
			update obj_SkipValidationRec;
		}

		Savepoint sp = Database.setSavepoint();
		if (list_CaseIds != null && list_CaseIds.size() > 0) {
			//getting the list of email messages related to a case and then will be copying it to the merging parent case.
			list_CaseToCopy = [
				SELECT
					id,
					AccountId,
					ContactId,
					CaseNumber,
					RecordTypeId,
					Subject,
					Description,
					Opportunity__r.Id,
					Origin,
					OwnerId,
					Status,
					Type,
					RecordType.name,
					ParentId,
					Parent.CaseNumber,
					Parent.Status,
					Status_Change_Date_Time__c,
					Complaint_Type__c,
					(
						SELECT
							Id,
							ParentId,
							ActivityId,
							TextBody,
							HtmlBody,
							Headers,
							createdById,
							Subject,
							FromName,
							FromAddress,
							ToAddress,
							CcAddress,
							BccAddress,
							CreatedDate,
							Incoming,
							HasAttachment,
							Status,
							MessageDate,
							IsDeleted,
							ReplyToEmailMessageId,
							LastModifiedById,
							LastModifiedDate
						FROM EmailMessages
						ORDER BY messageDate ASC
					)
				FROM Case
				WHERE Id IN :list_CaseIds
			];

			//Copy Email to Feed Item
			//list of email messages to be inserted as Feed items
			List<FeedComment> list_ToInsertFeedItemList = new List<FeedComment>();
			// map of selected caseids to its case record
			Map<id, Case> map_caseIdToCase = new Map<id, Case>();
			//map of email message and its old parent case id
			Map<Id, Id> map_emailMessageIdToParentCaseId = new Map<Id, Id>();
			//map of old case ID and newly inserted feed items which in actual are the email messages
			Map<Id, Id> map_CaseIdToFeedId = new Map<Id, Id>();
			//map of feed items to its case record id
			//Id of the feed item posted on parent case (caseToMerge)
			Id idParentCaseFeedItem;

			String strUrlInstance = String.valueof(System.URL.getSalesforceBaseURL().gethost());
			String strUrlInstanceFinal = strUrlInstance.removeEndIgnoreCase('.my.salesforce.com');
			if (list_CaseToCopy.size() > 0) {
				FeedItem objFeedItemChild;
				FeedItem objFeedItemParent;
				for (Case caseToCopy : list_CaseToCopy) {
					ConnectApi.FeedItemInput objInput = new ConnectApi.FeedItemInput();
					ConnectApi.MessageBodyInput objInputBody = new ConnectApi.MessageBodyInput();
					objInputBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

					ConnectApi.TextSegmentInput objInputSegment = new ConnectApi.TextSegmentInput();
					objInputSegment.Text = 'This case is merged to ';
					objInputBody.messageSegments.add(objInputSegment);

					//add case link
					ConnectApi.EntityLinkSegmentInput objInputLinkSegment = new ConnectApi.EntityLinkSegmentInput();
					objInputLinkSegment.entityId = caseToMerge.Id;
					objInputBody.messageSegments.add(objInputLinkSegment);

					objInput.body = objInputBody;

					objInput.SubjectId = caseToCopy.Id;
					ConnectApi.BatchInput objBatchInput = new ConnectApi.BatchInput(objInput);
					list_BatchInputs.add(objBatchInput);
					list_CaseToCopyIds.add(caseToCopy.Id);

					ConnectApi.FeedItemInput objInput2 = new ConnectApi.FeedItemInput();
					ConnectApi.MessageBodyInput objInputBody2 = new ConnectApi.MessageBodyInput();
					objInputBody2.messageSegments = new List<ConnectApi.MessageSegmentInput>();

					ConnectApi.TextSegmentInput objInputSegment2 = new ConnectApi.TextSegmentInput();
					objInputSegment2.Text = 'Case ';
					objInputBody2.messageSegments.add(objInputSegment2);

					//add case link
					ConnectApi.EntityLinkSegmentInput objInputLinkSegment2 = new ConnectApi.EntityLinkSegmentInput();
					objInputLinkSegment2.entityId = caseToCopy.Id;
					objInputBody2.messageSegments.add(objInputLinkSegment2);

					objInputSegment2 = new ConnectApi.TextSegmentInput();
					objInputSegment2.Text = ' was merged to this case.';
					objInputBody2.messageSegments.add(objInputSegment2);

					objInput2.body = objInputBody2;
					objInput2.SubjectId = caseToMerge.Id;
					ConnectApi.BatchInput objBatchInput2 = new ConnectApi.BatchInput(objInput2);
					list_BatchInputs.add(objBatchInput2);
				}
				if (list_BatchInputs.size() > 0) {
					//only post when not running tests. Allows test class to use SeeAllData = false
					try {
						if (!Test.isRunningTest()) {
							List<ConnectApi.BatchResult> list_BatchResults = ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), list_BatchInputs);

							for (ConnectApi.BatchResult objBR : list_BatchResults) {
								if (objBR.isSuccess() == true) {
									ConnectAPI.FeedElement objFE = (ConnectAPI.FeedElement) objBR.getResult();
									if (list_CaseToCopyIds.contains(objFE.Parent.Id)) {
										map_CaseIdToFeedId.put(objFE.Parent.Id, objFE.Id);
									} else {
										idParentCaseFeedItem = objFE.Id;
									}
								} else {
									ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', 'ChatterFeeds postFeedElementBatch failure', objBR.getErrorMessage());
								}
							}
						}
					} catch (Exception ex) {
						ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', ex.getMessage(), ex.getStackTraceString());
						throw new AuraHandledException(ex.getMessage());
					}
				}

				// preparing the list of the feed item records to be inserted from the email messages of the selected case

				for (Case caseToCopy : list_CaseToCopy) {
					for (EmailMessage emailToCopy : caseToCopy.EmailMessages) {
						ConnectApi.CommentInput objComment = new ConnectApi.CommentInput();
						ConnectApi.MessageBodyInput objCommentBody = new ConnectApi.MessageBodyInput();
						objCommentBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

						ConnectApi.TextSegmentInput objCommentSegment = new ConnectApi.TextSegmentInput();
						objCommentSegment.Text = 'Email copied from merged case: ';
						objCommentBody.messageSegments.add(objCommentSegment);

						//add case link
						ConnectApi.EntityLinkSegmentInput objCommentLinkSegment = new ConnectApi.EntityLinkSegmentInput();
						objCommentLinkSegment.entityId = caseToCopy.Id;
						objCommentBody.messageSegments.add(objCommentLinkSegment);

						//start email information
						ConnectApi.TextSegmentInput objCommentSegmentTextEmailInfo = new ConnectApi.TextSegmentInput();
						objCommentSegmentTextEmailInfo.Text = ' \r\n From Email: ' + emailToCopy.FromAddress + ' \r\n ';
						objCommentSegmentTextEmailInfo.Text += 'To Email: ' + emailToCopy.ToAddress + ' \r\n ';

						if (emailToCopy.TextBody != null && emailToCopy.TextBody.length() > 9500) {
							objCommentSegmentTextEmailInfo.Text += emailToCopy.TextBody.substring(0, 9500);
						} else {
							objCommentSegmentTextEmailInfo.Text += emailToCopy.TextBody;
						}

						objCommentSegmentTextEmailInfo.Text += ' \r\n ' + 'Link of the email message: ';

						objCommentBody.messageSegments.add(objCommentSegmentTextEmailInfo);

						//add email link
						ConnectApi.EntityLinkSegmentInput objEmailLink = new ConnectApi.EntityLinkSegmentInput();
						objEmailLink.entityId = emailToCopy.Id;
						objCommentBody.messageSegments.add(objEmailLink);

						objComment.body = objCommentBody;
						map_emailMessageIdToParentCaseId.put(emailToCopy.id, caseToCopy.id);

						if (!Test.isRunningTest()) {
							ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), idParentCaseFeedItem, objComment, null);
						}
					}
					map_caseIdToCase.put(caseToCopy.id, caseToCopy);
				}
				if (map_emailMessageIdToParentCaseId.size() > 0) {
					moveAttachmentAsFeed(map_emailMessageIdToParentCaseId, map_caseIdToCase, idParentCaseFeedItem);
				}
			}
			//Create feed for email Attachments
			// Insert FeedItem related to Case
			copyFeeds(list_CaseIds, idParentCaseFeedItem);

			if (list_CaseToCopy.size() > 0) {
				List<BusinessHours> list_BizHours = new List<BusinessHours>();

				for (BusinessHours objBh : GlobalQueryHelper.getAllBusinessHoursList()) {
					if (objBh.Name == 'Gusto - Denver - Engagement') {
						list_BizHours.add(objBh);
					}
				}

				for (Case caseToCopy : list_CaseToCopy) {
					String strOwnerId = caseToCopy.OwnerId;

					if (caseToCopy.Status != 'Closed') {
						//create case audit log for closing the case
						Case_Audit_Log__c objLog = new Case_Audit_Log__c();
						objLog.Case__c = caseToCopy.Id;
						objLog.Event_Type__c = 'Status Change';
						objLog.From_Status__c = caseToCopy.Status;
						objLog.To_Status__c = 'Closed';
						objLog.From_Date_Time__c = caseToCopy.Status_Change_Date_Time__c;
						objLog.To_Date_Time__c = System.now();

						if (strOwnerId.startsWith('005')) {
							objLog.Advocate__c = caseToCopy.OwnerId;
						}

						if (list_BizHours.size() > 0) {
							objLog.Business_Hours__c = list_BizHours[0].Id;
							Id idHours = objLog.Business_Hours__c;
							DateTime dtmFromTime = objLog.From_Date_Time__c;
							DateTime dtmToTime = objLog.To_Date_Time__c;
							if (dtmFromTime != null) {
								Long lngMS = BusinessHours.diff(idHours, dtmFromTime, dtmToTime);
								objLog.Duration_in_seconds__c = lngMS / 1000;
							}
						}

						list_Logs.add(objLog);

						if (caseToCopy.RecordType.Name == CaseUtils.TYPE_MODERN_BANK && String.isBlank(caseToCopy.Complaint_Type__c)) {
							caseToCopy.Complaint_Type__c = 'No Complaint';
						}

						caseToCopy.Status = 'Closed';
						caseToCopy.Skip_Survey__c = true;
						caseToCopy.Closed_Reason__c = 'Merged Duplicate';
						caseToCopy.Status_Change_Date_Time__c = System.now();
					}

					if (caseToCopy.ParentId == null) {
						caseToCopy.ParentId = caseToMerge.Id;
					}

					if (strOwnerId.startsWith('00G')) {
						caseToCopy.OwnerId = UserInfo.getUserId();
					}
				}
			}
			try {
				CaseTriggerHelper.skipTrigger = true;
				CaseAuditLogTriggerHelper.skipTrigger = true;
				update list_CaseToCopy;

				if (!list_Logs.isEmpty()) {
					insert list_Logs;
				}

				CaseTriggerHelper.skipTrigger = false;
				CaseAuditLogTriggerHelper.skipTrigger = false;

				if (list_FeedItemChildList.size() > 0) {
					insert list_FeedItemChildList;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', ex.getMessage(), ex.getStackTraceString());
				throw new AuraHandledException(ex.getMessage());
			}

			//BY:PR, Date: 6/12/19, Desc: We are updating the custom setting to skip the "Cant_Change_Read_Only_Case_Status" case validation.
			if (obj_SkipValidationRec != null && obj_SkipValidationRec.id != null) {
				obj_SkipValidationRec.Disable_Validation__c = false;
				update obj_SkipValidationRec;
			}

			wrapperResponseObj = new WrapperResponse(
				null,
				true,
				'Case ' +
					String.join(list_CaseNumbers, ', ') +
					' is successfully merged with ' +
					caseToMerge.CaseNumber +
					'. The status of case ' +
					String.join(list_CaseNumbers, ', ') +
					' is updated to closed'
			);
			return wrapperResponseObj;
		}
		wrapperResponseObj = new WrapperResponse(null, true, caseToMerge.Id);
		return wrapperResponseObj;
	}
	/*********************************************************************************************************
	 * @name			moveAttachmentAsFeed
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		Captures the attachments related to the email messages of the cases to be merged and merged to the parent case.
	 *                  and inserts it as the feed comments
	 **********************************************************************************************************/
	private static void moveAttachmentAsFeed(Map<id, Id> map_emailMessageIdToParentCaseId, Map<id, Case> map_caseIdToCase, Id idParentCaseFeedItem) {
		List<Attachment> list_AttachmentRecords = new List<Attachment>();
		List<FeedComment> list_ToInsertFeedCommentList = new List<FeedComment>();
		Map<id, combinedattachment> map_combAttIdToCombAttachRec = new Map<id, combinedattachment>();
		Map<id, String> map_ContentDocIdToDistributionPublicUrl = new Map<id, String>();

		if (map_emailMessageIdToParentCaseId.size() > 0) {
			list_AttachmentRecords = [
				SELECT Id, ParentId, Name, OwnerId, CreatedDate, createdById
				FROM Attachment
				WHERE ParentId IN :map_emailMessageIdToParentCaseId.keySet()
				ORDER BY CreatedDate ASC
			];
		} else {
			return;
		}

		//Copy attachments to Feed Comment
		try {
			if (list_AttachmentRecords.size() > 0) {
				for (Attachment attachmentRec : list_AttachmentRecords) {
					if (Limits.getDMLStatements() >= 140) {
						break;
					}

					ConnectApi.CommentInput objComment = new ConnectApi.CommentInput();
					ConnectApi.MessageBodyInput objCommentBody = new ConnectApi.MessageBodyInput();
					objCommentBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

					ConnectApi.TextSegmentInput objCommentSegment = new ConnectApi.TextSegmentInput();
					objCommentSegment.Text = 'Attachment copied from merged case: ';
					objCommentBody.messageSegments.add(objCommentSegment);

					//add case link
					ConnectApi.EntityLinkSegmentInput objCommentLinkSegment = new ConnectApi.EntityLinkSegmentInput();
					objCommentLinkSegment.entityId = map_caseIdToCase.get(map_emailMessageIdToParentCaseId.get(attachmentRec.ParentId)).Id;
					objCommentBody.messageSegments.add(objCommentLinkSegment);

					ConnectApi.TextSegmentInput objCommentSegmentTextAttachInfo = new ConnectApi.TextSegmentInput();
					objCommentSegmentTextAttachInfo.Text = '\r\n Attachment: ';
					objCommentBody.messageSegments.add(objCommentSegmentTextAttachInfo);

					//add attachment link
					ConnectApi.EntityLinkSegmentInput objAttachLink = new ConnectApi.EntityLinkSegmentInput();
					objAttachLink.entityId = attachmentRec.Id;
					objCommentBody.messageSegments.add(objAttachLink);

					objComment.body = objCommentBody;

					//only post when not running tests. Allows test class to use SeeAllData = false
					if (!Test.isRunningTest()) {
						ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), idParentCaseFeedItem, objComment, null);
					}
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_MergeCaseController', 'mergeSeletedCase', ex.getMessage(), ex.getStackTraceString());
		}

		for (EmailMessage em : [
			SELECT id, parentId, (SELECT FileExtension, ContentSize, Title, SharingOption, Id, ParentId, LastModifiedDate, CreatedById, CreatedDate FROM combinedattachments)
			FROM emailmessage
			WHERE id IN :map_emailMessageIdToParentCaseId.keySet()
		]) {
			for (combinedattachment ct : em.combinedattachments) {
				map_combAttIdToCombAttachRec.put(ct.id, ct);
			}
		}

		if (map_combAttIdToCombAttachRec.size() > 0) {
			for (ContentDistribution cd : [SELECT DistributionPublicUrl, ContentDocumentId, Id FROM ContentDistribution WHERE contentdocumentid IN :map_combAttIdToCombAttachRec.keyset()]) {
				map_ContentDocIdToDistributionPublicUrl.put(cd.ContentDocumentId, cd.DistributionPublicUrl);
			}
		}

		list_ToInsertFeedCommentList = new List<FeedComment>();

		try {
			for (combinedattachment ct : map_combAttIdToCombAttachRec.values()) {
				if (Limits.getDMLStatements() >= 140) {
					break;
				}

				ConnectApi.CommentInput objComment = new ConnectApi.CommentInput();
				ConnectApi.MessageBodyInput objCommentBody = new ConnectApi.MessageBodyInput();
				objCommentBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

				ConnectApi.TextSegmentInput objCommentSegment = new ConnectApi.TextSegmentInput();
				objCommentSegment.Text = 'Attachment copied from merged case: ';
				objCommentBody.messageSegments.add(objCommentSegment);

				//add case link
				ConnectApi.EntityLinkSegmentInput objCommentLinkSegment = new ConnectApi.EntityLinkSegmentInput();
				objCommentLinkSegment.entityId = map_caseIdToCase.get(map_emailMessageIdToParentCaseId.get(ct.parentId)).Id;
				objCommentBody.messageSegments.add(objCommentLinkSegment);

				ConnectApi.TextSegmentInput objCommentSegmentTextAttachInfo = new ConnectApi.TextSegmentInput();
				objCommentSegmentTextAttachInfo.Text = '\r\n Attachment: ';
				objCommentBody.messageSegments.add(objCommentSegmentTextAttachInfo);

				//add attachment link
				ConnectApi.EntityLinkSegmentInput objAttachLink = new ConnectApi.EntityLinkSegmentInput();
				objAttachLink.entityId = ct.Id;
				objCommentBody.messageSegments.add(objAttachLink);

				objComment.body = objCommentBody;

				//only post when not running tests. Allows test class to use SeeAllData = false
				if (!Test.isRunningTest()) {
					ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), idParentCaseFeedItem, objComment, null);
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_MergeCaseController', 'moveAttachmentAsFeed', ex.getMessage(), ex.getStackTraceString());
		}
	}

	/*********************************************************************************************************
	 * @name			copyFeeds
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		This method copies the feed comments of the case getting merged to the new case as the feed comment
	 **********************************************************************************************************/
	public static void copyFeeds(List<Id> list_CaseIds, Id idParentCaseFeedItem) {
		if (idParentCaseFeedItem == null) {
			return;
		}

		Map<Id, FeedItem> map_FeedItemToCopy = new Map<Id, FeedItem>(
			[
				SELECT
					BestCommentId,
					Body,
					CommentCount,
					CreatedById,
					CreatedDate,
					CreatedBy.IsActive,
					CreatedBy.Name,
					HasContent,
					HasLink,
					Id,
					Visibility,
					IsDeleted,
					LastEditById,
					LastEditDate,
					LastModifiedDate,
					LikeCount,
					LinkUrl,
					ParentId,
					RelatedRecordId,
					Revision,
					SystemModstamp,
					Title,
					Type,
					(SELECT CommentBody, CommentType, CreatedById, CreatedDate, FeedItemId, IsDeleted, LastEditById, LastEditDate, ParentId, RelatedRecordId, Revision FROM FeedComments)
				FROM FeedItem
				WHERE ParentId IN :list_CaseIds
			]
		);

		if (map_FeedItemToCopy != null && !map_FeedItemToCopy.isEmpty()) {
			List<FeedComment> list_FeedComments = new List<FeedComment>();

			for (FeedItem objFeedItem : map_FeedItemToCopy.values()) {
				if (String.isNotBlank(objFeedItem.Body) || String.isNotBlank(objFeedItem.LinkUrl)) {
					FeedComment objFeedComment = new FeedComment();
					objFeedComment.FeedItemId = idParentCaseFeedItem;
					objFeedComment.CreatedDate = objFeedItem.CreatedDate;

					if (String.isNotBlank(objFeedItem.Body)) {
						objFeedComment.CommentBody = objFeedItem.Body.left(9500);
					}
					if (String.isBlank(objFeedItem.Body) && String.isNotBlank(objFeedItem.LinkUrl)) {
						objFeedComment.CommentBody = objFeedItem.LinkUrl;
					}

					objFeedComment.IsRichText = true;
					list_FeedComments.add(objFeedComment);
				}

				for (FeedComment objExistingFeedComment : objFeedItem.FeedComments) {
					FeedComment objFeedComment = new FeedComment();
					objFeedComment.FeedItemId = idParentCaseFeedItem;
					objFeedComment.CreatedDate = objExistingFeedComment.CreatedDate;
					objFeedComment.CommentBody = objExistingFeedComment.CommentBody.left(9500);
					objFeedComment.IsRichText = true;
					if (String.isNotBlank(objFeedComment.CommentBody)) {
						list_FeedComments.add(objFeedComment);
					}
				}
			}

			if (!list_FeedComments.isEmpty()) {
				try {
					List<Database.SaveResult> list_SaveResults = Database.insert(list_FeedComments, false);
					List<String> list_Errors = new List<String>();
					for (Database.SaveResult objSaveResult : list_SaveResults) {
						if (!objSaveResult.isSuccess()) {
							for (Database.Error objError : objSaveResult.getErrors()) {
								if (!objError.getMessage().contains('Error while parsing Rich Text Content')) {
									String strErrorMessage = 'Insert failed for ' + objSaveResult.getId() + '. Error: ' + objError.getMessage() + '  ';
									list_Errors.add(strErrorMessage);
								}
							}
						}
					}

					if (!list_Errors.isEmpty()) {
						ExceptionLogUtil.logException(UserInfo.getUserId(), 'LWC_MergeCaseController', 'copyFeeds', list_Errors, 'Medium');
					}
				} catch (Exception ex) {
					ExceptionLogUtil.logException('LWC_MergeCaseController', 'copyFeeds', ex.getMessage(), ex.getStackTraceString());
				}
			}
		}
	}
	/*********************************************************************************************************
	 * @name			WrapperResponse
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		WrapperResponse to return the data to the JS file.
	 **********************************************************************************************************/
	public class WrapperResponse {
		@AuraEnabled
		public map<String, Object> map_ResponseData;
		@AuraEnabled
		public Boolean blnIsSuccess;
		@AuraEnabled
		public string strMessage;
		public WrapperResponse(Map<String, Object> responseData, Boolean isSuccess, String responseMessage) {
			this.map_ResponseData = responseData;
			this.blnIsSuccess = isSuccess;
			this.strMessage = responseMessage;
		}
	}
}