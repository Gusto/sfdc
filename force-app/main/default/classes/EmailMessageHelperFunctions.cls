public class EmailMessageHelperFunctions {
	public static Map<String, Pattern_Matching__mdt> map_PatternMatchings; 
	public static String strTypeofPatternMatching;
	public static Map<String, List<String>> map_SubjectToBodyPatterns;
	public static List<String> listContactsToIgnore;
	public static Set<String> set_UniqueCarrierNames;
	public static Id IdCarrierContactsAccount = System.label.Carrier_Account_Id;

	public static Map<String, Pattern_Matching__mdt> getPatternMatchingMap(String strType) {
		if (strTypeofPatternMatching == null) {
			strTypeofPatternMatching = strType;
		}

		if (map_PatternMatchings == null || strTypeofPatternMatching != strType) {
			map_PatternMatchings = new Map<String, Pattern_Matching__mdt>();

			for (Pattern_Matching__mdt pm : [
				SELECT MasterLabel, Contains__c, Carrier_Name__c, Preference_Index__c, Is_Active__c, Type__c, Email_Subject__c, Is_Group_Number_Pattern__c, Remove_From_End__c, Is_Partial_Match__c
				FROM Pattern_Matching__mdt
				WHERE Is_Active__c = TRUE AND Type__c = :strType
				ORDER BY Preference_Index__c ASC
			]) {
				map_PatternMatchings.put(pm.Contains__c.toLowerCase(), pm);
			}
		}
		return map_PatternMatchings;
	}

	public static Map<String, Pattern_Matching__mdt> getPatternMatchingMap(String strType, Boolean getOnlyGroupNumberPatterns, Boolean getOnlyPartialMatches) {
		if (strTypeofPatternMatching == null) {
			strTypeofPatternMatching = strType;
		}

		if (map_PatternMatchings == null || strTypeofPatternMatching != strType) {
			map_PatternMatchings = new Map<String, Pattern_Matching__mdt>();
			if (getOnlyGroupNumberPatterns) {
				for (Pattern_Matching__mdt pm : [
					SELECT MasterLabel, Contains__c, Carrier_Name__c, Preference_Index__c, Is_Active__c, Type__c, Email_Subject__c, Is_Group_Number_Pattern__c, Remove_From_End__c, Is_Partial_Match__c
					FROM Pattern_Matching__mdt
					WHERE Is_Active__c = TRUE AND Type__c = :strType AND Is_Group_Number_Pattern__c = :getOnlyGroupNumberPatterns
					ORDER BY Preference_Index__c ASC
				]) {
					map_PatternMatchings.put(pm.Contains__c, pm);
				}
			} else if (getOnlyPartialMatches) {
				for (Pattern_Matching__mdt pm : [
					SELECT MasterLabel, Contains__c, Carrier_Name__c, Preference_Index__c, Is_Active__c, Type__c, Email_Subject__c, Is_Group_Number_Pattern__c, Remove_From_End__c, Is_Partial_Match__c
					FROM Pattern_Matching__mdt
					WHERE Is_Active__c = TRUE AND Type__c = :strType AND Is_Partial_Match__c = :getOnlyPartialMatches
					ORDER BY Preference_Index__c ASC
				]) {
					map_PatternMatchings.put(pm.Contains__c.toLowerCase(), pm);
				}
			}
		}
		return map_PatternMatchings;
	}

	// Map of Subjects to Body Patterns
	public static Map<String, List<String>> getSubjectToBodyPatternsMap(String strType) {
		if (map_SubjectToBodyPatterns == null) {
			map_SubjectToBodyPatterns = new Map<String, List<String>>();
			for (Pattern_Matching__mdt pm : [
				SELECT MasterLabel, Contains__c, Carrier_Name__c, Preference_Index__c, Is_Active__c, Type__c, Email_Subject__c, Is_Group_Number_Pattern__c, Remove_From_End__c
				FROM Pattern_Matching__mdt
				WHERE Is_Active__c = TRUE AND Type__c = :strType
				ORDER BY Preference_Index__c ASC
			]) {
				map_SubjectToBodyPatterns.put(pm.Email_Subject__c.toLowerCase(), pm.Contains__c.toLowerCase().split(';'));
			}
		}
		return map_SubjectToBodyPatterns;
	}

	public static List<String> getAllContactsToIgnoreList(Set<String> insertedEmailAddresses) {
		if (listContactsToIgnore == null) {
			listContactsToIgnore = new List<String>();
			for (Contact c : [
				SELECT Id, Name, Email
				FROM Contact
				WHERE AccountId != :IdCarrierContactsAccount AND Account.ZP_Company_ID__c != NULL AND Email != NULL AND Email IN :insertedEmailAddresses
			]) {
				listContactsToIgnore.add(c.Email);
			}
		}
		return listContactsToIgnore;
	}

	public static Set<String> getAllCarrierNames() {
		if (set_UniqueCarrierNames == null) {
			set_UniqueCarrierNames = new Set<String>();
			List<AggregateResult> list_UniqueCarriers = new List<AggregateResult>();
			for (AggregateResult ar : [
				SELECT Carrier_Unique_Name__c
				FROM Carrier__c
				WHERE Carrier_Id__c != NULL
				GROUP BY Carrier_Unique_Name__c
			]) {
				list_UniqueCarriers.add(ar);
			}

			for (AggregateResult ar : list_UniqueCarriers) {
				String strTemp = (String) ar.get('Carrier_Unique_Name__c');
				if(String.isNotBlank(strTemp)){
					set_UniqueCarrierNames.add(strTemp.toLowerCase());
				}
			}
		}
		return set_UniqueCarrierNames;
	}

	// Method will go through all the stored patterns and do pattern match to get the subject down to a matchable string for Account matching
	public static String doPatternMatching(String strEmailSubject, Email_Message__c objEmailMessage, Boolean blnIgnoreEmail, String strTempMatch, String strEmailBody) {
		String strRegexReplacement = '';
		String strMatch = '';
		String strGroupNumberMatch = '';
		String strTempSubjectForGroupMatch = '';
		// Maps to get different types of patterns stored in Pattern_Matching Metadata type for our matching algorithm
		Map<String, Pattern_Matching__mdt> map_AllNonActionableSubjects = getPatternMatchingMap('Non_Actionable_Subject');
		Map<String, Pattern_Matching__mdt> map_AllPartialMatchedNonActionableSubjects = getPatternMatchingMap('Non_Actionable_Subject', false, true);
		Map<String, Pattern_Matching__mdt> map_AllPrefixes = getPatternMatchingMap('Prefix');
		Map<String, Pattern_Matching__mdt> map_AllRegex = getPatternMatchingMap('Regex');
		Map<String, Pattern_Matching__mdt> map_AllGroupNumberPatterns = getPatternMatchingMap('Regex', true, false);
		Map<String, Pattern_Matching__mdt> map_AllSpecialCharacters = getPatternMatchingMap('Special_Character');
		Map<String, Pattern_Matching__mdt> map_AllSubjectPatterns = getPatternMatchingMap('Subject_Pattern');
		Map<String, List<String>> map_SubjectToBodyPatterns = getSubjectToBodyPatternsMap('Body_Pattern');
		// SJay - 5/18/2020 - Querying all carrier names to remove them from email subject.
		getAllCarrierNames();
		// SJay - 5/21/2020 - Converting to lower case for better matching rates.
		strTempSubjectForGroupMatch = strEmailSubject;
		strEmailSubject = strEmailSubject.toLowerCase();

		// Ignoring any Non Actionable Subjects
		if (map_AllNonActionableSubjects != null && map_AllNonActionableSubjects.containsKey(strEmailSubject)) {
			blnIgnoreEmail = true;
			objEmailMessage.Is_Non_Actionable_Email__c = true;
			objEmailMessage.Ignore_from_Search__c = true;
		} else if (map_AllPartialMatchedNonActionableSubjects != null) {
			for (String subjectPattern : map_AllPartialMatchedNonActionableSubjects.keySet()) {
				if (String.isNotBlank(subjectPattern) && strEmailSubject.containsIgnoreCase(subjectPattern)) {
					blnIgnoreEmail = true;
					objEmailMessage.Is_Non_Actionable_Email__c = true;
					objEmailMessage.Ignore_from_Search__c = true;
					break;
				}
			}
		}
		if (!blnIgnoreEmail) {
			// Removing any body patterns from known subjects and their given body patterns.
			if (map_SubjectToBodyPatterns != null && map_SubjectToBodyPatterns.containsKey(strEmailSubject)) {
				strTempMatch = strEmailBody.trim().left(255);
				strTempMatch = strTempMatch.toLowerCase();
				for (String bodyPattern : map_SubjectToBodyPatterns.get(strEmailSubject)) {
					if (String.isNotBlank(bodyPattern) && strTempMatch.containsIgnoreCase(bodyPattern)) {
						strTempMatch = strTempMatch.remove(bodyPattern);
					}
				}
			} else {
				// Removing any subject patterns from Subject
				strTempMatch = strEmailSubject;
				if (map_AllSubjectPatterns != null) {
					for (String subjectPattern : map_AllSubjectPatterns.keySet()) {
						if (String.isNotBlank(subjectPattern) && strTempMatch.containsIgnoreCase(subjectPattern)) {
							strTempMatch = strTempMatch.remove(subjectPattern);
						}
					}
				}
			}
			if (!set_UniqueCarrierNames.isEmpty()) {
				for (String carrierName : set_UniqueCarrierNames) {
					if (String.isNotBlank(carrierName) && strTempMatch.containsIgnoreCase(carrierName)) {
						strTempMatch = strTempMatch.remove(carrierName);
					}
				}
			}

			// Removing any regex found from Subject
			if (map_AllGroupNumberPatterns != null) {
				for (String regexPattern : map_AllGroupNumberPatterns.keySet()) {
					if (String.isNotBlank(regexPattern)) {
						Matcher m = Pattern.compile(regexPattern).matcher(strTempSubjectForGroupMatch);
						if (m.find()) {
							strGroupNumberMatch = m.group();
							break;
						}
					}
				}
			}

			// Removing any regex found from Subject
			if (map_AllRegex != null) {
				for (String regexPattern : map_AllRegex.keySet()) {
					if (String.isNotBlank(regexPattern)) {
						strTempMatch = strTempMatch.replaceAll(regexPattern, strRegexReplacement);
					}
				}
			}
			// Removing any prefixes such as Re, Fw, etc found from Subject
			if (map_AllPrefixes != null) {
				for (String prefixPattern : map_AllPrefixes.keySet()) {
					if (String.isNotBlank(prefixPattern) && strTempMatch.toLowerCase().containsIgnoreCase(prefixPattern.toLowerCase())) {
						strTempMatch = strTempMatch.remove(prefixPattern);
					}
				}
			}
			strTempMatch = strTempMatch.trim();
			// Removing any special characters such as -,{}, etc found from Subject
			if (map_AllSpecialCharacters != null) {
				for (String specialCharacterPattern : map_AllSpecialCharacters.keySet()) {
					if (
						String.isNotBlank(specialCharacterPattern) &&
						strTempMatch.containsIgnoreCase(specialCharacterPattern) &&
						map_AllSpecialCharacters.get(specialCharacterPattern).Remove_From_End__c == false
					) {
						strTempMatch = strTempMatch.remove(specialCharacterPattern);
					} else if (
						String.isNotBlank(specialCharacterPattern) &&
						strTempMatch.endsWith(specialCharacterPattern) &&
						map_AllSpecialCharacters.get(specialCharacterPattern).Remove_From_End__c
					) {
						strTempMatch = strTempMatch.removeEnd(specialCharacterPattern);
					}
				}
			}
			// If the processed string is different from the inbound subject only then write it into Possible Match field.
			if (!strTempMatch.equals(strEmailSubject)) {
				objEmailMessage.Possible_Match__c = strTempMatch;
				strMatch = strTempMatch;
			}
			if (String.isNotBlank(strGroupNumberMatch)) {
				objEmailMessage.Possible_Group_Number__c = strGroupNumberMatch;
			}
		}
		return strMatch;
	}

	// Method will check for any customer emails and sets the Is_Customer_Email__c flag on Custom Email Message
	public static Boolean checkForCustomerEmails(String strFromAddress, Email_Message__c objEmailMessage) {
		Boolean blnIsCustomerEmail = false;
		List<Contact> customerConList = [
			SELECT Id, Name, Email
			FROM Contact
			WHERE Email = :strFromAddress AND AccountId != :IdCarrierContactsAccount AND Account.ZP_Company_ID__c != NULL
			LIMIT 1
		];
		if (!customerConList.isEmpty()) {
			objEmailMessage.Ignore_from_Search__c = true;
			objEmailMessage.Is_Customer_Email__c = true;
			blnIsCustomerEmail = true;
		}
		return blnIsCustomerEmail;
	}

	// Method will check for any Gusto emails and sets the Is_Gusto_Email__c flag on Custom Email Message
	public static Boolean checkForGustoEmails(String strFromAddress, String strReplyToAddress, Email_Message__c objEmailMessage) {
		Boolean blnIsFromGustoEmail = false;
		if (strReplyToAddress != null && strReplyToAddress.contains('@gusto.com') || strReplyToAddress.contains('@zenpayroll.com')) {
			objEmailMessage.Ignore_from_Search__c = true;
			objEmailMessage.Is_Gusto_Email__c = true;
			blnIsFromGustoEmail = true;
		}
		return blnIsFromGustoEmail;
	}

	// Method will check for any From Address to be ignored and sets the Is_From_Address_Ignored__c flag on Custom Email Message
	public static Boolean checkForFromAddressesToIgnore(String strFromAddress, String strReplyToAddress, Email_Message__c objEmailMessage) {
		Boolean blnIsFromAddressIgnored = false;
		Map<String, Pattern_Matching__mdt> map_AllIgnoredFromAddressPatterns = getPatternMatchingMap('Ignore_From_Address');

		// Check if From Address is to be ignored then ignore that email message from the view.
		if (map_AllIgnoredFromAddressPatterns != null && map_AllIgnoredFromAddressPatterns.containsKey(strReplyToAddress)) {
			objEmailMessage.Ignore_from_Search__c = true;
			objEmailMessage.Is_From_Address_Ignored__c = true;
			blnIsFromAddressIgnored = true;
		}

		return blnIsFromAddressIgnored;
	}

	// Method to handle base64 Image URl in HTML Body.
	public static String replaceBase64URLFromHTMLBody(String strHtmlTextBody) {
		Map<String, Pattern_Matching__mdt> map_AllBase65URLRegex = getPatternMatchingMap('Body_Regex');

		for (String strRegexBase64URL : map_AllBase65URLRegex.keySet()) {
			if (String.isNotBlank(strRegexBase64URL)) {
				Matcher objMatcher = Pattern.compile(strRegexBase64URL).matcher(strHtmlTextBody);

				while (objMatcher.find()) {
					String strMatched = objMatcher.group();
					strHtmlTextBody = strHtmlTextBody.replace(strMatched, '');
				}
			}
		}
		return strHtmlTextBody;
	}

	/*
	 * @Author:      Midhuna KB
	 * @Description: Get records from Custom Metadata - Email Case Type
	 * @Parm:        N/A
	 * @Return:      Map of EmailAddress - Case RecordType to Case Type
	 */
	public static Map<String, String> getEmailCaseTypeMetadata() {
		Map<String, String> map_EmailAddressToCaseRecordType = new Map<String, String>();
		List<Email_Case_Type__mdt> list_EmailCaseTypeMdt = new List<Email_Case_Type__mdt>();

		if (Test.isRunningTest()) {
			list_EmailCaseTypeMdt = EmailMessageTriggerHelperTest.generateTestMetadata();
		} else {
			list_EmailCaseTypeMdt = [
				SELECT Email_Address__c, Record_Type__c, IsActive__c, Type__c
				FROM Email_Case_Type__mdt
				WHERE IsActive__c = TRUE
			];
		}

		for (Email_Case_Type__mdt objEmailCaseType : list_EmailCaseTypeMdt) {
			map_EmailAddressToCaseRecordType.put(objEmailCaseType.Email_Address__c + '-' + objEmailCaseType.Record_Type__c, objEmailCaseType.Type__c);
		}

		return map_EmailAddressToCaseRecordType;
	}

	/*
	 * @Author:      Ankit C
	 * @Description: Check if the emali has any matching patterns in the Subject/Body.
	 * @Parm:        N/A
	 * @Return:      Boolean- true if a match is found
	 */
	public static Boolean checkEmailPatternMatch(EmailMessage objEmailMessage, Pattern_Matching__mdt objPatternMatching) {
		Boolean blnMatchFound = false;
		String strLatestMessage = '';
		if (String.isNotBlank(objEmailMessage.TextBody)) {
			strLatestMessage = objEmailMessage.TextBody;

			for (String strDelimiter : Label.Engagement_Email_Delimiter.split(';')) {
				if (strLatestMessage.contains(strDelimiter)) {
					strLatestMessage = strLatestMessage.substring(0, strLatestMessage.indexOf(strDelimiter) + strDelimiter.length());
					break;
				}
			}
		}

		//Remove any number patterns from the email body.
		if (String.isNotBlank(objPatternMatching.Common_Regex__c)) {
			for (String strRegex : objPatternMatching.Common_Regex__c.split(';')) {
				strLatestMessage = strLatestMessage.replaceAll(strRegex.trim(), '');
			}
		}

		strLatestMessage = strLatestMessage.trim();

		//Check if the email contains any keywords that should be ignored while auto-closing
		if (String.isNotBlank(objPatternMatching.Ignored_Subjects__c)) {
			for (String strText : objPatternMatching.Ignored_Subjects__c.split(';')) {
				if (strLatestMessage.containsIgnoreCase(strText.trim())) {
					return blnMatchFound;
				}
			}
		}

		//Check if the subject line has any matching patterns
		if (String.isNotBlank(objPatternMatching.Common_Subjects__c)) {
			for (String strText : objPatternMatching.Common_Subjects__c.split(';')) {
				if (objEmailMessage.Subject.containsIgnoreCase(strText.trim())) {
					blnMatchFound = true;
					break;
				}
			}
		}

		//Check if the email body has any matching patterns
		if (String.isNotBlank(objPatternMatching.Common_Body_Patterns__c)) {
			for (String strText : objPatternMatching.Common_Body_Patterns__c.split(';')) {
				if (strLatestMessage.containsIgnoreCase(strText.trim()) && strLatestMessage.length() < objPatternMatching.Max_Char_for_Email_Body__c) {
					blnMatchFound = true;
					break;
				}
			}
		}

		return blnMatchFound;
	}
}