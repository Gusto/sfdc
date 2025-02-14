/**
 * @name         : ReRouteCaseController
 * @author       : Pradeep Chary
 * @date         : 11-04-2024
 * @description  : Re-Route Case Flow Component Controller
 * @test classes : ReRouteCaseControllerTest
**/
public class ReRouteCaseController {

    // Set of profile names that can bypass the skill check
    private static final Set<String> set_ProfileNames = new Set<String>{
        'Biztech-BSA',
        'System Administrator',
        'ZP System Administrator'
    };
    
    /**
     * @Author      : Pradeep Chary
     * @Description : Check the Skills assigned to the Case
     * @Parm        : list_Input - Case Record
    **/
    @InvocableMethod(label='Check Case Skills' description='Check the Skills assigned to the Case')
    public static List<Boolean> checkCaseSkills(List<CaseInput> list_Input) {
        // Get the first case from the list
        CaseInput objInput = list_Input.get(0);
        // Initialize the skill match flag to false
        Boolean blnIsSkillMatched = false;
        
        // Get the case record from the input
        Case objCase = objInput.objCase;
        // Get the old case record from the input
        Case objOldCase = objInput.objOldCase;

        try {
            // Query User Details
            List<User> list_Users = [SELECT Id, Name, IsActive, ManagerId, Profile.Name 
                                     FROM User 
                                     WHERE Id = :UserInfo.getUserId() 
                                     AND IsActive = TRUE];
            // Check if the user is active and has a valid profile
            if (!list_Users.isEmpty() && set_ProfileNames.contains(list_Users[0].Profile.Name)) {
                return new List<Boolean> { blnIsSkillMatched };
            }

            if (objCase.Persona__c == CaseUtils.MEMBER_PERSONA && 
                (objCase.Type == CaseUtils.PAYROLL_CASE_PILLAR && objOldCase.Type == CaseUtils.TAXES_CASE_PILLAR) ||
                (objCase.Type == CaseUtils.TAXES_CASE_PILLAR && objOldCase.Type == CaseUtils.PAYROLL_CASE_PILLAR)) {
                    return new List<Boolean> { blnIsSkillMatched };
            }

            // Update the case pillar
            objCase = CaseTriggerHelper.updateCasePillar(objCase, objOldCase);
            // Check if the updated case pillar and old case pillar are same
            if (objCase.Sub_Pillar__c == objOldCase.Sub_Pillar__c && objCase.Routing_Team__c == objOldCase.Routing_Team__c) {
                blnIsSkillMatched = true;
            }
        } catch (Exception ex) {
            // Log the exception if needed
            ExceptionLogUtil.logException('ReRouteCaseController', 'checkCaseSkills', ex.getMessage(), ex.getStackTraceString());
        }

        // Return the skill match result
        return new List<Boolean> { blnIsSkillMatched };
    }

    /**
     * @Name        : CaseInput
     * @Author      : Pradeep Chary
     * @Description : Inputs for old and new case records
    **/
    public class CaseInput {
        @InvocableVariable(
            required=true
            label='Case Record'
            description='Updated Case Record'
        )
        public Case objCase;
        
        @InvocableVariable(
            required=true
            label='Prior Case Record'
            description='Old Case Record'
        )
        public Case objOldCase;
        
        public CaseInput() {}
    }
}