/*------------------------------------------------------------------------------
* Project Name..........: <<Gusto>>
* File..................: <<UR_ExcludedCSVCtrl>>
* Created by............: <<Lirik>>
* Description...........: <<This class is used to show excluded *.CSV records>>
*-------------------------------------------------------------------------------*/
public with sharing class UR_ExcludedCSVCtrl {
    public Research_Project_Master__c ProjectMasterObj {get;set;}
    public Research_Configuration__c objResearch{get;set;}
    public Map<Id, String> csvMap{get;set;}
	
    public UR_ExcludedCSVCtrl(){
        String currentRecordId  = ApexPages.CurrentPage().getparameters().get('projectId'); 
        ProjectMasterObj = new Research_Project_Master__c(id=currentRecordId);
        objResearch = new Research_Configuration__c();
        objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();
		csvMap = new Map<Id, String>();
    }
    
    public void fetchExcludedRecord(){
        String userId = '';
        String employeeId = '';
        Id projectId = ProjectMasterObj.Id;
        Set<String> csvEmailSet = new Set<String>();
        Set<String> csvUserIdSet = new Set<String>();
        Set<String> csvEmployeeIdSet = new Set<String>();
		List<Research_Upload_Info__c> rsUploadObjList = [
			SELECT First_Name__c, Last_Name__c, Opt_Out__c, Opt_Out_Reason__c, Blacklist__c, Email__c, Company_Id__c, Accountant_Firm_Id__c, User_Id__c, Employee_Id__c
			FROM Research_Upload_Info__c
			WHERE Research_Project_Master_Id__c = :projectId
		];
		for(Research_Upload_Info__c rsUploadObj : rsUploadObjList){
            if(String.isNotBlank(rsUploadObj.Email__c)){
                csvEmailSet.add(rsUploadObj.Email__c);
            }if(String.isNotBlank(rsUploadObj.User_Id__c)){
                csvUserIdSet.add(rsUploadObj.User_Id__c);
            }if(String.isNotBlank(rsUploadObj.Employee_Id__c)){
                csvEmployeeIdSet.add(rsUploadObj.Employee_Id__c);
            }
        }
        
		
		Map<String,Research_Project_Detail__c> reserveEmailIdMap = new Map<String,Research_Project_Detail__c>();
		Map<String,Research_Project_Detail__c> reserveUserIdMap = new Map<String,Research_Project_Detail__c>();
		Map<String,Research_Project_Detail__c> reserveEmpIdMap = new Map<String,Research_Project_Detail__c>();
		Map<String,Research_Project_Detail__c> notVisibleEmailIdMap = new Map<String,Research_Project_Detail__c>();
		Map<String,Research_Project_Detail__c> notVisibleUserIdMap = new Map<String,Research_Project_Detail__c>();
		Map<String,Research_Project_Detail__c> notVisibleEmpIdMap = new Map<String,Research_Project_Detail__c>();
			
        String strDaySinceCont='90';
        if(objResearch!=null && objResearch.Days_Since_Last_Contact_High_Limit__c!=null){
            strDaySinceCont = objResearch.Days_Since_Last_Contact_High_Limit__c + '';
        }
        integer daySince=integer.valueof(strDaySinceCont);
        Date modifedDate=Date.today().addDays(-daySince);
        for(Research_Project_Detail__c proDetailObj : [select id, Research_Project_Master__c, Research_Project_Master__r.Name, Contact__c, Contact__r.Email, Contact__r.UR_Recent_Project_Completion_date__c, Research_Project_Master__r.Project_Status__c, Research_Project_Master__r.Project_Start_Date__c, Research_Project_Master__r.Project_End_Date__c,  Research_Project_Master__r.Project_Completion_Date__c, Contact__r.ZP_User_Id__c, Contact__r.Employee_Id__c from Research_Project_Detail__c where  Research_Project_Master__c !=: projectId and (Contact__r.Email IN : csvEmailSet or Contact__r.ZP_User_Id__c IN : csvUserIdSet or Contact__r.Employee_Id__c IN : csvEmployeeIdSet)]){
        
            if('Complete'!= proDetailObj.Research_Project_Master__r.Project_Status__c){
				if(String.isNotBlank(proDetailObj.Contact__r.Email)){
					reserveEmailIdMap.put(proDetailObj.Contact__r.Email, proDetailObj);
				}if(String.isNotBlank(proDetailObj.Contact__r.ZP_User_Id__c)){
					reserveUserIdMap.put(proDetailObj.Contact__r.ZP_User_Id__c, proDetailObj);
				}if(String.isNotBlank(proDetailObj.Contact__r.Employee_Id__c)){
					reserveEmpIdMap.put(proDetailObj.Contact__r.Employee_Id__c, proDetailObj);
				}
            }else if('Complete' == proDetailObj.Research_Project_Master__r.Project_Status__c && 
                 proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c!=null && 
                 proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c > modifedDate){
				 
				 if(String.isNotBlank(proDetailObj.Contact__r.Email)){
					notVisibleEmailIdMap.put(proDetailObj.Contact__r.Email, proDetailObj);
				 }if(String.isNotBlank(proDetailObj.Contact__r.ZP_User_Id__c)){
					notVisibleUserIdMap.put(proDetailObj.Contact__r.ZP_User_Id__c, proDetailObj);
				 }if(String.isNotBlank(proDetailObj.Contact__r.Employee_Id__c)){
					notVisibleEmpIdMap.put(proDetailObj.Contact__r.Employee_Id__c, proDetailObj);
				 }
			}
        }
        
		Boolean isReserved = false;
		Boolean isDisabled = false;
		Boolean isBlackListOptOut = false;
		String errorMsg = '';
		Research_Project_Detail__c projectDetailObj=null;
		String strValue = '';
		for(Research_Upload_Info__c rsUploadObj : rsUploadObjList){
			isReserved = false;
			isDisabled = false;
			errorMsg = '';
			isBlackListOptOut = false;
			if(rsUploadObj.Blacklist__c || rsUploadObj.Opt_Out__c || Test.isRunningTest()){
				isBlackListOptOut = true;
				errorMsg='Participant is on the ';
				if(rsUploadObj.Blacklist__c){
					errorMsg = errorMsg + 'Blocklist ';
				}if(rsUploadObj.Opt_Out__c){
					if (String.isNotBlank(rsUploadObj.Opt_Out_Reason__c)) {
						errorMsg = errorMsg + rsUploadObj.Opt_Out_Reason__c;
					} else {
						errorMsg = errorMsg + 'OptOut ';
					}
				}
			}
			
			if(isBlackListOptOut==false || Test.isRunningTest()){
				if(String.isNotBlank(rsUploadObj.Email__c) && reserveEmailIdMap.containsKey(rsUploadObj.Email__c)){
					isReserved = true;
					projectDetailObj = reserveEmailIdMap.get(rsUploadObj.Email__c);
					errorMsg ='Participant having email id as : ' + rsUploadObj.Email__c +' reserved in (' + projectDetailObj.Research_Project_Master__r.Name + ') project.';
				}else if(String.isNotBlank(rsUploadObj.User_Id__c) && reserveUserIdMap.containsKey(rsUploadObj.User_Id__c)){
					isReserved = true;
					projectDetailObj = reserveUserIdMap.get(rsUploadObj.User_Id__c);
					errorMsg='Participant having user id as : ' + rsUploadObj.User_Id__c +' reserved in (' + projectDetailObj.Research_Project_Master__r.Name + ') project.';
				}else if(String.isNotBlank(rsUploadObj.Employee_Id__c) && reserveEmpIdMap.containsKey(rsUploadObj.Employee_Id__c)){
					isReserved = true;
					projectDetailObj = reserveEmpIdMap.get(rsUploadObj.Employee_Id__c);
					errorMsg='Participant having employee id as : ' + rsUploadObj.Employee_Id__c +' reserved in (' + projectDetailObj.Research_Project_Master__r.Name + ') project.';
				}
			}
			
			if(isReserved==false || Test.isRunningTest()){
				if(String.isNotBlank(rsUploadObj.Email__c) && notVisibleEmailIdMap.containsKey(rsUploadObj.Email__c)){
					isDisabled = true;
					projectDetailObj = notVisibleEmailIdMap.get(rsUploadObj.Email__c);
					errorMsg='Participant having email id as : ' + rsUploadObj.Email__c +' will be available after ' + strDaySinceCont + 'days of project(' + projectDetailObj.Research_Project_Master__r.Name + ') completion(' + projectDetailObj.Research_Project_Master__r.Project_Completion_Date__c +').';
				}else if(String.isNotBlank(rsUploadObj.User_Id__c) && notVisibleUserIdMap.containsKey(rsUploadObj.User_Id__c)){
					isDisabled = true;
					projectDetailObj = notVisibleUserIdMap.get(rsUploadObj.User_Id__c);
					errorMsg='Participant having user id as : ' + rsUploadObj.User_Id__c +' will be available after ' + strDaySinceCont + 'days of project('+ projectDetailObj.Research_Project_Master__r.Name +') completion('+ projectDetailObj.Research_Project_Master__r.Project_Completion_Date__c  +').';
				}else if(String.isNotBlank(rsUploadObj.Employee_Id__c) && notVisibleEmpIdMap.containsKey(rsUploadObj.Employee_Id__c)){
					isDisabled = true;
					projectDetailObj = notVisibleEmpIdMap.get(rsUploadObj.Employee_Id__c);
					errorMsg='Participant having employee id as : ' + rsUploadObj.Employee_Id__c +' will be available after ' + strDaySinceCont + 'days of project('+ projectDetailObj.Research_Project_Master__r.Name +') completion('+ projectDetailObj.Research_Project_Master__r.Project_Completion_Date__c +').';
				}
			}
			
			if(isReserved==true || isDisabled==true || isBlackListOptOut==true){
                userId = rsUploadObj.User_Id__c;
                employeeId = rsUploadObj.Employee_Id__c;
                if(String.isNotBlank(userId) && userId!='null'){
                    userId = '~'+userId;
                }if(String.isNotBlank(employeeId) && employeeId!='null'){
                    employeeId = '~'+employeeId;
                }
				strValue = rsUploadObj.First_Name__c+','+rsUploadObj.Last_Name__c+','+rsUploadObj.Email__c+','+userId+','+employeeId+',"'+errorMsg+'"';
				csvMap.put(rsUploadObj.Id,strValue);
			}
		}
    }
}