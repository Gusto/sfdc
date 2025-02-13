/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * Created by............: <<Lirik>>
 * Test Classes----------: <<UR_UtilityCtrl>>
 * Description...........: <<This is helper class. All the global functionality should be impelement in this class.>>
 *-------------------------------------------------------------------------------*/
public without sharing class UR_UtilityCtrl {
	public static String strReplyEmail = Label.UR_ReplyEmail;
	public static Id orgWideEmail_NoReply = null;
	public static Id orgWideEmailToOwner = null;
	public static Map<String, String> emailStatusMap = new Map<String, String>();
	public static Id UXResearch_SentEmail_FolderId = null;
	public static Integer maxCSVRows = 100;
	public static Map<String, List<Selectoption>> searchMap = new Map<String, List<Selectoption>>();
	public static List<selectOption> yesNoOption = new List<selectOption>();
	public static String loginUserProfileName = '';
	public static Boolean isProjectWriteAccess;
	public static final String PROJECT_STATUS_COMPLETE = 'Complete';
	public static final Integer MAX_BATCH_LIMIT = 100;
	public static final String APEX_HOLDING_JOB_STATUS = 'Holding';
	public static final String EXCEED_APEX_JOB_MSG = 'Currently Gusto Salesforce is over batch job limit, try again in 10-15 minutes. If it still isn’t working, report to Scout admin so they can help.';

	public static String strProjectDetail =
		'SELECT Id,Research_Project_Master__c,NDA_Send__c,Blacklist__c, ' +
		'Opt_Out__c,Reason__c,Incentive__c,Unread_Email__c,' +
		'Project_Name__c,Project_Id__c,Screener_URL__c,Contact__c,' +
		'Contact__r.AccountId, Contact__r.Account.Name, Contact__r.Account.ZP_Company_ID__c, ' +
		'Contact__r.ZP_User_Id__c, Contact__r.Employee_Id__c, Contact__r.Account.ZP_Firm_ID__c, ' +
		'Contact__r.Email,Contact__r.Name, Comment__c,' +
		'Research_Participant_Status__c, Researcher_Name__c, Calendly_URL__c, Company_Name__c, ' +
		'Date_of_Attended__c, Incentive_Amount__c, Length_of_Interview__c,  Locked__c, NDA_URL__c, ' +
		'Research_Participant_Status_Number__c, Study_End_Date__c, Study_Start_Date__c, ' +
		'Participant_Email__c FROM Research_Project_Detail__c';

	//Initialize static variables.
	static {
		for (OrgWideEmailAddress owEmailList : [
			SELECT Id, DisplayName
			FROM OrgWideEmailAddress
			WHERE DisplayName = 'UX Research' OR DisplayName = 'no-reply@gusto.com'
		]) {
			if (owEmailList.DisplayName == 'UX Research') {
				orgWideEmail_NoReply = owEmailList.id;
			} else {
				orgWideEmailToOwner = owEmailList.id;
			}
		}

		emailStatusMap.put('Send survey or screener', 'Contacted');
		emailStatusMap.put('Invite to Interview', 'Invited');
		emailStatusMap.put('Confirm details about study & send NDA', '');
		emailStatusMap.put('Send Reminder', '');
		emailStatusMap.put('Follow up after study', '');
		emailStatusMap.put('Cancel session', 'Canceled');

		List<Folder> folderlist = [SELECT ID, DeveloperName, Name FROM Folder WHERE DeveloperName = 'UX_Research_Sent_Email'];
		if (folderlist.size() > 0) {
			UXResearch_SentEmail_FolderId = folderlist[0].id;
		}

		yesNoOption.add(new selectOption('', '--None--'));
		yesNoOption.add(new selectOption('Yes', 'Yes'));
		yesNoOption.add(new selectOption('No', 'No'));

		searchMap = new Map<String, List<Selectoption>>();
		processSearchMap();
		loginUserProfileName = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
	}

	//This method parse CSV file rows.
	public static List<List<String>> parseCSV(string contents, boolean fromSurvey) {
		List<List<String>> allData = new List<List<String>>();
		try {
			List<String> lines = new List<String>();
			if (contents.length() < 100000) {
				lines = contents.split('\n');
			} else {
				Integer startIndex = 0;
				Integer endIndex = 0;
				Integer csvLength = contents.length();
				while (startIndex < csvLength) {
					endIndex = contents.indexOf('\n', startIndex);
					if (endIndex == -1) {
						endIndex = csvLength;
					}
					lines.add(contents.subString(startIndex, endIndex));
					startIndex = endIndex + 1;
				}
			}

			if (fromSurvey == true) {
				allData = callSurveyDataParsing(lines);
			} else {
				allData = callDataParsing(lines);
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_UtilityCtrl', 'parseCSV', ex.getMessage(), ex.getStackTraceString());
		}
		return allData;
	}

	// This method checked, login user have UX project record access or not.
	public static boolean IsEditAccess(string recId) {
		boolean isEditAccess = false;
		isProjectWriteAccess = false;
		List<Research_Project_Master__share> lstUsrAccess = [
			SELECT AccessLevel
			FROM Research_Project_Master__share
			WHERE ParentId = :recId AND UserOrGroupId = :UserInfo.getUserId()
			LIMIT 1
		];

		if (lstUsrAccess != null && lstUsrAccess.size() > 0) {
			if (lstUsrAccess[0].AccessLevel != 'Read') {
				isEditAccess = true;
				isProjectWriteAccess = true;
			}
		}

		List<Profile> userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
		if (userProfile.size() > 0 && 'Gusto UX Research Admin'.equalsIgnoreCase(userProfile[0].Name)) {
			//"Gusto UX Research Admin" profile user can access any of the UXR Scout records.
			isEditAccess = true;
			isProjectWriteAccess = true;
		}
		//If user has Edit access then check Project is complete or not
		List<Research_Project_Master__c> lstProject = [
			SELECT id
			FROM Research_Project_Master__c
			WHERE Id = :recId AND Project_Status__c != 'Complete'
		];
		if (isEditAccess == true && lstProject != null && lstProject.size() > 0) {
			isEditAccess = true;
		} else {
			isEditAccess = false;
		}
		return isEditAccess;
	}

	// This method checked, login user have UX project record access and can reopen then project .
	public static boolean IsProjectEditAccess(string recId) {
		Boolean isEditAccess = false;
		List<Research_Project_Master__share> lstUsrAccess = [
			SELECT AccessLevel
			FROM Research_Project_Master__share
			WHERE ParentId = :recId AND UserOrGroupId = :UserInfo.getUserId()
			LIMIT 1
		];

		if (lstUsrAccess != null && lstUsrAccess.size() > 0) {
			if (lstUsrAccess[0].AccessLevel != 'Read') {
				isEditAccess = true;
			}
		}

		List<Profile> userProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
		if (userProfile.size() > 0 && 'Gusto UX Research Admin'.equalsIgnoreCase(userProfile[0].Name)) {
			//"Gusto UX Research Admin" profile user can access any of the UXR Scout records.
			isEditAccess = true;
		}
		return isEditAccess;
	}

	//Survey CSV Parser
	public static List<List<String>> callSurveyDataParsing(List<string> lines) {
		//Remove Enter character from Question column
		//Start here
		string strLine = '';
		integer cnt = 1;
		for (integer i = 0; i < lines.size(); i++) {
			//get Line number of Import JSON
			if (lines[i].indexOf('ImportId') > -1) {
				cnt = i;
				break;
			}
		}
		for (integer i = 1; i < cnt; i++) {
			string str = lines[i].Trim();
			if (string.isNotBlank(str)) {
				string st = lines[i].trim().replaceAll('\r\n', '');
				st = lines[i].trim().replaceAll('\n', '');
				strLine = strLine + ' ' + st;
			}
		}

		//End here
		List<List<String>> allData = new List<List<String>>();
		integer i = 0;
		for (String line : lines) {
			if (i <= 1 || i >= cnt) {
				//Iterate question line
				if (i == 1) {
					line = strLine;
				}

				if (line.replaceAll(',', '').trim().length() == 0)
					break;
				List<String> cleanFields = new List<String>();
				String compositeField;
				Boolean makeCompositeField = false;
				for (String field : line.split(',')) {
					if (!'#EOL#'.equalsIgnoreCase(field)) {
						if (makeCompositeField == true && field.trim().endsWith('"')) {
							compositeField += ',' + field.trim();
							cleanFields.add(compositeField.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
							makeCompositeField = false;
						} else if (field.trim().startsWith('"') && field.trim().endsWith('"')) {
							cleanFields.add(field.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
						} else if (field.trim().startsWith('"')) {
							makeCompositeField = true;
							compositeField = field.trim();
						} else if (field.trim().endsWith('"')) {
							compositeField += ',' + field.trim();
							cleanFields.add(compositeField.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
							makeCompositeField = false;
						} else if (makeCompositeField) {
							compositeField += ',' + field.trim();
						} else {
							cleanFields.add(field.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
						}
					}
				}
				allData.add(cleanFields);
			}
			i++;
		}
		return allData;
	}

	//CSV Parser
	public static List<List<String>> callDataParsing(List<String> list_CSVsInfo) {
		List<List<String>> list_AllDatas = new List<List<String>>();
		List<String> list_FieldsInfo = new List<String>();
		String strCompositeField;
		Boolean blnMakeCompositeField = false;

		for (String strCSVRow : list_CSVsInfo) {
			list_FieldsInfo = new List<String>();
			strCompositeField = '';
			blnMakeCompositeField = false;

			if (String.isBlank(strCSVRow) || strCSVRow.replaceAll(',', '').trim().length() == 0) {
				break;
			}

			for (String strFieldInfo : strCSVRow.split(',')) {
				if (String.isBlank(strFieldInfo) || (strFieldInfo.trim() == 'null')) {
					list_FieldsInfo.add('');
				} else if (!'#EOL#'.equalsIgnoreCase(strFieldInfo)) {
					if (blnMakeCompositeField == true && strFieldInfo.trim().endsWith('"')) {
						strCompositeField += ',' + strFieldInfo.trim();
						list_FieldsInfo.add(strCompositeField.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
						blnMakeCompositeField = false;
					} else if (strFieldInfo.trim().startsWith('"') && strFieldInfo.trim().endsWith('"')) {
						list_FieldsInfo.add(strFieldInfo.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
					} else if (strFieldInfo.trim().startsWith('"')) {
						blnMakeCompositeField = true;
						strCompositeField = strFieldInfo.trim();
					} else if (strFieldInfo.trim().endsWith('"')) {
						strCompositeField += ',' + strFieldInfo.trim();
						list_FieldsInfo.add(strCompositeField.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
						blnMakeCompositeField = false;
					} else if (blnMakeCompositeField) {
						strCompositeField += ',' + strFieldInfo.trim();
					} else {
						list_FieldsInfo.add(strFieldInfo.replaceAll(',"""', ',""').replaceAll('""",', '"",').replaceAll('""', '"').trim());
					}
				}
			}

			list_AllDatas.add(list_FieldsInfo);
		}

		return list_AllDatas;
	}

	//This method return UX Project Detail
	public static Research_Project_Master__c RetriveProjectDetail(string projectId) {
		Research_Project_Master__c objProject = new Research_Project_Master__c();
		List<Research_Project_Master__c> lstReProject = [
			SELECT
				Project_Id__c,
				NDA_URL__c,
				Calendly_EventId__c,
				CreatedDate,
				Customer_Types__c,
				Description__c,
				Id,
				Name,
				Number_of_Participants_to_Add_to_Project__c,
				Number_of_Allowed_Participant__c,
				Survey_Id__c,
				Primary_calendly_URL__c,
				Product_Area__c,
				Project_End_Date__c,
				Project_Start_Date__c,
				Project_Status__c,
				Researcher_Name__c,
				Screener_URL__c,
				Type_of_Research__c,
				Last_View_Calendar_Date__c,
				(
					SELECT
						Id,
						NDA_Send__c,
						Blacklist__c,
						Opt_Out__c,
						Reason__c,
						Incentive__c,
						Unread_Email__c,
						Project_Name__c,
						Project_Id__c,
						Screener_URL__c,
						Contact__c,
						Contact__r.AccountId,
						Contact__r.Account.Name,
						Contact__r.Account.ZP_Company_ID__c,
						Contact__r.ZP_User_Id__c,
						Contact__r.Employee_Id__c,
						Contact__r.Email,
						Contact__r.Name,
						Comment__c,
						Research_Participant_Status__c,
						Researcher_Name__c,
						Calendly_URL__c,
						Company_Name__c,
						Date_of_Attended__c,
						Incentive_Amount__c,
						Length_of_Interview__c,
						Locked__c,
						NDA_URL__c,
						Research_Participant_Status_Number__c,
						Study_End_Date__c,
						Study_Start_Date__c,
						Participant_Email__c,
						Researcher_Email__c
					FROM Research_Project_Details__r
				)
			FROM Research_Project_Master__c
			WHERE Id = :projectId
		];
		if (lstReProject != null && lstReProject.size() > 0) {
			objProject = lstReProject[0];
		}
		return objProject;
	}

	//This method return Research Survey Response Details
	public static List<Research_Survey__c> RetriveResSurveyDetail(string recid, string questionCode) {
		List<Research_Survey__c> lstSurvey = new List<Research_Survey__c>();
		string query = 'select id,Recorded_Date__c,Research_Project_Detail__c,';
		query = query + ' Research_Project_Detail__r.Research_Project_Master__c,';
		query = query + ' Research_Project_Detail__r.Research_Project_Master__r.Name, ';
		query = query + ' Research_Project_Detail__r.Blacklist__c, ';
		query = query + ' Research_Project_Detail__r.Opt_Out__c, ';
		query = query + ' Research_Project_Detail__r.Research_Participant_Status__c,';
		query = query + ' Research_Project_Detail__r.Contact__c,Research_Project_Detail__r.Contact__r.Name,';
		query = query + ' Research_Project_Detail__r.Contact__r.Email,Research_Project_Detail__r.Comment__c,Response_Id__c,';
		query = query + ' (select id,Question_Code_Number__c,Name,Research_Survey__c,Survey_Answers__c,Survey_Question_Code__c, Survey_Questions__c from Research_Survey_Responses__r';
		if (string.isNotBlank(questionCode)) {
			query = query + '  where Survey_Question_Code__c=:questionCode';
		}
		query = query + ' order by Survey_Question_Code__c ASC) from Research_Survey__c where Research_Project_Detail__r.Research_Project_Master__c=:recid';
		lstSurvey = database.query(query);
		return lstSurvey;
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : This method return UXR Scout Research Configuration detail
	 * @Parm        : NA
	 * @Return      : Object of Research_Configuration__c
	 **/
	public static Research_Configuration__c RetriveResearchConfiguration() {
		Research_Configuration__c objConfig = new Research_Configuration__c();
		List<Research_Configuration__c> list_Configs = [
			SELECT
				Id,
				Name,
				Administrator_1__c,
				Administrator_2__c,
				Administrator_3__c,
				Days_Since_Last_Contact_High_Limit__c,
				Days_Since_Last_Contact_Low_Limit__c,
				Lock_Contacts_For_X_days__c,
				Max_Number_Of_Participants_High_Limit__c,
				Max_Number_Of_Studies_Participants__c,
				NDA_URL__c,
				Min_Number_Of_Participants_Low_Limit__c,
				Qualitative_Survey_Participated_Blackout__c,
				Max_Incentive_of_Current_Year__c,
				Quantitative_Survey_Participated_Blackou__c,
				States__c,
				Unsubscribe_Text__c,
				Include_Marketing_Optout__c,
				Include_Likely_to_be_James__c,
				Include_Likely_to_be_Jordan__c,
				Include_Likely_to_be_Operator_Jessica__c,
				Include_Likely_to_be_Owner_Jessica__c,
				Exclude_Likely_to_be_James__c,
				Exclude_Likely_to_be_Jordan__c,
				Exclude_Likely_to_be_Operator_Jessica__c,
				Exclude_Likely_to_be_Owner_Jessica__c,
				Max_Number_Of_Participants_To_Send_Email__c,
				Approval_Code_Applied_Date__c
			FROM Research_Configuration__c
			LIMIT 1
		];

		if (list_Configs != null && list_Configs.size() > 0) {
			objConfig = list_Configs[0];
		}

		return objConfig;
	}

	//This method return any picklist values
	public static List<selectOption> getPickValues(Sobject object_name, String field_name) {
		List<selectOption> options = new List<selectOption>();
		Schema.sObjectType sobject_type = object_name.getSObjectType();
		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
		List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pick_list_values) {
			options.add(new selectOption(a.getValue(), a.getLabel()));
		}
		return options;
	}

	//This return us status of participants on the basis on what type of email send to them.
	public static List<selectOption> getEmailStatusList() {
		List<selectOption> options = new List<selectOption>();
		options.add(new selectOption('', '--None--'));
		for (String key : emailStatusMap.keySet()) {
			options.add(new selectOption(key, key));
		}
		return options;
	}

	//This method repalce merge tag with their respective vlaues.
	public static String replaceProjectMasterTag(Research_Project_Master__c objProject, String inputString) {
		if (String.isNotBlank(inputString)) {
			inputString = inputString.Replace('{!Research_Project_Detail__c.Project_Name__c}', objProject.Name);
			inputString = inputString.Replace('{!Research_Project_Detail__c.Project_Id__c}', objProject.Project_Id__c);

			if (String.isNotBlank(objProject.Project_Id__c)) {
				inputString = inputString.Replace('{!Research_Project_Detail__c.Project_Id__c}', objProject.Project_Id__c);
			} else {
				inputString = inputString.Replace('{!Research_Project_Detail__c.Project_Id__c}', '');
			}
		}
		return inputString;
	}

	//Create email template on click of send email button.
	public static String createNewEmailTemplate(String strSelectEmailId, String strSubject, String emailBody) {
		String emailTemplateId = '';
		string emailTemplateName = String.valueof(DateTime.now().getTime());
		emailTemplateName = 'T_' + strSelectEmailId + '_' + emailTemplateName;
		EmailTemplate objTemp = null;
		try {
			objTemp = new EmailTemplate();
			if (String.isNotBlank(UXResearch_SentEmail_FolderId)) {
				objTemp.FolderId = UXResearch_SentEmail_FolderId; //new Folder
			}
			objTemp.Name = emailTemplateName;
			objTemp.DeveloperName = emailTemplateName;
			objTemp.Body = '';
			objTemp.HtmlValue = emailBody;
			objTemp.IsActive = true;
			objTemp.Subject = strSubject;
			objTemp.TemplateStyle = 'none';
			objTemp.TemplateType = 'custom';
			insert objTemp;
			emailTemplateId = objTemp.id;
		} catch (Exception e) {
			ExceptionLogUtil.logException('UR_UtilityCtrl', 'createNewEmailTemplate', e.getMessage(), e.getStackTraceString());
			emailTemplateId = '';
		}
		return emailTemplateId;
	}

	//This method Initialize subQuery filter criteria. like :  equals, contains...
	public static void processSearchMap() {
		String filterString = 'contains;equals;not equal to;does not contain;start with';
		List<Selectoption> strList = new List<selectoption>();
		for (String nameStr : filterString.split(';')) {
			strList.add(new selectoption(nameStr, nameStr));
		}
		searchMap.put('String', strList);

		filterString = 'equals;not equal to;less than;greater than;less or equal,greater or equal';
		List<Selectoption> numList = new List<selectoption>();
		for (String nameStr : filterString.split(';')) {
			numList.add(new selectoption(nameStr, nameStr));
		}
		searchMap.put('Number', numList);

		List<Selectoption> dateList = new List<selectoption>();
		dateList.add(new selectoption('equals', 'on'));
		dateList.add(new selectoption('greater than', 'after'));
		dateList.add(new selectoption('less than', 'before'));
		dateList.add(new selectoption('between', 'between'));
		searchMap.put('Date', dateList);
	}

	//This method parse subQuery filter criteria for string fields. Eg :  equals, contains...
	public static String createSearchString(String fieldType, String filter, String searchFieldAPIName, String searchFieldvalue) {
		String filterString = '';
		if (fieldType == 'String') {
			if (filter == 'equals') {
				filterString = ' and ' + searchFieldAPIName + ' = \'' + searchFieldvalue + '\'';
			} else if (filter == 'not equal to') {
				filterString = ' and ' + searchFieldAPIName + ' != \'' + searchFieldvalue + '\'';
			} else if (filter == 'contains') {
				//filterString = ' and ' + searchFieldAPIName + ' Like  \'%' + searchFieldvalue +'%\'';
				filterString = ' and (' + searchFieldAPIName + ' Like  \'%' + searchFieldvalue + '\' OR ' + searchFieldAPIName + ' Like  \'' + searchFieldvalue + '%\'' + ') ';
			} else if (filter == 'does not contain') {
				filterString = ' and (NOT ' + searchFieldAPIName + ' Like  \'%' + searchFieldvalue + '%\')';
			} else if (filter == 'start with') {
				filterString = ' and ' + searchFieldAPIName + ' Like  \'' + searchFieldvalue + '%\'';
			}
		}
		return filterString;
	}

	//This method parse subQuery filter criteria for Date fields. Eg :  equals, contains...
	public static String createSearchString(String fieldType, String filter, String searchFieldAPIName, Date dtFromJoined, Date dtToJoined) {
		String filterString = '';
		if (fieldType == 'Date') {
			String strFromDate = dtFromJoined + '';
			String strToDate = dtToJoined + '';
			if (dtFromJoined != null && String.isNotBlank(strFromDate)) {
				strFromDate = strFromDate.substring(0, 10);
			}
			if (dtToJoined != null && String.isNotBlank(strToDate)) {
				strToDate = strToDate.substring(0, 10);
			}

			if (filter == 'equals') {
				filterString = ' and ' + searchFieldAPIName + ' = ' + strFromDate + ' ';
			} else if (filter == 'not equal to') {
				filterString = ' and ' + searchFieldAPIName + ' != ' + strFromDate + ' ';
			} else if (filter == 'less than') {
				filterString = ' and ' + searchFieldAPIName + ' < ' + strFromDate + ' ';
			} else if (filter == 'greater than') {
				filterString = ' and ' + searchFieldAPIName + ' > ' + strFromDate + ' ';
			} else if (filter == 'less or equal') {
				filterString = ' and ' + searchFieldAPIName + ' <= ' + strFromDate + ' ';
			} else if (filter == 'greater or equal') {
				filterString = ' and ' + searchFieldAPIName + ' >= ' + strFromDate + ' ';
			} else if (filter == 'between') {
				filterString = ' and ' + searchFieldAPIName + ' >= ' + strFromDate + ' and ' + searchFieldAPIName + ' <= ' + strToDate + ' ';
			}
		}
		return filterString;
	}

	//This method parse subQuery filter criteria for Number fields. Eg :  equals, not equal to...
	public static String createSearchString(String fieldType, String filter, String searchFieldAPIName, Decimal value) {
		String filterString = '';
		if (fieldType == 'Number') {
			if (filter == 'equals') {
				filterString = ' and ' + searchFieldAPIName + ' = ' + value;
			} else if (filter == 'not equal to') {
				filterString = ' and ' + searchFieldAPIName + ' != ' + value;
			} else if (filter == 'less than') {
				filterString = ' and ' + searchFieldAPIName + ' < ' + value;
			} else if (filter == 'greater than') {
				filterString = ' and ' + searchFieldAPIName + ' > ' + value;
			} else if (filter == 'less or equal') {
				filterString = ' and ' + searchFieldAPIName + ' <= ' + value;
			} else if (filter == 'greater or equal') {
				filterString = ' and ' + searchFieldAPIName + ' >= ' + value;
			}
		}
		return filterString;
	}

	// This method returns all sub roles.
	public static Set<ID> getAllSubRoleIds(Set<ID> roleIds) {
		Set<ID> currentRoleIds = new Set<ID>();
		for (UserRole userRole : [SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleID != NULL]) {
			currentRoleIds.add(userRole.Id);
		}
		if (currentRoleIds.size() > 0) {
			currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
		}
		return currentRoleIds;
	}

	// This method returns all the user hierarchy below the "admin" Role.
	public static void getAdminRoleHierarchy(List<Research_Project_Master__c> uxPejectList) {
		set<Id> uxPejectIdSet = new Set<Id>();
		for (Research_Project_Master__c obj : uxPejectList) {
			uxPejectIdSet.add(Obj.Id);
		}
		if (uxPejectIdSet.size() > 0) {
			assignedAdminRoleHierarchy(uxPejectIdSet);
		}
	}

	@Future
	public static void assignedAdminRoleHierarchy(set<Id> uxPejectIdSet) {
		List<Research_Project_Master__c> uxPejectList = [SELECT Id, Name, OwnerId FROM Research_Project_Master__c WHERE ID IN :uxPejectIdSet];
		List<User> userList = new List<User>();
		Set<Id> finalRoleIdSet = new Set<Id>();
		List<UserRole> userRoleList = [SELECT Id, Name FROM UserRole WHERE Name = 'admin'];
		if (userRoleList.size() > 0) {
			Set<Id> roleIdSet = new Set<Id>();
			roleIdSet.add(userRoleList[0].Id);
			finalRoleIdSet = getAllSubRoleIds(roleIdSet);
		}

		Id loginUserId = UserInfo.getUserId();
		List<User> AdminRoleHierarchyUserList = new List<User>();
		List<Research_Project_Master__share> shareProjecttoGustoTeam = new List<Research_Project_Master__share>();

		if (finalRoleIdSet.size() > 0) {
			AdminRoleHierarchyUserList = [SELECT Id FROM User WHERE UserRoleId IN :finalRoleIdSet AND isActive = TRUE AND Id != :loginUserId];
		}

		if (AdminRoleHierarchyUserList.size() > 0 && uxPejectList.size() > 0) {
			for (Research_Project_Master__c projectMaster : uxPejectList) {
				for (User userObj : AdminRoleHierarchyUserList) {
					if (projectMaster.OwnerId != userObj.Id) {
						Research_Project_Master__share objShare = new Research_Project_Master__share();
						objShare.ParentId = projectMaster.Id;
						objShare.UserOrGroupId = userObj.Id;
						objShare.AccessLevel = 'read';
						shareProjecttoGustoTeam.add(objShare);
					}
				}
			}
		}

		if (shareProjecttoGustoTeam.size() > 0) {
			insert shareProjecttoGustoTeam;
		}
	}

	public static void skipTriggerLogic() {
		EmailMessageTriggerHelper.skipTrigger = true;
		TaskTriggerHelper.skipTrigger = true;
		AccountRelatedTrackingTriggerHelper.skipTrigger = true;
	}

	public static void createUXRSearchingRecord(String searchParam, Id projectId, String searchType, Integer result, String msg) {
		try {
			UXR_Searching_Log__c obj = new UXR_Searching_Log__c();
			obj.Research_Project_Master__c = projectId;
			obj.Search_Parameter__c = searchParam;
			obj.Search_Type__c = searchType;
			obj.Search_Result__c = result;
			obj.User__c = UserInfo.getUserId();
			obj.Message__c = msg;
			insert obj;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_UtilityCtrl', 'createUXRSearchingRecord', ex.getMessage(), ex.getStackTraceString());
		}
	}

	public static boolean participantExistInProject(Id projectId) {
		//Check if project participant is available
		Boolean isParticipantExist = false;
		integer partCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId];
		//Check if CSV data is available for this project or not
		integer csvCount = [SELECT COUNT() FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :projectId];
		//Check if any one of them or both has value then redirect to project Participant screen
		if (partCount > 0 || csvCount > 0) {
			isParticipantExist = true;
		}
		return isParticipantExist;
	}

	public static boolean participantExist(Id projectId) {
		//Check if project participant is available
		Boolean isParticipantExist = false;
		integer partCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId];
		if (partCount > 0) {
			isParticipantExist = true;
		}
		return isParticipantExist;
	}

	public static boolean surveyExist(Id projectId) {
		Boolean isSurveyExist = false;
		integer surveyCount = [SELECT COUNT() FROM Research_Survey__c WHERE Research_Project_Detail__r.Research_Project_Master__c = :projectId];
		if (surveyCount > 0) {
			isSurveyExist = true;
		}
		return isSurveyExist;
	}

	public static boolean emailExist(Id projectId) {
		Boolean isEmailExist = false;
		integer emailCount = [SELECT COUNT() FROM EmailMessage WHERE RelatedToId IN (SELECT id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId)];
		if (emailCount > 0) {
			isEmailExist = true;
		}
		return isEmailExist;
	}

	public static boolean calendarEventExist(Id projectId) {
		Boolean isEventExist = false;
		integer eventCount = [SELECT COUNT() FROM Event WHERE WhatId IN (SELECT Id FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :projectId)];
		if (eventCount > 0) {
			isEventExist = true;
		}
		return isEventExist;
	}

	public static Boolean checkApexJobLimit(Integer intNewBatchRequest) {
		List<AggregateResult> list_Results = [SELECT Count(Id) FROM AsyncApexJob WHERE Status = :APEX_HOLDING_JOB_STATUS];
		String strResult = String.valueOf(list_Results[0].get('expr0'));
		Integer intHoldJobCount = Integer.valueOf(strResult);
		Integer intAvailableBatchLimit = MAX_BATCH_LIMIT - (intHoldJobCount + intNewBatchRequest);
		if (intAvailableBatchLimit < 0) {
			return true;
		} else {
			return false;
		}
	}
}