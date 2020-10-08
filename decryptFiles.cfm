<cfscript>
    cfparam(name="URL.iv", type="numeric", default="0");
    cfparam(name="URL.secretKey", type="string", default="");

    fragmentDir = getDirectoryFromPath(getCurrentTemplatePath()) & "/Fragments/";
    decodedDir = getDirectoryFromPath(getCurrentTemplatePath()) & "/Decoded/";

    /*
        An EXT-X-KEY tag with a KEYFORMAT of "identity" that does not have an
        IV attribute indicates that the Media Sequence Number is to be used
        as the IV when decrypting a Media Segment, by putting its big-endian
        binary representation into a 16-octet (128-bit) buffer and padding
        (on the left) with zeros.
   */

    iv = URL.iv;
    secretKeyHex = URL.secretKey;
    binaryKey = binaryDecode(secretKeyHex, "hex");
    ivBinary = null;

    if (iv EQ 0)
        ivBinary = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    else
        ivBinary = binaryDecode(iv, "hex");

    files = directoryList(
        path=fragmentDir,
        type="file",
        listInfo="name",
        filter="fragment_*"
    );

    secretKey = createObject("java", "javax.crypto.spec.SecretKeySpec").init(binaryKey, "AES");
    iv = createObject("java", "javax.crypto.spec.IvParameterSpec").init(ivBinary);

    cipherFacade = createObject("java", "javax.crypto.Cipher");
    cipher = cipherFacade.getInstance("AES/CBC/PKCS5Padding");
    cipher.init(cipherFacade.DECRYPT_MODE, secretKey, iv);

    for(fileName in files) {

        inputData = fileReadBinary(fragmentDir & fileName);
        outputBytes = cipher.doFinal(inputData);

        outputFile = fileOpen(decodedDir & fileName, "write");
        fileWrite(outputFile, outputBytes);
        fileClose(outputFile);
    }
</cfscript>

<!--- https://tools.ietf.org/html/rfc8216#section-4.3.2.4 --->
<!--- https://docs.oracle.com/javase/7/docs/api/javax/crypto/spec/IvParameterSpec.html#IvParameterSpec(byte[]) --->
<!--- https://docs.oracle.com/javase/7/docs/api/javax/crypto/Cipher.html#doFinal() --->
<!--- https://stackoverflow.com/questions/39276955/java-cipher-padding-error --->
<!--- https://stackoverflow.com/questions/6669181/why-does-my-aes-encryption-throws-an-invalidkeyexception --->
<!--- https://stackoverflow.com/questions/50628791/decrypt-m3u8-playlist-encrypted-with-aes-128-without-iv --->