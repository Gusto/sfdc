public with sharing class UR_ManageCSVRecordCtrl{
	public Research_Project_Master__c ProjectMasterObj {get;set;}
	public String query=''; 
	public Set<String> extraColumnSet{get;set;}
	public Map<Id, String> csvMap{get;set;}
	public String strFlag = '';
	public UR_ManageCSVRecordCtrl(){
		String currentRecordId  = ApexPages.CurrentPage().getparameters().get('projectId'); 
		strFlag  = ApexPages.CurrentPage().getparameters().get('flag');	
		ProjectMasterObj = new Research_Project_Master__c(id=currentRecordId);
		Integer extraColumn = 0;
		extraColumnSet = new Set<String>();
		csvMap = new Map<Id, String>();
		List<Research_Project_Master__c> projectList = [Select id, Uploaded_CSV_Column__c from Research_Project_Master__c where Id =:currentRecordId];
		if(projectList.size()>0){
			ProjectMasterObj = projectList[0];
			if(projectList[0].Uploaded_CSV_Column__c!=null){
				Integer totalColumn = Integer.valueOf(projectList[0].Uploaded_CSV_Column__c);
				if(totalColumn>=7){
					extraColumn = totalColumn -7;
				}
			}
		}
		
	   query = 'select Id, Name, Accountant_Firm_Id__c, Company_Id__c, CSV_File_Name__c, CSV_Header__c, CSV_Upload_Date__c, Email__c, Employee_Id__c, First_Name__c, Last_Name__c, Message__c, Research_Project_Master__c, Status__c, User_Id__c ';			
	  
	   String subQuery = '';
	   if(extraColumn!=null && extraColumn >0){
		 String fieldAPIName = '';
		 for(Integer iCount=1; iCount<=extraColumn; iCount++){
			fieldAPIName = 'UXR_CSV_Column'+iCount+'__c';
			subQuery = subQuery + fieldAPIName + ', ';
			extraColumnSet.add(fieldAPIName);
		 }
	   }	  
	   if(String.isNotBlank(subQuery)){
			subQuery = subQuery.trim();
			subQuery = subQuery.subString(0,subQuery.length()-1);
			query = query + ',' + subQuery;
	   }
	   query = query + ' from UXR_CSV_Staging__c ';
	  
	}
	
    public pageReference fetchList(){
        Id projectId = ProjectMasterObj.Id;
		query = query + ' where Research_Project_Master__c =: projectId ';
        if(!Test.isRunningTest()){
        	query = query + ' and (Status__c = :strFlag or CSV_Header__c = true) order by CSV_Header__c desc';
        }
		String csvColumn = '';
		for(UXR_CSV_Staging__c csvObj : database.query(query)){
			csvColumn = '';
			csvColumn = csvObj.First_Name__c + ',' + csvObj.Last_Name__c + ',' + csvObj.Email__c + ',' + csvObj.Company_Id__c  + ',' + csvObj.User_Id__c + ',' + csvObj.Employee_Id__c + ',' + csvObj.Accountant_Firm_Id__c ;
			
			for(String fieldAPIName : extraColumnSet){
				csvColumn = csvColumn + ',' + csvObj.get(fieldAPIName);
			}
			
			csvColumn = csvColumn + ',' + csvObj.CSV_File_Name__c + ',' + csvObj.Status__c  + ',"' + csvObj.Message__c + '"';

			csvMap.put(csvObj.Id,csvColumn);
		}
        return null;
    }    
}