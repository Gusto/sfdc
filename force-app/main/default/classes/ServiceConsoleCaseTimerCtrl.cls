/**
 * @name         : ServiceConsoleCaseTimerCtrl
 * @author       : Sean DesMarteau
 * @date         : 04-04-2022
 * @description  : Controller class for serviceConsoleCaseTimerCmp LWC. R
 * @test classes : ServiceConsoleCaseTimerCtrlTest
 **/
global with sharing class ServiceConsoleCaseTimerCtrl {
	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Updates the Case Session Time
	 * @Parm        : idCase - Case Id of record to update
	 * 				  strTimeVal - String value of the Session time to convert to seconds
	 * @Return      : Case[] - Returns updated case record
	 **/
	@AuraEnabled
	global static Case[] updateCaseSessionTime(Id idCase, String strTimeVal) {
		if (!Schema.sObjectType.Case.fields.Handle_Time_Seconds_New__c.isAccessible()) {
			throw new System.NoAccessException();
		}

		// Time Calculations
		String[] list_TimeVal = strTimeVal.split(':');
		Integer intHours = Integer.valueof(list_TimeVal[0]);
		Integer intMinutes = Integer.valueof(list_TimeVal[1]);
		Integer intSeconds = Integer.valueof(list_TimeVal[2]);
		Integer intFullTime = intSeconds + (intMinutes * 60) + (intHours * 3600);

		List<Case> list_Cases = [SELECT Id, Status, Handle_Time_Seconds_New__c FROM Case WHERE Id = :idCase LIMIT 1 FOR UPDATE];

		if (list_Cases[0].Handle_Time_Seconds_New__c == null) {
			list_Cases[0].Handle_Time_Seconds_New__c = intFullTime;
		} else {
			list_Cases[0].Handle_Time_Seconds_New__c += intFullTime;
		}

		CaseTriggerHelper.skipTrigger = true;
		update list_Cases;
		CaseTriggerHelper.skipTrigger = false;

		return [SELECT Handle_Time_Seconds_New__c FROM Case WHERE Id = :idCase];
	}

	/**
	 * @Author      : Sean DesMarteau
	 * @Description : Query for Case Status
	 * @Parm        : idCase - Case Id of record to update
	 * @Return      : Status - Returns Status value from Case
	 **/
	@AuraEnabled(cacheable=true)
	global static String grabCaseStatus(Id idCase) {
		return [SELECT Status FROM Case WHERE Id = :idCase LIMIT 1].Status;
	}
}