/**
 * @name         TaxResAccountSpecialistViewCmpCtrl
 * @author       Anand Singh
 * @Date         2nd August 2021
 * @Description  This class handles the Account Specialist View
 * @Test class   TaxResAccountSpecialistViewCmpCtrlTest.cls
 **/
public with sharing class TaxResAccountSpecialistViewCmpCtrl {
	public static final Id LOGGED_IN_USER = UserInfo.getUserId();
	public static final Set<String> set_ExcludedCase = new Set<String>{ CaseUtils.STATUS_CLOSED, CaseUtils.STATUS_SOLVED };
	public static final String CASE_RECORD_TYPE_ID = CaseUtils.RECTYPE_TAXRES;
	public static final String CASE_TAX_RES_READ_ONLY_RT_ID = CaseUtils.RECTYPE_TAXRES_READ_ONLY;
	public static final String CASE_STATUS_RESEARCH_IN_PROGRESS = CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS;
	public static final String TAX_RES_ACCOUNT_SPECIALIST = 'Account Specialist';
	public static final Set<String> set_TaxResSkillTypes = new Set<String>{ 'Overview', 'OOO' };
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_AccountSpecialistQueries = getQueryConfigurationRecords();
	public static final String SORT_BY_CASE_NUMBER = 'CaseNumberURL';
	public static final String SORT_BY_ACCOUNT_NAME = 'AccountName';
	public static final String SORT_BY_AGENCY_INFORMATION = 'AgencyInformation';
	public static final String SORT_BY_TAX_NOTICE_FORM_NUMBER = 'TaxNoticeFormNumber';
	public static final String SORT_BY_TAX_NOTICE_TYPE = 'TaxNoticeType';
	public static final String SORT_BY_AGE = 'Age';
	public static final String SORT_BY_CASE_STATUS = 'CaseStatus';
	public static final String SORT_BY_EMAIL_STATUS = 'EmailStatus';
	public static final String SORT_BY_PARTNER_TIER = 'PartnerTier';
	public static final String SORT_BY_CUSTOMER_TIER = 'CustomerTier';
	public static final String SORT_BY_FOLLOWUP_DATE = 'FollowUpdate';

	public static final String QUERY_AS_MAIN = 'Account_Specialist_Overview_Main';
	public static final String QUERY_AS_ACTION_REQUIRED_NEW_CASES = 'Account_Specialist_Overview_New_Case';
	public static final String QUERY_AS_ACTION_REQUIRED_INPROGRESS_CASES = 'Account_Specialist_Overview_In_Progress';
	public static final String QUERY_AS_SHELVED_CASES = 'Account_Specialist_Overview_ShelvedCases';

	public static final String CASE_FIELDS_STATUS = 'Status';
	public static final String CASE_FIELDS_SHELVED_REASON = 'Shelved_Reason__c';

	/**
	 * @Author      : Anand Singh
	 * @Description : Get Custom Setting value To use in JS
	 * @Parm        : NA.
	 * @Return      : User_Role__c object
	 **/
	@AuraEnabled(cacheable=true)
	public static Configuration_Settings__c getCustomSettings() {
		return Configuration_Settings__c.getOrgDefaults();
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Get User role data from User_Role__c object of logged in user
	 * @Parm        : NA.
	 * @Return      : User_Role__c object
	 **/
	@AuraEnabled
	public static User_Role__c retrieveUserRoleData() {
		try {
			List<User_Role__c> list_ObjUserRoles = [
				SELECT Id, User_Skill_Team__c, POD_Captain__c, User__c, User__r.Out_Of_Office__c
				FROM User_Role__c
				WHERE User__c = :LOGGED_IN_USER AND User_Skill_Team__c = :TAX_RES_ACCOUNT_SPECIALIST
				LIMIT 1
			];
			if (list_ObjUserRoles.size() > 0) {
				return list_ObjUserRoles[0];
			}
		} catch (Exception objException) {
			User_Role__c objUserRole = new User_Role__c();
			objUserRole.BT_Notes__c = objException.getMessage();
			return objUserRole;
		}

		return null;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Common Method to get AS View
	 * @Parm        : String sortBy, String SortDirectionm, String strDataToShow
	 * @Return      : List of Case Wrapper
	 **/
	@AuraEnabled
	public static List<CaseWrapper> getAccountSpecialistCases(Integer intLimitSize, Integer intOffset, String strSortBy, String strSortDirection, String strDataToShow) {
		List<CaseWrapper> list_CaseWrappers = new List<CaseWrapper>();
		String strFieldSortBy = sortingBy(strSortBy);

		try {
			if (map_AccountSpecialistQueries?.size() > 0) {
				Tax_Res_Play_Mode_Configuration__mdt objPlayModeMainQuery = new Tax_Res_Play_Mode_Configuration__mdt();
				if (map_AccountSpecialistQueries.containsKey(QUERY_AS_MAIN)) {
					objPlayModeMainQuery = map_AccountSpecialistQueries.get(QUERY_AS_MAIN);
					String strQuery = objPlayModeMainQuery.Filter_Value__c;

					Tax_Res_Play_Mode_Configuration__mdt objPlayModeWhereClause = new Tax_Res_Play_Mode_Configuration__mdt();
					objPlayModeWhereClause = map_AccountSpecialistQueries.get(strDataToShow);

					if (objPlayModeWhereClause != null) {
						strQuery = strQuery + ' AND ' + objPlayModeWhereClause.Filter_Value__c;
					}

					if (String.isNotBlank(strSortBy) && String.isNotBlank(strSortDirection)) {
						if (strDataToShow != QUERY_AS_ACTION_REQUIRED_NEW_CASES && strFieldSortBy == CASE_FIELDS_STATUS) {
							strQuery = strQuery + ' ORDER BY ' + CASE_FIELDS_STATUS + ' ' + strSortDirection + ', ' + CASE_FIELDS_SHELVED_REASON + ' ' + strSortDirection;
						} else {
							strQuery = strQuery + ' ORDER BY ' + strFieldSortBy + ' ' + strSortDirection;
						}
					} else {
						strQuery = strQuery + ' ' + objPlayModeWhereClause.Order_by_records__c;
					}
					strQuery = strQuery + ' LIMIT ' + intLimitSize + ' OFFSET ' + intOffset;

					List<Case> list_Cases = Database.query(strQuery);
					if (list_Cases?.size() > 0) {
						for (Case objCase : list_Cases) {
							CaseWrapper objWrap = new CaseWrapper();
							objWrap.objCase = objCase;
							list_CaseWrappers.add(objWrap);
						}
					}
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('TaxResAccountSpecialistViewCmpCtrl', 'getAccountSpecialistCases', objException.getMessage(), 'High');
		}
		return list_CaseWrappers;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Common Method to get Sort Query data by passing the Wrapper and get actual query name
	 * @Parm        : String strSortByTemp (Wrapper Column name)
	 * @Return      : String (Object field name)
	 **/
	public static String sortingBy(String strSortByTemp) {
		String strSortingBy = strSortByTemp;
		if (strSortByTemp == SORT_BY_CASE_NUMBER) {
			strSortingBy = 'CaseNumber';
		} else if (strSortByTemp == SORT_BY_ACCOUNT_NAME) {
			strSortingBy = 'Account.Name';
		} else if (strSortByTemp == SORT_BY_EMAIL_STATUS) {
			strSortingBy = 'Email_Status__c';
		} else if (strSortByTemp == SORT_BY_AGENCY_INFORMATION) {
			strSortingBy = 'Agency_Information__r.Name';
		} else if (strSortByTemp == SORT_BY_TAX_NOTICE_FORM_NUMBER) {
			strSortingBy = 'Tax_Notice_Form_Number__c';
		} else if (strSortByTemp == SORT_BY_TAX_NOTICE_TYPE) {
			strSortingBy = 'Notice_Type__c';
		} else if (strSortByTemp == SORT_BY_AGE) {
			strSortingBy = 'Age__c';
		} else if (strSortByTemp == SORT_BY_CASE_STATUS) {
			strSortingBy = 'Status';
		} else if (strSortByTemp == SORT_BY_PARTNER_TIER) {
			strSortingBy = 'Account.AM_Tier__c';
		} else if (strSortByTemp == SORT_BY_CUSTOMER_TIER) {
			strSortingBy = 'Account.Tier__c';
		} else if (strSortByTemp == SORT_BY_FOLLOWUP_DATE) {
			strSortingBy = 'Follow_Up_Date__c';
		}
		return strSortingBy;
	}

	/*
	 * @name         CaseWrapper
	 * @author       Anand Singh
	 * @Description  This class handles the AS view Display
	 */
	public class CaseWrapper {
		@AuraEnabled
		public Case objCase;

		@AuraEnabled
		public Boolean blnSelected;
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Get Account Specialist over view and from metadata
	 * @Parm        : NA
	 * @Return      : Map of Queries
	 **/
	public static Map<String, Tax_Res_Play_Mode_Configuration__mdt> getQueryConfigurationRecords() {
		Map<String, Tax_Res_Play_Mode_Configuration__mdt> map_CoordinatorQueriesTemp = new Map<String, Tax_Res_Play_Mode_Configuration__mdt>();
		for (Tax_Res_Play_Mode_Configuration__mdt objMetadata : [
			SELECT Id, DeveloperName, Filter_Type__c, Skill_Type__c, Priority__c, Play_Type__c, Order_by_records__c, Filter_Value__c
			FROM Tax_Res_Play_Mode_Configuration__mdt
			WHERE Team__c = :TAX_RES_ACCOUNT_SPECIALIST AND Skill_Type__c IN :set_TaxResSkillTypes AND Active__c = TRUE
		]) {
			map_CoordinatorQueriesTemp.put(objMetadata.DeveloperName, objMetadata);
		}

		return map_CoordinatorQueriesTemp;
	}
}