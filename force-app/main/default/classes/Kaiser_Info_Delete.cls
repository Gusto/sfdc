/**
    @author - Rakesh Vishwanathula
    @CreatedDate - 09/16/2020
    @Description - This Class will delete Kaiser group & member data in SFDC and mainly used by Workato integration as we don't have bulk delete operation in Workato
**/
@RestResource(urlMapping='/kaiser/delete/kaiserInfo/*')
global with sharing class Kaiser_Info_Delete {
	@HttpDelete
	global static String DeleteGroupsOrMembersInfo() {
		RestRequest req = RestContext.request;
		String strResponse;
		String strObjectInfo = req.params.containsKey('object') ? req.params.get('object') : '';
		String strRegion = req.params.containsKey('region') ? req.params.get('region') : '';

		if (String.isBlank(strObjectInfo) || String.isBlank(strRegion)) {
			return 'FAILURE';
		}

		if (strObjectInfo == 'Kaiser_Groups_Info__c') {
			String strQuery = 'SELECT Id FROM Kaiser_Groups_Info__c';
			if (strRegion == 'CA') {
				strQuery += ' WHERE Region_ID__c LIKE \'%NCR%\' OR Region_ID__c LIKE \'%SCR%\'';
			} else {
				strQuery += ' WHERE Region_ID__c LIKE \'%' + strRegion + '%\'';
			}
			strQuery += ' LIMIT 10000';

			try {
				List<Kaiser_Groups_Info__c> list_GroupInfo = Database.query(strQuery);
				if (!list_GroupInfo.isEmpty()) {
					delete list_GroupInfo;
				}
				strResponse = 'SUCCESS';
			} catch (Exception ex) {
				strResponse = 'FAILURE';
			}
		} else if (strObjectInfo == 'Kaiser_Member_Info__c') {
			String strQuery = 'SELECT Id FROM Kaiser_Member_Info__c';
			if (strRegion == 'CA') {
				strQuery += ' WHERE KP_Region_Code__c LIKE \'%NCR%\' OR KP_Region_Code__c LIKE \'%SCR%\'';
			} else {
				strQuery += ' WHERE KP_Region_Code__c LIKE \'%' + strRegion + '%\'';
			}
			strQuery += ' LIMIT 10000';

			try {
				List<Kaiser_Member_Info__c> list_MemberInfo = Database.query(strQuery);
				if (!list_MemberInfo.isEmpty()) {
					delete list_MemberInfo;
				}
				strResponse = 'SUCCESS';
			} catch (Exception ex) {
				strResponse = 'FAILURE';
			}
		} else {
			strResponse = 'FAILURE';
		}
		return strResponse;
	}
}