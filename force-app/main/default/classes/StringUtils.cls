/**
 * @description  Class for String Utilities
 * @author Rushi Ravisaheb
 * @since Dec 2021
 * @see StringUtilsTest
 **/
public without sharing class StringUtils {
	/**
	 * @description Return Opportunity Name reduced to 120 Characters
	 * @author Rushi Ravisaheb
	 * @param  strName    Opportunity's Name parameter e.g. Account Name
	 * @param  strPostFix Additional character to concatenate to strName
	 * @return            Opportunity Name reduced to 120 characters
	 */
	public static String getOppName(String strName, String strPostFix) {
		return StringUtils.getJoinedString(strName, null, strPostFix, null, 120);
	}

	/**
	 * @description Most object Name fields are only 80 characters. This appends a suffix to a base string and clips to 80 chars
	 *
	 * @param strName   Base string
	 * @param strSuffix Suffix to append to string
	 * @return          `String` String shortened to 80 characters
	 */
	public static String getRecordName(String strName, String strSuffix) {
		return StringUtils.getJoinedString(strName, null, strSuffix, null, 80);
	}

	/**
	 * @author        Rushi Ravisaheb
	 * @description   To get trimmed string to use in record assignment where field Length is limited
	 * @param         strBase Main string to get concatenated
	 * @param         strPreFix [Optional] Prefix to concatenate to Base String
	 * @param         strPostFix [Optional] Postfix to concatenate to Base String
	 * @param         strJoinStr [Optional] String to concatenate supplied strings
	 * @param         intLength Maximum length to which the result is trimmed to
	 * @return        Concatenated and trimmed string based on supplied parameters
	 **/
	@TestVisible
	private static String getJoinedString(String strBase, String strPreFix, String strPostFix, String strJoinStr, Integer intLength) {
		strJoinStr = String.isBlank(strJoinStr) ? ' - ' : strJoinStr;

		if (String.isNotBlank(strPreFix)) {
			strBase = strPreFix + strJoinStr + strBase;
		}

		if (String.isNotBlank(strPostFix)) {
			strBase = strBase + strJoinStr + strPostFix;
		}

		if (strBase.length() > intLength) {
			strBase = strBase.left(intLength);
		}
		return strBase;
	}
}