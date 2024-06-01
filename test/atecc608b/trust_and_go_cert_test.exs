defmodule ATECC608B.TrustAndGoCertTest do
  use ExUnit.Case

  # DER encoded, known good device certificate, this is the expected result of the decompression operation
  # This fixture was taken from a Trust and Go development kit.
  @device_cert_der <<48, 130, 2, 31, 48, 130, 1, 197, 160, 3, 2, 1, 2, 2, 16, 95, 35, 90, 189,
                     183, 43, 237, 52, 180, 55, 114, 231, 157, 64, 193, 28, 48, 10, 6, 8, 42, 134,
                     72, 206, 61, 4, 3, 2, 48, 79, 49, 33, 48, 31, 6, 3, 85, 4, 10, 12, 24, 77,
                     105, 99, 114, 111, 99, 104, 105, 112, 32, 84, 101, 99, 104, 110, 111, 108,
                     111, 103, 121, 32, 73, 110, 99, 49, 42, 48, 40, 6, 3, 85, 4, 3, 12, 33, 67,
                     114, 121, 112, 116, 111, 32, 65, 117, 116, 104, 101, 110, 116, 105, 99, 97,
                     116, 105, 111, 110, 32, 83, 105, 103, 110, 101, 114, 32, 50, 67, 48, 48, 48,
                     32, 23, 13, 50, 48, 49, 49, 49, 49, 48, 52, 48, 48, 48, 48, 90, 24, 15, 50,
                     48, 52, 56, 49, 49, 49, 49, 48, 52, 48, 48, 48, 48, 90, 48, 66, 49, 33, 48,
                     31, 6, 3, 85, 4, 10, 12, 24, 77, 105, 99, 114, 111, 99, 104, 105, 112, 32,
                     84, 101, 99, 104, 110, 111, 108, 111, 103, 121, 32, 73, 110, 99, 49, 29, 48,
                     27, 6, 3, 85, 4, 3, 12, 20, 115, 110, 48, 49, 50, 51, 65, 50, 51, 70, 50, 57,
                     70, 57, 51, 54, 54, 65, 48, 49, 48, 89, 48, 19, 6, 7, 42, 134, 72, 206, 61,
                     2, 1, 6, 8, 42, 134, 72, 206, 61, 3, 1, 7, 3, 66, 0, 4, 211, 48, 184, 178,
                     237, 228, 213, 2, 223, 72, 181, 74, 47, 41, 204, 121, 249, 1, 229, 148, 253,
                     107, 249, 45, 235, 109, 24, 122, 199, 127, 45, 187, 177, 96, 39, 154, 74, 32,
                     167, 230, 227, 80, 127, 151, 58, 173, 67, 145, 155, 239, 45, 28, 153, 178,
                     156, 21, 51, 35, 223, 205, 153, 16, 103, 105, 163, 129, 141, 48, 129, 138,
                     48, 42, 6, 3, 85, 29, 17, 4, 35, 48, 33, 164, 31, 48, 29, 49, 27, 48, 25, 6,
                     3, 85, 4, 5, 19, 18, 101, 117, 105, 52, 56, 95, 69, 56, 69, 66, 49, 66, 50,
                     48, 50, 48, 50, 55, 48, 12, 6, 3, 85, 29, 19, 1, 1, 255, 4, 2, 48, 0, 48, 14,
                     6, 3, 85, 29, 15, 1, 1, 255, 4, 4, 3, 2, 3, 136, 48, 29, 6, 3, 85, 29, 14, 4,
                     22, 4, 20, 151, 183, 73, 230, 144, 67, 143, 54, 169, 250, 252, 96, 146, 71,
                     159, 40, 22, 186, 201, 184, 48, 31, 6, 3, 85, 29, 35, 4, 24, 48, 22, 128, 20,
                     15, 98, 31, 244, 74, 181, 144, 211, 77, 4, 193, 243, 125, 246, 18, 203, 91,
                     181, 237, 52, 48, 10, 6, 8, 42, 134, 72, 206, 61, 4, 3, 2, 3, 72, 0, 48, 69,
                     2, 33, 0, 225, 151, 170, 38, 210, 208, 172, 148, 171, 77, 236, 194, 48, 85,
                     79, 86, 17, 205, 83, 174, 36, 173, 26, 226, 115, 126, 162, 214, 158, 202,
                     162, 173, 2, 32, 37, 208, 92, 14, 110, 165, 28, 96, 62, 90, 91, 132, 224, 76,
                     171, 81, 38, 198, 189, 179, 124, 137, 6, 161, 89, 96, 108, 52, 130, 176, 36,
                     175>>

  test "Decompress a Trust and Go certificate" do
    <<_pad1::4-bytes, signer_public_x::32-bytes, _pad2::4-bytes, signer_public_y::32-bytes>> =
      ATECC508A.Sim608BTNG.signer_pubkey()

    signer_public_key = signer_public_x <> signer_public_y

    device_public_key = ATECC508A.Sim608BTNG.genkey()

    aki = :crypto.hash(:sha, <<4>> <> signer_public_key)
    ski = :crypto.hash(:sha, <<4>> <> device_public_key)

    <<
      _compressed_signature::binary-size(64),
      _compressed_validity::binary-size(3),
      signer_id::size(16),
      template_id::size(4),
      _chain_id::size(4),
      _serial_number_source::size(4),
      _format_version::size(4),
      0::size(8)
    >> = ATECC508A.Sim608BTNG.device_cert()

    singer_id_string = Integer.to_string(signer_id, 16)

    template =
      ATECC508A.Certificate.TrustAndGoTemplate.device(
        ATECC508A.Sim608BTNG.serial_number(),
        signer_id,
        template_id,
        "eui48_#{ATECC508A.Sim608BTNG.mac()}",
        ski,
        aki
      )

    issuer_rdn =
      X509.RDNSequence.new(
        "/O=Microchip Technology Inc/CN=Crypto Authentication Signer #{singer_id_string}",
        :otp
      )

    subject_rdn =
      X509.RDNSequence.new(
        "/O=Microchip Technology Inc/CN=sn" <>
          Base.encode16(ATECC508A.Sim608BTNG.serial_number()),
        :otp
      )

    compressed = %ATECC508A.Certificate.Compressed{
      data: ATECC508A.Sim608BTNG.device_cert(),
      device_sn: ATECC508A.Sim608BTNG.mac(),
      public_key: device_public_key,
      template: template,
      issuer_rdn: issuer_rdn,
      subject_rdn: subject_rdn
    }

    decompressed = ATECC508A.Certificate.decompress(compressed)
    assert X509.Certificate.to_der(decompressed) == @device_cert_der
  end
end
