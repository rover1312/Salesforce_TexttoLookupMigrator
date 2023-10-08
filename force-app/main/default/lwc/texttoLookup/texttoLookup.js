import { LightningElement, track,wire } from 'lwc';
import getOptions from '@salesforce/apex/objectQuery.getOptions';
import fetchFieldAPIName from '@salesforce/apex/objectQuery.fetchFieldAPIName';
import Confirm1 from '@salesforce/apex/TexttoLookupController.Confirm';

export default class texttoLookup extends LightningElement {
    @track value = '';
    @track options = []; // populate this with your object options
    @track fieldName = '';
    @track lookupName = '';
    @track data = [];
    @track isData = false;
    @track isConfig = true;
    @track Fuzzytoggle;
    @track columns = [
        { label: 'Field Name', fieldName: 'fieldName' },
        { label: 'API Name', fieldName: 'apiName' },
    ];

    @track options;

    @wire(getOptions)
    wiredOptions({ error, data }) {
        if (data) {
            this.options = data.map(option => ({ label: option.label, value: option.value }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.options = undefined;
        }
    }



    handleObjectChange(event) {
        this.value = event.detail.value;
        // add logic to fetch field data based on selected object and field name
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        // process selected row
    }

    handleSearch(){
        console.log('hit button!');
        fetchFieldAPIName({ sObjectName: this.value })
            .then(result => {

                console.log('result found');
                console.log(result);
                this.isData = true;
                this.data = result.map(option => ({ label: option, value: option}));
            })
            .catch(error => {
                console.error('Error in getting field API names: ' + error);
            });
    }

    handleFieldChange(event){
        this.fieldName = event.detail.value;
    }

    handleLookupChange(event) {
        this.lookupName = event.detail.value;
        // add logic to fetch field data based on selected object and field name
    }

    handleConfirm(){

        Confirm1({ 
            lookupFieldName: this.lookupName, 
            textFieldName: this.fieldName, 
            sObjectApi: this.value 
        })
        .then(result => {
            // handle successful response
        })
        .catch(error => {
            // handle error
        });
        
    }

    changeFuzzyToggle(event){
        if(event.detail.value){
            this.Fuzzytoggle = true;
        }

    }

}