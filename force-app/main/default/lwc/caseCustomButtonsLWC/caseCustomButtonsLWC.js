import { LightningElement, api, wire, track } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CASE_CompanyID from "@salesforce/schema/Case.Account.ZP_Company_ID__c";
import CASE_AccCompany from "@salesforce/schema/Case.Account.ZP_Company_ID__c";
import CASE_AccAccountant from "@salesforce/schema/Case.Account.ZP_Firm_ID__c";
import CaseContactUserId from "@salesforce/schema/Case.Contact_User_Id__c";
import CaseContactEmployeeId from "@salesforce/schema/Case.Contact_Employee_Id__c";
import CaseRelatedCompany from "@salesforce/schema/Case.Related_Company__r.ZP_Company_ID__c";
import CaseHippoURL from "@salesforce/label/c.CaseHippoURL";
import PandaURL from "@salesforce/label/c.PandaURL";
import CasePandaCompany from "@salesforce/label/c.CasePandaCompany";
import CasePandaAccountant from "@salesforce/label/c.CasePandaAccountant";
import HippoButton from "@salesforce/label/c.Hippo";
import PandaCompanyButton from "@salesforce/label/c.Panda_Company";
import PandaAccountantButton from "@salesforce/label/c.Panda_Accountant";
import PandaRelatedCompanyButton from "@salesforce/label/c.Panda_Related_Company";

const fields = [CASE_CompanyID, CASE_AccCompany, CASE_AccAccountant, CaseContactUserId, CaseContactEmployeeId, CaseRelatedCompany];

export default class CaseCustomButtonsLWC extends LightningElement {
	label = {
		CaseHippoURL,
		CasePandaCompany,
		CasePandaAccountant,
		HippoButton,
		PandaCompanyButton,
		PandaAccountantButton,
		PandaURL,
		PandaRelatedCompanyButton
	};

	@api recordId;
	@track caseCompayID;
	@track caseAccCompayID;
	@track caseAccFirmID;
	idCaseContactEmployee;
	idCaseContactUser;
	idCaseRelatedCompany;


	@wire(getRecord, { recordId: "$recordId", fields })
	Case;

	//Logic to Disable the Hippo Button if Company ID is blank
	get hippoBtn() {
		this.caseCompayID = getFieldValue(this.Case.data, CASE_CompanyID);
		return getFieldValue(this.Case.data, CASE_CompanyID) != undefined && getFieldValue(this.Case.data, CASE_CompanyID) != null ? false : true;
	}

	//Logic to Disable the Panda-Company Button if Zp Company ID is blank on Realted Account
	get pandaCompanyBtn() {
		this.caseAccCompayID = getFieldValue(this.Case.data, CASE_AccCompany);
		return getFieldValue(this.Case.data, CASE_AccCompany) != undefined && getFieldValue(this.Case.data, CASE_AccCompany) != null ? false : true;
	}

	//Logic to Disable the Panda-Accountant Button if ZP Firm Company ID is blank on Realted Account
	get pandaAccountantBtn() {
		this.caseAccFirmID = getFieldValue(this.Case.data, CASE_AccAccountant);
		return getFieldValue(this.Case.data, CASE_AccAccountant) != undefined && getFieldValue(this.Case.data, CASE_AccAccountant) != null ? false : true;
	}

	//Logic to Disable the Panda-Related Company Button if Customer Name is blank on Case
	get pandaRelatedCompanyButton() {
		this.idCaseRelatedCompany = getFieldValue(this.Case.data, CaseRelatedCompany);
		return this.idCaseRelatedCompany != undefined && this.idCaseRelatedCompany != null ? false : true;
	}

	get pandaUserButton() {
		this.idCaseContactUser = getFieldValue(this.Case.data, CaseContactUserId);
		return this.idCaseContactUser !== undefined && this.idCaseContactUser !== null
			? false
			: true;
	}

	get pandaEmployeeButton() {
		this.idCaseContactEmployee = getFieldValue(this.Case.data, CaseContactEmployeeId);
		return this.idCaseContactEmployee !== undefined && this.idCaseContactEmployee !== null
			? false
			: true;
	}

	onhandleClickHippo(event) {
		const hippoURL = this.label.CaseHippoURL + this.caseCompayID;
		window.open(hippoURL);
	}

	onhandleClickPandaCompany(event) {
		const pandaCompanyURL = this.label.CasePandaCompany + this.caseAccCompayID;
		window.open(pandaCompanyURL);
	}

	onhandleClickPandaAccountant(event) {
		const pandaAccountantURL = this.label.CasePandaAccountant + this.caseAccFirmID;
		window.open(pandaAccountantURL);
	}

	handleOnClickPandaUser(event) {
		window.open(this.label.PandaURL + "/users/" + this.idCaseContactUser);
	}

	handleOnClickPandaEmployee(event) {
		window.open(this.label.PandaURL + "/employees/" + this.idCaseContactEmployee);
	}

	handleOnClickPandaRelatedCompany(event) {
		const pandaRelatedCompanyURL = this.label.CasePandaCompany + this.idCaseRelatedCompany;
		window.open(pandaRelatedCompanyURL);
	}
}