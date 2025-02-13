/**
 * @name         : RecoveryInboundEmailService
 * @author       : Alex Xiong
 * @date         : 06-29-2021
 * @description  : RecoveryInboundEmailServiceTest
**/

global class RecoveryInboundEmailService implements Messaging.InboundEmailHandler {
	public static final String RECOVERY_EMAIL = 'recovery@gusto.com';
	public static final String KEY_PREFIX = 'zenpayroll-payroll-';
	public static final String CONTRACTOR_PAYMENT_GROUP_PREFIX = 'zenpayroll-contractor-payment-';
	public static final String INTERNATIONAL_CONTRACTOR_PAYMENT_PREFIX = 'zenpayroll-international-contractor-payment-';
	public static final String RECOVERY_NON_ACTIONABLE_QUEUE = 'Recovery Cases - Non-actionable';
	public static final String RECOVERY_CASE_QUEUE = 'Recovery Case';
	public static final String DUPLICATE_INTEGRATION_KEY_MSG = 'duplicate value found: Integration_Key__c';

	public static Boolean blnToRecoveryEmail = false;
	public static String strDebug = '';

	global Messaging.InboundEmailResult handleInboundEmail(
		Messaging.InboundEmail objEmail,
		Messaging.InboundEnvelope objEnvelope
	) {
		strDebug += 'handleInboundEmail start \n';
		String strBody = '';

		if (String.isNotBlank(objEmail.HtmlBody)) {
			strBody = objEmail.HtmlBody;
		} else if (String.isNotBlank(objEmail.PlainTextBody)) {
			strBody = objEmail.PlainTextBody;
		}

		String strCaseRef = getCaseReference(strBody);
		Case objCase = new Case();
		String strParentId;
		String strToAddresses;
		String strRecoveryEmailAddress = Label.Recovery_Case_Email_Service_Address;

		strDebug += 'strCaseRef: ' + strCaseRef + '\n';

		if (objEmail.FromName.equalsIgnoreCase(RECOVERY_EMAIL)) {
			strDebug += 'blnToRecoveryEmail = false \n';
			blnToRecoveryEmail = false;
		}

		if (objEmail.ToAddresses != null) {
			strToAddresses = String.valueOf(objEmail.ToAddresses).toLowerCase();

			if (
				(String.isNotBlank(strRecoveryEmailAddress) &&
				strToAddresses.indexof(strRecoveryEmailAddress.toLowerCase()) > -1)
			) {
				strDebug += 'blnToRecoveryEmail = true \n';
				blnToRecoveryEmail = true;
			}
		}

		/*
        BY: PR, Date: 6/25/19,
        Desc: For “to” scenario even if Nacha(any nacha - no error code filter) is present “Create Case” and assign nacha to that case 
        For "From" scenario if Case is not present and Nacha( with error code=R01) is present Assign email to nacha, if nacha is not present 
        then create case.
        */

		/**
		 * if email has a case reference, find a case with it.
		 * if no case was found, if the email is FROM recovery@gusto.com, then email's parent = Nacha record
		 * if there is a case already then the email's parent will be the Case
		 */
		if (String.isNotBlank(strCaseRef)) {
			objCase = getCaseInformation(strCaseRef);

			if (objCase == null || objCase.Id == null) {
				if (!blnToRecoveryEmail) {
					strParentId = checkR01NachaEntry(strCaseRef);
					strDebug += '!blnToRecoveryEmail, strParentId: ' + strParentId + '\n';
				}
			} else {
				strParentId = objCase.Id;
				strDebug += 'objCase is not null. blnToRecoveryEmail, strParentId: ' + strParentId + '\n';
			}
		}

		/**
		 * if no parent was still found, create the case then set the email's parent to it
		 * if email is to recovery@gusto then assign this case to a nacha entry return
		 * with the same event Id
		 */
		if (String.isBlank(strParentId)) {
			objCase = createCase(objEmail, strCaseRef);
			strParentId = objCase.Id;
			if (blnToRecoveryEmail || Test.isRunningTest()) {
				assignNewCaseToNachaEntry(strParentId, strCaseRef);
			}
		}

		if (String.isNotBlank(strParentId)) {
			EmailMessage objMsg = new EmailMessage();
			String strCCAddress = '';

			if (objEmail.ccAddresses != null) {
				for (String strAddress : objEmail.ccAddresses) {
					if (strCCAddress != '') {
						strCCAddress += '; ';
					}
					strCCAddress += strAddress;
				}
			}

			objMsg.CcAddress = strCCAddress;
			objMsg.FromAddress = objEmail.FromAddress;
			objMsg.FromName = objEmail.FromName;
			objMsg.Headers = '' + objEmail.headers;
			objMsg.HtmlBody = objEmail.HtmlBody?.left(131000);
			objMsg.TextBody = objEmail.PlainTextBody?.left(131000);
			objMsg.Subject = objEmail.Subject;

			if (String.isNotBlank(strParentId)) {
				if (strParentId.indexOf('500') == 0) {
					objMsg.ParentId = strParentId;
				} else {
					objMsg.RelatedToId = strParentId;
				}
			}

			String strToAddress = '';
			if (objEmail.ToAddresses != null) {
				for (String strAddress : objEmail.ToAddresses) {
					if (strToAddress != '') {
						strToAddress += '; ';
					}
					strToAddress += strAddress;
				}
			}

			objMsg.ToAddress = strToAddress;
			objMsg.Incoming = true;

			try {
				insert objMsg;
				List<Attachment> list_Attachments = new List<Attachment>();
				if (objEmail.binaryAttachments != null) {
					for (Messaging.InboundEmail.BinaryAttachment objAttach : objEmail.binaryAttachments) {
						Attachment attch = new Attachment();
						attch.Body = objAttach.body;
						attch.Name = objAttach.fileName;
						attch.ContentType = objAttach.mimeTypeSubType;
						attch.ParentId = objMsg.Id;
						list_Attachments.add(attch);
					}
				}

				if (objEmail.textAttachments != null) {
					for (Messaging.InboundEmail.TextAttachment objAttach : objEmail.textAttachments) {
						Attachment attch = new Attachment();
						attch.Body = Blob.valueOf(objAttach.body);
						attch.Name = objAttach.fileName;
						attch.ContentType = objAttach.mimeTypeSubType;
						attch.ParentId = objMsg.Id;
						list_Attachments.add(attch);
					}
				}

				if (list_Attachments.size() > 0) {
					insert list_Attachments;
				}
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RecoveryInboundEmailService',
					'handleInboundEmail',
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
		}

		Messaging.InboundEmailResult objResult = new Messaging.InboundEmailresult();
		return objResult;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : Takes case reference and finds a Recovery Case with that integration key or Case Reference.
	 *                If a Case is found and does not have a parent, make sure Status = Open. 
	 *                If Case has a parent, return the parent.
	 * @Parm        : strCaseRef - Case Reference from email body
	 * @Return      : A Case or null
	 **/
	public static Case getCaseInformation(String strCaseRef) {
		strDebug += 'getCaseInformation() start \n';
		List<Case> list_CasesToUpdate = new List<Case>();
		Case objCaseRec = new Case();
		String strIntegrationKey = strCaseRef.replace('ref:_', '').replace(':ref', '');
		strIntegrationKey = strIntegrationKey.trim();

		strDebug += 'strIntegrationKey: ' + strIntegrationKey + '\n';

		Map<String, Case> map_Cases = new Map<String, Case>();
		for (Case objCase : [SELECT Id, IsClosed, Case_Reference__c, Integration_Key__c, ParentId FROM Case WHERE (Case_Reference__c = :strCaseRef OR Integration_Key__c = :strIntegrationKey) AND RecordTypeId = :CaseUtils.RECTYPE_RECOVERY ORDER BY CreatedDate ASC]) {
			map_Cases.put(objCase.Case_Reference__c, objCase);
			map_Cases.put(objCase.Integration_Key__c, objCase);
		}

		strDebug += 'map_Cases: ' + JSON.serialize(map_Cases) + '\n';

		if (map_Cases.size() > 0) {
			objCaseRec = map_Cases.containsKey(strCaseRef) ? map_Cases.get(strCaseRef) : map_Cases.get(strIntegrationKey);
			
			strDebug += 'objCaseRec: ' + JSON.serialize(objCaseRec) + '\n';

			if (objCaseRec?.ParentId == null) {
				if (objCaseRec?.IsClosed == true) {
					objCaseRec.Status = 'Open';
					list_CasesToUpdate.add(objCaseRec);
				}
			} else {
				if (objCaseRec?.IsClosed == false) {
					objCaseRec.Status = 'Closed';
					list_CasesToUpdate.add(objCaseRec);
				}

				objCaseRec = new Case(Id = objCaseRec.ParentId);
			}

			try {
				update list_CasesToUpdate;
			} catch (Exception ex) {
				ExceptionLogUtil.logException(
					'RecoveryInboundEmailService',
					'getCaseInformation',
					ex.getMessage(),
					ex.getStackTraceString()
				);
			}
			
			strDebug += 'map_Cases.size() > 0 \n';
			strDebug += 'objCaseRec: ' + objCaseRec + '\n';
			return objCaseRec;
		} else {
			strDebug += 'map_Cases is empty \n';
			return null;
		}
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : This method takes the email body and gets the Integration Key
	 * @Parm        : strBody - Email's text body
	 * @Return      : The Integration Key
	 **/
	public static String getCaseReference(String strBody) {
		String strRecordInfo = '';
		Integer intStartingIndex = strBody?.indexOf('ref:_');
		Integer intEndingIndex = strBody?.IndexOf(':ref', intStartingIndex);

		try {
			if (
				intStartingIndex > -1 &&
				intEndingIndex > -1 &&
				intEndingIndex > intStartingIndex &&
				(intEndingIndex - intStartingIndex) > 0 &&
				(intEndingIndex - intStartingIndex) < 100
			) {
				strRecordInfo = strBody.substring(intStartingIndex, intEndingIndex + 4);
				strRecordInfo = strRecordInfo.trim();
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException(
				'RecoveryInboundEmailService',
				'getCaseReference',
				ex.getMessage(),
				ex.getStackTraceString()
			);
		}
		return strRecordInfo;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : This takes an Inbound Email then inserts a Case
	 * @Parm        : objEmail - the Inbound Email record
	 *                strRef - Case reference string to use as Case's Integration Key
	 * @Return      : The Case object inserted
	 **/
	public static Case createCase(Messaging.InboundEmail objEmail, String strRef) {
		List<Contact> list_Contact = [
			SELECT Id
			FROM Contact
			WHERE Email = :objEmail.FromAddress
			ORDER BY RecordType.Name ASC
		];

		String strNonRecoveryActionableQueueId = GlobalQueryHelper.getQueueIdByName(RECOVERY_NON_ACTIONABLE_QUEUE);
		String strRecoveryCaseQueueId = GlobalQueryHelper.getQueueIdByName(RECOVERY_CASE_QUEUE);
		String strRecoveryCasesNonActionableEmailBody = Label.Engagement_Recovery_Cases_Non_Actionable_Email_Body;

		Case objCase = new Case();
		objCase.Subject = objEmail.Subject;

		if (
			!blnToRecoveryEmail &&
			((String.isNotBlank(objEmail.HtmlBody) && 
			objEmail?.HtmlBody?.contains(strRecoveryCasesNonActionableEmailBody)) ||
			(String.isNotBlank(objEmail.PlainTextBody) && 
			objEmail?.PlainTextBody?.contains(strRecoveryCasesNonActionableEmailBody)))
		) {
			objCase.OwnerId = strNonRecoveryActionableQueueId;
		} else {
			objCase.OwnerId = strRecoveryCaseQueueId;
		}

		if (String.isNotBlank(objEmail.PlainTextBody)) {
			objCase.Description = objEmail.PlainTextBody.left(32000);
		} else if (String.isNotBlank(objEmail.HtmlBody)) {
			objCase.Description = objEmail.HtmlBody.left(32000);
		}

		if (list_Contact.size() > 0) {
			objCase.ContactId = list_Contact[0].Id;
		} else {
			objCase.SuppliedEmail = objEmail.FromAddress;
		}
		objCase.Integration_Key__c = strRef.replace('ref:_', '').replace(':ref', '');
		objCase.Origin = 'Email';
		objCase.RecordTypeId = cache.getRecordTypeId('Case', 'Recovery Cases');

		try {
			insert objCase;
		} catch (exception ex) {
			if (!ex.getMessage().contains(DUPLICATE_INTEGRATION_KEY_MSG)) {
				ExceptionLogUtil.logException(
					'RecoveryInboundEmailService',
					'createCase',
					ex.getMessage(),
					ex.getStackTraceString() + '\n' + strDebug
				);
			}
		}

		return objCase;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : This takes a Case Reference/Event Id and finds a R01 Nacha record
	 * 				  Do a query for ZP Nacha with a Nacha subquery.
	 * 				  The one with no Nacha should be reprocessed then use that Nacha for
	 * 				  the remainder of this process.
	 * @Parm        : strCaseRef - the Case Reference/Event Id
	 * @Return      : a Nacha record's Id
	 **/
	public static String checkR01NachaEntry(String strCaseRef) {
		if (String.isNotBlank(strCaseRef)) {
			String strEventId = strCaseRef;
			strEventId = strEventId.replace('ref:_', '').replace(':ref', '');
			if (strEventId.indexOf(KEY_PREFIX) > -1) {
				strEventId = strEventId.replace(KEY_PREFIX, ' ');
				strEventId = strEventId.trim();
			} else if (strEventId.indexOf(CONTRACTOR_PAYMENT_GROUP_PREFIX) > -1) {
				strEventId = strEventId.replace(CONTRACTOR_PAYMENT_GROUP_PREFIX, ' ');
				strEventId = strEventId.trim();
			} else if (strEventId.indexOf(INTERNATIONAL_CONTRACTOR_PAYMENT_PREFIX) > -1) {
				strEventId = strEventId.replace(INTERNATIONAL_CONTRACTOR_PAYMENT_PREFIX, ' ');
				strEventId = strEventId.trim();
			}
			
			List<ZP_Nacha_Entry_Returns__c> list_ZPNachasToReprocess = new List<ZP_Nacha_Entry_Returns__c>();
			List<ZP_Nacha_Entry_Returns__c> list_ZPNWithNachas = [
				SELECT
					Id,
					Event_Id__c,
					Transaction_Type__c,
					Amount__c,
					Error_Code__c,
					Case_Id__c,
					Expedite_Reason__c,
					Company_Id__c,
					Event_Type__c,
					Id__c,
					External_Key__c,
					Created_At__c,
					Error_Code_Description__c,
					Nacha_Entry_Id__c,
					Return_Code_At__c,
					Updated_At__c,
					Processing_State__c,
					(SELECT Id FROM Nacha_Entry_Returns__r)
				FROM ZP_Nacha_Entry_Returns__c
				WHERE
					Event_Id__c = :strEventId
					AND Error_Code__c LIKE '%R01%'
					AND Id NOT IN (SELECT ZP_Nacha_Entry_Return__c FROM Nacha_Entry_Return__c)
				ORDER BY CreatedDate DESC
			];

			//go through zp nachas and process ones without nacha
			if (!list_ZPNWithNachas.isEmpty()) {
				for (ZP_Nacha_Entry_Returns__c objZP : list_ZPNWithNachas) {
					if (objZP.Nacha_Entry_Returns__r.isEmpty()) {
						list_ZPNachasToReprocess.add(objZP);
					}
				}
			}

			if (!list_ZPNachasToReprocess.isEmpty()) {
				ZPNachaEntryReturnsTriggerHelper objHelper = new ZPNachaEntryReturnsTriggerHelper();
				ZPNachaEntryReturnsTriggerHelper.skipTrigger = true;
				objHelper.processInformation(list_ZPNachasToReprocess);
				update list_ZPNachasToReprocess;
			}

			List<Nacha_Entry_Return__c> list_Nacha = [
				SELECT Id
				FROM Nacha_Entry_Return__c
				WHERE Event_ID__c = :strEventId AND Error_Code__c LIKE '%R01%'
				ORDER BY CreatedDate DESC
			];

			if (!list_Nacha.isEmpty()) {
				return list_Nacha.get(0).Id;
			}
		}
		return null;
	}

	/**
	 * @Author      : Alex Xiong
	 * @Description : This takes a Case Id and Event Id, searches for a Nacha Entry Return with the same Event Id and no Case.
	 *                If one is found, associate that Nacha Entry Return to the provided Case
	 * @Parm        : strCaseId - A Case Id
	 *                strEventId - A Case Reference/Event Id
	 * @Return      : N/A
	 **/
	public void assignNewCaseToNachaEntry(String strCaseId, String strEventId) {
		if (String.isNotBlank(strCaseId) && String.isNotBlank(strEventId)) {
			list<Nacha_Entry_Return__c> list_NachaRecordsToUpdate = new List<Nacha_Entry_Return__c>();
			strEventId = strEventId.replace('ref:_', '').replace(':ref', '');

			if (strEventId.indexOf(KEY_PREFIX) > -1) {
				strEventId = strEventId.replace(KEY_PREFIX, ' ');
				strEventId = strEventId.trim();
			} else if (strEventId.indexOf(CONTRACTOR_PAYMENT_GROUP_PREFIX) > -1) {
				strEventId = strEventId.replace(CONTRACTOR_PAYMENT_GROUP_PREFIX, ' ');
				strEventId = strEventId.trim();
			} else if (strEventId.indexOf(INTERNATIONAL_CONTRACTOR_PAYMENT_PREFIX) > -1) {
				strEventId = strEventId.replace(INTERNATIONAL_CONTRACTOR_PAYMENT_PREFIX, ' ');
				strEventId = strEventId.trim();
			}

			for (Nacha_Entry_Return__c objNacha : [
				SELECT Id, Case__c
				FROM Nacha_Entry_Return__c
				WHERE Event_ID__c = :strEventId AND Case__c = NULL
			]) {
				objNacha.Case__c = strCaseId;
				list_NachaRecordsToUpdate.add(objNacha);
			}

			if (list_NachaRecordsToUpdate.size() > 0) {
				try {
					update list_NachaRecordsToUpdate;
				} catch (exception ex) {
					ExceptionLogUtil.logException(
						'RecoveryInboundEmailService',
						'assignNewCaseToNachaEntry',
						ex.getMessage(),
						ex.getStackTraceString()
					);
				}
			}
		}
	}
}