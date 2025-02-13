global class WFMRequestEmailService implements Messaging.InboundEmailHandler {
      
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        
        system.debug('@@## email '+email+' ##$$ envelope '+envelope);
        
        String body = '';

        if(email.plainTextBody!=null){
            body = email.plainTextBody;
        } else if(email.htmlBody!=null) {
            body = email.htmlBody;
        }
        system.debug('body :: '+body);
		try{
            WFM_Request__c req = new WFM_Request__c();
            List<User> userList = [Select Id from user where email =:email.fromAddress];
            if(userList.size()>0){
                req.Requester__c = userList[0].id;
            }
            
            req.Status__c = 'New';
            req.From_Email__c = email.fromAddress;
            req.From_Name__c = email.fromName;
            req.Subject__c = email.subject;
            req.Email_Content__c = body;
            
            insert req;
            
            system.debug('req :: '+req);
            
        //try{
			//insert msg;
			List<Attachment> attachmentList = new List<Attachment>();
            if(email.binaryAttachments!=null){
                for(Messaging.InboundEmail.BinaryAttachment atch : email.binaryAttachments){

                    Attachment attch = new Attachment();
                    attch.Body = atch.body;
                    attch.Name = atch.fileName;
                    attch.ContentType = atch.mimeTypeSubType;
                    attch.ParentId = req.Id;
                    attachmentList.add(attch);
                }   
            }
            if(email.textAttachments!=null){
                for(Messaging.InboundEmail.TextAttachment atch : email.textAttachments){

                    Attachment attch = new Attachment();
                    attch.Body = Blob.valueOf(atch.body);
                    attch.Name = atch.fileName;
                    attch.ContentType = atch.mimeTypeSubType;
                    attch.ParentId = req.Id;
                    attachmentList.add(attch);
                } 
            }
            if(attachmentList.size()>0){
                insert attachmentList;
            }

        } catch(Exception ex){
            system.debug('Exception :: '+ex.getMessage());
            system.debug('Exception2 :: '+ex.getStackTraceString());
        }
        
		Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        return result;
    }
    
 
    

    
   
}