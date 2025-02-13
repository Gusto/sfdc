/*
--@Author: Deepak Tyagi
--@CreateDate: 02/27/2019
--@Jira: BT-3976
*/
public class ProductUpsellPageExtension {
	public Partnership_Interest__c interestObj{get;set;}
	public Opportunity oppRec;
	public list<selectOption> contactList {get;set;}
    public String selectedContact{get;set;}
    public List<SelectOption> lst_401kPicklistValues {get;set;}
    public String strSelected401kVal {get;set;}
	
	public ProductUpsellPageExtension(ApexPages.StandardController sc){   
		interestObj = new Partnership_Interest__c();  
        oppRec = (Opportunity)sc.getRecord();
        contactList = new list<selectOption>();
        contactList.add(new SelectOption('None','None'));
        lst_401kPicklistValues = get401kPicklistValuesForSalesRT();
        interestObj.RecordTypeId = cache.getRecordTypeId('Partnership_Interest__c','New Partnership Interest');
        if(oppRec != Null){
        	interestObj.Opportunity__c = oppRec.Id;
            oppRec = [Select Id, AccountId From Opportunity Where Id =: oppRec.Id Limit 1];
        	if(oppRec.AccountId != Null){
	        	interestObj.Account__c = oppRec.AccountId;
	        }
	        for(OpportunityContactRole role : [Select Id, ContactId, Contact.Name From OpportunityContactRole Where OpportunityId =: oppRec.Id]){
	        	contactList.add(new SelectOption(role.ContactId, role.Contact.Name));
	        }
        }
    }
    
    public pageReference saveRec(){
    	if(selectedContact == 'None'){
            apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,'Please select Contact.'));
            return null;
        }
        interestObj.Contact__c = selectedContact;

        if (strSelected401kVal != 'None') {
            interestObj.Interest_401K__c = strSelected401kVal;
        }

        try{
        	insert interestObj;
        }catch(exception ex){
            apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error,'Error occurred while creating the record.'+ex.getMessage()));
                return null;
        }
        
        return new pageReference('/'+interestObj.id);
    }

    public static List<SelectOption> get401kPicklistValuesForSalesRT() {
        List<SelectOption> lst_401kSalesRTPicklist = new List<SelectOption>();
        lst_401kSalesRTPicklist.add(new SelectOption('None','None'));
        for (String strPicklistVal : Label.X401k_Interest_Picklist_Values.split(',')) {
            lst_401kSalesRTPicklist.add(new SelectOption(strPicklistVal.trim(),strPicklistVal.trim()));
        }
        return lst_401kSalesRTPicklist;
    }
}