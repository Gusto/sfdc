/**
 * @name         FWManageRoleUtil
 * @author       Deepika Saini
 * @date         31st May 2021
 * @description  FWManageRole related Utilities for reuse
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class FWManageRoleUtil {
	//Roles
	public static final String ROLE_IMPLEMENTATION = 'Implementation Advocate';
	public static final String ROLE_ADVISOR = 'Advisor';
	public static final String ROLE_RENEWAL_SPECIALIST = 'Renewal Specialist';
	public static final String ROLE_BENEFITS_DESIGNER = 'Benefits Designer';
	public static final String ROLE_PAYROLL_TRANSFER_ADV = 'Payroll Transfer Advocate';
	public static final String ROLE_PAYROLL_TRANSFER_FAC = 'Payroll Transfer Facilitator';
	public static final string ROLE_BENEFIT_TRANSFER = 'Benefit Transfer';
	public static final string ROLE_BENEFIT_TRANSFER_QUALIFIER = 'Benefit Transfer Qualifier';
	public static final string ROLE_BENEFIT_TRANSFER_ADVOCATE = 'Benefit Transfer Advocate';
	public static final string ROLE_BENEFIT_TRANSFER_FACILITATOR1 = 'Benefit Transfer Facilitator 1';
	public static final string ROLE_BENEFIT_TRANSFER_FACILITATOR2 = 'Benefit Transfer Facilitator 2';
	public static final string ROLE_CARRIER_IO = 'Carrier IO';
	public static final string ROLE_BYB_ADVOCATE = 'BYB Advocate';

	public static final String TEAM_ADVISING = 'Benefits Advising';

	public static final String OA_ROLE_ADVOCATE = 'Advocate';
	public static final String BT_FACILITATOR1 = 'Facilitator 1';
	public static final String BT_FACILITATOR2 = 'Facilitator 2';
	public static final String BT_QUALIFIER = 'Qualifier';

	public static final String SKILL_TYPE_CORE = 'Core';
	public static final String SKILL_TYPE_FLEX = 'Flex';
	public static final String SKILL_TYPE_TRAINING = 'Training';
	public static final String TYPE_REGION = 'Region';
	public static final String TYPE_POD = 'POD';

	public static final String COVERAGE_TYPE_MEDICAL = 'Medical';
	public static final String COVERAGE_TYPE_DENTAL = 'Dental';
	public static final String COVERAGE_TYPE_VISION = 'Vision';
	public static final String COVERAGE_TYPE_LIFE = 'Life';
	public static final String COVERAGE_TYPE_STD = 'Short Term Disability';
	public static final String COVERAGE_TYPE_LTD = 'Long Term Disability';

	public static final String BENEFITS_BIG_DESK = 'Benefits Big Desk';
	public static final String COVERAGE_TYPE = 'Coverage type';
	public static final String ORDER_ALLOCATION = 'Order Allocation';
	public static final String STATE = 'State';
	public static final String CARRIER_POD = 'Carrier POD';
	public static final String TIER = 'Tier';
	public static final String ORDER_TYPE = 'Order Type';
	public static final String PARTNER = 'Partner';
	public static final String TADA = 'Tada';
	
	public static final String TADA_ERROR = 'TAdA';
	public static final String FLEX_TRAINING_ERROR = 'Flex/Training, ';
	public static final String END_DATE_ERROR = 'End Date, ';
	public static final String REQUIRED_FIELD_ERROR = 'Required Fields(';

	public static final Id ADVISING_BOA_RT_ID = Cache.getRecordTypeId('Benefit_Order_Allocation__c', 'Advising');

	public static final Set<String> set_CoverageTypes = new Set<String>{
		COVERAGE_TYPE_DENTAL,
		COVERAGE_TYPE_LIFE,
		COVERAGE_TYPE_LTD,
		COVERAGE_TYPE_MEDICAL,
		COVERAGE_TYPE_STD,
		COVERAGE_TYPE_VISION
	};

	public static final Set<String> set_AdvisorRoles = new Set<String>{ ROLE_ADVISOR, ROLE_RENEWAL_SPECIALIST };
	public static final Set<String> set_RoleWithOnlySkillCore = new Set<String>{
		ROLE_IMPLEMENTATION,
		ROLE_ADVISOR,
		ROLE_RENEWAL_SPECIALIST,
		ROLE_BENEFITS_DESIGNER
	};

	public static final Set<String> set_AdvisingRoles = new Set<String>{
		ROLE_ADVISOR,
		ROLE_RENEWAL_SPECIALIST,
		ROLE_BENEFITS_DESIGNER
	};

	public static Map<String, Set<String>> map_HashOfSkillWithUsers;
	public static Map<String, String> map_UserIdsWithSkillType = new Map<String, String>();

	private static Map<String, Decimal> map_UserIdCap;

	/**
	 * @Author      : Deepika Saini
	 * @Description : Get the Advising User
	 * @Parm        : set_States - Set of states
	 *                set_RoleNames - set of Role Name
	 * @Return      : Map<String, Set<String>> - [#State_Group__c#Benefits_Big_Desk__c, [Set of Eligible user for these Skills]]
	 **/
	public static Map<String, Set<String>> getAdvisingUserSkills(Set<String> set_States, Set<String> set_RoleNames) {
		if (map_HashOfSkillWithUsers == null) {
			fetchAdvisingUserSkills(set_States, set_RoleNames);
		}

		return map_HashOfSkillWithUsers;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Query the User Skill Object to get Advising Skills Data
	 * @Parm        : set_States - Set of states
	 *                set_RoleNames - set of Role Name
	 * @Return      : null
	 **/
	private static void fetchAdvisingUserSkills(Set<String> set_States, Set<String> set_RoleNames) {
		map_HashOfSkillWithUsers = new Map<String, Set<String>>();
		for (User_Skill__c objUserSkill : [
			SELECT
				Id,
				User_Name__c,
				User_Role__c,
				User_Role__r.User__c,
				State_Group__c,
				Benefits_Big_Desk__c,
				Coverage_Type__c,
				User_Skill_Role_Name__c
			FROM User_Skill__c
			WHERE
				User_Role__c != null
				AND User_Role__r.User__c != null
				AND Skill_Role_Name__c != null
				AND State_Group__c != null
				AND State_Group__c IN :set_States
				AND User_Skill_Role_Name__c IN :set_RoleNames
				AND User_Role__r.User__r.IsActive = TRUE
				AND User_Role__r.User__r.Out_Of_Office__c = FALSE
		]) {
			String strKey = '#' + objUserSkill.State_Group__c + '#' + objUserSkill.Benefits_Big_Desk__c;
			Set<String> set_TempUserIds = new Set<String>();

			if (!map_HashOfSkillWithUsers.isEmpty()) {
				if (map_HashOfSkillWithUsers.containsKey(strKey)) {
					set_TempUserIds = map_HashOfSkillWithUsers.get(strKey);
				}
			}

			set_TempUserIds.add(objUserSkill.User_Role__r.User__c);
			map_HashOfSkillWithUsers.put(strKey, set_TempUserIds);

			if (
				map_UserIdsWithSkillType.isEmpty() ||
				(!map_UserIdsWithSkillType.isEmpty() &&
				!map_UserIdsWithSkillType.containsKey(objUserSkill.User_Role__r.User__c))
			) {
				map_UserIdsWithSkillType.put(
					objUserSkill.User_Role__r.User__c,
					objUserSkill.User_Skill_Role_Name__c
				);
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Get the Advising Cap Detial for Ramping
	 * @Parm        : set_Months - Set of Months
	 *                set_Years - set of Years
	 * 				  set_RecordTypes - set of Record Type
	 * @Return      : Map<String, Decimal> - [UserId~month~year, Max Number Opp of Capacity]
	 **/
	public static Map<String, Decimal> getAdvisingCapDetailsForRamping(
		Set<Decimal> set_Months,
		Set<Decimal> set_Years,
		Set<Id> set_RecordTypes
	) {
		if (map_UserIdCap == null) {
			fetchAdvisingCapDetailsForRamping(set_Months, set_Years, set_RecordTypes);
		}

		return map_UserIdCap;
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : fetch Advising Cap Detial from Benefit_Order_Allocation__c
	 * @Parm        : set_Months - Set of Months
	 *                set_Years - set of Years
	 * 				  set_RecordTypes - set of Record Type
	 * @Return      : null
	 **/
	private static void fetchAdvisingCapDetailsForRamping(
		Set<Decimal> set_Months,
		Set<Decimal> set_Years,
		Set<Id> set_RecordTypes
	) {
		map_UserIdCap = new Map<String, Decimal>();

		if (!set_Months.isEmpty() && !set_Years.isEmpty()) {
			for (Benefit_Order_Allocation__c objBOA : [
				SELECT Id, User__c, Month__c, Year__c, Max_BO__c
				FROM Benefit_Order_Allocation__c
				WHERE
					Month__c != null
					AND User__c != null
					AND Year__c != null
					AND Month__c IN :set_Months
					AND Year__c IN :set_Years
					AND RecordTypeId IN :set_RecordTypes
			]) {
				String strkey = objBOA.User__c + '~' + objBOA.Month__c + '~' + objBOA.Year__c;
				map_UserIdCap.put(strkey, objBOA.Max_BO__c);
			}
		}
	}

	//To be converted to custom setting during group ops
	public static final Map<String, Set<String>> map_TeamToRoleName = new Map<String, Set<String>>{
		TEAM_ADVISING => new Set<String>{ ROLE_RENEWAL_SPECIALIST, ROLE_ADVISOR, ROLE_BENEFITS_DESIGNER }
	};
	public static final Map<String, Set<String>> map_RoleToSkill = new Map<String, Set<String>>{
		ROLE_RENEWAL_SPECIALIST => new Set<String>{ SKILL_TYPE_CORE },
		ROLE_ADVISOR => new Set<String>{ SKILL_TYPE_CORE },
		ROLE_BENEFITS_DESIGNER => new Set<String>{ SKILL_TYPE_CORE }
	};

	private static Map<String, Skill_Criteria_Setup__c> map_SkillSetupCriteria;

	/**
	 * @Author      : Deepika Saini
	 * @Description : get the SetUp Criteria for the Skills
	 * @Parm        : null
	 * @Return      : Map<String, Skill_Criteria_Setup__c> - [Qualification-Core, Skill Criteria setup object]
	 **/
	public static Map<String, Skill_Criteria_Setup__c> retriveAllSetupCriteria() {
		if (map_SkillSetupCriteria == null) {
			map_SkillSetupCriteria = new Map<String, Skill_Criteria_Setup__c>();

			for (Skill_Criteria_Setup__c objSkillSetup : Skill_Criteria_Setup__c.getall().values()) {
				map_SkillSetupCriteria.put(
					objSkillSetup.Team__c +
					'-' +
					objSkillSetup.Skill_Type__c,
					objSkillSetup
				);
			}
		}
		return map_SkillSetupCriteria;
	}

	//BD Play Mode Config Keys
	public static final String BASE_FILTER = 'Base Query';
	public static final String BASE_WHERE_FILTER = 'Base WHERE Clause';
	public static final String BUCKET1_FILTER = 'Bucket 1 WHERE Clause';
	public static final String ORDERBY_FILTER = 'Order By';
	public static final String BUCKET1SIZE_FILTER = 'Bucket 1 Batch Size';
	public static final String BUCKET2SIZE_FILTER = 'Bucket 2 Batch Size';
	public static final String CARRIERWHERE_FILTER = 'Carrier Preference WHERE Clause';
	public static final String CARRIER_CHANGE_WHERE_FILTER = 'Change Carrier Preference WHERE Clause';
	public static final String SAME_CARRIER_PLAY_COUNT_FILTER = 'Same Carrier Play Count';
}