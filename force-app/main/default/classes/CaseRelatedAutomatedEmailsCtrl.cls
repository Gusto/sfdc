/**
 * @name         CaseRelatedAutomatedEmailsCtrl
 * @author       Anand
 * @date         01/27/2021
 * @description  This class segregate the Email message record betwen OE and Advising
 * @test class   CaseRelatedAutomatedEmailsCtrlTest.cls
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class CaseRelatedAutomatedEmailsCtrl {
	public String strCaseId;
	public List<EmailMessageWrapper> list_AdvisingEmail { get; set; }
	public List<EmailMessageWrapper> list_OEEmail { get; set; }

	public CaseRelatedAutomatedEmailsCtrl(ApexPages.StandardController stdController) {
		strCaseId = stdController.getId();
		list_AdvisingEmail = new List<EmailMessageWrapper>();
		list_OEEmail = new List<EmailMessageWrapper>();
		for (EMailMEssage em : [
			SELECT
				Id,
				Automated_Email__c,
				ParentId,
				Subject,
				Email_Template_Name__c,
				FromAddress,
				ToAddress,
				MessageDate
			FROM EMailMEssage
			WHERE Email_Template_Name__c != NULL AND Automated_Email__c = TRUE AND ParentId = :strCaseId
			ORDER BY createddate DESC
		]) {
			EmailMessageWrapper objEmailWarpper = new EmailMessageWrapper();
			objEmailWarpper.objEmailMessage = em;
			if (em.Email_Template_Name__c != null && em.Email_Template_Name__c.indexOf('Advising') > -1) {
				list_AdvisingEmail.add(objEmailWarpper);
			} else {
				list_OEEmail.add(objEmailWarpper);
			}
		}
	}

	public class EmailMessageWrapper {
		public EmailMessage objEmailMessage { get; set; }
	}
}