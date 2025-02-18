/**
 * @author       Rushi R
 * @description  Helper class for QA Sheet
 * @test         HIGroupEventQASheetHandlerTest
 * @revisions    Date ----------- Name ---------- Comments
 *               07/07/2023       Rushi R         Created methods to create QA Sheet from Opportunity and update QA Sheet from Benefit Order
 **/
public with sharing class QASheetHelper {
	public final static Id QAS_BEN_NP_RT_ID = Cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
	public final static Id QAS_BEN_CHG_RT_ID = Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Change');
	public final static Id QAS_BEN_RNWL_RT_ID = Cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');

	public static Set<Id> set_opptyRecordTypeIds = new Set<Id>{
		OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID,
		OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID,
		OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID
	};

	/*
	 * @author       Rushi R
	 * @description  This method is used to create or update QA Sheet
	 * @param        list_sObjects - List of SObjects
	 */
	public static void createOrUpdateQASheet(List<SObject> list_sObjects) {
		SObject obj = list_sObjects[0];
		if (obj instanceof Opportunity) {
			createQASheetFromOppty((List<Opportunity>) list_sObjects);
		} else if(obj instanceof Benefit_Order__c) {
			Set<Id> set_BOIds = new Set<Id>();
			for (Benefit_Order__c objBO : (List<Benefit_Order__c>) list_sObjects) {
				set_BOIds.add(objBO.Id);
			}
			updateQASheetFromBO(set_BOIds);
		}
	}

	/*
	 * @author       Rushi R
	 * @description  This method is used to create QA Sheet from Opportunity
	 * @param        list_newOppty - List of Opportunity
	 */
	static void createQASheetFromOppty(List<Opportunity> list_newOppty) {
		List<QA_Sheet__c> list_QASheet = new List<QA_Sheet__c>();
		Map<Id, Opportunity> map_Oppty = new Map<Id, Opportunity>();
		Map<Id, Transition_to_Fulfillment__c> map_Ttf = new Map<Id, Transition_to_Fulfillment__c>();
		Map<Id, Id> map_opptyIdAcctId = new Map<Id, Id>();
		Map<Id, Account> map_accounts = new Map<Id, Account>();
		Set<Id> set_acctId = new Set<Id>();

		for (Opportunity objOppty : list_newOppty) {
			map_Oppty.put(objOppty.Id, objOppty);
			map_opptyIdAcctId.put(objOppty.Id, objOppty.AccountId);
			set_acctId.add(objOppty.AccountId);
		}

		if (!set_acctId.isEmpty()) {
			map_accounts = BenefitOrderHelperFunctions.getAccountsByAccountId(set_acctId);
		}

		for (Opportunity objOppty : list_newOppty) {
			Account objAcct;
			if (objOppty.AccountId != null && !map_accounts.isEmpty() && map_accounts.containsKey(objOppty.AccountId)) {
				objAcct = map_accounts.get(objOppty.AccountId);
			}

			QA_Sheet__c objQASheet = new QA_Sheet__c(
				Opportunity__c = objOppty.Id,
				RecordTypeId = objOppty.RecordTypeId.equals(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
					? QAS_BEN_NP_RT_ID
					: (objOppty.RecordTypeId.equals(OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID)
							? QAS_BEN_CHG_RT_ID
							: (objOppty.RecordTypeId.equals(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) ? QAS_BEN_RNWL_RT_ID : null)),
				Effective_Date__c = objOppty.HI_Effective_Date__c
			);

			if (objAcct != null) {
				objQASheet.DBA__c = String.isNotBlank(objAcct?.Name) ? objAcct.Name : '';
				objQASheet.Entity_Type__c = String.isNotBlank(objAcct?.Corporation_Type__c) ? objAcct.Corporation_Type__c : '';
				objQASheet.Mailing_Address__c =
					(String.isNotBlank(objAcct?.BillingStreet) ? objAcct.BillingStreet : '') +
					(String.isNotBlank(objAcct?.BillingState) ? objAcct.BillingState : '') +
					(String.isNotBlank(objAcct?.BillingPostalCode) ? objAcct.BillingPostalCode : '') +
					(String.isNotBlank(objAcct?.BillingCountry) ? objAcct.BillingCountry : '');
				objQASheet.SIC_Code__c = String.isNotBlank(objAcct?.Sic) ? objAcct.Sic : '';
			}
			list_QASheet.add(objQASheet);
		}

		if (!list_QASheet.isEmpty()) {
			insert list_QASheet;
		}
	}

	/*
	 * @author       Rushi R
	 * @description  This method is used to update QA Sheet from Benefit Order
	 * @param        list_BOs - List of Benefit Orders
	 */
	@future
	static void updateQASheetFromBO(Set<Id> set_BOIds) {
		List<Benefit_Order__c> list_BOs = [SELECT Id, Opportunity__c, Coverage_Effective_Date__c FROM Benefit_Order__c WHERE Id IN :set_BOIds];
		List<String> list_QAfields = new List<string>(QA_Sheet__c.getSObjectType().getDescribe().fields.getMap().keySet());

		Map<Id, Benefit_Order__c> map_opptyIdBO = new Map<Id, Benefit_Order__c>();
		for (Benefit_Order__c objBO : list_BOs) {
			map_opptyIdBO.put(objBO.Opportunity__c, objBO);
		}

		Set<Id> set_opptyIds = map_opptyIdBO.keySet();
		List<QA_Sheet__c> list_QASheet = new List<QA_Sheet__c>();
		String strQASheetQuery =
			'SELECT ' +
			String.join(list_QAfields, ',') +
			', RecordType.DeveloperName, Opportunity__r.Application_Id__c, ' +
			'Opportunity__r.AccountId, Opportunity__r.OwnerId, Opportunity__r.RecordTypeId, Opportunity__r.RecordType.DeveloperName ' +
			'FROM QA_Sheet__c WHERE Opportunity__c IN :set_opptyIds';
		for (QA_Sheet__c objQASheet : Database.query(strQASheetQuery)) {
			if (String.isNotBlank(objQASheet.Opportunity__c) && map_opptyIdBO.containsKey(objQASheet.Opportunity__c)) {
				Benefit_Order__c objBO = map_opptyIdBO.get(objQASheet.Opportunity__c);
				objQASheet.Benefit_Order__c = objBO.Id;
				objQASheet.Policy_Renewal_Date__c = objBO.Coverage_Effective_Date__c;
				list_QASheet.add(objQASheet);
			}
		}

		if (!list_QASheet.isEmpty()) {
			update list_QASheet;
		}

		List<Company_Level_Documents__c> list_CLD = new List<Company_Level_Documents__c>();
		for (Company_Level_Documents__c objCLD : [SELECT Id, Opportunity__c, Benefit_Order__c FROM Company_Level_Documents__c WHERE Opportunity__c IN :set_opptyIds]) {
			if (String.isNotBlank(objCLD.Opportunity__c) && map_opptyIdBO.containsKey(objCLD.Opportunity__c)) {
				Benefit_Order__c objBO = map_opptyIdBO.get(objCLD.Opportunity__c);
				objCLD.Benefit_Order__c = objBO.Id;
				list_CLD.add(objCLD);
			}
		}

		if (!list_CLD.isEmpty()) {
			update list_CLD;
		}

	}
}