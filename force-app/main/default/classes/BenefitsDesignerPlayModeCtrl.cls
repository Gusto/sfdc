/**
 * @name		BenefitsDesignerPlayModeCtrl
 * @author      Neha Dabas
 * @date        June 9 2021
 * @description Controller for BenefitsDesignerPlayMode page
 * @test class	BenefitsDesignerPlayModeCtrlTest
 * @revisions   Date ------------ Name ------------ Comments
 **/
public with sharing class BenefitsDesignerPlayModeCtrl {
	public Integer intOpptiesInReadyForDefault { get; private set; }
	public Integer intOpptiesInBlocked { get; private set; }
	public Integer intRecommendationsSentCount { get; private set; }
	public DateTime dtLatestBlockedTimestamp { get; private set; }
	public Boolean blnIsBenefitDesginer { get; private set; }
	public Boolean blnPlayModeConfigComplete { get; private set; }
	public String strAssignedOpportunityIds { get; private set; }
	public String strAssignedOpportunityNames { get; private set; }

	private Id idLoggedInUser;
	private Set<String> set_States;
	private Set<String> set_CoverageTypes;
	private Id idUserPreferredCarrier;
	private String strUserPreferredState;
	private User_Role__c objUserRole;
	private Map<String, String> map_BDPlayModeConfig;

	private List<Opportunity> list_Opportunities;

	private final String MESSAGE_PLAY_AGAIN = 'Queue is refreshing, please play again';
	private final String MESSAGE_NO_OPPTY = 'There are no opportunities available to be assigned!';
	private final String MESSAGE_INCOMPLETE_CONFIG = 'Playmode Configurations are not complete. Please contact your administrator.';

	//Constructor
	public BenefitsDesignerPlayModeCtrl() {
		initializeSkillsAndUserData();
		if (blnIsBenefitDesginer != true) {
			return;
		}

		fetchPlayModeConfigurations();

		if (map_BDPlayModeConfig.isEmpty() || !map_BDPlayModeConfig.containsKey(FWManageRoleUtil.BASE_FILTER)) {
			blnPlayModeConfigComplete = false;
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, MESSAGE_INCOMPLETE_CONFIG));
			return;
		}

		blnPlayModeConfigComplete = true;

		strAssignedOpportunityIds = '';
		strAssignedOpportunityNames = '';

		initializeStatistics();
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Fetch Coverage Type and States details from User Role data
	 * @Parm        : null
	 * @Return      : null
	 **/
	private void initializeSkillsAndUserData() {
		idLoggedInUser = userInfo.getUserId();
		blnIsBenefitDesginer = false;
		set_CoverageTypes = new Set<String>();
		set_States = new Set<String>();

		for (User_Skill__c objUserSkill : [
			SELECT State_Group__c, Coverage_Type__c
			FROM User_Skill__c
			WHERE Skill__r.Role__r.Name = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER AND User_Role__r.User__c = :idLoggedInUser
		]) {
			set_States.add(objUserSkill.State_Group__c);
			set_CoverageTypes.add(objUserSkill.Coverage_Type__c);
		}

		if (!set_States.isEmpty() && !set_CoverageTypes.isEmpty()) {
			blnIsBenefitDesginer = true;

			objUserRole = [
				SELECT Advising_Preferred_Carrier_Play_Count__c, BD_User_Preference_Carrier__c, BD_User_Preference_State__c
				FROM User_Role__c
				WHERE User__c = :idLoggedInUser
			];

			if (objUserRole != null) {
				idUserPreferredCarrier = objUserRole.BD_User_Preference_Carrier__c;
			}
		}
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Get count of Ready for Default Package and Blocked Opporutnities
	 * @Parm        : null
	 * @Return      : null
	 **/
	private void initializeStatistics() {
		intOpptiesInReadyForDefault = 0;
		intOpptiesInBlocked = 0;
		intRecommendationsSentCount = 0;
		dtLatestBlockedTimestamp = null;

		Set<String> set_ValidOpptyStages = new Set<String>{ OpportunityUtil.READY_FOR_DEFAULT_STAGE, OpportunityUtil.ALIGNMENT_COMPLETE_STAGE };

		intOpptiesInReadyForDefault = [
			SELECT COUNT()
			FROM Opportunity
			WHERE StageName IN :set_ValidOpptyStages AND Benefits_Designer__c = :idLoggedInUser AND Advising_Blocked_Reason__c = NULL
		];

		for (AggregateResult objAggregate : [
			SELECT count(Id) countBlocked, max(Last_Blocked_Timestamp__c) latestBlockedTime
			FROM Opportunity
			WHERE StageName IN :set_ValidOpptyStages AND Advising_Blocked_Reason__c != NULL AND Benefits_Designer__c = :idLoggedInUser
		]) {
			intOpptiesInBlocked = Integer.valueOf(objAggregate.get('countBlocked'));
			dtLatestBlockedTimestamp = DateTime.valueOf(objAggregate.get('latestBlockedTime'));
		}

		intRecommendationsSentCount = [
			SELECT COUNT()
			FROM Opportunity
			WHERE Recommendation_Sent_Start__c = TODAY AND Benefits_Designer__c = :idLoggedInUser
		];
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Get Play Mode Configurations
	 * @Parm        : null
	 * @Return      : null
	 **/
	private void fetchPlayModeConfigurations() {
		map_BDPlayModeConfig = new Map<String, String>();

		for (Advising_BenOps_Playmode_Config__mdt objConfig : [
			SELECT Filter_Type__c, Filter_Value__c
			FROM Advising_BenOps_Playmode_Config__mdt
			WHERE Active__c = TRUE AND Role_Name__c = :FWManageRoleUtil.ROLE_BENEFITS_DESIGNER
		]) {
			map_BDPlayModeConfig.put(objConfig.Filter_Type__c, objConfig.Filter_Value__c);
		}
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Play Eligible Opportunitites
	 * @Parm        : null
	 * @Return      : null
	 **/
	public void playOpportunities() {
		String strQuery;
		Integer intIterator = 1;
		List<Opportunity> list_Opportunities = new List<Opportunity>();
		Map<Id, Opportunity> map_OpportunitiesToUpdate = new Map<Id, Opportunity>();

		Set<Id> set_EligibleOpportunities = new Set<Id>();

		Decimal dcMaxPlayCount = map_BDPlayModeConfig.containsKey(FWManageRoleUtil.SAME_CARRIER_PLAY_COUNT_FILTER)
			? Decimal.valueOf(map_BDPlayModeConfig.get(FWManageRoleUtil.SAME_CARRIER_PLAY_COUNT_FILTER))
			: 5;

		if (blnIsBenefitDesginer != true || blnPlayModeConfigComplete != true) {
			return;
		}
		try {
			while (intIterator <= 2) {
				//Bucket 1
				if (intIterator == 1) {
					if (String.isNotBlank(idUserPreferredCarrier)) {
						strQuery = getQuery(1, true, dcMaxPlayCount);
						list_Opportunities = Database.query(strQuery);
					}

					if (String.isBlank(idUserPreferredCarrier) || list_Opportunities.isEmpty()) {
						strQuery = getQuery(1, false, dcMaxPlayCount);
						list_Opportunities = Database.query(strQuery);
					}

					if (!list_Opportunities.isEmpty()) {
						set_EligibleOpportunities = checkEligibleOpportunities(list_Opportunities, 1);

						if (!set_EligibleOpportunities.isEmpty()) {
							break;
						}
					}
				}

				//Bucket 2
				if (intIterator == 2) {
					if (String.isNotBlank(idUserPreferredCarrier)) {
						strQuery = getQuery(2, true, dcMaxPlayCount);
						list_Opportunities = Database.query(strQuery);
					}

					if (String.isBlank(idUserPreferredCarrier) || list_Opportunities.isEmpty()) {
						strQuery = getQuery(2, false, dcMaxPlayCount);
						list_Opportunities = Database.query(strQuery);
					}

					if (!list_Opportunities.isEmpty()) {
						set_EligibleOpportunities = checkEligibleOpportunities(list_Opportunities, 2);

						if (!set_EligibleOpportunities.isEmpty()) {
							break;
						}
					}
				}

				intIterator++;
			}

			if (set_EligibleOpportunities.isEmpty()) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, MESSAGE_NO_OPPTY));
				return;
			}

			strAssignedOpportunityIds = '';
			strAssignedOpportunityNames = '';
			list_Opportunities = null;
			try {
				list_Opportunities = [
					SELECT
						OwnerId,
						Name,
						Benefits_Designer__c,
						Owner_Role_Name__c,
						UW_Carrier_Previous_Year__r.Carrier_Unique_Name__c,
						UW_State_PY__c,
						(SELECT OwnerId, Name, Benefits_Designer__c, Owner_Role_Name__c FROM Opportunities__r)
					FROM Opportunity
					WHERE Id IN :set_EligibleOpportunities AND Benefits_Designer__c = NULL
					FOR UPDATE
				];
			} catch (Exception objSOQLException) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, MESSAGE_PLAY_AGAIN));
				return;
			}

			if (!list_Opportunities.isEmpty()) {
				for (Opportunity objOpp : list_Opportunities) {
					if (String.isBlank(objOpp.Owner_Role_Name__c)) {
						objOpp.OwnerId = idLoggedInUser;
						objOpp.Owner_Role_Name__c = FWManageRoleUtil.ROLE_BENEFITS_DESIGNER;
					}
					objOpp.Benefits_Designer__c = idLoggedInUser;
					objOpp.Benefits_Designer_Assignment_Timestamp__c = System.now();

					map_OpportunitiesToUpdate.put(objOpp.Id, objOpp);
					strAssignedOpportunityIds += objOpp.Id + ',';
					strAssignedOpportunityNames += objOpp.Name + ',';

					if (!objOpp.Opportunities__r.isEmpty()) {
						for (Opportunity objChildOpp : objOpp.Opportunities__r) {
							objChildOpp.OwnerId = objOpp.OwnerId;
							objChildOpp.Owner_Role_Name__c = objOpp.Owner_Role_Name__c;
							objChildOpp.Benefits_Designer__c = objOpp.Benefits_Designer__c;
							objChildOpp.Benefits_Designer_Assignment_Timestamp__c = System.now();

							map_OpportunitiesToUpdate.put(objChildOpp.Id, objChildOpp);

							strAssignedOpportunityIds += objChildOpp.Id + ',';
							strAssignedOpportunityNames += objChildOpp.Name + ',';
						}
					}
				}

				if (!map_OpportunitiesToUpdate.isEmpty()) {
					update map_OpportunitiesToUpdate.values();
				}

				//Update Carrier and State Preferences
				if (idUserPreferredCarrier != list_Opportunities[0].UW_Carrier_Previous_Year__c) {
					objUserRole.BD_User_Preference_Carrier__c = list_Opportunities[0].UW_Carrier_Previous_Year__c;
					objUserRole.BD_User_Preference_State__c = list_Opportunities[0].UW_State_PY__c;
					objUserRole.Advising_Preferred_Carrier_Play_Count__c = 0;
				}

				objUserRole.Advising_Preferred_Carrier_Play_Count__c = objUserRole.Advising_Preferred_Carrier_Play_Count__c + 1;

				update objUserRole;

				strAssignedOpportunityIds = strAssignedOpportunityIds.removeEnd(',');
				strAssignedOpportunityNames = strAssignedOpportunityNames.removeEnd(',');
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, MESSAGE_PLAY_AGAIN));
				return;
			}
			initializeStatistics();
		} catch (Exception objExc) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, objExc.getMessage()));
			return;
		}
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Check Opporutnity Eligibility based on Coverage Type
	 * @Parm        : list_Opportunities - List of Opportunities
	 * 				  intBucket- bucket size
	 * @Return      : set of Opportunites Ids
	 **/
	private Set<Id> checkEligibleOpportunities(List<Opportunity> list_Opportunities, Integer intBucket) {
		Set<Id> set_EligibleOpportunityIds = new Set<Id>();

		Integer intBatchSize = 1;

		if (intBucket == 1 && map_BDPlayModeConfig.containsKey(FWManageRoleUtil.BUCKET1SIZE_FILTER)) {
			intBatchSize = Integer.valueOf(map_BDPlayModeConfig.get(FWManageRoleUtil.BUCKET1SIZE_FILTER));
		} else if (intBucket == 2 && map_BDPlayModeConfig.containsKey(FWManageRoleUtil.BUCKET2SIZE_FILTER)) {
			intBatchSize = Integer.valueOf(map_BDPlayModeConfig.get(FWManageRoleUtil.BUCKET2SIZE_FILTER));
		}

		Id idCarrier;
		for (Opportunity objOpp : list_Opportunities) {
			if (set_EligibleOpportunityIds.size() >= intBatchSize) {
				break;
			}

			if (!objOpp.Opportunities__r.isEmpty()) {
				continue;
			}

			if (objOpp.Medical_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_MEDICAL)) {
				continue;
			}

			if (objOpp.Dental_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_DENTAL)) {
				continue;
			}

			if (objOpp.Vision_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_VISION)) {
				continue;
			}

			if (objOpp.Life_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_LIFE)) {
				continue;
			}

			if (objOpp.Short_Term_Disability_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_STD)) {
				continue;
			}

			if (objOpp.Long_Term_Disability_Renewal__c && !set_CoverageTypes.contains(FWManageRoleUtil.COVERAGE_TYPE_LTD)) {
				continue;
			}

			if (idCarrier == null) {
				idCarrier = objOpp.UW_Carrier_Previous_Year__c;
			}

			if (idCarrier == objOpp.UW_Carrier_Previous_Year__c) {
				set_EligibleOpportunityIds.add(objOpp.Id);
			}
		}

		return set_EligibleOpportunityIds;
	}

	/**
	 * @Author      : Neha Dabas
	 * @Description : Form Opportunity Query based on bucket, User Preference and Same Carrier Play count
	 * @Parm        : intBucket- bucket size
	 * 				  blnWithCarrierPreference - Carrier Preference is set or not
	 * 				  dcMaxPlayCount - max play count of user
	 * @Return      : String - Query
	 **/
	private String getQuery(Integer intBucket, Boolean blnWithCarrierPreference, Decimal dcMaxPlayCount) {
		String strQuery = map_BDPlayModeConfig.get(FWManageRoleUtil.BASE_FILTER) + ' ' + map_BDPlayModeConfig.get(FWManageRoleUtil.BASE_WHERE_FILTER);

		if (intBucket == 1) {
			if (map_BDPlayModeConfig.containsKey(FWManageRoleUtil.BUCKET1_FILTER)) {
				strQuery += ' ' + map_BDPlayModeConfig.get(FWManageRoleUtil.BUCKET1_FILTER);
			}
		}

		if (blnWithCarrierPreference == true) {
			if (objUserRole.Advising_Preferred_Carrier_Play_Count__c >= dcMaxPlayCount) {
				strQuery += map_BDPlayModeConfig.containsKey(FWManageRoleUtil.CARRIER_CHANGE_WHERE_FILTER) ? ' ' + map_BDPlayModeConfig.get(FWManageRoleUtil.CARRIER_CHANGE_WHERE_FILTER) : '';
			} else {
				strQuery += map_BDPlayModeConfig.containsKey(FWManageRoleUtil.CARRIERWHERE_FILTER) ? ' ' + map_BDPlayModeConfig.get(FWManageRoleUtil.CARRIERWHERE_FILTER) : '';
			}
		}

		if (map_BDPlayModeConfig.containsKey(FWManageRoleUtil.ORDERBY_FILTER)) {
			strQuery += ' ' + map_BDPlayModeConfig.get(FWManageRoleUtil.ORDERBY_FILTER);
		}

		return strQuery;
	}
}