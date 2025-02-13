global class NanorepInboundEmailService implements Messaging.InboundEmailHandler {
	private static String companyId = '';
	private static String firmId = '';
	private static String userId = '';
	private static String emailAddress = '';
	private static String userName = '';
	private static String subject = '';

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		String body = '';

		if (email.htmlBody != null) {
			body = email.htmlBody;
		} else if (email.plainTextBody != null) {
			body = email.plainTextBody;
		}

		try {
			Case c = new Case();

			c = createCase(email);

			EmailMessage msg = new EmailMessage();
			String ccaddr = '';

			if (email.ccAddresses != null) {
				for (String str : email.ccAddresses) {
					if (ccaddr != '') {
						ccaddr += '; ';
					}
					ccaddr += str;
				}
			}

			msg.CcAddress = ccaddr;
			msg.FromAddress = emailAddress;
			msg.FromName = userName;
			msg.Headers = '' + email.headers;
			msg.TextBody = getParsedText(body);
			msg.Subject = subject;
			if (c != null && c.Id != null) {
				msg.ParentId = c.Id;
			}
			String toaddr = '';
			if (email.toAddresses != null) {
				for (String str : email.toAddresses) {
					if (toaddr != '') {
						toaddr += '; ';
					}
					toaddr += str;
				}
			}

			msg.Incoming = true;
			insert msg;
			List<Attachment> attachmentList = new List<Attachment>();
			if (email.binaryAttachments != null) {
				for (Messaging.InboundEmail.BinaryAttachment atch : email.binaryAttachments) {
					if (isExeFile(atch, null)) {
						continue;
					}
					Attachment attch = new Attachment();
					attch.Body = atch.body;
					attch.Name = atch.fileName;
					attch.ContentType = atch.mimeTypeSubType;
					attch.ParentId = msg.Id;
					attachmentList.add(attch);
				}
			}
			if (email.textAttachments != null) {
				for (Messaging.InboundEmail.TextAttachment atch : email.textAttachments) {
					if (isExeFile(null, atch)) {
						continue;
					}
					Attachment attch = new Attachment();
					attch.Body = Blob.valueOf(atch.body);
					attch.Name = atch.fileName;
					attch.ContentType = atch.mimeTypeSubType;
					attch.ParentId = msg.Id;
					attachmentList.add(attch);
				}
			}
			if (attachmentList.size() > 0) {
				insert attachmentList;
			}
			createLog(email, c.id, 'Success', '');
		} catch (Exception ex) {
			createLog(email, null, 'Failed', ex.getMessage());
		}

		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		return result;
	}

	private void createLog(Messaging.InboundEmail email, String caseId, String status, String errorMessage) {
		Inapp_Email_Log__c log = new Inapp_Email_Log__c();
		log.Case__c = caseId;
		log.Exception__c = errorMessage;
		log.HTML_Body__c = email.htmlBody;
		log.Plain_Text_Body__c = email.plainTextBody;
		log.Status__c = status;
		log.message_id__c = 'Email-' + email.messageId;
		insert log;
	}

	public String getParsedText(String body) {
		String responseBody = body.split('-----------------------------------------------<br/>')[2];
		responseBody = responseBody.replaceAll('<br/>', '\n');
		responseBody = responseBody.replaceAll('<BR/>', '\n');
		responseBody = responseBody.replaceAll('</FONT>', '');
		responseBody = responseBody.replaceAll('<FONT size=1 face=Arial>', '');
		responseBody = responseBody.replaceAll('</P>', '');
		responseBody = responseBody.replaceAll('</DIV>', '');
		responseBody = responseBody.replaceAll('</BODY>', '');
		responseBody = responseBody.replaceAll('</HTML>', '');
		return responseBody;
	}

	public boolean isExeFile(Messaging.InboundEmail.BinaryAttachment binaryAttchmentRec, Messaging.InboundEmail.TextAttachment textAttachmentRec) {
		boolean isExeFile = false;
		List<Messaging.InboundEmail.Header> headerList = new List<Messaging.InboundEmail.Header>();

		if (binaryAttchmentRec != null) {
			headerList = binaryAttchmentRec.headers;
		} else if (textAttachmentRec != null) {
			headerList = textAttachmentRec.headers;
		}

		if (headerList != null && headerList.size() > 0) {
			for (Messaging.InboundEmail.Header headerRec : headerList) {
				if (headerRec.Name.equalsIgnoreCase('Content-Type') && headerRec.Value.equalsIgnoreCase('exe')) {
					isExeFile = true;
					break;
				}
			}
		}

		return isExeFile;
	}

	public static Case createCase(Messaging.InboundEmail email) {
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		Case cse = new Case();
		cse.setOptions(dmo);

		if (email.plainTextBody != null) {
			cse.Description = email.plainTextBody;
		} else if (email.htmlBody != null) {
			cse.Description = email.htmlBody;
		}

		cse.Origin = 'Gusto';
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Care');
		cse.Source__c = 'Support Bot';
		cse = setCaseAttributes(email.plainTextBody, cse);

		insert cse;

		return cse;
	}

	private static Case setCaseAttributes(String emailBody, Case cse) {
		cse.Authorized_User__c = 'Yes';

		if (emailBody.indexOf('-----------------------------------------------') > -1) {
			String metaData = '';
			String[] bodyArr = emailBody.split('-----------------------------------------------');
			if (bodyArr.size() > 2) {
				metaData = bodyArr[1];
			}

			String[] lineArray = metaData.split('\n');
			for (String line : lineArray) {
				if (line.indexOf('CompanyID : ') > -1) {
					companyId = line.replace('CompanyID : ', '');
				}
				if (line.indexOf('FirmID : ') > -1) {
					firmId = line.replace('FirmID : ', '');
				}
				if (line.indexOf('UserID : ') > -1) {
					userId = line.replace('UserID : ', '');
				}
				if (line.indexOf('Email : ') > -1) {
					emailAddress = line.replace('Email : ', '');
					if (emailAddress.indexOf(' <') > -1) {
						emailAddress = emailAddress.split(' <')[0];
					}
					emailAddress = emailAddress.trim();
				}
				if (line.indexOf('UserName : ') > -1) {
					userName = line.replace('UserName : ', '');
				}
				if (line.indexOf('subject :') > -1) {
					subject = line.replace('subject :', '');
				}
			}

			List<Account> companyAccounts = new List<Account>([SELECT Id FROM Account WHERE ZP_Company_id__c = :companyId AND ZP_Company_id__c != NULL]);
			List<Account> firmAccounts = new List<Account>([SELECT Id FROM Account WHERE ZP_Firm_id__c = :firmId AND ZP_Firm_id__c != NULL]);
			List<Contact> contactList = new List<Contact>([SELECT Id FROM contact WHERE zp_user_id__c = :userId AND zp_user_id__c != NULL]);
			List<Contact> contactEailList = new List<Contact>([SELECT Id FROM contact WHERE Email = :emailAddress AND Email != NULL]);
			if (firmId != '') {
				if (firmAccounts.size() > 0) {
					cse.AccountId = firmAccounts[0].id;
				}
				if (companyAccounts.size() > 0) {
					cse.Related_Company__c = companyAccounts[0].id;
				}
			} else if (companyId != '') {
				if (companyAccounts.size() > 0) {
					cse.AccountId = companyAccounts[0].id;
				}
			}
			if (userId != '') {
				if (contactList.size() > 0) {
					cse.ContactId = contactList[0].id;
				}
				cse.ZP_User_id__c = userId;
			}
			if (emailAddress != '') {
				cse.SuppliedEmail = emailAddress;
				if (contactList.size() < 1 && contactEailList.size() > 0) {
					cse.ContactId = contactEailList[0].id;
				}
			}
			if (userName != '') {
				cse.SuppliedName = userName;
			}
			if (subject != '') {
				cse.Subject = subject.left(80);
			}
		}
		return cse;
	}
}