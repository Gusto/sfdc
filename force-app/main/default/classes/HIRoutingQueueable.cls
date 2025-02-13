/**
 * @author       Praveen Sethu
 * @description  Sending Account for HI Owner Routing
 * @testClass    AccountTriggerHelperTest
 */
public class HIRoutingQueueable implements Queueable, Database.AllowsCallouts {
	public Id idAccount;
	public Map<Id, Account> map_Accounts = new Map<Id, Account>();

	public HIRoutingQueueable(Id idAccount) {
		this.idAccount = idAccount;
	}

	public HIRoutingQueueable(Map<Id, Account> map_Accounts) {
		this.map_Accounts = map_Accounts;
	}

	/**
	 * @Description : Standard queueable execute method that runs a flow to send account to RingLead for HI owner routing
	 * @Param       : Id - Id of the account to route HI Owner
	 **/
	public void execute(QueueableContext context) {
		if (idAccount != null && !map_Accounts.containsKey(idAccount)) {
			map_Accounts.put(idAccount, new Account(Id = idAccount));
		}

		for (Account objAcc : map_Accounts.values()) {
			// create parameter and set account id
			Map<String, Object> map_Params = new Map<String, Object>();
			map_Params.put('Account_Id', objAcc.Id);
			// start the flow
			new Flow.Interview.Send_Account_For_HI_Owner_Routing(map_Params).start();
		}
	}
}