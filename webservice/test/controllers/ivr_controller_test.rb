require 'test_helper'

class TestIvrController < IvrController
   def get_configuration
     JSON.parse '{"menu":[{"key":1,"id":"E599819C-38A8-464F-A9A4-C12F1C42654F","subitems":[{"type":"PlayTts","value":"Hello World","id":"BE4BE074-FE4A-494D-8075-0619A078F2B7"},{"type":"InputDigits","id":"A9259836-4160-42CC-BC9A-A487E57E62E9","attribute":""},{"type":"SetAttribute","id":"8CE1F5BE-99DD-4D96-8454-BC9ED8A73CDB","attribute":"eic_SDFLK","value":"some value"},{"type":"WorkgroupTransfer","id":"D9F1C304-3302-4AD9-8D34-CDCDAC0C13D5","destination":"salesforce"}]}]}'
  end
end

class IvrTest <ActiveSupport::TestCase
  test "Get Configuration" do
    controller = TestIvrController.new
    config = controller.get_configuration
    refute_nil config['menu'] 
  end

  test "Get Menu" do
    controller = TestIvrController.new
    config = controller.get_configuration
    refute_nil controller.get_menu 1, config
  end

  
  test "first Node" do
    controller = TestIvrController.new
    config = controller.get_configuration
    menu = controller.get_menu "1", config
    nextNode = controller.next_node menu, ""
    assert nextNode['id'] == "BE4BE074-FE4A-494D-8075-0619A078F2B7"
  end
  
  test "Next Node" do
    controller = TestIvrController.new
    config = controller.get_configuration
    menu = controller.get_menu "1", config
    nextNode = controller.next_node menu, "BE4BE074-FE4A-494D-8075-0619A078F2B7"
    assert nextNode['id'] == "A9259836-4160-42CC-BC9A-A487E57E62E9"
  end
  
  test "Next Node when at the end" do
    controller = TestIvrController.new
    config = controller.get_configuration
    menu = controller.get_menu 1, config
    assert_nil controller.next_node menu, "D9F1C304-3302-4AD9-8D34-CDCDAC0C13D5"
  end
  
  test "Store and get Attributes" do
    controller = IvrController.new
    keys = 'hello|foo'
    values = 'world|bar'
    callidkey = 'baz'
    
    controller.store_attributes callidkey, keys, values
    
    interaction = Interaction.find_by interactionid: callidkey
    refute_nil interaction
    
    hello = controller.get_attribute callidkey, 'hello'
    assert hello == 'world'
  end
  
  test "Store and get digits" do
    controller = IvrController.new
    callidkey = 'baz'
    digits ='1234'
    
    controller.update_digits callidkey, digits
    
    assert controller.get_digits(callidkey) == digits
  end
end
