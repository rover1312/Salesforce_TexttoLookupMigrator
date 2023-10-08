global class TexttoLookupBatch implements Database.Batchable<sObject> {
    public string sObjectApi;
    public string TextField;
    public string LookupField;
    public string LookupObjectApI;
    public Boolean FuzzyToggle;
    
    
    public TexttoLookupBatch(String api ,String text ,String Lookup){
        this.sObjectApi = api;
        this.TextField = text;
        this.LookupField = Lookup;
        
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
                    obj.put(LookupField, MatchedData[index].Id);
                    updateList.add(obj);
                }
            }
        }
        database.update(updateList,false);
        
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
    
    
    public void fuzzyMatchAndUpdate(List<sObject> scope, List<String> fuzzyDict) {
    Map<String, Id> nameToIdMap = new Map<String, Id>();
    Map<String, Id> searchToRecordIdMap = new Map<String, Id>();
    List<String> searchList = new List<String>();

    for(sObject obj: scope){
        String textFieldValue = String.valueOf(obj.get(TextField));
        if(obj.get(LookupField) == null && textFieldValue != null){
            for(String fuzzyKey: fuzzyDict){
                String searchString = textFieldValue + fuzzyKey;
                searchList.add(searchString);
                searchToRecordIdMap.put(searchString, obj.Id);
            }
        }
    }

    String searchString = '\'' + String.join(searchList, '\',\'') + '\'';
    String query = 'Select Id,Name from '+ this.LookupObjectApI + ' Where Name In ('+ searchString + ')';
    System.debug(query);
    for(sObject obj: Database.query(query)){
        nameToIdMap.put(String.valueOf(obj.get('Name')), obj.Id);
    }
	Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectApi);
    List<sObject> updateList = new List<sObject>();
    for(String key: nameToIdMap.keySet()){
        Id recordId = searchToRecordIdMap.get(key);
        if(recordId != null){
			sObject obj = targetType.newSObject(recordId);
            obj.put(LookupField, nameToIdMap.get(key));
            updateList.add(obj);
        }
    }
    
    database.update(updateList,false);
}
}