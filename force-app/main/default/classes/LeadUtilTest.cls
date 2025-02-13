@isTest
private without sharing class LeadUtilTest{

    @isTest
    static void testGeneral(){
        LeadUtil ldUtil = new LeadUtil();
    }//NOPMD

    @isTest
    static void test(){
        Map<String, Integer> map_ResultG2 = LeadUtil.map_G2CrowdLabelToEE;
        Map<String, Integer> map_ResultCompStatus = LeadUtil.map_CompLeadStatusOrder;
        Map<String, Integer> map_ResultResStatus = LeadUtil.map_ResLeadStatusOrder;
        Set<String> set_ResultFakeEmails = LeadUtil.set_FakeEmails;
        Set<String> set_ResultExcludeRev = LeadUtil.set_ExcludeStatusRevert;
        Set<String> set_ResultQualifStatus = LeadUtil.set_LeadQualificationStatuses;
        Set<String> set_ResultTestComps = LeadUtil.set_TestCompanies;
        Set<Id> set_ResultLdCreationUsers = LeadUtil.set_LeadCreationUsers;
        Set<String> set_ResultLeadCreatOffers = LeadUtil.set_LdCreationOffer;
        Set<String> set_ResultExcEmailDomains = LeadUtil.set_Exclude_EmailDomains;
    }//NOPMD
}