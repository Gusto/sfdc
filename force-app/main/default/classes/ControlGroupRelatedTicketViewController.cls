/**
 * @description Control Group based Ticket - LWC Controller
 * @author  Ajay Krishna P U
 * @since 2023-05-24
 * @see ControlGroupRelatedTicketControllerTest
 */
public with sharing class ControlGroupRelatedTicketViewController {
	/**
	 * @description           Fetch Control group related Tickets
	 * @param idTicket        Ticket Id the request originated
	 * @param list_Fields     Tickets fields to Query
	 * @param strControlGroup Control Group of Tickets to filter
	 * @param strOrderBy      Query order by
	 * @return                `List<Ticket__c>`
	 * @exception             AuraHandledException, if any exception occurred
	 */
	@AuraEnabled(cacheable=true)
	public static List<Ticket__c> getControlGroupRelatedTickets(Id idTicket, List<String> list_Fields, String strControlGroup, String strOrderBy) {
		try {
			if (String.isBlank(strControlGroup)) {
				return new List<Ticket__c>();
			}

			Id idArdiusRecordTypeId = TicketUtil.ARDIUS_TICKET_RT_ID;
			strOrderBy = String.isBlank(strOrderBy) ? 'Id DESC' : strOrderBy;

			return Database.query(
				'SELECT ' +
					String.escapeSingleQuotes(String.join(list_Fields, ',')) +
					' FROM Ticket__c' +
					' WHERE RecordTypeId =: idArdiusRecordTypeId AND Id != :idTicket AND Account__r.Control_Group__c = :strControlGroup' +
					' ORDER BY ' +
					String.escapeSingleQuotes(strOrderBy)
			);
		} catch (Exception objException) {
			throw new AuraHandledException(objException.getMessage());
		}
	}

	/**
	 * @description           Fetch cases linked emails and display on Ticket
	 * @param idTicket        Ticket Id the request originated
	 * @param list_Fields     Tickets fields to Query
	 * @param strOrderBy      Query order by
	 * @return                `List<Case>`
	 * @exception             AuraHandledException, if any exception occurred
	 */

	@AuraEnabled(cacheable=true)
	public static List<Case> getCasesLinkedToEmail(Id idTicket, List<String> list_Fields, String strOrderBy) {
		try {
			if (String.isBlank(idTicket)) {
				return new List<Case>();
			}
			Id IdRecordTypeId = CaseUtils.RECTYPE_R_D_TAX_CREDITS;
			strOrderBy = String.isBlank(strOrderBy) ? 'Id DESC' : strOrderBy;
			List<Case> list_caseData = new List<Case>();
			List<EmailMessage> list_emailMessage = [SELECT Id FROM EmailMessage WHERE RelatedToId = :idTicket];

			if (list_emailMessage == null || list_emailMessage.isEmpty()) {
				return new List<Case>();
			}
			return Database.query(
				'SELECT ' +
					String.escapeSingleQuotes(String.join(list_Fields, ',')) +
					' FROM Case' +
					' WHERE RecordTypeId = :IdRecordTypeId AND SourceId IN :list_emailMessage' +
					' ORDER BY ' +
					String.escapeSingleQuotes(strOrderBy)
			);
		} catch (Exception objException) {
			throw new AuraHandledException(objException.getMessage());
		}
	}
}