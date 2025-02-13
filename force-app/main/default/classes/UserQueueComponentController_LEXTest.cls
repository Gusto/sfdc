@isTest
public class UserQueueComponentController_LEXTest {
    
    static testMethod void testGetUserData(){
        // Method to get user details
        Test.startTest();
       List<User> lst_Users = UserQueueComponentController_LEX.getUserData(); 
        System.assertEquals(true, lst_Users.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testUpdateUserData(){
        //Method to update USer Record.
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
        
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser234566@testorg.com');
        insert u;
        
        
        Map<String,String> jsonStringMap = new Map<String,String>();
        jsonStringMap.put('Id',u.Id);
        jsonStringMap.put('ClassQueue','Class 1');
        jsonStringMap.put('BenefitsClass', 'Class 1');
        
        List<Map<String,String>> jsonStringList = new List<Map<String,String>>();
        jsonStringList.add(jsonStringMap);
        
        Test.startTest();
        List<User> lst_updateUser = UserQueueComponentController_LEX.updateUserData(JSON.serialize(jsonStringList));
        System.assertEquals(true, lst_updateUser.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testgetDirectReports(){
        // Method to fetch the direct reports to the logged in user
        Id userId = UserInfo.getUserId();
        Test.startTest();
        List<User> lst_user = UserQueueComponentController_LEX.getDirectReportUsers(userId);
        // System.assertEquals(true, lst_user.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testretrieveRoles(){
        //Method to return roles based on the search string
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
        
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser234566@testorg.com');
        insert u;
        
        Test.startTest();
        List<User> lst_userRole = UserQueueComponentController_LEX.retrieveRoles('My Role', u.LastName);
        System.assertEquals(true, lst_userRole.size()>0);
        Test.stopTest();
    }
    
    static testMethod void testretrieveUsers(){
        //Method to return Users based on the search string
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
        
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, UserRoleId = r.Id,
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser234566@testorg.com');
        insert u;
        
        Test.startTest();
        List<User> lst_userName =  UserQueueComponentController_LEX.retrieveUsers(u.LastName, 'My Role');
        System.assertEquals(true, lst_userName.size()>0);
        Test.stopTest();
    }
}