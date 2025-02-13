/***************************************************
Purpose : To have all Order related Utility methods in one class.
Written By : Sourav Mitra
Test Classes : <<TBD>>
****************************************************/
public class OrderUtils {
	public static Set<String> set_OrderAssignment = new Set<String>{ 'Same carrier, plan/group level changes', 'Same Carrier, NO Plan/Group Level Changes', 'Carrier Switch', 'New line of Coverage' };

	//OutBoundEmailMessage related variables
	static String ACTIVE_EMPLOYEE_COUNT = '[ACTIVE EMPLOYEE COUNT]';
	static String DISMISSED_EMPLOYEE_COUNT = '[DISMISSED EMPLOYEE COUNT]';
	static String CONTRACTORS_COUNT = '[CONTRACTORS COUNT]';
	static String STATES = '[STATES]';
	static String CONTACT_FIRST_NAME = '[CONTACT FIRST NAME]';
	static String ORDER_OWNER_NAME = '[ORDER OWNER NAME]';
	static String CALENDELY_LINK = '[CALENDELY LINK]';
	static String ORDER_OWNER_PHONE = '[ORDER OWNER PHONE]';
	static String ORDER_OWNER_PHONE_EXTENSION = '[ORDER OWNER PHONE EXTENSION]';
	static String TEAM_INVITATION_PREFERENCE = '[TEAM INVITATION PREFERENCE]';
	static String IDENTIFIER_ACTIVE_EMPLOYEE = 'pay_active_employee';
	static String IDENTIFIER_DISMISSED_EMPLOYEE = 'pay_dismissed_employee';
	static String IDENTIFIER_CONTRACTOR = 'pay_contractors';
	public static String PT_DEFAULT_EMAIL_ADDRESS = 'payrollonboarding@gusto.com';
	public static String PT_TEAM_INVITATION_PREFERENCE = 'admin';
	static Map<String, String> map_RetriveEmailMacro = OrderUtils.getEmailMacro();
	public static String BASICS_COMPLETED = 'section_gather_the_basics_completed';
	
	/*
    To Create the carrier order from the policy where BO exist
    Written By : Deepika Saini
    */
	public static void createCarrierOrderAgainstBO() {
		Set<Id> set_OpportunityIds = new Set<Id>();
		Set<string> set_OrderStatus = new Set<String>{ 'Fulfilled', 'Closed Admin', 'Canceled', 'Closed Lost' };

		// fetch all the Benefit order which does not have any child CO reccord
		// SJay - 04/09/2020 - Removed carrier order null check as there can be benefit orders which have one or more children but no carrier order.
		List<Benefit_Order__c> list_BenefitOrderCreatedToday = [
			SELECT Id, Name, Opportunity__r.Id
			FROM Benefit_Order__c
			WHERE
				CreatedDate <= TODAY
				AND CreatedDate >= YESTERDAY
				AND Opportunity__r.StageName IN ('Pending PR', 'Closed Won')
				AND RecordType.Name IN ('New Plan', 'Change', 'Renewal')
				AND Order_Status__c NOT IN :set_OrderStatus
		];
		//create a set of Opportunity
		for (Benefit_Order__c objBenefitOrder : list_BenefitOrderCreatedToday) {
			set_OpportunityIds.add(objBenefitOrder.Opportunity__r.Id);
		}
		//fetch the policy which to be created
		List<Policy__c> list_PolicyToCreateCarrierOrder = [
			SELECT Id, Name, Is_Selected__c, Group_Number__c, Opportunity__c, Opportunity__r.RecordType.Name, Carrier__c, Carrier_Order__c, Benefit_Type__c
			FROM Policy__c
			WHERE Is_Selected__c = TRUE AND Opportunity__c IN :set_OpportunityIds AND Carrier_Order__c = NULL
		];
		//Policy helper class is used to create Carrier order.
		if (!list_PolicyToCreateCarrierOrder.isEmpty()) {
			PolicyHelper.isPolicySelected(list_PolicyToCreateCarrierOrder, null, 'insert');
		}
	}
	//set all the textarea with the rows 4 or number of line of the data
	public static Map<String, Integer> setRowCountOfTextArea(sobject objRecord, Set<String> set_FieldsName, Map<String, Integer> map_RowCountOfTextArea) {
		for (String strTempFieldName : set_FieldsName) {
			Integer intRowCount = 4;
			Integer intColsCount = 35;
			if (String.valueof(objRecord.get(strTempFieldName)) != null && String.valueof(objRecord.get(strTempFieldName)).trim() != null) {
				objRecord.put(strTempFieldName, String.valueOf(objRecord.get(strTempFieldName)).trim());
				intRowCount = 0;
				if (string.valueOf(objRecord.get(strTempFieldName)).length() > intColsCount) {
					intRowCount = string.valueOf(objRecord.get(strTempFieldName)).length() / intColsCount;
				}
				intRowCount = intRowCount + string.valueOf(objRecord.get(strTempFieldName)).split('\n').size();
				if (intRowCount < 4) {
					intRowCount = 4;
				}
			}
			map_RowCountOfTextArea.put(strTempFieldName, intRowCount);
		}
		return map_RowCountOfTextArea;
	}

	/*Neha, 4th September 2019
	 *Set all the textarea with the rows 4 or number of line of the data for QA line
	 */
	public static Map<String, Map<String, Integer>> setRowCountForTextArea(List<sobject> lstObj, Set<String> set_FieldsName, Map<String, Map<String, Integer>> map_RowCountOfTextArea) {
		Integer intColsCount = 35; //no. of characters to be shown in each row in text area fields

		if (null != lstObj && lstObj.size() > 0) {
			String objType = lstObj[0].getSObjectType().getDescribe().getName(); // type of sObject
			for (sObject objRecord : lstObj) {
				for (String strFieldName : set_FieldsName) {
					Integer intRowCount = 4;
					//Calculate row count for each field
					if (String.valueof(objRecord.get(strFieldName)) != null && String.valueof(objRecord.get(strFieldName)).trim() != null) {
						objRecord.put(strFieldName, String.valueOf(objRecord.get(strFieldName)).trim());
						intRowCount = 0;
						if (string.valueOf(objRecord.get(strFieldName)).length() > intColsCount) {
							intRowCount = string.valueOf(objRecord.get(strFieldName)).length() / intColsCount;
						}
						intRowCount = intRowCount + string.valueOf(objRecord.get(strFieldName)).split('\n').size();
						if (intRowCount < 4) {
							intRowCount = 4;
						}
					}
					Map<String, Integer> map_CountWithRows = new Map<String, Integer>();

					String strMApKey;
					if ('Transition_to_Fulfillment__c'.equalsIgnoreCase(objType)) {
						strMApKey = objType; // As TTF might not have Id take object name as key
					} else {
						strMApKey = objRecord.Id;
					}
					if (map_RowCountOfTextArea.containsKey(strMApKey)) {
						map_CountWithRows = map_RowCountOfTextArea.get(strMApKey);
					}

					map_CountWithRows.put(strFieldName, intRowCount);

					map_RowCountOfTextArea.put(strMApKey, map_CountWithRows);
				}
			}
		}
		return map_RowCountOfTextArea;
	}
	//DS[04-09-2020] get TTQ Fields With Order Types from Custom Metadata
	public static Set<String> getTTQFieldsAsPerCOOrderAssignment(String strLineOfCoverage) {
		Set<String> set_TTQFieldNames = new Set<String>();
		if (String.isNotBlank(strLineOfCoverage)) {
			if (strLineOfCoverage == 'Short Term Disability') {
				strLineOfCoverage = 'STD';
			} else if (strLineOfCoverage == 'Long Term Disability') {
				strLineOfCoverage = 'LTD';
			}

			for (TTQ_Fields_With_Line_Coverage__mdt objTTQField : [SELECT Id, TTQ_Fields_Name__c FROM TTQ_Fields_With_Line_Coverage__mdt WHERE MasterLabel = :strLineOfCoverage]) {
				set_TTQFieldNames.addAll(objTTQField.TTQ_Fields_Name__c.split(','));
			}
		}
		return set_TTQFieldNames;
	}

	public static String getFieldAPIName(String objectName, String fieldApiName) {
		SObjectType type = Utils.getSObjectDescribe(objectName).getSObjectType();
		Map<String, Schema.SObjectField> mfields = type.getDescribe().fields.getMap();
		if (mfields.containsKey(fieldApiName)) {
			return mfields.get(fieldApiName).getDescribe().getlabel();
		}
		return null;
	}

	/*
	 * @Description : Sending outbound email
	 * @Parm        : map_OrderCases - [map of Order record and related Case]
	 * @Return      : N/A
	 */
	public static void sendIntroEmail(Map<Order, Case> map_OrderCases) {
		if (map_OrderCases?.size() > 0) {
			Map<Id, Messaging.SingleEmailMessage> map_CaseIdEmailMessageInstances = new Map<Id, Messaging.SingleEmailMessage>();
			Map<String, EmailTemplate> map_TemplateNameRecords = new Map<String, EmailTemplate>();
			Set<Id> set_ErroredTargetObjectIds = new Set<Id>();
			Map<Id, EmailMessage> map_ContactIdsEmailMessageToInsert = new Map<Id, EmailMessage>();
			String EMAIL_IOP = 'Payroll_Transfer_Intro_Email_IOP_QBO_2';
			Map<String, List<Id>> map_CaseIdTeamMemberIds = new Map<String, List<Id>>();
			Set<Id> set_CaseIds = new Set<Id>();
			list<OrgWideEmailAddress> list_OrgWideAddresses = GlobalQueryHelper.getOrgWideEmailByAdd(PT_DEFAULT_EMAIL_ADDRESS);

			//Querying Email Templates related to Advising Email
			for (EmailTemplate objET : [SELECT Id, Subject, DeveloperName, HtmlValue, Name FROM EmailTemplate WHERE DeveloperName = :EMAIL_IOP]) {
				map_TemplateNameRecords.put(objET.DeveloperName, objET);
			}

			for (Order objOrder : map_OrderCases.keyset()) {
				Case objCase = map_OrderCases.get(objOrder);
				set_CaseIds.add(objCase.Id);
			}
			map_CaseIdTeamMemberIds = fetchTeamMember(set_CaseIds);

			for (Order objOrder : map_OrderCases.keyset()) {
				try {
					//code for OutboundEmail instance creation---------starts-----------
					EmailTemplate objEmailTemplate = map_TemplateNameRecords.get(EMAIL_IOP);
					Case objCase = map_OrderCases.get(objOrder);
					String strEmailBody = getEmailBody(objEmailTemplate.HtmlValue, objCase, objOrder);
					Messaging.SingleEmailMessage objMessage = createEmailRecord(objEmailTemplate.Subject, objCase, strEmailBody);

					if (list_OrgWideAddresses?.size() > 0) {
						objMessage.setOrgWideEmailAddressId(list_OrgWideAddresses.get(0).Id);
					}

					//code to set cc addresses
					if (objCase.Order_AE_Email__c != null) {
						objMessage.setToAddresses(new List<String>{ objCase.Order_AE_Email__c });
					}

					if (map_CaseIdTeamMemberIds?.containsKey(objCase.Id) && map_CaseIdTeamMemberIds.get(objCase.Id) != null) {
						objMessage.setCcAddresses(map_CaseIdTeamMemberIds.get(objCase.Id));
					}

					map_CaseIdEmailMessageInstances.put(objCase.Id, objMessage);

					EmailMessage objEmailMessage = createEmailMessageRecord(strEmailBody, objCase, objEmailTemplate.Subject, objEmailTemplate.DeveloperName, objMessage, objOrder);
					map_ContactIdsEmailMessageToInsert.put(objCase.ContactId, objEmailMessage);
				} catch (Exception objExeption) {
					ExceptionLogUtil.logException('OrderUtils', 'Intro Email', objExeption.getMessage() + ' ON Line ' + objExeption.getLineNumber(), objExeption.getStackTraceString());
				}
			}

			if (map_CaseIdEmailMessageInstances.size() > 0) {
				Messaging.SendEmailResult[] results;
				if (!Test.isRunningTest()) {
					results = Messaging.sendEmail(map_CaseIdEmailMessageInstances.values(), false);
				}

				if (results != null) {
					for (Messaging.SendEmailResult objResult : results) {
						if (!objResult.isSuccess() && !Test.isRunningTest()) {
							set_ErroredTargetObjectIds.add(objResult.getErrors().get(0).getTargetObjectId());
						}
					}
				}

				if (set_ErroredTargetObjectIds.size() > 0) {
					for (Order objOrder : map_OrderCases.keyset()) {
						Case objCase = map_OrderCases.get(objOrder);
						if (objCase.ContactId != null && set_ErroredTargetObjectIds.contains(objCase.ContactId)) {
							map_ContactIdsEmailMessageToInsert.remove(objCase.ContactId);
						}
					}
				}

				insert map_ContactIdsEmailMessageToInsert.values();
			}
		}
	}

	/*
	 * @Description : Creates EmailMessage record
	 * @Parm        : strBody[html template body], objCase[case record], strSubject[email subject],
	 *               strEmailTemplateName[ email template name], objEmailMessage[messaging singleEmailMessage],
	 *               objOrder[order record]
	 * @Return      : N/A
	 */
	public static EmailMessage createEmailMessageRecord(String strBody, Case objCase, String strSubject, String strEmailTemplateName, Messaging.SingleEmailMessage objEmailMessage, Order objOrder) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}

		EmailMessage objMsg = new EmailMessage(); // Created a EmailMessage and copy all details.
		objMsg.ToAddress = objCase.contactId;
		objMsg.Subject = strSubject;
		objMsg.HtmlBody = strBody;
		objMsg.ParentId = objCase.Id; //Attaching with the case
		objMsg.MessageDate = System.now();
		objMsg.Status = '3';
		objMsg.Email_Template_Name__c = strEmailTemplateName;

		List<String> list_temp = objEmailMessage.getCcAddresses();
		if (list_temp != null && list_temp.size() > 0) {
			objMsg.CcAddress = String.join(list_temp, ',');
		}

		objMsg.FromName = PT_DEFAULT_EMAIL_ADDRESS;
		objMsg.FromAddress = PT_DEFAULT_EMAIL_ADDRESS;

		return objMsg;
	}

	/*
	 * @Description : Creates Messaging.SingleEmailMessage object
	 * @Parm        : strSubject[template subject], objCase[case record], strBody[email body]
	 * @Return      : N/A
	 */
	public static Messaging.SingleEmailMessage createEmailRecord(String strSubject, Case objCase, String strBody) {
		//Add Account Name in Subject
		if (String.isNotBlank(strSubject) && strSubject.containsIgnoreCase('[ACCOUNT NAME]') && objCase != null && objCase.AccountId != null && objCase.Account.Name != null) {
			strSubject = strSubject.replace('[ACCOUNT NAME]', objCase.Account.Name);
		}

		Messaging.SingleEmailMessage objMail = new Messaging.SingleEmailMessage();
		objMail.setSubject(strSubject);
		objMail.setHTMLBody(strBody);
		objMail.setTargetObjectId(objCase.ContactId);
		objMail.setSaveAsActivity(false);
		objMail.setWhatId(objCase.Id);
		objMail.setUseSignature(false);
		return objMail;
	}

	/*
	 * @Description : Replace email body with "Email Macro" records
	 * @Parm        : strTemplateBody[template body], objCase[case record], objOrder[order object]
	 * @Return      : N/A
	 */
	public static String getEmailBody(String strTemplateBody, Case objCase, Order objOrder) {
		if (String.isNotBlank(strTemplateBody) && objCase != null && objOrder != null) {
			String strFormattedMacro = '';
			String strInvitationReference = '';
			if (objOrder.Active_Employee_Count__c != null && objOrder.Active_Employee_Count__c > 0) {
				strTemplateBody = strTemplateBody.replace(ACTIVE_EMPLOYEE_COUNT, String.valueOf(objOrder.Active_Employee_Count__c));
			} else {
				strTemplateBody = removeDynamicText(strTemplateBody, ACTIVE_EMPLOYEE_COUNT);
			}

			if (objOrder.Inactive_Employee_Count__c != null && objOrder.Inactive_Employee_Count__c > 0) {
				strTemplateBody = strTemplateBody.replace(DISMISSED_EMPLOYEE_COUNT, String.valueOf(objOrder.Inactive_Employee_Count__c));
			} else {
				strTemplateBody = removeDynamicText(strTemplateBody, DISMISSED_EMPLOYEE_COUNT);
			}

			if (objOrder.Contractor_Count__c != null && objOrder.Contractor_Count__c > 0) {
				strTemplateBody = strTemplateBody.replace(CONTRACTORS_COUNT, String.valueOf(objOrder.Contractor_Count__c));
			} else {
				strTemplateBody = removeDynamicText(strTemplateBody, CONTRACTORS_COUNT);
			}

			if (String.isNotBlank(objOrder.Invite_Employees_Via_Email__c)) {
				String strMacroIdentifier = IDENTIFIER_ACTIVE_EMPLOYEE + '_' + objOrder.Invite_Employees_Via_Email__c.toLowerCase().replace(' ', '_');
				if (map_RetriveEmailMacro.containsKey(strMacroIdentifier)) {
					strInvitationReference += map_RetriveEmailMacro.get(strMacroIdentifier);
				}
			}

			if (String.isNotBlank(objOrder.Invite_Dismissed_Employees_Via_Email__c)) {
				String strMacroIdentifier = IDENTIFIER_DISMISSED_EMPLOYEE + '_' + objOrder.Invite_Dismissed_Employees_Via_Email__c.toLowerCase().replace(' ', '_');
				if (map_RetriveEmailMacro.containsKey(strMacroIdentifier)) {
					strInvitationReference += map_RetriveEmailMacro.get(strMacroIdentifier);
				}
			}

			if (String.isNotBlank(objOrder.Invite_Contractors_Via_Email__c)) {
				String strMacroIdentifier = IDENTIFIER_CONTRACTOR + '_' + objOrder.Invite_Contractors_Via_Email__c.toLowerCase().replace(' ', '_');
				if (map_RetriveEmailMacro.containsKey(strMacroIdentifier)) {
					strInvitationReference += map_RetriveEmailMacro.get(strMacroIdentifier);
				}
			}

			if (objOrder.States__c?.length() > 0) {
				strTemplateBody = strTemplateBody.replace(STATES, objOrder.States__c);
			} else {
				strTemplateBody = removeDynamicText(strTemplateBody, STATES);
			}

			if (objOrder.Team_Invitation_Preference__c?.length() > 0) {
				strTemplateBody = strTemplateBody.replace(TEAM_INVITATION_PREFERENCE, strInvitationReference);
			} else {
				strTemplateBody = removeDynamicText(strTemplateBody, TEAM_INVITATION_PREFERENCE);
			}

			if (objCase.Account.Name != null) {
				strTemplateBody = strTemplateBody.replace('[ACCOUNT NAME]', objCase.Account.Name);
			}

			if (objCase.Contact_First_Name__c != null) {
				strTemplateBody = strTemplateBody.replace(CONTACT_FIRST_NAME, objCase.Contact_First_Name__c);
			}

			if (objCase.Order_Owner_Name__c != null) {
				strTemplateBody = strTemplateBody.replace(ORDER_OWNER_NAME, objCase.Order_Owner_Name__c);
			}

			if (objCase.Order_Owner_Calendly_Link__c != null) {
				strTemplateBody = strTemplateBody.replace(CALENDELY_LINK, objCase.Order_Owner_Calendly_Link__c);
			} else {
				strTemplateBody = strTemplateBody.replace(CALENDELY_LINK, '');
			}

			if (objCase.Order_Owner_Phone__c != null) {
				strTemplateBody = strTemplateBody.replace(ORDER_OWNER_PHONE, objCase.Order_Owner_Phone__c);
			} else {
				strTemplateBody = strTemplateBody.replace(ORDER_OWNER_PHONE, '');
			}

			if (objCase.Order_Owner_Phone_Extension__c != null) {
				strTemplateBody = strTemplateBody.replace(ORDER_OWNER_PHONE_EXTENSION, objCase.Order_Owner_Phone_Extension__c);
			} else {
				strTemplateBody = strTemplateBody.replace(ORDER_OWNER_PHONE_EXTENSION, '');
			}

			strTemplateBody += '<div style="color: transparent">' + objCase.Case_Reference__c + '</div>';
		}

		return strTemplateBody;
	}

	/*
	 * @Description : Replace static identifiers with null
	 * @Parm        : strTemplateBody[template body], strIdentifier[static identifier]
	 * @Return      : N/A
	 */
	public static String removeDynamicText(String strTemplateBody, String strIdentifier) {
		if (String.isNotBlank(strTemplateBody) && String.isNotBlank(strIdentifier)) {
			strTemplateBody = strTemplateBody.replace(strIdentifier, '');
		}

		return strTemplateBody;
	}

	//Getting EMail Macro to use in email template
	public static Map<String, String> getEmailMacro() {
		if (map_RetriveEmailMacro == null) {
			fetchEmailMacro();
		}
		return map_RetriveEmailMacro;
	}

	/*
	 * @Description : query Email Macro
	 * @Parm        : N/A
	 * @Return      : N/A
	 */
	private static void fetchEmailMacro() {
		map_RetriveEmailMacro = new Map<String, String>();
		for (Email_Macro__c objEmailMacro : [
			SELECT Id, Body__c, Macro_Identifier__c
			FROM Email_Macro__c
			WHERE Carrier__c = NULL AND Macro_Identifier__c != NULL AND Macro_Identifier__c LIKE :'pay_%'
		]) {
			map_RetriveEmailMacro.put(objEmailMacro.Macro_Identifier__c, objEmailMacro.Body__c);
		}
	}

	/*
	 * @Description : query CaseTeamMember records
	 * @Parm        : set_CaseIds[case ids]
	 * @Return      : Map of case and ids of CaseTeamMember
	 */
	private static Map<String, List<Id>> fetchTeamMember(Set<Id> set_CaseIds) {
		Map<String, List<Id>> map_CaseIdCaseTeamMembers = new Map<String, List<Id>>();
		for (CaseTeamMember objMember : [SELECT Id, MemberId, ParentId FROM CaseTeamMember WHERE ParentId = :set_CaseIds]) {
			List<Id> list_MemberIds = new List<Id>();
			if (map_CaseIdCaseTeamMembers.containsKey(objMember.ParentId)) {
				list_MemberIds = (map_CaseIdCaseTeamMembers.get(objMember.ParentId));
			}

			list_MemberIds.add(objMember.MemberId);
			map_CaseIdCaseTeamMembers.put(objMember.ParentId, list_MemberIds);
		}

		return map_CaseIdCaseTeamMembers;
	}
}