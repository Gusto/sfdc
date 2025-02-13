public class CallBackController {
	public string queueId { get; set; }
	public string name { get; set; }
	public string phone { get; set; }
	public string dtm { get; set; }
	public Case tempCase { get; set; }

	public List<SelectOption> queueList { get; private set; }

	public Contact c { get; private set; }
	public Account a { get; private set; }
	public Case cs { get; private set; }
	public boolean isSuccess { get; set; }

	private string caseId { get; private set; }
	private string contactId { get; private set; }

	private map<String, String> queueMap;

	private User loggedInUser;
	private String strLoggedInUserName, strLoggedInUserSkillId;
	public Boolean bool_UserCallBack { get; set; }

	public CallBackController() {
		init();
		setAttributes();
	}

	public pageReference submitCallBack() {
		if (phone.length() > 10) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Phone number is invalid. Please enter a valid 10 digit phone number'));
			return null;
		}
		if (phone == null || phone == '') {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Phone number is required.'));
			return null;
		}
		if (name == null || name == '') {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'Name is required.'));
			return null;
		}
		phone = phone.replaceAll(' ', '');
		phone = phone.replaceAll('', '');
		phone = phone.replaceAll('', '');
		phone = phone.replaceAll('-', '');
		GenesysCallbackIntegration genesysIntegration = new GenesysCallbackIntegration();
		dtm = '';
		if (tempCase.Auto_Close_Date_Time__c != null) {
			DateTime tempDtm = tempCase.Auto_Close_Date_Time__c;
			dtm = tempDtm.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + '.000Z';
			//dtm = tempDtm.yearGmt();
		}

		//apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR,dtm));
		String response = (!Test.isRunningTest()
			? genesysIntegration.sumitCallBack(
					queueId,
					phone,
					name,
					dtm,
					strLoggedInUserName,
					cs.Id,
					bool_UserCallBack,
					cs.Auth__c,
					cs.AuthPath__c,
					cs.Genesys_Call_Id__c,
					strLoggedInUserSkillId,
					cs.CaseNumber,
					cs.Origin
			  )
			: 'Success');

		if (response.contains('Success')) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.INFO, 'Callback successfully scheduled'));
			Case_Audit_log__c log = new Case_Audit_log__c();
			log.Event_Type__c = 'Phone Callback';
			log.Case__c = caseId;
			insert log;

			isSuccess = true;
			cs.Latest_Successful_Callback_Timestamp__c = system.now();
			update cs;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, 'An error occured when submitting callback request'));
		}

		return null;
	}

	private void init() {
		isSuccess = false;
		phone = '';
		caseId = '';
		contactId = '';
		bool_UserCallBack = true;
		strLoggedInUserName = userinfo.getFirstName() + ' ' + userinfo.getLastName();
		tempCase = new Case();
		//By ND, 4th December 2019, Autopouplate requested time
		tempCase.Auto_Close_Date_Time__c = system.now();

		queueMap = new Map<String, String>();
		queueList = new List<SelectOption>();
		List<Phone_Queue__c> sortedPhoneQueue = Phone_Queue__c.getall().values();
		sortedPhoneQueue.sort();
		queueList.add(new SelectOption('', '--Select--'));
		for (Phone_Queue__c queue : sortedPhoneQueue) {
			queueList.add(new SelectOption(queue.Queue_Id__c, queue.Name));
			queueMap.put(queue.Name, queue.Queue_Id__c);
		}
		//get user details for logged in user
		loggedInUser = [SELECT Default_Callback_Queue__c, Personal_Skill_Id__c FROM User WHERE Id = :userInfo.getUserId()];

		strLoggedInUserSkillId = loggedInUser.Personal_Skill_Id__c;
	}

	private void setAttributes() {
		if (apexPages.currentPage().getParameters().get('caseId') != null) {
			caseId = apexPages.currentPage().getParameters().get('caseId');
		}
		if (apexPages.currentPage().getParameters().get('contactId') != null) {
			contactId = apexPages.currentPage().getParameters().get('contactId');
		}

		if (caseId != null && caseId != '') {
			List<Case> caseList = new List<Case>(
				[
					SELECT
						id,
						CaseNumber,
						Auth__c,
						Latest_Successful_Callback_Timestamp__c,
						AuthPath__c,
						Genesys_Call_Id__c,
						Record_Type_Name__c,
						AccountId,
						Account.Name,
						Account.RecordType.Name,
						Account.Care_Account_Manager__c,
						Account.CX_Experiment__c,
						Account.Concierge_Group__c,
						SuppliedPhone,
						SuppliedName,
						ContactId,
						Contact.Name,
						Contact.Phone,
						Contact.MobilePhone,
						Contact.HomePhone,
						Origin
					FROM Case
					WHERE id = :caseId
				]
			);
			if (caseList.size() > 0) {
				cs = caseList[0];
				if (cs.SuppliedPhone != null) {
					phone = cs.SuppliedPhone;
					//name = cs.SuppliedName;
				}
				if (cs.ContactId != null) {
					//By ND, 4th December 2019, Auto populate contact name
					if (String.isBlank(phone) && cs.contact.Phone != null) {
						phone = cs.Contact.Phone;
					}
					name = cs.Contact.Name;
				}
				setQueueId(cs.Account, cs.Contact, cs.Record_Type_Name__c);

				if (cs.Latest_Successful_Callback_Timestamp__c != null) {
					ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Callback has already been successfully scheduled on ' + cs.Latest_Successful_Callback_Timestamp__c.format()));
				}
			}
		}
		phone = phone.replaceAll(' ', '');
		phone = phone.replaceAll('[()]', '');
		phone = phone.replaceAll('-', '');
	}

	private void setQueueId(Account acc, Contact cnt, String type) {
		if (acc != null && acc.Concierge_Group__c != null) {
			if (queueMap.containsKey(acc.Concierge_Group__c)) {
				queueId = queueMap.get(acc.Concierge_Group__c);
			} else {
				setQueueBasedOnUser();
			}
		} else {
			setQueueBasedOnUser();
		}
	}
	/*
	 * By ND, 4th December 2019,
	 * Desc	:Auto populate queue based on Logged In User's default queue in case it is not assigned based on related Account
	 */
	private void setQueueBasedOnUser() {
		if (null != loggedInUser && null != loggedInUser.Default_Callback_Queue__c && queueMap.containsKey(loggedInUser.Default_Callback_Queue__c)) {
			queueId = queueMap.get(loggedInUser.Default_Callback_Queue__c);
		}
	}
}