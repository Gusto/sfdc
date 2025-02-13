/***************************************************
Purpose : Whenever the user is Out of office make the changes in user and users Role object
Written By : Akash Sharma
Updated By : Deepika Saini (add Comments)
Test Classes : OfficeFunctionalityTest
****************************************************/
public class OfficeFunctionalityCtrl{
    //variable used for Show Message
    public String sectionMessage{get;set;}
    //variable used for check OutoFOffice is true or not
    public Boolean outOfOffice{get;set;}
    //variable used for User record
    public List<User> userRec;
    
    public OfficeFunctionalityCtrl(){
        userRec = new List<User>();
        userRec = [SELECT Out_Of_Office__c FROM User WHERE Id=:UserInfo.getUserId()];
        // User can only change the field(Out Of Office) value of itself only.
        if(userRec != NULL &&  userRec.size()>0){
            outOfOffice = userRec[0].Out_Of_Office__c;
        }
        else{
            sectionMessage = 'You are not the part of User Role Table. Contact your system Admin';        
        }
        
    }
    // User can only change the field(Out Of Office) value of itself only.
    public void outOfOfficeSelection(){
        if(userRec!=NULL){
            userRec[0].Out_Of_Office__c = outOfOffice;
            Update userRec;
        }
    }
}