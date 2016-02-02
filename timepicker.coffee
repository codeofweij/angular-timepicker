###
wz-timepicker

mimics the google calendar time picker, no date component.
returns minutes in a day
###
module = angular.module( 'wjz', ['template/wztimepicker.html'])

module.factory 'TimeService', ($filter) ->
   today = (minutes) ->
      date = new Date()
      date.setHours(0)
      date.setMinutes(minutes,0,0,0)
      date

   getDurationString = (minutes) ->
         hours = minutes / 60
         unit = if hours < 1 then 'min' else if hours == 1 then 'hr' else 'hrs'
         amount = if hours < 1 then hours * 60 else hours
         return "#{amount} #{unit}"
   ### API methods
   ###
   getToday: ()->
      today(0)
   
   getDateFromMinutes: (minutes) ->
      today(minutes)
   
   getTimeString: (date) ->
      return $filter('date')(date, 'h:mm a')
   
   getTimeOptions:  () ->
      timeOptions = []          
      for i in [0..47]
         date = today( (i * 30 ))
         timeOptions.push
            minutes: i * 30
            string: $filter('date')(date, 'h:mm a')               
      return timeOptions
   
   getDurationString:  (minutes) ->
      getDurationString(minutes)
      
   getOffsetTimeOptions:  (offsetMinutes) ->
         
      timeOptions = [] 
      for i in [0..47]
         minutes = i * 30
         if minutes > offsetMinutes
            date = today( (i * 30 ))
            timeOptions.push
               minutes: i * 30
               string: $filter('date')(date, 'h:mm a')               
               duration: getDurationString( minutes - offsetMinutes ) 

      return timeOptions

module.directive 'wzTimepicker', (TimeService, $timeout) ->
   
   restrict: 'E'
   templateUrl: 'template/wztimepicker.html',
   scope:
      time: '='
      offset: '='
   link: (scope, element, attrs) ->
      ###
         use javascript to track when use clicks outside of TimeOptions dropdown
         if the dropdown is open, then hide it
      ###
      $(document).mouseup (e) ->
         if (!element.is(e.target) && element.has(e.target).length == 0) # ... nor a descendant of the container 
            if scope.showOptions
               scope.showOptions = false
               scope.$apply()
         return
      
      if scope.offset
         scope.timeOptions = TimeService.getOffsetTimeOptions(scope.offset)

         scope.$watch 'offset', (newValue, oldValue) ->
            # use offset time options
            scope.timeOptions = TimeService.getOffsetTimeOptions(scope.offset)            
            #update defaults
            scope.time.minutes = scope.offset + 30
            setDefaults()
            return
      else
         scope.timeOptions =  TimeService.getTimeOptions()

      ## initial settings
      setDefaults = ()->
         for t in scope.timeOptions
            if t.minutes == scope.time.minutes
               scope.setTime( t )
               return
         return

      scope.showOptions = false
      scope.show = () ->
         scope.showOptions = true
         ### 
          need a timeout to wait for the div to be visible, 
          otherwise scrollIntoView() doesn't work
         ###         
         $timeout () ->
            #element.find(".selected-time")[0].scrollIntoView()
            return
         , 1
         return
      
      scope.hide = () ->
         scope.showOptions = false
         return
      
      scope.setTime = (time) ->

         scope.timeString = time.string
         scope.time.string = time.string
         scope.time.minutes = time.minutes
         scope.showOptions = false
         return

      setDefaults()
      return

angular.module("template/wztimepicker.html", []).run ["$templateCache", ($templateCache) ->
   $templateCache.put("template/wztimepicker.html",
   "
      <div style=\"display:inline-block\">
         <input ng-click=\"show()\" type=\"input\" ng-model=\"timeString\" size=\"8\" style=\"font-size:12px\">
         <div ng-show=\"showOptions\"
              style=\"border:1px solid #DDD; position:absolute;z-index:1000;font-size:12px;height:130px;width:125px;overflow-y:scroll\">
            <div class=\"list-group\"> <a ng-class=\"{'selected-time': time.minutes == minutes}\"
ng-repeat=\"time in timeOptions\" ng-click=\"setTime(time)\" style=\"border:none;padding:2px 5px\" class=\"list-group-item\" >
                  {{ ::time.string }}  
                  <span style=\"position:absolute;float:right\" ng-if=\"time.duration\"> &nbsp;&nbsp;({{ ::time.duration }}) </span>
               </a>
            </div>
         </div>
      </div>
   "
   )]