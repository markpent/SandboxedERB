class Controller


  def url_for(options)
    "/#{options[:controller]}/#{options[:action]}/#{options[:id]}"
  end
  
  def base_url
    "http://some.url"
  end
end
