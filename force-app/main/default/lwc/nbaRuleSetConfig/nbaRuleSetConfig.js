import { LightningElement, track } from "lwc";
import getRuleList from "@salesforce/apex/RuleSetController.getRuleSet";
import getRuleSets from "@salesforce/apex/RuleSetController.getRuleSets";
import updateRuleSet from "@salesforce/apex/RuleSetController.updateRuleSets";
import getRecordsFromRule from "@salesforce/apex/RuleSetController.getRecordsFromRuleNew";
import saveRuleSetConfig from "@salesforce/apex/RuleSetController.saveRuleSetConfig";
import queryRecordCount from "@salesforce/apex/RuleSetController.getRecordCount";
import refreshAllRules from "@salesforce/apex/RuleSetController.refreshAllRules";
import createNewRuleSet from "@salesforce/apex/RuleSetController.createNewRuleSet";
import createNewRuleConfig from "@salesforce/apex/RuleSetController.createNewRuleConfig";
import holdOutValidation from "@salesforce/apex/RuleSetController.holdOutValidation";
import checkPerformance from "@salesforce/apex/RuleSetController.checkPerformance";
import validateSOQL from "@salesforce/apex/NBAUserInterfaceController.validateSOQLQuery";
import { displayToast } from "c/utilityService";
import { sendAuraEvent } from "c/utilityService";
import nbaRecordViewSizeLabel from "@salesforce/label/c.NBA_Record_View_Size";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from 'lightning/confirm';

export default class NbaRuleSetConfig extends LightningElement {
	@track list_rules = [];
	@track blnChanged = false;
	@track list_priority = [];
	@track blnLoading = false;
	@track list_TeamNames = [];
	@track strWarningMessage = "Please pick a rule set from the dropdown.";
	@track showMessage = true;
	@track strTeamName = "";
	@track strRuleDescription = "";
	@track blnRuleDetailVisible = false;
	@track blnShowRuleDetail = false;
	@track blnError = false;
	@track blnViewOnlyAccess = false;
	@track strViewOnlyAccessMessage = "You have view only access to this page.";
	@track objVisibleRule = {};
	@track strSelectedTeam = "";
	@track viewModal = false;
	@track list_ModalLeads = [];
	@track list_ModalOpps = [];
	@track viewRulesName = "";
	@track blnModalLeadsAvailable = false;
	@track blnModalOppsAvailable = false;
	@track viewRecordId = "";
	@track nbaRecordViewSizeLabel = nbaRecordViewSizeLabel;
	// list of available user roles for rule set configuration
	@track list_AvailableRoles = [];
	// rule set configuration object
	@track objConfig = {};
	// accordion section open
	@track list_openSections = [];
	// list of selected user roles for rule set configuration
	@track list_SelectedRoles = [];
	// map of selected skills for rule set
	@track map_RuleAndSkills = new Map();
	// list of selected skills for rule set configuration
	@track list_SelectedSkills = [];
	// list of available skills for rule set configuration
	@track list_AvailableSkills = [];
	// boolean flag to toggle on and off to show cheat sheet
	@track blnShowCheatSheet = false;
	// map of standard skills and details
	@track list_Skills = new Map();
	// list of skills for a specific rule
	@track list_RuleSkills = [];
	// list of skills for a specific rule to display on the right panel
	@track list_RuleSkillsToDisplay = [];
	// boolean flag to indicate if skill settings have changed
	blnSkillChanged = false;
	// error message to display respective to skill settings
	errorMessage = null;
	blnMaxRefreshAll = false;
	blnNoRefreshConfig = false;
	blnMaxRefreshAllHelp = false;
	strRefreshAllLabel = '';
	@track viewSkillsModal = false;

	@track list_ViewRecords = [];
	@track blnViewRecordsAvailable = false;

	@track configCreateModalVisible = false;
	@track ruleCreateModalVisible = false;
	abbreviationHelpText =
		'Used to identity each rule set by team abbreviation. The value is suffixed to the Served Up Rule and Served Other Rules field on Serving Object when records are served to the user. The format is "Rule Name" (from NBA Rule Set) & " - " & "Abbreviation" and is limited to 5 characters. This value is also passed to the Task fields when the Task is created for logging a call when applicable.';

	@track ruleConfigNew = {
		Name: "",
		Abbreviation__c: "",
		Team_Skill_Type__c: ""
	};

	@track newRuleSet = {
		name: "",
		cloneRuleSet: "",
		cloneOptions: [],
		title: "Create New Rule Set"
	};
	get objOperatorOptions() {
		return [
			{ label: "AND", value: "AND" },
			{ label: "OR", value: "OR" }
		];
	}

	orgId = "";

	connectedCallback() {
		this.handleLoad();
	}

	handleLoad() {
		// get list of unique ruule sets
		this.blnLoading = true;
		getRuleSets()
			.then((result) => {
				this.orgId = result.strOrgId;
				// if user doesn't have permission to edit access, set view only access to true
				this.blnViewOnlyAccess = !result.blnHasPermissions;
				let list_tempTeamNames = [];
				// populate picklist with unique rule sets
				for (let eachTeam of result.list_TeamNames) {
					let objTeam = {
						label: eachTeam + "",
						value: eachTeam + ""
					};
					list_tempTeamNames.push(objTeam);
				}
				this.list_TeamNames = list_tempTeamNames;

				// populate list of user roles to be displayed on multi select picklist
				for (let eachRole of result.list_UserRoles) {
					this.list_AvailableRoles.push({
						label: eachRole.Name + "",
						value: eachRole.Name + ""
					});
				}
				this.blnLoading = false;
				// if only one team, set the team name and fetch the rules
				let rulePreference = localStorage.getItem("rulePreference_" + this.orgId);
				if (this.list_TeamNames.length == 1) {
					this.strTeamName = this.list_TeamNames[0].value;
					this.objConfig = new Object();
					this.objConfig = {
						Name: this.strTeamName,
						User_Roles__c: ""
					};
					this.strSelectedTeam = this.list_TeamNames[0].value;
					this.fetchTeamRules();
				} else if (rulePreference && result.list_TeamNames.includes(rulePreference)) {
					this.strTeamName = rulePreference;
					this.objConfig = new Object();
					this.objConfig = {
						Name: this.strTeamName,
						User_Roles__c: ""
					};
					this.strSelectedTeam = rulePreference;
					this.fetchTeamRules();
				}
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				this.blnError = true;
				this.strWarningMessage = error?.body?.message;
				this.blnLoading = false;
			});
	}

	handleChange(event) {
		// initialize variables
		this.blnChanged = true;
		let list_tempRules = [];
		let blnPriorityDecrease = false;
		let maxPriority = 0;

		let priority = event.detail.value;
		let ruleId = event.target.dataset.id;

		// map of priority number and rule object
		let priority_map = new Map();
		// map of priority numbers and if they are active
		let priorityActiveMap = new Map();

		for (let eachRule of this.list_rules) {
			priority_map.set(eachRule.Priority__c + "", eachRule);
			priorityActiveMap.set(eachRule.Priority__c + "", eachRule.Is_Active__c);

			if (eachRule.Priority__c > maxPriority) {
				maxPriority = eachRule.Priority__c;
			}
		}

		// two variables of priorities that need to be swapped
		let swap1 = this.list_rules.find((item) => item.Id === ruleId);
		let swapPriority = swap1.Priority__c.toString();

		// getting the rule object of the priority number
		let firstSwap = priority_map.has(priority) ? priority_map.get(priority) : null;
		let secondSwap = priority_map.has(swapPriority) ? priority_map.get(swapPriority) : null;

		if (Number(priority) > Number(swapPriority)) {
			blnPriorityDecrease = true;
		}

		// swapping the priority numbers
		for (let eachRule of this.list_rules) {
			if (eachRule.Id == secondSwap.Id) {
				eachRule.Priority__c = priority;
			}
		}

		// second for loop is for adjusting the priority numbers of other rules
		for (let eachRule of this.list_rules) {
			if (eachRule.Id == secondSwap.Id) {
				continue;
			}
			if (Number(eachRule.Priority__c) == 1 && blnPriorityDecrease) {
				continue;
			}
			if (Number(eachRule.Priority__c) == Number(maxPriority) && !blnPriorityDecrease) {
				continue;
			}
			if (Number(eachRule.Priority__c) <= Number(priority) && Number(eachRule.Priority__c) >= Number(swapPriority) && blnPriorityDecrease) {
				eachRule.Priority__c = eachRule.Priority__c - 1;
			} else if (Number(eachRule.Priority__c) >= Number(priority) && Number(eachRule.Priority__c) <= Number(swapPriority) && !blnPriorityDecrease) {
				eachRule.Priority__c = Number(eachRule.Priority__c) + 1;
			}
		}

		// build a new rule object with the updated priority numbers
		for (let eachRule of this.list_rules) {
			// initialize list variables
			let list_priority_temp = [];
			let list_filter = [];

			// create list of priority numbers that are not the current priority number
			// also do not include priority numbers that are not active
			for (let eachFilter of this.list_priority) {
				let priorityActive = true;
				eachFilter = eachFilter.toString();
				if (priorityActiveMap.has(eachFilter)) {
					priorityActive = priorityActiveMap.get(eachFilter);
				}

				if (eachFilter != eachRule.Priority__c && priorityActive == true) {
					list_filter.push(eachFilter);
				}
			}
			// build values for dropdown
			for (let priority of list_filter) {
				let objPriority = {
					label: priority + "",
					value: priority + ""
				};
				list_priority_temp.push(objPriority);
			}

			// build a new rule object with the updated priority numbers
			let objRule = {
				Id: eachRule.Id,
				Name: eachRule.Name,
				Rule_Name__c: eachRule.Rule_Name__c,
				Description__c: eachRule.Description__c,
				Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c,
				Is_Active__c: eachRule.Is_Active__c,
				Priority__c: eachRule.Priority__c,
				Weighting__c: eachRule.Weighting__c,
				List_Priority__c: list_priority_temp,
				List_Chosen__c: null,
				CreatedBy: eachRule.CreatedBy,
				CreatedDate: eachRule.CreatedDate,
				LastModifiedBy: eachRule.LastModifiedBy,
				LastModifiedDate: eachRule.LastModifiedDate
			};
			// add to temp rules
			list_tempRules.push(objRule);
		}

		// add to list of rule
		this.list_rules = list_tempRules;

		// reset all combo box elements
		this.template.querySelectorAll("lightning-combobox").forEach((each) => {
			if (each.label != "Pick a rule set") {
				each.value = null;
			}
		});
	}

	// Handler when user clicks "Reset" button - We query and fetch the rules again
	handleCancel(event) {
		this.blnChanged = false;
		//if button is clicked on skill section, unset skill changed.
		if (event.target.dataset.event == "skills") {
			this.blnSkillChanged = false;
		}
		this.fetchTeamRules();
	}

	// Handler when user clicks "Save" button - We update the rules
	handleSave(event) {
		this.blnLoading = true;
		let eventName = event.target.dataset.event;
		let list_RulesToSend = [];
		// build list of rules with hold out percentage
		let list_HoldOutRules = [];
		// if button is clicked on skill section, send for skill update.
		if (eventName == "skills") {
			this.handleUpdateRule();
			return;
		} else {
			// build list of rules with hold out percentage
			for (let eachRule of this.list_rules) {
				if (eachRule.Hold_Out_Percentage__c && eachRule.Hold_Out_Percentage__c > 0) {
					list_HoldOutRules.push({
						Id: eachRule.Id,
						Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c
					});
				}
			}
			// reset error message on hold out percentage fields
			this.list_rules.forEach((eachRule) => {
				let holdoutCmp = this.template.querySelector("lightning-input[data-holdout=" + eachRule.Id + "]");
				holdoutCmp.setCustomValidity("");
				holdoutCmp.reportValidity();
			});

			// check if the rule inputs are valid
			let blnIsValid = true;
			const allValid = [...this.template.querySelectorAll("lightning-input")].reduce((validSoFar, inputCmp) => {
				if (!inputCmp.reportValidity()) blnIsValid = false;
				return validSoFar;
			}, true);

			if (!blnIsValid) {
				displayToast(this, "Please check the error messages on the hold out fields", "", "error", "");
				this.blnLoading = false;
				return;
			}

			for (let eachRule of this.list_rules) {
				let objRule = {
					Id: eachRule.Id,
					Priority__c: eachRule.Priority__c,
					Is_Active__c: eachRule.Is_Active__c,
					Weighting__c: eachRule.Weighting__c,
					Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c,
					NBA_Rule_Set_Configuration__c: this.objConfig.Id
				};
				list_RulesToSend.push(objRule);
			}
		}
		// if there are rules with hold out percentage, validate them
		if (list_HoldOutRules.length > 0) {
			// send list of rules to check all serving objects have a valid hold out percentage
			holdOutValidation({
				list_Rules: list_HoldOutRules
			})
				.then((result) => {
					if (result.blnIsSuccess) {
						let holdOutError = false;
						if (result.map_HoldOutErrors) {
							// if there are errors - higlight the error fields and stop save
							list_HoldOutRules.forEach((eachRule) => {
								let holdoutCmp = this.template.querySelector("lightning-input[data-holdout=" + eachRule.Id + "]");
								let error = result.map_HoldOutErrors[eachRule.Id];
								if (error) {
									holdoutCmp.setCustomValidity(error);
									holdoutCmp.reportValidity();
									holdOutError = true;
								}
							});
							if (!holdOutError) {
								// if there are no errors - save rule sets
								this.saveRuleSets(list_RulesToSend);
							} else {
								displayToast(this, "Please check the error messages on the hold out fields.", "", "error", "");
							}
						} else {
							this.saveRuleSets(list_RulesToSend);
						}
					} else {
						// show the right error message
						displayToast(this, "Error in validating hold out field", "Error Reason: " + result.strMessage, "error", "");
					}
					this.blnLoading = false;
				})
				.catch((error) => {
					this.error = error;
					displayToast(this, "Error in updating preferences", "Error Reason: " + error?.body?.message, "error", "");
					this.blnLoading = false;
				});
		} else {
			this.saveRuleSets(list_RulesToSend);
		}
	}

	saveRuleSets(list_RulesToSend) {
		// apex method to update the rules
		updateRuleSet({
			list_Rules: list_RulesToSend,
			objRuleWrapper: null
		})
			.then((result) => {
				if (result.blnIsSuccess) {
					displayToast(this, "Preferences saved successfully!", "", "success", "");
					// fetch the rules and order by priority
					this.fetchTeamRules();
					this.blnRuleDetailVisible = false;
					this.blnChanged = false;
				} else {
					// show the right error message
					displayToast(this, "Error in updating preferences", "Error Reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.error = error;
				displayToast(this, "Error in updating preferences", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});

	}
	//Validate skill settings before saving, checks for duplicate skills and invalid skill levels
	validateSkillSetings() {
		let validity = true;
		//Check standard validity of operator and skill level fields
		if (this.blnChanged && this.list_RuleSkillsToDisplay.length) {
			this.template.querySelectorAll("lightning-input-field").forEach(function (element) {
				validity = validity && element.reportValidity();
			}, this);
		}
		//If valid so far, check for skill level formatting and uniqueness
		if (validity) {
			for (let element of this.list_RuleSkillsToDisplay) {
				let operator = element.Operator__c;
				let skillLevel = element.Skill_Level__c;
				if (skillLevel != null) {
					if (operator != null) {
						let levelValidity = true;
						// if operator is = or !=, check for comma separated values and uniqueness
						if (operator == "=" || operator == "!=") {
							levelValidity = /^\s*(0|1|2|3|4|5|6|7|8|9|10)(\s*,\s*(0|1|2|3|4|5|6|7|8|9|10))*\s*$/g.test(skillLevel);
							if (!levelValidity) {
								validity = false;
								this.errorMessage = "Skill level not formatted correctly. Please ensure to enter numbers only between 0 to 10 separated by a comma.";
								break;
							}
							// check for uniqueness
							let skillLevels = skillLevel.split(",");
							skillLevels.forEach((o, i, a) => (a[i] = a[i].trim()));
							levelValidity = new Set(skillLevels).size === skillLevels.length;
							if (!levelValidity) {
								validity = false;
								this.errorMessage = "Skill level not formatted correctly. Please ensure to enter numbers only between 0 to 10 separated by a comma. Numbers should be unique.";
								break;
							}
						} else {
							// if operator is > or <, check for single value and validity
							levelValidity = /^(0|1|2|3|4|5|6|7|8|9|10)$/g.test(skillLevel);
							if (!levelValidity) {
								validity = false;
								this.errorMessage = 'Please update skill level format to enter a number between 0 and 10. If the operator is not "=" or "!=", only one value is can be entered.';
								break;
							}
						}
					} else {
						// if skill level is set, operator cannot be none
						validity = false;
						this.errorMessage = "Operator cannot be none if skill level is set";
						break;
					}
					// remove spaces from skill level and set it back
					let skillLevels = skillLevel.split(",");
					skillLevels.forEach((o, i, a) => (a[i] = a[i].trim()));
					element.Skill_Level__c = skillLevels.join(",");
				} else if (operator != null) {
					// if operator is set, skill level cannot be none
					validity = false;
					this.errorMessage = "Skill level cannot be none if operator is set";
					break;
				}
			}
		} else {
			this.errorMessage = "Please check the error messages on the skill setting fields";
		}
		return validity;
	}

	// Handler when user changes team names - We query rules for specific team
	handleChangeTeam(event) {
		this.strTeamName = event.detail.value;
		this.objConfig = new Object();
		this.objConfig = {
			Name: this.strTeamName,
			User_Roles__c: ""
		};
		localStorage.setItem("rulePreference_" + this.orgId, this.strTeamName);
		this.fetchTeamRules();
	}

	// Fetches rules for specific team
	fetchTeamRules() {
		// reset all variables
		this.blnRuleDetailVisible = false;
		this.blnChanged = false;
		this.blnSkillChanged = false;
		this.list_rules = [];
		this.blnLoading = true;
		this.list_priority = [];
		this.blnMaxRefreshAll = false;
		this.blnNoRefreshConfig = false;
		this.blnMaxRefreshAllHelp = false;
		this.strRefreshAllLabel = '';
		// apex method to fetch rules
		getRuleList({
			strTeamName: this.strTeamName
		})
			.then((result) => {
				// initalize variables
				this.blnLoading = false;
				let list_TempRules = [];
				let priorityActiveMap = new Map();
				this.objConfig = result.objConfig;
				this.blnNoRefreshConfig = this.objConfig.Available_Refreshes_Per_Day__c === undefined ? true : false;
				this.blnMaxRefreshAll = (this.objConfig.Refreshes_Triggered_Today__c >= this.objConfig.Available_Refreshes_Per_Day__c || this.objConfig.Available_Refreshes_Per_Day__c === undefined || this.objConfig.Refreshes_Triggered_Today__c === undefined) ? true : false;
				if (!this.blnNoRefreshConfig) {
					this.blnMaxRefreshAllHelp = this.objConfig.Refreshes_Triggered_Today__c >= this.objConfig.Available_Refreshes_Per_Day__c ? true : false;
				}
				let intRefreshAmount = (this.objConfig.Available_Refreshes_Per_Day__c - this.objConfig.Refreshes_Triggered_Today__c);
				let strRefreshAmount = Number.isNaN(intRefreshAmount) ? '' : ' (' + intRefreshAmount + ')';
				this.strRefreshAllLabel = 'Refresh All Rules' + strRefreshAmount;
				// build a map of priority and is_active
				for (let eachRule of result.list_Rules) {
					this.list_priority.push(eachRule.Priority__c);
					priorityActiveMap.set(eachRule.Priority__c + "", eachRule.Is_Active__c);
				}

				this.map_RuleAndSkills = new Map();
				// build a active rules first
				for (let eachRule of result.list_Rules) {
					if (eachRule.Is_Active__c == true) {
						list_TempRules.push(this.buildRule(eachRule, priorityActiveMap));
					}
					// build a map of rule and skills
					if (eachRule.hasOwnProperty("NBA_Rule_Set_Skills__r") && eachRule.NBA_Rule_Set_Skills__r.length) {
						if (eachRule.Rule_Skills_Criteria_Logic__c) {
							// sort the skills based on order, order is stored as part of json string on rule
							let ruleSkillCriteria = JSON.parse(eachRule.Rule_Skills_Criteria_Logic__c);
							for (let eachSkill of eachRule.NBA_Rule_Set_Skills__r) {
								for (let ruleSkill of ruleSkillCriteria.list_RuleSkills) {
									if (ruleSkill.Name == eachSkill.Name) {
										eachSkill.Order = ruleSkill.Order;
									}
								}
							}
							eachRule.NBA_Rule_Set_Skills__r.sort((a, b) => Number(a.Order) - Number(b.Order));
						}
						this.map_RuleAndSkills.set(eachRule.Id, eachRule.NBA_Rule_Set_Skills__r);
					}
				}
				// build list of inactive rules in the end
				for (let eachRule of result.list_Rules) {
					if (eachRule.Is_Active__c == false) {
						list_TempRules.push(this.buildRule(eachRule, priorityActiveMap));
					}
				}
				// set rules to the track list variable
				this.list_rules = list_TempRules;
				// show list of selected user roles
				this.list_SelectedRoles = [];
				if (result.objConfig && result.objConfig.User_Roles__c) {
					let list_Roles = result.objConfig.User_Roles__c.split(",");
					// alphabetically sort the roles on load
					list_Roles = list_Roles.sort(function (a, b) {
						return a.toLowerCase().localeCompare(b.toLowerCase());
					});
					this.list_SelectedRoles = list_Roles;
				}
				// show list of available skills from standard skills available for skill type on nba configuration record
				this.list_AvailableSkills = [];
				if (result.list_Skills) {
					for (let eachSkill of result.list_Skills) {
						this.list_AvailableSkills.push({
							label: eachSkill.MasterLabel + "",
							value: eachSkill.MasterLabel + ""
						});
						this.list_Skills.set(eachSkill.MasterLabel, eachSkill);
					}
				}

				this.showMessage = false;
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in fetching rules", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}

	// Build rule object
	buildRule(eachRule, priorityActiveMap) {
		// build a filtered list of priority
		let list_filter = this.list_priority.filter((item) => item !== eachRule.Priority__c);
		let list_priority_temp = [];

		for (let priority of list_filter) {
			// build object for dropdown
			let objPriority = {
				label: priority + "",
				value: priority + ""
			};

			// add to the list only if the priority is active
			let priorityActive = true;
			priority = priority.toString();
			if (priorityActiveMap.has(priority)) {
				priorityActive = priorityActiveMap.get(priority);
			}

			if (priorityActive == true) {
				list_priority_temp.push(objPriority);
			}
		}

		let ruleSkillCriteria;
		if (eachRule.hasOwnProperty("NBA_Rule_Set_Skills__r") && eachRule.NBA_Rule_Set_Skills__r.length) {
			// sort the skills based on order, order is stored as part of json string on rule if available
			if (eachRule.Rule_Skills_Criteria_Logic__c) {
				ruleSkillCriteria = JSON.parse(eachRule.Rule_Skills_Criteria_Logic__c);
				ruleSkillCriteria.list_RuleSkills.sort((a, b) => Number(a.Order) - Number(b.Order));
			} else {
				ruleSkillCriteria = { list_RuleSkills: eachRule.NBA_Rule_Set_Skills__r };
				let ruleSkillCriteriaObj = JSON.stringify(ruleSkillCriteria);
				ruleSkillCriteria = JSON.parse(ruleSkillCriteriaObj);
			}
		}
		// build list of skills used
		let list_SkillsUsed = [];
		if (eachRule.NBA_Rule_Set_Skills__r) {
			for (let i = 0; i < ruleSkillCriteria.list_RuleSkills.length; i++) {
				let eachSkill = ruleSkillCriteria.list_RuleSkills[i];
				let strName = eachSkill.Name;
				let strOperator = eachSkill.Operator__c;
				let strLevel = eachSkill.Skill_Level__c;
				let strSkillDisplay = "";
				if (!strOperator) {
					strSkillDisplay = strName;
				} else {
					strSkillDisplay = strName + " " + strOperator + " " + strLevel;
				}
				if (i != ruleSkillCriteria.list_RuleSkills.length - 1) {
					strSkillDisplay += "\n" + ruleSkillCriteria.logic;
				}
				list_SkillsUsed.push(strSkillDisplay);
			}
		}
		// build rule object and return back
		let objRule = {
			Id: eachRule.Id,
			Name: eachRule.Name,
			Rule_Name__c: eachRule.Rule_Name__c,
			Description__c: eachRule.Description__c,
			Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c,
			Is_Active__c: eachRule.Is_Active__c,
			Priority__c: eachRule.Priority__c,
			Weighting__c: eachRule.Weighting__c,
			List_Priority__c: list_priority_temp,
			CreatedBy: eachRule.CreatedBy.Name,
			CreatedDate: Date.parse(eachRule.CreatedDate),
			LastModifiedBy: eachRule.Rule_Last_Updated_By__r.Name,
			LastModifiedDate: Date.parse(eachRule.Rule_Last_Updated_Time__c),
			List_Chosen__c: "",
			Refresh_Date_Available__c: eachRule.Last_Refreshed_Date__c ? eachRule.Last_Refreshed_Date__c : false,
			Last_Zero_Record_Run_Date_Available__c: eachRule.Last_Ran_With_Zero_Records__c ? eachRule.Last_Ran_With_Zero_Records__c : false,
			Last_Ran_With_Zero_Records__c: eachRule.Last_Ran_With_Zero_Records__c ? eachRule.Last_Ran_With_Zero_Records__c : "Not available",
			Last_Refreshed_Date__c: eachRule.Last_Refreshed_Date__c ? eachRule.Last_Refreshed_Date__c : "Not refreshed yet",
			Skills_Used__c: list_SkillsUsed,
			Are_Skills_Used__c: list_SkillsUsed.length > 0 ? true : false,
			RuleSkillsCriteriaLogic: ruleSkillCriteria ? ruleSkillCriteria.criteriaLogic : null,
			RuleSkillsLogic: ruleSkillCriteria?.logic ? ruleSkillCriteria.logic : "OR",
			NBA_Rule_Criteria__r: eachRule.NBA_Rule_Criteria__r
		};

		// show message if there are no criteria added
		if (eachRule.NBA_Rule_Criteria__r) {
			// if criteria added - show the record count or show message that criteria is available but not refreshed yet
			if (eachRule.Record_Count__c && !eachRule.Record_Count__c.includes("No criteria found")) {
				objRule.Record_Count__c = eachRule.Record_Count__c.split("\n");
			} else {
				objRule.Record_Count__c = ["Criteria available but not refreshed yet"];
			}
		} else {
			objRule.Record_Count__c = ["No criteria found"];
		}

		return objRule;
	}

	// Handler when user activates or deactivates a rule
	// Handler when user activates or deactivates a rule
	async handleActiveChange(event) {
		// initialize variables
		this.blnChanged = true;
		let list_tempRules = [];
		let list_tempRules1 = [];
		let priorityActiveMap = new Map();
		let priority_map = new Map();
		let inactivePriorty = 0;
		let highestActivePriority = 0;
		let blnInactive = false;
		let activePriority = 0;
		let blnActive = false;
		let adjustOtherRules = true;
		let blnPoorPerformance = false;
		// creating local variables to store event data
		let idRuleSet;
		let blnTargetChecked = event.target.checked;

		for (let eachRule of this.list_rules) {
			// find the highest active priority - when user deactives a rule - we will need to swap with highest active priority rule
			if (eachRule.Is_Active__c == true && eachRule.Priority__c > highestActivePriority) {
				highestActivePriority = eachRule.Priority__c;
			}

			if (eachRule.Id == event.target.dataset.id) {
				idRuleSet = event.target.dataset.id;
				if (event.target.checked) {
					activePriority = eachRule.Priority__c;
					blnActive = true;
				}
			}

			if (eachRule.Id == event.target.dataset.id) {
				if (event.target.checked) {
					// if activating a rule - check if the rule has poor performance
					this.blnLoading = true;
					const result = await checkPerformance({ idRuleSet: eachRule.Id });
					this.blnLoading = false;
					result.forEach((eachCriteria) => {
						if (!eachCriteria.Performance__c || eachCriteria.Performance__c == "Poor") {
							blnPoorPerformance = true;
						}
					});
					// if the rule has poor performance - show a warning message and do not activate the rule
					if (blnPoorPerformance) {
						displayToast(
							this,
							"Rule Performance is Poor and Rule cannot be activated. Please review and adjust the Rule Criteria as needed and rerun Performance until Excellent or Good for each serving object.",
							"",
							"warning",
							""
						);
						let checkboxCmp = this.template.querySelector('[data-checkbox="' + eachRule.Id + '"]');
						if (checkboxCmp) {
							checkboxCmp.checked = false;
						}
					}
				}
			}
		}
		// if a rule has poor performance - do not activate rule and reorder priority
		if (blnPoorPerformance) {
			return;
		}

		for (let eachRule of this.list_rules) {
			// set is_active flag
			if (eachRule.Id == idRuleSet) {
				eachRule.Is_Active__c = blnTargetChecked;
				// find the inactive priority rule
				if (eachRule.Is_Active__c == false) {
					inactivePriorty = eachRule.Priority__c;
					// flag to indicate if user deactivates a rule
					blnInactive = true;
				}  else {
					// do not adjust the priority of other rules if you are activating the rule with highest priority
					if (Number(eachRule.Priority__c) == Number((highestActivePriority + 1))) {
						adjustOtherRules = false;
					}
					eachRule.Priority__c = highestActivePriority + 1;
				}
			} else if (blnActive && eachRule.Is_Active__c == false && adjustOtherRules == true && eachRule.Priority__c < activePriority) {
				// adjust the priority of other rules if you are activating a rule - priority of remaining rules need to be incremented by 1
				eachRule.Priority__c = eachRule.Priority__c + 1;
			}
		
			// build different maps used for data processing
			list_tempRules1.push(eachRule);
			priorityActiveMap.set(eachRule.Priority__c + "", eachRule.Is_Active__c);
			priority_map.set(eachRule.Priority__c + "", eachRule);
		}
		// build list of active rules first
		for (let eachRule of list_tempRules1) {
			if (eachRule.Is_Active__c == true) {
				list_tempRules.push(this.initializeRule(eachRule, priorityActiveMap));
			}
		}

		// build list of inactive rules in the end
		for (let eachRule of list_tempRules1) {
			if (eachRule.Is_Active__c == false) {
				list_tempRules.push(this.initializeRule(eachRule, priorityActiveMap));
			}
		}

		// if user deactivates a rule - change the priority of inactive rule to highest active priority and adjust other rules priority
		if (blnInactive == true) {
			let firstSwap = {};
			let secondSwap = {};

			// find the first and second rule to swap
			if (inactivePriorty != 0 && highestActivePriority != 0) {
				firstSwap = priority_map.has(inactivePriorty.toString()) ? priority_map.get(inactivePriorty.toString()) : null;
				secondSwap = priority_map.has(highestActivePriority.toString()) ? priority_map.get(highestActivePriority.toString()) : null;
			}

			// build the priority map again
			priorityActiveMap = new Map();

			for (let eachRule of list_tempRules) {
				// swap the inactive rule with highest active priority rule
				if (eachRule.Id == firstSwap.Id) {
					eachRule.Priority__c = secondSwap.Priority__c;
				} else if (eachRule.Priority__c > inactivePriorty && eachRule.Is_Active__c == true) {
					eachRule.Priority__c = eachRule.Priority__c - 1;
				}
				priorityActiveMap.set(eachRule.Priority__c + "", eachRule.Is_Active__c);
			}

			// ret-build list of rules, priority dropdown & adjust priority of other rules
			for (let eachRule of list_tempRules) {
				let list_filter = [];
				let list_priority_temp = [];

				for (let eachFilter of this.list_priority) {
					let priorityActive = true;
					eachFilter = eachFilter.toString();
					if (priorityActiveMap.has(eachFilter)) {
						priorityActive = priorityActiveMap.get(eachFilter);
					}

					if (eachFilter != eachRule.Priority__c && priorityActive == true && eachFilter != secondSwap.Priority__c) {
						list_filter.push(eachFilter);
					}
				}

				for (let priority of list_filter) {
					let objPriority = {
						label: priority + "",
						value: priority + ""
					};
					list_priority_temp.push(objPriority);
				}
				eachRule.List_Priority__c = list_priority_temp;
			}
		}
		this.list_rules = list_tempRules;
	}

	// initialize a new rule object
	initializeRule(eachRule, priorityActiveMap) {
		// initalize variables
		let list_filter = [];
		let list_priority_temp = [];

		// build the priority dropdown
		for (let eachFilter of this.list_priority) {
			let priorityActive = true;
			eachFilter = eachFilter.toString();
			if (priorityActiveMap.has(eachFilter)) {
				priorityActive = priorityActiveMap.get(eachFilter);
			}

			if (eachFilter != eachRule.Priority__c && priorityActive == true) {
				list_filter.push(eachFilter);
			}
		}

		for (let priority of list_filter) {
			let objPriority = {
				label: priority + "",
				value: priority + ""
			};
			list_priority_temp.push(objPriority);
		}

		// build the rule object and return
		let objRule = {
			Id: eachRule.Id,
			Name: eachRule.Name,
			Rule_Name__c: eachRule.Rule_Name__c,
			Description__c: eachRule.Description__c,
			Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c,
			Is_Active__c: eachRule.Is_Active__c,
			Priority__c: eachRule.Priority__c,
			Weighting__c: eachRule.Weighting__c,
			List_Priority__c: list_priority_temp,
			List_Chosen__c: null,
			CreatedBy: eachRule.CreatedBy,
			CreatedDate: eachRule.CreatedDate,
			LastModifiedBy: eachRule.LastModifiedBy,
			LastModifiedDate: eachRule.LastModifiedDate,
			Record_Count__c: eachRule.Record_Count__c,
			Refresh_Date_Available__c: eachRule.Last_Refreshed_Date__c ? eachRule.Last_Refreshed_Date__c : false,
			Last_Zero_Record_Run_Date_Available__c: eachRule.Last_Ran_With_Zero_Records__c ? eachRule.Last_Ran_With_Zero_Records__c : false,
			Last_Ran_With_Zero_Records__c: eachRule.Last_Ran_With_Zero_Records__c ? eachRule.Last_Ran_With_Zero_Records__c : "Not available",
			Last_Refreshed_Date__c: eachRule.Last_Refreshed_Date__c ? eachRule.Last_Refreshed_Date__c : "Not refreshed yet",
			Skills_Used__c: eachRule.Skills_Used__c,
			Are_Skills_Used__c: eachRule.Are_Skills_Used__c
		};
		return objRule;
	}
	// Handler when user clicks "View Rules" button
	handleViewRules(event) {
		sendAuraEvent(this, event.target.dataset.id, "opensubtab");
	}

	// Handler when slider value changes
	handleSliderChange(event) {
		this.blnChanged = true;
		for (let eachRule of this.list_rules) {
			if (eachRule.Id == event.target.dataset.id) {
				eachRule.Weighting__c = event.detail.value;
				break;
			}
		}
	}

	// Handler when skill operator/level value changes
	handleSkillChange(event) {
		let list_RuleSkillsToDisplayTemp = [];
		for (let element of this.list_RuleSkillsToDisplay) {
			let tempElement = Object.assign({}, element);
			//for the skill being changed
			if (event.target.dataset.skill == element.Name) {
				// if operator is changed, set the operator
				if (event.target.dataset.field == "operator" && event.detail.value != element.Operator__c) {
					tempElement.Operator__c = event.detail.value ? event.detail.value : null;
					this.blnSkillChanged = true;
				}
				// if skill level is changed, set the skill level
				else if (event.target.dataset.field == "level" && event.detail.value != element.Skill_Level__c) {
					tempElement.Skill_Level__c = event.detail.value.length ? event.detail.value : null;
					this.blnSkillChanged = true;
				}
			}
			list_RuleSkillsToDisplayTemp.push(tempElement);
		}
		this.list_RuleSkillsToDisplay = list_RuleSkillsToDisplayTemp;
	}

	// Handler when rule detail change
	handleViewRuleChange(event) {
		let value = event.detail.value;
		this.objVisibleRule[event.target.dataset.field] = value;
	}

	// sort rules in ascending order of priority
	sort() {
		this.list_rules.sort((a, b) => (a.Priority__c > b.Priority__c ? 1 : b.Priority__c > a.Priority__c ? -1 : 0));
	}

	handleClickRule(event) {
		sendAuraEvent(this, event.target.dataset.id, "openrecord");
	}

	handleViewRecords(event) {
		let ruleSetId = event.target.dataset.id;
		this.viewRecordId = ruleSetId;
		this.blnLoading = true;
		this.viewModal = false;
		// apex method to fetch leads and opportunities
		getRecordsFromRule({
			idRecordId: ruleSetId
		})
			.then((result) => {
				this.viewRulesName = result.objRuleSet.Rule_Name__c;
				if (result.blnIsSuccess) {
					if (result.list_ViewRecords.length > 0) {
						this.list_ViewRecords = result.list_ViewRecords;
						this.blnViewRecordsAvailable = true;
						this.list_ViewRecords.forEach((eachRecord) => {
							let list_Rows = [];
							eachRecord.list_SObjects.forEach((eachSObject) => {
								let list_Fields = [];
								eachSObject = Object.fromEntries(Object.entries(eachSObject).map(([key, value]) => [key.toLowerCase(), value]));

								eachRecord.list_Columns.forEach((eachColumn) => {
									eachColumn = eachColumn.toLowerCase();
									let value = "";
									let id = "";
									if (!eachColumn.includes(".")) {
										eachSObject[eachColumn] = eachSObject[eachColumn] ? eachSObject[eachColumn] : "";
										value = eachSObject[eachColumn.toLowerCase()];
										if (eachColumn == "name") {
											id = eachSObject["id"];
										}
									} else {
										let arr = eachColumn.split(".");
										let counter = 0;
										let tempSObject = eachSObject;
										arr.forEach((each) => {
											// else form the json object
											if (counter != arr.length - 1) {
												tempSObject[each] = tempSObject[each] ? tempSObject[each] : {};
												tempSObject = tempSObject[each];
												tempSObject = Object.fromEntries(Object.entries(tempSObject).map(([key, value]) => [key.toLowerCase(), value]));
												counter = counter + 1;
											}
										});
										tempSObject = Object.fromEntries(Object.entries(tempSObject).map(([key, value]) => [key.toLowerCase(), value]));
										let field = arr[arr.length - 1].toLowerCase();
										value = tempSObject[field];
										if (field == "name") {
											id = tempSObject["id"];
										}
									}
									let dateTimeField = false;
									if (value) {
										const dtmRegex = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
										dateTimeField = dtmRegex.test(value);
									}
									list_Fields.push({
										label: eachColumn,
										value: value,
										id: id,
										isLink: id ? true : false,
										isDateTime: dateTimeField
									});
								});
								list_Rows.push({
									Id: eachSObject.Id,
									list_Fields: list_Fields
								});
							});
							eachRecord.list_Rows = list_Rows;
						});
					} else {
						this.blnViewRecordsAvailable = false;
						this.list_ViewRecords = [];
					}
					this.viewModal = true;
				} else {
					displayToast(this, "Error in viewing records", "Error reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in viewing records", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}

	handleModalCancel(event) {
		this.viewModal = false;
	}

	handleOpenRecord(event) {
		sendAuraEvent(this, event.target.dataset.id, "openrecord");
	}

	// Handler when user clicks "Save" button - We update the Rule Set Config
	handleConfigSave() {
		this.blnLoading = true;
		// apex method to update the rule set configuration record
		saveRuleSetConfig({
			strTeamName: this.objConfig.Name,
			strUserRole: this.objConfig.User_Roles__c
		})
			.then((result) => {
				if (result.blnIsSuccess) {
					// If successful response - show toast notification and hyperlink to the record
					let objConfig = result.objConfig;
					const event = new ShowToastEvent({
						title: "Success!",
						variant: "success",
						mode: "dismissable",
						message: "{0} configuration saved successfully!",
						messageData: [
							{
								url: result.strBaseURL + "/" + objConfig.Id,
								label: objConfig.Name
							}
						]
					});

					// alphabetically sort the roles after save
					if (result.objConfig && result.objConfig.User_Roles__c) {
						let list_Roles = result.objConfig.User_Roles__c.split(",");
						list_Roles = list_Roles.sort(function (a, b) {
							return a.toLowerCase().localeCompare(b.toLowerCase());
						});
						this.list_SelectedRoles = list_Roles;
					}

					this.dispatchEvent(event);
					// hide the accordion after successfully saving the configuration
					this.handleAccordionCancel();
				} else {
					displayToast(this, "Error in saving configuration", "Error reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in saving configuration", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}
	// handler when user changes user role
	handleUserRoleChange(event) {
		let value = event.detail.value;
		if (event.target.dataset.field == "User_Roles__c") {
			value = String(event.detail.value);
		}
		this.objConfig[event.target.dataset.field] = value;
	}

	// handler when user adds/removes/rearranges skills to/from a rule
	handleRuleSkillChange(event) {
		let value = event.detail.value;
		let list_TempRuleSkills = [];
		let list_TempRuleSkillsDisplay = [];
		let map_ExistingRulesDisplay = new Map();
		let list_originalDisplay = [...this.list_RuleSkillsToDisplay];
		for (let displayedSkill of this.list_RuleSkillsToDisplay) {
			let tempSkill = Object.assign({}, displayedSkill);
			map_ExistingRulesDisplay.set(displayedSkill.Skill_Id__c, tempSkill);
		}
		let criteriaLogicCmp = this.template.querySelector('[data-uniqueid="RuleSkillsCriteriaLogic"]');

		// if rule is removed, do not add to diplay list, re-decide order and update criteria logic
		if (value.length < this.list_SelectedSkills.length) {
			for (let element of this.list_RuleSkills) {
				if (!value.includes(element.skill.Name)) {
					if (!element.action == "new") {
						element.action = "delete";
						list_TempRuleSkills.push(element);
					}
				} else {
					if (map_ExistingRulesDisplay.has(element.skill.Skill_Id__c)) {
						list_TempRuleSkillsDisplay.push(map_ExistingRulesDisplay.get(element.skill.Skill_Id__c));
					} else {
						list_TempRuleSkillsDisplay.push(element.skill);
					}
					list_TempRuleSkills.push(element);
				}
			}
			let orderCounter = "1";
			let list_TempRuleSkillsDisplayMem = [...list_TempRuleSkillsDisplay];
			list_TempRuleSkillsDisplay = [];
			for (let element of value) {
				for (let skill of list_TempRuleSkillsDisplayMem) {
					if (skill.Name == element) {
						skill.Order = orderCounter;
						orderCounter = (Number(orderCounter) + 1).toString();
						list_TempRuleSkillsDisplay.push(skill);
					}
				}
			}
			if (list_TempRuleSkillsDisplay.length == 1) {
				this.objVisibleRule.RuleSkillsCriteriaLogic = "1";
				criteriaLogicCmp.setCustomValidity("");
				criteriaLogicCmp.reportValidity();
			} else if (list_TempRuleSkillsDisplay.length == 0) {
				this.objVisibleRule.RuleSkillsCriteriaLogic = null;
				criteriaLogicCmp.setCustomValidity("");
				criteriaLogicCmp.reportValidity();
			} else {
				let criteriaLogic = "";
				for (let i = 0; i < list_TempRuleSkillsDisplay.length; i++) {
					let skill = list_TempRuleSkillsDisplay[i];
					if (i == list_TempRuleSkillsDisplay.length - 1) {
						criteriaLogic += skill.Order;
					} else {
						criteriaLogic += skill.Order + " " + this.objVisibleRule.RuleSkillsLogic + " ";
					}
				}
				this.objVisibleRule.RuleSkillsCriteriaLogic = criteriaLogic;
			}
		}
		// if rule is being added, add to display list, re-decide order and update criteria logic
		else if (value.length > this.list_SelectedSkills.length) {
			let skillExists = false;
			let logicCmp = this.template.querySelector('[data-uniqueid="RuleSkillsLogic"]');
			if (!logicCmp.checkValidity() && !this.objVisibleRule.RuleSkillsCriteriaLogic) {
				logicCmp.value = this.objVisibleRule.RuleSkillsLogic;
			}
			logicCmp.setCustomValidity("");
			logicCmp.reportValidity();
			for (let element of value) {
				if (!this.list_SelectedSkills.includes(element)) {
					for (let ruleSkill of this.list_RuleSkills) {
						if (ruleSkill.skill.Name == element) {
							ruleSkill.action = "none";
							ruleSkill.skill.Skill_Level__c = 0;
							skillExists = true;
						}
						list_TempRuleSkills.push(ruleSkill);
						if (map_ExistingRulesDisplay.has(ruleSkill.skill.Skill_Id__c)) {
							list_TempRuleSkillsDisplay.push(map_ExistingRulesDisplay.get(ruleSkill.skill.Skill_Id__c));
						} else {
							list_TempRuleSkillsDisplay.push(ruleSkill.skill);
						}
					}
					if (!skillExists) {
						let skill = this.list_Skills.get(element);
						let tempSkill = { NBA_Rule_Set__c: this.objVisibleRule.Id, Name: skill.MasterLabel, Skill_Id__c: skill.Id, Order: (list_TempRuleSkillsDisplay.length + 1).toString() };
						list_TempRuleSkills.push({ skill: tempSkill, action: "new" });
						list_TempRuleSkillsDisplay.push(tempSkill);
						if (list_TempRuleSkillsDisplay.length == 1) {
							this.objVisibleRule.RuleSkillsCriteriaLogic = "1";
						} else {
							this.objVisibleRule.RuleSkillsCriteriaLogic =
								this.objVisibleRule.RuleSkillsCriteriaLogic + " " + this.objVisibleRule.RuleSkillsLogic + " " + list_TempRuleSkillsDisplay.length;
						}
					}
				}
			}
		} else {
			// if rule is rearranged, re-decide display order
			let orderCounter = "1";
			for (let i = 0; i < value.length; i++) {
				let element = value[i];
				for (let [key, item] of map_ExistingRulesDisplay) {
					if (item.Name == element) {
						item.Order = orderCounter;
						orderCounter = (Number(orderCounter) + 1).toString();
						list_TempRuleSkillsDisplay.push(item);
					}
				}
			}
			list_TempRuleSkills = this.list_RuleSkills;
		}
		this.list_RuleSkillsToDisplay = list_TempRuleSkillsDisplay;
		this.list_RuleSkills = list_TempRuleSkills;
		this.blnSkillChanged = true;

		//updated selected skills list
		let list_SkillNames = [];
		if (value.length) {
			for (let eachSkill of value) {
				list_SkillNames.push(eachSkill);
			}
		}
		this.list_SelectedSkills = list_SkillNames;
	}

	handleRuleSkillCriteriaChange(event) {
		let selectedAttribute = event.target.dataset.attribute;
		// if logic is changed from OR to AND or vice-versa, update the criteria logic to reflect the change
		if (selectedAttribute == "RuleSkillsLogic") {
			let logicCmp = this.template.querySelector('[data-uniqueid="RuleSkillsLogic"]');
			logicCmp.setCustomValidity("");
			logicCmp.reportValidity();
			if (!this.objVisibleRule.RuleSkillsCriteriaLogic) {
				logicCmp.setCustomValidity("Please add one or more skills to set the logic");
				logicCmp.reportValidity();
				logicCmp.value = this.objVisibleRule.RuleSkillsLogic;
			} else {
				this.blnSkillChanged = true;
				let criteriaLogic = this.objVisibleRule.RuleSkillsCriteriaLogic;
				criteriaLogic = criteriaLogic.replaceAll(this.objVisibleRule.RuleSkillsLogic, event.detail.value);
				setTimeout(() => {
					this.objVisibleRule.RuleSkillsCriteriaLogic = criteriaLogic;
					this.objVisibleRule.RuleSkillsLogic = event.detail.value;
				}, 0);
			}
		} else if (selectedAttribute == "RuleSkillsCriteriaLogic") {
			this.objVisibleRule.RuleSkillsCriteriaLogic = event.detail.value;
			this.blnSkillChanged = true;
		}
	}

	// Hides accordion section to update rule set configuration
	handleAccordionCancel() {
		this.list_openSections = [];
	}

	// refresh all rules
	async handleRefreshAllRules() {
		let strRuleSetConfigId = this.objConfig.Id;
		try {
			const result = await LightningConfirm.open({
				message: `This action will refresh the record count for all rules within this Rule Set. This action can only be taken ${this.objConfig.Available_Refreshes_Per_Day__c} times per day for this Rule Set. Today's remaining refresh count for this Rule Set is:  ${(this.objConfig.Available_Refreshes_Per_Day__c - this.objConfig.Refreshes_Triggered_Today__c)}. Please click 'OK' to proceed and utilize one of the remaining refreshes.`,
				label: 'Refresh All Rules',
			});
			if (result) {
				this.blnLoading = true;
				let objResult = await refreshAllRules({ idRecord: strRuleSetConfigId });
				if (objResult.blnIsSuccess) {
					let variant = (objResult.strMessage.includes("completed successfully")) ? "success" : "warning";
					let title = (objResult.strMessage.includes("completed successfully")) ? "Success" : "Warning";
					displayToast(this, title, objResult.strMessage, variant, "");
					this.fetchTeamRules();
				} else {
					displayToast(this, "Error in refreshing all rules record count", "Error Reason: " + objResult.strMessage, "error", "");
				}
				this.blnLoading = false;
			}
		} catch (error) {
			console.log("error", error);
			this.blnLoading = false;
			displayToast(this, "Error in fetching record count", "Error Reason: " + error, "error", "");
		}
	}

	handleViewRecordCount(event) {
		let ruleSetId = event.target.dataset.id;
		this.blnLoading = true;
		// apex method to fetch leads and opportunities
		queryRecordCount({
			idRecord: ruleSetId
		})
			.then((result) => {
				if (result.blnIsSuccess) {
					displayToast(this, "Record count fetched successfully!", "", "success", "");

					for (let eachRule of this.list_rules) {
						if (eachRule.Id == ruleSetId) {
							eachRule.Refresh_Date_Available__c = true;
							eachRule.Last_Refreshed_Date__c = result.objRuleSet.Last_Refreshed_Date__c;

							if (result.objRuleSet.Last_Ran_With_Zero_Records__c) {
								eachRule.Last_Zero_Record_Run_Date_Available__c = true;
								eachRule.Last_Ran_With_Zero_Records__c = result.objRuleSet.Last_Ran_With_Zero_Records__c;
							} else {
								eachRule.Last_Zero_Record_Run_Date_Available__c = false;
							}

							eachRule.LastModifiedBy = result.objRuleSet.Rule_Last_Updated_By__r.Name;
							eachRule.LastModifiedDate = Date.parse(result.objRuleSet.Rule_Last_Updated_Time__c);
							if (result.objRuleSet.Record_Count__c) {
								eachRule.Record_Count__c = result.objRuleSet.Record_Count__c.split("\n");
							} else {
								eachRule.Record_Count__c = ["No criteria found"];
							}
						}
					}
				} else {
					// show the right error message
					displayToast(this, "Error in fetching record count", "Error Reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in fetching record count", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}

	handleViewSkills(event) {
		this.viewSkillsModal = true;
		this.list_SelectedSkills = [];
		this.list_RuleSkillsToDisplay = [];
		this.list_RuleSkills = [];
		this.blnSkillChanged = false;
		//reset the fields to its default value
		this.template.querySelectorAll("lightning-input-field").forEach((field) => {
			field.reset();
		});

		// get rule details
		for (let eachRule of this.list_rules) {
			if (eachRule.Id == event.target.dataset.id) {
				// set selected skills for the rule and build a list of skills to display on right panel
				this.viewRulesName = eachRule.Rule_Name__c;

				this.objVisibleRule = {
					Id: eachRule.Id,
					Rule_Name__c: eachRule.Rule_Name__c,
					Description__c: eachRule.Description__c ? eachRule.Description__c : "",
					Hold_Out_Percentage__c: eachRule.Hold_Out_Percentage__c,
					RuleSkillsCriteriaLogic: eachRule.RuleSkillsCriteriaLogic,
					RuleSkillsLogic: eachRule.RuleSkillsLogic
				};
				let list_RuleSkillsToDisplayTemp = [];
				if (this.map_RuleAndSkills.has(this.objVisibleRule.Id)) {
					let list_SkillNames = [];
					for (let eachSkill of this.map_RuleAndSkills.get(this.objVisibleRule.Id)) {
						list_SkillNames.push(eachSkill.Name);
						this.list_RuleSkills.push({ skill: eachSkill, action: "none" });
						list_RuleSkillsToDisplayTemp.push(eachSkill);
					}
					this.list_SelectedSkills = list_SkillNames;
				}
				setTimeout(() => {
					this.list_RuleSkillsToDisplay = list_RuleSkillsToDisplayTemp;
				}, 0);
			}
		}
	}

	closeSkillsModal() {
		this.viewSkillsModal = false;
	}

	handleConfigCreated() {
		displayToast(this, "Configuration successfully created!", "", "success", "");
		this.configCreateModalVisible = false;
		this.handleLoad();
	}

	createNewConfig() {
		this.configCreateModalVisible = true;
		this.ruleConfigNew = {
			Name: "",
			Abbreviation__c: "",
			Team_Skill_Type__c: ""
		};
	}

	hideConfigModal() {
		this.configCreateModalVisible = false;
	}

	createNewRule() {
		let cloneOptions = [];
		this.list_rules.forEach((eachRule) => {
			cloneOptions.push({ label: eachRule.Rule_Name__c, value: eachRule.Id });
		});
		this.newRuleSet = {
			cloneOptions: cloneOptions,
			title: "Create New Rule under " + this.objConfig.Name + " rule set"
		};

		this.ruleCreateModalVisible = true;
	}

	handleCloseRule() {
		this.ruleCreateModalVisible = false;
	}

	handleNewRuleChange(event) {
		let value = event.detail.value;
		this.newRuleSet[event.target.dataset.field] = value;
	}

	handleCreateNewRule(event) {
		let newRuleTextBox = this.template.querySelector("lightning-input[data-id=createNewRuleText]");

		this.newRuleSet.name = this.newRuleSet.name ? this.newRuleSet.name : "";
		this.newRuleSet.name = this.newRuleSet.name.trim();
		this.newRuleSet.name = this.newRuleSet.name.replace(/\s{2,}/g, " ");

		if (this.newRuleSet.name == "" || this.newRuleSet.name == null || this.newRuleSet.name == undefined) {
			newRuleTextBox.setCustomValidity("Complete this field");
			newRuleTextBox.reportValidity();
			return;
		}

		if (this.newRuleSet.name.includes("-")) {
			newRuleTextBox.setCustomValidity("Please remove dashes from the Rule Name to save.");
			newRuleTextBox.reportValidity();
			return;
		}

		if (this.newRuleSet.name.length > 50) {
			newRuleTextBox.setCustomValidity("Rule Name is limited to 50 characters, please reduce the length of the Rule Name to 50 characters or less to save.");
			newRuleTextBox.reportValidity();
			return;
		}
		
		this.newRuleSet.name = this.newRuleSet.name.replace(/\s{2,}/g, " ");

		let existingRuleFound = false;
		let priority = 0;
		this.list_rules.forEach((eachRule) => {
			if (eachRule.Rule_Name__c.trim().toLowerCase() == this.newRuleSet.name.trim().toLowerCase()) {
				existingRuleFound = true;
			}
			if (eachRule.Priority__c >= priority) {
				priority = eachRule.Priority__c;
			}
		});

		if (existingRuleFound) {
			newRuleTextBox.setCustomValidity("Rule with this name already exists.");
			newRuleTextBox.reportValidity();
			return;
		}

		newRuleTextBox.setCustomValidity("");
		newRuleTextBox.reportValidity();

		this.blnLoading = true;
		// apex method to fetch leads and opportunities
		createNewRuleSet({
			objRuleSet: {
				Rule_Name__c: this.newRuleSet.name,
				Priority__c: priority + 1,
				NBA_Rule_Set_Configuration__c: this.objConfig.Id
			},
			idCloneRule: this.newRuleSet.cloneRuleSet
		})
			.then((result) => {
				if (result.blnIsSuccess) {
					displayToast(this, this.newRuleSet.name + " rule succesfully created!", "", "success", "");
				} else {
					// .fetchTeamRules
					displayToast(this, "Error in creating new rule", "Error Reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
				this.ruleCreateModalVisible = false;
				this.fetchTeamRules();
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in creating new rule", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}

	handleRuleChange(event) {
		let id = event.target.dataset.id;
		let value = event.detail.value;
		let field = event.target.dataset.field;
		this.list_rules.forEach((eachRule) => {
			if (eachRule.Id == id) {
				eachRule[field] = value;
			}
		});
		this.blnChanged = true;
	}

	handleUpdateRule() {
		this.blnLoading = true;
		// if skill changed, validate the skill settings
		if (!this.validateSkillSetings()) {
			displayToast(this, "Error in updating " + this.objVisibleRule.Rule_Name__c, "Error Reason: " + this.errorMessage, "error");
			this.blnLoading = false;
			return;
		}

		let criteriaLogicCmp = this.template.querySelector('[data-uniqueid="RuleSkillsCriteriaLogic"]');
		if (this.objVisibleRule.RuleSkillsCriteriaLogic != null) {
			criteriaLogicCmp.setCustomValidity("");
			criteriaLogicCmp.reportValidity();

			let numberPattern = /[-]{0,1}[\d]*[.]{0,1}[\d]+/g;
			let list_Allnumbers = this.objVisibleRule.RuleSkillsCriteriaLogic.match(numberPattern);
			let list_UniqueNumbers = Array.from(new Set(list_Allnumbers));
			// sort in descending order
			list_UniqueNumbers = list_UniqueNumbers.sort(function (a, b) {
				return b - a;
			});

			// check if logic contains any numbers
			if (list_UniqueNumbers.length == 0) {
				criteriaLogicCmp.setCustomValidity("Logic does not contain any numbers.");
				criteriaLogicCmp.reportValidity();
			}

			let missingCriteria = false;
			list_UniqueNumbers.forEach((number) => {
				if (this.list_RuleSkillsToDisplay.filter((skill) => skill.Order == number).length == 0) {
					missingCriteria = true;
				}
			});

			// check if logic contains any numbers that do not match any criteria
			if (missingCriteria) {
				criteriaLogicCmp.setCustomValidity("Logic contains a number that does not match any criteria.");
				criteriaLogicCmp.reportValidity();
			}

			missingCriteria = false;
			this.list_RuleSkillsToDisplay.forEach((skill) => {
				if (!this.objVisibleRule.RuleSkillsCriteriaLogic.includes(skill.Order.toString())) {
					missingCriteria = true;
				}
			});

			// check if logic contains all the criteria
			if (missingCriteria) {
				criteriaLogicCmp.setCustomValidity("Logic does not contain all the criteria.");
				criteriaLogicCmp.reportValidity();
			}
		} else if (this.list_RuleSkillsToDisplay.length) {
			criteriaLogicCmp.setCustomValidity("Complete this field.");
			criteriaLogicCmp.reportValidity();
		}

		// check if all lightning input fields are valid
		const blnInputFieldsValid = [...this.template.querySelectorAll("lightning-input")].reduce((validSoFar, inputField) => {
			inputField.reportValidity();
			return validSoFar && inputField.checkValidity();
		}, true);
		if (!blnInputFieldsValid) {
			displayToast(this, "Error in updating " + this.objVisibleRule.Rule_Name__c, "Please check errors on the page", "error");
			this.blnLoading = false;
			return;
		}

		//at this point all basic validations are done - next generate the soql query as per the criteria logic and validate
		let criteria = this.objVisibleRule.RuleSkillsCriteriaLogic;
		if (criteria) {
			let numberPattern = /[-]{0,1}[\d]*[.]{0,1}[\d]+/g;
			let list_Allnumbers = criteria.match(numberPattern);
			let list_UniqueNumbers = Array.from(new Set(list_Allnumbers));
			// sort in descending order
			list_UniqueNumbers = list_UniqueNumbers.sort(function (a, b) {
				return b - a;
			});
			criteria = criteria.replace(/\b(\d+)\b/g, "{!$1}");
			list_UniqueNumbers.forEach((number) => {
				let skill = this.list_RuleSkillsToDisplay.find((skillItem) => skillItem.Order == number);
				let whereClause = this.buildWhereClause(skill);
				criteria = criteria.replaceAll("{!" + number + "}", whereClause);
			});

			let strQuery = "SELECT Id FROM ServiceResourceSkill WHERE (" + criteria + ") LIMIT 0";
			validateSOQL({
				strQuery: strQuery,
				strBaseObject: null,
				idRuleSet: null
			})
				.then((result) => {
					if (result.blnError) {
						// if error - show error message in the UI
						criteriaLogicCmp.setCustomValidity(result.strMessage);
						criteriaLogicCmp.reportValidity();
						displayToast(this, "Error in updating " + this.objVisibleRule.Rule_Name__c, "Please check errors on the page", "error");
						this.blnLoading = false;
					} else {
						// if no error - update the rule
						criteriaLogicCmp.setCustomValidity("");
						criteriaLogicCmp.reportValidity();
						//this.objVisibleRule.RuleSkillSoqlQuery = "SELECT Id, Skill.MasterLabel FROM ServiceResourceSkill WHERE (" + criteriaSave + ")";
						this.handleSaveRule();
					}
				})
				.catch((error) => {
					this.error = error;
					console.log("error", error);
					displayToast(this, "Error in updating rules", "Error Reason: " + error?.body?.message || "Unknown error.", "error", "");
					this.blnLoading = false;
				});
		} else {
			this.handleSaveRule();
		}
	}

	buildWhereClause(skill) {
		let skillLevel = skill.Skill_Level__c;
		let operator = skill.Operator__c;
		let skillName = "'" + skill.Name + "'";

		// Based on input skill, operator and level, build the where clause such that it can be used in SOQL query
		// Skill.MasterLabel = 'skillName' AND SkillLevel operator skillLevel (handle multiple values for IN and NOT IN operators)
		let whereClause = "";
		if (operator == ">=") {
			whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel >= " + skillLevel + ")";
		} else if (operator == "<=") {
			whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel <= " + skillLevel + ")";
		} else if (operator == ">") {
			whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel > " + skillLevel + ")";
		} else if (operator == "<") {
			whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel < " + skillLevel + ")";
		} else if (operator == "=") {
			if (skillLevel.includes(",")) {
				let list_Values = skillLevel.split(",");
				whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel IN (" + list_Values.join(",") + "))";
			} else {
				whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel = " + skillLevel + ")";
			}
		} else if (operator == "!=") {
			if (skillLevel.includes(",")) {
				let list_Values = skillLevel.split(",");
				whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel NOT IN (" + list_Values.join(",") + "))";
			} else {
				whereClause = whereClause + "(Skill.MasterLabel = " + skillName + " AND SkillLevel != " + skillLevel + ")";
			}
		} else if (operator == null) {
			whereClause = whereClause + "(Skill.MasterLabel = " + skillName + ")";
		}
		return whereClause;
	}

	handleSaveRule() {
		// build a wrapper to send to apex method
		let skillsWrapper = null;
		if (this.blnSkillChanged) {
			let ruleSkills = [];
			let ruleSkillsCriteria = {};
			for (let element of this.list_RuleSkillsToDisplay) {
				ruleSkills.push(element);
			}
			ruleSkillsCriteria["list_RuleSkills"] = ruleSkills;
			ruleSkillsCriteria["criteriaLogic"] = this.objVisibleRule.RuleSkillsCriteriaLogic;
			ruleSkillsCriteria["logic"] = this.objVisibleRule.RuleSkillsLogic;
			skillsWrapper = {
				list_RuleSkills: ruleSkills,
				blnSkillsChanged: true
			};
			//store the rule skills criteria logic in the rule object as a json string to be parsed and used going forward to understand order and logic
			if (ruleSkills.length) {
				this.objVisibleRule.Rule_Skills_Criteria_Logic__c = JSON.stringify(ruleSkillsCriteria, null, "\t");
			} else {
				this.objVisibleRule.Rule_Skills_Criteria_Logic__c = null;
			}
		}
		this.blnLoading = true;
		let list_Rules = [this.objVisibleRule];
		updateRuleSet({
			list_Rules: list_Rules,
			strRuleSkillsData: JSON.stringify(skillsWrapper)
		})
			.then((result) => {
				this.blnLoading = false;
				if (result.blnIsSuccess) {
					displayToast(this, this.objVisibleRule.Rule_Name__c + " updated successfully!", "", "success", "");
					this.blnRuleDetailVisible = false;
					this.viewSkillsModal = false;
					this.fetchTeamRules();
				} else {
					displayToast(this, "Error in updating " + this.objVisibleRule.Rule_Name__c, "Error Reason: " + result.strMessage, "error", "");
				}
				this.blnLoading = false;
			})
			.catch((error) => {
				this.error = error;
				console.log("error", error);
				displayToast(this, "Error in updating rules", "Error Reason: " + error?.body?.message, "error", "");
				this.blnLoading = false;
			});
	}

	handleNewRuleSetChange(event) {
		let value = event.detail.value;
		this.ruleConfigNew[event.target.dataset.field] = value;
	}

	createRuleSet() {
		// trim and remove extra spaces from rule set name and abbreviation
		this.ruleConfigNew.Name = this.ruleConfigNew.Name ? this.ruleConfigNew.Name : "";
		this.ruleConfigNew.Name = this.ruleConfigNew.Name.trim();
		this.ruleConfigNew.Name = this.ruleConfigNew.Name.replace(/\s{2,}/g, " ");
		let textBoxCmp = this.template.querySelector("lightning-input[data-id=createNewRuleConfigText]");

		this.ruleConfigNew.Abbreviation__c = this.ruleConfigNew.Abbreviation__c ? this.ruleConfigNew.Abbreviation__c : "";
		this.ruleConfigNew.Abbreviation__c = this.ruleConfigNew.Abbreviation__c.trim();
		this.ruleConfigNew.Abbreviation__c = this.ruleConfigNew.Abbreviation__c.replace(/\s{2,}/g, " ");
		let abbreviationCmp = this.template.querySelector("lightning-input[data-id=createNewRuleConfigAbbr]");

		// check for duplicate rule set name
		if (this.ruleConfigNew.Name) {
			let existingRuleSetFound = false;
			this.list_TeamNames.forEach((eachRuleSet) => {
				if (eachRuleSet.label.trim().toLowerCase() == this.ruleConfigNew.Name.trim().toLowerCase()) {
					existingRuleSetFound = true;
				}
			});

			if (existingRuleSetFound) {
				textBoxCmp.setCustomValidity("Rule set with this name already exists.");
				textBoxCmp.reportValidity();
				return;
			}

			textBoxCmp.setCustomValidity("");
			textBoxCmp.reportValidity();
		}
		let validated = true;

		if (this.ruleConfigNew.Name == "" || this.ruleConfigNew.Name == null || this.ruleConfigNew.Name == undefined) {
			textBoxCmp.setCustomValidity("Complete this field");
			textBoxCmp.reportValidity();
			validated = false;
		} else {
			textBoxCmp.setCustomValidity("");
			textBoxCmp.reportValidity();
		}

		if (this.ruleConfigNew.Abbreviation__c == "" || this.ruleConfigNew.Abbreviation__c == null || this.ruleConfigNew.Abbreviation__c == undefined) {
			abbreviationCmp.setCustomValidity("Complete this field");
			abbreviationCmp.reportValidity();
			validated = false;
		} else {
			abbreviationCmp.setCustomValidity("");
			abbreviationCmp.reportValidity();
		}

		if (validated) {
			this.blnLoading = true;
			// apex method to fetch leads and opportunities
			createNewRuleConfig({
				objRuleSetConfig: this.ruleConfigNew
			})
				.then((result) => {
					if (result.blnIsSuccess) {
						displayToast(this, this.ruleConfigNew.Name + " rule set succesfully created!", "", "success", "");
						this.configCreateModalVisible = false;

						let list_TeamNames = [];
						this.list_TeamNames.forEach((eachTeam) => {
							list_TeamNames.push(eachTeam);
						});

						list_TeamNames.push({
							label: this.ruleConfigNew.Name,
							value: this.ruleConfigNew.Name
						});
						this.list_TeamNames = list_TeamNames;
					} else {
						// .fetchTeamRules
						displayToast(this, "Error in creating new rule", "Error Reason: " + result.strMessage, "error", "");
					}
					this.blnLoading = false;
				})
				.catch((error) => {
					this.error = error;
					console.log("error", error);
					displayToast(this, "Error in creating new rule", "Error Reason: " + error?.body?.message, "error", "");
					this.blnLoading = false;
				});
		}
	}
}