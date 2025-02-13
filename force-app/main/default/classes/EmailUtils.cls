public class EmailUtils {
	public static void sendTextEmail(List<String> recipients, String emailSubject, String textBody) {
		sendEmail(recipients, emailSubject, textBody, false, null);
	}

	public static void sendHTMLEmail(List<String> recipients, String emailSubject, String htmlBody) {
		sendEmail(recipients, emailSubject, htmlBody, true, null);
	}

	public static void sendEmail(List<String> recipients, String emailSubject, String body, Boolean useHTML, List<Messaging.EmailFileAttachment> fileAttachments) {
		if (recipients == null) {
			return;
		}
		if (recipients.size() == 0) {
			return;
		}
		// Create a new single email message object
		// that will send out a single email to the addresses in the To, CC & BCC list.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//the email is not saved as an activity.
		mail.setSaveAsActivity(false);
		// Assign the addresses for the To lists to the mail object.
		mail.setToAddresses(recipients);
		// Specify the subject line for your email address.
		mail.setSubject(emailSubject);
		// Set to True if you want to BCC yourself on the email.
		mail.setBccSender(false);
		// The email address of the user executing the Apex Code will be used.
		mail.setUseSignature(false);
		if (useHTML) {
			// Specify the html content of the email.
			mail.setHtmlBody(body);
		} else {
			// Specify the text content of the email.
			mail.setPlainTextBody(body);
		}
		// Specify FileAttachments
		if (fileAttachments != null && fileAttachments.size() > 0) {
			mail.setFileAttachments(fileAttachments);
		}
		// Send the email you have created.
		try {
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
		} catch (System.EmailException e) {
		}
	}

	/**
	 * null     => false
	 * ''       => false
	 * ' '      => false
	 * 'x'      => false
	 * 'x@'     => false
	 * 'x@x'    => false
	 * 'x@x.x'  => true
	 */
	public static Boolean isValidEmailAddress(String str) {
		if (str != null && str.trim() != null && str.trim().length() > 0) {
			String[] split = str.split('@');
			if (split != null && split.size() == 2) {
				split = split[1].split('\\.');
				if (split != null && split.size() >= 2) {
					return true;
				}
			}
		}
		return false;
	}

	public static Boolean isNotValidEmailAddress(String str) {
		return !isValidEmailAddress(str);
	}
}