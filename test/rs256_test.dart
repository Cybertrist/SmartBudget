// La signature RS256 en Dart, comparée à celle d'OpenSSL. Pas besoin
// d'appareil : ce test tourne sur la machine, par flutter test.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/banque/rs256.dart';

void main() {
  test("la signature RS256 est celle d'OpenSSL", () async {
    // Une clé jetable, générée pour ce test : jamais celle du compte.
    const pem = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDwenZow46TR/ZC
uQVeHSlZBnOn/ZQjT6xEl4NlKDRpNIe0jEq0uqvdigz2dpE66ReNyZ+x8adg6m9S
fB16ckFf4cFUkOF7aSn8HAsZt+nY7m/phYyID3ZbbPmVdrmxaGFjDFMiqa3pm0OU
GJpEOIhHyiMncApxnD7WohSTpTqvHYjSSfROCdK8hiylOiaVXRv2xmzJVKvZqRfs
Gu43J++YoRqaWWwnqIRfpmScsIrqMCPCxOKoaPUvpTr6+ThcUSFf6ObjgeqSHonP
yVaMiap1PUfYPj7y6veNll81SVoJkPm1sCjN3n3jEvSLdGHPBbF0wdEOZ/qGTB1P
5NoZNFSJAgMBAAECggEANqN0hPAt1Fvs4ZMdW5lfnCkhnSE6B93h48HTKmg8pEy5
qrWXgcHKK+9ia5tb+xkb72zIuosP/y609XZa0kfkf68RGLBEcyBdWDlc8k59tPrT
9aiQ2hc9Sp+Tg7iyj1MKkZEq0HziFWpgK+V9I5P+ruUIIL1NuiuIgYbZCwTnNQMd
ohpdD8FPPrCa4XHKpm033gn3gpbiZU5k0fvtmvmoappBYxAgM1ODRix05C6fwYtg
JYPtGWK7X8jTgDsYZ68AVMt2pYVDbWbS2qb/agsl4KbkZa7ZUo8SLQu0nYdFWr+U
VAsnNFqv8YqTzwjdOzHxxpT3ytAz5WaioutjF32YSwKBgQD6u78Vr+Zb/G0qVjvr
kYJ9I8JRTsXd3JCeINsoIkfLP66hlqOH8j+tKNNrqLGIpGuyIbu23fNlg9sBpCID
4MTTj+v/Fl01gHhoRUB1C2Rn5i/L9pJ5f2jekb7n6VbUUj18GfFE0I6ocB/Smfp4
0e383TqOwcnw5dXMXEBQj/ZQ+wKBgQD1h5KLBwEfXNL3hznIVuuTT0itbkI2uoos
iwPQhNORWZSPh+AGYP8iBc4mIboe9Gubz9lOW+QENTh/jRJaMosKQmNc+8Lx5o1u
GSnZmp1bdN1GtqSyVcjmRgCLPoFJwhKHWq6l9/eJzK8UeKWMQMijn268jEevs420
nSGeYjrhSwKBgQCZ7qfKvboUYS34HwccgbH19/01g8IQingyzIMf6aPgEVG6HMx7
Cuuy+GyMHP4ZoLAJpZIkG7FxcnkDUewcK2NLa4F8kxNYZG4HvfRrpznWW8ieVNvq
QaF1e08T+/p10aOzzA2GrO/YUzYGSsguYtvUMVHhEPJUthYDJ+PIUgnr/wKBgQDS
NFt1w21mmGXVnWQO7LuKxpoGQRtXF6UsNWfyoYUwL21M5JsbWveS/T1c0As0bTWj
k/MLbwhrwdS4/uHzbsoy4luHQ9PGngf/dnOp5QFLR2YaIEwokeEJpGzayYyOxSRv
1WcomH7I7wAFmrTAusYLr3dy3PaSqjprowshOiAGuQKBgDDC6ac3xOF5DAh0//ek
HJroAylD+2O5BxM4+xpLRjs3bsUosgwsTw7ekd7LG/CjsyK3mjg8ceXhPvCBSH01
5TT2dffOocSmUsPuHgIkkutcyDh8VAUYH5UJswPU5YM2N9mJKeA7cVPaWeWzBM/G
1KB6OV8+e2+RskyXZwQ0Wdol
-----END PRIVATE KEY-----''';
    final signature = signerRs256(pem, 'eyJhIjoxfQ.eyJiIjoyfQ');
    expect(base64Url.encode(signature).replaceAll('=', ''), '0sN5uGxXVPOGKQUTXb5kkzOEZOxOcY7Do2ehJATj4ZNB7s7kgwdj0fvg7OGmD2LBSfdii4ktGB0F7wk4sGo1qE0aVIoEclRh05O8CAONu4XBYrZwDA0fDeoJx-PPbJ2mN7GidqjMKLTtu5oPiT_9BkjqQIFXTnaCkYbNjBd-4wC5tRpE0IRtSKVocd04i7v4Y70wS5Gwj8Vedki5QSVLQwcU6on2_YcSUIDaCGFePCYxsTmeYgj71M7w__aceSNAfpfC6ekoTAT9IqRRWWmziZxAIjmIUrbWXBsAXAV19smkQHwdHS6lFaYcOhd6OENSSJ5-JXUV_vK180eFNwyYhQ');
  });
}
