/**
 * @description Generic Flow utility to do DML
 * @author      Ajay Krishna P U
 * @since       2024-03-26
 * @see         SObjectDMLFlowUtilTest
 */
public without sharing class SObjectDMLFlowUtil {
	/**
	 * @description         Utility method to Skip trigger and do DML operations
	 *                      Only support one type of DML Type and Skip trigger class
	 * @param list_Requests List of Requests
	 */
	@InvocableMethod(label='DML Operation on SObject' description='Performs the required DML operation on the respective SObject as per requirements')
	public static void doDML(List<Request> list_Requests) {
		if (list_Requests.isEmpty()) {
			return;
		}

		//Initialize variables
		List<SObject> list_SObjectsToProcess = new List<SObject>();
		String strDMLType = list_Requests[0].strDMLType;
		String strSkipTriggerClass = list_Requests[0].strSkipTriggerClass;
		String strBypassTriggerHandlers = list_Requests[0].strBypassTriggerHandlers;

		//Extract processing records
		for (Request objRequest : list_Requests) {
			if (objRequest.objRecord != null) {
				list_SObjectsToProcess.add(objRequest.objRecord);
			}

			if (objRequest.list_SObjects != null && !objRequest.list_SObjects.isEmpty()) {
				list_SObjectsToProcess.addAll(objRequest.list_SObjects);
			}
		}

		//Enable Skip trigger
		doSkipTrigger(true, strSkipTriggerClass);
		doBypassTriggerHandlers(true, strBypassTriggerHandlers);

		//Do DML
		doDMLOperation(strDMLType, list_SObjectsToProcess);

		//Disable Skip trigger
		doSkipTrigger(false, strSkipTriggerClass);
		doBypassTriggerHandlers(false, strBypassTriggerHandlers);
	}

	/**
	 * @description               Skip Trigger, Note: Extended as required
	 * @param blnActive           Whether the Skip Trigger have to be active
	 * @param strSkipTriggerClass The trigger helper to be skipped
	 * @exception                 CustomException if Invalid Trigger class
	 */
	private static void doSkipTrigger(Boolean blnActive, String strSkipTriggerClass) {
		switch on strSkipTriggerClass {
			when 'OpportunityTriggerHelper' {
				OpportunityTriggerHelper.skipTrigger = blnActive;
			}
			when 'AccountTriggerHelper' {
				AccountTriggerHelper.skipTrigger = blnActive;
			}
		}
	}

	/**
	 * @description                    Bypass Trigger Handlers
	 * @param blnBypass                Whether to bypass or clear bypass Trigger handler
	 * @param strBypassTriggerHandlers Semicolon separated list of Trigger handler names to bypass
	 */
	private static void doBypassTriggerHandlers(Boolean blnBypass, String strBypassTriggerHandlers) {
		if (String.isBlank(strBypassTriggerHandlers)) {
			return;
		}

		if (blnBypass) {
			TriggerHandler.bypass(strBypassTriggerHandlers.split(';'));
		} else {
			TriggerHandler.clearBypass(strBypassTriggerHandlers.split(';'));
		}
	}

	/**
	 * @description      Do DML operation
	 * @param strDMLType    DML Type
	 * @param list_SObjectsToProcess List of records to process
	 * @exception                    CustomException if invalid DML Type
	 */
	private static void doDMLOperation(String strDMLType, List<SObject> list_SObjectsToProcess) {
		switch on strDMLType {
			when 'INSERT' {
				insert list_SObjectsToProcess;
			}
			when 'UPDATE' {
				update list_SObjectsToProcess;
			}
			when 'DELETE' {
				delete list_SObjectsToProcess;
			}
			when else {
				throw new CustomException('Invalid DML Type');
			}
		}
	}

	/**
	 * Flow Request Type
	 */
	public class Request {
		@InvocableVariable(label='SObject Record')
		public SObject objRecord;

		@InvocableVariable(label='SObject Records (Multiple)')
		public List<SObject> list_SObjects;

		@InvocableVariable(label='DML Operation' description='Supported Types: INSERT | UPDATE | DELETE')
		public String strDMLType;

		@InvocableVariable(label='Trigger to Skip' description='Supported Triggers: OpportunityTriggerHelper')
		public String strSkipTriggerClass;

		@InvocableVariable(label='Triggers to Bypass' description='Supports multiple triggers to bypass, Semicolon separated list of Trigger handler names eg: OpportunityTriggerHandler')
		public String strBypassTriggerHandlers;

		public Request() {
		}
		public Request(SObject objRecord, String strDMLType, String strSkipTriggerClass) {
			this.objRecord = objRecord;
			this.strDMLType = strDMLType;
			this.strSkipTriggerClass = strSkipTriggerClass;
		}
		public Request(List<SObject> list_SObjects, String strDMLType, String strBypassTriggerHandlers) {
			this.list_SObjects = list_SObjects;
			this.strDMLType = strDMLType;
			this.strBypassTriggerHandlers = strBypassTriggerHandlers;
		}
	}

	/**
	 * Custom Exception Class
	 */
	public class CustomException extends Exception {
	}
}