public class SendSlackNotForOppResellerWrapper {
	@InvocableVariable
	@AuraEnabled
    public String strOpportunityId;
    @InvocableVariable
	@AuraEnabled
    public String strSoldByName;
    @InvocableVariable
	@AuraEnabled
    public String strReferredByName;
    @InvocableVariable
	@AuraEnabled
    public String strSoldBy;
    @InvocableVariable
	@AuraEnabled
    public String strReferredBy;
    @InvocableVariable
	@AuraEnabled
    public String strSoldByOwnerSlackId;
    @InvocableVariable
	@AuraEnabled
    public String strReferredByOwnerSlackId;
}