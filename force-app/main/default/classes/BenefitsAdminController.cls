public class BenefitsAdminController {
	public Opportunity theOpp { get; private set; }

	public BenefitsAdminController(ApexPages.StandardController controller) {
		theOpp = (Opportunity) controller.getRecord();
		theOpp = [SELECT Id, accountId, account.ZP_Company_ID__c, ID__c, Source_ID__c FROM Opportunity WHERE Id = :theOpp.id FOR UPDATE];
	}

	public list<BenefitsuserDetails> getUserroles() {
		list<BenefitsuserDetails> listToReturn = new List<BenefitsuserDetails>();
		listToReturn.clear();
		map<string, ZP_User_Role__c> userIdUserRoleRecMap = new Map<string, ZP_User_Role__c>();

		List<ZP_User_Role__c> zpuserrole = [
			SELECT First_Name__c, Last_Name__c, Is_Primary__c, Type__c, User_Id__c
			FROM ZP_User_Role__c
			WHERE Type__c = 'Role::PayrollAdmin' AND Company_Id__c = :theOpp.account.ZP_Company_ID__c
		];
		if (zpuserrole.size() > 0) {
			for (ZP_User_Role__c rec : zpuserrole) {
				userIdUserRoleRecMap.put(rec.User_Id__c, rec);
			}

			if (userIdUserRoleRecMap.keyset().size() > 0) {
				for (ZP_User__c usrRec : [SELECT id, Id__c, Email__c FROM ZP_User__c WHERE Id__c IN :userIdUserRoleRecMap.keyset()]) {
					if (!string.isBlank(usrRec.Id__c) && userIdUserRoleRecMap.containsKey(usrRec.Id__c)) {
						ZP_User_Role__c usrRole = userIdUserRoleRecMap.get(usrRec.Id__c);
						BenefitsuserDetails wrapperRec = new BenefitsuserDetails(usrRole.First_Name__c, usrRole.Last_Name__c, usrRec.Email__c, usrRole.Is_Primary__c);
						listToReturn.add(wrapperRec);
					}
				}
			}
		}

		return listToReturn;
	}

	public list<BenefitsuserDetails> getBenefitUserroles() {
		list<BenefitsuserDetails> listToReturnbenefits = new List<BenefitsuserDetails>();
		listToReturnbenefits.clear();
		String HINewPlanId;
		map<string, ZP_User_Role__c> benefitsuserRoleMap = new Map<string, ZP_User_Role__c>();
		set<String> HIBenefitsAdminset = new Set<string>();
		set<String> HINPIdset = new Set<string>();

		List<HI_New_Plans_Application__c> HINewPlanIDList = [SELECT Id__c FROM HI_New_Plans_Application__c WHERE External_Key__c = :theOpp.Source_ID__c];
		if (HINewPlanIDList.size() > 0) {
			for (HI_New_Plans_Application__c HiNPId : HINewPlanIDList) {
				HINPIdset.add(HiNPId.Id__c);
			}
		}

		List<HI_Benefits_Admin__c> BenfitsAdmin = [SELECT Id__c, ZP_User_Id__c FROM HI_Benefits_Admin__c WHERE Id__c IN :HINPIdset];
		if (BenfitsAdmin.size() > 0) {
			for (HI_Benefits_Admin__c rec : BenfitsAdmin) {
				HIBenefitsAdminset.add(rec.ZP_User_Id__c);
			}
		}

		List<ZP_User_Role__c> zpuserroles = [SELECT First_Name__c, Last_Name__c, Is_Primary__c, Type__c, User_Id__c FROM ZP_User_Role__c WHERE User_Id__c IN :HIBenefitsAdminset];
		if (zpuserroles.size() > 0) {
			for (ZP_User_Role__c rec : zpuserroles) {
				benefitsuserRoleMap.put(rec.User_Id__c, rec);
			}

			if (benefitsuserRoleMap.keyset().size() > 0) {
				for (ZP_User__c usrRec : [SELECT id, Id__c, Email__c FROM ZP_User__c WHERE Id__c IN :benefitsuserRoleMap.keyset()]) {
					if (!string.isBlank(usrRec.Id__c) && benefitsuserRoleMap.containsKey(usrRec.Id__c)) {
						ZP_User_Role__c usrRole = benefitsuserRoleMap.get(usrRec.Id__c);
						BenefitsuserDetails wrapperRec = new BenefitsuserDetails(usrRole.First_Name__c, usrRole.Last_Name__c, usrRec.Email__c, false);
						listToReturnbenefits.add(wrapperRec);
					}
				}
			}
		}

		return listToReturnbenefits;
	}

	public class BenefitsuserDetails {
		public string firstName { get; set; }
		public string lastName { get; set; }
		public string email1 { get; set; }
		public boolean isPrimary { get; set; }

		public BenefitsuserDetails(string fName, string lName, string email2, boolean prim) {
			firstName = fName;
			lastName = lName;
			email1 = email2;
			isPrimary = prim;
		}
	}
}