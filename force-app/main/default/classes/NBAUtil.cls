/**
 * @description  Apex class used for commonly used functions used by NBA classes
 * @author       Praveen Sethu
 * @date         10-15-2023
 * @see          NBAUtilTest
 **/
public without sharing class NBAUtil {
	public static final String N_BUSINESS_DAYS_AGO = 'N_BUSINESS_DAYS_AGO';
	public static final String N_BUSINESS_DAYS_FUTURE = 'N_BUSINESS_DAYS_FUTURE';
	public static final String N_D_BUSINESS_DAYS_AGO = 'N_D_BUSINESS_DAYS_AGO';
	public static final String N_D_BUSINESS_DAYS_FUTURE = 'N_D_BUSINESS_DAYS_FUTURE';
	public static final String OWNER_ID_MYSELF = 'MYSELF';
	public static final Set<String> CUSTOM_FUNCTIONS = new Set<String>{ 'N_D_BUSINESS_DAYS_FUTURE', 'N_D_BUSINESS_DAYS_AGO', 'N_BUSINESS_DAYS_AGO', 'N_BUSINESS_DAYS_FUTURE', 'MYSELF' };

	/**
	 * @description Adds or substract N business days from the current date
	 * @param       Integer - Number of business days
	 * @param       String - add or substract string
	 * @return      DateTime - The resulting date after Add or Subtract
	 **/
	public static DateTime nBusinessDays(Integer intDays, String strAddOrSubtract) {
		Datetime dtmCurrentDate = Datetime.now(); // Get the current date and time
		DateTime finalDateTime = dtmCurrentDate;
		if (strAddOrSubtract.containsIgnoreCase('add')) {
			BusinessHours objBusinessHours = GlobalQueryHelper.getDefaultBusinessHour();
			if (objBusinessHours != null && intDays > 0) {
				Long oneDayWorkingHoursInMilliSecs = 9 * 60 * 60 * 1000;
				Long daysRangeInMillisecond = intDays * oneDayWorkingHoursInMilliSecs;
				finalDateTime = BusinessHours.add(objBusinessHours.Id, dtmCurrentDate, daysRangeInMillisecond);
			}
		} else {
			while (intDays > 0) {
				dtmCurrentDate = dtmCurrentDate.addDays(-1); // substract one day

				// Check if the resulting day is a weekend (Saturday or Sunday)
				if (dtmCurrentDate.format('E') != 'Sat' && dtmCurrentDate.format('E') != 'Sun') {
					intDays--; // If not a weekend, add/subtract one business day
				}
			}

			finalDateTime = DateTime.newInstance(dtmCurrentDate.year(), dtmCurrentDate.month(), dtmCurrentDate.day(), 0, 0, 0);
		}
		return finalDateTime;
	}

	/**
	 * @description Replaces custom functions in the input query with the actual values
	 * @param       String - Input query
	 * @return      String - The resulting query after replacement
	 **/
	public static String replaceCustomFunctions(String strInputQuery) {
		// Convert the input query to upper case
		strInputQuery = strInputQuery.toUpperCase();
		// Compile the pattern to find N_BUSINESS_DAYS_AGO
		strInputQuery = replaceNBusinessDays(N_BUSINESS_DAYS_AGO, strInputQuery);
		// Compile the pattern to find N_BUSINESS_DAYS_AGO
		strInputQuery = replaceNBusinessDays(N_BUSINESS_DAYS_FUTURE, strInputQuery);
		// Compile the pattern to find N_BUSINESS_DAYS_AGO for Date Type
		strInputQuery = replaceNBusinessDays(N_D_BUSINESS_DAYS_AGO, strInputQuery);
		// Compile the pattern to find N_BUSINESS_DAYS_AGO for Date Type
		strInputQuery = replaceNBusinessDays(N_D_BUSINESS_DAYS_FUTURE, strInputQuery);
		// replace ownerId with logged in user
		strInputQuery = strInputQuery.replaceAll(OWNER_ID_MYSELF, UserInfo.getUserId());

		// return the resulting query
		return strInputQuery;
	}

	/**
	 * @description Receieves a query with custom functions and replaces custom functions with actual values
	 * @param       String - Input query
	 * @return      String - The resulting query after replacement
	 **/
	public static String convertCustomFunctionsToSOQL(String strQuery) {
		Boolean blnCustomFunction = false;
		for (String strCustomFunctions : CUSTOM_FUNCTIONS) {
			if (strQuery.containsIgnoreCase(strCustomFunctions)) {
				blnCustomFunction = true;
				break;
			}
		}
		if (blnCustomFunction) {
			strQuery = replaceCustomFunctions(strQuery);
		}
		return strQuery;
	}

	/**
	 * @description Replaces custom functions in the input query with the actual values of N business days
	 * @param       String - function name to replace
	 * @param       String - Input query
	 * @return      String - The resulting query after replacement
	 **/
	public static string replaceNBusinessDays(String strFunctionName, String strInputQuery) {
		// Compile the pattern to find N_BUSINESS_DAYS_AGO
		Pattern objPattern = System.Pattern.compile(strFunctionName + ':\\d+');
		Matcher objMatcher = objPattern.matcher(strInputQuery);

		while (objMatcher.find()) {
			String strMatch = objMatcher.group();

			// Get number of days to add/subract
			List<String> list_Splits = strMatch.split(':');
			Integer intDays = Integer.valueOf(list_Splits.get(1));
			// add/subract N business days
			Datetime dtmUpdatedDateTime;
			if (strFunctionName == N_BUSINESS_DAYS_AGO || strFunctionName == N_D_BUSINESS_DAYS_AGO) {
				dtmUpdatedDateTime = nBusinessDays(intDays, 'subtract');
			} else if (strFunctionName == N_BUSINESS_DAYS_FUTURE || strFunctionName == N_D_BUSINESS_DAYS_FUTURE) {
				dtmUpdatedDateTime = nBusinessDays(intDays, 'add');
			}
			// Replace the query with the actual date base of date-datetime type
			if (strFunctionName == N_D_BUSINESS_DAYS_AGO || strFunctionName == N_D_BUSINESS_DAYS_FUTURE) {
				strInputQuery = strInputQuery.replaceAll(strMatch, dtmUpdatedDateTime.formatGmt('yyyy-MM-dd'));
			} else {
				strInputQuery = strInputQuery.replaceAll(strMatch, dtmUpdatedDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
			}
		}
		return strInputQuery;
	}
}