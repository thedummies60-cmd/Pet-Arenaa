import com.android.apksig.ApkSigner;
import com.android.apksig.ApkVerifier;

import java.io.File;
import java.io.FileInputStream;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.X509Certificate;
import java.util.Collections;

/** Signs an APK (v2 scheme; minSdk 24 needs no v1) with a PKCS12 keystore and verifies the result. */
public class Sign {
    public static void main(String[] args) throws Exception {
        // args: keystore password alias in.apk out.apk
        char[] pass = args[1].toCharArray();
        KeyStore ks = KeyStore.getInstance("PKCS12");
        try (FileInputStream in = new FileInputStream(args[0])) {
            ks.load(in, pass);
        }
        PrivateKey key = (PrivateKey) ks.getKey(args[2], pass);
        X509Certificate cert = (X509Certificate) ks.getCertificate(args[2]);
        ApkSigner.SignerConfig signer =
                new ApkSigner.SignerConfig.Builder("petarena", key, Collections.singletonList(cert)).build();
        new ApkSigner.Builder(Collections.singletonList(signer))
                .setInputApk(new File(args[3]))
                .setOutputApk(new File(args[4]))
                .setMinSdkVersion(24)
                .setV1SigningEnabled(false)
                .build()
                .sign();
        ApkVerifier.Result r = new ApkVerifier.Builder(new File(args[4])).build().verify();
        System.out.println("verified=" + r.isVerified() + " v1=" + r.isVerifiedUsingV1Scheme()
                + " v2=" + r.isVerifiedUsingV2Scheme() + " errors=" + r.getErrors());
        if (!r.isVerified()) System.exit(1);
    }
}
