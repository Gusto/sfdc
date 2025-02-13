public class UtilitiesFactory {
	public static List<User> list_TicketOwnerUser = new List<User>();
	public static set<String> set_FlexibleTeam = new Set<String>{ 'Implementation Advocate'};
	public static Set<String> set_ExcludeOrderType = new Set<String>{ 'TAdA: No Pre OE Setup', 'TAdA: Pre OE Setup' };
	public static Set<String> set_TADAAndBOROrderType = new Set<String>{ 'BOR', 'BOR + TAdA', 'BOR TAdA Only', 'TAdA: No Pre OE Setup', 'TAdA: Pre OE Setup', 'Renewal Alignment' };
	public static Set<String> set_ExcludeBYBOrderType = new Set<String>{
		'New to Gusto',
		'Same carrier, plan/group level changes',
		'Same carrier, NO plan/group level changes',
		'Carrier switch',
		'New Line of Coverage'
	};
	public static Set<string> set_COCanceled = new Set<String>{ 'Canceled', 'Closed Admin', 'Closed Lost' };
	public static Set<String> set_FWExcludeCOBO = new Set<String>{ 'Closed Admin', 'Closed Lost' };
	static final String USER_PERFIX = '005';
	public static Boolean blnSubmission = false;
	public static String BIZTECH_ERROR_EMAIL = System.Label.BizTech_Error_Email;

	/**
	 * @Author      : Deepika Saini
	 * @Description : Mark the require Re routing field if Owner is Invalid
	 * @Parm        : strTicketOwner - Onwer of Ticket
	 *                strTeam - team of the ticket
	 *                blnIsReRouting - Record should be going to check rerouting or not
	 * @Return      : Boolean - Onwer is valid or not
	 **/
	public static Boolean CheckTicketOwnerIsValidOrNot(String strTicketOwner, String strTeam, Boolean blnIsReRouting) {
		Boolean blnIsOwnerInValid = false;

		if (String.isNotBlank(strTicketOwner)) {
			String strPreFix = String.valueOf(strTicketOwner).left(3).toLowercase();

			//if owner is not user
			if (strPreFix != USER_PERFIX) {
				return blnIsOwnerInValid;
			}

			// In case of Submission, if CO is submitted by RPA User and Ticket is created for RPA User
			// then CO should be reRoute
			if (strTicketOwner.left(15).equals(Label.RPA_Automation_User_Id) && String.isNotBlank(strTeam) && strTeam.equalsIgnoreCase(TicketUtil.TICKET_ROLE_FULFILLMENT)) {
				blnIsOwnerInValid = true;
				return blnIsOwnerInValid;
			}

			list_TicketOwnerUser = [
				SELECT Id, IsActive, UserRole.Name
				FROM User
				WHERE Id = :strTicketOwner
			];

			if (!list_TicketOwnerUser.isEmpty() && blnIsReRouting && !list_TicketOwnerUser[0].IsActive) {
				blnIsOwnerInValid = true;
			}
		}

		return blnIsOwnerInValid;
	}

	public static Map<String, String> CheckLoggedInUserRole() {
		Map<String, String> map_CurrentUserRoles = new Map<String, String>();
		for (User_Skill__c objUserSkill : [
			SELECT Id, Active__c, User_Name__c, User_Role__c, User_Role__r.User__c, Skill__c, Skill__r.Build_Plans__c, Skill_Role__c, Skill_Role_Name__c
			FROM User_Skill__c
			WHERE User_Role__r.User__c = :UserInfo.getUserId()
		]) {
			//Check if Logged in user from Qualification Team
			if (objUserSkill.Skill_Role_Name__c.indexof('Qualification') > -1) {
				//In case of Active Core
				if (objUserSkill.Active__c) {
					map_CurrentUserRoles.put('Qualification', objUserSkill.Skill_Role__c);
				} else {
					//If Core is not active then check flex
					if (objUserSkill.Skill_Role_Name__c.indexof('Flex') > -1) {
						map_CurrentUserRoles.put('Qualification Flex', objUserSkill.Skill_Role__c);
					}
					//If Core is not action then check training
					if (objUserSkill.Skill_Role_Name__c.indexof('Training') > -1) {
						map_CurrentUserRoles.put('Qualification Training', objUserSkill.Skill_Role__c);
					}
				}
			}

			//BY:PR, Date: JUly/21/2020 ,Desc: Check if Logged in user from Submission Team
			if (objUserSkill.Skill_Role_Name__c.indexof('Submission') > -1) {
				if (objUserSkill.Active__c) {
					map_CurrentUserRoles.put('Submission', objUserSkill.Skill_Role__c);
				} else {
					//If Core is not active then check flex
					if (objUserSkill.Skill_Role_Name__c.indexof('Flex') > -1) {
						map_CurrentUserRoles.put('Submission Flex', objUserSkill.Skill_Role__c);
					}
					//If Core is not action then check training
					if (objUserSkill.Skill_Role_Name__c.indexof('Training') > -1) {
						map_CurrentUserRoles.put('Submission Training', objUserSkill.Skill_Role__c);
					}
				}
			}
			//BY:AKS, Date: JUly/23/2020 ,Desc: Check if Logged in user from Confirmation Team
			if (objUserSkill.Skill_Role_Name__c.indexof('Confirmation') > -1) {
				if (objUserSkill.Active__c) {
					map_CurrentUserRoles.put('Confirmation', objUserSkill.Skill_Role__c);
				} else {
					//If Core is not active then check flex
					if (objUserSkill.Skill_Role_Name__c.indexof('Flex') > -1) {
						map_CurrentUserRoles.put('Confirmation Flex', objUserSkill.Skill_Role__c);
					}
					//If Core is not action then check training
					if (objUserSkill.Skill_Role_Name__c.indexof('Training') > -1) {
						map_CurrentUserRoles.put('Confirmation Training', objUserSkill.Skill_Role__c);
					}
				}
			}
		}
		return map_CurrentUserRoles;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : ReAssign Ticket Owner and BO in case user is inactive or role changed
	 * @Parm        : objTicket - ticket record
	 *                list_BO - Benefit order list
	 *                blnIsNoStatusUpdate - status should be changed or not
	 * @Return      : Boolean - reassignment of IA true or not
	 **/
	public static Boolean reAssignIAForInvalidTicketOwner(Ticket__c objTicket, List<Benefit_Order__c> list_BO, Boolean blnIsNoStatusUpdate) {
		if (objTicket != null && list_BO != null && list_BO.size() > 0 && blnIsNoStatusUpdate != null) {
			String strSubTeam = objTicket.Sub_Team__c;

			if (
				list_BO[0].OwnerId == list_BO[0].Opportunity__r.OwnerId &&
				list_BO[0].Opportunity__r.Owner_Role_Name__c != null &&
				list_BO[0].Opportunity__r.Owner_Role_Name__c == FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST
			) {
				strSubTeam = FWManageRoleUtil.ROLE_RENEWAL_SPECIALIST;
			}

			//Check for Current IA validity (is IA still part of the team or not)
			List<User_Skill__c> list_UserSkills = [
				SELECT Id
				FROM User_Skill__c
				WHERE
					User_Role__r.User__c = :objTicket.OwnerId
					AND User_Skill_Role_Name__c = :strSubTeam
					AND Skill_Type__c = :TicketUtil.TICKET_OWNER_ROLE_TYPE_CORE
					AND User_Role__r.User__r.IsActive = TRUE
					AND Active__c = TRUE
				LIMIT 1
			];

			//If IA is not part of the Team
			if (list_UserSkills.isEmpty()) {
				Boolean blnIsCONotApproved = false;
				if (list_BO[0].Order_Status__c == 'Fulfilled' && blnIsNoStatusUpdate) {
					objTicket.OwnerId = list_BO[0].OwnerId;
					for (Carrier_Order__c objCO : [
						SELECT Id, Implementation_Stage__c
						FROM Carrier_Order__c
						WHERE Implementation_Stage__c NOT IN :UtilitiesFactory.set_COCanceled AND Benefit_Order__c = :list_BO[0].Id
					]) {
						if (objCO.Implementation_Stage__c != 'Approved') {
							blnIsCONotApproved = true;
							break;
						}
					}
				}
				//If "No Open BO & CO" + "no Status Change" then> Assign the ticket to the queue
				if (list_BO[0].Order_Status__c == 'Fulfilled' && !blnIsCONotApproved && blnIsNoStatusUpdate) {
					objTicket.OwnerId = Label.Member_Fulfillment_Queue;
				} else {
					//else get the next IA canditate + Update related BO owner + Update New Ticket owner
					FWAssignmentUtil objController = new FWAssignmentUtil();
					List<Benefit_Order__c> list_UpdatedBOs = objController.processAdvocateAssignmentForBO(list_BO, true, null, null, null, new Map<Id, Id>());
					if (list_UpdatedBOs != null && !list_UpdatedBOs.isEmpty()) {
						list_BO[0].OwnerId = list_UpdatedBOs[0].OwnerId;
						list_BO[0].Assignment_Message__c = list_UpdatedBOs[0].Assignment_Message__c;
						objTicket.OwnerId = list_UpdatedBOs[0].OwnerId;
						return true;
					}
				}
			}
		}
		return false;
	}

	public static Boolean CheckLoggedInUser() {
		Boolean blnIsAdmin = false;
		User objUser = [SELECT Id, Profile.Name FROM User WHERE Id = :userinfo.getUserId() LIMIT 1];
		if (objUser.Profile.Name.indexOf('System Administrator') > -1) {
			blnIsAdmin = true;
		}
		return blnIsAdmin;
	}
	//By AKS dated 3nd June to get picklist value for Flexible workforce
	public static List<SelectOption> getPickListValues(String Objectname, String FieldName, Set<String> set_ExcludedList) {
		List<SelectOption> options = new List<SelectOption>();
		Schema.DescribeSObjectResult sobject_describe = Schema.getGlobalDescribe().get(ObjectName).getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pick_list_values = field_map.get(FieldName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
		for (Schema.PicklistEntry objPLV : pick_list_values) {
			//for all values in the picklist list
			if (blnSubmission) {
				if (set_ExcludedList == null || (set_ExcludedList != null && set_ExcludedList.contains(objPLV.getValue()) == false)) {
					options.add(new SelectOption(objPLV.getValue(), objPLV.getLabel()));
				}
			} else {
				if (set_ExcludeOrderType.contains(objPLV.getValue()) == false) {
					//Exclude TADA value
					if (set_ExcludedList == null || (set_ExcludedList != null && set_ExcludedList.contains(objPLV.getValue()) == false)) {
						options.add(new SelectOption(objPLV.getValue(), objPLV.getLabel()));
					}
				}
			}
		}
		return options;
	}

	//By AKS dated 3nd June for Skill Type for Flexible workforce
	public static List<SelectOption> RetriveSkillType() {
		List<SelectOption> list_Options = new List<SelectOption>();
		list_Options.add(new SelectOption('', '--None--'));
		list_Options.add(new SelectOption('Core', 'Core Skills'));
		list_Options.add(new SelectOption('Flex', 'Flex Skills'));
		list_Options.add(new SelectOption('Training', 'Training Skills'));

		return list_Options;
	}

	//By AKS dated 2nd June for Setup Filter Criteria for Flexible workforce
	public static List<SelectOption> RetriveSkillSetupCriteria() {
		List<SelectOption> list_CriteriaOptions = new List<SelectOption>();
		list_CriteriaOptions.add(new SelectOption('Region', 'Region'));
		list_CriteriaOptions.add(new SelectOption('State', 'State'));
		list_CriteriaOptions.add(new SelectOption('Carrier POD', 'Carrier POD'));
		list_CriteriaOptions.add(new SelectOption('Order Type', 'Order Type'));
		list_CriteriaOptions.add(new SelectOption('Tier', 'Tier'));
		list_CriteriaOptions.add(new SelectOption('Partner', 'Partner'));
		list_CriteriaOptions.add(new SelectOption('Tada', 'Tada'));
		list_CriteriaOptions.add(new SelectOption('Confirmation', 'Confirmation'));
		list_CriteriaOptions.add(new SelectOption('Benefits Big Desk', 'Benefits Big Desk'));
		list_CriteriaOptions.add(new SelectOption('Coverage type', 'Coverage type'));
		list_CriteriaOptions.add(new SelectOption('Order Allocation', 'Order Allocation'));
		return list_CriteriaOptions;
	}

	//By DS dated 8nd June for Role Type for Flexible workforce
	public static List<SelectOption> RetriveRoleType() {
		List<SelectOption> list_Options = new List<SelectOption>();
		list_Options.add(new SelectOption('', '--None--'));
		list_Options.add(new SelectOption('Implementation Advocate', 'Implementation Advocate'));
		list_Options.add(new SelectOption('Carrier IO', 'Carrier IO'));
		list_Options.add(new SelectOption('BYB Advocate', 'BYB Advocate'));
		list_Options.add(new SelectOption('Payroll Transfer Advocate', 'Payroll Transfer Advocate'));
		list_Options.add(new SelectOption('Payroll Transfer Facilitator', 'Payroll Transfer Facilitator'));
		list_Options.add(new SelectOption('Benefit Transfer', 'Benefit Transfer'));
		list_Options.add(new SelectOption('Benefits Advising', 'Benefits Advising'));
		//list_Options.add(new SelectOption('Account Specialist', 'Account Specialist'));
		return list_Options;
	}

	public static Map<String, String> getActiveState() {
		Map<String, String> map_ActiveStates = new Map<String, String>();
		// Query all State from custom setting
		// Making query instead of get All value because I have to take data sort by state name
		for (State_Name_to_abbreviations_Mapping__c objSNAM : [SELECT id, State_Abbreviation__c, State_Name__c, HI_Active__c FROM State_Name_to_abbreviations_Mapping__c ORDER BY State_Name__c]) {
			if (objSNAM.HI_Active__c) {
				map_ActiveStates.put(objSNAM.State_Abbreviation__c, objSNAM.State_Name__c);
			}
		}
		return map_ActiveStates;
	}

	public static Set<String> getCarrierNames(string strTeam) {
		Set<String> set_CarrierName = new Set<String>();
		String strQuery = 'SELECT Id, Carrier_Name__c FROM Flexible_Workforce_Carriers__c WHERE Name != null';
		if (string.isNotBlank(strTeam) && (strTeam == 'Qualification' || strTeam == 'Submission')) {
			strQuery = 'SELECT Id, Carrier_Name__c FROM Flexible_Workforce_Carriers__c where Type__c = \'Both\' OR ';
			strQuery = strQuery + 'Type__c = \'' + strTeam + '\' ';
		}

		strQuery = strQuery + ' ORDER BY Carrier_Name__c ';
		// Query all State from custom setting
		for (Flexible_Workforce_Carriers__c objFWName : Database.query(strQuery)) {
			set_CarrierName.add(objFWName.Carrier_Name__c);
		}
		return set_CarrierName;
	}

	//Written by AKS dated 2nd April
	public static Set<String> RetriveUserRole(Id IdUserId) {
		Set<String> set_CurrentUserRoles = new Set<String>();
		for (User_Skill__c objUserSkill : [
			SELECT Id, User_Name__c, User_Role__c, User_Role__r.User__c, Skill__c, Skill__r.Build_Plans__c, Skill_Role_Name__c
			FROM User_Skill__c
			WHERE User_Role__r.User__c = :IdUserId
		]) {
			set_CurrentUserRoles.add(objUserSkill.Skill_Role_Name__c);
		}
		return set_CurrentUserRoles;
	}

	//BY:PR, DAte: May/11/2020, Desc: https://app.asana.com/0/1149920908637905/1170649748837574/f
	public static Boolean isBTRenewalDateValid(Date dtRenewalDate) {
		Boolean isValid = false;
		Date dtDateAfterOneYearFromToday = System.today().addYears(1);
		if (dtRenewalDate != null && dtRenewalDate > System.today() && (dtRenewalDate.day() == 1 || dtRenewalDate.day() == 15) && dtRenewalDate <= dtDateAfterOneYearFromToday) {
			isValid = true;
		}

		return isValid;
	}

	public static List<String> accessibleFields(String objectName, String prefix) {
		Map<String, Schema.SObjectField> objectFields = Utils.getSObjectDescribe(objectName).fields.getMap();
		List<String> fieldsList = new List<String>();
		for (String fieldName : objectFields.keySet()) {
			if (objectFields.get(fieldName).getDescribe().isAccessible()) {
				if (prefix != null && prefix != '') {
					fieldName = prefix + '.' + objectFields.get(fieldName).getDescribe().getName();
				} else {
					fieldName = objectFields.get(fieldName).getDescribe().getName();
				}
				fieldsList.add(fieldName);
			}
		}
		return fieldsList;
	}

	public static String processField(sObject obj, String fieldName) {
		if (obj.get(fieldName) == null) {
			return '';
		}

		DescribeSObjectResult dsor = obj.getSObjectType().getDescribe();
		DescribeFieldResult dfr = dsor.fields.getMap().get(fieldName).getDescribe();

		if (dfr.getType().name() == 'DateTime') {
			DateTime dt = (dateTime) obj.get(fieldName);

			return dt.formatGMT('yyyy-MM-dd HH:mm');
		} else if (dfr.getType().name() == 'Date') {
			Date d = (Date) obj.get(fieldName);
			Datetime dt = datetime.newInstance(d.year(), d.month(), d.day());
			return dt.formatGMT('yyyy-MM-dd');
		}

		return String.valueof(obj.get(fieldName));
	}

	public static List<String> caseRelevantFields() {
		List<String> fieldsNames = new List<String>();
		fieldsNames.addAll(accessibleFields('Case', ''));
		fieldsNames.addAll(accessibleFields('Account', 'Account'));
		fieldsNames.addAll(accessibleFields('Contact', 'Contact'));
		return fieldsNames;
	}

	public static String getCaseQuery(Id idCase) {
		String strCaseQuery = 'SELECT ' + String.join(caseRelevantFields(), ',') + ' FROM Case WHERE Id = \'' + String.valueof(idCase) + '\'';
		return strCaseQuery;
	}

	public static Case getFullCase(Id idCase) {
		List<SObject> obs = Database.query(getCaseQuery(idCase));
		Case objCase = (Case) obs[0];
		return objCase;
	}

	public static Boolean isOverride(String strOverrideName) {
		Boolean blnIsOverride = false;
		List<Override_Rule__mdt> list_ORules = new List<Override_Rule__mdt>();
		for (Override_Rule__mdt objOverrideRule : Override_Rule__mdt.getAll().values()) {
			if (objOverrideRule.MasterLabel == strOverrideName && objOverrideRule.Override__c == true) {
				list_ORules.add(objOverrideRule);
			}
		}

		if (list_ORules.size() > 0)
			blnIsOverride = true;
		else
			blnIsOverride = false;

		return blnIsOverride;
	}

	public static Map<String, String> readStringAsMap(string strSavedData) {
		Map<String, String> map_ConvertedFromString = new Map<String, String>();

		if (String.isNotBlank(strSavedData)) {
			List<String> lst_individualDataStr = new List<String>();
			if (strSavedData.indexOf(',') > -1) {
				lst_individualDataStr = strSavedData.split(',');
			} else {
				lst_individualDataStr.add(strSavedData);
			}
			if (lst_individualDataStr.size() > 0) {
				for (String strObjectIds : lst_individualDataStr) {
					if (strObjectIds.indexOf('=>') > -1) {
						list<string> lstTemp = strObjectIds.split('=>');
						if (lstTemp != null && lstTemp.size() > 0) {
							map_ConvertedFromString.put(lstTemp.get(0).trim(), lstTemp.get(1).trim());
						}
					}
				}
			}
		}
		return map_ConvertedFromString;
	}

	public static List<HIFullfillmentEventWrapper> getDecryptedHIEventStr(List<HI_Fulfillment_Event__c> list_FulfillmentList) {
		List<HIFullfillmentEventWrapper> list_ObjHIFullFillWrapper = new List<HIFullfillmentEventWrapper>();
		Blob blobEncryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (HI_Fulfillment_Event__c objHiFulfill : list_FulfillmentList) {
			if (objHiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || objHiFulfill.Id__c == null) {
				continue;
			}
			objHiFulfill.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objHiFulfill.Message__c = '';
			try {
				Blob blobDecryptedBlob = EncodingUtil.base64Decode(objHiFulfill.Event_Info_Encrypted__c);
				String strDeCryptedText = EncryptionUtils.getDecryptedText(blobEncryptionKey, blobDecryptedBlob);
				HIFullfillmentEventWrapper objHIFulFillEventWrapper = new HIFullfillmentEventWrapper();
				objHIFulFillEventWrapper.jsonString = strDeCryptedText;
				objHIFulFillEventWrapper.objHiFulFillmentEvent = objHiFulfill;
				list_ObjHIFullFillWrapper.add(objHIFulFillEventWrapper);
			} catch (Exception e) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Decryption failed.', objHiFulfill);
				continue;
			}
		}

		return list_ObjHIFullFillWrapper;
	}

	@future
	public static void deleteRecords(Set<String> set_SkillId) {
		try {
			if (set_SkillId != null && set_SkillId.size() > 0) {
				List<Skill__c> list_Skill = [SELECT Id FROM Skill__c WHERE Id IN :set_SkillId];
				delete list_Skill;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UtilitiesFactory', 'deleteRecords', ex);
		}
	}

	//[Bhagat & Sanjay] [2 Sep 2020] : We can use this method to send email to System Admin.
	public static void sendExceptionEmail(Exception ex, String strEmailSubject, String strAdditionalMessage) {
		//If required, we will move To address in custom label.
		String strToAddresses = BIZTECH_ERROR_EMAIL;
		List<String> list_ToAddresses = strToAddresses.split(';');

		strEmailSubject = strEmailSubject + ' caused by: ' + ex.getMessage();
		String strEmailBody =
			strEmailSubject +
			':\n\n' +
			'Caused by: ' +
			ex.getCause() +
			'\n' +
			'Line Number: ' +
			ex.getLineNumber() +
			'\n' +
			'Type: ' +
			ex.getTypeName() +
			'\n' +
			'Message: ' +
			ex.getMessage() +
			'\n' +
			'Stack Trace: ' +
			ex.getStackTraceString();
		if (String.isNotBlank(strAdditionalMessage)) {
			strEmailBody = strEmailBody + '\n\n' + strAdditionalMessage;
		}

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setSubject(strEmailSubject);
		email.setPlainTextBody(strEmailBody);
		email.setToAddresses(list_ToAddresses);
		if (!Test.isRunningTest()) {
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
		}
	}

	//[Bhagat] [2 Sep 2020] : In Batch_Email_Settings__c custom setting, we can maintain the batch/future class status.
	//and show the success or fail message on user screen.
	public static List<Batch_Email_Settings__c> fetchBatchEmailSettings(Id idLoginUser) {
		List<Batch_Email_Settings__c> list_BatchEmailSetting = new List<Batch_Email_Settings__c>();
		for (Batch_Email_Settings__c objSetting : [
			SELECT Id, SetupOwnerId, Running_Mass_Email_Batch__c, Mass_Email_Status_Message__c
			FROM Batch_Email_Settings__c
			WHERE SetupOwnerId != NULL AND SetupOwnerId = :idLoginUser
			LIMIT 1
		]) {
			list_BatchEmailSetting.add(objSetting);
		}

		if (list_BatchEmailSetting.size() == 0) {
			list_BatchEmailSetting.add(new Batch_Email_Settings__c(SetupOwnerId = idLoginUser));
		}
		return list_BatchEmailSetting;
	}

	static final String FIELD_NAME_KEY = 'FieldNames', RELATIONSHIP_NAME_KEY = 'RelationshipName';
	static Map<String, Object> map_HistoryTrackingInfo;
	static Map<String, Map<String, String>> map_FieldInfoForHistoryTracking;

	/**
	 * @Author      : Neha Dabas
	 * @Description : Fetch fields for a particular sObject which are eligible for Field History Tracking
	 * @Parm        : null
	 * @Return      : Map<String, Object> - [objectName, Field_History_Tracking_Configuration__mdt]
	 **/
	public static Map<String, Object> fetchHistoryTrackingInfo() {
		if (map_HistoryTrackingInfo != null && !map_HistoryTrackingInfo.isEmpty()) {
			return map_HistoryTrackingInfo;
		}

		map_HistoryTrackingInfo = new Map<String, Object>();
		List<Field_History_Tracking_Configuration__mdt> list_FieldHistoryTrackingConfig = new List<Field_History_Tracking_Configuration__mdt>();

		for (Field_History_Tracking_Configuration__mdt objFieldHistoryTrack : Field_History_Tracking_Configuration__mdt.getAll().values()) {
			if (objFieldHistoryTrack.Relationship_Field_Name__c != null) {
				list_FieldHistoryTrackingConfig.add(objFieldHistoryTrack);
			}
		}

		if (list_FieldHistoryTrackingConfig != null && !list_FieldHistoryTrackingConfig.isEmpty()) {
			for (Field_History_Tracking_Configuration__mdt objHistoryTrackingSetting : list_FieldHistoryTrackingConfig) {
				Set<String> set_FieldsToTrack = new Set<String>(objHistoryTrackingSetting.Field_Names__c?.toLowerCase().split(';'));

				Map<String, Object> map_HistoryTracking = new Map<String, Object>();
				map_HistoryTracking.put(FIELD_NAME_KEY, set_FieldsToTrack);
				map_HistoryTracking.put(RELATIONSHIP_NAME_KEY, objHistoryTrackingSetting.Relationship_Field_Name__c);
				map_HistoryTrackingInfo.put(objHistoryTrackingSetting.DeveloperName, map_HistoryTracking);
			}
		}

		return map_HistoryTrackingInfo;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Fetch fields Info for each field that needs to be history tracked
	 * @Parm        : strObjName - Object name
	 *                idRecord - Record Ids
	 * @Return      : Map<String, String> - [objectName, FieldInfo]
	 **/
	public static Map<String, String> fetchFieldInfoForHistoryTrack(String strObjName, Id idRecord) {
		Map<String, String> map_FieldInfo = new Map<String, String>();

		if (map_HistoryTrackingInfo == null || map_HistoryTrackingInfo.isEmpty() || !map_HistoryTrackingInfo.containsKey(strObjName)) {
			return map_FieldInfo;
		}

		if (map_FieldInfoForHistoryTracking != null && !map_FieldInfoForHistoryTracking.isEmpty() && map_FieldInfoForHistoryTracking.containsKey(strObjName)) {
			return map_FieldInfoForHistoryTracking.get(strObjName);
		}

		if (map_FieldInfoForHistoryTracking == null) {
			map_FieldInfoForHistoryTracking = new Map<String, Map<String, String>>();
		}

		String strObjectAPIName = idRecord.getSObjectType().getDescribe().getName();

		Map<String, Schema.SObjectField> map_Fields = Utils.getSObjectDescribe(strObjectAPIName).fields.getMap();
		Set<String> set_FieldsToTrack = (Set<String>) ((Map<String, Object>) map_HistoryTrackingInfo.get(strObjName)).get(FIELD_NAME_KEY);

		for (String strFieldName : set_FieldsToTrack) {
			if (map_Fields.containsKey(strFieldName)) {
				map_FieldInfo.put(strFieldName, map_Fields.get(strFieldName).getDescribe().getLabel());
			}
		}

		map_FieldInfoForHistoryTracking.put(strObjName, map_FieldInfo);
		return map_FieldInfo;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : To record history data for changed record
	 * @Parm        : objNew - New record
	 *                objOld - Old record
	 *                strObjName - Object name
	 * @Return      : List<Field_History__c> - List of Field History
	 **/
	public static List<Field_History__c> createHistoryTracking(sObject objNew, sObject objOld, String strObjName) {
		List<Field_History__c> list_FieldHistory = new List<Field_History__c>();
		Set<String> set_FieldsToTrack;
		Map<String, Object> map_Response = fetchHistoryTrackingInfo();
		Id idLoggedInUser = userInfo.getUserId();

		if (String.isBlank(strObjName) || map_Response == null || map_Response.isEmpty() || !map_Response.containsKey(strObjName)) {
			return list_FieldHistory;
		}

		Map<String, Object> map_HistoryTrackingConfig = (Map<String, Object>) map_Response.get(strObjName);
		set_FieldsToTrack = (Set<String>) map_HistoryTrackingConfig.get(FIELD_NAME_KEY);
		String strRelationshipName = (String) map_HistoryTrackingConfig.get(RELATIONSHIP_NAME_KEY);

		if (objNew == null || objOld == null || set_FieldsToTrack == null || set_FieldsToTrack.isEmpty() || String.isBlank(strRelationshipName)) {
			return list_FieldHistory;
		}

		//Get Field Labels for the eligible Fields which are to be tracked
		Id idRecord = (Id) objNew.get('Id');
		Map<String, String> map_FieldNameToLabel = fetchFieldInfoForHistoryTrack(strObjName, idRecord);

		for (String strFieldName : set_FieldsToTrack) {
			if (objOld.get(strFieldName) != objNew.get(strFieldName)) {
				String strOldValue = '' + objOld.get(strFieldName);
				strOldValue = strOldValue.length() > 255 ? strOldValue.substring(0, 255) : strOldValue;

				String strNewValue = '' + objNew.get(strFieldName);
				strNewValue = strNewValue.length() > 255 ? strNewValue.substring(0, 255) : strNewValue;

				Field_History__c objFieldHistory = new Field_History__c(Field_Name__c = strFieldName, New_Value__c = strNewValue, Old_Value__c = strOldValue, Record_Id__c = idRecord);

				objFieldHistory.put(strRelationshipName, objNew.get('Id'));

				if (map_FieldNameToLabel.containsKey(strFieldName)) {
					objFieldHistory.Field_Label__c = map_FieldNameToLabel.get(strFieldName);
				}

				list_FieldHistory.add(objFieldHistory);
			}
		}

		return list_FieldHistory;
	}

	/*
	 * Author       :   Neha Dabas
	 * Created On   :   5-Oct-2020
	 * Description  :   Fetch fields for a particular sObject which are eligible for Field History Tracking
	 * Parameters   :   strObjectName - This needs to be same as DeveloperName for the corresponding metadata record. eg. for Carrier Order, it is Carrier_Order
	 */
	public static Map<String, Object> fetchHistoryTrackingFieldNames(String strObjectName) {
		Map<String, Object> map_Response = new Map<String, Object>();
		Set<String> set_FieldsToTrack = new Set<String>();
		String strObjRelationshipName = '';
		if (String.isBlank(strObjectName)) {
			return map_Response;
		}
		List<Field_History_Tracking_Configuration__mdt> list_EligibleFields = new List<Field_History_Tracking_Configuration__mdt>();
		list_EligibleFields = [SELECT Field_Names__c, Relationship_Field_Name__c FROM Field_History_Tracking_Configuration__mdt WHERE DeveloperName = :strObjectName LIMIT 1];
		if (list_EligibleFields != null && !list_EligibleFields.isEmpty() && String.isNotBlank(list_EligibleFields[0].Field_Names__c)) {
			set_FieldsToTrack.addAll(list_EligibleFields[0].Field_Names__c.toLowerCase().split(';'));
			strObjRelationshipName = list_EligibleFields[0].Relationship_Field_Name__c;
		}
		map_Response.put(FIELD_NAME_KEY, set_FieldsToTrack);
		map_Response.put(RELATIONSHIP_NAME_KEY, strObjRelationshipName);
		return map_Response;
	}

	/*
	 * Author       :   Neha Dabas
	 * Description  :   To record history data for changed reocrds
	 * Created On   :   9-Oct-2020
	 * Parameters   :   strObjectName - This needs to be same as DeveloperName for the corresponding metadata record. eg. for Carrier Order, it is Carrier_Order
	 */
	public static void setHistoryTracking(List<SObject> list_NewValues, Map<Id, SObject> map_OldValues, String strObjName) {
		if (String.isBlank(strObjName)) {
			return;
		}
		Set<String> set_FieldsToTrack;
		Map<String, Object> map_Response = fetchHistoryTrackingFieldNames(strObjName);
		if (map_Response == null || map_Response.isEmpty() || !map_Response.containsKey(FIELD_NAME_KEY)) {
			return;
		}
		set_FieldsToTrack = (Set<String>) map_Response.get(FIELD_NAME_KEY);

		if (list_NewValues == null || list_NewValues.isEmpty() || map_OldValues == null || map_OldValues.isEmpty() || set_FieldsToTrack == null || set_FieldsToTrack.isEmpty()) {
			return;
		}
		String strRelationshipName = map_Response.containsKey(RELATIONSHIP_NAME_KEY) ? (String) map_Response.get(RELATIONSHIP_NAME_KEY) : '';
		List<Field_History__c> list_FieldHistory = new List<Field_History__c>();
		Id idLoggedInUser = userInfo.getUserId();

		//Get Field Labels for the eligible Fields which are to be tracked
		Id idRecordId = (Id) list_NewValues[0].get('Id');
		String strObjectAPIName = idRecordId.getSObjectType().getDescribe().getName();
		Map<String, Schema.SObjectField> map_Fields = Schema.getGlobalDescribe().get(strObjectAPIName).getDescribe().fields.getMap();
		Map<String, String> map_FieldNameToLabel = new Map<String, String>();

		for (String strFieldName : map_Fields.keySet()) {
			if (set_FieldsToTrack.contains(strFieldName)) {
				map_FieldNameToLabel.put(strFieldName, map_Fields.get(strFieldName).getDescribe().getLabel());
			}
		}

		//Iterate over the object records to check if there was a change made to relevant fields and then create history record for the same
		for (SObject objNew : list_NewValues) {
			SObject objOld = map_OldValues.get(objNew.Id);
			for (String strFieldName : set_FieldsToTrack) {
				if (objOld.get(strFieldName) != objNew.get(strFieldName)) {
					String strOldValue = '' + objOld.get(strFieldName);
					strOldValue = strOldValue.length() > 255 ? strOldValue.substring(0, 255) : strOldValue;

					String strNewValue = '' + objNew.get(strFieldName);
					strNewValue = strNewValue.length() > 255 ? strNewValue.substring(0, 255) : strNewValue;
					Field_History__c objFieldHistory = new Field_History__c(
						Field_Name__c = strFieldName,
						New_Value__c = strNewValue,
						Old_Value__c = strOldValue,
						Record_Id__c = (String) objNew.get('Id')
					);
					if (String.isNotBlank(strRelationshipName)) {
						objFieldHistory.put(strRelationshipName, objNew.get('Id'));
					}
					if (map_FieldNameToLabel.containsKey(strFieldName)) {
						objFieldHistory.Field_Label__c = map_FieldNameToLabel.get(strFieldName);
					}
					list_FieldHistory.add(objFieldHistory);
				}
			}
		}
		if (!list_FieldHistory.isEmpty()) {
			insert list_FieldHistory;
		}
	}
}