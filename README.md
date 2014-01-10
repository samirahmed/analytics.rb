# analytics.rb

### Google Analytics for you commandline tools

## How it works

analytics.rb is a simple implementation of the Google Analytics [measurement protocol](https://developers.google.com/analytics/devguides/collection/protocol/v1/)

It takes three steps to using it

**1. Create a Google Analytics property with universal analytics using an 'app' profile (not website) [help](https://support.google.com/analytics/answer/1009694?hl=en)**

**2. Configure Analytics in just one line**

```ruby
Analytics.configure "UA-XXXXXXXX-Y", "MyAppName" 
```

**3. Log 'Event' or 'Exception' activity in just one line**

```ruby
Analytics.event category:'AppStart' action:'--help' 
```

**Voila! You should be ready to log analytics!**

## Details

Analytics.rb supports the following options

- **Event Logging:** track any 'event' you define and report it in the _Behaviour_ section of GA
- **Exception Logging:** capture exception information and send back analysis in the _Crashes_ section of GA
- **Timing Logging:** track timing and performance statistics and report it in the _App Speed_ section of GA

### Event Logging


## Configuration Options

Only two required options are necessary to configure Analytics, the properties `Tracking ID`  and `Application Name`

```ruby
Analytics.configure "UA-XXXXXXXX-Y", "AppName"
```

A variety of option parameters are accepted too



```ruby
# debug mode enable - prints to file
Analytics.configure "UA-XXXXXXXX-Y", "AppName", debug: true
```

Calling `.configure` clears all your configuration options and resets them to defaults.


