@isTest
public class EncryptionUtilsTest {
    
	@isTest
    static void testEncryptionKey() {
        Blob key = EncryptionUtils.generateKey('Gusto Test');
        
        Blob savedKey = EncryptionUtils.getEncryptionKey('Gusto Test');
        
        system.assert(key==savedKey);

    }
    
    @isTest
    static void testEncryptionData() {
        Blob key = EncryptionUtils.generateKey('Gusto Test');
        
        Blob encryptedBlob = EncryptionUtils.getEncryptedBlob(key, 'This is a test');
        
        String decryptedText = EncryptionUtils.getDecryptedText(key, encryptedBlob);
        
        system.assert('This is a test'==decryptedText);

    }
}