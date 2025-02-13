/**
 * @description Generic Breadcrumb cmp build for community
 * @author      Ajay Krishna P U
 * @since       2024-02-02
 */
import { LightningElement, api } from "lwc";
import basePath from "@salesforce/community/basePath";

const HOME = "Home";
export default class CustomBreadcrumb extends LightningElement {
	@api strLevelNLabel;
	@api strLevelNB1Label;
	@api strLevelNB1Path;

	listBreadCrumbs = [];

    /**
     * Initialize Breadcrumbs
     */
	connectedCallback() {
		this.prepareBreadcrumbs();
	}

    /**
     * Prepare Bedumb in format
     */
	prepareBreadcrumbs() {
		const listBreadCrumbs = [];
		listBreadCrumbs.push({ label: HOME, name: HOME, href: basePath });

		if (this.strLevelNB1Label) {
			listBreadCrumbs.push({ label: this.strLevelNB1Label, name: this.strLevelNB1Label, href: basePath + this.strLevelNB1Path });
		}

		listBreadCrumbs.push({ label: this.strLevelNLabel, name: this.strLevelNLabel, href: window.location.href });
		this.listBreadCrumbs = listBreadCrumbs;
	}
}