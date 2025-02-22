/**
* @description  Helper class for SkillRequirementTrigger
* @author       Ankit C
* @date         08-06-2024
* @see          SkillRequirementTriggerTest
**/
public class SkillRequirementTriggerHelper {
	public static Boolean blnSkipTrigger = false;
	public static Boolean blnThrowException = false;
	Map<Id, Case> map_CaseById = new Map<Id, Case>();
	Map<Id, Skill> map_SkillById = new Map<Id, Skill>();
	Map<Id, LiveChatTranscript> map_ChatById = new Map<Id, LiveChatTranscript>();
	Map<Id, List<SkillRequirement>> map_SkillsByWorkItemId = new Map<Id, List<SkillRequirement>>();
	
	/**
	 * @description Handle afterInsert context
	 * @author      Ankit C
	 * @param       list_SkillRequirements - List of SkillRequirements from trigger.new
	 * @return      NA
	**/
	public void processAfterInsert(List<SkillRequirement> list_SkillRequirements) {
		createCollectionsAfter(list_SkillRequirements);
		if (!map_SkillsByWorkItemId.isEmpty()) {
			for (Id idWorkItem : map_SkillsByWorkItemId.keySet()) {
				if (map_CaseById.containsKey(idWorkItem)) {
					Case objCase = map_CaseById.get(idWorkItem);
					for (SkillRequirement objSkillReq : map_SkillsByWorkItemId.get(idWorkItem)) {
						Skill objSkill = map_SkillById.get(objSkillReq.SkillId);
						switch on objSkill.Type.DeveloperName {
							when 'Case_Type' {
								objCase.Type = objSkill.MasterLabel;
							}	
							when 'Company_Size' {		
								objCase.Company_Size__c = objSkill.MasterLabel;
							}
							when 'Persona' {		
								objCase.Persona__c = objSkill.MasterLabel;
							}
							when 'Specialization' {		  
								objCase.Specialization__c = objSkill.MasterLabel;
							}
							when 'Support_Level' {		  
								objCase.Support_Level__c = objSkill.MasterLabel;
							}
							when 'Engagement_Alert' {		  
								objCase.Engagement_Alert__c = objSkill.MasterLabel;
							}
						}
						
						if (objSkill.DeveloperName == 'Gusto_Global') {
							objCase.Type = objSkill.MasterLabel;
						}
					}
				} else if (map_ChatById.containsKey(idWorkItem)) {
					LiveChatTranscript objChat = map_ChatById.get(idWorkItem);
					for (SkillRequirement objSkillReq : map_SkillsByWorkItemId.get(idWorkItem)) {
						Skill objSkill = map_SkillById.get(objSkillReq.SkillId);
						switch on objSkill.Type.DeveloperName {
							when 'Case_Type' {
								objChat.Request_Type__c = objSkill.MasterLabel;
							}	
							when 'Company_Size' {		
								objChat.Company_Size__c = objSkill.MasterLabel;
							}
							when 'Persona' {		
								objChat.Persona__c = objSkill.MasterLabel;
							}
							when 'Support_Level' {		  
								objChat.Support_Level__c = objSkill.MasterLabel;
							}
						}
					}
				}
			}
			
			if (!map_CaseById.isEmpty()) {
				Utils.doDMLAndReturnAllErrors('Update', 'Id', map_CaseById.values(), false, true, 'SkillRequirementTriggerHelper.processAfterInsert()');
			}
			
			if (!map_ChatById.isEmpty()) {
				Utils.doDMLAndReturnAllErrors('Update', 'Id', map_ChatById.values(), false, true, 'SkillRequirementTriggerHelper.processAfterInsert()');
			}
		}
	}
	
	/**
	 * @description Create collection variables needed for the after context
	 * @author      Ankit C
	 * @param       list_SkillRequirements - List of SkillRequirements from trigger.new
	 * @return      NA
	**/
	private void createCollectionsAfter(List<SkillRequirement> list_SkillRequirements) {
		Set<Id> set_PSRIds = new Set<Id>();
		Set<Id> setCaseIds = new Set<Id>();
		Set<Id> set_ChatIds = new Set<Id>();
		Set<Id> set_SkillIds = new Set<Id>();
		for (SkillRequirement objSkill : list_SkillRequirements) {
			set_PSRIds.add(objSkill.RelatedRecordId);
		}
		
		if (!set_PSRIds.isEmpty()) {
			String strQuery = 'SELECT Id, WorkItemId, (SELECT Id, SkillId FROM SkillRequirements) FROM PendingServiceRouting WHERE Id IN :set_PSRIds';
			if (!Test.isRunningTest()) {
				strQuery += ' AND IsTransfer = true';
			}
			List<PendingServiceRouting> list_PSRs = Database.query(strQuery);
			for (PendingServiceRouting objPSR : list_PSRs) {
				String strObjectType = objPSR.WorkItemId.getSObjectType().getDescribe().getName();
				if (strObjectType == 'Case') {
					setCaseIds.add(objPSR.WorkItemId);
				} else if (strObjectType == 'LiveChatTranscript') {
					set_ChatIds.add(objPSR.WorkItemId);
				}
				
				if (!objPSR.SkillRequirements.isEmpty()) {
					map_SkillsByWorkItemId.put(objPSR.WorkItemId, objPSR.SkillRequirements);
					for (SkillRequirement objSkill : objPSR.SkillRequirements) {
						set_SkillIds.add(objSkill.SkillId);
					}
				}
			}
			
			map_SkillById = new Map<Id, Skill>([SELECT Id, DeveloperName, MasterLabel, Type.DeveloperName FROM Skill WHERE Id IN :set_SkillIds]);
			if (!set_ChatIds.isEmpty()) {
				map_ChatById = new Map<Id, LiveChatTranscript>([SELECT Id FROM LiveChatTranscript WHERE Id IN :set_ChatIds AND RecordTypeId = :Utils.CHAT_EXTERNAL_RT_ID]);
			}
			
			if (!setCaseIds.isEmpty()) {
				map_CaseById = new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN :setCaseIds AND IsClosed = false AND RecordTypeId = :CaseUtils.RECTYPE_ENGAGEMENT]);
			}
		}
	}

	/**
	 * @description Handle beforeInsert context, ensure the chat and case transfer skill level is defaulted to level 10
	 * @author      Sirisha K
	 * @param       list_SkillRequirements - List of SkillRequirements from trigger.new
	 * @return      NA
	**/
	public void processBeforeInsert(List<SkillRequirement> list_SkillRequirements) {
		Set<Id> set_PSRIds = new Set<Id>();
		Set<Id> set_skillIds = new Set<Id>();
		Set<Id> set_caseTypeskillIds = new Set<Id>();
		
		for (SkillRequirement objSkill : list_SkillRequirements) {
			set_PSRIds.add(objSkill.RelatedRecordId);
		}
		if (!set_PSRIds.isEmpty()){
        //Querying the associated PSR for the SkillRequirement
			  String strQuery = 'SELECT Id, WorkItemId FROM PendingServiceRouting WHERE Id IN :set_PSRIds';
			  if (!Test.isRunningTest()) {
				  strQuery += ' AND IsTransfer = true';
			  }
			  Map<Id,PendingServiceRouting> map_PSRById = new Map<Id, PendingServiceRouting>();
        for (PendingServiceRouting objPSR : Database.query(strQuery)) {
          map_PSRById.put(objPSR.Id, objPSR);
        }
        //Iterating over new SkillRequirements
        for(SkillRequirement objSkill : list_SkillRequirements) {
          //Check if PSR Id is there map_PSRById map which means the associated PSR has IsTransfer=true
          if (map_PSRById.containsKey(objSkill.RelatedRecordId)) {
					  set_skillIds.add(objSkill.SkillId);
          }
       }
		}
		if(!set_skillIds.isEmpty()){
			//Querying the Skill obeject and it's type to determine the type of the skill 
			String strQuery = 'SELECT Id, Type.DeveloperName from Skill WHERE Id IN :set_skillIds AND Type.DeveloperName = \'Case_Type\' ';
			for (Skill objskill : Database.query(strQuery)) {
        set_caseTypeskillIds.add(objskill.Id);
      }
		}
		if(!set_caseTypeskillIds.isEmpty()){
		  // loop through the trigger.New and check if there are any skills of case_type and default the level to 10 
			for (SkillRequirement objSkillReq : list_SkillRequirements) {
			  if(set_caseTypeskillIds.contains(objSkillReq.SkillId))
					objSkillReq.SkillLevel = 10; 
			}
		}
	}
}