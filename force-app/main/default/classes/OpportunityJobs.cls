/**
 * @name         : OpportunityJobs
 * @author       : Prashant Bhatt
 * @date         : 03-17-2021
 * @description  : Nightly Job to sync up the Account Benefit Opt out to Opportunity
 * @test classes : OpportunityJobsTest
 **/

public class OpportunityJobs implements Database.Batchable<sObject>, Database.Stateful {
	public String strQuery;
	Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
	Integer intAge = objConfig.CL_Tier_Upsell_Age__c != null && objConfig.CL_Tier_Upsell_Age__c != 0 ? objConfig.CL_Tier_Upsell_Age__c.intValue() : 45;
	Date dtToday = System.today().addDays(-intAge);
	Date dtTodayForInternationalPayroll = System.today().addDays(-90);

	public OpportunityJobs(String qry) {
		strQuery = qry;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (String.isBlank(strQuery)) {
			Id idCompanyRecordType = OpportunityUtil.COMPANY_OPPTY_RT_ID;
			Id idAcquisitionRecordType = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
			Set<Id> set_CompanyRecTypes = new Set<Id>{ idCompanyRecordType, idAcquisitionRecordType };
			Id idUpsellRecordType = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
			String strWhereClause =
				'((CreatedDate <= :dtToday AND' +
				' Additional_Opportunity_Services__c EXCLUDES (' +
				'\'' +
				AccountUtil.EMPLOYER_OF_RECORD +
				'\'' +
				'))' +
				' OR (CreatedDate <= :dtTodayForInternationalPayroll AND' +
				' Additional_Opportunity_Services__c INCLUDES (' +
				'\'' +
				AccountUtil.EMPLOYER_OF_RECORD +
				'\'' +
				'))' +
				')';

			strQuery =
				'SELECT Id, RecordtypeId, CreatedDate, Name, Type, Benefits_Opt_Out__c, Upsell_Tier__c,Sold_By__r.Apply_to_all_clients__c, ' +
				'Sold_By__r.Benefits_Email_Opt_Out__c, Account.Upsell_Opp_Open__c,Account.Upsell_Tier_Opps_Open__c FROM Opportunity WHERE ((RecordTypeId IN :set_CompanyRecTypes ' +
				'AND Sold_By__c != NULL AND Sold_By__r.Benefit_Opt_Out_Sync__c = true) OR (RecordTypeId = :idUpsellRecordType AND ' +
				strWhereClause +
				')) AND IsClosed = false';
		}
		return Database.getQueryLocator(strQuery);
	}

	public void execute(Database.BatchableContext bc, List<Opportunity> list_Opportunity) {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		List<Opportunity> list_OppsToUpdate = new List<Opportunity>();
		List<Account> list_AccsToUpdate = new List<Account>();
		Set<Id> set_AccIds = new Set<Id>();
		Set<Id> set_UpsellAccIds = new Set<Id>();
		Id idCompanyRecordType = OpportunityUtil.COMPANY_OPPTY_RT_ID;
		Id idAcquisitionRecordType = OpportunityUtil.ACQUISITION_OPPTY_RT_ID;
		Id idUpsellRecordType = OpportunityUtil.TIER_UPSELL_OPPTY_RT_ID;
		Map<Id, String> map_IdAndUpsellOpenOpp = new Map<Id, String>();
		for (Opportunity objOpp : list_Opportunity) {
			if (
				(objOpp.RecordtypeId == idCompanyRecordType || (objOpp.RecordtypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID && objOpp.Type == OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS)) &&
				objOpp.Sold_By__c != null
			) {
				objOpp.Benefits_Opt_Out__c = objOpp.Sold_By__r.Benefits_Email_Opt_Out__c;
				list_OppsToUpdate.add(objOpp);
				set_AccIds.add(objOpp.Sold_By__c);
			}
			if (objOpp.RecordtypeId == idUpsellRecordType && objOpp.CreatedDate <= dtToday) {
				objOpp.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
				objOpp.Stage_Detail__c = OpportunityUtil.TIMING_STAGE;
				objOpp.CloseDate = Date.today();
				list_OppsToUpdate.add(objOpp);
				set_AccIds.add(objOpp.AccountId);
				set_UpsellAccIds.add(objOpp.AccountId);

				if (objOpp.Upsell_Tier__c != null) {
					if (objOpp.Upsell_Tier__c.equalsIgnoreCase(AccountUtil.EMPLOYER_OF_RECORD)) {
						if (objOpp.Account.Upsell_Tier_Opps_Open__c == OpportunityUtil.INTERNATIONAL_PAYROLL_AND_TIER_UPSELL) {
							map_IdAndUpsellOpenOpp.put(objOpp.AccountId, OpportunityUtil.TIER_UPSELL);
						} else {
							map_IdAndUpsellOpenOpp.put(objOpp.AccountId, '');
						}
					} else {
						if (objOpp.Account.Upsell_Tier_Opps_Open__c == OpportunityUtil.INTERNATIONAL_PAYROLL_AND_TIER_UPSELL) {
							map_IdAndUpsellOpenOpp.put(objOpp.AccountId, AccountUtil.EMPLOYER_OF_RECORD);
						} else {
							map_IdAndUpsellOpenOpp.put(objOpp.AccountId, '');
						}
					}
				}
			}
		}

		try {
			if (!list_OppsToUpdate.isEmpty()) {
				update list_OppsToUpdate;
			}

			if (!set_AccIds.isEmpty()) {
				for (Id objAccId : set_AccIds) {
					Account objAcc = new Account();
					objAcc.id = objAccId;
					objAcc.Benefit_Opt_Out_Sync__c = false;
					if (set_UpsellAccIds.contains(objAccId)) {
						objAcc.Upsell_Opp_Open__c = false;
					}
					if (map_IdAndUpsellOpenOpp.containsKey(objAccId)) {
						objAcc.Upsell_Tier_Opps_Open__c = map_IdAndUpsellOpenOpp.get(objAccId);
					}
					list_AccsToUpdate.add(objAcc);
				}
			}

			if (!list_AccsToUpdate.isEmpty()) {
				update list_AccsToUpdate;
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('OpportunityJobs', 'execute', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'OpportunityJobs', false);
	}
}