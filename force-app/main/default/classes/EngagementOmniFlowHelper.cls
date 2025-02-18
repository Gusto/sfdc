global class EngagementOmniFlowHelper {
    @InvocableMethod(label='Get Skill Requirements')
    public static List<SkillRequirement> getSkillRequirements(List<skillCaseWrapper> skillCaseWrapperList) {
        List<SkillRequirement> skillRequirementList = new List<SkillRequirement>();
        System.debug('**** '+skillCaseWrapperList);
        SkillRequirement skillReq = new SkillRequirement();
        skillReq.SkillId = skillCaseWrapperList[0].skillRec.Id;
        skillReq.RelatedRecordId = skillCaseWrapperList[0].caseRecord.Id;
        skillReq.SkillLevel = Decimal.ValueOf(skillCaseWrapperList[0].caseRecord.Skill_level__c);
        return skillRequirementList;
    }
    public class skillCaseWrapper{
        @InvocableVariable(required=true)
        public Skill skillRec;
        @InvocableVariable(required=true)
        public case caseRecord;
    }
}