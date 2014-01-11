# analytics.rb

**Google Analytics for you commandline tools**

## How it works

analytics.rb is a simple implementation of the Google Analytics [measurement protocol](https://developers.google.com/analytics/devguides/collection/protocol/v1/) that takes just three steps to use

1. Create a Google Analytics property with universal analytics using an 'app' profile (not website) [help](https://support.google.com/analytics/answer/1009694?hl=en)

2. Configure Analytics in just one line
 ```ruby
 Analytics.configure "UA-XXXXXXXX-Y", "MyAppName" 
 ```

3. Log 'Event' or 'Exception' activity in just one line
 ```ruby
Analytics.event category:'AppStart' action:'--help' 
 ```

Voila! You have logged an event to your App analytics from the command line!

## Details

Analytics.rb supports the following options

- **Event Logging:** track any 'event' you define and report it in the _Behaviour_ section of GA
- **Exception Logging:** capture exception information and send back analysis in the _Crashes_ section of GA
- **Timing Logging:** track timing and performance statistics and report it in the _App Speed_ section of GA

###### Fire & Forget

All request to the GA Measurement API are done on a new thread.
The return type for logging methods is of type `Thread`
The `Net::HTTP::Response` object is contained in the thread's `:response` key incase you want to access it

### Event Logging

Event tracking supports the following (all the following are optional parameters)

| Parameter      | Explaination                                               |
|---------------:|:----------------------------------------------------------:|
| `:category`    | Broad category associated with this event |
| `:action`      | Action associated with this event |
| `:label`       | Description for the event (500 byte max) |
| `:value`       | Value associated with this event (number) | 

**Sample Exception**

Log and event with cagetory and label values

```ruby
Analytics.event category: "Parameters", label: "--help"
```

The event method returns a type 'Thread' that is executing the fire and forget request

In this examlpe we log an event and wait for execution to complete

```ruby
thread = Analytics.event category: "Parameter", label: "--all"  # capture fire and forget thread
thread.nil?                                                     # => false, if it is nil there was an error
thread.status                                                   # => sleep
thread.join                                                     # block until thread is complete

resp = thread[:response]                                        # Net::HTTP::Response object
```

See the [GA event reference](https://support.google.com/analytics/answer/1033068) regarding the different options.

See the [GA parameter reference](https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters#events) regard the maximum bytes

### Exception Logging

Similar to Event Logging, except only accepting two optional parameters

| Parameter      | Expaination |
|---------------:|:-----------:|
| `:description` | Exception description text (500 byte max) |
| `:fatal?`      | True or false value to indicate the exception is fatal (default false) |

**Sample Exception**

```ruby

rescue Exception => e
  Analytics.exception description: e.message, :fatal? => true
end
```

### Configuration Options

Only two required options are necessary to configure Analytics, the properties `Tracking ID`  and `Application Name`

```ruby
Analytics.configure "UA-XXXXXXXX-Y", "AppName"
```

A variety of option parameters are accepted too

NOTE: Calling `.configure` clears all your configuration options and resets them to defaults.

```ruby
# debug mode enable ... prints to console
Analytics.configure "UA-XXXXXXXX-Y", "AppName", debug: true

# anonymize client IP address AND resets debug to false
Analytics.configure "UA-XXXXXXXX-Y", "AppName", anonymize_ip: true

# set App Name Explicitly
Analytics.app_version = '0.1'
```

### Other options

**Client Id**

Client Id's are UUIDs that must be sent with every request. Currently a random UUID is assigned for a given instance

**Session Start & Stop**

You can start and stop sessions by logging with `:session` parameter

```ruby
# debug mode enable ... prints to console
Analytics.event label: "Program start", session: 'start'  # starts session for this client id

sleep 10                                                  # wait for 10 seconds ... 

Analytics.exception description: "Uh-Oh", session: 'end'     # terminate the session for this client Id
```
