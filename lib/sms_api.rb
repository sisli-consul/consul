class SMSApi
  attr_accessor :client

  def initialize
    @client = Savon.client(wsdl: url)
  end

  def url
    return "" unless end_point_available?

    Rails.application.secrets.sms_end_point
  end

  def sms_deliver(phone, code)
    return stubbed_response unless end_point_available?

    response = client.call(:send_sms, xml: xml_request(phone, code))
    success?(response)
  end

  def xml_request(phone, code)
    "<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns='#{Rails.application.secrets.sms_xmlns}'>
       <soapenv:Header/>
       <soapenv:Body>
         <sendSms>
           <requestXml>
             <![CDATA[
               <SendSms>
                 <Username>#{Rails.application.secrets.sms_username}</Username>
                 <Password>#{Rails.application.secrets.sms_password}</Password>
                 <UserCode>#{Rails.application.secrets.sms_user_code}</UserCode>
                 <AccountId>#{Rails.application.secrets.sms_account_id}</AccountId>
                 <Originator>#{Rails.application.secrets.sms_originator}</Originator>
                 <SendDate></SendDate>
                 <ValidityPeriod>300</ValidityPeriod>
                 <MessageText>#{t("verification.api_message", url: Setting["url"], code: code)}</MessageText>
                 <IsCheckBlackList>0</IsCheckBlackList>
                 <ReceiverList>
                   <Receiver>#{phone}</Receiver>
                 </ReceiverList>
               </SendSms>
             ]]>
             </requestXml>
         </sendSms>
       </soapenv:Body>
     </soapenv:Envelope>"
  end

  def success?(response)
    response.body[:send_sms_response][:send_sms_result][:error_code] == "0"
  end

  def end_point_available?
    Rails.env.staging? || Rails.env.preproduction? || Rails.env.production?
  end

  def stubbed_response
    {
      send_sms_response: {
        send_sms_result: {
          error_code: "0",
          packet_id: "361304601",
          message_id_list: { message_id: "8139550551" }
        }
      }
    }
  end
end
