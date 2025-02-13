/***
    Created by : Swati Arya
    Created Date : 03/24/2023
    Description: Hi Upsell Information related Utilities for reuse
**/
public class HIUpsellInformationUtil {
	public static final String COMPANY_ID_EMPTY = 'Company Id is empty.';
	public static final String EXTERNAL_KEY_EMPTY = 'External key is empty.';
	public static final String BENEFIT_TYPE_EMPTY = 'Benefit type is empty.';
	public static final String COMPANY_NOT_EXIST = 'Company does not exist.';
	public static final String OPPTY_DONT_EXIST = 'Opportunity does not exist.';
	public static final String UPSELL_TYPE_NEW_TADA = 'New TAdA Plan';
	public static final String UPSELL_TYPE_TRANSFER_TADA = 'Transfer TAdA Plan';
	public static final String STR_NEW_BENEFIT = 'new_benefit';
	public static final String STR_TRANSFER_BENEFIT = 'transfer_benefit';
	public static final String STR_FSA = 'fsa';
	public static final String STR_DCA = 'dca';
	public static final String STR_HSA = 'HSA';
	public static final String STR_COMMUTER = 'Commuter';
	public static final String STR_FSA_MEDICAL = 'Flexible Spending Account - Medical';
	public static final String STR_FSA_DEPENDENT = 'Flexible Spending Account - Dependent Care';
	public static final String STR_HI_BENEFIT_INTEREST = 'HIBENEFITINTEREST';
	public static final String STR_CHANGE = 'Change';
	public static final String STR_MODE_NORMAL = 'Normal';
	public static final String DUPLICATE_VALUE_ERROR_MSG = 'duplicate value found: Id__c duplicates value on record with id:';

	public static final List<String> POLICY_BENEFIT_TYPES = new List<String>{ STR_FSA_MEDICAL, STR_FSA_DEPENDENT, STR_HSA, STR_COMMUTER };

	/**
	 * @author      Deepika
	 * @description Get Carrier which is saved in the Configuration setting
	 * @param       N/A
	 * @return      Carrier__c
	 **/
	public static Carrier__c getActiveTadaCarrier() {
		Configuration_Settings__c objConfig = Configuration_Settings__c.getOrgDefaults();
		Carrier__c objCarrier = new Carrier__c();

		if (objConfig != null && objConfig.Active_TAdA_Provider__c != null) {
			String strCOTadaKey = String.valueOf(objConfig.Active_TAdA_Provider__c);
			objCarrier = [SELECT Id, Key__c, Name FROM Carrier__c WHERE Key__c = :strCOTadaKey LIMIT 1];
		}
		return objCarrier;
	}
}