/**
 * @name         SandboxPostRefresh
 * @author       Sanjay Paryani
 * @date         07/07/2020
 * @description  Sandbox Post Refresh class. Runs after sandbox refresh (if indicated).
 * @revisions    Date ------------ Name ------------ Comments
 *               07/07/2020        SanjayP           Added check to get fields only if they are editable.
 *               07/07/2020        SanjayP           Added check to get users only if they are active.
 *               07/07/2020        SanjayP           Changed unmasking technique as Salesforce currently uses .invalid for email masking.
 *				09/03/2020		  SanjayP			Added maskEmails(set_ObjectNames) method to mask only for certain objects.
 *				10/22/2020		  SanjayP			Added creation of user records after a sandbox refresh. This is useful to add non-gusto user records.
 **/
public class SandboxPostRefresh implements SandboxPostCopy {
	public static Sandbox_Refresh_Config__c objSandboxRefreshSettings = SandboxPostRefreshUtils.objSandboxRefreshSettings;
	public static Configuration_Settings__c objConfigSettings = SandboxPostRefreshUtils.objConfigSettings;
	public static String strDevOrgName = objSandboxRefreshSettings?.Dev_Environment_Name__c;
	public static String strUATOrgName = objSandboxRefreshSettings?.UAT_Environment_Name__c;
	public static String strIntgnOrgName = objSandboxRefreshSettings?.Integration_Environment_Name__c;
	public static Set<String> set_FieldsToMask = new Set<String>();
    public static final String ZP_SYSTEM_ADMINISTRATOR = 'ZP System Administrator';
    public static final String BIZTECH_BSA = 'Biztech-BSA';

	/**
	 * @description  This method runs during the post Sandbox refresh process.
	 */
	public static void runApexClass(SandboxContext context) {
		String strSandboxName = context.sandboxName();
        updateBiztechBSAUserToSysAdmin();
		unmaskUsers(strSandboxName);
		maskEmails();
		createUserRecords(strSandboxName);
		createEntitlementRecords();
		System.enqueueJob(new ImportCSVDataController.ImportGFLeadData());
	}

	/**
	 * @description  This method will unmask Salesforce users' email address. Functionality driven off the Sandbox_User_Unmask__c Custom Setting
	 */
	public static void unmaskUsers(String strSandboxName) {
		Map<Id, String> map_UserToEmail = new Map<Id, String>();
		Set<Id> set_UserIDs = new Set<Id>();
		Set<Id> set_ProfileIDs = new Set<Id>();
		String strSOQLQuery = '';

		// Queries SB_User_Unmask__c records
		for (Sandbox_User_Unmask__c objSetting : [SELECT SetupOwnerId, Apply_only_to_dev_test__c, Apply_to_Integration__c FROM Sandbox_User_Unmask__c WHERE Unmask_Email__c = TRUE]) {
			if (
				(String.isNotBlank(strDevOrgName) && strSandboxName != strDevOrgName && String.isNotBlank(strUATOrgName) && strSandboxName != strUATOrgName && objSetting.Apply_only_to_dev_test__c) &&
				(String.isNotBlank(strIntgnOrgName) &&
				strSandboxName != strIntgnOrgName &&
				objSetting.Apply_to_Integration__c)
			) {
				continue;
			} else {
				if (objSetting.SetupOwnerId.getSObjectType() == User.SObjectType) {
					set_UserIDs.add(objSetting.SetupOwnerId);
				} else if (objSetting.SetupOwnerId.getSObjectType() == Profile.SObjectType) {
					set_ProfileIDs.add(objSetting.SetupOwnerId);
				}
			}
		}
		Boolean blnHasUserId = !set_UserIDs.isEmpty();
		Boolean blnHasProfileId = !set_ProfileIDs.isEmpty();
		if (blnHasUserId && blnHasProfileId) {
			strSOQLQuery = 'SELECT Id, Email FROM User WHERE ( Id IN :set_UserIDs OR ProfileId IN :set_ProfileIDs ) AND IsActive = True';
		} else if (blnHasUserId) {
			strSOQLQuery = 'SELECT Id, Email FROM User WHERE Id IN :set_UserIDs AND IsActive = True';
		} else if (blnHasProfileId) {
			strSOQLQuery = 'SELECT Id, Email FROM User WHERE ProfileId IN :set_ProfileIDs AND IsActive = True';
		}
		if (strSOQLQuery.length() > 0) {
			//Derive user's email via Regex
			//String regex = '\\@.*$';
			for (User u : Database.query(strSOQLQuery)) {
				if (!map_UserToEmail.containsKey(u.Id)) {
					map_UserToEmail.put(
						u.Id,
						//Remove text following @ and after, then replace = with @
						//u.Email.replaceAll(regex, '').replace('=','@')

						//Salesforce currently uses .invalid to mask emails
						u.Email.removeEnd('.invalid')
					);
				}
			}
			if (!map_UserToEmail.isEmpty()) {
				List<User> usersToUpdate = new List<User>();
				//Generate user update list
				for (Id i : map_UserToEmail.keySet()) {
					usersToUpdate.add(new User(Id = i, Email = map_UserToEmail.get(i)));
				}
				Boolean blnUserSkipTrigger = UserTriggerHelper.skipTrigger;
				UserTriggerHelper.skipTrigger = true;
				update usersToUpdate;
				UserTriggerHelper.skipTrigger = blnUserSkipTrigger;
			}
		}
	}

	/**
	 * @description  This method will mask all email fields in an org (except User object)
	 */
	public static void maskEmails() {
		Map<String, List<String>> map_SOEmailFieldMap = new Map<String, List<String>>();
		if (String.isNotBlank(objSandboxRefreshSettings.MaskField__c)) {
			set_FieldsToMask.addAll(objSandboxRefreshSettings.MaskField__c.split(';'));
		}
		//Get all Objects
		for (SObjectType soType : Schema.getGlobalDescribe().values()) {
			DescribeSObjectResult soDescribe = soType.getDescribe();
			//Only look for Objects that are querable and updatable
			if (soDescribe.isQueryable() && soDescribe.isUpdateable()) {
				String strObjectTypeName = soDescribe.getName();
				if (strObjectTypeName != 'User') {
					//Describe Field
					for (SObjectField soField : soDescribe.fields.getMap().values()) {
						DescribeFieldResult field = soField.getDescribe();
						if ((field.getType() == Schema.DisplayType.EMAIL || set_FieldsToMask?.contains(field.getName())) && field.isFilterable() && field.isUpdateable()) {
							if (!map_SOEmailFieldMap.containsKey(strObjectTypeName)) {
								map_SOEmailFieldMap.put(strObjectTypeName, new List<String>{ field.getName() });
							} else {
								map_SOEmailFieldMap.get(strObjectTypeName).add(field.getName());
							}
						}
					}
				}
			}
		}
		//Create batch for every object that fits in the criteria above
		for (String obj : map_SOEmailFieldMap.keySet()) {
			SandboxEmailMaskBatch sandEmailBatch = new SandboxEmailMaskBatch(createSOQL(obj, map_SOEmailFieldMap.get(obj)), map_SOEmailFieldMap.get(obj));
			Database.executeBatch(sandEmailBatch);
		}
	}

	public static void maskEmails(Set<String> set_ObjectNames) {
		Map<String, List<String>> map_SOEmailFieldMap = new Map<String, List<String>>();
		if (String.isNotBlank(objSandboxRefreshSettings.MaskField__c)) {
			set_FieldsToMask.addAll(objSandboxRefreshSettings.MaskField__c.split(';'));
		}
		//Set<String> set_ObjectsToMask = new Set<String>{'Contact', 'Lead', 'Account', 'Opportunity'};
		//Set<String> set_ObjectsToMask = new Set<String>{'Contact'};

		//Get all Objects
		for (SObjectType soType : Schema.getGlobalDescribe().values()) {
			DescribeSObjectResult soDescribe = soType.getDescribe();
			//Only look for Objects that are querable and updatable
			if (soDescribe.isQueryable() && soDescribe.isUpdateable()) {
				String strObjectTypeName = soDescribe.getName();
				if (strObjectTypeName != 'User' && set_ObjectNames.contains(strObjectTypeName)) {
					//Describe Field
					for (SObjectField soField : soDescribe.fields.getMap().values()) {
						DescribeFieldResult field = soField.getDescribe();
						if ((field.getType() == Schema.DisplayType.EMAIL || set_FieldsToMask?.contains(field.getName())) && field.isFilterable() && field.isUpdateable()) {
							if (!map_SOEmailFieldMap.containsKey(strObjectTypeName)) {
								map_SOEmailFieldMap.put(strObjectTypeName, new List<String>{ field.getName() });
							} else {
								map_SOEmailFieldMap.get(strObjectTypeName).add(field.getName());
							}
						}
					}
				}
			}
		}
		//Create batch for every object that fits in the criteria above
		for (String obj : map_SOEmailFieldMap.keySet()) {
			SandboxEmailMaskBatch sandEmailBatch = new SandboxEmailMaskBatch(createSOQL(obj, map_SOEmailFieldMap.get(obj)), map_SOEmailFieldMap.get(obj));
			Database.executeBatch(sandEmailBatch);
		}
	}

	/**
	 * @description  Helper method that generates SOQL for maskEmails() method. SOQL string is passed into batch
	 */
	public static String createSOQL(String strObjName, List<String> list_Fields) {
		List<String> list_Conditions = new List<String>();

		for (String strField : list_Fields) {
			list_Conditions.add(strField + ' != NULL');
		}

		//Exclude Lead's that are converted. Cannot update these leads.
		if (strObjName == 'Lead') {
			list_Conditions.add('isConverted = FALSE');
		}
		return 'SELECT Id,' + String.join(list_Fields, ',') + ' FROM ' + strObjName + ' WHERE ' + String.join(list_Conditions, ' OR ');
	}

	/**
	 * @description  This method will create user records for all the users mentioned (Create_User__c=true) in Sandbox_User_Record__mdt metadata type.
	 */
	public static void createUserRecords(String strSandboxName) {
		Map<String, String> map_usersToCreate = new Map<String, String>();
		List<User> list_UsersToInsert = new List<User>();

		// Queries SB_User_Unmask__c records
		for (Sandbox_User_Record__mdt objUserRecord : [SELECT DeveloperName, User_Email__c FROM Sandbox_User_Record__mdt WHERE Create_User__c = TRUE AND User_Email__c != NULL]) {
			if (String.isNotBlank(objUserRecord.User_Email__c) && !map_usersToCreate.containsKey(objUserRecord.DeveloperName)) {
				map_usersToCreate.put(objUserRecord.DeveloperName, objUserRecord.User_Email__c);
			}
		}
		if (map_usersToCreate != null && map_usersToCreate.size() > 0)
			list_UsersToInsert = createUsers('ZP System Administrator', strSandboxName, map_usersToCreate);

		if (list_UsersToInsert != null && list_UsersToInsert.size() > 0) {
			Boolean blnUserSkipTrigger = UserTriggerHelper.skipTrigger;
			UserTriggerHelper.skipTrigger = true;
			database.insert(list_UsersToInsert, false);
			UserTriggerHelper.skipTrigger = blnUserSkipTrigger;
		}
	}

	public static List<User> createUsers(String profileName, String strSandboxName, Map<String, String> map_userRecords) {
		// Generating a Unique Name
		String orgId = UserInfo.getOrganizationId();
		String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
		Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
		String uniqueName = orgId + dateString + randomInt;

		// Querying for the Profile record matching the input profile name.
		Profile objProfile = [SELECT ID FROM Profile WHERE Name = :profileName];
		UserRole objUserRole = [SELECT ID FROM UserRole WHERE Name = 'admin'];
		List<User> list_Users = new List<User>();

		for (String strUser : map_userRecords.keySet()) {
			String strFirstName = strUser.split('_')[0];
			String strLastName = strUser.split('_')[1];
			String strUserName = strFirstName + '.' + strLastName + '@gusto.com' + '.' + strSandboxName;
			User objUser = new User(
				firstname = strFirstName,
				lastname = strLastName,
				email = map_userRecords.get(strUser),
				username = strUserName.toLowerCase(),
				alias = uniqueName.substring(18, 23),
				TimeZoneSidkey = 'GMT',
				LocaleSidKey = 'en_US',
				emailencodingKey = 'UTF-8',
				languagelocalekey = 'en_US',
				ProfileId = objProfile.Id,
				UserRoleId = objUserRole.Id
			);
			list_Users.add(objUser);
		}
		return list_Users;
	}

	/**
	 * @description This method creates an Entitlment Account and entitlement record for case creation post refresh.
	 * @author      Todd Dowdy
	 * @param       n/a
	 * @return      n/a
	 **/
	@future
	public static void createEntitlementRecords() {
		List<Entitlement> list_Entitlements = new List<Entitlement>();
		Account objEntitlementAcc = new Account(Name = objSandboxRefreshSettings.Entitlement_Account_Name__c, RecordTypeId = AccountUtil.COMPANY_ACCOUNT_RT_ID);
		insert objEntitlementAcc;

		for (String strEntitlement : SandboxPostRefreshUtils.set_Entitlement_Names) {
			Entitlement objEntitlement = new Entitlement();

			objEntitlement.Name = strEntitlement;
			objEntitlement.AccountId = objEntitlementAcc.Id;
			objEntitlement.StartDate = Date.today();
			objEntitlement.EndDate = objEntitlement.StartDate.addYears(50);
			if (strEntitlement.contains('Engagement')) {
				objEntitlement.BusinessHoursId = objSandboxRefreshSettings.EngagementBusinessHourId__c;
				objEntitlement.SlaProcessId = objSandboxRefreshSettings.EngagementEntitlementProcessId__c;
			} else if (strEntitlement.contains('Compliance')) {
				objEntitlement.BusinessHoursId = objSandboxRefreshSettings.VitalsBusinessHourId__c;
				objEntitlement.SlaProcessId = objSandboxRefreshSettings.ComplianceEntitlementProcessId__c;
			} else if (strEntitlement.contains('Tax Ops')) {
				objEntitlement.BusinessHoursId = objSandboxRefreshSettings.VitalsBusinessHourId__c;
				objEntitlement.SlaProcessId = objSandboxRefreshSettings.TaxOpsEntitlementProcessId__c;
			} else if (strEntitlement.contains('Risk')) {
				objEntitlement.BusinessHoursId = objSandboxRefreshSettings.VitalsBusinessHourId__c;
				objEntitlement.SlaProcessId = objSandboxRefreshSettings.VitalsEntitlementProcessId__c;
			} else {
				objEntitlement.BusinessHoursId = objSandboxRefreshSettings.EngagementBusinessHourId__c;
				objEntitlement.SlaProcessId = objSandboxRefreshSettings.EngagementEntitlementProcessId__c;
			}
			list_Entitlements.add(objEntitlement);
		}
		insert list_Entitlements;
		updateEntitlementSettings(list_Entitlements);
	}

	/**
	 * @description This method updates custom setting entitlement IDs.
	 * @author      Todd Dowdy
	 * @param       List of entitlement record list_Entitlements
	 * @return      n/a
	 **/
	public static void updateEntitlementSettings(List<Entitlement> list_Entitlements) {
		for (Entitlement ent : list_Entitlements) {
			if (ent.Name.contains('Engagement')) {
				objConfigSettings.PayrollCareEntitlementId__c = ent.Id;
			} else if (ent.Name.contains('Compliance')) {
				objConfigSettings.PayrollComplianceEntitlementId__c = ent.Id;
			} else if (ent.Name.contains('Tax Ops')) {
				objConfigSettings.TaxOpsEntitlementId__c = ent.Id;
			} else if (ent.Name.contains('Risk')) {
				objConfigSettings.RiskEntitlementId__c = ent.Id;
			}
		}
		update objConfigSettings;
	}
    
    /**
	 * @description Update the profile of users who are in the profile "Biztech-BSA" and change it to "ZP System Administrator".
	 * @author      Yogesh Kherajani
	 * @param       n/a
	 * @return      n/a
	 **/
    public static void updateBiztechBSAUserToSysAdmin(){
        List<Profile> lst_ZPSystemAdministratorProfile = [SELECT Id FROM Profile WHERE Name = :ZP_SYSTEM_ADMINISTRATOR];
        
        if(lst_ZPSystemAdministratorProfile.isEmpty()){
            return;
        }
        
        List<User> lst_BiztechBSAUser = [SELECT Id FROM User WHERE Profile.Name = :BIZTECH_BSA];
        
        for(User objBiztechBSAUser : lst_BiztechBSAUser){
            objBiztechBSAUser.ProfileId = lst_ZPSystemAdministratorProfile[0].Id;
        }
        
        if(!lst_BiztechBSAUser.isEmpty()){
        	UPDATE lst_BiztechBSAUser;    
        }
    }
}