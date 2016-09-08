from __future__ import print_function
import boto3
import json
import md5
def base_62_encode_number(num):
  #not using zero , since causes confusion
  #can keep abcde in the beginning
  #have to add some salt to prevent iteration
  alphabet = "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  if num == 0:
      return alphabet[0]
  arr = []
  base = len(alphabet)
  while num:
      num, rem = divmod(num, base)
      arr.append(alphabet[rem])
  arr.reverse()
  return ''.join(arr)



def sanity_check_on_get(event):
  return True
def sanity_check_on_post(event):
  return True

def get_base_62_code_for_url(url):
  m = md5.new()
  m.update(url)
  hex_string = m.hexdigest()
  large_number = int(hex_string,16)
  base_62_string = base_62_encode_number(large_number)
  first_6_chars = base_62_string[:6]
  return first_6_chars


def process_get(event):
  if sanity_check_on_get(event) == True:
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('sz_url_shortner_table')
    shortcode = event['shortcode']
    result = table.get_item(Key={'code':shortcode})
    if 'Item' in result:
      url = result['Item']['url']
      return {'destination_url':url,'message':'redirecting to '+url}
    else:
      raise Exception('Error:ResourceNotFound')
  else:
    raise Exception('Error:InvalidRequest')



def process_post(event):
  if sanity_check_on_post(event) == True:
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('sz_url_shortner_table')
    url_to_be_saved = event['body']['url']
    result = table.query(IndexName='url-index',Select='ALL_ATTRIBUTES',KeyConditions={'url':{'AttributeValueList':[url_to_be_saved],'ComparisonOperator':'EQ'}})
    
    if len(result['Items']) > 0:
      #url is present already,return the old code
      shortcode = result['Items'][0]['code']
      return {'message':'url already indexed,returning previous code','shortcode':shortcode}
    else:
      print("New url will be indexed")
      rehashcode = url_to_be_saved
      collision_flag = False
      while True:
        rehashcode = get_base_62_code_for_url(rehashcode)
        result = table.get_item(Key={'code':rehashcode})
        if 'Item' in result:
          print("Whoa! it has collided with a previous url.rehashing it")     
          collision_flag = True
        else:
          table.put_item(Item={'code':rehashcode,'url':url_to_be_saved})
          if collision_flag == True:
            return {'message':'saved after collision,lucky you','shortcode':rehashcode}
          else:
            return {'message':'saved successfully','shortcode':rehashcode}
  else:
    raise Exception('Error:InvalidPostRequest')


def lambda_handler(event, context):
  print("Received event: " + json.dumps(event, indent=2))
  if event['http_method'] == 'GET':
    return process_get(event)
  elif event['http_method'] == 'POST':
    return process_post(event)
  else:
    raise Exception('Error:MethodNotSupported')
