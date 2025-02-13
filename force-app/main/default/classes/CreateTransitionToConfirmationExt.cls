/** 
  * Description     :   On Carrier order,for creating/updating transition to fulfillment records based on record types-
  *                     Confirmation New Plan,Confirmation Renewal/Change with respective page layout
  *                     Buttons:Transition to Confirmation.
  *
  * Visualforce page:   NPRU_CreateTransitionToConfirmation

  * Created By      :   Syam Nukilla 
  *                
  * Created Date    :   10/03/2019
  **/
public class CreateTransitionToConfirmationExt {
    public String currentRecordId;
    public List<Transition_to_Fulfillment__c> lstTtfRec;
    public Carrier_Order__c coObj;
    public id  newrecordtypeid;
    public id renewalrecordtypeid;
    public String urlStr;
    public id carriernewrectypeid;
    public id fullfillrecordtypeid;
    public String contactId;
    public String ContactName;
    public List<Transition_to_Fulfillment__c> ttfRecCon;
    public CreateTransitionToConfirmationExt(ApexPages.StandardController standardController){
        lstTtfRec = new List<Transition_to_Fulfillment__c>();
        currentRecordId  = ApexPages.CurrentPage().getparameters().get('id');
        urlStr = null;
        carriernewrectypeid =cache.getRecordTypeId('Carrier_Order__c', 'New Plan');
    }
    // transition to Confirmation
    public PageReference initconfirmation(){
        newrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation New Plan');
        renewalrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Confirmation Renewal/Change');
        
        List<Carrier_Order__c> coList= [select id,name,Benefit_Order__c,Benefit_Order__r.name,
                                        Benefit_Order__r.Opportunity__c,Benefit_Order__r.Opportunity__r.name,
                                        Benefit_Order__r.Opportunity__r.Account.id,Benefit_Order__r.Opportunity__r.Account.name,recordtypeid 
                                        from Carrier_Order__c where id =:currentRecordId Limit 1];
        if(coList!=Null){
            coObj = coList[0];
            if(coObj.recordtypeid == carriernewrectypeid){
            fullfillrecordtypeid = newrecordtypeid;
            }
            else{
            fullfillrecordtypeid = renewalrecordtypeid;
            }
            ttfRecCon = [SELECT Id,Contact__r.id,Contact__r.name FROM Transition_to_Fulfillment__c WHERE Opportunity__c =:coObj.Benefit_Order__r.Opportunity__c];
            if(ttfRecCon.size()>0 && ttfRecCon!= Null){
                ContactName = ttfRecCon[0].Contact__r.name;
                ContactId = ttfRecCon[0].Contact__r.id;
            }
        }
        String prefix = Transition_to_Fulfillment__c.sobjectType.getDescribe().getkeyPrefix();
        lstTtfRec = [select id,name,Opportunity__c,Carrier_Order__c from Transition_to_Fulfillment__c where Benefit_Order__c=:coObj.Benefit_Order__c and (recordtypeid=:newrecordtypeid or recordtypeid=:renewalrecordtypeid)];
        if(lstTtfRec.size()==0){
            urlStr = '/'+prefix+'/e?retURL=%2F'+currentRecordId+'&RecordType='+fullfillrecordtypeid+'&ent=Transition_to_Fulfillment__c&CF00N3D000004yWa5='+coObj.name+'&CF00N3D000004yWa5_lkid='+coObj.id+'&CF00N1M00000FE19l='+coObj.Benefit_Order__r.name+'&CF00N1M00000FE19l_lkid='+coObj.Benefit_Order__c+'&CF00N1600000FDl7b_lkid='+coObj.Benefit_Order__r.Opportunity__c+'&CF00N1600000FDl7b='+coObj.Benefit_Order__r.Opportunity__r.name+'&CF00N1600000FDl7J_lkid='+coObj.Benefit_Order__r.Opportunity__r.Account.id+'&CF00N1600000FDl7J='+coObj.Benefit_Order__r.Opportunity__r.Account.name+'&CF00N3D000004jtw5_lkid='+ContactId+'&CF00N3D000004jtw5='+ContactName+'&nooverride=1';
        }
        else{
            urlStr = '/'+lstTtfRec[0].id+'/e?retURL=%2F'+coObj.id+'&RecordType='+fullfillrecordtypeid+'&ent=Transition_to_Fulfillment__c&nooverride=1';
        }
        PageReference pg = new PageReference(urlStr);
        pg.setRedirect(true);
        return pg;
    }
    // end of transition to Confirmation
}