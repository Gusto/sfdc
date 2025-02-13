@isTest
public class CreateSkillRecordsCtrlTest {
	@isTest
	private static void testPayrollFacilitatorRole() {
		List<Role__c> RoleList = new List<Role__c>();
		Role__c ptRole = new Role__c();
		ptRole.name = 'Payroll Transfer Facilitator';
		RoleList.add(ptRole);
		insert (RoleList);
		CreateSkillRecordsCtrl obj = new CreateSkillRecordsCtrl(ptRole.Name);
		obj.CreatePayrollFacilitatorRoleAndSkill();
		Integer intPTSkill = obj.list_PayrollTransferSkill.size();
		Integer intComplexityScore = obj.list_PayrollComplexityScore.size();
		Integer intExpRequest = obj.list_ExceptionRequest.size();
		Integer intProvider = obj.list_PayrollProviderType.size();
		Integer intSalesTeam = obj.list_PayrollSalesTeam.size();

		Integer intIARecordPermutation = (intPTSkill * intComplexityScore * intExpRequest * intProvider * intSalesTeam);
		Integer intIARec = [SELECT COUNT() FROM Skill__c WHERE Role__r.Name = 'Payroll Transfer Facilitator'];
		System.assertEquals(intIARecordPermutation, intIARec);
	}
}