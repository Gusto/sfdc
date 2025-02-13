/* @name         ZPCompanyQueue
 * @author       Praveen Sethu
 * @date         10-16-2021
 * @description  Re-process ZP comapany records asynchronously
 * @test classes ZPCompanyTriggerHelperTest
 */
public class ZPCompanyQueue implements Queueable {
	private List<ZP_Company__c> list_Companies;
	private String strOperation;
	private ZP_Company_Configuration_Settings__mdt objConfig;
	public Boolean blnInsert = false;
	public Boolean blnTestException = false;

	public ZPCompanyQueue(List<ZP_Company__c> list_InputCompanies) {
		list_Companies = list_InputCompanies;
	}

	public ZPCompanyQueue(List<ZP_Company__c> list_InputCompanies, String strOperation, ZP_Company_Configuration_Settings__mdt objConfig) {
		list_Companies = list_InputCompanies;
		this.strOperation = strOperation;
		this.objConfig = objConfig;
	}

	public void execute(QueueableContext context) {
		try {
			ZPCompanyTriggerHelper.queue = true;
			ZPCompanyTriggerHelper.blnInsert = blnInsert;
			if (String.isBlank(strOperation)) {
				if (list_Companies.size() > 0) {
					update list_Companies;
				}
			} else if (strOperation == 'Prioritized') {
				// If enqueud for prioritized processing, get batch size from configuration
				Integer intBatchSize = objConfig?.Prioiritized_Processing_Batch_Size__c != null &&
					Integer.valueOf(objConfig.Prioiritized_Processing_Batch_Size__c) != 0
					? Integer.valueOf(objConfig.Prioiritized_Processing_Batch_Size__c)
					: 15;
				// Split the list into two based on the batch size
				List<ZP_Company__c> list_companiesToProcess = new List<ZP_Company__c>();
				List<ZP_Company__c> list_companiesRemaining = new List<ZP_Company__c>();
				for (ZP_Company__c objCompany : list_Companies) {
					if (list_companiesToProcess.size() < intBatchSize) {
						list_companiesToProcess.add(objCompany);
					} else {
						list_companiesRemaining.add(objCompany);
					}
				}
				// Process the first batch
				if (!list_companiesToProcess.isEmpty()) {
					update list_companiesToProcess;
				}
				// Enqueue a new job to process the remaining companies
				if (!list_companiesRemaining.isEmpty()) {
					if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !blnTestException) {
						System.enqueueJob(new ZPCompanyQueue(list_companiesRemaining, strOperation, objConfig));
					} else {
						ExceptionLogUtil.logException(
							'ZPCompanyQueue',
							'execute',
							'ZP Company processing were left to be prioritized for ' + list_companiesRemaining.size() + 'records.',
							(String) null
						);
					}
				}
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ZPCompanyQueue', 'execute', null, objException);
		}
	}
}