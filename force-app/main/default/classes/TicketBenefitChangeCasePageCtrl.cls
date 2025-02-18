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
    
    /**
	 * @description Returns a Fulfillment Case with ticket.
	 * @author     Deepika Saini
	 * @param       Id of Ticket.
	 * @return      Object of Ticket record.
	 **/
	@AuraEnabled
	public static Ticket__c getFulfilmentCaseWithTicket(Id idTicketRecord) {
		Ticket__c objTicket = new Ticket__c();
		if (idTicketRecord != null) {
			for (Ticket__c objtic :[
				SELECT 
                     Id,
                     Account__c,
                     RecordType.Name,
                     Fulfillment_Case__c,
                     Fulfillment_Case__r.CaseNumber,
                     OwnerId,
                     Status__c,
                     Priority__c,
                     Carrier__c,
                     Contact__c
                     FROM Ticket__c
                     WHERE Id =: idTicketRecord
			]) {
				objTicket = objtic;
			}
		}        
		return objTicket;
	}

    /**
	 * @description Returns a Fulfillment Case with ticket.
	 * @author     Deepika Saini
	 * @param       Id of Ticket.
	 * @return      create the ticket with Fulfillment Case.
	 **/
	@AuraEnabled
	public static CreateTicketResponseWrapper saveFulfillmentCase(Ticket__c objTicket) {
        if (objTicket == null) {
            return new CreateTicketResponseWrapper(false, 'Ticket record is null', null);
        }
        if (objTicket.OwnerId != UserInfo.getuserId()) {
            return new CreateTicketResponseWrapper(false, 'This ticket is accessible only by ticket owner.', null);
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
        objCase.ContactId = objTicket.Contact__c;
        objCase.Carrier__c = objTicket.Carrier__c;
        try {
            insert objCase;
            objTicket.Fulfillment_Case__c = objCase.Id;
            update objTicket;
            // If successful, send a sucess response back to front ent
            Ticket__c objTicketUpdated = [SELECT Id, Name, Fulfillment_Case__c, Fulfillment_Case__r.CaseNumber FROM Ticket__c WHERE Id = :objTicket.Id]; 
			CreateTicketResponseWrapper objWrapper = new CreateTicketResponseWrapper(true, null, objTicketUpdated);
            return objWrapper;
        } catch (Exception objException) {
            //skip validation rule errors since they come from bad user input
			if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
				ExceptionLogUtil.logException('TicketBenefitChangeCasePageCtrl', 'saveFulfillmentCase', objException.getMessage(), objException.getStackTraceString());
			}
            return new CreateTicketResponseWrapper(false, objException.getMessage(), null);
        }
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

    /**
	 * @name         : CreateTicketResponseWrapper
	 * @author       : Deepika Saini
	 * @date         : 02/04/2025
	 * @description  : Wrapper class to share data between Apex and LWC
	 * @test classes : CreateTicketControllerTest
	 **/
	public class CreateTicketResponseWrapper {

		/* Success flag */
		@AuraEnabled
		public Boolean blnIsSuccess;

		/* Message */
		@AuraEnabled
		public String strMessage;

		/* Ticket__c record */
		@AuraEnabled
		public Ticket__c objTicket;

		// Parameterized Constructor
		public CreateTicketResponseWrapper(Boolean blnIsSuccess, String strMessage, Ticket__c objTicket) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.objTicket = objTicket;
		}
	}
}