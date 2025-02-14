/**
* @description Apex controller class for omniSkillsBacklog LWC
* @author      Ankit
* @date        18 Nov 2024
* @see         OmniBacklogControllerTest
*/
public class OmniBacklogController {
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
			
			objWrapper.list_Skills = list_TempSkills;
			objWrapper.list_Pillars = list_TempPillars;
			objWrapper.list_SubPillars = list_TempSubPillars;
			objWrapper.list_WFMQueues = list_TempWFMQueues;
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
	public static List<PendingRoutingWrapper> getBacklogItems(List<Id> list_SkillIds, List<String> list_Pillars, List<String> list_SubPillars, List<String> list_WFMQueues, String strCaseNumber, String strPriority) {
		List<PendingServiceRouting> list_PSRs;
		List<PendingRoutingWrapper> list_Results = new List<PendingRoutingWrapper>();
		Map<Id, User> map_UserById = new Map<Id, User>();
		Set<Id> set_OwnerIds = new Set<Id>();
		strCaseNumber = strCaseNumber.trim();
		strPriority = strPriority.trim();
		String strQuery = 'SELECT Id, WorkItemId, CreatedDate, WorkItem.CaseNumber,'
			+ 'WorkItem.First_Response_Time__c, WorkItem.Case_Pillar__c, WorkItem.Sub_Pillar__c,'
			+ 'WorkItem.WFM_Queue_Tag__c, WorkItem.OwnerId, WorkItem.Owner.IsActive, RoutingPriority,'
			+ '(SELECT Skill.MasterLabel, SkillLevel FROM SkillRequirements)'
			+ 'FROM PendingServiceRouting WHERE WorkItem.CaseNumber != null';
		String strWhereClause = '';
		if (!list_SkillIds.isEmpty()) {
			strWhereClause += ' AND Id IN (SELECT RelatedRecordId  FROM SkillRequirement WHERE SkillId = :list_SkillIds)';
		}
		
		if (!list_Pillars.isEmpty()) {
			strWhereClause += ' AND WorkItem.Case_Pillar__c IN :list_Pillars';
		}
		
		if (!list_SubPillars.isEmpty()) {
			strWhereClause += ' AND WorkItem.Sub_Pillar__c IN :list_SubPillars';
		}
		
		if (!list_WFMQueues.isEmpty()) {
			strWhereClause += ' AND WorkItem.WFM_Queue_Tag__c IN :list_WFMQueues';
		}
		
		if (String.isNotBlank(strCaseNumber)) {
			strWhereClause += ' AND WorkItem.CaseNumber = :strCaseNumber';
		}
		
		if (String.isNotBlank(strPriority)) {
			Integer intPriority = Integer.valueOf(strPriority);
			strWhereClause += ' AND RoutingPriority = :intPriority';
		}
		
		strQuery += strWhereClause;
		list_PSRs = Database.query(strQuery);
		
		for (PendingServiceRouting objPSR : list_PSRs) {
			if (String.valueOf(objPSR.WorkItem.OwnerId).startsWith(CaseUtils.USER_ID_PREFIX)) {
				set_OwnerIds.add(objPSR.WorkItem.OwnerId);
			}
		}
		
		if (!set_OwnerIds.isEmpty()) {
			map_UserById = new Map<Id, User>([SELECT Id, IsActive, Name, PE__c FROM User WHERE Id IN :set_OwnerIds]);
		}
		
		for (PendingServiceRouting objPSR : list_PSRs) {
			PendingRoutingWrapper objWrapper = new PendingRoutingWrapper();
			objWrapper.idCase = objPSR.WorkItemId;
			objWrapper.dtmFirstResponse = objPSR.WorkItem.First_Response_Time__c;
			objWrapper.strCaseNumber = objPSR.WorkItem.CaseNumber;
			objWrapper.intPriority = Integer.valueOf(objPSR.RoutingPriority);
			objWrapper.strPillar = objPSR.WorkItem.Case_Pillar__c ;
			objWrapper.strSubPillar = objPSR.WorkItem.Sub_Pillar__c;
			objWrapper.strWFMQueue = objPSR.WorkItem.WFM_Queue_Tag__c;
			if (map_UserById.containsKey(objPSR.WorkItem.OwnerId)) {
				objWrapper.strOwnerActive = map_UserById.get(objPSR.WorkItem.OwnerId).IsActive
					? 'Yes'
					: 'No';
				objWrapper.strPE = map_UserById.get(objPSR.WorkItem.OwnerId).PE__c;
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
		@AuraEnabled public DateTime dtmFirstResponse;
		@AuraEnabled public String strOwnerActive;
		@AuraEnabled public String strPE;
		@AuraEnabled public List<String> skills;
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
	}
}