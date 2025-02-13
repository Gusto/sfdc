/**
 * @name         SalesCallTrackingUtil
 * @author       Deepika Saini
 * @date          04/05/2021
 * @description  Utility class to hold constants and common data
 * @test class
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class SalesCallTrackingUtil {
	public static final Id SALES_CALL_TRACKING_RT_NEW_PLAN_ID = Cache.getRecordTypeId(
		'Sales_Call_Tracking__c',
		'New Plan'
	);

	public static final Id SALES_CALL_TRACKING_RT_RENEWAL_ID = Cache.getRecordTypeId(
		'Sales_Call_Tracking__c',
		'Renewal'
	);

	public static final Id SALES_CALL_TRACKING_RT_CHANGE_ID = Cache.getRecordTypeId(
		'Sales_Call_Tracking__c',
		'Change'
	);

	public static final Id SALES_CALL_TRACKING_RT_BENEFITS_BOR_ID = Cache.getRecordTypeId(
		'Sales_Call_Tracking__c',
		'Benefits BoR'
	);

	public static final Map<String, Id> BO_RT_NAME_WITH_SALES_CALL_TRACKING_RT_IDS = new Map<String, Id>{
		BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN => SALES_CALL_TRACKING_RT_NEW_PLAN_ID,
		BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL => SALES_CALL_TRACKING_RT_RENEWAL_ID,
		BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE => SALES_CALL_TRACKING_RT_CHANGE_ID,
		BenefitOrderUtil.BENEFIT_ORDER_RT_BENEFITS_BOR => SALES_CALL_TRACKING_RT_BENEFITS_BOR_ID,
		BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL_ALIGNMENT => SALES_CALL_TRACKING_RT_RENEWAL_ID
	};
}