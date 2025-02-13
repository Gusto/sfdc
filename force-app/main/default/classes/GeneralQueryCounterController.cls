/*
 * Description: Contains methods to load the General Query Counter LWC
 * Author: Omar Benitez
 * Date: 08/01/2024
 */
public without sharing class GeneralQueryCounterController {
	//This method loads the configuration from metadata to return the map of response.
	@AuraEnabled(cacheable=true)
	public static Map<String, Integer> loadCmp() {
		Map<String, Integer> map_result = new Map<String, Integer>();
		List<General_Query_Counter_Comp_Setting__mdt> list_metadata = General_Query_Counter_Comp_Setting__mdt.getAll().values();
		Set<String> set_customPerm = new Set<String>();
		Map<String, List<General_Query_Counter_Comp_Setting__mdt>> map_customPermMeta = new Map<String, List<General_Query_Counter_Comp_Setting__mdt>>();

		for (General_Query_Counter_Comp_Setting__mdt obj_meta : list_metadata) {
			set_customPerm.add(obj_meta.Custom_Permission__c);
			if (map_customPermMeta.get(obj_meta.Custom_Permission__c) == null) {
				map_customPermMeta.put(obj_meta.Custom_Permission__c, new List<General_Query_Counter_Comp_Setting__mdt>());
			}
			map_customPermMeta.get(obj_meta.Custom_Permission__c).add(obj_meta);
		}
		Set<String> set_userPermissions = new Set<String>();
		for (String strCustomPerm : set_customPerm) {
			if (FeatureManagement.checkPermission(strCustomPerm)) {
				set_userPermissions.add(strCustomPerm);
			}
		}
		for (String strCustomPerm : set_userPermissions) {
			for (General_Query_Counter_Comp_Setting__mdt obj_meta : map_customPermMeta.get(strCustomPerm)) {
				String strSQOL = NBAUtil.replaceCustomFunctions(obj_meta.SOQL__c);
				AggregateResult[] list_results = Database.query(strSQOL);
				Integer intResult = (Integer) list_results[0].get('expr0');
				map_result.put(obj_meta.Label__c, intResult);
			}
		}
		return map_result;
	}
}