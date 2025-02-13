/**
 * @name         TaxResSFDCSkillAssignmentWrapper
 * @author       Pravesh Rana
 * @Date         June 1 2023
 * @description  This class handles the Intelligence Routing Case assignment fuctionality for Accout Specialist
 * @test class   TaxResSFDCSkillAssignmentWrapperTest.cls
 **/
public class TaxResSFDCSkillAssignmentWrapper {
	static Map<String, String> map_Complexity = new Map<String, String>{ 'L' => 'Low', 'M' => 'Medium', 'H' => 'High' };
	static Map<String, String> map_DebitCredit = new Map<String, String>{ 'D' => 'Debit', 'C' => 'Credit', 'N' => 'No Balance Due' };
	static Map<String, String> map_Threshold = new Map<String, String>{
		'0' => '$0.00',
		'50' => '$0.00 - $50.00',
		'1500' => '$0.00 - $1500.00',
		'10000' => '$0.00 - $10,000.00',
		'10000+' => '$0.00 - $10,000.00+'
	};
	static Map<String, String> map_MultiYear = new Map<String, String>{ 'Y' => 'Yes', 'N' => 'No' };
	static String IR_REPORT_RECORD_NAME = 'IR_Assignment_Page_Report_Id';
	public static String INDENTIFIER_JOINT = '#';
	static Integer intTierAllValues = getPicklistSize('Tier__c');
	static Integer intDebitAllValues = getPicklistSize('Debit_Credit__c');
	static Integer intPartnerTierAllValues = getPicklistSize('Partner_Tier__c');

	static List<String> list_AgencyNameIds = new List<String>();
	static Map<String, Set<String>> map_TypeStateAgencyIds = new Map<String, Set<String>>();
	static Map<Id, Agency_Information__c> map_AgencyIdRecords = new Map<Id, Agency_Information__c>();

	/**
	 * @Author      : Pravesh Rana
	 * @Description : return wrapper which contains Agency_Information, User_SKill__c and User_Role__c related infor
	 * @Parm        : strResourceFilter, strAgencyFilter, strOrderBy, strOrderByDirection, intLimitSize, intOffset.
	 * @Return      : return wrapper which contains Agency_Information, User_SKill__c and User_Role__c related infor
	 **/
	@AuraEnabled
	public static OnPageLoadDataWrapperClass fetchUserSkills(
		String strResourceFilter,
		String strAgencyFilter,
		String strOrderBy,
		String strOrderByDirection,
		Integer intLimitSize,
		Integer intOffset,
		String strDebitCreditFilter,
		String strTierFilter
	) {
		Map<Id, String> map_UserIdUniqueIdentifier = new Map<Id, String>();
		List<TaxResSFDCSkillAssignmentWrapperClass> list_UserSkillWrapper = new List<TaxResSFDCSkillAssignmentWrapperClass>();
		OnPageLoadDataWrapperClass objPageLoadDataWrapper = new OnPageLoadDataWrapperClass();
		String strMainQuery = ' ';
		String strCountQuery = '';
		String strFilter = ' ';
		String strCommonFilter = '';
		Integer intEligibleCaseCount = 0;
		Set<String> set_ResourceIds = new Set<String>();
		Set<String> set_AgencyIds = new Set<String>();
		Map<String, TaxResSFDCSkillAssignmentWrapperClass> map_UserAgencyIdAggregateSkillInfo = new Map<String, TaxResSFDCSkillAssignmentWrapperClass>();
		Set<String> set_DebitCredit = new Set<String>();
		Set<String> set_Tiers = new Set<String>();
		Tax_Res_Play_Mode_Configuration__mdt objIRReportIdRecord = CaseUtils.getQueryConfigurationRecords(IR_REPORT_RECORD_NAME);

		//calling method to populate Agency_Information record details
		getAgencyInformation();

		if (strOrderBy == 'strAgentName') {
			strOrderBy = 'User_Role__r.User_Full_Name__c';
		}

		strMainQuery = 'SELECT Id,Agency_Information__c,Agency_Information__r.Name, Agency_Complexity__c,Tax_Notice_Type__c,Form_Number_Complexity__c,Debit_Credit__c,Multi_Year__c,Partner_Tier__c,Tier__c,Thresholds__c,User_Role__c,Backup_Resource__c,Backup_Resource__r.User_Full_Name__c,Backup_Resource__r.User__c,User_Role__r.User_Full_Name__c,User_Role__r.User__c,User_Skill_Hash__c, Active__c FROM User_Skill__c	';
		strCommonFilter = ' WHERE User_Skill_Hash__c != NULL AND User_Role__r.User_Skill_team__c = \'' + CaseUtils.TAXRES_ACCOUNT_SPECIALIST + '\' AND Agency_Information__c != NULL ';
		//used to get the total eligible record's count
		strCountQuery = 'SELECT Count() FROM User_Skill__c ';

		//converting page filter string into a set
		set_ResourceIds.addAll(strResourceFilter.split(','));
		set_AgencyIds.addAll(strAgencyFilter.split(','));

		if (set_AgencyIds?.size() > 0) {
			Set<String> set_AgencyIdsFilter = new Set<String>();
			Set<String> set_AgencyGroupNameToRemove = new Set<String>();
			for (String strAgency : set_AgencyIds) {
				if (map_TypeStateAgencyIds.containsKey(strAgency)) {
					set_AgencyIdsFilter.addAll(map_TypeStateAgencyIds.get(strAgency));
					set_AgencyGroupNameToRemove.add(strAgency);
				}
			}

			if (set_AgencyIdsFilter.size() > 0) {
				set_AgencyIds.addAll(set_AgencyIdsFilter);
				//remove the agency group name
				set_AgencyIds.removeAll(set_AgencyGroupNameToRemove);
			}
		}

		if (String.isNotBlank(strResourceFilter)) {
			strFilter += ' AND User_Role__r.User__c IN  :set_ResourceIds ';
		}

		if (String.isNotBlank(strAgencyFilter)) {
			strFilter += ' AND Agency_Information__c IN  :set_AgencyIds ';
		}

		if (String.isNotBlank(strDebitCreditFilter)) {
			set_DebitCredit.addAll(strDebitCreditFilter.split(','));
			strFilter += ' AND Debit_Credit__c IN :set_DebitCredit ';
		}

		if (String.isNotBlank(strTierFilter)) {
			set_Tiers.addAll(strTierFilter.split(','));
			strFilter += ' AND Tier__c IN :set_Tiers ';
		}

		intEligibleCaseCount = Database.countQuery(strCountQuery + strCommonFilter + strFilter + ' LIMIT 49999 ');

		strFilter += '  AND  Active__c = true ';

		if (String.isNotBlank(strOrderBy)) {
			strFilter += '  Order By ' + strOrderBy + ' ' + strOrderByDirection;
		}

		if (intLimitSize > 0) {
			strFilter += '  LIMIT ' + intLimitSize;
		}

		for (User_Skill__c objUserSkill : Database.query(strMainQuery + strCommonFilter + strFilter)) {
			String strUniqueKey = objUserSkill.User_Role__c + INDENTIFIER_JOINT + objUserSkill.Agency_Information__c;
			TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord = new TaxResSFDCSkillAssignmentWrapperClass();

			if (map_UserAgencyIdAggregateSkillInfo?.containsKey(strUniqueKey)) {
				objWrapperRecord = map_UserAgencyIdAggregateSkillInfo.get(strUniqueKey);
			}

			if (objWrapperRecord.strAgentName == null) {
				objWrapperRecord.strAgentName = objUserSkill.User_Role__r.User_Full_Name__c;
				objWrapperRecord.strAgentId = objUserSkill.User_Role__r.User__c;
				objWrapperRecord.strBAgentId = objUserSkill.Backup_Resource__r.User__c;
				objWrapperRecord.strAgencyName = objUserSkill.Agency_Information__r.Name;
				objWrapperRecord.strAgencyId = objUserSkill.Agency_Information__c;
				objWrapperRecord.strAgencyComplexity = map_Complexity.containsKey(objUserSkill.Agency_Complexity__c)
					? map_Complexity.get(objUserSkill.Agency_Complexity__c)
					: objUserSkill.Agency_Complexity__c;
				objWrapperRecord.strUniqueId = strUniqueKey;
				objWrapperRecord.blnIsActive = objUserSkill.Active__c;
			}

			objWrapperRecord.strBAgentName = getUniqueValues(objWrapperRecord.strBAgentName, objUserSkill.Backup_Resource__r.User_Full_Name__c, null);

			String strJoint = ' ; ';
			String strTempFNComplexity = map_Complexity?.containsKey(objUserSkill.Form_Number_Complexity__c)
				? map_Complexity.get(objUserSkill.Form_Number_Complexity__c)
				: objUserSkill.Form_Number_Complexity__c;
			String strTempDC = map_DebitCredit.containsKey(objUserSkill.Debit_Credit__c) ? map_DebitCredit.get(objUserSkill.Debit_Credit__c) : objUserSkill.Debit_Credit__c;
			String strTempThreshold = map_Threshold.containsKey(objUserSkill.Thresholds__c) ? map_Threshold.get(objUserSkill.Thresholds__c) : objUserSkill.Thresholds__c;
			String strTempTier = String.isBlank(objUserSkill.Tier__c) ? 'NA' : objUserSkill.Tier__c;
			String strTempPTier = String.isBlank(objUserSkill.Partner_Tier__c) ? 'NA' : objUserSkill.Partner_Tier__c;
			String strTempMultiYear = map_MultiYear.containsKey(objUserSkill.Multi_Year__c) ? map_MultiYear.get(objUserSkill.Multi_Year__c) : objUserSkill.Multi_Year__c;

			objWrapperRecord.strNoticeType = getUniqueValues(objWrapperRecord.strNoticeType, objUserSkill.Tax_Notice_Type__c, null);
			objWrapperRecord.strFormNumberComplexity = getUniqueValues(objWrapperRecord.strFormNumberComplexity, strTempFNComplexity, null);
			objWrapperRecord.strDebitCredit = getUniqueValues(objWrapperRecord.strDebitCredit, strTempDC, 'Debit_Credit__c');
			objWrapperRecord.strThreshold = getUniqueValues(objWrapperRecord.strThreshold, strTempThreshold, null);
			objWrapperRecord.strTier = getUniqueValues(objWrapperRecord.strTier, strTempTier, 'Tier__c');
			objWrapperRecord.strPartnerTier = getUniqueValues(objWrapperRecord.strPartnerTier, strTempPTier, 'Partner_Tier__c');
			objWrapperRecord.strMultiYear = getUniqueValues(objWrapperRecord.strMultiYear, strTempMultiYear, null);

			map_UserAgencyIdAggregateSkillInfo.put(strUniqueKey, objWrapperRecord);
			map_UserIdUniqueIdentifier.put(objUserSkill.User_Role__r.User__c, objUserSkill.User_Role__r.User_Full_Name__c + '#' + objUserSkill.User_Role__r.User__c);
		}

		for (User_Role__c objUserRole : GlobalQueryHelper.getSpecialistUserRoleMap().values()) {
			if (!map_UserIdUniqueIdentifier.containsKey(objUserRole.User__c)) {
				map_UserIdUniqueIdentifier.put(objUserRole.User__c, objUserRole.User_Full_Name__c + '#' + objUserRole.User__c);
			}
		}

		objPageLoadDataWrapper.list_UserSkillWrapper = map_UserAgencyIdAggregateSkillInfo.values();
		objPageLoadDataWrapper.list_AgencyNameAbbreviations = list_AgencyNameIds;
		objPageLoadDataWrapper.list_AgentNameId = map_UserIdUniqueIdentifier.values();
		objPageLoadDataWrapper.intTotalRecords = intEligibleCaseCount;
		objPageLoadDataWrapper.strReportId = objIRReportIdRecord?.Filter_Value__c;

		return objPageLoadDataWrapper;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : query Agency_Information records and group agencies by "Tax Type" & "State"
	 * @Parm        : N/A
	 * @Return      : N/A But populates public variables list_AgencyNameIds & map_TypeStateAgencyIds
	 **/
	static void getAgencyInformation() {
		list_AgencyNameIds = new List<String>();
		Set<String> set_Types = new Set<String>();
		Set<String> set_StateNames = new Set<String>();

		if (String.isNotBlank(Label.IR_Agency_Grouping_States)) {
			for (String strGroup : Label.IR_Agency_Grouping_States.split(';')) {
				List<String> list_TempValues = strGroup.split('-');
				set_StateNames.add(list_TempValues[0].trim());
				set_Types.add(list_TempValues[1].trim());
			}
		}

		for (Agency_Information__c objAgency : [
			SELECT Id, Name, Agency_Abbreviation__c, Agency_Complexity__c, State__c, Tax_Type__c
			FROM Agency_Information__c
			WHERE Agency_Abbreviation__c != NULL AND Active__c = TRUE
			ORDER BY Name
		]) {
			list_AgencyNameIds.add(objAgency.Name + '#' + objAgency.Id);

			if (String.isBlank(objAgency.Tax_Type__c) || String.isBlank(objAgency.State__c)) {
				continue;
			}

			if (set_StateNames.contains(objAgency.State__c) && set_Types.contains(objAgency.Tax_Type__c)) {
				Set<String> set_AgencyIds = new Set<String>();
				String strKey = objAgency.State__c + ' - ' + objAgency.Tax_Type__c;

				if (map_TypeStateAgencyIds.containsKey(strKey)) {
					set_AgencyIds = map_TypeStateAgencyIds.get(strKey);
				}

				set_AgencyIds.add(objAgency.Id);
				map_TypeStateAgencyIds.put(strKey, set_AgencyIds);
			}

			map_AgencyIdRecords.put(objAgency.Id, objAgency);
		}

		for (String strGroupName : map_TypeStateAgencyIds.keyset()) {
			if (map_TypeStateAgencyIds.get(strGroupName).size() > 1) {
				list_AgencyNameIds.add(strGroupName + '#' + strGroupName);
			}
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : group unique values of a picklist together and returns all as value if all the picklist value are present
	 * @Parm        : strCurrentVal, strNewVal, strFieldName
	 * @Return      : String [unique values]
	 **/
	static String getUniqueValues(String strCurrentVal, String strNewVal, String strFieldName) {
		String strReturnVal;
		String strJoint = ' ; ';

		if (String.isBlank(strCurrentVal)) {
			strReturnVal = strNewVal;
		} else if (String.isBlank(strNewVal) || strCurrentVal == 'All' || strCurrentVal?.split(strJoint).contains(strNewVal)) {
			strReturnVal = strCurrentVal;
		} else if (!strCurrentVal?.split(strJoint).contains(strNewVal)) {
			strReturnVal = strCurrentVal + strJoint + strNewVal;
		}

		if (String.isNotBlank(strReturnVal) && strReturnVal != 'All' && String.isNotBlank(strFieldName)) {
			List<String> list_TempList = strReturnVal?.split(strJoint);
			
			if (list_TempList.size() == 1 && list_TempList?.contains('NA')) {
				strReturnVal = 'NA';
			} else if (list_TempList.size() > 1 && list_TempList?.contains('NA')) {
				list_TempList.remove(list_TempList.indexOf('NA'));
				strReturnVal = String.join(list_TempList, strJoint);
			}
			
			if (strFieldName == 'Tier__c' && list_TempList.size() == intTierAllValues - 1) {
				strReturnVal = 'All';
			} else if (strFieldName == 'Partner_Tier__c' && list_TempList.size() == intPartnerTierAllValues - 1) {
				strReturnVal = 'All';
			} else if (strFieldName == 'Debit_Credit__c' && list_TempList.size() == intDebitAllValues) {
				strReturnVal = 'All';
			}
		}

		return strReturnVal;
	}

	static Integer getPicklistSize(String strFieldName) {
		integer intPicklistSize = 0;

		if (String.isNotBlank(strFieldName)) {
			List<System.SelectOption> list_TempValues = Cache.getFieldPickListValues('User_Skill__c', strFieldName);
			intPicklistSize = list_TempValues.size();
		}

		return intPicklistSize;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : handle logic to get all the skills for a user + agency combination. This method either returns all the
	 * 					user skill records separately or based in user + agency + multi year grouping
	 * 					based on "strType" variable
	 * @Parm        : strUniqueIndetifier, strType
	 * @Return      : list<TaxResSFDCSkillAssignmentWrapperClass>
	 **/
	@AuraEnabled
	public static list<TaxResSFDCSkillAssignmentWrapperClass> getAllSkillsForUserRoleAgency(String strUniqueIndetifier, String strType) {
		List<String> list_UserRoleAgency = strUniqueIndetifier.split(INDENTIFIER_JOINT);
		String strUserRoleId = list_UserRoleAgency.get(0);
		String strAgencyId = list_UserRoleAgency.get(1);
		String strMultiYrTier = '';
		String strMultiYrPartnerTier = '';
		List<TaxResSFDCSkillAssignmentWrapperClass> list_UserSkillWrapper = new List<TaxResSFDCSkillAssignmentWrapperClass>();
		Map<String, TaxResSFDCSkillAssignmentWrapperClass> map_UserSkillWrapper = new Map<String, TaxResSFDCSkillAssignmentWrapperClass>();

		for (User_Skill__c objUserSkill : [
			SELECT
				Id,
				Agency_Information__c,
				Agency_Information__r.Name,
				Agency_Complexity__c,
				Tax_Notice_Type__c,
				Form_Number_Complexity__c,
				Debit_Credit__c,
				Multi_Year__c,
				Partner_Tier__c,
				Tier__c,
				Thresholds__c,
				User_Role__c,
				Backup_Resource__c,
				User_Role__r.User_Full_Name__c,
				Backup_Resource__r.User_Full_Name__c,
				Backup_Resource__r.User__c,
				User_Role__r.User__c,
				User_Skill_Hash__c,
				Active__c
			FROM User_Skill__c
			WHERE User_Role__c = :strUserRoleId AND Agency_Information__c = :strAgencyId
		]) {
			if (String.isBlank(strType)) {
				TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord = new TaxResSFDCSkillAssignmentWrapperClass();
				objWrapperRecord.strAgentName = objUserSkill.User_Role__r.User_Full_Name__c;
				objWrapperRecord.strBAgentName = objUserSkill.Backup_Resource__r.User_Full_Name__c;
				objWrapperRecord.strAgencyName = objUserSkill.Agency_Information__r.Name;
				objWrapperRecord.strAgencyComplexity = map_Complexity.containsKey(objUserSkill.Agency_Complexity__c)
					? map_Complexity.get(objUserSkill.Agency_Complexity__c)
					: objUserSkill.Agency_Complexity__c;
				objWrapperRecord.strNoticeType = objUserSkill.Tax_Notice_Type__c;
				objWrapperRecord.strFormNumberComplexity = map_Complexity.containsKey(objUserSkill.Form_Number_Complexity__c)
					? map_Complexity.get(objUserSkill.Form_Number_Complexity__c)
					: objUserSkill.Form_Number_Complexity__c;
				objWrapperRecord.strDebitCredit = map_DebitCredit.containsKey(objUserSkill.Debit_Credit__c) ? map_DebitCredit.get(objUserSkill.Debit_Credit__c) : objUserSkill.Debit_Credit__c;
				objWrapperRecord.strThreshold = map_Threshold.containsKey(objUserSkill.Thresholds__c) ? map_Threshold.get(objUserSkill.Thresholds__c) : objUserSkill.Thresholds__c;
				objWrapperRecord.strTier = String.isBlank(objUserSkill.Tier__c) ? 'NA' : objUserSkill.Tier__c;
				objWrapperRecord.strPartnerTier = String.isBlank(objUserSkill.Partner_Tier__c) ? 'NA' : objUserSkill.Partner_Tier__c;
				objWrapperRecord.strMultiYear = map_MultiYear.containsKey(objUserSkill.Multi_Year__c) ? map_MultiYear.get(objUserSkill.Multi_Year__c) : objUserSkill.Multi_Year__c;
				objWrapperRecord.strUniqueId = objUserSkill.Id;
				objWrapperRecord.blnIsActive = objUserSkill.Active__c;
				list_UserSkillWrapper.add(objWrapperRecord);
			} else {
				if (!objUserSkill.Active__c) {
					continue;
				}

				strMultiYrTier = objUserSkill.Multi_Year__c+'#Tier';
				strMultiYrPartnerTier = objUserSkill.Multi_Year__c+'#PartnerTier';

				TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord = new TaxResSFDCSkillAssignmentWrapperClass();
				if ((objUserSkill.Partner_Tier__c == null || objUserSkill.Partner_Tier__c == 'NA') && map_UserSkillWrapper.containsKey(strMultiYrTier)) {
					objWrapperRecord = map_UserSkillWrapper.get(strMultiYrTier);
				} else if ((objUserSkill.Tier__c == null || objUserSkill.Tier__c == 'NA') && map_UserSkillWrapper.containsKey(strMultiYrPartnerTier)) {
					objWrapperRecord = map_UserSkillWrapper.get(strMultiYrPartnerTier);
				}

				objWrapperRecord.strAgentName = objUserSkill.User_Role__r.User__c;
				objWrapperRecord.strBAgentName = objUserSkill.Backup_Resource__r.User__c;
				objWrapperRecord.strAgencyName = objUserSkill.Agency_Information__c;
				objWrapperRecord.strAgencyComplexity = objUserSkill.Agency_Complexity__c;
				objWrapperRecord.strMultiYear = objUserSkill.Multi_Year__c;
				objWrapperRecord.strUniqueId = objUserSkill.Id;
				objWrapperRecord.blnIsActive = objUserSkill.Active__c;
				objWrapperRecord.strThreshold = objUserSkill.Thresholds__c;

				if (String.isNotBlank(objWrapperRecord.strNoticeType)) {
					if (objWrapperRecord.strNoticeType.indexOf(objUserSkill.Tax_Notice_Type__c) == -1) {
						objWrapperRecord.strNoticeType = objWrapperRecord.strNoticeType + ',' + objUserSkill.Tax_Notice_Type__c;
					}
				} else {
					objWrapperRecord.strNoticeType = objUserSkill.Tax_Notice_Type__c;
				}

				if (String.isNotBlank(objWrapperRecord.strFormNumberComplexity)) {
					if (objWrapperRecord.strFormNumberComplexity.indexOf(objUserSkill.Form_Number_Complexity__c) == -1) {
						objWrapperRecord.strFormNumberComplexity = objWrapperRecord.strFormNumberComplexity + ',' + objUserSkill.Form_Number_Complexity__c;
					}
				} else {
					objWrapperRecord.strFormNumberComplexity = objUserSkill.Form_Number_Complexity__c;
				}

				if (String.isNotBlank(objWrapperRecord.strDebitCredit)) {
					if (objWrapperRecord.strDebitCredit.indexOf(objUserSkill.Debit_Credit__c) == -1) {
						objWrapperRecord.strDebitCredit = objWrapperRecord.strDebitCredit + ',' + objUserSkill.Debit_Credit__c;
					}
				} else {
					objWrapperRecord.strDebitCredit = objUserSkill.Debit_Credit__c;
				}

				if (String.isNotBlank(objWrapperRecord.strTier) && (objUserSkill.Partner_Tier__c == null || objUserSkill.Partner_Tier__c == 'NA')) {
					if (!objWrapperRecord.strTier.split(',').contains(objUserSkill.Tier__c)) {
						objWrapperRecord.strTier = objWrapperRecord.strTier + ',' + objUserSkill.Tier__c;
					}
				} else if (objUserSkill.Partner_Tier__c == null || objUserSkill.Partner_Tier__c == 'NA'){
					objWrapperRecord.strTier = objUserSkill.Tier__c;
				}

				if (String.isNotBlank(objWrapperRecord.strPartnerTier) && (objUserSkill.Tier__c == null || objUserSkill.Tier__c == 'NA')) {
					if (!objWrapperRecord.strPartnerTier.split(',').contains(objUserSkill.Partner_Tier__c)) {
						objWrapperRecord.strPartnerTier = objWrapperRecord.strPartnerTier + ',' + objUserSkill.Partner_Tier__c;
					}
				} else if (objUserSkill.Tier__c == null || objUserSkill.Tier__c == 'NA') {
					objWrapperRecord.strPartnerTier = objUserSkill.Partner_Tier__c;
				}

				if (objUserSkill.Partner_Tier__c != null && objUserSkill.Partner_Tier__c != 'NA') {
					map_UserSkillWrapper.put(strMultiYrPartnerTier, objWrapperRecord);
				} else {
					map_UserSkillWrapper.put(strMultiYrTier, objWrapperRecord);
				}
			}
		}

		if (map_UserSkillWrapper.size() > 0) {
			list_UserSkillWrapper = map_UserSkillWrapper.values();
		}

		return list_UserSkillWrapper;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : handle logic to create, delete, activate, deactivate, edit, clone user_Skill records
	 * @Parm        : objNewSkillsJson, strRemoveSkillIds, strActivateSkillIds, strDeactivateSkillIds, strType
	 * @Return      : N/A
	 **/
	@AuraEnabled
	public static string dmlOnUserSkills(object objNewSkillsJson, String strRemoveSkillIds, String strActivateSkillIds, String strDeactivateSkillIds, String strType) {
		List<User_Skill__c> list_UserSkillsToDelete = new List<User_Skill__c>();
		List<User_Skill__c> list_UpsertUserSkills = new List<User_Skill__c>();
		List<TaxResSFDCSkillAssignmentWrapperClass> list_UpdatedWrapperInstances;
		Map<String, String> map_UserIdUserRoleIds = new Map<String, String>();
		Map<Id, Set<String>> map_UserIdExistingSkills = new Map<Id, Set<String>>();
		Set<String> set_AgencyId = new Set<String>();
		Map<Id, Agency_Information__c> map_AgencyIdRecord = new Map<Id, Agency_Information__c>();
		List<User_Skill__c> list_OldUserSkills = new List<User_Skill__c>();
		Set<String> set_UserIdAgencyId = new Set<String>();
		Set<String> set_UserIdPartOfSkillCreation = new Set<String>();
		String strMessage = '';
		Map<String, Set<String>> map_UserIdSkillHash = new Map<String, Set<String>>();

		//delete the skills
		if (String.isNotBlank(strRemoveSkillIds)) {
			for (String strUserSkillId : strRemoveSkillIds.split(',')) {
				User_Skill__c objUSkill = new User_Skill__c(Id = strUserSkillId);
				list_UserSkillsToDelete.add(objUSkill);
			}
		}

		//Activate and Deactivate the skills
		if (String.isNotBlank(strActivateSkillIds)) {
			for (String strUserSkillId : strActivateSkillIds.split(',')) {
				User_Skill__c objUSkill = new User_Skill__c(Id = strUserSkillId, Active__c = true);
				list_UpsertUserSkills.add(objUSkill);
			}
		} else if (String.isNotBlank(strDeactivateSkillIds)) {
			for (String strUserSkillId : strDeactivateSkillIds.split(',')) {
				User_Skill__c objUSkill = new User_Skill__c(Id = strUserSkillId, Active__c = false);
				list_UpsertUserSkills.add(objUSkill);
			}
		}

		if (objNewSkillsJson != null) {
			list_UpdatedWrapperInstances = (List<TaxResSFDCSkillAssignmentWrapperClass>) JSON.deserialize(JSON.serialize(objNewSkillsJson), List<TaxResSFDCSkillAssignmentWrapperClass>.class);
			getAgencyInformation();

			List<TaxResSFDCSkillAssignmentWrapperClass> list_GroupedAgencyRecords = new List<TaxResSFDCSkillAssignmentWrapperClass>();
			for (TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord : list_UpdatedWrapperInstances) {
				if (map_TypeStateAgencyIds.containsKey(objWrapperRecord.strAgencyName)) {
					Integer intCounter = 1;
					for (Id idAgency : map_TypeStateAgencyIds.get(objWrapperRecord.strAgencyName)) {
						TaxResSFDCSkillAssignmentWrapperClass objNewWrapper = new TaxResSFDCSkillAssignmentWrapperClass();
						objNewWrapper.blnIsActive = true;
						objNewWrapper.strAgencyComplexity = map_AgencyIdRecords.get(idAgency).Agency_Complexity__c;
						objNewWrapper.strAgencyId = idAgency;
						objNewWrapper.strAgencyName = idAgency;
						objNewWrapper.strAgentId = objWrapperRecord.strAgentId;
						objNewWrapper.strAgentName = objWrapperRecord.strAgentName;
						objNewWrapper.strBAgentId = objWrapperRecord.strBAgentId;
						objNewWrapper.strBAgentName = objWrapperRecord.strBAgentName;
						objNewWrapper.strDebitCredit = objWrapperRecord.strDebitCredit;
						objNewWrapper.strFormNumberComplexity = objWrapperRecord.strFormNumberComplexity;
						objNewWrapper.strMultiYear = objWrapperRecord.strMultiYear;
						objNewWrapper.strNoticeType = objWrapperRecord.strNoticeType;
						objNewWrapper.strPartnerTier = objWrapperRecord.strPartnerTier;
						objNewWrapper.strThreshold = objWrapperRecord.strThreshold;
						objNewWrapper.strTier = objWrapperRecord.strTier;
						objNewWrapper.strUniqueId = objWrapperRecord.strUniqueId + intCounter;
						intCounter++;
						list_GroupedAgencyRecords.add(objNewWrapper);
					}
				}
			}

			if (list_GroupedAgencyRecords.size() > 0) {
				list_UpdatedWrapperInstances.addAll(list_GroupedAgencyRecords);
			}

			for (User_Role__c objUserRole : GlobalQueryHelper.getSpecialistUserRoleMap().values()) {
				map_UserIdUserRoleIds.put(objUserRole.User__c, objUserRole.Id);
			}

			//need agency Id to get agency info
			for (TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord : list_UpdatedWrapperInstances) {
				set_AgencyId.add(objWrapperRecord.strAgencyName);
				set_UserIdAgencyId.add(objWrapperRecord.strAgentName + '#' + objWrapperRecord.strAgencyName);
				set_UserIdPartOfSkillCreation.add(objWrapperRecord.strAgentName);
			}

			//get already assigned User Skiils for User ROles which we are creating new User Skill Records
			for (User_Skill__c objSkill : [
				SELECT Id, User_Role__c, User_Role__r.User__c, Agency_Information__c, User_Skill_Hash__c
				FROM User_Skill__c
				WHERE User_Role__r.User__c IN :set_UserIdPartOfSkillCreation
			]) {
				Set<String> set_TempSkillPattern = new Set<String>();
				String strKey = objSkill.User_Role__r.User__c + '#' + objSkill.Agency_Information__c;

				if (set_UserIdAgencyId.contains(strKey) && strType.equalsIgnoreCase('edit')) {
					list_OldUserSkills.add(objSkill);
				} else {
					if (map_UserIdExistingSkills.containsKey(objSkill.User_Role__c)) {
						set_TempSkillPattern = map_UserIdExistingSkills.get(objSkill.User_Role__c);
					}

					set_TempSkillPattern.add(objSkill.User_Skill_Hash__c);
					map_UserIdExistingSkills.put(objSkill.User_Role__c, set_TempSkillPattern);
				}
			}

			//final loop on list of skills from html
			for (TaxResSFDCSkillAssignmentWrapperClass objWrapperRecord : list_UpdatedWrapperInstances) {
				if (!map_UserIdUserRoleIds.containsKey(objWrapperRecord.strAgentName)) {
					throw new AuraHandledException('Resource does not have a related User Role.');
				}

				if (!map_UserIdUserRoleIds.containsKey(objWrapperRecord.strBAgentName)) {
					throw new AuraHandledException('Backup resource does not have a related User Role.');
				}

				//skipp group record as we have already included proper member agencies in the list
				if (map_TypeStateAgencyIds.containsKey(objWrapperRecord.strAgencyName)) {
					continue;
				}

				List<String> list_NoticeType = objWrapperRecord?.strNoticeType?.replace('NA', '')?.split(',');
				List<String> list_DebitCredit = objWrapperRecord?.strDebitCredit?.replace('NA', '')?.split(',');
				List<String> list_Tier = String.isNotBlank(objWrapperRecord.strTier) ? objWrapperRecord.strTier?.split(',') : objWrapperRecord.strPartnerTier?.split(',');

				if (isNumeric(objWrapperRecord.strUniqueId) || strType.equalsIgnoreCase('edit')) {
					for (String strNoticeType : list_NoticeType) {
						if (String.isBlank(strNoticeType)) {
							continue;
						}
						for (String strDebitCredit : list_DebitCredit) {
							if (String.isBlank(strDebitCredit)) {
								continue;
							}
							for (String strTier : list_Tier) {
								User_Skill__c objUserSkill = new User_Skill__c(
									Active__c = true,
									Tax_Notice_Type__c = strNoticeType,
									Form_Number_Complexity__c = objWrapperRecord.strFormNumberComplexity,
									Debit_Credit__c = strDebitCredit,
									Multi_Year__c = objWrapperRecord.strMultiYear,
									Partner_Tier__c = String.isBlank(objWrapperRecord.strTier) ? strTier : 'NA',
									Tier__c = String.isNotBlank(objWrapperRecord.strTier) ? strTier : 'NA',
									Thresholds__c = objWrapperRecord.strThreshold
								);

								objUserSkill.User_Role__c = map_UserIdUserRoleIds.get(objWrapperRecord.strAgentName);
								objUserSkill.Backup_Resource__c = map_UserIdUserRoleIds.get(objWrapperRecord.strBAgentName);
								objUserSkill.Agency_Information__c = objWrapperRecord.strAgencyName;
								String strSkillPattern =
									map_AgencyIdRecords?.get(objUserSkill.Agency_Information__c)?.Agency_Abbreviation__c +
									'|' +
									map_AgencyIdRecords?.get(objUserSkill.Agency_Information__c)?.Agency_Complexity__c +
									'|' +
									objUserSkill.Tax_Notice_Type__c +
									'|' +
									objUserSkill.Form_Number_Complexity__c +
									'|' +
									objUserSkill.Debit_Credit__c +
									'|' +
									objUserSkill.Thresholds__c +
									'|' +
									objUserSkill.Tier__c +
									'|' +
									objUserSkill.Partner_Tier__c +
									'|' +
									objUserSkill.Multi_Year__c;

								Set<String> set_PresentSkills = map_UserIdExistingSkills.get(objUserSkill?.User_Role__c);
								if (set_PresentSkills?.size() > 0 && String.isNotBlank(strSkillPattern) && set_PresentSkills?.contains(strSkillPattern)) {
									throw new AuraHandledException('Can not create duplicate skills.');
								} else {
									list_UpsertUserSkills.add(objUserSkill);
								}

								if (strType.equalsIgnoreCase('edit')) {
									if(!map_UserIdSkillHash.isEmpty() && map_UserIdSkillHash.get(objUserSkill?.User_Role__c).contains(strSkillPattern)) {
										throw new AuraHandledException('Can not create duplicate skills.');
									} else {
										set_PresentSkills = new Set<String>();
										if (map_UserIdSkillHash?.get(objUserSkill.User_Role__c) != null) {
											set_PresentSkills = map_UserIdSkillHash.get(objUserSkill?.User_Role__c);
										}
										set_PresentSkills.add(strSkillPattern);
										map_UserIdSkillHash.put(objUserSkill.User_Role__c, set_PresentSkills);
									}
								}
							}
						}
					}
				}
			}
		}

		try {
			if (!list_UserSkillsToDelete.isEmpty()) {
				delete list_UserSkillsToDelete;
				strMessage = 'Success: Skills(s) deleted successfully';
			}

			if (!list_OldUserSkills.isEmpty()) {
				delete list_OldUserSkills;
			}

			if (!list_UpsertUserSkills.isEmpty()) {
				upsert list_UpsertUserSkills;
				strMessage = 'Success: Skills(s) created/updated successfully';
			}

			return strMessage;
		} catch (Exception e) {
			String errorMsg = 'The following exception has occurred: ' + e.getMessage();
			throw new AuraHandledException(ErrorMsg);
		}
	}

	//wrapper
	public class TaxResSFDCSkillAssignmentWrapperClass {
		@AuraEnabled
		public String strUniqueId;
		@AuraEnabled
		public String strAgentName;
		@AuraEnabled
		public String strAgentId;
		@AuraEnabled
		public String strBAgentName;
		@AuraEnabled
		public String strBAgentId;
		@AuraEnabled
		public String strAgencyName;
		@AuraEnabled
		public String strAgencyId;
		@AuraEnabled
		public String strAgencyComplexity;
		@AuraEnabled
		public String strNoticeType;
		@AuraEnabled
		public String strFormNumberComplexity;
		@AuraEnabled
		public String strDebitCredit;
		@AuraEnabled
		public String strThreshold;
		@AuraEnabled
		public String strTier;
		@AuraEnabled
		public String strPartnerTier;
		@AuraEnabled
		public String strMultiYear;
		@AuraEnabled
		public Boolean blnIsActive;

		//Agency|Agency Complexity|Tax Notice Type|Tax Notice Complexity|Debit/Credit|Thresholds|Tier|Partner Tier|Multi YR/QTR Indicator
		//CA-EDD|L|SUI|L|C|50|Concierge|NA|N

		public TaxResSFDCSkillAssignmentWrapperClass() {
			this.strUniqueId = strUniqueId;
			this.strAgentName = strAgentName;
			this.strBAgentName = strBAgentName;
			this.strAgencyName = strAgencyName;
			this.strAgencyComplexity = strAgencyComplexity;
			this.strNoticeType = strNoticeType;
			this.strFormNumberComplexity = strFormNumberComplexity;
			this.strDebitCredit = strDebitCredit;
			this.strThreshold = strThreshold;
			this.strTier = strTier;
			this.strPartnerTier = strPartnerTier;
			this.strMultiYear = strMultiYear;
			this.blnIsActive = blnIsActive;
			this.strAgentId = strAgentId;
			this.strAgencyId = strAgencyId;
		}
	}

	//wrapper
	public class OnPageLoadDataWrapperClass {
		@AuraEnabled
		public List<String> list_AgentNameId;
		@AuraEnabled
		public List<String> list_AgencyNameAbbreviations;
		@AuraEnabled
		public List<TaxResSFDCSkillAssignmentWrapperClass> list_UserSkillWrapper;
		@AuraEnabled
		public Integer intTotalRecords;
		@AuraEnabled
		public String strReportId;

		public OnPageLoadDataWrapperClass() {
			this.list_AgentNameId = list_AgentNameId;
			this.list_AgencyNameAbbreviations = list_AgencyNameAbbreviations;
			this.list_UserSkillWrapper = list_UserSkillWrapper;
			this.intTotalRecords = intTotalRecords;
			this.strReportId = strReportId;
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : handle logic to check if passed value is numeric or not
	 * @Parm        : strInput
	 * @Return      : Boolean
	 **/
	public static Boolean isNumeric(String strInput) {
		Boolean blnIsRandomNumber;

		try {
			Decimal.valueOf(strInput);
			blnIsRandomNumber = true;
		} catch (Exception objException) {
			blnIsRandomNumber = false;
		}

		return blnIsRandomNumber;
	}
}