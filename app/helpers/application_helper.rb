module ApplicationHelper
  def json_stringify(json_string, at=nil, pretty=false)
    begin
      json_obj = JSON.parse(json_string)
    rescue Exception => e
      raise "Error while parsing JSON string : #{e.message}, string : #{json_string}"
    end
    unless at.nil?
      json_obj = json_obj[at]
    end
    if pretty
      begin
        JSON.pretty_generate(json_obj)
      rescue
        json_obj.to_json
      end
    else
      json_obj.to_json
    end
  end
end
