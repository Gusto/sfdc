/**
 * @author Yogesh Kherajani
 * @since 02/20/2024
 * @description This wrapper class is used to provide limit details.
 * Test class: SalesforceOrgNotificationCtrlTest
 **/
public class SalesforceOrgLimitDetails {
	@InvocableVariable
	@AuraEnabled
	public Decimal decAsyncLimitConsumption;
	@InvocableVariable
	@AuraEnabled
	public Decimal decDailyAPIRequestConsumption;
	@InvocableVariable
	@AuraEnabled
	public Decimal decSingleEmailConsumption;
	@InvocableVariable
	@AuraEnabled
	public Decimal decAsyncLimitMax;
	@InvocableVariable
	@AuraEnabled
	public Decimal decAsyncLimitRemaning;
	@InvocableVariable
	@AuraEnabled
	public Decimal decDailyAPIRequestMax;
	@InvocableVariable
	@AuraEnabled
	public Decimal decDailyAPIRequestRemaning;
	@InvocableVariable
	@AuraEnabled
	public Decimal decSingleEmailMax;
	@InvocableVariable
	@AuraEnabled
	public Decimal decSingleEmailRemaning;
}