/***************************************************
Purpose : Ticket Functionality: Show all related ticket for carrier order and benefit order page
Written By : Deepika Saini
Test Classes : ShowAllTicketsOnBOCOCtrlTest
****************************************************/
public with sharing class ShowAllTicketsOnBOCOCtrl {
	/**
	 * @author      Deepika Saini
	 * @description Get all Ticket records related to Carrier Order or Benefit Order
	 * @param       Id of benefit order or carrier order
	 * @return      List Of Ticket
	 **/
	@AuraEnabled
	public static List<Ticket__c> getRelatedTickets(Id idCO) {
		Carrier_Order__c objCarrierOrder = [SELECT Id, Benefit_Order__c FROM Carrier_Order__c WHERE Id = :idCO];

		String strbenefitOrderId = objCarrierOrder.Benefit_Order__c;

		List<Ticket__c> list_Tickets = new List<Ticket__c>();
		String strQuery = 'SELECT Id, Name, Status__c, Escalation_Reason__c, Owner_Full_Name__c FROM Ticket__c ';
		strQuery += ' WHERE Benefit_Order__c =\'' + strbenefitOrderId + '\' OR Carrier_Order__c = \'' + idCO + '\' ORDER BY CREATEDDATE DESC';

		return Database.Query(strQuery);
	}
}