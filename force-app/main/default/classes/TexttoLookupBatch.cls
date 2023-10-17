global class TexttoLookupBatch implements Database.Batchable<sObject>, Database.Stateful {
    public string sObjectApi;
    public string TextField;
    public string LookupField;
    public string LookupObjectApI;
    public string FuzzyToggle;
    public boolean overWriteData;
    public List<String> ResultData = new List<String>();
    public List<String> fuzzyDict = new List<String>();
    
    
    
    public TexttoLookupBatch(String api ,String text ,String Lookup , String Toggle , List<String> dict , boolean OverwriteData){
        //variable assignment done here.
        this.sObjectApi = api;
        this.TextField = text;
        this.LookupField = Lookup;
        this.FuzzyToggle = Toggle;
        this.fuzzyDict = dict;
        this.overWriteData = OverwriteData;
        //fetch object and field here to get the lookup object.
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(this.sObjectApi);
        Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(this.LookupField);
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.SObjectType> referenceTo = fieldResult.getReferenceTo();
        for(Schema.SObjectType refObj : referenceTo){
            this.LookupObjectApI = refObj.getDescribe().getName();
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //initial search query.
        String query = 'Select id,'+this.TextField+','+this.LookupField+' '+' from '+ this.sObjectApi;
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        String TextField = this.TextField;
        List<String> textData = new List<String>();
        List<sObject> updateList = new List<sObject>();
        List<sObject> unMatchedList = new List<sObject>();
        //for 1:1 matching going through scope and adding all text values to list.
        for(sObject obj: scope){
            if(obj.get(TextField) != null){
                if(obj.get(this.LookupField) == null || this.overWriteData){
                    textData.add(String.valueOf(obj.get(TextField)));
                }
            }
        }
        //search based on above list.
        String textDataString = '\'' + String.join(textData, '\',\'') + '\'';
        String query = 'Select Id,Name from '+ this.LookupObjectApI + ' Where Name In ('+ textDataString + ')';
        System.debug(query);
        List<sObject> MatchedData = Database.query(query);
        System.debug('Matched data debug log: '+ MatchedData);
        //reusing same list to store the Name of the record from above query.
        textData.clear();
        for(sObject obj: MatchedData){
            textData.add(String.valueOf(obj.get('Name')));
        }
        //mapping of matched values done here.
        for(Integer i = 0; i < scope.size(); i++){
            sObject obj = scope[i];
            if(textData.contains(String.valueOf(obj.get(TextField)))){
                Integer index = textData.indexOf(String.valueOf(obj.get(TextField)));
                System.debug('Index: ' + index);
                System.debug(String.valueOf(obj.get(TextField)));
                if(index != -1 && index < MatchedData.size()){
                    if(obj.get(this.LookupField) == null){
                        obj.put(this.LookupField, MatchedData[index].Id);
                        System.debug('Matched Index Id ' + MatchedData[index].Id);
                    }    
                    updateList.add(obj);
                    System.debug(updateList.size()+ ' size of update List');
                }
            }
            else{
                System.debug('unmatched ' + String.valueOf(obj.get(TextField)));
                unMatchedList.add(obj);
                System.debug('size unmatched' + unMatchedList.size());
            }
        }
        String msg = '';
        
        if(this.FuzzyToggle == 'false'){
            
        }
        else{
            
            wrapperClass result = fuzzyMatchAndUpdate(unMatchedList,this.fuzzyDict);
            updateList.addall(result.list1);
            unMatchedList = result.list2;
            //String query2 = 'Select id,'+this.TextField+','+this.LookupField+' '+' from '+ this.sObjectApi + ' Where Id In: unMatchedList';
            //unMatchedList = database.query(query2);
            //Database.SaveResult[] srList = database.update(updateList,false);
            System.debug('size of List should be 2 ' + updateList.size());
            
            
        }
        
        //update operations performed below: 
        Database.SaveResult[] srList = database.update(updateList,false);
        for(Integer i = 0 ; i < srList.size() ; i++){
            if(srList[i].isSuccess()){
                msg =  'Success'+ ',' + srList[i].getId()+ ',' + String.valueOf(updateList[i].get(TextField)) + ',' + String.valueOf(updateList[i].get(this.LookupField)) + '\n';
                This.ResultData.add(msg);
                System.debug(msg);
            }
            else{
                String err1 = '';
                for(Database.Error err : srList[i].getErrors()) {
                    err1 += err.getMessage() + '::';
                }
                msg = err1+ ','+srList[i].getId() + ',' +String.valueOf(updateList[i].get(TextField)) + ',' + String.valueOf(updateList[i].get(this.LookupField))+'\n';
                this.ResultData.add(msg);
                System.debug(msg);
            }
        }
        
        for(sObject obj : unMatchedList){
            msg = 'No Match Found'+ ','+obj.id+',' +String.valueOf(obj.get(TextField)) + ',' +'\n';
            this.ResultData.add(msg);
        }
        
        System.debug('#################'+ this.ResultData);
        
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('In finish');
        
        // Create the CSV data
        String Header = 'Success/Error Message,Id,Text Field Value, Lookup Value\n';
        String Body = '';
        System.debug('size'+ This.ResultData.size());
        for (String Msg : this.ResultData) {
            System.debug(Msg);
            Body += Msg;
        }
        String csvData = Header + Body;
        System.debug('csvData' + csvData);
        
        Blob csvBlob = Blob.valueOf(csvData);
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Text_Lookup_Result' + datetime.now();
        cv.PathOnClient = cv.Title +'.csv';
        cv.VersionData = csvBlob;
        insert cv;
    }
    
    
    
    public WrapperClass fuzzyMatchAndUpdate(List<sObject> scope, List<String> fuzzyDict) {
        Map<String, Id> nameToIdMap = new Map<String, Id>();
        List<String> searchList = new List<String>();
        List<Id> recordIdList = new List<Id>();
        List<sObject> unmatched = new List<sObject>();
        List<sObject> updateList = new List<sObject>();
        List<sObject> scopeList = new List<sObject>();
        Map<Id, sObject> scopeMap = new Map<Id, sObject>();
        
        for(sObject obj: scope){
            scopeMap.put(obj.Id, obj);
            String textFieldValue = String.valueOf(obj.get(TextField));
            if((this.overWriteData || obj.get(this.LookupField) == null) && textFieldValue != null){
                for(String fuzzyKey: fuzzyDict){
                    String searchString = textFieldValue + fuzzyKey;
                    searchList.add(searchString.toLowerCase());
                    recordIdList.add(obj.Id);
                    scopeList.add(obj);
                }
            }
        }
        
        String searchString = '\'' + String.join(searchList, '\',\'') + '\'';
        String query = 'Select Id,Name from '+ this.LookupObjectApI + ' Where Name In ('+ searchString + ')';
        System.debug(query);
        for(sObject obj: Database.query(query)){
            system.debug('Searched value ' + String.valueOf(obj.get('Name')));
            nameToIdMap.put(String.valueOf(obj.get('Name')).toLowerCase(), obj.Id);
        }
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(this.sObjectApi);
        
        for(String key: nameToIdMap.keySet()){
            System.debug(key + 'Key##');
            Integer index = searchList.indexOf(key);
            if(index != -1){
                sObject record = scopeList.get(index);
                System.debug(record + 'record Id');
                if(record != null){
                    record.put(this.LookupField, nameToIdMap.get(key));
                    System.debug(String.valueOf(record.get(this.LookupField)) + 'lookup value after fuzzy');
                    updateList.add(record);
                    if(scopeMap.containsKey(record.Id)) {
                        scopeMap.remove(record.Id);
                    }
                }
            }
        }
        unmatched.addAll(scopeMap.values());
        return new WrapperClass(updateList, unmatched);
    }
    
    
    
}