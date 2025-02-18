/**
 * @description  ZPProductLineUtil - used for commonly used constants in ZPProductLineTriggerHelper
 * @author       Anurag Gautam
 * @date         06/08/2023
 * @see          ZPProductLineTriggerHelper
 **/
public with sharing class ZPProductLineUtil { 
	// Error Messages:
	public static final String ERR_MSG_COMPANY_ID_DOES_NOT_EXIST = 'Company does not exist';
	public static final String ERR_MSG_COMPANY_BASE_ID_DOES_NOT_EXIST = 'Company Base Id is missing';
	public static final String ERR_MSG_COMPANY_ENROLLMENT_ID_DOES_NOT_EXIST = 'Company Enrollment Id is missing';
	public static final String ERR_MSG_PARENT_ID_DOES_NOT_EXIST = 'Product line is add on and Parent ID is missing';
	public static final String ERR_MSG_PRICING_PLAN_ID_DOES_NOT_EXIST = 'Pricing plan Id is missing.';
	public static final String ERR_MSG_PRODUCT_LINE_ID_DOES_NOT_EXIST = 'Product line Id is missing';
	public static final String ERR_MSG_PRODUCT_NAME_DOES_NOT_EXIST = 'Product name is missing';
	public static final String ERR_MSG_START_DATE_DOES_NOT_EXIST = 'Start date is missing';
	public static final String ERR_MSG_TYPE_DOES_NOT_EXIST = 'Type is missing';
	public static final String ERR_MSG_UUID_DOES_NOT_EXIST = 'UUID is missing';
	public static final String ERR_MSG_ZP_COMPANY_DEAD = 'ZP Company is Dead';
	public static final String ERR_MSG_STATUS_DOES_NOT_EXIST = 'Status is missing';
	public static final String TYPE_BASE = 'base';
	public static final String TYPE_ADD_ON = 'add_on';
	public static final String STATUS_DELETED = 'deleted';
	public static final String STATUS_ACTIVE = 'active';
	public static final String STATUS_INACTIVE = 'inactive';
	public static final String FUTURE_BACKLOG = 'Future Backlog';
	public static final String SUCCESS_MESSAGE = 'Record processed successfully.';
	public static final String PRODUCT_DEACTIVATED_MESSAGE = 'Product has been deactivated in panda.';
	public static final String ADD_SERVICES_PRIORITY_SUPPORT = 'Priority Support and HR Services';
	public static final String ERR_MSG_FUTURE_START_DATE = 'Future Start Date';
	public static final String ERR_MSG_BASE_PRODUCT = 'Base Product does not exist';
	public static final String ERR_MSG_PRODUCT_ERROR = 'Product Id and Pricing Plan Id does not exist';

	public final static Map<String, String> map_ExternalIdAndProductName = new Map<String, String>{
		'premium' => 'Legacy Premium',
		'premium_v2' => 'Premium',
		'premium_crb' => 'Premium CRB',
		'premium_multi_ein' => 'Premium Multi-EIN',
		'simple' => 'Simple',
		'plus' => 'Plus',
		'contractor_only' => 'contractor_only',
		'Advanced time-off' => 'Advanced Time-Off',
		'HR services' => 'HR Services',
		'Advanced time-off premium' => 'Advanced Time-Off Premium',
		'Next-day direct deposit' => 'Next-Day Direct Deposit',
		'Performance & engagement' => 'Performance And Engagement',
		'Priority support' => 'Priority Support',
		'Priority Support and HR Services' => 'Priority Support and HR Services',
		'Time and project tracking' => 'Time And Project Tracking',
		'wholesale' => 'Wholesale'
	};

	// RecordTypeIds:
	public static final Id COMPANY_ACCOUNT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Account', 'Company');

	/*
	 * @author:         Anurag Gautam
	 * @description:    Querying ZP Companies and builds a map of Company Id and ZP Company record
	 * @parm:           Set - Set of company Ids
	 * @return:         Map of Company Id and ZP Company record
	 */
	public static Map<String, ZP_Company__c> queryZPCompany(Set<String> set_CompanyIds) {
		Map<String, ZP_Company__c> map_ZPCompanies = new Map<String, ZP_Company__c>();

		for (ZP_Company__c objComp : [SELECT Id, Id__c, Processing_State__c, Message__c FROM ZP_Company__c WHERE Id__c IN :set_CompanyIds AND Processing_State__c = :IntegrationUtils.DEAD_STATE]) {
			map_ZPCompanies.put(objComp.Id__c, objComp);
		}
		return map_ZPCompanies;
	}

	/**
	 * @Author      : Anurag Gautam
	 * @Description : Query Payment Plan
	 * @Parm        : set_ProductIds , set_PricingPlanIds
	 * @Return      : query results - List of Payment Plans
	 **/
	public static List<PriceBook2> queryPaymentPlans() {
		return [
			SELECT
				Name,
				Payment_Plan__c,
				Payment_Plan_Name__c,
				Pricing_Plan_ID__c,
				Product_Line_ID__c,
				Product_Tier__c,
				(SELECT Id, Name,Product2.Name, Product2.Product_Category__c, Product2.Pricing_Plan_ID__c, Product2.Product_Line_ID__c,Product2.Product_Type__c, UnitPrice,Product2.ExternalId,PriceBook2.Name,PriceBook2Id FROM PriceBookEntries)
			FROM PriceBook2
			WHERE isActive = TRUE
		];
	}

	/**
	 * @Author      : Anurag Gautam
	 * @Description : Query ZP_Product_Line__c
	 * @Parm        : set_CompanyIds
	 * @Return      : query results - List of ZP_Product_Line__c
	 **/
	public static List<ZP_Product_Line__c> queryZPProductLine(Set<String> set_CompanyIds) {
		return [
			SELECT Id, Company_Base_ID__c, Company_Enrollment_ID__c, Company_ID__c, Parent_ID__c, Pricing_Plan_ID__c, Product_Line_ID__c, Start_Date__c, Status__c, Type__c,Assigned_Quantity__c,Product_Name__c
			FROM ZP_Product_Line__c
			WHERE Company_Id__c IN :set_CompanyIds AND Status__c !=: STATUS_DELETED
			ORDER BY Start_Date__c DESC
		];
	}

	/**
	 * @Author      : Anurag Gautam
	 * @Description : Query Opportunity
	 * @Parm        : set_CompanyIds
	 * @Return      : query results - List of Opportunity
	 **/
	public static List<Opportunity> queryOpportunity(Set<String> set_CompanyIds) {
		return [
			SELECT Id, ZP_Company_ID_from_Account__c, Pricebook2Id, (Select Id,Product2.Product_Type__c from opportunityLineItems)
			FROM Opportunity
			WHERE ZP_Company_ID_from_Account__c IN :set_CompanyIds AND RecordTypeId =: OpportunityUtil.COMPANY_OPPTY_RT_ID
		];
	}
}