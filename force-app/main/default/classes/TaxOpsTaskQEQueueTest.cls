@isTest
private class TaxOpsTaskQEQueueTest
{	

	@testSetup
	static void testDataSetup(){

		Tax_Ops_Task_QE__c qeRec = new Tax_Ops_Task_QE__c();
		qeRec.Tax_code__c = 'AK0000-010';
		qeRec.Tax_Description__c = 'Alaska Quarterly Contribution (SUI)';
		qeRec.Form_Code__c = 'AK 07-1004';
		qeRec.Period_End__c = system.today().addDays(5);
		qeRec.Due_Date__c = system.today().addDays(10);
		qeRec.Filing_Method__c = 'Paper';
		qeRec.Payment_estimate__c = 123456;
		qeRec.Total_Count_of_Returns__c = 1;

		TaxOpsTaskQETriggerHelper.queue = true;
		insert qeRec;

	}

	@isTest
	static void queueabilityCheckMethod(){

		list<Tax_Ops_Task_QE__c> tempList = [select id from Tax_Ops_Task_QE__c];
		if(tempList.size()>0){
			TaxOpsTaskQEQueue  updateJob = new TaxOpsTaskQEQueue (tempList);
	        ID jobID = System.enqueueJob(updateJob);
	        system.assert(jobID != null);
		}

	}
}