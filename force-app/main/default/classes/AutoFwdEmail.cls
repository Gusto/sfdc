/*
  @Author -Gaurav Khare
  @CreateDate 10-Dec-2020
  @Description - AutoFwdEmail
*/
global class AutoFwdEmail implements Messaging.InboundEmailHandler {
	Email_Service_Log__c objEmailLog = new Email_Service_Log__c();
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		try {
			objEmailLog.Type__c = 'INFO';
			objEmailLog.Subject__c = email.subject;
			objEmailLog.Original_Mail__c = String.ValueOf(email);
			String fromAddress = email.fromAddress;
			objEmailLog.To_Address__c = String.ValueOf(email.toAddresses);
			objEmailLog.From_Address__c = email.fromAddress;
			objEmailLog.Reply_To__c = email.replyTo;
			String toAddress = '';
			Set<string> setBenefitRoles = new Set<string>();
			List<string> benefitsRolesList = Label.Benefits_Roles.split(',');
			for (String role : benefitsRolesList) {
				setBenefitRoles.add(role);
			}

			//search for the formAddress in the leads and contacts(prefer contact first)
			List<List<sObject>> searchList = [FIND :fromAddress IN ALL FIELDS RETURNING Contact(Id, Name, AccountId WHERE AccountId != NULL), Lead(Id, Name, Company WHERE Company != NULL)];

			Contact[] searchContacts = (Contact[]) searchList[0];
			Lead[] searchLead = (Lead[]) searchList[1];

			//first check if contact exist, if not check for exisitng lead
			if (searchContacts != null && searchContacts.size() > 0) {
				objEmailLog.Search_Contacts__c = searchContacts[0].Name + ' ' + String.valueOf(searchContacts);
				List<Account> accs = [SELECT Name, HI_Owner__c, HI_Owner__r.Email, HI_Owner__r.UserRole.Name, HI_Owner__r.isActive FROM Account WHERE Id = :searchContacts[0].AccountId LIMIT 1];

				if (accs != null && accs.size() > 0) {
					objEmailLog.Search_Accounts__c = String.valueOf(accs);
					objEmailLog.Account_Owner_UserRole__c = accs[0].HI_Owner__c != null ? accs[0].HI_Owner__r.UserRole.Name : '';
					objEmailLog.Role_Exists_In_Benefit_Roles__c = accs[0].HI_Owner__c != null ? String.ValueOf(setBenefitRoles.contains(accs[0].HI_Owner__r.UserRole.Name)) : '';
				}
				if (accs != null && accs.size() > 0 && accs[0].HI_Owner__c != null && accs[0].HI_Owner__r.isActive && setBenefitRoles.contains(accs[0].HI_Owner__r.UserRole?.Name)) {
					toAddress = accs[0].HI_Owner__r.Email;
				}
			} else if (searchLead != null && searchLead.size() > 0) {
				objEmailLog.Search_Lead__c = searchLead[0].Name + ' ' + String.valueOf(searchLead);
				List<Account> accs = [SELECT Id, HI_Owner__c, HI_Owner__r.Email, HI_Owner__r.UserRole.Name, HI_Owner__r.isActive FROM Account WHERE Name = :searchLead[0].Company LIMIT 1];

				if (accs != null && accs.size() > 0) {
					objEmailLog.Search_Accounts__c = String.valueOf(accs);
					objEmailLog.Account_Owner_UserRole__c = accs[0].HI_Owner__c != null ? accs[0].HI_Owner__r.UserRole.Name : '';
					objEmailLog.Role_Exists_In_Benefit_Roles__c = accs[0].HI_Owner__c != null ? String.ValueOf(setBenefitRoles.contains(accs[0].HI_Owner__r.UserRole.Name)) : '';
				}
				if (accs != null && accs.size() > 0 && accs[0].HI_Owner__c != null && accs[0].HI_Owner__r.isActive && setBenefitRoles.contains(accs[0].HI_Owner__r.UserRole.Name)) {
					toAddress = accs[0].HI_Owner__r.Email;
				}
			}
			if (toAddress == null || toAddress == '') {
				toAddress = Label.Default_Benefits_Distribution_Email;
			}
			objEmailLog.Email_To_Be_Fwded__c = toAddress;

			if (toAddress != null && toAddress != '') {
				sendEmail(email, toAddress);
			}
		} catch (Exception e) {
			objEmailLog.Type__c = 'ERROR';
			objEmailLog.Error_Desc__c = e.getMessage();
			objEmailLog.Trace__c = e.getStackTraceString();
		}

		try {
			logEmailDetails(objEmailLog);
		} catch (Exception e) {
			// Do Nothinng
		}
		return result;
	}

	private void sendEmail(Messaging.InboundEmail email, String toAddress) {
		OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'no-reply@gusto.com'];
		String prefixMsg = getPrefixMesage(email);
		if (prefixMsg == null) {
			prefixMsg = '';
		}
		Messaging.reserveSingleEmailCapacity(1);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new List<String>{ toAddress };
		mail.setToAddresses(toAddresses);
		if (owea == null) {
			mail.setSenderDisplayName('no-reply@gusto.com');
		} else {
			mail.setOrgWideEmailAddressId(owea.get(0).Id);
		}
		mail.setSubject('Fwd: ' + email.subject);
		mail.setPlainTextBody(prefixMsg + email.plainTextBody);
		// Gaurav Khare : 11-Feb-2020 : Fixed Null body issue
		if (email.htmlBody == null) {
			mail.setHtmlBody(prefixMsg + email.plainTextBody);
		} else {
			mail.setHtmlBody(prefixMsg + email.htmlBody);
		}
		setAttacments(email, mail);

		EmailMessageTriggerHelper.skipTrigger = true;
		Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
		EmailMessageTriggerHelper.skipTrigger = false;
	}

	private void setAttacments(Messaging.InboundEmail email, Messaging.SingleEmailMessage mail) {
		List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
		if (email.binaryAttachments != null) {
			for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
				Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
				efa.setFileName(bAttachment.fileName);
				efa.setBody(bAttachment.Body);
				for (Messaging.InboundEmail.Header hd : bAttachment.headers) {
					if (hd.name == 'Content-Type') {
						efa.setContentType(hd.value);
					}
				}
				attachments.add(efa);
			}
		}
		if (email.textAttachments != null) {
			for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
				Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
				efa.setFileName(tAttachment.fileName);
				efa.setBody(Blob.ValueOf(tAttachment.Body));
				for (Messaging.InboundEmail.Header hd : tAttachment.headers) {
					if (hd.name == 'Content-Type') {
						efa.setContentType(hd.value);
					}
				}
				attachments.add(efa);
			}
		}
		if (attachments.size() > 0) {
			mail.setFileAttachments(attachments);
		}
	}

	private String getPrefixMesage(Messaging.InboundEmail email) {
		String sDate = '';
		for (Messaging.InboundEmail.Header hd : email.headers) {
			if (hd.name == 'Date') {
				sDate = String.ValueOf(hd.value);
			}
		}
		String strPrefixMessage = '';
		strPrefixMessage += '---------- Forwarded message ---------<br>';
		if (email.fromName != null) {
			strPrefixMessage += 'From: ' + email.fromName + '&lt;' + email.FromAddress + '&gt;' + '<br>';
		} else {
			strPrefixMessage += 'From: ' + email.FromAddress + '<br>';
		}
		strPrefixMessage += 'Date: ' + sDate + '<br>';
		strPrefixMessage += 'Subject: ' + email.Subject + '<br>';
		strPrefixMessage += 'To: ';
		if (email.toAddresses != null) {
			for (String toAddrs : email.toAddresses) {
				if (toAddrs != null) {
					strPrefixMessage += '&lt;' + toAddrs + '&gt;';
				}
				if (toAddrs != email.toAddresses[email.toAddresses.size() - 1]) {
					strPrefixMessage += ', ';
				}
			}
		}

		strPrefixMessage += '<br>';
		if (email.ccAddresses != null) {
			strPrefixMessage += 'CC: ' + email.ccAddresses + '<br>';
		}
		// 31-Jan-2020 : Gaurav Khare : replyTo would help for cases with masked fromAddress (e.g. name via benefits-advising@gusto.com)
		if (email.replyTo != null) {
			strPrefixMessage += 'Reply To: ' + email.replyTo + '<br>';
		}
		strPrefixMessage += '<br>';

		return strPrefixMessage;
	}

	private void logEmailDetails(Email_Service_Log__c emailLogObj) {
		if (Label.LogEmailService == 'Y') {
			insert emailLogObj;
		}
	}
}