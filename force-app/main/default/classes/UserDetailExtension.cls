public with sharing class UserDetailExtension {
    
    public User toEditUserRec{get;set;}
    public string selectedUserId{get;set;}
    private ApexPages.StandardController standardController;
    public User userFooterRec{get;set;}
    public list<selectOption> selectedAllQueueList{get;set;}
    public list<selectOption> selectedIndividualQueueList{get;set;}
    public Advocate_State__c advocate{get;set;}
    
    public UserDetailExtension(ApexPages.StandardController standardController) {
        this.standardController = standardController;
        Id userId = UserInfo.getUserId();
        userFooterRec = [Select id, Out_Of_Office__c from User where Id =: userId];
        toEditUserRec = new User();
        
        advocate = new Advocate_State__c();
        List<Advocate_State__c> advocates = new List<Advocate_State__c>([Select Id,State__c, User__c,User_Id__c from Advocate_State__c where User__c=:UserInfo.getUserId()]);
        if(advocates.size() > 0){
            advocate = advocates[0];
        } else {
            advocate = new Advocate_State__c();
            advocate.user__c = UserInfo.getUserId();
            advocate.user_id__c = UserInfo.getUserId();
        }
        
    }
    
    public UserDetailExtension(apexPages.standardSetController setController){
        toEditUserRec = new User();
        selectedAllQueueList = new list<selectOption>();
        selectedIndividualQueueList = new list<selectOption>();
    }    
    
    //creating new instance for the selected User
    public void editUser(){
        
        selectedAllQueueList = new list<selectOption>();
        selectedIndividualQueueList = new list<selectOption>();
        
        if(string.isBlank(selectedUserId)){
           apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,'Please select a user record.'));
           return; 
        }
        toEditUserRec = [select id, Class_Queue__c,Benefits_Class__c , Individual_Queues__c, All_Queues__c,Name, On_The_Floor_Date_Care__c, On_The_Floor_Date_FSC__c, On_The_Floor_Date_DSP__c,On_The_Floor_Date_PRC_Class_2__c, On_The_Floor_Date_PRC_Class_3__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c from User where id=:selectedUserId limit 1].get(0);
        
        if(toEditUserRec.Individual_Queues__c != null && toEditUserRec.Individual_Queues__c.length()>0){
            for(string rec: toEditUserRec.Individual_Queues__c.split(';')){
                selectedIndividualQueueList.add( new selectOption(rec,rec));
            }
        }
        
        if(toEditUserRec.All_Queues__c != null && toEditUserRec.All_Queues__c.length()>0){
            for(string rec: toEditUserRec.All_Queues__c.split(';')){
                selectedAllQueueList.add( new selectOption(rec,rec));
            }
        }
    }
    
    public list<SelectOption> getAllQueueAvailableList(){
        
        List<SelectOption> toReturnNameList = new List<SelectOption>();        
        Schema.DescribeFieldResult fieldResult =  User.All_Queues__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple){
            if(toEditUserRec.All_Queues__c != null && toEditUserRec.All_Queues__c.length()>0 &&
            toEditUserRec.All_Queues__c.indexof(f.getValue()) > -1){
                continue;
            }
            toReturnNameList.add(new SelectOption(f.getLabel(), f.getValue()));
        }
               
        return toReturnNameList;
    }
    
    public list<SelectOption> getIndividualQueueAvailableList(){
        
        List<SelectOption> toReturnNameList = new List<SelectOption>();        
        Schema.DescribeFieldResult fieldResult =  User.Individual_Queues__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple){
            if(toEditUserRec.Individual_Queues__c != null && toEditUserRec.Individual_Queues__c.length()>0 &&
            toEditUserRec.Individual_Queues__c.indexof(f.getValue()) > -1){
                continue;
            }
            toReturnNameList.add(new SelectOption(f.getLabel(), f.getValue()));
        }
               
        return toReturnNameList;
    }
    
    //updating User Record
    public void updateUser(){
        
        if(toEditUserRec != null && toEditUserRec.id != null){
           
            if(selectedAllQueueList.size()>0){
                string allQueueStr = '';
                for(selectOption rec:selectedAllQueueList){
                    if(string.isBlank(allQueueStr))
                        allQueueStr=rec.getValue();
                    else
                        allQueueStr+=';'+rec.getValue();
                }
                toEditUserRec.All_Queues__c = allQueueStr;
            }
            
            if(selectedIndividualQueueList.size()>0){
                string indiQueueStr = '';
                for(selectOption rec:selectedIndividualQueueList){
                    if(string.isBlank(indiQueueStr))
                        indiQueueStr=rec.getValue();
                    else
                        indiQueueStr+=';'+rec.getValue();
                }
                toEditUserRec.Individual_Queues__c = indiQueueStr;
            }
            
            
            try{
                
                update toEditUserRec;
            }
            catch(exception ex){
                apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,ex.getMessage()));
                return;
            }
            
            toEditUserRec = new User();
            selectedUserId = null;
        }
                
    }
    
    public void updateUserFooterRecord(){
        
        if(userFooterRec != null && userFooterRec.id != null){
            try{
                upsert advocate User_Id__c;
                update userFooterRec;
            }
            catch(exception ex){
                apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,ex.getMessage()));
                return;
            }
        }
    }
    
    public void cancelEditUser(){
        toEditUserRec = new User();
        selectedUserId = null;
    }
    
}