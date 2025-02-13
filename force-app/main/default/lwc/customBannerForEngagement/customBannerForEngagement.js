import { LightningElement, track } from 'lwc';
import BannerLabel from '@salesforce/label/c.Engagement_Close_banner';
export default class CustomBannerForEngagement extends LightningElement {
    @track closedBannerLabel = BannerLabel ; 
}