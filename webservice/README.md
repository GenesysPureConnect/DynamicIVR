
#Dynamic IVR
The purpose of the dynamic IVR is to let the flow of the IVR to be controlled by a web service which can lead to a more powerful and dynamic IVR.  This guide will be using Ruby on Rails to power the web service, but any kind of web service that supports soap and follows the same WSDL can be used with these handlers.  For web services that might have a slightly different WSDL, some modifications of the handlers might be necessary.  

##IVR Configuration
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

##Ruby on Rails Web service
This web service needs to support a soap endpoint, so we will be using the [Wash_out][1] Ruby gem.  Make sure to add it to your gemfile

    gem 'wash_out'

The logic for our IVR will all be handled in our ivr_controller.  Create a new controller and then add the following line to your routes.rb so that wash_out can properly handle the soap endpoint

    wash_out :ivr

In the ivr_controller, we have three publicly exposed soap methods

**get_next_action:**
Returns the next action for the handlers to process.

**set_attributes:**
Called at the start of the call to cache the attributes in the web server.

**digits_received:** 
Called whenever we get digits from the caller.

  [1]: https://github.com/inossidabile/wash_out