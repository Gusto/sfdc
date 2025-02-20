import { LightningElement, track, api, wire } from "lwc";

import getPropertiesOnLoad from "@salesforce/apex/LogSmartCallingControllerLEX.getOnLoadProperties";
import saveCompleteRecords from "@salesforce/apex/LogSmartCallingControllerLEX.saveRecords";
import getNiceInteraction from "@salesforce/apex/LogSmartCallingControllerLEX.getNiceInteraction";
import saveLTC from "@salesforce/apex/LogSmartCallingControllerLEX.saveLTC";
import getLeadPassDetails from "@salesforce/apex/LogSmartCallingControllerLEX.getLeadPassDetails";
import saveLeadPass from "@salesforce/apex/LogSmartCallingControllerLEX.saveLeadPass";
import checkContactEmail from "@salesforce/apex/LogSmartCallingControllerLEX.checkContactEmail";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { loadStyle } from "lightning/platformResourceLoader";
import stretchMultiPicklists from "@salesforce/resourceUrl/LWCStretchMultiSelectPicklists";
import PRODUCT_UPSELL from "@salesforce/schema/Partnership_Interest__c";
import TAX_YEAR_LABEL from "@salesforce/label/c.CurrentTaxYear";
import LEAD_STATE from "@salesforce/schema/Lead.State";
import LEAD_STATUS from "@salesforce/schema/Lead.Status";
import LEAD_STATUS_DETAIL from "@salesforce/schema/Lead.Lead_Status_Detail__c";
import LIKELIHOOD_TO_STAY_WITH_GUSTO from "@salesforce/schema/Opportunity.Likelihood_to_Stay_with_Gusto__c";
import LIKELIHOOD_TO_STAY_WITH_GUSTO_ACC from "@salesforce/schema/Account.Likelihood_to_Stay_with_Gusto__c"; 
import GUSTO_RETENTION_NOTES from "@salesforce/schema/Opportunity.Gusto_Retention_Notes__c";
import GUSTO_RETENTION_NOTES_ACC from "@salesforce/schema/Account.Gusto_Retention_Notes__c";


import * as util from "./logSmartCallingLwcCmpUtil.js";

export default class LogSmartCallingLwcCmp extends LightningElement {
	@api recordId;
	@api objectApiName;
	//Purecloud attributes
	@track strNiceInteraction = "";

	objMetadata;
	@track objParameters = {
		strRecordId: "",
		strObjectName: "",
		strDisposition: "",
		strNotes: "",
		blnOpportunityPPA: false,
		blnInboundCall: false,
		blnOutboundEmail: false,
		blnOutboundCall: true,
		blnOpportunityDemo: false,
		blnTaskScheduledCall: false,
		blnCreateProductUpsell: false,
		blnAddProductInterest: false,
		blnInAppScheduler: false,
		list_ProductUpsellValues: [],
		list_ObjectDetailValues: [],
		blnDoNotCall: false,
		strFollowUpDate: "",
		strFollowUpSubject: util.TASK_SUBJECT.FOLLOW_UP_CALL,
		blnCreatePayrollOpportunity: false,
		strPayrollOpportunityName: "",
		strPayrollOpportunityStage: "",
		strPayrollOpportunityCloseDate: "",
		blnCreateHIOpportunity: false,
		blnCreateArdiusOpportunity: false,
		strHIOpportunityType: "",
		strHIOpportunityStage: util.OPP_STAGE.RAW,
		strArdiusOpportunityStage: util.ARDIUS_OPP_STAGE.GP,
		strHIOpportunityCloseDate: "",
		strArdiusOpportunityCloseDate: "",
		strHIOpportunityState: "",
		strHIOpportunityEmployees: "",
		strHIOpportunityNotes: "",
		blnHIOpportunityLiveTransfer: false,
		strWhoId: "",
		strWhatId: "",
		strPhoneNumber: "",
		strFeatureRequest: "",
		strCallObjective: "",
		strTaskType: util.TASK_TYPE.OUTBOUND_CALL,
		strPartnerSalesTaskType: "",
		strTaskSubject: "",
		strSelectedPointOfConId: "",
		strSelectedHIOppConId: "",
		strLeadCurrentStatus: "",
		strType: util.TAX_CREDIT_TYPE.NB,
		strTaxYear: "",
		strProductInterest: "",
		strProductInterestCountries: "",
		productInterestAccountId: "",
		strSecContactId: "",
		strFeatureRequestType: "",
		strLeadPassCountries: "",
		strLeadPassCountriesAdditional: ""
	};

	blnIsRendered = false;
	blnSpinner = false;
	blnShowModal = false;

	//opportunity contact roles
	@track list_ContactRoles = [];
	objContactRoleDisplayed;
	blnDisplayCase = false;

	//Payroll opty
	blnCreatePayrollOpty = false;
	@track list_PayrollOptyStages = [];

	//HI
	blnCreateHIOpty = false;
	//ARDIUS
	blnCreateArdiusOpty = false;
	blnAllowArdiusOpty = false;

	@track list_StateOptions = [];

	@track list_HIOptyStageOptions = [];
	//Opp details
	map_ObjectDetailValues = new Map();

	//product Interest
	blnProductInterest = false;
	blnShowProductInterestCountries = false;
	strAccountRecordTypeId = "";
	productInterestAccount;
	strProductInterestToShow = "";
	list_ProductInterestValues;
	@track list_CountryOptions = [];
	@track map_CountryOptions = [];
	@track list_SelectedCountryOptions = [];
	list_SelectedCountryOptionsOriginal = [];
	@track supportedCountries = [];

	//upsell
	blnLoadProductUpsell = false;
	blnHasProductUpsellFields = false;
	blnCreateProductUpsell = false;
	blnTypeSelected = false;
	blnType401 = false;
	blnType529 = false;
	blnTypeArdius = false;
	blnTypeWorkersComp = false;
	blnWorkersCompInterestNEXT = false;
	blnShowSecondaryContact = false;
	blnShowLeadPass = true;
	blnShowLeadPassModal = false;
	blnContactHasEmail = false;
	objLeadPassDetails;
	objLeadPassAccount;
	@track list_CountriesSentToRemote = [];
	@track list_CountriesSentToRemoteToDisplay = [];
	@track map_AllCountries = {};
	@track list_LeadPassOptions = [];
	@track list_LeadPassOptionsSelected = [];
	@track list_LeadPassOptionsAdditional = [];
	@track list_LeadPassOptionsAdditionalSelected = [];

	list_ProductUpsellPicklistFields;
	list_ProductUpsellMultiPicklistFields;
	list_ProductUpsell401KFields;
	list_ProductUpsell529TextAreaFields;
	list_ProductUpsellArdiusFields;
	list_ProductUpsellWorkersCompFields;
	list_ProductUpsellTextAreaFields;
	list_ProductUpsellOtherFields;
	list_SelectedProductUpsellType;
	list_AccountContacts = [];
	list_Contacts = []; 
	@track list_ProductUpsellFields = [];
	map_ProductUpsellValues = new Map();
	@track list_PointOfContact = [];
	@track list_HIAccountContacts = [];

	//object type
	obj_UserDetails;
	strCurrentRecordDetail = "";
	strAddtnlInfoDetail = "";
	blnButtonDisabled = false;
	@track map_ObjectProperties = new Map();
	@track list_ObjFields = [];
	@track map_AddtnlInfoObjectProperties = new Map();
	@track list_AddtnlInfoObjFields = [];
	selectedHIOpptyStage = util.OPP_STAGE.RAW;
	selectedArdiusOpptyStage = "";
	selectedType = util.TAX_CREDIT_TYPE.NB;
	selectedTaxYear = util.labels.TAX_YEAR_LABEL;
	blnShowCases;
	@track objProductUpsellInfo;

	@track objAllSmartCalling = {};
	@track list_ObjectiveOptions = [];
	@track list_PartnerSalesTypeOptions = [];
	@track map_PartnerSalesTypes = {};
	@track picklistOptionMap = new Map();

	selSObjectName;

	objTheLead;
	objTheAccount;
	@track accRecordType;

	_blnShowRelatedTo = false;
	showLtc = false;
	showSave = true;

	FIELD_API = {};

	get userRoleName() {
		return this.obj_UserDetails?.UserRole?.Name;
	}

	get userProfileName() {
		return this.obj_UserDetails?.Profile?.Name;
	}

	get list_DispositionOptions() {
		return this.blnIsCXUser ? [...util.list_DispositionOptions, util.PicklistOption.setLabelAndValue(util.TASK_CALL_DISPOSITION.NO_SHOW)] : util.list_DispositionOptions;
	}

	get list_HIOptyTypeOptions() {
		return util.list_HIOptyTypeOptions;
	}

	get list_FeatureRequestTypeOptions() {
		console.log("FRT===>", util.list_FeatureRequestTypeOptions);
		return util.list_FeatureRequestTypeOptions;
	}
	get blnIsCXUser() {
		return Boolean(this.userProfileName?.containsIgnoreCase(util.USER_PROFILE.CX_USER));
	}

	get blnIsArdiusUser() {
		return Boolean(this.userProfileName?.equalsIgnoreCase(util.USER_PROFILE.ARD_BASE_USER));
	}

	get blnShowTaskTypeSection() {
		return Boolean(this.objAllSmartCalling?.Show_Task_Type__c && this.list_TaskTypeOptionsByProfile?.length);
	}

	get blnShowPartnerSalesType() {
		return Boolean(this.blnShowTaskTypeSection && this.objAllSmartCalling?.Show_Partner_Sales_Type__c);
	}

	get blnDisablePartnerSalesType() {
		return !this.list_PartnerSalesTypeOptions?.length || !this.objParameters.strTaskType || this.objParameters.strTaskType === util.PicklistOption.OPTION_NONE;
	}

	get blnShowInboundCall() {
		return !this.blnIsCXUser && this.objAllSmartCalling?.Inbound_Call__c;
	}

	get blnShowOutboundEmail() {
		return !this.blnIsCXUser && this.objAllSmartCalling?.Outbound_Email__c;
	}

	get showSaveWOCall() {
		return this.blnIsCXUser || this.objectApiName !== util.SOBJECT_NAME.Benefit_Order__c;
	}

	get blnObjectiveRequired() {
		return this.blnIsArdiusUser || Boolean(this.objAllSmartCalling.Show_Call_Objective__c && this.objParameters.strDisposition === util.TASK_CALL_DISPOSITION.CONNECT);
	}

	get blnSaveButtonDisabled() {
		return this.blnButtonDisabled;
	}

	get blnIsNoOfEmployeesRequired() {
		return this.blnIsCXUser;
	}

	get blnIsHINotesRequired() {
		return this.blnIsCXUser;
	}

	get strDispositionHelpText() {
		return this.blnIsCXUser ? "" : util.DISPOSITION_HELP_TEXT;
	}

	get strFolloupDateHelpText() {
		return util.FOLLOWUPDATE_HELP_TEXT;
	}

	get strFolloupSubjectHelpText() {
		return util.FOLLOWUPSUBJECT_HELP_TEXT;
	}

	get strDoNotCallHelpText() {
		return util.DONOTCALL_HELP_TEXT;
	}

	get strHINotesHelpText() {
		return util.HINOTES_HELP_TEXT;
	}

	get strRelatedToHelpText() {
		return util.RELATEDTO_HELP_TEXT;
	}

	get strSecondaryPOCHelpText() {
		return util.SECONDARYPOC_HELP_TEXT;
	}

	get blnShowContactName() {
		return this.blnIsAccount || this.blnIsOpportunity || this.blnIsTicket;
	}

	get blnShowRelatedTo() {
		return this._blnShowRelatedTo && this.blnIsAccount;
	}

	get categoryOptions() {
		return util.categoryOptions;
	}

	get blnCreateLeadPass() {
		let blnHasAccessFinal = false;
		let list_Roles = [];
		this.objAllSmartCalling?.Create_Lead_Pass_Roles__c?.split(",")?.forEach((strRole) => {
			list_Roles.push(strRole);
		});
		if (this.objAllSmartCalling?.Create_Lead_Pass__c) {
			blnHasAccessFinal = list_Roles?.length && !list_Roles.includes(this.userRoleName) ? false : true;
		}
		return blnHasAccessFinal;
	}

	@wire(getObjectInfo, { objectApiName: PRODUCT_UPSELL })
	objProductUpsellInfo;

	get customerSucessRT() {
		const list_RecordTypes = this.objProductUpsellInfo.data.recordTypeInfos;
		return Object.keys(list_RecordTypes).find((objRT) => list_RecordTypes[objRT].name === util.PRODUCT_UPSELL_RT_NAME.CUSTOMER_SUCCESS);
	}

	get accountRecordTypeId() {
		return this.strAccountRecordTypeId;
	}

	connectedCallback() {
		this.strCurrentRecordDetail = `${util.SOBJECT_NAME[this.objectApiName]} ${util.DETAIL}`;
		this.strAddtnlInfoDetail = `${util.SOBJECT_NAME[this.objectApiName]} ${util.ADDITIONAL_INFO}`;
		this.doInit();

		this.FIELD_API.LEAD_STATE = LEAD_STATE.fieldApiName;
		if (this.blnIsAccount) {
			this.FIELD_API.LIKELIHOOD_TO_STAY_WITH_GUSTO = LIKELIHOOD_TO_STAY_WITH_GUSTO_ACC.fieldApiName;
			this.FIELD_API.GUSTO_RETENTION_NOTES = GUSTO_RETENTION_NOTES_ACC.fieldApiName;
		}else{
			this.FIELD_API.LIKELIHOOD_TO_STAY_WITH_GUSTO = LIKELIHOOD_TO_STAY_WITH_GUSTO.fieldApiName;
			this.FIELD_API.GUSTO_RETENTION_NOTES = GUSTO_RETENTION_NOTES.fieldApiName;
		}
		this.selectedTaxYear = util.labels.TAX_YEAR_LABEL;
	}

	renderedCallback() {
		if (this.blnIsRendered) return;
		this.blnIsRendered = true;
		const style = document.createElement("style");
		style.innerText = `
            section h3 {
                background-color: #f2f2f2;
                padding: 3px 3px;
            }
        `;
		this.template.querySelector("lightning-accordion-section")?.appendChild(style);

		Promise.all([loadStyle(this, stretchMultiPicklists)]);
	}

	doInit() {
		this.blnSpinner = true;
		this.blnButtonDisabled = true;
		const t0 = performance.now();

		// Calling the imperative Apex method with the JSON
		getPropertiesOnLoad({
			strObjectName: this.objectApiName,
			strRecordId: this.recordId
		})
			.then((result) => {
				const t1 = performance.now();
				console.log("time taken for getPropertiesOnLoad : " + (t1 - t0) + " milliseconds.");

				if (result?.strMetadataProperties) {
					let strHIOpportunityCloseDate = "";
					let strArdiusOpportunityCloseDate = "";
					this.blnAllowArdiusOpty = result.disableArdiusOpp;
					this.list_AccountContacts = JSON.parse(JSON.stringify(result?.list_AccountContacts));
					this.obj_UserDetails = result.objUserDetails;
					this.assignFieldProperties(result.strMetadataProperties);
					this.assignProductUpsellProperties(result.list_ProductUpsellProperties);
					this.assignObjectProperties(result);
					this.assignContactRoles(result);
					this.assignStateOptions(result.list_States);
					// adding countries to map so that we can show labels in the available options
					this.assignProductInterestCountryOptions(result.map_PICountryOptions);
					// adding already selected countries to list so that we can show in the chosen options
					this.assignSelectedProductInterestCountries(result.list_SelectedProductInterestCountries);
					this.assignSupportedCountries(result.list_SupportedCountries);
					this.assignCallObjectives(result.list_CallObjectives);
					this.strCallObjectiveHelpText = result.strCallObjectiveHelpText;

					this.list_TaskTypeOptionsByProfile = this.userProfileName || this.userRoleName ? util.populateTaskType(this.userProfileName, this.userRoleName) : [];

					if (this.blnShowPartnerSalesType) {
						this.map_PartnerSalesTypes = result.map_PartnerSalesTypes;
						this.setPartnerSalesTaskTypeOptions();
					}

					if (this.blnIsAccount || this.blnIsOpportunity) {
						strHIOpportunityCloseDate = this.getLastDateofMonth();
						strArdiusOpportunityCloseDate = this.getLastDateofMonth();
						this.objParameters.strWhatId = this.recordId;
						this.selSObjectName = this.objectApiName;
						this.strAccountRecordTypeId = result?.objProductInterestAccount?.RecordTypeId;
						this.productInterestAccount = result?.objProductInterestAccount;
						if (this.blnIsAccount) {
							this.setRelatedToOptions(result);
							this._blnShowRelatedTo = true;
						}

						if (!this.blnCreateLeadPass) {
							this.blnShowLeadPass = false;
						}
					}

					this.objParameters.strHIOpportunityCloseDate = strHIOpportunityCloseDate;
					this.objParameters.strArdiusOpportunityCloseDate = strArdiusOpportunityCloseDate;
				} else {
					console.error(util.ERROR_MSGS.NO_ALL_SMART_CALLING_METADATA);
				}
			})
			.catch((error) => {
				let strErrMsg = error.body?.message || error.message;
				console.error(strErrMsg);
				util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			})
			.finally(() => {
				this.blnSpinner = false;
				this.blnButtonDisabled = false;
			});
	}

	assignFieldProperties(result) {
		this.objMetadata = result;
		this.objAllSmartCalling = JSON.parse(result);

		//payroll opportunity
		const list_PayrollOptyStages = [];
		this.objAllSmartCalling?.Payroll_Opp_Stages__c?.split(",")?.forEach((strStage) => {
			list_PayrollOptyStages.push(util.PicklistOption.setLabelAndValue(strStage));
		});
		this.list_PayrollOptyStages = list_PayrollOptyStages;

		//HI opportunity
		const list_HIOptyStageOptions = [];
		this.objAllSmartCalling?.Hi_Opp_Stages__c?.split(",")?.forEach((strStage) => {
			list_HIOptyStageOptions.push(util.PicklistOption.setLabelAndValue(strStage));
		});
		this.list_HIOptyStageOptions = list_HIOptyStageOptions;
		//Ardius opportunity
		const list_ArdiusOptyStageOptions = [];
		this.objAllSmartCalling?.Ardius_Opp_Stage_Values__c?.split(",")?.forEach((strStage) => {
			list_ArdiusOptyStageOptions.push(util.PicklistOption.setLabelAndValue(strStage));
		});
		this.list_ArdiusOptyStageOptions = list_ArdiusOptyStageOptions;
		//Tax Credit Type
		const list_TaxCreditsTypeOptions = [];
		this.objAllSmartCalling?.Tax_Credits_Type_Values__c?.split(",")?.forEach((strStage) => {
			list_TaxCreditsTypeOptions.push(util.PicklistOption.setLabelAndValue(strStage));
		});
		this.list_TaxCreditsTypeOptions = list_TaxCreditsTypeOptions;
	}

	assignProductUpsellProperties(result) {
		if (result?.length) {
			this.list_ProductUpsellPicklistFields = [];
			this.list_ProductUpsellMultiPicklistFields = [];
			this.list_ProductUpsellTextAreaFields = [];
			this.list_ProductUpsellOtherFields = [];

			this.list_ProductUpsell401KFields = [];
			this.list_ProductUpsell529TextAreaFields = [];
			this.list_ProductUpsellArdiusFields = [];
			this.list_ProductUpsellWorkersCompFields = [];

			result.forEach((current) => {
				if (current.strTypeDependantCategory == "") {
					switch (current.strFieldType) {
						case util.FIELD_TYPE.PICKLIST:
							this.list_ProductUpsellPicklistFields.push(current);
							break;
						case util.FIELD_TYPE.MULTIPICKLIST:
							this.list_ProductUpsellMultiPicklistFields.push(current);
							break;
						case util.FIELD_TYPE.TEXTAREA:
							this.list_ProductUpsellTextAreaFields.push(current);
							break;
						default:
							this.list_ProductUpsellOtherFields.push(current);
					}
				} else if (current.strTypeDependantCategory != "") {
					switch (current.strTypeDependantCategory) {
						case "Type_401K":
							this.list_ProductUpsell401KFields.push(current);
							break;
						case "Type_529":
							this.list_ProductUpsell529TextAreaFields.push(current);
							break;
						case "Type_TaxCredits":
							this.list_ProductUpsellArdiusFields.push(current);
							break;
						case "Type_WorkersComp":
							this.list_ProductUpsellWorkersCompFields.push(current);
							break;
						default:
							break;
					}
				}
			});
			if (this.userProfileName != util.USER_PROFILE.ARD_BASE_USER) {
				this.blnHasProductUpsellFields = true;
			} else {
				this.blnHasProductUpsellFields = false;
			}
		}
	}

	assignObjectProperties(result) {
		const map_ObjectProperties = new Map();
		const map_AddtnlInfoObjectProperties = new Map();

		if (result?.map_CurrentObjectProperties) {
			for (let [strFieldName, objField] of Object.entries(result.map_CurrentObjectProperties)) {
				objField.intSize = 12;
				objField.intSmallSize = 12;
				objField.intLargeSize = 6;
				objField.intMediumSize = 6;

				if (objField.strFieldType === util.FIELD_TYPE.MULTIPICKLIST) {
					objField.intLargeSize = 12;
					objField.intMediumSize = 12;
				}

				if (strFieldName === this.FIELD_API.LEAD_STATE && this.blnIsLead) {
					objField.blnShowSpecific = true;
					objField.blnShowState = true;
					objField.strStateValue = result?.objLead?.State ? result.objLead.State : "";
				}

				map_ObjectProperties.set(strFieldName, objField);
			}
		}

		if (result?.map_AddtnlInfoObjectProperties) {
			for (let [strFieldName, objField] of Object.entries(result.map_AddtnlInfoObjectProperties)) {
				objField.intSize = 12;
				objField.intSmallSize = 12;
				objField.intLargeSize = 6;
				objField.intMediumSize = 6;

				if (objField.strFieldType === util.FIELD_TYPE.MULTIPICKLIST) {
					objField.intLargeSize = 12;
					objField.intMediumSize = 12;
				}

				map_AddtnlInfoObjectProperties.set(strFieldName, objField);
			}
		}

		this.map_ObjectProperties = map_ObjectProperties;
		this.list_ObjFields = Array.from(map_ObjectProperties.values());
		this.map_AddtnlInfoObjectProperties = map_AddtnlInfoObjectProperties;
		this.list_AddtnlInfoObjFields = Array.from(map_AddtnlInfoObjectProperties.values());
	}

	assignContactRoles(result) {
		let list_PointOfContact = [];
		let list_ContactRoles = [];
		let map_ContactIdToRoles = new Map();

		if (this.blnIsOpportunity || this.blnIsTicket) {
			let blnHasNumber;
			result?.list_ContactRoles?.forEach((current) => {
				let record = {
					id: current.objOptyContactRole?.ContactId,
					name: current.objOptyContactRole?.Contact?.Name,
					email: current.objOptyContactRole?.Contact?.Email,
					phone: current.objOptyContactRole?.Contact?.Phone,
					mobile: current.objOptyContactRole?.Contact?.MobilePhone,
					zpphone: current.objOptyContactRole?.Contact?.ZP_Phone__c,
					role: current.objOptyContactRole?.Role,
					blnDisplay: false,
					list_Cases: current?.list_Cases
				};

				if (!blnHasNumber) {
					blnHasNumber = Boolean(record.phone || record.mobile || record.zpphone);
				}
				if (!map_ContactIdToRoles.has(record.id)) {
					map_ContactIdToRoles.set(record.id, record);
					list_PointOfContact.push(new util.PicklistOption(record.name, record.id));
				}
			});
			list_ContactRoles = Array.from(map_ContactIdToRoles.values());

			if (!this.blnIsCXUser && !result?.list_ContactRoles?.length && !blnHasNumber) {
				this.displayLtc();
			}
		} else if (this.blnIsAccount) {
			result?.list_ContactRoles?.forEach((current) => {
				let record = {
					id: current.objAcctContact?.Contact__c,
					name: current.objAcctContact?.Contact__r?.FirstName + " " + current.objAcctContact?.Contact__r?.LastName,
					email: current.objAcctContact?.Contact__r?.Email,
					phone: current.objAcctContact?.Contact__r?.Phone,
					mobile: current.objAcctContact?.Contact__r?.MobilePhone,
					zpphone: current.objAcctContact?.Contact__r?.ZP_Phone__c,
					role: current.objAcctContact?.Role_Name__c,
					blnDisplay: false,
					list_Cases: current?.list_Cases
				};
				if (!map_ContactIdToRoles.has(record.id)) {
					map_ContactIdToRoles.set(record.id, record);
					list_PointOfContact.push(new util.PicklistOption(record.name, record.id));
				}
				list_ContactRoles = Array.from(map_ContactIdToRoles.values());
			});
		} else if (this.blnIsLead && result?.objLead && Object.keys(result.objLead).length) {
			let record = {
				id: result.objLead.Id,
				name: result.objLead.Name,
				email: result.objLead.Email,
				phone: result.objLead.Phone,
				mobile: result.objLead.MobilePhone,
				secondaryPhone: result.objLead.Secondary_Phone__c
			};

			if (!this.blnIsCXUser && !record.phone && !record.mobile && !record.secondaryPhone) {
				this.displayLtc();
			}

			this.objTheLead = result.objLead;
			list_ContactRoles.push(record);
			list_PointOfContact.push(new util.PicklistOption(record.name, record.id));
		}

		this.list_ContactRoles = list_ContactRoles;
		this.list_PointOfContact = list_PointOfContact;
	}

	get list_AccountContactsOptions() {
		if(this.list_Contacts.length < 1 ){
			console.log("after if options ==>");
			this.list_AccountContacts?.forEach((current) => {
				this.list_Contacts.push(new util.PicklistOption(current.Name, current.Id));
			});
			}
		return this.list_Contacts;
	}

	assignStateOptions(result) {
		const list_StateOptions = [];
		result?.forEach((state) => {
			list_StateOptions.push(util.PicklistOption.setLabelAndValue(state));
		});
		this.list_StateOptions = list_StateOptions;
	}

	// method to prepare the available countries option
	assignProductInterestCountryOptions(result) {
		const list_CountryOptions = [];
		this.map_CountryOptions = result;
		for (var key in result) {
			list_CountryOptions.push(new util.PicklistOption(key, result[key]));
		}
		this.list_CountryOptions = list_CountryOptions;
	}

	// method to prepare the chosen countries option
	assignSelectedProductInterestCountries(result) {
		const list_SelectedOptions = [];
		result?.forEach((country) => {
			list_SelectedOptions.push(country);
		});
		this.list_SelectedCountryOptions = list_SelectedOptions;
		this.list_SelectedCountryOptionsOriginal = list_SelectedOptions;
	}

	assignSupportedCountries(result) {
		this.supportedCountries = result;
	}

	assignCallObjectives(result) {
		const list_ObjectiveOptions = [];
		result?.forEach((current) => {
			list_ObjectiveOptions.push(util.PicklistOption.setLabelAndValue(current));
		});
		this.list_ObjectiveOptions = list_ObjectiveOptions;
	}

	displayLtc() {
		this.showLtc = true;
	}

	handleOpenRecord(event) {
		event.preventDefault();
		let recordId = event.target.dataset.id;
		this.dispatchEvent(
			new CustomEvent("openrecord", {
				detail: { recordId }
			})
		);
	}

	handleDisplayCase(event) {
		let idContact = event.target.dataset.id;
		this.list_ContactRoles.forEach((objCont) => {
			let strContactId = objCont.id;

			if (strContactId === idContact) {
				objCont.blnDisplay = true;
				this.objContactRoleDisplayed = objCont;
			} else {
				objCont.blnDisplay = false;
			}
		});

		this.blnDisplayCase = true;
	}

	handleHideCase(event) {
		let idContact = event.target.dataset.id;
		this.list_ContactRoles.forEach((objCont) => {
			let strContactId = objCont.id;

			if (strContactId === idContact) {
				objCont.blnDisplay = false;
				this.objContactRoleDisplayed = null;
			}
		});

		this.blnDisplayCase = false;
	}

	handleDispositionChange(event) {
		const value = event.detail.value;
		const strDatetime = new Date().toLocaleString();
		let strNotes = this.objParameters.strNotes;
		let strTaskSubject = this.objParameters.strTaskSubject;
		let strRegexDisposition = this.objParameters.strDisposition;

		this.objParameters.strDisposition = value;

		if (this.blnIsCXUser || !value) {
			return;
		} else {
			if (strRegexDisposition && strNotes?.startsWithIgnoreCase(strRegexDisposition)) {
				const strRegex = new RegExp(strRegexDisposition, "i");
				strNotes = strNotes?.replace(strRegex, value);
				strTaskSubject = strTaskSubject?.replace(strRegex, value);
			} else {
				let strCommonTxt = `${value} || ${strDatetime} || ${this.obj_UserDetails.Name}` + "\n";
				strNotes = strCommonTxt + strNotes;
				strTaskSubject = strCommonTxt + strTaskSubject;
			}

			if (this.objectApiName === util.SOBJECT_NAME.Benefit_Order__c) {
				strNotes += !strNotes?.containsIgnoreCase(util.NOTES) ? "\n" + util.NOTES + " \n" + util.ACTION_ITEMS + " \n" : "";
				this.objParameters.strNotes = strNotes;
				return;
			}
		}

		this.objParameters.strNotes = strNotes;
		this.objParameters.strTaskSubject = this.objAllSmartCalling.Show_Subject__c ? strTaskSubject : "";
	}

	handleFeatureRequestTypeChange(event) {
		this.objParameters.strFeatureRequestType = event.detail.value;
	}

	handleObjectiveChange(event) {
		this.objParameters.strCallObjective = event.detail.value;
	}

	handleTaskTypeChange(event) {
		this.objParameters.strTaskType = event.detail.value;
		this.objParameters.strPartnerSalesTaskType = "";

		this.blnShowPartnerSalesType && this.setPartnerSalesTaskTypeOptions();
	}

	setPartnerSalesTaskTypeOptions() {
		const list_CallPicklist = util.labels.TASK_CALL_PICKLIST.toLowerCase().split(",");
		const strTaskType = this.objParameters.strTaskType;
		const list_PartnerSalesTypeOptions = [];

		if (this.map_PartnerSalesTypes) {
			Object.entries(this.map_PartnerSalesTypes).forEach(([value, label]) => {
				if (
					(list_CallPicklist?.includes(label.toLowerCase()) && (strTaskType?.equalsIgnoreCase(util.TASK_TYPE.INBOUND_CALL) || strTaskType?.equalsIgnoreCase(util.TASK_TYPE.OUTBOUND_CALL))) ||
					(!strTaskType?.equalsIgnoreCase(util.TASK_TYPE.INBOUND_CALL) && !strTaskType.equalsIgnoreCase(util.TASK_TYPE.OUTBOUND_CALL))
				) {
					list_PartnerSalesTypeOptions.push(new util.PicklistOption(label, value));
				}
			});
		}

		this.list_PartnerSalesTypeOptions = list_PartnerSalesTypeOptions;
	}

	setRelatedToOptions(objResult) {
		const picklistOptionMap = new Map();
		const accRecTypeName = objResult?.objAccount?.RecordType.Name;
		this.accRecordType = accRecTypeName;

		picklistOptionMap
			.set(this.objectApiName, [new util.PicklistOption(util.PicklistOption.OPTION_NONE, "")])
			.set(util.SOBJECT_NAME.Opportunity, [new util.PicklistOption(util.PicklistOption.OPTION_NONE, "")]);

		if (accRecTypeName === util.REC_TYPE_NAMES[this.objectApiName].COMPANY) {
			picklistOptionMap.get(this.objectApiName).push(new util.PicklistOption(objResult.objAccount.Name, objResult.objAccount.Id));

			if (objResult?.map_CompanyOpportunities) {
				for (let [idOppId, objOpportunity] of Object.entries(objResult.map_CompanyOpportunities)) {
					let objPicklistOption = new util.PicklistOption(objOpportunity.Name, idOppId);
					picklistOptionMap.get(util.SOBJECT_NAME.Opportunity).push(objPicklistOption);
				}
			}
		} else if (accRecTypeName === util.REC_TYPE_NAMES[this.objectApiName].RESELLER) {
			picklistOptionMap.get(this.objectApiName).push(new util.PicklistOption(objResult.objAccount.Name, objResult.objAccount.Id));
			if (objResult?.map_CompanyAccounts) {
				for (let [idAccountId, objAccount] of Object.entries(objResult.map_CompanyAccounts)) {
					let objPicklistOption = new util.PicklistOption(objAccount.Name, idAccountId);
					picklistOptionMap.get(this.objectApiName).push(objPicklistOption);

					objAccount?.Opportunities?.forEach((objOpportunity) => {
						objPicklistOption = new util.PicklistOption(objOpportunity.Name, objOpportunity.Id);
						picklistOptionMap.get(util.SOBJECT_NAME.Opportunity).push(objPicklistOption);
					});
				}
			}
		}

		this.picklistOptionMap = picklistOptionMap;
	}

	handlePartnerSalesTypeChange(event) {
		this.objParameters.strPartnerSalesTaskType = event.detail.value;
	}

	handleTaskSubjectChange(event) {
		this.objParameters.strTaskSubject = event.detail.value;
	}

	handleInboundCallChange(event) {
		this.objParameters.blnInboundCall = event.target.checked;
	}

	handleOutboundEmailChange(event) {
		this.objParameters.blnOutboundEmail = event.target.checked;
	}

	handleCreatePayrollOp(event) {
		this.blnCreatePayrollOpty = event.target.checked;
		this.objParameters.blnCreatePayrollOpportunity = event.target.checked;
	}

	handleCreateProductUpsell(event) {
		this.blnCreateProductUpsell = event.target.checked;
		this.objParameters.blnCreateProductUpsell = event.target.checked;

		if (!this.objParameters.blnCreateProductUpsell) {
			this.objParameters.map_ProductUpsellValues = new Map();
		}
	}

	handlePointOfContactChange(event) {
		const value = event.detail?.value ? event.detail.value : "";
		if (this.blnIsCXUser || !this.objParameters.strWhoId) {
			this.objParameters.strWhoId = value;
		}

		if (!this.blnIsCXUser) {
			this.objParameters.strSelectedPointOfConId = value;
		}
	}

	handleSecondaryPointOfContactChange(event) {
		const value = event.detail?.value ? event.detail.value : "";
		this.objParameters.strSecContactId = value;
	}

	handleContactNameChange(event) {
		const value = event.detail?.value ? event.detail.value : "";
		this.objParameters.strWhoId = value;
		let contactSelectCmp = this.template.querySelector('[data-uniqueid="contactNameLeadPass"]');
		if (contactSelectCmp) {
			contactSelectCmp.setCustomValidity("");
			contactSelectCmp.reportValidity();
		}
		this.checkContactEmail();
	}

	checkContactEmail() {
		checkContactEmail({
			strContactId: this.objParameters.strWhoId
		})
			.then((result) => {
				this.blnContactHasEmail = result;
			})
			.catch((error) => {
				let strErrMsg = error.body?.message || error.message;
				console.error(error);
				util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
			})
			.finally(() => {
				this.blnSpinner = false;
			});
	}

	handleBenefitsContactChange(event){
		this.objParameters.strSelectedHIOppConId = event.target.value;
	}

	handleCreateHIOp(event) {
		this.blnCreateHIOpty = event.target.checked;
		this.objParameters.blnCreateHIOpportunity = event.target.checked;
	}

	handleCreateArdiusOp(event) {
		this.blnCreateArdiusOpty = event.target.checked;
		this.objParameters.blnCreateArdiusOpportunity = event.target.checked;
	}

	handleAddProductInterest(event) {
		this.list_ProductInterestValues = [];
		this.blnProductInterest = event.target.checked;
		this.blnShowProductInterestCountries = event.target.checked;
		this.objParameters.blnAddProductInterest = event.target.checked;
		this.objParameters.productInterestAccountId = this.productInterestAccount.Id;
		this.list_ProductInterestValues.push(new util.PicklistOption("Employer of Record", "international_payroll_logacall"));
		this.list_ProductInterestValues.push(new util.PicklistOption("Premium Tier", "premium_tier_logacall"));
		this.list_ProductInterestValues.push(new util.PicklistOption("International Contractor Payment", "international_contractor_payment_logacall"));
		this.strProductInterestToShow = "international_payroll_logacall";
		this.objParameters.strProductInterestCountries = this.list_SelectedCountryOptions.toString();
		this.objParameters.strProductInterest = this.strProductInterestToShow;
	}

	handleOptyStageChange(event) {
		this.objParameters.strPayrollOpportunityStage = event.detail.value;
	}

	handleHIOptyTypeChange(event) {
		this.objParameters.strHIOpportunityType = event.detail.value;
	}

	handleHIOptyStageChange(event) {
		this.objParameters.strHIOpportunityStage = event.detail.value;
	}

	handleArdiusOptyStageChange(event) {
		this.objParameters.strArdiusOpportunityStage = event.detail.value;
	}

	handleTaxCreditTypeChange(event) {
		this.objParameters.strType = event.detail.value;
	}

	handleTaxYearChange(event) {
		if (event.detail.value.length == 4 && event.detail.value != "") {
			this.objParameters.strTaxYear = event.detail.value;
		} else {
			//util.displayToast(this, util.ERROR_MSGS.TAX_YEAR_LENGTH, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			this.objParameters.strTaxYear = util.labels.TAX_YEAR;
		}
	}

	handleProductInterest(event) {
		this.objParameters.strProductInterest = event.detail.value;
		if (event.detail.value == "premium_tier_logacall" || event.detail.value == "international_contractor_payment_logacall") {
			this.strProductInterestToShow = event.detail.value;
			this.blnShowProductInterestCountries = false;
			this.list_SelectedCountryOptions = this.list_SelectedCountryOptionsOriginal;
			this.objParameters.strProductInterestCountries = this.list_SelectedCountryOptions.toString();
		} else if (event.detail.value == "international_payroll_logacall") {
			this.strProductInterestToShow = "international_payroll_logacall";
			this.blnShowProductInterestCountries = true;
		}
	}

	handleStateChange(event) {
		this.objParameters.strHIOpportunityState = event.detail.value;
	}

	handleProductInterestCountry(event) {
		this.list_SelectedCountryOptions = event.detail.value;
		this.objParameters.strProductInterestCountries = this.list_SelectedCountryOptions.toString();
	}

	handleLeadPass(event) {
		if (!this.blnCreateLeadPass) {
			util.displayToast(this, util.ERROR_MSGS.LEAD_PASS_NOT_AVAILABLE, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
			return;
		}
		this.blnSpinner = true;
		getLeadPassDetails({ strAccountId: this.productInterestAccount.Id })
			.then((result) => {
				this.objLeadPassDetails = result;
				this.list_CountriesSentToRemote = this.objLeadPassDetails.list_CountriesSentToRemote ? this.objLeadPassDetails.list_CountriesSentToRemote : null;
				this.map_AllCountries = this.objLeadPassDetails.map_AllCountries ? this.objLeadPassDetails.map_AllCountries : null;
				let list_ProductInterestCountryOptions = this.objLeadPassDetails.list_ProductInterestCountryOptions ? this.objLeadPassDetails.list_ProductInterestCountryOptions : null;
				let list_SelectedProductInterestCountries = this.objLeadPassDetails.list_SelectedProductInterestCountries ? this.objLeadPassDetails.list_SelectedProductInterestCountries : null;
				if (this.list_CountriesSentToRemote) {
					this.list_CountriesSentToRemote.forEach((country) => {
						this.list_CountriesSentToRemoteToDisplay.push(this.map_AllCountries[country]);
					});
					this.list_CountriesSentToRemoteToDisplay.sort();
				}
				this.objLeadPassAccount = this.objLeadPassDetails.objProductInterestAccount;
				if (list_SelectedProductInterestCountries) {
					let list_LeadPassOptions = [];
					let list_LeadPassOptionsSelected = [];
					let list_LeadPassOptionsAdditional = [];
					list_SelectedProductInterestCountries.forEach((country) => {
						let countryLabel = this.map_AllCountries[country];
						list_LeadPassOptions.push(new util.PicklistOption(countryLabel, country));
						if (!this.list_CountriesSentToRemoteToDisplay.includes(countryLabel) && !this.supportedCountries.includes(country)) {
							list_LeadPassOptionsSelected.push(country);
						}
					});
					this.list_LeadPassOptions = list_LeadPassOptions;
					this.list_LeadPassOptionsSelected = list_LeadPassOptionsSelected;
					if (this.list_LeadPassOptionsSelected.length > 0) {
						this.objParameters.strLeadPassCountries = this.list_LeadPassOptionsSelected.toString();
					}
					list_ProductInterestCountryOptions.forEach((country) => {
						let countryLabel = this.map_AllCountries[country];
						if (!list_SelectedProductInterestCountries.includes(country) && !this.list_LeadPassOptionsSelected.includes(country) && !this.supportedCountries.includes(country)) {
							list_LeadPassOptionsAdditional.push(new util.PicklistOption(countryLabel, country));
						}
					});
					this.list_LeadPassOptionsAdditional = list_LeadPassOptionsAdditional;
				}
				this.blnShowModal = true;
				this.blnShowLeadPassModal = true;
			})
			.catch((error) => {
				let strErrMsg = error.body?.message || error.message;
				console.error(error);
				util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
			})
			.finally(() => {
				this.blnSpinner = false;
			});
	}

	handleLeadPassSend() {
		let contactSelectCmp = this.template.querySelector('[data-uniqueid="contactNameLeadPass"]');
		let countrySelectCmp = this.template.querySelector('[data-uniqueid="countrySelect"]');
		let countrySelectAdditionalCmp = this.template.querySelector('[data-uniqueid="countrySelectAdditional"]');
		countrySelectCmp.setCustomValidity("");
		countrySelectCmp.reportValidity();
		countrySelectAdditionalCmp.setCustomValidity("");
		countrySelectAdditionalCmp.reportValidity();
		contactSelectCmp.setCustomValidity("");
		contactSelectCmp.reportValidity();
		if (this.objParameters.strWhoId == "") {
			contactSelectCmp.setCustomValidity(util.ERROR_MSGS.SELECT_CONTACT_BEFORE_SAVING);
			contactSelectCmp.reportValidity();
			util.displayToast(this, util.ERROR_MSGS.SELECT_CONTACT_BEFORE_SAVING, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}
		this.blnSpinner = true;
		if (this.list_LeadPassOptionsSelected.length == 0 && this.list_LeadPassOptionsAdditionalSelected.length == 0) {
			countrySelectCmp.setCustomValidity(util.ERROR_MSGS.LEAD_PASS_FIELDS_REQUIRED);
			countrySelectCmp.reportValidity();
			countrySelectAdditionalCmp.setCustomValidity(util.ERROR_MSGS.LEAD_PASS_FIELDS_REQUIRED);
			countrySelectAdditionalCmp.reportValidity();
			util.displayToast(this, util.ERROR_MSGS.LEAD_PASS_FIELDS_REQUIRED, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			this.blnSpinner = false;
			return;
		}
		this.objParameters.productInterestAccountId = this.productInterestAccount.Id;
		this.objParameters.strRecordId = this.recordId;
		this.objParameters.strObjectName = this.objectApiName;
		this.objParameters.strProductInterest = "international_payroll_logacall";
		saveLeadPass({
			strDataInJson: JSON.stringify(this.objParameters)
		})
			.then((result) => {
				util.displayToast(this, util.TOAST_PARAMS.MESSAGE.SUCCESS, util.SUCCESS_MSGS.LEAD_PASS_SUCCESS, util.TOAST_PARAMS.TYPE.SUCCESS, "");
				this.refreshComponent();
			})
			.catch((error) => {
				let strErrMsg = error.body?.message || error.message;
				console.error(error);
				util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
			})
			.finally(() => {
				this.blnSpinner = false;
			});
	}

	handleLeadPassOption(event) {
		this.list_LeadPassOptionsSelected = event.detail.value;
		this.objParameters.strLeadPassCountries = this.list_LeadPassOptionsSelected.toString();
		let countrySelectCmp = this.template.querySelector('[data-uniqueid="countrySelect"]');
		countrySelectCmp.setCustomValidity("");
		countrySelectCmp.reportValidity();
		let countrySelectAdditionalCmp = this.template.querySelector('[data-uniqueid="countrySelectAdditional"]');
		countrySelectAdditionalCmp.setCustomValidity("");
		countrySelectAdditionalCmp.reportValidity();
	}

	handleLeadPassOptionAdditional(event) {
		this.list_LeadPassOptionsAdditionalSelected = event.detail.value;
		this.objParameters.strLeadPassCountriesAdditional = this.list_LeadPassOptionsAdditionalSelected.toString();
		let countrySelectAdditionalCmp = this.template.querySelector('[data-uniqueid="countrySelectAdditional"]');
		countrySelectAdditionalCmp.setCustomValidity("");
		countrySelectAdditionalCmp.reportValidity();
		let countrySelectCmp = this.template.querySelector('[data-uniqueid="countrySelect"]');
		countrySelectCmp.setCustomValidity("");
		countrySelectCmp.reportValidity();
	}

	closeModal() {
		this.blnShowModal = false;
		if (this.blnShowLeadPassModal) {
			this.blnShowLeadPassModal = false;
			this.destroyLeadPass();
		}
	}

	destroyLeadPass() {
		this.objLeadPassDetails = null;
		this.list_CountriesSentToRemote = [];
		this.list_CountriesSentToRemoteToDisplay = [];
		this.list_LeadPassOptions = [];
		this.list_LeadPassOptionsSelected = [];
		this.list_LeadPassOptionsAdditional = [];
		this.list_LeadPassOptionsAdditionalSelected = [];
		this.objLeadPassAccount = null;
	}

	handleProductUpsellFields(event) {
		this.list_SelectedProductUpsellType = [];
		this.blnTypeSelected = false;
		this.blnType401 = false;
		this.blnType529 = false;
		this.blnTypeArdius = false;
		this.blnTypeWorkersComp = false;
		this.blnWorkersCompInterestNEXT = false;
		let list_SecPOCExcludeRoles = [];
		if (event.detail.value !== undefined) {
			this.map_ProductUpsellValues.set(event.target.fieldName, event.detail.value);
		} else if (event.detail.checked !== undefined) {
			this.map_ProductUpsellValues.set(event.target.fieldName, event.detail.checked.toString());
		}

		for (let [key, value] of this.map_ProductUpsellValues) {
			if (key == "Type__c" && value !== "") {
				this.blnTypeSelected = true;
				var values = value.split(";");
				for (var i = 0; i < values.length; i++) {
					if (values[i] == "Ardius") {
						this.blnTypeArdius = true;
					} else if (values[i] == "529") {
						this.blnType529 = true;
					} else if (values[i] == "401k") {
						this.blnType401 = true;
					} else if (values[i] == "Worker's Comp") {
						this.blnTypeWorkersComp = true;
					}
				}
			}
			if (key == "Workers_Comp_InterestPicklist__c" && value == "NEXT Insurance") {
				this.blnWorkersCompInterestNEXT = true;
				this.objAllSmartCalling?.Secondary_POC_Exclude_Roles__c?.split(",")?.forEach((role) => list_SecPOCExcludeRoles.push(role));
				if((this.blnIsOpportunity || this.blnIsAccount) && this.objAllSmartCalling?.Show_Secondary_POC__c && !list_SecPOCExcludeRoles?.includes(this.userRoleName) && this.list_AccountContacts.length > 1){
					this.blnShowSecondaryContact = true;
				}
			}

		}
	}

	handleObjectDetailFields(event) {
		if (event.detail.value !== undefined) {
			this.map_ObjectDetailValues.set(event.target.fieldName, event.detail.value);
		} else if (event.detail.checked !== undefined) {
			this.map_ObjectDetailValues.set(event.target.fieldName, event.detail.checked.toString());
		}
	}

	handleNotesChange(event) {
		this.objParameters.strNotes = event.detail.value;
	}

	handleFeatureRequestChange(event) {
		this.objParameters.strFeatureRequest = event.detail.value;
	}

	handleDoNotCallChange(event) {
		this.objParameters.blnDoNotCall = event.target.checked;
	}

	handleFollowUpDateChange(event) {
		this.objParameters.strFollowUpDate = event.detail.value;
	}

	handleFollowUpSubjectChange(event) {
		this.objParameters.strFollowUpSubject = event.detail.value;
	}

	handlePayrollOpportunityNameChange(event) {
		this.objParameters.strPayrollOpportunityName = event.detail.value;
	}

	handlePayrollOpportunityCloseDateChange(event) {
		this.objParameters.strPayrollOpportunityCloseDate = event.detail.value;
	}

	handleHIOptyCloseDateChange(event) {
		this.objParameters.strHIOpportunityCloseDate = event.detail.value;
	}

	handleHIOptyEmployeesChange(event) {
		this.objParameters.strHIOpportunityEmployees = event.detail.value;
	}

	handleHIOptyNotesChange(event) {
		this.objParameters.strHIOpportunityNotes = event.detail.value;
	}

	handleLiveHITransferChange(event) {
		this.objParameters.blnHIOpportunityLiveTransfer = event.target.checked;
	}

	handleSaveLTC(event) {
		if (this.userProfileName === util.USER_PROFILE.BENEFITS_USER) {
			this.saveAction(true);
		} else {
			this.blnSpinner = true;
			this.blnButtonDisabled = true;
			// Calling the imperative Apex method with the JSON
			saveLTC({
				strObjectName: this.objectApiName,
				strRecordId: this.recordId
			})
				.then((result) => {
					util.displayToast(this, util.SUCCESS_MSGS.TASK_CREATED, result, util.TOAST_PARAMS.TYPE.SUCCESS, "");
					this.refreshComponent();
				})
				.catch((error) => {
					let strErrMsg = error.body?.message || error.message;
					console.error(strErrMsg);
					util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
				})
				.finally(() => {
					this.blnSpinner = false;
					this.blnButtonDisabled = false;
				});
		}
	}

	handleSave() {
		this.saveAction();
	}

	/**
	 * If we're saving with a call, get Nice Interaction record
	 * if we don't have one yet, show warning toast.
	 *
	 * If we're saving without a call, save with fake interaction id
	 */
	saveAction(bln_isSaveWOCall = false) {
		//Contact is required if Product upsell is checked.
		if (this.blnCreateProductUpsell && this.objParameters.strWhoId == "") {
			util.displayToast(this, util.ERROR_MSGS.SELECT_CONTACT_BEFORE_SAVING, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		//Secondary Contact should be different from Selected Contact Name
		if (this.objParameters.strWhoId && this.objParameters.strSecContactId && this.objParameters.strWhoId == this.objParameters.strSecContactId) {
			util.displayToast(this, util.ERROR_MSGS.SELECT_DIFFERENT_SEC_CONTACT, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		//Product interest countries are required if Add Product Interest is selected.
		if (this.blnProductInterest && this.objParameters.strProductInterestCountries == "" && this.blnShowProductInterestCountries) {
			util.displayToast(this, util.ERROR_MSGS.PRODUCT_INTEREST_COUNTRIES_REQUIRED, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		//Workers Comp Interest is requeired if Workers Comp is selected in Type.
		if (this.blnCreateProductUpsell && this.blnTypeSelected && this.blnTypeWorkersComp && !this.blnWorkersCompInterestNEXT) {
			util.displayToast(this, util.ERROR_MSGS.WORKERS_COMP_INTEREST_REQUIRED, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		//Selected Contact must have an email for NEXT.

		if (this.blnCreateProductUpsell && this.blnTypeSelected && this.blnTypeWorkersComp && this.blnWorkersCompInterestNEXT && !this.blnContactHasEmail) {
			util.displayToast(this, util.ERROR_MSGS.CONTACT_EMAIL_REQUIRED_FOR_NEXT, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			return;
		}

		const selectedCountriesArray = this.objParameters.strProductInterestCountries.split(",");
		//Contact is required for non supported countries if Add Product interest is checked.
		const areSupportedCountriesSelected = selectedCountriesArray.every((country) => this.supportedCountries.includes(country.trim()));
		const areNonSupportedCountriesSelected = selectedCountriesArray.some((country) => !this.supportedCountries.includes(country.trim()));

		if (selectedCountriesArray.length > 0 && selectedCountriesArray != "" && this.blnProductInterest && this.objParameters.strWhoId == "" && this.blnShowProductInterestCountries) {
			if ((areSupportedCountriesSelected && areNonSupportedCountriesSelected) || areNonSupportedCountriesSelected) {
				util.displayToast(this, util.ERROR_MSGS.SELECT_CONTACT_BEFORE_SAVING, "", util.TOAST_PARAMS.TYPE.ERROR, "");
				return;
			}
		}

		this.blnSpinner = true;
		this.blnButtonDisabled = true;

		if (this.blnIsCXUser || this.objParameters?.strPhoneNumber) {
			getNiceInteraction({
				strSelectedPhoneNumber: this.objParameters.strPhoneNumber
			})
				.then((result) => {
					if (result) {
						//we have a nice interaction record
						const objNiceInteraction = JSON.parse(result);

						if (objNiceInteraction.Call_Start_Date_and_Time__c) objNiceInteraction.Call_Start_Date_and_Time__c = new Date(objNiceInteraction.Call_Start_Date_and_Time__c)?.toISOString();

						if (objNiceInteraction.Call_End_Date_and_Time__c) objNiceInteraction.Call_End_Date_and_Time__c = new Date(objNiceInteraction.Call_End_Date_and_Time__c)?.toISOString();

						this.strNiceInteraction = JSON.stringify(objNiceInteraction);

						this.saveData(false);
					} else {
						//no nice interaction record
						this.saveData(true);
					}
				})
				.catch((error) => {
					let strErrMsg = error.body?.message || error.message;
					console.error(strErrMsg);
					util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.MODE.STICKY);
					this.blnSpinner = false;
					this.blnButtonDisabled = false;
				});
		} else {
			this.saveData(true);
		}
	}

	//save logic where we pass data to Apex
	saveData(blnIsSaveWOCall) {
		var t0 = performance.now();

		const blnDisposition = [...this.template.querySelectorAll(`[data-name="disposition"]`)].reduce(util.checkInputValidity, true);

		let blnDetailOpportunity = true;
		if (this.blnIsOpportunity) {
			blnDetailOpportunity = [...this.template.querySelectorAll(`[data-name="detail-opportunity"]`)].reduce(util.checkInputFieldValidity, true);
		}

		let blnCallObjective = [...this.template.querySelectorAll(`[data-name="callObjective"]`)].reduce(util.checkInputValidity, true);

		let blnPayrollOpportunity = true;
		if (this.objParameters.blnCreatePayrollOpportunity) {
			blnPayrollOpportunity = [...this.template.querySelectorAll(`[data-name="payroll-opportunity"]`)].reduce(util.checkInputValidity, true);
		}

		let blnHiOpportunity = true;
		if (this.objParameters.blnCreateHIOpportunity) {
			blnHiOpportunity = [...this.template.querySelectorAll(`[data-name="hi-opportunity"]`)].reduce(util.checkInputValidity, true);
		}

		let blnArdiusOpportunity = true;
		if (this.objParameters.blnCreateArdiusOpportunity) {
			blnArdiusOpportunity = [...this.template.querySelectorAll(`[data-name="ardius-opportunity"]`)].reduce(util.checkInputValidity, true);
		}

		let blnPointOfContact = true;
		if (this.blnCreateProductUpsell) {
			blnPointOfContact = [...this.template.querySelectorAll('[data-name="Point of Contact"]')].reduce(util.checkInputValidity, true);
		}

		let blnRelatedTo = true;
		if (this.blnShowRelatedTo) {
			blnRelatedTo = this.template.querySelector('[data-name="Related To"]')?.validateCombobox();
		}

		let blnContactName = true;
		if (this.blnShowContactName && !blnIsSaveWOCall) {
			blnContactName = [...this.template.querySelectorAll('[data-name="Contact Name"]')].reduce(util.checkInputValidity, true);
		}

		if (blnDisposition && blnPayrollOpportunity && blnHiOpportunity && blnDetailOpportunity && blnPointOfContact && blnCallObjective && blnRelatedTo && blnContactName) {
			if (this.blnIsLead) {
				const strLeadStatus = this.map_ObjectDetailValues.get(LEAD_STATUS.fieldApiName) || this.objTheLead[LEAD_STATUS.fieldApiName];
				const strLeadStatusDetail = this.map_ObjectDetailValues.get(LEAD_STATUS_DETAIL.fieldApiName) || this.objTheLead[LEAD_STATUS_DETAIL.fieldApiName];
				let blnShowToast = false;

				if (
					(strLeadStatus === util.LEAD_STATUS.FUTURE_OPPORTUNITY && strLeadStatusDetail === util.LEAD_STATUS_DETAIL.FEATURE_NOT_LISTED) ||
					(strLeadStatus === util.LEAD_STATUS.UNQUALIFIED && strLeadStatusDetail === util.LEAD_STATUS_DETAIL.OTHER)
				) {
					util.displayToast(this, util.ERROR_MSGS.PROVIDE_ADDITNL_CONTXT_FOR_CLOSED_REASONS, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
					blnShowToast = true;
				}
				if (strLeadStatus === util.LEAD_STATUS.UNQUALIFIED && !strLeadStatusDetail) {
					util.displayToast(this, util.ERROR_MSGS.LEAD_STATUS_DETAIL_REQUIRED, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
					blnShowToast = true;
				}

				if (blnShowToast) {
					this.blnSpinner = false;
					this.blnButtonDisabled = false;
					return;
				}

				this.objParameters.strLeadCurrentStatus = strLeadStatus;

				if (
					!this.blnIsCXUser &&
					this.objAllSmartCalling.Show_Point_of_Contact__c &&
					this.objAllSmartCalling.Product_Upsell__c &&
					this.blnHasProductUpsellFields &&
					this.blnCreateProductUpsell &&
					!this.objParameters.strSelectedPointOfConId
				) {
					if (this.objParameters.strWhoId) {
						this.objParameters.strSelectedPointOfConId = this.objParameters.strWhoId;
					} else if (this.list_ContactRoles?.length) {
						this.objParameters.strSelectedPointOfConId = this.list_ContactRoles[0].id;
					}
				}
			}

			this.objParameters.strRecordId = this.recordId;
			this.objParameters.strObjectName = this.objectApiName;

			let list_productUpsellValues = [];
			for (let [key, value] of this.map_ProductUpsellValues) {
				list_productUpsellValues.push({ strFieldApiName: key, strFieldValue: value });
			}

			let list_ObjectDetailValues = [];
			for (let [key, value] of this.map_ObjectDetailValues) {
				list_ObjectDetailValues.push({ strFieldApiName: key, strFieldValue: value });
			}

			this.objParameters.list_ProductUpsellValues = list_productUpsellValues;
			this.objParameters.list_ObjectDetailValues = list_ObjectDetailValues;

			this.blnSpinner = true;
			this.blnButtonDisabled = true;

			// Calling the imperative Apex method with the JSON
			saveCompleteRecords({
				strDataInJson: JSON.stringify(this.objParameters),
				strMetadata: this.objMetadata,
				blnIsSaveWOCall: blnIsSaveWOCall,
				strNiceInteraction: this.strNiceInteraction
			})
				.then((result) => {
					if (result === util.ERROR_MSGS.CROSS_SELL_OPPORTUNITY_FOR_ICP_ALREADY_EXISTS) {
						util.displayToast(this, result, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
						return;
					}
					if (result === util.ERROR_MSGS.UPSELL_OPPORTUNITY_FOR_EMPLOYER_ALREADY_EXISTS) {
						util.displayToast(this, result, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
						return;
					}
					util.displayToast(this, util.TOAST_PARAMS.MESSAGE.SUCCESS, util.SUCCESS_MSGS.RECORDS_UPDATED, util.TOAST_PARAMS.TYPE.SUCCESS, "");
					this.refreshComponent();
					var t1 = performance.now();
					console.log("time taken to filter " + (t1 - t0) + " milliseconds.");
				})
				.catch((error) => {
					let strErrMsg = error.body?.message || error.message;
					console.error(strErrMsg);
					util.displayToast(this, strErrMsg, "", util.TOAST_PARAMS.TYPE.ERROR, util.TOAST_PARAMS.TYPE.STICKY);
				})
				.finally(() => {
					this.blnSpinner = false;
					this.blnButtonDisabled = false;
				});
		} else {
			util.displayToast(this, util.ERROR_MSGS.REQUIRED_FIELDS_MISSING, "", util.TOAST_PARAMS.TYPE.ERROR, "");
			this.blnSpinner = false;
			this.blnButtonDisabled = false;
		}
	}

	refreshComponent() {
		this.dispatchEvent(new CustomEvent("refreshcomponent"));
	}

	get blnIsOpportunity() {
		return this.objectApiName === util.SOBJECT_NAME.Opportunity;
	}

	get blnIsTicket() {
		return this.objectApiName === util.SOBJECT_NAME.Ticket__c;
	}

	get blnIsAccount() {
		return this.objectApiName === util.SOBJECT_NAME.Account;
	}

	get blnIsLead() {
		return this.objectApiName === util.SOBJECT_NAME.Lead;
	}

	onClickToDial(event) {
		this.objParameters.strPhoneNumber = event?.target?.value ? event.target.value : "";
		this.objParameters.strWhoId = event.target?.dataset?.contactId ? event.target.dataset.contactId : "";
		if (this.objParameters.strWhoId && this.objParameters.strWhoId.startsWith("003")) {
			this.checkContactEmail();
		}

		this.dispatchEvent(
			new CustomEvent("openutility", {
				detail: {}
			})
		);
	}

	getLastDateofMonth() {
		const dtToday = new Date();
		const dtLastDay = new Date(dtToday.getFullYear(), dtToday.getMonth() + 1, 0);
		const intNextMonth = dtLastDay.getMonth() + 1;
		const intLastDate = dtLastDay.getDate();
		return `${dtLastDay.getFullYear()}-${intNextMonth <= 9 ? "0" + intNextMonth : intNextMonth}-${intLastDate <= 9 ? "0" + intLastDate : intLastDate}`;
	}

	handleSelectOptionChange(event) {
		const { selOption, sObjectName } = event.detail;

		this.objParameters.strWhatId = selOption;
		this.selSObjectName = sObjectName;
	}
}