public without sharing class setAutoResponseTaxResCaseFlowExtension {
    
    public SettingProxy setting{get;set;}
    
    public setAutoResponseTaxResCaseFlowExtension(){          
        setting = new SettingProxy([select id, Flow_type__c from Org_case_flow_volume__c limit 1]);            
    }
    
    
    public pageReference saveCustom(){
        
        try{            
            update setting.getFlowVolumeSetting();
        }
        catch(exception ex){
            apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,ex.getMessage()));
            return null;
        }
        
        apexPages.addMessage(new apexPages.Message(apexPages.Severity.Info,'Update successful.'));        
        return null;
        
    }
    
    public class SettingProxy {
        public Id Id {get;set;}
        public String flowType {get;set;}

        public SettingProxy(Org_case_flow_volume__c flowRec) {
            this.Id = flowRec.Id;
            this.flowType = flowRec.Flow_type__c;
        }

        public SettingProxy() {}

        public Org_case_flow_volume__c getFlowVolumeSetting() {
            return new Org_case_flow_volume__c(
                Id = this.Id,
                Flow_type__c = this.flowType
            );
        }
    }
}