/**
 * Author: Lakshey Mendiratta
 * Date: 9/17/2020
 * Desc: Controller for UserQueue LWC
 */
public with sharing class UserQueueComponentController_LEX {

    public class EventDataWrapper {
        @AuraEnabled public Id Id {get;set;}
        @AuraEnabled public String strBenefitsClass {get;set;}
        @AuraEnabled public String strClassQueue {get;set;}
        @AuraEnabled public Boolean blnOutOfOffice {get;set;}
            
    }

    @AuraEnabled
    public static List<User> updateUserData(String strUserUpdateData){
        //Method to update user data
        List<EventDataWrapper> lst_updateRecords = (List<EventDataWrapper>)JSON.deserialize(strUserUpdateData,List<EventDataWrapper>.class);
        if(!lst_updateRecords.isEmpty()){
            List<User> lst_userUpdate = new List<User>();
            for(EventDataWrapper user: lst_updateRecords){
                User objTempUser = new User();
                objTempUser.Id = user.Id;
                objTempUser.Class_Queue__c = user.strClassQueue;
                objTempUser.Benefits_Class__c = user.strBenefitsClass;
                if(user.blnOutOfOffice != null){
                    objTempUser.Out_Of_Office__c = user.blnOutOfOffice;
                }
                lst_userUpdate.add(objTempUser);
            }

            if(!lst_updateRecords.isEmpty()){
                update(lst_userUpdate);
            }
        }
        return [SELECT Id, FirstName, LastName, Class_Queue__c, Benefits_Class__c, Out_Of_Office__c, Individual_Queues__c,
                All_Queues__c, On_The_Floor_Date_Care__c, On_The_Floor_Date_PRC_Class_2__c, On_The_Floor_Date_PRC_Class_3__c,
                On_The_Floor_Date_FSC__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP__c,
                On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c, PRC_Homeroom_Start_Date__c, FSC_Homeroom_Start_Date__c 
                FROM User 
                ORDER BY Name ASC NULLS LAST];
    }

    @AuraEnabled
    public static List<User> retrieveUsers(String strUserName, String strUserRole) {
        // Method to retrieve users on the basis of search string 
        strUserName = '%' + strUserName + '%';
        strUserRole = '%' + strUserRole + '%';

        List<User> lst_Users = [SELECT Id, FirstName, LastName, Class_Queue__c, Benefits_Class__c, Out_Of_Office__c, Individual_Queues__c, 
                                All_Queues__c, On_The_Floor_Date_Care__c, On_The_Floor_Date_PRC_Class_2__c, On_The_Floor_Date_PRC_Class_3__c,
                                On_The_Floor_Date_FSC__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP__c,
                                On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c, PRC_Homeroom_Start_Date__c, FSC_Homeroom_Start_Date__c  
                                FROM User 
                                WHERE ((Name LIKE :strUserName) AND (UserRole.Name LIKE :strUserRole)) 
                                ORDER BY Name ASC NULLS LAST];

        if(lst_Users.isEmpty()) {
            throw new AuraHandledException('No Record Found..');
        }
        return lst_Users; 
    }

    @AuraEnabled
    public static List<User> retrieveRoles(String strRoleName, String strUserName) {
        // Method to retrieve roles on the basis of search string 
        strRoleName = '%' + strRoleName + '%';
        strUserName = '%' + strUserName + '%';
        List<User> lst_Users = [SELECT Id, FirstName, LastName, Class_Queue__c, Benefits_Class__c, Out_Of_Office__c, Individual_Queues__c, All_Queues__c,
                                On_The_Floor_Date_Care__c, On_The_Floor_Date_PRC_Class_2__c, On_The_Floor_Date_PRC_Class_3__c,
                                On_The_Floor_Date_FSC__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP__c,
                                On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c, PRC_Homeroom_Start_Date__c, FSC_Homeroom_Start_Date__c  
                                FROM User 
                                WHERE UserRole.Name LIKE :strRoleName AND Name LIKE :strUserName 
                                ORDER BY Name ASC NULLS LAST];

        if(lst_Users.isEmpty()) {
            throw new AuraHandledException('No Record Found..');
        }
        return lst_Users; 
    }


    @AuraEnabled(cacheable=true)
    public static List<User> getUserData(){
        //Method to fetch all user data required
        return [SELECT Id, FirstName, LastName, Class_Queue__c, Benefits_Class__c, Out_Of_Office__c, Individual_Queues__c, All_Queues__c,
                On_The_Floor_Date_Care__c, On_The_Floor_Date_PRC_Class_2__c ,On_The_Floor_Date_PRC_Class_3__c,
                On_The_Floor_Date_FSC__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP__c,
                On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c, PRC_Homeroom_Start_Date__c, FSC_Homeroom_Start_Date__c  
                FROM User 
                ORDER BY Name ASC NULLS LAST];
    }

    @AuraEnabled
    public static List<User> getDirectReportUsers(String strLoggedInUserId){
        //Method to fetch the direct report users to the logged in User
        
        List<User> lst_Users = [SELECT Id, FirstName, LastName, Class_Queue__c, Benefits_Class__c, Out_Of_Office__c, Individual_Queues__c, All_Queues__c,
                                On_The_Floor_Date_Care__c, On_The_Floor_Date_PRC_Class_2__c, On_The_Floor_Date_PRC_Class_3__c,
                                On_The_Floor_Date_FSC__c, On_The_Floor_Date_FSC_Class_2__c, On_The_Floor_Date_FSC_Class_3__c, On_The_Floor_Date_DSP__c,
                                On_The_Floor_Date_DSP_Class_2__c, On_The_Floor_Date_DSP_Class_3__c, PRC_Homeroom_Start_Date__c, FSC_Homeroom_Start_Date__c 
                                FROM User 
                                WHERE ManagerId =: strLoggedInUserId 
                                ORDER BY Name ASC NULLS LAST];
        return lst_Users;
    }
}