public class TransitionToNotesOnCODetailExt {
	string currentRecordId;
	public QA_Lines_Of_Coverage__c QALObj { get; set; }
	public Transition_to_Fulfillment__c TtqObj { get; set; }
	public list<QA_Sheet__c> lstQARec { get; set; }
	public QA_Sheet__c QAObj { get; set; }
	public Carrier_Order__c CarrierOrderObj { get; private set; }
	//boolean for checking if the carrier is Tadas
	public Boolean blnIsCarrierTadas { get; set; }
	Id ttfBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');
	Id ttfRenewalRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
	Id ttfNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
	Id ttfChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
	Id ttfSubmissionNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
	Id ttfSubmissionRenwChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');
	Id ttfConfrimationNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation New Plan');
	Id ttfConfrimationRenewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation Renewal/Change');

	//[BS : 15 Sep 2020] Declare two variable strHippoURL & blnMemberOfQASheetPilotGroup.
	public String strHippoURL { get; set; }

	public TransitionToNotesOnCODetailExt(ApexPages.StandardController sc) {
		QAObj = new QA_Sheet__c();
		TtqObj = new Transition_to_Fulfillment__c();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
		blnIsCarrierTadas = false;
		/*List<QA_Lines_Of_Coverage__c> lstQAL = [select id,name,QA_Sheet__r.id,QA_Sheet__r.name,QA_Sheet__r.Benefit_Order__r.id,Carrier_Order__c 
                                                from QA_Lines_Of_Coverage__c 
                                                where Carrier_Order__c=:currentRecordId];
        if(lstQAL!=Null && lstQAL.size()>0){
            QALObj = lstQAL[0];
        }
        strBOId = QALObj.QA_Sheet__r.Benefit_Order__r.id;*/
		CarrierOrderObj = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE Id = :currentRecordId];

		lstQARec = [
			SELECT
				Id,
				RecordTypeId,
				RecordType.Name,
				Benefit_Order__c,
				Benefit_Order__r.Opportunity__c,
				Benefit_Order__r.Opportunity__r.Source_ID__c,
				Benefit_Order__r.Application_Id__c,
				Benefit_Order__r.Opportunity__r.RecordTypeId,
				Benefit_Order__r.Opportunity__r.RecordType.Name,
				Benefit_Order__r.Account__c,
				Benefit_Order__r.Account__r.ZP_Company_ID__c
			FROM QA_Sheet__c
			WHERE Benefit_Order__c = :CarrierOrderObj.Benefit_Order__c
			ORDER BY createdDate DESC
			LIMIT 1
		];
		if (lstQARec != null && lstQARec.size() > 0) {
			QAObj = lstQARec[0];
		}

		if (CarrierOrderObj != null) {
			List<Transition_to_Fulfillment__c> lstTTQ = [
				SELECT id, Name, Do_they_have_affiliates__c, Parent_Transition_to_fulfillment__c
				FROM Transition_to_Fulfillment__c
				WHERE
					Benefit_Order__c = :CarrierOrderObj.Benefit_Order__c
					AND (recordtypeid = :ttfBorRecType
					OR recordtypeid = :ttfRenewalRecType
					OR recordtypeid = :ttfNewRecType
					OR recordtypeid = :ttfChangeRecType)
			];
			if (lstTTQ != null && lstTTQ.size() > 0) {
				TtqObj = lstTTQ[0];
			}
		}

		if ([SELECT COUNT() FROM QA_Lines_Of_Coverage__c WHERE Carrier_Order__c = :currentRecordId AND Benefits_selected_Carrier__r.Partner_Type__c ='TAdA'] > 0) {
			blnIsCarrierTadas = true;
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
	}
}