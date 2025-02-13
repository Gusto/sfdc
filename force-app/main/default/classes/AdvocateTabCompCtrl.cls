public class AdvocateTabCompCtrl {
	public boolean IsFacilitator{get;set;}
    public AdvocateTabCompCtrl(){
        checkLoggedInUserRole();
    }

    private void checkLoggedInUserRole(){
        IsFacilitator=false;
        for(User_Skill__c  us: [select Skill__c,Skill__r.Role__r.Name from User_Skill__c where 
            User_Role__r.User__c=:UserInfo.getUserId() and Skill__c!=null and Skill__r.Role__r.Name !=null 
            and (Skill__r.Role__r.Name='Payroll Transfer Advocate' or Skill__r.Role__r.Name='Payroll Transfer Facilitator')]){
                string strRoleName=us.Skill__r.Role__r.Name;
                //If they have only as a Facilitator role. If it both then it will be treat as non Facilitator
                if(strRoleName.indexOf('Facilitator')>-1 && strRoleName.indexOf('Advocate')==-1){
                    IsFacilitator=true;
                }
        }
    }
}