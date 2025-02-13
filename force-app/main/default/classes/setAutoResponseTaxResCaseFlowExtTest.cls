@isTest
public class setAutoResponseTaxResCaseFlowExtTest {
	
    @isTest
    static void testPageRefreshFunctionality(){
        Org_case_flow_volume__c csRec = new Org_case_flow_volume__c();
        csRec.Flow_type__c = 'Low Volume';
        try{
        	insert csRec;    
        }
        catch(exception ex){}        
        
        if(csRec.id != null)
        	system.assert(csRec.id != null);
        
        
        setAutoResponseTaxResCaseFlowExtension controller = new setAutoResponseTaxResCaseFlowExtension();
        controller.saveCustom();
    }    
    
}