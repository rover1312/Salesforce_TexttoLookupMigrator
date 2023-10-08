public class TexttoLookupController {
@AuraEnabled
public static void Confirm(String lookupFieldName , String textFieldName , String sObjectApi){
    TexttoLookupBatch batch = new TexttoLookupBatch(sObjectApi, textFieldName, lookupFieldName);
    Database.executeBatch(batch,20);
}
}