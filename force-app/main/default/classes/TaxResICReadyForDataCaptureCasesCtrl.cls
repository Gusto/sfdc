public with sharing class TaxResICReadyForDataCaptureCasesCtrl {
	public static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	public static final String CASE_STATUS_DATA_CAPTURE_IN_PROGRESS = 'Data Capture in Progress';
	static final String IS_OCR_PROCESSED = 'IsOCRProcessed';
	static final String ACCOUNT_NAME = 'accountName';
	static final String ACCOUNT_INFO = 'agencyInfo';
	static final String SEGMENT = 'segment';
	static final String TIER = 'tier';
	static final String AGE = 'age';
	static final String STATUS = 'Status';
	static final Id idLoggedInUser = UserInfo.getUserId();
	public static final Id RECTYPE_TAXRES = Cache.getRecordTypeId('Case', 'Tax Res');
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');
	public static final String FULLY_INDEXED = 'Fully Indexed';
	public static final String AUTO_INDEX_STATUS = 'autoIndexStatus';
	public static final String PARTIALLY_INDEXED = 'partialAutoIndexed';

	@AuraEnabled
	public static List<Case> getCases(Integer intLimitSize, Integer intOffset, String strOrderBy, String strOrderDirection, Boolean blnIsMyCases, Boolean blnIsIDP, String strSelectedIndexing) {
		try {
			List<String> list_EligibleCaseStatus = new List<String>();
			list_EligibleCaseStatus.add(CASE_STATUS_READYFORDATACAPTURE);

			if (String.isBlank(strOrderBy) || String.isBlank(strOrderDirection)) {
				return null;
			}
			
			if (strOrderBy == ACCOUNT_NAME) {
				strOrderBy = 'Account.Name';
			} else if (strOrderBy == ACCOUNT_INFO) {
				strOrderBy = 'Agency_Information__r.Name';
			} else if (strOrderBy == SEGMENT) {
				strOrderBy = 'Account.RecordType.Name';
			} else if (strOrderBy == TIER) {
				strOrderBy = 'Account.Tier__c';
			} else if (strOrderBy == AGE) {
				strOrderBy = 'Age__c';
			} else if (strOrderBy == STATUS) {
				strOrderBy = 'Status';
			} else if (strOrderBy == AUTO_INDEX_STATUS || strOrderBy == PARTIALLY_INDEXED) {
				strOrderBy = 'Auto_Indexing_Status__c';
			}

			String strQuery =
				'SELECT Id, Status, Is_OCR_Processed__c, CaseNumber, AccountId, Account.RecordType.Name, Account.Tier__c, Account.Name, Age__c, ' +
				' Agency_Information__c, Agency_Information__r.Name, Account.Partner_Segment__c, CreatedDate, Auto_Indexing_Status__c FROM Case';


			String strOrderClause = ' ORDER BY ' + strOrderBy + ' ' + strOrderDirection + ' NULLS LAST ' + ' LIMIT ' + intLimitSize + ' OFFSET ' + intOffset;
			String strWhereClause = ' WHERE Status IN :list_EligibleCaseStatus AND RecordTypeId = :RECTYPE_TAXRES';
			
			if (blnIsIDP) {
				strWhereClause += ' AND Agency_Information__r.OCR_Enabled__c = true'; //Added condition for IDP Agencies only
			} else {
				strWhereClause += ' AND Agency_Information__r.OCR_Enabled__c = false'; ////Added condition for Non IDP Agencies only
			}

			if (strSelectedIndexing != null && strSelectedIndexing != 'All') {
				strWhereClause += ' AND Auto_Indexing_Status__c = :strSelectedIndexing';
			}

			if (blnIsMyCases) {
				strWhereClause += ' AND OwnerId = :idLoggedInUser ';
				list_EligibleCaseStatus.add(CASE_STATUS_DATA_CAPTURE_IN_PROGRESS);
			} else {
				strWhereClause += ' AND OwnerId = \'' + TAXRESDATACAPTURE_QUEUE_ID + '\'';
			}

			strQuery = strQuery + strWhereClause + strOrderClause;
			return Database.query(strQuery);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Take it case from queue to individual
	 * @Parm        : String [case id]
	 * @Return      : String [result/error/exception information]
	 **/
	@AuraEnabled
	public static String takeItCase(String strCaseId) {
		String strReturnMessage = null;
		try {
			if (String.isNotBlank(strCaseId)) {
				//get case Status before updating
				List<Case> list_Cases = [SELECT Id, Status FROM Case WHERE Id = :strCaseId AND Status = :CASE_STATUS_READYFORDATACAPTURE FOR UPDATE];

				if (list_Cases?.size() > 0) {
					Case objCase = new Case(Id = list_Cases.get(0).Id, OwnerId = UserInfo.getUserId(), Status = CASE_STATUS_DATA_CAPTURE_IN_PROGRESS);
					CaseTriggerHelper.skipTrigger = true;
					update objCase;

					List<Case> list_TempCases = [
						SELECT Id, Email_Status__c, Status, RecordTypeId, OwnerId, Account_Specialist__c
						FROM Case
						WHERE Id = :list_Cases.get(0).Id
					];
					CaseTriggerHelper.createTaxResAuditLogs(list_TempCases, CaseUtils.STATUS_CHANGE, false, false);
					strReturnMessage = 'success';
				} else {
					strReturnMessage = 'alreadytaken';
				}
			}
		} catch (Exception objException) {
			strReturnMessage = objException.getMessage();
		}
		return strReturnMessage;
	}
}