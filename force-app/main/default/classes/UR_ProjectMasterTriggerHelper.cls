/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* Created by............: <<Lirik>>
* Test Classes----------: <<UR_ProjectMasterTriggerHelper>>
* Description...........: <<Helper Class Of UR_ProjectMasterTgr trigger>>
*-------------------------------------------------------------------------------*/

public with sharing class UR_ProjectMasterTriggerHelper {
   public static boolean skipTrigger = false;
 
   public void OnBeforeInsert(List<Research_Project_Master__c> newProjectMaster){ 
  		PopulateData(newProjectMaster,false,null);
   }
     
   public void OnAfterInsert(Map<ID, Research_Project_Master__c> newProjectMasterMap) {
		 UR_UtilityCtrl.getAdminRoleHierarchy(newProjectMasterMap.values());
   }
    
    public void OnBeforeUpdate(Map<ID, Research_Project_Master__c>  oldProjectMasterMap, Map<ID, Research_Project_Master__c> newProjectMasterMap){
		PopulateData(newProjectMasterMap.values(),true,oldProjectMasterMap);
    }
    
    public void OnAfterUpdate(Map<ID, Research_Project_Master__c>  oldProjectMasterMap, Map<ID, Research_Project_Master__c> newProjectMasterMap) {
    	List<Research_Project_Master__c> updatedOwnerList = new List<Research_Project_Master__c>();
		for(Research_Project_Master__c rpm:newProjectMasterMap.values()){
			if(oldProjectMasterMap.get(rpm.Id).OwnerId != rpm.OwnerId){
				updatedOwnerList.add(rpm);
			}
		}
		if(updatedOwnerList.size()>0){
			UR_UtilityCtrl.getAdminRoleHierarchy(updatedOwnerList);
		}
    }
    
    public void OnBeforeDelete(Research_Project_Master__c[] projectMasterToDelete, Map<ID, Research_Project_Master__c> oldProjectMasterMap){
		for(Research_Project_Master__c obj : projectMasterToDelete){
			if('Initiated' != obj.Project_Status__c && 'Gusto UX Research Admin'!=UR_UtilityCtrl.loginUserProfileName){
			  obj.adderror('Gusto UX Research Admin profile, user can delete ' +obj.Name+ ' record.');
			}
		 }
    }
    
   /* public void OnAfterDelete(Research_Project_Master__c[] deletedProjectMaster, Map<ID, Research_Project_Master__c> oldProjectMasterMap){
        
    }
    
    public void OnUndelete(Research_Project_Master__c[] restoredProjectMaster){
      
    }*/
    
    public void PopulateData(List<Research_Project_Master__c> lstResearchMaster, boolean isUpdate,Map<ID, Research_Project_Master__c>  oldProjectMasterMap){
        Research_Configuration__c objResearch=new Research_Configuration__c();
		objResearch=UR_UtilityCtrl.RetriveResearchConfiguration();
		//Update maximum number of aprticipanty in case of blank from project configuration 
		for(Research_Project_Master__c rpm:lstResearchMaster){
			rpm.Researcher_Name__c=rpm.OwnerId;
			if(rpm.Number_of_Allowed_Participant__c==null || (isUpdate==true && oldProjectMasterMap!=null && rpm.Type_of_Research__c!=oldProjectMasterMap.get(rpm.id).Type_of_Research__c)){
				if (rpm.Type_of_Research__c == UR_NewEditProjectCtrl.UNMODERATED_SURVEY) {
					rpm.Number_of_Allowed_Participant__c=objResearch.Max_Number_Of_Participants_High_Limit__c;
				}else{
					rpm.Number_of_Allowed_Participant__c=objResearch.Max_Number_Of_Studies_Participants__c;
				}
			}
			if(rpm.NDA_URL__c==null){
				rpm.NDA_URL__c=objResearch.NDA_URL__c;
			}
			
			//Update addition additional approval 
            if(isUpdate==true){
                if(rpm.Additional_Participant_Status__c=='Approved' && rpm.Number_of_Expected_Participant__c!=null){
                    rpm.Number_of_Allowed_Participant__c = rpm.Number_of_Allowed_Participant__c + rpm.Number_of_Expected_Participant__c;
                    rpm.Number_of_Expected_Participant__c=null;
                }
            }
		}
    }

}