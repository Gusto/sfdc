import { PicklistOption, checkInputValidity} from "c/utilityService";

const CASE_TYPE = {
	PAYROLL_CARE: "Payroll Care",
	BENEFITS_CARE: "Benefits Care",
	TAX_RES: "Tax Res",
	TAX_OPS: "Tax Ops",
	MODERN_BANK: "Modern Bank",
	PAYROLL_COMPLIANCE: "Payroll Compliance",
	RISK_ASSURANCE: "Risk Assurance",
	SALES_CASES: "Sales Cases",
	BENEFITS_BOR: "Benefits BoR",
	PAYROLLOPS_AUDIT: "PayrollOps Audit",
	BENEFITS_CHANGE_CASE: "Benefits Change Case",
	BENEFITS_NEW_PLAN_CASE: "Benefits New Plan Case",
	BENEFITS_RENEWAL_CASE: "Benefits Renewal Case",
	MEMEBER_FULFILLMENT_EMAILS: "Member Fulfillment Emails",
	CONCIERGE_CLASS_3: "Concierge Class 3",
	ENGAGEMENT: "Engagement"
};

const list_CaseTypeOptions = [
	PicklistOption.setLabelAndValue(CASE_TYPE.ENGAGEMENT),
	PicklistOption.setLabelAndValue(CASE_TYPE.TAX_RES),
	PicklistOption.setLabelAndValue(CASE_TYPE.TAX_OPS),
	PicklistOption.setLabelAndValue(CASE_TYPE.MODERN_BANK),
	PicklistOption.setLabelAndValue(CASE_TYPE.PAYROLL_COMPLIANCE),
	PicklistOption.setLabelAndValue(CASE_TYPE.RISK_ASSURANCE),
	PicklistOption.setLabelAndValue(CASE_TYPE.SALES_CASES),
	PicklistOption.setLabelAndValue(CASE_TYPE.BENEFITS_BOR),
	PicklistOption.setLabelAndValue(CASE_TYPE.PAYROLLOPS_AUDIT),
	PicklistOption.setLabelAndValue(CASE_TYPE.BENEFITS_CHANGE_CASE),
	PicklistOption.setLabelAndValue(CASE_TYPE.BENEFITS_NEW_PLAN_CASE),
	PicklistOption.setLabelAndValue(CASE_TYPE.BENEFITS_RENEWAL_CASE),
	PicklistOption.setLabelAndValue(CASE_TYPE.MEMEBER_FULFILLMENT_EMAILS),
	PicklistOption.setLabelAndValue(CASE_TYPE.CONCIERGE_CLASS_3)
];

export {
    list_CaseTypeOptions,
    checkInputValidity
};