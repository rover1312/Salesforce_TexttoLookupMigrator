global class TexttoLookupBatch implements Database.Batchable<sObject> {
    public string sObjectApi;
    public string TextField;
    public string LookupField;
    public string LookupObjectApI;
    public string FuzzyToggle;
    public List<String> ResultData = new List<String>();
    public List<String> fuzzyDict = new List<String>();

    
    
    public TexttoLookupBatch(String api ,String text ,String Lookup , String Toggle , List<String> dict){
        this.sObjectApi = api;
        this.TextField = text;
        this.LookupField = Lookup;
        this.FuzzyToggle = Toggle;
        this.fuzzyDict = dict;
        
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(this.sObjectApi);
        System.debug(' objectType '+sObjectType);
        Schema.SObjectField field = sObjectType.getDescribe().fields.getMap().get(this.LookupField);
        System.debug(field);
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        System.debug(fieldResult);
        List<Schema.SObjectType> referenceTo = fieldResult.getReferenceTo();
        for(Schema.SObjectType refObj : referenceTo){
            this.LookupObjectApI = refObj.getDescribe().getName();
            system.debug(this.LookupObjectApI);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        String query = 'Select id,'+this.TextField+','+this.LookupField+' '+' from '+ this.sObjectApi;
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        String TextField = this.TextField;
        List<String> textData = new List<String>();
        List<sObject> updateList = new List<sObject>();
        List<sObject> unMatchedList = new List<sObject>();
        
        for(sObject obj: scope){
            if(obj.get(TextField) != null){
                textData.add(String.valueOf(obj.get(TextField)));
            }
        }
        String textDataString = '\'' + String.join(textData, '\',\'') + '\'';
		String query = 'Select Id,Name from '+ this.LookupObjectApI + ' Where Name In ('+ textDataString + ')';
		System.debug(query);
		List<sObject> MatchedData = Database.query(query);

        textData.clear();
        for(sObject obj: MatchedData){
            textData.add(String.valueOf(obj.get('Name')));
        }
        
        for(Integer i = 0; i < scope.size(); i++){
            sObject obj = scope[i];
            if(textData.contains(String.valueOf(obj.get(TextField)))){
                Integer index = textData.indexOf(String.valueOf(obj.get(TextField)));
                if(index != -1 && index < MatchedData.size()){
                    system.debug('outside If'+String.valueOf(obj.get(this.LookupField)));
                    if(String.valueOf(obj.get(this.LookupField))=='null'){
                        obj.put(this.LookupField, MatchedData[index].Id);
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
            Database.SaveResult[] srList = database.update(updateList,false);
            for(Integer i = 0 ; i < srList.size() ; i++){
                if(srList[i].isSuccess()){
                    msg =  'Success'+ ',' + srList[i].getId()+ ',' + String.valueOf(updateList[i].get(TextField)) + ',' + String.valueOf(updateList[i].get(this.LookupField)) + '\n';
                    ResultData.add(msg);
                    System.debug(msg);
                }
                else{
                    String err1 = '';
                    for(Database.Error err : srList[i].getErrors()) {
                        err1 += err.getMessage() + '::';
                    }
                    msg = err1+ ','+srList[i].getId() + ',' +String.valueOf(updateList[i].get(TextField)) + ',' + String.valueOf(updateList[i].get(this.LookupField))+'\n';
                    ResultData.add(msg);
                    System.debug(msg);
                }
            }
    
            for(sObject obj : unMatchedList){
                msg = 'No Match Found'+ ','+obj.id+',' +String.valueOf(obj.get(TextField)) + ',' +'\n';
                ResultData.add(msg);
            }
        }
        else{
            
            List<sObject> fuzzyList = fuzzyMatchAndUpdate(unMatchedList,this.fuzzyDict);
            updateList.addall(fuzzyList);
            Database.SaveResult[] srList = database.update(updateList,false);
            System.debug('size of List should be 2 ' + updateList.size());
            
            
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {

        System.debug('In finish');

        
    }
    
    
public List<sObject> fuzzyMatchAndUpdate(List<sObject> scope, List<String> fuzzyDict) {
    Map<String, Id> nameToIdMap = new Map<String, Id>();
    Map<String, Id> searchToRecordIdMap = new Map<String, Id>();
    List<String> searchList = new List<String>();

    for(sObject obj: scope){
        String textFieldValue = String.valueOf(obj.get(TextField));
        if(obj.get(this.LookupField) == null && textFieldValue != null){
            for(String fuzzyKey: fuzzyDict){
                String searchString = textFieldValue + fuzzyKey;
                searchList.add(searchString.toLowerCase());
                searchToRecordIdMap.put(searchString.toLowerCase(), obj.Id);
                
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
    List<sObject> updateList = new List<sObject>();
    for(String key: nameToIdMap.keySet()){
        System.debug(key + 'Key##');
        System.debug('#############' + searchToRecordIdMap);
        Id recordId = searchToRecordIdMap.get(key);
        System.debug(recordId + 'record Id');
        if(recordId != null){
			sObject obj = targetType.newSObject(recordId);
            obj.put(this.LookupField, nameToIdMap.get(key));
            System.debug(String.valueOf(obj.get(this.LookupField)) + 'lookup value after fuzzy');
            updateList.add(obj);
        }
    }
        System.debug('######Return' + updateList.size());
    Return updateList;
    //database.update(updateList,false);
}

}