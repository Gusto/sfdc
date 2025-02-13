/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_VewEmailCtrl>>
 * Description...........: <<This class View all the email related to any UX project>>
 *-------------------------------------------------------------------------------*/
public class UR_VewEmailCtrl {
	public String currentRecordId { get; set; }
	public Research_Project_Master__c objProject { get; set; }
	public String strSelectedContactedEmail { get; set; }
	public List<MessageWrapper> lstMessageWrapper { get; set; }
	public String sortbyFieldAPIName { get; set; }
	public String prevSortbyFieldAPIName { get; set; }
	public String orderAs { get; set; }

	//Just to implete and bind from date and to date
	public Contact objContactFrom { get; set; }
	public Contact objContactTo { get; set; }
	Map<Id, Research_Project_Detail__c> map_Participants;
	public set<string> setPartId;
	public string successMsg { get; set; }
	public EmailWrapper objEmailMsgWrapper;
	public String emailReplyBody { get; set; }
	public String currentPartId;
	public boolean isEditable { get; set; }
	public Date dtFromDate { get; set; }
	public static final Integer PAGE_SIZE = Integer.valueof(Label.UR_NoOfEmailPerPage);
	public ApexPages.StandardSetController setCon { get; set; }
	public boolean isConstructor = true;
	public static final Integer MAX_LIST_LIMIT = 1000;
	public Double offset {
		get {
			TimeZone tz = UserInfo.getTimeZone();
			//Milliseconds to Day
			return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
		}
	}
	public String strSearchContactName { get; set; }

	//Constructor
	public UR_VewEmailCtrl(ApexPages.StandardController controller) {
		isConstructor = true;
		objContactFrom = new Contact();
		successMsg = '';
		setCon = null;
		objContactTo = new Contact();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		orderAs = ApexPages.CurrentPage().getparameters().get('orderas');
		if (String.isBlank(orderAs)) {
			orderAs = 'asc';
		}
		sortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('sortby');
		if (String.isBlank(sortbyFieldAPIName)) {
			sortbyFieldAPIName = 'Status';
		}
		prevSortbyFieldAPIName = sortbyFieldAPIName;

		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		showMessageHistory();
		objContactFrom.Birthdate = dtFromDate;
		objContactTo.Birthdate = Date.Today().AddDays(2);
		isConstructor = false;
	}

	//This method retun all the project Participants related to the UX project.
	public pagereference RetriveProjectParticipant() {
		setPartId = new Set<string>();
		objProject = new Research_Project_Master__c(id = currentRecordId);
		map_Participants = new Map<Id, Research_Project_Detail__c>();

		//Get All Contact who has received an email related to this project
		//get All related participant
		for (EmailMessage ems : [
			SELECT RelatedToId
			FROM EmailMessage
			WHERE
				RelatedToId IN (
					SELECT id
					FROM Research_Project_Detail__c
					WHERE Research_Project_Master__c = :currentRecordId
				)
		]) {
			setPartId.add(ems.RelatedToId);
		}

		return null;
	}

	//Fetch seleted participant name and email Id.
	public void fetchParticipantDetails(Set<Id> set_SelectedPartId) {
		map_Participants = new Map<Id, Research_Project_Detail__c>();
		if (set_SelectedPartId != null && set_SelectedPartId.size() > 0) {
			for (Research_Project_Detail__c objRPD : [
				SELECT Id, Research_Project_Master__r.CreatedDate, Research_Project_Master__c, Contact__c, Contact__r.Email, Contact__r.Name
				FROM Research_Project_Detail__c
				WHERE Id IN :set_SelectedPartId
				ORDER BY Contact__r.Name
			]) {
				if (dtFromDate == null && objRPD.Research_Project_Master__c != null) {
					DateTime dtCreatedDate = objRPD.Research_Project_Master__r.CreatedDate;
					dtFromDate = date.newInstance(dtCreatedDate.year(), dtCreatedDate.month(), dtCreatedDate.day());
				}

				map_Participants.put(objRPD.Id, objRPD);
			}
		}
	}

	//This method return email history.
	public pageReference showMessageHistory() {
		try {
			RetriveProjectParticipant();
			RetriveEmail(true);
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
		return null;
	}
	public PageReference RetriveEmail(boolean runSOQL) {
		List<EmailMessage> lstMessageHistory = new List<EmailMessage>();
		lstMessageWrapper = new List<MessageWrapper>();
		string query = 'SELECT HtmlBody, CreatedDate, Unread_Email__c, FromAddress,FromName, ToAddress, RelatedToId, Status, Subject ';
		query = query + ' FROM EmailMessage WHERE RelatedToId in:setPartId';

		if (string.isNotBlank(strSelectedContactedEmail)) {
			query = query + ' AND RelatedToId=:strSelectedContactedEmail';
		}
		if (objContactFrom.Birthdate != null && objContactTo.Birthdate != null) {
			date dFrom = objContactFrom.Birthdate;
			Time fromTime = Time.newInstance(0, 1, 0, 0);
			date dTo = objContactTo.Birthdate;
			Time toTime = Time.newInstance(23, 59, 59, 0);
			DateTime fromDT = DateTime.newInstance(dFrom, fromTime);
			DateTime toDT = DateTime.newInstance(dTo, toTime);
			query = query + ' AND CreatedDate>=:fromDT AND CreatedDate<=:toDT';
		}
		//query = query + ' order by createddate desc';
		query = query + ' order by ' + sortbyFieldAPIName + ' ' + orderAs + ' NULLS LAST';

		if (runSOQL == true) {
			setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
			setCon.setPageSize(PAGE_SIZE);
		}

		Set<Id> set_SelectedPartId = new Set<Id>();
		for (EmailMessage objEM : (List<EmailMessage>) setCon.getRecords()) {
			set_SelectedPartId.add(objEM.relatedToId);
		}

		fetchParticipantDetails(set_SelectedPartId);

		for (EmailMessage objEM : (List<EmailMessage>) setCon.getRecords()) {
			MessageWrapper objWrapper = new MessageWrapper();
			objWrapper.objEmailMsg = objEM;
			objWrapper.envStyle = 'fa-envelope-open';
			if (objEM.Unread_Email__c) {
				objWrapper.envStyle = 'fa-envelope';
			}

			Research_Project_Detail__c objRPD = map_Participants.get(objEM.relatedToId);

			if (objRPD != null) {
				objWrapper.strName = objRPD.Contact__r.Name;
				objWrapper.strEmail = objRPD.Contact__r.Email;
			}
			lstMessageWrapper.add(objWrapper);
		}

		if (lstMessageWrapper.size() == 0 && !isConstructor) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No record found.'));
		}

		return null;
	}

	//This method retun Email wrapper class to show email details on VF page.
	public EmailWrapper getobjEmailMsgWrapper() {
		successMsg = '';
		String currentTaskId = ApexPages.currentPage().getParameters().get('currentTaskId');
		currentPartId = ApexPages.currentPage().getParameters().get('currentPartId');
		objEmailMsgWrapper = new EmailWrapper();
		emailReplyBody = '';
		EmailMessage objEmailMessage = new EmailMessage();
		if (currentTaskId != null) {
			objEmailMessage = [
				SELECT Id, Subject, HtmlBody, RelatedToId, ToAddress, Createddate, FromAddress, FromName, CcAddress, BccAddress, Unread_Email__c
				FROM EmailMessage
				WHERE id = :currentTaskId
			];
			if (objEmailMessage != null) {
				objEmailMsgWrapper.objEmailMessage = objEmailMessage;
				objEmailMsgWrapper.emailBody = '';
				if (String.isNotBlank(objEmailMessage.HtmlBody)) {
					objEmailMsgWrapper.emailBody = objEmailMessage.HtmlBody.replace('\n\r', '<br/>');
					objEmailMsgWrapper.emailBody = objEmailMsgWrapper.emailBody.replace('<ul>', '<ul class="slds-list_dotted slds-m-top_small slds-m-bottom_small">');
					objEmailMsgWrapper.emailBody = objEmailMsgWrapper.emailBody.replace('<ol>', '<ol class="slds-list_ordered slds-m-top_small slds-m-bottom_small">');
				}
			}
		}
		return objEmailMsgWrapper;
	}

	//Wrapper class.
	public class EmailWrapper {
		public EmailMessage objEmailMessage { get; set; }
		public string emailBody { get; set; }
	}

	//Update Read email status if any email is in unread
	public PageReference UpdateReadEmailStatus() {
		string strTaskId = ApexPages.currentPage().getParameters().get('currentTaskId');
		currentPartId = ApexPages.currentPage().getParameters().get('currentPartId');

		//If user has editable access then upadte will be happen
		if (isEditable == true) {
			Integer emailCount = [SELECT COUNT() FROM EmailMessage WHERE id = :strTaskId AND Unread_Email__c = TRUE];

			if (emailCount == 1) {
				EmailMessage obj = new EmailMessage(id = strTaskId);
				obj.Unread_Email__c = false;
				update obj;
			}
		}
		return null;
	}

	//This method will execute on reply link.
	public void ReplyEmail() {
		UR_UtilityCtrl.skipTriggerLogic();
		try {
			if (string.isNotBlank(emailReplyBody)) {
				EmailMessage objEmailMessage = objEmailMsgWrapper.objEmailMessage;
				String dateObj = objEmailMessage.Createddate.format('EEE, d MMM yyyy HH:mm ');
				String replyFromStmt = 'On ' + dateObj + ',' + objEmailMessage.FromName + ' ' + '&lt;' + objEmailMessage.FromAddress + '&gt; wrote:';
				list<string> toaddrs = new List<string>();
				//generate Email Body
				emailReplyBody = emailReplyBody.replace('\n', '<br/>');
				String contactId = [SELECT Id, Contact__r.Email, Contact__r.id FROM Research_Project_Detail__c WHERE Id = :currentPartId].Contact__r.Id;
				string emailBody = emailReplyBody + '<br/>' + '<b>' + replyFromStmt + '</b>' + '<br/>' + objEmailMessage.HtmlBody;
				List<Messaging.SingleEmailMessage> mail = new List<Messaging.SingleEmailMessage>();
				Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
				msg.setWhatId(currentPartId);
				msg.setTargetObjectId(contactId);
				if (string.isNotBlank(UR_UtilityCtrl.strReplyEmail)) {
					msg.setReplyTo(UR_UtilityCtrl.strReplyEmail);
				}
				msg.setSubject(objEmailMessage.Subject);
				msg.setHtmlBody(emailBody);
				msg.setSaveAsActivity(true);
				if (UR_UtilityCtrl.orgWideEmail_NoReply != null) {
					msg.setOrgWideEmailAddressId(UR_UtilityCtrl.orgWideEmail_NoReply);
				}
				mail.add(msg);
				Messaging.sendEmail(mail);
				emailReplyBody = '';
				successMsg = 'Email sent successfully.<br/>';
				showMessageHistory();
			}
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			successMsg = e.getMessage();
		}
	}

	//This method will execute on click of back button.
	public PageReference BackToProject() {
		PageReference pageRef = new PageReference('/apex/UR_AddParticipants?projectId=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//Wrapper class
	public class MessageWrapper {
		public EmailMessage objEmailMsg { get; set; }
		public string strName { get; set; }
		public string strEmail { get; set; }
		public string envStyle { get; set; }
	}

	//For pagination
	/** indicates whether there are more records after the current page set.*/
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	/** indicates whether there are more records before the current page set.*/
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	/** returns the page number of the current page set*/
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	public Integer getTotalRecord() {
		Decimal totalSize = 0;
		if (setCon != null) {
			totalSize = setCon.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
	}

	/** return total number of pages for page set*/
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	/** returns the first page of the page set*/
	public void first() {
		setCon.first();
		RetriveEmail(false);
	}

	/** returns the last page of the page set*/
	public void last() {
		setCon.last();
		RetriveEmail(false);
	}

	/** returns the previous page of the page set*/
	public void previous() {
		setCon.previous();
		RetriveEmail(false);
	}

	/** returns the next page of the page set*/
	public void next() {
		setCon.next();
		RetriveEmail(false);
	}

	//End pagination

	public pageReference sortParticipantList() {
		setSortingFilter();
		PageReference pageRef = new PageReference('/apex/UR_ViewEmail?projectId=' + objProject.Id + '&orderas=' + orderAs + '&sortby=' + sortbyFieldAPIName);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void setSortingFilter() {
		if (sortbyFieldAPIName != prevSortbyFieldAPIName) {
			orderAs = 'asc';
		} else {
			if ('asc' == orderAs) {
				orderAs = 'desc';
			} else {
				orderAs = 'asc';
			}
		}
	}

	// JS Remoting action called when searching for a movie name
	@RemoteAction
	public static List<Research_Project_Detail__c> searchContact(String strProjectId, String strSearchTerm) {
		List<Research_Project_Detail__c> list_Participant = new List<Research_Project_Detail__c>();
		if (String.isNotBlank(strProjectId) && String.isNotBlank(strSearchTerm)) {
			String strQuery =
				'SELECT Id, Contact__r.Name FROM Research_Project_Detail__c WHERE Research_Project_Master__c= :strProjectId AND Contact__r.Name LIKE \'%' +
				String.escapeSingleQuotes(strSearchTerm) +
				'%\' LIMIT 50';
			list_Participant = Database.query(strQuery);
		}

		return list_Participant;
	}
}