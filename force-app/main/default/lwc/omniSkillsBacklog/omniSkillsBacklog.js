import { LightningElement, track, wire } from "lwc";
import getBacklogItems from "@salesforce/apex/OmniBacklogController.getBacklogItems";
import retrieveFilters from "@salesforce/apex/OmniBacklogController.getFilters";
import { displayToast } from "c/utilityService";
export default class OmniSkillsBacklog extends LightningElement {
	@track list_MasterData = [];
	@track list_SkillOptions = [];
	@track list_FilteredData = [];
	@track list_Pillars = [];
	@track list_SubPillars = [];
	@track list_WFMQueues = [];
	@track list_SelectedSkills = [];
	@track list_SelectedPillars = [];
	@track list_SelectedSubPillars = [];
	@track list_SelectedWFMQueues = [];
	@track list_ChatButtons = [];
	blnIsLoading = false;
	blnDisableFilter = true;
	blnDisableClear = true;
	intBacklogCount = 0;
	strCaseNumber = "";
	strPriority = "";
	strSortedBy = "";
	strSortDirection = "";
	strAgentId = "";
	strChatButtonId = "";

	columns = [
		{
			label: "Work Item",
			fieldName: "strCaseNumber",
			type: "customColumn",
			sortable: true,
			typeAttributes: {
				caseNumber: { fieldName: "strCaseNumber" },
				caseRecordId: { fieldName: "idCase" }
			}
		},
		{ label: "Skills Required", fieldName: "skills", type: "text", initialWidth: 400, wrapText: true },
		{ label: "Priority", fieldName: "intPriority", sortable: true },
		{ label: "Pillar", fieldName: "strPillar", sortable: true },
		{ label: "Sub-Pillar", fieldName: "strSubPillar", sortable: true },
		{ label: "WFM Queue Tag", fieldName: "strWFMQueue", sortable: true },
		{ label: "Owner", fieldName: "strOwner" },
		{ label: "Owner Active", fieldName: "strOwnerActive" },
		{ label: "PE", fieldName: "strPE" },
		{
			label: "Requested Time",
			fieldName: "dtmRequestedTime",
			type: "date",
			sortable: true,
			typeAttributes: {
				weekday: "short",
				year: "numeric",
				month: "short",
				day: "2-digit",
				hour: "2-digit",
				minute: "2-digit"
			}
		},
		{
			label: "First Response Time",
			fieldName: "dtmFirstResponse",
			type: "date",
			sortable: true,
			typeAttributes: {
				weekday: "short",
				year: "numeric",
				month: "short",
				day: "2-digit",
				hour: "2-digit",
				minute: "2-digit"
			}
		}
	];

	connectedCallback() {
		this.loadBacklogItems(true);
	}

	/**
	 * This method calls the apex method to fetch the backlog items
	 */
	@wire(retrieveFilters)
	wiredFilters({ error, data }) {
		if (data) {
			this.list_SkillOptions = data.list_Skills.map((skill) => ({
				label: skill.MasterLabel,
				value: skill.Id
			}));

			this.list_Pillars = data.list_Pillars.map((pillar) => ({
				label: pillar,
				value: pillar
			}));

			this.list_SubPillars = data.list_SubPillars.map((subpillar) => ({
				label: subpillar,
				value: subpillar
			}));

			this.list_WFMQueues = data.list_WFMQueues.map((wfmqueue) => ({
				label: wfmqueue,
				value: wfmqueue
			}));

			this.list_ChatButtons = data.list_ChatButtons.map((chatbutton) => ({
				label: chatbutton.MasterLabel,
				value: chatbutton.Id
			}));
		} else if (error) {
			console.error("Error fetching skills", error);
		}
	}

	/**
	 * This method calls the apex method to fetch the backlog items
	 */
	loadBacklogItems(blnInitialLoad) {
		this.blnIsLoading = true;
		getBacklogItems({
			list_SkillIds: this.list_SelectedSkills,
			list_Pillars: this.list_SelectedPillars,
			list_SubPillars: this.list_SelectedSubPillars,
			list_WFMQueues: this.list_SelectedWFMQueues,
			strCaseNumber: this.strCaseNumber,
			strPriority: this.strPriority,
			strOwnerId: this.strAgentId,
			strChatButtonId: this.strChatButtonId
		})
			.then((result) => {
				let list_Temp = [];
				list_Temp = result.map((item) => ({
					...item,
					skills: item.skills.join(", ") // Format skills array as a comma-separated string
				}));
				if (blnInitialLoad) {
					this.list_MasterData = list_Temp;
				}

				this.list_FilteredData = list_Temp;
				this.intBacklogCount = this.list_FilteredData.length;
				this.blnIsLoading = false;
				if (blnInitialLoad) {
					displayToast(this, 'Success', 'Successfully loaded work items from backlog', 'success', '');
				}
			})
			.catch((error) => {
				let strErrorMessage = 'Error occurred while fetching backlog items';
				if (error.body) {
					strErrorMessage = error.body.message;
				}

				displayToast(this, 'Error', strErrorMessage, 'error', '');
				console.error("Error fetching backlog items", JSON.stringify(error));
				this.blnIsLoading = false;
			});
	}

	/**
	 * Handler method for selected skillchange
	 */
	handleSkillChange(event) {
		this.blnDisableFilter = false;
		this.list_SelectedSkills = event.detail.value;
	}

	/**
	 * Handler method for selected pillar change
	 */
	handlePillarChange(event) {
		this.blnDisableFilter = false;
		this.list_SelectedPillars = event.detail.value;
	}

	/**
	 * Handler method for selected sub pillar change
	 */
	handleSubPillarChange(event) {
		this.blnDisableFilter = false;
		this.list_SelectedSubPillars = event.detail.value;
	}

	/**
	 * Handler method for selected wfm queues change
	 */
	handleWFMQueueChange(event) {
		this.blnDisableFilter = false;
		this.list_SelectedWFMQueues = event.detail.value;
	}

	/**
	 * Handler method for case number change
	 */
	handleCaseNumber(event) {
		if (event.detail.value && event.detail.value.length >= 8) {
			this.blnDisableFilter = false;
			this.strCaseNumber = event.detail.value;
		}
	}

	/**
	 * Handler method for priority change
	 */
	handlePriorityChange(event) {
		this.blnDisableFilter = false;
		this.strPriority = event.detail.value;
	}

	/**
	 * Handler method for the apply filters button
	 */
	handleOnFilter() {
		this.blnDisableClear = false;
		this.blnDisableFilter = true;
		this.loadBacklogItems(false);
	}

	/**
	 * Handler method for the clear filters button
	 */
	handleOnClear() {
		this.blnIsLoading = true;
		this.blnDisableClear = true;
		this.list_SelectedSkills = [];
		this.list_SelectedPillars = [];
		this.list_SelectedSubPillars = [];
		this.list_SelectedWFMQueues = [];
		this.strCaseNumber = "";
		this.strAgentId = "";
		this.strPriority = "";
		this.list_FilteredData = this.list_MasterData;
		this.intBacklogCount = this.list_FilteredData.length;
		const recordPicker = this.template.querySelector('lightning-record-picker');
		recordPicker.clearSelection();
		this.blnDisableClear = true;
		this.blnDisableFilter = true;
		this.blnIsLoading = false;
		this.strChatButtonId = "";
	}

	/**
	 * Handler method for the onsort event fired from the datatable
	 */
	updateColumnSorting(event) {
		this.blnIsLoading = true;
		var strFieldName = event.detail.fieldName;
		var strSortDirection = event.detail.sortDirection;
		this.strSortedBy = strFieldName;
		this.sortedDirection = strSortDirection;
		this.list_FilteredData = this.sortData(strFieldName, strSortDirection);
		this.blnIsLoading = false;
	}

	/**
	 * To sort the data based on the field name and direction
	 */
	sortData(strFieldName, strSortDirection) {
		var data = JSON.parse(JSON.stringify(this.list_FilteredData));
		var keyValue = (a) => {
			return a[strFieldName];
		};
		var isReverse = strSortDirection === "asc" ? 1 : -1;
		data.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : "";
			y = keyValue(y) ? keyValue(y) : "";
			return isReverse * ((x > y) - (y > x));
		});
		return data;
	}

	get priorityOptions() {
		return [
			{ label: '0', value: '0' },
			{ label: '1', value: '1' },
			{ label: '2', value: '2' },
			{ label: '3', value: '3' },
			{ label: '4', value: '4' },
			{ label: '5', value: '5' },
			{ label: '6', value: '6' },
			{ label: '7', value: '7' },
			{ label: '8', value: '8' },
			{ label: '9', value: '9' }
		];
	}

	handleAgentChange(event) {
		this.strAgentId = event.detail.recordId;
		this.blnDisableFilter = false;
	}

	handleButtonChange(event) {
		this.strChatButtonId = event.detail.value;
		this.blnDisableFilter = false;
	}
}