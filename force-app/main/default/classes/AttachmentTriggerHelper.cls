/**
Created by : Anshul Agrawal
Created Date : 2/01/2018
**/
public class AttachmentTriggerHelper {
	
	public static boolean skipTrigger = false;
    public static integer counter=0; 
    
	public void OnBeforeInsert(List<Attachment> attachments)
    { 
        counter++;  
    }
    
    public boolean OnAfterInsert(Map<ID, Attachment> newAttachmentMap)
    {
        if(skipTrigger==true){
	      return false;
	    }
		counter++;
		//create attachment on new email message
        createNewAttachment(newAttachmentMap.values());
        
        return true;
    }
    
    @future
    public static void OnAfterInsertAsync(Set<ID> insertedAttachmentIDs){
        
    }
    
    public void OnBeforeUpdate(Map<ID, Attachment>  oldAttachmentMap, Map<ID, Attachment> newAttachmentMap)
    {
        counter++;
	}
	
	public void OnAfterUpdate(Map<ID, Attachment>  oldAttachmentMap, Map<ID, Attachment> newAttachmentMap)
	{       
    	counter++;
    }
    
    @future
    public static void OnAfterUpdateAsync(Set<ID> updatedAttachmentIDs){
        
    }
    
    public void OnBeforeDelete(Attachment[] attachmentToDelete, Map<ID, Attachment> oldAttachmentMap){
        counter++;
    }
    
    public void OnAfterDelete(Attachment[] deletedAttachments, Map<ID, Attachment> oldAttachmentMap){
        counter++;
        
    }
    
    @future
    public static void OnAfterDeleteAsync(Set<ID> deletedAttachmentIDs){
        
    }
    
    public void OnUndelete(Attachment[] restoredAttachments){
        counter++;
    }
    
    private void createNewAttachment(List<Attachment> attachmentList){
    	system.debug('In createFollwUp case>>');
        Set<id> emailMessageIdSet = new Set<id>();
        map<String, Id> oldIdEmailMsgWithNewIdMap = new map<String,Id>();
        Map<Id, id> map_stdEmailMsgToCustomEmailMsg = new Map<Id, Id>();
        List<Attachment> insertAttList = new List<Attachment>();
        
        for(Attachment m : attachmentList){
            string parentId = m.ParentId;
            if(parentId!=null && parentId.IndexOf('02s')==0){
                emailMessageIdSet.add(m.ParentId);
            }
        }
        system.debug('emailMessageIdSet in AttachmentTriggerHelper>>'+emailMessageIdSet);
        if(emailMessageIdSet.size()>0){
            for (EmailMessage e : [SELECT id,ParentId,Old_Parent_Email_Id__c FROM EmailMessage where Old_Parent_Email_Id__c in :emailMessageIdSet]){
				oldIdEmailMsgWithNewIdMap.put(e.Old_Parent_Email_Id__c,e.Id);
	        }
        }
        
        system.debug('oldIdEmailMsgWithNewIdMap in AttachmentTriggerHelper>>'+oldIdEmailMsgWithNewIdMap);
        if(oldIdEmailMsgWithNewIdMap.size() > 0) {
	        for(Attachment att : attachmentList){
	            if(oldIdEmailMsgWithNewIdMap.containsKey(att.ParentId)){          
			        Attachment newAtt = att.clone();
			        newAtt.parentid = oldIdEmailMsgWithNewIdMap.get(att.ParentId);
			        insertAttList.add(newAtt);  
		    	}
	        }   
        }
        
        // SJay - 12/11/2020  - Added code to handle universal inbox email attachments        
        
        if(emailMessageIdSet.size()>0){
            for(Email_Message__c objCustomEmail  : [SELECT 	Id,
                                               				EmailID__c
                                                	FROM	Email_Message__c
                                                	WHERE	EmailID__c IN :emailMessageIdSet]) 
        {
            map_stdEmailMsgToCustomEmailMsg.put(objCustomEmail.EmailID__c, objCustomEmail.Id);    
        }
            
            if(map_stdEmailMsgToCustomEmailMsg.size() > 0) {   
                for(Attachment objAttachment : attachmentList){
                    if(map_stdEmailMsgToCustomEmailMsg.containsKey(objAttachment.ParentId)){          
                        Attachment objClonedAttachment = objAttachment.clone();
                        objClonedAttachment.ParentId = map_stdEmailMsgToCustomEmailMsg.get(objAttachment.ParentId);
                        insertAttList.add(objClonedAttachment);  
                    }
                }         
            }
        }
        if(insertAttList.size() > 0 ){
            try {
                skipTrigger = true;
                database.insert(insertAttList,false);
            } catch(Exception ex){
            	ExceptionLogUtil.logException('AttachmentTriggerHelper', 'createNewAttachment', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());       
                system.debug('error occurred while interting new attachment list in AttachmentTriggerHelper '+ex.getMessage());
            }
        }
	}
}