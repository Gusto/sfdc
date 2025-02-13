/*
    By : Pravesh
    Date : April 14, 2017
*/
public with sharing class NormalizationUtil {
	list<string> companyAcronymsList = new List<string>();
	map<string, string> streetCommonStandardizedvalueMap = new Map<string, string>();
	set<string> secondaryUnitCommonStandardizedValueSet = new Set<string>();
	map<string, string> geographicalCommonStandardizedValueMap = new Map<string, string>();

	public NormalizationUtil() {
		if (Company_acronyms__c.getall().keyset().size() > 0)
			companyAcronymsList.addAll(Company_acronyms__c.getall().Keyset());

		if (Street_Suffix_Abbrevation__c.getall() != null && Street_Suffix_Abbrevation__c.getall().keyset().size() > 0) {
			for (string rec : Street_Suffix_Abbrevation__c.getall().keyset()) {
				streetCommonStandardizedvalueMap.put(rec.tolowerCase(), Street_Suffix_Abbrevation__c.getall().get(rec).Standardized__c.tolowerCase());
			}
		}

		if (Secondary_Unit_Designators__c.getall() != null && Secondary_Unit_Designators__c.getall().keyset().size() > 0) {
			for (string rec : Secondary_Unit_Designators__c.getall().keyset()) {
				secondaryUnitCommonStandardizedValueSet.add(rec.tolowerCase());
				secondaryUnitCommonStandardizedValueSet.add(Secondary_Unit_Designators__c.getall().get(rec).Standardized__c.tolowerCase());
			}
		}

		if (Geographical_Directions_Acronyms__c.getall() != null && Geographical_Directions_Acronyms__c.getall().keyset().size() > 0) {
			for (string rec : Geographical_Directions_Acronyms__c.getall().keyset()) {
				geographicalCommonStandardizedValueMap.put(rec, Geographical_Directions_Acronyms__c.getall().get(rec).Standardized_Value__c.tolowerCase());
			}
		}
	}

	/*
        Functionality Implemented :
        a.) converting to lowercase
        b.) removing the common email domains present in custom setting object "Email_Domain__c"
        c.)Parse email domain from address
    */
	public string normaliseDomainField(string originalEmailValue) {
		if (originalEmailValue == null || originalEmailValue.length() == 0) {
			return originalEmailValue;
		}

		string normalizedDomainValue;
		if (originalEmailValue.contains('@')) {
			normalizedDomainValue = originalEmailValue.substring(originalEmailValue.indexof('@'), originalEmailValue.length()).replace('@', '').trim();
			list<Email_Domain__c> domainList = [SELECT name FROM Email_Domain__c WHERE Name = :normalizedDomainValue LIMIT 1];
			Email_Domain__c commonEmailDomain = new Email_Domain__c();
			if (domainList != null && domainList.size() > 0) {
				commonEmailDomain = domainList.get(0);
			}
			normalizedDomainValue = normalizedDomainValue.toLowerCase();
			if (commonEmailDomain != null && commonEmailDomain.Name != null) {
				normalizedDomainValue = '';
			}
		}

		return normalizedDomainValue;
	}

	/*
        This method is used to return the normalised Naame to be saved.

        Functionality Implemented :
        a.) converting to lowercase
        b.) Remove special characters
        c.) Remove acronyms from end
    */
	public string normaliseNameField(string originalNameValue) {
		if (originalNameValue == null || originalNameValue.length() == 0) {
			return originalNameValue;
		}

		string normalizedNameValue = originalNameValue;
		normalizedNameValue = normalizedNameValue.tolowercase();

		// removing the acronym from the end.
		if (companyAcronymsList != null && companyAcronymsList.size() > 0) {
			for (string rec : companyAcronymsList) {
				rec = rec.tolowerCase();
				list<string> nameList = normalizedNameValue.split(' ');
				list<string> acronymList = rec.split(' ');

				if (acronymList != null && acronymList.size() > 0) {
					if (acronymList.size() == 1) {
						if (nameList[nameList.size() - 1].equals(rec)) {
							normalizedNameValue = normalizedNameValue.substring(0, normalizedNameValue.lastIndexOf(rec));
						}
					} else if (acronymList.size() > 1 && normalizedNameValue.contains(rec)) {
						normalizedNameValue = normalizedNameValue.substring(0, normalizedNameValue.lastIndexOf(rec));
					}
				}
			}
		}

		// removing the special characters from the company name.
		normalizedNameValue = normalizedNameValue.replaceAll('[|,|.|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\-\\(|\\)|\\{|\\}|\\;|\\\'"]', '');
		normalizedNameValue = normalizedNameValue.replaceAll(' ', '');

		return normalizedNameValue;
	}

	/*
        This method is used to return the normalised Naame to be saved.

        Functionality Implemented :
        a.) converting to lowercase
        b.) Remove special characters
        c.)Standardize Street Suffix Abbreviations
        d.)Remove Secondary Unit Designators (Both description and abbreviation)
        e.)Standardize Geographic Names

    */
	public string normaliseAddressField(string originalAddressValue) {
		if (originalAddressValue == null || originalAddressValue.length() == 0) {
			return originalAddressValue;
		}

		string normalizedAddressValue = originalAddressValue;

		string tempNamestr = normalizedAddressValue;
		normalizedAddressValue = normalizedAddressValue.replaceAll('[|,|.|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\-\\(|\\)|\\{|\\}|\\;|\\\'"]', '');
		normalizedAddressValue = normalizedAddressValue.toLowerCase();

		for (string str : normalizedAddressValue.split(' ')) {
			//Standardizing Street Suffix Abbreviations
			str = str.trim();
			if (streetCommonStandardizedvalueMap != null && streetCommonStandardizedvalueMap.keyset().size() > 0) {
				if (streetCommonStandardizedvalueMap.containsKey(str)) {
					normalizedAddressValue = normalizedAddressValue.replace(str, streetCommonStandardizedvalueMap.get(str));
				}
			}
			//Removeing Secondary Unit Designators (both description and abbreviation)
			if (secondaryUnitCommonStandardizedValueSet != null && secondaryUnitCommonStandardizedValueSet.size() > 0) {
				if (secondaryUnitCommonStandardizedValueSet.contains(str)) {
					normalizedAddressValue = normalizedAddressValue.replace(str, '');
				}
			}
			//Standardizing Geographic Names
			if (geographicalCommonStandardizedValueMap != null && geographicalCommonStandardizedValueMap.keyset().size() > 0) {
				if (geographicalCommonStandardizedValueMap.containsKey(str)) {
					normalizedAddressValue = normalizedAddressValue.replace(str, geographicalCommonStandardizedValueMap.get(str));
				}
			}
		}

		normalizedAddressValue = normalizedAddressValue.replaceAll(' ', '');

		return normalizedAddressValue;
	}

	/*
        Standardize Zip code to 5 digits
    */
	public string normalisePostalCodeField(string originalPostalCodeValue) {
		if (originalPostalCodeValue == null || originalPostalCodeValue.length() == 0) {
			return originalPostalCodeValue;
		}

		string normalizedPostalCodeValue = originalPostalCodeValue;

		if (normalizedPostalCodeValue.length() > 5) {
			normalizedPostalCodeValue = normalizedPostalCodeValue.substring(0, 5);
		}
		return normalizedPostalCodeValue;
	}

	/*
        This method is used to return the normalised Phone Number to be saved.

        Functionality Implemented :
        a.) remove special characters
        b.) remove country code
        c.)standardize phone to 9 digits
    */
	public string normalisePhoneField(string originalPhoneValue) {
		if (originalPhoneValue == null || originalPhoneValue.length() == 0) {
			return originalPhoneValue;
		}

		string normalizedPhoneValue = originalPhoneValue;

		normalizedPhoneValue = normalizedPhoneValue.replaceAll('[|,|.|\\,||"||:|~|!|@|#|$|%|^|&|*|_|+|=|<|>|?|\\-\\(|\\)|\\{|\\}|\\;|\\\'"]', '');
		normalizedPhoneValue = normalizedPhoneValue.replaceAll(' ', '');

		if (normalizedPhoneValue.length() == 11 && normalizedPhoneValue.contains('1') && normalizedPhoneValue.indexOf('1') == 0) {
			normalizedPhoneValue = normalizedPhoneValue.substring(1, normalizedPhoneValue.length());
		} else if (normalizedPhoneValue.length() > 10) {
			//invalid
			normalizedPhoneValue = '';
		}

		return normalizedPhoneValue;
	}

	/*  Functionality Implemented :
        Same as normaliseDomainField but bulkified
        By: Gaurav Khare : 4-Dec-19
    */
	public Map<String, String> normaliseDomainFieldBulkified(set<String> setEmails) {
		Map<String, String> mapEmailToNormalizedValue = new Map<String, String>();
		Map<String, String> finalEmailToNormalizedValueMap = new Map<String, String>();
		string normalizedDomainValue;
		for (String email : setEmails) {
			if (email != null && email.contains('@')) {
				normalizedDomainValue = email.substring(email.indexof('@'), email.length()).replace('@', '').trim();
				mapEmailToNormalizedValue.put(email, normalizedDomainValue);
			}
		}
		Set<String> commonEmailDomainSet = new Set<String>();
		if (mapEmailToNormalizedValue.size() > 0) {
			list<Email_Domain__c> domainList = [SELECT name FROM Email_Domain__c WHERE Name IN :mapEmailToNormalizedValue.values()];

			for (Email_Domain__c emldmn : domainList) {
				commonEmailDomainSet.add(emldmn.name);
			}
		}
		for (String email : mapEmailToNormalizedValue.keyset()) {
			string normalizedDmnValue = mapEmailToNormalizedValue.get(email);
			normalizedDmnValue = normalizedDmnValue.toLowerCase();
			if (commonEmailDomainSet.contains(normalizedDmnValue)) {
				finalEmailToNormalizedValueMap.put(email, '');
			} else {
				finalEmailToNormalizedValueMap.put(email, normalizedDmnValue);
			}
		}
		return finalEmailToNormalizedValueMap;
	}
}