public class DisplayEditTTConfirmationExt {
	public Transition_to_Fulfillment__c objTTF { get; set; }
	public Transition_to_Fulfillment__c objTTQ { get; set; }

	public Map<Id, Boolean> map_ShowTTQForQALine { get; set; }
	public Map<String, String> map_FieldAPILabel { get; set; }
	public Map<Id, Set<String>> map_TTQAsPerCOOrderAssignement { get; set; }

	public list<QA_Lines_Of_Coverage__c> lstQALinesOfCoverage { get; set; } // to display lines of coverage for a specific type
	public Set<String> set_OrderAssignment = OrderUtils.set_OrderAssignment;

	/* Lines of coverage type variables*/
	public String StrParam { get; set; }
	public boolean Medicaltab { get; set; }
	public boolean Dentaltab { get; set; }
	public boolean Visiontab { get; set; }
	public boolean Lifetab { get; set; }
	public boolean LTDtab { get; set; }
	public boolean STDtab { get; set; }
	public boolean FSAtab { get; set; }
	public boolean DCAtab { get; set; }
	public boolean HSAtab { get; set; }
	public boolean Commutertab { get; set; }
	/* Lines of coverage type variables*/

	private Id idCurrentCO;
	private String strQAId;
	private string idCurrentBO;
	public QA_Sheet__c QAObj { get; set; }
	public list<QA_Lines_Of_Coverage__c> QALinesOfCoverage;
	public Boolean chkErrors = false;
	public string scriptvar { get; set; }
	public Boolean blnIsRecBO { get; set; } // true if TTC is opened from Benefit Order
	public String accCompanyId { get; set; }
	public Boolean isPoliciesExist { get; set; }

	/*Dynamic text area rows variables*/

	//Key is Id/ObjName and value is Map<FieldAPINAme,Rowcount>
	public Map<String, Map<String, Integer>> map_RowCountTextArea { get; set; }

	//Text area fields on TTC record to be scaled dynamically
	Set<String> set_TTCTextAreaFields = new Set<String>{ 'NHEs_that_were_submitted_with_group__c', 'State_continuation_enrollees_submitted__c', 'Anticipated_pending_items_anything_inte__c' };

	//Text area fields on QA Lines of coverage records to be scaled dynamically
	Set<String> set_QALinesTextAreaFields = new Set<String>{ 'Other_items_to_note_for_this_group__c', 'Documents_Require_for_Submission__c' };

	/*Dynamic text area rows variables*/

	public DisplayEditTTConfirmationExt(ApexPages.StandardController controller) {
		//get page parameters
		idCurrentCO = ApexPages.currentPage().getParameters().get('cid');
		idCurrentBO = ApexPages.currentPage().getParameters().get('bid');

		blnIsRecBO = false;
		objTTF = new Transition_to_Fulfillment__c();
		QAObj = new QA_Sheet__c();
		map_TTQAsPerCOOrderAssignement = new Map<Id, Set<String>>();
		map_FieldAPILabel = new Map<String, String>();
		map_ShowTTQForQALine = new Map<Id, Boolean>();

		Schema.SObjectType objectType = QA_Sheet__c.getSObjectType();
		List<String> qafields = new List<string>(objectType.getDescribe().fields.getMap().keySet());

		Schema.SObjectType ttfobjectType = Transition_to_Fulfillment__c.getSObjectType();
		List<String> ttffields = new List<string>(ttfobjectType.getDescribe().fields.getMap().keySet());

		Id ttfBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BoR');
		Id qanewRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
		Id qaRenewalRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');
		Id qaChangeRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Change');
		Id ttfqnewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Id ttfqRenewalRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
		Id ttfqChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Id ttfSubmissionNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
		Id ttfSubmissionRenwChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');
		Id ttfconfirmationNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation New Plan');
		Id ttfconfirmationRenwChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation Renewal/Change');

		if (idCurrentCO != null) {
			string soql =
				'select ' +
				String.join(qafields, ',') +
				',Benefit_Order__r.recordtype.developername,recordtype.developername,Benefit_Order__r.Opportunity__c,Benefit_Order__r.Opportunity__r.Account.ZP_Company_ID__c,Benefit_Order__r.id,Benefit_Order__r.ownerid,Benefit_Order__r.Opportunity__r.Accountid,Benefit_Order__r.Opportunity__r.ownerid from QA_Sheet__c where Benefit_Order__c IN (SELECT Benefit_Order__c FROM Carrier_Order__c WHERE Id=:idCurrentCO ) ORDER BY createdDate DESC LIMIT 1';
			QAObj = Database.query(soql);
		} else if (idCurrentBO != '') {
			string soql =
				'select ' +
				String.join(qafields, ',') +
				',Benefit_Order__r.recordtype.developername,recordtype.developername,Benefit_Order__r.Opportunity__c,Benefit_Order__r.Opportunity__r.Account.ZP_Company_ID__c,Benefit_Order__r.id,Benefit_Order__r.ownerid,Benefit_Order__r.Opportunity__r.Accountid,Benefit_Order__r.Opportunity__r.ownerid from QA_Sheet__c where Benefit_Order__c = :idCurrentBO ORDER BY createdDate DESC LIMIT 1';
			QAObj = Database.query(soql);
		}
		id oppid;

		if (QAObj != null) {
			oppid = QAObj.Benefit_Order__r.Opportunity__c;
			accCompanyId = QAObj.Benefit_Order__r.Opportunity__r.Account.ZP_Company_ID__c;
		}

		//TTConfirmation existing record.
		string ttfsoql =
			'select ' +
			String.join(ttffields, ',') +
			',Account__r.Anchor_Pay_Date__c,Account__r.id from Transition_to_Fulfillment__c where Opportunity__c =: oppid and (recordtypeid =: ttfconfirmationNewRecType  or recordtypeid =: ttfconfirmationRenwChangeRecType)';
		list<Transition_to_Fulfillment__c> lstTTCExistingRec = Database.query(ttfsoql);
		if (lstTTCExistingRec.size() > 0) {
			objTTF = lstTTCExistingRec[0];
		}

		if (QAObj != null && lstTTCExistingRec.size() == 0) {
			if (QAObj.recordtypeid == qanewRecType)
				objTTF.recordtypeid = ttfconfirmationNewRecType;
			else if (QAObj.recordtypeid == qaRenewalRecType || QAObj.recordtypeid == qaChangeRecType)
				objTTF.recordtypeid = ttfconfirmationRenwChangeRecType;
			objTTF.Benefit_Order__c = QAObj.Benefit_Order__c;
			objTTF.Opportunity__c = QAObj.Benefit_Order__r.Opportunity__c;
			objTTF.Account__c = QAObj.Benefit_Order__r.Opportunity__r.Accountid;
			objTTF.Benefit_Advisor__c = QAObj.Benefit_Order__r.Opportunity__r.ownerid;
			objTTF.Implementation_Advocate__c = QAObj.Benefit_Order__r.ownerid;
		}

		map_RowCountTextArea = new Map<String, Map<String, Integer>>();
		map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ objTTF }, set_TTCTextAreaFields, map_RowCountTextArea);

		// getting TTq record
		string ttfqsoql =
			'select ' +
			String.join(ttffields, ',') +
			',Account__r.Anchor_Pay_Date__c from Transition_to_Fulfillment__c where Opportunity__c =: oppid and (recordtypeid =: ttfBorRecType or recordtypeid =: ttfqnewRecType or recordtypeid =: ttfqRenewalRecType or recordtypeid =: ttfqChangeRecType)';
		list<Transition_to_Fulfillment__c> lstTTQ = Database.query(ttfqsoql);

		if (lstTTQ.size() > 0) {
			objTTQ = lstTTQ[0];
			if (lstTTCExistingRec.size() == 0) {
				objTTF.Benefits_Point_of_Contact__c = objTTQ.Benefits_Point_of_Contact__c;

				objTTF.Do_they_have_affiliates__c = objTTQ.Do_they_have_affiliates__c;
				objTTF.DBA__c = objTTQ.DBA__c;
				objTTF.Composite_Rated__c = objTTQ.Composite_Rated__c;
			}
		}

		//Get TTS record
		String strTTSQuery =
			'SELECT ' +
			String.join(ttffields, ',') +
			' FROM Transition_to_Fulfillment__c WHERE Opportunity__c =: oppid AND (recordtypeid =: ttfSubmissionNewRecType OR recordtypeid =: ttfSubmissionRenwChangeRecType) LIMIT 1';
		List<Transition_to_Fulfillment__c> lstTTS = Database.query(strTTSQuery);

		if (null != lstTTS && lstTTS.size() > 0 && lstTTCExistingRec.size() == 0) {
			objTTF.Anticipated_pending_items_anything_inte__c = lstTTS[0].Anticipated_pending_items_anything_inte__c;
		}

		//QA Line
		Schema.SObjectType objectTypeQAl = QA_Lines_Of_Coverage__c.getSObjectType();
		List<String> QALinesFields = new List<string>(objectTypeQAl.getDescribe().fields.getMap().keySet());
		string soqlQAL;
		if (String.isNotBlank(idCurrentCO))
			soqlQAL =
				'SELECT ' +
				String.join(QALinesFields, ',') +
				',Carrier_Order__r.Automated_Submission__c,Carrier_Order__r.Order_Assignment__c,Benefits_selected_Carrier__r.Carrier_Wiki__c FROM QA_Lines_Of_Coverage__c WHERE QA_Sheet__c =\'' +
				QAObj.Id +
				'\' AND Carrier_Order__c =: idCurrentCO';
		else if (idCurrentBO != '')
			soqlQAL =
				'SELECT ' +
				String.join(QALinesFields, ',') +
				',Carrier_Order__r.Automated_Submission__c,Carrier_Order__r.Order_Assignment__c,Benefits_selected_Carrier__r.Carrier_Wiki__c FROM QA_Lines_Of_Coverage__c WHERE QA_Sheet__c =\'' +
				QAObj.Id +
				'\'';
		QALinesOfCoverage = Database.query(soqlQAL);
		string tastring;
		if (QALinesOfCoverage != null && QALinesOfCoverage.size() > 0) {
			isPoliciesExist = false;
			Set<String> set_AllTTQFieldName = new Set<String>();

			for (QA_Lines_Of_Coverage__c objQAlines : QALinesOfCoverage) {
				objQAlines.Carrier_Wiki__c = objQAlines.Benefits_selected_Carrier__r.Carrier_Wiki__c;
				/*TTQ Fields*/
				map_ShowTTQForQALine.put(objQAlines.Id, false);

				if (
					(QAObj.recordtype.developername == 'Benefit_Renewal' ||
					QAObj.recordtype.developername == 'Benefit_Change') &&
					objQAlines.Carrier_Order__c != null &&
					!String.isBlank(objQAlines.Carrier_Order__r.Order_Assignment__c) &&
					(!set_OrderAssignment.isEmpty() && set_OrderAssignment.contains(objQAlines.Carrier_Order__r.Order_Assignment__c)) &&
					!String.isBlank(objQAlines.Lines_Of_Coverage__c) &&
					(objQAlines.Lines_Of_Coverage__c != 'HSA' ||
					objQAlines.Lines_Of_Coverage__c != 'Commuter' ||
					objQAlines.Lines_Of_Coverage__c != 'Flexible Spending Account - Medical' ||
					objQAlines.Lines_Of_Coverage__c != 'Flexible Spending Account - Dependent Care') &&
					null != objTTQ
				) {
					Set<String> strFieldName = OrderUtils.getTTQFieldsAsPerCOOrderAssignment(objQAlines.Lines_Of_Coverage__c);
					set_AllTTQFieldName.addAll(strFieldName);
					map_TTQAsPerCOOrderAssignement.put(objQAlines.Id, strFieldName);
					map_ShowTTQForQALine.put(objQAlines.Id, true);
				}

				if (objQAlines.Lines_Of_Coverage__c != '' && objQAlines.Lines_Of_Coverage__c != null)
					tastring += ':' + objQAlines.Lines_Of_Coverage__c;
			}

			map_RowCountTextArea = OrderUtils.setRowCountForTextArea(QALinesOfCoverage, set_QALinesTextAreaFields, map_RowCountTextArea);
			for (String strTmp : set_AllTTQFieldName) {
				map_FieldAPILabel.put(strTmp, OrderUtils.getFieldAPIName('QA_Lines_Of_Coverage__c', strTmp));
			}
		} else {
			isPoliciesExist = true;
		}
		if (tastring != '' && tastring != null) {
			Medicaltab = tastring.contains(':Medical') ? true : false;
			Dentaltab = tastring.contains(':Dental') ? true : false;
			Visiontab = tastring.contains('Vision') ? true : false;
			Lifetab = tastring.contains('Life') ? true : false;
			LTDtab = tastring.contains('LTD') || tastring.contains('Long Term Disability') ? true : false;
			STDtab = tastring.contains('STD') || tastring.contains('Short Term Disability') ? true : false;
			FSAtab = tastring.contains('FSA') || tastring.contains('Flexible Spending Account - Medical') ? true : false; //(Flexible Spending Account - Medical) or (FSA)
			DCAtab = tastring.contains('DCA') || tastring.contains('Flexible Spending Account - Dependent Care') ? true : false;
			HSAtab = tastring.contains('HSA') ? true : false;
			Commutertab = tastring.contains('Commuter') ? true : false;
		}
	} // end of constructor
	public Boolean checkRequiredFields() {
		chkErrors = false;
		//for checking the mandatory fields
		if (string.isblank(objTTF.NHEs_that_were_submitted_with_group__c)) {
			chkErrors = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'NHEs that were submitted with group : Please Enter a value'));
		}
		if (string.isblank(objTTF.State_continuation_enrollees_submitted__c)) {
			chkErrors = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'State continuation enrollees submitted : Please Enter a value'));
		}
		if (!QALinesOfCoverage.isEmpty()) {
			for (QA_Lines_Of_Coverage__c qline : QALinesOfCoverage) {
				if (string.isblank(qline.Allows_plans_with_no_enrollees__c)) {
					chkErrors = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Allows plans with no enrollees? : Please Enter a value'));
				}
				if (string.isblank(qline.Should_policy_year_be_anything__c)) {
					chkErrors = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Should policy year be anything other than 12 months? : Please Enter a value'));
				}
				if (string.isblank(qline.Other_items_to_note_for_this_group__c)) {
					chkErrors = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Other items to note for this group : Please Enter a value'));
				}
			}
		}

		return chkErrors;
	}

	public pagereference customsave() {
		try {
			if (QALinesOfCoverage != null && QALinesOfCoverage.size() > 0) {
				update QALinesOfCoverage;

				map_RowCountTextArea = OrderUtils.setRowCountForTextArea(QALinesOfCoverage, set_QALinesTextAreaFields, map_RowCountTextArea);
			}
			if (objTTF != null) {
				upsert objTTF;

				map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ objTTF }, set_TTCTextAreaFields, map_RowCountTextArea);
			}
		} catch (DmlException e) {
			chkErrors = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return null;
	}

	public pagereference MoveToConfirmation() {
		if (!checkRequiredFields()) {
			pagereference pg = customsave();
			if (chkErrors) {
				return null;
			}
			List<Carrier_Order__c> lstCarrierOrder = [
				SELECT Id, Name, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Carrier__c, Effective_Date__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :QAObj.Benefit_Order__c AND id = :idCurrentCO
			];

			if (!lstCarrierOrder.isEmpty()) {
				for (Carrier_Order__c coObj : lstCarrierOrder) {
					if (
						coObj.Implementation_Stage__c != 'Approved' ||
						coObj.Implementation_Stage__c != 'Canceled' ||
						coObj.Implementation_Stage__c != 'Closed Lost' ||
						coObj.Implementation_Stage__c != 'Closed Admin'
					) {
						coObj.Implementation_Stage__c = 'Ready for Confirmation';
					}
				}
				OnboardingPlayModeUtility.setFirstPlayDateForCarrierOrders('Order', lstCarrierOrder);
			}
			//DS[08-10-2020] https://app.asana.com/0/1195411211351298/1168663648856807
			//lstCarrierOrder is old code.. no change in the existing variable name
			Map<Id, Carrier_Order__c> map_CarrierOrderToBeUpdated = new Map<Id, Carrier_Order__c>();
			if (lstCarrierOrder != null && lstCarrierOrder.size() > 0) {
				for (Carrier_Order__c objCO : lstCarrierOrder) {
					map_CarrierOrderToBeUpdated.put(objCO.Id, objCO);
				}
				List<Carrier_Order__c> list_ChildCarrierOrder = getChildCarrierOrderStatus();
				if (!list_ChildCarrierOrder.isEmpty()) {
					for (Carrier_Order__c objChildCO : list_ChildCarrierOrder) {
						map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
					}
				}
				if (!map_CarrierOrderToBeUpdated.isEmpty()) {
					update map_CarrierOrderToBeUpdated.values();
				}
			}
			scriptvar = '<script> RefreshPrimaryTab(); </script>';
		}
		return null;
	}
	public List<Carrier_Order__c> getChildCarrierOrderStatus() {
		List<Carrier_Order__c> lstChildCarrierOrder = new List<Carrier_Order__c>();
		for (Carrier_Order__c co : [SELECT id, name FROM Carrier_Order__c WHERE Parent_Carrier_Order__c = :idCurrentCO]) {
			co.Implementation_Stage__c = 'Ready for Confirmation';
			lstChildCarrierOrder.add(co);
		}
		return lstChildCarrierOrder;
	}

	public PageReference DisplayRec() {
		lstQALinesOfCoverage = new List<QA_Lines_Of_Coverage__c>();

		for (QA_Lines_Of_Coverage__c qloc : QALinesOfCoverage) {
			if (qloc.Lines_Of_Coverage__c == StrParam) {
				lstQALinesOfCoverage.add(qloc);
			}
			if (
				(StrParam == 'FSA' &&
				qloc.Lines_Of_Coverage__c == 'Flexible Spending Account - Medical') ||
				(StrParam == 'DCA' &&
				qloc.Lines_Of_Coverage__c == 'Flexible Spending Account - Dependent Care') ||
				(StrParam == 'LTD' &&
				qloc.Lines_Of_Coverage__c == 'Long Term Disability') ||
				(StrParam == 'STD' &&
				qloc.Lines_Of_Coverage__c == 'Short Term Disability')
			) {
				lstQALinesOfCoverage.add(qloc);
			}
		}

		return null;
	}
}