public class SandboxPostRefreshUtils {
	// Custom Settings
	public static Sandbox_Refresh_Config__c objSandboxRefreshSettings = Sandbox_Refresh_Config__c.getOrgDefaults();
	public static Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();

	// strings
	public static final String ENTITLEMENT_ENGAGEMENT_NAME = 'Engagement - Gusto Entitlement - Please Don\'t Delete';
	public static final String ENTITLEMENT_TAXOPS_NAME = 'Tax Ops -Gusto Entitlement - Please Don\'t Delete';
	public static final String ENTITLEMENT_RISK_NAME = 'Risk -Gusto Entitlement - Please Don\'t Delete';
	public static final String ENTITLEMENT_COMPLIANCE_NAME = 'Payroll Compliance - Gusto Entitlement - Please Don\'t Delete Undo';

	// Sets
	public final static Set<String> set_Entitlement_Names = new Set<String>{ ENTITLEMENT_ENGAGEMENT_NAME, ENTITLEMENT_TAXOPS_NAME, ENTITLEMENT_RISK_NAME, ENTITLEMENT_COMPLIANCE_NAME };
}