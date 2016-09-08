require 'aws-sdk'
def ensure_api(client,api_name)
  apis = client.get_rest_apis({}).items
  api_obj = nil
  apis.each do |api|
    if api.name.eql?api_name
      api_obj = api
      break
    end
  end
  if not api_obj
    api_obj = client.create_rest_api({name: api_name})
  end
  slash_resource = is_resource_present?(client,api_obj,"/")
  if slash_resource
    return api_obj,slash_resource
  else
    raise Exception.new("Api created but root did not.Holy Moly!")
  end
end
def is_resource_present?(client,api,path_to_check)
  resources = client.get_resources({rest_api_id:api.id}).items
  resources.each do |resource|
    if resource.path.eql?path_to_check
      return resource 
    end
  end
  return nil
end
def ensure_resource(client,api,full_path,parent_resource)
  resource = is_resource_present?(client,api,full_path)
  if not resource
    path_part = full_path.split("/").last
    resource =  client.create_resource({rest_api_id:api.id,parent_id:parent_resource.id,path_part:path_part})
  end
  return resource

end
def ensure_method(client,api,slash_u_shortcode_resource,method_name)
  resp = client.put_method({
    rest_api_id: api.id, # required
    resource_id: slash_u_shortcode_resource.id, # required
    http_method: "GET", # required
    authorization_type: "NONE" # required
  })
end

def ensure_lambda_integration(client,api,slash_u_shortcode_resource,method_name,lambda_arn_uri)
  resp = client.put_integration({
    rest_api_id: api.id, # required
    resource_id: slash_u_shortcode_resource.id, # required
    http_method: method_name, # required
    type: "AWS", # required, accepts HTTP, AWS, MOCK
    integration_http_method: method_name,
    uri: lambda_arn_uri 
  })
end

def lambda_arn_uri
  lambda_arn_copy = "arn:aws:lambda:ap-southeast-1:327453933654:function:sz_url_shortner_lambda" 
  "arn:aws:apigateway:ap-southeast-1:lambda:path/2015-03-31/functions/#{lambda_arn_copy}/invocations"
end

def main()
  client = Aws::APIGateway::Client.new(region: 'ap-southeast-1')
  api,slash_resource           = ensure_api(client,"will_it_work")
  slash_u_resource            = ensure_resource(client,api,"/u",slash_resource)
  slash_u_shortcode_resource  = ensure_resource(client,api,"/u/{shortcode}",slash_u_resource)
  ensure_method(client,api,slash_u_shortcode_resource)

end
main
