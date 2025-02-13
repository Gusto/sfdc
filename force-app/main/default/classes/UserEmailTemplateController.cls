/**
Created by : Anshul Agrawal
Created Date : 02/20/2018
**/
public with sharing class UserEmailTemplateController
{
    private Map<Id, Folder> folderMap{get;set;}
    //List of string to store Alphabets character for Alphabetically searching
    public List<EmailingTemplate> emailingTemplates {get; set;}      
    public String folderId {get; set;}
    public string searchEmailName {get; set;}    
    

    //constructor
    public UserEmailTemplateController()
    {	
    	emailingTemplates = new List<EmailingTemplate>();
        folderMap = new Map<Id, Folder>( [Select id , Name from Folder where Type = 'Email']);
        this.getEmailTemplateData();
    }

    public void getEmailTemplateData() //Method to get Name Template Name, Description FolderId from EmailTemplate
    {
		system.debug('searchEmailName>>'+searchEmailName);
		emailingTemplates.clear();
        String query= '';
        String strFilter = 'where IsActive=true';
        if(searchEmailName!=null && searchEmailName!=''){
		    String searchEmailName1 = '%' + searchEmailName + '%';
		    strFilter  = strFilter  +  ' AND (Name like :searchEmailName1  OR Description like :searchEmailName1)' ;
	    }
	    system.debug('folderId >>'+folderId);
	    if(folderId!=null && folderId != 'All') {
	    	strFilter  = strFilter  +  ' AND FolderId = :folderId' ;
	    }
	    if(strFilter != '')
        {
            query = 'select id,Name, TemplateType, Description , Folder.Name from EmailTemplate '+strFilter+' Order by Name limit 1000';
            System.debug('Query ---->'+ query );
            Database.QueryLocator q = Database.getQueryLocator(query);
			// Get an iterator
			Database.QueryLocatorIterator it =  q.iterator();			
			// Iterate over the records
			while (it.hasNext())
			{
			    EmailTemplate e= (EmailTemplate)it.next();
			    //System.debug(e);
                EmailingTemplate tempE = new EmailingTemplate();
                tempE.templateId = e.Id;
                tempE.Name = e.Name;
                tempE.Folder = e.Folder.Name;
                tempE.Description = e.Description;          
                emailingTemplates.add(tempE);
            }
            
            system.debug('emailingTemplates size'+emailingTemplates.size());
        }
    }
    
    public List<SelectOption> getFolders() // show email template according to selaeted email template folder
    {
      List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('All', 'All'));
            for(Id key :folderMap.keySet()){
			    options.add(new SelectOption(key, folderMap.get(key).name));
			}
            return options;
    }
    
    @remoteAction
    public static Boolean logEmailAudit(string templateId, String caseId){
        
        system.debug('~~!! templateId '+templateId);
        if(!string.isBlank(templateId)){
        	try{
	            list<EmailTemplate> emailTemplateList = [select id,Body, Name  from EmailTemplate where Id =:templateId];
	            if(emailTemplateList.size()>0){
	            	Email_Template_Audit_Log__c emailAudit = new Email_Template_Audit_Log__c();
	            	emailAudit.Case_Id__c = caseId;
	            	emailAudit.Login_User__c = UserInfo.getUserId();
	            	emailAudit.Template_Id__c = emailTemplateList.get(0).id;
	            	emailAudit.Template_Name__c = emailTemplateList.get(0).Name;
	            	insert emailAudit;
	            }
        	}catch(Exception e){
        		return false;
        	}
        }
        return true;
    }     
    
    @remoteAction
    public static string getEmailSubject(String caseId){
        
        system.debug('~~!! caseId '+caseId);
        if(!string.isBlank(caseId)){
        	try{
        		list<EmailMessage> emailMsgList = [select id, subject, createddate from EmailMessage where parentid = :caseId order by createddate desc];
	            if(emailMsgList.size() > 0){
	            	return emailMsgList[0].subject;
	            }
        	}catch(Exception e){
        		return null;
        	}
        }
        return null;
    }                                
                                
    class EmailingTemplate // inner class to get emailTemplates Properties
    {
            public String templateId {get; set;}
            public String Name {get; set;}
            public String Folder {get; set;}
            public String Description {get; set;}
    }

    @remoteAction
    public static string getTemplateBody(string templateId){
        
        if(string.isNotBlank(templateId)){
            list<EmailTemplate> tempList = [select id, body from EmailTemplate where id=:templateId];
            if(tempList != null && tempList.size()>0){
                return tempList.get(0).body;
            }            
        }

        return null;
    } 
}