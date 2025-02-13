@RestResource(urlMapping='/MFAutomationService/Carrier/*')
global with sharing class HIBotGetEnrollmentService {
	@HttpGet
	global static HIFulfillmentBotResponseJSON doGet() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;
		String carrierId = req.requestURI.substring(req.requestURI.lastIndexOf('/') + 1);
		String carrierType = Label.MFAutomationCarrierIds;
		List<Case> caseList = new List<Case>();
		integer carrierIdPos = carrierId.indexOf('?');
		if (carrierIdPos > -1) {
			carrierId = carrierId.left(carrierIdPos);
		}
        
		map<String, set<string>> carrierIdTypeMap = new Map<String, set<string>>();
		List<String> carrerIdList = carrierType.split('~');
		set<String> companyIdSet = new Set<String>();
		set<String> employeeIdSet = new Set<String>();
		for (String carrierIdType : carrerIdList) {
			set<string> carrierTypeSet = new Set<string>();
			String carId = carrierIdType.split(':')[0];
			String carType = carrierIdType.split(':')[1];
			if (carrierIdTypeMap.containsKey(carId)) {
				carrierTypeSet = carrierIdTypeMap.get(carId);
			}
			carrierTypeSet.add(carType);
			carrierIdTypeMap.put(carId, carrierTypeSet);
		}

		if (req.params.get('caseId') != null) {
			return getCaseDetail(req.params.get('caseId'));
		}
        
		if (carrierIdTypeMap.containsKey(carrierId)) {
			set<string> carrierTypeSet = carrierIdTypeMap.get(carrierId);
			set<string> stateSet = new Set<string>();
			if (req.params.get('type') != null) {
				carrierTypeSet = new Set<string>();
				carrierTypeSet.add(req.params.get('type'));
			} else {
				carrierTypeSet = new Set<string>();
				carrierTypeSet.add('NHE');
			}
			if (req.params.get('state') != null) {
				String stateStr = req.params.get('state');
				for (String st : stateStr.split(';')) {
					stateSet.add(st);
				}
			}

			if (Test.isRunningTest()) {
				caseList = [
					SELECT
						Id,
						Type,
						Company_ID__c,
						createddate,
						ZP_Company_Id__c,
						Contact_Employee_Id__c,
						Employee_Ids__c,
						Carrier__r.Carrier_id__c,
						Automation_Status__c,
						Status,
						Anticipated_Effective_Date__c,
						Fulfillment_Event_Encrypted_JSON__c,
						Integration_id__c
					FROM Case
					WHERE
						Automation_Status__c NOT IN ('Failed', 'Completed')
						AND Carrier__r.Carrier_id__c = :carrierId
						AND Status NOT IN ('Solved', 'Closed', 'Resolved', 'Cancelled')
						AND Type IN :carrierTypeSet
						AND Closed_Reason__c != 'Termination Cancelled'
					ORDER BY Anticipated_Effective_Date__c ASC
					LIMIT 10
				];
			} else {
				if (stateSet.size() > 0) {
					caseList = [
						SELECT Id, Fulfillment_Event_Encrypted_JSON__c, Type, Company_ID__c, createddate, Contact_Employee_Id__c, Employee_Ids__c, Integration_id__c
						FROM Case
						WHERE
							Automation_Status__c NOT IN ('Failed', 'Completed')
							AND Group_Member_Update_Type__c EXCLUDES ('SSN Update', 'Bank Account Update', 'Two Percent Shareholder Update', 'FLSA Status Update', 'Hire Date Update')
							AND Carrier__r.Carrier_id__c = :carrierId
							AND Type IN :carrierTypeSet
							AND Status NOT IN ('Solved', 'Closed', 'Resolved', 'Cancelled')
							AND Integration_Id__c != NULL
							AND (owner.name = 'Member Fulfillment'
							OR owner.name = 'MF Automation')
							AND MF_Automation_Date__c != NULL
							AND Carrier__r.State__c IN :stateSet
							AND Closed_Reason__c != 'Termination Cancelled'
						ORDER BY MF_Automation_Date__c ASC
						LIMIT 10
					];
				} else {
					caseList = [
						SELECT Id, Fulfillment_Event_Encrypted_JSON__c, Type, Company_ID__c, createddate, Contact_Employee_Id__c, Employee_Ids__c, Integration_id__c
						FROM Case
						WHERE
							Automation_Status__c NOT IN ('Failed', 'Completed')
							AND Group_Member_Update_Type__c EXCLUDES ('SSN Update', 'Bank Account Update', 'Two Percent Shareholder Update', 'FLSA Status Update', 'Hire Date Update')
							AND Carrier__r.Carrier_id__c = :carrierId
							AND Type IN :carrierTypeSet
							AND Status NOT IN ('Solved', 'Closed', 'Resolved', 'Cancelled')
							AND Integration_Id__c != NULL
							AND (owner.name = 'Member Fulfillment'
							OR owner.name = 'MF Automation')
							AND MF_Automation_Date__c != NULL
							AND Closed_Reason__c != 'Termination Cancelled'
						ORDER BY MF_Automation_Date__c ASC
						LIMIT 10
					];
				}
			}

			if (caseList.size() > 0) {
				for (case c : caseList) {
					if (c.Type == 'Termination' || c.Type == 'Member Updates') {
						if (c.Company_ID__c != null) {
							companyIdSet.add(c.Company_ID__c);
						}
						if (c.Employee_Ids__c != null) {
							employeeIdSet.add(c.Employee_Ids__c);
						}
						if (c.Contact_Employee_Id__c != null) {
							employeeIdSet.add(c.Contact_Employee_Id__c);
						}
					}
				}
				map<String, ZP_user_role__c> userRoleMap = new Map<String, ZP_user_role__c>();
				if (companyIdSet.size() > 0) {
					userRoleMap = getUserRoleMap(companyIdSet, employeeIdSet);
				}
                
				map<String, HI_Fulfillment_Employee_Info__c> employeeInfoMap = new Map<String, HI_Fulfillment_Employee_Info__c>();
				if (employeeIdSet.size() > 0) {
					employeeInfoMap = getEmployeeInfoMap(employeeIdSet);
				}
				Map<String, HI_Fulfillment_Event__c> hiFulfillmentMap = getFulfillmentEventMap(caseList);
				for (Case c : caseList) {
					if (c.Type == 'Termination' && c.Company_ID__c != null && c.Employee_Ids__c != null) {
						Hi_fulfillment_event__c fulfillmentEvent = new HI_Fulfillment_Event__c();
						fulfillmentEvent.Event_Sub_Type__c = '';
						if (string.isNotEmpty(c.Integration_Id__c) && hiFulfillmentMap.containsKey(c.Integration_Id__c)) {
							fulfillmentEvent = hiFulfillmentMap.get(c.Integration_Id__c);
						}
					}
                    
					HIFulfillmentBotResponseJSON responseJSON = getResponseFromCase(c);
                    
					if (c.Type == 'Member Updates') {
						if (!employeeInfoMap.containsKey(c.Employee_Ids__c)) {
							continue;
						}
						responseJSON.member_updates = null;
						responseJSON.member_updates = getMemberUpdateInfo(employeeInfoMap.get(c.Employee_Ids__c));
					}
					return responseJSON;
				}
			}
		}
		return null;
	}

	private static List<HIFulfillmentBotResponseJSON.member_update> getMemberUpdateInfo(HI_Fulfillment_Employee_Info__c employeeInfo) {
		List<HIFulfillmentBotResponseJSON.member_update> updateList = new List<HIFulfillmentBotResponseJSON.member_update>();

		if (string.isNotBlank(employeeInfo.Home_Street_1__c)) {
			HIFulfillmentBotResponseJSON.member_update addressUpdate = new HIFulfillmentBotResponseJSON.member_update();
			addressUpdate.type = 'home_address';
			HIFulfillmentBotResponseJSON.work_address addressInfo = new HIFulfillmentBotResponseJSON.work_address();
			addressInfo.street_1 = employeeInfo.Home_Street_1__c;
			addressInfo.street_2 = '';
			addressInfo.city = '';
			addressInfo.state = '';
			addressInfo.country = '';
			addressInfo.county_name = '';
			addressInfo.zip = '';
			if (string.isNotBlank(employeeInfo.Home_Street_2__c))
				addressInfo.street_2 = employeeInfo.Home_Street_2__c;

			if (string.isNotBlank(employeeInfo.Home_City__c))
				addressInfo.city = employeeInfo.Home_City__c;

			if (string.isNotBlank(employeeInfo.Home_State__c))
				addressInfo.state = employeeInfo.Home_State__c;

			if (string.isNotBlank(employeeInfo.Home_Country__c))
				addressInfo.country = employeeInfo.Home_Country__c;

			if (string.isNotBlank(employeeInfo.Home_County__c))
				addressInfo.county_name = employeeInfo.Home_County__c;

			if (string.isNotBlank(employeeInfo.Home_Zip__c))
				addressInfo.zip = employeeInfo.Home_Zip__c;

			HIFulfillmentBotResponseJSON.member_update_info memberUpdInfo = new HIFulfillmentBotResponseJSON.member_update_info();
			memberUpdInfo.home_address = addressInfo;
			addressUpdate.member_update_info = memberUpdInfo;

			updateList.add(addressUpdate);
		}
		if (string.isNotBlank(employeeInfo.First_Name__c)) {
			HIFulfillmentBotResponseJSON.member_update addressUpdate = new HIFulfillmentBotResponseJSON.member_update();
			addressUpdate.type = 'first_name';

			HIFulfillmentBotResponseJSON.member_update_info memberUpdInfo = new HIFulfillmentBotResponseJSON.member_update_info();
			memberUpdInfo.first_name = employeeInfo.First_Name__c;
			addressUpdate.member_update_info = memberUpdInfo;

			updateList.add(addressUpdate);
		}
		if (string.isNotBlank(employeeInfo.Last_Name__c)) {
			HIFulfillmentBotResponseJSON.member_update addressUpdate = new HIFulfillmentBotResponseJSON.member_update();
			addressUpdate.type = 'last_name';

			HIFulfillmentBotResponseJSON.member_update_info memberUpdInfo = new HIFulfillmentBotResponseJSON.member_update_info();
			memberUpdInfo.last_name = employeeInfo.Last_Name__c;
			addressUpdate.member_update_info = memberUpdInfo;

			updateList.add(addressUpdate);
		}
		if (employeeInfo.Birth_Date__c != null) {
			HIFulfillmentBotResponseJSON.member_update addressUpdate = new HIFulfillmentBotResponseJSON.member_update();
			addressUpdate.type = 'birthday';

			HIFulfillmentBotResponseJSON.member_update_info memberUpdInfo = new HIFulfillmentBotResponseJSON.member_update_info();
			memberUpdInfo.birthday = '' + employeeInfo.Birth_Date__c;
			addressUpdate.member_update_info = memberUpdInfo;

			updateList.add(addressUpdate);
		}

		return updateList;
	}

	private static map<String, HI_Fulfillment_Event__c> getFulfillmentEventMap(List<case> caseList) {
		Set<String> eventIdset = new Set<String>();
		map<String, HI_Fulfillment_Event__c> fulfillmentMap = new Map<String, HI_Fulfillment_Event__c>();
		for (Case c : caseList) {
			if (c.Integration_id__c != null && c.Integration_id__c != '')
				eventIdSet.add(c.Integration_Id__c);
		}
		if (eventIdset.size() > 0) {
			for (HI_Fulfillment_Event__c event : [SELECT Id, Id__c, Event_Type__c, Event_Sub_Type__c FROM HI_Fulfillment_Event__c WHERE Id__c IN :eventIdSet]) {
				fulfillmentMap.put(event.Id__c, event);
			}
		}
		return fulfillmentMap;
	}

	private static HIFulfillmentBotResponseJSON getCaseDetail(String caseId) {
		set<String> companyIdSet = new Set<String>();
		set<String> employeeIdSet = new Set<String>();
		List<Case> caseList = [
			SELECT Id, Fulfillment_Event_Encrypted_JSON__c, Type, Company_ID__c, Employee_Ids__c, Contact_Employee_Id__c, createddate
			FROM Case
			WHERE id = :caseId AND Closed_Reason__c != 'Termination Cancelled'
			LIMIT 1
		];
		Case c = caseList[0];

		if (c.Company_ID__c != null) {
			companyIdSet.add(c.Company_ID__c);
		}
		if (c.Employee_Ids__c != null) {
			employeeIdSet.add(c.Employee_Ids__c);
		}
		if (c.Contact_Employee_Id__c != null) {
			employeeIdSet.add(c.Contact_Employee_Id__c);
		}
        
		map<String, HI_Fulfillment_Employee_Info__c> employeeInfoMap = new Map<String, HI_Fulfillment_Employee_Info__c>();
		if (employeeIdSet.size() > 0) {
			employeeInfoMap = getEmployeeInfoMap(employeeIdSet);
		}

		map<String, ZP_user_role__c> userRoleMap = new Map<String, ZP_user_role__c>();
		if (companyIdSet.size() > 0) {
			userRoleMap = getUserRoleMap(companyIdSet, employeeIdSet);
		}

		HIFulfillmentBotResponseJSON responseJSON = getResponseFromCase(c);
        
		if (c.Type == 'Member Updates') {
			if (!employeeInfoMap.containsKey(c.Employee_Ids__c)) {
				return null;
			}
			responseJSON.member_updates = null;
			responseJSON.member_updates = getMemberUpdateInfo(employeeInfoMap.get(c.Employee_Ids__c));
		}

		return responseJSON;
	}

	private static map<String, ZP_user_role__c> getUserRoleMap(Set<String> companyIdSet, Set<String> employeeIdSet) {
		map<String, ZP_user_role__c> userRoleMap = new Map<String, ZP_user_role__c>();
		for (ZP_User_Role__c role : [
			SELECT Id, Company_Id__c, Employee_Id__c, Is_UX_Active__c
			FROM ZP_User_Role__c
			WHERE deleted_at__c = NULL AND Is_UX_Active__c = TRUE AND Company_Id__c IN :companyIdSet AND Employee_Id__c IN :employeeIdSet
		]) {
			userRoleMap.put(role.Company_Id__c + '-' + role.Employee_Id__c, role);
		}
		return userRoleMap;
	}

	private static map<String, HI_Fulfillment_Employee_Info__c> getEmployeeInfoMap(Set<String> employeeIdSet) {
		map<String, HI_Fulfillment_Employee_Info__c> employeeMap = new Map<String, HI_Fulfillment_Employee_Info__c>();
		for (HI_Fulfillment_Employee_Info__c employee : [
			SELECT
				id,
				Employee_Id__c,
				Birth_Date__c,
				Hire_Date__c,
				Home_City__c,
				Home_Country__c,
				Home_County__c,
				Home_State__c,
				Home_Street_1__c,
				Home_Street_2__c,
				Home_Zip__c,
				Last_Name__c,
				First_Name__c
			FROM HI_Fulfillment_Employee_Info__c
			WHERE Employee_Id__c IN :employeeIdSet
		]) {
			employeeMap.put(employee.employee_id__c, employee);
		}

		return employeeMap;
	}

	private static HIFulfillmentBotResponseJSON getResponseFromCase(Case c) {
		Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
		Blob decryptedBlob = EncodingUtil.base64Decode(c.Fulfillment_Event_Encrypted_JSON__c);
		String deCryptedText = EncryptionUtils.getDecryptedText(encryptionKey, decryptedBlob);
		HIFulfillmentBotResponseJSON enrollmentResponse = (HIFulfillmentBotResponseJSON) System.JSON.deserialize(deCryptedText, HIFulfillmentBotResponseJSON.class);
		if (enrollmentResponse.control_info == null) {
			enrollmentResponse.control_info = new HIFulfillmentBotResponseJSON.control_info();
		}
		enrollmentResponse.control_info.case_id = c.Id;
		Date createdDate = date.newinstance(c.createddate.year(), c.createddate.month(), c.createddate.day());
		enrollmentResponse.control_info.created_date = createdDate;
		if (enrollmentResponse.employee.annual_salary == null || enrollmentResponse.employee.annual_salary == '') {
			enrollmentResponse.employee.annual_salary = '';
		}
        
		return enrollmentResponse;
	}
}