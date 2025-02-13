/*************************************************************************************************************
 * name			FollowUpEscalationCaseController_LEX
 * author	    Lakshey Mendiratta
 * created			16/10/2020
 * description
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	-----------	----------------------------------------------
 * version		1.0		2020-10-16		Lakshey
 *
 **************************************************************************************************************/
public with sharing class FollowUpEscalationCaseController_LEX {
	/*********************************************************************************************************
	 * @name			crateCase
	 * @author			Lakshey
	 * @created			16 / 10 / 2020
	 * @description		Create a new escalation case
	 * @return			Case object
	 **********************************************************************************************************/
	@AuraEnabled
	public static Case createFollowEscalationCase(
		Id idOriginalCase,
		String strErrorOrigin,
		String strDescription,
		String strSubject,
		String strCustomOutreach,
		String strSteps,
		String strAdminRequest,
		DateTime strTime,
		String strCaseReasonSelected,
		String strCaseEscalationType,
		String strEscalationQueue
	) {
		String strRecordType;
		String strContactName;
		String strAccountName;
		String strConfirmCaseReason;
		String strConfirmCaseReasonClassification;
		List<Case> list_Cases = [
			SELECT
				RecordTypeId,
				RecordType.Name,
				ContactId,
				AccountId,
				Confirm_Case_Reason__c,
				Confirm_Case_Reason_Classification__c
			FROM Case
			WHERE Id = :idOriginalCase
		];

		List<Case_Reason_Classification__c> list_CaseReasonClassifications = new List<Case_Reason_Classification__c>();
	
		// Get correspending case reason classification record 
		list_CaseReasonClassifications = [
			SELECT Id, Name, Class__c, Type__c, Default_Type__c 
			FROM Case_Reason_Classification__c 
			WHERE Name = :strCaseReasonSelected
		];

		for (Case objParentCase : list_Cases) {
			//default the record type id
			strRecordType = objParentCase.RecordTypeId;

			if (!list_CaseReasonClassifications.isEmpty()) {
				strRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().
					get(list_CaseReasonClassifications.get(0).Default_Type__c).getRecordTypeId();
			}

			strContactName = objParentCase.ContactId;
			strAccountName = objParentCase.AccountId;

			if (String.isBlank(objParentCase.Confirm_Case_Reason__c)) {
				objParentCase.Confirm_Case_Reason__c = strCaseReasonSelected;
			} else {
				if (
					(String.isNotBlank(strCaseReasonSelected) &&
					objParentCase.Confirm_Case_Reason__c != strCaseReasonSelected)
				) {
					objParentCase.Confirm_Case_Reason__c = strCaseReasonSelected;
					strConfirmCaseReason = strCaseReasonSelected;
				} else {
					strConfirmCaseReason = objParentCase.Confirm_Case_Reason__c;
				}
			}

			//set parent case's record type and type to match with confirm case reason
			objParentCase.RecordTypeId = strRecordType;

			if (!list_CaseReasonClassifications.isEmpty()) {
				objParentCase.Type = list_CaseReasonClassifications.get(0).Type__c;
			}
		}

		if (list_Cases != null && list_Cases.size() > 0) {
			update list_Cases;
		}

		//query for a group where name matches from what we're receiving from LWC
		//if no group found, make the owner the PRC Escalation Queue
		List<Group> list_Group = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :strEscalationQueue];
		Id idEscalationGroup = Label.Payroll_Care_Escalation_Queue;

		if (!list_Group.isEmpty()) {
			idEscalationGroup = list_Group[0]?.Id;
		}

		Database.DMLOptions objDMLOption = new Database.DMLOptions();
		objDMLOption.assignmentRuleHeader.useDefaultRule = false;
		Case objCase = new case();
		objCase.setOptions(objDMLOption);
		objCase.Origin = 'Escalation';
		objCase.RecordTypeId = strRecordType;
		objCase.ContactId = strContactName;
		objCase.AccountId = strAccountName;
		objCase.Direction__c = 'Outbound';
		objCase.OwnerId = idEscalationGroup;
		objCase.Preferred_Customer_Outreach__c = strCustomOutreach;
		objCase.Error_Origin_New__c = strErrorOrigin;
		objCase.Subject = strSubject;
		objCase.Description = strDescription;
		objCase.DeEscalation_Steps_Taken__c = strSteps;
		objCase.Did_Admin_Request_to_Speak_to_Manager__c = strAdminRequest;
		objCase.Preferred_Time_of_Outreach__c = strTime;
		objCase.ParentId = list_Cases[0].Id;
		objCase.Confirm_Case_Reason__c = (String.isBlank(strConfirmCaseReason))
			? strCaseReasonSelected
			: strConfirmCaseReason;
		objCase.Escalation_Type__c = strCaseEscalationType;
		objCase.Skip_Survey__c = true;

		try {
			insert objCase;
			return [SELECT Id, CaseNumber FROM Case WHERE Id = :objCase.Id];
		} catch (Exception e) {
			ExceptionLogUtil.logException(
				'FollowUpEscalationCaseController_LEX',
				'createFollowEscalationCase',
				e.getMessage(),
				e.getStackTraceString()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*********************************************************************************************************
	 * @name			FeedComments
	 * @author			Lakshey
	 * @created			16 / 10 / 2020
	 * @description		Post a feed comment on the new case created
	 **********************************************************************************************************/
	@AuraEnabled
	public static void insertChatterFeed(Id idParentCase, String strCaseNumber, String strNewCaseId) {
		String strUrlInstance = String.valueof(System.URL.getSalesforceBaseURL().gethost());
		String strUrlInstanceFinal = strUrlInstance.removeEndIgnoreCase('.my.salesforce.com');

		try {
			List<Case> list_ParentCases = [SELECT Id, CaseNumber FROM Case WHERE Id = :idParentCase LIMIT 1];
			List<Case> list_Cases = [
				SELECT
					Id,
					Origin,
					ContactId,
					AccountId,
					Direction__c,
					CaseNumber,
					Preferred_Customer_Outreach__c,
					Error_Origin_New__c,
					Subject,
					Description,
					Preferred_Time_of_Outreach__c,
					Did_Admin_Request_to_Speak_to_Manager__c,
					DeEscalation_Steps_Taken__c
				FROM Case
				WHERE Id = :strNewCaseId
				LIMIT 1
			];

			if (!list_ParentCases.isEmpty() && !list_Cases.isEmpty()) {
				String strOldCaseNumber = list_ParentCases[0].CaseNumber;
				Case objCase = list_Cases[0];

				String strTime = objCase.Preferred_Time_of_Outreach__c != null ?
					String.valueOf(objCase.Preferred_Time_of_Outreach__c.format()) : 
					String.valueOf(System.Now());

				ConnectApi.MessageBodyInput objMsgInput = new ConnectApi.MessageBodyInput();
				objMsgInput.MessageSegments = new List<ConnectApi.MessageSegmentInput>();
				ConnectApi.TextSegmentInput objTextSegment = new ConnectApi.TextSegmentInput();
				ConnectApi.MarkupBeginSegmentInput beginParagraph = new ConnectApi.MarkupBeginSegmentInput();
				ConnectApi.MarkupBeginSegmentInput beginBold = new ConnectApi.MarkupBeginSegmentInput();
				ConnectApi.MarkupEndSegmentInput endParagraph = new ConnectApi.MarkupEndSegmentInput();
				ConnectApi.MarkupEndSegmentInput endBold = new ConnectApi.MarkupEndSegmentInput();
				beginParagraph.markupType = ConnectApi.MarkupType.Paragraph;
				beginBold.markupType = ConnectApi.MarkupType.Bold;
				endParagraph.markupType = ConnectApi.MarkupType.Paragraph;
				endBold.markupType = ConnectApi.MarkupType.Bold;

				objTextSegment.Text = 'Escalation Case created from ';
				objMsgInput.MessageSegments.add(objTextSegment);
				//attach case
				ConnectApi.EntityLinkSegmentInput objEntityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
				objEntityLinkSegment.entityId = idParentCase;
				objMsgInput.messageSegments.add(objEntityLinkSegment);
				objTextSegment.Text += '\r\n';

				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Origin: ',
					objCase.Origin,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Direction: ',
					objCase.Direction__c,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Preferred Customer Outreach: ',
					objCase.Preferred_Customer_Outreach__c,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Escalation Error Origin: ',
					objCase.Error_Origin_New__c,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Subject: ',
					objCase.Subject,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Description: ',
					objCase.Description,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Preferred Time of Outreach: ',
					strTime,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'De-Escalation Steps Taken: ',
					objCase.DeEscalation_Steps_Taken__c,
					endBold,
					endParagraph
				);
				writeFeedLine(
					objTextSegment,
					objMsgInput,
					beginParagraph,
					beginBold,
					'Did Admin Request to Speak to Manager: ',
					objCase.Did_Admin_Request_to_Speak_to_Manager__c,
					endBold,
					endParagraph
				);

				ConnectApi.FeedItemInput objFeedItemInput = new ConnectApi.FeedItemInput();
				objFeedItemInput.body = objMsgInput;
				objFeedItemInput.subjectId = strNewCaseId;
				objFeedItemInput.visibility = ConnectApi.FeedItemVisibilityType.INTERNALUSERS;

				ConnectApi.FeedElement objFeedElement = ConnectApi.ChatterFeeds.postFeedElement(
					Network.getNetworkId(),
					objFeedItemInput
				);
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException(
				'FollowUpEscalationCaseController_LEX',
				'insertChatterFeed',
				e.getMessage(),
				e.getStackTraceString()
			);
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * Author: Alex
	 * Date: 10/26/2020
	 * Desc: format the line
	 */
	public static void writeFeedLine(
		ConnectApi.TextSegmentInput objTextSegment,
		ConnectApi.MessageBodyInput objMsgInput,
		ConnectApi.MarkupBeginSegmentInput beginParagraph,
		ConnectApi.MarkupBeginSegmentInput beginBold,
		String strField,
		String strFieldValue,
		ConnectApi.MarkupEndSegmentInput endBold,
		ConnectApi.MarkupEndSegmentInput endParagraph
	) {
		objTextSegment = new ConnectApi.TextSegmentInput();
		objMsgInput.messageSegments.add(beginParagraph);
		objMsgInput.messageSegments.add(beginBold);
		objTextSegment.Text = strField;
		objMsgInput.messageSegments.add(objTextSegment);
		objMsgInput.messageSegments.add(endBold);
		objTextSegment = new ConnectApi.TextSegmentInput();
		objTextSegment.Text = strFieldValue + '\r\n';
		objMsgInput.MessageSegments.add(objTextSegment);
		objMsgInput.messageSegments.add(endParagraph);
	}
}