function hex2a(hex) {
    let str = '';
    for (let i = 0; i < hex.length; i += 2) {
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    }
    return str;
}


function decrypt(encryptedtext, rawkey) {

    // var rawkey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
    // var passphrase = "koinonia";

    // var rawkey = CryptoJS.PBKDF2(
    //   passphrase, 
    //   salt, 
    //   { 
    //     hasher: CryptoJS.algo.SHA512, 
    //     keySize: 64/8, 
    //     iterations: 999
    //   }
    // );

    console.log('raw key:');
    console.log(rawkey);

    var decoded = CryptoJS.AES.decrypt(
        encryptedtext,
        CryptoJS.enc.Hex.parse(rawkey),
        {
            iv: CryptoJS.enc.Hex.parse("00000000000000000000000000000000"),
            padding: CryptoJS.pad.NoPadding,
            mode: CryptoJS.mode.CTR
        }
    );

    return decoded;

}