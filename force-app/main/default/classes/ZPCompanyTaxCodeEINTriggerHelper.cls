public with sharing class ZPCompanyTaxCodeEINTriggerHelper {
	private Boolean m_isExecuting = false;
	private Integer BatchSize = 0;

	public ZPCompanyTaxCodeEINTriggerHelper(boolean isExecuting, integer size) {
		m_isExecuting = isExecuting;
		BatchSize = size;
	}

	public void OnBeforeInsert(ZP_Company_Tax_Code_EIN__c[] newRecords) {
		for (ZP_Company_Tax_Code_EIN__c einRec : newRecords) {
			if (string.isNotBlank(einRec.Fein__c)) {
				einRec.Fein__c = replaceSpecialCharacters(einRec.Fein__c);
			}

			if (string.isNotBlank(einRec.Account_Number__c)) {
				einRec.Account_Number__c = replaceSpecialCharacters(einRec.Account_Number__c);
			}

			if (string.isNotBlank(einRec.Reference_Ein__c)) {
				einRec.Reference_Ein__c = replaceSpecialCharacters(einRec.Reference_Ein__c);
			}
		}

		//BY:PR, Date: July/8/2020, Desc: to populate Account lookup using zp company id field value
		populateRelatedCompany(newRecords);
	}

	public void OnBeforeUpdate(Map<ID, ZP_Company_Tax_Code_EIN__c> oldMap, ZP_Company_Tax_Code_EIN__c[] updatedRecords, Map<ID, ZP_Company_Tax_Code_EIN__c> recordMap) {
		for (ZP_Company_Tax_Code_EIN__c einRec : updatedRecords) {
			ZP_Company_Tax_Code_EIN__c oldRec = oldMap.get(einRec.id);
			if (string.isNotBlank(einRec.Fein__c) && oldRec.Fein__c != einRec.Fein__c) {
				einRec.Fein__c = replaceSpecialCharacters(einRec.Fein__c);
			}

			if (string.isNotBlank(einRec.Account_Number__c) && oldRec.Account_Number__c != einRec.Account_Number__c) {
				einRec.Account_Number__c = replaceSpecialCharacters(einRec.Account_Number__c);
			}

			if (string.isNotBlank(einRec.Reference_Ein__c) && oldRec.Reference_Ein__c != einRec.Reference_Ein__c) {
				einRec.Reference_Ein__c = replaceSpecialCharacters(einRec.Reference_Ein__c);
			}
		}
		//BY:PR, Date: July/8/2020, Desc: to populate Account lookup if empty
		populateRelatedCompany(updatedRecords);
	}

	public boolean IsTriggerContext {
		get {
			return m_isExecuting;
		}
	}

	public boolean IsVisualforcePageContext {
		get {
			return !IsTriggerContext;
		}
	}

	public boolean IsWebServiceContext {
		get {
			return !IsTriggerContext;
		}
	}

	public boolean IsExecuteAnonymousContext {
		get {
			return !IsTriggerContext;
		}
	}

	public String replaceSpecialCharacters(String val) {
		String res = val.replaceAll('[^a-zA-Z0-9]', '');
		return res;
	}

	/*BY:PR, Date: July/8/2020
    Desc: To get Account information in the "CA TAX CODE EDD RESULTS" report, we are populating Account lookup based on ZP_Company_Id 
    */
	public void populateRelatedCompany(list<ZP_Company_Tax_Code_EIN__c> list_ZPCompanyDetails) {
		if (list_ZPCompanyDetails != null && list_ZPCompanyDetails.size() > 0) {
			set<string> set_ZPCompanyId = new Set<string>();
			map<string, Id> map_zpCompanyAccountId = new Map<string, Id>();
			for (ZP_Company_Tax_Code_EIN__c objEIN : list_ZPCompanyDetails) {
				if (objEIN.Company__c == null && objEIN.ZP_Company_ID__c != null) {
					map_zpCompanyAccountId.put(objEIN.ZP_Company_ID__c, null);
				}
			}

			if (map_zpCompanyAccountId.size() > 0) {
				for (Account objAcc : [SELECT Id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :map_zpCompanyAccountId.keySet()]) {
					map_zpCompanyAccountId.put(objAcc.ZP_Company_ID__c, objAcc.Id);
				}

				for (ZP_Company_Tax_Code_EIN__c objEIN : list_ZPCompanyDetails) {
					if (map_zpCompanyAccountId.containsKey(objEIN.ZP_Company_ID__c) && map_zpCompanyAccountId.get(objEIN.ZP_Company_ID__c) != null) {
						objEIN.Company__c = map_zpCompanyAccountId.get(objEIN.ZP_Company_ID__c);
					}
				}
			}
		}
	}
}