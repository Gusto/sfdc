public without sharing class EmailCarrierListCaseExtension {

    public Case theCase {get; private set;}
    public String email {get; set;}
    public String fromEmail {get; set;}
    public String carrierId {get; set;}
    public List<SelectOption> carrierOptions {get; private set;}
    public List<SelectOption> emailOptions {get; private set;}

        
    public EmailCarrierListCaseExtension(ApexPages.StandardController controller) {

        
        theCase = (Case) controller.getRecord();
        theCase = [Select Id, Opportunity__c,Benefit_Order__c,RecordType.Name from Case where Id=:theCase.id];
        email='';
        carrierId='';
        if(theCase.RecordType.Name.indexOf('Renewal')>-1 || theCase.RecordType.Name.indexOf('Change')>-1){
            fromEmail = Label.RenewalCaseCarrierEmail;
        }else if(theCase.RecordType.Name.indexOf('New Plan')>-1){
            fromEmail = Label.NewPlanCaseCarrierEmail;
        }else if(theCase.RecordType.Name.indexOf('Benefits BoR')>-1){
            fromEmail = Label.BORTransferCaseCarrierEmail;
        }
        carrierOptions = new List<SelectOption>();
        SelectOption optn = new SelectOption('','');
        carrierOptions.add(optn);
    
    //Lirik - Not in USE - Migration for BOR to BO -- Start ---
       // if(theCase.Opportunity__c != null || thecase.BoR_Transfer__c!= null){
       //Lirik - Not in USE - Migration for BOR to BO -- End ---
        if(theCase.Opportunity__c != null || thecase.Benefit_Order__c!= null){
            Set<id> carrierIdSet = new Set<id>();
            if(theCase.Opportunity__c != null && theCase.RecordType.Name.indexOf('Benefits BoR') < 0){
              for(Policy__c policy : [Select Id, Carrier__c,Carrier__r.Name, Carrier__r.State__c from Policy__c where Is_Selected__c=true and Opportunity__c=:theCase.Opportunity__c]){
                  if(carrierIdSet.contains(policy.Carrier__c)){
                      continue;
                  }
                  optn = new SelectOption(''+policy.Carrier__c,policy.Carrier__r.Name+' - '+policy.Carrier__r.State__c+' (Policy) ');
                  carrierOptions.add(optn);
                  carrierIdSet.add(policy.Carrier__c);
              }
              
            }else if(thecase.Benefit_Order__c!= null && theCase.RecordType.Name.indexOf('Benefits BoR') > -1) {
              for(Carrier_Order__c carrierInfo : [Select Id, Carrier__c,Carrier__r.Name, Carrier__r.State__c from Carrier_Order__c where Benefit_Order__c=:theCase.Benefit_Order__c]){
                  if(carrierIdSet.contains(carrierInfo.Carrier__c)){
                      continue;
                  }
                  optn = new SelectOption(''+carrierInfo.Carrier__c,carrierInfo.Carrier__r.Name+' - '+carrierInfo.Carrier__r.State__c+' (Carrier) ');
                  carrierOptions.add(optn);
                  carrierIdSet.add(carrierInfo.Carrier__c);
              }
            }
            //Lirik - Not in USE - Migration for BOR to BO -- Start ---
            /*}else if(thecase.BoR_Transfer__c!= null && theCase.RecordType.Name.indexOf('Benefits BoR') > -1) {
              for(Carrier_Information__c carrierInfo : [Select Id, Carrier__c,Carrier__r.Name, Carrier__r.State__c from Carrier_Information__c where BoR_Transfer_Id__c=:theCase.BoR_Transfer__c]){
                  if(carrierIdSet.contains(carrierInfo.Carrier__c)){
                      continue;
                  }
                  optn = new SelectOption(''+carrierInfo.Carrier__c,carrierInfo.Carrier__r.Name+' - '+carrierInfo.Carrier__r.State__c+' (Carrier) ');
                  carrierOptions.add(optn);
                  carrierIdSet.add(carrierInfo.Carrier__c);
              }
            }*/
            //Lirik - Not in USE - Migration for BOR to BO -- End ---
            
            
            for(Carrier__c carrier : [Select Id, Name, State__c,Renewal_Email_List__c,New_Plan_Email_List__c,BOR_Transfer_Email_List__c from Carrier__c]){
                if(theCase.RecordType.Name.indexOf('Benefits BoR') < 0){
                  if(carrier.Renewal_Email_List__c==null && carrier.New_Plan_Email_List__c==null){
                      continue;
                  }
                  if(carrierIdSet.contains(carrier.Id)){
                      continue;
                  }
                  optn = new SelectOption(''+carrier.Id,carrier.Name+' - '+carrier.State__c);
                  carrierOptions.add(optn);
                  carrierIdSet.add(carrier.Id);
                }else if(theCase.RecordType.Name.indexOf('Benefits BoR') > -1){
                  if(carrier.BOR_Transfer_Email_List__c==null ){
                      continue;
                  }
                  if(carrierIdSet.contains(carrier.Id)){
                      continue;
                  }
                  optn = new SelectOption(''+carrier.Id,carrier.Name+' - '+carrier.State__c);
                  carrierOptions.add(optn);
                  carrierIdSet.add(carrier.Id);
                  
                }
            }
        }
    }
    
    public PageReference renderEmailDetails(){
    email='';
        emailOptions = new List<SelectOption>();
        SelectOption optn = new SelectOption('','');
        emailOptions.add(optn);
        
        if(carrierId!=null && carrierId!=''){
            Carrier__c carrier = [Select Id, Renewal_Email_List__c,New_Plan_Email_List__c,BOR_Transfer_Email_List__c from Carrier__c where id=:carrierId];
            if(carrier.Renewal_Email_List__c!=null && carrier.Renewal_Email_List__c!=''){
                for(String emailInfo : carrier.Renewal_Email_List__c.split('\n')){
                    if(emailInfo.indexOf('::')>-1){

                        emailOptions.add(new SelectOption(emailInfo.split('::')[1].trim(),'Renewal - '+emailInfo.split('::')[0]));
                    }
                }
            }
            if(carrier.New_Plan_Email_List__c!=null && carrier.New_Plan_Email_List__c!=''){
                for(String emailInfo : carrier.New_Plan_Email_List__c.split('\n')){
                    if(emailInfo.indexOf('::')>-1){

                        emailOptions.add(new SelectOption(emailInfo.split('::')[1].trim(),'New Plan - '+emailInfo.split('::')[0]));
                    }
                }
            }
            if(carrier.BOR_Transfer_Email_List__c!=null && carrier.BOR_Transfer_Email_List__c!=''){
                for(String emailInfo : carrier.BOR_Transfer_Email_List__c.split('\n')){
                    if(emailInfo.indexOf('::')>-1){

                        emailOptions.add(new SelectOption(emailInfo.split('::')[1].trim(),'BoR Transfer - '+emailInfo.split('::')[0]));
                    }
                }
            }
        }
        
        return null;
    }
    
    public PageReference assignEmail(){
        /*
        if(carrierId!=null && carrierId!=''){
            Carrier__c carrier = [Select Id, Group_Benefits_and_Renewals_Email__c from Carrier__c where id=:carrierId];
            if(carrier.Group_Benefits_and_Renewals_Email__c!=null && carrier.Group_Benefits_and_Renewals_Email__c!=''){
                email = carrier.Group_Benefits_and_Renewals_Email__c;
            }
        }
        */
        return null;
    }
    

}