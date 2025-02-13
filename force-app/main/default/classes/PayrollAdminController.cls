public class PayrollAdminController {
	public Opportunity theOpp { get; private set; }

	public PayrollAdminController(ApexPages.StandardController controller) {
		theOpp = (Opportunity) controller.getRecord();
		theOpp = [SELECT Id, accountId, ZP_Company_ID__c FROM Opportunity WHERE Id = :theOpp.id FOR UPDATE];
	}

	public list<userDetails> getUserroles() {
		list<userDetails> listToReturn = new List<userDetails>();
		map<string, ZP_User_Role__c> userIdUserRoleRecMap = new Map<string, ZP_User_Role__c>();

		List<ZP_User_Role__c> zpuserrole = [
			SELECT First_Name__c, Last_Name__c, Is_Primary__c, Type__c, User_Id__c
			FROM ZP_User_Role__c
			WHERE Type__c = 'Role::PayrollAdmin' AND Company_Id__c = :theOpp.ZP_Company_ID__c
		];
		if (zpuserrole.size() > 0) {
			for (ZP_User_Role__c rec : zpuserrole) {
				userIdUserRoleRecMap.put(rec.User_Id__c, rec);
			}

			if (userIdUserRoleRecMap.keyset().size() > 0) {
				for (ZP_User__c usrRec : [SELECT id, Id__c, Email__c FROM ZP_User__c WHERE Id__c IN :userIdUserRoleRecMap.keyset()]) {
					if (!string.isBlank(usrRec.Id__c) && userIdUserRoleRecMap.containsKey(usrRec.Id__c)) {
						ZP_User_Role__c usrRole = userIdUserRoleRecMap.get(usrRec.Id__c);
						userDetails wrapperRec = new userDetails(usrRole.First_Name__c, usrRole.Last_Name__c, usrRec.Email__c, usrRole.Is_Primary__c);
						listToReturn.add(wrapperRec);
					}
				}
			}
		}
		return listToReturn;
	}

	public class userDetails {
		public string firstName { get; set; }
		public string lastName { get; set; }
		public string email1 { get; set; }
		public boolean isPrimary { get; set; }

		public userDetails(string fName, string lName, string email2, boolean prim) {
			firstName = fName;
			lastName = lName;
			email1 = email2;
			isPrimary = prim;
		}
	}
}