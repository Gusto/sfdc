/**
 * @name         CarrierMassUpdateCtrl
 * @author       Deepika Saini
 * @date         02 July 2024
 * @description  Mass Update: Carrier Fulfillment Blocked and Fulfillment Carrier Grouping
 * @test class   CarrierMassUpdateCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class CarrierMassUpdateCtrl {
	private final ApexPages.StandardSetController CarrierController;
	public List<Carrier__c> list_CarrierRecord { get; set; }
	public Carrier__c objCarrier { get; set; }
	public String strCurrentStep { get; set; }
	private final PageReference FROMPAGE;
	private static final STRING CARRIERFILTER = '/lightning/o/Carrier__c/list?filterName=';
	private static final STRING REFERER = 'referer';
	private static final STRING LIGHTNING_URL = 'lightning.force.com';
	private static final STRING FIRSTSTEP = '1';
	private static final STRING SECONDSTEP = '2';
	public Integer intSelectedCarrier { get; set; }
	public static String strErrorMsg = 'Please select any value';
	public static String strExceptionMsg = 'Error, please try again';
	public static String strMessage = 'Successfully Updated!!';
	public static String strNoRecordSelected = 'No record was selected on the list view. Please click Cancel button and select records.';
	public List<String> list_fieldList { get; set; }
	public List<Schema.FieldSetMember> list_FieldsForUpdate { get; set; }
	public List<Schema.FieldSetMember> list_FieldSetMember = getFields();
	public List<CheckBoxOption> list_FieldListToDisplay { get; set; }
	public CarrierMassUpdateCtrl(ApexPages.StandardSetController objStdCtrl) {
		intSelectedCarrier = 0;
		strCurrentStep = FIRSTSTEP;
		objCarrier = new Carrier__c();
		list_CarrierRecord = new List<Carrier__c>();
		list_fieldList = new List<String>();
		list_FieldListToDisplay = new List<CheckBoxOption>();
		CarrierController = (ApexPages.StandardSetController) objStdCtrl;
		List<Carrier__c> list_SelectedCarrierRecord = CarrierController.getSelected();
		Id filterId = objStdCtrl.getFilterId();
		if (ApexPages.currentPage().getHeaders().get(REFERER).containsIgnoreCase(LIGHTNING_URL)) {
			FROMPAGE = new PageReference(CARRIERFILTER + filterId);
		} else {
			FROMPAGE = CarrierController.cancel();
		}
		if (list_SelectedCarrierRecord?.size() == 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, strNoRecordSelected));
		} else {
			intSelectedCarrier = list_SelectedCarrierRecord?.size();
			Set<Id> set_CarrierIds = new Set<Id>();
			for (Carrier__c objCarrier : list_SelectedCarrierRecord) {
				set_CarrierIds.add(objCarrier.Id);
			}

			String strQueryString = 'SELECT Id, Name, ';

			if (list_FieldSetMember != null && !list_FieldSetMember.isEmpty()) {
				for (Schema.FieldSetMember field : list_FieldSetMember) {
					strQueryString += field.fieldPath + ',';
				}
			}
			strQueryString = strQueryString.removeEnd(',') + ' FROM Carrier__c WHERE Id IN : set_CarrierIds';
			list_CarrierRecord = Database.query(strQueryString);
			getFieldOption();
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method gives the current page number.
	 * @param        NA
	 * @return       String - current page number
	 **/
	public String getStep() {
		return strCurrentStep;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method update Carrier__c field values on selected Carrier records.
	 * @param        NA
	 * @return       Page Reference of current page
	 **/
	public PageReference updateCarrier() {
		try {
			strCurrentStep = FIRSTSTEP;
			if (list_CarrierRecord?.size() > 0) {
				List<Carrier__c> list_CarriersToUpdate = new List<Carrier__c>();
				for (Carrier__c objCarrierRec : list_CarrierRecord) {
					for (Schema.FieldSetMember field : list_FieldsForUpdate) {
						objCarrierRec.put(field.fieldPath, objCarrier.get(field.fieldPath));
					}
					list_CarriersToUpdate.add(objCarrierRec);
				}
				if (list_CarriersToUpdate.size() > 0) {
					update list_CarriersToUpdate;

					ApexPages.addMessage(new apexPages.Message(ApexPages.Severity.CONFIRM, strMessage));
					strCurrentStep = SECONDSTEP;
				}
			}
			return ApexPages.currentPage();
		} catch (Exception ojbExp) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ojbExp.getmessage()));
			return ApexPages.currentPage();
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method redirect to list of records.
	 * @param        NA
	 * @return       Page Reference of Filter page
	 **/
	public PageReference cancel() {
		return FROMPAGE;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method get the fields from Fields set.
	 * @param        NA
	 * @return       List<Schema.FieldSetMember> - list fields of the fieldSet
	 **/
	public List<Schema.FieldSetMember> getFields() {
		return SObjectType.Carrier__c.FieldSets.Carrier_Mass_Update.getFields();
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method retuens the select option for fields to update select list.
	 * @param        NA
	 * @return       void
	 **/
	public void getFieldOption() {
		if (list_FieldSetMember != null && !list_FieldSetMember.isEmpty()) {
			for (Schema.FieldSetMember field : list_FieldSetMember) {
				list_FieldListToDisplay.add(new CheckBoxOption(field.Label));
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method returns fields to display which selected in list.
	 * @param        NA
	 * @return       List<Schema.FieldSetMember> - list of field selected from fieldSet
	 **/
	public List<Schema.FieldSetMember> getfieldsToUpdate() {
		list_FieldsForUpdate = new List<Schema.FieldSetMember>();

		if (list_FieldSetMember != null && !list_FieldSetMember.isEmpty()) {
			for (Schema.FieldSetMember field : list_FieldSetMember) {
				if (list_fieldList != null && list_fieldList.contains(field.Label)) {
					list_FieldsForUpdate.add(field);
				}
			}
		}

		return list_FieldsForUpdate;
	}

	/**
	 * @author       Deepika Saini
	 * @description  This method updates fields on fields to update section when checkbox checked/unchecked.
	 * @param        NA
	 * @return       void
	 **/
	public void onCheckBoxChange() {
		list_fieldList.clear();
		for (CheckBoxOption option : list_FieldListToDisplay) {
			if (option.selected) {
				list_fieldList.add(option.label);
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  This wrapper class used for checkbox option to hold checked/uncheked state.
	 * @param        NA
	 * @return       void
	 **/
	public class CheckBoxOption {
		public String label { get; set; }
		public Boolean selected { get; set; }

		public CheckBoxOption(String label) {
			this.label = label;
			this.selected = false;
		}
	}
}