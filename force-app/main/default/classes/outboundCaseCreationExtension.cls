public with sharing class outboundCaseCreationExtension {
	

	public string selectedRecordType{get;set;}
	public string newCaseId{get;set;}
    public string caseSubject{get;set;}

	list<string> recordTypePicklistValues = new list<string>();
	string contactid;

	public outboundCaseCreationExtension(apexpages.standardController sc) {		

		contactid = sc.getId();

		for(RecordType rec:[select Id,Name from RecordType where sObjectType='Case' and IsActive = true]){
        	recordTypePicklistValues.add(rec.Name);
        }
        userDefaultRecordType();
	}

	Public List<SelectOption> getCaseRecordTypeList() {
        List<SelectOption> options = new List<SelectOption>();
        for(string rec: recordTypePicklistValues){
        	options.add(new SelectOption(rec,rec));
        }
        return options;
    }

    public void createCase(){

    	if(string.isNotBlank(selectedRecordType) && string.isNotBlank(contactid)){

    		Contact conRec = [select id, AccountId from Contact where id=:contactid];

    		Case newCase = new Case();
    		newCase.RecordTypeId = cache.getRecordTypeId('Case',selectedRecordType);
    		newCase.origin = 'Email';
    		newCase.Direction__c = 'Outbound';
    		newCase.ContactId = conRec.id;
    		newCase.AccountId = conRec.AccountId;
            if(string.isNotBlank(caseSubject))
                newCase.Subject = caseSubject;

    		if(selectedRecordType == 'Payroll Care'){
    			newCase.Type = 'Payroll Care';
    		}else if(selectedRecordType == 'Benefits Care'){
    			newCase.Type = 'Benefits Care';
    		}else if(selectedRecordType == 'Tax Res'){
				newCase.Type = 'Tax Res';
    		}else if(selectedRecordType == 'Modern Bank'){
    			newCase.Type = 'Payroll Care';
    		}

    		try{
    			insert newCase;
    			newCaseId = newCase.id;
    		}
    		catch(exception ex){
    			apexPages.addMessage(new apexPages.Message(apexPages.severity.error,ex.getMessage()));
    		}
    	}
    }


    public void  userDefaultRecordType(){
        Schema.DescribeSObjectResult R = Case.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        for(Schema.RecordTypeInfo rec: RT){
            if(rec.isDefaultRecordTypeMapping()){
                selectedRecordType =  rec.getName();
                break;
            }
        }
    }
}