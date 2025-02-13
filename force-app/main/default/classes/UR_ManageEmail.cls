/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_ManageEmail>>
 * Description...........: <<Email services are automated processes that use Apex classes to process the contents, headers, and attachments of inbound email. >>
 *-------------------------------------------------------------------------------*/
global class UR_ManageEmail implements Messaging.InboundEmailHandler {
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
		//get Project Master Record && Contact Id
		if (string.isNotBlank(email.Subject) && email.fromAddress != null) {
			string strEmailBody = email.htmlBody;
			integer startP = strEmailBody.indexOf('[Ref:');
			integer endP = strEmailBody.indexOf(':Ref]');
			if (startP > -1 && endP > -1) {
				strEmailBody = strEmailBody.substring(startP + 5, endP).Trim();
				integer spCharPosition = strEmailBody.indexOf('~');
				string projectId = strEmailBody.substring(0, spCharPosition);
				string participantId = strEmailBody.substring(spCharPosition + 1, strEmailBody.length());

				string sfdcContactId = null;
				//get SFDC Id depending upon Project id from Porject detail Object

				List<Research_Project_Detail__c> lstProjectDetail = [
					SELECT id, Research_Project_Master__c, Research_Project_Master__r.Name, Research_Project_Master__r.Owner.Email, Research_Project_Master__r.Owner.Name, Contact__c
					FROM Research_Project_Detail__c
					WHERE Project_Id__c = :projectId AND id = :participantId
					LIMIT 1
				];

				if (lstProjectDetail != null && lstProjectDetail.size() > 0) {
					//Create Email Message
					EmailMessage newEmail = new EmailMessage();
					newEmail.FromAddress = email.fromAddress;
					newEmail.FromName = email.FromName;
					newEmail.ToAddress = email.fromAddress;
					newEmail.Status = '2';
					newEmail.Unread_Email__c = true;
					newEmail.Subject = email.Subject;
					newEmail.TextBody = email.plainTextBody;
					newEmail.HtmlBody = email.htmlBody;
					newEmail.RelatedToId = lstProjectDetail[0].Id;
					insert newEmail;

					//Manage Attachement
					List<Attachment> lstAttachment = new List<Attachment>();
					//Handle text Attachment
					if (email.textAttachments != null && email.textAttachments.size() > 0) {
						for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
							Attachment attachment = new Attachment();
							attachment.Name = tAttachment.fileName;
							attachment.Body = Blob.valueOf(tAttachment.body);
							attachment.ParentId = newEmail.id;
							lstAttachment.add(attachment);
						}
					}
					//Handle Binary Attachemnt
					if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
						for (Messaging.Inboundemail.BinaryAttachment bAttachment : email.binaryAttachments) {
							Attachment attachmentB = new Attachment();
							attachmentB.Name = bAttachment.fileName;
							attachmentB.Body = bAttachment.body;
							attachmentB.ParentId = newEmail.Id;
							lstAttachment.add(attachmentB);
						}
					}
					if (lstAttachment != null && lstAttachment.size() > 0) {
						insert lstAttachment;
					}
					//Update Project Detail to mark email as unread on detail level
					Research_Project_Detail__c rpd = new Research_Project_Detail__c(id = lstProjectDetail[0].Id);
					rpd.Unread_Email__c = true;
					update rpd;
					//Send Reply copy to project owner
					List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
					Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
					if (Test.isRunningTest()) {
						msg.toAddresses = new List<String>{ 'Test1@gusto.com' };
					} else {
						msg.toAddresses = new List<String>{ lstProjectDetail[0].Research_Project_Master__r.Owner.Email };
					}

					if (UR_UtilityCtrl.orgWideEmailToOwner != null) {
						msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmailToOwner);
					}
					string emailBody = 'Hello ' + lstProjectDetail[0].Research_Project_Master__r.Owner.Name + ', <br/><br/>';
					emailBody = emailBody + 'You have received a reply from a participant in Scout! <br/><br>';
					emailBody =
						emailBody +
						'To reply, go to your Scout project: <a href=' +
						URL.getSalesforceBaseUrl().toExternalForm() +
						'/one/one.app#/alohaRedirect/apex/UR_ViewEmail?projectId=' +
						lstProjectDetail[0].Research_Project_Master__c +
						' target="_blank">' +
						lstProjectDetail[0].Research_Project_Master__r.Name +
						'</a>';
					emailBody = emailBody + '<br/><br/>' + '------- <br/> From : ' + email.FromName + ' [' + email.fromAddress + '] <br/><br/>';
					emailBody = emailBody + email.htmlBody;
					msg.setHtmlBody(emailBody);
					msg.setSubject('UXR Scout : ' + email.Subject);
					mail.add(msg);

					if (mail.size() > 0) {
						UR_UtilityCtrl.skipTriggerLogic();
						if(OrganizationUtilities.canSendEmails()){
							Messaging.sendEmail(mail);
						}
					}
				}
			}
		}

		return result;
	}
}