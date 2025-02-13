/**
 * @author       Praveen Sethu
 * @description  Queuable class used to convert company and reseller leads
 * @see ZPCompanyTriggerHelperTest,ZPAccountingFirmTriggerHelperTest
 */
public with sharing class LeadConvertQueueable implements Queueable {
	public Database.LeadConvert objLeadConvert;
	public Id idLead;
	public Id idAccount;
	public Id idContact;
	public Id idOpportunity;
	public Id idCompany;
	public Id idFirm;
	public Boolean blnDoNotCreateOppty;
	public static Id idOwner;

	public LeadConvertQueueable(Id idLead, Id idAccount, Id idContact, Id idOpportunity, Id idCompany, Id idFirm, Boolean blnDoNotCreateOppty) {
		this.idLead = idLead;
		this.idAccount = idAccount;
		this.idContact = idContact;
		this.idOpportunity = idOpportunity;
		this.idCompany = idCompany;
		this.idFirm = idFirm;
		this.blnDoNotCreateOppty = blnDoNotCreateOppty;
	}

	/**
	 * @description    execute method that converts company or reseller leads and re-processes companies or accounting firms
	 * @param          idLead - Lead Id to convert
	 * @param          idAccount - Existing account that lead will convert to
	 * @param          idContact - Existing contact that lead will convert to
	 * @param          idOpportunity - Existing opportunity that lead will convert to
	 * @param          idCompany - ZP Company Id to re-process
	 * @param          idFirm - ZP Accounting Firm Id to re-process
	 * @param          blnDoNotCreateOppty - Boolean flag to indicate if lead will convert to an opportunity
	 */
	public void execute(QueueableContext context) {
		if (idLead != null) {
			Database.LeadConvert objLeadConvert = new Database.LeadConvert();
			objLeadConvert.setLeadId(idLead);
			// set existing account id
			if (idAccount != null) {
				objLeadConvert.setAccountId(idAccount);
				// set exisitng contact id only if account id is set
				if (idContact != null) {
					objLeadConvert.setContactId(idContact);
				}
			}

			// set exisitng opp id
			if (idOpportunity != null) {
				objLeadConvert.setOpportunityId(idOpportunity);
			}
			objLeadConvert.setDoNotCreateOpportunity(blnDoNotCreateOppty);

			objLeadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);
			//for testing error
			if (idOwner != null) {
				objLeadConvert.setOwnerId(idOwner);
			}
			Database.LeadConvertResult objConvertResult = Database.convertLead(objLeadConvert, false);

			if (!objConvertResult.isSuccess() || Test.isRunningTest()) {
				String errorMessage = '';
				for (Database.Error error : objConvertResult.getErrors()) {
					if (!error.getMessage().contains('Validation error')) {
						ExceptionLogUtil.logException(
							'LeadConvertResult',
							'LeadConvertQueueable',
							'execute',
							error.getMessage() +
								'\nLeadId : ' +
								objConvertResult.getLeadId(), //LeadId added to the error message to help identify the erroring lead
							String.join(error.getFields(), ',')
						);
					}
				}
			}

			if (objConvertResult.isSuccess()) {
				// re-process company or accounting firm if there is enough queueable jobs available
				if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
					if (idCompany != null) {
						ZP_Company__c objCompany = new ZP_Company__c(Id = idCompany, Processing_State__c = 'Retry', Message__c = 'Async Lead Conversion Successful');
						Database.update(objCompany, false);
					} else if (idFirm != null) {
						ZP_Accounting_Firm__c objFirm = new ZP_Accounting_Firm__c(Id = idFirm, Processing_State__c = 'Retry', Message__c = 'Async Lead Conversion Successful');
						Database.update(objFirm, false);
					}
				}
			}
		}
	}
}