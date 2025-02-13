/**
 * @name         HIFulfillmentEventHelperFunctions
 * @author       Aurobind Ravichandran
 * @date         07/16/2017
 * @description
 * @revisions    Date ------------ Name ------------ Comments
 *				1/2/2020		  Anand         Added the check for Benefit BOR Record type
 **/
public class HIFulfillmentEventHelperFunctions {
	public static Set<String> set_RecordTypeNames = new Set<String>{ 'New Plan', 'Renewal', 'Benefits BoR' };
	public static Set<String> set_IgnoreBOStages = new Set<String>{ 'Closed Admin', 'Closed Lost', 'Canceled', 'Denied' };
	public static Set<String> set_AccountRecordTypeIds = new Set<String>{ Cache.getRecordTypeId('Account', 'Company'), Cache.getRecordTypeId('Account', 'Embedded Company') };

	public static date getDateFromString(String dte) {
		if (dte != null && dte != '' && dte != 'null') {
			String[] strArr = dte.split('-');
			Date dt = Date.newInstance(Integer.valueOf(strArr[0]), Integer.valueOf(strArr[1]), Integer.valueOf(strArr[2]));
			return dt;
		}
		return null;
	}

	public static DateTime getDateTimeFromString(String dtmStr) {
		String datePart = dtmStr.split('T')[0];
		String timePart = dtmStr.split('T')[1].replace('.', 'X').split('X')[0];
		String[] datePartArr = datePart.split('-');
		String[] timePartArr = timePart.split(':');
		DateTime dtm = datetime.newInstance(
			Integer.valueOf(datePartArr[0]),
			Integer.valueOf(datePartArr[1]),
			Integer.valueOf(datePartArr[2]),
			Integer.valueOf(timePartArr[0]),
			Integer.valueOf(timePartArr[1]),
			Integer.valueOf(timePartArr[2])
		);
		return dtm;
	}

	//Query Benefit Order object
	public static map<String, Benefit_Order__c> getBenefitOrderMap(Set<String> set_zpCompanyIds) {
		Map<String, Benefit_Order__c> map_orderMap = new Map<String, Benefit_Order__c>();
		for (Benefit_Order__c objBO : [
			SELECT
				Id,
				Account__r.ZP_Company_ID__c,
				OwnerId,
				Closed__c,
				Order_Status__c,
				RecordTypeId,
				RecordType.Name,
				RecordType.DeveloperName,
				Application_Id__c,
				(SELECT Id, Benefit_Types__c, Carrier__r.Id__c FROM Carrier_Orders__r)
			FROM Benefit_Order__c
			WHERE Order_Status__c NOT IN :set_IgnoreBOStages AND Account__r.ZP_Company_ID__c IN :set_zpCompanyIds AND RecordType.Name IN :set_RecordTypeNames
		]) {
			String strApplicationId = objBO.Application_Id__c;
			if (String.isNotBlank(strApplicationId)) {
				if (objBO.RecordType.Name.equalsIgnoreCase(HIEnrollmentEventUtility.BO_RECORD_TYPE_BENFITS_BOR)) {
					strApplicationId = strApplicationId.replace('hawaiian_ice-bor_transfer-', '');
				}
				map_orderMap.put(objBO.Account__r.ZP_Company_ID__c + strApplicationId, objBO);
			} else {
				map_orderMap.put(objBO.Account__r.ZP_Company_ID__c, objBO);
			}
		}

		return map_orderMap;
	}

	//get contact full name
	public static string getName(String firstName, String lastName, String middleName) {
		String name = '';
		if (firstName != null && firstName != '' && firstName != 'null') {
			name += firstName + ' ';
		}
		if (middleName != null && middleName != '' && middleName != 'null') {
			name += middleName + ' ';
		}
		if (lastName != null && lastName != '' && lastName != 'null') {
			name += lastName;
		}
		return name;
	}

	//get complete address
	public static string getAddress(String street1, String street2, String city, String county_name, String state, String zip, String country) {
		String address = '';
		if (street1 != null && street1 != '' && street1 != 'null') {
			address += street1 + ' ';
		}
		if (street2 != null && street2 != '' && street2 != 'null') {
			address += street2;
		}
		if (city != null && city != '' && city != 'null') {
			address += ', ' + city;
		}
		if (county_name != null && county_name != '' && city != 'county_name') {
			address += ', ' + county_name;
		}
		if (state != null && state != '' && state != 'county_name') {
			address += ', ' + state;
		}
		if (zip != null && zip != '' && zip != 'county_name') {
			address += ', ' + zip;
		}
		if (country != null && country != '' && country != 'county_name') {
			address += ', ' + country;
		}
		return address;
	}
	// query contact records using ZP User Ids
	public static map<String, Contact> getContactsForEmployeeID(Set<String> set_EmployeeID) {
		map<String, Contact> map_Contacts = new Map<String, Contact>();
		for (Contact objContact : [SELECT Id, Employee_Id__c, Email, Name FROM Contact WHERE Employee_Id__c != NULL AND Employee_Id__c IN :set_EmployeeID]) {
			map_Contacts.put('' + objContact.Employee_Id__c, objContact);
		}

		return map_Contacts;
	}
	//query account records using ZP Company Ids
	public static map<String, Account> getAccounts(Set<String> companyIdSet) {
		Map<String, Account> accountMap = new Map<String, Account>();
		for (Account acc : [SELECT Id, Name, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :companyIdSet AND RecordTypeId IN :set_AccountRecordTypeIds]) {
			accountMap.put('' + acc.ZP_Company_ID__c, acc);
		}
		return accountMap;
	}

	//query contacts using email Ids
	public static map<String, Contact> getContacts(Set<String> set_SearchKeys) {
		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		for (Contact objContact : [
			SELECT Id, Name, Email, AccountId, Account.ZP_Company_ID__c, Account.ZP_Firm_ID__c, FirstName, LastName, Employee_Id__c
			FROM Contact
			WHERE Email IN :set_SearchKeys OR Employee_Id__c IN :set_SearchKeys
		]) {
			map_Contacts.put(objContact.Email, objContact);
			if (String.isNotBlank(objContact.Account.ZP_Company_ID__c)) {
				map_Contacts.put(objContact.Account.ZP_Company_ID__c + '-' + objContact.Email, objContact);
			}

			if (String.isNotBlank(objContact.Account.ZP_Company_ID__c) && String.isNotBlank(objContact.Employee_Id__c)) {
				map_Contacts.put(objContact.Account.ZP_Company_ID__c + '-' + objContact.Employee_Id__c, objContact);
			}
		}

		return map_Contacts;
	}

	//query  Carrier records using carrier key
	public static map<String, Carrier__c> getCarrierInfo(Set<String> carrierKeySet) {
		map<String, Carrier__c> carrierMap = new Map<String, Carrier__c>();
		for (Carrier__c objCarrier : [SELECT Id, Key__c, State__c, Name, Id__c, Carrier_Unique_Name__c FROM Carrier__c WHERE Key__c IN :carrierKeySet]) {
			if (objCarrier.Key__c != null) {
				carrierMap.put(objCarrier.Key__c, objCarrier);
			}
		}
		return carrierMap;
	}

	//query  Carrier records using carrier id
	public static map<String, Carrier__c> getCarrierInfoById(Set<String> carrierIdSet) {
		map<String, Carrier__c> carrierMap = new Map<String, Carrier__c>();
		for (Carrier__c objCarrier : [SELECT Id, Id__c, Key__c, Name, State__c, Carrier_Unique_Name__c FROM Carrier__c WHERE Id__c IN :carrierIdSet]) {
			if (objCarrier.Key__c != null) {
				carrierMap.put(objCarrier.Id__c, objCarrier);
			}
		}
		return carrierMap;
	}

	public static string getFormatedSSN(String ssn) {
		String formatedSSN = '';
		if (ssn != null && ssn != '' && ssn != 'null') {
			//formatedSSN='XXX-XX-'+ssn.substring(5);
			for (integer i = 0; i < ssn.length(); i++) {
				formatedSSN += ssn.substring(i, i + 1);
				if (i == 2 || i == 5) {
					formatedSSN += '-';
				}
			}
		}
		return formatedSSN;
	}

	public static string getMaskedSSN(String ssn) {
		String formatedSSN = '';
		if (ssn != null && ssn != '' && ssn != 'null') {
			formatedSSN = 'XXX-XX-' + ssn.substring(5);
		}
		return formatedSSN;
	}

	public static string getChangeDateFormat(String dte) {
		String formatedDate = '';
		if (dte != null && dte != '' && dte != 'null') {
			String[] strArr = dte.split('-');
			formatedDate = strArr[1] + '-' + strArr[2] + '-' + strArr[0];
		}
		return formatedDate;
	}

	public static void setCaseGroupNumber(map<Id, Case> newCaseMap, map<Id, Case> oldCaseMap) {
		Set<Id> caseIdSet = new Set<Id>();
		for (Case c : newCaseMap.values()) {
			Case oldCase = oldCaseMap.get(c.id);
			if (
				((oldCase.MF_Group_Number__c != c.MF_Group_Number__c && c.MF_Group_Number__c != null && c.MF_Group_Number__c != '') ||
				(oldCase.MF_Policy_Number__c != c.MF_Policy_Number__c &&
				c.MF_Policy_Number__c != null &&
				c.MF_Policy_Number__c != '')) &&
				(c.Type == 'NHE' ||
				c.Type == 'Termination' ||
				c.Type == 'Member Updates') &&
				c.Status == 'On Hold' &&
				c.Fulfillment_Event_Encrypted_JSON__c != null
			) {
				caseIdSet.add(c.id);
			}
		}
		if (caseIdSet.size() > 0) {
			for (Case c : newCaseMap.values()) {
				if (!caseIdSet.contains(c.id))
					continue;

				Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
				Blob decryptedBlob = EncodingUtil.base64Decode(c.Fulfillment_Event_Encrypted_JSON__c);
				String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
				HIFulfillmentBotResponseJSON enrollmentResponse = (HIFulfillmentBotResponseJSON) System.JSON.deserialize(deCryptedText, HIFulfillmentBotResponseJSON.class);
				if (enrollmentResponse.policies != null && enrollmentResponse.policies.size() > 0) {
					for (HIFulfillmentBotResponseJSON.Policy pol : enrollmentResponse.policies) {
						if (pol.group_number == null || pol.group_number == '') {
							pol.group_number = c.MF_Group_Number__c;
						}
						if (pol.policy_number == null || pol.policy_number == '') {
							pol.policy_number = c.MF_Policy_Number__c;
						}
					}
				}
				Blob botEncryptedBlob = EncryptionUtils.getEncryptedBlob(encryptionKey, '' + JSON.serialize(enrollmentResponse));
				String botJsonString = EncodingUtil.base64Encode(botEncryptedBlob);
				c.Fulfillment_Event_Encrypted_JSON__c = botJsonString;
			}
		}
	}

	// this method is saving employee.dependent info in an attachment record in encrypted form.
	public static void createAttachment(List<Case> caseListForUpsert, map<String, HIFulfillmentAddToBasicPacific.CaseDataWrapper> caseWrapperMap) {
		List<Attachment> attachmentList = new List<Attachment>();
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		for (Case c : caseListForUpsert) {
			if (c.Id != null) {
				if (caseWrapperMap.containsKey(c.Integration_Key__c)) {
					HIFulfillmentAddToBasicPacific.CaseDataWrapper wrapper = caseWrapperMap.get(c.Integration_Key__c);
					if (wrapper.piiInformation != null && wrapper.piiInformation != '') {
						Attachment atch = new Attachment();
						atch.ParentId = c.Id;
						atch.Body = EncryptionUtils.getEncryptedBlob(encryptionKey, wrapper.piiInformation);
						atch.Name = 'encFile.txt';
						attachmentList.add(atch);
					}
				}
			}
		}
		if (attachmentList.size() > 0) {
			insert attachmentList;
		}
	}

	// this method is setting up the related Contact records info based on related "zp Company Id"
	public static void processContactInformation(
		List<HI_Fulfillment_Event__c> fulfillmentList,
		map<string, HIFulfillmentAddToBasicPacificJSON> evenIdInfoMap,
		map<String, Account> accountMap,
		map<String, Contact> contactMap
	) {
		List<Contact> contactListForInsert = new List<Contact>();
		for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
			if (hiFulfill.Processing_State__c == IntegrationUtils.DEAD_STATE || hiFulfill.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			HIFulfillmentAddToBasicPacificJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
			if (!accountMap.containsKey('' + hiEventInfo.employee.company_id)) {
				HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Company does not exist.', hiFulfill);
				continue;
			}

			if (!contactMap.containsKey(hiEventInfo.employee.company_id + '-' + hiEventInfo.employee.email) && !contactMap.containsKey(hiEventInfo.employee.email)) {
				Contact c = new Contact();
				c.AccountId = accountMap.get('' + hiEventInfo.employee.company_id).Id;
				c.FirstName = hiEventInfo.employee.first_Name;
				c.LastName = hiEventInfo.employee.last_name;
				c.Email = hiEventInfo.employee.email;
				c.RecordTypeId = Cache.getRecordTypeId('Contact', 'Company');
				contactListForInsert.add(c);
			}
		}
		if (contactListForInsert.size() > 0) {
			Map<String, String> dmlContactInsertErrorsMap = new Map<String, String>();
			List<Database.SaveResult> saveResult = database.insert(contactListForInsert, false);
			dmlContactInsertErrorsMap = Utils.processSaveResult(saveResult, contactListForInsert, 'email', true, 'HIFulfillmentAddToBasicPacific-processContactInformation');
			for (HI_Fulfillment_Event__c hiFulfill : fulfillmentList) {
				HIFulfillmentAddToBasicPacificJSON hiEventInfo = evenIdInfoMap.get(hiFulfill.Id__c);
				if (dmlContactInsertErrorsMap.containsKey(hiEventInfo.employee.email)) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, dmlContactInsertErrorsMap.get(hiEventInfo.employee.email), hiFulfill);
					continue;
				}
			}
		}
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Fetch existing contact with respect to Email & Employee Id
	 * @Parm        : Set of String contains email & employee id
	 * @Return      : Map of <String, Contact>
	 **/
	public static Map<String, Contact> getContactWithEmailAndEmployeeId(Set<String> set_SearchKey) {
		Map<String, Contact> map_Contacts = new Map<String, Contact>();
		for (Contact objContact : [
			SELECT Id, Name, Email, Unique_Email_Address_Contact__c, Employee_Id__c, AccountId, Account.ZP_Company_ID__c
			FROM Contact
			WHERE Email IN :set_SearchKey OR Unique_Email_Address_Contact__c IN :set_SearchKey OR Employee_Id__c IN :set_SearchKey
		]) {
			if (String.isNotBlank(objContact.Email)) {
				map_Contacts.put('' + objContact.Email, objContact);
			}

			if (String.isNotBlank(objContact.Unique_Email_Address_Contact__c)) {
				map_Contacts.put('' + objContact.Unique_Email_Address_Contact__c, objContact);
			}

			if (objContact.AccountId != null && String.isNotBlank(objContact.Account.ZP_Company_ID__c) && String.isNotBlank(objContact.Employee_Id__c)) {
				map_Contacts.put(objContact.Account.ZP_Company_ID__c + '-' + objContact.Employee_Id__c, objContact);
			}
		}

		return map_Contacts;
	}
}