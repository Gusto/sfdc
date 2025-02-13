/********************************************************************
* Info : AdvocateTabCompCtrlTest is used to cover AdvocateTabCompCtrl
*       * 
* Created by : Lirik on 11/17/2020
***********************************************************************/ 

@isTest
public class AdvocateTabCompCtrlTest {
	static testMethod void testAdvocateTabCompCtrl() {
        //Create Role
        Role__c ptaRole = new Role__c(Name = 'Payroll Transfer Advocate');
        ptaRole.Skill_Type__c='Core';
        insert ptaRole;        
        
        //Create Skill
        List<Skill__c> lstSkill = new List<Skill__c>();
        lstSkill.add(new Skill__c(Payroll_Transfer_Skills__c ='Bulk',Role__c = ptaRole.Id));
        lstSkill.add(new Skill__c(Payroll_Transfer_Skills__c ='Direct',Role__c = ptaRole.Id));
        insert lstSkill;
        //Create user Role
        User_Role__c userRoleObj = new User_Role__c();
        userRoleObj.User__c = userinfo.getUserId();
        insert userRoleObj;
        
        //Create User Skill
        User_Skill__c userSkillObj = new User_Skill__c();
        userSkillObj.Skill__c = lstSkill[0].id;
        userSkillObj.User_Role__c = userRoleObj.Id;  
        userSkillObj.Skill_role_name__c = 'Payroll Transfer Advocate';
        insert userSkillObj;
        
        AdvocateTabCompCtrl objAdvTab=new AdvocateTabCompCtrl();	
    }
}