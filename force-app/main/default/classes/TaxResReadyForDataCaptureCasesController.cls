/**
 * @name         TaxResReadyForDataCaptureCasesController
 * @author       Pravesh Rana
 * @date         05/30/2022
 * @description  Used by LWC component "TaxResReadyForDataCaptureCases"
 * 				Test Class - TaxResReadyForDataCaptureCasesCtrlTest
 **/
public with sharing class TaxResReadyForDataCaptureCasesController {
	public static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	public static final String CASE_STATUS_DATACAPTUREINPROGRESS = 'Data Capture in Progress';
	static final String IS_OCR_PROCESSED = 'IsOCRProcessed';
	static final String ACCOUNT_NAME = 'accountName';
	static final String ACCOUNT_INFO = 'agencyInfo';
	static final String SEGMENT = 'segment';
	static final String TIER = 'tier';
	static final String AGE = 'age';
	static final String STATUS = 'status';
	static final String CASE_OWNER = 'caseOwner';
	static final String CUSTOM_PERMISSIONSET_NOTICE_INDEX = 'Tax_Resolution_Notice_Index_Visibility_IC';
	static final String USER_OWNER_TYPE = 'User';
	static final String QUEUE_OWNER_TYPE = 'Queue';
	public static final String TAXRESDATACAPTURE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('TaxRes_Data_Capture_Queue');
	public static final Id RECTYPE_TAXRES = Cache.getRecordTypeId('Case', 'Tax Res');
	static Set<String> set_NoticeIndexerIds = getUsersWithCustomPermission();
	public static final String AUTO_INDEX_STATUS = 'autoIndexStatus';
	public static final String PARTIALLY_INDEXED = 'partialAutoIndexed';

	/**
	 * @Author      : Anand Singh
	 * @Description : Get Cases to display on the table
	 * @Parm        : Multiple table parameter.
	 * @Return      : List<Case> cases.
	 **/
	@AuraEnabled
	public static List<Case> getCases(
		Integer intLimitSize,
		Integer intOffset,
		String strOrderBy,
		String strOrderDirection,
		String strTierFilter,
		String strPartnerTierFilter,
		Integer intStartAge,
		Integer intEndAge,
		Date dtStartDueDate,
		Date dtEndDueDate,
		String strTaxNoticeType,
		String strOwnerId,
		String strSegment,
		Boolean blnIsOCR
	) {
		try {
			if (String.isBlank(strOrderBy) || String.isBlank(strOrderDirection)) {
				return null;
			}

			Set<String> set_Tiers = new Set<String>();
			Set<String> set_PartnerTiers = new Set<String>();
			Set<String> set_NoticeType = new Set<String>();
			List<String> list_Status = new List<String>{ CASE_STATUS_READYFORDATACAPTURE, CASE_STATUS_DATACAPTUREINPROGRESS };
			
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
			} else if (strOrderBy == CASE_OWNER) {
				strOrderBy = 'Owner.Name';
			} else if (strOrderBy == STATUS) {
				strOrderBy = 'Status';
			} else if (strOrderBy == AUTO_INDEX_STATUS || strOrderBy == PARTIALLY_INDEXED) {
				strOrderBy = 'Auto_Indexing_Status__c';
			}

			String strQuery =
				'SELECT Id, OwnerId,Owner.Name, Status, Is_OCR_Processed__c, CaseNumber, AccountId, Account.Tier__c, Account.RecordType.Name, Account.Name, Age__c, ' +
				' Agency_Information__c, Agency_Information__r.Name, Account.Partner_Segment__c, CreatedDate, Auto_Indexing_Status__c FROM Case';
				
			String strOrderClause = ' ORDER BY ' + strOrderBy + ' ' + strOrderDirection + ' NULLS LAST ' + ' LIMIT :intLimitSize OFFSET :intOffset';
			String strWhereClause = ' WHERE Status IN :list_Status AND RecordTypeId = :RECTYPE_TAXRES ';
			String strTierClause = '';
			String strStartDateClause = '';
			String strEndDateClause = '';
			Boolean blnHasFilter = false;

			if (blnIsOCR != null) {
				strWhereClause += ' AND Agency_Information__r.OCR_Enabled__c = :blnIsOCR ';
			}

			if (String.isNotBlank(strTierFilter)) {
				set_Tiers.addAll(strTierFilter.split(','));
				strWhereClause += ' AND Account.Tier__c IN :set_Tiers ';
			}

			if (String.isNotBlank(strPartnerTierFilter)) {
				set_PartnerTiers.addAll(strPartnerTierFilter.split(','));
				strWhereClause += ' AND Account.AM_Tier__c IN :set_PartnerTiers ';
			}

			if (String.isNotBlank(strTaxNoticeType)) {
				set_NoticeType.addAll(strTaxNoticeType.split(','));
				strWhereClause += ' AND Notice_Type__c IN :set_NoticeType ';
			}

			if (intStartAge != null && intStartAge > 0) {
				strWhereClause += ' AND Age__c >= :intStartAge ';
			}

			if (intEndAge != null && intEndAge > 0) {
				strWhereClause += ' AND Age__c <= :intEndAge ';
			}

			if (dtStartDueDate != null) {
				strWhereClause += ' AND Payment_Due_Date__c >= :dtStartDueDate ';
			}

			if (dtEndDueDate != null) {
				strWhereClause += ' AND Payment_Due_Date__c <= :dtEndDueDate ';
			}

			if (String.isBlank(strOwnerId)) {
				strWhereClause += ' AND (Owner.Type=:USER_OWNER_TYPE OR (Owner.Type=:QUEUE_OWNER_TYPE AND OwnerId=:TAXRESDATACAPTURE_QUEUE_ID))';
			} else if (String.isNotBlank(strOwnerId)) {
				strWhereClause += ' AND OwnerId = :strOwnerId ';
			}

			if (String.isNotBlank(strSegment) && !strSegment.equalsIgnoreCase('ALL')) {
				strWhereClause += ' AND Account.RecordType.Name = :strSegment ';
			}

			strQuery = strQuery + strWhereClause + strOrderClause;

			return Database.query(strQuery);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Update Case Owner after selection from data table
	 * @Parm        : List of Cased ids and Owner id
	 * @Return      : String message as confirmation
	 **/
	@AuraEnabled
	public static string updateCaseOwner(List<String> list_CaseIds, String strCaseOwner) {
		String strReturnMessage = null;
		try {
			if (set_NoticeIndexerIds.contains(strCaseOwner) || Test.isRunningTest()) {
				List<Case> list_CaseUpdates = new List<Case>();
				if (list_CaseIds?.size() > 0 && String.isNotBlank(strCaseOwner)) {
					for (String str : list_CaseIds) {
						Case objCase = new Case(Id = str);
						objCase.OwnerId = strCaseOwner;
						list_CaseUpdates.add(objCase);
					}
				}

				if (list_CaseUpdates?.size() > 0) {
					CaseTriggerHelper.skipTrigger = true;
					update list_CaseUpdates;
					strReturnMessage = 'success';
				}
			} else {
				strReturnMessage = 'invaliduser';
			}
		} catch (Exception objException) {
			strReturnMessage = objException.getMessage();
		}
		return strReturnMessage;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Check user has Notice Index permison or not
	 * @Parm        : String CaseOwner
	 * @Return      : Set of user who has permission
	 **/
	public static Set<String> getUsersWithCustomPermission() {
		Set<Id> set_PermissionSetIds = new Set<Id>();
		Set<String> set_NoticeIndexerIdsTemp = new Set<String>();

		for (SetupEntityAccess objAccess : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName = :CUSTOM_PERMISSIONSET_NOTICE_INDEX)]) {
			set_PermissionSetIds.add(objAccess.ParentId);
		}

		if (set_PermissionSetIds.size() > 0) {
			// We are looking for users with any permission set that has the custom permission passed in the method.
			for (User objUser : [SELECT Id FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN :set_PermissionSetIds)]) {
				set_NoticeIndexerIdsTemp.add(objUser.Id);
			}
		}
		return set_NoticeIndexerIdsTemp;
	}
}