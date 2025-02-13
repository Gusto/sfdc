@isTest
public class WFMRequestEmailServiceTest {

    static testMethod void testNewEmailCaseCreation() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = 'test';
        email.fromName = 'test test';
        email.plainTextBody = getCaseTextBody();
        email.htmlBody = getHTMLBody();
        List<String> emailList = new List<String>();
        emailList.add('test@gustotest.com');
        email.ccAddresses = emailList;
        email.toAddresses = emailList;
        Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];  
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.txt';
        String algorithmName = 'HMacSHA1';
        Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'),
        Blob.valueOf('test_key'));
        binaryAttachment.Body = b;
        binaryAttachments[0] =  binaryAttachment ;
        email.binaryAttachments = binaryAttachments ;
        
        Messaging.InboundEmail.TextAttachment[] textAttachments = new Messaging.InboundEmail.TextAttachment[1];  
        Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
		textAttachment.Filename = 'test.txt';
        textAttachment.Body = 'test';
        textAttachments[0] =  textAttachment ;
        email.textAttachments = textAttachments ;
        
        envelope.fromAddress = 'user@acme.com';
        envelope.toAddress = 'test@test.com';


        // setup controller object
        WFMRequestEmailService catcher = new WFMRequestEmailService();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true);          
    }    
    
    
    private static String getCaseTextBody(){
        String body='';
        body+='-----------------------------------------------';
        body+='\nsubject : TEST for JEN nanorep';
        body+='\nCompanyID : 11111111111111';
        body+='\nFirmID : ';
        body+='\nUserID : 11111111111111';
        body+='\nEmail : test@gusto.test';
        body+='\nTier : concierge';
        body+='\nConciergePod : Dolores and Teddy';
        body+='\nUserName : Oscar Cronin';
        body+='\nContext : ';
        body+='\nUserRole : payroll_admin';
        body+='\nOrigin-URL : https://manage.gusto-demo.com/payroll_admin';
        body+='\n-----------------------------------------------';
        body+='\nThis is my test email from Nano Rep bot';
        return body;
    }
    
    private static String getHTMLBody(){
        String body='';
        body+='-----------------------------------------------<br/>';
        body+='<br/>subject : TEST for JEN nanorep';
        body+='<br/>CompanyID : 11111111111111';
        body+='<br/>FirmID : ';
        body+='<br/>UserID : 11111111111111';
        body+='<br/>Email : test@gusto.test';
        body+='<br/>Tier : concierge';
        body+='<br/>ConciergePod : Dolores and Teddy';
        body+='<br/>UserName : Oscar Cronin';
        body+='<br/>Context : ';
        body+='<br/>UserRole : payroll_admin';
        body+='<br/>Origin-URL : https://manage.gusto-demo.com/payroll_admin';
        body+='-----------------------------------------------<br/>';
        body+='<br/>This is my test email from Nano Rep bot';
        return body;
    }    
}