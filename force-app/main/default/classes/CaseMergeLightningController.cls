/*************************************************************************************************************
 * @name			CaseMergeLightningController
 * @author			Lakshey Mendiratta
 * @created			18 / 09 / 2020
 * @description		This class covers the follow up case functinality
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-09-18		Lakshey Mendiratta		Initial Development
 *
 **************************************************************************************************************/
public without sharing class CaseMergeLightningController {
	/*********************************************************************************************************
	 * @name			activateCaseAssignmentRules
	 * @author			Lakshey Mendiratta
	 * @created			18 / 09 / 2020
	 * @description		return the assignment rule operation after updating the case
	 **********************************************************************************************************/
	@AuraEnabled
	public static void activateCaseAssignmentRules(Id idCase) {
		Case caseObj = new Case(Id = idCase);
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		caseObj.setOptions(dmo);
		try {
			update caseObj;
		} catch (DmlException e) {
			ExceptionLogUtil.logException('CaseMergeLightningController', 'activateCaseAssignmentRules', e.getMessage(), e.getStackTraceString());
		}
	}

	/*********************************************************************************************************
	 * @name			activateCaseAssignmentRules
	 * @author			Lakshey Mendiratta
	 * @created			18 / 09 / 2020
	 * @description		updates the case owner
	 **********************************************************************************************************/
	@AuraEnabled
	public static void setCaseOwner(String loggedInUserId, Id caseId) {
		Case caseObj = new Case(Id = caseId);
		caseObj.OwnerId = loggedInUserId;
		update caseObj;
	}

	/*********************************************************************************************************
	 * @name			activateCaseAssignmentRules
	 * @author			Lakshey Mendiratta
	 * @created			18 / 09 / 2020
	 * @description		updates the case status
	 **********************************************************************************************************/
	@AuraEnabled
	public static Case getCaseData(Id caseId) {
		Case caseObj = new Case(Id = caseId);
		caseObj.Status = 'Closed';
		update caseObj;

		return [SELECT Id, Account.Name FROM Case WHERE Id = :caseId];
	}

	@AuraEnabled
	public static String insertChatterFeed(Id idCase, String strCaseNumber, String strNewCaseId) {
		String strUrlInstance = String.valueof(System.URL.getSalesforceBaseURL().gethost());
		String strUrlInstanceFinal = strUrlInstance.removeEndIgnoreCase('.my.salesforce.com');
		ConnectApi.MessageBodyInput objMsgInput = new ConnectApi.MessageBodyInput();
		objMsgInput.MessageSegments = new List<ConnectApi.MessageSegmentInput>();

		List<FeedComment> list_ToInsertFeedItemList = new List<FeedComment>();
		Map<Id, Id> map_emailMessageIdToParentCaseId = new Map<Id, Id>();
		List<FeedComment> list_ToInsertFeedCommentList = new List<FeedComment>();
		try {
			//make the feed post
			Case objOldParentCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :idCase LIMIT 1];
			String strOldcaseNumber = objOldParentCase != null ? objOldParentCase.CaseNumber : '';

			Case objNewCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :strNewCaseId LIMIT 1];
			String strNewCaseNumber = objNewCase != null ? objNewCase.CaseNumber : '';

			ConnectApi.TextSegmentInput objTextSegment = new ConnectApi.TextSegmentInput();
			objTextSegment.Text = 'Case ';
			objMsgInput.MessageSegments.add(objTextSegment);

			ConnectApi.EntityLinkSegmentInput objEntityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
			objEntityLinkSegment.entityId = idCase;
			objMsgInput.messageSegments.add(objEntityLinkSegment);

			ConnectApi.TextSegmentInput objTextSegment2 = new ConnectApi.TextSegmentInput();
			objTextSegment2.Text = ' was merged to this case.';
			objMsgInput.MessageSegments.add(objTextSegment2);

			ConnectApi.FeedItemInput objFeedItemInput = new ConnectApi.FeedItemInput();
			objFeedItemInput.body = objMsgInput;
			objFeedItemInput.subjectId = strNewCaseId;
			objFeedItemInput.visibility = ConnectApi.FeedItemVisibilityType.INTERNALUSERS;

			ConnectApi.FeedElement objFeedElement;
			if (!Test.isRunningTest()) {
				objFeedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), objFeedItemInput);
			}

			for (Case caseToCopy : [
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
				WHERE Id = :idCase
				LIMIT 1
			]) {
				strCaseNumber = caseToCopy.CaseNumber;
				if (caseToCopy.EmailMessages != null && caseToCopy.EmailMessages.size() > 0) {
					for (EmailMessage emailToCopy : caseToCopy.EmailMessages) {
						//make email comment
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

						if (!Test.isRunningTest()) {
							ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), objFeedElement.Id, objComment, null);
						}

						map_emailMessageIdToParentCaseId.put(emailToCopy.id, caseToCopy.id);
					}
				}
			}

			if (map_emailMessageIdToParentCaseId.size() > 0) {
				for (Attachment attachmentRec : [
					SELECT Id, ParentId, Name, OwnerId, CreatedDate, createdById
					FROM Attachment
					WHERE ParentId IN :map_emailMessageIdToParentCaseId.keySet()
					ORDER BY CreatedDate ASC
				]) {
					ConnectApi.CommentInput objComment = new ConnectApi.CommentInput();
					ConnectApi.MessageBodyInput objCommentBody = new ConnectApi.MessageBodyInput();
					objCommentBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

					ConnectApi.TextSegmentInput objCommentSegment = new ConnectApi.TextSegmentInput();
					objCommentSegment.Text = 'Attachment copied from merged case: ';
					objCommentBody.messageSegments.add(objCommentSegment);

					//add case link
					ConnectApi.EntityLinkSegmentInput objCommentLinkSegment = new ConnectApi.EntityLinkSegmentInput();
					objCommentLinkSegment.entityId = idCase;
					objCommentBody.messageSegments.add(objCommentLinkSegment);

					ConnectApi.TextSegmentInput objCommentSegmentTextAttachInfo = new ConnectApi.TextSegmentInput();
					objCommentSegmentTextAttachInfo.Text = '\r\n Attachment: ';
					objCommentBody.messageSegments.add(objCommentSegmentTextAttachInfo);

					//add attachment link
					ConnectApi.EntityLinkSegmentInput objAttachLink = new ConnectApi.EntityLinkSegmentInput();
					objAttachLink.entityId = attachmentRec.Id;
					objCommentBody.messageSegments.add(objAttachLink);

					objComment.body = objCommentBody;
					if (!Test.isRunningTest()) {
						ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), objFeedElement.Id, objComment, null);
					}
				}
			}

			List<FeedComment> list_FeedComment = new List<FeedComment>();
			for (FeedItem originalFeed : [
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
					(
						SELECT CommentBody, CommentType, CreatedById, CreatedDate, FeedItemId, IsDeleted, LastEditById, LastEditDate, ParentId, RelatedRecordId, Revision
						FROM FeedComments
					)
				FROM FeedItem
				WHERE ParentId = :idCase
			]) {
				if (String.isNotBlank(originalFeed.Body) || String.isNotBlank(originalFeed.LinkUrl)) {
					FeedComment newCom = new FeedComment();
					newCom.FeedItemId = objFeedElement?.Id;
					newCom.CreatedDate = originalFeed.CreatedDate;
					if (String.isNotBlank(originalFeed.Body)) {
						newCom.CommentBody = originalFeed.Body;
					}
					if (String.isBlank(originalFeed.Body) && String.isNotBlank(originalFeed.LinkUrl)) {
						newCom.CommentBody = originalFeed.LinkUrl;
					}
					newCom.IsRichText = true;
					list_FeedComment.add(newCom);
				}
				for (FeedComment fc : originalFeed.FeedComments) {
					if (String.isNotBlank(fc.CommentBody)) {
						FeedComment newCom1 = new FeedComment();
						newCom1.FeedItemId = objFeedElement?.Id;
						newCom1.CreatedDate = fc.CreatedDate;
						newCom1.CommentBody = fc.CommentBody;
						newCom1.IsRichText = true;
						list_FeedComment.add(newCom1);
					}
				}
			}

			if (!list_FeedComment.isEmpty()) {
				try {
					List<Database.SaveResult> list_SaveResults = Database.insert(list_FeedComment, false);
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
						ExceptionLogUtil.logException(UserInfo.getUserId(), 'CaseMergeLightningController', 'insertChatterFeed', list_Errors, 'Medium');
					}
				} catch (Exception ex) {
					ExceptionLogUtil.logException('CaseMergeLightningController', 'insertChatterFeed', ex.getMessage(), ex.getStackTraceString());
				}
			}

			ConnectApi.CommentInput objFollowUpCreatedComment = new ConnectApi.CommentInput();
			ConnectApi.MessageBodyInput objFollowUpCommentBody = new ConnectApi.MessageBodyInput();
			objFollowUpCommentBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();

			ConnectApi.TextSegmentInput objCommentSegment = new ConnectApi.TextSegmentInput();
			objCommentSegment.Text = 'Follow up Case ';
			objFollowUpCommentBody.messageSegments.add(objCommentSegment);

			//add case link
			ConnectApi.EntityLinkSegmentInput objFollowUpLinkSegment = new ConnectApi.EntityLinkSegmentInput();
			objFollowUpLinkSegment.entityId = strNewCaseId;
			objFollowUpCommentBody.messageSegments.add(objFollowUpLinkSegment);
			objFollowUpCreatedComment.body = objFollowUpCommentBody;

			ConnectApi.TextSegmentInput objCommentSegment2 = new ConnectApi.TextSegmentInput();
			objCommentSegment2.Text = ' created';
			objFollowUpCommentBody.messageSegments.add(objCommentSegment2);

			if (!Test.isRunningTest()) {
				ConnectApi.Comment commentRep = ConnectApi.ChatterFeeds.postCommentToFeedElement(Network.getNetworkId(), objFeedElement.Id, objFollowUpCreatedComment, null);
			}

			return 'Case ' + strOldcaseNumber + ' has been Successfully merged to ' + strNewCaseNumber;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('CaseMergeLightningController', 'insertChatterFeed', ex.getMessage(), ex.getStackTraceString());
		}
		return null;
	}

	/*
    * @author:         Ankit CS
    * @description:    Create a chatter post with the required fields 
    * @param:          strOriginalCaseId - Parent Case Id
                       strNewCaseId - Follow-up Case Id
                       map_CaseFields - Map of case fields by field name
    * @return:         NA
    */
	@AuraEnabled
	public static void insertCaseChatterNotes(String strOriginalCaseId, String strNewCaseId, Map<String, Object> map_CaseFields) {
		try {
			ConnectApi.MessageBodyInput objMsgInput = new ConnectApi.MessageBodyInput();
			objMsgInput.MessageSegments = new List<ConnectApi.MessageSegmentInput>();
			ConnectApi.TextSegmentInput objTextSegment = new ConnectApi.TextSegmentInput();
			ConnectApi.MarkupBeginSegmentInput objBeginParagraph = new ConnectApi.MarkupBeginSegmentInput();
			ConnectApi.MarkupBeginSegmentInput objBeginBold = new ConnectApi.MarkupBeginSegmentInput();
			ConnectApi.MarkupEndSegmentInput objEndParagraph = new ConnectApi.MarkupEndSegmentInput();
			ConnectApi.MarkupEndSegmentInput objEndBold = new ConnectApi.MarkupEndSegmentInput();
			objBeginParagraph.MarkupType = ConnectApi.MarkupType.Paragraph;
			objBeginBold.MarkupType = ConnectApi.MarkupType.Bold;
			objEndParagraph.MarkupType = ConnectApi.MarkupType.Paragraph;
			objEndBold.MarkupType = ConnectApi.MarkupType.Bold;
			objTextSegment.Text = 'Follow-up Case created from ';
			objMsgInput.MessageSegments.add(objTextSegment);
			//Link Parent Case
			ConnectApi.EntityLinkSegmentInput objEntityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
			objEntityLinkSegment.EntityId = strOriginalCaseId;
			objMsgInput.MessageSegments.add(objEntityLinkSegment);
			objTextSegment.Text += '\r\n';

			//Write required fields into the feed
			FollowUpEscalationCaseController_LEX.writeFeedLine(
				objTextSegment,
				objMsgInput,
				objBeginParagraph,
				objBeginBold,
				'Subject: ',
				(String) map_CaseFields.get('Subject'),
				objEndBold,
				objEndParagraph
			);

			FollowUpEscalationCaseController_LEX.writeFeedLine(
				objTextSegment,
				objMsgInput,
				objBeginParagraph,
				objBeginBold,
				'Description: ',
				(String) map_CaseFields.get('Description'),
				objEndBold,
				objEndParagraph
			);

			FollowUpEscalationCaseController_LEX.writeFeedLine(
				objTextSegment,
				objMsgInput,
				objBeginParagraph,
				objBeginBold,
				'What is the Customer Asking and/or Requesting?: ',
				(String) map_CaseFields.get('Customer_Query_Request__c'),
				objEndBold,
				objEndParagraph
			);

			FollowUpEscalationCaseController_LEX.writeFeedLine(
				objTextSegment,
				objMsgInput,
				objBeginParagraph,
				objBeginBold,
				'What Action or Correction is Needed to Resolve Customer Inquiry?: ',
				(String) map_CaseFields.get('Action_Correction_Needed__c'),
				objEndBold,
				objEndParagraph
			);

			FollowUpEscalationCaseController_LEX.writeFeedLine(
				objTextSegment,
				objMsgInput,
				objBeginParagraph,
				objBeginBold,
				'Reason for Follow-up Case: ',
				(String) map_CaseFields.get('Reason_for_Follow_up_Case__c'),
				objEndBold,
				objEndParagraph
			);

			ConnectApi.FeedItemInput objFeedItemInput = new ConnectApi.FeedItemInput();
			objFeedItemInput.Body = objMsgInput;
			objFeedItemInput.SubjectId = strNewCaseId;
			objFeedItemInput.Visibility = ConnectApi.FeedItemVisibilityType.INTERNALUSERS;

			if (!Test.isRunningTest()) {
				ConnectApi.FeedElement objFeedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), objFeedItemInput);
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CaseMergeLightningController', 'insertCaseChatterNotes', objException.getMessage(), objException.getStackTraceString());
		}
	}
}