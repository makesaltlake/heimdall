# A mixin for any API controller representing a resource that needs access to wireless credentials
module Api::Ext::HasWirelessCredentials
  def wireless_credentials
    render json: {
      wireless_credentials: WirelessCredentialSet.most_recent_first.map do |wireless_credential_set|
        {
          ssid: wireless_credential_set.ssid,
          password: wireless_credential_set.password
        }
      end
    }
  end
end
