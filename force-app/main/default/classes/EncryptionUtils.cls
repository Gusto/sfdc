public class EncryptionUtils {
	public static Blob generateKey(String keyName) {
		List<Key_Master__c> keyList = new List<Key_Master__c>([SELECT Id FROM Key_Master__c WHERE Key_Name__c = :keyName]);
		if (keyList.size() == 0) {
			Blob key = Crypto.generateAesKey(256);
			Key_Master__c mstr = new Key_Master__c();
			mstr.Key_Name__c = keyName;
			insert mstr;
			Attachment atch = new Attachment();
			atch.ParentId = mstr.id;
			atch.Body = key;
			atch.Name = 'key.txt';
			insert atch;

			return key;
		}
		return null;
	}

	public static Blob getEncryptionKey(String keyName) {
		List<Key_Master__c> keyList = new List<Key_Master__c>([SELECT Id FROM Key_Master__c WHERE Key_Name__c = :keyName]);
		if (keyList.size() > 0) {
			List<Attachment> atchment = new List<Attachment>([SELECT Id, Body FROM Attachment WHERE ParentId = :keyList[0].Id]);
			if (atchment.size() > 0) {
				return atchment[0].Body;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}

	public static Blob getEncryptedBlob(Blob secretKey, String Input) {
		Blob data = Blob.valueOf(Input);
		Blob encryptedData = Crypto.encryptWithManagedIV('AES256', secretKey, data);

		return encryptedData;
	}

	public static String getDecryptedText(Blob secretKey, Blob encryptedText) {
		Blob decryptedData = Crypto.decryptWithManagedIV('AES256', secretKey, encryptedText);
		return decryptedData.toString();
	}
}