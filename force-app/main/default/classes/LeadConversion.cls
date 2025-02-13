public without sharing class LeadConversion {
	static final String CONVERTED_LEAD_STATUS = Config.LeadConversion.CONVERTED_LEAD_STATUS;
	static final Integer BATCH_SIZE = Config.LeadConversion.LEAD_CONVERSION_BATCH_SIZE;
	static final Boolean SEND_NOTIFICATION_EMAIL = Config.LeadConversion.SEND_NOTIFICATION_EMAIL;

	public static List<OpportunityContactRole> oppContactRoleList = new List<OpportunityContactRole>();

	public class ConversionRequest {
		public List<Lead> leads { get; set; }
		public Map<Id, Database.LeadConvert> leadConvertMap { get; private set; }
		{
			leadConvertMap = new Map<Id, Database.LeadConvert>();
		}

		public ConversionRequest(List<Lead> leads) {
			this.leads = leads;
			addLeads(leads);
		}

		public List<Database.LeadConvert> getLeadConverts() {
			return leadConvertMap.values();
		}

		public void addLeads(List<Lead> leads) {
			if (leads != null) {
				for (Lead lead : leads) {
					addLead(lead);
				}
			}
		}

		public void addLead(Lead lead) {
			if (lead != null) {
				Database.LeadConvert leadConvert = new Database.LeadConvert();
				leadConvert.setLeadId(lead.Id);
				leadConvertMap.put(lead.Id, leadConvert);
			}
		}
	}

	public class ConversionResult {
		public List<Database.LeadConvertResult> convertResults { get; private set; }
		public Map<Id, Database.LeadConvert> map_converts { get; private set; }

		public void setConvertResults(List<Database.LeadConvertResult> convertResults) {
			this.convertResults = convertResults;
		}

		public void setConverts(Map<Id, Database.LeadConvert> map_converts) {
			this.map_converts = map_converts;
		}
	}

	abstract class Handler {
		{
		}
	}

	class Initializer extends LeadConversion.Handler {
		ConversionResult handle(List<Lead> leads) {
			LeadConversion.ConversionRequest conversionRequest = new LeadConversion.ConversionRequest(leads);

			LeadConversion.OpportunityCompanyIdMatcher opportunityCompanyIdMatcher = new LeadConversion.OpportunityCompanyIdMatcher();
			opportunityCompanyIdMatcher.handle(conversionRequest);

			LeadConversion.ContactEmailMatcher contactEmailMatcher = new LeadConversion.ContactEmailMatcher();
			contactEmailMatcher.handle(conversionRequest);

			LeadConversion.AccountCompanyIdMatcher accountCompanyIdMatcher = new LeadConversion.AccountCompanyIdMatcher();
			accountCompanyIdMatcher.handle(conversionRequest);

			LeadConversion.AccountCompanyLeadIdMatcher accountCompanyLeadIdMatcher = new LeadConversion.AccountCompanyLeadIdMatcher();
			accountCompanyLeadIdMatcher.handle(conversionRequest);

			LeadConversion.AccountFirmIdMatcher objAccountFirmIdMatcher = new LeadConversion.AccountFirmIdMatcher();
			objAccountFirmIdMatcher.handle(conversionRequest);

			LeadConversion.DoNotResellerOpportunityHandler doNotResellerOpportunityHandler = new LeadConversion.DoNotResellerOpportunityHandler();
			doNotResellerOpportunityHandler.handle(conversionRequest);

			LeadConversion.OwnerHandler ownerHandler = new LeadConversion.OwnerHandler();
			ownerHandler.handle(conversionRequest);

			LeadConversion.ConversionHandler conversionHandler = new LeadConversion.ConversionHandler();
			return conversionHandler.handle(conversionRequest);
		}
	}

	class ConversionHandler extends LeadConversion.Handler {
		ConversionResult handle(ConversionRequest conversionRequest) {
			for (Database.LeadConvert lc : conversionRequest.getLeadConverts()) {
				lc.setSendNotificationEmail(SEND_NOTIFICATION_EMAIL);
				lc.setConvertedStatus(CONVERTED_LEAD_STATUS);
			}

			List<Database.LeadConvertResult> convertResults = Database.convertLead(conversionRequest.getLeadConverts(), false);
			new LeadConvertResultsHandler().handle(convertResults, new Map<Id, Lead>(conversionRequest.leads));
			LeadConversion.ConversionResult conversionResult = new LeadConversion.ConversionResult();
			conversionResult.setConvertResults(convertResults);
			conversionResult.setConverts(conversionRequest.leadConvertMap);
			return conversionResult;
		}
	}

	class LeadConvertResultsHandler extends LeadConversion.Handler {
		Id resellerLeadRecordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');
		void handle(List<Database.LeadConvertResult> convertResults, Map<Id, Lead> map_Leads) {
			Map<String, String> errorMap = new Map<String, String>();

			for (Database.LeadConvertResult convertResult : convertResults) {
				if (!convertResult.isSuccess()) {
					String errorMessage = '';
					for (Database.Error error : convertResult.getErrors()) {
						if (!error.getMessage().contains('Validation error') && map_Leads.get(convertResult.getLeadId()).RecordTypeId != resellerLeadRecordTypeId) {
							ExceptionLogUtil.logException(
								'LeadConvertResult',
								'Leadconversion',
								'LeadConvertResultsHandler-handle',
								error.getMessage() +
									'\nLeadId : ' +
									convertResult.getLeadId(), //LeadId added to the error message to help identify the erroring lead
								String.join(error.getFields(), ',')
							);
						}
					}
				}
			}
		}
	}

	class ContactEmailMatcher extends LeadConversion.Handler {
		void handle(ConversionRequest conversionRequest) {
			Map<String, Id> leadIdsByEmail = new Map<String, Id>();

			for (Lead lead : conversionRequest.leads) {
				if (lead.Email != null) {
					leadIdsByEmail.put(lead.Email.toLowerCase(), lead.Id);
				}
			}

			if (!leadIdsByEmail.isEmpty()) {
				Set<Id> accountIdSet = new Set<Id>();
				List<Contact> contacts = [SELECT Id, AccountId, OwnerId, Email FROM Contact WHERE Email IN :leadIdsByEmail.keySet()];
				for (Contact con : contacts) {
					accountIdSet.add(con.AccountId);
				}
				Map<Id, List<Opportunity>> accountIdToOpenOppsMap = new Map<Id, List<Opportunity>>();
				if (accountIdSet.size() > 0) {
					for (Opportunity o : [
						SELECT Id, AccountId, (SELECT Id, ContactId, OpportunityId, Role, IsPrimary FROM OpportunityContactRoles WHERE ContactId IN :contacts)
						FROM Opportunity
						WHERE AccountId IN :accountIdSet AND RecordTypeId = :Cache.getRecordTypeId('Opportunity', 'Company Opportunity') AND IsWon = FALSE AND StageName != 'Closed - Lost'
					]) {
						if (accountIdToOpenOppsMap.containsKey(o.AccountId)) {
							accountIdToOpenOppsMap.get(o.AccountId).add(o);
						} else {
							accountIdToOpenOppsMap.put(o.AccountId, new List<Opportunity>{ o });
						}
					}
				}

				for (Contact contact : contacts) {
					Id leadId = leadIdsByEmail.get(contact.Email);

					Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(leadId);

					//set the account id if it hasnt been set
					if (leadConvert.getAccountId() == null) {
						leadConvert.setAccountId(contact.AccountId);
					}

					//if the account id matches, set the contact details
					if (leadConvert.getAccountId() == contact.AccountId) {
						leadConvert.setContactId(contact.Id);
						leadConvert.setOwnerId(contact.OwnerId);
					}

					if (accountIdToOpenOppsMap.containsKey(contact.AccountId)) {
						for (Opportunity o : accountIdToOpenOppsMap.get(contact.AccountId)) {
							if (o.OpportunityContactRoles.size() == 0) {
								OpportunityContactRole ocr = new OpportunityContactRole(ContactId = contact.Id, OpportunityId = o.Id);
								ocr.Role = 'Contact';
								oppContactRoleList.add(ocr);
							}
						}
					}
				}

				if (oppContactRoleList.size() > 0) {
					Utils.doDMLAndReturnAllErrors('Insert', 'ContactId', oppContactRoleList, false, true, 'ContactEmailMatcher-handle');
				}
			}
		}
	}

	class AccountCompanyIdMatcher extends LeadConversion.Handler {
		void handle(ConversionRequest conversionRequest) {
			Map<String, Id> leadIdsByCompanyId = new Map<String, Id>();

			for (Lead lead : conversionRequest.leads) {
				if (String.isNotBlank(lead.ZP_Company_ID__c)) {
					leadIdsByCompanyId.put(lead.ZP_Company_ID__c, lead.Id);
				}
			}

			if (!leadIdsByCompanyId.isEmpty()) {
				List<Account> accounts = [SELECT Id, OwnerId, ZP_Company_ID__c FROM Account WHERE ZP_Company_ID__c IN :leadIdsByCompanyId.keySet()];

				for (Account account : accounts) {
					Id leadId = leadIdsByCompanyId.get(account.ZP_Company_ID__c);

					Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(leadId);
					if (leadConvert.getAccountId() == null) {
						leadConvert.setAccountId(account.Id);
						leadConvert.setOwnerId(account.OwnerId);
					}
				}
			}
		}
	}

	class AccountCompanyLeadIdMatcher extends LeadConversion.Handler {
		void handle(ConversionRequest conversionRequest) {
			Map<String, Id> leadIdsByCompanyLeadId = new Map<String, Id>();

			for (Lead lead : conversionRequest.leads) {
				if (String.isNotBlank(lead.ZP_Company_Lead_ID__c)) {
					leadIdsByCompanyLeadId.put(lead.ZP_Company_Lead_ID__c, lead.Id);
				}
			}

			if (!leadIdsByCompanyLeadId.isEmpty()) {
				List<Account> accounts = [SELECT Id, OwnerId, ZP_Company_Lead_ID__c FROM Account WHERE ZP_Company_Lead_ID__c IN :leadIdsByCompanyLeadId.keySet()];

				for (Account account : accounts) {
					Id leadId = leadIdsByCompanyLeadId.get(account.ZP_Company_Lead_ID__c);

					Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(leadId);

					if (leadConvert.getAccountId() == null) {
						leadConvert.setAccountId(account.Id);
						leadConvert.setOwnerId(account.OwnerId);
					}
				}
			}
		}
	}

	/**
	 * @description  Matcher class used to match reseller lead and reseller account
	 * @author       Praveen Sethu
	 * @date         03-10-2022
	 * @see          LeadConversion
	 * @see          NA
	 **/
	class AccountFirmIdMatcher extends LeadConversion.Handler {
		/**
		 * @description Matches accounts by firm id
		 * @author      Praveen Sethu
		 * @param       conversion request containing list of leads to match
		 * @return      NA
		 **/
		void handle(ConversionRequest conversionRequest) {
			Map<String, Id> map_ResellerLeads = new Map<String, Id>();

			for (Lead objLead : conversionRequest.leads) {
				if (String.isNotBlank(objLead.ZP_Firm_ID__c)) {
					map_ResellerLeads.put(objLead.ZP_Firm_ID__c, objLead.Id);
				}
			}

			if (!map_ResellerLeads.isEmpty()) {
				List<Account> list_Accounts = [SELECT Id, OwnerId, ZP_Firm_Id__c FROM Account WHERE ZP_Firm_Id__c IN :map_ResellerLeads.keySet()];

				for (Account objAcc : list_Accounts) {
					if (map_ResellerLeads.containsKey(objAcc.ZP_Firm_Id__c)) {
						Id idLead = map_ResellerLeads.get(objAcc.ZP_Firm_Id__c);

						Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(idLead);

						if (leadConvert != null && leadConvert.getAccountId() == null) {
							leadConvert.setAccountId(objAcc.Id);
							leadConvert.setOwnerId(objAcc.OwnerId);
						}
					}
				}
			}
		}
	}

	class OpportunityCompanyIdMatcher extends LeadConversion.Handler {
		void handle(ConversionRequest conversionRequest) {
			Map<String, Id> leadIdsByCompanyId = new Map<String, Id>();

			for (Lead lead : conversionRequest.leads) {
				if (String.isNotBlank(lead.ZP_Company_ID__c)) {
					leadIdsByCompanyId.put(lead.ZP_Company_ID__c, lead.Id);
				}
			}

			if (!leadIdsByCompanyId.isEmpty()) {
				List<Opportunity> opportunities = [SELECT Id, AccountId, ZP_Company_ID__c, OwnerId FROM Opportunity WHERE ZP_Company_ID__c IN :leadIdsByCompanyId.keySet()];

				for (Opportunity opportunity : opportunities) {
					Id leadId = leadIdsByCompanyId.get(opportunity.ZP_Company_ID__c);

					Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(leadId);

					//set the account id if it hasnt been set
					if (leadConvert.getAccountId() == null) {
						leadConvert.setAccountId(opportunity.AccountId);
					}

					//if the account id matches, set the opportunity details
					if (leadConvert.getAccountId() == opportunity.AccountId) {
						leadConvert.setDoNotCreateOpportunity(true);
						leadConvert.setOwnerId(opportunity.OwnerId);
					}
				}
			}
		}
	}

	class DoNotResellerOpportunityHandler extends LeadConversion.Handler {
		Id resellerLeadRecordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');

		void handle(LeadConversion.ConversionRequest conversionRequest) {
			for (Lead lead : conversionRequest.leads) {
				if (lead.RecordTypeId == resellerLeadRecordTypeId) {
					Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(lead.Id);
					leadConvert.setDoNotCreateOpportunity(true);
				}
			}
		}
	}

	class OwnerHandler extends LeadConversion.Handler {
		void handle(LeadConversion.ConversionRequest conversionRequest) {
			for (Lead lead : conversionRequest.leads) {
				Database.LeadConvert leadConvert = conversionRequest.leadConvertMap.get(lead.Id);

				if (leadConvert.getOwnerId() == null) {
					leadConvert.setOwnerId(lead.OwnerId);
				}
			}
		}
	}

	public static ConversionResult convert(List<Lead> leads) {
		return new LeadConversion.Initializer().handle(leads);
	}
}