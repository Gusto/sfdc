@isTest
private class TaxOpsTaskQETriggerHelperTest
{
	
	@isTest
	static void syncCheckMethod(){

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

		list<Tax_Ops_Task__c> tempList = [select id,Total_Count_of_Returns__c from Tax_Ops_Task__c];

		system.assert(tempList.size()>0);
		system.assert(tempList.get(0).Total_Count_of_Returns__c == 1);

		qeRec.Processing_State__c = '';
		qeRec.Total_Count_of_Returns__c = 3;
		update qeRec;

		tempList = [select id,Total_Count_of_Returns__c from Tax_Ops_Task__c];
		system.assert(tempList.size()>0);

		delete qeRec;

	}


}