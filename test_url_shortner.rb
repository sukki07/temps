require 'rest-client'
require 'json'
#get a link Test location header and status code
#post a link Test response body, get the same link 
#post a link , post it again 
#all kinds of sanity checks on post and get , with without auth header and content_types and malformatted urls
#also keep
#get on empty link must not be allowed or must redirect to stayzilla.com

def post(resource_url,body,headers)
  res = RestClient::Request.execute(
    method: :post, 
    url: resource_url,
    payload: body , 
    headers: headers
  )
end

def scene1
  resource_url = "https://ilstdusgw4.execute-api.ap-southeast-1.amazonaws.com/prod/u/"
  url_to_be_saved = "http://ghchecks.stayzilla.com/"
  body =  "{\"url\":\"#{url_to_be_saved}\"}"
  headers = {:Authorization=>"st.z.la",:content_type=>"application/json"}
  response = post(resource_url,body,headers)
end
scene1



