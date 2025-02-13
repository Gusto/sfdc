/**
 * @name         TaxResCaseMassEmailCtrl
 * @author       Neha Dabas
 * @date         30th July 2020
 * @description  To send mass email to customers based on the cases selected for Large Scale Issues. Controller for TaxResCaseMassEmail page.
 * @test class   TaxResCaseMassEmailCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class TaxResCaseMassEmailCtrl {
	public static final integer INT_MAX_CASE_LIMIT = 500;
	public static final String STR_ERROR_MAX_CASES = 'You cannot select more than 500 cases at a time. Please review your selection.';
	//the selected email template folder
	public String strSelectedEmailFolder { get; set; }
	//the selected email template
	public String strSelectedEmailTemplate { get; set; }
	//List of email template select options from the selected folder
	public List<SelectOption> list_EmailTemplatesByFolderName { get; set; }

	//the list of email templates from the folder
	public List<EmailTemplate> list_EmailTemplates { get; set; }
	//the selected email template
	public EmailTemplate emailTemplateRec { get; set; }
	public List<CaseWrapper> list_CaseWrappers { get; set; }
	public List<SelectOption> list_LargeScaleIssueName { get; set; }
	public String strSelectLSIName { get; set; }
	public List<OrgWideEmailAddress> list_SupportEmailAddress { get; set; }

	//the id of the mass email template folder
	public Id idMassEmailFolder { get; set; }
	//the name of the email template being saved
	public String strMassEmailName { get; set; }
	//the HTML body to save onto new email template
	public String strHtmlBody { get; set; }

	//case search and pagination
	public Case objDummyCaseResolutionEmail { get; set; }

	//public Integer size{get;set;}
	public static final Integer QUERY_LIMIT = 10000;
	public static final Integer PAGE_SIZE = 50;
	public Integer intSelectedCaseIndx { get; set; }
	public Boolean blnSelectAll { get; set; }
	private Id idLoggedInUser;
	public Boolean blnIsMassEmailBatchRunning { get; set; }
	public String strMassEmailMessage { get; set; }

	public ApexPages.StandardSetController setCon_Cases {
		get {
			if (setCon_Cases == null) {
				String strCaseQuery = formCaseQuery();
				if (String.isNotBLank(strCaseQuery)) {
					setCon_Cases = new ApexPages.StandardsetController(Database.getQueryLocator(strCaseQuery));
					// sets the number of records to show in each page view
					setCon_Cases.setPageSize(PAGE_SIZE);
				}
			}
			return setCon_Cases;
		}
		private set;
	}

	private Map<Id, CaseWrapper> map_SelectedCases;
	public Boolean blnOneOrMoreCasesSelected {
		get {
			if (map_SelectedCases == null || map_SelectedCases.size() == 0) {
				return false;
			}
			return true;
		}
	}
	/*Constructor*/
	public TaxResCaseMassEmailCtrl() {
		idLoggedInUser = userInfo.getUserId();
		checkIsBatchRunning();
		initializeData();
	}

	public void checkIsMassEmailBatchRunning() {
		checkIsBatchRunning();
		fetchLSICases();
	}

	public void checkIsBatchRunning() {
		List<Batch_Email_Settings__c> list_BatchEmailSetting = UtilitiesFactory.fetchBatchEmailSettings(idLoggedInUser);
		if (list_BatchEmailSetting.size() > 0 && list_BatchEmailSetting[0].id != null) {
			blnIsMassEmailBatchRunning = list_BatchEmailSetting[0].Running_Mass_Email_Batch__c;
			strMassEmailMessage = list_BatchEmailSetting[0].Mass_Email_Status_Message__c;
		} else {
			blnIsMassEmailBatchRunning = false;
			strMassEmailMessage = '';
		}
	}

	//On click of close icon this method will execute.
	public void clearMassEmailMessage() {
		TaxResCaseMassEmailCtrl.saveMassEmailStatus(idLoggedInUser, false, '');
		strMassEmailMessage = '';
	}

	public void fetchLSICases() {
		map_SelectedCases = new Map<Id, CaseWrapper>();
		setCon_Cases = null;
		initializeCaseWrapper();
	}

	private void initializeData() {
		list_CaseWrappers = new List<CaseWrapper>();
		list_EmailTemplatesByFolderName = new List<SelectOption>();
		list_EmailTemplates = new List<EmailTemplate>();
		list_SupportEmailAddress = GlobalQueryHelper.getOrgWideEmailByAdd('support@gusto.com');
		strMassEmailName = '';

		objDummyCaseResolutionEmail = new Case(RecordTypeId = Cache.getRecordTypeId('Case', 'Tax Res'), Type = 'Tax Res', Customer_Journey__c = 'Large Scale Issue');

		long long10DaysInMilliSecond = 10 * 8 * 60 * 60 * 1000;
		BusinessHours objBusinessHour = GlobalQueryHelper.getDefaultBusinessHour();
		Datetime dtTenWorkingDaysFromToday;
		if (objBusinessHour != null) {
			dtTenWorkingDaysFromToday = BusinessHours.add(objBusinessHour.Id, system.now(), long10DaysInMilliSecond);
		} else {
			dtTenWorkingDaysFromToday = system.now().addDays(10);
		}
		objDummyCaseResolutionEmail.Next_Steps__c = 'Next Response by ' + dtTenWorkingDaysFromToday.month() + '/' + dtTenWorkingDaysFromToday.day();

		fetchLargeScaleIssues();
	}
	private void fetchLargeScaleIssues() {
		list_LargeScaleIssueName = new List<SelectOption>();
		strSelectLSIName = '';

		//@Neha Dabas 21-Sept-2020, Exclude Done and Rejected LSIs
		Set<String> set_InvalidLSIStatus = new Set<String>{ 'Done', 'Reject' };
		for (Large_Scale_Issue__c objLSI : [SELECT Name FROM Large_Scale_Issue__c WHERE Status__c NOT IN :set_InvalidLSIStatus ORDER BY Name]) {
			list_LargeScaleIssueName.add(new SelectOption(objLSI.Id, objLSI.Name));

			if (String.isBlank(strSelectLSIName)) {
				strSelectLSIName = objLSI.Id;
			}
		}
		fetchLSICases();
	}
	private String formCaseQuery() {
		if (String.isBlank(strSelectLSIName)) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select Large Scale Issue.'));
			return '';
		}
		Set<String> set_ValidCaseRecTypes = new Set<String>{ 'Tax Res' };
		Set<String> set_StatusToExclude = new Set<String>{ 'Closed' };
		String strCaseQuery = 'SELECT LSI_Mass_Emails_Sent__c,Contact.Email,Agency_Information__c,Next_Steps__c,Mass_Email_Step__c,CaseNumber,Subject,Customer_Responses_Since_Last_Update__c,Contact.Name,ContactId,Days_since_last_email_to_customer__c,Type,Status FROM Case';
		String strWhereClause =
			' WHERE Large_Scale_Issue_Classification__c = :strSelectLSIName AND RecordType.Name = \'Tax Res\' AND Status != \'Closed\' AND Status != \'Solved\' AND ContactId != NULL AND OwnerId = \'' +
			idLoggedInUser +
			'\'';

		strCaseQuery += strWhereClause + ' ORDER BY LastModifiedDate Desc LIMIT :QUERY_LIMIT ';

		return strCaseQuery;
	}
	//indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			return setCon_Cases.getHasNext();
		}
		set;
	}

	//indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			return setCon_Cases.getHasPrevious();
		}
		set;
	}

	//returns the page number of the current page set
	public Integer pageNumber {
		get {
			return setCon_Cases.getPageNumber();
		}
		set;
	}

	//return total number of pages for page set
	public Integer getTotalPages() {
		Decimal decTotalSize = setCon_Cases.getResultSize();
		Decimal decPageSize = setCon_Cases.getPageSize();
		Decimal decPages = decTotalSize / decPageSize;
		return (Integer) decPages.round(System.RoundingMode.CEILING);
	}

	//returns the first page of the page set
	public void first() {
		setCon_Cases.first();
		initializeCaseWrapper();
	}

	//returns the last page of the page set
	public void last() {
		setCon_Cases.last();
		initializeCaseWrapper();
	}

	//returns the previous page of the page set
	public void previous() {
		setCon_Cases.previous();
		initializeCaseWrapper();
	}

	//returns the next page of the page set
	public void next() {
		setCon_Cases.next();
		initializeCaseWrapper();
	}
	//init accounts
	public void initializeCaseWrapper() {
		list_CaseWrappers = new List<CaseWrapper>();

		Integer indx = 0;
		Boolean blnAllCasesForCurrentViewSelected = true;
		for (Case objCase : (List<Case>) setCon_Cases.getRecords()) {
			if (map_SelectedCases != null && map_SelectedCases.containsKey(objCase.id)) {
				list_CaseWrappers.add(new CaseWrapper(objCase, true, indx));
			} else {
				list_CaseWrappers.add(new CaseWrapper(objCase, false, indx));
				if (blnAllCasesForCurrentViewSelected) {
					blnAllCasesForCurrentViewSelected = false;
				}
			}
			indx++;
		}
		if (blnAllCasesForCurrentViewSelected) {
			blnSelectAll = true;
		} else {
			blnSelectAll = false;
		}
	}
	public void selectUnselectAllCase() {
		if (null != list_CaseWrappers && list_CaseWrappers.size() > 0) {
			for (CaseWrapper objSelectedCase : list_CaseWrappers) {
				if (blnSelectAll && !map_SelectedCases.containsKey(objSelectedCase.objCase.Id)) {
					if (map_SelectedCases.size() < INT_MAX_CASE_LIMIT) {
						map_SelectedCases.put(objSelectedCase.objCase.Id, objSelectedCase);
					} else {
						ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, STR_ERROR_MAX_CASES));
						break;
					}
				} else if (!blnSelectAll && map_SelectedCases.containsKey(objSelectedCase.objCase.Id)) {
					map_SelectedCases.remove(objSelectedCase.objCase.Id);
				}

				objSelectedCase.blnSelected = blnSelectAll;
			}
		}
	}
	// to maintain the case selection across pages
	public void selectCase() {
		if (null != list_CaseWrappers && list_CaseWrappers.size() > intSelectedCaseIndx) {
			CaseWrapper objSelectedCase = list_CaseWrappers[intSelectedCaseIndx];

			//deselect case
			if (!objSelectedCase.blnSelected && map_SelectedCases.containsKey(objSelectedCase.objCase.Id)) {
				map_SelectedCases.remove(objSelectedCase.objCase.Id);
			} else if (objSelectedCase.blnSelected) {
				//select case
				if (null == map_SelectedCases)
					map_SelectedCases = new Map<Id, CaseWrapper>();
				else if (map_SelectedCases.size() == INT_MAX_CASE_LIMIT) {
					objSelectedCase.blnSelected = false;
					ApexPages.addmessage(new ApexPages.message(ApexPages.Severity.ERROR, STR_ERROR_MAX_CASES));
					return;
				}
				map_SelectedCases.put(objSelectedCase.objCase.Id, objSelectedCase);
			}
		}
	}
	//Get email template folders. Mass Email Template will be first
	public List<SelectOption> getEmailTemplateFolderOpts() {
		List<SelectOption> list_Opts = new List<SelectOption>();
		list_Opts.add(new SelectOption('--None--', '--None--'));
		//Folder fldrMassEmail = [SELECT Id, Name FROM Folder WHERE Name = 'Large Scale Issue Mass Email'];
		//idMassEmailFolder = fldrMassEmail.Id;
		//list_Opts.add(new SelectOption(fldrMassEmail.Id, fldrMassEmail.Name));

		List<SelectOption> list_OtherOpts = new List<SelectOption>();
		for (Folder objfolder : [SELECT Id, Name FROM Folder WHERE Name = 'Large Scale Issue Mass Email' OR Type = 'Email' ORDER BY Name ASC]) {
			if (objfolder.Name != 'Large Scale Issue Mass Email') {
				list_OtherOpts.add(new SelectOption(objfolder.Id, objfolder.Name));
			}
			if (objfolder.Name == 'Large Scale Issue Mass Email') {
				list_Opts.add(new SelectOption(objfolder.Id, objfolder.Name));
				idMassEmailFolder = objfolder.Id;
			}
		}

		//On UI, we are showing the folder as: 'Large Scale Issue Mass Email' --> Others folder order by Name -->'Unfiled Public Classic Email Templates'
		//That's why we are using list_OtherOpts.
		list_Opts.addAll(list_OtherOpts);
		list_OtherOpts.clear();

		list_Opts.add(new SelectOption(UserInfo.getOrganizationId(), 'Unfiled Public Classic Email Templates'));
		return list_Opts;
	}
	/*
        Assigns emailTemplateRec the selected Email Template from strSelectedEmailTemplate
    */
	public void displayEmailTemplate() {
		if (list_EmailTemplates.size() > 0 && strSelectedEmailTemplate != '' && strSelectedEmailTemplate != '--None--') {
			EmailTemplate eTemplate = [
				SELECT Id, Name, Subject, FolderId, BrandTemplateId, TemplateStyle, DeveloperName, Encoding, HtmlValue, Body
				FROM EmailTemplate
				WHERE Id = :strSelectedEmailTemplate
			];
			emailTemplateRec = eTemplate;
			if (String.isNotBlank(emailTemplateRec.HTMLValue)) {
				strHtmlBody = emailTemplateRec.HTMLValue;
			} else {
				strHtmlBody = emailTemplateRec.Body;
			}

			strMassEmailName = emailTemplateRec.Name;
		}
	}

	public void queryTemplates() {
		List<SelectOption> list_TemplateSelect = new List<SelectOption>();
		List<EmailTemplate> list_Template = new List<EmailTemplate>();
		List<EmailTemplate> list_QueriedTemplates = [SELECT Id, Name, Description FROM EmailTemplate WHERE FolderId = :strSelectedEmailFolder ORDER BY Name ASC];

		for (EmailTemplate f : list_QueriedTemplates) {
			if (f.Description == null) {
				list_TemplateSelect.add(new SelectOption(f.Id, f.Name));
			} else
				list_TemplateSelect.add(new SelectOption(f.Id, f.Description));
		}

		list_EmailTemplates.addAll(list_QueriedTemplates);
		list_EmailTemplatesByFolderName.add(new SelectOption('--None--', '--None--'));
		list_EmailTemplatesByFolderName.addAll(selectOptionSortByLabel(list_TemplateSelect));
	}
	/*
        @Param:List of selectOption to be sort.
        @Return: Sorted list of selectOptions by Label
    */
	public List<SelectOption> selectOptionSortByLabel(List<SelectOption> list_SelectOptionsToSort) {
		if (list_SelectOptionsToSort == null || list_SelectOptionsToSort.size() <= 1) {
			return list_SelectOptionsToSort;
		}
		List<SelectOption> list_LessSelectOption = new List<SelectOption>();
		List<SelectOption> list_GreaterSelectOption = new List<SelectOption>();
		Integer intPivot = list_SelectOptionsToSort.size() / 2;

		//save the pivot and remove it from the selectOption list
		SelectOption pivotValue = list_SelectOptionsToSort[intPivot];
		list_SelectOptionsToSort.remove(intPivot);
		for (SelectOption so : list_SelectOptionsToSort) {
			if (so.getLabel() <= pivotValue.getLabel()) {
				list_LessSelectOption.add(so);
			} else if (so.getLabel() > pivotValue.getLabel()) {
				list_GreaterSelectOption.add(so);
			}
		}
		List<SelectOption> list_SortedSelectOptions = new List<SelectOption>();
		list_SortedSelectOptions.addAll(selectOptionSortByLabel(list_LessSelectOption));
		list_SortedSelectOptions.add(pivotValue);
		list_SortedSelectOptions.addAll(selectOptionSortByLabel(list_GreaterSelectOption));
		return list_SortedSelectOptions;
	}
	/*
        This method is to fetch the email templates according to the email folder selected on page
    */
	public void fetchEmailTemplatesByFolderName() {
		list_EmailTemplatesByFolderName = new List<SelectOption>();
		list_EmailTemplates = new List<EmailTemplate>();
		if (String.isNotBlank(strSelectedEmailFolder)) {
			queryTemplates();
			emailTemplateRec = null;
			strSelectedEmailTemplate = '';
			strHtmlBody = null;
		}
	}
	/*
        Sends emails from the support@gusto org wide email address
        creates an email message record on the case(s)
    */
	public void sendEmail() {
		try {
			if (!validateCaseAndEmailSelections()) {
				return;
			}

			Map<String, String> map_FieldToUpdate = identifyFieldsToBeUpdatedOnCase();
			Set<Id> set_CasesToUpdate = new Set<Id>();
			for (CaseWrapper cw : map_SelectedCases.values()) {
				set_CasesToUpdate.add(cw.objCase.Id);
			}
			if (set_CasesToUpdate.size() > 0) {
				//Call Batch Class to send the email and update the case records.
				TaxResCaseMassEmailBatch objBatch = new TaxResCaseMassEmailBatch();
				objBatch.map_FieldToUpdate = map_FieldToUpdate;
				objBatch.set_CasesToUpdate = set_CasesToUpdate;
				objBatch.idSelectedEmailTemplate = emailTemplateRec.Id;
				objBatch.idBatchRunByUser = idLoggedInUser;
				Database.executeBatch(objBatch, 50);

				//set "Running Mass Email Batch?" flag as True on custom setting(Batch Email Settings)
				TaxResCaseMassEmailCtrl.saveMassEmailStatus(idLoggedInUser, true, '');
				blnIsMassEmailBatchRunning = true;

				//ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Email sending has been initiated in the backgroud.'));
			}
		} catch (Exception objExcep) {
			ExceptionLogUtil.logException('TaxResCaseMassEmailCtrl', 'sendEmail', objExcep.getMessage() + '  ' + objExcep.getStackTraceString(), 'high');
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, objExcep.getMessage() + '  ' + objExcep.getStackTraceString()));
			UtilitiesFactory.sendExceptionEmail(objExcep, 'Send Mass Email Failure', 'Login user id : ' + idLoggedInUser);
		}
	}

	private Map<String, String> identifyFieldsToBeUpdatedOnCase() {
		Map<String, String> map_FieldsToBeUpdated = new Map<String, String>();
		map_FieldsToBeUpdated.put('Mass_Email_Step__c', objDummyCaseResolutionEmail.Mass_Email_Step__c);
		if (objDummyCaseResolutionEmail.Mass_Email_Step__c.equalsIgnoreCase('Resolution')) {
			map_FieldsToBeUpdated.put('Next_Steps__c', '');
		} else {
			map_FieldsToBeUpdated.put('Next_Steps__c', objDummyCaseResolutionEmail.Next_Steps__c);
		}

		return map_FieldsToBeUpdated;
	}

	private Boolean validateCaseAndEmailSelections() {
		if (map_SelectedCases == null || map_SelectedCases.size() == 0) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Please select some cases to proceed.'));
			return false;
		}
		if (emailTemplateRec == null) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Please select an email template to proceed.'));
			return false;
		}
		if (String.isBlank(objDummyCaseResolutionEmail.Mass_Email_Step__c)) {
			ApexPages.AddMessage(new ApexPages.Message(ApexPAges.Severity.ERROR, 'Please select Mass Email Step to proceed.'));
			return false;
		}
		return true;
	}

	/*Case Wrapper class*/
	public class CaseWrapper {
		//to see if the Case has been selected to send an email to
		public Boolean blnSelected { get; set; }
		//the Case record
		public Case objCase { get; set; }

		public Integer indx { get; set; }
		/*Constructor*/
		public CaseWrapper(Case objCase, Boolean blnSelected, Integer intIndex) {
			this.objCase = objCase;
			this.blnSelected = blnSelected;
			this.indx = intIndex;
		}
	}

	public static void saveMassEmailStatus(Id idLoggedInUser, boolean blnBatchRunning, String strMessage) {
		try {
			if (idLoggedInUser != null) {
				List<Batch_Email_Settings__c> list_BatchEmailSetting = UtilitiesFactory.fetchBatchEmailSettings(idLoggedInUser);
				if (list_BatchEmailSetting.size() > 0) {
					list_BatchEmailSetting[0].Running_Mass_Email_Batch__c = blnBatchRunning;
					list_BatchEmailSetting[0].Mass_Email_Status_Message__c = strMessage;
					upsert list_BatchEmailSetting;
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('TaxResCaseMassEmailCtrl', 'saveMassEmailStatus', ex.getMessage(), ex.getStackTraceString());
		}
	}
}