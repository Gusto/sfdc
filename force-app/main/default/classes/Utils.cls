/**
 * @name         : Utils
 * @description  : Common methods
 * @test classes : UtilsTest, BenefitOrderHelperTests, PartnerAccountBatchTest
 **/
public without sharing class Utils {
	public static Configuration_Settings__c ORG_WIDE_CONFIG_SETTINGS = Configuration_Settings__c.getOrgDefaults();
	public static Map<String, String> stateTaxCodeMap;
	public static Map<String, String> map_StateAbb = new Map<String, String>();
	public static Map<String, String> zipCodeTaxCodeMap;
	public static Map<String, String> stateZipTaxCodeMap;
	public static final String BIZTECH_DEV_EMAIL = Label.Batch_Finish_Email_DL;
	public static final String API_HEROKU = 'API Heroku';
	public static final String LICENSED_STATE = 'Licensed States';
	public static final BusinessHours objDefaultBuinessHourRec = GlobalQueryHelper.getDefaultBusinessHour();
	public static Set<String> setCOExclude = new Set<String>{ 'Approved', 'Canceled', 'Closed Admin' };
	public static Set<String> setBOExclude = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin', 'Fulfilled', 'Approved' };
	public static List<GroupMember> list_GroupMembers;
	public static List<CaseTeamRole> list_CaseTeamRoles;
	public static Set<String> setOrderExclude = new Set<String>{ 'Closed: Payroll Run', 'Closed: Canceled' };
	public static final String BENEFIT_TYPE_STD = 'Short Term Disability';
	public static final String BENEFIT_TYPE_LTD = 'Long Term Disability';
	public static String DAYS = 'Days';
	public static String MINUTES = 'Minutes';
	public static String MILLISECONDS = 'Milliseconds';
	public static String SECONDS = 'Seconds';
	public static String HOURS = 'Hours';
	public static String ENGAGEMENT_CASE_ROUTING_GROUP = 'Engagement_Case_Routing_Play_Access';
	public static String UI_THEME_THEME4U = 'Theme4u';
	public static String UI_THEME_THEME4D = 'Theme4d';
	public static final String BOUNCE_EMAIL_ERROR = 'EMAIL_ADDRESS_BOUNCED';
	public static final String RPA_ONLY = 'RPA Only';
	public static final String HI_ONLY = 'HI Only';
	public static final String HI_AND_RPA = 'HI and RPA';
	public static final String QUALIFIED_STATUS_DETAIL = 'Chose Competitor';
	public static final String DAY_E = 'E';
	public static final String SAT = 'Sat';
	public static final String SUN = 'Sun';
	public static String CHAT_STATUS_COMPLETED = 'Completed';
	public static String CHAT_STATUS_MISSED = 'Missed';
	public static String CHAT_STATUS_BLOCKED = 'Blocked';
	public static String CHAT_STATUS_Dropped = 'Dropped';
	public static String CHAT_EVENT_TYPE_CANCELNOAGENT = 'CancelNoAgent';
	public static String CHAT_EVENT_TYPE_CANCELVISITOR = 'CancelVisitor';
	public final static Id CHAT_EXTERNAL_RT_ID = Schema.SObjectType.LiveChatTranscript.getRecordTypeInfosByDeveloperName().get('External').getRecordTypeId();
	
	//There are only few records having  Partner Type as 'TAdA'
	public static Set<Id> set_TAdACarrierIds = new Set<Id>();
	static {
		for (Carrier__c objCarrier : [SELECT Id, Name, State__c, Submission_Method__c, Partner_Type__c, Follow_Up_Method__c FROM Carrier__c WHERE Partner_Type__c = 'TAdA' LIMIT 100]) {
			set_TAdACarrierIds.add(objCarrier.Id);
		}
	}

	public static String getState(String strAb) {
		if (map_StateAbb.values().isEmpty()) {
			List<State_Name_to_abbreviations_Mapping__c> list_StateAbbName = State_Name_to_abbreviations_Mapping__c.getall().values();
			for (State_Name_to_abbreviations_Mapping__c objState : list_StateAbbName) {
				if (!map_StateAbb.containsKey(objState.State_Abbreviation__c)) {
					map_StateAbb.put(objState.State_Abbreviation__c, objState.State_Name__c);
				}
			}
		}
		if (map_StateAbb.containsKey(strAb)) {
			return map_StateAbb.get(strAb);
		} else {
			return '';
		}
	}

	public static Boolean checkifStateCodeisPresent(Set<String> setStatesAbbreviation, String strStateName) {
		if (String.isNotBlank(strStateName) && !setStatesAbbreviation.IsEmpty() && setStatesAbbreviation != null) {
			if (setStatesAbbreviation.contains(getStateCode(strStateName)) || setStatesAbbreviation.contains(strStateName)) {
				return true;
			} else {
				return false;
			}
		} else {
			return false;
		}
	}

	public static String getStateCode(String state) {
		Map<String, String> stateMap = new Map<String, String>();
		stateMap.put('Alabama', 'AL');
		stateMap.put('Alaska', 'AK');
		stateMap.put('Arizona', 'AZ');
		stateMap.put('Arkansas', 'AR');
		stateMap.put('California', 'CA');
		stateMap.put('Colorado', 'CO');
		stateMap.put('Connecticut', 'CT');
		stateMap.put('Delaware', 'DE');
		stateMap.put('District of Columbia', 'DC');
		stateMap.put('Florida', 'FL');
		stateMap.put('Georgia', 'GA');
		stateMap.put('Hawaii', 'HI');
		stateMap.put('Idaho', 'ID');
		stateMap.put('Illinois', 'IL');
		stateMap.put('Indiana', 'IN');
		stateMap.put('Iowa', 'IA');
		stateMap.put('Kansas', 'KS');
		stateMap.put('Kentucky', 'KY');
		stateMap.put('Louisiana', 'LA');
		stateMap.put('Maine', 'ME');
		stateMap.put('Maryland', 'MD');
		stateMap.put('Massachusetts', 'MA');
		stateMap.put('Michigan', 'MI');
		stateMap.put('Minnesota', 'MN');
		stateMap.put('Mississippi', 'MS');
		stateMap.put('Missouri', 'MO');
		stateMap.put('Montana', 'MT');
		stateMap.put('Nebraska', 'NE');
		stateMap.put('Nevada', 'NV');
		stateMap.put('New Hampshire', 'NH');
		stateMap.put('New Jersey', 'NJ');
		stateMap.put('New Mexico', 'NM');
		stateMap.put('New York', 'NY');
		stateMap.put('North Carolina', 'NC');
		stateMap.put('North Dakota', 'ND');
		stateMap.put('Ohio', 'OH');
		stateMap.put('Oklahoma', 'OK');
		stateMap.put('Oregon', 'OR');
		stateMap.put('Pennsylvania', 'PA');
		stateMap.put('Rhode Island', 'RI');
		stateMap.put('South Carolina', 'SC');
		stateMap.put('South Dakota', 'SD');
		stateMap.put('Tennessee', 'TN');
		stateMap.put('Texas', 'TX');
		stateMap.put('Utah', 'UT');
		stateMap.put('Vermont', 'VT');
		stateMap.put('Virginia', 'VA');
		stateMap.put('Washington', 'WA');
		stateMap.put('West Virginia', 'WV');
		stateMap.put('Wisconsin', 'WI');
		stateMap.put('Wyoming', 'WY');
		if (stateMap.containsKey(state)) {
			return stateMap.get(state);
		} else {
			return '';
		}
	}

	@InvocableMethod(label='Fire Case Assignment Rule' description='To trigger Case Assignment Rules.')
	public static void triggerCaseAssignmentRule(List<Id> list_UserIds) {
		futuretriggerCaseAssignmentRule(list_UserIds);
	}
	@future
	public static void futuretriggerCaseAssignmentRule(List<Id> list_UserIds) {
		List<Case> list_CasesToUpdate = new List<Case>();
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;
		List<Case> list_Cases = [SELECT Id, Status FROM Case WHERE Status != 'Solved' AND STATUS != 'Awaiting Response' AND IsClosed != TRUE AND OwnerId IN :list_UserIds];
		for (Case cse : list_Cases) {
			cse.setOptions(dmo);
			list_CasesToUpdate.add(cse);
		}
		update list_CasesToUpdate;
	}

	public static String getTaxPct(String stateCd, String zip, String city) {
		String taxInfo = '';
		if (stateTaxCodeMap == null) {
			setStateTaxMap();
		}
		if (stateCd != null && stateCd != '') {
			taxInfo = stateTaxCodeMap.get(stateCd);
		} else if (zip != null && zip != '') {
			taxInfo = zipCodeTaxCodeMap.get(zip);
		}
		return taxInfo;
	}

	public static void setStateTaxMap() {
		stateTaxCodeMap = new Map<String, String>();
		zipCodeTaxCodeMap = new Map<String, String>();
		stateZipTaxCodeMap = new Map<String, String>();

		for (ZP_Sales_Tax_Jurisdictions__c tax : [
			SELECT Id, City__c, Efective_Till__c, Effective_From__c, Sales_Tax__c, State__c, Zip_Code__c
			FROM ZP_Sales_Tax_Jurisdictions__c
			WHERE Efective_Till__c = NULL
		]) {
			stateTaxCodeMap.put(tax.State__c, tax.State__c);
			if (tax.Zip_Code__c != null && tax.Zip_Code__c != '') {
				zipCodeTaxCodeMap.put(tax.Zip_Code__c, tax.Zip_Code__c);
				stateZipTaxCodeMap.put(tax.State__c, tax.State__c);
			}
		}
	}

	public static Boolean sendEmail(String to, String senderDisplayName, String subject, String textBody) {
		if (to == null || to.trim() == '') {
			return true;
		}
		if (Limits.getLimitEmailInvocations() - Limits.getEmailInvocations() <= 2) {
			return false;
		}
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(to.split(','));
		email.setSubject(subject);
		email.setPlainTextBody(textBody);
		email.setSenderDisplayName(senderDisplayName);
		email.setSaveAsActivity(false);
		Boolean all_or_nothing = false; // Fail gracefully in sandboxes Set to System Email Only
		Messaging.SendEmailResult[] results;
		if (OrganizationUtilities.canSendEmails()) {
			results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email }, all_or_nothing);
			return results[0].isSuccess();
		} else {
			return false;
		}
	}

	public static String consolidateErrors(Database.Error[] errors) {
		String s = '';
		for (Database.Error err : errors) {
			s += '    ' + err.getMessage() + '\n';
			s += '    ' + err.getFields() + '\n';
			s += '    ' + err.getStatusCode() + '\n';
		}
		return s;
	}

	public static void insertAndLog(List<SObject> sobjs, Boolean allOrNothing) {
		if (sobjs.isEmpty()) {
			return;
		}

		List<Database.SaveResult> results = Database.insert(sobjs, allOrNothing);
		if (results.isEmpty()) {
			return;
		}

		List<Database.Error> errors = getResultErrors(results);
		if (errors.isEmpty()) {
			return;
		}

		String consolidatedErrorMessage = consolidateErrors(errors);
	}

	public static void insertAndLog(SObject sobj, Boolean allOrNothing) {
		List<SObject> sobjs = new List<SObject>();
		sobjs.add(sobj);
		insertAndLog(sobjs, allOrNothing);
	}

	public static void updateAndLog(List<SObject> sobjs, Boolean allOrNothing) {
		if (sobjs.isEmpty()) {
			return;
		}

		List<Database.SaveResult> results = Database.update(sobjs, allOrNothing);
		if (results.isEmpty()) {
			return;
		}

		List<Database.Error> errors = getResultErrors(results);
		if (errors.isEmpty()) {
			return;
		}
		String consolidatedErrorMessage = consolidateErrors(errors);
	}

	public static void updateAndLog(SObject sobj, Boolean allOrNothing) {
		List<SObject> sobjs = new List<SObject>();
		sobjs.add(sobj);
		updateAndLog(sobjs, allOrNothing);
	}

	public static List<Database.Error> getResultErrors(List<Database.SaveResult> saveResults) {
		List<Database.Error> errors = new List<Database.Error>();
		for (Database.SaveResult result : saveResults) {
			if (result.isSuccess()) {
				continue;
			}
			errors.addAll(result.getErrors());
		}
		return errors;
	}

	/**
	 * Krishna Bodala
	 * Common routine for DML and handling the errors
	 * Based on the dml type and attribute options, this method returns all errors and also logs them in the system.
	 */
	public static Map<String, String> doDMLAndReturnAllErrors(
		String dmlType,
		String keyFieldForReturnedMap,
		List<SObject> listOfSObjectRecords,
		Boolean allOrNothing,
		Boolean logTheError,
		String stackTrace
	) {
		Map<String, String> errorMap = new Map<String, String>();
		if (listOfSObjectRecords == null || listOfSObjectRecords.isEmpty()) {
			return errorMap;
		}

		if (dmlType == 'Insert') {
			errorMap = processSaveResult(Database.Insert(listOfSObjectRecords, allOrNothing), listOfSObjectRecords, keyFieldForReturnedMap, logTheError, stackTrace);
		} else if (dmlType == 'Update') {
			errorMap = processSaveResult(Database.Update(listOfSObjectRecords, allOrNothing), listOfSObjectRecords, keyFieldForReturnedMap, logTheError, stackTrace);
		} else if (dmlType == 'Upsert') {
			errorMap = processUpsertResult(Database.Upsert(listOfSObjectRecords, allOrNothing), listOfSObjectRecords, keyFieldForReturnedMap, logTheError, stackTrace);
		} else if (dmlType == 'Delete') {
			errorMap = processDeleteResult(Database.Delete(listOfSObjectRecords, allOrNothing), listOfSObjectRecords, keyFieldForReturnedMap, logTheError, stackTrace);
		}
		return errorMap;
	}

	/**
	 * Krishna Bodala
	 * processes save result for insert/update
	 * if the error needs to be logged, calls async log handler
	 */
	public static Map<String, String> processSaveResult(
		List<Database.SaveResult> saveResult,
		List<SObject> listOfSObjectRecords,
		String keyFieldForReturnedMap,
		Boolean logTheError,
		String stackTrace
	) {
		String strFinalErrMsg = ' ';
		Set<String> set_ErrorRecIds = new Set<String>();
		Map<String, String> errorMap = new Map<String, String>();
		Integer i = 0;

		for (Database.SaveResult result : saveResult) {
			if (!result.isSuccess()) {
				String errorMessage = consolidateErrors(result.getErrors());
				if (keyFieldForReturnedMap != null) {
					String mapKey = String.valueOf(listOfSObjectRecords[i].get(keyFieldForReturnedMap));
					if (String.isNotBlank(mapKey) && mapKey.contains('~')) {
						mapKey = mapKey.split('~')[0];
					}
					errorMap.put(mapKey, errorMessage);
					set_ErrorRecIds.add(result.getId());
					strFinalErrMsg = strFinalErrMsg + ' , ' + errorMessage;
				}
			}
			i++;
		}
		if (String.isNotBlank(strFinalErrMsg) && logTheError) {
			strFinalErrMsg += ' || '+JSON.serialize(listOfSObjectRecords)+' || ';
			String strLogRecordId = ExceptionLogUtil.logExceptionWithId('Utils', 'processSaveResult', strFinalErrMsg, stackTrace, set_ErrorRecIds);
		}
		return errorMap;
	}

	/**
	 * Krishna Bodala
	 * processes save result for insert/update
	 * if the error needs to be logged, calls async log handler
	 */
	public static Map<String, String> processUpsertResult(
		List<Database.UpsertResult> saveResult,
		List<SObject> listOfSObjectRecords,
		String keyFieldForReturnedMap,
		Boolean logTheError,
		String stackTrace
	) {
		String strFinalErrMsg = ' ';
		Map<String, String> errorMap = new Map<String, String>();
		Set<String> set_ErrorRecIds = new Set<String>();
		Integer i = 0;

		for (Database.UpsertResult result : saveResult) {
			if (!result.isSuccess()) {
				String errorMessage = consolidateErrors(result.getErrors());
				if (keyFieldForReturnedMap != null) {
					String mapKey = String.valueOf(listOfSObjectRecords[i].get(keyFieldForReturnedMap));
					if (String.isNotBlank(mapKey) && mapKey.contains('~')) {
						mapKey = mapKey.split('~')[0];
					}
					errorMap.put(mapKey, errorMessage);
					set_ErrorRecIds.add(result.getId());
					strFinalErrMsg += ' , ' + errorMessage;
				}
			}
			i++;
		}
		if (String.isNotBlank(strFinalErrMsg) && logTheError) {
			strFinalErrMsg += ' || '+JSON.serialize(listOfSObjectRecords)+' || ';
			String strLogRecordId = ExceptionLogUtil.logExceptionWithId('Utils', 'processUpsertResult', strFinalErrMsg, stackTrace, set_ErrorRecIds);
		}

		return errorMap;
	}

	/**
	 * Krishna Bodala
	 * processes save result for delete
	 * if the error needs to be logged, calls async log handler
	 */
	public static Map<String, String> processDeleteResult(
		List<Database.DeleteResult> saveResult,
		List<SObject> listOfSObjectRecords,
		String keyFieldForReturnedMap,
		Boolean logTheError,
		String stackTrace
	) {
		Map<String, String> errorMap = new Map<String, String>();
		Integer i = 0;

		for (Database.DeleteResult result : saveResult) {
			if (!result.isSuccess()) {
				String errorMessage = consolidateErrors(result.getErrors());
				if (keyFieldForReturnedMap != null) {
					String mapKey = String.valueOf(listOfSObjectRecords[i].get(keyFieldForReturnedMap));
					errorMap.put(mapKey, errorMessage);
					if (logTheError) {
						ExceptionLogUtil.logException('Database.SaveResult', 'Utils', 'processSaveResult', errorMessage, result.getId());
					}
				}
			}
			i++;
		}
		return errorMap;
	}

	/**
	 * @author Krishna Bodala
	 * @description Converts a Map into a String
	 */
	public static String consolidateErrorMap(Map<String, String> errorMap) {
		String consolidatedMessage = '';
		if (errorMap != null && errorMap.keySet().size() > 0) {
			for (String key : errorMap.keySet()) {
				consolidatedMessage += key + '-' + errorMap.get(key) + '\n';
			}
		}
		return consolidatedMessage;
	}

	/**
	 * gets the next business day based on current day
	 */
	public static Date getNextBusinessDay() {
		return getNextBusinessDayFromDate(System.today());
	}

	public static Boolean isWeekendDay(Date dtParam) {
		Boolean blnFlag = false;
		if (dtParam != null) {
			DateTime dtmObj = DateTime.newInstance(dtParam, Time.newInstance(0, 0, 0, 0));
			String strDayOfWeek = dtmObj.format('EEEE');
			if (strDayOfWeek == 'Saturday' || strDayOfWeek == 'Sunday') {
				blnFlag = true;
			}
		}
		return blnFlag;
	}

	//Add or decrease in BusinessDaysToAdd days
	public static Date getBusinessDayFromDate(Date dtStartDate, Integer intBusinessDaysToAdd) {
		Date dtFinalDate = dtStartDate;
		if (dtFinalDate != null) {
			Integer intDirection = intBusinessDaysToAdd < 0 ? -1 : 1;
			while (intBusinessDaysToAdd != 0) {
				dtFinalDate = dtFinalDate.addDays(intDirection);
				if (!isWeekendDay(dtFinalDate)) {
					intBusinessDaysToAdd -= intDirection;
				}
			}
		}
		return dtFinalDate;
	}

	/**
	 * @author		 	Neha Dabas
	 * @description	 	Add or Subtract business hours to a datetime and return the same
	 * @param		 	dtStartDateTime From DateTime,
	 * @param           intBusinessHours No. of business hours
	 */
	public static DateTime addOrSubtractBusinessHoursToDate(DateTime dtStartDateTime, Integer intBusinessHours) {
		DateTime dtFinalDateTime = dtStartDateTime;
		if (dtFinalDateTime != null && intBusinessHours != 0) {
			dtFinalDateTime = BusinessHours.add(objDefaultBuinessHourRec.Id, dtStartDateTime, intBusinessHours * 60 * 60 * 1000);
		}
		return dtFinalDateTime;
	}

	/**
	 * @author		 	Priya Singh
	 * @description	 	Get next 24 hours but exclude weekend.
	 */
	public static DateTime nextBusinessHoursDateTime() {
		Datetime dtmCurrentTime = Datetime.now();
		Datetime dtmNext24Hours = dtmCurrentTime.addHours(24);
		if (dtmNext24Hours.format(DAY_E) == SAT || dtmNext24Hours.format(DAY_E) == SUN) {
			// If it doesn't fall within business hours, update to the next business day
			while (dtmNext24Hours.format(DAY_E) == SAT || dtmNext24Hours.format(DAY_E) == SUN) {
				dtmNext24Hours = dtmNext24Hours.addDays(1);
			}
		}
		return dtmNext24Hours;
	}

	public static Date getNextBusinessDayFromDate(Date dte) {
		Date startOfWeek = dte.toStartOfWeek();
		Integer dayOfWeek = startOfWeek.daysBetween(dte);
		Integer numOfDaysToAdd = 1;
		if (dayOfWeek == 5) {
			numOfDaysToAdd = 3;
		} else if (dayOfWeek == 6) {
			numOfDaysToAdd = 2;
		}

		return dte.addDays(numOfDaysToAdd);
	}
	
	/**
	 * @description       Returns no of non working days 
	 * 					  The logic does not Consider Holidays as of now.
	 *
	 * @param dtStartDate Start Date
	 * @param dtEndDate End Date
	 * @return            Integer number of non working days
	 */
	public static Integer getNumberOfNonWorkingDays(Date dtStartDate, Date dtEndDate) {
		Integer intNonWorkingDays = 0;
		for (integer i=0; i <= dtStartDate.daysBetween(dtEndDate); i++) {
			 Date dtNextDay = dtStartDate + i;
			 if(isWeekendDay(dtNextDay)){
				intNonWorkingDays = intNonWorkingDays + 1;
			 }
		}
		return intNonWorkingDays;
	}

	/**
	 * @description       Add Specified no of days to a Date and return the nearest Business Day
	 * 					  If the calculated date falls within business hours, the same date is returned.
	 * 					  The logic Consider Holidays as well.
	 *
	 * @param dtStartDate Start Date
	 * @param intNoOfDays No.of Business Days, add to Start Date
	 * @return            `Date`
	 */
	public static Date addBusinessDays(Date dtStartDate, Integer intNoOfDays) {
		Date dtFinalDate = getBusinessDayFromDate(dtStartDate, intNoOfDays);
		return BusinessHours.nextStartDate(Utils.objDefaultBuinessHourRec.Id, DateTime.newInstance(dtFinalDate, Time.newInstance(0, 0, 0, 0))).date();
	}

	/*
	 *   Decorates the input String to be a human recognizable phrase
	 *       1) The first and last day of the word are always capitalized
	 *       2) Never capitalize prepositions and conjunctions of four or fewer letters.
	 *       3) Words with five or more letters, regardless of whether the word is a conjunction or preposition, must be
	 *       capitalized.
	 *       4) Never capitalize the particle “to”, even when used as an infinitive (meaning with a verb)
	 *       5) Never capitalize articles: a, an, the.
	 *       6) Replace all underscores with spaces
	 * */
	public static String humanize(String stringValue) {
		Set<String> forceLowerWords = new Set<String>{
			'a',
			'an',
			'and',
			'as',
			'at',
			'but',
			'buy',
			'by',
			'down',
			'for',
			'from',
			'if',
			'in',
			'into',
			'like',
			'near',
			'nor',
			'of',
			'off',
			'on',
			'once',
			'onto',
			'or',
			'over',
			'past',
			'so',
			'than',
			'that',
			'the',
			'till',
			'to',
			'up',
			'upon',
			'when',
			'with',
			'yet'
		};
		String humanizedString = '';

		if (stringValue == null) {
			return null;
		}

		if (String.isNotBlank(stringValue)) {
			humanizedString = '';

			List<String> splitWords = stringValue.toLowerCase().trim().replaceAll('_', ' ').split(' ');

			for (Integer i = 0; i < splitWords.size(); i++) {
				String word = splitWords[i];

				// capitalize first, last, and 5 letter+ words
				if (i == 0 || word.length() > 4 || i == splitWords.size() - 1) {
					humanizedString += word.capitalize() + ' ';
				} else if (forceLowerWords.contains(word)) {
					humanizedString += word.toLowerCase() + ' ';
				} else {
					humanizedString += word.capitalize() + ' ';
				}
			}
			humanizedString.trim();
		}
		return humanizedString.trim();
	}

	public static String getFieldAPINameString(String ObjectApiName) {
		String FieldNameString;

		Map<String, schema.sobjecttype> globalObjectsMap = Schema.getGlobalDescribe();
		Set<String> objectKeys = globalObjectsMap.keySet();
		if (objectKeys.contains(ObjectApiName.toLowerCase())) {
			Schema.DescribeSObjectResult r = globalObjectsMap.get(ObjectApiName).getDescribe();
			Map<String, Schema.SObjectField> fieldMap = r.fields.getMap();
			for (String str : fieldMap.keySet()) {
				if (String.isBlank(FieldNameString)) {
					FieldNameString = str.trim();
				} else {
					FieldNameString += ' , ' + str.trim();
				}
			}
		}

		return FieldNameString;
	}

	public static Schema.DescribeSObjectResult getSObjectDescribe(String strObjectName){
		return ((SObject)Type.forName(strObjectName).newInstance()).getSObjectType().getDescribe(); 
	}
	//business hours logic
	public static Long businessHours(Id businessHoursId, DateTime oppCreatedDate, DateTime secondDate) {
		// businessHoursId cannot be null when using BusinessHours.diff function
		if (businessHoursId == null) {
			return 0;
		}
		return Math.abs(BusinessHours.diff(businessHoursId, oppCreatedDate, secondDate) / 1000 / 60 / 60);
	}

	public static Long businessMinutes(Id businessHoursId, DateTime fromTime, DateTime toTime) {
		// businessHoursId cannot be null when using BusinessHours.diff function
		if (businessHoursId == null) {
			return 0;
		}
		return Math.abs(BusinessHours.diff(businessHoursId, fromTime, toTime) / 1000 / 60);
	}

	public static Integer getTimezoneOffset() {
		TimeZone tz = UserInfo.getTimeZone();
		return tz.getOffset(DateTime.newInstance(2012, 11, 23, 12, 0, 0)) / 1000 / 60 / 60;
	}

	public static Map<Id, String> getProfileNameMap() {
		Map<Id, String> profileNameMap = new Map<Id, String>();
		for (Profile pfl : [SELECT Id, Name FROM Profile]) {
			profileNameMap.put(pfl.id, pfl.Name);
		}
		return profileNameMap;
	}

	public static Set<String> getRolesSet(String roleset, String component) {
		Map<String, Rolesets__c> roleSetMap = Rolesets__c.getAll();
		Set<String> allowedRolesSet = new Set<String>();
		for (Rolesets__c objRoleSet : roleSetMap.values()) {
			List<String> componentsList = objRoleSet.components__C.split('\\r\\n');
			Set<String> componentsSet = new Set<String>();
			componentsSet.addAll(componentsList);
			if (componentsSet.contains(component)) {
				List<String> allowedRolesList = objRoleSet.Roles__c.split('\\r\\n');
				allowedRolesSet.addAll(allowedRolesList);
				break;
			}
		}

		return allowedRolesSet;
	}

	/*
	Get the carrier version based on effective Date.
	This is used in CarrierOrder trigger helper and HI Carrier version
	*/
	public static Map<String, Carrier_Version_Detail__c> getCarrierVersion(Map<String, Date> map_carrierIdDate) {
		Set<String> set_carrierIds = map_carrierIdDate.KeySet();
		List<String> list_carrierVersionfields = new List<String>(Carrier_Version_Detail__c.getSObjectType().getDescribe().fields.getMap().keySet());
		String strQuery =
			'SELECT ' +
			String.join(list_carrierVersionfields, ',') +
			', Carrier_Id__r.Name, Carrier_Id__r.Id__c FROM Carrier_Version_Detail__c ' +
			' WHERE Effective_Date__c != null and Carrier_Id__r.Id__c IN :set_carrierIds ORDER BY Effective_Date__c DESC, CreatedDate DESC LIMIT 2000';
		List<Carrier_Version_Detail__c> list_CarrierVersion = Database.query(strQuery);

		Map<String, Carrier_Version_Detail__c> map_carrierVersion = new Map<String, Carrier_Version_Detail__c>();
		if (!list_CarrierVersion.isEmpty()) {
			for (String carrierId : set_carrierIds) {
				for (Carrier_Version_Detail__c objCarrierVersion : list_CarrierVersion) {
					Date dtEffectiveDate = map_carrierIdDate.get(objCarrierVersion.Carrier_Id__r.Id__c);
					if (
						dtEffectiveDate != null &&
						carrierId == objCarrierVersion.Carrier_Id__r.Id__c &&
						objCarrierVersion.Effective_Date__c <= dtEffectiveDate &&
						!map_carrierVersion.containsKey(objCarrierVersion.Carrier_Id__r.Id__c)
					) {
						map_carrierVersion.put(objCarrierVersion.Carrier_Id__r.Id__c, objCarrierVersion);
						break;
					}
				}
			}
		}
		return map_carrierVersion;
	}

	/*
	Method to parse the JSON String array ["t","t"] and covert to String
	*/
	public static String getStrArrayToString(String strVal, String strSeperator) {
		if (String.isBlank(strVal) || String.isBlank(strSeperator)) {
			return null;
		}

		list<String> list_string = new List<String>();
		list_string = (List<String>) json.deserialize(strVal, List<String>.class);
		return String.join(list_string, strSeperator);
	}

	/**
	 * process save result for insert/update
	 * if the error needs to be logged in Exception_Log__c
	 */
	public static Map<String, String> processSaveRecords(
		List<Database.SaveResult> list_SaveResult,
		List<SObject> list_SObjectRecords,
		String strKeyFieldForReturnedMap,
		Boolean blnIsErrorToBeLogged,
		String strStackTrace,
		String strStackTraceMethod
	) {
		Map<String, String> map_Errors = new Map<String, String>();
		Integer intTempValue = 0;

		for (Database.SaveResult objSaveResult : list_SaveResult) {
			if (!objSaveResult.isSuccess()) {
				String strErrorMessage = consolidateErrors(objSaveResult.getErrors());
				if (strKeyFieldForReturnedMap != null) {
					String strMapKey = String.valueOf(list_SObjectRecords[intTempValue].get(strKeyFieldForReturnedMap));
					map_Errors.put(strMapKey, strErrorMessage);
				}
			}
			intTempValue++;
		}

		if (blnIsErrorToBeLogged && !map_Errors.isEmpty()) {
			String strConsolidatedMessage = consolidateErrorMap(map_Errors);
			ExceptionLogUtil.logException(strStackTrace, strStackTraceMethod, strConsolidatedMessage, 'Medium');
		}
		return map_Errors;
	}

	/**
	 * process save result for upsert
	 * if the error needs to be logged in Exception_Log__c
	 */
	public static Map<String, String> processUpsertRecords(
		List<Database.UpsertResult> list_UpsertResult,
		List<SObject> list_SObjectRecords,
		String strKeyFieldForReturnedMap,
		Boolean blnIsErrorToBeLogged,
		String strStackTrace,
		String strStackTraceMethod
	) {
		Map<String, String> map_Errors = new Map<String, String>();
		Integer intTempValue = 0;

		for (Database.UpsertResult objUpsertResult : list_UpsertResult) {
			if (!objUpsertResult.isSuccess()) {
				String strErrorMessage = ConsolidateErrors(objUpsertResult.getErrors());

				if (strKeyFieldForReturnedMap != null) {
					String strMapKey = String.valueOf(list_SObjectRecords[intTempValue].get(strKeyFieldForReturnedMap));
					map_Errors.put(strMapKey, strErrorMessage);
				}
			}
			intTempValue++;
		}

		if (blnIsErrorToBeLogged && !map_Errors.isEmpty()) {
			String strConsolidatedMessage = consolidateErrorMap(map_Errors);
			ExceptionLogUtil.logException(strStackTrace, strStackTraceMethod, strConsolidatedMessage, 'Medium');
		}

		return map_Errors;
	}

	/**
	 * @author        Praveen
	 * @description   Get difference between two different timestamps
	 * @param         Datetime dtFromDate From Time
	 * @param         Datetime dtToDate To Time
	 * @param         String strDiffType Indicates if difference type is months, days or minutes
	 * @return        Difference
	 **/
	public static Integer getTimeStampDiff(Datetime dtFromDate, DateTime dtToDate, String strDiffType) {
		try {
			if (dtFromDate == null || dtToDate == null) {
				return 0;
			} else {
				Long intToTime = dtFromDate.getTime();
				Long intFromTime = dtToDate.getTime();
				Long intMilliSeconds = intFromTime - intToTime;
				Long intSeconds = intMilliSeconds / 1000;
				Long intMinutes = intSeconds / 60;
				Long intHours = intMinutes / 60;
				Long intDays = intHours / 24;

				if (strDiffType == MILLISECONDS) {
					return Integer.valueOf(intMilliSeconds);
				} else if (strDiffType == SECONDS) {
					return Integer.valueOf(intSeconds);
				} else if (strDiffType == MINUTES) {
					return Integer.valueOf(intMinutes);
				} else if (strDiffType == HOURS) {
					return Integer.valueOf(intHours);
				} else if (strDiffType == DAYS) {
					return Integer.valueOf(intDays);
				} else {
					return 0;
				}
			}
		} catch (Exception ex) {
			return 0;
		}
	}

	/**
	 * @author        Ankit CS
	 * @description   Generic method to check if the user has access to a tab
	 * @param         strGroupName Name of the public group in which we have to check the user access.
	 * @return        `Boolean`  true/ false
	 **/
	public static Boolean checkTabAccessGeneric(String strGroupName) {
		List<String> list_UsersOrRoles = new List<String>();
		List<String> list_CurrentUserGroups = new List<String>();
		Set<Id> set_NestedGroupIds = new Set<Id>();
		String strGroupTypePrefix = Schema.SObjectType.Group.getKeyPrefix();
		//make a query on group members

		//for each group member, if member's group is the mentioned group name and member is a group, add to set_NestedGroupIds
		for (GroupMember objUserOrGroup : getGroupMembers(strGroupName)) {
			if (objUserOrGroup.Group.DeveloperName == strGroupName && (objUserOrGroup.UserOrGroupId + '').startsWith(strGroupTypePrefix)) {
				set_NestedGroupIds.add(objUserOrGroup.UserOrGroupId);
			}
			if (objUserOrGroup.Group.DeveloperName == strGroupName) {
				list_UsersOrRoles.add(objUserOrGroup.UserOrGroupId);
			}
		}

		//if we have groups inside the mentioned group, start recursive search for all members
		for (Id i : getGroupsForIds(set_NestedGroupIds)) {
			list_UsersOrRoles.add(i);
		}

		//if we have user ids or roles, get current user's id and id of Roles related to current user if list_UsersOrRoles contains user id or user's roles, return true
		if (!list_UsersOrRoles.isEmpty()) {
			list_CurrentUserGroups.add(UserInfo.getUserId());
			Group objUserRole = [SELECT Id FROM Group WHERE RelatedId = :UserInfo.getUserRoleId() AND Type = 'Role'];
			list_CurrentUserGroups.add(objUserRole.Id);

			if (!list_CurrentUserGroups.isEmpty()) {
				for (String strUserOrGroupId : list_CurrentUserGroups) {
					if (list_UsersOrRoles.contains(strUserOrGroupId)) {
						return true;
					}
				}
				return false;
			}
		}
		return false;
	}

	/**
	 * @description Deprecate if possible - leaving in case there are other references. Use `queryGroupMembers` instead
	 * @author      Ankit CS
	 * @param       strGroupName The group name or developername
	 * @deprecated  Use queryGroupMembers(String strGroupName) instead
	 * @return      The members of the group
	 */
	public static List<GroupMember> getGroupMembers(String strGroupName) {
		return queryGroupMembers(strGroupName);
	}

	/**
	 * @author        Ankit CS
	 * @description   To get all the group members for the mentioned group name.
	 * @param         strGroupName Name of the public group.
	 * @return        `List<GroupMember>` List of all group members for the mentioned group.
	 **/
	public static List<GroupMember> queryGroupMembers(String strGroupName) {
		List<GroupMember> list_GroupMembers = new List<GroupMember>();
		for (GroupMember objGrpMember : [
			SELECT UserOrGroupId, GroupId, Group.Type, Group.DeveloperName
			FROM GroupMember
			WHERE Group.DeveloperName = :strGroupName OR (Group.DeveloperName != :strGroupName AND UserOrGroupId != :UserInfo.getUserId())
		]) {
			list_GroupMembers.add(objGrpMember);
		}
		return list_GroupMembers;
	}

	/**
	 * @author        Ankit CS
	 * @description   Recursively get Nested Group Member Ids from the given Public Group
	 * @param         set_UserOrGroupIds Set of group Ids.
	 * @return        `Set<String>` Set of all the nested public group Ids
	 **/
	public static Set<Id> getGroupsForIds(Set<Id> set_UserOrGroupIds) {
		Set<Id> set_NestedGroupIds = new Set<Id>();
		Set<Id> set_AllNestedGroupMemberIds = new Set<Id>();
		String strGroupTypePrefix = Schema.SObjectType.Group.getKeyPrefix();

		if (!set_UserOrGroupIds.isEmpty()) {
			for (GroupMember objInnerGroupMember : [SELECT GroupId, UserOrGroupId, Group.Type FROM GroupMember WHERE GroupId IN :set_UserOrGroupIds AND GroupId != NULL]) {
				// found a group for traversal
				if ((objInnerGroupMember.UserOrGroupId + '').startsWith(strGroupTypePrefix)) {
					set_NestedGroupIds.add(objInnerGroupMember.UserOrGroupId);
				}
				set_AllNestedGroupMemberIds.add(objInnerGroupMember.UserOrGroupId);
			}

			// call self method to get nested groups
			for (Id i : getGroupsForIds(set_NestedGroupIds)) {
				set_AllNestedGroupMemberIds.add(i);
			}
			//set_AllNestedGroupMemberIds.addAll(getGroupsForIds(set_NestedGroupIds));
		}
		return set_AllNestedGroupMemberIds;
	}

	/**
	 * @author        Sanjay Paryani
	 * @description   To get the CaseTeamRole record for the mentioned role name.
	 * @param         strRoleName strRoleName Name of the case team role.
	 * @return        List<GroupMember> List of all group members for the mentioned group.
	 **/
	public static List<CaseTeamRole> queryCaseTeamRoles(String strRoleName) {
		list_CaseTeamRoles = new List<CaseTeamRole>();
		for (CaseTeamRole objCaseTeamRole : [SELECT Id, Name FROM CaseTeamRole WHERE Name = :strRoleName]) {
			list_CaseTeamRoles.add(objCaseTeamRole);
		}
		return list_CaseTeamRoles;
	}

	/**
	 * @author        Sanjay Paryani
	 * @description   Skip Trigger, which is not required for this functionality
	 * @param         blnFlag set skipTrigger flags to this value
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		HIGroupEventTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTaskCreation = blnFlag;
		UserTriggerHelper.skipTrigger = blnFlag;
		ContactTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		AccountRelatedTrackingTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		CaseAuditLogTriggerHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.skipTrigger = blnFlag;
		PolicyHelper.skipTrigger = blnFlag;
	}

	/**
	 * @author        Praveen Sethu
	 * @description   Utility method to send emails after batch job finishes
	 * @param         Boolean
	 **/
	public static void processBatchFinish(AsyncApexJob objAsyncJob, String strBatchName, Boolean blnCreateExceptionLog) {
		String strSubject = strBatchName + ' Status - ' + objAsyncJob.Status;
		String strBody = 'Records processed ' + objAsyncJob.TotalJobItems + ' with ' + objAsyncJob.NumberOfErrors + ' failures.';

		// Only Send email when there are errors
		if (objAsyncJob.NumberOfErrors > 0 && objAsyncJob.TotalJobItems == objAsyncJob.NumberOfErrors) {
			sendEmail(BIZTECH_DEV_EMAIL, API_HEROKU, strSubject, strBody);
			if (blnCreateExceptionLog) {
				ExceptionLogUtil.logException(strBatchName, 'finish', strSubject, strBody);
			}
		}
	}

	/**
	 * @author       Rushi Ravisaheb
	 * @description  Method to generate Random Integer of X Length
	 * @param        intLength Required length
	 * @return       `String` value of Random integer
	 */
	public static String getRandomIntValue(Integer intLength) {
		Integer intMaxValue = Integer.valueOf(Math.Pow(10, intLength) - 1);
		return String.valueOf(Math.Round(Math.Random() * intMaxValue)).leftPad(intLength, '0');
	}

	/**
	 * @author       Lalitha Kasturi
	 * @description  Method to generate Random Integer from a range of two given integers
	 * @param        integer Required intStartNum
	 * @param        integer Required intEndNum
	 * @return       value of Random integer
	 */
	public static Integer generateRandomFromRange(Integer intStartNum, Integer intEndNum) {
		Integer intReturnValue;
		//Logic- first we will generate random boolean value which will decide if we want to
		//add the random number from intStartNum or will subtract random number from intEndNum
		Integer intRandomNumber = Integer.valueof((Math.random() * 10));
		Boolean blnAddSubFlag = Math.mod(intRandomNumber, 2) == 0 ? true : false;

		Integer intDiffInRange = intEndNum - intStartNum;
		//Now find random number starting from 0 to intDiffInRange
		Integer intRandomNum = Math.mod(Math.round(Math.random() * intDiffInRange + 1), intDiffInRange);

		//If blnAddSubFlag is true, we will add random number generated between 0 and intDiffInRange from start number
		//else we will subtract random number from end number
		if (blnAddSubFlag) {
			if (intDiffInRange > 1) {
				intReturnValue = intStartNum + intRandomNum;
			} else {
				intReturnValue = intStartNum;
			}
		} else {
			if (intDiffInRange > 1) {
				intReturnValue = intEndNum - intRandomNum;
			} else {
				intReturnValue = intEndNum;
			}
		}
		return intReturnValue;
	}

	/**
	 * @author       Debasmita Rawooth
	 * @description  Method to filter Accounts violating Validation Rule - Direct_Require_Competitor to prevent exception logging
	 * @param        List Required list_InputResult
	 */
	public static List<Database.SaveResult> filterAccounts(List<Database.SaveResult> list_InputResult) {
		List<Database.SaveResult> list_FilteredResult = new List<Database.SaveResult>();
		Set<Id> set_FailedAccountIds = new Set<Id>();
		Set<Id> set_FilterAccountIds = new Set<Id>();
		String strCompanyRecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID;
		Boolean blnSkipValidationRule = UserUtils.returnLoggedInUser().Exempt_from_Validation_Rules__c;

		for (Database.SaveResult objResult : list_InputResult) {
			if (!objResult.isSuccess()) {
				set_FailedAccountIds.add(objResult.getId());
			}
		}
		for (Account objAccount : [
			SELECT Id, Name, Qualified_Status_Detail__c, Previous_Payroll_Provider__c
			FROM Account
			WHERE Id IN :set_FailedAccountIds AND RecordTypeID = :strCompanyRecordTypeId
		]) {
			if (!blnSkipValidationRule && objAccount.Qualified_Status_Detail__c == QUALIFIED_STATUS_DETAIL && String.isBlank(objAccount.Previous_Payroll_Provider__c)) {
				set_FilterAccountIds.add(objAccount.Id);
			}
		}
		for (Database.SaveResult result : list_InputResult) {
			if (!set_FilterAccountIds.contains(result.getId())) {
				list_FilteredResult.add(result);
			}
		}
		return list_FilteredResult;
	}

	/**
	 * @description	Add a value to MultiPicklist type value.
	 * @author	Ajay Krishna P U
	 * @param strOriginalValue The current value of a MultiPicklist @accepts 'String', null, ''
	 * @param strAddValue      The new value to add @accepts 'String', null, ''
	 * @return                 `String` ';' separated values IF values ELSE null
	 */
	public static String addToMultiPicklistValue(String strOriginalValue, String strAddValue) {
		if (String.isBlank(strAddValue)) {
			return toNullIfBlank(strOriginalValue);
		}

		if (String.isBlank(strOriginalValue)) {
			return toNullIfBlank(strAddValue);
		}

		Set<String> set_UniqueValues = new Set<String>(strOriginalValue.split(';'));
		set_UniqueValues.add(strAddValue);

		String strValue = String.join(new List<String>(set_UniqueValues), ';');
		return toNullIfBlank(strValue);
	}

	/**
	 * @description	Returns Null IF @strValue is blank ELSE @strValue
	 * @author	Ajay Krishna P U
	 * @param strValue The value to be verified
	 * @return         `String` null IF @strValue is blank ELSE @strValue
	 */
	public static String toNullIfBlank(String strValue) {
		return String.isBlank(strValue) ? null : strValue;
	}

	/**
	 * @description	Check Whether the Multipicklist have value
	 * note: If @strMultiPicklistValue = empty | @value = empty then function returns false always.
	 * @author	Ajay Krishna P U
	 * @param strMultiPicklistValue Multi Picklist Value @accepts null, '', String
	 * @param strValue              The value to check
	 * @return                      `Boolean`
	 */
	public static Boolean isMultiPicklistContains(String strMultiPicklistValue, String strValue) {
		if (String.isBlank(strMultiPicklistValue) || String.isBlank(strValue)) {
			return false;
		}

		String strPicklistConverted = ';' + strMultiPicklistValue + ';';
		String strValueConverted = ';' + strValue + ';';
		return strPicklistConverted.containsIgnoreCase(strValueConverted);
	}

	/**
	 * @author       Bhagat Singh
	 * @description  Get Carrier with respect to Ids
	 * @param        Set of Carrier Ids
	 * @return       Map of Carrier Objects
	 */
	public static Map<Id, Carrier__c> getCarrierInfo(Set<Id> set_Ids) {
		Map<Id, Carrier__c> map_Carriers = new Map<Id, Carrier__c>();
		for (Carrier__c objCarrier : [SELECT Id, Name, State__c, Submission_Method__c, Follow_Up_Method__c, Partner_Type__c FROM Carrier__c WHERE Id =: set_Ids AND Name != null]) {
			map_Carriers.put(objCarrier.Id, objCarrier);
		}

		return map_Carriers;
	}
}