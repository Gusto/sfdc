/**
 * @description Custom Ticket Email Handler for seamless Ardius Ticket Email Interaction
 * @author      Ajay Krishna P U
 * @since       2023-05-27
 */
global class TicketEmailInboundHandler implements Messaging.InboundEmailHandler {
	//Relation Type
	final static String RELATION_TYPE_FROM_ADDRESS = 'FromAddress';
	final static String RELATION_TYPE_TO_ADDRESS = 'ToAddress';
	final static String RELATION_TYPE_CC_ADDRESS = 'CcAddress';

	//Max Limits
	@TestVisible
	final static Integer BODY_MAX_LIMIT = 131000;
	@TestVisible
	final static Integer SUBJECT_MAX_LIMIT = 3000;
	final static Integer CASE_BODY_MAX_LIMIT = 32000;
	final static Integer CASE_SUBJECT_MAX_LIMIT = 255;
	final static Integer HEADERS_MAX_LIMIT = 32000;

	//Sharing Settings
	final static String DOC_SHARE_TYPE = 'V';
	final static String DOC_VISIBILITY = 'AllUsers';

	//Message Constants
	final static String EMAIL_STATUS_SENT = '3'; //Status - Any SObject Emails
	final static String EMAIL_STATUS_READ = '1'; //Status - Case Emails
	@TestVisible
	final static String TRUNCATED_IDENTIFIER = '\n-------------Truncated-------------';

	//Applicable Contact Record Types
	final static List<Id> LIST_ALLOWED_CONTACT_RECORD_TYPES = new List<Id>{ ContactUtil.COMPANY_CONTACT_RT_ID, ContactUtil.RESELLER_CONTACT_RT_ID };

	/**
	 * @description           Handle Inbound Email Message and Link and Save to SObject
	 * @param objInboundEmail Inbound Email
	 * @param objEnvelop      Inbound Envelope
	 * @return                `Messaging.InboundEmailResult`
	 */
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail objInboundEmail, Messaging.InboundEnvelope objEnvelop) {
		try {
			//Validate Inputs
			if (objInboundEmail == null) {
				return null;
			}

			//1. Identify Email Thread / Reply To Email
			EmailMessage objEmailThread = identifyEmailThread(objInboundEmail);

			//2. Check If - Email Message have to be tracked ?
			if (!checkIfEmailMessageHaveToTrack(objEmailThread)) {
				return null;
			}

			//3. Get Existing Email Recipients in the system
			Map<String, Id> map_EmailToRelatedId = getSystemEmailRecipients(objInboundEmail);

			//4. Create Email Message
			EmailMessage objNewEmailMessage = createEmailMessage(objInboundEmail, objEmailThread, map_EmailToRelatedId);

			//5. Create Email Message Relations - From, To & Cc Address
			createEmailMessageRelations(objNewEmailMessage, objInboundEmail, map_EmailToRelatedId);

			//6.Create Attachments
			createEmailAttachments(objNewEmailMessage, objInboundEmail);

			//7. Update Communication Status to Related Ticket object
			updateCommunicationStatus(objNewEmailMessage);
		} catch (Exception objEx) {
			String strMessage =
				'Ex Message:' +
				objEx.getMessage() +
				'\nSub:' +
				objInboundEmail.subject +
				'\nMId:' +
				objInboundEmail.messageId +
				'\nTo:' +
				(objInboundEmail.toAddresses == null ? '' : String.join(objInboundEmail.toAddresses, ',')) +
				'\nBody:' +
				objInboundEmail.plainTextBody;
			ExceptionLogUtil.logException('TicketEmailInboundHandler', 'handleInboundEmail', strMessage, objEx.getStackTraceString());
		}
		return null;
	}

	/**
	 * @description           Identify Parent Email or Email Thread, The function uses Thread id to identification
	 * @param objInboundEmail Inbound Email
	 * @return                `EmailMessage`
	 */
	private static EmailMessage identifyEmailThread(Messaging.InboundEmail objInboundEmail) {
		List<EmailMessage> list_ParentEmailMessages = new List<EmailMessage>();

		//Most possible case, Check If Reply to header available
		if (objInboundEmail.inReplyTo != null) {
			list_ParentEmailMessages = [
				SELECT Id, MessageIdentifier, ThreadIdentifier, RelatedToId
				FROM EmailMessage
				WHERE MessageIdentifier = :objInboundEmail.inReplyTo
				ORDER BY CreatedDate DESC
				LIMIT 1
			];
		}

		//Rare case, In case ReplyTo not found check reference header
		if ((list_ParentEmailMessages == null || list_ParentEmailMessages.isEmpty()) && objInboundEmail.references != null) {
			list_ParentEmailMessages = [
				SELECT Id, MessageIdentifier, ThreadIdentifier, RelatedToId
				FROM EmailMessage
				WHERE MessageIdentifier IN :objInboundEmail.references
				ORDER BY CreatedDate DESC
				LIMIT 1
			];
		}

		//Return Email Message if Valid
		if (list_ParentEmailMessages != null && !list_ParentEmailMessages.isEmpty()) {
			List<Ticket__c> list_Tickets = [SELECT Id FROM Ticket__c WHERE Id = :list_ParentEmailMessages[0].RelatedToId AND RecordTypeId = :TicketUtil.ARDIUS_TICKET_RT_ID];
			if (!list_Tickets.isEmpty()) {
				return list_ParentEmailMessages[0];
			}
		}

		//Related Ticket is unidentified
		Ticket_Inbound_Email_Config__mdt objEmailConfig = getInboundEmailConfig(objInboundEmail);

		//Auto create a case If Config - Auto create enabled
		if (objEmailConfig != null && objEmailConfig.Auto_Create_Case_If_Unidentified_Thread__c) {
			Case objCase = createCase(objInboundEmail, objEmailConfig);
			return new EmailMessage(RelatedToId = objCase.Id);
		}

		//No configuration for unidentified Email message Or Auto Case create is disabled ==> Skip the message
		return null;
	}

	/**
	 * @description          Check If Email Have to be tracked
	 * @param objEmailThread Inbound Email
	 * @return               `Boolean`
	 */
	private static Boolean checkIfEmailMessageHaveToTrack(EmailMessage objEmailThread) {
		if (objEmailThread == null || String.isBlank(objEmailThread.RelatedToId)) {
			return false;
		}

		return true;
	}

	/**
	 * @description           Get Contacts/Users associated to the email Ids
	 * @param objInboundEmail Inbound Email
	 * @return                `Map<String, Id>`
	 */
	private static Map<String, Id> getSystemEmailRecipients(Messaging.InboundEmail objInboundEmail) {
		Set<String> set_Emails = new Set<String>();

		if (objInboundEmail.ccAddresses != null) {
			set_Emails.addAll(objInboundEmail.ccAddresses);
		}

		if (objInboundEmail.toAddresses != null) {
			set_Emails.addAll(objInboundEmail.toAddresses);
		}

		set_Emails.add(resolveFromAddress(objInboundEmail));

		Map<String, Id> map_EmailToRelatedId = new Map<String, Id>();

		//Find Contacts related to Email
		for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Email IN :set_Emails AND AccountId != NULL AND RecordTypeId IN :LIST_ALLOWED_CONTACT_RECORD_TYPES]) {
			map_EmailToRelatedId.put(objContact.Email, objContact.Id);
		}

		//Remove already identified Emails from Set
		set_Emails.removeAll(map_EmailToRelatedId.keySet());
		if (set_Emails.isEmpty()) {
			return map_EmailToRelatedId;
		}

		//Find Users related to Email
		for (User objUser : [SELECT Id, Email FROM User WHERE Email IN :set_Emails AND IsActive = TRUE]) {
			map_EmailToRelatedId.put(objUser.Email, objUser.Id);
		}
		return map_EmailToRelatedId;
	}

	/**
	 * @description                Create Email Message object
	 * @param objInboundEmail      Inbound Email
	 * @param objEmailThread       Thread Email
	 * @param map_EmailToRelatedId Map of Email to Related SObject Id
	 * @return                     `EmailMessage`
	 */
	private static EmailMessage createEmailMessage(Messaging.InboundEmail objInboundEmail, EmailMessage objEmailThread, Map<String, Id> map_EmailToRelatedId) {
		EmailMessage objMessage = new EmailMessage(
			FromAddress = resolveFromAddress(objInboundEmail),
			FromName = objInboundEmail.fromName,
			ToAddress = toStringArray(toMessageAddress(objInboundEmail.toAddresses, map_EmailToRelatedId)),
			ToIds = toArray(toMessageAddressIds(objInboundEmail.toAddresses, map_EmailToRelatedId)),
			CcAddress = toStringArray(toMessageAddress(objInboundEmail.ccAddresses, map_EmailToRelatedId)),
			CcIds = toArray(toMessageAddressIds(objInboundEmail.ccAddresses, map_EmailToRelatedId)),
			Subject = toLimitStr(objInboundEmail.subject, SUBJECT_MAX_LIMIT, null),
			HtmlBody = toLimitStr(objInboundEmail.htmlBody, BODY_MAX_LIMIT, TRUNCATED_IDENTIFIER),
			TextBody = toLimitStr(objInboundEmail.plainTextBody, BODY_MAX_LIMIT, TRUNCATED_IDENTIFIER),
			Headers = toLimitStr(toSerializedString(objInboundEmail.headers), HEADERS_MAX_LIMIT, null),
			RelatedToId = objEmailThread.RelatedToId,
			MessageIdentifier = objInboundEmail.messageId,
			ThreadIdentifier = objEmailThread.ThreadIdentifier,
			ClientThreadIdentifier = objEmailThread.ThreadIdentifier,
			ReplyToEmailMessageId = objEmailThread.Id,
			Incoming = true,
			Status = EMAIL_STATUS_SENT
		);

		String strRelatedToId = objEmailThread.RelatedToId == null ? '' : String.valueOf(objEmailThread.RelatedToId);
		if (strRelatedToId.startsWith(CaseUtils.CASE_ID_PREFIX)) {
			objMessage.ParentId = objEmailThread.RelatedToId;
			objMessage.Status = EMAIL_STATUS_READ;
		}

		EmailMessageTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;

		insert objMessage;

		EmailMessageTriggerHelper.skipTrigger = false;
		TaskTriggerHelper.skipTrigger = false;

		return objMessage;
	}

	/**
	 * @description           Resolve From Address  ReplyTo || From Address
	 *
	 * @param objInboundEmail Inbound Email
	 * @return                `String`
	 */
	private static String resolveFromAddress(Messaging.InboundEmail objInboundEmail) {
		return String.isBlank(objInboundEmail.replyTo) ? objInboundEmail.fromAddress : objInboundEmail.replyTo;
	}

	/**
	 * @description                Creates Email Message Relation
	 * @param objEmailMessage      Email Message created
	 * @param objInboundEmail      Inbound Email
	 * @param map_EmailToRelatedId Email To associated SObject
	 */
	private static void createEmailMessageRelations(EmailMessage objEmailMessage, Messaging.InboundEmail objInboundEmail, Map<String, Id> map_EmailToRelatedId) {
		List<EmailMessageRelation> list_MessageRelations = new List<EmailMessageRelation>();

		//From Address
		String strResolvedFromAddress = resolveFromAddress(objInboundEmail);
		if (map_EmailToRelatedId.containsKey(strResolvedFromAddress)) {
			list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, map_EmailToRelatedId.get(strResolvedFromAddress), RELATION_TYPE_FROM_ADDRESS));
		} else {
			list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, strResolvedFromAddress, RELATION_TYPE_FROM_ADDRESS));
		}

		//CC Addresses - related SObject Email & Ids
		Set<String> set_CCEmails = toMessageAddress(objInboundEmail.ccAddresses, map_EmailToRelatedId);
		if (set_CCEmails != null) {
			for (String strEmail : set_CCEmails) {
				list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, strEmail, RELATION_TYPE_CC_ADDRESS));
			}
		}

		Set<Id> set_CCRecipients = toMessageAddressIds(objInboundEmail.ccAddresses, map_EmailToRelatedId);
		if (set_CCRecipients != null) {
			for (Id idSObject : set_CCRecipients) {
				list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, idSObject, RELATION_TYPE_CC_ADDRESS));
			}
		}

		//To Addresses - related SObject Email & Ids
		Set<String> set_ToEmails = toMessageAddress(objInboundEmail.toAddresses, map_EmailToRelatedId);
		if (set_ToEmails != null) {
			for (String strEmail : set_ToEmails) {
				list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, strEmail, RELATION_TYPE_TO_ADDRESS));
			}
		}

		Set<Id> set_ToRecipients = toMessageAddressIds(objInboundEmail.toAddresses, map_EmailToRelatedId);
		if (set_ToRecipients != null) {
			for (Id idSObject : set_ToRecipients) {
				list_MessageRelations.add(toEmailMessageRelation(objEmailMessage.Id, idSObject, RELATION_TYPE_TO_ADDRESS));
			}
		}

		EmailMessageTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;

		insert list_MessageRelations;

		EmailMessageTriggerHelper.skipTrigger = false;
		TaskTriggerHelper.skipTrigger = false;
	}

	/**
	 * @description           Template - EmailMessageRelation
	 * @param idEmailMessage  Email Message Id
	 * @param strEmail        Relation - Email
	 * @param strRelationType Relation Type
	 * @return                `EmailMessageRelation`
	 */
	private static EmailMessageRelation toEmailMessageRelation(Id idEmailMessage, String strEmail, String strRelationType) {
		return new EmailMessageRelation(EmailMessageId = idEmailMessage, RelationAddress = strEmail, RelationType = strRelationType);
	}

	/**
	 * @description             Template - EmailMessageRelation
	 * @param idEmailMessage    Email Message Id
	 * @param idRelationSObject Relation - SObject
	 * @param strRelationType   Relation Type
	 * @return                  `EmailMessageRelation`
	 */
	private static EmailMessageRelation toEmailMessageRelation(Id idEmailMessage, Id idRelationSObject, String strRelationType) {
		return new EmailMessageRelation(EmailMessageId = idEmailMessage, RelationId = idRelationSObject, RelationType = strRelationType);
	}

	/**
	 * @description           Create Attachments and relate to Email Message
	 * @param objEmailMessage Email Message cerated
	 * @param objInboundEmail Inbound Email Message
	 * @return                `List<Id>`
	 */
	private static List<Id> createEmailAttachments(EmailMessage objEmailMessage, Messaging.InboundEmail objInboundEmail) {
		List<ContentVersion> list_ContentVersions = new List<ContentVersion>();
		if (objInboundEmail.binaryAttachments != null) {
			for (Messaging.InboundEmail.BinaryAttachment objBinaryAttachment : objInboundEmail.binaryAttachments) {
				list_ContentVersions.add(toContentVersion(objBinaryAttachment.fileName, objBinaryAttachment.body));
			}
		}

		if (objInboundEmail.textAttachments != null) {
			for (Messaging.InboundEmail.TextAttachment objTextAttachment : objInboundEmail.textAttachments) {
				list_ContentVersions.add(toContentVersion(objTextAttachment.fileName, Blob.valueOf(objTextAttachment.body)));
			}
		}

		if (list_ContentVersions.isEmpty()) {
			return null;
		}

		insert list_ContentVersions;

		List<ContentDocumentLink> list_ContentDocumentLinks = new List<ContentDocumentLink>();
		List<Id> list_ContentDocumentIds = new List<Id>();
		for (ContentVersion objContentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :list_ContentVersions]) {
			list_ContentDocumentLinks.add(toContentDocumentLink(objContentVersion.ContentDocumentId, objEmailMessage.Id));
			list_ContentDocumentIds.add(objContentVersion.ContentDocumentId);
		}

		insert list_ContentDocumentLinks;
		return list_ContentDocumentIds;
	}

	/**
	 * @description       Template - Content Version
	 * @param strFileName File Name
	 * @param blobData    Blob Data
	 * @return            `ContentVersion`
	 */
	private static ContentVersion toContentVersion(String strFileName, Blob blobData) {
		return new ContentVersion(Title = strFileName, PathOnClient = strFileName, VersionData = blobData);
	}

	/**
	 * @description             Template ContentDocumentLink
	 * @param idContentDocument Content Document Id
	 * @param idEntity          Link Entity Id
	 * @return                  `ContentDocumentLink`
	 */
	private static ContentDocumentLink toContentDocumentLink(Id idContentDocument, Id idEntity) {
		return new ContentDocumentLink(ContentDocumentId = idContentDocument, LinkedEntityId = idEntity, ShareType = DOC_SHARE_TYPE, Visibility = DOC_VISIBILITY);
	}

	/**
	 * @description                Returns Emails which are not associated to Any contacts/Users in the system
	 * @param list_Emails          List of Emails to check
	 * @param map_EmailToRelatedId Map of Emails associated to SObject in the system
	 * @return                     `Set<String>`
	 */
	private static Set<String> toMessageAddress(List<String> list_Emails, Map<String, Id> map_EmailToRelatedId) {
		if (list_Emails == null) {
			return null;
		}

		Set<String> set_Emails = new Set<String>(list_Emails);
		Set<String> set_EmailsInMap = map_EmailToRelatedId.keySet();

		set_Emails.removeAll(set_EmailsInMap);

		if (set_Emails.isEmpty()) {
			return null;
		}

		return set_Emails;
	}

	/**
	 * @description                Returns SObject Ids which are associated to Any contacts/Users in the system
	 * @param list_Emails          List of Emails to check
	 * @param map_EmailToRelatedId Map of Emails associated to SObject in the system
	 * @return                     `Set<Id>`
	 */
	private static Set<Id> toMessageAddressIds(List<String> list_Emails, Map<String, Id> map_EmailToRelatedId) {
		if (list_Emails == null) {
			return null;
		}

		Set<String> set_Emails = new Set<String>(list_Emails);
		Set<String> set_EmailsInMap = map_EmailToRelatedId.keySet();

		set_Emails.retainAll(set_EmailsInMap);

		if (set_Emails.isEmpty()) {
			return null;
		}

		Set<Id> set_SObjectIds = new Set<Id>();
		for (String strEmail : set_Emails) {
			set_SObjectIds.add(map_EmailToRelatedId.get(strEmail));
		}

		return set_SObjectIds;
	}

	/**
	 * @description      Convert into String Array - Comma separated String
	 * @param set_Source Set of String
	 * @return           `String`
	 */
	private static String toStringArray(Set<String> set_Source) {
		if (set_Source == null) {
			return null;
		}

		return String.join(new List<String>(set_Source), ',');
	}

	/**
	 * @description      Convert into String Array - Comma separated String
	 * @param set_Source Set of Ids
	 * @return           `String`
	 */
	private static String toStringArray(Set<Id> set_Source) {
		if (set_Source == null) {
			return null;
		}

		List<String> list_Source = new List<String>();
		for (Id idValue : set_Source) {
			list_Source.add(String.valueOf(idValue));
		}

		return String.join(list_Source, ',');
	}

	/**
	 * @description      Convert a Set<Id> into Id Array
	 *
	 * @param set_Source Set of String
	 * @return           `List<Id>`
	 */
	private static List<Id> toArray(Set<Id> set_Source) {
		if (set_Source == null) {
			return null;
		}

		return new List<Id>(set_Source);
	}

	/**
	 * @description    To JSON Serialized format
	 * @param objValue Object
	 * @return         `String`
	 */
	private static String toSerializedString(Object objValue) {
		if (objValue == null) {
			return null;
		}

		return JSON.serialize(objValue);
	}

	/**
	 * @description                  Truncate a String If it crosses the limit and add identification
	 * @param strSource              Source String
	 * @param intLimit               Limit
	 * @param strTruncatedIdentifier String identifier concatenated If Truncated
	 * @return                       `String`
	 */
	private static String toLimitStr(String strSource, Integer intLimit, String strTruncatedIdentifier) {
		if (String.isBlank(strSource) || strSource.length() <= intLimit) {
			return strSource;
		}

		strTruncatedIdentifier = String.isBlank(strTruncatedIdentifier) ? '' : strTruncatedIdentifier;
		return strSource.left(intLimit - strTruncatedIdentifier.length()) + strTruncatedIdentifier;
	}

	/**
	 * @description                 Create case from Inbound email information
	 * @param objInboundEmail       Inbound Email object
	 * @param objEmailServiceConfig Email service configuration object
	 * @return                      `Case`
	 */
	private static Case createCase(Messaging.InboundEmail objInboundEmail, Ticket_Inbound_Email_Config__mdt objEmailServiceConfig) {
		Contact objContact = getRelatedContact(resolveFromAddress(objInboundEmail));

		Case objCase = new Case(
			RecordTypeId = CaseUtils.RECTYPE_R_D_TAX_CREDITS,
			Status = objEmailServiceConfig.Case_Status__c,
			Origin = objEmailServiceConfig.Case_Origin__c,
			Subject = toLimitStr(objInboundEmail.subject, CASE_SUBJECT_MAX_LIMIT, null),
			Description = toLimitStr(objInboundEmail.plainTextBody, CASE_BODY_MAX_LIMIT, null),
			SuppliedEmail = resolveFromAddress(objInboundEmail),
			SuppliedName = objInboundEmail.FromName,
			ContactId = objContact?.Id,
			AccountId = objContact?.AccountId,
			OwnerId = resolveCaseOwnerId(objEmailServiceConfig)
		);

		insert objCase;
		return objCase;
	}

	/**
	 * @description    Get Case related contact
	 * @param strEmail Email to check for Contacts
	 * @return         `Contact`
	 */
	private static Contact getRelatedContact(String strEmail) {
		if (String.isBlank(strEmail)) {
			return null;
		}

		List<Contact> list_Contacts = [SELECT Id, Email, AccountId FROM Contact WHERE Email = :strEmail AND AccountId != NULL AND RecordTypeId IN :LIST_ALLOWED_CONTACT_RECORD_TYPES LIMIT 1];
		if (list_Contacts.isEmpty()) {
			return null;
		}

		return list_Contacts[0];
	}

	/**
	 * @description           Update Communication Status If the message related to Ticket
	 * @param objEmailMessage Email Message processed
	 */
	private static void updateCommunicationStatus(EmailMessage objEmailMessage) {
		if (objEmailMessage.RelatedToId == null || !String.valueOf(objEmailMessage.RelatedToId).startsWithIgnoreCase(TaskUtil.TICKET_PREFIX)) {
			return;
		}

		update new Ticket__c(Id = objEmailMessage.RelatedToId, Communication_Status__c = TicketUtil.COMM_STATUS_RESPONSE_RECEIVED, Unresponsive__c = false);
	}

	/**
	 * @description           Find inbound email configuration.
	 * If a  config with same email found then same will be return, else return default config(could be null)
	 * @param objInboundEmail Inbound email
	 * @return                `Ticket_Inbound_Email_Config__mdt`
	 */
	private static Ticket_Inbound_Email_Config__mdt getInboundEmailConfig(Messaging.InboundEmail objInboundEmail) {
		Ticket_Inbound_Email_Config__mdt objDefaultConfig = null;
		List<String> list_ToAddresses = objInboundEmail.toAddresses == null ? new List<String>() : objInboundEmail.toAddresses;
		Set<String> set_ToAddresses = new Set<String>();

		for (String strToAddress : list_ToAddresses) {
			set_ToAddresses.add(strToAddress.toLowerCase());
		}

		for (Ticket_Inbound_Email_Config__mdt objConfig : Ticket_Inbound_Email_Config__mdt.getAll().values()) {
			if (String.isNotBlank(objConfig.Inbound_Email__c) && set_ToAddresses.contains(objConfig.Inbound_Email__c.toLowerCase())) {
				return objConfig;
			}

			if (objConfig.Is_Default_Configuration__c) {
				objDefaultConfig = objConfig;
			}
		}

		return objDefaultConfig;
	}

	/**
	 * @description                 Return Auto create - case owner based on config
	 * @param objEmailServiceConfig Email Configuration
	 * @return                      `Id` QueueId/User Id If found in config, else current user Id
	 */
	private static Id resolveCaseOwnerId(Ticket_Inbound_Email_Config__mdt objEmailServiceConfig) {
		if (String.isNotBlank(objEmailServiceConfig.Case_Owner_User_Id__c)) {
			return objEmailServiceConfig.Case_Owner_User_Id__c;
		}

		if (String.isNotBlank(objEmailServiceConfig.Case_Owner_Queue_Name__c)) {
			Map<String, Group> map_Groups = GlobalQueryHelper.getAllQueuesByDevNameMap();
			if (map_Groups.containsKey(objEmailServiceConfig.Case_Owner_Queue_Name__c)) {
				return map_Groups.get(objEmailServiceConfig.Case_Owner_Queue_Name__c).Id;
			}
		}

		return UserInfo.getUserId();
	}
}