public class DisplayEditTTSExt {
	public Map<String, Map<String, List<String>>> map_ParentChildFieldsWithValues { get; set; }
	public Map<String, String> map_ChildToParentMapping { get; set; }
	public Map<String, String> map_ParentChildAPIFields { get; set; }
	public Map<String, String> map_ParentChildLabelFields { get; set; }
	public String strChild { get; set; }
	public String strParentRecord { get; set; }
	public String strChildRecord { get; set; }
	public List<String> list_Values { get; set; }
	public static Id LOGGED_IN_USER = UserInfo.getUserId();
	public Transition_to_Fulfillment__c objTTSRecord { get; set; }
	public Transition_to_Fulfillment__c ttfbrecord { get; set; }
	public List<Master_Company_Level_Documents__c> lstMasterCLD { get; set; }
	public List<Company_Level_Documents__c> lstChildCLD { get; set; }
	public Integer rowNum;
	public Integer selectedRowIndex { get; set; }
	public List<MasterCLDwrapper> lstMasterCLDWrapper { get; set; }
	public QA_Sheet__c QAObj { get; set; }
	public List<QA_Lines_Of_Coverage__c> lstQALinesOfCoverage { get; set; }
	public List<QA_Lines_Of_Coverage__c> QALinesOfCoverage { get; set; }
	public Boolean bool { get; set; }
	public List<SelectOption> firstList { get; set; }
	public List<SelectOption> secondList { get; set; }
	public List<Benefit_Order__c> list_RelatedBOs { get; set; }
	public String StrParam { get; set; }
	public String accCompanyId { get; set; }
	public String scriptvar { get; set; }
	public Boolean chkErrors = false;
	public Boolean blnShowAttachmentSection { get; set; }
	//key QA line Id value Set<FieldsName>
	public Map<Id, Set<String>> map_TTQAsPerCOOrderAssignement { get; set; }

	public String tastring { get; set; }
	public List<Transition_to_Fulfillment__c> lstTTSExisting;
	Id CurrentRecId;
	public Boolean blnPageReadOnly { get; set; }

	// Set of TTS Text Area Field
	Set<String> set_TTSTextAreaFields = new Set<String>{
		'List_of_plans_removed__c',
		'List_of_New_Hire_Names_to_be_included__c',
		'Anticipated_pending_items_anything_inte__c'
	};
	// Set of QA Line Text Area Field
	Set<String> set_QALinesTextAreaFields = new Set<String>{
		'Documents_Require_for_Submission__c',
		'Participation_Requirements__c',
		'Plan_changes__c',
		'Waiting_Period_change__c',
		'Contribution_change__c'
	};

	//Carrier Order having TAdA: No Pre OE Setup and TAdA: Pre OE Setup
	public Boolean isTadaNotesToBeDisplayed { get; set; }
	//Carrier Order having Carrier Switch with Same Plan And Same no Plan
	public Boolean isCarrierSwitchWithSamePlan { get; set; }

	//Key is Id/ObjName and value is Map<FieldAPINAme,Rowcount>
	public Map<String, Map<String, Integer>> map_RowCountTextArea { get; set; }

	public Boolean isChecked { get; set; }
	//key QA Line Id,  Value True/False
	public Map<Id, Boolean> map_ShowTTQForQALine { get; set; }
	//Key API Field Name, Value Field Label
	public Map<String, String> map_FieldAPILabel { get; set; }
	//DS[16-09-2020]
	public Set<String> set_OrderAssignment = OrderUtils.set_OrderAssignment;

	//Neha Dabas Aug 31,2020 : Add Rating Structure Change if there is a Medical Line of Coverage with Blue Shield of CA as Carrier
	public Boolean bln_BSCAMedicalForRenewal { get; set; }

	//DS[30-09-2020]: Status should not be changed if the Implementation stage is Ready for confirmation,
	//pending confirmaiton, submission prep, approved or approved pending ee audit
	public Set<String> set_ExcluededImplementationStage = new Set<String>{ 'Ready for Confirmation', 'Pending Confirmation', 'Submission Prep', 'Approved Pending EE Audit', 'Approved', 'Canceled' };
	// TTS configuration changes
	public Map<String, List<TTSFieldsWrapper>> map_SectionHeaderAndFields { get; set; }
	public Company_Level_Documents__c objCLD { get; set; }
	public QA_Lines_Of_Coverage__c objQALineOfCoverage { get; set; }
	public String strApplicationId;
	public String strCompanyId;
	public Set<String> set_DiffLayoutFields = new Set<String>();
	public Map<String, Boolean> map_SectionHeaderWithSameLayout { get; set; }
	public Map<String, TTSFieldsWrapper> map_CompanyLevelDocumentsFields { get; set; }
	public HIGroupEventTTSNotePostOEEmailJSON objHIGroupEventTTSNotePostOEEmailJSON;
	public HIQaSheetWrapper objHIQaSheetWrapper;
	Map<String, List<String>> map_ObjectAPIAndRequiredFieldAPI = new Map<String, List<String>>();
	public List<String> list_SectionHeaderWithOrder { get; set; }
	Map<String, String> map_FieldAPIAndLabel = new Map<String, String>();
	Boolean blnSubmissionAdvocateUser;
	public boolean blnShowBankInformation { get; set; }
	public Boolean blnIsDocRequired;

	public DisplayEditTTSExt(ApexPages.StandardController controller) {
		list_Values = new List<String>();
		strChild = '';
		strParentRecord = '';
		strChildRecord = '';
		map_ParentChildFieldsWithValues = new Map<String, Map<String, List<String>>>();
		map_ParentChildAPIFields = new Map<String, String>();
		map_ChildToParentMapping = new Map<String, String>();
		map_ParentChildLabelFields = new Map<String, String>();
		objCLD = new Company_Level_Documents__c();
		objQALineOfCoverage = new QA_Lines_Of_Coverage__c();
		map_SectionHeaderAndFields = new Map<String, List<TTSFieldsWrapper>>();
		strCompanyId = '';
		strApplicationId = '';
		set_DiffLayoutFields.add('Do_they_have_affiliates__c');

		map_SectionHeaderWithSameLayout = new Map<String, Boolean>();
		map_SectionHeaderWithSameLayout.put(TransitiontoFulfilmentUtil.COMPANY_LEVEL_DOCUMENTS, false);
		map_SectionHeaderWithSameLayout.put(TransitiontoFulfilmentUtil.CENSUS_SECTION_HEADER, false);
		map_SectionHeaderWithSameLayout.put(TransitiontoFulfilmentUtil.PLOICY_DETAILS_DENTAL_SECTION_HEADER, false);
		map_SectionHeaderWithSameLayout.put(TransitiontoFulfilmentUtil.PLOICY_DETAILS_LIDI_SECTION_HEADER, false);
		map_SectionHeaderWithSameLayout.put(TransitiontoFulfilmentUtil.PLOICY_DETAILS_MEDICAL_SECTION_HEADER, false);

		map_CompanyLevelDocumentsFields = new Map<String, TTSFieldsWrapper>();

		blnSubmissionAdvocateUser = false;
		blnShowBankInformation = false;
		blnIsDocRequired = true;

		tastring = '';
		ttfbrecord = new Transition_to_Fulfillment__c();
		lstTTSExisting = new List<Transition_to_Fulfillment__c>();
		map_TTQAsPerCOOrderAssignement = new Map<Id, Set<String>>();
		map_FieldAPILabel = new Map<String, String>();
		map_ShowTTQForQALine = new Map<Id, Boolean>();

		CurrentRecId = ApexPages.currentPage().getParameters().get('BOid');
		Schema.SObjectType objectType = QA_Sheet__c.getSObjectType();

		List<String> qafields = new List<String>(objectType.getDescribe().fields.getMap().keySet());
		Schema.SObjectType ttfobjectType = Transition_to_Fulfillment__c.getSObjectType();
		List<String> ttffields = new List<String>(ttfobjectType.getDescribe().fields.getMap().keySet());
		Id TTFQBcRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Id TTFQBnpRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits New Plan');
		Id TTFQBrRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Renewal');
		Id qanewRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
		Id qaRenewalRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Renewal');
		Id qaChangeRecType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit Change');
		Id ttfSubmissionNewRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
		Id ttfSubmissionRenwChangeRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');

		if (CurrentRecId == null) {
			return;
		}

		// TTS configuration changes
		String strSoql =
			'SELECT ' +
			String.join(qafields, ',') +
			' ,Benefit_Order__r.Has_TADA__c, Benefit_Order__r.UW_Owner__c,' +
			' Benefit_Order__r.Submission_Deadline__c,' +
			' Benefit_Order__r.Recordtype.DeveloperName,' +
			' Benefit_Order__r.Type__c,' +
			' Recordtype.DeveloperName,' +
			' Benefit_Order__r.Opportunity__c,' +
			' Benefit_Order__r.Application_Id__c,' +
			' Benefit_Order__r.Id,' +
			' Benefit_Order__r.Ownerid,' +
			' Benefit_Order__r.Opportunity__r.Accountid,' +
			' Benefit_Order__r.Opportunity__r.Ownerid,' +
			' Benefit_Order__r.Opportunity__r.Account.ZP_Company_ID__c,' +
			' Carrier_Order__r.HI_Carrier_Id__c' +
			' From QA_Sheet__c WHERE Benefit_Order__c = :CurrentRecId' +
			' ORDER BY CreatedDate DESC LIMIT 1';

		QAObj = Database.query(strSoql);
		id oppid;
		id accid;
		if (QAObj != null) {
			oppid = QAObj.Benefit_Order__r.Opportunity__c;
			accid = QAObj.Benefit_Order__r.Opportunity__r.Accountid;
			accCompanyId = QAObj.Benefit_Order__r.Opportunity__r.Account.ZP_Company_ID__c;
			strCompanyId = accCompanyId;
			strApplicationId = QAObj.Benefit_Order__r.Application_Id__c;
		}

		if (String.isNotBLank(strCompanyId) && String.isNotBLank(strApplicationId)) {
			Boolean blnTTSEvent = false;
			Boolean blnQAEvent = false;

			for (HIGroupEvent__c objHIGroupEvent : [
				SELECT Id, Event_type__c, Event_Info__c
				FROM HIGroupEvent__c
				WHERE
					Event_type__c IN :TransitiontoFulfilmentUtil.set_EventsType
					AND Application_Id__c = :strApplicationId
					AND Company_Id__c = :strCompanyId
					AND Processing_State__c = :TransitiontoFulfilmentUtil.LABEL_PROCESSED
				ORDER BY LastModifiedDate DESC
			]) {
				if (blnTTSEvent && blnQAEvent) {
					break;
				}

				if (objHIGroupEvent.Event_type__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.LABEL_TTS_POST_OE_EMAIL) && !blnTTSEvent) {
					objHIGroupEventTTSNotePostOEEmailJSON = (HIGroupEventTTSNotePostOEEmailJSON) JSON.deserialize(objHIGroupEvent.Event_Info__c, HIGroupEventTTSNotePostOEEmailJSON.class);
					blnTTSEvent = true;
				}

				if (objHIGroupEvent.Event_type__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.LABEL_QA_SHEET_INFO) && !blnQAEvent) {
					objHIQaSheetWrapper = (HIQaSheetWrapper) JSON.deserialize(objHIGroupEvent.Event_Info__c, HIQaSheetWrapper.class);
					for (HIQASheetWrapper.QALineOfCoverageWrapper objQlWrapper : objHIQaSheetWrapper.qual_loc_data) {
						if (objQlWrapper.documents_required_oa == null || objQlWrapper.documents_required_oa.isEmpty()) {
							blnIsDocRequired = false;
						}
					}

					blnQAEvent = true;
				}
			}
		}
		List<Carrier_Order__c> list_CarrierOrders = new List<Carrier_Order__c>();

		for (User objUser : [SELECT Id, Name, UserRole.Name FROM User WHERE Id = :LOGGED_IN_USER AND UserRole.Name = :TransitiontoFulfilmentUtil.SUBMISSION_ADVOCATE]) {
			blnSubmissionAdvocateUser = true;
		}

		if (QAObj.Benefit_Order__c != null) {
			Boolean blnIsLoggedInUserSubmission = false;
			list_CarrierOrders = [SELECT Id, OwnerId, Order_Assignment__c, Order_Type__c, Carrier__c, Carrier__r.Name FROM Carrier_Order__c WHERE Benefit_Order__c = :QAObj.Benefit_Order__c];

			for (Carrier_Order__c objCO : list_CarrierOrders) {
				if (objCO.OwnerId == LOGGED_IN_USER) {
					blnIsLoggedInUserSubmission = true;
				}
			}

			if (QAObj.Benefit_Order__r.UW_Owner__c == LOGGED_IN_USER || QAObj.Benefit_Order__r.OwnerId == LOGGED_IN_USER || blnIsLoggedInUserSubmission || blnSubmissionAdvocateUser) {
				blnPageReadOnly = false;
			} else {
				blnPageReadOnly = true;
			}
		}

		//if TTS record already exists fetch the same record and display data
		//BY:PR, Date:OCT-7-2020, Desc:introduce if codition and string variable
		String strTTFsoql = '';
		String strWHERETTFsoql = '';

		if (String.isNotBlank(CurrentRecId) || oppid != null) {
			strTTFsoql = 'select ' + String.join(ttffields, ',') + ',Account__r.Anchor_Pay_Date__c,Account__r.id from Transition_to_Fulfillment__c ';
			strWHERETTFsoql = ' where ((Opportunity__c =: oppid AND Opportunity__c !=null) OR Benefit_Order__c=:CurrentRecId) and (recordtypeid =: ttfSubmissionNewRecType  or recordtypeid =: ttfSubmissionRenwChangeRecType)';
			lstTTSExisting = Database.query(strTTFsoql + strWHERETTFsoql);
		}

		if (lstTTSExisting.size() > 0) {
			objTTSRecord = lstTTSExisting[0];
			bool = true;
		} else {
			objTTSRecord = new Transition_to_Fulfillment__c();
		}

		if (QAObj != null && lstTTSExisting.size() == 0) {
			if (QAObj.recordtypeid == qanewRecType)
				objTTSRecord.recordtypeid = ttfSubmissionNewRecType;
			else if (QAObj.recordtypeid == qaRenewalRecType || QAObj.recordtypeid == qaChangeRecType)
				objTTSRecord.recordtypeid = ttfSubmissionRenwChangeRecType;
			objTTSRecord.Benefit_Order__c = CurrentRecId;
			objTTSRecord.Opportunity__c = QAObj.Benefit_Order__r.Opportunity__c;
			objTTSRecord.Account__c = QAObj.Benefit_Order__r.Opportunity__r.Accountid;
			objTTSRecord.Benefit_Advisor__c = QAObj.Benefit_Order__r.Opportunity__r.ownerid;
			objTTSRecord.Implementation_Advocate__c = QAObj.Benefit_Order__r.ownerid;

			if (QAObj.Benefit_Order__r.Type__c == TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_TO_GUSTO) {
				objTTSRecord.DBA__c = QAObj.DBA__c;
			}

			objTTSRecord.Date_Established__c = QAObj.Date_Established__c;
			objTTSRecord.Eligible_SIC_Code__c = QAObj.SIC_Code__c;
			objTTSRecord.Industry__c = QAObj.Industry__c;
			objTTSRecord.Successor_predecessor_plan_codes_and_nam__c = QAObj.Successor_predecessor_plan_codes_and_nam__c;
		}
		//Display some fields if the Order type is Same Carrier, Plan or Same Carrier, No plan with CO Carrier Switch
		isCarrierSwitchWithSamePlan = false;

		if (QAObj.Benefit_Order__c != null) {
			isTadaNotesToBeDisplayed = QAObj.Benefit_Order__r.Has_TADA__c;

			if (
				!list_CarrierOrders.isEmpty() &&
				(QAObj.Benefit_Order__r.Type__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.CO_ORDER_TYPE_SAME_GROUP_LEVEL) ||
				QAObj.Benefit_Order__r.Type__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.CO_ORDER_TYPE_SAME_NO_GROUP_LEVEL))
			) {
				for (Carrier_Order__c objCO : list_CarrierOrders) {
					if (
						objCO.Order_Assignment__c != null &&
						(objCO.Order_Assignment__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.CO_ORDER_TYPE_CARRIER_SWITCH) ||
						objCO.Order_Assignment__c?.equalsIgnoreCase(TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE))
					) {
						isCarrierSwitchWithSamePlan = true;
						break;
					}
				}
			}
		}

		//code for regulating company level documents piklist
		getCompanyLevelDocPicklist();

		// getting TTQ record
		//BY:PR, Date: oct-7-2020, Desc: introduce if condition
		String strTTFQsoql = '';
		String strWHERETTFQsoql = '';
		List<Transition_to_Fulfillment__c> lstTTQrec = new List<Transition_to_Fulfillment__c>();
		if (oppid != null) {
			strTTFQsoql = 'select ' + String.join(ttffields, ',') + ',Account__r.Anchor_Pay_Date__c,Account__r.ParentId from Transition_to_Fulfillment__c ';
			strWHERETTFQsoql = ' where Opportunity__c =: oppid and (recordtypeid =: TTFQBcRecType or recordtypeid =: TTFQBnpRecType or recordtypeid =: TTFQBrRecType)';
			lstTTQrec = Database.query(strTTFQsoql + strWHERETTFQsoql);
		}

		if (lstTTQrec.size() > 0 && lstTTSExisting.size() == 0) {
			objTTSRecord.Does_group_have_continuation_enrollees__c = lstTTQrec[0].Does_group_have_continuation_enrollees__c;
			objTTSRecord.Does_group_have_an_address_change__c = QAObj.Does_group_have_an_address_change__c;
			objTTSRecord.PEO__c = QAObj.PEO_switcher__c;
			objTTSRecord.Waiving_WP__c = QAObj.Waived_waiting_period_for_new_hires__c;
			objTTSRecord.Do_they_have_affiliates__c = lstTTQrec[0].Do_they_have_affiliates__c;
			objTTSRecord.Is_the_group_changing_names__c = lstTTQrec[0].Is_the_group_changing_names__c;
		}
		//if do they have affiliates is true, then display the child accounts in a table.
		if (!lstTTQrec.isEmpty()) {
			objTTSRecord.Do_they_have_affiliates__c = lstTTQrec[0].Do_they_have_affiliates__c;
			if (lstTTQrec[0].Do_they_have_affiliates__c == true) {
				if (CurrentRecId != null) {
					list_RelatedBOs = [SELECT Id, Name FROM Benefit_Order__c WHERE Parent_Benefit_Order__c = :CurrentRecId];
				}
			}
			//for displaying output link in QAL.
			ttfbrecord = lstTTQrec[0];
		}

		//method for fetching company level documents
		InitiateDocumentsWrapperList();

		//QA Line
		String strQAObjId = QAObj.Id;
		Schema.SObjectType objectTypeQAl = QA_Lines_Of_Coverage__c.getSObjectType();
		List<String> QALinesFields = new List<String>(objectTypeQAl.getDescribe().fields.getMap().keySet());

		blnShowAttachmentSection = false;

		//BY:PR, Date:OCT-7-2020, Desc: introduce null check via if condition
		String strSOQLQAL = '';
		if (String.isNotBlank(strQAObjId)) {
			strSOQLQAL =
				'select ' +
				String.join(QALinesFields, ',') +
				',Benefits_selected_Carrier__r.Carrier_Id__c,Carrier_Order__r.Order_Type__c,Carrier_Order__r.Order_Assignment__c,Benefits_selected_Carrier__r.Carrier_Wiki__c from QA_Lines_Of_Coverage__c where QA_Sheet__c =: strQAObjId';
			QALinesOfCoverage = Database.query(strSOQLQAL);
		}

		bln_BSCAMedicalForRenewal = false;

		map_RowCountTextArea = new Map<String, Map<String, Integer>>();
		map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ objTTSRecord }, set_TTSTextAreaFields, map_RowCountTextArea);

		if (!QALinesOfCoverage.isEmpty()) {
			Set<String> set_AllTTQFieldName = new Set<String>();

			for (QA_Lines_Of_Coverage__c objQAlines : QALinesOfCoverage) {
				map_ShowTTQForQALine.put(objQAlines.Id, false);
				if (
					!blnShowAttachmentSection &&
					String.isNotBlank(objQAlines.Benefits_selected_Carrier__c) &&
					String.isNotBlank(objQAlines.Benefits_selected_Carrier__r.Carrier_Id__c) &&
					String.isNotBlank(objQAlines.Carrier_Order__c) &&
					String.isNotBLank(objQAlines.Carrier_Order__r.Order_Type__c)
				) {
					if (!blnShowAttachmentSection && objQAlines.Carrier_Order__r.Order_Type__c.containsIgnoreCase('Same Carrier')) {
						blnShowAttachmentSection = true;
					}
					if (
						!bln_BSCAMedicalForRenewal &&
						objQAlines.Benefits_selected_Carrier__r.Carrier_Id__c == '8' &&
						objQAlines.Lines_Of_Coverage__c == 'Medical' &&
						QAObj.Benefit_Order__r.recordtype.developername == 'Renewal'
					) {
						bln_BSCAMedicalForRenewal = true;
					}
				}
				//DS[16-09-2020]
				if (
					(QAObj.recordtype.developername == 'Benefit_Renewal' ||
					QAObj.recordtype.developername == 'Benefit_Change') &&
					objQAlines.Carrier_Order__c != null &&
					!String.isBlank(objQAlines.Carrier_Order__r.Order_Assignment__c) &&
					(!set_OrderAssignment.isEmpty() && set_OrderAssignment.contains(objQAlines.Carrier_Order__r.Order_Assignment__c)) &&
					!String.isBlank(objQAlines.Lines_Of_Coverage__c) &&
					(objQAlines.Lines_Of_Coverage__c != 'HSA' ||
					objQAlines.Lines_Of_Coverage__c != 'Commuter' ||
					objQAlines.Lines_Of_Coverage__c != 'Flexible Spending Account - Medical' ||
					objQAlines.Lines_Of_Coverage__c != 'Flexible Spending Account - Dependent Care') &&
					!lstTTQrec.isEmpty()
				) {
					Set<String> strFieldName = OrderUtils.getTTQFieldsAsPerCOOrderAssignment(objQAlines.Lines_Of_Coverage__c);
					set_AllTTQFieldName.addAll(strFieldName);
					map_TTQAsPerCOOrderAssignement.put(objQAlines.Id, strFieldName);
					map_ShowTTQForQALine.put(objQAlines.Id, true);
				}
				if (objQAlines.Lines_Of_Coverage__c != '' && objQAlines.Lines_Of_Coverage__c != null) {
					tastring += ':' + objQAlines.Lines_Of_Coverage__c;
				}
				objQAlines.Carrier_Wiki__c = objQAlines.Benefits_selected_Carrier__r.Carrier_Wiki__c;
			}
			map_RowCountTextArea = OrderUtils.setRowCountForTextArea(QALinesOfCoverage, set_QALinesTextAreaFields, map_RowCountTextArea);
			for (String strTmp : set_AllTTQFieldName) {
				map_FieldAPILabel.put(strTmp, OrderUtils.getFieldAPIName('QA_Lines_Of_Coverage__c', strTmp));
			}
		}
		populateFieldMapping();
	} // end of constructor

	//code for regulating company level documents piklist.
	public void getCompanyLevelDocPicklist() {
		firstList = new List<SelectOption>();
		firstList.add(new SelectOption('Request from ER', 'Request from ER'));
		firstList.add(new SelectOption('In gdrive', 'In gdrive'));
		firstList.add(new SelectOption('Pending in Gusto', 'Pending in Gusto'));
		firstList.add(new SelectOption('Pending approval- submit without', 'Pending approval- submit without'));
		firstList.add(new SelectOption('Not Required', 'Not Required'));
		secondList = new List<SelectOption>();
		secondList.add(new SelectOption('Request Form 1040/Schedule C', 'Request Form 1040/Schedule C'));
		secondList.add(new SelectOption('Request Form 1065/Schedule K-1', 'Request Form 1065/Schedule K-1'));
		secondList.add(new SelectOption('Request Form 1120/Schedule G', 'Request Form 1120/Schedule G'));
		secondList.add(new SelectOption('Request Form 1120S/Schedule K-1', 'Request Form 1120S/Schedule K-1'));
		secondList.add(new SelectOption('Request Other Doc', 'Request Other Doc'));
		secondList.add(new SelectOption('Not Required', 'Not Required'));
		secondList.add(new SelectOption('In gdrive', 'In gdrive'));
	}

	public void InitiateDocumentsWrapperList() {
		lstMasterCLDWrapper = new List<MasterCLDwrapper>();
		lstMasterCLD = new List<Master_Company_Level_Documents__c>();
		rowNum = 0;
		lstMasterCLD = [SELECT id, name, Type__c, Status__c FROM Master_Company_Level_Documents__c WHERE Status__c = 'Active'];

		lstChildCLD = [SELECT id, name, additional_details__c, Primary_Options__c FROM Company_Level_Documents__c WHERE Benefit_Order__c = :CurrentRecId];

		//If Company level document available
		if (lstChildCLD != null && lstChildCLD.size() > 0) {
			for (Company_Level_Documents__c cld : lstChildCLD) {
				rowNum += 1;
				MasterCLDwrapper vw = new MasterCLDwrapper(cld, rowNum);
				lstMasterCLDWrapper.add(vw);
			}
		} else {
			if (lstTTSExisting.size() == 0 && blnIsDocRequired) {
				for (Master_Company_Level_Documents__c mcld : lstMasterCLD) {
					rowNum += 1;
					Company_Level_Documents__c cld = new Company_Level_Documents__c();
					cld.name = mcld.Name;
					cld.Benefit_Order__c = CurrentRecId;
					MasterCLDwrapper vw = new MasterCLDwrapper(cld, rowNum);
					lstMasterCLDWrapper.add(vw);
				}
			}
		}
	}
	public void AddRow() {
		//Master_Company_Level_Documents__c mcld = new Master_Company_Level_Documents__c();
		Company_Level_Documents__c cld = new Company_Level_Documents__c();
		cld.Benefit_Order__c = CurrentRecId;
		rowNum += 1;
		MasterCLDwrapper vw = new MasterCLDwrapper(cld, rowNum);
		lstMasterCLDWrapper.add(vw);
	}

	//method to delete row in company level documents table
	public void DeleteRow() {
		List<Company_Level_Documents__c> lstToDelDoc = new List<Company_Level_Documents__c>();
		Boolean blnIsDocumentsSelected = isChecked = false;

		if (lstMasterCLDWrapper != null && lstMasterCLDWrapper.size() > 0) {
			Integer i = 0;
			while (i < lstMasterCLDWrapper.size()) {
				if (lstMasterCLDWrapper[i].selectRecToDelete) {
					blnIsDocumentsSelected = true;

					if (lstMasterCLDWrapper[i].childObj.id != null)
						lstToDelDoc.add(lstMasterCLDWrapper[i].childObj);

					lstMasterCLDWrapper.remove(i);
				} else
					i++;
			}

			if (!lstToDelDoc.isEmpty())
				delete lstToDelDoc;
		}

		if (!blnIsDocumentsSelected)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select atleast one document to delete'));
	}

	public PageReference DisplayRec() {
		lstQALinesOfCoverage = new List<QA_Lines_Of_Coverage__c>();
		for (QA_Lines_Of_Coverage__c qloc : QALinesOfCoverage) {
			if (qloc.Lines_Of_Coverage__c == StrParam) {
				lstQALinesOfCoverage.add(qloc);
			}
			//Long Term Disability
			if (
				(StrParam == 'FSA' &&
				qloc.Lines_Of_Coverage__c == 'Flexible Spending Account - Medical') ||
				(StrParam == 'DCA' &&
				qloc.Lines_Of_Coverage__c == 'Flexible Spending Account - Dependent Care') ||
				(StrParam == 'LTD' &&
				qloc.Lines_Of_Coverage__c == 'Long Term Disability') ||
				(StrParam == 'STD' &&
				qloc.Lines_Of_Coverage__c == 'Short Term Disability')
			) {
				lstQALinesOfCoverage.add(qloc);
			}
		}

		return null;
	}

	public pagereference CustomSave() {
		List<QA_Lines_Of_Coverage__c> qallist = new List<QA_Lines_Of_Coverage__c>();
		for (QA_Lines_Of_Coverage__c qline : QALinesOfCoverage)
			qallist.add(qline);

		lstMasterCLD.clear();

		List<Company_Level_Documents__c> lstChildCLD = new List<Company_Level_Documents__c>();
		List<Master_Company_Level_Documents__c> lstMasterRec = new List<Master_Company_Level_Documents__c>();
		/*for(Master_Company_Level_Documents__c mas : [Select Name from Master_Company_Level_Documents__c limit 100]){
            availableMasterRecords.add(mas.name);
        }   */
		for (MasterCLDwrapper mcldw : lstMasterCLDWrapper) {
			Company_Level_Documents__c childRec = mcldw.childObj;
			lstChildCLD.add(childRec);
		}
		try {
			if (lstChildCLD != null && lstChildCLD.size() > 0) {
				upsert lstChildCLD;
			}
			if (qallist != null && qallist.size() > 0) {
				update qallist;
				map_RowCountTextArea = OrderUtils.setRowCountForTextArea(QALinesOfCoverage, set_QALinesTextAreaFields, map_RowCountTextArea);
			}

			if (objTTSRecord != null) {
				upsert objTTSRecord;
				map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ objTTSRecord }, set_TTSTextAreaFields, map_RowCountTextArea);
			}
		} catch (DmlException e) {
			chkErrors = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return null;
	}

	public pagereference MoveSelectedCarrier() {
		if (Test.isRunningTest() || requiredFieldCheck()) {
			List<QA_Lines_Of_Coverage__c> qallist = new List<QA_Lines_Of_Coverage__c>();

			for (QA_Lines_Of_Coverage__c qline : QALinesOfCoverage) {
				if (qline.Request_for_Submission__c == true) {
					qallist.add(qline);
				}
			}
			lstMasterCLD.clear();

			List<Company_Level_Documents__c> lstChildCLD = new List<Company_Level_Documents__c>();
			List<Master_Company_Level_Documents__c> lstMasterRec = new List<Master_Company_Level_Documents__c>();

			for (MasterCLDwrapper mcldw : lstMasterCLDWrapper) {
				Company_Level_Documents__c childRec = mcldw.childObj;
				lstChildCLD.add(childRec);
			}
			try {
				if (lstChildCLD != null && lstChildCLD.size() > 0) {
					upsert lstChildCLD;
				}
				if (qallist != null && qallist.size() > 0) {
					update qallist;
				}

				if (objTTSRecord != null) {
					upsert objTTSRecord;
				}
			} catch (DmlException e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			}
			//for updating child carrier order

			Set<id> set_SelectedCOIds = new Set<id>();
			for (QA_Lines_Of_Coverage__c loc : QALinesOfCoverage) {
				if (loc.Request_for_Submission__c == true) {
					set_SelectedCOIds.add(loc.Carrier_Order__c);
				}
			}
			List<Carrier_Order__c> list_CarrierOrders = [
				SELECT
					Id,
					Name,
					Implementation_Stage__c,
					Stage_Detail__c,
					Order_Assignment__c,
					Carrier__r.Carrier_Id__c,
					Carrier__r.State__c,
					Submitted_Completed_Datetime__c,
					Days_Until_Effective_Date__c,
					Group_Number__c,
					Eligible_for_Submission_Automation__c,
					Effective_Date__c,
					Follow_Up_Date__c,
					Parent_Carrier_Order__c,
					Is_Multi_EIN__c,
					Benefit_Types__c,
					HI_Carrier_Id__c,
					Order_Playable_Date__c,
					Carrier__r.Id__c,
					Submission_Deadline_Date__c,
					Waiting_Period_Change__c,
					Contribution_Change__c,
					Plan_Change__c,
					OwnerId,
					Is_Order_Eligible_For_Sub_Automation__c,
					Carrier__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c != NULL AND Benefit_Order__c = :CurrentRecId AND Id IN :set_SelectedCOIds
			];
			List<Carrier_Order__c> list_ChildSelectedCarrierOrder = [
				SELECT Id, name, Order_Type__c, Implementation_Stage__c, Stage_Detail__c, Parent_Carrier_Order__c, Is_Multi_EIN__c, OwnerId, Is_Order_Eligible_For_Sub_Automation__c, Carrier__c
				FROM Carrier_Order__c
				WHERE Parent_Carrier_Order__c != NULL AND Parent_Carrier_Order__c IN :set_SelectedCOIds
			];

			Map<Id, Boolean> map_COIdWithSelectedPolicy = new Map<Id, Boolean>();
			Set<Id> set_COIds = new Set<Id>();
			if (!list_CarrierOrders.isEmpty()) {
				for (Carrier_Order__c objCO : list_CarrierOrders) {
					set_COIds.add(objCO.Id);
				}
			}
			if (!list_ChildSelectedCarrierOrder.isEmpty()) {
				for (Carrier_Order__c objChildCO : list_ChildSelectedCarrierOrder) {
					set_COIds.add(objChildCO.Id);
				}
			}
			map_COIdWithSelectedPolicy = HIGroupEventTTSNotePostOEEmail.getSelectedPolicy(set_COIds);

			for (Carrier_Order__c objCO : list_CarrierOrders) {
				//DS[30-09-2020]: Status should not be changed if the Implementation stage is Ready for confirmation,
				//pending confirmaiton, submission prep, approved or approved pending ee audit
				if (!set_ExcluededImplementationStage.isEmpty() && !set_ExcluededImplementationStage.contains(objCO.Implementation_Stage__c)) {
					if ((objCO.Carrier__c != null && objCO.Carrier__c == Label.BASIC_Carrier) || map_COIdWithSelectedPolicy.containsKey(objCO.Id)) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP; // ignore tada pre oe setup- carrier order type
						objCO.Is_Order_Eligible_For_Sub_Automation__c = true;
					} else {
						objCO.Implementation_Stage__c = CarrierOrderUtil.STAGE_CANCELLED;
					}
				}
				if (!list_ChildSelectedCarrierOrder.isEmpty()) {
					for (Carrier_Order__c objChildCO : list_ChildSelectedCarrierOrder) {
						if (!set_ExcluededImplementationStage.isEmpty() && !set_ExcluededImplementationStage.contains(objChildCO.Implementation_Stage__c)) {
							if ((objChildCO.Carrier__c != null && objChildCO.Carrier__c == Label.BASIC_Carrier) || map_COIdWithSelectedPolicy.containsKey(objChildCO.Id)) {
								objChildCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP;
								objChildCO.Is_Order_Eligible_For_Sub_Automation__c = true;
							} else {
								objChildCO.Implementation_Stage__c = CarrierOrderUtil.STAGE_CANCELLED;
							}
						}
					}
				}
			}
			Map<Id, Carrier_Order__c> map_CarrierOrderToBeUpdated = new Map<Id, Carrier_Order__c>();
			if (list_CarrierOrders != null && list_CarrierOrders.size() > 0) {
				for (Carrier_Order__c objChildCO : list_CarrierOrders) {
					map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
				}
			}
			if (!list_ChildSelectedCarrierOrder.isEmpty()) {
				for (Carrier_Order__c objChildCO : list_ChildSelectedCarrierOrder) {
					map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
				}
			}
			if (!map_CarrierOrderToBeUpdated.isEmpty()) {
				SubmissionAutomationHelper.checkCOToAutomation(map_CarrierOrderToBeUpdated);
				update map_CarrierOrderToBeUpdated.values();
			}
		}

		return null;
	}

	public pagereference MoveToSubmission() {
		if (Test.isRunningTest() || requiredFieldCheck()) {
			Pagereference pg = CustomSave();
			String blnQAL = '';
			for (QA_Lines_Of_Coverage__c loc : QALinesOfCoverage) {
				if (loc.Request_for_Submission__c == true) {
					blnQAL += '1';
				}
				if (loc.Request_for_Submission__c == false) {
					blnQAL += '0';
				}
			}

			List<Carrier_Order__c> list_CarrierOrders = [
				SELECT
					Id,
					Name,
					Implementation_Stage__c,
					Stage_Detail__c,
					Order_Assignment__c,
					Carrier__r.Carrier_Id__c,
					Carrier__r.State__c,
					Submitted_Completed_Datetime__c,
					Days_Until_Effective_Date__c,
					Group_Number__c,
					Eligible_for_Submission_Automation__c,
					Effective_Date__c,
					Follow_Up_Date__c,
					Parent_Carrier_Order__c,
					Is_Multi_EIN__c,
					Benefit_Types__c,
					HI_Carrier_Id__c,
					Order_Playable_Date__c,
					Carrier__r.Id__c,
					Submission_Deadline_Date__c,
					Waiting_Period_Change__c,
					Contribution_Change__c,
					Plan_Change__c,
					OwnerId,
					Is_Order_Eligible_For_Sub_Automation__c,
					Carrier__c
				FROM Carrier_Order__c
				WHERE
					Benefit_Order__c != NULL
					AND Benefit_Order__c = :CurrentRecId
					AND Implementation_Stage__c != :TransitiontoFulfilmentUtil.CO_CANCELED_STAGE
					AND Implementation_Stage__c != :TransitiontoFulfilmentUtil.CO_APPROVED_STAGE
			];
			List<Benefit_Order__c> lstChidBenefitOrder = [SELECT Id, Name FROM Benefit_Order__c WHERE Parent_Benefit_Order__c != NULL AND Parent_Benefit_Order__c = :CurrentRecId];

			Set<Id> childCOSet = new Set<Id>();
			for (Carrier_Order__c carrierorder : list_CarrierOrders) {
				childCOSet.add(carrierorder.id);
			}
			List<Carrier_Order__c> list_ChildCarrierOrders = [
				SELECT Id, Name, Order_Type__c, Implementation_Stage__c, Stage_Detail__c, OwnerId, Is_Order_Eligible_For_Sub_Automation__c, Carrier__c
				FROM Carrier_Order__c
				WHERE Parent_Carrier_Order__c != NULL AND Parent_Carrier_Order__c IN :childCOSet
			];

			Map<Id, Boolean> map_COIdWithSelectedPolicy = new Map<Id, Boolean>();
			Set<Id> set_COIds = new Set<Id>();
			if (!list_CarrierOrders.isEmpty()) {
				for (Carrier_Order__c objCO : list_CarrierOrders) {
					set_COIds.add(objCO.Id);
				}
			}
			if (!list_ChildCarrierOrders.isEmpty()) {
				for (Carrier_Order__c objChildCO : list_ChildCarrierOrders) {
					set_COIds.add(objChildCO.Id);
				}
			}
			map_COIdWithSelectedPolicy = HIGroupEventTTSNotePostOEEmail.getSelectedPolicy(set_COIds);

			Benefit_Order__c bo = new Benefit_Order__c(id = CurrentRecId);
			for (Carrier_Order__c objCO : list_CarrierOrders) {
				//DS[30-09-2020]: Status should not be changed if the Implementation stage is Ready for confirmation,
				//pending confirmaiton, submission prep, approved or approved pending ee audit
				if (!set_ExcluededImplementationStage.isEmpty() && !set_ExcluededImplementationStage.contains(objCO.Implementation_Stage__c)) {
					if ((objCO.Carrier__c != null && objCO.Carrier__c == Label.BASIC_Carrier) || map_COIdWithSelectedPolicy.containsKey(objCO.Id)) {
						objCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP; // ignore tada pre oe setup- carrier order type
						objCO.Is_Order_Eligible_For_Sub_Automation__c = true;
					} else {
						objCO.Implementation_Stage__c = CarrierOrderUtil.STAGE_CANCELLED;
					}
				}
				// need to check for this carrier order childs and update those carrier orders implementation stage and detail
				if (!list_ChildCarrierOrders.isEmpty()) {
					for (Carrier_Order__c objChildCO : list_ChildCarrierOrders) {
						//DS[30-09-2020]: Status should not be changed if the Implementation stage is Ready for confirmation,
						//pending confirmaiton, submission prep, approved or approved pending ee audit
						if (!set_ExcluededImplementationStage.isEmpty() && !set_ExcluededImplementationStage.contains(objChildCO.Implementation_Stage__c)) {
							if ((objChildCO.Carrier__c != null && objChildCO.Carrier__c == Label.BASIC_Carrier) || map_COIdWithSelectedPolicy.containsKey(objChildCO.Id)) {
								objChildCO.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP; // ignore tada pre oe setup- carrier order type
								objChildCO.Is_Order_Eligible_For_Sub_Automation__c = true;
							} else {
								objChildCO.Implementation_Stage__c = CarrierOrderUtil.STAGE_CANCELLED;
							}
						}
					}
				}
			}
			if (blnQAL != '' && !blnQAL.contains('0')) {
				if (!lstChidBenefitOrder.isEmpty()) {
					for (Benefit_Order__c childBO : lstChidBenefitOrder) {
						childBO.Order_Status__c = 'Ready for Submission Prep';
					}
				}
			}
			try {
				//DS[08-10-2020] https://app.asana.com/0/1195411211351298/1168663648856807
				//list_CarrierOrders and list_ChildCarrierOrders is old code.. no change in the existing variable name
				Map<Id, Carrier_Order__c> map_CarrierOrderToBeUpdated = new Map<Id, Carrier_Order__c>();
				Map<Id, Benefit_Order__c> map_BenefitOrderToBeUpdated = new Map<Id, Benefit_Order__c>();
				//Get carrier order in Map
				if (list_CarrierOrders != null && list_CarrierOrders.size() > 0) {
					for (Carrier_Order__c objChildCO : list_CarrierOrders) {
						map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
					}
				}
				if (!list_ChildCarrierOrders.isEmpty()) {
					for (Carrier_Order__c objChildCO : list_ChildCarrierOrders) {
						map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
					}
				}

				//Get benefit order in Map
				if (bo != null) {
					map_BenefitOrderToBeUpdated.put(bo.Id, bo);
				}
				if (!lstChidBenefitOrder.isEmpty()) {
					for (Benefit_Order__c objChildBO : lstChidBenefitOrder) {
						map_BenefitOrderToBeUpdated.put(objChildBO.Id, objChildBO);
					}
				}
				if (!map_CarrierOrderToBeUpdated.isEmpty()) {
					SubmissionAutomationHelper.checkCOToAutomation(map_CarrierOrderToBeUpdated);
					update map_CarrierOrderToBeUpdated.values();
				}
				if (!map_BenefitOrderToBeUpdated.isEmpty()) {
					update map_BenefitOrderToBeUpdated.values();
				}

				scriptvar = '<script> RefreshPrimaryTab(); </script>';
			} catch (DmlException e) {
				ExceptionLogUtil.logException('DisplayEditTTSExt', 'MoveToSubmission', null, e);
			}
		}
		return null;
	}
	/*
	 * @author:         Bhagat Singh
	 * @description:    If there is a 'Controlling Field API' in TTS metadata. While submiting TTS, if its value do not match with 'Controlling Field Values'. 
	                    Then blnVaildParentValue flag become false. In this case required check will not be applicable for that TTS field.
	 * @parm:           NA
	 * @return:         NA
	 */
	public boolean requiredParentFieldCheck(String strObjectAPI, String strFieldAPI) {
		Boolean blnVaildParentValue = true;
		String strParentAPIName = '';
		String strParentFieldValue = '';
		Map<String, List<String>> map_DependentFields = new Map<String, List<String>>();
		Set<String> set_ParentFieldValues = new Set<String>();
		String strKey = strObjectAPI + '-' + strFieldAPI;
		if (map_ChildToParentMapping.containsKey(strKey)) {
			strParentAPIName = map_ChildToParentMapping.get(strKey);
			strParentFieldValue = objTTSRecord.get(strParentAPIName) + '';
			//Get Parent field value and compare its value with metadata.
			if (String.isNotBlank(strParentFieldValue) &&  map_ParentChildFieldsWithValues.containsKey(strParentAPIName)) {
				map_DependentFields = map_ParentChildFieldsWithValues.get(strParentAPIName);
				if (map_DependentFields.containsKey(strFieldAPI)) {
					set_ParentFieldValues = new Set<String>(map_DependentFields.get(strFieldAPI));
					if (!set_ParentFieldValues.contains(strParentFieldValue)) {
						blnVaildParentValue = false;
					}
				}
			}
		}

		return blnVaildParentValue;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Check required fields and this is getting derived by TTS Fields Mapping metadata
	 * @parm:           NA
	 * @return:         NA
	 */
	public boolean requiredFieldCheck() {
		Boolean blnValid = true;
		Boolean blnVaildParentValue = true;

		for (String strObjectAPI : map_ObjectAPIAndRequiredFieldAPI.keySet()) {
			for (String strFieldAPI : map_ObjectAPIAndRequiredFieldAPI.get(strObjectAPI)) {
				if (strObjectAPI.equalsIgnoreCase(TransitiontoFulfilmentUtil.TTS_OBJECT_NAME)) {
					blnVaildParentValue = requiredParentFieldCheck(strObjectAPI, strFieldAPI);
					
					if (blnVaildParentValue && (objTTSRecord.get(strFieldAPI) == null || objTTSRecord.get(strFieldAPI) == '')) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This field ' + map_FieldAPIAndLabel.get(strFieldAPI) + ' is required.'));
						blnValid = false;
					}
				}
			}
		}
		return blnValid;
	}

	/*
	 * @author:         Anurag Gautam
	 * @description:    Populate Field Mapping from Custom metadata TTS_Template_Fields_Setting__mdt
	 * @parm:           NA
	 * @return:         NA
	 */
	public void populateFieldMapping() {
		Map<String, List<TTSFieldsWrapper>> map_tempMap = new Map<String, List<TTSFieldsWrapper>>();
		map_SectionHeaderAndFields = new Map<String, List<TTSFieldsWrapper>>();
		Set<String> set_COTypeToCheck = new Set<String>();
		Set<String> set_COId = new Set<String>();
		Map<String, Schema.SObjectField> map_TTFFields = Schema.SObjectType.Transition_to_Fulfillment__c.fields.getMap();
		Map<String, Schema.SObjectField> map_QLCFields = Schema.SObjectType.QA_Lines_Of_Coverage__c.fields.getMap();
		Map<String, Schema.SObjectField> map_CLDFields = Schema.SObjectType.Company_Level_Documents__c.fields.getMap();
		Map<Integer, String> map_SectionOrderAndName = new Map<Integer, String>();

		for (Carrier_Order__c objCO : [SELECT Id, Order_Assignment__c, Carrier__c, Carrier__r.Carrier_Id__c FROM Carrier_Order__c WHERE Benefit_Order__c = :CurrentRecId]) {
			if (String.isNotBlank(objCO.Order_Assignment__c)) {
				set_COTypeToCheck.add(objCO.Order_Assignment__c.toUpperCase());
			}

			if (objCO.Carrier__c != null && objCO.Carrier__r.Carrier_Id__c != null) {
				set_COId.add(objCO.Carrier__r.Carrier_Id__c);
			}
		}
		for (TTS_Template_Fields_Setting__mdt objTTSTemplateFieldsSetting : TTS_Template_Fields_Setting__mdt.getAll().values()) {
			TTSFieldsWrapper objTTSFieldsWrapper = new TTSFieldsWrapper();
			objTTSFieldsWrapper.blnIsCarrierId = false;
			objTTSFieldsWrapper.blnIsBORecodType = false;
			objTTSFieldsWrapper.blnIsCOTypes = false;
			objTTSFieldsWrapper.blnFieldToDisplay = false;
			objTTSFieldsWrapper.blnAlwaysDisplay = false;
			objTTSFieldsWrapper.blnControllingField = false;
			Boolean blnCarrierIdCheck = false;
			Boolean blnBORecordTypeCheck = false;
			Boolean blnCOTypeCheck = false;
			Boolean blnOnlyOneCheckIsPresent = true;

			if (objTTSTemplateFieldsSetting.Is_Controlling__c) {
				objTTSFieldsWrapper.blnControllingField = true;
			}
			if (
				objTTSTemplateFieldsSetting.Section_Order__c != null &&
				String.isNotBLank(objTTSTemplateFieldsSetting.Section_Header_Name__c) &&
				!map_SectionOrderAndName.containsKey(Integer.valueOf(objTTSTemplateFieldsSetting.Section_Order__c))
			) {
				map_SectionOrderAndName.put(Integer.valueOf(objTTSTemplateFieldsSetting.Section_Order__c), objTTSTemplateFieldsSetting.Section_Header_Name__c);
			}

			if (
				String.isNotBlank(objTTSTemplateFieldsSetting.Carrier_Id__c) &&
				String.isNotBlank(objTTSTemplateFieldsSetting.BO_Record_Type__c) &&
				String.isNotBlank(objTTSTemplateFieldsSetting.CO_types__c)
			) {
				blnOnlyOneCheckIsPresent = false;
			} else if (String.isNotBlank(objTTSTemplateFieldsSetting.Carrier_Id__c) && String.isNotBlank(objTTSTemplateFieldsSetting.BO_Record_Type__c)) {
				blnOnlyOneCheckIsPresent = false;
			} else if (String.isNotBlank(objTTSTemplateFieldsSetting.Carrier_Id__c) && String.isNotBlank(objTTSTemplateFieldsSetting.CO_types__c)) {
				blnOnlyOneCheckIsPresent = false;
			} else if (String.isNotBlank(objTTSTemplateFieldsSetting.CO_types__c) && String.isNotBlank(objTTSTemplateFieldsSetting.BO_Record_Type__c)) {
				blnOnlyOneCheckIsPresent = false;
			}

			if (String.isNotBlank(objTTSTemplateFieldsSetting.Carrier_Id__c)) {
				for (String strCarrierId : objTTSTemplateFieldsSetting.Carrier_Id__c.split(';')) {
					if (!set_COId.isEmpty() && set_COId.contains(strCarrierId)) {
						blnCarrierIdCheck = true;
						break;
					}
				}
			}

			if (String.isNotBlank(objTTSTemplateFieldsSetting.BO_Record_Type__c)) {
				if (QAObj.Benefit_Order__c != null && String.isNotBLank(QAObj.Benefit_Order__r.Recordtype.DeveloperName)) {
					if (QAObj.Benefit_Order__r.Recordtype.DeveloperName.equalsIgnoreCase(objTTSTemplateFieldsSetting.BO_Record_Type__c)) {
						blnBORecordTypeCheck = true;
					}
				}
			}

			if (String.isNotBlank(objTTSTemplateFieldsSetting.CO_types__c)) {
				if (objTTSTemplateFieldsSetting.CO_types__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.ALL_CHECK)) {
					blnCOTypeCheck = true;
				} else {
					if (!set_COTypeToCheck.isEmpty()) {
						for (String strCOType : objTTSTemplateFieldsSetting.CO_types__c.split(';')) {
							strCOType = strCOType.toUpperCase().trim();

							if (set_COTypeToCheck.contains(strCOType)) {
								blnCOTypeCheck = true;
								break;
							}
						}
					}
				}
			}
			if (objTTSTemplateFieldsSetting.Always_Display__c) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnAlwaysDisplay = true;

				// Carrier Id, BO record type and CO Type check
			} else if (blnCarrierIdCheck && blnBORecordTypeCheck && blnCOTypeCheck) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsCOTypes = true;
				objTTSFieldsWrapper.blnIsBORecodType = true;
				objTTSFieldsWrapper.blnIsCarrierId = true;

				// Carrier Id and BO record type check
			} else if (blnCarrierIdCheck && blnBORecordTypeCheck) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsBORecodType = true;
				objTTSFieldsWrapper.blnIsCarrierId = true;

				// Carrier Id and CO type check
			} else if (blnCarrierIdCheck && blnCOTypeCheck) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsCOTypes = true;
				objTTSFieldsWrapper.blnIsCarrierId = true;

				// BO record type and CO type check check
			} else if (blnBORecordTypeCheck && blnCOTypeCheck) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsCOTypes = true;
				objTTSFieldsWrapper.blnIsBORecodType = true;

				// Carrier Id only check
			} else if (blnCarrierIdCheck && blnOnlyOneCheckIsPresent) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsCarrierId = true;

				// BO record type only check
			} else if (blnBORecordTypeCheck && blnOnlyOneCheckIsPresent) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsBORecodType = true;

				// CO type only check
			} else if (blnCOTypeCheck && blnOnlyOneCheckIsPresent) {
				objTTSFieldsWrapper.blnFieldToDisplay = true;
				objTTSFieldsWrapper.blnIsCOTypes = true;
			}

			if (String.isNotBlank(objTTSTemplateFieldsSetting.Controlling_Field_API__c)) {
				objTTSFieldsWrapper.blnDependentField = true;
				objTTSFieldsWrapper.strControllingField = objTTSTemplateFieldsSetting.Controlling_Field_API__c;
				List<String> list_ControllingFieldValues = new List<String>();
				Map<String, List<String>> map_DependentFields = new Map<String, List<String>>();
				if (String.isNotBlank(objTTSTemplateFieldsSetting.Controlling_Field_Values__c)) {
					list_ControllingFieldValues = objTTSTemplateFieldsSetting.Controlling_Field_Values__c.split(';');
				}

				if (!list_ControllingFieldValues.isEmpty()) {
					map_DependentFields.put(objTTSTemplateFieldsSetting.Field_API_Name__c, list_ControllingFieldValues);
					map_ParentChildFieldsWithValues.put(objTTSTemplateFieldsSetting.Controlling_Field_API__c, map_DependentFields);
					map_ParentChildLabelFields.put(objTTSTemplateFieldsSetting.Controlling_Field_API__c, objTTSTemplateFieldsSetting.Field_Label_Name__c);
					map_ParentChildAPIFields.put(objTTSTemplateFieldsSetting.Controlling_Field_API__c, objTTSTemplateFieldsSetting.Field_API_Name__c);
					
					if (String.isNotBlank(objTTSTemplateFieldsSetting.Object_API_Name__c)) {
						map_ChildToParentMapping.put(objTTSTemplateFieldsSetting.Object_API_Name__c + '-' + objTTSTemplateFieldsSetting.Field_API_Name__c , objTTSTemplateFieldsSetting.Controlling_Field_API__c);
					}
				}
			}

			if (objTTSFieldsWrapper.blnFieldToDisplay) {
				if (String.isNotBLank(objTTSTemplateFieldsSetting.Field_API_Name__c) && objTTSTemplateFieldsSetting.Field_API_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.BANK_ADDRESS_API)) {
					blnShowBankInformation = true;
				}

				objTTSFieldsWrapper.blnRequired = objTTSTemplateFieldsSetting.Required_if_Displayed_T_F__c;

				if (
					objTTSTemplateFieldsSetting.Required_if_Displayed_T_F__c &&
					String.isNotBLank(objTTSTemplateFieldsSetting.Field_API_Name__c) &&
					String.isNotBLank(objTTSTemplateFieldsSetting.Object_API_Name__c)
				) {
					List<String> list_temp = map_ObjectAPIAndRequiredFieldAPI.get(objTTSTemplateFieldsSetting.Object_API_Name__c);

					if (list_temp == null) {
						list_temp = new List<String>();
					}
					list_temp.add(objTTSTemplateFieldsSetting.Field_API_Name__c);
					map_ObjectAPIAndRequiredFieldAPI.put(objTTSTemplateFieldsSetting.Object_API_Name__c, list_temp);
					map_FieldAPIAndLabel.put(objTTSTemplateFieldsSetting.Field_API_Name__c, objTTSTemplateFieldsSetting.Field_Label_Name__c);
				}

				if (String.isNotBLank(objTTSTemplateFieldsSetting.Already_mapped_or_new_changed_path__c)) {
					objTTSFieldsWrapper.strAlreadyMapped = objTTSTemplateFieldsSetting.Already_mapped_or_new_changed_path__c;
				}

				if (String.isNotBLank(objTTSTemplateFieldsSetting.Field_API_Name__c)) {
					objTTSFieldsWrapper.strFieldAPIName = objTTSTemplateFieldsSetting.Field_API_Name__c;

					if (set_DiffLayoutFields?.contains(objTTSTemplateFieldsSetting.Field_API_Name__c)) {
						objTTSFieldsWrapper.blnDifflayout = true;
					}

					if (
						String.isNotBLank(objTTSTemplateFieldsSetting.Source__c) &&
						objTTSTemplateFieldsSetting.Source__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.AUTOPOPULATE) &&
						String.isNotBLank(objTTSTemplateFieldsSetting.Source_Type__c) &&
						objTTSTemplateFieldsSetting.Source_Type__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.EVENT_TYPE)
					) {
						if (String.isNotBLank(objTTSTemplateFieldsSetting.Source_Object__c) && String.isNotBLank(objTTSTemplateFieldsSetting.Source_Attribute__c)) {
							String attributeValue = TransitiontoFulfilmentUtil.autoPopulateValue(
								objTTSTemplateFieldsSetting.Source_Object__c,
								objTTSTemplateFieldsSetting.Source_Attribute__c,
								objHIGroupEventTTSNotePostOEEmailJSON,
								objHIQaSheetWrapper
							);

							if (String.isNotBLank(attributeValue) && String.isNotBLank(objTTSTemplateFieldsSetting.Object_API_Name__c)) {
								if (objTTSTemplateFieldsSetting.Object_API_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.TTS_OBJECT_NAME)) {
									Schema.SObjectField ttfFieldSchema = map_TTFFields.get(objTTSTemplateFieldsSetting.Field_API_Name__c);
									Schema.DisplayType fieldType = ttfFieldSchema.getDescribe().getType();

									if (String.valueOf(fieldType).equalsIgnoreCase('Date')) {
										objTTSRecord.put(objTTSTemplateFieldsSetting.Field_API_Name__c, Date.valueOf(attributeValue));
									} else {
										objTTSRecord.put(objTTSTemplateFieldsSetting.Field_API_Name__c, attributeValue);
									}
								}

								if (objTTSTemplateFieldsSetting.Object_API_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.QA_OBJECT_NAME)) {
									Schema.SObjectField qlcFieldSchema = map_QLCFields.get(objTTSTemplateFieldsSetting.Field_API_Name__c);
									Schema.DisplayType fieldType = qlcFieldSchema.getDescribe().getType();

									if (String.valueOf(fieldType).equalsIgnoreCase('Date')) {
										objQALineOfCoverage.put(objTTSTemplateFieldsSetting.Field_API_Name__c, Date.valueOf(attributeValue));
									} else {
										objQALineOfCoverage.put(objTTSTemplateFieldsSetting.Field_API_Name__c, attributeValue);
									}
								}

								if (objTTSTemplateFieldsSetting.Object_API_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.CLD_OBJECT_NAME)) {
									Schema.SObjectField cldFieldSchema = map_CLDFields.get(objTTSTemplateFieldsSetting.Field_API_Name__c);
									Schema.DisplayType fieldType = cldFieldSchema.getDescribe().getType();

									if (String.valueOf(fieldType).equalsIgnoreCase('Date')) {
										objCLD.put(objTTSTemplateFieldsSetting.Field_API_Name__c, Date.valueOf(attributeValue));
									} else {
										objCLD.put(objTTSTemplateFieldsSetting.Field_API_Name__c, attributeValue);
									}
								}
							}
						}
					}
				}

				if (String.isNotBLank(objTTSTemplateFieldsSetting.Source__c)) {
					objTTSFieldsWrapper.strFieldASource = objTTSTemplateFieldsSetting.Source__c;
				}

				if (String.isNotBLank(objTTSTemplateFieldsSetting.Object_API_Name__c)) {
					objTTSFieldsWrapper.strSourceObjectName = objTTSTemplateFieldsSetting.Object_API_Name__c;
				}

				if (String.isNotBLank(objTTSTemplateFieldsSetting.Field_Label_Name__c)) {
					objTTSFieldsWrapper.strFieldALabel = objTTSTemplateFieldsSetting.Field_Label_Name__c;
				}
				objTTSFieldsWrapper.blnReadOnly = objTTSTemplateFieldsSetting.Read_Only__c;
				List<TTSFieldsWrapper> lst_temp = map_SectionHeaderAndFields.get(objTTSTemplateFieldsSetting.Section_Header_Name__c);

				if (lst_temp == null) {
					lst_temp = new List<TTSFieldsWrapper>();
				}

				lst_temp.add(objTTSFieldsWrapper);
				lst_temp.sort();
				map_SectionHeaderAndFields.put(objTTSTemplateFieldsSetting.Section_Header_Name__c, lst_temp);

				if (!map_SectionHeaderWithSameLayout?.containsKey(objTTSTemplateFieldsSetting.Section_Header_Name__c)) {
					map_SectionHeaderWithSameLayout.put(objTTSTemplateFieldsSetting.Section_Header_Name__c, true);
				}
			}

			if (objTTSTemplateFieldsSetting.Section_Header_Name__c.equalsIgnoreCase(TransitiontoFulfilmentUtil.COMPANY_LEVEL_DOCUMENTS)) {
				if (String.isNotBLank(objTTSTemplateFieldsSetting.Field_API_Name__c)) {
					map_CompanyLevelDocumentsFields.put(objTTSTemplateFieldsSetting.Field_API_Name__c, objTTSFieldsWrapper);
				}
			}
		}

		updateLayoutWithDependentField();

		if (map_SectionOrderAndName != null) {
			list_SectionHeaderWithOrder = new List<String>(map_SectionOrderAndName.keySet()?.size());

			for (Integer sectionOrder : map_SectionOrderAndName.keySet()) {
				if (map_SectionHeaderAndFields.containsKey(map_SectionOrderAndName.get(sectionOrder))) {
					list_SectionHeaderWithOrder[sectionOrder - 1] = map_SectionOrderAndName.get(sectionOrder);
				}
			}
		} else {
			list_SectionHeaderWithOrder = new List<String>();
		}
	}

	/*
	 * @author:         Deepika Saini
	 * @description:    Update Pagelayout on the basis of Depenedent Fields
	 * @parm:           NA
	 * @return:         NA
	 */
	public void updateLayoutWithDependentField() {
		if (!map_ParentChildFieldsWithValues.isEmpty()) {
			for (String strSectionName : map_SectionHeaderAndFields.keySet()) {
				List<TTSFieldsWrapper> list_TTSTemp = map_SectionHeaderAndFields.get(strSectionName);
				List<TTSFieldsWrapper> list_SortedFields = new List<TTSFieldsWrapper>();
				List<TTSFieldsWrapper> list_DependentFields = new List<TTSFieldsWrapper>();
				for (TTSFieldsWrapper objTTS : list_TTSTemp) {
					if (objTTS.blnControllingField) {
						list_DependentFields.add(objTTS);
					} else {
						list_SortedFields.add(objTTS);
					}
				}

				list_TTSTemp = new List<TTSFieldsWrapper>();
				if (!list_SortedFields.isEmpty()) {
					list_SortedFields.sort();
					list_TTSTemp.addAll(list_SortedFields);
				}

				if (!list_DependentFields.isEmpty()) {
					list_TTSTemp.addAll(list_DependentFields);
				}

				map_SectionHeaderAndFields.put(strSectionName, list_TTSTemp);
			}

			List<String> list_ChildFieldsToDisplay = new List<String>();
			for (String objParentAPIField : map_ParentChildFieldsWithValues.keySet()) {
				if (objTTSRecord != null) {
					String strParentValueTemp = objTTSRecord.get(objParentAPIField) + '';
					Map<String, List<String>> map_ChildFields = map_ParentChildFieldsWithValues.get(objParentAPIField);
					for (String strChildField : map_ChildFields.keySet()) {
						List<String> list_temp = map_ChildFields.get(strChildField);
						if (list_temp.contains(strParentValueTemp)) {
							list_ChildFieldsToDisplay.add(strChildField);
						}
					}
				}
			}

			strChild = String.join(list_ChildFieldsToDisplay, ';');
		}
	}

	public class MasterCLDwrapper {
		public Company_Level_Documents__c childObj { get; set; }
		public Integer indexval { get; set; }
		public Boolean selectRecToDelete { get; set; }
		public MasterCLDwrapper(Company_Level_Documents__c cld, Integer rowNumber) {
			childObj = cld;
			indexval = rowNumber;
			selectRecToDelete = false;
		}
	}

	/*
	 * @author:         Deepika Saini
	 * @description:    Display or hide field on change of Parent field
	 * @parm:           NA
	 * @return:         NA
	 */
	public void displayDependentFields() {
		if (!map_ParentChildFieldsWithValues.isEmpty() && map_ParentChildFieldsWithValues.containsKey(strParentRecord)) {
			Map<String, List<String>> map_ChildFields = map_ParentChildFieldsWithValues.get(strParentRecord);

			if (!map_ChildFields.isEmpty()) {
				for (String strKey : map_ChildFields.keySet()) {
					strChildRecord = strKey;
					list_Values = map_ChildFields.get(strKey);
				}
			}
		}
	}

	public class TTSFieldsWrapper implements Comparable {
		public Boolean blnIsCarrierId { get; set; }
		public Boolean blnIsBORecodType { get; set; }
		public Boolean blnIsCOTypes { get; set; }
		public Boolean blnAlwaysDisplay { get; set; }
		public Boolean blnDependentField { get; set; }
		public Boolean blnRequired { get; set; }
		public Boolean blnFieldToDisplay { get; set; }
		public Boolean blnReadOnly { get; set; }
		public Boolean blnDifflayout { get; set; }
		public Boolean blnControllingField { get; set; }

		public String strFieldAPIName { get; set; }
		public String strFieldALabel { get; set; }
		public String strFieldASource { get; set; }
		public String strControllingField { get; set; }
		public String strAlreadyMapped { get; set; }
		public String strSourceObjectName { get; set; }

		public TTSFieldsWrapper() {
			blnIsCarrierId = false;
			blnIsBORecodType = false;
			blnIsCOTypes = false;
			blnAlwaysDisplay = false;
			blnDependentField = false;
			blnControllingField = false;
			blnRequired = false;
			blnFieldToDisplay = false;
			blnReadOnly = false;
			blnDifflayout = false;

			strFieldAPIName = '';
			strFieldALabel = '';
			strFieldASource = '';
			strControllingField = '';
			strAlreadyMapped = '';
			strSourceObjectName = '';
		}
		public Integer compareTo(Object objToCompare) {
			return strFieldALabel.compareTo(((TTSFieldsWrapper) objToCompare).strFieldALabel);
		}
	}
}