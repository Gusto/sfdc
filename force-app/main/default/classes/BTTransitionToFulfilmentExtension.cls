/*
@Purpose: Extension class for Custom VF page "BTTransitionToFulfilmentEdit" which we are using to override "Edit" page of
            "Transition To Fulfillment" object.
@Written By: PR
*/
public without sharing class BTTransitionToFulfilmentExtension {
	public static final Integer PAGE_SIZE = 10;
	public static final Integer QUERY_LIMIT = 10000;

	Map<String, Set<String>> map_CarriersWithDate = new Map<String, Set<String>>();
	Map<String, Set<String>> map_BenefitTypesDateWithCarrierName = new Map<String, Set<String>>();
	Map<String, Carrier__c> map_CarriersWithKey = new Map<String, Carrier__c>();
	static final String OPP_RT_BENEFIT_BYB = 'Benefits BYOB';
	public static final String MSQ_BROKER_CONTACT_EMPTY = 'Broker point of Contact is required.';
	public static final String MSQ_SGHI_LGHI_EMPTY = 'SGHI/LGHI is required for BYB.';
	public static final String MSQ_FUNDING_TYPE_EMPTY = 'Funding Type is required for BYB.';
	public static final String MSQ_PEO_SWITCHER_EMPTY = 'PEO Switcher is required for BYB.';
	public static final String MSQ_BROKER_LOYAL_EMPTY = 'Broker Loyal is required for BYB.';
	public static final String MSQ_BOR_ED_EMPTY = 'BoR Eligible Medical is required for BYB.';
	public static final String MSQ_BYB_REASON_EMPTY = 'BYB Reason is required when Bor Eligible Medical is Y.';
	public static final String MSQ_PREFERRED_BROKER_EMPTY = 'Preferred Broker is required when Handed off to preferred broker partner is checked.';
	public static final String MSQ_ENTER_OTHER_CARRIER_NAME = 'Enter Other Carrier Name.';
	public static final String MSQ_INVALID_RENEWAL_DATE = 'Benefit Renewal Date must be in the future, within the next year, 1st or 15th of month.';
	public static final String MSQ_RENEWAL_DATE_MISSING = 'Benefits renewal date is required.';
	public static final String MSQ_BENEFIT_TYPE_MISSING = 'Benefit Type Should be Selected.';
	public static final String MSQ_CARRIER_MISSING = 'Carrier is required.';
	public static final String MSQ_CARRIER_KEY_MISSING = 'Carrier is inactive please select an active carrier or select Other and enter the new carrier name in';
	public static final String OPP_STAGE_CLOSED_WON = 'Closed Won';
	public static final String OPP_STAGE_PENDING_PR = 'Pending PR';
	public static final String BENEFIT_ORDER_TYPE_BYB_MID_YEAR = 'Gusto to BYB - Midyear';
	public static final String TTF_RT_BENEFIT_BYB = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits BYB');
	public Integer intSaveIndx { get; set; }
	public Integer intEditIndx { get; set; }
	public Integer intDeleteIndx { get; set; }
	public String strErrorMessage { get; set; }
	public Boolean blnIsErrorOtherCarrier { get; set; }
	public Id idBrokerRole { get; set; }
	public Boolean blnIsBYOBOpportunity { get; set; }
	public Transition_to_Fulfillment__c objTTFRecord { get; set; }
	public Opportunity objRelatedOpp { get; set; }
	public List<OpportunityContactRole> list_OpptyContactRole { get; set; }
	public List<SelectOption> list_BenefitTypes { get; set; }
	public list<SelectOption> lst_YesNoPicklist { get; set; } //works as master licklist values for all the picklists no present iin TTF
	public boolean blnIsOppERConfirmed { get; set; } //using this to enable/disable the "Send Order" checkbox
	public Attachment objAttachmentNew { get; set; } //attachment objec instance used to save user uploded documents
	public Id idPrimaryRole { get; set; } //contains primary role Id
	public Id idSecRole { get; set; } //contains secondary Id
	public list<Attachment> lst_TTFAttachmentList { get; set; } //contains attachment list
	public string strAttachmentIdToDelete { get; set; }
	public string strPartnerTier { get; set; } //store partnertier
	public string strPartnerFirmName { get; set; } //store partner firm name
	public Integer selectedCompanyIndx { get; set; } // to add or remove selected companies
	public String strAccName { get; set; } // to search accounts by name
	public String strZPCompanyId { get; set; } // to search accounts by ZPCompanyId
	public Integer size { get; set; }
	public Integer noOfRecords { get; set; }
	public boolean blnShowOrderTypePage { get; set; }
	public boolean blnBOOrderTypeReq { get; set; }
	public boolean blnBORDateReq { get; set; }
	public boolean blnBYBReason { get; set; }
	public boolean blnCreateBenefitOrder { get; set; }
	public List<SelectOption> list_OrderTypeBO { get; set; }
	public Benefit_Order__c objBenefitOrder { get; set; }
	public tadaDetailWrapper optedTadaDetails { get; set; }
	public List<POCWrapper> list_POCWrapper { get; set; }
	public list<externalCoverageWrapper> lst_eternalCoverageDetails { get; set; }
	public List<AccountWrapper> lstAccWrapper { get; set; } //list used for affiliates
	public List<CarrierDetailWrapper> list_CarrierDetails { get; set; }
	public map<string, BenefitsWrapper> map_carrierKeyBenefitDetails { get; set; }
	public Map<Id, AccountWrapper> mapSelectedAccounts { get; set; }
	public list<priorityReasonsWrapper> lst_priorityReasonDetails { get; set; }
	public Id idAcccountToBeRemoved { get; set; }
	public boolean blnIsAffiliatesFormedSigned { get; set; } //is all affiliates forms signed
	public list<Account> list_AffiliatedAccounts { get; set; } //list to show affiliates for the Multi-EIN child TTF records
	public string strMultiEINNewTTFIds { get; set; } //contains ; separated ids of newly created Multi-EIN records
	public string strWarningMessage { get; set; }
	public boolean blnIsError { get; set; } //this to stop page from redirecting if there are some errors on page
	//this variable lets us know wether we want want to close the opp or not
	boolean blnIsOppReadyForClosedWon;
	string strOpportunityId, strTTFObjId, strBenefitExternalId, strReturnURL;
	/* AccountsWrapper Section */
	Set<String> setOpportunityStatusToExclude = new Set<String>{ 'Closed Won' };
	Set<String> set_OppStagesToExcludeForAffiliateChecks = new Set<String>{ 'Closed Won', 'Order Lost', 'Closed Lost', 'Closed Admin' };
	private String strSource; //To identify the source of BTTTFDocumentUpload page

	public static final String LABEL_MEDICAL = 'Medical';
	public static final String LABEL_VISION = 'Vision';
	public static final String LABEL_LTD = 'LTD';
	public static final String LABEL_STD = 'STD';
	public static final String LABEL_LIFE = 'Life';
	public static final String LABEL_DENTAL = 'Dental';
	public static final String LABEL_LOWER_MEDICAL = 'medical';
	public static final String LABEL_LOWER_VISION = 'vision';
	public static final String LABEL_LOWER_LTD = 'ltd';
	public static final String LABEL_LOWER_STD = 'std';
	public static final String LABEL_LOWER_LIFE = 'life';
	public static final String LABEL_LOWER_DENTAL = 'dental';
	public static final String LABEL_OTHER = 'Other';
	public static final String LABEL_LOWER_LONG_TERM = 'long_term_disability';
	public static final String LABEL_LOWER_SHORT_TERM = 'short_term_disability';
	public Map<String, String> map_ContactIdRole { get; set; }

	public BTTransitionToFulfilmentExtension(apexPages.StandardController sc) {
		blnIsError = false;
		blnIsOppReadyForClosedWon = false;
		blnIsOppERConfirmed = false;
		blnBYBReason = false;
		objTTFRecord = new Transition_to_Fulfillment__c();
		map_carrierKeyBenefitDetails = new Map<string, BenefitsWrapper>();
		lst_TTFAttachmentList = new List<Attachment>();
		list_AffiliatedAccounts = new List<Account>();
		blnIsBYOBOpportunity = false;
		blnShowOrderTypePage = false;
		blnBOOrderTypeReq = false;
		blnBORDateReq = false;
		objBenefitOrder = new Benefit_Order__c();

		list_OrderTypeBO = new List<SelectOption>();
		list_OrderTypeBO.add(new selectOption('', '--None--'));
		Set<String> set_excludedOrderTypes = new Set<String>();
		set_excludedOrderTypes.addAll(UtilitiesFactory.set_TADAAndBOROrderType);
		set_excludedOrderTypes.addAll(UtilitiesFactory.set_ExcludeBYBOrderType);
		List<SelectOption> list_OrderTypeBOTemp = UtilitiesFactory.getPickListValues('Benefit_Order__c', 'Type__c', set_excludedOrderTypes);
		if (list_OrderTypeBOTemp != null && list_OrderTypeBOTemp.size() > 0) {
			list_OrderTypeBO.addAll(list_OrderTypeBOTemp);
		}

		if (apexPages.currentPage().getParameters().get('Id') != null) {
			strTTFObjId = apexPages.currentPage().getParameters().get('Id');
		} else {
			strOpportunityId = apexPages.currentPage().getParameters().get('oppId');
		}
		strReturnURL = apexPages.currentPage().getParameters().get('retURL');

		if (string.isNotBlank(strOpportunityId)) {
			objTTFRecord.Opportunity__c = strOpportunityId;
		} else if (string.isBlank(strTTFObjId)) {
			strTTFObjId = apexPages.currentPage().getParameters().get('ttfId');
		}

		lst_YesNoPicklist = new List<SelectOption>();
		lst_YesNoPicklist.add(new SelectOption('No', 'Select'));
		lst_YesNoPicklist.add(new SelectOption('Yes', 'Yes'));
		lst_YesNoPicklist.add(new SelectOption('No', 'No'));

		getBenefitsInfo(); //should be always on top of the data retriving methods
		//get attachment data for TTF detail page
		if (objTTFRecord.Id != null) {
			lst_TTFAttachmentList = getAttachmentRecords(objTTFRecord.Opportunity__c);
		}
		initializeSecondaryPOCData();
		populateExternalCoverageInfo();
		getTadaDetails();

		//Get Accounts for Multi-EIN/SameLogin
		lstAccWrapper = new List<AccountWrapper>();
		initializeAccountWrapper();
		getMultiEINAffiliateDetails();
		checkAffiliatesStatus();

		//Update/populate lists et el details for BYB
		populateBYBInfoHelper();
		getCarrierInfo();
	}

	/**This constructor is used by "BTTTFDocumentUpload" vf page. This page we are using to implement file upload functionality */
	public BTTransitionToFulfilmentExtension() {
		blnIsError = false;
		strOpportunityId = apexPages.currentPage().getParameters().get('oppId');
		strTTFObjId = apexPages.currentPage().getParameters().get('ttfId');

		if (string.isNotBlank(strTTFObjId)) {
			objTTFRecord = new Transition_to_Fulfillment__c(id = strTTFObjId);
			objTTFRecord.Opportunity__c = strOpportunityId;
		} else {
			objTTFRecord = new Transition_to_Fulfillment__c();
			objTTFRecord.Opportunity__c = strOpportunityId;
		}
		strSource = '';
		if (apexPages.currentPage().getParameters().containsKey('source')) {
			strSource = apexPages.currentPage().getParameters().get('source');
		}
		fetchAttachments();

		objAttachmentNew = new Attachment();
	}

	/*
	 * Fetch Attachemnts based on the origin of page.
	 */
	private void fetchAttachments() {
		if ('DisplayEditTTS'.equalsIgnoreCase(strSource)) {
			lst_TTFAttachmentList = getAttachmentRecords(objTTFRecord.Id);
		} else {
			lst_TTFAttachmentList = getAttachmentRecords(objTTFRecord.Opportunity__c);
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Getting the detail of carrier to be displied on UI for BYOB
	 * @Parm        : NA
	 * @Return      : void
	 **/
	public void getCarrierInfo() {
		Set<String> set_CarrierNames = new Set<String>();
		if (objTTFRecord.Medical_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.Medical_Renewal_Date__c, LABEL_MEDICAL, set_CarrierNames, false);
		}
		if (objTTFRecord.Dental_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.Dental_Renewal_Date__c, LABEL_DENTAL, set_CarrierNames, false);
		}
		if (objTTFRecord.Life_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.Life_Renewal_Date__c, LABEL_LIFE, set_CarrierNames, false);
		}
		if (objTTFRecord.Vision_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.Vision_Renewal_Date__c, LABEL_VISION, set_CarrierNames, false);
		}
		if (objTTFRecord.LTD_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.LTD_Renewal_Date__c, LABEL_LTD, set_CarrierNames, false);
		}
		if (objTTFRecord.STD_Renewal_Date__c != null) {
			retriveCarrierInfo(objTTFRecord.STD_Renewal_Date__c, LABEL_STD, set_CarrierNames, false);
		}

		if (objTTFRecord.STD_New_Line_Carrier__c != null) {
			retriveCarrierInfo(objTTFRecord.STD_New_Line_Carrier__c, LABEL_STD, set_CarrierNames, true);
		}
		if (objTTFRecord.Long_term_Disability_New_carriers__c != null) {
			retriveCarrierInfo(objTTFRecord.Long_term_Disability_New_carriers__c, LABEL_LTD, set_CarrierNames, true);
		}
		if (objTTFRecord.Vision_New_carriers__c != null) {
			retriveCarrierInfo(objTTFRecord.Vision_New_carriers__c, LABEL_VISION, set_CarrierNames, true);
		}
		if (objTTFRecord.Dental_New_carriers__c != null) {
			retriveCarrierInfo(objTTFRecord.Dental_New_carriers__c, LABEL_DENTAL, set_CarrierNames, true);
		}
		if (objTTFRecord.Life_New_Line_Carrier__c != null) {
			retriveCarrierInfo(objTTFRecord.Life_New_Line_Carrier__c, LABEL_LIFE, set_CarrierNames, true);
		}
		if (objTTFRecord.Medical_New_carriers__c != null) {
			retriveCarrierInfo(objTTFRecord.Medical_New_carriers__c, LABEL_MEDICAL, set_CarrierNames, true);
		}

		if (!set_CarrierNames.isEmpty()) {
			for (Carrier__c objCarrier : [SELECT Id, Name, Key__c FROM Carrier__c WHERE Key__c IN :set_CarrierNames]) {
				map_CarriersWithKey.put(objCarrier.Key__c, objCarrier);
			}
		}

		if (!map_CarriersWithKey.isEmpty() && !map_CarriersWithDate.isEmpty()) {
			Integer intCount = 0;
			Set<String> set_BenefitTypes = new Set<String>();
			List<Date> list_Dates = new List<Date>();

			for (String strKey : map_CarriersWithDate.keySet()) {
				List<String> list_CarriersWithDate = strKey.split('>');
				Carrier__c objCarrier = new Carrier__c();
				set_BenefitTypes = map_CarriersWithDate.get(strKey);
				Set<String> set_OtherCarrierNames = new Set<String>();

				if (list_CarriersWithDate?.size() <= 2) {
					if (map_CarriersWithKey.containsKey(list_CarriersWithDate[0])) {
						objCarrier = map_CarriersWithKey.get(list_CarriersWithDate[0]);
					}

					if (objCarrier.Name.equalsIgnoreCase(LABEL_OTHER)) {
						set_OtherCarrierNames = new Set<String>();
						for (String strBenefitType : set_BenefitTypes) {
							if (!map_BenefitTypesDateWithCarrierName.isEmpty() && map_BenefitTypesDateWithCarrierName.containsKey(strBenefitType + '>' + list_CarriersWithDate[1])) {
								set_OtherCarrierNames.addAll(map_BenefitTypesDateWithCarrierName.get(strBenefitType + '>' + list_CarriersWithDate[1]));
							}
						}
					}

					if (!set_OtherCarrierNames.isEmpty()) {
						for (String strOtherCarrierName : set_OtherCarrierNames) {
							CarrierDetailWrapper objCarrierWrapper = new CarrierDetailWrapper(
								new Case(Carrier__c = objCarrier.Id),
								new Contact(Last_Activity_Date__c = Date.valueOf(list_CarriersWithDate[1].replace('/', '-'))),
								new List<String>(set_BenefitTypes),
								true,
								intCount + 1,
								objCarrier.Name,
								objCarrier.Key__c,
								strOtherCarrierName,
								true
							);

							list_CarrierDetails.add(objCarrierWrapper);
							intCount += 1;
						}
					} else {
						CarrierDetailWrapper objCarrierWrapper = new CarrierDetailWrapper(
							new Case(Carrier__c = objCarrier.Id),
							new Contact(Last_Activity_Date__c = Date.valueOf(list_CarriersWithDate[1].replace('/', '-'))),
							new List<String>(set_BenefitTypes),
							true,
							intCount + 1,
							objCarrier.Name,
							objCarrier.Key__c,
							'',
							false
						);

						list_CarrierDetails.add(objCarrierWrapper);
						intCount += 1;
					}
				}
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Create a Maps for showing Carrier + renewal date+ Benefit Types
	 * @Parm        : strData : TTF Field Data
	 * 				  strBenefitType : Benefit Type Name
	 * 				  set_CarrierNames : Set of Carrier to Query
	 * 				  blnIsOtherCarrier : Carrier is Other or not
	 * @Return      : void
	 **/
	public void retriveCarrierInfo(String strData, String strBenefitType, Set<String> set_CarrierNames, Boolean blnIsOtherCarrier) {
		for (String strCarrierWithDate : strData.split(';')) {
			List<String> list_CarriersWithDate = strCarrierWithDate.split('>');

			if (list_CarriersWithDate?.size() <= 2) {
				Set<String> set_BenefitTypes = new Set<String>();
				Set<String> set_OtherCarrierNames = new Set<String>();
				if (!blnIsOtherCarrier) {
					set_CarrierNames.add(list_CarriersWithDate[0]);

					if (!map_CarriersWithDate.isEmpty() && map_CarriersWithDate.containsKey(strCarrierWithDate)) {
						set_BenefitTypes = map_CarriersWithDate.get(strCarrierWithDate);
					}

					set_BenefitTypes.add(strBenefitType);
					map_CarriersWithDate.put(strCarrierWithDate, set_BenefitTypes);
				} else {
					String strKey = strBenefitType + '>' + list_CarriersWithDate[1];
					if (!map_BenefitTypesDateWithCarrierName.isEmpty() && map_BenefitTypesDateWithCarrierName.containsKey(strKey)) {
						set_OtherCarrierNames = map_BenefitTypesDateWithCarrierName.get(strKey);
					}
					set_OtherCarrierNames.add(list_CarriersWithDate[0]);
					map_BenefitTypesDateWithCarrierName.put(strKey, set_OtherCarrierNames);
				}
			}
		}
	}

	/**This method is used to get the Non-Tada benefit details from "HI Carrier Information" staging object */
	public void getBenefitsInfo() {
		if (string.isNotBlank(strOpportunityId)) {
			set<string> set_CarrierExternalKey = new Set<String>();
			list<Opportunity> lst_objOpp = getOpportunityDetails(strOpportunityId);
			if (lst_objOpp.size() > 0) {
				Opportunity objOpp = lst_objOpp.get(0);
				objRelatedOpp = lst_objOpp.get(0);
				strBenefitExternalId = (objOpp.Id__c != null ? objOpp.Id__c.replace('HIBORTRANSFER', ' ').trim() : '');
				objTTFRecord.Account__c = objOpp.AccountId;
				objTTFRecord.OwnerId = objOpp.OwnerId;
				strPartnerTier = objOpp.Partner_Tier__c;
				strPartnerFirmName = objOpp.Partner_Firm_Name__c;
				if (objOpp.StageName == 'ER Confirm') {
					if (objOpp.Account.Joined_Date_Panda__c != null) {
						blnIsOppReadyForClosedWon = true;
					} else if (
						String.isNotBlank(objOpp.Benefits_Setup_Steps_Completed__c) &&
						String.valueOf(6) == objOpp.Benefits_Setup_Steps_Completed__c &&
						objOpp.Account.Anchor_Pay_Date__c != null
					) {
						Date dtAnchorDate = objOpp.Account.Anchor_Pay_Date__c;
						Date dtTodayDate = Date.today();
						Date dtNextMonthDate = dtTodayDate.addMonths(1);
						if (dtAnchorDate.month() == dtTodayDate.month() && dtAnchorDate.year() == dtTodayDate.year()) {
							blnIsOppReadyForClosedWon = true;
						} else if (dtAnchorDate.month() == dtNextMonthDate.month() && dtAnchorDate.year() == dtNextMonthDate.year()) {
							blnIsOppReadyForClosedWon = true;
						}
					}
					blnIsOppERConfirmed = true;
				}

				// additional checks for the BYB Opp as the record is created manually
				if (objOpp.RecordType.Name == OPP_RT_BENEFIT_BYB) {
					blnIsBYOBOpportunity = true;
					objTTFRecord.RecordTypeId = TTF_RT_BENEFIT_BYB;
					blnIsOppERConfirmed = blnIsOppERConfirmed && showSaveOrder(objOpp);
				}
			}
		} else if (string.isNotBlank(strTTFObjId)) {
			list<Transition_to_Fulfillment__c> lstTTFRec = getTransitionToFulfillment(strTTFObjId);
			if (lstTTFRec.size() > 0) {
				objTTFRecord = lstTTFRec.get(0);
				objRelatedOpp = new Opportunity(
					Id = objTTFRecord.Opportunity__c,
					SGHI_LGHI__c = objTTFRecord.Opportunity__r.SGHI_LGHI__c,
					Funding_Type__c = objTTFRecord.Opportunity__r.Funding_Type__c,
					Unsupported_Carrier__c = objTTFRecord.Opportunity__r.Unsupported_Carrier__c,
					RecordTypeId = objTTFRecord.Opportunity__r.RecordTypeId
				);
				if (objTTFRecord.BoR_Eligible_Medical__c == 'Y') {
					blnBYBReason = true;
				}
				if (string.isNotBlank(objTTFRecord.Opportunity__r.Id__c)) {
					strBenefitExternalId = objTTFRecord.Opportunity__r.Id__c.replace('HIBORTRANSFER', ' ').trim();
				}
				if (objTTFRecord.Opportunity__r.StageName == 'ER Confirm') {
					if (objTTFRecord.Account__r.Joined_Date_Panda__c != null) {
						blnIsOppReadyForClosedWon = true;
					} else if (
						String.isNotBlank(objTTFRecord.Opportunity__r.Benefits_Setup_Steps_Completed__c) &&
						String.valueOf(6) == objTTFRecord.Opportunity__r.Benefits_Setup_Steps_Completed__c &&
						objTTFRecord.Account__r.Anchor_Pay_Date__c != null
					) {
						Date dtAnchorDate = objTTFRecord.Account__r.Anchor_Pay_Date__c;
						Date dtTodayDate = Date.today();
						Date dtNextMonthDate = dtTodayDate.addMonths(1);
						if (dtAnchorDate.month() <= dtNextMonthDate.month() && dtAnchorDate.year() <= dtNextMonthDate.year()) {
							blnIsOppReadyForClosedWon = true;
						}
					}
					blnIsOppERConfirmed = true;
				}

				// additional checks for the BYB Opp as the record is created manually
				if (objTTFRecord.Opportunity__r.RecordType.Name == OPP_RT_BENEFIT_BYB) {
					blnIsBYOBOpportunity = true;

					blnIsOppERConfirmed = blnIsOppERConfirmed && showSaveOrder(objTTFRecord.Opportunity__r);
				}
			}
		}

		if (string.isNotBlank(strBenefitExternalId) && !blnIsBYOBOpportunity) {
			// SJay - 12/14/2020 - Added deleted_at__c check to make sure we are not querying any deleted carrier info.
			for (HI_Carrier_Information__c objHICi : [SELECT Id__c, Key__c, Plan_Type__c FROM HI_Carrier_Information__c WHERE BOR_Transfer_Id__c = :strBenefitExternalId AND Deleted_At__c = NULL]) {
				BenefitsWrapper benefitDetail;

				if (map_carrierKeyBenefitDetails.containsKey(objHICi.Key__c)) {
					benefitDetail = map_carrierKeyBenefitDetails.get(objHICi.Key__c);
				} else {
					benefitDetail = new BenefitsWrapper();
					benefitDetail.lstBenefitName = new List<string>();
				}
				benefitDetail.lstBenefitName.add(objHICi.Plan_Type__c);
				map_carrierKeyBenefitDetails.put(objHICi.Key__c, benefitDetail);
			}

			if (map_carrierKeyBenefitDetails.size() > 0) {
				map<string, Date> map_CarrierKeySelectedRenewalDate = new Map<String, Date>();
				if (objTTFRecord.Id != null) {
					if (string.isNotBlank(objTTFRecord.Medical_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.Medical_Renewal_Date__c));
					}
					if (string.isNotBlank(objTTFRecord.Dental_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.Dental_Renewal_Date__c));
					}
					if (string.isNotBlank(objTTFRecord.Vision_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.Vision_Renewal_Date__c));
					}
					if (string.isNotBlank(objTTFRecord.Life_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.Life_Renewal_Date__c));
					}
					if (string.isNotBlank(objTTFRecord.LTD_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.LTD_Renewal_Date__c));
					}
					if (string.isNotBlank(objTTFRecord.STD_Renewal_Date__c)) {
						map_CarrierKeySelectedRenewalDate.putAll(getCarrierKeySelectedDateMap(objTTFRecord.STD_Renewal_Date__c));
					}
				}

				for (Carrier__c objCarrier : [SELECT Name, Id, Id__c, Key__c FROM Carrier__c WHERE Key__c IN :map_carrierKeyBenefitDetails.keyset()]) {
					if (map_carrierKeyBenefitDetails.containsKey(objCarrier.Key__c)) {
						map_carrierKeyBenefitDetails.get(objCarrier.Key__c).objCarrier = objCarrier;
						if (map_CarrierKeySelectedRenewalDate.containsKey(objCarrier.Key__c)) {
							map_carrierKeyBenefitDetails.get(objCarrier.Key__c).objContact.Last_Activity_Date__c = map_CarrierKeySelectedRenewalDate.get(objCarrier.Key__c);
						}
					}
				}
			}
		}
	}

	void getMultiEINAffiliateDetails() {
		if (objTTFRecord.Multi_EIN__c != null && objTTFRecord.Multi_EIN__c == 'Y') {
			if (objTTFRecord.Account__r.ParentId != null) {
				list_AffiliatedAccounts = [
					SELECT Id, Name, Phone, Joined_Date_Panda__c, ParentId
					FROM Account
					WHERE (ParentId = :objTTFRecord.Account__r.ParentId OR Id = :objTTFRecord.Account__r.ParentId) AND Id != :objTTFRecord.Account__c
				];
			}
		}
	}

	void checkAffiliatesStatus() {
		// SJay - 07/28/2020 - adding more stages to exclude when checking the affiliate status.
		// Replaced setOpportunityStatusToExclude with set_OppStagesToExcludeForAffiliateChecks.
		if (objTTFRecord.Multi_EIN__c != null && objTTFRecord.Multi_EIN__c == 'Y') {
			string strQuery = 'SELECT Id,Name, Account.ParentId,Account.Name, StageName FROM Opportunity ' + ' WHERE StageName NOT IN: set_OppStagesToExcludeForAffiliateChecks AND ';
			if (objTTFRecord.Account__r.ParentId == null) {
				//if parent get all childs
				strQuery += ' Account.ParentId = \'' + objTTFRecord.Account__c + '\' ';
			} else {
				strQuery +=
					' (Account.ParentId = \'' +
					objTTFRecord.Account__r.ParentId +
					'\' OR AccountId = \'' +
					objTTFRecord.Account__r.ParentId +
					'\') AND AccountId != \'' +
					objTTFRecord.Account__c +
					'\' ';
			}

			for (Opportunity objOpp : database.query(strQuery)) {
				if (string.isBlank(strWarningMessage)) {
					strWarningMessage =
						'Action Required: Submit TTF <br/> <a href="javascript:void(0);" onclick="javascript:window.open(' +
						'\'/' +
						objOpp.AccountId +
						'\')">' +
						objOpp.Account.Name +
						'</a>';
				} else {
					strWarningMessage += ', ' + '<a href="javascript:void(0);" onclick="javascript:window.open(' + '\'/' + objOpp.AccountId + '\')">' + objOpp.Account.Name + '</a>';
				}
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Populate all the information for BYOB
	 * @Parm        : null
	 * @Return      : void
	 **/
	void populateBYBInfoHelper() {
		// populate Benefits Types for BYB selection
		list_BenefitTypes = new List<SelectOption>{
			new SelectOption(LABEL_MEDICAL, LABEL_MEDICAL),
			new SelectOption(LABEL_DENTAL, LABEL_DENTAL),
			new SelectOption(LABEL_VISION, LABEL_VISION),
			new SelectOption(LABEL_LIFE, LABEL_LIFE),
			new SelectOption(LABEL_LTD, LABEL_LTD),
			new SelectOption(LABEL_STD, LABEL_STD)
		};

		list_CarrierDetails = new List<CarrierDetailWrapper>();
		intSaveIndx = intDeleteIndx = intEditIndx = 0;
		strErrorMessage = '';
		blnIsErrorOtherCarrier = false;

		lst_priorityReasonDetails = new List<priorityReasonsWrapper>();
		for (Schema.PicklistEntry pickListVal : Transition_to_Fulfillment__c.Priority_Reasons__c.getDescribe().getPicklistValues()) {
			if (string.isNotBlank(objTTFRecord.Priority_Reasons__c) && objTTFRecord.Priority_Reasons__c.indexOf(pickListVal.getValue()) > -1) {
				lst_priorityReasonDetails.add(new priorityReasonsWrapper(pickListVal.getLabel(), pickListVal.getValue(), true));
			} else {
				lst_priorityReasonDetails.add(new priorityReasonsWrapper(pickListVal.getLabel(), pickListVal.getValue(), false));
			}
		}
	}

	/**
	 * @Description : Show the Send Order
	 * @Parm        : objOpp : Opportunity
	 * @Return      : Boolean
	 **/
	Boolean showSaveOrder(Opportunity objOpp) {
		return (!objOpp.Order_Generated__c &&
		objOpp.Handoff_Email_Sent__c &&
		objOpp.Funding_Type__c != null &&
		objOpp.BYOB_Source__c != null &&
		objOpp.SGHI_LGHI__c != null &&
		objOpp.BYOB_Broker__c != null &&
		objOpp.Renewal_Date__c != null);
	}

	private map<string, Date> getCarrierKeySelectedDateMap(string strSavedData) {
		map<string, Date> map_carrierKeyRenewalDate = new Map<String, Date>();

		if (string.isNotBlank(strSavedData)) {
			list<string> lst_individualDateStr = new List<string>();
			if (strSavedData.indexOf(';') > -1) {
				lst_individualDateStr = strSavedData.split(';');
			} else {
				lst_individualDateStr.add(strSavedData);
			}

			if (lst_individualDateStr.size() > 0) {
				for (String strDate : lst_individualDateStr) {
					if (strDate.indexOf('>') > -1) {
						list<string> lstTemp = strDate.split('>');
						if (lstTemp != null && lstTemp.size() > 0) {
							integer intYear = integer.valueOf(lstTemp.get(1).trim().split('/').get(0));
							integer intMonth = integer.valueOf(lstTemp.get(1).trim().split('/').get(1));
							integer intDay = integer.valueOf(lstTemp.get(1).trim().split('/').get(2));
							date dtRenewalDateTemp = date.newInstance(intYear, intMonth, intDay);
							map_carrierKeyRenewalDate.put(lstTemp.get(0).trim(), dtRenewalDateTemp);
						}
					}
				}
			}
		}

		return map_carrierKeyRenewalDate;
	}

	//================================Attachment handling Logic Start============================
	public void deleteAttachmentRecord() {
		if (string.isNotBlank(strAttachmentIdToDelete)) {
			set<Attachment> set_attachmentTemp = new Set<Attachment>();
			set_attachmentTemp.addAll(lst_TTFAttachmentList);
			for (Attachment objAttachment : lst_TTFAttachmentList) {
				if (string.valueOf(objAttachment.Id) == strAttachmentIdToDelete) {
					set_attachmentTemp.remove(objAttachment);
					break;
				}
			}

			lst_TTFAttachmentList = new List<Attachment>();
			lst_TTFAttachmentList.addAll(set_attachmentTemp);

			try {
				delete new Attachment(id = strAttachmentIdToDelete);
			} catch (exception ex) {
				ExceptionLogUtil.logException('BTTransitionToFulfilmentExtension', 'deleteAttachmentRecord', ex.getMessage(), 'Medium');
			}
		}
	}

	/**This method is used to upload attachment from TTF edit page */
	public void uploadAttachment() {
		if (objAttachmentNew != null && objAttachmentNew.Body != null) {
			if ('DisplayEditTTS'.equalsIgnoreCase(strSource)) {
				objAttachmentNew.ParentId = objTTFRecord.Id;
			} else {
				objAttachmentNew.ParentId = objTTFRecord.Opportunity__c;
			}

			try {
				insert objAttachmentNew;
				objAttachmentNew = new Attachment();
			} catch (exception ex) {
				Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
				return;
			}

			fetchAttachments();
		}
	}

	//================================Opportunity Role Start======================================
	/*
	 * Initialize Secondary Point of Contact Data
	 */
	private void initializeSecondaryPOCData() {
		if (null != objTTFRecord && null != objTTFRecord.Opportunity__c) {
			//Get Opportunity Contact Roles
			Id idopportunity = objTTFRecord.Opportunity__c; //Check_Additional_POC__c
			list_OpptyContactRole = getOpportunityContactRoleDetails(idopportunity);
			map_ContactIdRole = new Map<String, String>();
			if (null != list_OpptyContactRole) {
				//Check for duplicate contacts
				Map<Id, OpportunityContactRole> map_PreferredContactRole = new Map<Id, OpportunityContactRole>();

				for (OpportunityContactRole objConRole : list_OpptyContactRole) {
					map_PreferredContactRole = TransitiontoFulfilmentUtil.setPreferredContactRole(map_PreferredContactRole, objConRole);
					//map_ContactIdRole used to concatenate the role is used for displaying purpose, if Contact have multiple roles.
					if (!map_ContactIdRole.containskey(objConRole.ContactId)) {
						map_ContactIdRole.put(objConRole.ContactId, objConRole.role);
					} else {
						String strTempRole = map_ContactIdRole.get(objConRole.ContactId);
						strTempRole += ', ' + objConRole.role;
						map_ContactIdRole.put(objConRole.ContactId, strTempRole);
					}
				}
				list_POCWrapper = new List<POCWrapper>();
				Boolean blnIsPrimaryExist = false;
				//Construct Wrapper for unique contacts
				for (OpportunityContactRole objConRole : map_PreferredContactRole.values()) {
					if (objTTFRecord.Id == null) {
						if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_ADMIN && !blnIsPrimaryExist) {
							blnIsPrimaryExist = true;
							objConRole.IsPrimary = true;
							objTTFRecord.Contact__c = objConRole.contactId;
							objTTFRecord.Point_of_Contact_Phone__c = objConRole.Contact.Phone;
							objTTFRecord.Point_of_Contact_Email__c = objConRole.Contact.Email;
						} else if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_SIGNATORY) {
							objConRole.Check_Additional_POC__c = true;
							objConRole.Check_Broker_POC__c = false;
							if (objConRole.IsPrimary) {
								objConRole.IsPrimary = false;
							}
						} else {
							if (objConRole.Check_Broker_POC__c) {
								objTTFRecord.Broker_Point_of_Contact__c = objConRole.contactId;
							}
							if (objConRole.IsPrimary) {
								objConRole.IsPrimary = false;
							}
							objConRole.Check_Additional_POC__c = false;
						}
					}
					list_POCWrapper.add(new POCWrapper(objConRole, objTTFRecord.Contact__c));
				}
			}
		}
	}

	/* This method updates the Preferred Broker field for BYB */
	public void updatePreferedBroker() {
		if (blnIsBYOBOpportunity && !objTTFRecord.Handed_off_to_preferred_broker_partner__c) {
			objTTFRecord.Preferred_Broker__c = null;
		}
	}
	/* This method updates the Bor Eligible Medical field for BYB */
	public void updateBoREligibleMedical() {
		if (objTTFRecord.BoR_Eligible_Medical__c == 'Y') {
			blnBYBReason = true;
		} else {
			blnBYBReason = false;
			objTTFRecord.BYB_Reason__c = null;
		}
	}

	public void selectSecondary() {
		if (null != idSecRole) {
			for (POCWrapper poc : list_POCWrapper) {
				if (poc.objContactRole.Id == idSecRole && poc.objContactRole.Check_Additional_POC__c) {
					if (poc.boolChkPrimary) {
						poc.boolChkPrimary = false; //Uncheck the additional POC field on Primary POC
						objTTFRecord.Contact__c = null;
						poc.objContactRole.IsPrimary = false;
					}

					if (poc.objContactRole.Check_Broker_POC__c) {
						poc.objContactRole.Check_Broker_POC__c = false; //Uncheck the Broker POC field on Primary POC
						objTTFRecord.Broker_Point_of_Contact__c = null;
					}
				}
			}
		}
	}

	public void selectBroker() {
		if (null != idBrokerRole) {
			Boolean blnBrokerSet = false;

			for (POCWrapper poc : list_POCWrapper) {
				if (poc.objContactRole.Id == idBrokerRole && poc.objContactRole.Check_Broker_POC__c) {
					poc.objContactRole.Check_Additional_POC__c = false;

					if (poc.boolChkPrimary) {
						poc.boolChkPrimary = false;
						poc.objContactRole.IsPrimary = false;
						objTTFRecord.Contact__c = null;
					}

					objTTFRecord.Broker_Point_of_Contact__c = poc.objContactRole.ContactId;
					blnBrokerSet = true;
				} else {
					poc.objContactRole.Check_Broker_POC__c = false;
				}

				if (!blnBrokerSet) {
					objTTFRecord.Broker_Point_of_Contact__c = null;
				}
			}
			idBrokerRole = null;
		}
	}

	public void selectPrimary() {
		if (null != idPrimaryRole) {
			Boolean boolPrimarySet = false;

			for (POCWrapper poc : list_POCWrapper) {
				if (poc.boolChkPrimary && poc.objContactRole.Id == idPrimaryRole) {
					poc.objContactRole.Check_Additional_POC__c = false; //Uncheck the additional POC field on Primary POC

					if (poc.objContactRole.Check_Broker_POC__c) {
						poc.objContactRole.Check_Broker_POC__c = false; //Uncheck the Broker POC field on Primary POC
						objTTFRecord.Broker_Point_of_Contact__c = null;
					}
					objTTFRecord.Contact__c = poc.objContactRole.ContactId;
					objTTFRecord.Point_of_Contact_Phone__c = poc.objContactRole.Contact.Phone;
					objTTFRecord.Point_of_Contact_Email__c = poc.objContactRole.Contact.Email;
					poc.objContactRole.IsPrimary = true;
					boolPrimarySet = true;
				} else {
					poc.boolChkPrimary = false; // Uncheck all other roles set as primary POC
					poc.objContactRole.IsPrimary = false;
				}
				if (!boolPrimarySet) {
					objTTFRecord.Contact__c = null;
				}
			}
			idPrimaryRole = null;
		}
	}

	/**This method is called after TTF record is inserted or updated. This method SYNC the Contact phone and Email field with data provided by user on TTF page */
	public void syncContactDetails() {
		if (objTTFRecord != null && objTTFRecord.Contact__c != null) {
			list<Contact> lst_ContactRec = [SELECT Id, Phone, Email FROM Contact WHERE Id = :objTTFRecord.Contact__c];

			if (lst_ContactRec.size() > 0) {
				Contact obj_toSyncContactRec = new Contact(id = objTTFRecord.Contact__c);
				if (objTTFRecord.Point_of_Contact_Phone__c != null && lst_ContactRec.get(0).Phone != objTTFRecord.Point_of_Contact_Phone__c) {
					obj_toSyncContactRec.Phone = objTTFRecord.Point_of_Contact_Phone__c;
				}
				if (objTTFRecord.Point_of_Contact_Email__c != null && lst_ContactRec.get(0).Email != objTTFRecord.Point_of_Contact_Email__c) {
					obj_toSyncContactRec.Email = objTTFRecord.Point_of_Contact_Email__c;
				}

				if (obj_toSyncContactRec.Phone != null || obj_toSyncContactRec.Email != null) {
					try {
						boolean blnPreviousValue = ContactTriggerHelper.skipTrigger;
						ContactTriggerHelper.skipTrigger = true;
						update obj_toSyncContactRec;
						ContactTriggerHelper.skipTrigger = blnPreviousValue;
					} catch (exception ex) {
						ExceptionLogUtil.logException('BTTransitionToFulfilmentExtension', 'syncContactDetails', ex.getMessage(), 'Low');
					}
				}
			}
		}
	}
	//================================Opportunity Role End======================================

	/**
	 * @Author      : Deepika Saini
	 * @Description : Add New row for Carrier
	 * @Parm        : null
	 * @Return      : void
	 **/
	public void addNewCarrierRow() {
		Integer intCount = 0;
		if (list_CarrierDetails == null) {
			list_CarrierDetails = new List<CarrierDetailWrapper>();
		}
		if (!list_CarrierDetails.isEmpty()) {
			intCount = list_CarrierDetails.size();
		}

		list_CarrierDetails.add(new CarrierDetailWrapper(new Case(), new Contact(), new List<String>(), false, intCount + 1, '', '', '', false));
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Save the row of Carrier
	 * @Parm        : null
	 * @Return      : void
	 **/
	public void saveCarriers() {
		blnIsErrorOtherCarrier = false;
		strErrorMessage = '';
		if (intSaveIndx != null) {
			if (!list_CarrierDetails.isEmpty()) {
				Map<Id, Carrier__c> map_Carriers = new Map<Id, Carrier__c>();
				Set<Id> set_CarrierIds = new Set<Id>();
				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (objCarrierDetail.objCase.Carrier__c != null) {
						set_CarrierIds.add(objCarrierDetail.objCase.Carrier__c);
					}
				}
				
				if (set_CarrierIds.size() > 0) {
					map_Carriers = new Map<ID, Carrier__c>([SELECT Id, Key__c, Name FROM Carrier__c WHERE Id IN :set_CarrierIds]);
				}

				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (objCarrierDetail.intRecordIndex == intSaveIndx) {
						if (objCarrierDetail.objCase.Carrier__c == null) {
							strErrorMessage += 'Carrier Name, ';
						}
						if (objCarrierDetail.objContact.Last_Activity_Date__c == null) {
							strErrorMessage += 'Renewal Date, ';
						}
						if (objCarrierDetail.list_SelectedBenefitNames.isEmpty()) {
							strErrorMessage += 'Benefit Type, ';
						}

						if (String.isNotBlank(strErrorMessage)) {
							strErrorMessage = strErrorMessage.removeEnd(', ');
							strErrorMessage += ' is Empty';
							blnIsErrorOtherCarrier = true;
						} else {
							Carrier__c objCarrier = new Carrier__c();
							if (map_Carriers.containsKey(objCarrierDetail.objCase.Carrier__c)) {
								objCarrier = map_Carriers.get(objCarrierDetail.objCase.Carrier__c);
							}

							if (objCarrier.Key__c == null) {
								strErrorMessage += MSQ_CARRIER_KEY_MISSING;
								blnIsErrorOtherCarrier = true;
								break;
							}

							if (objCarrier.Name == 'Other' && String.isBlank(objCarrierDetail.strOtherCarrier)) {
								strErrorMessage += 'Other Carrier Name, ';
								strErrorMessage = strErrorMessage.removeEnd(', ');
								strErrorMessage += ' is Empty';
								blnIsErrorOtherCarrier = true;
								objCarrierDetail.blnIsOtherTextBoxDisplayed = true;
							} else {
								objCarrierDetail.objCase.Carrier__c = objCarrier.Id;
								objCarrierDetail.strCarrierName = objCarrier.Name;
								objCarrierDetail.strCarrierKey = objCarrier.Key__c;
								objCarrierDetail.blnIsSaved = true;
								objCarrierDetail.blnIsOtherTextBoxDisplayed = true;
							}
						}
					}
				}
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Delete the row of Carrier
	 * @Parm        : null
	 * @Return      : void
	 **/
	public void deleteCarrierName() {
		blnIsErrorOtherCarrier = false;
		strErrorMessage = '';
		List<CarrierDetailWrapper> list_CarrierDetailsNotToBeDeleted = null;

		if (intDeleteIndx != null) {
			list_CarrierDetailsNotToBeDeleted = new List<CarrierDetailWrapper>();

			if (!list_CarrierDetails.isEmpty()) {
				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (objCarrierDetail.intRecordIndex != intDeleteIndx) {
						list_CarrierDetailsNotToBeDeleted.add(objCarrierDetail);
					}
				}
			}
			list_CarrierDetails = null;
		}

		Integer intCount = 0;
		if (list_CarrierDetailsNotToBeDeleted != null && !list_CarrierDetailsNotToBeDeleted.isEmpty()) {
			list_CarrierDetails = new List<CarrierDetailWrapper>();
			for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetailsNotToBeDeleted) {
				objCarrierDetail.intRecordIndex = intCount++;
				list_CarrierDetails.add(objCarrierDetail);
			}
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Edit the row of Carrier
	 * @Parm        : null
	 * @Return      : void
	 **/
	public void editCarrierName() {
		blnIsErrorOtherCarrier = false;
		strErrorMessage = '';
		if (intEditIndx != null) {
			if (!list_CarrierDetails.isEmpty()) {
				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (objCarrierDetail.intRecordIndex == intEditIndx) {
						objCarrierDetail.blnIsSaved = false;
					}
				}
			}
		}
	}

	//==============================External coverage logic starts=============================
	private void populateExternalCoverageInfo() {
		lst_eternalCoverageDetails = new List<externalCoverageWrapper>();

		Schema.DescribeFieldResult fieldResult = Transition_to_Fulfillment__c.Lines_of_Coverage_Staying_External__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry pickListVal : ple) {
			if (string.isNotBlank(objTTFRecord.Lines_of_Coverage_Staying_External__c) && objTTFRecord.Lines_of_Coverage_Staying_External__c.indexOf(pickListVal.getValue()) > -1) {
				lst_eternalCoverageDetails.add(new externalCoverageWrapper(pickListVal.getLabel(), pickListVal.getValue(), true));
			} else {
				lst_eternalCoverageDetails.add(new externalCoverageWrapper(pickListVal.getLabel(), pickListVal.getValue(), false));
			}
		}
	}
	//==============================External coverage logic ends=============================

	//==============================Tada details Logic Starts=================================
	private void getTadaDetails() {
		optedTadaDetails = new tadaDetailWrapper('', '', '', '');

		if (string.isNotBlank(strBenefitExternalId) && (obj_BORTransfer == null || obj_BORTransfer.Id == null)) {
			getBORTransferDetails();
		}

		Boolean blnIsFirstTime = false;
		string strIsfsa, strIshsa, strIsdca, strIscommuter;
		if (
			objTTFRecord.Id != null &&
			objTTFRecord.Multi_EIN__c == 'Y' &&
			ApexPages.currentPage().getParameters().get('isFT') != null &&
			ApexPages.currentPage().getParameters().get('isFT') == 'true'
		) {
			blnIsFirstTime = true;
		}

		if (obj_BORTransfer != null && obj_BORTransfer.Id != null && string.isNotBlank(obj_BORTransfer.Additional_Information__c)) {
			BORAdditionalInformationJSON parsedData = (BORAdditionalInformationJSON) JSON.deserialize(
				obj_BORTransfer.Additional_Information__c.replace('=>', ': '),
				BORAdditionalInformationJSON.class
			);

			if (parsedData.administrators != null) {
				BORAdditionalInformationJSON.cls_administrators administrators = parsedData.administrators;
				strIsfsa = (administrators.fsa != null ? 'Transfer' : '');
				strIshsa = (administrators.hsa != null ? 'Transfer' : '');
				strIsdca = (administrators.dca != null ? 'Transfer' : '');
				strIscommuter = (administrators.commuter != null ? 'Transfer' : '');
			}
		}

		if (objTTFRecord.Id == null || blnIsFirstTime) {
			optedTadaDetails = new tadaDetailWrapper(strIsfsa, strIshsa, strIsdca, strIscommuter);
		} else {
			if (objTTFRecord.Type_of_Transfer_TADA_s__c != null && objTTFRecord.Type_of_Transfer_TADA_s__c.indexOf('FSA') > -1) {
				strIsfsa = 'Transfer';
			} else if (objTTFRecord.Type_of_TADA_s__c != null && objTTFRecord.Type_of_TADA_s__c.indexOf('Flexible Spending Account - Medical') > -1) {
				strIsfsa = 'New';
			} else {
				strIsfsa = '';
			}

			if (objTTFRecord.Type_of_Transfer_TADA_s__c != null && objTTFRecord.Type_of_Transfer_TADA_s__c.indexOf('HSA') > -1) {
				strIshsa = 'Transfer';
			} else if (objTTFRecord.Type_of_TADA_s__c != null && objTTFRecord.Type_of_TADA_s__c.indexOf('HSA') > -1) {
				strIshsa = 'New';
			} else {
				strIshsa = '';
			}

			if (objTTFRecord.Type_of_Transfer_TADA_s__c != null && objTTFRecord.Type_of_Transfer_TADA_s__c.indexOf('DCA') > -1) {
				strIsdca = 'Transfer';
			} else if (objTTFRecord.Type_of_TADA_s__c != null && objTTFRecord.Type_of_TADA_s__c.indexOf('Flexible Spending Account - Dependent Care') > -1) {
				strIsdca = 'New';
			} else {
				strIsdca = '';
			}

			if (objTTFRecord.Type_of_Transfer_TADA_s__c != null && objTTFRecord.Type_of_Transfer_TADA_s__c.indexOf('Commuter') > -1) {
				strIscommuter = 'Transfer';
			} else if (objTTFRecord.Type_of_TADA_s__c != null && objTTFRecord.Type_of_TADA_s__c.indexOf('Commuter') > -1) {
				strIscommuter = 'New';
			} else {
				strIscommuter = '';
			}

			optedTadaDetails = new tadaDetailWrapper(strIsfsa, strIshsa, strIsdca, strIscommuter);
		}
	}
	//===============================Tada details Logic Ends======================================

	//===============================Multi-EIN logic Starts======================================
	public ApexPages.StandardSetController setCon {
		get {
			if (setCon == null) {
				if (objTTFRecord.Account__c == null) {
					Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Not able to find related account. Please reload the page.'));
					return new ApexPages.StandardSetController(new List<Account>());
				}

				String strAccountQuery =
					'SELECT Id,Name,ParentId,(SELECT Id,Transition_to_Fulfillment__c FROM Benefit_Orders__r ' +
					' WHERE RecordType.Name =\'Benefits BoR\'),(SELECT Id,Source_ID__c,ZP_Company_ID_from_Account__c FROM Opportunities WHERE ' +
					' REcordType.Name=\'Company Opportunity\' AND IsCLosed = false) FROM Account WHERE RecordType.Name =\'Company\' AND ' +
					' Id IN (SELECT AccountId FROM Opportunity WHERE RecordType.NAme =\'Benefits BoR\' AND ' +
					' StageName NOT IN: setOpportunityStatusToExclude) AND ZP_Company_Id__c != NULL AND ' +
					' Id != \'' +
					objTTFRecord.Account__c +
					'\' ';

				if (String.isNotBlank(strAccName)) {
					strAccountQuery += ' AND  Name Like \'%' + strAccName + '%\'';
				}
				if (String.isNotBlank(strZPCompanyId)) {
					strAccountQuery += ' AND ZP_Company_ID__c Like \'%' + strZPCompanyId + '%\'';
				}
				strAccountQuery += ' LIMIT :QUERY_LIMIT ';
				setCon = new ApexPages.StandardSetController(Database.getQueryLocator(strAccountQuery));

				// sets the number of records to show in each page view
				setCon.setPageSize(PAGE_SIZE);
			}
			return setCon;
		}
		set;
	}

	//indicates whether there are more records after the current page set.
	public Boolean hasNext {
		get {
			return setCon.getHasNext();
		}
		set;
	}

	//indicates whether there are more records before the current page set.
	public Boolean hasPrevious {
		get {
			return setCon.getHasPrevious();
		}
		set;
	}

	//returns the page number of the current page set
	public Integer pageNumber {
		get {
			return setCon.getPageNumber();
		}
		set;
	}

	//return total number of pages for page set
	public Integer getTotalPages() {
		Decimal totalSize = setCon.getResultSize();
		Decimal pageSize = setCon.getPageSize();
		Decimal pages = totalSize / pageSize;
		return (Integer) pages.round(System.RoundingMode.CEILING);
	}

	//returns the first page of the page set
	public void first() {
		setCon.first();
		initializeAccountWrapper();
	}

	//returns the last page of the page set
	public void last() {
		setCon.last();
		initializeAccountWrapper();
	}

	//returns the previous page of the page set
	public void previous() {
		setCon.previous();
		initializeAccountWrapper();
	}

	//returns the next page of the page set
	public void next() {
		setCon.next();
		initializeAccountWrapper();
	}

	//init accounts
	public void initializeAccountWrapper() {
		boolean blnIsPageLoad = false;
		if ((lstAccWrapper == null || lstAccWrapper.size() == 0) && (mapSelectedAccounts == null || mapSelectedAccounts.size() == 0)) {
			blnIsPageLoad = true;
		}

		lstAccWrapper = new List<AccountWrapper>();
		map<Id, Account> map_alreadyRelatedAffiliates = new Map<Id, Account>();

		if (blnIsPageLoad) {
			Integer indx1 = 0;
			mapSelectedAccounts = new Map<ID, AccountWrapper>();
			for (Account objAcc : [SELECT Id, Name, ParentId FROM Account WHERE ParentId = :objTTFRecord.Account__c]) {
				mapSelectedAccounts.put(objAcc.Id, new AccountWrapper(objAcc, true, indx1));
				indx1++;
			}
		}

		Integer indx = 0;
		if (mapSelectedAccounts == null) {
			mapSelectedAccounts = new Map<ID, AccountWrapper>();
		}

		for (Account objAcc : (List<Account>) setCon.getRecords()) {
			if (mapSelectedAccounts != null && mapSelectedAccounts.containsKey(objAcc.id)) {
				lstAccWrapper.add(new AccountWrapper(objAcc, true, indx));
			} else {
				lstAccWrapper.add(new AccountWrapper(objAcc, false, indx));
			}
			indx++;
		}

		if (objTTFRecord.Multi_EIN__c != null && objTTFRecord.Multi_EIN__c == 'Y') {
			multiEINSendOrderCheck();
		}
	}

	// to add selected companies to mapSelectedAccounts
	public void selectCompany() {
		if (null != lstAccWrapper && lstAccWrapper.size() > selectedCompanyIndx) {
			AccountWrapper objSelectedAcc = lstAccWrapper[selectedCompanyIndx];

			//deselect account
			if (!objSelectedAcc.isSelected && mapSelectedAccounts.containsKey(objSelectedAcc.objAccount.Id)) {
				mapSelectedAccounts.remove(objSelectedAcc.objAccount.Id);
			} else if (objSelectedAcc.isSelected) {
				//select account
				if (null == mapSelectedAccounts)
					mapSelectedAccounts = new Map<Id, AccountWrapper>();
				mapSelectedAccounts.put(objSelectedAcc.objAccount.Id, objSelectedAcc);
			}
		}
	}
	/*
	 * REmove selected account from map
	 */
	public void removeAccount() {
		if (null != idAcccountToBeRemoved && null != mapSelectedAccounts && mapSelectedAccounts.containsKey(idAcccountToBeRemoved)) {
			mapSelectedAccounts.remove(idAcccountToBeRemoved);
			initializeAccountWrapper();
			multiEINSendOrderCheck();
		}
	}

	/*
	 * Fetch Accounts based on search criteria
	 */
	public void searchAccounts() {
		setCon = null;
		initializeAccountWrapper();
	}

	//BY:PR, Date: March-23-2020, Desc: this methods updates the parent-afifliate relationship for Multi-ein logic
	void updateMultiEINAffiliateRelationShip() {
		map<Id, Account> map_toUpdateAffiliateAccounts = new Map<Id, Account>();
		if (mapSelectedAccounts.size() > 0) {
			for (Id idAcc : mapSelectedAccounts.keySet()) {
				map_toUpdateAffiliateAccounts.put(idAcc, new Account(Id = idAcc, ParentId = objTTFRecord.Account__c));
			}
		}
		for (Opportunity objOpp : [SELECT Id, AccountId FROM Opportunity WHERE Account.ParentId = :objTTFRecord.Account__c AND StageName != :OPP_STAGE_CLOSED_WON]) {
			if (map_toUpdateAffiliateAccounts != null && !map_toUpdateAffiliateAccounts.containsKey(objOpp.AccountId)) {
				Account objAccTemp = new Account(id = objOpp.AccountId);
				objAccTemp.ParentId = null;
				map_toUpdateAffiliateAccounts.put(objAccTemp.Id, objAccTemp);
			}
		}

		try {
			boolean previousVal = AccountTriggerHelper.skipTrigger;
			AccountTriggerHelper.skipTrigger = true;
			update map_toUpdateAffiliateAccounts.values();
			AccountTriggerHelper.skipTrigger = previousVal;
		} catch (exception ex) {
		}
	}

	//BY:PR, Date: March-23-2020, Desc: this methods contains logic that controlls "send Order" display criteria of "send order will only be visible when all the affiliates have there forms signed"
	public void multiEINSendOrderCheck() {
		blnIsAffiliatesFormedSigned = true;
		if (objTTFRecord.Id != null && objTTFRecord.Opportunity__c != null && objTTFRecord.Account__c != null && objTTFRecord.Multi_EIN__c == 'Y') {
			if (mapSelectedAccounts.size() > 0) {
				Integer objAggregateResultOpportunity = [
					SELECT COUNT()
					FROM Opportunity
					WHERE AccountId IN :mapSelectedAccounts.keyset() AND RecordType.Name = 'Benefits BoR' AND Signing_Forms_Completed_Timestamp__c = NULL
				];

				if (objAggregateResultOpportunity > 0) {
					blnIsAffiliatesFormedSigned = false;
				}
			}
		}
	}
	//===============================Multi-EIN logic Ends======================================

	//============================TTF Save functionality===================================
	public void updateTAdaDetails() {
		if (optedTadaDetails != null) {
			string strTransferTadas = ' ';
			string strNewTadas = ' ';
			if (optedTadaDetails.strIsHSASelected == 'Transfer') {
				strTransferTadas = strTransferTadas + ';' + 'HSA';
			} else if (optedTadaDetails.strIsHSASelected == 'New') {
				strNewTadas = strNewTadas + ';' + 'HSA';
			}

			if (optedTadaDetails.strIsFSASelected == 'Transfer') {
				strTransferTadas = strTransferTadas + ';' + 'FSA';
			} else if (optedTadaDetails.strIsFSASelected == 'New') {
				strNewTadas = strNewTadas + ';' + 'Flexible Spending Account - Medical';
			}

			if (optedTadaDetails.strIsDCASelected == 'Transfer') {
				strTransferTadas = strTransferTadas + ';' + 'DCA';
			} else if (optedTadaDetails.strIsDCASelected == 'New') {
				strNewTadas = strNewTadas + ';' + 'Flexible Spending Account - Dependent Care';
			}

			if (optedTadaDetails.strIsCommuterSelected == 'Transfer') {
				strTransferTadas = strTransferTadas + ';' + 'Commuter';
			} else if (optedTadaDetails.strIsCommuterSelected == 'New') {
				strNewTadas = strNewTadas + ';' + 'Commuter';
			}

			objTTFRecord.Type_of_Transfer_TADA_s__c = (string.isNotBlank(strTransferTadas) ? strTransferTadas.trim().removeStart(';') : '');
			objTTFRecord.Type_of_TADA_s__c = (string.isNotBlank(strNewTadas) ? strNewTadas.trim().removeStart(';') : '');
		}
	}

	public PageReference showBenefitOrderTypePage() {
		PageReference pageRef;
		blnShowOrderTypePage = false;
		blnBOOrderTypeReq = false;
		if (objTTFRecord.Send_Order__c && blnIsBYOBOpportunity) {
			if (checkRequiredFields()) {
				return null;
			} else {
				blnShowOrderTypePage = true;
				blnBOOrderTypeReq = true;
			}
		} else {
			pageRef = saveTTFRecord();
		}
		return pageRef;
	}

	public PageReference backToTTF() {
		blnShowOrderTypePage = false;
		blnBOOrderTypeReq = false;
		blnBORDateReq = false;
		blnIsError = false;
		return null;
	}

	public Pagereference saveTTFRecord() {
		blnCreateBenefitOrder = false;
		if (blnIsBYOBOpportunity) {
			if (objBenefitOrder.Type__c == null && blnBOOrderTypeReq) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Order type for Benefit order must be selected.'));
				blnBOOrderTypeReq = true;
				blnIsError = true;
				return null;
			}
			if (objBenefitOrder.Type__c != null && objBenefitOrder.Type__c == BENEFIT_ORDER_TYPE_BYB_MID_YEAR && objBenefitOrder.BoR_Date__c == null) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'BoR Date is required'));
				blnBORDateReq = true;
				blnIsError = true;
				return null;
			}
		}

		if (checkRequiredFields()) {
			return null;
		}

		updateTAdaDetails();

		try {
			//Re-init lstOpptyContactRole and get primary contact if any
			list_OpptyContactRole = new List<OpportunityContactRole>();
			if (null != list_POCWrapper) {
				for (POCWrapper poc : list_POCWrapper) {
					list_OpptyContactRole.add(poc.objContactRole);
				}
			}

			//sync
			if (objTTFRecord.Multi_EIN__c == 'Y' && !blnIsBYOBOpportunity) {
				updateMultiEINAffiliateRelationShip();
			}

			if (objTTFRecord.Id == null) {
				objTTFRecord.RecordTypeId = blnIsBYOBOpportunity ? TransitiontoFulfilmentUtil.strBenBybRecTypeId : TransitiontoFulfilmentUtil.strBenBorRecTypeId;
				insert objTTFRecord;

				if (objTTFRecord.Send_Order__c) {
					blnCreateBenefitOrder = true;
				}
			} else {
				if (!objTTFRecord.Opportunity__r.Order_Generated__c && objTTFRecord.Send_Order__c) {
					blnCreateBenefitOrder = true;
				}
				update objTTFRecord;
			}

			if (blnCreateBenefitOrder && blnIsBYOBOpportunity) {
				BenefitOrderHelperFunctions objBOCreationUtil = new BenefitOrderHelperFunctions();
				objBOCreationUtil.dateBOR = objBenefitOrder.BoR_Date__c;
				objBOCreationUtil.strBenefitOrderType = objBenefitOrder.Type__c;
				Map<Id, Transition_To_Fulfillment__c> map_NewTTFRec = new Map<Id, Transition_To_Fulfillment__c>();
				map_NewTTFRec.put(objTTFRecord.Id, objTTFRecord);
				objBOCreationUtil.createBenefitOrder(null, null, map_NewTTFRec, null);
			}

			if (null != list_OpptyContactRole && list_OpptyContactRole.size() > 0) {
				Database.update(list_OpptyContactRole);
			}

			//calling method to sync contact data "Phone and Email" provided by user back to Contact record.
			syncContactDetails();

			/*if payroll has run and sales has  "send order" update the related Opp to "Closed Won",
			 If payroll has not run but sales has "send Order" update opp to "Pending PR"*/
			list<Opportunity> list_objOpp = new List<Opportunity>();
			if (objTTFRecord.Send_Order__c == true) {
				//or condition is for Multi EIN removal
				if (!blnIsBYOBOpportunity) {
					if (blnIsOppReadyForClosedWon || (objTTFRecord.Multi_EIN__c == 'Y' && objTTFRecord.Account__r.ParentId == null && objTTFRecord.Opportunity__r.StageName == OPP_STAGE_CLOSED_WON)) {
						list_objOpp.add(new Opportunity(Id = objTTFRecord.Opportunity__c, StageName = OPP_STAGE_CLOSED_WON));
					} else if (blnIsOppERConfirmed) {
						list_objOpp.add(new Opportunity(Id = objTTFRecord.Opportunity__c, StageName = OPP_STAGE_PENDING_PR));
					}
				}

				//If parent TTF has been "Send Order" this is the time we want to create TTF for affiliates.
				if (objTTFRecord.Multi_EIN__c != null && objTTFRecord.Multi_EIN__c == 'Y' && objTTFRecord.Account__r.ParentId == null) {
					createTTFRecordsForAffiliatedCompanies();
				}
			}

			if (!list_objOpp.isEmpty()) {
				Opportunity objOppToUpdate = list_objOpp[0];
				objOppToUpdate.SGHI_LGHI__c = objRelatedOpp.SGHI_LGHI__c;
				objOppToUpdate.Funding_Type__c = objRelatedOpp.Funding_Type__c;
				objOppToUpdate.Unsupported_Carrier__c = objRelatedOpp.Unsupported_Carrier__c;
			} else {
				list_objOpp.add(objRelatedOpp);
			}

			if (list_objOpp.size() != null) {
				update list_objOpp;
			}

			if (objTTFRecord.Multi_EIN__c == null || objTTFRecord.Multi_EIN__c == 'N' || objTTFRecord.Account__r.ParentId != null || objTTFRecord.Send_Order__c == false) {
				ApexPages.PageReference pageRef = new ApexPages.PageReference('/' + objTTFRecord.Opportunity__c);
				return pageRef;
			} else if (objTTFRecord.Send_Order__c && blnIsBYOBOpportunity) {
				ApexPages.PageReference pageRef = new ApexPages.PageReference('/' + objTTFRecord.Opportunity__c);
				return pageRef;
			}
			return null;
		} catch (Exception ex) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		return null;
	}

	/**This method is called on click of "Cancel" button from page */
	public Pagereference cancelPage() {
		return new Pagereference(strReturnURL);
	}

	//BY:PR, Date: March-23-2020, Desc: in the following method we are creating TTF records for affiliates in Multi-EIN logic
	void createTTFRecordsForAffiliatedCompanies() {
		list<Transition_to_Fulfillment__c> list_NewTTFRecords = new List<Transition_to_Fulfillment__c>();
		//get already present TTF records
		map<string, Transition_to_Fulfillment__c> map_OpportunityIdTTFRecord = new Map<string, Transition_to_Fulfillment__c>();

		if (objTTFRecord.Send_Order__c) {
			for (Transition_to_Fulfillment__c objTTF : [
				SELECT Id, Opportunity__c, Multi_EIN__c
				FROM Transition_to_Fulfillment__c
				WHERE Opportunity__r.Account.ParentId = :objTTFRecord.Account__c AND RecordType.Name = 'Benefits BoR' AND Opportunity__r.StageName NOT IN :setOpportunityStatusToExclude
			]) {
				objTTF.Multi_EIN__c = 'Y';
				map_OpportunityIdTTFRecord.put(objTTF.Opportunity__c, objTTF);
			}

			// TTF will get created from Parent Company TTF. This was for child TTFs below query should return "zero rows"
			for (Opportunity objOpp : [
				SELECT Id, AccountId
				FROM Opportunity
				WHERE
					RecordType.Name = 'Benefits BoR'
					AND Account.ParentId = :objTTFRecord.Account__c
					AND ID NOT IN (SELECT Opportunity__c FROM Transition_to_Fulfillment__c WHERE Opportunity__r.Account.ParentID = :objTTFRecord.Account__c)
			]) {
				Transition_to_Fulfillment__c objNewTTF = objTTFRecord.clone(false, false, false, false);
				objNewTTF.Opportunity__c = objOpp.Id;
				objnewTTF.Account__c = objOpp.AccountId;
				objnewTTF.Send_Order__c = false;
				objnewTTF.Benefits_Point_of_Contact__c = null;
				objnewTTF.HSA_Renewal_Date__c = null;
				objnewTTF.FSA_Renewal_Date__c = null;
				objnewTTF.DCA_Renewal_Date__c = null;
				objnewTTF.Commuter_Renewal_Date__c = null;
				objnewTTF.Medical_Renewal_Date__c = null;
				objnewTTF.Dental_Renewal_Date__c = null;
				objnewTTF.Vision_Renewal_Date__c = null;
				objnewTTF.Life_Renewal_Date__c = null;
				objnewTTF.LTD_Renewal_Date__c = null;
				objnewTTF.STD_Renewal_Date__c = null;
				objnewTTF.Type_of_Transfer_TADA_s__c = null;
				objnewTTF.Type_of_TADA_s__c = null;
				objnewTTF.Medical_Carrier__c = null;
				objnewTTF.Dental_Carrier__c = null;
				objnewTTF.Vision_Carrier__c = null;
				objnewTTF.LTD_Carrier__c = null;
				objnewTTF.STD_Carrier__c = null;
				list_NewTTFRecords.add(objnewTTF);
			}
		}

		try {
			if (map_OpportunityIdTTFRecord.size() > 0) {
				list_NewTTFRecords.addAll(map_OpportunityIdTTFRecord.values());
			}
			if (list_NewTTFRecords.size() > 0) {
				upsert list_NewTTFRecords;

				strMultiEINNewTTFIds = '';
				for (Transition_to_Fulfillment__c objTTF : list_NewTTFRecords) {
					if (string.isBlank(strMultiEINNewTTFIds)) {
						strMultiEINNewTTFIds = objTTF.Id;
					} else {
						strMultiEINNewTTFIds += ';' + objTTF.Id;
					}
				}
			}
		} catch (exception ex) {
			apexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
		}
	}

	//======================Utils====================================================================
	HI_BoR_Transfer__c obj_BORTransfer = new HI_BoR_Transfer__c();

	private void getBORTransferDetails() {
		if (string.isNotBlank(strBenefitExternalId)) {
			list<HI_BoR_Transfer__c> lst_borTransfer = [SELECT Id, Additional_Information__c FROM HI_BoR_Transfer__c WHERE Id__c = :strBenefitExternalId];
			if (lst_borTransfer.size() > 0) {
				obj_BORTransfer = lst_borTransfer.get(0);
			}
		}
	}

	private list<OpportunityContactRole> getOpportunityContactRoleDetails(Id oppId) {
		if (oppId != null) {
			return [
				SELECT OpportunityId, Contact.FirstName, Contact.LastName, Role, Check_Additional_POC__c, Check_Broker_POC__c, Contact.Phone, Contact.Email, IsPrimary
				FROM OpportunityContactRole
				WHERE OpportunityId = :oppId
			];
		}
		return new List<OpportunityContactRole>();
	}

	private list<Opportunity> getOpportunityDetails(string strOpportunityId) {
		if (string.isNotBlank(strOpportunityId)) {
			return [
				SELECT
					Id,
					Id__c,
					AccountId,
					StageName,
					Account.Joined_Date_Panda__c,
					Account.Anchor_Pay_Date__c,
					Benefits_Setup_Steps_Completed__c,
					OwnerId,
					RecordTypeId,
					RecordType.Name,
					Partner_Tier__c,
					Partner_Firm_Name__c,
					Funding_Type__c,
					BYOB_Source__c,
					SGHI_LGHI__c,
					BYOB_Broker__c,
					Renewal_Date__c,
					Handoff_Email_Sent__c,
					Order_Generated__c,
					Unsupported_Carrier__c
				FROM Opportunity
				WHERE Id = :strOpportunityId
			];
		}
		return new List<Opportunity>();
	}

	private list<Transition_to_Fulfillment__c> getTransitionToFulfillment(String strTTFId) {
		List<String> list_Fields = new List<String>(Transition_to_Fulfillment__c.SObjectType.getDescribe().fields.getMap().keySet());
		if (String.isNotBlank(strTTFId)) {
			String strWhereClause = ' WHERE Id = :strTTFId';
			String strTTFSOQL =
				'Select Account__r.Joined_Date_Panda__c,Account__r.Anchor_Pay_Date__c,Opportunity__r.Benefits_Setup_Steps_Completed__c, Benefit_Order__r.Name,Account__r.ParentId,Account__r.Name,Contact__r.Name,Broker_Point_of_Contact__r.Name,Opportunity__r.Id__c,Opportunity__r.Name,Opportunity__r.StageName,Opportunity__r.RecordTypeId,Opportunity__r.RecordType.Name,Opportunity__r.Partner_Tier__c,Opportunity__r.Partner_Firm_Name__c,Opportunity__r.Funding_Type__c,Opportunity__r.BYOB_Source__c,Opportunity__r.SGHI_LGHI__c,Opportunity__r.BYOB_Broker__c,Opportunity__r.Renewal_Date__c,Opportunity__r.Handoff_Email_Sent__c,Opportunity__r.Order_Generated__c,' +
				String.join(list_Fields, ',') +
				',Opportunity__r.Unsupported_Carrier__c, Opportunity__r.PEO__c' +
				' FROM Transition_to_Fulfillment__c' +
				strWhereClause;
			return Database.query(strTTFSOQL);
		}
		return new List<Transition_to_Fulfillment__c>();
	}

	private list<Attachment> getAttachmentRecords(Id idParentId) {
		if (idParentId != null) {
			list<Attachment> list_temp = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :idParentId];

			return list_temp;
		}
		return new List<Attachment>();
	}

	//==============================================Validation Starts===============================

	public void populateRenewalDateandCarrier(
		Set<String> setBenefitTypes,
		Map<String, String> map_BenefitTypesWithDate,
		Map<String, String> map_BenefitTypesWithCarrier,
		Map<String, String> map_BenefitTypesWithOtherCarrier,
		Transition_To_Fulfillment__c objTTFRecord
	) {
		Map<String, String> map_BenefitTypesWithRenewalDateField = new Map<String, String>{
			LABEL_LOWER_MEDICAL => 'Medical_Renewal_Date__c',
			LABEL_LOWER_DENTAL => 'Dental_Renewal_Date__c',
			LABEL_LOWER_VISION => 'Vision_Renewal_Date__c',
			LABEL_LOWER_LIFE => 'Life_Renewal_Date__c',
			LABEL_LOWER_LONG_TERM => 'LTD_Renewal_Date__c',
			LABEL_LOWER_SHORT_TERM => 'STD_Renewal_Date__c',
			LABEL_LOWER_LTD => 'LTD_Renewal_Date__c',
			LABEL_LOWER_STD => 'STD_Renewal_Date__c'
		};

		Map<String, String> map_BenefitTypesWithCarrierField = new Map<String, String>{
			LABEL_LOWER_MEDICAL => 'Medical_Carrier__c',
			LABEL_LOWER_DENTAL => 'Dental_Carrier__c',
			LABEL_LOWER_VISION => 'Vision_Carrier__c',
			LABEL_LOWER_LIFE => 'LiDi_Carrier__c',
			LABEL_LOWER_LONG_TERM => 'LTD_Carrier__c',
			LABEL_LOWER_SHORT_TERM => 'STD_Carrier__c',
			LABEL_LOWER_LTD => 'LTD_Carrier__c',
			LABEL_LOWER_STD => 'STD_Carrier__c'
		};
		Map<String, String> map_BenefitTypesWithOtherCarrierField = new Map<String, String>{
			LABEL_LOWER_MEDICAL => 'Medical_New_carriers__c',
			LABEL_LOWER_DENTAL => 'Dental_New_carriers__c',
			LABEL_LOWER_VISION => 'Vision_New_carriers__c',
			LABEL_LOWER_LIFE => 'Life_New_Line_Carrier__c',
			LABEL_LOWER_LTD => 'Long_term_Disability_New_carriers__c',
			LABEL_LOWER_STD => 'STD_New_Line_Carrier__c'
		};

		objTTFRecord.Medical_Carrier__c = null;
		objTTFRecord.Medical_Renewal_Date__c = null;
		objTTFRecord.Dental_Carrier__c = null;
		objTTFRecord.Dental_Renewal_Date__c = null;
		objTTFRecord.LiDi_Carrier__c = null;
		objTTFRecord.LTD_Carrier__c = null;
		objTTFRecord.LTD_Renewal_Date__c = null;
		objTTFRecord.STD_Carrier__c = null;
		objTTFRecord.STD_Renewal_Date__c = null;
		objTTFRecord.Vision_Carrier__c = null;
		objTTFRecord.Vision_Renewal_Date__c = null;
		objTTFRecord.Life_Renewal_Date__c = null;

		for (String strBenfitType : setBenefitTypes) {
			String strBenfitTypeLower = strBenfitType.toLowerCase();
			String strRenewalFieldName, strCarrierFieldName, strOtherCarrierField;

			if (map_BenefitTypesWithRenewalDateField?.containsKey(strBenfitTypeLower)) {
				strRenewalFieldName = map_BenefitTypesWithRenewalDateField.get(strBenfitTypeLower);
			}

			if (map_BenefitTypesWithCarrierField?.containsKey(strBenfitTypeLower)) {
				strCarrierFieldName = map_BenefitTypesWithCarrierField.get(strBenfitTypeLower);
			}

			if (blnIsBYOBOpportunity && map_BenefitTypesWithOtherCarrierField?.containsKey(strBenfitTypeLower)) {
				strOtherCarrierField = map_BenefitTypesWithOtherCarrierField.get(strBenfitTypeLower);
			}

			if (String.isNotBlank(strRenewalFieldName) && String.isNotBlank(strCarrierFieldName) && map_BenefitTypesWithDate.containsKey(strBenfitTypeLower)) {
				objTTFRecord.put(strRenewalFieldName, map_BenefitTypesWithDate.get(strBenfitTypeLower));
				if (map_BenefitTypesWithCarrier.containsKey(strBenfitTypeLower))
					objTTFRecord.put(strCarrierFieldName, map_BenefitTypesWithCarrier.get(strBenfitTypeLower));
			}

			if (String.isNotBlank(strOtherCarrierField) && map_BenefitTypesWithOtherCarrier.containsKey(strBenfitTypeLower)) {
				objTTFRecord.put(strOtherCarrierField, map_BenefitTypesWithOtherCarrier.get(strBenfitTypeLower));
			}
		}
	}

	//**this mthod contains all the validation logic and is called before the save method */
	public boolean checkRequiredFields() {
		blnIsError = false;
		blnIsErrorOtherCarrier = false;
		Map<String, String> map_BenefitNamesOtherDateString = new Map<String, String>();
		Map<String, String> map_BenefitNameDateString = new Map<String, String>();
		Map<String, String> map_BenefitNameCarrierNameStr = new Map<String, String>();

		if (!blnIsBYOBOpportunity && map_carrierKeyBenefitDetails != null && map_carrierKeyBenefitDetails.size() > 0) {
			for (BenefitsWrapper benefitInfo : map_carrierKeyBenefitDetails.values()) {
				if (benefitInfo.lstBenefitName.size() > 0) {
					if (benefitInfo.objContact.Last_Activity_Date__c == null) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, MSQ_RENEWAL_DATE_MISSING));
						blnIsError = true;
						break;
					}

					if (benefitInfo.objContact.Last_Activity_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(benefitInfo.objContact.Last_Activity_Date__c)) {
						apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, MSQ_INVALID_RENEWAL_DATE));
						blnIsError = true;
						break;
					}

					for (string benefitName : benefitInfo.lstBenefitName) {
						string dateStr;
						if (map_BenefitNameDateString.containsKey(benefitName)) {
							dateStr = map_BenefitNameDateString.get(benefitName);
						}

						string tempdate =
							string.valueOf(benefitInfo.objContact.Last_Activity_Date__c.Year()) +
							'/' +
							string.valueOf(benefitInfo.objContact.Last_Activity_Date__c.Month()) +
							'/' +
							string.valueOf(benefitInfo.objContact.Last_Activity_Date__c.Day());

						if (string.isNotBlank(dateStr)) {
							dateStr = dateStr + ';' + benefitInfo.objCarrier.Key__c + '>' + tempdate;
						} else {
							dateStr = benefitInfo.objCarrier.Key__c + '>' + tempdate;
						}

						map_BenefitNameDateString.put(benefitName, dateStr);
						if (map_BenefitNameCarrierNameStr.containsKey(benefitName)) {
							string strCarrierName = map_BenefitNameCarrierNameStr.get(benefitName);
							strCarrierName = strCarrierName + ';' + benefitInfo.objCarrier.Name;
							map_BenefitNameCarrierNameStr.put(benefitName, strCarrierName);
						} else {
							map_BenefitNameCarrierNameStr.put(benefitName, benefitInfo.objCarrier.Name);
						}
					}
				}
			}
		}

		if (list_CarrierDetails?.size() > 0 && blnIsBYOBOpportunity) {
			Set<String> set_CarrierId = new Set<String>();
			for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
				if (objCarrierDetail.objCase.Carrier__c == null) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_CARRIER_MISSING));
					blnIsError = true;
					break;
				}

				if (objCarrierDetail.list_SelectedBenefitNames.isEmpty()) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_BENEFIT_TYPE_MISSING));
					blnIsError = true;
					break;
				}
				if (objCarrierDetail.objContact.Last_Activity_Date__c == null) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_RENEWAL_DATE_MISSING));
					blnIsError = true;
					break;
				}

				if (objCarrierDetail.objContact.Last_Activity_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(objCarrierDetail.objContact.Last_Activity_Date__c)) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_INVALID_RENEWAL_DATE));
					blnIsError = true;
					break;
				}

				if (!objCarrierDetail.blnIsSaved)
					set_CarrierId.add(objCarrierDetail.objCase.Carrier__c);
			}

			if (!set_CarrierId.isEmpty()) {
				Map<Id, Carrier__c> map_Carriers = new Map<Id, Carrier__c>();
				for (Carrier__c objCarrier : [SELECT Id, Key__c, Name FROM Carrier__c WHERE Id IN :set_CarrierId]) {
					map_Carriers.put(objCarrier.Id, objCarrier);
				}

				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (!map_Carriers.isEmpty() && map_Carriers.containsKey(objCarrierDetail.objCase.Carrier__c)) {
						objCarrierDetail.strCarrierName = map_Carriers.get(objCarrierDetail.objCase.Carrier__c).Name;
						if (objCarrierDetail.strCarrierName == LABEL_OTHER && String.isBlank(objCarrierDetail.strOtherCarrier)) {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_ENTER_OTHER_CARRIER_NAME));
							blnIsError = true;
							break;
						}

						objCarrierDetail.strCarrierKey = map_Carriers.get(objCarrierDetail.objCase.Carrier__c).Key__c;

						if (String.isBlank(objCarrierDetail.strCarrierKey)) {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_CARRIER_KEY_MISSING));
							blnIsError = true;
							break;
						}

						objCarrierDetail.blnIsSaved = true;
					}
				}
			}

			if (!blnIsError) {
				Map<Id, Carrier__c> map_Carriers = new Map<Id, Carrier__c>();
				if (!set_CarrierId.isEmpty()) {
					for (Carrier__c objCarrier : [SELECT Id, Key__c, Name FROM Carrier__c WHERE Id IN :set_CarrierId]) {
						map_Carriers.put(objCarrier.Id, objCarrier);
					}
				}

				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					if (!map_Carriers.isEmpty() && map_Carriers.containsKey(objCarrierDetail.objCase.Carrier__c)) {
						objCarrierDetail.strCarrierName = map_Carriers.get(objCarrierDetail.objCase.Carrier__c).Name;
						objCarrierDetail.strCarrierKey = map_Carriers.get(objCarrierDetail.objCase.Carrier__c).Key__c;
						objCarrierDetail.blnIsSaved = true;
					}
				}

				for (CarrierDetailWrapper objCarrierDetail : list_CarrierDetails) {
					for (String strBenefitName : objCarrierDetail.list_SelectedBenefitNames) {
						String strBenfitNameLower = strBenefitName.toLowerCase();
						String strOtherDate, strDate;
						if (objCarrierDetail.strCarrierName.equalsIgnoreCase(LABEL_OTHER)) {
							if (map_BenefitNamesOtherDateString.containsKey(strBenfitNameLower)) {
								strOtherDate = map_BenefitNamesOtherDateString.get(strBenfitNameLower);
							}
						}

						if (map_BenefitNameDateString.containsKey(strBenfitNameLower)) {
							strDate = map_BenefitNameDateString.get(strBenfitNameLower);
						}

						String strTempDate =
							String.valueOf(objCarrierDetail.objContact.Last_Activity_Date__c.Year()) +
							'/' +
							String.valueOf(objCarrierDetail.objContact.Last_Activity_Date__c.Month()) +
							'/' +
							String.valueOf(objCarrierDetail.objContact.Last_Activity_Date__c.Day());

						if (String.isNotBlank(strDate)) {
							strDate = strDate + ';' + objCarrierDetail.strCarrierKey + '>' + strTempDate;
						} else {
							strDate = objCarrierDetail.strCarrierKey + '>' + strTempDate;
						}

						if (String.isNotBlank(objCarrierDetail.strOtherCarrier)) {
							if (String.isNotBlank(strOtherDate)) {
								strOtherDate = strOtherDate + ';' + objCarrierDetail.strOtherCarrier + '>' + strTempDate;
							} else {
								strOtherDate = objCarrierDetail.strOtherCarrier + '>' + strTempDate;
							}
						}

						if (String.isNotBlank(strOtherDate)) {
							map_BenefitNamesOtherDateString.put(strBenfitNameLower, strOtherDate);
						}

						map_BenefitNameDateString.put(strBenfitNameLower, strDate);
						if (map_BenefitNameCarrierNameStr.containsKey(strBenfitNameLower)) {
							String strCarrierName = map_BenefitNameCarrierNameStr.get(strBenfitNameLower);
							strCarrierName = strCarrierName + ';' + objCarrierDetail.strCarrierName;
							map_BenefitNameCarrierNameStr.put(strBenfitNameLower, strCarrierName);
						} else {
							map_BenefitNameCarrierNameStr.put(strBenfitNameLower, objCarrierDetail.strCarrierName);
						}
					}
				}
			}
		}

		if (!blnIsError) {
			Set<String> set_BenefitTypes = null;
			if (!blnIsBYOBOpportunity) {
				set_BenefitTypes = new Set<String>{ LABEL_LOWER_MEDICAL, LABEL_LOWER_DENTAL, LABEL_LOWER_VISION, LABEL_LOWER_LIFE, LABEL_LOWER_LONG_TERM, LABEL_LOWER_SHORT_TERM };
			} else {
				set_BenefitTypes = new Set<String>{ LABEL_MEDICAL, LABEL_DENTAL, LABEL_VISION, LABEL_LIFE, LABEL_LTD, LABEL_STD };
			}
			populateRenewalDateandCarrier(set_BenefitTypes, map_BenefitNameDateString, map_BenefitNameCarrierNameStr, map_BenefitNamesOtherDateString, objTTFRecord);
		}

		if (objTTFRecord.Contact__c == null) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Primary point of Contact is required.'));
			blnIsError = true;
		}

		if (objTTFRecord.Broker_Point_of_Contact__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_BROKER_CONTACT_EMPTY));
			blnIsError = true;
		}

		if (objRelatedOpp.SGHI_LGHI__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_SGHI_LGHI_EMPTY));
			blnIsError = true;
		}

		if (objRelatedOpp.Funding_Type__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_FUNDING_TYPE_EMPTY));
			blnIsError = true;
		}

		if (objTTFRecord.PEO__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_PEO_SWITCHER_EMPTY));
			blnIsError = true;
		}

		if (objTTFRecord.Preferred_Broker__c == null && blnIsBYOBOpportunity && objTTFRecord.Handed_off_to_preferred_broker_partner__c) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_PREFERRED_BROKER_EMPTY));
			blnIsError = true;
		}
		if (objTTFRecord.Broker_Loyal__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_BROKER_LOYAL_EMPTY));
			blnIsError = true;
		}
		if (objTTFRecord.BoR_Eligible_Medical__c == null && blnIsBYOBOpportunity) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_BOR_ED_EMPTY));
			blnIsError = true;
		}
		if (objTTFRecord.BoR_Eligible_Medical__c == 'Y' && blnIsBYOBOpportunity && objTTFRecord.BYB_Reason__c == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, MSQ_BYB_REASON_EMPTY));
			blnIsError = true;
		}
		if (optedTadaDetails != null) {
			if (optedTadaDetails.strIsHSASelected == 'Transfer' && objTTFRecord.HSA_Renewal_Date__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'HSA renewal date is required.'));
				blnIsError = true;
			}

			if (optedTadaDetails.strIsHSASelected == 'Transfer' && objTTFRecord.HSA_Renewal_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(objTTFRecord.HSA_Renewal_Date__c)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'HSA renewal date must be in the future, within the next year, 1st or 15th of month.'));
				blnIsError = true;
			}

			if (optedTadaDetails.strIsFSASelected == 'Transfer' && objTTFRecord.FSA_Renewal_Date__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'FSA renewal date is required.'));
				blnIsError = true;
			}

			if (optedTadaDetails.strIsFSASelected == 'Transfer' && objTTFRecord.FSA_Renewal_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(objTTFRecord.FSA_Renewal_Date__c)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'FSA renewal date must be in the future, within the next year, 1st or 15th of month.'));
				blnIsError = true;
			}

			if (optedTadaDetails.strIsDCASelected == 'Transfer' && objTTFRecord.DCA_Renewal_Date__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'DCA renewal date is required.'));
				blnIsError = true;
			}

			if (optedTadaDetails.strIsDCASelected == 'Transfer' && objTTFRecord.DCA_Renewal_Date__c != null && !UtilitiesFactory.isBTRenewalDateValid(objTTFRecord.DCA_Renewal_Date__c)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'DCA renewal date must be in the future, within the next year, 1st or 15th of month.'));
				blnIsError = true;
			}
		}

		if (objTTFRecord.Exception_Request__c != null && objTTFRecord.Exception_Request__c == 'Yes') {
			if (objTTFRecord.Reason_for_exception_request__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Exception reason is required.'));
				blnIsError = true;
			}

			if (objTTFRecord.Admin_Commited_High_Response_Level__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please select when admin committed to high level of responsiveness.'));
				blnIsError = true;
			}

			if (objTTFRecord.BA_sent_expectation_setting_macro_to_ER__c == null) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please select Yes OR No for BA sent expectation setting macro to ER.'));
				blnIsError = true;
			}
		}

		if (string.isBlank(objTTFRecord.Any_lines_of_coverage_staying_external__c) && !blnIsBYOBOpportunity) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Field cannot be blank: Line of coverage staying external.'));
			blnIsError = true;
		}

		if (objTTFRecord.Any_lines_of_coverage_staying_external__c == 'Y') {
			string strSelectedExternalLine = '';
			for (externalCoverageWrapper wrapperRec : lst_eternalCoverageDetails) {
				if (wrapperRec.bln_isSelected) {
					if (string.isBlank(strSelectedExternalLine)) {
						strSelectedExternalLine = wrapperRec.str_apiName;
					} else {
						strSelectedExternalLine = strSelectedExternalLine + ';' + wrapperRec.str_apiName;
					}
				}
			}

			if (string.isBlank(strSelectedExternalLine)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please select at least one line of coverage staying external.'));
				blnIsError = true;
			} else {
				objTTFRecord.Lines_of_Coverage_Staying_External__c = strSelectedExternalLine;
			}

			if (string.isBlank(objTTFRecord.Additional_Comments_Lines_of_Coverage__c)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please enter Additional Comments when customer has external lines of coverage.'));
				blnIsError = true;
			}
		}

		if (blnIsBYOBOpportunity && String.isBlank(objTTFRecord.Medical_Carrier__c)) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please enter/select Carrier with Medical Benefits for BYB.'));
			blnIsError = true;
		}

		if (objTTFRecord.Priority__c == 'Y') {
			string strSelectedPriorityReasons = '';
			for (priorityReasonsWrapper wrapperRec : lst_priorityReasonDetails) {
				if (wrapperRec.bln_isSelected) {
					if (string.isBlank(strSelectedPriorityReasons)) {
						strSelectedPriorityReasons = wrapperRec.str_apiName;
					} else {
						strSelectedPriorityReasons = strSelectedPriorityReasons + ';' + wrapperRec.str_apiName;
					}
				}
			}

			if (string.isBlank(strSelectedPriorityReasons)) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please select at least one priority reasons.'));
				blnIsError = true;
			} else {
				objTTFRecord.Priority_Reasons__c = strSelectedPriorityReasons;
			}
		}

		if (objTTFRecord.Requires_Open_Enrollment_on_Gusto__c == null && blnIsBYOBOpportunity) {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please select Requires Open Enrollment on Gusto?'));
			blnIsError = true;
		}

		return blnIsError;
	}

	public class tadaDetailWrapper {
		public string strIsFSASelected { get; set; }
		public string strIsHSASelected { get; set; }
		public string strIsDCASelected { get; set; }
		public string strIsCommuterSelected { get; set; }

		public tadaDetailWrapper(string isFSA, string isHSA, string isDCA, string isCommuter) {
			strIsFSASelected = isFSA;
			strIsHSASelected = isHSA;
			strIsDCASelected = isDCA;
			strIsCommuterSelected = isCommuter;
		}
	}

	/*
	 * WRapper for Point of contacts on TTF
	 */
	public class POCWrapper {
		public OpportunityContactRole objContactRole { get; set; }
		public Boolean boolChkPrimary { get; set; }

		public POCWrapper(OpportunityContactRole oppContactRole, Id idPContact) {
			objContactRole = oppContactRole;
			if (idPContact == oppContactRole.ContactId) {
				boolChkPrimary = true;
			} else {
				boolChkPrimary = false;
			}
		}
	}

	public class externalCoverageWrapper {
		public string str_benefitName { get; set; }
		public string str_apiName { get; set; }
		public boolean bln_isSelected { get; set; }

		public externalCoverageWrapper(string bName, string bApiName, boolean isSelected) {
			str_benefitName = bName;
			str_apiName = bApiName;
			bln_isSelected = isSelected;
		}
	}

	public class priorityReasonsWrapper {
		public string str_reasonName { get; set; }
		public string str_apiName { get; set; }
		public boolean bln_isSelected { get; set; }

		public priorityReasonsWrapper(string bName, string bApiName, boolean isSelected) {
			str_reasonName = bName;
			str_apiName = bApiName;
			bln_isSelected = isSelected;
		}
	}

	/*
	 * WRapper for showing Accounts on TTF if it is a multi-ein or same login
	 */
	public class AccountWrapper {
		public Account objAccount { get; set; }
		public Boolean isSelected { get; set; }
		public Integer intIndex { get; private set; }

		public AccountWrapper(Account objAcc, Boolean isSelect, Integer indx) {
			objAccount = objAcc;
			isSelected = isSelect;
			intIndex = indx;
		}
	}

	public class CarrierDetailWrapper {
		public List<String> list_SelectedBenefitNames { get; set; }
		public Boolean blnIsSaved { get; set; }
		public Integer intRecordIndex { get; set; }
		public Case objCase { get; set; }
		public Contact objContact { get; set; }
		public String strCarrierName { get; set; }
		public String strCarrierKey { get; set; }
		public String strOtherCarrier { get; set; }
		public Boolean blnIsOtherTextBoxDisplayed { get; set; }

		public CarrierDetailWrapper(
			Case objCaseTemp,
			Contact objContactTemp,
			List<String> list_SelectedBenefitNamesTemp,
			Boolean blnIsSavedTemp,
			Integer intIndx,
			String strCarrierNameTemp,
			String strCarrierKeyTemp,
			String strOtherCarrierTemp,
			Boolean blnIsOtherTextBoxDisplayedTemp
		) {
			list_SelectedBenefitNames = list_SelectedBenefitNamesTemp;
			objCase = objCaseTemp;
			objContact = objContactTemp;
			blnIsSaved = blnIsSavedTemp;
			intRecordIndex = intIndx;
			strCarrierKey = strCarrierKeyTemp;
			strCarrierName = strCarrierNameTemp;
			strOtherCarrier = strOtherCarrierTemp;
			blnIsOtherTextBoxDisplayed = blnIsOtherTextBoxDisplayedTemp;
		}
	}

	public class BenefitsWrapper {
		public List<string> lstBenefitName { get; set; }
		public Carrier__c objCarrier { get; set; }
		public Contact objContact { get; set; }
		public benefitsWrapper() {
			objContact = new Contact();
		}
	}
}