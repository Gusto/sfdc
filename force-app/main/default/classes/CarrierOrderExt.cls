public class CarrierOrderExt {
	public ApexPages.StandardController stdCon;
	public SObject sObj;
	// Boolean to show Error
	public Boolean blnHasError { get; set; }
	// Set to store all userId from Public Group
	set<Id> set_userPublicGroup;
	public static Boolean blnIsEarlySubmissionButtonClick = false;

	public CarrierOrderExt(ApexPages.StandardController standardController) {
		blnHasError = false;
		set_userPublicGroup = new Set<Id>();
		this.stdCon = standardController;
		if (!test.isRunningTest())
			stdCon.addFields(additionalFields);
		sObj = stdCon.getRecord();
		for (GroupMember gm : [SELECT Id, UserOrGroupId FROM GroupMember WHERE Group.Name = 'Order Stage Update Users']) {
			set_userPublicGroup.add(gm.UserOrGroupId);
		}
		String preFix = String.valueOf(stdCon.getId()).left(3).toLowercase();
		Schema.DescribeSObjectResult coObj = Carrier_Order__c.sObjectType.getDescribe();
		String coPrefix = coObj.getKeyPrefix();

		if (coPrefix == preFix) {
			Carrier_Order__c carrierObj = [SELECT Id, Benefit_Order__c, Benefit_Order__r.OwnerId, OwnerId, Confirmation_Owner__c, RecordType.Name FROM Carrier_Order__c WHERE Id = :stdCon.getId()];

			if (
				((carrierObj.Benefit_Order__r.OwnerId != userInfo.getUserId() && !set_userPublicGroup.contains(UserInfo.getUserId()))) ||
				((carrierObj.Benefit_Order__r.OwnerId != userInfo.getUserId() && !set_userPublicGroup.contains(UserInfo.getUserId())) &&
				carrierObj.OwnerId != userInfo.getUserId() &&
				carrierObj.Confirmation_Owner__c != userInfo.getUserId())
			) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, Label.CancelOrderError));
				blnHasError = true;
			}
		}
	}

	public void stageDenied() {
		setValue('Implementation_Stage__c', 'Denied');
	}

	public void stageCanceled() {
		setValue('Implementation_Stage__c', '');
		setValue('Additional_Details__c', '');
	}

	// This method is used to change the BO status only when CO implementation stage is in Early Submission
	public void stageBOOrderStatus(){
        String strBOId = (String) sObj.get('Benefit_Order__c');
        if(strBOId != null){
            List<Benefit_Order__c> list_BO = [Select Id,Order_Status__c From Benefit_Order__c WHERE Id =: strBOId Limit 1];
            if(!list_BO.isEmpty() && (String.valueof(sObj.get('Implementation_Stage__c')) == CarrierOrderUtil.IMPLEMENTATION_STAGE_EARLY_SUBMISSION ||
              String.valueof(sObj.get('Implementation_Stage__c')) == CarrierOrderUtil.IMPLEMENTATION_STAGE_READY_FOR_EARLY_SUBMISSION)){
				blnIsEarlySubmissionButtonClick = true;
                setStage(list_BO[0].Order_Status__c);
            }
        }

    }

	// This method is used to go back to the previous page
    public PageReference previousPage(){
        return getObjectPage();
    }

	public PageReference nextStage() {
		if (isOpen())
			requestNext();
		return getObjectPage();
	}

	private void requestNext() {
		PicklistUtl.PicklistResult result;
		try {
			PicklistUtl.PicklistRequest request = new PicklistUtl.PicklistRequest();
			request.objectName = 'Carrier_Order__c';
			request.fieldName = 'Implementation_Stage__c';
			request.currentValue = (String) sObj.get('Implementation_Stage__c');
			result = PicklistUtl.getNext(request);
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
		} finally {
			if (result.isSuccess())
				setStage(result.getValue());
		}
	}

	private void setStage(String value) {
		try {
			setValue('Implementation_Stage__c', value);
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
		} finally {
			doUpdate();
		}
	}
	@Testvisible
	private List<String> additionalFields {
		get {
			if (additionalFields == null) {
				additionalFields = new List<String>();
				additionalFields.add('Implementation_Stage__c');
				additionalFields.add('Closed__c');
				additionalFields.add('Benefit_Order__c');
			}
			return additionalFields;
		}
		private set;
	}

	private Boolean isOpen() {
		return !(Boolean) sObj.get('Closed__c');
	}

	private void setValue(String fieldName, String value) {
		sObj.put(fieldName, value);
	}

	private void doUpdate() {
		try {
			update sObj;
		} catch (Exception ex) {
			ExceptionHandler.notify(ex);
		}
	}

	private PageReference getObjectPage() {
		String objId = ApexPages.currentPage().getParameters().get('Id');
		PageReference pageRef = new PageReference('/' + objId);
		pageRef.setRedirect(true);
		return pageRef;
	}
}