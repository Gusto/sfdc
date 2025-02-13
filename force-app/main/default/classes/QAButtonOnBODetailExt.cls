public class QAButtonOnBODetailExt {
    string currentRecordId;
    public QA_Sheet__c QAObj{get;set;}
    public QAButtonOnBODetailExt(ApexPages.StandardController sc){
        currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
        List<QA_Sheet__c> qaList = [select id,name,Benefits_Point_of_Contact_Name_SFDC__c,Mailing_Address__c,Effective_Date__c from QA_Sheet__c where Benefit_Order__c =:currentRecordId]; 
        if(qaList!=Null && qaList.size()>0){
            QAObj = qaList[0];
        }
    }

    public PageReference DisplayQARecord(){
        if(QAObj!=Null){
            PageReference pageRef = new PageReference('/'+QAObj.id);
            return pageRef;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no QA Sheet is not available for this Benefit Order'));
    		return null;
        }
       /* list<QA_Sheet__c> qalist = [select id from QA_Sheet__c where Benefit_Order__c =:currentRecordId];
        if(qalist.size()>0){
        PageReference pageRef = new PageReference('/apex/NPRU_DisplayEditQASheet?id='+qalist[0].id);
        return pageRef;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'There is no QA Sheet is not available for this Benefit Order'));
    		return null;
        }*/
    }
}