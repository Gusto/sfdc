/**
Created by : Anshul Agrawal
Created Date : 02/20/2018
**/
public with sharing class CaseFeatureRequestExtension {
	private ApexPages.StandardController standardController;
	private Case caseSelected { get; set; }
	public String selectedFeature { get; set; }
	public String selectedFeatureComment { get; set; }
	private Id caseAccountId;
	private Id caseId;
	// Standard Set Controller
	public ApexPages.StandardSetController setCon { get; set; }

	public CaseFeatureRequestExtension(ApexPages.StandardController standardController) {
		this.standardController = standardController;
		caseId = standardController.getId();
		caseSelected = [SELECT CaseNumber, ContactId, AccountId, OwnerId FROM Case WHERE id = :caseId];
		caseAccountId = caseSelected.AccountId;
		caseFeatureList = new List<Feature_Request__c>();
		this.getCaseRequestedFeatures();
	}

	public List<Feature_Request__c> caseFeatureList {
		get {
			if (setCon != null) {
				return (List<Feature_Request__c>) setCon.getRecords();
			} else
				return null;
		}
		set;
	}

	public List<SelectOption> featureList {
		get {
			// do a field describe of the picklist field
			Schema.DescribeFieldResult describeResult = Feature_Request__c.Feature__c.getDescribe();
			// get the picklist values from this describe result
			List<Schema.PicklistEntry> entries = describeResult.getPicklistValues();
			// list of options to be returned to the VF page
			List<SelectOption> optionsToReturn = new List<SelectOption>();
			optionsToReturn.add(new SelectOption('select', 'Select Feature'));
			for (Schema.PicklistEntry pEntry : entries) {
				if (pEntry.isActive()) {
					optionsToReturn.add(new SelectOption(pEntry.getValue(), pEntry.getLabel()));
				}
			}
			return optionsToReturn;
		}
	}

	public PageReference getCaseRequestedFeatures() {
		String query = '';
		query = 'select id, Case__r.id, Case__r.Subject, Account__c, CreatedBy.name, Createddate, Feature__c, Comments__c from Feature_Request__c where Account__c =:caseAccountId order by createddate desc';
		setCon = new ApexPages.StandardSetController(Database.getQueryLocator(query));
		setCon.setPageSize(20);
		return null;
	}

	public PageReference submitFeature() {
		String query = '';
		String strFilter = 'where Account__c =:caseAccountId'; // and case__c =:caseId';
		if (selectedFeature != null && selectedFeature != '' && selectedFeature != 'select') {
			strFilter = strFilter + ' AND Feature__c  =:selectedFeature';
			List<Feature_Request__c> featureList = (List<Feature_Request__c>) Database.query('SELECT Id FROM Feature_Request__c ' + strFilter);
			if (featureList != null && featureList.size() > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Feature is already requested for the account'));
				return null;
			}
			try {
				Feature_Request__c newFeature = new Feature_Request__c();
				newFeature.Case__c = caseId;
				newFeature.Account__c = caseAccountId;
				newFeature.Feature__c = selectedFeature;
				newFeature.Comments__c = selectedFeatureComment;
				insert newFeature;
				featureList.clear();
				this.getCaseRequestedFeatures();
				selectedFeature = '';
				selectedFeatureComment = '';
			} catch (Exception e) {
				//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured whie requesting a feature'));
				ExceptionLogUtil.logException('CaseFeatureRequestExtension', 'submitFeature', e.getMessage(), e.getStackTraceString());
				return null;
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select appropriate feature'));
			return null;
		}
		return null;
	}
}