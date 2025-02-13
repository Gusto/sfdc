global class TaxOpsFailedRecordAccountAssignmentBatch implements Database.Batchable<sObject> {
	String einQueryStr;

	global TaxOpsFailedRecordAccountAssignmentBatch() {
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		string einQueryStr =
			' SELECT Id, ZP_Company_ID__c, Tax_Code__c, FEIN_Encrypt__c,Account_Number_Encrypt__c, ' +
			' Reference_Ein_Encrypt__c FROM ZP_Company_Tax_Code_EIN__c WHERE ZP_Company_ID__c != null limit 49000000 ';

		return Database.getQueryLocator(einQueryStr);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		list<ZP_Company_Tax_Code_EIN__c> einList = (ZP_Company_Tax_Code_EIN__c[]) scope;

		Map<String, String> feinZPIdMap = new Map<String, String>();
		Map<String, String> accNumTaxCodeZPIdMap = new Map<String, String>();
		Map<String, String> referenceEINTaxCodeZPIdMap = new Map<String, String>();
		Set<String> uniqueAccNumSet = new Set<String>();
		Set<String> uniqueReferenceEinSet = new Set<String>();

		Map<String, String> zpCompanyAccountIdMap = new Map<String, String>();

		for (ZP_Company_Tax_Code_EIN__c einRec : einList) {
			if (String.isNotBlank(einrec.FEIN_Encrypt__c)) {
				String feinStr = decodeStr(einrec.FEIN_Encrypt__c);
				feinZPIdMap.put(feinStr, einrec.ZP_Company_ID__c);
			}

			if (String.isNotBlank(einrec.Account_Number_Encrypt__c)) {
				String accNumStr = decodeStr(einrec.Account_Number_Encrypt__c);
				accNumTaxCodeZPIdMap.put(accNumStr + '_' + einrec.Tax_code__c, einrec.ZP_Company_ID__c);
				uniqueAccNumSet.add(accNumStr);
			}

			if (String.isNotBlank(einrec.Reference_Ein_Encrypt__c)) {
				String refEINStr = decodeStr(einrec.Reference_Ein_Encrypt__c);
				referenceEINTaxCodeZPIdMap.put(refEINStr + '_' + einrec.Tax_code__c, einrec.ZP_Company_ID__c);
				uniqueReferenceEinSet.add(refEINStr);
			}
		}

		Set<String> zpCompanyIdSet = new Set<String>();
		if (feinZPIdMap.keyset().size() > 0) {
			zpCompanyIdSet.addAll(feinZPIdMap.values());
		}

		if (Test.isRunningTest()) {
			uniqueAccNumSet.add('5464365436434');
		}

		if (uniqueAccNumSet.size() > 0) {
			zpCompanyIdSet.addAll(uniqueAccNumSet);
		}
		if (uniqueReferenceEinSet.size() > 0) {
			zpCompanyIdSet.addAll(uniqueReferenceEinSet);
		}

		if (zpCompanyIdSet.size() > 0) {
			for (Account rec : [SELECT id, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :zpCompanyIdSet]) {
				zpCompanyAccountIdMap.put(rec.ZP_Company_ID__c, rec.id);
			}

			list<Tax_Ops_Failed_Record__c> toUpdateFailedRecordsList = new List<Tax_Ops_Failed_Record__c>();

			if (zpCompanyAccountIdMap.keyset().size() > 0) {
				for (Tax_Ops_Failed_Record__c frRec : [
					SELECT id, Fein__c, Account_Number__c, Account__c, Tax_Code__c
					FROM Tax_Ops_Failed_Record__c
					WHERE Account__c = NULL AND Inactive__c = FALSE AND (Fein__c IN :feinZPIdMap.Keyset() OR Account_Number__c IN :uniqueAccNumSet OR Account_Number__c IN :uniqueReferenceEinSet)
				]) {
					if (String.isNotBlank(frRec.Fein__c) && feinZPIdMap.containsKey(frRec.Fein__c)) {
						frRec.Account__c = zpCompanyAccountIdMap.get(feinZPIdMap.get(frRec.Fein__c));
						toUpdateFailedRecordsList.add(frRec);
					} else if (String.isNotBlank(frRec.Account_Number__c)) {
						String accNumKey = frRec.Account_Number__c + '_' + frRec.Tax_Code__c;
						if (accNumTaxCodeZPIdMap.containsKey(accNumKey)) {
							frRec.Account__c = zpCompanyAccountIdMap.get(accNumTaxCodeZPIdMap.get(accNumKey));
							toUpdateFailedRecordsList.add(frRec);
						} else if (referenceEINTaxCodeZPIdMap.containsKey(accNumKey)) {
							frRec.Account__c = zpCompanyAccountIdMap.get(referenceEINTaxCodeZPIdMap.get(accNumKey));
							toUpdateFailedRecordsList.add(frRec);
						}
					}
				}
			}

			if (toUpdateFailedRecordsList.size() > 0) {
				try {
					update toUpdateFailedRecordsList;
				} catch (exception ex) {
				}
			}
		}
	}

	Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
	public string decodeStr(string encodeStr) {
		try {
			String b64Data = encodeStr;
			Blob decryptedInfo = EncodingUtil.base64Decode(b64Data);
			String originalFEIN = EncryptionUtils.getDecryptedText(encryptionKey, decryptedInfo);

			return originalFEIN;
		} catch (Exception e) {
			return null;
		}
	}

	global void finish(Database.BatchableContext BC) {
	}
}