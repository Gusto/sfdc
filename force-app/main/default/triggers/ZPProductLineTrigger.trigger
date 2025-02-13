trigger ZPProductLineTrigger on ZP_Product_Line__c (before insert, after insert,before update, after update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False Or Distribution Engine runs an update
	String strProdLineFeatureFlag = System.Label.Product_Lines_Feature_Flag;
    
    // set feature flag to true if running from test class
    if (Test.isRunningTest()) {
        strProdLineFeatureFlag = 'true';
    }
    
    /**
	 * @description ZP Payer Pricing plan and ZP Company Tier process execution are blocked by strProdLineFeatureFlag if this flag is true , also we are updating the Tier, Pricing, and Additional Services on Account via ZP Product line. 
	**/ 
    if (FeatureManagement.checkPermission('Bypass_Triggers') || 
        ZPProductLineTriggerHelper.skipTrigger || String.isBlank(strProdLineFeatureFlag) || !strProdLineFeatureFlag.equalsIgnoreCase('true') ) {
        return;
    }
	new ZPProductLineTriggerHandler().run();
}