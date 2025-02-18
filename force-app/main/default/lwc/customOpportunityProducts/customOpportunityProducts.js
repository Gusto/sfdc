import { LightningElement, wire, track , api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityProducts from '@salesforce/apex/OpportunityProductController.getOpportunityProducts';
import getOpportunityData from '@salesforce/apex/OpportunityProductController.getOpportunityData';
import searchPriceBookEntry from '@salesforce/apex/OpportunityProductController.searchPriceBookEntries';
import loadPriceBookEntries from '@salesforce/apex/OpportunityProductController.loadPriceBookEntries';
import addOpportunityProducts from '@salesforce/apex/OpportunityProductController.addOpportunityProducts';
import updateOpportunityProducts from '@salesforce/apex/OpportunityProductController.updateOpportunityProducts';
import validateSelectedProducts from '@salesforce/apex/OpportunityProductController.validateSelectedProducts';
import deleteRecord from '@salesforce/apex/OpportunityProductController.deleteOpportunityLineItem';

import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class CustomOpportunityProducts extends NavigationMixin(LightningElement) {
    @api recordId; // Opportunity Id
    @track opportunityProducts = [];
    @track searchResults = [];
    @track loadsSearchResults = [];
    @track selectedRows = [];
    @track selectedOlIIds = [];
    @track selectedProductRows = [];
    @track draftValues = [];
    @track draftProductValues = [];
    draftCellProductValues = [];
    @track isLoading = false;
    @track isModalOpen = false;
    @track blnAddProducts = false;
    @track blnShowDelete = false;
    @track blnShowSave = false;
    @track strSaveButtonLabel = "Select Products";
    searchTerm = '';
    @track productData = [];
    @track selectedProducts = [];
    @track changedProductMap = new Map();
    @track selectedProductIds = [];
    @track isEditing = false;
    @track blnShowProductEdit = false;
    @track editedProductData = {};
    @track showDeleteProduct = false;
    @track recordToDelete;
    @track opportunityRecord;
    @track blnProductRelatedReadonly = false;
    wiredResult;

    // Datatable columns for search results
    searchColumns = [
        {
            label: 'Product Name',
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'productName' },
                target: '_self'  // Opens in a new tab
            }
        },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number', editable: true },
        //{ label: 'Payment Plan Name', fieldName: 'priceBookName'},
        { label: 'Base Price', fieldName: 'BasePrice', type: 'currency' },
        { label: 'List Price', fieldName: 'unitPrice', type: 'currency'},
        { label: 'Line Description', fieldName: 'LineDescription', editable: true },
        //{ label: "Date", fieldName: "Date",  type: "date-local", typeAttributes: { month: "2-digit", day: "2-digit" } }
    ];

    // Datatable columns for Opportunity Products
    columns = [
        {
            label: 'Product Name',
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ProductName' },
                target: '_self'  // Opens in a new tab
            },
            initialWidth: 200
        },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number', editable: true , initialWidth: 120},
        { label: 'Base Price', fieldName: 'BasePrice', type: 'currency', initialWidth: 120 },
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', initialWidth: 120 },
        { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency' , initialWidth: 120},
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Edit', name: 'edit' },
                    { label: 'Delete', name: 'delete' },
                ],
                menuAlignment: 'auto',
                style: 'position: absolute !important;z-index: 1000 !important;left: 0 !important;top: 0 !important;'
            },
            initialWidth: 80,
            style: 'position: absolute !important;z-index: 1000 !important;left: 0 !important;top: 0 !important;'
        },
    ];

    readonlyColumns = [
        {
            label: 'Product Name',
            fieldName: 'productUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ProductName' },
                target: '_self'  // Opens in a new tab
            },
            initialWidth: 200
        },
        { label: 'Quantity', fieldName: 'Quantity', type: 'number', initialWidth: 120},
        { label: 'Base Price', fieldName: 'BasePrice', type: 'currency', initialWidth: 120 },
        { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', initialWidth: 120 },
        { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency' , initialWidth: 120},
    ];

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'edit':
                console.log('edit: ');
                this.editRecord(row.Id);
                console.log('edit after open: ');
                //refreshApex(this.wiredResult);
                break;
            case 'delete':
                this.deleteRecord(row.Id);
                break;
            default:
        }
    }

    editRecord(recordId) {
        console.log('edit started: ');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'OpportunityLineItem',
                actionName: 'edit'
            }
        });
        console.log('edit done: ');
    }

    deleteRecord(recordId) {

        if (this.opportunityRecord.StageName === 'Closed Won') {
            this.showToast('Error', 'Cannot delete products: Opportunity is Closed Won.', 'error');
            this.isLoading = false;
            return;
        }

        if (this.opportunityRecord.StageName === 'Closed Lost') {
            this.showToast('Error', 'Cannot delete products: Opportunity is Closed Lost.', 'error');
            this.isLoading = false;
            return;
        }

        this.recordToDelete = recordId;
        this.showDeleteProduct = true;
    }

    confirmDelete() {
        this.isLoading = true;
        deleteRecord({ recordId: this.recordToDelete })
            .then((validationMessage) => {
                if (validationMessage) {
                    this.showToast('Error', validationMessage, 'error');
                    this.isLoading = false;
                    this.showDeleteProduct = false;
                    return;
                } else {
                    this.showToast('Success', 'Record deleted successfully', 'success');
                    this.showDeleteProduct = false;
                    refreshApex(this.wiredResult);
                    this.recordToDelete = null;
                    this.isLoading = false;
                }
                
            })
            .catch(error => {
                this.showToast('Error', 'Error deleting record', 'error');
                console.error(error);
                this.isLoading = false;
            });
    }

    handleQuantityChange(event) {
        this.editedProductData.Quantity = event.target.value;
        this.editedProductData.TotalPrice = this.editedProductData.Quantity * this.editedProductData.UnitPrice + this.editedProductData.BasePrice; // Calculate total price dynamically
    }

    connectedCallback() {
        this.fetchOpportunityProducts();
        this.fetchOpportunityData();
    }

    fetchOpportunityData() {
        getOpportunityData({ opportunityId: this.recordId })
            .then((result) => {
                console.log('result opportunityRecord11: ' + result.toString());
                //console.log('this.opportunityRecord Pricebook Name: ' + result.PriceBook2.Name);
                this.opportunityRecord = result;
                console.log('this.opportunityRecord name: ' + this.opportunityRecord.Name);
                console.log('this.opportunityRecord Pricebook Name: ' + this.opportunityRecord.Pricebook2.Name);
                //console.log('this.opportunityRecord Recordtype.Name: ' + this.opportunityRecord.Recordtype.Name);
                for (const [key, value] of Object.entries(this.opportunityRecord)) {
                    console.log(`${key}:`, value);
                }
                console.log('recordtype: ' + this.opportunityRecord.RecordType.Name);
                if (this.opportunityRecord.RecordType.Name === 'Acquisition') {
                    this.blnProductRelatedReadonly = true;
                }
            })
            .catch((error) => {
                console.error(error);
            });
    }

    fetchOpportunityProducts() {
        this.isLoading = true;
        let tempProductsList = [];
        console.log('this.recordId: ' + this.recordId);
        getOpportunityProducts({ opportunityId: this.recordId })
            .then((result) => {
                result.forEach((element) => {
                    tempProductsList.push({
                        ProductName: element.Product2.Name,
                        productUrl: '/lightning/r/OpportunityLineItem/' + element.Id + '/view',
                        Quantity: element.Quantity,
                        BasePrice: element.Base_Price__c,
                        UnitPrice: element.Unit_Price__c,
                        TotalPrice: element.TotalPrice,
                        Id: element.Id,
                        OpportunityName: element.Opportunity.Name,
                        Description: element.Description,
                        CreatedBy: element.CreatedBy.Name,
                        LastModifiedBy: element.LastModifiedBy.Name
                    });
                    console.log('tempProductsList: ' + tempProductsList);
                    this.opportunityProducts = [...tempProductsList];
                });
                this.isLoading = false;
            })
            .catch((error) => {
                console.error(error);
                this.isLoading = false;
            });
    }

    handleProductSelection(event) {
        console.log('event.detail.selectedRows: ' + event.detail.selectedRows);
        let tempSelectedOLIIds = [];
        this.selectedRows = [];
        this.selectedRows = event.detail.selectedRows;

        if (this.selectedRows.length === 0) {
            this.blnShowDelete = false;
        } else {
            this.blnShowDelete = true;
        }

        const selectedIds = this.selectedRows.map(row => row.Id);
        //console.log('Selected Row IDs:' + selectedIds);
        this.selectedOLIIds = selectedIds;

        // Iterate over selected rows
        this.selectedRows.forEach(row => {
            
            console.log('ID: ' + row.Id);
            //console.log('ProductName: ' + row.ProductName);
        });

        //console.log('Selected OLI IDs: ' + this.selectedOLIIds);
    }

    reloadPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    openProductModal() {

        if (this.opportunityRecord.StageName === 'Closed Won') {
            this.showToast('Error', 'Cannot add products: Opportunity is Closed Won.', 'error');
            this.isLoading = false;
            return;
        }

        if (this.opportunityRecord.StageName === 'Closed Lost') {
            this.showToast('Error', 'Cannot add products: Opportunity is Closed Lost.', 'error');
            this.isLoading = false;
            return;
        }

        //this.isModalOpen = true;
        this.blnAddProducts = true;
        this.searchResults = [];
        this.selectedRows = [];

        let productsList = [];
        console.log('showProductsOnLoad before 11: ' + this.searchResults);
        loadPriceBookEntries({ opportunityId: this.recordId })
            .then((result) => {
                result.forEach((element) => {
                    productsList.push({
                        productName: element.productName,
                        productUrl: '/lightning/r/Product2/' + element.product2Id + '/view',
                        Quantity: element.quantity,
                        //priceBookName: element.priceBookName,
                        BasePrice: element.basePrice,
                        unitPrice: element.unitPrice,
                        //salesPrice: element.UnitPrice,
                        LineDescription: element.productCategory,
                        pbeId: element.pbeId,
                        product2Id: element.product2Id,
                        Id : element.pbeId
                    });
                    this.searchResults = productsList;
                    this.loadsSearchResults = productsList;
                });
                
            })
            .catch((error) => {
                console.error(error);
            });
        console.log('showProductsOnLoad after: ' + this.searchResults);
    }

    closeModal() {
        this.isModalOpen = false;
        this.blnAddProducts = false;
        this.showDeleteProduct = false;
        this.selectedProductIds = [];
    }

    handleSearchProducts(event) {
        this.searchTerm = event.target.value;
        //const todaysDate = new Date();
        let productsList = [];
        let tempResults = [];
        if (this.searchTerm.length >= 2) {
            searchPriceBookEntry({ strSearchTerm: this.searchTerm, opportunityId: this.recordId })
                .then((result) => {
                    tempResults = result;
                    console.log('tempResults: ' + tempResults);
                    result.forEach((element) => {
                        productsList.push({
                            productName: element.productName,
                            productUrl: '/lightning/r/Product2/' + element.Id + '/view',
                            Quantity: element.quantity,
                            //priceBookName: element.priceBookName,
                            BasePrice: element.basePrice,
                            unitPrice: element.unitPrice,
                            //salesPrice: element.UnitPrice,
                            LineDescription: element.productCategory,
                            pbeId: element.pbeId,
                            product2Id: element.product2Id,
                            Id : element.pbeId
                        });
                        this.searchResults = productsList;
                    });
                    
                })
                .catch((error) => {
                    console.error(error);
                });
        } else {
            this.searchResults = this.loadsSearchResults;
        }
        //console.log('productsList1: ' + this.productsList);
        //this.searchResults = productsList;
        console.log('searchResults: ' + this.searchResults);
    }

    handleRowSelection(event) {
        //this.selectedRows = event.detail.selectedRows.map((row) => row.Id);
        //console.log('event.detail.selectedRows: ' + event.detail.selectedRows);
        let tempSelectedOLIIds = [];
        this.selectedProductRows = [];
        this.selectedProductRows = event.detail.selectedRows;

        //console.log('this.selectedProductRows: ' + this.selectedProductRows);

        const selectedProductRowsFromList = this.selectedProductRows;
        // Iterate over each draft value object
        selectedProductRowsFromList.forEach(draft => {
            //console.log('Selected product Entry:');
            Object.entries(draft).forEach(([key, value]) => {
                console.log('Key: ${key}, Value: ${value}');
            });
        });
        
    }

    handleAddProductCellChange(event) {
        const { draftValues } = event.detail;
        console.log('Cell changed:', draftValues);

        this.draftCellProductValues.push(event.detail.draftValues);

        const updatedCells = this.draftCellProductValues;
        updatedCells.forEach(draft => {
            Object.entries(draft).forEach(([key, value]) => {
                console.log(`Key: ${key}, Value: ${value}`);
            });
        });

        event.detail.draftValues.forEach(field => {
            //console.log('field.Id 1: ' + field.Id);
            //console.log('field.Quantity 1: ' + field.Quantity);
            this.changedProductMap.set(field.Id, field.Quantity);
            //draftMap.set(field.Id, field.Quantity);
        });

        this.changedProductMap.forEach((value, key) => {
            console.log('Map Key: ' + key + ', Map Value: ' + value);
        });
    }

    addSelectedProducts(event) {
        let blnQuantityZero = new Boolean(false);
        if (this.selectedProductRows.length === 0) {
            alert('Please select at least one product.');
            return;
        }

        //this.draftProductValues = event.detail.draftValues;
        //this.draftProductValues = event.detail.draftProductValues;
        console.log('this.draftProductValues 1: ' + this.draftProductValues);
        //console.log('this.selectedProductRows: ' + this.selectedProductRows);

        const selectedProductName = this.selectedProductRows.map(row => row.ProductName);
        console.log('selectedProductName: ' + selectedProductName);

        const draftMap = new Map();
        this.draftProductValues.forEach(field => {
            console.log('field.Id : ' + field.Id);
            console.log('field.Quantity : ' + field.Quantity);
            draftMap.set(field.Id, field.Quantity);
        });

        this.changedProductMap.forEach((value, key) => {
            console.log('after Map Key: ' + key + ', after Map Value: ' + value);
            if (value === null || value === undefined || value === '' || value <= 0) {
                blnQuantityZero = true;
            }
        });

        // Convert the Map to a plain object
        const productMap = this.changedProductMap;
        let idAndPriceMap = Object.fromEntries(productMap);
        console.log('idAndPriceMap: ' + idAndPriceMap);

        this.isLoading = true;

        this.selectedProductIds = this.selectedProductRows.map((row) => row.product2Id);
        if (blnQuantityZero === true) {
            this.showToast('Error', 'Quantity must be greater than 0.', 'error');
            this.isLoading = false;
            return;
        } else {
            
            console.log('Opportunity id1: ' + this.recordId);
            validateSelectedProducts({ opportunityId: this.recordId, selectedProductIds: this.selectedProductIds })
            .then((validationMessage) => {
                if (validationMessage) {
                    this.showToast('Error', validationMessage, 'error');
                    this.isLoading = false;
                } else {
                    console.log('Opportunity id2: ' + this.recordId);
                    console.log('idAndPriceMap: ' + idAndPriceMap);
                    addOpportunityProducts({ strOpportunityId: this.recordId, list_SelectedPriceBookEntries: this.selectedProductRows, map_DraftValues : idAndPriceMap })
                        .then(() => {
                            this.showToast('Success', 'Selected products added successfully!', 'success');
                            //this.fetchOpportunityProducts();
                            refreshApex(this.wiredResult);
                            this.closeModal();
                            this.isLoading = false;
                        })
                        .catch((error) => {
                            console.error('Error occurred:', error);

                            // Extracting and formatting error details
                            let errorDetails = [];
                            if (error.body) {
                                if (error.body.message) {
                                    errorDetails.push(`Message: ${error.body.message}`);
                                }
                                if (error.body.fieldErrors) {
                                    Object.entries(error.body.fieldErrors).forEach(([field, errors]) => {
                                        errors.forEach(err => {
                                            errorDetails.push(`Field: ${field}, Error: ${err.message}`);
                                        });
                                    });
                                }
                                if (error.body.pageErrors) {
                                    error.body.pageErrors.forEach(pageError => {
                                        //errorDetails.push(`Page Error: ${pageError.message}`);
                                    });
                                }
                            }

                            // Fallback for other error details
                            if (error.body && error.body.output && error.body.output.errors) {
                                error.body.output.errors.forEach(err => {
                                    //errorDetails.push(`Error: ${err.message}`);
                                });
                            }

                            // Showing error details in a user-friendly format
                            let errorMessage = errorDetails.length
                                ? errorDetails.join('\n')
                                : 'An unexpected error occurred.';
                            this.showToast('Error', errorMessage, 'error');

                            //this.showToast('Error', 'An error occurred while adding products.', 'error');
                            this.isLoading = false;
                        });
                }
            })
            .catch((error) => {
                this.error = error;
                this.showToast('Error', 'Validation failed', 'error');
                this.isLoading = false;
            });
        }
    }

    handleAddProductSave(event) {
        this.draftProductValues = event.detail.draftValues;
        //console.log('this.draftProductValues: ' + this.draftProductValues);
        
        const updatedFields = event.detail.draftValues;
        // Iterate over each draft value object
        updatedFields.forEach(draft => {
            console.log('Draft Entry:');
            Object.entries(draft).forEach(([key, value]) => {
                console.log(`Key: ${key}, Value: ${value}`);
            });
        });
    }

    saveAllChanges(event) {
        let blnQuantityZero = new Boolean(false);
        this.isLoading = true;
        this.draftValues = event.detail.draftValues
        if (this.draftValues.length === 0) {
            alert('No changes to save.');
            this.isLoading = false;
            return;
        }

        if (this.opportunityRecord.StageName === 'Closed Won') {
            this.showToast('Error', 'Cannot edit products: Opportunity is Closed Won.', 'error');
            this.isLoading = false;
            return;
        }

        if (this.opportunityRecord.StageName === 'Closed Lost') {
            this.showToast('Error', 'Cannot edit products: Opportunity is Closed Lost.', 'error');
            this.isLoading = false;
            return;
        }

        this.draftValues.forEach(field => {
            console.log('field.Id: ' + field.Id);
            console.log('field.Quantity: ' + field.Quantity);
            console.log('field.ProductName: ' + field.ProductName);
            if (field.Quantity === null || field.Quantity === undefined || field.Quantity === '' || field.Quantity <= 0) {
                blnQuantityZero = true;
            }
        });

        console.log('this.draftValues: ' + this.draftValues);
        if (blnQuantityZero === true) {
            this.showToast('Error', 'Quantity must be greater than 0.', 'error');
            this.isLoading = false;
            return;
        } else {
            updateOpportunityProducts({ list_OpportunityLineItemsToUpdate : this.draftValues })
            .then(() => {
                this.draftValues = [];
                this.showToast('Success', 'All changes saved successfully!', 'success');
                this.opportunityProducts = [];
                console.log('this.opportunityProducts before: ' + this.opportunityProducts);
                //this.fetchOpportunityProducts();
                refreshApex(this.wiredResult);
                console.log('this.opportunityProducts after: ' + this.opportunityProducts);
                this.isLoading = false;
                //location.reload();
            })
            .catch((error) => {
                console.error(error);
                this.showToast('Error', error.body.message , 'error');
                this.isLoading = false;
            });
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }

    @wire(getOpportunityProducts, { opportunityId: '$recordId' })
    wiredOpportunityProducts(result) {
        this.wiredResult = result;
        if (result.data) {
            this.opportunityProducts = result.data.map(element => ({
                ProductName: element.Product2.Name,
                productUrl: `/lightning/r/OpportunityLineItem/${element.Id}/view`,
                Quantity: element.Quantity,
                BasePrice: element.Base_Price__c,
                UnitPrice: element.Unit_Price__c,
                TotalPrice: element.TotalPrice,
                Id: element.Id,
                OpportunityName: element.Opportunity.Name,
                Description: element.Description,
                CreatedBy: element.CreatedBy.Name,
                LastModifiedBy: element.LastModifiedBy.Name
            }));
        } else if (result.error) {
            console.error(result.error);
        }
    }
}