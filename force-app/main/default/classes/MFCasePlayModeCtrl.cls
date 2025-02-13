/**
 * @description  Play MF Case records
 * @author       Bhagat Singh
 * @date         11/14/2024
 * @see          MFCasePlayModeCtrlTest.cls
 **/
public with sharing class MFCasePlayModeCtrl {
	public static final String CONTACT_PLAY_MODE = 'Contact Play Mode';
	public static final String STR_NONE = '--None--';
	public static String strPlayClass;

	/**
	 * @description Returns Login user information.
	 * @author      Bhagat Singh
	 * @param       NA.
	 * @return      Object of UserInfoWrapper record.
	 **/
	@AuraEnabled(cacheable=true)
	public static UserInfoWrapper getUserInformation() {
		UserInfoWrapper objUserInfo = new UserInfoWrapper();
		objUserInfo.objloggedInUser = new User();
		objUserInfo.list_CaseTypes = new List<SelectOptionWrapper>();
		objUserInfo.list_Carries = new List<SelectOptionWrapper>();
		objUserInfo.list_CaseNumber = new List<SelectOptionWrapper>();
		List<User> list_Users = [SELECT Id, Selected_Case_Type_for_Play_Mode__c, Selected_Carrier_Type_for_Play_Mode__c FROM User WHERE Id = :UserInfo.getUserId()];
		if (list_Users.size() > 0) {
			objUserInfo.objloggedInUser = list_Users[0];
		}

		objUserInfo.list_CaseTypes.add(new SelectOptionWrapper(STR_NONE, STR_NONE));
		if (objUserInfo.objloggedInUser.id != null && objUserInfo.objloggedInUser.Selected_Case_Type_for_Play_Mode__c != null) {
			Set<String> set_SelectedValue = new Set<String>();
			set_SelectedValue.addAll(objUserInfo.objloggedInUser.Selected_Case_Type_for_Play_Mode__c.split(';'));
			for (Play_Mode_Config__c obj : Play_Mode_Config__c.getAll().values()) {
				if (set_SelectedValue.contains(obj.Name)) {
					objUserInfo.list_CaseTypes.add(new SelectOptionWrapper(obj.Name, obj.Name));
				}
			}
		}

		objUserInfo.list_Carries.add(new SelectOptionWrapper(STR_NONE, STR_NONE));
		if (objUserInfo.objloggedInUser.id != null && objUserInfo.objloggedInUser.Selected_Carrier_Type_for_Play_Mode__c != null) {
			Schema.DescribeFieldResult fieldResult = Carrier__c.Carrier_Play_Mode__c.getDescribe();
			List<Schema.PicklistEntry> list_Values = fieldResult.getPicklistValues();

			Set<String> set_SelectedValue = new Set<String>();
			set_SelectedValue.addAll(objUserInfo.objloggedInUser.Selected_Carrier_Type_for_Play_Mode__c.split(';'));

			for (Schema.PicklistEntry objPicklist : list_Values) {
				if (set_SelectedValue.contains(objPicklist.getValue())) {
					objUserInfo.list_Carries.add(new SelectOptionWrapper(objPicklist.getLabel(), objPicklist.getValue()));
				}
			}
		}

		for (Integer intIndex = 0; intIndex <= 10; intIndex++) {
			String strValue = intIndex + '';
			objUserInfo.list_CaseNumber.add(new SelectOptionWrapper(strValue, strValue));
		}

		return objUserInfo;
	}

	public class UserInfoWrapper {
		@AuraEnabled
		public User objloggedInUser;
		@AuraEnabled
		public List<SelectOptionWrapper> list_CaseTypes;
		@AuraEnabled
		public List<SelectOptionWrapper> list_Carries;
		@AuraEnabled
		public List<SelectOptionWrapper> list_CaseNumber;
	}

	public class SelectOptionWrapper {
		@AuraEnabled
		public String strLabel;
		@AuraEnabled
		public String strValue;

		public SelectOptionWrapper(String strLabel, String strValue) {
			this.strLabel = strLabel;
			this.strValue = strValue;
		}
	}

	/**
	 * @description Return Play mode case record Ids.
	 * @author      Bhagat Singh
	 * @param       NA.
	 * @return      List of String.
	 **/
	@AuraEnabled(cacheable=false)
	public static List<String> executePlay(String strCaseType, String strCarrierType, String strCount) {
		strCaseType = validateValue(strCaseType);
		strCarrierType = validateValue(strCarrierType);
		List<String> list_Cases = QualifyingLifeCasePlayModeController.executePlay(strCaseType, strCarrierType, strCount);

		return list_Cases;
	}

	/**
	 * @description Return Available case records.
	 * @author      Bhagat Singh
	 * @param       NA.
	 * @return      String as a message.
	 **/
	@AuraEnabled(cacheable=false)
	public static String getCaseDetails(String strCaseType, String strCarrierType) {
		strCaseType = validateValue(strCaseType);
		strCarrierType = validateValue(strCarrierType);
		String strFinalValue = QualifyingLifeCasePlayModeController.getSortingDetails(strCaseType, strCarrierType);
		strFinalValue = strFinalValue.replace('<b>', '');
		strFinalValue = strFinalValue.replace('</b>', '');

		return strFinalValue;
	}

	public static String validateValue(String strInputValue) {
		if (strInputValue == STR_NONE) {
			strInputValue = '0';
		}

		return strInputValue;
	}
}