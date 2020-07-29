def get_data_from_api (url)
    response_string = RestClient.get(url)
    response_hash = JSON.parse(response_string)
  end