# SPDX-FileCopyrightText: 2022 Connor Rigby
# SPDX-FileCopyrightText: 2022 Digit
# SPDX-FileCopyrightText: 2024 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule ATECC508A.Certificate.TrustAndGoTemplate do
  @moduledoc """
  Certificate template for pre-provisioned ATECC608B-TNGTLS from Microchip
  (Also known as a Trust and Go provisioned chip)

  Details on the structure of the compressed certificate and how they map to a standard X.509 cert can be found on the datasheet:
  https://ww1.microchip.com/downloads/en/DeviceDoc/ATECC608B-TNGTLS-CryptoAuthentication-Data-Sheet-DS40002250A.pdf
  (Table 4-12 - Certificate Storage)

  Detailed information on the certificate compression process can be found here:
  http://ww1.microchip.com/downloads/en/Appnotes/20006367A.pdf
  """
  alias X509.Certificate.Extension

  @type signer_id :: 0..65535
  @type template_id :: 0..15
  @type chain_id :: 0..15
  @type ski :: binary()
  @type aki :: binary()

  defstruct [
    :signer_id,
    :template_id,
    :chain_id,
    :sn_source,
    :device_sn,
    :certificate_sn,
    extensions: []
  ]

  @type t() :: %__MODULE__{
          signer_id: signer_id,
          template_id: template_id,
          chain_id: chain_id,
          sn_source: ATECC508A.sn_source(),
          device_sn: ATECC508A.serial_number() | nil,
          certificate_sn: binary() | nil,
          extensions: [Extension.t()]
        }

  @spec signer(signer_id(), ski(), aki()) :: t()
  def signer(signer_id, ski, aki) do
    %__MODULE__{
      signer_id: signer_id,
      template_id: 1,
      chain_id: 0,
      sn_source: :public_key,
      device_sn: nil,
      extensions: [
        Extension.key_usage([:digitalSignature, :keyCertSign, :cRLSign]),
        Extension.basic_constraints(true, 0),
        Extension.subject_key_identifier(ski),
        Extension.authority_key_identifier(aki)
      ]
    }
  end

  @spec device(ATECC508A.serial_number(), signer_id, template_id, String.t(), ski, aki) :: t()
  # there is an error with Extension.subject_alt_name/1 below. The error technically
  # correct, however in reality the trust and go modules do break the specification
  @dialyzer {:nowarn_function, device: 6}
  def device(device_sn, signer_id, template_id, eui_serial, ski, aki) do
    %__MODULE__{
      signer_id: signer_id,
      template_id: template_id,
      chain_id: 0,
      sn_source: :device_sn,
      device_sn: device_sn,
      extensions: [
        # /serialNumber=serialnumber
        # this is an RDNSequence, however it contains characters that are technically not
        # allowed.
        Extension.subject_alt_name(
          directoryName:
            {:rdnSequence, [[{:AttributeTypeAndValue, {2, 5, 4, 5}, to_charlist(eui_serial)}]]}
        ),
        # CA=False Critical
        # X509 doesn't allow this field to be critical
        {:Extension, {2, 5, 29, 19}, true, {:BasicConstraints, false, :asn1_NOVALUE}},
        Extension.key_usage([:digitalSignature, :keyAgreement]),
        Extension.subject_key_identifier(ski),
        Extension.authority_key_identifier(aki)
      ]
    }
  end
end
