/**
 * @name         NewTransitionToFulfillmentController
 * @author
 * @date
 * @description  Controller for CreateModifyTransitionToFulfilment vf page
 * @test class   NewTransitionToFulfillmentControllerTest
 * @revisions    19 May 2020 ------------ Neha Dabas ------------ Changes for TTQ Notes Automation from HI Fulfillment Event,Auto Size Long Text Area fields on page and adding OpportunityContactRole logic
 *               19 August 2020 ----------Neha Dabas ------------ Group Submission Fix
 */
public with sharing class NewTransitionToFulfillmentController {
	public String strSpecialEnrollmentMessage { get; set; }
	public Transition_to_Fulfillment__c ttfRecord { get; set; }
	public Opportunity objRelatedOpp { get; set; }
	Transition_to_Fulfillment__c transitionRec = new Transition_to_Fulfillment__c();
	static final String TTF_RT_BENEFIT_NEW_PLAN = 'Benefits New Plan';
	static final String TTF_RT_BENEFIT_RENEWAL = 'Benefits Renewal';
	static final String TTF_RT_BENEFIT_CHANGE = 'Benefits Change';
	static final String TTF_RT_BENEFIT_BOR = 'Benefits BoR';
	static final String TTF_RT_BENEFIT_BYB = 'Benefits BYB';
	static final String TTF_RT_PAYROLL_TFR = 'Payroll Transfer';
	static final String TTF_API_NAME = 'Transition_to_Fulfillment__c';
	static final String OPP_RT_COM_OPP = 'Company Opportunity';
	static final String OPP_RT_ACQUISITION = 'Acquisition';
	static final String OPP_RT_BENEFIT_NEW_PLAN = 'Benefits New Plan';
	static final Id OPP_RT_BENEFIT_NEW_PLAN_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPP_RT_BENEFIT_NEW_PLAN).getRecordTypeId();
	static final String OPP_RT_BENEFIT_RENEWAL = 'Benefits Renewal';
	static final String OPP_RT_BENEFIT_CHANGE = 'Benefits Change';
	static final String OPP_RT_BENEFIT_BOR = 'Benefits BoR';
	static final String OPP_RT_BENEFIT_BYB = 'Benefits BYOB';
	static final Id OPP_RT_BENEFIT_BYB_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPP_RT_BENEFIT_BYB).getRecordTypeId();
	static final Id TTF_RT_CHANGE = Cache.getRecordTypeId(TTF_API_NAME, TTF_RT_BENEFIT_CHANGE);
	static final Id TTF_RT_RENEWAL = Cache.getRecordTypeId(TTF_API_NAME, TTF_RT_BENEFIT_RENEWAL);
	static final Id TTF_RT_NEW_PLAN = Cache.getRecordTypeId(TTF_API_NAME, TTF_RT_BENEFIT_NEW_PLAN);
	static final Set<String> OPP_EXCLUDESTAGE = new Set<String>{ 'Closed Won', 'Closed Lost', 'Closed Admin' };
	public CarrierWrapper objCarrierWrapper { get; set; } // wrapper class for all existing carrier
	public List<AffliateWrapper> list_Affliates { get; set; }
	public Boolean blnNeededAffliated { get; set; } //this is for account parent chile hierarchy
	public Boolean blnReadOnly { get; private set; }
	public Set<String> set_BenefitType { get; set; }
	public Boolean blnPoliciesMissing { get; set; }
	public Boolean blnQASheetInfoMissing { get; set; }
	private static String STR_VALIDATIONMESSAGE = 'You must enter a value';
	//DS[11-09-2020] Remove TADA Order Type from Benefit Order
	public List<SelectOption> list_OrderTypeBO { get; set; }
	String strApplicationId; // to hold the numeric part of Application Id of Opportunity
	public String strHippoURL { get; set; }

	// Dynamic Row count fields
	Set<String> set_TTFTextAreaFields = new Set<String>{
		'Life_New_Waiting_Period_Description__c',
		'Medical_New_Contribution_Description__c',
		'Medical_New_Coverage_Description__c',
		'Medical_New_Waiting_Period_Description__c'
	};
	Set<String> set_BTTTFRecordTypes = new Set<String>{ TTF_RT_BENEFIT_BOR, TTF_RT_BENEFIT_BYB };
	Set<String> set_BTOppRecordTypes = new Set<String>{ OPP_RT_BENEFIT_BOR, OPP_RT_BENEFIT_BYB };

	//Key is ObjName and value is Map<FieldAPINAme,Rowcount>
	public Map<String, Map<String, Integer>> map_RowCountTextArea { get; set; }
	public List<OpportunityContactRole> list_OpptyContactRole { get; set; }
	public Id idPrimaryRole { get; set; }
	public Id idSecRole { get; set; }
	public static Boolean blnIsPoliciesExist = false;
	public static Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoveragePerPolicy; // Just to hold Does_group_have_an_alignment__c value
	public Map<String, QA_Lines_Of_Coverage__c> map_QALinesOfCoverage;
	public static String strNoPlanGroupLevelChanges = 'Same Carrier, NO plan/group level changes';
	public static Map<String, integer> map_OrderTypePrecedents = new Map<String, integer>{
		'carrier switch' => 1,
		'same carrier, no plan/group level changes' => 4,
		'same carrier, plan/group level changes' => 2,
		'new line of coverage' => 3
	};
	public Map<String, String> map_ContactIdRole { get; set; }

	public NewTransitionToFulfillmentController(ApexPages.StandardController stdController) {
		transitionRec = (Transition_to_Fulfillment__c) stdController.getRecord(); //not being used and have to be deleted
		ttfRecord = new Transition_to_Fulfillment__c();
		objCarrierWrapper = new CarrierWrapper(); //Initiate the variables
		medicalCarrierSwitch = false;
		list_Affliates = new List<AffliateWrapper>(); //list of child accounts
		blnNeededAffliated = boOrderTypeReq = isLinkClicked = blnReadOnly = false;
		set_BenefitType = new Set<String>(); //Set of benefit Type For terminated order
		//DS[11-09-2020] Remove TADA Order Type from Benefit Order
		list_OrderTypeBO = new List<SelectOption>();
		list_OrderTypeBO.add(new selectOption('', '--None--'));
		List<SelectOption> list_OrderTypeBOTemp = UtilitiesFactory.getPickListValues('Benefit_Order__c', 'Type__c', UtilitiesFactory.set_TADAAndBOROrderType);
		if (list_OrderTypeBOTemp != null && list_OrderTypeBOTemp.size() > 0) {
			list_OrderTypeBO.addAll(list_OrderTypeBOTemp);
		}
	}

	// Code we will invoke on page load.
	// Gets the id, lkid values to get the id of TTF to redirect to TTF edit or go to new TTF and set the record type.
	public PageReference autoRun() {
		String strOGRetURL = ApexPages.currentPage().getParameters().get('retURL');
		String strLkUpFieldId = null;
		String strOpptyId = null;
		// going through all the parameters present in the url.
		String strPrefix = Utils.getSObjectDescribe('Opportunity').getKeyPrefix();
		Map<String, String> list_Params = ApexPages.currentPage().getParameters();
		for (String strKey : list_Params.keySet()) {
			if (strKey.startsWith('CF') && strKey.endsWith('lkid')) {
				String val = list_Params.get(strKey);
				if (val.startsWith(strPrefix)) {
					strLkUpFieldId = strKey;
					strOpptyId = val;
					break;
				}
			}
		}
		String strURL = null;
		PageReference pageRef;
		Boolean blnNewRec = false;
		// if record is not present already.
		if (strURL == null) {
			strURL = '/' + Transition_to_Fulfillment__c.sobjectType.getDescribe().getkeyPrefix() + '/e';
			blnNewRec = true;
		}
		pageRef = new PageReference(strURL);
		// in case "New Record" functionality is called from parent record.
		// Sets the parent records id e.g. oppid if it is created from opportunity
		if (strLkUpFieldId != null) {
			pageRef.getParameters().put(strLkUpFieldId, strOpptyId);
			String strFieldId = strLkUpFieldId.replace('_lkid', '');
			if (list_Params.containsKey(strFieldId)) {
				pageRef.getParameters().put(strFieldId, list_Params.get(strFieldId));
			}
		}
		// we are passing the recordtype id in case opportunity is of type "Benefits BoR"
		if (blnNewRec) {
			List<Opportunity> oppList = [SELECT id, RecordType.Name FROM Opportunity WHERE Id = :strOpptyId];
			if (oppList != null && oppList.size() > 0) {
				if (set_BTOppRecordTypes.contains(oppList.get(0).RecordType.Name)) {
					PageReference pageRefLocal = new PageReference('/apex/BTTransitionToFulfillmentEdit?oppId=' + strOpptyId + '&retURL=' + ApexPages.currentPage().getParameters().get('retURL'));
					pageRefLocal.setRedirect(true);
					return pageRefLocal; //@PR, Jan 14 2019, redirect to BTTransitionToFulfillmentEdit for BT TTF
				}
				if (oppList.get(0).RecordType.Name == OPP_RT_BENEFIT_NEW_PLAN) {
					pageRef.getParameters().put('RecordType', Schema.SObjectType.Transition_to_Fulfillment__c.getRecordTypeInfosByName().get(TTF_RT_BENEFIT_NEW_PLAN).getRecordTypeId());
				}
				if (oppList.get(0).RecordType.Name == OPP_RT_BENEFIT_CHANGE) {
					pageRef.getParameters().put('RecordType', Schema.SObjectType.Transition_to_Fulfillment__c.getRecordTypeInfosByName().get(TTF_RT_BENEFIT_CHANGE).getRecordTypeId());
				}
				if (oppList.get(0).RecordType.Name == OPP_RT_BENEFIT_RENEWAL) {
					pageRef.getParameters().put('RecordType', Schema.SObjectType.Transition_to_Fulfillment__c.getRecordTypeInfosByName().get(TTF_RT_BENEFIT_RENEWAL).getRecordTypeId());
				}
				if (oppList.get(0).RecordType.Name == OPP_RT_BENEFIT_BYB) {
					pageRef.getParameters().put('RecordType', Schema.SObjectType.Transition_to_Fulfillment__c.getRecordTypeInfosByName().get(TTF_RT_BENEFIT_BYB).getRecordTypeId());
				}
				if (oppList.get(0).RecordType.Name == OPP_RT_COM_OPP || oppList.get(0).RecordType.Name == OPP_RT_ACQUISITION) {
					PageReference pageRefLocal = new PageReference('/apex/CreateEditPayrollTransferTTF?oppId=' + strOpptyId + '&retURL=' + strRetURL);
					pageRefLocal.setRedirect(true);
					return pageRefLocal; // @Neha , 16 Sep 2019 , redirect to CreateEditPayrollTransferTTF for Payroll TTF
				}
			}
		}
		// To stop the override from the "New Record" functionality
		pageRef.getParameters().put('nooverride', '1');
		if (list_Params.containsKey('retURL')) {
			pageRef.getParameters().put('retURL', list_Params.get('retURL'));
		}
		pageRef.setRedirect(true);
		return pageRef;
	}

	//Method returns the url to native page if an order is created for Np, Rn and Change
	private String getRecordTypeOfTTF(Id ttfId) {
		String strURLToSet = 'no';
		List<Transition_to_Fulfillment__c> list_TTF = [SELECT id, RecordType.Name, Benefit_Order__c, Carrier_Order__c FROM Transition_to_Fulfillment__c WHERE Id = :ttfId];
		if (list_TTF[0].RecordType.Name != TTF_RT_BENEFIT_NEW_PLAN && list_TTF[0].RecordType.Name != TTF_RT_BENEFIT_CHANGE && list_TTF[0].RecordType.Name != TTF_RT_BENEFIT_RENEWAL) {
			if (list_TTF[0].RecordType.Name == TTF_RT_PAYROLL_TFR) {
				strURLToSet = '/apex/CreateEditPayrollTransferTTF?ttfId=' + ttfId + '&retURL=' + strRetURL; // @Neha , 16 Sep 2019 , redirect to CreateEditPayrollTransferTTF for Payroll TTF
			} else if (set_BTTTFRecordTypes.contains(list_TTF[0].RecordType.Name)) {
				strURLToSet = '/apex/BTTransitionToFulfillmentEdit?ttfId=' + ttfId + '&retURL=' + ApexPages.currentPage().getParameters().get('retURL'); // @Pravesh , 15 Jan 2019 , redirect to BTTransitionToFulfillmentEdit for Benefits Transfer TTF
			} else if (list_TTF[0].Benefit_Order__c != null) {
				strURLToSet = '/' + ttfId + '/e?nooverride=1&retURL=' + (list_TTF[0].Benefit_Order__c == null ? ttfId : list_TTF[0].Benefit_Order__c);
			} else {
				strURLToSet = '/' + ttfId + '/e?nooverride=1&retURL=' + (list_TTF[0].Carrier_Order__c == null ? ttfId : list_TTF[0].Carrier_Order__c);
			}
		}
		return strURLToSet;
	}

	List<Policy__c> list_Policy;
	public List<SelectOption> medicalCarriers { get; set; }
	public List<SelectOption> dentalCarriers { get; set; }
	public List<SelectOption> visionCarriers { get; set; }
	public List<SelectOption> lifeCarriers { get; set; }
	public List<SelectOption> STDCarriers { get; set; }
	public List<SelectOption> LTDCarriers { get; set; }
	//Public String selMedicalCarriers{get;set;}
	public String contextRecordType { get; set; }
	public String strRetURL = null;
	public Boolean disableSendOrder { get; set; }
	public orderTypeEditWrapper orders { get; set; }
	public Boolean isTTFScreenVisible { get; set; }
	public Boolean isSendOrderAlready = false;
	public Map<String, List<SelectOption>> benefitTypeCarriersMap { get; set; } // used to list the carriers for termination section
	public Boolean medicalCarrierSwitch { get; set; }
	//BY:PR, Date: Sep/21/2020, Desc: this variable indicates wether related opp is "dismissed" or not
	public Boolean blnIsOpportunityDismissed { get; set; }
	//BY:PR, Date: Sep/21/2020, Desc: This field contains alternate opporunity if present for redirection.
	Opportunity objDismissedOppty;

	public Boolean isLinkClicked { get; set; }
	public PageReference initData() {
		String strRecordId = null;
		disableSendOrder = true;
		isTTFScreenVisible = true;
		blnIsOpportunityDismissed = false;
		Map<String, String> list_Params = ApexPages.currentPage().getParameters();
		String strUITheme = UserInfo.getUiThemeDisplayed();
		if (strUITheme == Utils.UI_THEME_THEME4U || strUITheme == Utils.UI_THEME_THEME4D) {
			if (list_Params != null && list_Params.containsKey('id')) {
				strRecordId = list_Params.get('id'); // returns TTFID if one exists
				strRetURL = '/' + list_Params.get('id');
			} else if (list_Params != null) {
				// gets opportunity id using lookup field
				for (String strKey : list_Params.keySet()) {
					if (strKey.startsWith('CF') && strKey.endsWith('lkid')) {
						strRecordId = list_Params.get(strKey);
						strRetURL = '/' + list_Params.get(strKey);
						break;
					}
				}
			}
		} else {
			if (list_Params != null && list_Params.containsKey('id')) {
				strRecordId = list_Params.get('id'); // returns TTFID if one exists
			} else if (list_Params != null && list_Params.containsKey('retURL')) {
				// gets opportunity id using retURL
				if (list_Params.get('retURL').length() > 16) {
					strRecordId = list_Params.get('retURL').subString(0, 16);
					strRecordId = strRecordId.replace('/', '');
				} else {
					strRecordId = list_Params.get('retURL').replace('/', '');
				}
			}
			if (strRetURL == null && list_Params.containsKey('retURL')) {
				strRetURL = list_Params.get('retURL');
			}
		}

		if (strRecordId == null || !(String.valueOf(strRecordId).length() >= 15)) {
			return null;
		}

		String strTTFPreFix = Utils.getSObjectDescribe('Transition_to_Fulfillment__c').getKeyPrefix();
		//IF TTF rcord id exists and order exists redirect to the native view page.
		if (strRecordId != null && strRecordId.startsWith(strTTFPreFix) && String.valueOf(strRecordId).length() >= 15) {
			String strURL = getRecordTypeOfTTF(strRecordId);
			if (strURL != 'no') {
				PageReference pageRefLocal = new PageReference(strURL);
				pageRefLocal.setRedirect(true);
				return pageRefLocal;
			}
		}

		String strPrefix = Utils.getSObjectDescribe('Opportunity').getKeyPrefix();
		if (strRecordId != null && String.valueOf(strRecordId).length() >= 15) {
			String strWhereClause = 'WHERE ';
			//Get TTF record by strOpptyId or TTF record id
			if (strRecordId.startsWith(strPrefix)) {
				strWhereClause += ' Opportunity__c=\'' + strRecordId + '\'';
			} else {
				strWhereClause += ' Id=\'' + strRecordId + '\'';
			}

			//get list of all fields to query
			List<String> list_TTFFields = new List<String>(Transition_to_Fulfillment__c.SObjectType.getDescribe().fields.getMap().keySet());
			String strTTFSOQL =
				'SELECT Opportunity__r.Id__c, Opportunity__r.Order__c, Order__r.Status, Opportunity__r.Order__r.Payroll_Run_Date__c,' +
				'Opportunity__r.AccountId, Opportunity__r.Account.ParentId, Opportunity__r.Name, RecordType.Name, Opportunity__r.StageName,' +
				'Opportunity__r.Benefits_Current_Setup_Step__c, Opportunity__r.ZP_Company_ID__c, Opportunity__r.RecordType.Name, ' +
				'Opportunity__r.RecordTypeId, Opportunity__r.Application_Id__c, Opportunity__r.ZP_Company_ID_from_Account__c, ' +
				'Opportunity__r.SGHI_LGHI__c, Opportunity__r.Funding_Type__c, Opportunity__r.Unsupported_Carrier__c, Opportunity__r.PEO__c, ' +
				String.join(list_TTFFields, ',') +
				' FROM Transition_to_Fulfillment__c ' +
				strWhereClause +
				' LIMIT 1';
			List<Transition_to_Fulfillment__c> list_TTFs = Database.query(strTTFSOQL);
			String strAcctId = null;
			String strParentAcctId = null;

			if (list_TTFs != null && list_TTFs.size() > 0 && list_TTFs[0].Order__c != null && Utils.setOrderExclude.contains(list_TTFs[0].Order__r.Status)) {
				list_TTFs = new List<Transition_to_Fulfillment__c>();
			}

			String strZpCompanyId = null;
			String strOppApplicationId = null;
			//if ttf record exists enable the send order button based on the record type
			if (list_TTFs.size() > 0) {
				ttfRecord = list_TTFs[0];
				objRelatedOpp = new Opportunity(
					Id = ttfRecord.Opportunity__c,
					SGHI_LGHI__c = ttfRecord.Opportunity__r.SGHI_LGHI__c,
					Funding_Type__c = ttfRecord.Opportunity__r.Funding_Type__c,
					Unsupported_Carrier__c = ttfRecord.Opportunity__r.Unsupported_Carrier__c,
					RecordTypeId = ttfRecord.Opportunity__r.RecordTypeId
				);
				strOppApplicationId = ttfRecord.Opportunity__r.Application_Id__c;
				strZpCompanyId = ttfRecord.Opportunity__r.ZP_Company_ID_from_Account__c;
				// [SM] : Page Rerouting to std page fix
				if (ttfRecord.RecordType.Name != TTF_RT_BENEFIT_NEW_PLAN && ttfRecord.RecordType.Name != TTF_RT_BENEFIT_RENEWAL && ttfRecord.RecordType.Name != TTF_RT_BENEFIT_CHANGE) {
					if (set_BTTTFRecordTypes.contains(ttfRecord.RecordType.Name)) {
						String strCurrentURL = ApexPages.currentPage().getParameters().get('retURL');
						PageReference pageRefLocal = new PageReference('/apex/BTTransitionToFulfillmentEdit?ttfId=' + ttfRecord.Id + '&retURL=' + strCurrentURL);
						pageRefLocal.setRedirect(true);
						return pageRefLocal;
					}

					if (ttfRecord.RecordType.Name == TTF_RT_PAYROLL_TFR) {
						PageReference pageRefLocal = new PageReference('/apex/CreateEditPayrollTransferTTF?ttfId=' + ttfRecord.Id + '&retURL=' + strRetURL);
						pageRefLocal.setRedirect(true);
						return pageRefLocal;
					}
					return new PageReference('/' + ttfRecord.Id + '/e?nooverride=1&retURL=' + strRecordId);
				}

				strParentAcctId = ttfRecord.Opportunity__r.Account.ParentId;
				contextRecordType = list_TTFs[0].RecordType.Name;
				if (ttfRecord.Opportunity__r.Account.ParentId == null) {
					blnNeededAffliated = true;
					strAcctId = ttfRecord.Opportunity__r.AccountId;
				}

				if (
					ttfRecord.RecordType.Name == TTF_RT_BENEFIT_NEW_PLAN &&
					ttfRecord.Opportunity__r.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
					(ttfRecord.Opportunity__r.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
					ttfRecord.Opportunity__r.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)
				) {
					disableSendOrder = false;
				} else if (
					(ttfRecord.RecordType.Name == TTF_RT_BENEFIT_RENEWAL ||
					ttfRecord.RecordType.Name == TTF_RT_BENEFIT_CHANGE) &&
					ttfRecord.Opportunity__r.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
					(ttfRecord.Opportunity__r.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
					ttfRecord.Opportunity__r.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)
				) {
					disableSendOrder = false;
				}

				if (ttfRecord.Send_Order__c) {
					disableSendOrder = blnReadOnly = true;
				}
				if (String.isNotBlank(ttfRecord.Opportunity__r.Id__c) && ttfRecord.Opportunity__r.Id__c.contains('HIRENEWAL')) {
					strApplicationId = ttfRecord.Opportunity__r.Id__c.replace('HIRENEWAL', '');
				}
				strHippoURL = getQASheetURL(ttfRecord.Opportunity__r.RecordTypeId, strZpCompanyId, strOppApplicationId);
			} else {
				//IF TTF record does not exist then create a new one and set the record type, opp id and account id
				//Set the needParenting to true
				ttfRecord = new Transition_to_Fulfillment__c();
				for (Opportunity objOpp : [
					SELECT
						Id__c,
						recordType.Name,
						StageName,
						Benefits_Current_Setup_Step__c,
						Account.ParentId,
						AccountId,
						Account.Name,
						ZP_Company_ID__c,
						Application_Id__c,
						RecordTypeId,
						ZP_Company_ID_from_Account__c,
						SGHI_LGHI__c,
						Funding_Type__c,
						Unsupported_Carrier__c,
						(SELECT contactId FROM OpportunityContactRoles WHERE IsPrimary = TRUE)
					FROM Opportunity
					WHERE Id = :strRecordId
					LIMIT 1
				]) {
					objRelatedOpp = objOpp;
					contextRecordType = objOpp.RecordType.Name;
					strOppApplicationId = objOpp.Application_Id__c;
					strZpCompanyId = objOpp.ZP_Company_ID_from_Account__c;
					if (contextRecordType != TTF_RT_BENEFIT_RENEWAL && contextRecordType != TTF_RT_BENEFIT_NEW_PLAN && contextRecordType != TTF_RT_BENEFIT_CHANGE) {
						return autoRun();
					}

					strParentAcctId = objOpp.Account.ParentId;
					if ((contextRecordType == TTF_RT_BENEFIT_RENEWAL || contextRecordType == TTF_RT_BENEFIT_NEW_PLAN) && objOpp.Account.ParentId == null) {
						blnNeededAffliated = true;
						strAcctId = objOpp.AccountId;
					}
					ttfRecord.Opportunity__c = strRecordId;
					ttfRecord.Account__c = objOpp.AccountId;
					if (contextRecordType == TTF_RT_BENEFIT_RENEWAL) {
						ttfRecord.RecordTypeId = TTF_RT_RENEWAL;
						if (
							objOpp.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
							(objOpp.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
							objOpp.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)
						) {
							disableSendOrder = false;
						}

						if (String.isNotBlank(objOpp.Id__c) && objOpp.Id__c.contains('HIRENEWAL')) {
							strApplicationId = objOpp.Id__c.replace('HIRENEWAL', '');
						}
						strHippoURL = getQASheetURL(objOpp.RecordTypeId, strZpCompanyId, strOppApplicationId);
					} else if (contextRecordType == TTF_RT_BENEFIT_NEW_PLAN) {
						ttfRecord.RecordTypeId = TTF_RT_NEW_PLAN;
						if (
							objOpp.StageName != OpportunityUtil.CLOSED_WON_STAGE &&
							(objOpp.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP ||
							objOpp.Benefits_Current_Setup_Step__c == OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP)
						) {
							disableSendOrder = false;
						}
					} else if (contextRecordType == TTF_RT_BENEFIT_CHANGE) {
						ttfRecord.RecordTypeId = TTF_RT_CHANGE;
						if (objOpp.StageName != OpportunityUtil.CLOSED_WON_STAGE) {
							disableSendOrder = false;
						}
					}
					if (objOpp.OpportunityContactRoles.size() > 0) {
						ttfRecord.Contact__c = objOpp.OpportunityContactRoles[0].contactId;
					}

					if (String.isNotBlank(objOpp.Benefits_Current_Setup_Step__c) && objOpp.Benefits_Current_Setup_Step__c.equalsIgnoreCase('Dismissed')) {
						blnIsOpportunityDismissed = true;
						objDismissedOppty = objOpp;
					}
				}

				if (blnIsOpportunityDismissed && objDismissedOppty != null) {
					Opportunity objAlternateOpp;
					Set<string> set_EligibleCurrentSetupStep = new Set<string>{ OpportunityUtil.COMPLETE_BENEFITSCURRENTSTEP, OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP };

					for (Opportunity objOpp : [
						SELECT Id, Name, Application_Id__c, ZP_Company_ID_from_Account__c
						FROM Opportunity
						WHERE
							AccountId != NULL
							AND AccountId = :objDismissedOppty.AccountId
							AND RecordType.Name = :objDismissedOppty.RecordType.Name
							AND ID != :objDismissedOppty.Id
							AND Benefits_Current_Setup_Step__c != NULL
							AND Benefits_Current_Setup_Step__c IN :set_EligibleCurrentSetupStep
							AND HI_Effective_Date__c != NULL
							AND (HI_Effective_Date__c = THIS_YEAR
							OR HI_Effective_Date__c = NEXT_YEAR)
							AND Id__c != NULL
						ORDER BY CreatedDate DESC
						LIMIT 1
					]) {
						objAlternateOpp = objOpp;
						strOppApplicationId = objOpp.Application_Id__c;
						strZpCompanyId = objOpp.ZP_Company_ID_from_Account__c;
					}

					//if alternate opportunity on same account exists then suggest that opp else suggest to create new Opp
					String strDismissedOpp = 'The following opportunity is dismissed in Hippo.';
					if (objAlternateOpp != null) {
						ApexPages.addMessage(
							new ApexPages.Message(
								ApexPages.Severity.Warning,
								strDismissedOpp +
									' Please click on the following ' +
									' <a style="color:blueviolet;" onclick="closeCurrentTab(\'' +
									objAlternateOpp.Id +
									'\');" >' +
									objAlternateOpp.Name +
									'</a> Opportunity to Submit TTQ'
							)
						);
					} else {
						ApexPages.addMessage(
							new ApexPages.Message(ApexPages.Severity.Warning, strDismissedOpp + 'Please create new application in hippo and then submit TTQ on the newly created opportunity.')
						);
					}
					return null;
				}
			}
			// load all the child accounts to the affliate wrapper
			// Affiliates are available only for renewal and change
			if (blnNeededAffliated && strAcctId != null) {
				for (Account a : [SELECT id FROM Account WHERE ParentId = :strAcctId]) {
					AffliateWrapper aff = new AffliateWrapper();
					aff.ttf.InternalAccount__c = a.id;
					list_Affliates.add(aff);
				}
				ttfRecord.Do_they_have_affiliates__c = false;

				//above commented code is same as below code
				if (!list_Affliates.isEmpty()) {
					ttfRecord.Do_they_have_affiliates__c = true;
				}
			}

			// disable Send order if parent account does not have any benefit Order
			if (blnNeededAffliated == false && strParentAcctId != null && disableSendOrder == false && contextRecordType != TTF_RT_BENEFIT_CHANGE) {
				// add filter for last 60days on created date
				List<Benefit_Order__c> list_parentBO = [SELECT id FROM Benefit_Order__c WHERE Account__c = :strParentAcctId AND CreatedDate = LAST_N_DAYS:60];
				if (list_parentBO.size() == 0) {
					disableSendOrder = true;
					ApexPages.addmessage(
						new ApexPages.message(
							ApexPages.severity.Error,
							'Parent Opportunity is not submitted for Implementation. Please submit parent opportunity to Implementation and then submit this group'
						)
					);
				}
			}

			if (strParentAcctId != null) {
				List<Account> list_parentAcct = [
					SELECT id, (SELECT id FROM Account_Transition_To_Fulfillment__r WHERE recordType.Name = :contextRecordType ORDER BY createddate DESC LIMIT 1)
					FROM Account
					WHERE Id = :strParentAcctId
				];
				if (list_parentAcct != null && list_parentAcct.size() > 0) {
					if (list_parentAcct[0].Account_Transition_To_Fulfillment__r != null && list_parentAcct[0].Account_Transition_To_Fulfillment__r.size() > 0) {
						ttfRecord.Parent_Transition_to_fulfillment__c = list_parentAcct[0].Account_Transition_To_Fulfillment__r[0].Id;
					}
				}
			}

			//Create benefit type carrier id/name selection option
			benefitTypeCarriersMap = new Map<String, List<SelectOption>>(); //used to populate termination section
			Schema.DescribeFieldResult fieldResult = Policy__c.Benefit_Type__c.getDescribe();
			benefitTypeCarriersMap.put(null, new List<SelectOption>());
			for (Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()) {
				benefitTypeCarriersMap.put(pickListVal.getLabel(), new List<SelectOption>());
			}
			list_Policy = [SELECT id, Benefit_Type__c, Carrier__c, Carrier__r.Name, Opportunity__c FROM Policy__c WHERE Opportunity__c = :ttfRecord.Opportunity__c AND Is_Selected__c = TRUE];
			// These lists are used to populate the main page when the medical, dental options are set to yes.
			medicalCarriers = new List<SelectOption>();
			dentalCarriers = new List<SelectOption>();
			visionCarriers = new List<SelectOption>();
			lifeCarriers = new List<SelectOption>();
			STDCarriers = new List<SelectOption>();
			LTDCarriers = new List<SelectOption>();
			makeItTerminatedSelected(ttfRecord);
			//create a map between benefit type and carrier id
			Map<String, Set<Id>> benefitTypeCarrieridMap = new Map<String, Set<Id>>();

			if (contextRecordType == TTF_RT_BENEFIT_RENEWAL || contextRecordType == TTF_RT_BENEFIT_NEW_PLAN || contextRecordType == TTF_RT_BENEFIT_CHANGE) {
				initQALinesOfCoverageMap();
			}

			for (Policy__c objPl : list_Policy) {
				if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_MEDICAL) {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							medicalCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						medicalCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_DENTAL) {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							dentalCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						dentalCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				} else if (objPl.Benefit_Type__c == 'Vision') {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							visionCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						visionCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				} else if (objPl.Benefit_Type__c == 'Life') {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							lifeCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						lifeCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				} else if (objPl.Benefit_Type__c == Utils.BENEFIT_TYPE_STD) {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							STDCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						STDCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				} else if (objPl.Benefit_Type__c == Utils.BENEFIT_TYPE_LTD) {
					if (benefitTypeCarrieridMap.containsKey(objPl.Benefit_Type__c)) {
						if (!benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).Contains(objPl.Carrier__c)) {
							LTDCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
							benefitTypeCarrieridMap.get(objPl.Benefit_Type__c).add(objPl.Carrier__c);
						}
					} else {
						benefitTypeCarrieridMap.put(objPl.Benefit_Type__c, new Set<Id>{ objPl.Carrier__c });
						LTDCarriers.add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
					}
				}
				if (benefitTypeCarriersMap.containsKey(objPl.Benefit_Type__c)) {
					benefitTypeCarriersMap.get(objPl.Benefit_Type__c).add(new SelectOption(objPl.Carrier__c, objPl.Carrier__r.Name));
				}
			}

			// user click on link from detail page of opp
			// paramter whereFrom is passed from the opportunity formula field "Update as Closed Won" when it is clicked in the ben change opp
			if (list_Params.containsKey('wherefrom') && list_Params.get('wherefrom') == 'linkClicked' && ttfRecord != null && ttfRecord.RecordTypeId == TTF_RT_CHANGE) {
				isLinkClicked = true;
				if (
					ttfRecord.Opportunity__c != null &&
					[SELECT Benefits_Current_Setup_Step__c FROM Opportunity WHERE Id = :ttfRecord.Opportunity__c LIMIT 1].Benefits_Current_Setup_Step__c != 'Completed'
				) {
					update new opportunity(Id = ttfRecord.Opportunity__c, Benefits_Current_Setup_Step__c = 'Completed');
					disableSendOrder = false;
				}
			}

			// BBO-1001 - Block 'Send Order' until receipt of QA Sheet
			blnQASheetInfoMissing = true;
			if (String.isNotBlank(strZpCompanyId) && String.isNotBlank(strOppApplicationId)) {
				Integer intQASheetEventCount = [
					SELECT COUNT()
					FROM HIGroupEvent__c
					WHERE
						Event_Type__c = :HIGroupEventUtil.EVENT_TYPE_QA_SHEET_INFO
						AND Processing_State__c = :IntegrationUtils.PROCESSED_STATE
						AND Application_Id__c = :strOppApplicationId
						AND Company_Id__c = :strZpCompanyId
				];
				blnQASheetInfoMissing = intQASheetEventCount > 0 ? false : true;
			}

			if (blnQASheetInfoMissing) {
				if (String.isBlank(strOppApplicationId) && (ttfRecord.RecordTypeId == TTF_RT_CHANGE)) {
					blnQASheetInfoMissing = false;
				}
			}
		}
		blnPoliciesMissing = false;
		if (ttfRecord.RecordTypeId == TTF_RT_RENEWAL || ttfRecord.RecordTypeId == TTF_RT_NEW_PLAN) {
			if (CheckPolicyExistOrNot(ttfRecord).isEmpty()) {
				blnPoliciesMissing = true;
			}
		}
		if (disableSendOrder == false && blnQASheetInfoMissing == true) {
			disableSendOrder = true;
		}
		if (disableSendOrder == false && blnPoliciesMissing == true) {
			disableSendOrder = true;
		}

		//dynamic row count
		map_RowCountTextArea = new Map<String, Map<String, Integer>>();
		map_RowCountTextArea = OrderUtils.setRowCountForTextArea(new List<Transition_to_Fulfillment__c>{ ttfRecord }, set_TTFTextAreaFields, map_RowCountTextArea);
		initializeSecondaryPOCData(); // get opportunity contact role data based on opporutnity Id
		return null;
	}

	private String getQASheetURL(String strRecordTypeId, String strCompanyID, String strApplicationId) {
		String strHippoURL = '';
		String strApplicationType = '';
		if (strRecordTypeId == OpportunityUtil.BENEFITS_NEWPLAN_CASE_RT_ID) {
			strApplicationType = HIGroupEventUtil.NEW_PLANS_APPLICATIONS;
		} else if (strRecordTypeId == OpportunityUtil.BENEFITS_CHANGE_CASE_RT_ID) {
			strApplicationType = HIGroupEventUtil.BENEFIT_CHANGE_APPLICATIONS;
		} else if (strRecordTypeId == OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID) {
			strApplicationType = HIGroupEventUtil.RENEWALS;
		}
		if (String.isNotBlank(strApplicationType)) {
			strHippoURL = HIGroupEventUtil.HIPPO_COMPANY_URL + strCompanyID + strApplicationType + strApplicationId + HIGroupEventUtil.QA_SHEET;
		}
		return strHippoURL;
	}

	// this method sets the wrapper medical, dental switch carrier values from the database when
	// a saved TTF record is loaded.
	private void makeItTerminatedSelected(Transition_to_Fulfillment__c ttfRecord) {
		if (String.isNotBlank(ttfRecord.Medical_Switch_New_Carriers__c)) {
			objCarrierWrapper.medicalSwitchCarrier = ttfRecord.Medical_Switch_New_Carriers__c.split(',');
		}
		if (String.isNotBlank(ttfRecord.Dental_New_carriers__c)) {
			objCarrierWrapper.dentalSwitchCarrier = ttfRecord.Dental_New_carriers__c.split(',');
		}
		if (String.isNotBlank(ttfRecord.Medical_New_carriers__c)) {
			objCarrierWrapper.medicalNewLineCarrier = ttfRecord.Medical_New_carriers__c.split(',');
		}
		if (String.isNotBlank(ttfRecord.Dental_New_carriers__c)) {
			objCarrierWrapper.dentalNewLineCarrier = ttfRecord.Dental_New_carriers__c.split(',');
		}
		if (String.isNotBlank(ttfRecord.Vision_New_carriers__c)) {
			objCarrierWrapper.visionNewLineCarrier = ttfRecord.Vision_New_carriers__c.split(',');
		}
		if (String.isNotBlank(ttfRecord.Long_term_Disability_New_carriers__c)) {
			objCarrierWrapper.longTermDisabilityNewLineCarrier = ttfRecord.Long_term_Disability_New_carriers__c.split(',');
		}
	}

	// This methods takes the values from the wrapper and sets the data to the TTF Fields
	private void assignCarrierSwichSelectionToTTF(Transition_to_Fulfillment__c ttfRecord) {
		if (objCarrierWrapper != null) {
			if (objCarrierWrapper.medicalSwitchCarrier.size() > 0) {
				ttfRecord.Medical_Switch_New_Carriers__c = String.join(objCarrierWrapper.medicalSwitchCarrier, ',');
			}
			if (objCarrierWrapper.dentalSwitchCarrier.size() > 0) {
				ttfRecord.Dental_New_carriers__c = String.join(objCarrierWrapper.dentalSwitchCarrier, ',');
			}
			if (objCarrierWrapper.medicalNewLineCarrier.size() > 0) {
				ttfRecord.Medical_New_carriers__c = String.join(objCarrierWrapper.medicalNewLineCarrier, ',');
			}
			if (objCarrierWrapper.dentalNewLineCarrier.size() > 0) {
				ttfRecord.Dental_New_carriers__c = String.join(objCarrierWrapper.dentalNewLineCarrier, ',');
			}
			if (objCarrierWrapper.visionNewLineCarrier.size() > 0) {
				ttfRecord.Vision_New_carriers__c = String.join(objCarrierWrapper.visionNewLineCarrier, ',');
			}
			if (objCarrierWrapper.longTermDisabilityNewLineCarrier.size() > 0) {
				ttfRecord.Long_term_Disability_New_carriers__c = String.join(objCarrierWrapper.longTermDisabilityNewLineCarrier, ',');
			}
		}
	}

	//Establishes the parent child relationship
	private void saveAccountRelationShip() {
		Set<Id> set_AccountId = new Set<Id>();
		Set<Id> set_AccountIdUncheckMultiEIN = new Set<Id>();
		Map<String, Account> childAccounts = new Map<String, Account>();
		//Get Parent Account
		set_AccountId.add(ttfRecord.Account__c);
		if (list_Affliates != null && list_Affliates.size() > 0) {
			for (AffliateWrapper af : list_Affliates) {
				if (af.ttf != null && af.ttf.InternalAccount__c != null) {
					childAccounts.put(af.ttf.InternalAccount__c, new Account(Id = af.ttf.InternalAccount__c, ParentId = ttfRecord.Account__c));
					//get All Affiliate Account
					set_AccountId.add(af.ttf.InternalAccount__c);
				}
			}
		}
		// Anything that is removed from the affiliate set the parent id to null
		for (Account a : [SELECT id FROM Account WHERE id NOT IN :childAccounts.keySet() AND ParentId = :ttfRecord.Account__c]) {
			a.ParentId = null;
			childAccounts.put(a.Id, a);
			set_AccountId.add(a.id);
			//get All Removed Affiliate Account
			set_AccountIdUncheckMultiEIN.add(a.id);
		}

		//updates the account
		if (childAccounts.size() > 0) {
			Boolean actSkipTrigger = AccountTriggerHelper.skipTrigger;
			AccountTriggerHelper.skipTrigger = true;
			update childAccounts.values();
			//Mark Multi EIN on opp in case of Affiliate
			if (set_AccountId != null && set_AccountId.size() > 0) {
				updateMultiEINOpportunity(set_AccountId, set_AccountIdUncheckMultiEIN);
			}
			AccountTriggerHelper.skipTrigger = actSkipTrigger;
		}
	}

	//Added by AKS dated 21st Jan 2021
	private void updateMultiEINOpportunity(Set<Id> set_AccountIdTemp, Set<Id> set_UnCheckMultiEIN) {
		List<Opportunity> list_UpdateOpportunity = new List<Opportunity>();
		for (Opportunity opp : [
			SELECT Id, AccountId, Is_Multi_EIN__c
			FROM Opportunity
			WHERE RecordType.Name = :OPP_RT_BENEFIT_RENEWAL AND StageName NOT IN :OPP_EXCLUDESTAGE AND Accountid IN :set_AccountIdTemp
		]) {
			opp.Is_Multi_EIN__c = true;
			//Uncheck from Opp in case of removed from Affiliates
			//If All Affiliates removed then uncheck from Parent opp also
			if (set_UnCheckMultiEIN.contains(opp.AccountId) || set_UnCheckMultiEIN.size() == set_AccountIdTemp.size() - 1) {
				opp.Is_Multi_EIN__c = false;
			}
			list_UpdateOpportunity.add(opp);
		}
		if (list_UpdateOpportunity.size() > 0) {
			Boolean blnSkipTrigger = OpportunityTriggerHelper.skipTrigger;
			OpportunityTriggerHelper.skipTrigger = true;
			update list_UpdateOpportunity;
			OpportunityTriggerHelper.skipTrigger = blnSkipTrigger;
		}
	}

	/**
	 * @Author      : Anurag Gautam
	 * @Description : This method is getiing used for processAcknowledgement.
	 * @Parm        : NA
	 * @Return      : PageReference
	 **/
	public PageReference processAcknowledgement() {
		PageReference objPageRef = calculateOrderType();
		return objPageRef;
	}

	// calculates order type and saves the record
	public PageReference calculateOrderType() {
		if (ttfRecord != null) {
			skipTrigger(true);
			Boolean blnHasError = false;
			if ('Y' == ttfRecord.Priority__c && String.isBlank(ttfRecord.Priority_Reasons__c)) {
				ttfRecord.Priority_Reasons__c.addError(STR_VALIDATIONMESSAGE);
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Priority Reasons: You must enter a value'));
				blnHasError = true;
			}
			//validate if Primary Point of contact is selected and it is not same as secondary point of contact
			if (ttfRecord.Contact__c == null) {
				ttfRecord.Contact__c.addError(STR_VALIDATIONMESSAGE);
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary Point of Contact : You must enter a value'));
				blnHasError = true;
			} else if (list_OpptyContactRole != null && !list_OpptyContactRole.isEmpty()) {
				for (OpportunityContactRole objContactRole : list_OpptyContactRole) {
					if (ttfRecord.Contact__c == objContactRole.ContactId && objContactRole.Check_Additional_POC__c) {
						ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary POC is also selected as Secondary POC. Please review your selections.'));
						blnHasError = true;
						objContactRole.IsPrimary = true;
						break;
					}
				}
			}

			if (blnHasError) {
				return null;
			}

			// sets the selected values for carriers from the wrapper to TTF record.
			assignCarrierSwichSelectionToTTF(ttfRecord);
			if (ttfRecord.Send_Order__c && (ttfRecord.RecordTypeId == TTF_RT_CHANGE || ttfRecord.RecordTypeId == TTF_RT_NEW_PLAN || ttfRecord.RecordTypeId == TTF_RT_RENEWAL)) {
				CalculationOrderTypeforBenfitCarrierOrders(ttfRecord);
				if (ttfRecord.RecordTypeId == TTF_RT_NEW_PLAN || (ttfRecord.RecordTypeId == TTF_RT_CHANGE && isLinkClicked)) {
					return SaveTTFRecord();
				}
				Savepoint sp = Database.setSavepoint();

				try {
					savePointOfContactChanges();
					upsert ttfRecord;
					if (objRelatedOpp.RecordTypeId == OPP_RT_BENEFIT_BYB_ID || objRelatedOpp.RecordTypeId == OPP_RT_BENEFIT_NEW_PLAN_ID) {
						update objRelatedOpp;
					}
				} catch (Exception ex) {
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
					Database.rollback(sp);
					isTTFScreenVisible = true;
					return null;
				}
				skipTrigger(false);
				isTTFScreenVisible = false;
				if (strRetURL == null) {
					strRetURL = '/' + ttfRecord.Id;
				}
				PageReference pageRefLocal = new PageReference(strRetURL);
				pageRefLocal.setRedirect(true);
				return pageRefLocal;
			} else {
				// if send order is not there then just save
				return SaveTTFRecord();
			}
		}
		return null;
	}

	/*
	 * Create CaseTeamMembers for each additional point of contact selected and save primary point of contact on Customer Case
	 */
	private void savePointOfContactChangesToCustomerCase() {
		//Update customer case and case team only if Send Order checkbox is checked for the first time
		if (!disableSendOrder && ttfRecord.Send_Order__c && !list_OpptyContactRole.isEmpty() && ttfRecord != null && ttfRecord.Id != null) {
			Set<Id> set_ContactIds;
			//get Customer case related to BO
			List<Case> list_Case = new List<Case>();
			Set<String> set_CaseTypes = new Set<String>{ 'Benefits Renewal', 'Benefits Change', 'Benefits New Plan' };

			for (OpportunityContactRole objOpptyCRole : list_OpptyContactRole) {
				if (objOpptyCRole.Check_Additional_POC__c) {
					if (set_ContactIds == null) {
						set_ContactIds = new Set<Id>();
					}
					set_ContactIds.add(objOpptyCRole.ContactId);
				}
			}

			list_Case = [SELECT Id, ContactId FROM Case WHERE Benefit_Order__r.Transition_To_Fulfillment__c = :ttfRecord.Id AND Carrier_Order__c = NULL AND Type IN :set_CaseTypes LIMIT 1];
			if (list_Case != null && !list_Case.isEmpty()) {
				Case objCase = list_Case[0];

				//update contact on Customer Case if a different Primary Point of Contact is selected on TTF
				if (objCase.ContactId != ttfRecord.Contact__c) {
					objCase.ContactId = ttfRecord.Contact__c;
					Boolean blnBefValue = CaseTriggerHelper.skipTrigger;
					CaseTriggerHelper.skipTrigger = true;
					update objCase;
					CaseTriggerHelper.skipTrigger = blnBefValue;
				}
				if (set_ContactIds != null && !set_ContactIds.isEmpty()) {
					Id idObjCase = objCase.Id;
					//get existing caseteam members
					List<CaseTeamMember> list_CaseTeamMembers = new List<CaseTeamMember>();
					list_CaseTeamMembers = [SELECT Id, MemberId FROM CaseTeamMember WHERE ParentId = :idObjCase];

					List<CaseTeamMember> list_CaseTeamMembersToInsert = new List<CaseTeamMember>();
					//check if teammember record exists for selected contacts
					if (!list_CaseTeamMembers.isEmpty()) {
						for (CaseTeamMember member : list_CaseTeamMembers) {
							if (set_ContactIds.contains(member.MemberId)) {
								set_ContactIds.remove(member.MemberId);
							}
						}
					}
					//Fetch case team role
					List<CaseTeamRole> list_CaseTeamRole = new List<CaseTeamRole>();
					list_CaseTeamRole = [SELECT Id FROM CaseTeamRole WHERE Name = 'Customer Contact'];
					Id idCaseTRole;
					if (list_CaseTeamRole != null && !list_CaseTeamRole.isEmpty()) {
						idCaseTRole = list_CaseTeamRole[0].Id;
					}

					//Create case team members for each contact
					for (Id idContact : set_ContactIds) {
						list_CaseTeamMembersToInsert.add(new CaseTeamMember(ParentId = idObjCase, TeamRoleId = idCaseTRole, MemberId = idContact));
					}

					CaseTriggerHelper.skipTrigger = true; //Neha Aug 26 for CPU Time Limit
					Database.Insert(list_CaseTeamMembersToInsert);
				}
			}
		}
	}
	/*
	 * Save Opportunity Contact Role records
	 */
	private void savePointOfContactChanges() {
		if (list_OpptyContactRole != null && !list_OpptyContactRole.isEmpty()) {
			Database.update(list_OpptyContactRole);
		}
	}

	public List<Policy__c> CheckPolicyExistOrNot(Transition_to_Fulfillment__c ttfRecord) {
		if (ttfRecord.Opportunity__c != null) {
			return ([SELECT Id FROM Policy__c WHERE Opportunity__c = :ttfRecord.Opportunity__c AND Is_Selected__c = TRUE LIMIT 1]);
		}
		return null;
	}

	public PageReference SaveTTFRecord() {
		try {
			if (ttfRecord != null) {
				if (!ttfRecord.Send_Order__c || ttfRecord.RecordTypeId == TTF_RT_NEW_PLAN || (ttfRecord.RecordTypeId == TTF_RT_CHANGE && isLinkClicked)) {
					savePointOfContactChanges();
				}

				upsert ttfRecord;
				if (objRelatedOpp.RecordTypeId == OPP_RT_BENEFIT_BYB_ID || objRelatedOpp.RecordTypeId == OPP_RT_BENEFIT_NEW_PLAN_ID) {
					Opportunity opportunityRecord = [SELECT Id, StageName FROM Opportunity WHERE ID = :objRelatedOpp.Id LIMIT 1];
					objRelatedOpp.StageName = opportunityRecord.StageName;
					update objRelatedOpp;
				}
				savePointOfContactChangesToCustomerCase();
				saveAccountRelationShip();
			}
		} catch (System.DmlException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
			return null;
		} catch (Exception ex) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
			return null;
		}
		skipTrigger(false);
		if (strRetURL == null) {
			strRetURL = '/' + ttfRecord.Id;
		}

		PageReference pageRef = new PageReference(strRetURL);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public PageReference cancelAction() {
		if (strRetURL == null) {
			strRetURL = '/' + ttfRecord.Id;
		}

		PageReference pageRef = new PageReference(strRetURL);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public static List<String> BO_order_type;
	public static Map<String, Set<String>> CO_order_type_Map;
	public static List<Policy__c> terminatedCarrierList;
	//method used to calucate and update the benefit and carrier order types.
	public PageReference CalculationOrderTypeforBenfitCarrierOrders(Transition_to_Fulfillment__c ttfRecord) {
		// created some dummy object
		orders = new orderTypeEditWrapper();
		Boolean blnOnlyTadasPolicy = true;
		orders.newCarrierOrders = new List<Carrier_Order__c>();
		if (ttfRecord.Opportunity__c != null) {
			BO_order_type = new List<String>();
			CO_order_type_Map = new Map<String, Set<String>>();
			// calculate order type for benefit order
			Set<Id> oppPolicyCarrierSet = new Set<Id>();
			if (ttfRecord.RecordTypeId == TTF_RT_NEW_PLAN) {
				//for new plan benefit order type is always set to ''New to Gusto
				//Carrier order types are also set to new to Gusto
				//except for Tada
				BO_order_type.add('New to Gusto');

				for (Policy__c objPl : list_Policy) {
					if (
						objPl.Benefit_Type__c != 'Flexible Spending Account - Medical' &&
						objPl.Benefit_Type__c != 'Flexible Spending Account - Dependent Care' &&
						objPl.Benefit_Type__c != 'HSA' &&
						objPl.Benefit_Type__c != 'Commuter'
					) {
						CO_order_type_Map.put(objPl.Carrier__c, new Set<String>{ 'New to Gusto' });
					}
					oppPolicyCarrierSet.add(objPl.Carrier__c);
				}
			} else if (ttfRecord.RecordTypeId == TTF_RT_CHANGE || ttfRecord.RecordTypeId == TTF_RT_RENEWAL) {
				// get policies of account
				Map<String, List<Policy__c>> accountPolicies = new Map<String, List<Policy__c>>();
				for (Policy__c actP : [
					SELECT id, Benefit_Type__c, Carrier__c, Carrier__r.Name
					FROM Policy__c
					WHERE Account__c = :ttfRecord.Account__c AND Coverage_Effective_Date__c < :System.today() AND Expiration_Date__c > :System.today() AND Is_Selected__c = TRUE
				]) {
					//skip old policies which is going to be renew again
					if (oppPolicyCarrierSet.contains(actP.Carrier__c)) {
						continue;
					}
					if (accountPolicies.containskey(actP.Benefit_Type__c)) {
						accountPolicies.get(actP.Benefit_Type__c).add(actP);
					} else {
						accountPolicies.put(actP.Benefit_Type__c, new List<Policy__c>{ actP });
					}
				}

				Set<String> coOrderTypes;
				List<String> ordertypeVal;
				Map<Id, List<Policy__c>> carrieridPolicyMap = new Map<Id, List<Policy__c>>();
				BO_order_type = new List<String>{ '' };
				if (ttfRecord.RecordTypeId == TTF_RT_CHANGE) {
					BO_order_type = new List<String>{ 'New Line of Coverage' };
				}

				Map<String, Set<String>> tadaInputMap = new Map<String, Set<String>>();

				for (Policy__c objPl : list_Policy) {
					if (carrieridPolicyMap.containsKey(objPl.Carrier__c)) {
						List<Policy__c> pList = carrieridPolicyMap.get(objPl.Carrier__c);
						pList.add(objPl);
						carrieridPolicyMap.put(objPl.Carrier__c, pList);
					} else {
						carrieridPolicyMap.put(objPl.Carrier__c, new List<Policy__c>{ objPl });
					}
					coOrderTypes = new Set<String>();
					ordertypeVal = new List<String>();
					if (ttfRecord.RecordTypeId == TTF_RT_CHANGE) {
						CO_order_type_Map.put(objPl.Carrier__c, new Set<String>{ 'New Line of Coverage' });
						continue;
					}
					if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_MEDICAL) {
						blnOnlyTadasPolicy = false;
						// getes the order types for medical
						BO_order_type = TransitiontoFulfilmentUtil.getOrderTypeforMedical(TransitiontoFulfilmentUtil.BENEFIT_TYPE_MEDICAL, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.addAll(BO_order_type);
						//by carrier maintain all the carrier order types
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_DENTAL) {
						blnOnlyTadasPolicy = false;
						ordertypeVal = TransitiontoFulfilmentUtil.getOrderTypeforDental(TransitiontoFulfilmentUtil.BENEFIT_TYPE_DENTAL, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.AddAll(ordertypeVal);
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_VISION) {
						blnOnlyTadasPolicy = false;
						ordertypeVal = TransitiontoFulfilmentUtil.getOrderTypeforVision(TransitiontoFulfilmentUtil.BENEFIT_TYPE_VISION, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.AddAll(ordertypeVal);
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_LIFE) {
						blnOnlyTadasPolicy = false;
						ordertypeVal = TransitiontoFulfilmentUtil.getOrderTypeforLifeInsurance(TransitiontoFulfilmentUtil.BENEFIT_TYPE_LIFE, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.AddAll(ordertypeVal);
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_STD) {
						blnOnlyTadasPolicy = false;
						ordertypeVal = TransitiontoFulfilmentUtil.getOrderTypeforSTD(TransitiontoFulfilmentUtil.BENEFIT_TYPE_STD, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.AddAll(ordertypeVal);
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					} else if (objPl.Benefit_Type__c == TransitiontoFulfilmentUtil.BENEFIT_TYPE_LTD) {
						blnOnlyTadasPolicy = false;
						ordertypeVal = TransitiontoFulfilmentUtil.getOrderTypeforLTD(TransitiontoFulfilmentUtil.BENEFIT_TYPE_LTD, map_QALinesOfCoverage);
						if (CO_order_type_Map.containsKey(objPl.Carrier__c)) {
							coOrderTypes = CO_order_type_Map.get(objPl.Carrier__c);
						}
						coOrderTypes.AddAll(ordertypeVal);
						CO_order_type_Map.put(objPl.Carrier__c, coOrderTypes);
					}
				}

				if (ttfRecord.RecordTypeId == TTF_RT_RENEWAL && blnOnlyTadasPolicy && (BO_order_type?.size() == 0 || String.isBlank(BO_order_type[0]))) {
					BO_order_type = new List<String>{ strNoPlanGroupLevelChanges };
				}
				// create a wrrper class to user interface

				//static varibles are set to that the right values are set when creating the order
				orders.newBenefitOrder = new Benefit_Order__c(Name = 'To be created', Type__c = BO_order_type[0]);
				//Go through the loop of all the carrier order typ emap and for each carrier set the benefit types
				Set<String> set_uniqueOrderTypeSetOfAllCarrier = new Set<String>();
				for (String strCarrier : CO_order_type_Map.keySet()) {
					String strBenType = '';
					String strOrderType = '';
					for (Policy__c objPl : carrieridPolicyMap.get(strCarrier)) {
						if (strBenType == '') {
							strBenType = objPl.Benefit_Type__c;
						} else if (!strBenType.contains(objPl.Benefit_Type__c)) {
							strBenType += ';' + objPl.Benefit_Type__c;
						}
					}

					Set<String> set_uniqueOrderTypeSet = new Set<String>();
					for (String strOt : CO_order_type_Map.get(strCarrier)) {
						if (strOrderType == '') {
							strOrderType = strOt;
							set_uniqueOrderTypeSet.add(strOt);
						} else {
							if (!set_uniqueOrderTypeSet.contains(strOt)) {
								strOrderType += ';' + strOt;
								set_uniqueOrderTypeSet.add(strOt);
							}
						}
					}

					if (!set_uniqueOrderTypeSet.isEmpty()) {
						set_uniqueOrderTypeSetOfAllCarrier.addAll(set_uniqueOrderTypeSet);
					}

					//static varibles are set to that the right values are set when creating the order
					orders.newCarrierOrders.add(
						new Carrier_Order__c(
							Carrier__c = strCarrier,
							Name = carrieridPolicyMap.get(strCarrier)[0].Carrier__r.Name,
							Order_Type__c = strOrderType,
							Benefit_Types__c = strBenType,
							Benefit_Type_Details__c = strOrderType
						)
					);
				}

				if (String.IsBlank(BO_order_type[0])) {
					String strOrderAssignment = '';
					Integer intTemp = 10;
					for (String strOT : set_uniqueOrderTypeSetOfAllCarrier) {
						//check for new to gusto, tada nd terminated, if present order assignment should be that
						if (
							strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO) ||
							strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_TADA_NO_PRE_OE) ||
							strOT.equalsIgnoreCase(CarrierOrderUtil.CO_ORDER_TYPE_TADA_PRE_OE_SETUP) ||
							strOT.equalsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_TERMINATED_ORDER)
						) {
							strOrderAssignment = strOT;
							break;
						}
						// check for the order type precedents
						if (map_OrderTypePrecedents.containsKey(strOT.toLowerCase()) && intTemp > map_OrderTypePrecedents.get(strOT.toLowerCase())) {
							intTemp = map_OrderTypePrecedents.get(strOT.toLowerCase());
							strOrderAssignment = strOT;
						}
					}

					if (!String.isBlank(strOrderAssignment)) {
						BO_order_type = new List<String>{ strOrderAssignment };
					}
				}
			}

			if (list_Policy?.size() > 0) {
				blnIsPoliciesExist = true;
			}
		}
		return null;
	}

	public Boolean boOrderTypeReq { get; set; }

	public class AffliateWrapper {
		public Transition_to_Fulfillment__c ttf { get; set; }
		public AffliateWrapper() {
			ttf = new Transition_to_Fulfillment__c();
		}
	}

	public void doesHaveAffliate() {
		if (list_Affliates != null && list_Affliates.size() > 0) {
			return;
		} else {
			addAffliate();
		}
	}

	public void addAffliate() {
		AffliateWrapper aff = new AffliateWrapper();
		aff.ttf = new Transition_to_Fulfillment__c();
		list_Affliates.add(aff);
	}

	public void removeAffliate() {
		String indxToRemove = Apexpages.currentPage().getParameters().get('indx');
		if (String.isNotBlank(indxToRemove) && list_Affliates != null && list_Affliates.size() > Integer.valueOf(indxToRemove)) {
			list_Affliates.remove(Integer.valueOf(indxToRemove));
		}
	}

	/*
	 * Select Primary Contact Role
	 */
	public void selectPrimary() {
		if (idPrimaryRole != null) {
			Boolean blnPrimarySet = false;

			for (OpportunityContactRole objContactRole : list_OpptyContactRole) {
				if (objContactRole.Id == idPrimaryRole) {
					if (objContactRole.IsPrimary) {
						objContactRole.Check_Additional_POC__c = false; //Uncheck the additional POC field on Primary POC
						ttfRecord.Contact__c = objContactRole.ContactId;
					} else {
						ttfRecord.Contact__c = null;
					}
				} else if (objContactRole.IsPrimary) {
					objContactRole.IsPrimary = false; // Uncheck all other roles set as primary POC
				}
			}
			idPrimaryRole = null;
		}
	}

	/*
	 * Select Secondary Contact Role
	 */
	public void selectSecondary() {
		if (idSecRole != null) {
			for (OpportunityContactRole objContactRole : list_OpptyContactRole) {
				if (objContactRole.Id == idSecRole && objContactRole.IsPrimary && objContactRole.Check_Additional_POC__c) {
					objContactRole.IsPrimary = false; //Uncheck the additional POC field on Primary POC
					ttfRecord.Contact__c = null;
				}
			}
		}
	}

	/*
	 * Initialize Secondary Point of Contact Data
	 */
	private void initializeSecondaryPOCData() {
		if (ttfRecord != null && ttfRecord.Opportunity__c != null) {
			//Get Opportunity Contact Roles
			List<OpportunityContactRole> list_OpptyContactRoleTemp;
			list_OpptyContactRole = list_OpptyContactRoleTemp = new List<OpportunityContactRole>();
			list_OpptyContactRoleTemp = [
				SELECT OpportunityId, Contact.FirstName, Contact.LastName, Role, Check_Additional_POC__c, IsPrimary, ContactId
				FROM OpportunityContactRole
				WHERE OpportunityId = :ttfRecord.Opportunity__c
			];

			if (list_OpptyContactRoleTemp != null) {
				//Check for duplicate contacts
				map_ContactIdRole = new Map<String, String>();
				Map<Id, OpportunityContactRole> map_PreferredContactRole = new Map<Id, OpportunityContactRole>();
				for (OpportunityContactRole objConRole : list_OpptyContactRoleTemp) {
					map_PreferredContactRole = TransitiontoFulfilmentUtil.setPreferredContactRole(map_PreferredContactRole, objConRole);
					//map_ContactIdRole used to concatenate the role is used for displaying purpose, if Contact have multiple roles.
					String strRole = (objConRole.role == null) ? '' : objConRole.role;
					if (!map_ContactIdRole.containskey(objConRole.ContactId)) {
						map_ContactIdRole.put(objConRole.ContactId, strRole);
					} else {
						String strTempRole = map_ContactIdRole.get(objConRole.ContactId);
						String strPrevRole = (String.isNotBlank(strTempRole)) ? ', ' : '';
						if (String.isNotBlank(strRole)) {
							strTempRole += strPrevRole + strRole;
						}
						map_ContactIdRole.put(objConRole.ContactId, strTempRole);
					}
				}

				Boolean blnIsPrimaryExist = false;
				//Populate ContactRole list for unique contacts
				for (OpportunityContactRole objConRole : map_PreferredContactRole.values()) {
					if (ttfRecord.Id == null) {
						if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_ADMIN && !blnIsPrimaryExist) {
							blnIsPrimaryExist = true;
							objConRole.IsPrimary = true;
							objConRole.Check_Additional_POC__c = false;
						} else if (objConRole.role == TransitiontoFulfilmentUtil.BENEFITS_SIGNATORY) {
							objConRole.Check_Additional_POC__c = true;
							if (objConRole.IsPrimary) {
								objConRole.IsPrimary = false;
							}
						} else {
							objConRole.Check_Additional_POC__c = false;
							objConRole.IsPrimary = false;
						}
					}
					list_OpptyContactRole.add(objConRole);
					if (objConRole.IsPrimary) {
						ttfRecord.Contact__c = objConRole.ContactId;
					}
				}
			}
		}
	}

	/*
	 * Initialize QA Lines of Coverage map for each benefit type
	 */
	void initQALinesOfCoverageMap() {
		map_QALinesOfCoverage = new Map<String, QA_Lines_Of_Coverage__c>();
		if (ttfRecord.Opportunity__c != null) {
			List<QA_Lines_Of_Coverage__c> list_QALinesOfCoverage = fetchRelatedQALinesOfCoverage();

			if (list_QALinesOfCoverage != null && !list_QALinesOfCoverage.isEmpty()) {
				for (QA_Lines_Of_Coverage__c objLoC : list_QALinesOfCoverage) {
					map_QALinesOfCoverage.put(objLoC.Lines_Of_Coverage__c, objLoC);
				}
			}
		}
	}

	/*
	 * Fetch QA Lines of coverage related to Benefit Order on TTF
	 */
	List<QA_Lines_Of_Coverage__c> fetchRelatedQALinesOfCoverage() {
		List<QA_Lines_Of_Coverage__c> list_QALoC = new List<QA_Lines_Of_Coverage__c>();
		list_QALoC = [
			SELECT
				Lines_Of_Coverage__c,
				QA_Sheet__r.Benefit_Order__c,
				Does_group_have_an_alignment__c,
				Rate_Change__c,
				New_Line_of_Coverage__c,
				New_Carrier__c,
				Waiting_Period_Change__c,
				Plan_changes__c,
				Contribution_change__c
			FROM QA_Lines_Of_Coverage__c
			WHERE QA_Sheet__r.Opportunity__c = :ttfRecord.Opportunity__c
		];
		return list_QALoC;
	}

	/**
	 * @author      Bhagat Singh
	 * @description Skip trigger, which are not required during send order.
	 * @param       Boolean
	 **/
	public void skipTrigger(Boolean blnFlag) {
		CaseTriggerHelper.skipTrigger = blnFlag;
		TaskTriggerHelper.skipTrigger = blnFlag;
		EmailMessageTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		AccountRelatedTrackingTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
	}

	public class orderTypeEditWrapper {
		public Benefit_Order__c newBenefitOrder { get; set; }
		public List<Carrier_Order__c> newCarrierOrders { get; set; }
	}

	public class carrierWrapper {
		public List<String> medicalSwitchCarrier { get; set; }
		public List<String> medicalNewLineCarrier { get; set; }
		public List<String> visionSwitchCarrier { get; set; }
		public List<String> visionNewLineCarrier { get; set; }
		public List<String> dentalSwitchCarrier { get; set; }
		public List<String> dentalNewLineCarrier { get; set; }
		public List<String> lifeSwitchCarrier { get; set; }
		public List<String> lifeNewLineCarrier { get; set; }
		public List<String> longTermDisabilitySwitchCarrier { get; set; }
		public List<String> longTermDisabilityNewLineCarrier { get; set; }
		public List<String> shortTermDisabilitySwitchCarrier { get; set; }
		public List<String> shortTermDisabilityNewLineCarrier { get; set; }
		public carrierWrapper() {
			medicalSwitchCarrier = new List<String>();
			medicalNewLineCarrier = new List<String>();
			visionSwitchCarrier = new List<String>();
			visionNewLineCarrier = new List<String>();
			dentalSwitchCarrier = new List<String>();
			dentalNewLineCarrier = new List<String>();
			lifeSwitchCarrier = new List<String>();
			lifeNewLineCarrier = new List<String>();
			longTermDisabilitySwitchCarrier = new List<String>();
			longTermDisabilityNewLineCarrier = new List<String>();
			shortTermDisabilitySwitchCarrier = new List<String>();
			shortTermDisabilityNewLineCarrier = new List<String>();
		}
	}
}