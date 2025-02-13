@isTest
public class OfficeFunctionalityCtrlTest {
    static testmethod void OfficeFunctionalitymethod(){
        
        OfficeFunctionalityCtrl objOffice=new OfficeFunctionalityCtrl();
        //get Logged in user Id
        User usr=new User(id=UserInfo.getUserId());
        usr.Out_Of_Office__c=true;
        update usr;
        
        objOffice=new OfficeFunctionalityCtrl();
        objOffice.outOfOfficeSelection();
        
    }
      
  }