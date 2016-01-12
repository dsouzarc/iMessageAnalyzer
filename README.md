#Written by Ryan D'souza

##iMessage Analyzer - Mac App

###Analyzes a user's iMessages while providing cool functionality

Analyzes a user's iMessage database (chat.db*) to understand a user and their friends' messaging habits by graphing (and calculating statistics) on those characteristics.

Adds some unique functionality from Messages.app that provides a better experience, including a refined search for messages.

*chat.db, where a user's messages are stored, can be found in 2 ways:

1. Where Messages.app (Apple's official Messages.app - iMessage for Mac) stores its data
2. Where the iPhone's chat.db database is stored after a backup to the computer


####Current Features:

- Looks like iMessage
  + Contacts tableview on left side with contact name + profile picture
  + iMessages you sent are in blue on the right side of messages panel
    - Normal text messages you send are in green
  + iMessages you received are in gray on the left side of messages panel
  + Shows each message's date/time and read receipts

#####Unique from iMessage Features

- **Loads all of a user's messages** (as opposed to scrolling up forever to see the first few messages) 
    + Still memory efficient and quick for large conversations 
        - Tested on conversations with > 26,000 messages
        - Tested on total messages > 60,000
        - Barely uses 110MB of RAM
        - Minimal CPU usage

- Searching for text shows conversations 
    + With text that matches the conversation
    + With contact names/numbers/emails that match the text
    + Still (somehow) quicker than iMessage's search for conversations with text
    + Searched text is highlighted in yellow
    + Pressing enter moves to the next occurrence of that text

- View **messages sent and received on a certain date** for a conversation
    + Calendar view pops up and a date can be chosen to view all messages with that conversant on
    + Pressing "Reset to All" shows all messages with person

- Double clicking on contact in Contacts Tableview on the left shows
    + **Total number of messages you sent and received** in that conversation
    + Option to perform More Analysis

- More Analysis
    + Shows the following for All Time or on a specific date
        -  **Words organized by frequency/occurrence** for each person
            + Uses a Heap Data Structure I wrote
        - Total number of messages sent and received
        - Total number of words sent and received
        - Average word per message sent and received
        - Date selected from calendar view on bottom left
        - The actual messages sent and received

- **Graphs and charts**
  + **Line graph** of messages with that person since your first message
    - Allows for zooming in on specific date ranges
    - Data can be changed to show
        + Messages with that person compared to all other messages sent during that time period
        + Your sent vs received messages with that person over time 
        + Your sent vs received words with that person over time
  + **Pie Chart**
    - Sent messages vs received messages with person
    - Sent words vs received words with that person
    - Total messages with person vs all other messages in inbox
  + **Bar Chart**
    - Sent vs received messages per hour of day --> When y'all talk the most
    - Sent vs received words per hour of day --> When y'all talk the most
    - Percentage of total messages with person per hour of day vs percentage of all other messages with other people per hour of day --> When y'all talk the most in comparison to when you mainly talk to everyone else


---

####Features in implementation:
- Statistics on actual messaging habits
    + Average reply time over the course of a day
- Autoreply based on replies to certain messages --> Machine Learning


---

##Screenshots
- Scroll to the bottom to see beginning flow


![Screenshot 31](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_31.png)
A graph of all messages with a person over the course of a year.
This person seems like a good friend

---

![Screenshot 32](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_32.png)
Zooming in on that graph

---

![Screenshot 33](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_33.png)
Clicking on a point shows the y-value above it.

---


![Screenshot 34](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_34.png)
Graphing message frequency with another one.
This seems like a broken-off friendship

---

![Screenshot 35](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_35.png)
Overlaying the messages with a friend (white) with all other messages on that day (green)

---

![Screenshot 36](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_36.png)
Zooming in on that overlay

---

![Screenshot 19](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_19.png)
Sent vs Received messages

---

![Screenshot 20](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_20.png)
Sent vs Received words

---

![Screenshot 21](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_21.png)
Pie chart of sent vs received messages

---

![Screenshot 22](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_22.png)
Pie chart of sent vs received words

---

![Screenshot 23](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_23.png)
Pie chart of total messages to that person vs all other messages

---

![Screenshot 24](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_24.png)
When y'all send the most amount of messages to each other throughout the day

---

![Screenshot 25](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_25.png)
When y'all type the most to each other throughout the day

---

![Screenshot 26](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_26.png)
That conversation vs all other conversations throughout the day

---

![Screenshot 27](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_27.png)
A percentage breakdown of that conversation vs all other conversations throughout the day

---

![Screenshot 37](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_37.png)
How that can vary from person to person

---

![Screenshot 0](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_0.png)
View full conversations - all at once - with a person, starting from the first interaction
Also shows delivered/read receipts for each person

---

![Screenshot 1](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_1.png)
View messages sent on a certain date (no messages)  

---

![Screenshot 2](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_2.png)
View messages sent on a certain date (messages)  

---

![Screenshot 3](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_3.png)
Searching for text brings up contacts + contacts with messages that match the text.
Pressing Enter brings up the next text occurence.
Message occurrences are highlighted in yellow and pressing enter scrolls to the next occurrence

---

![Screenshot 4](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_4.png)
Attachments sent are shown in a message.
Clicking on them opens a popup with that attachment

---

![Screenshot 5](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_5.png)
For multiple attachments in a message, the popup allows scrolling through each attachment as well as the ability to open each attachment in the right application

---

![Screenshot 6](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_6.png)
Movie attachments and PDFs are also shown and movies begin playing automatically

---

![Screenshot 28](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_28.png)
Double clicking a contact shows quick statistics and gives the option to view more icon (circle icon)

---

![Screenshot 29](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_29.png)
More analysis screen

- Shows all messages sent and received

- Shows the total word count, sent and received

- Shows the average word per message

- Shows all words for each participant in order of freuency

- All messages are displayed on tableview at bottom of the screen

---

![Screenshot 30](https://github.com/dsouzarc/iMessageAnalyzer/blob/master/Screenshots/Screenshot_30.png)
More analysis screen

Clicking on a date in the calendar on the bottom left
    - Shows above statistics but on that date
        + Includes recalculating word frequencies, words sent and received on date, and average word/message on date ("Avg. Word/Message (D)")
    - Shows messages sent on that day 
    - Pressing "Clear" resets everything to the initial screen
