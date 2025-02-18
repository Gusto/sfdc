/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class MassUpdateControllerCustom_Test {
    
    static testMethod void massUpdateNullTest() {
        
        List<Opportunity> oppList = new list<Opportunity>();
        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
        MassUpdateController_Custom tempController = new MassUpdateController_Custom(setCtr);
        
        system.assert(apexPages.hasMessages());
    }
    
    static testMethod void massUpdateTest() {
        
        list<UserRole> roleList = [select id from UserRole where Name='sales_sdr_partner_xx' limit 1];
        
        Id idUserRoleId;

        TestDataFactory.UserBuilder objUserBuilder = new TestDataFactory.UserBuilder()
			.setAlias('testo')
			.setUserName('Implementation.Advocate@Advocate.Implementation')
			.setEmailEncoding('UTF-8')
			.setFirstName('Implementation')
			.setLastName('Advocate')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setTimeZoneSidKey('America/Los_Angeles')
			.setExemptfromValidationRules(true)
            .setEmail('test@test.com')
            .setProfileId(UserInfo.getProfileId());
        
if(roleList != null && roleList.size() > 0)
            objUserBuilder.setUserRoleId(roleList.get(0).id);
        
        User objAdminUser = objUserBuilder.build();
        insert objAdminUser;
        
        system.runAs(objAdminUser){
            TestUtility.BenefitsNewPlanOpportunity();
        
        
        Opportunity o = new Opportunity();
        List<Opportunity> oppList = [SELECT name FROM Opportunity LIMIT 20];
        
        apexPages.currentPage().getParameters().put('id',oppList.get(0).id);
        ApexPages.StandardSetController setCtr = new ApexPages.StandardSetController(oppList);
        setCtr.setSelected(new Opportunity[]{o});
        MassUpdateController_Custom controller = new MassUpdateController_Custom(setCtr);
        //System.assertEquals(1, controller.getRecordSize()); 
        
        controller.getStep();
        controller.oppRec.OwnerId = Userinfo.getUserId();
        controller.step2();               
        controller.cancel();
            }
    }
    
    
}