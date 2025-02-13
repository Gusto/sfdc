/**
 * @name         : CreateTicketController
 * @author       : Praveen Sethu
 * @date         : 09-16-2020
 * @description  : Used for xFunctional Benefits Ticket Creation
 * @test classes : CreateTicketControllerTest
 **/
public without sharing class CreateTicketController {
	//Static Final variable for Partner Operations team
	public static final String PARTNER_OPERATIONS_TEAM = 'Partner Operations';

	/**
	 * @name         : CreateTicketResponseWrapper
	 * @author       : Praveen Sethu
	 * @date         : 09-16-2020
	 * @description  : Wrapper class to share data between Apex and LWC
	 * @test classes : CreateTicketControllerTest
	 **/
	public class CreateTicketResponseWrapper {
		/* List of Teams */
		@AuraEnabled
		public List<String> list_Teams;

		/* List of Ticket Reasons */
		@AuraEnabled
		public List<String> list_TicketReasons;

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
		public CreateTicketResponseWrapper(Boolean blnIsSuccess, String strMessage, List<String> list_Teams, List<String> list_TicketReasons) {
			this.blnIsSuccess = blnIsSuccess;
			this.strMessage = strMessage;
			this.list_Teams = list_Teams;
			this.list_TicketReasons = list_TicketReasons;
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Loading list of Ticket Reasons
	 * @Parm        : NA
	 * @Return      : CreateTicketResponseWrapper
	 **/
	@AuraEnabled
	public static CreateTicketResponseWrapper loadCreateTicketData() {
		try {
			if (CreateTicketControllerTest.blnThrowException && Test.isRunningTest()) {
				Integer intSample = 1 / 0;
			}

			// Load Team List
			List<String> list_TeamsAll = new List<String>();
			List<String> list_Teams = new List<String>();
			// Fectch UI_Ticket_Reason__c pick list values
			list_TeamsAll = TicketConfigController.returnPicklistValues('Ticket_Config__c', 'Team__c');
			//removing Partner Operations Team from Teams List
			for (String strTeamName : list_TeamsAll) {
				if (strTeamName != PARTNER_OPERATIONS_TEAM) {
					list_Teams.add(strTeamName);
				}
			}
			// Load Ticket Reason List
			List<String> list_TicketReasons = new List<String>();
			// Fectch UI_Ticket_Reason__c pick list values
			list_TicketReasons = TicketConfigController.returnPicklistValues('Ticket__c', 'UI_Ticket_Reason__c');

			return new CreateTicketResponseWrapper(true, null, list_Teams, list_TicketReasons);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CreateTicketController', 'loadCreateTicketData', objException.getMessage(), objException.getStackTraceString());

			return new CreateTicketResponseWrapper(false, objException.getMessage(), null, null);
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Creating a new xFunctional Benefis Ticket
	 * @Parm        : objTicket - Instance of Ticket__c, objTicketConfig - Instance of Ticket_Config__c
	 * @Return      : CreateTicketResponseWrapper
	 **/
	@AuraEnabled
	public static CreateTicketResponseWrapper updateTicket(Ticket__c objTicket, Ticket_Config__c objTicketConfig) {
		try {
			if (CreateTicketControllerTest.blnThrowException && Test.isRunningTest()) {
				Integer intSample = 1 / 0;
			}

			if (objTicket == null) {
				return new CreateTicketResponseWrapper(false, 'Ticket record is null', null, null);
			}

			// Check if Ticket Config has record type configured. If yes, set ticket's record type
			if (objTicketConfig != null && String.isNotBlank(objTicketConfig.Ticket_Record_Type__c)) {
				objTicket.RecordTypeId = Schema.SObjectType.Ticket__c.getRecordTypeInfosByName().get(objTicketConfig.Ticket_Record_Type__c).getRecordTypeId();
			}

			if (objTicket.RecordTypeId == TicketUtil.API_INTEGRATION_ESCALATION_TICKET_RT_ID) {
				objTicket.Status__c = 'New';
			}

			// Check if Ticket Config has Owner Type
			if (objTicketConfig != null && String.isNotBlank(objTicketConfig.Owner_Type__c)) {
				// Ticket owner can either  be assigned to a queue or a owner of the benefit order or the owner of opportunity
				// If Owner Type is Assign to a Queue
				if (objTicketConfig.Owner_Type__c == 'Assign to a Queue') {
					// Check Queue Id
					if (String.isNotBlank(objTicketConfig.Queue_Id__c)) {
						objTicket.OwnerId = [
							SELECT Queue.Id, Queue.Name, Queue.Type
							FROM QueueSObject
							WHERE Queue.Type = 'Queue' AND Queue.Name = :objTicketConfig.Queue_Id__c
							LIMIT 1
						]
						?.Queue.Id;
					}
				} else if (objTicketConfig.Owner_Type__c == 'Benefit Order Owner') {
					// Check if ticket config owner type is Benefit Order Owner
					// Check if the new ticket has a benefit order linked to it
					if (objTicket.Benefit_Order__c != null) {
						List<Benefit_Order__c> list_BenefitOrders = [
							SELECT Id, OwnerId
							FROM Benefit_Order__c
							WHERE Id = :objTicket.Benefit_Order__c
						];
						if (!list_BenefitOrders.isEmpty()) {
							objTicket.OwnerId = list_BenefitOrders.get(0).OwnerId;
						}
					} else {
						// If there are no opportunities, assign ticket to the Benefit Order back up queue
						// Check if there is backup queue configured
						if (String.isNotBlank(objTicketConfig.Queue_Id__c)) {
							objTicket.OwnerId = [
								SELECT Queue.Id, Queue.Name, Queue.Type
								FROM QueueSObject
								WHERE Queue.Type = 'Queue' AND Queue.Name = :objTicketConfig.Queue_Id__c
								LIMIT 1
							]
							?.Queue.Id;
						}
					}
				} else if (objTicketConfig.Owner_Type__c == 'Opportunity Owner') {
					// Check if ticket config owner type is Opportunity Owner
					// Check if the new ticket has a opportunity linked to it
					if (objTicket.Opportunity__c != null) {
						List<Opportunity> list_TicketOpportunities = [
							SELECT Id, OwnerId
							FROM Opportunity
							WHERE Id = :objTicket.Opportunity__c
						];
						if (!list_TicketOpportunities.isEmpty()) {
							objTicket.OwnerId = list_TicketOpportunities.get(0).OwnerId;
						}
					}
				} else if (objTicketConfig.Owner_Type__c == 'Case Owner') {
					// If there are no opportunities, assign ticket to the Case Owner back up queue
					// Check if there is backup queue configured
					if (String.isNotBlank(objTicketConfig.Queue_Id__c)) {
						objTicket.OwnerId = [
							SELECT Id
							FROM Group
							WHERE Type = 'Queue' AND Name = :objTicketConfig.Queue_Id__c
							LIMIT 1
						]
						?.Id;
					}

					// Check if ticket config owner type is Case Owner
					// Check if the new ticket has a Case linked to it
					if (objTicket.Case__c != null) {
						List<Case> list_TicketCases = [
							SELECT Id, OwnerId, Status
							FROM Case
							WHERE Id = :objTicket.Case__c AND IsClosed = FALSE
						];

						if (!list_TicketCases.isEmpty()) {
							//Owner is User Assign Ticket to Case Owner
							if (String.valueOf(list_TicketCases[0].OwnerId).startsWith('005')) {
								objTicket.OwnerId = list_TicketCases.get(0).OwnerId;
							}

							// If Case is owned by a Queue and Case Status is Draft or New
							if (
								String.valueOf(list_TicketCases[0].OwnerId).startsWith('00G') && String.valueOf(list_TicketCases[0].Status) == 'Draft' ||
								String.valueOf(list_TicketCases[0].Status) == 'New'
							) {
								objTicket.OwnerId = [
									SELECT Id
									FROM Group
									WHERE Type = 'Queue' AND Name = 'Member Ops - Submissions'
									LIMIT 1
								]
								?.Id;
							}

							// If Case is owned by a Queue and Case Status is Submitted
							if (String.valueOf(list_TicketCases[0].OwnerId).startsWith('00G') && String.valueOf(list_TicketCases[0].Status) == 'Submitted') {
								objTicket.OwnerId = [
									SELECT Id
									FROM Group
									WHERE Type = 'Queue' AND Name = 'Member Ops - Follow Up'
									LIMIT 1
								]
								?.Id;
							}
						}
					}

					objTicket.Skip_Assignment__c = true;
				}
			}

			TicketTriggerHelper.blnSkipTicketTriggerAssignment = true;
			// Insert a new Ticket
			insert objTicket;
			TicketTriggerHelper.blnSkipTicketTriggerAssignment = false;

			// If successful, send a sucess response back to front ent
			CreateTicketResponseWrapper objWrapper = new CreateTicketResponseWrapper(true, null, null, null);
			objWrapper.objTicket = [SELECT Id, Name FROM Ticket__c WHERE Id = :objTicket.Id];

			return objWrapper;
		} catch (Exception objException) {
			//skip validation rule errors since they come from bad user input
			if (!objException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
				ExceptionLogUtil.logException('CreateTicketController', 'updateTicket', objException.getMessage(), objException.getStackTraceString());
			}

			return new CreateTicketResponseWrapper(false, objException.getMessage(), null, null);
		}
	}
}