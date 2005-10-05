#!/usr/bin/python
#
# This script is a helper to clean POP3 mailboxes
# containing malformed mails that hangs MUA's, that 
# are too large, or whatever...
#
# It iterates over the non-retrieved mails, prints
# selected elements from the headers and prompt the 
# user to delete bogus messages.
#
# Written by Xavier Defrang <xavier.defrang@brutele.be>
# Modified By Plucio <plucio@brfree.com.br>
# 

# 
import getpass, poplib, re


# Change this to your needs
POPHOST = "mail.brfree.com.br"
POPUSER = "plucio"
POPPASS = ""

# How many lines of message body to retrieve
MAXLINES = 10

# Headers we're actually interrested in
rx_headers  = re.compile(r"^(From|To|Subject)")

try:

    # Connect to the POPer and identify user
    pop = poplib.POP3(POPHOST)
    pop.user(POPUSER)

    if not POPPASS:
        # If no password was supplied, ask for it
        POPPASS = getpass.getpass("Password for %s@%s:" % (POPUSER, POPHOST))

    # Authenticate user
    pop.pass_(POPPASS)

    # Get some general informations (msg_count, box_size)
    stat = pop.stat()

    # Print some useless information
    print "Logged in as %s@%s" % (POPUSER, POPHOST)
    print "Status: %d message(s), %d bytes" % stat

    bye = 0
    count_del = 0
    for n in range(stat[0]):

        msgnum = n+1

        pop.dele(msgnum)
        print "Message %d marked for deletion" % msgnum
        count_del += 1


    # Summary
    print "Deleting %d message(s) in mailbox %s@%s" % (count_del, POPUSER, POPHOST)

    # Commit operations and disconnect from server
    print "Closing POP3 session"
    pop.quit()

except poplib.error_proto, detail:

    # Fancy error handling
    print "POP3 Protocol Error:", detail

