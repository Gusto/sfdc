@isTest
public class HCProEmailServiceTest {
    
    static testMethod void testNewEmailCaseCreation() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = 'test';
        email.fromName = 'test test';
        email.plainTextBody = getCaseTextBody('pro email: test@gusto.com');
        List<String> emailList = new List<String>();
        emailList.add('test@gustotest.com');
        email.ccAddresses = emailList;
        email.toAddresses = emailList;
        
        envelope.fromAddress = 'user@acme.com';
        envelope.toAddress = 'test@test.com';
        
        // setup controller object
        HCProEmailService catcher = new HCProEmailService();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true); 
        
    }
    
    static testMethod void testNewEmailWithoutEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = 'test';
        email.fromName = 'test test';
        email.plainTextBody = getCaseTextBody('');
        List<String> emailList = new List<String>();
        emailList.add('test@gustotest.com');
        email.ccAddresses = emailList;
        email.toAddresses = emailList;
        
        envelope.fromAddress = 'user@acme.com';
        envelope.toAddress = 'test@test.com';
        
        // setup controller object
        HCProEmailService catcher = new HCProEmailService();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        System.assertEquals( result.success  ,true); 
        
    }
    
    private static String getCaseTextBody(String email){
        String body='';
        body+='Organization enrollment request';
        body+='\npro_id: 378605';
        body+='\npro_name: Test Test';
        body+='\npro mobile number: 9999999999';
        body+='\npro email: '+email;
        body+='\norganization id: 235663';
        body+='\norganization name: Test Test & A/C';
        body+='\norganization phone number: 7777777777';
        body+='\norganization email test.gusto@gusto.com';
        body+='\nservice categories: ["Heating & Air Conditioning"]';
        body+='\nservice address: Po Box 7, San Ramon, CA 80433';
        body+='\napi key:';
        body+='\nwebhook_api_key: cdf416f2b1e4416da06ba72a155a91b4';
        return body;
    }

}