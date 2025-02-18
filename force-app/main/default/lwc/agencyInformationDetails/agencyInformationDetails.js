import { LightningElement,track, api } from 'lwc';
import getFieldMetadata from '@salesforce/apex/AgencyInformationDetails.getFieldMetadata';
export default class AgencyInformationDetails extends LightningElement {
activeSectionsMessage = '';
@api objectAPIName;
@api recordId;
@track isLoading = false;
@track sectionData = [];
section = '';
    handledisplayMinSUIrate(e){
        this.sectionData.forEach((meta) => {
             meta.fieldDataList.forEach((field) => {
                if(field.metadata.IsDependent__c == true && field.metadata.DependentField_API_Name__c == e.target.fieldName){
                    if(field.metadata.Filter_Condition__c.split(':')[1].split(';').includes(e.target.value + '') ){
                        field.isVisible = true;
                    }else{
                        field.isVisible = false;
                    }
                }
             });
        });
    }

    handleSectionToggle(event) {
        this.section = event.detail.openSections;
    }
    submit(){
        this.template.querySelectorAll('lightning-record-edit-form').forEach((form) => {form.submit()});
        this.section = '';
    }
    connectedCallback() {
       this.getMetadata();
    }

    getMetadata(){
        this.isLoading = true;
        getFieldMetadata({recordId:this.recordId,ObjectAPIName:this.objectAPIName})
        .then(result => {
            this.isLoading = false;
            this.sectionData = result;
        })
        .catch(error => {
            this.isLoading = false;
            console.log('error in getMetadata:'+JSON.stringify(error));
        })
    }
}