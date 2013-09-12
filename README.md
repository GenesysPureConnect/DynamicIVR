
#Dynamic IVR
The purpose of the dynamic IVR is to let the flow of the IVR to be controlled by a web service which can lead to a more powerful and dynamic IVR.  This guide will be using Ruby on Rails to power the web service, but any kind of web service that supports soap and follows the same WSDL can be used with these handlers.  For web services that might have a slightly different WSDL, some modifications of the handlers might be necessary.  

##IVR Static Configuration
The configuration for our ivr will be stored in a JSON object.  This will make it easier to create in a web page.  The format will look like this:

    {
    "menu": [
        {
            "key": 1,
            "id": "E599819C-38A8-464F-A9A4-C12F1C42654F",
            "subitems": [
                {
                    "type": "PlayTts",
                    "value": "Hello World",
                    "id": "BE4BE074-FE4A-494D-8075-0619A078F2B7"
                },
                {
                    "type": "InputDigits",
                    "id": "A9259836-4160-42CC-BC9A-A487E57E62E9",
                    "attribute": ""
                },
                {
                    "type": "SetAttribute",
                    "id": "8CE1F5BE-99DD-4D96-8454-BC9ED8A73CDB",
                    "attribute": "eic_SDFLK",
                    "value": "some value"
                },
                {
                    "type": "WorkgroupTransfer",
                    "id": "D9F1C304-3302-4AD9-3302-CDCDAC0C13D5",
                    "destination": "salesforce"
                },
				{
                    "type": "Disconnect",
                    "id": "8D34C304-8D34-3302-8D34-C3302C0C13D5",
				}
            ]
        }
    ]
}

##Handlers
The handlers are used to process the actions returned by the web service.  They are used to provide the actual interactions to the call that the web service can not do itself.

**DynamicIVR_EntryPoint** 
The main handler for this system.  This is the handler that CustomSubroutineInitiatorRouter calls into.

**DynamicIVR_GetNextAction**
Queries the web service for the next action to perform

**DynamicIVR_DigitsReceived**
Calls into the web service to persist the last digits that were entered

**DynamicIVR_ProcessAction**
Process the current action by calling into the appropriate handler toolsteps

**DynamicIVR_SetCallAttributes** Takes call attributes off of the call, and sends them to the web service to be persisted

##Ruby on Rails Web service
###Introduction
This web service needs to support a soap endpoint, so we will be using the [Wash_out][1] Ruby gem.  Make sure to add it to your gemfile

    gem 'wash_out'

The logic for our IVR will all be handled in our ivr_controller.  Create a new controller and then add the following line to your routes.rb so that wash_out can properly handle the soap endpoint

    wash_out :ivr

In the ivr_controller, we have three publicly exposed soap methods

**get_next_action:**
Returns the next action for the handlers to process.

    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
    <Body>
        <get_next_action xmlns="urn:WashOut">
            <currentposition>[string]</currentposition>
            <menu>[int]</menu>
            <callIdKey>[string]</callIdKey>
        </get_next_action>
    </Body>
    </Envelope>

**set_attributes:**
Called at the start of the call to cache the attributes in the web server.

    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
    <Body>
        <set_attributes xmlns="urn:WashOut">
            <keys>[string]</keys>
            <values>[string]</values>
            <callIdKey>[string]</callIdKey>
        </set_attributes>
    </Body>
    </Envelope>

**digits_received:** 
Called whenever we get digits from the caller.

    <Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
    <Body>
        <digits_received xmlns="urn:WashOut">
            <digits>[string]</digits>
            <callIdKey>[string]</callIdKey>
        </digits_received>
    </Body>
    </Envelope>

###Call Flow
This is where things start to get interesting.  The IvrController currently handles 3 different menus.  Menu 1 uses a static configuration to play text to the caller and then transfer them to a workgroup, not that exciting yet because we can do the same thing in handlers today.  Menu 2 takes a slightly different approach in that regardless of the current step, it always calls into the play_time method.

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
      responseString = "The current time is #{time.hour >12 ? time.hour%12: time.hour}, {time.min}, #{time.hour >=12 ? 'P M' : 'A M'} "
    
      return create_tts_action 'play', responseString
    end

In this method, through various if statements we can control how our IVR will flow.  In this case we are playing the current time to the caller and then disconnecting them.  For reference, the IvrHelper class has methods to create the response actions.

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
  
Menu 3 is where we start to leverage the real power or Ruby.  We can use the power of [Object::send][2] in Ruby to dynamically call methods based on the last executed action.  

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


In the IvrController, whenever we are in menu 3, it will always call Menu3::get_next_action.  In the get_next_action, we call into the greeting if the currentActionId is nil.  This will happen for the first time the call to get the next action is made for a menu.  After the greeting, every time the get_next_action method is called, it will then call the method after_<CURRENTACTIONID>.  You can see that in the greeting action, the id of the action returned is 'greeting'.  The next time that get_next_action is called, the currentActionId will be 'greeting' so via the self.send call, the method after_greeting will be called.  Additional control statements can be added to the methods to dynamically return different menus based on caller or external data. 

  [1]: https://github.com/inossidabile/wash_out
  [2]: http://ruby-doc.org/core-2.0.0/Object.html#method-i-send