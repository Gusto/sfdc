/**
* @description Apex controller class for omniSkillsBacklog LWC
* @author      Ankit
* @date        18 Nov 2024
* @see         OmniBacklogControllerTest
*/
public class OmniBacklogController {
	public static final Schema.SObjectType TYPE_CASE = Case.SObjectType;
	public static final Schema.SObjectType TYPE_CHAT = LiveChatTranscript.SObjectType;
	/**
	 * @author:         Ankit CS
	 * @description:    Retrieve the list of Skills, Pillars, Sub-pillars and WFM queues
	*/
	@AuraEnabled(cacheable=true)
	public static FiltersWrapper getFilters() {
		FiltersWrapper objWrapper = new FiltersWrapper();
		List<Skill> list_TempSkills = new List<Skill>();
		List<String> list_TempPillars = new List<String>();
		List<String> list_TempSubPillars = new List<String>();
		List<String> list_TempWFMQueues = new List<String>();
		List<LiveChatButton> list_TempChatButtons = new List<LiveChatButton>();
		List<String> list_SkillTypes = new List<String>{
			'Specialization', 
			'Engagement_Alert', 
			'Persona',
			'Case_Type', 
			'Company_Size', 
			'Support_Level', 
			'Team', 
			'QA_Skill'
		};
		List<String> list_ExcludeChatButtons = new List<String>{
			'NOT IN USE'
		};

		try {
			for (Skill objSkill : [SELECT Id, DeveloperName, MasterLabel, Type.DeveloperName FROM Skill WHERE Type.DeveloperName IN :list_SkillTypes OR DeveloperName = 'Gusto_Global' ORDER BY Type.DeveloperName]) {
				if (!objSkill.MasterLabel.contains('deprecated')) {
					list_TempSkills.add(objSkill);
				}
			}
			
			for (Case_Pillar_Mapping__c objMapping : Case_Pillar_Mapping__c.getAll().values()) {
				if (String.isNotBlank(objMapping.Pillar__c) && !list_TempPillars.contains(objMapping.Pillar__c)) {
					list_TempPillars.add(objMapping.Pillar__c);
				}
				
				if (String.isNotBlank(objMapping.Sub_Pillar__c) && !list_TempSubPillars.contains(objMapping.Sub_Pillar__c)) {
					list_TempSubPillars.add(objMapping.Sub_Pillar__c);
				}
				
				if (String.isNotBlank(objMapping.WFM_Queue_Tag__c) && !list_TempWFMQueues.contains(objMapping.WFM_Queue_Tag__c)) {
					list_TempWFMQueues.add(objMapping.WFM_Queue_Tag__c);
				}
			}

			for (LiveChatButton objChatButton : [SELECT Id, DeveloperName, MasterLabel, Queue.Name FROM LiveChatButton ORDER BY MasterLabel]) {
				if (!list_ExcludeChatButtons.contains(objChatButton.MasterLabel) && !objChatButton.MasterLabel.containsIgnoreCase('test')) {
					list_TempChatButtons.add(objChatButton);
				}
			}
			
			objWrapper.list_Skills = list_TempSkills;
			objWrapper.list_Pillars = list_TempPillars;
			objWrapper.list_SubPillars = list_TempSubPillars;
			objWrapper.list_WFMQueues = list_TempWFMQueues;
			objWrapper.list_ChatButtons = list_TempChatButtons;
			return objWrapper;
		} catch (Exception objException) {
			ExceptionLogUtil.logException(
				'OmniBacklogController', 
				'getFilters', 
				'Exception On Line ' + objException.getLineNumber() + '-' + objException.getMessage(), 
				objException.getStackTraceString()
			);
			return objWrapper;
		}			
	}
	
	/**
	 * @author:         Ankit CS
	 * @description:    Retrieve the list of PSRs based on the selected filters
	 * @param:          list_SkillIds - List of selected Skills,
	 *                  list_Pillars - List of selected Pillars, 
	 *                  list_SubPillars - List of selected Sub-Pillars, 
	 *                  list_WFMQueues - List of selected WFM Queues, 
	 *                  strCaseNumber - Case number entered, 
	 *                  strPriority - Priority entered
	 * @return:         List<PendingRoutingWrapper> - List of PendingRoutingWrapper
	*/
	@AuraEnabled(cacheable=true)
	public static List<PendingRoutingWrapper> getBacklogItems(
		List<Id> list_SkillIds, 
		List<String> list_Pillars, 
		List<String> list_SubPillars, 
		List<String> list_WFMQueues, 
		String strCaseNumber, 
		String strPriority, 
		String strOwnerId,
		String strChatButtonId
	) {
		List<PendingServiceRouting> list_PSRs;
		List<PendingRoutingWrapper> list_Results = new List<PendingRoutingWrapper>();
		Map<Id, User> map_UserById = new Map<Id, User>();
		Map<Id, Case> map_CaseById = new Map<Id, Case>();
		Map<Id, LiveChatTranscript> map_ChatById = new Map<Id, LiveChatTranscript>();
		Set<Id> set_OwnerIds = new Set<Id>();
		Set<Id> set_CaseIds = new Set<Id>();
		Set<Id> set_ChatIds = new Set<Id>();
		strCaseNumber = strCaseNumber.trim();
		strPriority = strPriority.trim();
		String strQuery = 'SELECT Id, WorkItemId, WorkItem.OwnerId, CreatedDate, RoutingPriority,'
			+ '(SELECT Skill.MasterLabel, SkillLevel FROM SkillRequirements)'
			+ 'FROM PendingServiceRouting ';
		String strWhereClause = '';
		if (!list_SkillIds.isEmpty()) {
			strWhereClause += ' WHERE Id IN (SELECT RelatedRecordId FROM SkillRequirement WHERE SkillId = :list_SkillIds)';
		}

		if (String.isNotBlank(strPriority)) {
			Integer intPriority = Integer.valueOf(strPriority);
			if (String.isBlank(strWhereClause)) {
				strWhereClause += ' WHERE RoutingPriority = :intPriority';
			} else {
				strWhereClause += ' AND RoutingPriority = :intPriority';
			}
		}

		strQuery += strWhereClause + ' ORDER BY CreatedDate';
		list_PSRs = Database.query(strQuery);

		for (PendingServiceRouting objPSR : list_PSRs) {
			if (objPSR.WorkItemId.getSobjectType() == TYPE_CASE) {
				set_CaseIds.add(objPSR.WorkItemId);
			} else if (objPSR.WorkItemId.getSobjectType() == TYPE_CHAT) {
				set_ChatIds.add(objPSR.WorkItemId);
			}
		}

		strQuery = '';
		strWhereClause = '';
		strQuery = 'SELECT Id, CaseNumber, First_Response_Time__c, Case_Pillar__c, Sub_Pillar__c, WFM_Queue_Tag__c,'
			+ ' OwnerId, Owner.IsActive, Owner.Name FROM Case WHERE Id IN :set_CaseIds ';
		
		if (!list_Pillars.isEmpty()) {
			strWhereClause += ' AND Case_Pillar__c IN :list_Pillars';
		}
		
		if (!list_SubPillars.isEmpty()) {
			strWhereClause += ' AND Sub_Pillar__c IN :list_SubPillars';
		}
		
		if (!list_WFMQueues.isEmpty()) {
			strWhereClause += ' AND WFM_Queue_Tag__c IN :list_WFMQueues';
		}
		
		if (String.isNotBlank(strCaseNumber)) {
			strWhereClause += ' AND CaseNumber = :strCaseNumber';
		}

		if (String.isNotBlank(strOwnerId)) {
			strWhereClause += ' AND OwnerId = :strOwnerId';
		}

		strQuery += strWhereClause;
		map_CaseById = new Map<Id, Case>((List<Case>)Database.query(strQuery));

		for (Case objCase : map_CaseById.values()) {
			if (String.valueOf(objCase.OwnerId).startsWith(CaseUtils.USER_ID_PREFIX)) {
				set_OwnerIds.add(objCase.OwnerId);
			}
		}

		strQuery = '';
		strWhereClause = '';
		strQuery = 'SELECT Id, Name, WFM_Queue_Tag__c, Owner.Name FROM LiveChatTranscript WHERE Id IN :set_ChatIds ';
		
		if (!list_WFMQueues.isEmpty()) {
			strWhereClause += ' AND WFM_Queue_Tag__c IN :list_WFMQueues';
		}

		if (String.isNotBlank(strOwnerId)) {
			strWhereClause += ' AND OwnerId = :strOwnerId';
		}

		if (String.isNotBlank(strChatButtonId)) {
			strWhereClause += ' AND LiveChatButtonId = :strChatButtonId';
		}

		strQuery += strWhereClause;
		map_ChatById = new Map<Id, LiveChatTranscript>((List<LiveChatTranscript>)Database.query(strQuery));

		for (LiveChatTranscript objChat : map_ChatById.values()) {
			if (String.valueOf(objChat.OwnerId).startsWith(CaseUtils.USER_ID_PREFIX)) {
				set_OwnerIds.add(objChat.OwnerId);
			}
		}
		
		if (!set_OwnerIds.isEmpty()) {
			map_UserById = new Map<Id, User>([SELECT Id, IsActive, Name, PE__c FROM User WHERE Id IN :set_OwnerIds]);
		}
		
		for (PendingServiceRouting objPSR : list_PSRs) {
			if (!map_CaseById.containsKey(objPSR.WorkItemId) && !map_ChatById.containsKey(objPSR.WorkItemId)) {
				continue;
			}

			PendingRoutingWrapper objWrapper = new PendingRoutingWrapper();
			objWrapper.idCase = objPSR.WorkItemId;
			objWrapper.intPriority = Integer.valueOf(objPSR.RoutingPriority);
			objWrapper.dtmRequestedTime = objPSR.CreatedDate;
			if (map_UserById.containsKey(objPSR.WorkItem.OwnerId)) {
				objWrapper.strOwnerActive = map_UserById.get(objPSR.WorkItem.OwnerId).IsActive
					? 'Yes'
					: 'No';
				objWrapper.strPE = map_UserById.get(objPSR.WorkItem.OwnerId).PE__c;
			}

			if (objPSR.WorkItemId.getSobjectType() == TYPE_CASE && map_CaseById.containsKey(objPSR.WorkItemId)) {
				objWrapper.dtmFirstResponse = map_CaseById.get(objPSR.WorkItemId).First_Response_Time__c;
				objWrapper.strCaseNumber = map_CaseById.get(objPSR.WorkItemId).CaseNumber;
				objWrapper.strPillar = map_CaseById.get(objPSR.WorkItemId).Case_Pillar__c ;
				objWrapper.strSubPillar = map_CaseById.get(objPSR.WorkItemId).Sub_Pillar__c;
				objWrapper.strWFMQueue = map_CaseById.get(objPSR.WorkItemId).WFM_Queue_Tag__c;
				objWrapper.strOwner = map_CaseById.get(objPSR.WorkItemId).Owner.Name;
			} else if (objPSR.WorkItemId.getSobjectType() == TYPE_CHAT && map_ChatById.containsKey(objPSR.WorkItemId)) {
				objWrapper.strCaseNumber = map_ChatById.get(objPSR.WorkItemId).Name;
				objWrapper.strWFMQueue = map_ChatById.get(objPSR.WorkItemId).WFM_Queue_Tag__c;
				objWrapper.strOwner = map_ChatById.get(objPSR.WorkItemId).Owner.Name;
			}

			objWrapper.skills = new List<String>();
			for (SkillRequirement skillReq : objPSR.SkillRequirements) {
				Integer intSkillLevel = skillReq.SkillLevel != null
					? Integer.valueOf(skillReq.SkillLevel)
					: 0;
				objWrapper.skills.add('' + skillReq.Skill.MasterLabel + ' (' + intSkillLevel + ')');
			}
			
			list_Results.add(objWrapper);
		}

		return list_Results;       
	}
	
	/**
	 * @description Wrapper for the columns in the data table
	 * @author      Ankit
	 */
	public class PendingRoutingWrapper {
		@AuraEnabled public Id idCase;
		@AuraEnabled public String strCaseNumber;
		@AuraEnabled public Integer intPriority;
		@AuraEnabled public String strPillar;
		@AuraEnabled public String strSubPillar;
		@AuraEnabled public String strWFMQueue;
		@AuraEnabled public String strOwner;
		@AuraEnabled public DateTime dtmFirstResponse;
		@AuraEnabled public String strOwnerActive;
		@AuraEnabled public String strPE;
		@AuraEnabled public List<String> skills;
		@AuraEnabled public DateTime dtmRequestedTime;
	}
	
	/**
	 * @description Wrapper for the filters in the LWC
	 * @author      Ankit
	 * @date        18 Nov 2024
	 */
	public class FiltersWrapper {
		@AuraEnabled public List<Skill> list_Skills;
		@AuraEnabled public List<String> list_Pillars;
		@AuraEnabled public List<String> list_SubPillars;
		@AuraEnabled public List<String> list_WFMQueues;
		@AuraEnabled public List<LiveChatButton> list_ChatButtons;
	}
}