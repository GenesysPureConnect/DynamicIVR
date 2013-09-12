module IvrHelper
  def get_digits(callIdKey)
     interaction = Interaction.find_by interactionid: callIdKey
     puts interaction.inspect
     interaction.digits
  end
    
  def create_disconnect_action(id)
    {'type' => 'Disconnect', 'id'=>id}
  end
  
  def create_tts_action( id, ttsString)
    {'type' => 'PlayTts', 'value' => ttsString, 'id'=>id}
  end
  
  def create_set_attribute_action( id, attributeName, attributeValue)
    {'type' => 'SetAttribute', 'attribute' => attributeName, 'value' => attributeValue, 'id'=>id}
  end
  
  def create_digit_input_action(id)
    {'type' => 'InputDigits', 'id'=>id}
  end
  
  def create_workgroup_transfer_action(id, destination)
    {'type' => 'WorkgroupTransfer', 'destination' => destination, 'id'=>id}
  end
end