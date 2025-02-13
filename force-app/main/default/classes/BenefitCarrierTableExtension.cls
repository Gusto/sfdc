public with sharing class BenefitCarrierTableExtension {
	public Integer size { get; set; }
	public String loggedInUser { get; set; }
	public Integer noOfRecords { get; set; }
	public List<SelectOption> paginationSizeOptions { get; set; }
	public User_Preference__c userRecord { get; set; }
	public List<User_Preference__c> userList = new List<User_Preference__c>();

	public list<selectOption> benefitOrderStatus { get; set; }
	public list<selectOption> carrierOrderStatus { get; set; }

	public list<selectOption> selectedBenefitOrderStatus { get; set; }
	public list<selectOption> selectedCarrierOrderStatus { get; set; }

	public String benefitOrderSortOrder { get; set; }
	public string sortDirection { get; set; }
	private string sortOrderField { get; set; }

	boolean isCarrierOrderFilterApplied = false;

	public BenefitCarrierTableExtension(ApexPages.StandardController controller) {
		//benefitOrderSortOrder = 'Order_Status__c';
		sortDirection = 'ASC';
		benefitOrderStatus = new List<SelectOption>();
		carrierOrderStatus = new List<SelectOption>();
		selectedBenefitOrderStatus = new List<SelectOption>();
		selectedCarrierOrderStatus = new List<SelectOption>();
		paginationSizeOptions = new List<SelectOption>();
		paginationSizeOptions.add(new SelectOption('5', '5'));
		paginationSizeOptions.add(new SelectOption('10', '10'));
		paginationSizeOptions.add(new SelectOption('20', '20'));
		paginationSizeOptions.add(new SelectOption('50', '50'));
		paginationSizeOptions.add(new SelectOption('100', '100'));
		userList = [
			SELECT Id, Coverage_Effective_Date__c, User__c, Carrier_Name__c, Benefit_Order_Status__c, Carrier_Order_Implementation_Stage__c
			FROM User_Preference__c
			WHERE User__c = :UserInfo.getUserId()
		];
		if (userList.size() > 0) {
			userRecord = userList[0];

			if (userRecord.Benefit_Order_Status__c != null && userRecord.Benefit_Order_Status__c.length() > 0) {
				for (string status : userRecord.Benefit_Order_Status__c.split(',')) {
					selectedBenefitOrderStatus.add(new selectOption(status.trim(), status.trim()));
				}
			}

			if (userRecord.Carrier_Order_Implementation_Stage__c != null && userRecord.Carrier_Order_Implementation_Stage__c.length() > 0) {
				for (string stage : userRecord.Carrier_Order_Implementation_Stage__c.split(',')) {
					selectedCarrierOrderStatus.add(new selectOption(stage.trim(), stage.trim()));
				}
			}
		} else {
			userRecord = new User_Preference__c();
			userRecord.User__c = UserInfo.getUserId();
		}

		benefitOrderStatus = getPicklistOptions(new Benefit_Order__c(), 'Order_Status__c', userRecord.Benefit_Order_Status__c);
		carrierOrderStatus = getPicklistOptions(new Carrier_Order__c(), 'Implementation_Stage__c', userRecord.Carrier_Order_Implementation_Stage__c);
	}

	private list<SelectOption> getPicklistOptions(Sobject Obj, String PicklistFieldName, string toExcludeValueString) {
		Schema.sObjectType sobject_type = Obj.getSObjectType();
		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();

		List<Schema.PicklistEntry> pick_list_values = field_map.get(PicklistFieldName).getDescribe().getPickListValues();
		List<selectOption> options = new List<selectOption>();

		for (Schema.PicklistEntry a : pick_list_values) {
			if (toExcludeValueString != null && toExcludeValueString.length() > 0) {
				if (toExcludeValueString.contains(a.getValue())) {
					continue;
				}
			}
			SelectOption so = new selectOption(a.getLabel(), a.getValue());
			options.add(so);
		}

		return options;
	}

	public ApexPages.StandardSetController setCon {
		get {
			if (Test.isRunningTest()) {
				setCon = null;
			}
			if (setCon == null) {
				size = 20;
				String query = 'SELECT ';
				loggedInUser = userinfo.getUserId();
				for (Schema.FieldSetMember field : this.getBenefitOrderFields()) {
					query += field.getFieldPath() + ', ';
				}
				query += '(SELECT ID, CaseNumber, Requires_Action__c from Cases__r where RecordType.name in (\'Benefits Renewal Case\',\'Benefits New Plan Case\',\'Benefits Change Case\')), ';
				query += '(SELECT ';
				for (Schema.FieldSetMember field : this.getCarrierOrderFields()) {
					query += field.getFieldPath() + ', ';
				}

				query += 'Id, Name from Carrier_Orders__r';

				boolean isWhereApplied = false;
				if (userRecord.Carrier_Name__c != null && userRecord.Carrier_Name__c.length() > 0) {
					string tempName = userRecord.Carrier_Name__c;
					query += ' where Carrier__r.Name =\'' + tempName + '\' ';
					isWhereApplied = true;
					isCarrierOrderFilterApplied = true;
				}

				if (userRecord.Carrier_Order_Implementation_Stage__c != null && userRecord.Carrier_Order_Implementation_Stage__c.trim().length() > 0) {
					string tempStageString = '(';
					for (String rec : userRecord.Carrier_Order_Implementation_Stage__c.split(',')) {
						if (rec != null && rec.trim().length() > 0) {
							tempStageString += '\'' + rec.trim() + '\',';
						}
					}

					tempStageString = tempStageString.trim().removeEnd(',') + ')';

					if (tempStageString != null && tempStageString.length() > 0) {
						if (isWhereApplied) {
							query += ' and 	Implementation_Stage__c IN ' + tempStageString;
						} else {
							query += ' where  Implementation_Stage__c IN ' + tempStageString;
						}
						isCarrierOrderFilterApplied = true;
					}
				}

				query += '), Id, Name from Benefit_Order__c ';

				// if(!Test.isRunningTest()){
				query += 'where (OwnerId=:loggedInUser OR UW_Owner__c=:loggedInUser) and Order_Status__c not in (\'Canceled\',\'Closed Lost\',\'Closed Admin\')';

				if (userRecord.Coverage_Effective_Date__c != null) {
					Date tempDate = userRecord.Coverage_Effective_Date__c;
					query += ' and Coverage_Effective_Date__c = :tempDate';
				}

				if (userRecord.Benefit_Order_Status__c != null && userRecord.Benefit_Order_Status__c.length() > 0) {
					string tempStatusstring = '(';
					for (string rec : userRecord.Benefit_Order_Status__c.split(',')) {
						if (rec != null && rec.trim().length() > 0) {
							tempStatusString += '\'' + rec.trim() + '\',';
						}
					}
					tempStatusString = tempStatusString.trim().removeEnd(',') + ')';
					if (tempStatusString != null && tempStatusString.length() > 0) {
						query += ' and Order_Status__c IN ' + tempStatusString;
					}
				}

				if (benefitOrderSortOrder != null && benefitOrderSortOrder.length() > 0) {
					query += ' Order By ' + benefitOrderSortOrder + ' ' + sortDirection;
				}
				// }

				list<Benefit_Order__c> tempBenefitList = Database.query(query);

				if (isCarrierOrderFilterApplied) {
					setCon = new ApexPages.StandardSetController(filterOutBenefitOrderWithoutChildRecords(tempBenefitList));
				} else {
					setCon = new ApexPages.StandardSetController(tempBenefitList);
				}
				setCon.setPageSize(size);
				noOfRecords = setCon.getResultSize();
			}
			return setCon;
		}
		set;
	}

	public list<Benefit_Order__c> filterOutBenefitOrderWithoutChildRecords(list<Benefit_Order__c> originalBOList) {
		list<Benefit_Order__c> benefitOrderList = new List<Benefit_Order__c>();

		if (originalBOList == null || !(originalBOList.size() > 0)) {
			return originalBOList;
		}

		for (Benefit_Order__c rec : originalBOList) {
			if (rec.Carrier_Orders__r == null || !(rec.Carrier_Orders__r.size() > 0)) {
				continue;
			}
			benefitOrderList.add(rec);
		}

		isCarrierOrderFilterApplied = false;
		return benefitOrderList;
	}

	//refresh orders
	public PageReference refreshOrders() {
		queryRecords();

		return null;
	}

	//Save the edited orders
	public PageReference saveMe() {
		List<Benefit_Order__c> benefitOrderList = new List<Benefit_Order__c>();
		List<Carrier_Order__c> carrierOrderList = new List<Carrier_Order__c>();

		for (Benefit_Order__c benefitOrd : (List<Benefit_Order__c>) setCon.getRecords()) {
			benefitOrderList.add(benefitOrd);
			if (benefitOrd.Carrier_Orders__r.size() > 0) {
				for (Carrier_Order__c carrierOrd : benefitOrd.Carrier_Orders__r) {
					carrierOrderList.add(carrierOrd);
				}
			}
		}
		try {
			if (benefitOrderList.size() > 0) {
				update benefitOrderList;
			}
			if (carrierOrderList.size() > 0) {
				update carrierOrderList;
			}
			queryRecords();
		} catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return null;
	}

	//Refresh page size
	public PageReference refreshPageSize() {
		try {
			queryRecords();
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Modified rows exist in the records.'));
		}
		return null;
	}

	public void queryRecords() {
		String query = 'SELECT ';
		loggedInUser = userinfo.getUserId();
		for (Schema.FieldSetMember field : this.getBenefitOrderFields()) {
			query += field.getFieldPath() + ', ';
		}
		query += '(SELECT ID, CaseNumber, Requires_Action__c from Cases__r where RecordType.name in (\'Benefits Renewal Case\',\'Benefits New Plan Case\',\'Benefits Change Case\')), ';
		query += '(SELECT ';
		for (Schema.FieldSetMember field : this.getCarrierOrderFields()) {
			query += field.getFieldPath() + ', ';
		}
		query += 'Id, Name from Carrier_Orders__r';

		boolean isWhereApplied = false;
		if (userRecord.Carrier_Name__c != null && userRecord.Carrier_Name__c.length() > 0) {
			string tempName = userRecord.Carrier_Name__c;
			query += ' where Carrier__r.Name =\'' + tempName + '\' ';
			isWhereApplied = true;
			isCarrierOrderFilterApplied = true;
		}

		if (selectedCarrierOrderStatus != null && selectedCarrierOrderStatus.size() > 0) {
			string tempStageString;
			string tempCarrierOrderStage;

			for (selectOption rec : selectedCarrierOrderStatus) {
				string stage = rec.getValue();
				if (stage != null && stage.trim().length() > 0) {
					if (tempStageString == null || tempStageString.length() == 0) {
						tempStageString = '(';
					}
					tempStageString += '\'' + stage.trim() + '\',';
					tempCarrierOrderStage = stage.trim() + ',';
				}
			}

			if (tempStageString != null && tempStageString.length() > 0) {
				tempStageString = tempStageString.trim().removeEnd(',') + ')';
			}

			if (tempCarrierOrderStage != null && tempCarrierOrderStage.length() > 0) {
				tempCarrierOrderStage = tempCarrierOrderStage.trim().removeEnd(',');
				userRecord.Carrier_Order_Implementation_Stage__c = tempCarrierOrderStage;
			}

			if (tempStageString != null && tempStageString.length() > 0) {
				if (isWhereApplied) {
					query += ' and 	Implementation_Stage__c IN ' + tempStageString;
				} else {
					query += ' where  Implementation_Stage__c IN ' + tempStageString;
				}
				isCarrierOrderFilterApplied = true;
			}
		} else {
			userRecord.Carrier_Order_Implementation_Stage__c = '';
		}

		query += '), Id, Name from Benefit_Order__c ';
		//if(!Test.isRunningTest()){
		query += 'where (OwnerId=:loggedInUser OR UW_Owner__c=:loggedInUser) and Order_Status__c not in (\'Canceled\',\'Closed Lost\',\'Closed Admin\')';

		if (userRecord.Coverage_Effective_Date__c != null) {
			Date tempDate = userRecord.Coverage_Effective_Date__c;
			query += ' and Coverage_Effective_Date__c = :tempDate';
		}

		if (selectedBenefitOrderStatus != null && selectedBenefitOrderStatus.size() > 0) {
			string tempStatusString;
			string tempCarrierOrderStage;
			//userRecord.Benefit_Order_Status__c = userRecord.Benefit_Order_Status__c.replace('[','').replace(']','');
			for (selectOption rec : selectedBenefitOrderStatus) {
				string stage = rec.getValue();
				if (stage != null && stage.trim().length() > 0) {
					if (tempStatusString == null || tempStatusString.length() == 0) {
						tempStatusString = '(';
					}
					tempStatusString += '\'' + stage.trim() + '\',';
					tempCarrierOrderStage = stage + ',';
				}
			}

			if (tempStatusString != null && tempStatusString.length() > 0) {
				tempStatusString = tempStatusString.trim().removeEnd(',') + ')';
			}

			if (tempCarrierOrderStage != null && tempCarrierOrderStage.trim().length() > 0) {
				userRecord.Benefit_Order_Status__c = tempCarrierOrderStage.trim().removeEnd(',');
			}

			if (tempStatusString != null && tempStatusString.length() > 0) {
				query += ' and Order_Status__c IN ' + tempStatusString;
			}
		} else {
			userRecord.Benefit_Order_Status__c = '';
		}

		if (benefitOrderSortOrder != null && benefitOrderSortOrder.length() > 0) {
			query += ' order by ' + benefitOrderSortOrder + ' ' + sortDirection;
		}

		list<Benefit_Order__c> tempBenefitList = Database.query(query);
		if (isCarrierOrderFilterApplied) {
			setCon = new ApexPages.StandardSetController(filterOutBenefitOrderWithoutChildRecords(tempBenefitList));
		} else {
			setCon = new ApexPages.StandardSetController(tempBenefitList);
		}
		setCon.setPageSize(size);
		noOfRecords = setCon.getResultSize();
		//if(userRecord.Coverage_Effective_Date__c!=null){
		upsert userRecord;
		//}
	}

	public void sortbyBenefitOrderField() {
		//this.benefitOrderSortOrder = 'Name';
		if (sortOrderField == benefitOrderSortOrder) {
			sortDirection = (sortDirection == 'ASC' ? 'DESC' : 'ASC');
		} else {
			sortDirection = 'ASC';
		}

		sortOrderField = benefitOrderSortOrder;
		refreshOrders();
	}

	//Redirect to benefit order page
	public PageReference benefitOrderView() {
		Schema.DescribeSObjectResult result = Benefit_Order__c.SObjectType.getDescribe();
		PageReference pageRef = new PageReference('/' + result.getKeyPrefix());
		//PageReference pageRef = new PageReference('/apex/BenefitsTab');
		pageRef.setRedirect(true);
		return pageRef;
	}

	public List<Benefit_Order__c> getBenefitOrders() {
		List<Benefit_Order__c> benefitOrderList = new List<Benefit_Order__c>();
		for (Benefit_Order__c benefitOrd : (List<Benefit_Order__c>) setCon.getRecords()) {
			benefitOrderList.add(benefitOrd);
		}
		return benefitOrderList;
	}

	public List<Schema.FieldSetMember> getBenefitOrderFields() {
		return SObjectType.Benefit_Order__c.FieldSets.BenefitCarrierTableReq.getFields();
	}

	public List<Schema.FieldSetMember> getCarrierOrderFields() {
		return SObjectType.Carrier_Order__c.FieldSets.BenefitCarrierTableReq.getFields();
	}
}