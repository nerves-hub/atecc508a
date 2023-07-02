# Run `mix dialyzer --format short` for strings
[
  {"lib/atecc508a/certificate.ex:33:unknown_type Unknown type: :public_key.ec_public_key/0."},
  {"lib/atecc508a/certificate.ex:37:unknown_type Unknown type: :public_key.ec_private_key/0."},
  {"lib/x509/certificate.ex:20:unknown_type Unknown type: X509.ASN1.record/1."},
  {"lib/x509/certificate/extension.ex:12:unknown_type Unknown type: X509.ASN1.record/1."},
  {"lib/x509/certificate/validity.ex:15:unknown_type Unknown type: X509.ASN1.record/1."},
  {"lib/x509/public_key.ex:9:unknown_type Unknown type: :public_key.ec_public_key/0."},
  {"lib/x509/public_key.ex:9:unknown_type Unknown type: :public_key.rsa_public_key/0."}
]
