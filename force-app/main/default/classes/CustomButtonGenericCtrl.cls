/*
 * Description  :   Controller class to handle updates and page redirection for any custom buttons
 * Created By   :   Neha Dabas
 * Created Date :   31st July 2019
 */
public with sharing class CustomButtonGenericCtrl {
	public String strButtonSource { get; set; } // button name
	private String strEntityName; // name of the object that button is associated with
	private String strEntityId; // id of the object that button is assciated with
	public String strReturnURL { get; set; } // URL of page to which the button will redirect to, once the action is done

	public String comments { get; set; } // to Capture comments on click of ER OutReach or PI Submission
	public Ticket__c objTicket { get; set; } // to show existing comments if any
	public Boolean authorizedUser { get; set; }
	public CustomButtonGenericCtrl() {
		//initialize page parameters

		if (ApexPages.currentPage().getParameters().containsKey('source')) {
			strButtonSource = ApexPages.currentPage().getParameters().get('source');
		}
		if (ApexPages.currentPage().getParameters().containsKey('entityName')) {
			strEntityName = ApexPages.currentPage().getParameters().get('entityName');
		}
		if (ApexPages.currentPage().getParameters().containsKey('entityId')) {
			strEntityId = ApexPages.currentPage().getParameters().get('entityId');
		}
		if (ApexPages.currentPage().getParameters().containsKey('returnURL')) {
			strReturnURL = ApexPages.currentPage().getParameters().get('returnURL');
		}

		authorizedUser = false;
	}
	/*
	 * Description  :   Determines which action should be performed on button click based on buttonSource and entityName
	 * Created By   :   Neha Dabas
	 * Created Date :   31st July 2019
	 */
	public PageReference buttonAction() {
		try {
			if (String.isNotBlank(strButtonSource) && String.isNotBlank(strEntityName)) {
				if ('Ticket'.equalsIgnoreCase(strEntityName)) {
					if (String.isNotBlank(strEntityId)) {
						//Fetch ticket record and its related Carrier Order and Benefit Order
						objTicket = [SELECT COUNT() FROM Ticket__c WHERE Id = :strEntityId AND Carrier_Order__c != NULL LIMIT 1] > 0
							? [
									SELECT
										Id,
										Benefit_Order__r.OwnerId,
										Carrier_Order__r.OwnerId,
										Carrier_Order__c,
										ER_Outreach_count__c,
										ER_Outreach_Comments__c,
										Ready_for_Submission_Comments__c,
										Owner_Role_Type__c
									FROM Ticket__c
									WHERE Id = :strEntityId AND Carrier_Order__c != NULL
									LIMIT 1
							  ]
							: null;
						if (null != objTicket) {
							//When ER Outreach Button is clicked on Ticket Detail Page
							if ('EROutreach'.equalsIgnoreCase(strButtonSource)) {
								//logged in user should be the submission owner on carrier order
								if (objTicket.Carrier_Order__r.OwnerId != userInfo.getUserId()) {
									ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This action is avaiable only for Submission Owner'));
								} else {
									authorizedUser = true;
								}
							} else if ('PISubmission'.equalsIgnoreCase(strButtonSource)) {
								//When Ready For PI Submission Button is clicked on Ticket Detail Page
								//Logged in user should be Onboarding Advocate on related benefit order
								if (objTicket.Benefit_Order__r.OwnerId != userInfo.getUserId()) {
									ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This action is avaiable only for Onboarding Advocate'));
								} else {
									authorizedUser = true;
								}
							}
						} else {
							ApexPages.addMessage(
								new ApexPages.Message(ApexPages.Severity.WARNING, 'Either Ticket Id is not correct or there are no Carrier Orders Associated with it. Please check again.')
							);
						}
					}
				}
			}
			return null;
		} catch (Exception objException) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objException.getMessage()));
			return null;
		}
	}

	/*
	 * Description  :   Changes ticket ownership and Carrier Order Stage
	 * Created By   :   Neha Dabas
	 * Created Date :   31st July 2019
	 */
	public PageReference readyForPISubmissionAction() {
		PageReference returnPage;

		if (null != objTicket) {
			//Assign the ticket back to Submission owner on related carrier order
			objTicket.OwnerId = objTicket.Carrier_Order__r.OwnerId;

			//set comment
			String cmnt = '[' + system.now() + ']' + comments;

			objTicket.Ready_for_Submission_Comments__c = String.isBlank(objTicket.Ready_for_Submission_Comments__c) ? cmnt : objTicket.Ready_for_Submission_Comments__c + '\n' + cmnt;

			//Set last clicked date
			objTicket.PI_Submission_Date__c = system.today();

			//Set status to Ready for PI Submission
			objTicket.Status__c = 'Ready for PI Submission';

			// update related carrier order's implementation stage to 'Ready for Submission Prep'

			Carrier_Order__c objCO = new Carrier_Order__c(Id = objTicket.Carrier_Order__c, Implementation_Stage__c = 'Ready for Submission Prep');
			//DS[24/7/2020] for setting reRouting true in case ticket owner is not valid
			objCO.Requires_Routing__c = UtilitiesFactory.CheckTicketOwnerIsValidOrNot(objTicket.OwnerId, TicketUtil.TICKET_ROLE_FULFILLMENT, true);

			//DS[11-09-2020] Track Qualification owner at the time of ticket creation
			if (objTicket.OwnerId != null) {
				if (String.valueOf(objTicket.OwnerId).startsWith('005')) {
					objTicket.Initial_owner__c = objTicket.OwnerId;
				}
			}

			//update carrier order and ticket records
			update objTicket;
			update objCO;
			returnPage = new PageReference(strReturnURL);
		}
		return returnPage;
	}

	/*
	 * Description  :   Changes ticket ownership and updates Carrier Order Stage and other ER outreach related fields on Ticket
	 * Created By   :   Neha Dabas
	 * Created Date :   31st July 2019
	 */
	public PageReference initiateEROutreach() {
		PageReference returnPage;

		if (null != objTicket) {
			// Increament EROutreach count
			Decimal decCount = objTicket.ER_Outreach_count__c == null ? 0 : objTicket.ER_Outreach_count__c;
			objTicket.ER_Outreach_count__c = decCount + 1;

			String cmnt = '[' + system.now() + ']' + comments;

			objTicket.ER_Outreach_Comments__c = String.isBlank(objTicket.ER_Outreach_Comments__c) ? cmnt : objTicket.ER_Outreach_Comments__c + '\n' + cmnt;

			// Set latest ER Outreach Clicked date
			objTicket.ER_Outreach_Date__c = system.today();

			// Assign ticket to Onboarding Advocate on Benefit Order
			objTicket.OwnerId = objTicket.Benefit_Order__r.OwnerId;

			//Set ticket Status
			objTicket.Status__c = 'ER Outreach Required';

			Carrier_Order__c objCO = new Carrier_Order__c(Id = objTicket.Carrier_Order__c, Implementation_Stage__c = 'Awaiting Routing');

			update objTicket;
			update objCO;

			returnPage = new PageReference(strReturnURL);
		}

		return returnPage;
	}
}