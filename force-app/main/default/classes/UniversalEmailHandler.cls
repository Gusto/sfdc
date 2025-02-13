/**
 * @name         UniversalEmailHandler
 * @author       Sanjay Paryani
 * @date         01/16/2020
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 **/
global class UniversalEmailHandler implements Messaging.InboundEmailHandler {
	//Variables & Collections
	Boolean blnIsCustomerEmail = false;
	String strEmailBody = '';
	String strTempMatch = '';
	String strMatch = '';
	String strRegexReplacement = '';
	List<Account> list_MatchedAccounts;
	Boolean blnIsCarrierOpsEmail = false;
	Boolean blnIsFromGustoEmail = false;
	Boolean blnIsCommonSubjectFound = false;
	Boolean blnIgnoreEmail = false;
	Boolean blnIsFromAddressIgnored = false;
	List<Email_Message__c> list_EmailMessagesToInsert;
	public static Set<String> set_SkipEmails = new Set<String>();
	public static Set<String> set_ProcessEmails = new Set<String>();

	static {
		List<Benefit_Operations_Email_Handling__mdt> list_BenefitOpsMetadata = EmailMessageUtil.getBenefitOpsMetadata();
		if (list_BenefitOpsMetadata != null && list_BenefitOpsMetadata.size() > 0) {
			if (String.isNotBlank(list_BenefitOpsMetadata[0].Skip_Email_for_Universal_Inbox__c)) {
				for(String strValue :list_BenefitOpsMetadata[0].Skip_Email_for_Universal_Inbox__c.split(';')) {
					set_SkipEmails.add(strValue.trim());
				}
			}

			if (String.isNotBlank(list_BenefitOpsMetadata[0].Process_Email_for_Universal_Inbox__c)) {
				for(String strValue :list_BenefitOpsMetadata[0].Process_Email_for_Universal_Inbox__c.split(';')) {
					set_ProcessEmails.add(strValue.trim());
				}
			}
		}
	}

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		try {
			list_EmailMessagesToInsert = new List<Email_Message__c>();
			Email_Message__c objEmailMessage = new Email_Message__c();
			objEmailMessage.Message_Identifier__c = email.messageId;

			if (
				(email.toAddresses != null &&
				email.ccAddresses == null &&
				validCarrierOpsEmail(email.toAddresses) &&
				!checkSkipEmail(email.toAddresses)) ||
				(email.ccAddresses != null &&
				email.toAddresses == null &&
				validCarrierOpsEmail(email.ccAddresses) &&
				!checkSkipEmail(email.ccAddresses)) ||
				(email.ccAddresses != null &&
				email.toAddresses != null &&
				!checkSkipEmail(email.toAddresses) &&
				!checkSkipEmail(email.ccAddresses) &&
				(validCarrierOpsEmail(email.toAddresses) || validCarrierOpsEmail(email.ccAddresses)))
			) {
				objEmailMessage.Inbox_Type__c = 'Carrier_Ops';
				blnIsCarrierOpsEmail = true;
				Integer intCounter = 0;
				if (email.toAddresses != null) {
					objEmailMessage.To_Addresses__c = '';
					while (email.toAddresses.size() > intCounter) {
						String strToAddress = email.toAddresses.get(intCounter);
						if (!set_ProcessEmails.contains(strToAddress)) {
							objEmailMessage.To_Addresses__c = objEmailMessage.To_Addresses__c + strToAddress + ';';
						}
						intCounter++;
					}
					objEmailMessage.To_Addresses__c = objEmailMessage.To_Addresses__c.trim().left(255);
				}

				if (email.ccAddresses != null) {
					intCounter = 0;
					objEmailMessage.CC_Address__c = '';
					while (email.ccAddresses.size() > intCounter) {
						String strCcAddress = email.ccAddresses.get(intCounter);
						if (!set_ProcessEmails.contains(strCcAddress)) {
							objEmailMessage.CC_Address__c = objEmailMessage.CC_Address__c + strCcAddress + ';';
						}
						intCounter++;
					}
					objEmailMessage.CC_Address__c = objEmailMessage.CC_Address__c.trim().left(255);
				}
			}

			if (blnIsCarrierOpsEmail) {
				if (email.plainTextBody != null) {
					strEmailBody = email.plainTextBody;
				} else if (email.htmlBody != null) {
					strEmailBody = email.htmlBody.stripHtmlTags();
				}
				objEmailMessage.From_Name__c = email.fromName;
				objEmailMessage.From_Addresses__c = email.replyTo;

				// Calls method to check for customer contacts matching from address of inbound emails
				blnIsCustomerEmail = EmailMessageHelperFunctions.checkForCustomerEmails(email.fromAddress, objEmailMessage);
				// Calls method to check for from address containing any gusto domain for inbound emails
				blnIsFromGustoEmail = EmailMessageHelperFunctions.checkForGustoEmails(email.fromAddress, email.replyTo, objEmailMessage);
				// Calls method to check for any from address to be ignored
				blnIsFromAddressIgnored = EmailMessageHelperFunctions.checkForFromAddressesToIgnore(email.fromAddress, email.replyTo, objEmailMessage);

				if (String.isNotBlank(email.subject)) {
					objEmailMessage.Subject__c = email.subject.left(255);
					//Only if the email is not a customer email or Gusto email then process it further else ignore it.
					//Also check for any from address to be ignored and skip it.
					if (!blnIsCustomerEmail && !blnIsFromGustoEmail && !blnIsFromAddressIgnored) {
						//doPatternMatching(email.subject, objEmailMessage);
						strMatch = EmailMessageHelperFunctions.doPatternMatching(email.subject, objEmailMessage, blnIgnoreEmail, strTempMatch, strEmailBody);
					}
				}
				// Calls method to match the processed string strMatch with any Accounts in the system
				doAccountMatching(strMatch, objEmailMessage);

				if (email.htmlBody != null) {
					String strHtmlTextBody = EmailMessageHelperFunctions.replaceBase64URLFromHTMLBody(email.htmlBody.left(131072));
					objEmailMessage.HTML_Text_Body__c = strHtmlTextBody.left(131072);
					objEmailMessage.Text_Body_Long__c = strHtmlTextBody.left(131072);
				} else if (email.htmlBody == null && email.plainTextBody != null) {
					objEmailMessage.HTML_Text_Body__c = email.plainTextBody.left(131072);
					objEmailMessage.Text_Body_Long__c = email.plainTextBody.left(131072);
				}

				objEmailMessage.Text_Body__c = EmailMessageHelperFunctions.replaceBase64URLFromHTMLBody(strEmailBody.left(131072));
				if (String.isNotBlank(objEmailMessage.Text_Body__c)) {
					objEmailMessage.Text_Body_Chunk_1__c = objEmailMessage.Text_Body__c.trim().left(255);
				}
				list_EmailMessagesToInsert.add(objEmailMessage);

				if (list_EmailMessagesToInsert.size() > 0) {
					CustomEmailMessageTriggerHelper.blnIsCarrierOpsEmail = true;
					insert list_EmailMessagesToInsert;
					CustomEmailMessageTriggerHelper.blnIsCarrierOpsEmail = false;
				}
				processAttachments(email, objEmailMessage);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UniversalEmailHandler', 'handleInboundEmail', ex.getMessage(), ex.getStackTraceString());
		}

		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		return result;
	}

	// Method will match the processed string with any Accounts in the system
	public void doAccountMatching(String strInputMatch, Email_Message__c objEmailMessage) {
		//Subject Like :('%' + strInputMatch + '%')
		if (String.isNotBlank(strInputMatch)) {
			strInputMatch = strInputMatch.toLowerCase();
			list_MatchedAccounts = new List<Account>();
			list_MatchedAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE :(strInputMatch + '%')];
			if (list_MatchedAccounts.size() == 1) {
				objEmailMessage.Account__c = list_MatchedAccounts.get(0).Id;
			} else if (list_MatchedAccounts.size() > 1) {
				Integer intCounter = 0;
				objEmailMessage.Account_List__c = '';
				while (list_MatchedAccounts.size() > intCounter && intCounter < 12) {
					objEmailMessage.Account_List__c = objEmailMessage.Account_List__c + list_MatchedAccounts.get(intCounter).id + ';';
					intCounter++;
				}
			}
		}
	}

	// Method will process attachments from inbound emails.
	public void processAttachments(Messaging.InboundEmail email, Email_Message__c objEmailMessage) {
		List<Attachment> list_Attachments = new List<Attachment>();
		if (email.binaryAttachments != null) {
			for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments) {
				Attachment objAttachment = new Attachment();
				objAttachment.Body = binaryAttachment.body;
				objAttachment.Name = binaryAttachment.fileName;
				objAttachment.ContentType = binaryAttachment.mimeTypeSubType;
				objAttachment.ParentId = objEmailMessage.Id;
				list_Attachments.add(objAttachment);
			}
		}
		if (email.textAttachments != null) {
			for (Messaging.InboundEmail.TextAttachment textAttachment : email.textAttachments) {
				Attachment objAttachment = new Attachment();
				objAttachment.Body = Blob.valueOf(textAttachment.body);
				objAttachment.Name = textAttachment.fileName;
				objAttachment.ContentType = textAttachment.mimeTypeSubType;
				objAttachment.ParentId = objEmailMessage.Id;
				list_Attachments.add(objAttachment);
			}
		}
		if (list_Attachments.size() > 0) {
			insert list_Attachments;
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Skip email to process by UniversalEmailHandler class.
	 * @Parm        : List of email address
	 * @Return      : Boolean
	 */
	public static Boolean checkSkipEmail(List<String> list_Emails) {
		Boolean blnSkipFlag = false;
		if (list_Emails?.size() > 0) {
			for (String strEmail : list_Emails) {
				strEmail = strEmail.trim().toLowerCase();
				if (set_SkipEmails.contains(strEmail)) {
					blnSkipFlag = true;
					break;
				}
			}
		}

		return blnSkipFlag;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Valid Carrier Ops Email or not.
	 * @Parm        : List of email address
	 * @Return      : Boolean
	 */
	public static Boolean validCarrierOpsEmail(List<String> list_Emails) {
		Boolean blnValidFlag = false;
		if (list_Emails?.size() > 0) {
			for (String strEmail : list_Emails) {
				strEmail = strEmail.trim().toLowerCase();
				if (set_ProcessEmails.contains(strEmail)) {
					blnValidFlag = true;
					break;
				}
			}
		}

		return blnValidFlag;
	}
}