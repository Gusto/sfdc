/**
 * @description  Apex class that business logic to identify all NBA rules that are applicable to the given record.
 * @author       Praveen Sethu
 * @date         07-19-2023
 * @see          NBACategoryAlignmentTest
 **/
public without sharing class NBACategoryAlignment {
	public static final String SOBJECT_TYPE_LEAD = 'Lead';
	public static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';

	/**
	 * @description  Wrapper class to share the response from the Apex class to the Lightning component
	 * @author       Praveen Sethu
	 **/
	public class NBACategoryAlignmentResponse {
		// flag to indicate success or error message
		@AuraEnabled
		public Boolean blnSuccess;

		// success or exception message
		@AuraEnabled
		public String strMessage;

		// list of NBA rules that are applicable to the given record
		@AuraEnabled
		public List<NBA_Rule_Set__c> list_RuleSets;

		@AuraEnabled
		public Map<String, String> map_TalkingPoints = new Map<String, String>();

		public NBACategoryAlignmentResponse(Boolean blnSuccess, String strMessage, List<NBA_Rule_Set__c> list_RuleSets, Map<String, String> map_TalkingPoints) {
			this.blnSuccess = blnSuccess;
			this.strMessage = strMessage;
			this.list_RuleSets = list_RuleSets;
			this.map_TalkingPoints = map_TalkingPoints;
		}
	}

	/**
	 * @description Method to identify all NBA rules that are applicable to the given record
	 * @return      Lead or Opportunity Record Id
	 **/
	@AuraEnabled
	public static NBACategoryAlignmentResponse getServedCategories(Id recordId) {
		List<NBA_Rule_Set__c> list_RuleSets = new List<NBA_Rule_Set__c>();
		String strObjectType = recordId.getSObjectType().getDescribe().getName();
        String strServedOtherRules = '';
		String strServedUpRule = '';
		String strRuleAbbreviation = '';
		Map<String, String> map_TalkingPoints = new Map<String, String>();

		try {
			SObject objRecord = Database.query('SELECT Id, Served_Other_Rules__c, Served_Up_Rule__c FROM ' + strObjectType + ' WHERE Id = :recordId');
			strServedOtherRules = (String) objRecord.get('Served_Other_Rules__c');
            strServedUpRule = (String) objRecord.get('Served_Up_Rule__c');
			if (String.isNotBlank(strServedUpRule) && strServedUpRule.contains('-')) {
				strRuleAbbreviation = strServedUpRule.substringAfter('-').trim();
			}

			if (String.isBlank(strRuleAbbreviation)) {
				return new NBACategoryAlignmentResponse(false, 'Missing rule set config abbreviation. Please contact admin', list_RuleSets, map_TalkingPoints);
			}

			// Iterate through all the NBA rules that are active and applicable to the given record
			for (NBA_Rule_Set__c objRuleSet : [
				SELECT Id, Name, Rule_Name__c, (SELECT Id, Current_Criteria__c, Base_Object__c, Talking_Points__c FROM NBA_Rule_Criteria__r)
				FROM NBA_Rule_Set__c
				WHERE Is_Active__c = TRUE AND NBA_Rule_Set_Configuration__r.Abbreviation__c = :strRuleAbbreviation
				ORDER BY Priority__c ASC
            ]) {
                String strRuleNameWithSuffix = objRuleSet.Rule_Name__c + ' - ' + strRuleAbbreviation;
                Boolean blnIsPrimary = false;
                // add primary hashtag to the rule name, if rule name matches with the Served Up Rule on the record
                if (String.isNotBlank(strServedUpRule) && strRuleNameWithSuffix == strServedUpRule) {
                    objRuleSet.Rule_Name__c = objRuleSet.Rule_Name__c + '#Primary';
                    blnIsPrimary = true;
                }
                // add the rule to the list of rules that are applicable to the given record
                for (NBA_Rule_Criteria__c objRuleCriteria : objRuleSet.NBA_Rule_Criteria__r) {
                    if (String.isNotBlank(objRuleCriteria.Current_Criteria__c) && String.isNotBlank(objRuleCriteria.Talking_Points__c)) {
                        NBARequestWrapper objRequest = (NBARequestWrapper) System.JSON.deserialize(objRuleCriteria.Current_Criteria__c, NBARequestWrapper.class);
                        if (objRequest.servingObject == strObjectType) {
                            map_TalkingPoints.put(objRuleSet.Id, objRuleCriteria.Talking_Points__c);
                        }
                    }
                }
                if(blnIsPrimary || (String.isNotBlank(strServedOtherRules) && strServedOtherRules.contains(strRuleNameWithSuffix))){
                	list_RuleSets.add(objRuleSet);
                }
            }
			// if no errors, return success response along with list of rule sets
			return new NBACategoryAlignmentResponse(true, 'Success', list_RuleSets, map_TalkingPoints);
		} catch (Exception ex) {
			return new NBACategoryAlignmentResponse(false, ex.getMessage(), list_RuleSets, map_TalkingPoints);
		}
	}
}