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


##Screenshots

![Screenshot 0](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_0.png)
View full conversations - all at once - with a person, starting from the first interaction
Also shows delivered/read receipts for each person


![Screenshot 1](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_1.png)
View messages sent on a certain date (no messages)


![Screenshot 2](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_2.png)
View messages sent on a certain date (messages)


![Screenshot 3](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_3.png)
Searching for text brings up contacts + contacts with messages that match the text
Pressing Enter brings up the next text occurence 
Message occurrences are highlighted in yellow and pressing enter scrolls to the next occurrence


![Screenshot 4](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_4.png)
Attachments sent are shown in a message
Clicking on them opens a popup with that attachment


![Screenshot 5](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_5.png)
For multiple attachments in a message, the popup allows scrolling through each attachment
As well as the ability to open each attachment in the right application


![Screenshot 6](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_6.png)
Movie attachments and PDFs are also shown and movies begin playing automatically


![Screenshot 7](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_7.png)
Double clicking a contact shows quick statistics and gives the option to view more icon (circle icon)


![Screenshot 8](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_8.png)
More analysis screen (still under construction)
- Shows all messages sent and received
- Shows the total word count, sent and received
- Shows the average word per message
- Shows all words for each participant in order of freuency
- All messages are displayed on tableview at bottom of the screen


![Screenshot 9](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_9.png)
More analysis screen (still under construction)
Clicking on a date in the calendar on the bottom left
    - Shows above statistics but on that date
        + Includes recalculating word frequencies, words sent and received on date, and average word/message on date ("Avg. Word/Message (D)")
    - Shows messages sent on that day 
    - Pressing "Clear" resets everything to the initial screen
