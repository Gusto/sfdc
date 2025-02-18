public class CustomerFeedbackExtension {
	public Customer_Feedback__c objCustomerFeedback { get; set; }
	public Opportunity oppRec;
	public Account accRec;
	public List<Opportunity> list_PayrollOppRec;
	public Boolean blnIsAccountingFirm { get; set; }
	public Boolean blnIsClientOfAccountant { get; set; }
	public Boolean blnShowResellerClient { get; set; }
	String strOrderId;
	public Case objCase;
	public String strLabel { get; set; }
	public static final Id RENEWAL_CASE_RT_ID = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
	public static final Id ADVISING_FEEDBACK_RT_ID = Cache.getRecordTypeId('Customer_Feedback__c', 'Advising Feedback');
	public static final String LABEL_BENEFITS = 'Benefits';
	public static final Id COMPANY_OPPORTUNITY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Acquisition');
	public static final Id RESELLER_ACCOUNT_RT_ID = Cache.getRecordTypeId('Account', 'Reseller');
	public static final Id ACCOUNTING_FIRM_RT_ID = Cache.getRecordTypeId('Customer_Feedback__c', 'Accounting Firm');
	public static final Id COMPANY_ACCOUNT_RT_ID = Cache.getRecordTypeId('Account', 'Company');
	public static final Id CLIENT_OF_ACCOUNTANT_RT_ID = Cache.getRecordTypeId('Customer_Feedback__c', 'Client of Accountant');
	public static final Id DIRECT_PAYROLL_RT_ID = Cache.getRecordTypeId('Customer_Feedback__c', 'Direct Payroll');
	public static final String LABEL_SALES_FEEDBACK = 'Sales Feedback';
	public static final String LABEL_ADVISING_FEEDBACK = 'Benefits Advising Feedback';

	public CustomerFeedbackExtension(ApexPages.StandardController controller) {
		objCustomerFeedback = new Customer_Feedback__c();
		String strCaseId = ApexPages.CurrentPage().getParameters().get('caseId');
		String strOpportunityId = apexpages.currentpage().getparameters().get('OppId');
		String strAccountId = apexpages.currentpage().getparameters().get('accId');
		String strLeadId = apexpages.currentpage().getparameters().get('leadId');
		strOrderId = apexpages.currentpage().getparameters().get('orderId');
		list_PayrollOppRec = new List<Opportunity>();
		Opportunity payrollOpp;
		String companyOpptyRecType = COMPANY_OPPORTUNITY_RT_ID;

		blnIsAccountingFirm = false;
		blnIsClientOfAccountant = false;
		blnShowResellerClient = false;
		strLabel = LABEL_SALES_FEEDBACK;
		// Added by Chandrika
		// Get Opportunity Record
		if (!String.isBlank(strOpportunityId))
			oppRec = [SELECT Id, AccountId, Sold_By__c, Referred_By__c, RecordTypeId, RecordType.Name, StageName FROM Opportunity WHERE Id = :strOpportunityId LIMIT 1];

		// Get Account Record
		if (!String.isBlank(strAccountId)) {
			accRec = [SELECT Id, RecordTypeId, RecordType.Name, Partner_Status__c, Sold_By__c, Referred_By__c FROM Account WHERE Id = :strAccountId LIMIT 1];
			list_PayrollOppRec = [
				SELECT Id, Name, StageName, AccountId, CreatedDate
				FROM Opportunity
				WHERE AccountId = :strAccountId AND RecordTypeId = :COMPANY_OPPORTUNITY_RT_ID
				ORDER BY CreatedDate DESC
				LIMIT 1
			];
			if (list_PayrollOppRec != null && list_PayrollOppRec.Size() > 0)
				payrollOpp = list_PayrollOppRec[0];
		}

		if (String.isNotBlank(strCaseId)) {
			objCase = [SELECT Id, AccountId, Opportunity__c, RecordTypeId, RecordType.Name, ContactId FROM Case WHERE Id = :strCaseId LIMIT 1];
			strLabel = LABEL_ADVISING_FEEDBACK;
		}

		if (objCase != null && objCase.RecordTypeId == RENEWAL_CASE_RT_ID && objCase.ContactId != null) {
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = ADVISING_FEEDBACK_RT_ID);
			objCustomerFeedback.Opportunity__c = objCase.Opportunity__c;
			objCustomerFeedback.Account__c = objCase.AccountId;
			objCustomerFeedback.Case__c = objCase.Id;
			objCustomerFeedback.Reporting_Level__c = LABEL_BENEFITS;
		}

		//Feedback associated to Reseller Account
		if (accRec != null && accRec.RecordTypeId == RESELLER_ACCOUNT_RT_ID) {
			blnIsAccountingFirm = true;
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = ACCOUNTING_FIRM_RT_ID);
			objCustomerFeedback.Partner_Status__c = accRec.Partner_Status__c;
		}

		//Feedback associated to Client
		//Account
		if (accRec != null && accRec.RecordTypeId == COMPANY_ACCOUNT_RT_ID && (accRec.Sold_By__c != null || accRec.Referred_By__c != null)) {
			blnIsClientOfAccountant = true;
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = CLIENT_OF_ACCOUNTANT_RT_ID);
			objCustomerFeedback.Opportunity_Stage__c = (payrollOpp != null) ? payrollOpp.StageName : null;
			objCustomerFeedback.Opportunity__c = (payrollOpp != null) ? payrollOpp.Id : null;
		} else if (accRec != null && accRec.RecordTypeId == COMPANY_ACCOUNT_RT_ID) {
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = DIRECT_PAYROLL_RT_ID);
			objCustomerFeedback.Opportunity_Stage__c = (payrollOpp != null) ? payrollOpp.StageName : null;
			objCustomerFeedback.Opportunity__c = (payrollOpp != null) ? payrollOpp.Id : null;
		}

		//Opportunity
		if (oppRec != null && oppRec.RecordTypeId == COMPANY_OPPORTUNITY_RT_ID && (oppRec.Sold_By__c != null || oppRec.Referred_By__c != null)) {
			blnIsClientOfAccountant = true;
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = CLIENT_OF_ACCOUNTANT_RT_ID);
			objCustomerFeedback.Opportunity_Stage__c = oppRec.StageName;
		} else if (oppRec != null && oppRec.RecordTypeId == COMPANY_OPPORTUNITY_RT_ID && oppRec.Sold_By__c == null && oppRec.Referred_By__c == null) {
			objCustomerFeedback = new Customer_Feedback__c(RecordTypeId = DIRECT_PAYROLL_RT_ID);
			objCustomerFeedback.Opportunity_Stage__c = oppRec.StageName;
		}

		objCustomerFeedback.Opportunity__c = (objCustomerFeedback.Opportunity__c != null) ? objCustomerFeedback.Opportunity__c : strOpportunityId;
		objCustomerFeedback.Account__c = (objCustomerFeedback.Account__c != null) ? objCustomerFeedback.Account__c : strAccountId;
		objCustomerFeedback.Lead__c = strLeadId;

		// To show flow for non-direct
		if (blnIsAccountingFirm || blnIsClientOfAccountant)
			blnShowResellerClient = true;
	}

	public void refresh() {
	}

	// Modified by Chandrika : 07-27-2020
	// Replaced with calling getPickListValues method
	public List<SelectOption> getTypes() {
		return getPickListValues(objCustomerFeedback, 'Priority__c');
	}

	// Added by Chandrika : 07-27-2020
	public List<SelectOption> getPainScale() {
		return getPickListValues(objCustomerFeedback, 'Scale_of_Painful__c');
	}

	// Added by Chandrika : 07-27-2020
	public List<SelectOption> getPainFrequency() {
		return getPickListValues(objCustomerFeedback, 'Frequency_of_Partner_Feeling_Pain__c');
	}

	// Added by Chandrika : 07-27-2020
	public List<SelectOption> getFeedbackImp() {
		return getPickListValues(objCustomerFeedback, 'Feedback_Importance__c');
	}

	// Added by Chandrika : 07-27-2020
	public List<SelectOption> getPickListValues(Sobject object_Name, String field_Name) {
		Schema.sObjectType sobject_type = object_Name.getSObjectType(); //grab the sobject that was passed
		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();

		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();
		List<Schema.PicklistEntry> pick_list_values = field_map.get(field_Name).getDescribe().getPickListValues();

		List<selectOption> options = new List<selectOption>();

		for (Schema.PicklistEntry a : pick_list_values) {
			options.add(new selectOption(a.getLabel(), a.getValue()));
		}
		return options;
	}

	public pageReference saveRecord() {
		try {
			upsert objCustomerFeedback;
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
		}

		PageReference objPageReference;
		if (objCustomerFeedback.Case__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Case__c);
		} else if (objCustomerFeedback.opportunity__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Opportunity__c);
		} else if (objCustomerFeedback.Account__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Account__c);
		} else if (objCustomerFeedback.Lead__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Lead__c);
		}

		if (strOrderId != null) {
			objPageReference = new PageReference('/' + strOrderId);
		}

		objPageReference.setRedirect(true);
		return objPageReference;
	}

	public pageReference cancelRecord() {
		PageReference objPageReference;
		if (objCustomerFeedback.Case__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Case__c);
		} else if (objCustomerFeedback.opportunity__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Opportunity__c);
		} else if (objCustomerFeedback.Account__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Account__c);
		} else if (objCustomerFeedback.Lead__c != null) {
			objPageReference = new PageReference('/' + objCustomerFeedback.Lead__c);
		}

		if (strOrderId != null) {
			objPageReference = new PageReference('/' + strOrderId);
		}

		objPageReference.setRedirect(true);
		return objPageReference;
	}

	public pageReference savenextrecord() {
		try {
			upsert objCustomerFeedback;
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
		}

		PageReference objPageReference = new Pagereference('/apex/CustomerFeedbackPage');
		if (objCustomerFeedback.Case__c != null) {
			objPageReference.getParameters().put('caseId', objCustomerFeedback.Case__c);
		} else {
			if (objCustomerFeedback.opportunity__c != null) {
				objPageReference.getParameters().put('OppId', objCustomerFeedback.Opportunity__c);
			}
			if (objCustomerFeedback.Account__c != null) {
				objPageReference.getParameters().put('accId', objCustomerFeedback.Account__c);
			}
			if (objCustomerFeedback.Lead__c != null) {
				objPageReference.getParameters().put('leadId', objCustomerFeedback.Lead__c);
			}
			if (strOrderId != null) {
				objPageReference.getParameters().put('orderId', strOrderId);
			}
		}

		objPageReference.setRedirect(true);
		return objPageReference;
	}
}