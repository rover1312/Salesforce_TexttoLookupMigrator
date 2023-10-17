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
    @track batchStatus;
    @track options;
    @track batchJobId;
    @track executedPercentage = 0;
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
    allData = [];


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
            dict: this.Dictionary,
            Overwrite : true

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
            console.log(res[0].Status);
            if (res[0].Status != 'Queued' && res[0].Status != 'Preparing' && res[0].Status != 'Holding') {
                this.totalBatch = res[0].TotalJobItems;
                if (res[0].TotalJobItems == res[0].JobItemsProcessed) {
                    this.isBatchCompleted = true;
                }
                this.batchStatus = res[0].Status;
                this.executedPercentage = ((res[0].JobItemsProcessed / res[0].TotalJobItems) * 100).toFixed(2);
                this.executedBatch = res[0].JobItemsProcessed;
                var executedNumber = Number(this.executedPercentage);
                this.executedIndicator = Math.floor(executedNumber);
                }
                this.batchStatus = res[0].Status;
                this.refreshBatchOnInterval();
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
        }, 10000); //refersh view every time
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
        this.allData = data;
    }
    this.updateData();
    this.isResult = true;
}









pageSize = 5; // Number of records to display per page
pageNumber = 1; // Current page number
totalPages = Math.ceil(this.allData.length / this.pageSize); // Total number of pages
isFirstPage = true; // Is this the first page?
isLastPage = this.totalPages === 1; // Is this the last page?

// Method to handle 'Previous' button click
handlePrev() {
    if(this.pageNumber > 1) {
        this.pageNumber--;
        this.isFirstPage = this.pageNumber === 1;
        this.isLastPage = false;
        this.updateData();
    }
}

// Method to handle 'Next' button click
handleNext() {
    console.log(this.pageNumber);
    console.log(this.totalPages);
    if(this.pageNumber < this.totalPages) {
        this.pageNumber++;
        this.isLastPage = this.pageNumber === this.totalPages;
        this.isFirstPage = false;
        this.updateData();
    }
}

// Method to update the data displayed based on the current page number and page size
updateData() {
    this.totalPages =  Math.ceil(this.allData.length / this.pageSize);
    let start = (this.pageNumber - 1) * this.pageSize;
    let end = start + this.pageSize;
    this.Data = this.allData.slice(start, end);
}


}