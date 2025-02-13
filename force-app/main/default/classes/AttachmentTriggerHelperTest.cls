@isTest
private class AttachmentTriggerHelperTest {
    
    
    @testSetup 
    static void setUp() {
    	Account acc = TestUtility.CompanyAccount();
    	Case cse = new Case();
        cse.RecordTypeId = cache.getRecordTypeId('Case', 'MF QLE');
        cse.AccountId = acc.Id;
        cse.Subject='Test';
        cse.Description='Test';
        cse.Type='QLE';
        insert cse;
        

	}
    	
    
    @isTest
    static void createNewAttachmentTest() {
        //EmailMessage msg = [select id from EmailMessage where Subject='Parent test'];                  
        
        test.startTest();
        	Case cse = [select id from case limit 1]; 
        
            EmailMessage msg = new EmailMessage();
            msg.ParentId=cse.id;
            msg.FromAddress='test@gusto.com';
            msg.ToAddress='test.test@gusto.com';
            msg.Subject='Parent test';
            msg.TextBody='test';
            insert msg;
            
            EmailMessage msg1 = new EmailMessage();
            msg1.ParentId=cse.id;
            msg1.FromAddress='test@gusto.com';
            msg1.ToAddress='test.test@gusto.com';
            msg1.Subject='test Attachment';
            msg1.TextBody='test Attachment';
            msg1.Old_Parent_Email_Id__c = msg.id;
            insert msg1;        
	        Attachment atth = new Attachment();
	        atth.Name = 'Test Attachment';
	        atth.Body = Blob.valueOf('Test Immage');
	        atth.ParentId = msg.id;
        	insert atth;
        	
        	msg = [select id,HasAttachment from EmailMessage where Subject='test Attachment'];
        	system.assert(msg.HasAttachment!=null);
        	
        	atth.Name='Test Attachment Update';
        	update atth;
        
        test.stopTest();
        
        delete atth;
        
    }
}