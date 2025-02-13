/**
 * @name         : EngagementUserRole
 * @author       : Pradeep Chary
 * @date         : 01-18-2023
 * @description  : Checks the User Role belongs to the hierarchy of Engagement Role
 * @test classes : EngagementUserRoleTest
 **/
public class EngagementUserRole {
    
    public static Set<Id> set_EngagementRoleIds = new Set<Id>();
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Checks the User Role belongs to the hierarchy of Engagement Role
     * @Parm        : list_CurrentRoleIds - Prior User Role Ids
     * @Return      : Boolean True if the User Roles belongs to Engagement Role
     **/
    @InvocableMethod(
        label='Check If Role belongs to Engagement' 
        description='Boolean True if the User Role belongs to the Engagement Role'
    )
    public static List<Boolean> checkForEngagementUserRole(List<UserRoleInput> list_Inputs) {
        UserRoleInput objUserRoleInput = list_Inputs.get(0);
        
        if (set_EngagementRoleIds.isEmpty()) {
            set_EngagementRoleIds = constructUserRoleIds(objUserRoleInput.strRoleHierarchy);
        }
        
        if (set_EngagementRoleIds.contains(objUserRoleInput.idUserRole)) {
            return new List<Boolean>{ true };
        }
        
        return new List<Boolean>{ false };
    }
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Retunrs all the Roles Ids under Engagement Role
     * @Parm        : strRoleHierarchy - Role Hierarchies in consideration
     * @Return      : Set<Id> of Engagement Role Hierarchy Ids
     **/
    public static Set<Id> constructUserRoleIds(String strRoleHierarchy) {
        Set<Id> set_UserRoleIds = new Set<Id>();
        List<String> list_UserRoleNames = strRoleHierarchy.split(';');
        List<UserRole> list_UserRoles = [SELECT Id FROM UserRole WHERE DeveloperName IN :list_UserRoleNames];
        
        if (!list_UserRoles.isEmpty()) {
            Set<Id> set_RoleIds = new Set<Id>();
            for (UserRole objUserRole : list_UserRoles) {
                set_RoleIds.add(objUserRole.Id);
            }
            
            set_UserRoleIds = GlobalQueryHelper.getSubordinateRoles(set_RoleIds);
            set_UserRoleIds.addAll(set_RoleIds);
        }
        
        return set_UserRoleIds;
    }
    
    /**
     * @Name        : UserRoleInput
     * @Author      : Pradeep Chary
     * @Description : Inputs for User Flow to check User Role
     * @Date        : 01-25-2023
     **/
    public class UserRoleInput {
        @InvocableVariable(
            required=true
            label='User Role Id'
            description='Id of the Current User Role'
        )
        public Id idUserRole;
        
        @InvocableVariable(
            required=true
            label='Role Hierarchy'
            description='Role Hierarchies in consideration, add semi-colon for multiple values'
        )
        public String strRoleHierarchy;
        
        public UserRoleInput() {}
    }
}