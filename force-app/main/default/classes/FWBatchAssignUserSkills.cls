/**
	* @name         FWBatchAssignUserSkills
	* @author       Bhagat Singh
	* @date         04 Aug 2020
	* @description  This batch will execute. Once Qualification-Core or IA-Core skill will update.
	* @test class   FWManageRoleSkillsCtrlTest
	* @revisions    Date ------------ Name ------------ Comments
	**/
	public class FWBatchAssignUserSkills implements Database.Batchable<Sobject>, Database.Stateful {
		public String strRegionPODId; //Region POD Id.
		public String strRoleName; //Role Name. like Qualification/Submission.
		//Set of newly added state in POD.
		public Set<String> set_NewRegionPODStates = new Set<String>();
		//Set of deleted state from POD.
		public Set<String> set_DeletedRegionPODStates = new Set<String>();
		//Set of state related existing user skills.
		public Set<String> set_ExistingUserSkillStates = new Set<String>();
	
		//Fetch user role on the basis of region POD Id.
		public database.Querylocator Start(Database.BatchableContext objBatchable) {
			String strRegionKeyName = '';
			List<Region_POD__c> list_RegionPOD = [SELECT Key__c FROM Region_POD__c WHERE Id = :strRegionPODId];
	
			if(!list_RegionPOD.isEmpty()){
				strRegionKeyName = list_RegionPOD[0].Key__c;
			}
	
			String strQuery =
				'SELECT Id,'
				+ ' User_Skill_Type__c,'
				+ ' Selected_Regions_Id__c'
				+ ' FROM User_Role__c'
				+ ' WHERE (Selected_Region_Keys__c != null '
				+ 'AND Selected_Region_Keys__c LIKE \'%'
				+ strRegionKeyName
				+',%\' ) OR '
				+ '(Selected_Regions_Id__c != null '
				+ 'AND Selected_Regions_Id__c LIKE \'%'
				+ strRegionPODId
				+'%\' )';
	
			return Database.getQueryLocator(strQuery);
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Create new user skill, if states will added in POD.
		 * @Parm        : objBatchable - batachableContext
		 * 				  objScope - User Role Record
		 * @Return      : null
		 **/
		public void execute(Database.BatchableContext objBatchable, Sobject[] objScope) {
			set_ExistingUserSkillStates = new Set<String>();
	
			if (objScope != null && objScope.size() > 0) {
				//Note : Execute method should process one user role record at a time.
				User_Role__c objUserRole = (User_Role__c) objScope[0];
				Map<String, Set<String>> map_UserExistingSkills = RetriveUserSkillData(objUserRole.Id);
				Set<String> set_NewSelectedStates = new Set<String>();
	
				//Get existing set of State, Order Type, Partner, Tada related to "User Role".
				Set<String> set_ExistingStates = new Set<String>();
				Set<String> set_SelectedOrderTypes = new Set<String>();
				Set<String> set_SelectedPartners = new Set<String>();
				Set<String> set_SelectedCoverageTypes = new Set<String>();
				Boolean blnBenefitsBigDesk = false;
				String strSelectedTAdA = '';
	
				if (map_UserExistingSkills.containsKey('State_Group__c')) {
					set_ExistingStates = addSelectedValuesToSelectOption(
						map_UserExistingSkills.get('State_Group__c'),
						set_ExistingStates
					);
				}
	
				if (map_UserExistingSkills.containsKey('Order_Type__c')) {
					set_SelectedOrderTypes = addSelectedValuesToSelectOption(
						map_UserExistingSkills.get('Order_Type__c'),
						set_SelectedOrderTypes
					);
				}
	
				if (map_UserExistingSkills.containsKey('Partner__c')) {
					set_SelectedPartners = addSelectedValuesToSelectOption(
						map_UserExistingSkills.get('Partner__c'),
						set_SelectedPartners
					);
				}
	
				if (map_UserExistingSkills.containsKey('TADA__c')) {
					strSelectedTAdA = fetchTadaType(map_UserExistingSkills.get('TADA__c'), strSelectedTAdA, 'TAdA');
				}
	
				if (map_UserExistingSkills.containsKey('Coverage_Type__c')) {
					set_SelectedCoverageTypes = addSelectedValuesToSelectOption(
						map_UserExistingSkills.get('Coverage_Type__c'),
						set_SelectedCoverageTypes
					);
				}
	
				if (map_UserExistingSkills.containsKey('Benefits_Big_Desk__c')) {
					blnBenefitsBigDesk = fetchBigDeskType(
						map_UserExistingSkills.get('Benefits_Big_Desk__c'),
						blnBenefitsBigDesk
					);
				}
	
				//Check newly added state already available in User Role.
				for (String strState : set_NewRegionPODStates) {
					if (!set_ExistingStates.contains(strState)) {
						set_NewSelectedStates.add(strState);
					}
				}
	
				if (set_NewSelectedStates.size() > 0) {
					//Get the skill related to [State, Order Type, Partner]
					String strSkillQuery = getSkillQueryAsPerRoles(
						set_SelectedOrderTypes,
						set_SelectedPartners,
						strSelectedTAdA,
						set_NewSelectedStates,
						set_SelectedCoverageTypes,
						blnBenefitsBigDesk
					);
	
					List<Skill__c> list_SkillsRec = Database.Query(strSkillQuery);
	
					if (list_SkillsRec.size() > 0) {
						List<User_Skill__c> list_UserSkill = new List<User_Skill__c>();
	
						//Construct user skill records based on current transfer skill selection
						for (Skill__c objSkl : list_SkillsRec) {
							User_Skill__c objUR = new User_Skill__c();
							objUR.Skill__c = objSkl.Id;
							objUR.User_Role__c = objUserRole.Id;
							objUR.Skill_Role_Name__c = objSkl.Role__r.Name;
	
							if (objUserRole.User_Skill_Type__c == FWManageRoleUtil.SKILL_TYPE_CORE) {
								objUR.Active__c = true;
							}
	
							list_UserSkill.add(objUR);
						}
	
						if (!list_UserSkill.isEmpty()) {
							insert list_UserSkill;
						}
					}
				}
			}
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Delete user skill, if states will removed from POD.
		 * @Parm        : objBatchable - batachableContext
		 * @Return      : null
		 **/
		public void finish(Database.BatchableContext objBatchable) {
			if (set_DeletedRegionPODStates.size() > 0 && String.isNotBlank(strRegionPODId)) {
				FWManageRoleSkillsCtrl.deleteUserSkillRelatedToRegionPOD(
					strRegionPODId,
					set_DeletedRegionPODStates,
					false
				);
			}
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Set of string related to [State/ Order Type/ Partner/ Tada]
		 * @Parm        : set_SkillValues - Users selected Skills Value
		 * 				  set_SelectedOrderTypes - set of values
		 * @Return      : Set of string
		 **/
		public Set<String> addSelectedValuesToSelectOption(
			Set<String> set_SkillValues,
			Set<String> set_SelectedOrderTypes
		) {
			if (!set_SkillValues.isEmpty()) {
				for (String strValue : set_SkillValues) {
					set_SelectedOrderTypes.add(strValue);
				}
			}
	
			return set_SelectedOrderTypes;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get the type of tada type user have selected on UI.
		 * @Parm        : setString - Users selected TADA Values
		 * 				  strSelectedValue - String of UI Value
		 * 				  strRadioName - name of Radio Button
		 * @Return      : String which user have selected on UI During Mangae skill page
		 **/
		public String fetchTadaType(Set<String> setString, String strSelectedValue, String strRadioName) {
			if (setString.contains('true') && setString.contains('false')) {
				strSelectedValue = 'Both ' + strRadioName;
			} else if (setString.contains('true')) {
				strSelectedValue = 'Only ' + strRadioName;
			} else if (setString.contains('false')) {
				strSelectedValue = 'No ' + strRadioName;
			}
	
			return strSelectedValue;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get the BigDesk value of User
		 * @Parm        : setString - Users selected BigDesk Values
		 * 				  strSelectedValue - String of UI Value
		 * @Return      : String which user have selected on UI During Mangae skill page
		 **/
		public Boolean fetchBigDeskType(Set<String> setString, Boolean blnSelectedValue) {
			if (setString.contains('true')) {
				blnSelectedValue = true;
			} else if (setString.contains('false')) {
				blnSelectedValue = false;
			}
	
			return blnSelectedValue;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get the User skills of a User
		 * @Parm        : strUserRoleId - String of UserId
		 * @Return      : Map<String, Set<String>> - [FieldName, [Selected Skills value Set]]
		 * 				  ['Big_Desk__c', ['True','False']]
		 **/
		public Map<String, Set<String>> RetriveUserSkillData(String strUserRoleId) {
			Map<String, Set<String>> map_UserExistingSkills = new Map<String, Set<String>>();
	
			if (String.isNotBlank(strUserRoleId) && String.isNotBlank(strRoleName)) {
				for (User_Skill__c userSkill : [
					SELECT
						Skill__c,
						Skill__r.TADA__c,
						Skill__r.Order_Type__c,
						Skill__r.Partner__c,
						Skill__r.State_Group__c,
						Skill__r.Coverage_Type__c,
						Skill__r.Benefits_Big_Desk__c
					FROM User_Skill__c
					WHERE User_Role__c = :strUserRoleId AND Skill__r.Role__r.Name = :strRoleName AND Skill__c != null
				]) {
					if (userSkill.Skill__c != null && String.isNotBlank(userSkill.Skill__r.State_Group__c)) {
						set_ExistingUserSkillStates.add(userSkill.Skill__r.State_Group__c);
					}
	
					String str_StateGroup = userSkill.Skill__r.State_Group__c;
					addValueToMap('State_Group__c', str_StateGroup, map_UserExistingSkills);
	
					String str_OrderType = userSkill.Skill__r.Order_Type__c;
					addValueToMap('Order_Type__c', str_OrderType, map_UserExistingSkills);
	
					String str_Partner = userSkill.Skill__r.Partner__c;
					addValueToMap('Partner__c', str_Partner, map_UserExistingSkills);
	
					String strBooleanValue = userSkill.Skill__r.TADA__c ? 'true' : 'false';
					addValueToMap('TADA__c', strBooleanValue, map_UserExistingSkills);
	
					String strBigDeskValue = userSkill.Skill__r.Benefits_Big_Desk__c ? 'true' : 'false';
					addValueToMap('Benefits_Big_Desk__c', strBigDeskValue, map_UserExistingSkills);
	
					String strCoverageType = userSkill.Skill__r.Coverage_Type__c;
					addValueToMap('Coverage_Type__c', strCoverageType, map_UserExistingSkills);
				}
			}
	
			return map_UserExistingSkills;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Add the Field values in Map
		 * @Parm        : strFieldName - Name of field
		 * 				  strFieldValue - values of field
		 * 				  map_UserExistingSkills - map in which field name and values should be added
		 * @Return      : null
		 **/
		public void addValueToMap(
			String strFieldName,
			String strFieldValue,
			Map<String, Set<String>> map_UserExistingSkills
		) {
			if (strFieldValue != null) {
				Set<String> set_SkillRec = new Set<String>();
				if (
					!map_UserExistingSkills.isEmpty() &&
					map_UserExistingSkills.containsKey(strFieldName) &&
					!map_UserExistingSkills.get(strFieldName).isEmpty()
				) {
					set_SkillRec = map_UserExistingSkills.get(strFieldName);
				}
				set_SkillRec.add(strFieldValue);
				map_UserExistingSkills.put(strFieldName, set_SkillRec);
			}
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get where clause condition for different list option
		 * @Parm        : strFieldNameToCompare - Name of field
		 * 				  list_SeletionOption - Selected Values
		 * @Return      : String - Where cluase for Pick list values
		 **/
		public String getWhereClauseQuery(String strFieldNameToCompare, Set<String> list_SeletionOption) {
			String strWhereClause = '';
			for (String s : list_SeletionOption) {
				strWhereClause += '\'' + s + '\',';
			}
			strWhereClause = strWhereClause.removeEnd(',');
			return ' AND ' + strFieldNameToCompare + ' in (' + strWhereClause + ')';
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get where clause condition for TADA
		 * @Parm        : strFieldName - Name of field
		 * 				  strSelectedValue - values of field
		 * @Return      : String - Where clause for tada
		 **/
		public String getTAdAQuery(String strFieldName, String strSelectedValue) {
			String strWhereClause = '';
			if (strSelectedValue == 'Only TAdA') {
				strWhereClause = ' and ' + strFieldName + ' = true ';
			} else if (strSelectedValue == 'No TAdA') {
				strWhereClause = ' and ' + strFieldName + ' = false ';
			} else if (strSelectedValue == 'Both TAdA') {
				strWhereClause = ' and (' + strFieldName + ' = true or ' + strFieldName + ' =false)';
			}
			return strWhereClause;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get where clause condition for Big DESK
		 * @Parm        : strFieldName - Name of field
		 * 				  blnBenefitsBigDesk - values of field
		 * @Return      : String - Where clause for Big DESK
		 **/
		//for big desk only
		public String getBigDeskQuery(String strFieldName, Boolean blnBenefitsBigDesk) {
			String strWhereClause = '';
			if (blnBenefitsBigDesk) {
				strWhereClause = ' and ' + strFieldName + ' = true ';
			} else {
				strWhereClause = ' and ' + strFieldName + ' = false ';
			}
			return strWhereClause;
		}
	
		/**
		 * @Author      : Deepika Saini
		 * @Description : Get the Skills Query with all filters
		 * @Parm        : set_SelectedOrderTypes - Selected values of OrderType field
		 * 				  set_SelectedPartners -Selected values of Partner field
		 * 				  strSelectedTAdA - Selected values of TADA field
		 * 				  set_SelectedState - Selected values of State field
		 * 				  set_SelectedCoverageTypes - Selected values of Coverage Type field
		 * 				  blnBenefitsBigDesk - Boolean of Big desk field
		 * @Return      : String - Query
		 **/
		// This method add filter condition in soql query.
		public String getSkillQueryAsPerRoles(
			Set<String> set_SelectedOrderTypes,
			Set<String> set_SelectedPartners,
			String strSelectedTAdA,
			Set<String> set_SelectedState,
			Set<String> set_SelectedCoverageTypes,
			Boolean blnBenefitsBigDesk
		) {
			String strQueryToGetSkills = 'SELECT Id,Role__r.Name FROM Skill__c WHERE Role__c!=null ';
	
			if (!set_SelectedOrderTypes.isEmpty() && set_SelectedOrderTypes != null) {
				strQueryToGetSkills += getWhereClauseQuery('Order_Type__c', set_SelectedOrderTypes);
			}
	
			if (!set_SelectedState.isEmpty() && set_SelectedState != null) {
				strQueryToGetSkills += getWhereClauseQuery('State_Group__c', set_SelectedState);
			}
	
			if (!set_SelectedPartners.isEmpty() && set_SelectedPartners != null) {
				strQueryToGetSkills += getWhereClauseQuery('Partner__c', set_SelectedPartners);
			}
	
			if (String.isNotBlank(strSelectedTAdA)) {
				strQueryToGetSkills += getTAdAQuery('Tada__c', strSelectedTAdA);
			}
	
			strQueryToGetSkills += getBigDeskQuery('Benefits_Big_Desk__c', blnBenefitsBigDesk);
	
			if (!set_SelectedCoverageTypes.isEmpty() && set_SelectedCoverageTypes != null) {
				strQueryToGetSkills += getWhereClauseQuery('Coverage_Type__c', set_SelectedCoverageTypes);
			}
	
			if (String.isNotBlank(strRoleName)) {
				strQueryToGetSkills += ' AND Role__r.Name=:strRoleName ';
			}
	
			return strQueryToGetSkills;
		}
	}