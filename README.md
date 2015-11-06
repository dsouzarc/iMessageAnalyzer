#Written by Ryan D'souza

##iMessage Analyzer

###Analyzes a user's iMessages

Uses the user's iMessage database (chat.db) - can be configured to run using the user's local Messages.app database or the chat.db database when the user last backed up their iPhone - to understand a user and their friends' messaging habits.

####Current Features:

- Looks like iMessage (screenshots to come)
  + Contacts tableview on left side with contact name + profile picture
  + iMessages you sent in blue on the right side of messages panel
  + iMessages you received in gray on the left side of messages panel
  + Shows each message date/time and read receipts

- Loads all of a user's messages (as opposed to scrolling up forever to see the first few messages) 

- Searching for text shows conversations where that text was used as well as contacts with that text in their username
  + Search for text in all conversations is unique from iMessage

- Viewing messages sent on a certain date
    + Calendar view pops up and a date can be chosen to view all messages with that conversant on

####Features in implementation:
- Showing usage of search text throughout conversation

- Statistics on actual messaging habits
