public with sharing class PrivacyRequestRegenerateCodeExt {
    private ApexPages.StandardController stdCtrl;
    private Case c;
    public String redirectUrl {public get; private set;}
    public Boolean shouldRedirect {public get; private set;}

    public PrivacyRequestRegenerateCodeExt(ApexPages.StandardController ctrl) {
        this.stdCtrl = ctrl;
        if (!Test.isRunningTest()) ctrl.addFields(new List<String>{'CaseNumber', 'Privacy_Requester_First_Name__c', 'Privacy_Requester_Last_Name__c', 'Privacy_Requester_Email__c'});
        this.c = (Case) ctrl.getRecord();
        shouldRedirect = false;
        
    }
    
    //this method regenerates the Case's confirmation code and sends an 
    //email to the requester about their new code
    public PageReference regenerateCode() {
        redirectUrl = stdCtrl.view().getUrl();
        shouldRedirect = true;
        String strConfirm = CaseTriggerHelper.generateConfirmationCode(c);
        c.Confirmation_Code__c = strConfirm;
        update c;

        List<String> list_EmailAddress = new List<String>{c.Privacy_Requester_Email__c};
        List<String> list_EmailBody = new List<String>();
        String strEmailSubject = 'Your California Consumer Privacy Act Request Portal confirmation code';
        List<String> list_EmailSubject = new List<String>{strEmailSubject};

        String strEmailBody = '<html><body>You recently initiated a request through Gusto\'s California Consumer Privacy Act Request Portal. <br/>';
        strEmailBody += 'Here is your new confirmation code: ' + strConfirm + '<br/><br/>';
        strEmailBody += 'Please log in to the California Consumer Privacy Act Request Portal <a href="' + Label.Privacy_Request_Site_URL + '">here</a> to complete and submit your request. Please note that we are required by law to verify your identity before we can process your request.';
        strEmailBody += '</body></html>';


        list_EmailBody.add(strEmailBody);

        //send the email to the requester
        CaseTriggerHelper.sendPrivacyRequestEmail(list_EmailAddress, list_EmailBody, list_EmailSubject);

        //attach the email to the case
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.Subject = strEmailSubject;
        emailMsg.FromAddress = 'no-reply@gusto.com';
        emailMsg.ToAddress = c.Privacy_Requester_Email__c;
        emailMsg.ParentId = c.Id;
        emailMsg.MessageDate = System.now();
        emailMsg.Status = '3';
        insert emailMsg;

        return null;
    }

}