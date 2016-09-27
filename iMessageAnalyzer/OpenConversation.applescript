tell application "Messages"

    set targetBuddy to "{phoneNumber}"
    set targetService to id of 1st service whose service type = iMessage
    set textMessage to ""
    set theBuddy to buddy targetBuddy of service id targetService
    send textMessage to theBuddy

end tell
