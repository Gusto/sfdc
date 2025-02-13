/**
 * @name         : InsuranceQuoteTriggerHelper
 * @author       : David (Dato) Tsamalashvili
 * @date         : 10-06-2021
 * @description  : New InsuranceQuoteTriggerHelper Class for InsuranceQuote.
 * @test classes : InsuranceQuoteTriggerHelperTest
 **/
public class InsuranceQuoteTriggerHelper {
	// Static Variable used to Skip Triggers
	public static Boolean blnSkipTrigger = false;

	/** All Final Variables */
	public static final String STATUS_ASSIGNED = 'Assigned';
	public static final String QUEUED_STATE = 'Queued';

	//Constructor
	public InsuranceQuoteTriggerHelper() {
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles After Insert Context
	 * @Parm        : list_insuranceQuotes - List of Insurance Quotes from Trigger.new
	 * @Return      : N/A
	 **/
	public void processBeforeInsert(List<Insurance_Quote__c> list_insuranceQuotes) {
		for (Insurance_Quote__c objInsuranceQuote : list_insuranceQuotes) {
			if (objInsuranceQuote.Sales_Rep__c != null) {
				updateInsuranceQuote(objInsuranceQuote);
			}
		}
	}

	/**
	 * @Author      : David (Dato) Tsamalashvili
	 * @Description : Handles After Update Context
	 * @Parm        : list_insuranceQuotes - List of Insurance Quotes from Trigger.new
	 * @Parm        : map_oldInsuranceQuotes - Map of Insurance Quote Id and Insurance Quote Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processBeforeUpdate(
		List<Insurance_Quote__c> list_insuranceQuotes,
		Map<Id, Insurance_Quote__c> map_oldInsuranceQuotes
	) {
		for (Insurance_Quote__c objInsuranceQuote : list_insuranceQuotes) {
			if (
				objInsuranceQuote.Sales_Rep__c != null &&
				map_oldInsuranceQuotes.get(objInsuranceQuote.Id).Sales_Rep__c == null
			) {
				updateInsuranceQuote(objInsuranceQuote);
			}
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Updates Insurance Quote Status and Processing State
	 * @Parm        : objHIQuote - HI_Quote__c record
	 * @Return      : NA
	 **/
	private void updateInsuranceQuote(Insurance_Quote__c objInsuranceQuote) {
		objInsuranceQuote.Status__c = STATUS_ASSIGNED;
		objInsuranceQuote.Processing_State__c = QUEUED_STATE;
	}
}