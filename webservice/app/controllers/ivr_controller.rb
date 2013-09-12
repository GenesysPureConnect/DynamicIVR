require 'json'

class IvrController < ApplicationController
  include WashOut::SOAP
  include IvrHelper
  
  soap_action "get_next_action",
              :args   => {:currentposition =>:string, 
                          :menu=>:integer,
                          :callIdKey => :string},
              :return =>{:type => :string,
                          :id => :string,
                          :attribute=>:string,
                          :value=>:string,
                          :destination=>:string}
  def get_next_action
    puts params.inspect
    currentId = params[:currentposition]
    menuId = params[:menu]
    ivrData = get_configuration
    menu = get_menu menuId, ivrData
    
    if(menu != nil)
      nextNode = next_node menu, currentId
    end 
    
    if(menuId == 2)
      nextNode = play_time(currentId)
    elsif(menuId == 3)
      menu3 = Menu3.new
      nextNode= menu3.get_next_action params[:callIdKey], currentId
    end
    
    if(nextNode == nil)
      #no more actions to do, lets delete this interaction
      interaction = Interaction.find_by interactionid: params[:callIdKey]
      if(interaction != nil)
        interaction.delete
      end
    end
    render :soap => nextNode
  end


  soap_action "set_attributes",
              :args   => {:keys =>:string, 
                          :values=>:string,
                          :callIdKey => :string},
              :return =>nil
  def set_attributes
    store_attributes params[:callIdKey], params[:keys], params[:values]
    render :soap => nil
  end
  
  soap_action "digits_received",
              :args   => {:digits =>:string, 
                          :callIdKey => :string},
              :return =>nil
  def digits_received
    update_digits(params[:callIdKey], params[:digits])
    render :soap => nil
  end
  
  def update_digits(callIdKey, digits)
    puts "updating #{callIdKey} to #{digits}"
    interaction = Interaction.find_by interactionid: callIdKey
    if(interaction == nil)
      interaction = Interaction.create
      interaction.interactionid = callIdKey
    end
    
    interaction.digits = digits
    interaction.save!
  end
  
  def store_attributes(callIdKey, keys, values)
    keyArray = keys.split '|'
    valueArray = values.split '|'
    
    interaction = Interaction.find_by interactionid: callIdKey
    
    if(interaction == nil)
      interaction = Interaction.create
      interaction.interactionid = callIdKey
      interaction.save!
    end
    
    (0..keyArray.count-1).each do |i|
      if(keyArray.count > i && valueArray.count > i)
        attr = InteractionAttribute.create
        attr.key = keyArray[i];
        attr.value = valueArray[i];
        attr.interaction_id  = interaction.id
        attr.save!
      end
    end
    
  end
  
  def get_attribute(callIdKey, attribute)
    interaction = Interaction.find_by interactionid: callIdKey
    attribute = InteractionAttribute.where(:interaction_id => interaction.id,:key => attribute).take 
    return attribute.value
  end

  def get_configuration    
     JSON.parse '{"menu":[{"key":1,"id":"E599819C-38A8-464F-A9A4-C12F1C42654F","subitems":[{"type":"PlayTts","value":"Hello there, transfering now","id":"BE4BE074-FE4A-494D-8075-0619A078F2B7"},{"type":"WorkgroupTransfer","id":"D9F1C304-3302-4AD9-8D34-CDCDAC0C13D5","destination":"salesforce"}]}]}'
  end

  def get_menu(menuKey, ivrData)
    ivrData['menu'].each do |m|
      if(m['key'] == menuKey.to_i)
        return m
      end
    end
    return nil
  end
  
  def next_node(menu, currentId)
    if(currentId == nil || currentId == "")
      return menu['subitems'][0]
    end
    
    (0..menu['subitems'].count-1).each do |i|
      if(menu['subitems'][i]['id'].to_s == currentId.to_s)
        #found the current one, return the next
        return menu['subitems'][i+1]
      end
    end
    return nil
  end
  
  def play_time(currentId)
    #if current is disconnect, stop call processing
    if(currentId == 'disconnect')
      return nil
    end
    
    #if we played the time, disconnect next
    if(currentId == 'play')
      return create_disconnect_action 'disconnect'
    end
    
    time = Time.now
    responseString = "The current time is #{time.hour >12 ? time.hour%12: time.hour}, #{time.min}, #{time.hour >=12 ? 'P M' : 'A M'} "
    
    return create_tts_action 'play', responseString
  end
end

class Menu3
  include IvrHelper
  
  def get_next_action(callIdKey, currentActionId)
    begin
      if(currentActionId == nil)
        return greeting
      end
      
      return self.send('after_' + currentActionId , callIdKey)
    rescue => error
      puts error.inspect
      return nil
    end
  end
  
  def greeting
    create_tts_action 'greeting', 'This is the dynamic IVR, enter your favorite number followed by pound.'
  end
  
  def after_greeting(*args)
    create_digit_input_action 'fav_number_input'
  end
  
  def after_fav_number_input(*args)
    digits = get_digits args[0]
    create_tts_action 'fav_number_playback', 'your favorite number is ' + digits
  end
end
