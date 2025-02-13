public with sharing class EmailCarrierCaseExtension {
	public Case objCase { get; private set; }
	public String strToEmail { get; private set; }
	public String strFromEmailAddresses { get; private set; }
	public static final String MF_TERMINATION_RT = 'MF Termination';
	public static final String CASE_TYPE_CT = 'Continuation Termination';
	public static final String MF_NHE_RT = 'MF NHE';
	public static final String CASE_TYPE_CE = 'Continuation Enrollment';
	public static final String FROM_EMAIL_MF = 'memberfulfillment@gusto.com';
	public static final String FROM_EMAIL_COBRA = 'cobra@gusto.com';
	public Boolean blnShowFromAddress { get; set; }

	public EmailCarrierCaseExtension(ApexPages.StandardController objStdcontroller) {
		objCase = (Case) objStdcontroller.getRecord();
		blnShowFromAddress = false;
		objCase = [SELECT Id, Carrier__c, Carrier__r.Submission_Email__c, Contact.Email, RecordType.Name, Type, RecordTypeId FROM Case WHERE Id = :objCase.id];

		if (objCase != null) {
			strToEmail = '';
			if (objCase.carrier__c != null && objCase.carrier__r.Submission_Email__c != null) {
				strToEmail = objCase.carrier__r.Submission_Email__c;
			}

			strFromEmailAddresses = FROM_EMAIL_MF;
			if (
				(objCase.RecordType.Name == MF_TERMINATION_RT && CASE_TYPE_CT.equalsIgnoreCase(objCase.Type)) || (objCase.RecordType.Name == MF_NHE_RT && CASE_TYPE_CE.equalsIgnoreCase(objCase.Type))
			) {
				strFromEmailAddresses += ',' + FROM_EMAIL_COBRA;
				blnShowFromAddress = true;
			}
		}
	}
}