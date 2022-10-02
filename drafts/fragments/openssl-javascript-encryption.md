I wanted to pass encrypted files between a webserver and javascript running in the webpage. That's not easy, since it requires different libraries and it seems like standards adherence doesn't go as far as consistent interfaces.

So this is something that worked. [Source.](https://stackoverflow.com/questions/32654749/decrypt-openssl-aes-with-cryptojs)


```shell
encryptfile() {

  inputfile="$1"
  outputfile="$2"
 
  openssl enc -aes-128-ctr \
    -in "$inputfile" -out "$outputfile" \
    -base64 -A \
    -K 0123456789abcdef0123456789abcdef \
    -iv 00000000000000000000000000000000

}
```

```JavaScript
<!DOCTYPE html>
<html>

<head>
  <title>passwords</title>
</head>


<body>

  <script src="crypto-js.js"></script>

  <script>

    function hex2a(hex) {
      let str = '';
      for (let i = 0; i < hex.length; i += 2) {
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
      }
      return str;
    }

    var decoded = CryptoJS.AES.decrypt(
      "GM+oq1ZS3eWg+7kOY25o", 
      CryptoJS.enc.Hex.parse("0123456789abcdef0123456789abcdef"), 
      { 
        iv: CryptoJS.enc.Hex.parse("00000000000000000000000000000000"), 
        padding: CryptoJS.pad.NoPadding, 
        mode: CryptoJS.mode.CTR 
      }
    );

    console.log('decoded:');
    console.log(hex2a(decoded.toString()));

  </script>

</body>

</html>
```


openssl encryption -> cryptojs decryption
-----------------------------------------

```sh
openssl enc -aes-256-cbc -in file.txt -out file.enc -k password
```

```javascript
fs.readFile('file.enc', function(err, data) {
  var salt          = data.toString("hex", 8, 16),
      enc           = data.toString("hex", 16, data.length),
      derivedParams = CryptoJS.kdf.OpenSSL.execute(
                        password,
                        256/32,
                        128/32,
                        CryptoJS.enc.Hex.parse(salt)
                      ),
      cipherParams  = CryptoJS.lib.CipherParams.create({
                       ciphertext : CryptoJS.enc.Hex.parse(enc)
                     }),
      decrypted     = CryptoJS.AES.decrypt(
                        cipherParams,
                        derivedParams.key,
                        { iv : derivedParams.iv }
                      );

  console.log(hex2a(decrypted.toString())); // result is in hexa
});
```

cryptojs decryption -> openssl encryption
-----------------------------------------

```JavaScript
fs.readFile('file.txt', function(err, data) {
  var encrypted = CryptoJS.AES.encrypt(data.toString(), password);
      buff      = new Buffer(encrypted.toString(), "base64");

  fs.writeFile('file.enc', buff);
});
```

```sh
openssl enc -d -aes-256-cbc -in file.enc -out file2.txt -k password
```

