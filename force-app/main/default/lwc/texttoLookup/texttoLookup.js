import { LightningElement, track,wire } from 'lwc';
import getOptions from '@salesforce/apex/objectQuery.getOptions';
import fetchFieldAPIName from '@salesforce/apex/objectQuery.fetchFieldAPIName';
import Confirm1 from '@salesforce/apex/TexttoLookupController.Confirm';
import getJobDetails from '@salesforce/apex/TexttoLookupController.getJobDetails';
import getLatestCSVFile from '@salesforce/apex/TexttoLookupController.getLatestCSVFile';

export default class texttoLookup extends LightningElement {
    @track value = '';
    @track options = []; // populate this with your object options
    @track fieldName = '';
    @track lookupName = '';
    @track data = [];
    @track isData = false;
    @track isConfig = true;
    @track Fuzzytoggle = 'false';
    @track toggle;
    @track columns = [
        { label: 'Field Name', fieldName: 'fieldName' },
        { label: 'API Name', fieldName: 'apiName' },
    ];

    @track options;
    @track batchJobId;
    @track executedPercentage;
    @track executedIndicator;
    @track executedBatch;
    @track totalBatch;
    @track isBatchCompleted = false;
    @track batchClassName;
    @track batchSize;
    @track disableExecuteBatch = false;
    @track Dictionary = [];
    @track isResult = false;
    @track csvFile;
    @track columns;
    @track Data = [];
    @track columns1 = [];


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
            sObjectApi: this.value,
            Toggle: this.Fuzzytoggle,
            dict: this.Dictionary

        })
        .then(result => {
            this.batchJobId = result;
            console.log(result);
            this.isConfig = false; //change to false here
            this.getBatchStatus();
            this.isProcessing = true;
            
        })
        .catch(error => {
            // handle error
            console.error('Error occured in running batch job' + error);
        });
        
    }

    changeFuzzyToggle(event){
        
        this.Fuzzytoggle = event.target.checked.toString();
        this.toggle = event.target.checked;
        console.log(this.Fuzzytoggle);
        

    }

    getBatchStatus() {
        getJobDetails({ jobId: this.batchJobId }).then(res => {
            console.log('response => ', res);
            if (res[0].Status != 'Queued') {
                this.totalBatch = res[0].TotalJobItems;
                if (res[0].TotalJobItems == res[0].JobItemsProcessed) {
                    this.isBatchCompleted = true;
                }
                this.executedPercentage = ((res[0].JobItemsProcessed / res[0].TotalJobItems) * 100).toFixed(2);
                this.executedBatch = res[0].JobItemsProcessed;
                var executedNumber = Number(this.executedPercentage);
                this.executedIndicator = Math.floor(executedNumber);
                this.refreshBatchOnInterval();  //enable this if you want to refresh on interval
            }
            else{
                this.getBatchStatus();
            }
        }).catch(err => {
            console.log('err ', err);

        })
    }

    refreshBatchOnInterval() {
        this._interval = setInterval(() => {
            if (this.isBatchCompleted) {
                clearInterval(this._interval);
            } else {
                this.getBatchStatus();
            }
        }, 3000); //refersh view every time
    }

    handleDictionary(event){
        this.Dictionary = event.detail.value.split(',');
    }
    handleResult(){
        this.isProcessing = false;
        

        getLatestCSVFile()
            .then(result => {
                // Process the CSV data received from the Apex method
                if (result) {
                    this.csvFile = result;
                    this.parseCSV();
                    
                }
            })
            .catch(error => {
                console.error(error);
            });
    }


 parseCSV() {
    if (this.csvFile) {
        // Assuming 'result' is the content of your CSV file
        const result = this.csvFile;
        const lines = result.split(/\r\n|\n/);
        const headers = lines[0].split(',');
        this.columns = headers.map((header) => {
            return { label: header, fieldName: header };
        });
        const data = [];
        lines.forEach((line, i) => {
            if (i === 0) return;
            const obj = {};
            const currentline = line.split(',');
            for (let j = 0; j < headers.length; j++) {
                obj[headers[j]] = currentline[j];
            }
            data.push(obj);
        });
        this.Data = data;
    }
    this.isResult = true;
}


}