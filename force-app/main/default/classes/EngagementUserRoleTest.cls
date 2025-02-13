/**
* @Author       :   Pradeep Chary
* @CreatedDate  :   01-18-2023
* @Desc         :   Test class for EngagementUserRole
**/
@isTest
public class EngagementUserRoleTest {

    /**
     * @Author      : Pradeep Chary
     * @Description : Test method to check input UserRole belongs to Engagement Role Hierarchy
    **/
    @isTest
    public static void testCheckForEngagementUserRole() {
        Test.startTest();

        UserRole objUserRole = [SELECT Id FROM UserRole WHERE Name = 'Core & Complete'];
        EngagementUserRole.UserRoleInput objUserRoleInput = new EngagementUserRole.UserRoleInput();
        objUserRoleInput.idUserRole = objUserRole.Id;
        objUserRoleInput.strRoleHierarchy = 'Engagement';
        List<Boolean> list_EngagementRoles = 
            EngagementUserRole.checkForEngagementUserRole(new List<EngagementUserRole.UserRoleInput>{ objUserRoleInput });
        System.assertEquals(true, list_EngagementRoles.get(0));

        Test.stopTest();
    }
    
}