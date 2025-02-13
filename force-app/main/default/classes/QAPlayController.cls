/*
 * @name         : QAPlayController
 * @author       : Alex Xiong
 * @date         : 11-17-2020
 * @description  : Controller for qaPlayCmp LWC
 * @test classes : QAPlayControllerTest
 */
public class QAPlayController {
	/*
	 * @Author      : Alex Xiong
	 * @Description : Get a list of users. If blnDirectReports is true, get only users where current user is the manager
	 * @Param:      : blnDirectReports: True if you want to include direct report users.
	 * @Return:     : List of Users
	 */
	@AuraEnabled
	public static List<User> queryUsers(Boolean blnDirectReports) {
		try {
			List<User> list_User = new List<User>();
			String strQuery = 'SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true';
			if (blnDirectReports) {
				strQuery += ' AND ManagerId = \'' + UserInfo.getUserId() + '\'';
			}
			strQuery += ' ORDER BY Name ASC NULLS LAST';

			for (User objUser : (List<User>) Database.query(strQuery))
				list_User.add(objUser);

			return list_User;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
	 * @Author        : Alex Xiong
	 * @Description   : Returns cases based on filters provided
	 * @Param         : strOwnerId: An owner id
	 *                  dtFrom: Find Cases closed from this date
	 *                  dtTo: Find Cases closed to this date
	 *                  strClass: The class to filter on
	 *                  strRecordType: The record type to filter on
	 *                  strCaseReason: Case Reason to filter on
	 *                  strOrigin: Case origin to filter on
	 *                  strCSAT: The CSAT score to filter on.
	 *                  strEscalated: If "All Cases," gets all cases. If "Escalated Cases", gets Cases that created Escalation Cases
	 * @Return        : A list of Cases.
	 */
	@AuraEnabled
	public static List<Case> queryCases(String strOwnerId, Date dtFrom, Date dtTo, String strClass, String strRecordType, String strCaseReason, String strOrigin, String strCSAT, String strEscalated) {
		try {
			Boolean blnEscalated = strEscalated == 'Escalated Cases' ? true : false;
			String strQuery = 'SELECT ';

			strQuery += processQueryPart('Id FROM Case', blnEscalated, false);
			strQuery += ' WHERE ';

			if (blnEscalated) {
				strQuery += 'Origin = \'Escalation\' AND ';
			}

			/**
			 * get Closed and Solved Cases that have Solved_Closed_Date_Time__c
			 * to prevent getting open Cases with Solved_Closed_Date_Time__c
			 */
			strQuery += '(';
			strQuery += processQueryPart('Status = \'Solved\'', blnEscalated, true);
			strQuery += ' OR ';
			strQuery += processQueryPart('Status = \'Closed\'', blnEscalated, true);
			strQuery += ') AND ';
			strQuery += processQueryPart('Solved_Closed_Date_Time__c >= :dtFrom', blnEscalated, true);
			strQuery += ' AND ';
			strQuery += processQueryPart('Solved_Closed_Date_Time__c <= :dtTo', blnEscalated, true);

			// If 'Any' is selected, don't filter on it
			if (String.isNotBlank(strClass) && strClass != 'Any') {
				strQuery += ' AND ';
				strQuery += processQueryPart('Class__c = \'' + strClass + '\'', blnEscalated, true);
			}

			// Get record type + read only record type because Solved Cases aren't read only
			if (String.isNotBlank(strRecordType) && strRecordType != 'Any') {
				String strReadOnlyRecordType = strRecordType + ' - Read Only';
				strQuery += ' AND (';
				strQuery += processQueryPart('RecordType.Name = \'' + strRecordType + '\'', blnEscalated, true);
				strQuery += ' OR ';
				strQuery += processQueryPart('RecordType.Name = \'' + strReadOnlyRecordType + '\'', blnEscalated, true);
				strQuery += ')';
			}

			// If 'Email', get cases where Origin is not 'Phone' and not 'Chat'
			// if origin = Chat, also include Gusto b/c it's in-app
			if (String.isNotBlank(strClass) && strOrigin != 'Any') {
				if (strOrigin == 'Email') {
					strQuery += ' AND ';
					strQuery += processQueryPart('Origin != \'Phone\'', blnEscalated, true);
					strQuery += ' AND ';
					strQuery += processQueryPart('Origin != \'Chat\'', blnEscalated, true);
				} else if (String.isNotBlank(strClass) && (strOrigin == 'Phone' || strOrigin == 'Chat')) {
					strQuery += ' AND ';

					if (strOrigin == 'Chat') {
						strQuery += '(';
						strQuery += processQueryPart('Origin = \'Gusto\'', blnEscalated, true);
						strQuery += ' OR ';
					}

					strQuery += processQueryPart('Origin = \'' + strOrigin + '\'', blnEscalated, true);

					if (strOrigin == 'Chat') {
						strQuery += ')';
					}
				}
			}

			if (String.isNotBlank(strCaseReason)) {
				strQuery += ' AND ';
				strQuery += processQueryPart('Confirm_Case_Reason__c = \'' + strCaseReason + '\'', blnEscalated, true);
			}

			if (String.isNotBlank(strCSAT) && strCSAT != 'Any') {
				strQuery += ' AND ';
				strQuery += processQueryPart('Id IN (SELECT Case__c FROM Case_Survey_Response__c WHERE CSAT_Good_Bad__c = ', blnEscalated, false);
				if (strCSAT == 'Good')
					strQuery += String.valueOf(1);
				else
					strQuery += String.valueOf(0);

				strQuery += ')';
			}

			if (String.isNotBlank(strOwnerId)) {
				strQuery += ' AND ';
				strQuery += processQueryPart('OwnerId = \'' + strOwnerId + '\'', blnEscalated, true);
			}

			return (List<Case>) Database.query(strQuery);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	/*
	 * @Author:         Alex Xiong
	 * @Description:    helper method for writing SOQL for a case or case's parent
	 * @Param:          strQueryPart: part of SOQL string
	 *                  blnEscalated: true if query is asking for cases that created escalated cases
	 *                  blnDot: prepend Parent or Parent.
	 * @Return:         SOQL string part.
	 */
	public static String processQueryPart(String strQueryPart, Boolean blnEscalated, Boolean blnDot) {
		String strEscalatedQueryPart = strQueryPart;

		if (blnEscalated) {
			if (blnDot) {
				strEscalatedQueryPart = 'Parent.' + strEscalatedQueryPart;
			} else {
				strEscalatedQueryPart = 'Parent' + strEscalatedQueryPart;
			}
		}

		return strEscalatedQueryPart;
	}

	/*
	 * @Author       : Alex Xiong
	 * @Description  : Get Case Reason Classifications
	 * @Param:       : N/A
	 * @Return:      : Map of Case Reasons to associated Map of Id to Case Reason Classification
	 */
	@AuraEnabled
	public static Map<String, Map<Id, String>> queryReasons() {
		Map<String, Map<Id, String>> map_caseReasonToGroupMap = new Map<String, Map<Id, String>>();
		List<Case_Reason_Classification__c> list_caseReasonClassifications = new List<Case_Reason_Classification__c>();
		Map<String, Map<Id, String>> map_caseReasonToGroupMapOrdered = new Map<String, Map<Id, String>>();

		try {
			list_caseReasonClassifications = [
				SELECT Id, Name, Class__c, Type__c
				FROM Case_Reason_Classification__c
				WHERE Active__c = TRUE AND Generic_Routing_Reason__c = FALSE AND Type__c != 'Generic Routing'
			];
			// Arrange in such a way that all generic routing cases appear first, followed by reasons related to case record type
			// Iterate over list of case reason classification
			// Create a map of type and list of case reason classsification
			for (Case_Reason_Classification__c objCrc : list_caseReasonClassifications) {
				if (map_caseReasonToGroupMap.containsKey(objCrc.Type__c)) {
					Map<Id, String> map_IdToCaseReasonClassification = map_caseReasonToGroupMap.get(objCrc.Type__c);
					map_IdToCaseReasonClassification.put(objCrc.Id, objCrc.Name);
					map_caseReasonToGroupMap.put(objCrc.Type__c, map_IdToCaseReasonClassification);
				} else {
					map_caseReasonToGroupMap.put(objCrc.Type__c, new Map<Id, String>{ objCrc.Id => objCrc.Name });
				}
			}

			return map_caseReasonToGroupMap;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}