/**
 * @description Queueable class to process insert and updates asynchronously.
 * @group ZP_Product_Line__c
 * Test: ZPProductLineTriggerHelperTest
 */
public class ZPProductLineQueue implements Queueable {
	private List<ZP_Product_Line__c> list_ProductLines;

	public ZPProductLineQueue(List<ZP_Product_Line__c> list_ProductLines) {
		this.list_ProductLines = list_ProductLines;
	}

	/**
	 * @description Default execute method that sets queue flag to true and updates product line records.
	 */
	public void execute(QueueableContext context) {
		ZPProductLineTriggerHelper.blnQueue = true;
		if (list_ProductLines.size() > 0) {
			update list_ProductLines;
		}
	}
}