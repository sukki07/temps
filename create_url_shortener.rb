require 'aws-sdk'
require 'logger'
class UrlShortner
  attr_reader :slash_resource
  def initialize(region,name)
    @client = Aws::APIGateway::Client.new(region: region) 
    @api = ensure_api(name)
    @slash_resource = is_resource_present?("/") 
    if not @slash_resource
      raise Exception.new("Root resource not created,quitting.Most probably aws issue")
    end
  end
  def ensure_api(api_name)
    apis = @client.get_rest_apis({}).items
    api_obj = nil
    apis.each do |api|
      if api.name.eql?api_name
        api_obj = api
        $log.info "api with name #{api_name} found,not creating again"
        break
      end
    end
    if not api_obj
      api_obj = @client.create_rest_api({name: api_name})
    end
    return api_obj
  end

  def is_resource_present?(path_to_check)
    resources = @client.get_resources({rest_api_id:@api.id}).items
    resources.each do |resource|
      if resource.path.eql?path_to_check
        return resource 
      end
    end
    return nil
  end

  def ensure_resource(full_path,parent_resource)
    resource = is_resource_present?(full_path)
    if not resource
      $log.info "Creating resource #{full_path}"
      path_part = full_path.split("/").last
      resource =  @client.create_resource({rest_api_id:@api.id,parent_id:parent_resource.id,path_part:path_part})
    else
      $log.info "Resource #{full_path} already present"
    end
    return resource
  end
  def ensure_method(method_name,resource)
    params = {
      rest_api_id: @api.id, # required
      resource_id: resource.id, # required
      http_method: method_name # required
    }
    begin
      method = @client.get_method(params)
    rescue Aws::APIGateway::Errors::NotFoundException => e 
      $log.info "No method #{method_name} found on resource #{resource.path}"
    end
    if not method
      $log.info "Going to attach Method #{method_name} to resource #{resource.path}"
      return @client.put_method(params.merge({authorization_type: "NONE"}))
    else
      $log.info "Method #{method_name} is already attached to resource #{resource.path}"
      return method
    end
  end
  #after integraion , one has to go to UI and click tick mark , then only gateway gets permission to call lambda
  def ensure_integration(integration_params,resource)
    begin
      integration = @client.get_integration(rest_api_id:@api.id,resource_id:resource.id,http_method:integration_params[:http_method])
    rescue Aws::APIGateway::Errors::NotFoundException => e 
      $log.info "No integrations available for #{integration_params[:http_method]} on #{resource.path}"
    end
    if not integration
      $log.info "Going to create specified integration for  #{integration_params[:http_method]} on #{resource.path}"
      params =  
        {
        :rest_api_id => @api.id, # required
        :resource_id => resource.id, # required
      }.merge(integration_params) 
      return @client.put_integration(params)
    else
      $log.info "integration already present for #{integration_params[:http_method]} on #{resource.path}"
      return integration 
    end
  end

  def ensure_method_response(method_response_params,resource)
    begin
      method_response = @client.get_method_response({
      rest_api_id: @api.id, # required
      resource_id: resource.id, # required
      http_method: method_response_params[:http_method], # required
      status_code: method_response_params[:status_code] # required
    })
    rescue Aws::APIGateway::Errors::NotFoundException => e 
      $log.info "No #{method_response_params[:status_code]} Response availabe " 
    end
    if not method_response
    $log.info "Going to create #{method_response_params[:status_code]} method response for #{method_response_params[:http_method]} on #{resource.path}"
      return @client.put_method_response(
        {
        rest_api_id: @api.id, # required
        resource_id: resource.id
      }.merge(method_response_params)
      )
    else
      $log.info "method response for #{method_response_params[:status_code]} already configured on #{method_response_params[:http_method]} for #{resource.path}"
      return method_response
    end
  end

  def ensure_integration_response(integration_response_parameter_hash,resource)
    begin
      integration_response = @client.get_integration_response({
        rest_api_id: @api.id, # required
        resource_id: resource.id, # required
        http_method: integration_response_parameter_hash[:http_method], # required
        status_code: integration_response_parameter_hash[:status_code] # required
      })
    rescue Aws::APIGateway::Errors::NotFoundException => e
      $log.info "No integration response available for #{integration_response_parameter_hash[:status_code]} on #{integration_response_parameter_hash[:http_method]}"
    end
    if not integration_response 
      $log.info "Going to add integration response for #{integration_response_parameter_hash[:status_code]} on #{integration_response_parameter_hash[:http_method]}"
      return @client.put_integration_response(
        {
        rest_api_id: @api.id, # required
        resource_id: resource.id, # required
      }.merge(integration_response_parameter_hash))
    else
      $log.info "integration response already present on #{integration_response_parameter_hash[:status_code]} on #{integration_response_parameter_hash[:http_method]}"
      return integration_response
    end
  end
end

module GetOnSlashUShortcode
  def self.path
    "/u/{shortcode}"
  end
  def self.method
    "GET"
  end
  def self.integration
    lambda_arn = "arn:aws:lambda:ap-southeast-1:327453933654:function:sz_url_shortner_lambda" 
    uri = "arn:aws:apigateway:ap-southeast-1:lambda:path/2015-03-31/functions/#{lambda_arn}/invocations"
    request_template = {:'application/json'=>'{"shortcode":"$input.params(\'shortcode\')", "type":"ApiGatewayRequest", "http_method":"$context.httpMethod", "body" : $input.json(\'$\'), "headers": { #foreach($header in $input.params().header.keySet()) "$header": "$util.escapeJavaScript($input.params().header.get($header))" #if($foreach.hasNext),#end #end }, "params": { #foreach($param in $input.params().path.keySet()) "$param": "$util.escapeJavaScript($input.params().path.get($param))" #if($foreach.hasNext),#end #end }, "query": { #foreach($queryParam in $input.params().querystring.keySet()) "$queryParam": "$util.escapeJavaScript($input.params().querystring.get($queryParam))" #if($foreach.hasNext),#end #end}}'} 
    integration = {
      :type=>"AWS",
      :uri=>uri,
      :http_method=>"#{self.method}",
      :integration_http_method=> "#{self.method}",
      :request_templates=>request_template,
      :passthrough_behavior=>"NEVER"
    }
    return integration
  end
  def self.method_response(status_code)
    if status_code == "301"
      params =  {
        :http_method => self.method,
        :status_code => status_code,
        :response_parameters => {"method.response.header.Location"=>true} 
      }
      return params
    elsif  status_code == "404"
      params =  {
        :http_method => self.method,
        :status_code => status_code
      }
      return params
    end
  end
  def self.integration_response(status_code)
    if status_code == "301"
      return {
        :http_method =>self.method, 
        :status_code=> status_code, 
        :selection_pattern=> "-",
        :response_parameters=> {"method.response.header.Location"=>"integration.response.body.destination_url"},
        :response_templates=> {"application/json"=>'{"status":"successful redirection","destination_url":$input.json(\'$.destination_url\')}'}
      }
    elsif status_code == "404" 
      return {
        :http_method =>self.method, # required
        :status_code=> status_code, # required
        :selection_pattern=> "^Error.*",
        :response_templates=> {"application/json"=>'{"error":$input.json(\'$.errorMessage\')}'}
      }
    end
  end
end
module PostOnSlashU
  def self.path
    "/u"
  end
  def self.method
    "POST"
  end
  def self.integration
    lambda_arn = "arn:aws:lambda:ap-southeast-1:327453933654:function:sz_url_shortner_lambda" 
    uri = "arn:aws:apigateway:ap-southeast-1:lambda:path/2015-03-31/functions/#{lambda_arn}/invocations"
    request_template = {:'application/json'=>'{"http_method":"$context.httpMethod","body":$input.json(\'$\')}'}
    integration = {
      :type=>"AWS",
      :uri=>uri,
      :http_method=>"#{self.method}",
      :integration_http_method=>"#{self.method}",
      :request_templates=>request_template,
      :passthrough_behavior=>"NEVER"
    }
    return integration
  end

  def self.method_response(status_code)
    if status_code == "200"
      return {
        :http_method => self.method,
        :status_code => status_code
      }
    elsif  status_code == "404"
      return {
        :http_method => self.method,
        :status_code => status_code
      }
    end
  end

  def self.integration_response(status_code)
    if status_code == "200"
      return {
        :http_method =>self.method, 
        :status_code=> status_code, 
        :selection_pattern => "-",
        :response_templates=> {"application/json"=>'{"message":$input.json(\'$.message\'),"shortcode":$input.json(\'$.shortcode\')}'}
      }
    elsif status_code == "404"
      return {
        :http_method =>self.method, # required
        :status_code=> status_code, # required
        :selection_pattern=> "^Error.*",
        :response_templates=> {"application/json"=>'{"error":$input.json(\'$.errorMessage\')}'}
      }
    end
  end
end
$log = Logger.new(STDOUT)
shortner = UrlShortner.new("ap-southeast-1","check_it_out")
slash_u_resource                  = shortner.ensure_resource(PostOnSlashU.path,shortner.slash_resource)
slash_u_shortcode_resource        = shortner.ensure_resource(GetOnSlashUShortcode.path,slash_u_resource)
post_on_slash_u_resource          = shortner.ensure_method(PostOnSlashU.method,slash_u_resource)
get_on_slash_u_shortcode_resource = shortner.ensure_method(GetOnSlashUShortcode.method,slash_u_shortcode_resource)
integration_on_post               = shortner.ensure_integration(PostOnSlashU.integration,slash_u_resource)
integration_on_get                = shortner.ensure_integration(GetOnSlashUShortcode.integration,slash_u_shortcode_resource)
method_response_301_on_get        = shortner.ensure_method_response(GetOnSlashUShortcode.method_response("301"),slash_u_shortcode_resource)
method_response_404_on_get        = shortner.ensure_method_response(GetOnSlashUShortcode.method_response("404"),slash_u_shortcode_resource)
integration_response_301_on_get   = shortner.ensure_integration_response(GetOnSlashUShortcode.integration_response("301"),slash_u_shortcode_resource)
integration_response_404_on_get   = shortner.ensure_integration_response(GetOnSlashUShortcode.integration_response("404"),slash_u_shortcode_resource)
method_response_200_on_post       = shortner.ensure_method_response(PostOnSlashU.method_response("200"),slash_u_resource)
method_response_200_on_post       = shortner.ensure_method_response(PostOnSlashU.method_response("404"),slash_u_resource)
method_response_200_on_post       = shortner.ensure_integration_response(PostOnSlashU.integration_response("200"),slash_u_resource)
method_response_200_on_post       = shortner.ensure_integration_response(PostOnSlashU.integration_response("404"),slash_u_resource)

#api config , lambda config , dynamo config
