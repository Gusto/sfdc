/*
 * @name         TransitionToNotesOnBODetailExt
 * @author
 * @date
 * @description  Controller for TransitionToNotesOnBODetail page to show links to Transition Notes.
 * @test class   TransitionToNotesOnBODetailExtTest
 * @revisions    September 8,2020  ------------ Neha Dabas ------------ Add Confitmation Coverage Email Button for BO Owner(OE Email Automation)
 */
public class TransitionToNotesOnBODetailExt {
	string currentRecordId;
	public QA_Sheet__c QAObj { get; set; }
	public Transition_to_Fulfillment__c TtqObj { get; set; }
	//public Transition_to_Fulfillment__c objTTIA{get;set;}
	public Boolean chkQANotExists { get; set; }
	Id ttfBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');
	Id ttfRenewalRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
	Id ttfNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
	Id ttfChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
	Id ttfSubmissionNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
	Id ttfSubmissionRenwChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');

	//[BS : 17 Aug 2020] Declare two variable strHippoURL & blnMemberOfQASheetPilotGroup.
	public String strHippoURL { get; set; }
	//public Boolean blnMemberOfQASheetPilotGroup{get;set;}

	public Boolean blnShowConfirmationEmailBtn { get; private set; }

	public TransitionToNotesOnBODetailExt(ApexPages.StandardController sc) {
		chkQANotExists = false;
		QAObj = new QA_Sheet__c();
		TtqObj = new Transition_to_Fulfillment__c();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
		//[BS : 17 Aug 2020] Add RecordType.Name, ZP_Company_ID__c & Application_Id__c field in SOQL query.
		List<QA_Sheet__c> qaList = [
			SELECT
				id,
				name,
				Benefits_Point_of_Contact_Name_SFDC__c,
				Mailing_Address__c,
				Effective_Date__c,
				Benefit_Order__c,
				Benefit_Order__r.Account__c,
				Benefit_Order__r.Account__r.ZP_Company_ID__c,
				RecordTypeId,
				Benefit_Order__r.Opportunity__c,
				Benefit_Order__r.Submission_Deadline__c,
				Benefit_Order__r.Type__c,
				Benefit_Order__r.Opportunity__r.Source_ID__c,
				Benefit_Order__r.Opportunity__r.RecordType.Name,
				Benefit_Order__r.Application_Id__c,
				RecordType.Name,
				Benefit_Order__r.Parent_Benefit_Order__c
			FROM QA_Sheet__c
			WHERE Benefit_Order__c = :currentRecordId
			ORDER BY createdDate DESC
		];
		if (qaList != null && qaList.size() > 0) {
			QAObj = qaList[0];
		} else {
			chkQANotExists = true;
		}
		List<Transition_to_Fulfillment__c> lstTTQ = [
			SELECT id, name, Do_they_have_affiliates__c, Parent_Transition_to_fulfillment__c, RecordTypeId
			FROM Transition_to_Fulfillment__c
			WHERE Benefit_Order__c = :currentRecordId AND (recordtypeid = :ttfBorRecType OR recordtypeid = :ttfRenewalRecType OR recordtypeid = :ttfNewRecType OR recordtypeid = :ttfChangeRecType)
			ORDER BY createdDate DESC
		];

		if (lstTTQ != null && lstTTQ.size() > 0) {
			TtqObj = lstTTQ[0];
		}

		/*
		 * [BS : 16 Sep 2020]: - QA Sheet Link Enhancements
		 * If Transition_to_Fulfillment__c records having record type as : 'IA New Plan' & 'IA Renewal/Change'
		 * Then these records consider as TTIA's.
		 * Else, records consider as TTQ.
		 */
		Boolean blnTTIAUpdateBySFDC = false;
		Boolean blnTTIAUpdateByHIPPO = false;

		/*  
         * [BS : 16 Sep 2020]: - QA Sheet Link Enhancements
         * When:- QA sheet link should redirect the user to hippo.
         * Opportunity "Source ID" is not blank AND "Application Id" on "Benefit order" is not blank.
         * On TTF "Do they have affiliates" is false AND On TTF "Parent_Transition_to_fulfillment" is blank.
         * AND meet one of the below-mentioned condition. [BS:25 Sep 2020 - Remove this addtional filter]
               1) [TTIA's] filled in hippo - "Source_last_updated_by__c" hippo. 
               2) If QA_Sheet__c record type is 'Benefit New Plan'  
               3) if QA_Sheet__c record type is 'Benefit Change' & 'Benefit Renewal' & login user added in 'QA_Sheet_Pilot_Group'
        */
		strHippoURL = '';
		if (
			QAObj.RecordTypeId != null &&
			QAObj.Benefit_Order__c != null &&
			QAObj.Benefit_Order__r.Opportunity__c != null &&
			QAObj.Benefit_Order__r.Account__c != null &&
			String.IsNotBlank(QAObj.Benefit_Order__r.Opportunity__r.Source_ID__c) &&
			QAObj.Benefit_Order__r.Application_Id__c != null
		) {
			//Define dynamic hippo url as : http://hippo.gusto.com/companies/company_id/new_plans_applications/application_Id/qa_sheet
			String strSourceId = QAObj.Benefit_Order__r.Opportunity__r.Source_ID__c;
			if (strSourceId.contains('hawaiian_ice-benefit_change_application') || strSourceId.contains('hawaiian_ice-renewal') || strSourceId.contains('hawaiian_ice-new_plans_application')) {
				//Check Record Type
				if (QAObj.Benefit_Order__r.Opportunity__r.RecordType.Name == 'Benefits New Plan') {
					strHippoURL =
						'http://hippo.gusto.com/companies/' +
						QAObj.Benefit_Order__r.Account__r.ZP_Company_ID__c +
						'/new_plans_applications/' +
						QAObj.Benefit_Order__r.Application_Id__c +
						'/qa_sheet';
				} else if (QAObj.Benefit_Order__r.Opportunity__r.RecordType.Name == 'Benefits Change') {
					strHippoURL =
						'http://hippo.gusto.com/companies/' +
						QAObj.Benefit_Order__r.Account__r.ZP_Company_ID__c +
						'/benefit_change_applications/' +
						QAObj.Benefit_Order__r.Application_Id__c +
						'/qa_sheet';
				} else if (QAObj.Benefit_Order__r.Opportunity__r.RecordType.Name == 'Benefits Renewal') {
					strHippoURL = 'http://hippo.gusto.com/companies/' + QAObj.Benefit_Order__r.Account__r.ZP_Company_ID__c + '/renewals/' + QAObj.Benefit_Order__r.Application_Id__c + '/qa_sheet';
				}
			}
		}

		/*
		 * [BS : 16 Sep 2020]: - QA Sheet Link Enhancements
		 * If Qualification Owner is part of the public group AND recordtype of the "QA sheet" is 'Benefit New Plan'
		 * AND TTIA.recordtype='IA New Plan' AND TTIA.Source last updated by:= 'Salesforce',
		 * Then open the QA sheet in salesforce.
		 */
		if (blnTTIAUpdateBySFDC) {
			strHippoURL = '';
		}

		checkQATTIAValidations();

		checkSendConfirmationEmailVisibility();
	}
	/*
	 * @Neha Dabas, To check if Logged in User is authorised to view Confirmation Email Button.
	 */
	private void checkSendConfirmationEmailVisibility() {
		blnShowConfirmationEmailBtn = false;
		Set<String> set_ValidBORecTypes = new Set<String>{ 'Renewal', 'Change', 'New_Plan' };
		Set<String> set_OrderStatusToExclude = new Set<String>{ 'Canceled', 'Closed Admin' };
		Set<String> set_CarriersToExclude = new Set<String>{ CarrierOrderUtil.Name_BASIC};
		Benefit_Order__c objBO;
		List<Benefit_Order__c> list_BO = new List<Benefit_Order__c>();
		list_BO = [
			SELECT
				RecordType.DeveloperName,
				OwnerId,
				Order_Status__c,
				OE_Complete__c,
				(
					SELECT Id
					FROM Cases__r
					WHERE Integration_Id__c != NULL AND Carrier_Order__c = NULL
					LIMIT 1
				),
				(
					SELECT Order_Assignment__c, Carrier__r.Carrier_Unique_Name__c, Group_Number__c
					FROM Carrier_Orders__r
					WHERE
						Order_Assignment__c != NULL
						AND Carrier__c != NULL
						AND Implementation_Stage__c NOT IN :set_OrderStatusToExclude
						AND Carrier__r.Carrier_Unique_Name__c NOT IN :set_CarriersToExclude
						AND Carrier__r.Partner_Type__c != :CarrierOrderUtil.PARTNER_TYPE_TADA
				)
			FROM Benefit_Order__c
			WHERE Id = :currentRecordId
		];
		if (list_BO != null && !list_BO.isEmpty()) {
			objBO = list_BO[0];
		}
		if (objBO != null && set_ValidBORecTypes.contains(objBO.RecordType.DeveloperName) && objBO.Order_Status__c == 'Approved') {
			if (objBO.Cases__r == null || objBO.Cases__r.isEmpty()) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'No Customer case associated with this Benefit Order.'));
				return;
			}

			Map<Id, Integer> map_ExistingEmailCount = OEEmailAutomationHelper.fetchSentEmailCountForCases(new Set<Id>{ objBO.Cases__r[0].Id }, new Set<String>{ 'OE_Confirmation_Email_Default' });

			if (map_ExistingEmailCount != null && map_ExistingEmailCount.containsKey(objBO.Cases__r[0].Id) && map_ExistingEmailCount.get(objBO.Cases__r[0].Id) > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Coverage Confirmation Email has been sent for this Benefit Order.'));
				return;
			}
			if (objBO.Carrier_Orders__r != null && !objBO.Carrier_Orders__r.isEmpty()) {
				for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
					if (
						(objCO.Order_Assignment__c.containsIgnoreCase('New to Gusto') ||
						objCO.Order_Assignment__c.containsIgnoreCase('new line of coverage') ||
						objCO.Order_Assignment__c.containsIgnoreCase('Carrier switch')) && String.isBlank(objCO.Group_Number__c)
					) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Group number is missing from either Hippo or salesforce, send email manually'));
						return;
					}
				}
			}
			blnShowConfirmationEmailBtn = true;
		}
	}
	/*
	 * @Neha Dabas, Call SendConfirmationEmail function.
	 */
	public void invokeConfirmationEmail() {
		OEEmailAutomationHelper.sendConfirmationEmail((Id) currentRecordId);
	}

	//BY:PR, Date: Sep-17-2020, Desc: Show error on BO detail page for user convenience
	public void checkQATTIAValidations() {
		Set<String> set_QACoveragesRequiredFieldsName = new Set<String>{ 'Participation_Requirements__c' };
		//controller.getRequiredFieldsAsPerOrderType();
		//controller.checkRequiredFields();

		if (QAObj.Benefit_Order__c != null && QAObj.Benefit_Order__r.Submission_Deadline__c == null && QAObj.Benefit_Order__r.Type__c == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please review the benefit order and confirm order has an order type/submission deadline'));
		} else if (QAObj.Benefit_Order__c != null && QAObj.Benefit_Order__r.Submission_Deadline__c == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please review the benefit orders and confirm order has a submission deadline'));
		} else if (QAObj.Benefit_Order__c != null && QAObj.Benefit_Order__r.Type__c == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please review the benefit orders and confirm order has an order type'));
		}

		String strCarrierNames = '';
		if (String.isNotBlank(QAObj.Benefit_Order__c)) {
			for (Carrier_Order__c ObjCarrierOrder : [
				SELECT Id, Name, Order_Type__c, Submission_Deadline_Date__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :QAObj.Benefit_Order__c AND (Order_Type__c = NULL OR Submission_Deadline_Date__c = NULL)
			]) {
				if (ObjCarrierOrder.Order_Type__c == null || ObjCarrierOrder.Submission_Deadline_Date__c == null) {
					strCarrierNames += ObjCarrierOrder.Name + ', ';
				}
			}
		}

		if (String.isNotBlank(strCarrierNames)) {
			strCarrierNames = strCarrierNames.removeEnd(', ');
			String strErrorMessage = 'Review carrier orders - ';
			strErrorMessage += strCarrierNames + ' missing order type/submission deadline';
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strErrorMessage));
		}
	}
}