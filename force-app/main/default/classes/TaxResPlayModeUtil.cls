/**
 * @name         TaxResPlayModeUtil
 * @author       Anand Singh
 * @Date         25th May 2021
 * @description  This class handles the Play mode fuctionality for Accout Specialist
 * @test class   TaxResPlayModeUtilTest.cls
 **/
public with sharing class TaxResPlayModeUtil {
	static final String CAPTAIN = 'Captain';
	static final Id LOGGED_IN_USER = UserInfo.getUserId();

	//specialist assignment variables
	Map<String, String> map_tagNameQueryString = new Map<String, String>();
	String ERROR_MSG_USER_NOT_PRESENT = 'No Account Specialist user present in the system.';
	String ERROR_MSG_SPECIALIST_NOT_FOUND = 'Not able to find eligible Account Specialist.';
	String SUCCESS_OPEN_MATCH = 'Least # of open cases.';
	String SUCCESS_UNOPEN_MATCH = 'Least # of unopened cases.';
	String SUCCESS_MSG_RANDOM_MATCH = 'Random assignment processed.';
	String META_NAME_FOR_ELIGIBLE_USERS_QUERY = 'Specialist_Assignment_Eligible_Users';
	String META_NAME_FOR_OPEN_CASE_COUNT_QUERY = 'Specialist_Open_Case_Count';
	String META_NAME_FOR_NOT_STARTED_CASE_COUNT_QUERY = 'Specialist_Not_Started_Case_Count';
	String ERROR_MSG_UNMAPPED_FORM_NUMBER = 'Unmapped form number.';
	String SKILL_SPLIT_VAR = '&#124;';
	public static final String TAXRES_UNASSIGNED_PE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Tax_Res_Unassigned_PE_Queue');
	public static final String TAXRES_FROM_MAINTENANCE_QUEUE_ID = GlobalQueryHelper.getQueueIdByDevName('Form_Maintenance');
	Map<String, Set<String>> map_SkillPatternSetOfRelatedUserIds = new Map<String, Set<String>>();
	Map<String, Set<String>> map_SkillPatternSetOfBackupUserIds = new Map<String, Set<String>>();
	Map<String, Integer> map_IRUserIdOpenCaseCount = new Map<String, Integer>();
	Map<String, Integer> map_IRUserIdNotStartedCaseCount = new Map<String, Integer>();

	public TaxResPlayModeUtil() {
	}

	/**
	 * @Author      : Anand Singh
	 * @Description : Get User role data from User_Role__c object of logged in user
	 * @Parm        : Nothing.
	 * @Return      : User_Role__c object
	 **/
	@AuraEnabled
	public static User_Role__c retriveUserRoleData() {
		try {
			List<User_Role__c> list_UserRoles = [
				SELECT Id, User_Skill_Team__c, POD_Captain__c, User__c, User__r.Out_Of_Office__c, (SELECT Id, User_Skill_Role_Name__c FROM User_Role__r)
				FROM User_Role__c
				WHERE User__c = :LOGGED_IN_USER
				LIMIT 1
			];

			if (list_UserRoles.size() > 0) {
				return list_UserRoles[0];
			}
		} catch (Exception objException) {
			User_Role__c objUserRole = new User_Role__c();
			objUserRole.BT_Notes__c = objException.getMessage();
			return objUserRole;
		}

		return null;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : get meta-data records
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public void getCustomMetaData() {
		Set<String> set_RelatedConfigDevName = new Set<String>{ META_NAME_FOR_ELIGIBLE_USERS_QUERY, META_NAME_FOR_OPEN_CASE_COUNT_QUERY, META_NAME_FOR_NOT_STARTED_CASE_COUNT_QUERY };
		for (Tax_Res_Play_Mode_Configuration__mdt objConfig : [SELECT Id, DeveloperName, Filter_Value__c FROM Tax_Res_Play_Mode_Configuration__mdt WHERE DeveloperName IN :set_RelatedConfigDevName]) {
			map_tagNameQueryString.put(objConfig.DeveloperName, objConfig.Filter_Value__c);
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Specialist assignment related method to retrieve Specialist users' current related case count
	 * @Parm        : set_EligibleUsers [set of eligible Users], map_userIdCounts [Specialist users and related case count]
	 * @Return      : N/A
	 **/
	public Set<String> getUsersWithLeastCaseCount(Set<String> set_EligibleUsers, Map<String, Integer> map_userIdCounts) {
		Integer intLeastCount;
		Set<String> set_EligibleUserIds = new Set<String>();
		if (set_EligibleUsers.isEmpty()) {
			return new Set<String>();
		}

		if (map_userIdCounts.isEmpty()) {
			return set_EligibleUsers;
		}

		for (String idUser : set_EligibleUsers) {
			if (map_userIdCounts.containsKey(idUser)) {
				Integer intTemp = map_userIdCounts.get(idUser);
				if (intLeastCount == null || intTemp < intLeastCount) {
					intLeastCount = intTemp;
					set_EligibleUserIds = new Set<String>();
					set_EligibleUserIds.add(idUser);
				} else if (intTemp == intLeastCount) {
					set_EligibleUserIds.add(idUser);
				}
			}
		}

		return set_EligibleUserIds;
	}

	List<String> getSkillPartsList(String strSkillHash) {
		List<String> list_SkillParts = new List<String>();
		if (String.isNotBlank(strSkillHash)) {
			String decodedString = String.valueOf(EncodingUtil.urlDecode(strSkillHash, 'UTF-8'));
			list_SkillParts = String.valueOf(decodedString).split('\\|');
		}

		return list_SkillParts;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Main method to be called for Specialist assignment
	 * @Parm        : list_Cases [list of eligible cases], blnPerformDML [flag to decide if DML needs to be performed after assignment]
	 * @Return      : N/A
	 **/
	public void runIRSpecialistAssignment(List<Case> list_Cases, Boolean blnRunDML) {
		Map<Id, Case> map_OwnerUpdatedCases = new Map<Id, Case>();
		List<Database.SaveResult> list_SaveResult = new List<Database.SaveResult>();
		Set<String> set_CasePatterns = new Set<String>();
		Map<String, Set<String>> map_SkillAlternateSkills = new Map<String, Set<String>>();

		if (list_Cases.isEmpty()) {
			return;
		}

		for (Case objCase : list_Cases) {
			if (String.isNotBlank(objCase.Skill_Pattern__c)) {
				set_CasePatterns.add(objCase.Skill_Pattern__c);

				List<String> list_SkillsBreakDown = getSkillPartsList(objCase.Skill_Pattern__c);
				Set<String> set_alternateThresholds = new Set<String>();
				Set<String> set_alternateFNComplexity = new Set<String>();
				Set<String> set_AlternateSkills = new Set<String>();
				String strThreshold = list_SkillsBreakDown?.size() > 5 ? list_SkillsBreakDown.get(5) : null;
				String strFNComplexity = list_SkillsBreakDown?.size() > 3 ? list_SkillsBreakDown.get(3) : null;

				if (strThreshold == '0') {
					set_alternateThresholds = new Set<String>{ '0', '50', '1500', '10000', '10000+' };
				} else if (strThreshold == '50') {
					set_alternateThresholds = new Set<String>{ '50', '1500', '10000', '10000+' };
				} else if (strThreshold == '1500') {
					set_alternateThresholds = new Set<String>{ '1500', '10000', '10000+' };
				} else if (strThreshold == '10000') {
					set_alternateThresholds = new Set<String>{ '10000', '10000+' };
				} else if (String.isNotBlank(strThreshold)) {
					set_alternateThresholds = new Set<String>{ '10000+' };
				}

				if (strFNComplexity == 'L') {
					set_alternateFNComplexity = new Set<String>{ 'L', 'H', 'M' };
				} else if (strFNComplexity == 'M') {
					set_alternateFNComplexity = new Set<String>{ 'M', 'H' };
				} else if (String.isNotBlank(strFNComplexity)) {
					set_alternateFNComplexity = new Set<String>{ 'H' };
				}

				//agency|agencyComplexity|NoticeType|FNComplexity|Debit|Threshold|Tier|PTier|Multi
				//TaxNoticeComplexity//threshold
				for (String strTempThreshold : set_alternateThresholds) {
					for (String strComplexity : set_alternateFNComplexity) {
						String strTempSkill = list_SkillsBreakDown[0];
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[1];
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[2];
						strTempSkill = strTempSkill + '|' + strComplexity;
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[4];
						strTempSkill = strTempSkill + '|' + strTempThreshold;
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[6];
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[7];
						strTempSkill = strTempSkill + '|' + list_SkillsBreakDown[8];
						set_AlternateSkills.add(strTempSkill);
						set_CasePatterns.add(strTempSkill);
                        system.debug('strTempSkill******'+strTempSkill);
					}
				}

				if (set_AlternateSkills.size() > 0) {
					map_SkillAlternateSkills.put(objCase.Skill_Pattern__c, set_AlternateSkills);
				}
			}
		}

		if (set_CasePatterns.size() > 0) {
			getCustomMetaData();
			getEigibleUserSkills(set_CasePatterns);

			for (Case objCase : list_Cases) {
				String strEligibleUserId;
				String strErrorMsg = '';
				String strSuccessMsg = '';
				Set<String> set_UserIds = new Set<String>();
				List<String> list_SkillsBreakDown = getSkillPartsList(objCase.Skill_Pattern__c);
				String strFNComplexity = list_SkillsBreakDown?.size() > 3 ? list_SkillsBreakDown.get(3) : null;

				if (String.isNotBlank(objCase.Skill_Pattern__c) && map_SkillPatternSetOfRelatedUserIds.containsKey(objCase.Skill_Pattern__c)) {
					set_UserIds = map_SkillPatternSetOfRelatedUserIds.get(objCase.Skill_Pattern__c);
				}

				if (map_SkillAlternateSkills?.containsKey(objCase.Skill_Pattern__c)) {
					for (String objAltSkill : map_SkillAlternateSkills?.get(objCase.Skill_Pattern__c)) {
						if (String.isNotBlank(objAltSkill) && map_SkillPatternSetOfRelatedUserIds?.containsKey(objAltSkill)) {
							set_UserIds.addAll(map_SkillPatternSetOfRelatedUserIds.get(objAltSkill));
						}
					}
				}

				if (set_UserIds != null && set_UserIds.size() > 0) {
					set_UserIds = getUsersWithLeastCaseCount(set_UserIds, map_IRUserIdOpenCaseCount);

					if (set_UserIds != null && set_UserIds.size() < 1) {
						strErrorMsg = ERROR_MSG_SPECIALIST_NOT_FOUND;
					} else if (set_UserIds != null && set_UserIds.size() == 1) {
						strEligibleUserId = (new List<String>(set_UserIds))[0];
						strSuccessMsg = SUCCESS_OPEN_MATCH;
					} else {
						set_UserIds = getUsersWithLeastCaseCount(set_UserIds, map_IRUserIdNotStartedCaseCount);

						if (set_UserIds != null && set_UserIds.size() < 1) {
							strErrorMsg = ERROR_MSG_SPECIALIST_NOT_FOUND;
						} else if (set_UserIds != null && set_UserIds.size() == 1) {
							strEligibleUserId = (new List<String>(set_UserIds))[0];
							strSuccessMsg = SUCCESS_UNOPEN_MATCH;
						} else {
							Integer intRandomCount = Integer.valueOf(math.random() * set_UserIds.size());
							strEligibleUserId = (new List<String>(set_UserIds))[intRandomCount];
							strSuccessMsg = SUCCESS_MSG_RANDOM_MATCH;
						}
					}
				} else {
					strErrorMsg = ERROR_MSG_USER_NOT_PRESENT;
				}

				if (strEligibleUserId != null) {
					objCase.OwnerId = strEligibleUserId;
					objCase.Account_Specialist__c = strEligibleUserId;
					objCase.Error_Message__c = strSuccessMsg;
					map_IRUserIdOpenCaseCount.put(strEligibleUserId, map_IRUserIdOpenCaseCount.get(strEligibleUserId) + 1);
					map_IRUserIdNotStartedCaseCount.put(strEligibleUserId, map_IRUserIdNotStartedCaseCount.get(strEligibleUserId) + 1);
				} else if (String.isBlank(strFNComplexity)) {
					objCase.OwnerId = TAXRES_FROM_MAINTENANCE_QUEUE_ID;
					objCase.Error_Message__c = ERROR_MSG_UNMAPPED_FORM_NUMBER;
				} else {
					objCase.OwnerId = TAXRES_UNASSIGNED_PE_QUEUE_ID;
					objCase.Error_Message__c = strErrorMsg;
				}

				map_OwnerUpdatedCases.put(objCase.Id, objCase);
			}

			if (map_OwnerUpdatedCases.size() > 0) {
				if (blnRunDML) {
					try {
						list_SaveResult = Database.update(map_OwnerUpdatedCases.values(), false);
					} catch (System.DmlException objException) {
						ExceptionLogUtil.logException(
							'TaxResPlayModeUtil',
							'runIRSpecialistAssignment',
							'Exception On Line ' +
							objException.getLineNumber() +
							'-' +
							objException.getMessage(),
							objException.getStackTraceString()
						);
					}

					for (Database.SaveResult objSR : list_SaveResult) {
						if (!objSR.isSuccess()) {
							String strError = '';
							for (Database.Error objErr : objSR.getErrors()) {
								strError += objErr.getMessage();
							}
							map_OwnerUpdatedCases.get(objSR.getId()).Error_Message__c = strError;
						} else {
							map_OwnerUpdatedCases.remove(objSR.getId());
						}
					}
				}

				CaseTriggerHelper.createTaxResAuditLogs(map_OwnerUpdatedCases.values(), CaseUtils.OWNER_CHANGE, false, true);
			}
		}
	}

	public void getEigibleUserSkills(Set<String> set_SkillPatterns) {
		if (set_SkillPatterns?.size() > 0) {
			Set<String> set_Status = CaseUtils.set_OpenCaseStatuses;
			Set<String> set_UserIds = new Set<String>();

			for (User_Skill__c objSkill : [
				SELECT
					Id,
					User_Role__r.User__c,
					User_Skill_Hash__c,
					User_Role__r.User__r.Out_Of_Office__c,
					User_Role__r.Remove_From_Assignment__c,
					Backup_Resource__r.User__c,
					Backup_Resource__r.User__r.Out_Of_Office__c,
					Backup_Resource__r.Remove_From_Assignment__c
				FROM User_Skill__c
				WHERE User_Skill_Hash__c IN :set_SkillPatterns AND Active__c = TRUE AND User_Role__c != NULL AND User_Role__r.User_Skill_team__c = :CaseUtils.TAXRES_ACCOUNT_SPECIALIST
			]) {
				Set<String> set_TempUserIds = new Set<String>();
                system.debug('objSkill*******'+objSkill);
				String strPrimaryUser = objSkill.User_Role__r.User__c;
				if (map_SkillPatternSetOfRelatedUserIds.containsKey(objSkill.User_Skill_Hash__c)) {
					set_TempUserIds = map_SkillPatternSetOfRelatedUserIds.get(objSkill.User_Skill_Hash__c);
				}

				//skip the user if both user and backup user are not available/eligible
				if (
					(objSkill.User_Role__r.User__r.Out_Of_Office__c || objSkill.User_Role__r.Remove_From_Assignment__c) && 
					(String.isBlank(objSkill.Backup_Resource__c) || objSkill.Backup_Resource__c == null || (objSkill.Backup_Resource__c != null && (objSkill.Backup_Resource__r.User__r.Out_Of_Office__c || objSkill.Backup_Resource__r.Remove_From_Assignment__c)))
					
				) {
					continue;
				}

				//if primary resource is not available bu backup resource is, treat backup user as primary
				if (
					(objSkill.User_Role__r.User__r.Out_Of_Office__c || objSkill.User_Role__r.Remove_From_Assignment__c) && objSkill.Backup_Resource__c != null &&
					!objSkill.Backup_Resource__r.User__r.Out_Of_Office__c &&
					!objSkill.Backup_Resource__r.Remove_From_Assignment__c
				) {
					strPrimaryUser = objSkill.Backup_Resource__r.User__c;
				}

				set_TempUserIds.add(strPrimaryUser);
				set_UserIds.add(strPrimaryUser);
				map_SkillPatternSetOfRelatedUserIds.put(objSkill.User_Skill_Hash__c, set_TempUserIds);
				map_IRUserIdOpenCaseCount.put(strPrimaryUser, 0);
				map_IRUserIdNotStartedCaseCount.put(strPrimaryUser, 0);
			}

			for (AggregateResult objResult : Database.query(map_tagNameQueryString.get(META_NAME_FOR_OPEN_CASE_COUNT_QUERY))) {
				map_IRUserIdOpenCaseCount.put((String) objResult.get('Account_Specialist__c'), (Integer) objResult.get('cnt'));
			}

			for (AggregateResult objResult : Database.query(map_tagNameQueryString.get(META_NAME_FOR_NOT_STARTED_CASE_COUNT_QUERY))) {
				map_IRUserIdNotStartedCaseCount.put((String) objResult.get('Account_Specialist__c'), (Integer) objResult.get('cnt'));
			}
		}
	}
}