/*
	By: Deepak Tyagi
	Date: Dec 24, 2018
	JIRA # BT-2629
	Desc: Automation for Mid Year Benefit Adds
*/
public class TicketBenefitChangeCasePageCtrl {
    
    Ticket__c objTicket;
    
    public TicketBenefitChangeCasePageCtrl(ApexPages.standardController sc) {
        objTicket = (Ticket__c) sc.getRecord();
        objTicket = [SELECT 
                     Id,
                     Account__c,
                     RecordType.Name,
                     Fulfillment_Case__c,
                     OwnerId,
                     Status__c,
                     Priority__c
                     FROM Ticket__c
                     WHERE Id =: objTicket.Id];
    }
    
    public pageReference initMethod() {
        if (objTicket.Fulfillment_Case__c == null) {
            if (objTicket.OwnerId != UserInfo.getuserId()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This ticket is accessible only by ticket owner.'));
                return null;
            }
            Case objCase = new Case();
            objCase.Subject = 'Gusto benefits change';
            objCase.Description = 'Gusto benefits change';
            objCase.RecordTypeId = Cache.getRecordTypeId('Case', 'Benefits Change Case');
            objCase.Origin = 'Hippo';
            objCase.Type = 'Benefits Change';
            objCase.AccountId = objTicket.Account__c;
            objCase.Status = objTicket.Status__c;
            objCase.Priority = objTicket.Priority__c;
            objCase.OwnerId = objTicket.OwnerId;
            try {
                insert objCase;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in Case Creation.'));
                return null;
            }
            objTicket.Fulfillment_Case__c = objCase.Id;
            update objTicket;
            return new pageReference('/' + objTicket.Fulfillment_Case__c);
        } else {
            return new pageReference('/' + objTicket.Fulfillment_Case__c);
        }
    }
}