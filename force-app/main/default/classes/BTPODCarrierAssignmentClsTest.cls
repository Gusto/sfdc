/**
 * @name         BTPODCarrierAssignmentClsTest
 * @author       Vinay
 * @date         13-03-2020
 * @description  Test class for BTPODCarrierAssignmentCls class . VF page -
 **/

@istest
public class BTPODCarrierAssignmentClsTest {
	static testMethod void testmethod1() {
		Carrier__c obj_Carrier = new Carrier__c();
		obj_Carrier.Name = 'Test';
		obj_Carrier.Termination_Effective_Date__c = 'On the Date';
		obj_Carrier.State__c = 'al;ak';
		obj_Carrier.BoR_Complexity__c = '1';
		//obj_Carrier.BT_Facilitator_POD__c ='Unassigned';
		obj_Carrier.BT_Facilitator_POD__c = 'POD 1';
		insert obj_Carrier;

		List<Carrier__c> carLIst = new List<Carrier__c>();
		carLIst.add(obj_Carrier);

		BTPODCarrierAssignmentCls t1 = new BTPODCarrierAssignmentCls();
		t1.intialSetCount('TotalRecord');
		t1.countAndSumComplexity(carLIst, 'TotalRecord');
		t1.strSelectedPOD = 'POD 1';
		t1.selectPOD();

		// Assertions to check initial selection and complexity count
		System.assertEquals(t1.strSelectedPOD, 'POD 1', 'Selected POD should be POD 1');
		System.assertEquals(t1.map_CountAndTotalComplexity.get('POD 1').get('TotalRecord'), 1, 'Total record count for POD 1 should be 1');

		obj_Carrier.BT_Facilitator_POD__c = 'Unassigned';
		update obj_Carrier;
		t1.resetSearch();

		t1.strSearchName = 'Test';
		t1.lst_SelectedStateValues.add(new SelectOption('al', 'ak'));
		t1.searchCarrier();
		t1.addCarriersToPOD();
		t1.removeCarriersFromPOD();
		t1.updateCarrier(carLIst, 'removeCarriersFromPOD');

		// Assertions after adding/removing carriers
		System.assertEquals(obj_Carrier.BT_Facilitator_POD__c, 'Unassigned', 'Carrier should be unassigned after removal');

		BTPODCarrierAssignmentCls.pagination p1 = new BTPODCarrierAssignmentCls.pagination(t1.objSetConForAssignedCarriers, t1.lst_SelectedAssignedCarrier);
		p1.sortExp = 'name';

		// Assertions for pagination check
		System.assertNotEquals(p1.getTotalRecord(), 0, 'Total record count should be greater than 0');
		System.assertNotEquals(p1.getTotalPages(), 0, 'Total pages count should be greater than 0');

		p1.getstrDirectionToSort();
		p1.setstrDirectionToSort('true');
		p1.getTotalRecord();
		p1.getTotalPages();
		p1.first();
		p1.last();
		p1.previous();
		p1.next();
		p1.resetList();
		p1.fetchCarriers();

		// t1.lst_UnassignedCarrier.add(obj_Carrier);
		// t1.addCarriersToPOD();
	}

	static testMethod void testmethod2() {
		BTPODCarrierAssignmentCls t1 = new BTPODCarrierAssignmentCls();
		t1.selectPOD();
		t1.resetSearch();
		t1.searchCarrier();
		t1.addCarriersToPOD();
		t1.removeCarriersFromPOD();
		// Assertions to check carrier list
		System.assertEquals(t1.lst_UnassignedCarrier.size(), 0, 'Selected assigned carriers list should be empty after removal');
	}
}