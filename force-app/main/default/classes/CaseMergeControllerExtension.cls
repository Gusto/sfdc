/**
 * Controller for CaseMergeListView
 * @author Anshul Agrawal
 * @date 2/2018
 * @see CaseMergeControllerExtension
 * @group Enablement
 */
public without sharing class CaseMergeControllerExtension {
	public Case caseToMerge { get; set; }
	// the variable being set from the commandlink
	public String selectedCaseToMerge { get; set; }
	public string searchSubject { get; set; }
	public string searchStatus { get; set; }
	public string searchCaseNumber { get; set; }
	public boolean searchOpenCases { get; set; }
	private String masterCaseToMergeContact;
	private String masterCaseToMergeAccount;
	private String masterCaseToMergeSuppliedEmail;
	private String masterCaseToMergeSuppliedPhone;
	private Id masterCaseId;
	// Standard Set Controller
	public ApexPages.StandardSetController setCon { get; set; }

	public CaseMergeControllerExtension(ApexPages.StandardController standardController) {
		Id recordId = standardController.getId();
		searchOpenCases = true;

		caseToMerge = [SELECT CaseNumber, RecordTypeId, ContactId, AccountId, Status, Priority, Subject, Type, SuppliedEmail, SuppliedPhone, OwnerId FROM Case WHERE Id = :recordId];
		if (caseToMerge.ContactId != null) {
			masterCaseToMergeContact = caseToMerge.ContactId;
		} else {
			masterCaseToMergeContact = '000000000000000';
		}

		if (caseToMerge.AccountId != null) {
			masterCaseToMergeAccount = caseToMerge.AccountId;
		} else {
			masterCaseToMergeAccount = '0000000000000';
		}
		if (caseToMerge.SuppliedEmail != null) {
			masterCaseToMergeSuppliedEmail = caseToMerge.SuppliedEmail;
		} else {
			masterCaseToMergeSuppliedEmail = 'gustotest@gustotestuser.com';
		}
		if (caseToMerge.SuppliedPhone != null) {
			masterCaseToMergeSuppliedPhone = caseToMerge.SuppliedPhone;
		} else {
			masterCaseToMergeSuppliedPhone = '%9999999999%';
		}

		masterCaseId = caseToMerge.Id;
		caseSearchList = new List<Case>();
		searchBySubject();
	}

	public List<Case> caseSearchList {
		get {
			if (setCon != null) {
				return (List<Case>) setCon.getRecords();
			} else
				return null;
		}
		set;
	}

	public PageReference searchBySubject() {
		String query = '';
		String strFilter = 'AND Id != :masterCaseId ';
		if (searchSubject != null && searchSubject != '') {
			String searchSubject1 = '%' + searchSubject + '%';
			strFilter = strFilter + ' AND Subject like :searchSubject1';
		}
		if (searchOpenCases) {
			strFilter = strFilter + ' AND IsClosed=false ';
		}
		if (searchStatus != null && searchStatus != '') {
			String searchStatus1 = '%' + searchStatus + '%';
			strFilter = strFilter + ' AND Status like :searchStatus1';
		}
		if (searchCaseNumber != null && searchCaseNumber != '') {
			String searchCaseNumber1 = '%' + searchCaseNumber + '%';
			strFilter = strFilter + ' AND CaseNumber like :searchCaseNumber1';
		}
		if (strFilter != '') {
			if (searchCaseNumber != null && searchCaseNumber != '') {
				String searchCaseNumber1 = '%' + searchCaseNumber + '%';
				strFilter = ' CaseNumber like :searchCaseNumber1';
				query = 'SELECT CaseNumber, RecordTypeId, ContactId, Status, Priority, Subject, SuppliedEmail, OwnerId from Case ' + 'WHERE ' + strFilter + ' order by CreatedDate desc Limit 1000';
			} else {
				query =
					'SELECT CaseNumber, RecordTypeId, ContactId, Status, Priority, Subject, SuppliedEmail, OwnerId from Case ' +
					'WHERE (ContactId =: masterCaseToMergeContact or SuppliedEmail =: masterCaseToMergeSuppliedEmail or SuppliedPhone like :masterCaseToMergeSuppliedPhone) ' +
					strFilter +
					' order by CreatedDate desc Limit 1000';
			}
			setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
			setCon.setPageSize(20);
		}

		return null;
	}

	public PageReference mergeSeletedCase() {
		EmailMessageTriggerHelper.skipTrigger = true;

		//BY:PR, Date: 6/12/19, Desc: We are updating the custom setting to skip the "Cant_Change_Read_Only_Case_Status" case validation.
		Case_Merge_Skip_Validation__c obj_SkipValidationRec = Case_Merge_Skip_Validation__c.getOrgDefaults();
		if (obj_SkipValidationRec != null && obj_SkipValidationRec.Id != null) {
			obj_SkipValidationRec.Disable_Validation__c = true;
			update obj_SkipValidationRec;
		}

		Case caseToCopy = new Case();
		List<FeedItem> feedItemList = new List<FeedItem>();

		Savepoint sp = Database.setSavepoint();
		if (selectedCaseToMerge != null) {
			try {
				caseToCopy = [
					SELECT
						Id,
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
					WHERE Id = :selectedCaseToMerge
				];

				//Copy Email to Feed Item
				List<FeedItem> toInsertFeedItemList = new List<FeedItem>();
				Set<Id> emailMessageIdSet = new Set<Id>();

				for (EmailMessage emailToCopy : caseToCopy.EmailMessages) {
					FeedItem newFeedItem = new FeedItem();
					newFeedItem.ParentId = caseToMerge.Id;
					newFeedItem.CreatedById = emailToCopy.CreatedById;
					newFeedItem.CreatedDate = emailToCopy.CreatedDate;
					newFeedItem.Body = 'Email copied from merged case: ' + caseToCopy.CaseNumber + ' \r\n ';
					newFeedItem.Body += 'From Email: ' + emailToCopy.FromAddress + ' \r\n ';
					newFeedItem.Body += 'To Email: ' + emailToCopy.ToAddress + ' \r\n ';
					if (emailToCopy.TextBody != null && emailToCopy.TextBody.length() > 9500) {
						newFeedItem.Body += emailToCopy.TextBody.substring(0, 9500);
					} else {
						newFeedItem.Body += emailToCopy.TextBody;
					}
					newFeedItem.Body += ' \r\n ' + 'Link of the email message: ' + URL.getSalesforceBaseUrl().getHost() + '/' + emailToCopy.Id;
					newFeedItem.Status = 'Published';
					newFeedItem.type = 'TextPost';
					newFeedItem.Visibility = 'AllUsers';
					toInsertFeedItemList.add(newFeedItem);
					emailMessageIdSet.add(emailToCopy.Id);
				}

				//Create feed for email Attachments
				if (emailMessageIdSet.size() > 0) {
					moveAttachmentAsFeed(emailMessageIdSet, caseToCopy.Id, caseToCopy.CaseNumber);
				}

				if (toInsertFeedItemList.size() > 0) {
					insert toInsertFeedItemList;
				}

				// Insert FeedItem related to Case
				copyFeeds();
				if (caseToCopy.status != 'Closed') {
					caseToCopy.status = 'Closed';
					caseToCopy.Closed_Reason__c = 'Merged Duplicate';
				}
				if (caseToCopy.ParentId == null) {
					caseToCopy.ParentId = caseToMerge.Id;
				}
				String ownerId = caseToCopy.OwnerId;
				if (ownerId.indexOf('00G') == 0) {
					caseToCopy.OwnerId = UserInfo.getUserId();
				}
				update caseToCopy;
				FeedItem item = new FeedItem();
				item.ParentId = caseToCopy.Id;
				item.IsRichText = true;
				item.Body = 'This case is merged to ' + caseToMerge.CaseNumber + '.';
				feedItemList.add(item);

				item = new FeedItem();
				item.ParentId = caseToMerge.Id;
				item.IsRichText = true;
				item.Body = 'Case ' + caseToCopy.CaseNumber + ' was merged to this case.';
				feedItemList.add(item);
				insert (feedItemList);

				//BY:PR, Date: 6/12/19, Desc: We are updating the custom setting to skip the "Cant_Change_Read_Only_Case_Status" case validation.
				if (obj_SkipValidationRec != null && obj_SkipValidationRec.Id != null) {
					obj_SkipValidationRec.Disable_Validation__c = false;
					update obj_SkipValidationRec;
				}
			} catch (Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured whie merging the selected record'));
				Database.rollback(sp);
				ExceptionLogUtil.logException('CaseMergeControllerExtension', 'mergeSeletedCase', e.getMessage(), e.getStackTraceString());
				return null;
			}
			ApexPages.addMessage(
				new ApexPages.Message(
					ApexPages.Severity.INFO,
					'Case ' + caseToCopy.CaseNumber + ' is successfully merged with ' + caseToMerge.CaseNumber + '. The status of case ' + caseToCopy.CaseNumber + ' is updated to closed'
				)
			);
			return null;
		}
		return new PageReference('/' + masterCaseId);
	}

	private void moveAttachmentAsFeed(Set<Id> emailMessageIdSet, Id caseId, string caseNumber) {
		List<Attachment> attachmentList = new List<Attachment>();

		if (emailMessageIdSet.size() > 0) {
			attachmentList = [SELECT Id, ParentId, Name, OwnerId, CreatedDate, createdById FROM Attachment WHERE ParentId IN :emailMessageIdSet ORDER BY CreatedDate ASC];
		} else {
			return;
		}

		//Copy Email to Feed Item
		List<FeedItem> toInsertFeedItemList = new List<FeedItem>();
		for (Attachment attachmentRec : attachmentList) {
			FeedItem newFeedItem = new FeedItem();
			newFeedItem.ParentId = CaseId;
			newFeedItem.CreatedById = attachmentRec.CreatedById;
			newFeedItem.CreatedDate = attachmentRec.CreatedDate;
			newFeedItem.Body = 'Attachment copied from merged case: ' + caseNumber + ' \r\n ';
			newFeedItem.Body += 'Attachment Name: ' + attachmentRec.Name + ' \r\n ';
			newFeedItem.Body += ' \r\n ' + 'Link of the attachment record: ' + URL.getSalesforceBaseUrl().getHost() + '/' + attachmentRec.Id;
			newFeedItem.Status = 'Published';
			newFeedItem.type = 'TextPost';
			newFeedItem.Visibility = 'AllUsers';

			toInsertFeedItemList.add(newFeedItem);
		}

		if (toInsertFeedItemList.size() > 0) {
			insert toInsertFeedItemList;
		}
	}

	private void copyFeeds() {
		List<FeedComment> feedCommentToInsertList = new List<FeedComment>();
		Map<Id, FeedItem> oldIdNewFeedItemMap = new Map<Id, FeedItem>();
		Map<Id, FeedItem> feedItemToCopyMap = new Map<Id, FeedItem>(
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
				WHERE ParentId = :selectedCaseToMerge AND Type IN ('TextPost')
			]
		);

		if (feedItemToCopyMap != null && feedItemToCopyMap.size() > 0) {
			for (FeedItem originalFeed : feedItemToCopyMap.Values()) {
				FeedItem newFeedItem = originalFeed.clone();
				newFeedItem.ParentId = caseToMerge.Id;
				newFeedItem.CreatedById = originalFeed.CreatedById;
				newFeedItem.CreatedDate = originalFeed.CreatedDate;
				oldIdNewFeedItemMap.put(originalFeed.Id, newFeedItem);
			}
			if (oldIdNewFeedItemMap.size() > 0) {
				insert oldIdNewFeedItemMap.Values();
				for (Id oldFeedId : oldIdNewFeedItemMap.keyset()) {
					if (feedItemToCopyMap.containskey(oldFeedId)) {
						FeedItem feedItemToCopy = feedItemToCopyMap.get(oldFeedId);
						for (FeedComment com : feedItemToCopy.FeedComments) {
							FeedComment newCom = com.Clone();
							newCom.FeedItemId = oldIdNewFeedItemMap.get(oldFeedId).Id;
							newCom.CreatedDate = com.CreatedDate;
							feedCommentToInsertList.add(newCom);
						}
					}
				}
				if (feedCommentToInsertList != null && feedCommentToInsertList.size() > 0) {
					insert feedCommentToInsertList;
				}
			}
		}
	}
}