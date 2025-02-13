/*------------------------------------------------------------------------------
 * Project Name..........: <<Gusto>>
 * File..................: <<UR_ManageCSVCtrl>>
 * Created by............: <<Lirik>>
 * Description...........: <<This class is used to upload *csv files and Filter "Research Upload Info" record information>>
 *-------------------------------------------------------------------------------*/
public with sharing class UR_ManageCSVCtrl {
	public string UR_Delimiter = Label.UR_Delimiter;
	public Integer size { get; set; }
	public Integer noOfRecords { get; set; }
	public List<SelectOption> paginationSizeOptions { get; set; }
	public static final Integer QUERY_LIMIT = 10000;
	public static final Integer PAGE_SIZE = UR_UtilityCtrl.maxCSVRows;
	public ApexPages.StandardSetController setCon { get; set; }
	public ApexPages.StandardSetController setParticipant { get; set; }
	public string extraNOP { get; set; }

	public Blob csvFileBody { get; set; }
	public String csvFileName { get; set; }
	public String sampleCSVHeader { get; set; }
	public Research_Project_Master__c ProjectMasterObj { get; set; }
	public Map<Integer, String> csvQuestionMap = new Map<Integer, String>();
	public List<ResearchUploadInfo> researchUploadInfoList { get; set; }
	public transient Map<Id, List<Research_Upload_Field_Data__c>> uploadDataMap = new Map<Id, List<Research_Upload_Field_Data__c>>();
	public Boolean includeAll { get; set; }
	public string FirstName { get; set; }
	public string LastName { get; set; }
	public string Email { get; set; }
	public string CompanyId { get; set; }
	public string UserId { get; set; }
	public string EmployeeId { get; set; }
	public string AccountFirmId { get; set; }
	public List<fieldLabelInfo> fieldLabelObj { get; set; }
	public Map<String, String> questionAnsMap { get; set; }
	public Set<String> fieldLabelSet { get; set; }
	public Set<String> searchLabelSet { get; set; }
	public Set<String> filterQuestionSet { get; set; }
	public Set<String> filterAnswerSet { get; set; }
	public String filterQuery { get; set; }
	public List<ResearchUploadInfo> convertedResList { get; set; }
	public String participantComments { get; set; }
	public Map<String, Id> contactRecordTypeMap { get; set; }
	public Map<String, Id> companyIdWithAccountMap { get; set; }
	public Map<String, Id> firmIdWithAccountMap { get; set; }
	public Research_Configuration__c objResearch { get; set; }

	public Boolean showHide { get; set; }
	public string rightPanelStyle { get; set; }
	public string filterLabel { get; set; }
	public Date lastUploadedDate { get; set; }
	public Integer totalContact { get; set; }
	public Integer totalContacttoExclude { get; set; }
	public Integer totalFailCSVRecord { get; set; }
	public boolean isEditable { get; set; }
	public String reqField { get; set; }
	public Set<String> duplicateRecord { get; set; }
	public String reservedEmailId { get; set; }
	public String strDaySinceCont { get; set; }
	public Set<string> setExcludedEmailDomain { get; set; }
	public Integer resParticipantCount { get; set; }
	public Set<String> set_selectedParticipantEmail { get; set; }
	public Set<String> set_SelectedParticipantUserId { get; set; }
	public Set<String> set_SelectedParticipantEmpId { get; set; }
	public Set<String> set_ReserveEmailId { get; set; }
	public Set<String> set_ReserveUserId { get; set; }
	public Set<String> set_ReserveEmpId { get; set; }

	public Set<String> invalidCompanyIdSet { get; set; } // This set check, is there is any Account record exit not in salsesforce.
	public Set<String> invalidFirmIdSet { get; set; } // This set check, is there is any Account record exit not in salsesforce.
	public String newRecordCount { get; set; }
	public List<selectOption> includeParticipant { get; set; }
	public String selIncludeParticipant { get; set; }
	public Integer csvUploadRecordCount { get; set; }
	public Boolean isUploadInprogress { get; set; }

	public String sortbyFieldAPIName { get; set; }
	public String prevSortbyFieldAPIName { get; set; }
	public String orderAs { get; set; }
	public String selSortbyFieldAPIName { get; set; }
	public String selPrevSortbyFieldAPIName { get; set; }
	public String selOrderAs { get; set; }
	public String searchByField { get; set; }
	public String viewObjId { get; set; }
	public Map<String, String> viewMoreMap { get; set; }
	public ContactWrapper viewContactWrapperObj { get; set; }
	public Integer viewRowIndex { get; set; }
	public List<selectOption> selPageResultList { get; set; }
	public String selPageResultStr { get; set; }
	public Integer totalAvaillableCSVRecord { get; set; }
	// This method count,
	// 1.) Total number of "csv contact records" imported(by *.CSV).
	// 2.) Total number of "csv contact records" excluded from first table.
	public void fetchCSVDetails() {
		String projectIdStr = ProjectMasterObj.Id;
		totalFailCSVRecord = [SELECT COUNT() FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c = :ProjectMasterObj.Id AND Status__c = 'Fail'];
		totalContact = [SELECT COUNT() FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :projectIdStr];
		totalContacttoExclude = [
			SELECT COUNT()
			FROM Research_Upload_Info__c
			WHERE
				Research_Project_Master_Id__c = :projectIdStr
				AND (Blacklist__c = TRUE
				OR Opt_Out__c = TRUE
				OR Email__c IN :set_ReserveEmailId
				OR Company_Id__c IN :invalidCompanyIdSet
				OR Accountant_Firm_Id__c IN :invalidFirmIdSet
				OR User_Id__c IN :set_ReserveUserId
				OR Employee_Id__c IN :set_ReserveEmpId
				OR Excluded_Contact__c = TRUE)
		];

		lastUploadedDate = null;
		for (Research_Upload_Info__c obj : [SELECT CSV_Upload_Date__c FROM Research_Upload_Info__c WHERE Research_Project_Master_Id__c = :projectIdStr AND CSV_Upload_Date__c != NULL LIMIT 1]) {
			lastUploadedDate = obj.CSV_Upload_Date__c;
		}
	}

	// Wrapper class to map Question and Answer.
	// This class used to left search option.
	public class fieldLabelInfo {
		public String fieldLabel { get; set; }
		public String flagValue { get; set; }
		public fieldLabelInfo() {
			fieldLabel = '';
			flagValue = '';
		}
	}

	// This method reterive inital configuration settings.
	public void RetriveProjectConfiguration() {
		objResearch = new Research_Configuration__c();
		objResearch = UR_UtilityCtrl.RetriveResearchConfiguration();
	}

	//Wrapper class to show csv rows on visual force page.
	// This class used to maintain Research_Upload_Info__c record information.
	public class ResearchUploadInfo {
		public Research_Upload_Info__c UploadInfo { get; set; }
		public boolean flag { get; set; }
		public boolean removeflag { get; set; }
		public String comment { get; set; }
		public String status { get; set; }
	}

	//Constructor
	public UR_ManageCSVCtrl() {
	}

	//Constructor
	public UR_ManageCSVCtrl(apexPages.StandardController stdcon) {
		resParticipantCount = 0;
		isUploadInprogress = false;
		csvUploadRecordCount = 0;
		setCon = null;
		setParticipant = null;
		extraNOP = null;
		includeAll = true;
		filterQuestionSet = new Set<String>();
		filterAnswerSet = new Set<String>();
		filterQuery = '';
		strDaySinceCont = '90'; //Set Default value.
		questionAnsMap = new Map<String, String>();
		String currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');

		orderAs = ApexPages.CurrentPage().getparameters().get('orderas');
		if (String.isBlank(orderAs)) {
			orderAs = 'asc';
		}
		sortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('sortby');
		if (String.isBlank(sortbyFieldAPIName)) {
			sortbyFieldAPIName = 'First_Name__c';
		}
		prevSortbyFieldAPIName = sortbyFieldAPIName;

		selOrderAs = ApexPages.CurrentPage().getparameters().get('selorderas');
		if (String.isBlank(selOrderAs)) {
			selOrderAs = 'asc';
		}
		selSortbyFieldAPIName = ApexPages.CurrentPage().getparameters().get('selsortby');
		if (String.isBlank(selSortbyFieldAPIName)) {
			selSortbyFieldAPIName = 'Contact__r.Name';
		}
		selPrevSortbyFieldAPIName = selSortbyFieldAPIName;

		newRecordCount = ApexPages.CurrentPage().getparameters().get('rowCount');
		if (String.isNotBlank(newRecordCount) && Integer.valueOf(newRecordCount) > 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, newRecordCount + ' records has been successfully added.'));
		}
		searchByField = '';

		/*String isdeleteCSV  = ApexPages.CurrentPage().getparameters().get('isdeletecsv'); 
        if(String.isNotBlank(isdeleteCSV) && 'Y'==isdeleteCSV){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'All CSV records has been successfully deleted.'));
        }*/
		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		ProjectMasterObj = new Research_Project_Master__c(id = currentRecordId);
		fieldLabelObj = new List<fieldLabelInfo>();
		searchLabelSet = new Set<String>();
		existingEmailIdSet = new Set<String>();
		existingUserIdSet = new Set<String>();
		existingEmpIdSet = new Set<String>();

		//To download sample CSV file
		sampleCSVHeader = 'first_name,last_name,email,company_id,user_id,employee_id,accounting_firm_id';

		contactRecordTypeMap = new Map<String, Id>();
		for (RecordType rObj : [SELECT Id, sObjectType FROM RecordType WHERE DeveloperName = 'Company' AND (sObjectType = 'Contact' OR sObjectType = 'Account')]) {
			contactRecordTypeMap.put(rObj.sObjectType, rObj.Id);
		}

		convertedResList = new List<ResearchUploadInfo>();
		participantComments = '';
		lstSelectedContactWrapper = new List<ContactWrapper>();
		setExcludedEmailDomain = new Set<string>();
		for (UR_Excluded_Contact_Domain__c objExclude : UR_Excluded_Contact_Domain__c.getall().values()) {
			setExcludedEmailDomain.add(objExclude.Name);
		}

		// Fetch "UX Scout(Research_Project_Master__c)" project details.
		RetriveProjectRecord();

		// Check uploaded csv records, engaged with any other projects.
		checkResParticipantForOtherProject();

		// This method retrieve all the slected participants details.
		populateSelectedContact(true);

		//companyIdWithAccountMap & firmIdWithAccountMap used to get exisitng Account records.
		companyIdWithAccountMap = new Map<String, Id>();
		firmIdWithAccountMap = new Map<String, Id>();

		//Retrieve "UX Scout" custom setting infotrmation
		RetriveProjectConfiguration();

		showHide = true;
		rightPanelStyle = 'slds-large-size_8-of-12';
		filterLabel = '<< Hide Filters';
		fetchCSVDetails();

		duplicateRecord = new Set<String>();
		reqField = '';
		reservedEmailId = '';
		includeParticipant = new List<selectOption>();
		includeParticipant.add(new selectOption('Add participants', 'Add participants'));
		includeParticipant.add(new selectOption('From CSV', 'From CSV'));
		includeParticipant.add(new selectOption('From Salesforce search', 'From Salesforce search'));

		viewMoreMap = new Map<String, String>();
		viewContactWrapperObj = new ContactWrapper();
		viewRowIndex = 0;

		selPageResultList = new List<selectOption>();
		selPageResultList.add(new selectOption('10', '10'));
		selPageResultList.add(new selectOption('25', '25'));
		selPageResultList.add(new selectOption('50', '50'));
		selPageResultList.add(new selectOption('100', '100'));
		selPageResultStr = ApexPages.CurrentPage().getparameters().get('pagesize');
		if (String.isBlank(selPageResultStr)) {
			selPageResultStr = '50';
		}
	}

	//This method show and hide search filter section
	public void HideFilter() {
		if (showHide == true) {
			rightPanelStyle = 'slds-large-size_12-of-12';
			showHide = false;
			filterLabel = 'Show Filters >>';
		} else {
			rightPanelStyle = 'slds-large-size_8-of-12';
			showHide = true;
			filterLabel = '<< Hide Filters';
		}
	}

	//This method release, participants from the project.
	public PageReference removeContact() {
		Set<string> projectDetailIdSet = new Set<string>();
		for (ContactWrapper cw : lstSelectedContactWrapper) {
			if (cw.selContact == true && cw.projectPartId != null) {
				projectDetailIdSet.add(cw.projectPartId);
			}
		}
		if (projectDetailIdSet.size() > 0) {
			List<Research_Project_Detail_Data_Info__c> list_RSProjectDetailInfo = [SELECT Id FROM Research_Project_Detail_Data_Info__c WHERE Research_Project_Detail__c IN :projectDetailIdSet];
			if (list_RSProjectDetailInfo.size() > 0) {
				delete list_RSProjectDetailInfo;
			}
			List<Research_Project_Detail__c> list_RSProjectDetail = [SELECT Id FROM Research_Project_Detail__c WHERE id IN :projectDetailIdSet];
			if (list_RSProjectDetail.size() > 0) {
				delete list_RSProjectDetail;
			}
			PageReference pageRef = new PageReference(
				'/apex/UR_ManageCSV?projectId=' +
					ProjectMasterObj.Id +
					'&orderas=' +
					orderAs +
					'&sortby=' +
					sortbyFieldAPIName +
					'&selorderas=' +
					selOrderAs +
					'&selsortby=' +
					selSortbyFieldAPIName +
					'&pagesize=' +
					selPageResultStr
			);
			pageRef.setRedirect(true);
			return pageRef;
		} else {
			return null;
		}
	}

	//This method add contact in selected contact list.
	public PageReference addContact() {
		newRecordCount = '';
		PageReference pageRef = null;
		String userId = '', empEmailId = '';
		Boolean isRecordSelected = false, isValidRecord = false;
		Set<String> set_CheckEmailId = new Set<String>();
		Set<String> set_CheckUserId = new Set<String>();
		Set<String> set_checkEmpId = new Set<String>();

		for (ResearchUploadInfo resUploadObj : researchUploadInfoList) {
			// This for loop, create list of selected records from First table
			// This for loop, also create a set of EmailId, UserId and EmployeeId set.
			userId = resUploadObj.UploadInfo.User_Id__c;
			empEmailId = resUploadObj.UploadInfo.Email__c;
			isValidRecord = false;
			if (resUploadObj.flag == true) {
				isRecordSelected = true;
				if (String.isNotBlank(resUploadObj.UploadInfo.Email__c)) {
					set_CheckEmailId.add(resUploadObj.UploadInfo.Email__c);
					isValidRecord = true;
				}
				if (String.isNotBlank(resUploadObj.UploadInfo.User_Id__c)) {
					set_CheckUserId.add(resUploadObj.UploadInfo.User_Id__c);
					isValidRecord = true;
				}
				if (String.isNotBlank(resUploadObj.UploadInfo.Employee_Id__c)) {
					set_checkEmpId.add(resUploadObj.UploadInfo.Employee_Id__c);
					isValidRecord = true;
				}

				if (isValidRecord) {
					resUploadObj.removeflag = true;
					convertedResList.add(resUploadObj); // Create Selected record list from first table.
					resUploadObj.flag = false;
					resUploadObj.removeflag = false;
					resUploadObj.comment = participantComments;
					resUploadObj.status = 'Reserved';
				} else {
					resUploadObj.removeflag = false;
				}
			} else {
				resUploadObj.removeflag = false;
			}
		}

		if (isRecordSelected == false) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'Please select at least one record.'));
		} else {
			// If selected participant recently reserved then this method return "Invalid participant email Id" set
			Set<String> set_InvalidEmailId = isReservedParticipant(set_CheckEmailId, set_CheckUserId, set_checkEmpId);

			if (set_InvalidEmailId.size() > 0) {
				ApexPages.addMessage(
					new ApexPages.Message(
						ApexPages.severity.Error,
						'Out of ' + convertedResList.size() + ' selected, ' + set_InvalidEmailId.size() + ' is already added in other projects. Kindly refresh this screen to see updated data.'
					)
				);
				convertedResList.clear();
			} else {
				// Reserved selected paticipants.
				PageReference pageObj = saveCSVContact();
				return pageObj;
			}
		}
		return null;
	}

	//This method will be called from Back button.
	public PageReference BackToProjectVf() {
		PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + ProjectMasterObj.Id);
		/*Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(ProjectMasterObj.Id);
        if(isParticipantExist){
            pageRef = new PageReference('/apex/UR_ManageParticipant?Id='+ProjectMasterObj.Id);
        }else{
        	pageRef = new PageReference('/apex/UR_AddParticipants?projectId='+ProjectMasterObj.Id);
        }*/
		return pageRef;
	}

	//This method will be called from "Reserve selected contacts" button.
	//If selected contact does not exist in salesforce then this method create new contact record list in salesforce and reserver the contact with project.
	public PageReference saveContact() {
		try {
			saveSelectedCSVConatct();
			updatedExistingParicipant();
			convertedResList.clear();
			participantComments = '';
			filterQuery = '';
		} catch (Exception ex) {
			String error = ex + '';
			error = error.replace('MaxParticipantLimitException:[]:', '');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, error));
			return null;
		}
		PageReference pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + ProjectMasterObj.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method will be called from "Reserve selected contacts" button.
	public PageReference saveCSVContact() {
		try {
			saveSelectedCSVConatct();
			PageReference pageRef = new PageReference(
				'/apex/UR_ManageCSV?projectId=' +
					ProjectMasterObj.Id +
					'&rowCount=' +
					newRecordCount +
					'&orderas=' +
					orderAs +
					'&sortby=' +
					sortbyFieldAPIName +
					'&selorderas=' +
					selOrderAs +
					'&selsortby=' +
					selSortbyFieldAPIName +
					'&pagesize=' +
					selPageResultStr
			);
			pageRef.setRedirect(true);
			return pageRef;
		} catch (Exception ex) {
			String error = ex + '';
			error = error.replace('MaxParticipantLimitException:[]:', '');
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, error));
			return null;
		}
	}

	//This method reserved selected participant to the project.
	//
	public void saveSelectedCSVConatct() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		decimal MaximumNumber = 0;
		decimal minimumNumber = 0;
		if (objResearch != null && objResearch.Max_Number_Of_Participants_High_Limit__c != null) {
			MaximumNumber = objResearch.Max_Number_Of_Participants_High_Limit__c;
		}
		if (objResearch != null && objResearch.Min_Number_Of_Participants_Low_Limit__c != null) {
			minimumNumber = objResearch.Min_Number_Of_Participants_Low_Limit__c;
		}
		//Update maximum value from project level
		if (ProjectMasterObj != null && ProjectMasterObj.Number_of_Allowed_Participant__c != null) {
			MaximumNumber = ProjectMasterObj.Number_of_Allowed_Participant__c;
		}

		String empEmailId = '', empUserId = '', empEmpId = '', companyId = '', accFirmId = '';
		Set<String> newEmailIdSet = new Set<String>();
		Set<String> newUserIdSet = new Set<String>();
		Set<String> newEmpIdSet = new Set<String>();
		for (ResearchUploadInfo resUploadObj : convertedResList) {
			empEmailId = resUploadObj.UploadInfo.Email__c;
			empUserId = resUploadObj.UploadInfo.User_Id__c;
			empEmpId = resUploadObj.UploadInfo.Employee_Id__c;
			if (String.isNotBlank(empEmailId)) {
				newEmailIdSet.add(empEmailId);
			}
			if (String.isNotBlank(empUserId)) {
				newUserIdSet.add(empUserId);
			}
			if (String.isNotBlank(empEmpId)) {
				newEmpIdSet.add(empEmpId);
			}
		}

		Map<String, Id> conObjEmailIdMap = new Map<String, Id>();
		Map<String, Id> conObjUserIdMap = new Map<String, Id>();
		Map<String, Id> conObjEmpIdMap = new Map<String, Id>();

		if (newEmailIdSet.size() > 0) {
			//Create existing contact Map[conObjEmailIdMap, conObjUserIdMap, conObjEmpIdMap].
			List<Contact> tempContactList = [
				SELECT Id, Employee_Id__c, ZP_User_Id__c, Email
				FROM Contact
				WHERE Email IN :newEmailIdSet OR ZP_User_Id__c IN :newUserIdSet OR Employee_Id__c IN :newEmpIdSet
			];
			for (Contact conObj : tempContactList) {
				if (String.isNotBlank(conObj.Email)) {
					conObjEmailIdMap.put(conObj.Email, conObj.Id);
				}
				if (String.isNotBlank(conObj.ZP_User_Id__c)) {
					conObjUserIdMap.put(conObj.ZP_User_Id__c, conObj.Id);
				}
				if (String.isNotBlank(conObj.Employee_Id__c)) {
					conObjEmpIdMap.put(conObj.Employee_Id__c, conObj.Id);
				}
			}
			tempContactList.clear();
		}

		List<Contact> conList = new List<Contact>();
		// When we select records from first table then these set :
		// [newlyCreatedEmailIdSet, newlyCreatedUserIdSet, newlyCreatedEmpIdSet] check duplicate "Contact" records in newly created contact list.
		Set<String> newlyCreatedEmailIdSet = new Set<String>();
		Set<String> newlyCreatedUserIdSet = new Set<String>();
		Set<String> newlyCreatedEmpIdSet = new Set<String>();

		for (ResearchUploadInfo resUploadObj : convertedResList) {
			empEmailId = resUploadObj.UploadInfo.Email__c; //[First preference on Contact]
			empUserId = resUploadObj.UploadInfo.User_Id__c; //[Second preference on Contact]
			empEmpId = resUploadObj.UploadInfo.Employee_Id__c; //[Third preference on Contact]

			//Search on Account Map
			companyId = resUploadObj.UploadInfo.Company_Id__c; //[First preference on Account]
			accFirmId = resUploadObj.UploadInfo.Accountant_Firm_Id__c; //[Second preference on Account]

			String encodedCodeEmail = '';
			if (!conObjEmailIdMap.containsKey(empEmailId) && !conObjUserIdMap.containsKey(empUserId) && !conObjEmpIdMap.containsKey(empEmpId)) {
				if (
					(String.isNotBlank(resUploadObj.UploadInfo.Email__c) && newlyCreatedEmailIdSet.contains(resUploadObj.UploadInfo.Email__c)) ||
					(String.isNotBlank(resUploadObj.UploadInfo.User_Id__c) && newlyCreatedUserIdSet.contains(resUploadObj.UploadInfo.User_Id__c)) ||
					(String.isNotBlank(resUploadObj.UploadInfo.Employee_Id__c) && newlyCreatedEmpIdSet.contains(resUploadObj.UploadInfo.Employee_Id__c))
				) {
					//If duplicate contact record exist in newly reserve participant list [Duplicate check on then basis of EmailId, UserId, EmployeeId]
					//Do nothing.
				} else {
					//Create new contact.
					Contact conObj = new Contact();
					conObj.recordTypeId = contactRecordTypeMap.get('Contact');
					conObj.FirstName = resUploadObj.UploadInfo.First_Name__c;
					conObj.LastName = resUploadObj.UploadInfo.Last_Name__c;
					conObj.Email = resUploadObj.UploadInfo.Email__c;
					conObj.Unique_Email_Address_Contact__c = conObj.Email; //This logic shared by Ash.

					//get Email domain
					conObj.UXResearch_Exclude_Domain__c = false;
					if (string.isNotBlank(conObj.Email) && setExcludedEmailDomain.size() > 0) {
						string email = conObj.Email;
						string domain = email.substring(email.indexOf('@') + 1, email.length()).Trim();
						conObj.UXResearch_Exclude_Domain__c = setExcludedEmailDomain.contains(domain);
					}

					conObj.Employee_Id__c = resUploadObj.UploadInfo.Employee_Id__c;
					conObj.ZP_User_Id__c = resUploadObj.UploadInfo.User_Id__c;
					if (companyIdWithAccountMap.containsKey(companyId)) {
						conObj.AccountId = companyIdWithAccountMap.get(companyId);
					} else {
						conObj.AccountId = firmIdWithAccountMap.get(accFirmId);
					}
					conObj.UXR_Scout_Uploaded__c = true;
					conList.add(conObj);

					//Create new set, on the basis of newly created contact.
					if (String.isNotBlank(conObj.Email)) {
						newlyCreatedEmailIdSet.add(conObj.Email);
					}
					if (String.isNotBlank(conObj.ZP_User_Id__c)) {
						newlyCreatedUserIdSet.add(conObj.ZP_User_Id__c);
					}
					if (String.isNotBlank(conObj.Employee_Id__c)) {
						newlyCreatedEmpIdSet.add(conObj.Employee_Id__c);
					}
				}
			}
		}

		if (conList.size() > 0) {
			insert conList;

			//This for loop update contact Map[conObjEmailIdMap, conObjUserIdMap, conObjEmpIdMap].
			for (Contact conObj : conList) {
				if (String.isNotBlank(conObj.Email)) {
					conObjEmailIdMap.put(conObj.Email, conObj.id);
				}
				if (String.isNotBlank(conObj.ZP_User_Id__c)) {
					conObjUserIdMap.put(conObj.ZP_User_Id__c, conObj.id);
				}
				if (String.isNotBlank(conObj.Employee_Id__c)) {
					conObjEmpIdMap.put(conObj.Employee_Id__c, conObj.id);
				}
			}
		}

		//Clear below mentioned set.
		// When we select records from first table then these set :
		// [newlyCreatedEmailIdSet, newlyCreatedUserIdSet, newlyCreatedEmpIdSet] check duplicate "Research Project Detail" records in newly created contact list.
		newlyCreatedEmailIdSet.clear();
		newlyCreatedUserIdSet.clear();
		newlyCreatedEmpIdSet.clear();

		Set<Id> UploadInfoIdSet = new Set<Id>();
		Map<String, Research_Project_Detail__c> rsProjectMap = new Map<String, Research_Project_Detail__c>();
		List<Research_Project_Detail__c> rsProjectList = new List<Research_Project_Detail__c>();
		for (ResearchUploadInfo resUploadObj : convertedResList) {
			empEmailId = resUploadObj.UploadInfo.Email__c; //[First preference on Contact]
			empUserId = resUploadObj.UploadInfo.User_Id__c; //[Second preference on Contact]
			empEmpId = resUploadObj.UploadInfo.Employee_Id__c; //[Third preference on Contact]

			if (
				(String.isNotBlank(empEmailId) ||
				String.isNotBlank(empUserId) ||
				String.isNotBlank(empEmpId)) &&
				!existingEmailIdSet.contains(empEmailId + '') &&
				!existingUserIdSet.contains(empUserId + '') &&
				!existingEmpIdSet.contains(empEmpId + '') &&
				(conObjEmailIdMap.containsKey(empEmailId) ||
				conObjUserIdMap.containsKey(empUserId) ||
				conObjEmpIdMap.containsKey(empEmpId))
			) {
				if (!newlyCreatedEmailIdSet.contains(empEmailId + '') && !newlyCreatedUserIdSet.contains(empUserId + '') && !newlyCreatedEmpIdSet.contains(empEmpId + '')) {
					//Add new participant in your project.
					Research_Project_Detail__c rsObj = new Research_Project_Detail__c();
					if (String.isNotBlank(empEmailId) && conObjEmailIdMap.containsKey(empEmailId)) {
						rsObj.Contact__c = conObjEmailIdMap.get(empEmailId);
						rsProjectMap.put(empEmailId, rsObj);
					} else if (String.isNotBlank(empUserId) && conObjUserIdMap.containsKey(empUserId)) {
						rsObj.Contact__c = conObjUserIdMap.get(empUserId);
						rsProjectMap.put(empUserId, rsObj);
					} else if (String.isNotBlank(empEmpId) && conObjEmpIdMap.containsKey(empEmpId)) {
						rsObj.Contact__c = conObjEmpIdMap.get(empEmpId);
						rsProjectMap.put(empEmpId, rsObj);
					}
					rsObj.Research_Project_Master__c = ProjectMasterObj.id;
					rsObj.Research_Participant_Status__c = 'Reserved';
					rsObj.Comment__c = resUploadObj.comment;
					rsObj.Added_by_CSV__c = true;
					rsProjectList.add(rsObj);
					UploadInfoIdSet.add(resUploadObj.UploadInfo.Id);

					if (String.isNotBlank(empEmailId)) {
						newlyCreatedEmailIdSet.add(empEmailId);
					}
					if (String.isNotBlank(empUserId)) {
						newlyCreatedUserIdSet.add(empUserId);
					}
					if (String.isNotBlank(empEmpId)) {
						newlyCreatedEmpIdSet.add(empEmpId);
					}
				} else {
					//Duplicate records
					//Do not add again in "Research Project Detail" object.
				}
			}
		}

		if (rsProjectList.size() > 0) {
			//Integer totalParticipant = lstSelectedContactWrapper.size() + rsProjectList.size();
			Integer totalParticipant = resParticipantCount + rsProjectList.size();
			if (totalParticipant >= minimumNumber && totalParticipant <= MaximumNumber) {
				insert rsProjectList;
				newRecordCount = rsProjectList.size() + '';
			} else {
				String errorMsg = Label.UR_YouCanAddParticipant1 + ' ' + minimumNumber + ' to ' + MaximumNumber + ' ' + Label.UR_YouCanAddParticipant2;
				convertedResList.clear();
				throw new MaxParticipantLimitException(errorMsg);
			}

			if (rsProjectList.size() > 0) {
				Map<String, Id> rsProjectDetailMap = new Map<String, Id>();
				for (String recordKey : rsProjectMap.keySet()) {
					rsProjectDetailMap.put(recordKey, rsProjectMap.get(recordKey).Id);
				}
				if (rsProjectDetailMap.size() > 0) {
					insertRSProjectDetailInfo(UploadInfoIdSet, rsProjectDetailMap);
				}
			}
		}
	}

	@future
	public static void insertRSProjectDetailInfo(Set<Id> UploadInfoIdSet, Map<String, Id> rsProjectDetailMap) {
		List<Research_Project_Detail_Data_Info__c> rsProjectDetailsDataList = new List<Research_Project_Detail_Data_Info__c>();
		String key = '';
		Research_Project_Detail_Data_Info__c rsProjectDataObj = null;
		//This for loop create new "Research Upload Field Data" records.
		List<Research_Upload_Field_Data__c> tempUploadedList = [
			SELECT id, Field_Label__c, Field_Value__c, Research_Upload_Info__c, Research_Upload_Info__r.Employee_Id__c, Research_Upload_Info__r.User_Id__c, Research_Upload_Info__r.Email__c
			FROM Research_Upload_Field_Data__c
			WHERE Research_Upload_Info__c IN :UploadInfoIdSet
		];
		for (Research_Upload_Field_Data__c reDataObj : tempUploadedList) {
			key = '';
			if (reDataObj.Research_Upload_Info__c != null) {
				if (String.isNotBlank(reDataObj.Research_Upload_Info__r.Email__c)) {
					key = reDataObj.Research_Upload_Info__r.Email__c;
				} else if (String.isNotBlank(reDataObj.Research_Upload_Info__r.User_Id__c)) {
					key = reDataObj.Research_Upload_Info__r.User_Id__c;
				} else if (String.isNotBlank(reDataObj.Research_Upload_Info__r.Employee_Id__c)) {
					key = reDataObj.Research_Upload_Info__r.Employee_Id__c;
				}
			}

			if (String.isNotBlank(key) && rsProjectDetailMap.containsKey(key)) {
				rsProjectDataObj = new Research_Project_Detail_Data_Info__c();
				rsProjectDataObj.Label__c = reDataObj.Field_Label__c;
				rsProjectDataObj.Value__c = reDataObj.Field_Value__c;
				rsProjectDataObj.Research_Project_Detail__c = rsProjectDetailMap.get(key);

				rsProjectDetailsDataList.add(rsProjectDataObj);
			}
		}
		tempUploadedList.clear();

		if (rsProjectDetailsDataList.size() > 0) {
			insert rsProjectDetailsDataList;
			rsProjectDetailsDataList.clear();
		}
	}

	//This method updated the comment related to selected participants.
	public void updatedExistingParicipant() {
		try {
			if (lstSelectedContactWrapper != null) {
				if (lstSelectedContactWrapper.size() >= 0) {
					List<Research_Project_Detail__c> lstProjectDetail = new List<Research_Project_Detail__c>();
					for (ContactWrapper ctw : lstSelectedContactWrapper) {
						Research_Project_Detail__c prd = new Research_Project_Detail__c();
						prd.id = ctw.projectPartId;
						prd.Comment__c = ctw.strComment;
						lstProjectDetail.add(prd);
					}
					if (lstProjectDetail != null && lstProjectDetail.size() > 0) {
						update lstProjectDetail;
					}
				}
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
		}
	}

	//This method will execute on page load time.
	public void init() {
		// On page load this function fetch existing information.
		showResearchUploadInfo(false, true);
	}

	//This method add more, search filter criteria.
	public Boolean setFilterCondition() {
		// This method apply filter condition in soql query.
		searchByField = '';
		Boolean isFilterExist = false;
		filterQuestionSet.clear();
		filterAnswerSet.clear();
		filterQuery = '';

		if (String.isNotBlank(FirstName)) {
			isFilterExist = true;
			FirstName = FirstName.trim();
			FirstName = FirstName.replace('*', '');
			FirstName = FirstName.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.First_Name__c LIKE \'%' + FirstName + '%\' ';
			searchByField = searchByField + 'First Name : ' + FirstName + '\n';
		}
		if (String.isNotBlank(LastName)) {
			isFilterExist = true;
			LastName = LastName.trim();
			LastName = LastName.replace('*', '');
			LastName = LastName.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.Last_Name__c LIKE \'%' + LastName + '%\' ';
			searchByField = searchByField + 'Last Name : ' + LastName + '\n';
		}
		if (String.isNotBlank(Email)) {
			isFilterExist = true;
			Email = Email.trim();
			Email = Email.replace('*', '');
			Email = Email.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.Email__c LIKE \'%' + Email + '%\' ';
			searchByField = searchByField + 'Email : ' + Email + '\n';
		}
		if (String.isNotBlank(CompanyId)) {
			isFilterExist = true;
			CompanyId = CompanyId.trim();
			CompanyId = CompanyId.replace('*', '');
			CompanyId = CompanyId.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.Company_Id__c LIKE \'%' + CompanyId + '%\' ';
			searchByField = searchByField + 'Company Id : ' + CompanyId + '\n';
		}
		if (String.isNotBlank(UserId)) {
			isFilterExist = true;
			UserId = UserId.trim();
			UserId = UserId.replace('*', '');
			UserId = UserId.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.User_Id__c LIKE \'%' + UserId + '%\' ';
			searchByField = searchByField + 'User Id : ' + UserId + '\n';
		}
		if (String.isNotBlank(EmployeeId)) {
			isFilterExist = true;
			EmployeeId = EmployeeId.trim();
			EmployeeId = EmployeeId.replace('*', '');
			EmployeeId = EmployeeId.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.Employee_Id__c LIKE \'%' + EmployeeId + '%\' ';
			searchByField = searchByField + 'Employee Id : ' + EmployeeId + '\n';
		}
		if (String.isNotBlank(AccountFirmId)) {
			isFilterExist = true;
			AccountFirmId = AccountFirmId.trim();
			AccountFirmId = AccountFirmId.replace('*', '');
			AccountFirmId = AccountFirmId.replace('%', '');
			filterQuery = filterQuery + ' and Research_Upload_Info__r.Accountant_Firm_Id__c LIKE \'%' + AccountFirmId + '%\' ';
			searchByField = searchByField + 'Accountant Firm Id : ' + AccountFirmId + '\n';
		}

		for (fieldLabelInfo lblStr : fieldLabelObj) {
			if (String.isNotBlank(lblStr.flagValue)) {
				isFilterExist = true;
				lblStr.flagValue = lblStr.flagValue.trim();
				filterQuestionSet.add(lblStr.fieldLabel);
				filterAnswerSet.add(lblStr.flagValue);
				searchByField = searchByField + lblStr.fieldLabel + ' : ' + lblStr.flagValue + '\n';
			}
		}
		return isFilterExist;
	}

	//This method will call from "Search" button.
	public void showAll() {
		// Once user search the record basis on some filter condition.
		if (setFilterCondition()) {
			showAllWithFilter();
		} else {
			resetAll();
		}
	}

	//If their is any filter condition than this method will call from "Search" button.
	public void showAllWithFilter() {
		//Fetch Reserve Participant info and create a set of Email, UserId, and EmployeeId
		fetchSelectedParticipantDetails();

		checkResParticipantForOtherProject();

		questionAnsMap = new Map<String, String>();
		uploadDataMap = new Map<Id, List<Research_Upload_Field_Data__c>>();
		List<Research_Upload_Field_Data__c> tempInfoList = new List<Research_Upload_Field_Data__c>();
		fieldLabelSet = new Set<String>();
		String key = '';
		Set<Id> uploadInfoId = new Set<Id>();
		researchUploadInfoList = new List<ResearchUploadInfo>();

		Map<String, List<String>> checkFilterMap = new Map<String, List<String>>();

		//First we fetch "Research_Upload_Field_Data__c" information(On the basis of applied filter condition).
		Id projectId = ProjectMasterObj.id;
		String projectIdStr = projectId;
		String strSubQueryString = 'SELECT id, Field_Label__c, Field_Value__c, Research_Upload_Info__c, Research_Upload_Info__r.Research_Project_Master__c, Research_Upload_Info__r.Research_Project_Master_Id__c FROM Research_Upload_Field_Data__c WHERE Research_Upload_Info__r.Research_Project_Master_Id__c =: projectIdStr AND Research_Upload_Info__r.Excluded_Contact__c=false ';
		if (!Test.isRunningTest()) {
			strSubQueryString =
				strSubQueryString +
				' AND Research_Upload_Info__r.Blacklist__c = false AND Research_Upload_Info__r.Opt_Out__c=false ' +
				' AND Research_Upload_Info__r.Email__c NOT IN : set_ReserveEmailId AND Research_Upload_Info__r.Email__c NOT IN : set_selectedParticipantEmail ' +
				' AND Research_Upload_Info__r.User_Id__c NOT IN : set_ReserveUserId AND Research_Upload_Info__r.User_Id__c NOT IN : set_SelectedParticipantUserId ' +
				' AND Research_Upload_Info__r.Employee_Id__c NOT IN : set_ReserveEmpId AND Research_Upload_Info__r.Employee_Id__c NOT IN : set_SelectedParticipantEmpId  ' +
				' AND Research_Upload_Info__r.Company_Id__c NOT IN : invalidCompanyIdSet AND Research_Upload_Info__r.Accountant_Firm_Id__c NOT IN : invalidFirmIdSet ';
		}

		strSubQueryString = strSubQueryString + filterQuery;
		if (filterQuestionSet != null && filterQuestionSet.size() > 0) {
			strSubQueryString = strSubQueryString + ' AND Field_Label__c IN : filterQuestionSet AND Field_Value__c IN : filterAnswerSet  ';
		}
		strSubQueryString = strSubQueryString + ' LIMIT 5000 ';

		List<Research_Upload_Field_Data__c> tempUploadedFieldDataList = Database.query(strSubQueryString);
		for (Research_Upload_Field_Data__c uploadDataObj : tempUploadedFieldDataList) {
			if (uploadDataMap.containsKey(uploadDataObj.Research_Upload_Info__c)) {
				tempInfoList = uploadDataMap.get(uploadDataObj.Research_Upload_Info__c);
				tempInfoList.add(uploadDataObj);
				uploadDataMap.put(uploadDataObj.Research_Upload_Info__c, tempInfoList);
			} else {
				tempInfoList = new List<Research_Upload_Field_Data__c>();
				tempInfoList.add(uploadDataObj);
				uploadDataMap.put(uploadDataObj.Research_Upload_Info__c, tempInfoList);
			}
			if (!fieldLabelSet.contains(uploadDataObj.Field_Label__c)) {
				fieldLabelSet.add(uploadDataObj.Field_Label__c);

				if (!searchLabelSet.contains(uploadDataObj.Field_Label__c)) {
					fieldLabelInfo labelObj = new fieldLabelInfo();
					labelObj.fieldLabel = uploadDataObj.Field_Label__c;
					fieldLabelObj.add(labelObj);
					searchLabelSet.add(uploadDataObj.Field_Label__c);
				}
			}
			key = uploadDataObj.Research_Upload_Info__c + uploadDataObj.Field_Label__c;
			if (String.isNotBlank(uploadDataObj.Field_Value__c)) {
				questionAnsMap.put(key, uploadDataObj.Field_Value__c);
			} else {
				questionAnsMap.put(key, '');
			}

			if (filterAnswerSet.size() > 0) {
				//This block of code, create Map. This map would be used in filter criteria.
				if (filterAnswerSet.contains(uploadDataObj.Field_Value__c)) {
					if (checkFilterMap.containsKey(uploadDataObj.Research_Upload_Info__c)) {
						List<String> tempLabelList = checkFilterMap.get(uploadDataObj.Research_Upload_Info__c);
						tempLabelList.add(uploadDataObj.Field_Value__c);
						checkFilterMap.put(uploadDataObj.Research_Upload_Info__c, tempLabelList);
					} else {
						List<String> tempLabelList = new List<String>();
						tempLabelList.add(uploadDataObj.Field_Value__c);
						checkFilterMap.put(uploadDataObj.Research_Upload_Info__c, tempLabelList);
					}
				}
			} else {
				//If we have not applied any filter condition in Questions
				uploadInfoId.add(uploadDataObj.Research_Upload_Info__c);
			}
		}
		tempUploadedFieldDataList.clear();

		if (filterAnswerSet.size() > 0) {
			// Check Output result, match all the filter criteria or not.
			for (String filterKey : checkFilterMap.keySet()) {
				List<String> tempLabelList = checkFilterMap.get(filterKey);
				if (tempLabelList.size() >= filterAnswerSet.size()) {
					uploadInfoId.add(filterKey);
				}
			}
		}

		String strQueryString =
			'SELECT id, First_Name__c, Last_Name__c, Email__c, Company_Id__c, User_Id__c, Employee_Id__c, Accountant_Firm_Id__c, ' +
			'Blacklist__c, Opt_Out__c FROM Research_Upload_Info__c WHERE Blacklist__c = false AND Opt_Out__c=false AND Excluded_Contact__c=false  ' +
			' AND Email__c NOT IN : set_ReserveEmailId AND Email__c NOT IN : set_selectedParticipantEmail ' +
			' AND User_Id__c NOT IN : set_ReserveUserId AND User_Id__c NOT IN : set_SelectedParticipantUserId ' +
			' AND Employee_Id__c NOT IN : set_ReserveEmpId AND Employee_Id__c NOT IN : set_SelectedParticipantEmpId ' +
			' AND Company_Id__c NOT IN : invalidCompanyIdSet AND Accountant_Firm_Id__c NOT IN : invalidFirmIdSet ';

		if (uploadInfoId.size() > 0 || filterAnswerSet.size() > 0) {
			strQueryString = strQueryString + ' AND Id IN : uploadInfoId ';
		} else {
			//If there is no Research_Upload_Field_Data__c record exist. then this block of code would executed.
			strQueryString = strQueryString + ' AND Research_Project_Master_Id__c =: projectIdStr ';
			if (String.isNotBlank(filterQuery)) {
				filterQuery = filterQuery.replace('Research_Upload_Info__r.', '');
				strQueryString = strQueryString + filterQuery;
			}
		}

		strQueryString = strQueryString;
		if (includeAll == false && lastUploadedDate != null) {
			Date dateObj = system.today();
			strQueryString = strQueryString + ' AND LastModifiedDate >=: lastUploadedDate ';
		}
		//strQueryString = strQueryString + ' order by First_Name__c LIMIT : QUERY_LIMIT ';
		strQueryString = strQueryString + ' order by ' + sortbyFieldAPIName + ' ' + orderAs + ' NULLS LAST limit 5000 ';

		setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQueryString));
		setCon.setPageSize(Integer.valueOf(selPageResultStr));

		String strkey = '';
		//Filter Research Upload List, because email id added in other project also.
		for (Research_Upload_Info__c uploadObj : (List<Research_Upload_Info__c>) setCon.getRecords()) {
			ResearchUploadInfo uploadInfoObj = new ResearchUploadInfo();
			uploadInfoObj.UploadInfo = uploadObj;
			uploadInfoObj.flag = false;
			uploadInfoObj.removeflag = false;
			researchUploadInfoList.add(uploadInfoObj);

			for (String label : fieldLabelSet) {
				strkey = uploadObj.id + label;
				if (!questionAnsMap.containsKey(strkey)) {
					questionAnsMap.put(strkey, '');
				}
			}
		}

		if (String.isNotBlank(searchByField)) {
			UR_UtilityCtrl.createUXRSearchingRecord(searchByField, ProjectMasterObj.Id, 'CSV Search', researchUploadInfoList.size(), '');
		}

		//Clear Selected Participant Set. Because it will consider in view state.
		clearSelectedParticipantSet();
	}

	// This method will call on page load time.
	// This method will call once user click "Clear All Filter" button.
	//In this method first we fetch Research_Upload_Info__c records then we will search Research_Upload_Field_Data__c records with any filter condition.
	//Only "Include All Uploaded Data" is true or false condition applied in this method.
	public void showResearchUploadInfo(Boolean isCreatedToday, Boolean isRunSoqlQuery) {
		//Fetch Reserve Participant info and create a set of Email, UserId, and EmployeeId
		fetchSelectedParticipantDetails();

		try {
			Set<String> companyIdSet = new Set<String>();
			Set<String> firmIdSet = new Set<String>();
			companyIdWithAccountMap = new Map<String, Id>();
			firmIdWithAccountMap = new Map<String, Id>();

			fieldLabelSet = new Set<String>();
			// List<Research_Upload_Info__c> uploadInfoList = new List<Research_Upload_Info__c>();
			researchUploadInfoList = new List<ResearchUploadInfo>();
			uploadDataMap = new Map<Id, List<Research_Upload_Field_Data__c>>();

			if (ProjectMasterObj != null) {
				Id projectId = ProjectMasterObj.id;
				String projectIdStr = projectId;
				String strQueryString =
					'SELECT id, First_Name__c, Last_Name__c, Email__c, Company_Id__c, User_Id__c, ' + ' Employee_Id__c, Accountant_Firm_Id__c, Blacklist__c, Opt_Out__c  FROM Research_Upload_Info__c ';

				String strQueryFilter =
					' WHERE Research_Project_Master_Id__c =: projectIdStr AND Excluded_Contact__c=false AND Blacklist__c = false ' +
					' AND Opt_Out__c=false AND  Email__c NOT IN : set_ReserveEmailId AND Email__c NOT IN : set_selectedParticipantEmail AND ' +
					' User_Id__c NOT IN : set_ReserveUserId AND User_Id__c NOT IN : set_SelectedParticipantUserId AND ' +
					' Employee_Id__c NOT IN : set_ReserveEmpId AND Employee_Id__c NOT IN : set_SelectedParticipantEmpId AND ' +
					' Company_Id__c NOT IN : invalidCompanyIdSet AND Accountant_Firm_Id__c NOT IN : invalidFirmIdSet';

				strQueryString = strQueryString + strQueryFilter;
				strQueryString = strQueryString + filterQuery;
				if (isCreatedToday && lastUploadedDate != null) {
					Date dateObj = system.today();
					strQueryString = strQueryString + ' AND LastModifiedDate >=: lastUploadedDate ';
				}

				//strQueryString = strQueryString + ' order by First_Name__c LIMIT : QUERY_LIMIT ';
				strQueryString = strQueryString + ' order by ' + sortbyFieldAPIName + ' ' + orderAs + ' NULLS LAST limit 5000';

				if (isRunSoqlQuery) {
					totalAvaillableCSVRecord = 0;
					String totalCSVRecordQuery = 'SELECT count(id) totalrecord FROM Research_Upload_Info__c ' + strQueryFilter;
					AggregateResult results = Database.query(totalCSVRecordQuery);
					if (results != null) {
						totalAvaillableCSVRecord = Integer.valueOf(results.get('totalrecord') + '');
					}
					setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQueryString));
					setCon.setPageSize(Integer.valueOf(selPageResultStr));
				}

				questionAnsMap = new Map<String, String>();
				for (Research_Upload_Info__c uploadObj : (List<Research_Upload_Info__c>) setCon.getRecords()) {
					ResearchUploadInfo uploadInfoObj = new ResearchUploadInfo();
					uploadInfoObj.UploadInfo = uploadObj;
					uploadInfoObj.flag = false;
					uploadInfoObj.removeflag = false;
					researchUploadInfoList.add(uploadInfoObj);
					uploadDataMap.put(uploadObj.id, new List<Research_Upload_Field_Data__c>());
					if (String.isNotBlank(uploadObj.Company_Id__c)) {
						companyIdSet.add(uploadObj.Company_Id__c);
					}
					if (String.isNotBlank(uploadObj.Accountant_Firm_Id__c)) {
						firmIdSet.add(uploadObj.Accountant_Firm_Id__c);
					}
				}

				String key = '';

				if (uploadDataMap.size() > 0) {
					List<Research_Upload_Field_Data__c> tempInfoList = new List<Research_Upload_Field_Data__c>();
					Set<ID> keySet = uploadDataMap.keySet();
					String subQuery = 'SELECT id, Field_Label__c, Field_Value__c, Research_Upload_Info__c FROM Research_Upload_Field_Data__c WHERE Research_Upload_Info__c IN : keySet ';

					if (filterQuestionSet != null && filterQuestionSet.size() > 0) {
						subQuery = subQuery + ' AND Field_Label__c IN : filterQuestionSet AND Field_Value__c IN : filterAnswerSet';
					}

					List<Research_Upload_Field_Data__c> tempUploadedFieldList = Database.query(subQuery);
					for (Research_Upload_Field_Data__c uploadDataObj : tempUploadedFieldList) {
						if (uploadDataMap.containsKey(uploadDataObj.Research_Upload_Info__c)) {
							tempInfoList = uploadDataMap.get(uploadDataObj.Research_Upload_Info__c);
							tempInfoList.add(uploadDataObj);
							uploadDataMap.put(uploadDataObj.Research_Upload_Info__c, tempInfoList);
						}
						if (!fieldLabelSet.contains(uploadDataObj.Field_Label__c)) {
							fieldLabelSet.add(uploadDataObj.Field_Label__c);

							if (!searchLabelSet.contains(uploadDataObj.Field_Label__c)) {
								fieldLabelInfo labelObj = new fieldLabelInfo();
								labelObj.fieldLabel = uploadDataObj.Field_Label__c;
								fieldLabelObj.add(labelObj);
								searchLabelSet.add(uploadDataObj.Field_Label__c);
							}
						}
						key = uploadDataObj.Research_Upload_Info__c + uploadDataObj.Field_Label__c;
						if (string.isNotBlank(uploadDataObj.Field_Value__c)) {
							questionAnsMap.put(key, uploadDataObj.Field_Value__c);
						} else {
							questionAnsMap.put(key, '');
						}
					}
					tempUploadedFieldList.clear();
				}

				String strkey = '';
				for (Research_Upload_Info__c uploadObj : (List<Research_Upload_Info__c>) setCon.getRecords()) {
					for (String label : fieldLabelSet) {
						strkey = uploadObj.id + label;
						if (!questionAnsMap.containsKey(strkey)) {
							questionAnsMap.put(strkey, '');
						}
					}
				}
			}

			//-----------------Selected Contact-----------------------
			for (ContactWrapper ctw : lstSelectedContactWrapper) {
				if (String.isNotBlank(ctw.objAcountZPCompanyId)) {
					companyIdSet.add(ctw.objAcountZPCompanyId);
				}
				if (String.isNotBlank(ctw.objAcountZPFirmId)) {
					firmIdSet.add(ctw.objAcountZPFirmId);
				}
			}
			//-------------------------------------------

			if (companyIdSet.size() > 0 || firmIdSet.size() > 0) {
				List<Account> tempAccountList = [SELECT id, ZP_Firm_ID__c, ZP_Company_ID__c FROM Account WHERE ZP_Firm_ID__c IN :firmIdSet OR ZP_Company_ID__c IN :companyIdSet];
				for (Account accObj : tempAccountList) {
					//Create existing Account Map
					if (String.isNotBlank(accObj.ZP_Company_ID__c)) {
						companyIdWithAccountMap.put(accObj.ZP_Company_ID__c, accObj.id);
					}
					if (String.isNotBlank(accObj.ZP_Firm_ID__c)) {
						firmIdWithAccountMap.put(accObj.ZP_Firm_ID__c, accObj.id);
					}
				}
				tempAccountList.clear();
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
			ExceptionLogUtil.logException('UR_ManageCSVCtrl', 'showResearchUploadInfo', ex.getMessage(), ex.getStackTraceString());
		}

		//Clear Selected Participant Set. Because it will consider in view state.
		clearSelectedParticipantSet();
	}

	// This method upload new csv file.
	public PageReference importCSVFile() {
		PageReference pageRef = null;
		Attachment attachment = null;
		try {
			//Check apex job limit.
			//On CSV upload, two batch will be execute and some records will processed in queue.
			if (UR_UtilityCtrl.checkApexJobLimit(10)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, UR_UtilityCtrl.EXCEED_APEX_JOB_MSG));
				return null;
			}

			String csvName = csvFileName;
			List<Research_Project_Master__c> projectUploadStatus = [SELECT id, CSV_Upload_In_Progress__c, CSV_Delete_In_Progress__c FROM Research_Project_Master__c WHERE Id = :ProjectMasterObj.Id];
			if (csvFileBody == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please upload a CSV in order to perform a search'));
				return null;
			} else if (!csvName.contains('.csv')) {
				csvFileBody = null;
				csvName = '';
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'File must be a CSV in the correct format'));
				return null;
			} else if (projectUploadStatus.size() > 0 && projectUploadStatus[0].CSV_Upload_In_Progress__c) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'CSV Upload request already in-progress. please wait for few minutes.'));
				return null;
			}

			attachment = new Attachment(Body = csvFileBody, Name = csvName, ParentId = ProjectMasterObj.Id);
			insert attachment;

			//Update csv upload status on project object.
			UR_ProjectMasterTriggerHelper.skipTrigger = true;
			ProjectMasterObj.CSV_Upload_In_Progress__c = true;
			ProjectMasterObj.CSV_Delete_In_Progress__c = false;
			ProjectMasterObj.CSV_Error__c = '';
			update ProjectMasterObj;
			UR_ProjectMasterTriggerHelper.skipTrigger = false;

			//Run batch class to process the Attachment record.
			UR_ImportCSVJob batchObj = new UR_ImportCSVJob();
			batchObj.csvFileId = attachment.Id;
			batchObj.projectObjId = ProjectMasterObj.Id;
			Database.executeBatch(batchObj, 2000);

			if (attachment.Id != null) {
				pageRef = new PageReference('/apex/UR_ManageCSV?projectId=' + ProjectMasterObj.Id);
				pageRef.setRedirect(true);
			}
		} catch (Exception ex) {
			csvFileBody = null;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'An error has occured while importing data Please make sure input csv file is correct'));
			ExceptionLogUtil.logException('UR_ManageCSVCtrl', 'importCSVFile', ex.getMessage(), ex.getStackTraceString());
			pageRef = null;
		}
		attachment = null;
		csvFileBody = null;
		return pageRef;
	}

	//Contact Logic Strat
	public list<ContactWrapper> lstSelectedContactWrapper { get; set; }
	public set<String> existingEmailIdSet { get; set; }
	public set<String> existingUserIdSet { get; set; }
	public set<String> existingEmpIdSet { get; set; }

	public void RetriveProjectRecord() {
		//ProjectMasterObj=UR_UtilityCtrl.RetriveProjectDetail(ProjectMasterObj.Id + '');
		List<Research_Project_Master__c> lstReProject = [
			SELECT
				Project_Id__c,
				NDA_URL__c,
				Calendly_EventId__c,
				CreatedDate,
				Customer_Types__c,
				Description__c,
				Id,
				Name,
				Number_of_Participants_to_Add_to_Project__c,
				Number_of_Allowed_Participant__c,
				Survey_Id__c,
				Primary_calendly_URL__c,
				Product_Area__c,
				Project_End_Date__c,
				Project_Start_Date__c,
				Project_Status__c,
				Researcher_Name__c,
				Screener_URL__c,
				Type_of_Research__c,
				CSV_Upload_In_Progress__c,
				CSV_Delete_In_Progress__c,
				Uploaded_CSV_Column__c,
				CSV_Error__c
			FROM Research_Project_Master__c
			WHERE Id = :ProjectMasterObj.Id
		];
		if (lstReProject.size() > 0) {
			ProjectMasterObj = lstReProject[0];
		}

		if (ProjectMasterObj.Id == null) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_InvalidProjectDetail));
		}
	}

	public PageReference checkUploadInprogress() {
		PageReference pageRef = null;
		updateUploadStatus();
		if (String.isBlank(ProjectMasterObj.CSV_Error__c)) {
			// Check uploaded csv records, engaged with any other projects.
			checkResParticipantForOtherProject();
			showResearchUploadInfo(false, true);
			fetchCSVDetails();
		} else {
			pageRef = new PageReference('/apex/UR_ManageCSV?projectId=' + ProjectMasterObj.Id);
			pageRef.setRedirect(true);
		}
		return pageRef;
	}

	public void updateUploadStatus() {
		csvUploadRecordCount = [SELECT COUNT() FROM UXR_CSV_Staging__c WHERE Research_Project_Master__c = :ProjectMasterObj.id AND (Status__c = 'Pending' OR Status__c = 'Processed')];
		for (Research_Project_Master__c uxProjectObj : [
			SELECT id, CSV_Upload_In_Progress__c, CSV_Delete_In_Progress__c, Uploaded_CSV_Column__c, CSV_Error__c
			FROM Research_Project_Master__c
			WHERE Id = :ProjectMasterObj.Id
		]) {
			isUploadInprogress = uxProjectObj.CSV_Upload_In_Progress__c;
			ProjectMasterObj.CSV_Upload_In_Progress__c = uxProjectObj.CSV_Upload_In_Progress__c;
			ProjectMasterObj.CSV_Delete_In_Progress__c = uxProjectObj.CSV_Delete_In_Progress__c;
			ProjectMasterObj.CSV_Error__c = uxProjectObj.CSV_Error__c;
		}
	}

	public void clearSelectedParticipantSet() {
		set_selectedParticipantEmail.clear();
		set_SelectedParticipantUserId.clear();
		set_SelectedParticipantEmpId.clear();
	}

	public void fetchSelectedParticipantDetails() {
		try {
			set_selectedParticipantEmail = new Set<String>();
			set_SelectedParticipantUserId = new Set<String>();
			set_SelectedParticipantEmpId = new Set<String>();

			Id projectId = ProjectMasterObj.id;
			String strQueryString = UR_UtilityCtrl.strProjectDetail + ' WHERE Research_Project_Master__c=:projectId';
			strQueryString = strQueryString + ' ORDER BY ' + selSortbyFieldAPIName + ' ' + selOrderAs + ' NULLS LAST ';

			List<Research_Project_Detail__c> tempProjectDetailList = Database.query(strQueryString);
			for (Research_Project_Detail__c rpd : tempProjectDetailList) {
				if (String.isNotBlank(rpd.Contact__r.Email)) {
					set_selectedParticipantEmail.add(rpd.Contact__r.Email); //This set maintain already selected participant Email Id.
				}
				if (String.isNotBlank(rpd.Contact__r.ZP_User_Id__c)) {
					set_SelectedParticipantUserId.add(rpd.Contact__r.ZP_User_Id__c); //This set maintain already selected participant ZP User ID.
				}
				if (String.isNotBlank(rpd.Contact__r.Employee_Id__c)) {
					set_SelectedParticipantEmpId.add(rpd.Contact__r.Employee_Id__c); //This set maintain already selected participant Employee Id.
				}
			}
			tempProjectDetailList.clear();

			resParticipantCount = set_selectedParticipantEmail.size();
		} catch (Exception ex) {
			ExceptionLogUtil.logException('UR_ManageCSVCtrl', 'fetchSelectedParticipantDetails', ex.getMessage(), ex.getStackTraceString());
		}
	}

	//This method is used to get selected participants from project detail object.
	public void populateSelectedContact(boolean isPageLoad) {
		try {
			updateUploadStatus();
			lstSelectedContactWrapper = new List<ContactWrapper>();
			if (isPageLoad) {
				Id projectId = ProjectMasterObj.id;
				String strQueryString = UR_UtilityCtrl.strProjectDetail + ' WHERE Research_Project_Master__c=:projectId';
				strQueryString = strQueryString + ' ORDER BY ' + selSortbyFieldAPIName + ' ' + selOrderAs + ' NULLS LAST Limit 5000 ';

				setParticipant = new ApexPages.StandardSetController(Database.getQueryLocator(strQueryString));
				setParticipant.setPageSize(PAGE_SIZE);
			}
			for (Research_Project_Detail__c rpd : (List<Research_Project_Detail__c>) setParticipant.getRecords()) {
				ContactWrapper cw = new ContactWrapper();
				cw.objCon = new Contact(Id = rpd.Contact__c, Employee_Id__c = rpd.Contact__r.Employee_Id__c, ZP_User_Id__c = rpd.Contact__r.ZP_User_Id__c, Email = rpd.Contact__r.Email);

				cw.objContactName = rpd.Contact__r.Name;
				cw.objAcountZPCompanyId = rpd.Contact__r.Account.ZP_Company_ID__c;
				cw.objAcountZPFirmId = rpd.Contact__r.Account.ZP_Firm_ID__c;
				cw.objAcountId = rpd.Contact__r.AccountId;
				cw.objAcountName = rpd.Contact__r.Account.Name;

				cw.selContact = false;
				cw.chkDisabled = false;
				//In case of research
				if (rpd.Research_Participant_Status__c != null && rpd.Research_Participant_Status__c != 'Reserved') {
					cw.chkDisabled = true;
				}
				cw.strComment = rpd.Comment__c;
				cw.strPartStatus = rpd.Research_Participant_Status__c;
				cw.projectPartId = rpd.Id;
				lstSelectedContactWrapper.add(cw);
				if (String.isNotBlank(rpd.Contact__r.Email)) {
					existingEmailIdSet.add(rpd.Contact__r.Email);
				}
				if (String.isNotBlank(rpd.Contact__r.ZP_User_Id__c)) {
					existingUserIdSet.add(rpd.Contact__r.ZP_User_Id__c);
				}
				if (String.isNotBlank(rpd.Contact__r.Employee_Id__c)) {
					existingEmpIdSet.add(rpd.Contact__r.Employee_Id__c);
				}
			}
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
			ExceptionLogUtil.logException('UR_ManageCSVCtrl', 'populateSelectedContact', ex.getMessage(), ex.getStackTraceString());
		}
	}

	//Wrapper class to show existing contact on Visual force page.
	public class ContactWrapper {
		public Contact objCon { get; set; }
		public boolean selContact { get; set; }
		public integer noOfQuantativeAttended { get; set; }
		public integer noOfQualitativeAttended { get; set; }
		public string npsScore { get; set; }
		public string strComment { get; set; }
		public string strPartStatus { get; set; }
		public string projectPartId { get; set; }
		public boolean chkDisabled { get; set; }
		public string objContactName { get; set; }
		public string objAcountZPCompanyId { get; set; }
		public string objAcountZPFirmId { get; set; }
		public string objAcountId { get; set; }
		public string objAcountName { get; set; }
	}

	//Throw custom exception.
	public class MaxParticipantLimitException extends Exception {
	}

	// indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	// indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	// returns the page number of the current page set
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	public Integer getTotalRecord() {
		Decimal totalSize = 0;
		if (setCon != null) {
			totalSize = setCon.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
	}

	// return total number of pages for page set
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	// returns the first page of the page set
	public void first() {
		setCon.first();
		resetList();
	}

	// returns the last page of the page set
	public void last() {
		setCon.last();
		resetList();
	}

	// returns the previous page of the page set
	public void previous() {
		setCon.previous();
		resetList();
	}

	// returns the next page of the page set
	public void next() {
		setCon.next();
		resetList();
	}

	public void resetList() {
		showResearchUploadInfo(false, false);
	}

	// This method will called from download csv link
	public PageReference downloadCSV() {
		return Page.UR_SampleCSV;
	}

	//This method redirect us to Project closer screen.
	public PageReference markProjectCompleted() {
		PageReference pageRef = new PageReference('/apex/UR_ProjectCloser?projectId=' + ProjectMasterObj.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method redirect us to search in salsforce screen.
	public PageReference manageParticipant() {
		PageReference pageRef = new PageReference('/apex/UR_ManageContact?projectId=' + ProjectMasterObj.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	//This method checked participants exist with project or not.
	public PageReference CheckParticipant() {
		PageReference pageRef = null;
		Boolean isParticipantExist = UR_UtilityCtrl.participantExistInProject(ProjectMasterObj.Id);
		if (isParticipantExist) {
			pageRef = new PageReference('/apex/UR_ManageParticipant?Id=' + ProjectMasterObj.Id);
			pageRef.setRedirect(true);
		}
		return pageRef;
	}

	//This method send approval request for increase number of paticipants
	public PageReference SendApprovalRequest() {
		try {
			if (string.isNotBlank(extraNOP)) {
				//get number of selected participant detail
				integer partCount = [SELECT COUNT() FROM Research_Project_Detail__c WHERE Research_Project_Master__c = :ProjectMasterObj.Id];
				integer exNop = integer.valueof(extraNOP);
				if (exNop <= 0) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_ApprovalMsg));
					return null;
				}

				//Total number of participant
				exNop = integer.valueof(ProjectMasterObj.Number_of_Allowed_Participant__c) + exNop;
				if (exNop > partCount) {
					//Update project object
					ProjectMasterObj.Number_of_Expected_Participant__c = integer.valueof(extraNOP);
					ProjectMasterObj.Additional_Participant_Status__c = 'In progress';
					ProjectMasterObj.CSV_Delete_In_Progress__c = false;
					ProjectMasterObj.CSV_Upload_In_Progress__c = false;
					update ProjectMasterObj;
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Approval request successfully submitted.'));
					//PageReference pageRef = new PageReference('/apex/UR_ManageCSV?projectId='+ProjectMasterObj.Id+'&orderas=' + orderAs + '&sortby='+sortbyFieldAPIName+'&selorderas=' + selOrderAs + '&selsortby='+selSortbyFieldAPIName);
					return null;
				}
			} else {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_NoOfParticipants));
				return null;
			}

			return null;
		} catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
	}

	//This method reset all filter conditions
	public void resetAll() {
		includeAll = true;
		FirstName = '';
		LastName = '';
		Email = '';
		CompanyId = '';
		UserId = '';
		EmployeeId = '';
		AccountFirmId = '';
		filterQuery = '';
		for (fieldLabelInfo obj : fieldLabelObj) {
			obj.flagValue = '';
		}
		filterQuestionSet.clear();
		filterAnswerSet.clear();
		filterQuery = '';

		checkResParticipantForOtherProject();

		showResearchUploadInfo(false, true);
	}

	//This method delete all the csv files records
	public PageReference deleteResearchUploadInfo() {
		try {
			//Check apex job limit.
			//On delete, two batch will be execute.
			if (UR_UtilityCtrl.checkApexJobLimit(2)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, UR_UtilityCtrl.EXCEED_APEX_JOB_MSG));
				return null;
			}

			//Delete Research_Upload_Info__c records.
			UR_DeleteUploadInfoData deleteBatchObj = new UR_DeleteUploadInfoData();
			deleteBatchObj.projectId = ProjectMasterObj.Id;
			Database.executeBatch(deleteBatchObj, 500);

			ProjectMasterObj.CSV_Upload_In_Progress__c = false;
			ProjectMasterObj.CSV_Delete_In_Progress__c = true;
			update ProjectMasterObj;

			PageReference pageRef = new PageReference(
				'/apex/UR_ManageCSV?projectId=' +
					ProjectMasterObj.Id +
					'&orderas=' +
					orderAs +
					'&sortby=' +
					sortbyFieldAPIName +
					'&selorderas=' +
					selOrderAs +
					'&selsortby=' +
					selSortbyFieldAPIName +
					'&pagesize=' +
					selPageResultStr
			);
			pageRef.setRedirect(true);
			return pageRef;
		} catch (Exception ex) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex + ''));
		}
		return null;
	}

	public void checkResParticipantForOtherProject() {
		String projectIdStr = ProjectMasterObj.Id;
		set_ReserveEmailId = new Set<String>();
		set_ReserveUserId = new Set<String>();
		set_ReserveEmpId = new Set<String>();
		invalidCompanyIdSet = new Set<String>();
		invalidFirmIdSet = new Set<String>();
		Set<String> set_CSVEmail = new Set<String>();
		Set<String> set_CSVUserId = new Set<String>();
		Set<String> set_CSVEmployeeId = new Set<String>();
		//This block of code would be executed, when this method calling from constructor.
		Map<String, List<String>> accountCompanyIdMap = new Map<String, List<String>>();
		Map<String, List<String>> accountFirmIdMap = new Map<String, List<String>>();
		List<Research_Upload_Info__c> tempUploadInfoList = [
			SELECT Email__c, Company_Id__c, Accountant_Firm_Id__c, User_Id__c, Employee_Id__c
			FROM Research_Upload_Info__c
			WHERE Research_Project_Master_Id__c = :projectIdStr AND Excluded_Contact__c = FALSE
		];
		for (Research_Upload_Info__c rsUploadObj : tempUploadInfoList) {
			if (String.isNotBlank(rsUploadObj.Email__c)) {
				set_CSVEmail.add(rsUploadObj.Email__c);
			}
			if (String.isNotBlank(rsUploadObj.User_Id__c)) {
				set_CSVUserId.add(rsUploadObj.User_Id__c);
			}
			if (String.isNotBlank(rsUploadObj.Employee_Id__c)) {
				set_CSVEmployeeId.add(rsUploadObj.Employee_Id__c);
			}
			if (String.isNotBlank(rsUploadObj.Company_Id__c)) {
				invalidCompanyIdSet.add(rsUploadObj.Company_Id__c);
				if (String.isNotBlank(rsUploadObj.Accountant_Firm_Id__c)) {
					if (accountCompanyIdMap.containsKey(rsUploadObj.Company_Id__c)) {
						List<String> accFirmIdList = accountCompanyIdMap.get(rsUploadObj.Company_Id__c);
						accFirmIdList.add(rsUploadObj.Accountant_Firm_Id__c);
						accountCompanyIdMap.put(rsUploadObj.Company_Id__c, accFirmIdList);
					} else {
						List<String> accFirmIdList = new List<String>();
						accFirmIdList.add(rsUploadObj.Accountant_Firm_Id__c);
						accountCompanyIdMap.put(rsUploadObj.Company_Id__c, accFirmIdList);
					}
				}
			}

			if (String.isNotBlank(rsUploadObj.Accountant_Firm_Id__c)) {
				invalidFirmIdSet.add(rsUploadObj.Accountant_Firm_Id__c);
				if (String.isNotBlank(rsUploadObj.Company_Id__c)) {
					if (accountFirmIdMap.containsKey(rsUploadObj.Accountant_Firm_Id__c)) {
						List<String> accCompanyIdList = accountFirmIdMap.get(rsUploadObj.Accountant_Firm_Id__c);
						accCompanyIdList.add(rsUploadObj.Company_Id__c);
						accountFirmIdMap.put(rsUploadObj.Accountant_Firm_Id__c, accCompanyIdList);
					} else {
						List<String> accCompanyIdList = new List<String>();
						accCompanyIdList.add(rsUploadObj.Company_Id__c);
						accountFirmIdMap.put(rsUploadObj.Accountant_Firm_Id__c, accCompanyIdList);
					}
				}
			}
		}
		tempUploadInfoList.clear();

		if (invalidCompanyIdSet.size() > 0 || invalidFirmIdSet.size() > 0) {
			//Check invalid company Id.
			//String objValue = '';
			List<Account> tempAccountList = [SELECT Id, ZP_Company_ID__c, ZP_Firm_ID__c FROM Account WHERE ZP_Company_ID__c IN :invalidCompanyIdSet OR ZP_Firm_ID__c IN :invalidFirmIdSet];
			for (Account accObj : tempAccountList) {
				if (String.isNotBlank(accObj.ZP_Company_ID__c)) {
					if (invalidCompanyIdSet.contains(accObj.ZP_Company_ID__c)) {
						//Remove valid element from [invalidCompanyIdSet] on the basis of ZP_Company_ID__c field value.
						invalidCompanyIdSet.remove(accObj.ZP_Company_ID__c);

						//Remove valid element from [invalidCompanyIdSet] on the basis of ZP_Firm_ID__c field value.
						if (accountCompanyIdMap.containsKey(accObj.ZP_Company_ID__c)) {
							for (String objValue : accountCompanyIdMap.get(accObj.ZP_Company_ID__c)) {
								if (String.isNotBlank(objValue) && invalidFirmIdSet.contains(objValue)) {
									invalidFirmIdSet.remove(objValue);
								}
							}
						}
					}
				}

				if (String.isNotBlank(accObj.ZP_Firm_ID__c)) {
					if (invalidFirmIdSet.contains(accObj.ZP_Firm_ID__c)) {
						//Remove valid element from [invalidFirmIdSet] on the basis of ZP_Firm_ID__c field value.
						invalidFirmIdSet.remove(accObj.ZP_Firm_ID__c);

						//Remove valid element from [invalidFirmIdSet] on the basis of ZP_Company_ID__c field value.
						if (accountFirmIdMap.containsKey(accObj.ZP_Firm_ID__c)) {
							for (String objValue : accountFirmIdMap.get(accObj.ZP_Firm_ID__c)) {
								if (String.isNotBlank(objValue) && invalidCompanyIdSet.contains(objValue)) {
									invalidCompanyIdSet.remove(objValue);
								}
							}
						}
					}
				}
			}
			tempAccountList.clear();
		}

		Id projectId = ProjectMasterObj.id;
		strDaySinceCont = '90';
		if (objResearch != null && objResearch.Days_Since_Last_Contact_High_Limit__c != null) {
			strDaySinceCont = objResearch.Days_Since_Last_Contact_High_Limit__c + '';
		}
		integer daySince = integer.valueof(strDaySinceCont);
		Date modifedDate = Date.today().addDays(-daySince);

		for (Research_Project_Detail__c proDetailObj : [
			SELECT
				Id,
				Research_Project_Master__c,
				Contact__c,
				Contact__r.Email,
				Contact__r.UR_Recent_Project_Completion_date__c,
				Research_Project_Master__r.Project_Status__c,
				Contact__r.ZP_User_Id__c,
				Contact__r.Employee_Id__c
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c != :projectId AND (Contact__r.Email IN :set_CSVEmail OR Contact__r.ZP_User_Id__c IN :set_CSVUserId OR Contact__r.Employee_Id__c IN :set_CSVEmployeeId)
		]) {
			if (
				'Complete' != proDetailObj.Research_Project_Master__r.Project_Status__c ||
				('Complete' == proDetailObj.Research_Project_Master__r.Project_Status__c &&
				proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c != null &&
				proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c > modifedDate)
			) {
				if (String.isNotBlank(proDetailObj.Contact__r.Email)) {
					set_ReserveEmailId.add(proDetailObj.Contact__r.Email);
				}
				if (String.isNotBlank(proDetailObj.Contact__r.ZP_User_Id__c)) {
					set_ReserveUserId.add(proDetailObj.Contact__r.ZP_User_Id__c);
				}
				if (String.isNotBlank(proDetailObj.Contact__r.Employee_Id__c)) {
					set_ReserveEmpId.add(proDetailObj.Contact__r.Employee_Id__c);
				}
			}
		}
	}

	public Set<String> isReservedParticipant(Set<String> set_CSVEmail, Set<String> set_CSVUserId, Set<String> set_CSVEmpId) {
		Id projectId = ProjectMasterObj.id;
		strDaySinceCont = '90';
		if (objResearch != null && objResearch.Days_Since_Last_Contact_High_Limit__c != null) {
			strDaySinceCont = objResearch.Days_Since_Last_Contact_High_Limit__c + '';
		}
		integer daySince = integer.valueof(strDaySinceCont);
		Date modifedDate = Date.today().addDays(-daySince);
		Set<String> set_InvalidEmailId = new Set<String>();
		List<Research_Project_Detail__c> tempProjectDetailList = [
			SELECT
				id,
				Research_Project_Master__c,
				Contact__c,
				Contact__r.Email,
				Contact__r.UR_Recent_Project_Completion_date__c,
				Research_Project_Master__r.Project_Status__c,
				Contact__r.ZP_User_Id__c,
				Contact__r.Employee_Id__c
			FROM Research_Project_Detail__c
			WHERE Research_Project_Master__c != :projectId AND (Contact__r.Email IN :set_CSVEmail OR Contact__r.ZP_User_Id__c IN :set_CSVUserId OR Contact__r.Employee_Id__c IN :set_CSVEmpId)
		];

		for (Research_Project_Detail__c proDetailObj : tempProjectDetailList) {
			if (
				'Complete' != proDetailObj.Research_Project_Master__r.Project_Status__c ||
				('Complete' == proDetailObj.Research_Project_Master__r.Project_Status__c &&
				proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c != null &&
				proDetailObj.Contact__r.UR_Recent_Project_Completion_date__c > modifedDate)
			) {
				set_InvalidEmailId.add(proDetailObj.Contact__r.Email);
			}
		}
		tempProjectDetailList.clear();
		return set_InvalidEmailId;
	}

	// indicates whether there are more records after the current page set.
	public Boolean hasNextParticipant {
		get {
			return setParticipant.getHasNext();
		}
		set;
	}

	// indicates whether there are more records before the current page set.
	public Boolean hasPreviousParticipant {
		get {
			return setParticipant.getHasPrevious();
		}
		set;
	}

	// returns the page number of the current page set
	public Integer pageNumberParticipant {
		get {
			return setParticipant.getPageNumber();
		}
		set;
	}

	public Integer getTotalRecordParticipant() {
		Decimal totalSize = 0;
		if (setParticipant != null) {
			totalSize = setParticipant.getResultSize();
		}
		return (Integer) totalSize.round(System.RoundingMode.CEILING);
	}

	public Integer getTotalPagesParticipant() {
		Decimal totalSize = setParticipant.getResultSize();
		Decimal pageSize = setParticipant.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	public void firstParticipant() {
		setParticipant.first();
		populateSelectedContact(false);
	}

	// returns the last page of the page set
	public void lastParticipant() {
		setParticipant.last();
		populateSelectedContact(false);
	}

	// returns the previous page of the page set
	public void previousParticipant() {
		setParticipant.previous();
		populateSelectedContact(false);
	}

	// returns the next page of the page set
	public void nextParticipant() {
		setParticipant.next();
		populateSelectedContact(false);
	}

	public PageReference addParticipants() {
		PageReference pageRef = null;
		if ('From CSV' == selIncludeParticipant) {
			pageRef = new PageReference('/apex/UR_ManageCSV?projectId=' + ProjectMasterObj.Id);
		} else {
			pageRef = new PageReference('/apex/UR_ManageContact?projectId=' + ProjectMasterObj.Id);
		}
		pageRef.setRedirect(true);
		return pageRef;
	}

	public void sortManageContactList() {
		setSortingFilter();
		prevSortbyFieldAPIName = sortbyFieldAPIName;
		showAll();
	}

	public void setSortingFilter() {
		if (sortbyFieldAPIName != prevSortbyFieldAPIName) {
			orderAs = 'asc';
		} else {
			if ('asc' == orderAs) {
				orderAs = 'desc';
			} else {
				orderAs = 'asc';
			}
		}
	}

	public void selSortManageContactList() {
		selSetSortingFilter();
		selPrevSortbyFieldAPIName = selSortbyFieldAPIName;
		populateSelectedContact(true);
	}

	public void selSetSortingFilter() {
		if (selSortbyFieldAPIName != selPrevSortbyFieldAPIName) {
			selOrderAs = 'asc';
		} else {
			if ('asc' == selOrderAs) {
				selOrderAs = 'desc';
			} else {
				selOrderAs = 'asc';
			}
		}
	}

	public void viewMoreFields() {
		viewContactWrapperObj = lstSelectedContactWrapper[viewRowIndex];
		viewMoreMap = new Map<String, String>();
		for (Research_Project_Detail_Data_Info__c fieldData : [
			SELECT Label__c, Value__c, Research_Project_Detail__c
			FROM Research_Project_Detail_Data_Info__c
			WHERE Research_Project_Detail__c = :viewObjId
		]) {
			if (String.isBlank(fieldData.Value__c)) {
				viewMoreMap.put(fieldData.Label__c, '');
			} else {
				viewMoreMap.put(fieldData.Label__c, fieldData.Value__c);
			}
		}
		for (string key : fieldLabelSet) {
			if (!viewMoreMap.containsKey(key)) {
				viewMoreMap.put(key, '');
			}
		}
	}

	public void resetSearchContactList() {
		resetAll();
	}
}