module ApplicationHelper
  def json_stringify(json_string, at=nil, pretty=false)
    json_obj = JSON.parse(json_string)
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
