/*************************************************************************************************************
 * @name			LWC_SubmitCallBackController
 * @author			Dhir Kumar
 * @created			17 / 09 / 2020
 * @description		This class covers the call back functioanlity.
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 * 				No.		Date			Author					Description
 * 				----	------------	--------------------	----------------------------------------------
 * @version		1.0		2020-09-17		Dhir Kumar			 Initial Development (Functional logic taken from the class CallBackController)
 *
 **************************************************************************************************************/
public class LWC_SubmitCallBackController {
	public static boolean blnIsSuccess; // captures the infomation to display the Call Back form or not
	public static string strPhone; // captures the infomation of the Phone Number
	public static string idCase; // holds the current case Id
	public static string idContact; // holds the Contact related to the case
	public static Boolean blnUserCallBack; // captures the check of call back to happen or not
	public static User objLoggedInUser;
	public static String strLoggedInUserName, strLoggedInUserSkillId;
	public static Case tempCase;
	public static Map<String, String> map_Queue;
	public static List<SelectOption> list_Queue;
	public static Case objCase; // to get the record of the current case
	public static string strName; // captures the case's contact name
	public static string strQueueId;
	public static string strDtm; //captures the string format of the Auto close date

	/*********************************************************************************************************
	 * @name			callBackLoad
	 * @author			Dhir
	 * @created			17 / 09 / 2020
	 * @description		It combines all the methods from which values are needed at the load of call back page
	 * @param			map<String, Object> map_Response : Response object to pass the values to the JS file of LWC.
	 * @return			map<String, Object>
	 **********************************************************************************************************/
	@AuraEnabled
	public static map<String, Object> callBackLoad(String idCase) {
		map<String, Object> map_Response = new Map<String, Object>();
		map_Response.put('firstMethod', firstMethod());
		map_Response.put('getQueueList', getQueueList());
		map_Response.put('setAttributes', setAttributes(idCase));
		try {
			return map_Response;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_SubmitCallBackController', 'callBackLoad', ex.getMessage(), ex.getStackTraceString());
		}
		return null;
	}

	/*********************************************************************************************************
	 * @name			getQueueList
	 * @author			Dhir kumar
	 * @created			17 / 09 / 2020
	 * @description		It gets the Phone queue users from the custom setting and prepares the map of same.
	 * @param			map<String, Object> map_Response : Response object to pass the values to the JS file of LWC.
	 * @return			map<String, Object>
	 **********************************************************************************************************/
	public static Map<String, Object> getQueueList() {
		map_Queue = new Map<String, String>();
		list_Queue = new List<SelectOption>();
		Map<String, Object> map_Response = new Map<String, Object>();
		try {
			List<Phone_Queue__c> list_SortedPhoneQueue = Phone_Queue__c.getall().values();
			list_Queue.add(new SelectOption('', '--Select--'));
			if (null != list_SortedPhoneQueue && list_SortedPhoneQueue.size() > 0) {
				list_SortedPhoneQueue.sort();
				for (Phone_Queue__c queue : list_SortedPhoneQueue) {
					list_Queue.add(new SelectOption(queue.Name, queue.Queue_Id__c));
					map_Queue.put(queue.Name, queue.Queue_Id__c);
				}
			}
			map_Response.put('queueMap', map_Queue);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_SubmitCallBackController', 'getQueueList', ex.getMessage(), ex.getStackTraceString());
			return null;
		}
		return map_Response;
	}

	/*********************************************************************************************************
	 * @name			firstMethod
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		It captures the logged in User informtation and sends to UI
	 * @param			map<String, Object> map_Response : Response object to pass the values to the JS file of LWC.
	 * @return			map<String, Object>
	 **********************************************************************************************************/
	public static Map<String, Object> firstMethod() {
		blnIsSuccess = false;
		strPhone = '';
		idCase = '';
		idContact = '';
		blnUserCallBack = true;
		map<String, Object> map_Response = new Map<String, Object>();
		try {
			strLoggedInUserName = userinfo.getFirstName() + ' ' + userinfo.getLastName();
			tempCase = new Case();
			//By ND, 4th December 2019, Autopouplate requested time
			tempCase.Auto_Close_Date_Time__c = system.now().addminutes(1);
			//get user details for logged in user
			objLoggedInUser = [
				SELECT Default_Callback_Queue__c, PureCloud_UserId__c
				FROM User
				WHERE Id = :userInfo.getUserId()
			];
			strLoggedInUserSkillId = objLoggedInUser.PureCloud_UserId__c;
			map_Response.put('strLoggedInUserName', strLoggedInUserName);
			map_Response.put('strLoggedInUserSkillId', strLoggedInUserSkillId);
			map_Response.put('bool_UserCallBack', blnUserCallBack);
			map_Response.put('tempCase', tempCase);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_SubmitCallBackController', 'firstMethod', ex.getMessage(), ex.getStackTraceString());
		}
		return map_Response;
	}

	/*********************************************************************************************************
	 * @name			setAttributes
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		It gets the current case record and checks whether call has already been scheduled or not
	 **********************************************************************************************************/
	public static Map<String, Object> setAttributes(String idCase) {
		map<String, Object> map_Response = new Map<String, Object>();
		String strQueueId = '';
		try {
			if (String.isNotBlank(idCase)) {
				List<Case> list_Case = new List<Case>(
					[
						SELECT
							id,
							CaseNumber,
							Auth__c,
							Latest_Successful_Callback_Timestamp__c,
							AuthPath__c,
							Genesys_Call_Id__c,
							Record_Type_Name__c,
							AccountId,
							Account.Name,
							Account.RecordType.Name,
							Account.Care_Account_Manager__c,
							Account.CX_Experiment__c,
							Account.Concierge_Group__c,
							SuppliedPhone,
							SuppliedName,
							ContactId,
							Contact.Name,
							Contact.Phone,
							Contact.MobilePhone,
							Contact.HomePhone,
							Origin,
							Channel__c
						FROM Case
						WHERE Id = :idCase
					]
				);
				if (list_Case.size() > 0) {
					objCase = list_Case[0];
					if (objCase.SuppliedPhone != null) {
						strPhone = objCase.SuppliedPhone;
					}
					if (objCase.ContactId != null) {
						//By ND, 4th December 2019, Auto populate contact name
						if (String.isBlank(strPhone) && objCase.contact.Phone != null) {
							strPhone = objCase.Contact.Phone;
						}
						strName = objCase.Contact.Name;
					}
					strQueueId = setQueueId(objCase.Account, objCase.Contact, objCase.Record_Type_Name__c);

					if (objCase.Latest_Successful_Callback_Timestamp__c != null) {
						map_Response.put('isSuccess', true);
						return map_Response;
					}
				}
			}
			strPhone = strPhone.replaceAll(' ', '');
			strPhone = strPhone.replaceAll('[()]', '');
			strPhone = strPhone.replaceAll('-', '');

			map_Response.put('Phone', strPhone);
			map_Response.put('queueId', strQueueId);
			map_Response.put('name', strName);
			map_Response.put('cs', objCase);
		} catch (Exception ex) {
			ExceptionLogUtil.logException('LWC_SubmitCallBackController', 'setAttributes', ex.getMessage(), ex.getStackTraceString());
		}
		return map_Response;
	}

	/*********************************************************************************************************
	 * @name			setAttributes
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		This methods sets the Queue according to the Account group
	 **********************************************************************************************************/
	public static string setQueueId(Account objAcc, Contact objCont, String strType) {
		if (objAcc != null && objAcc.Concierge_Group__c != null) {
			if (map_Queue.containsKey(objAcc.Concierge_Group__c)) {
				strQueueId = map_Queue.get(objAcc.Concierge_Group__c);
			} else {
				setQueueBasedOnUser();
			}
		} else {
			setQueueBasedOnUser();
		}

		return strQueueId;
	}
	/*
	 * By ND, 4th December 2019,
	 * Desc	:Auto populate queue based on Logged In User's default queue in case it is not assigned based on related Account
	 */
	public static void setQueueBasedOnUser() {
		if (null != objLoggedInUser && null != objLoggedInUser.Default_Callback_Queue__c && map_Queue.containsKey(objLoggedInUser.Default_Callback_Queue__c)) {
			strQueueId = map_Queue.get(objLoggedInUser.Default_Callback_Queue__c);
		}
	}

	/*********************************************************************************************************
	 * @name			setAttributes
	 * @author			Dhir Kumar
	 * @created			17 / 09 / 2020
	 * @description		This methods places the call back request
	 **********************************************************************************************************/
	@AuraEnabled
	public static Map<String, String> submitCallBack(
		String idQueue,
		String strPhone,
		String strName,
		String strLoggedInUserName,
		Case ObjtempCase,
		Case objCase,
		Boolean blnUserCallBack,
		String strLoggedInUserSkillId
	) {
		String strMsg = '';
		Map<String, String> map_Response = new Map<String, String>();
		strPhone = strPhone.replaceAll(' ', '');
		strPhone = strPhone.replaceAll('', '');
		strPhone = strPhone.replaceAll('', '');
		strPhone = strPhone.replaceAll('-', '');
		GenesysCallbackIntegration genesysIntegration = new GenesysCallbackIntegration();
		strDtm = '';
		if (objtempCase.Auto_Close_Date_Time__c != null) {
			objTempCase.Auto_Close_Date_Time__c = system.now().addminutes(1);
			DateTime tempDtm = objtempCase.Auto_Close_Date_Time__c;
			strDtm = tempDtm.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss') + '.000Z';
		}
		String response = (!Test.isRunningTest()
			? genesysIntegration.sumitCallBack(
					idQueue,
					strPhone,
					strName,
					strDtm,
					strLoggedInUserName,
					objCase.Id,
					blnUserCallBack,
					objCase.Auth__c,
					objCase.AuthPath__c,
					objCase.Genesys_Call_Id__c,
					strLoggedInUserSkillId,
					objCase.CaseNumber,
					objCase.Origin
			  )
			: 'Success');

		if (response.contains('Success')) {
			strMsg = 'Callback successfully scheduled';
			map_Response.put('msg', strMsg);
			Case_Audit_log__c objLog = new Case_Audit_log__c();
			objLog.Event_Type__c = 'Phone Callback';
			objLog.Case__c = objCase.id;
			insert objLog;

			blnIsSuccess = true;
			objCase.Latest_Successful_Callback_Timestamp__c = system.now();
			update objCase;
		} else {
			strMsg = 'An error occured when submitting callback request';
			map_Response.put('msg', strMsg);
		}

		map_Response.put('response', response);
		map_Response.put('msg', strMsg);

		return map_Response;
	}
}