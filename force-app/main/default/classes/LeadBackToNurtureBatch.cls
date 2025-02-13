/**
 * @name         LeadBackToNurtureBatch
 * @author       Praveen Sethu
 * @date         08-28-2021
 * @description  Update Leads to Back to Nurture if no Activity has been logged by Rep in last 21 days
 * @test classes LeadBackToNurtureBatchTest
 **/
public class LeadBackToNurtureBatch implements Database.Batchable<sObject>, Database.stateful {
	public static Boolean blnException = false;
	public String strQuery;

	public LeadBackToNurtureBatch() {
	}

	public LeadBackToNurtureBatch(String strQuery) {
		this.strQuery = strQuery;
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh Kumar
	 * @Description : Datbase execute method - Query for Leads that have no activity logged OR that have been MQL'ed before 21 days
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public Database.QueryLocator start(Database.BatchableContext BC) {
		String strMQLLeadStatus = LeadUtil.LEAD_STATUS_MQL;
		Id idCompanyLeadRType = LeadUtil.COMPANY_LEAD_RT_ID;
		Integer intNoOfLeadDormantDays = LeadUtil.NO_OF_LEAD_DORMANT_DAYS;

		if (String.isBlank(strQuery)) {
			// Query
			strQuery = 'SELECT Id, Status ';
			strQuery += ' FROM Lead ';
			strQuery += ' WHERE IsConverted = False ';
			strQuery += ' AND CreatedDate = LAST_N_DAYS:60 ';
			strQuery += ' AND Status = :strMQLLeadStatus  ';
			strQuery +=
				' AND (Last_Rep_Activity_Days__c >= :intNoOfLeadDormantDays OR (Last_Rep_Activity_Date__c = null AND MQL_Date__c < LAST_N_DAYS:' +
				intNoOfLeadDormantDays +
				' )) ';
		}

		return Database.getQueryLocator(strQuery);
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh Kumar
	 * @Description : Update lead status to Back to Nurture
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public void execute(Database.BatchableContext BC, List<Lead> list_Leads) {
		try {
			for (Lead objLead : list_Leads) {
				objLead.Status = LeadUtil.LEAD_STATUS_BACK_TO_NURT;
			}

			LeadTriggerHelper.skipTrigger = true;
			update list_Leads;

			if (Test.isRunningTest() && blnException == true) {
				Integer i = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException(
				'LeadBackToNurtureBatch',
				'BeforeexecuteInsert',
				'Exception On Line ' +
				objEx.getLineNumber() +
				'-' +
				objEx.getMessage(),
				objEx.getStackTraceString()
			);
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Send error email if any batches failed
	 * @Parm        : NA
	 * @Return      : N/A
	 **/
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'LeadBackToNurtureBatch', false);
	}
}