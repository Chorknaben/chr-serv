#!/bin/bash
EMAIL=$(cat /tmp/chorserv-feedback-email)
TYPE=$(cat /tmp/chorserv-feedback-feedbacktype)
NAME=$(cat /tmp/chorserv-feedback-name)
CONTENT=$(cat /tmp/chorserv-feedback-text)
case $TYPE in
    1) TYPE_TEXT="Kritik"
        ;;
    2) TYPE_TEXT="Lob"
        ;;
    3) TYPE_TEXT="Vorschlag"
        ;;
    *) exit 240
        ;;
esac
( 
    echo To: feedback@chorknaben-biberach.de
    echo From: feedbackagent.chorserv@chorknaben-biberach.de
    echo Subject: Feedback via Formular
    echo
    echo "Von: $EMAIL (Name: $NAME)" 
    echo "Typ: $TYPE_TEXT" 
    echo "- - - -"
    echo $CONTENT
    echo "- - - -"
) | sendmail -t
rm /tmp/chorserv-feedback-email
rm /tmp/chorserv-feedback-feedbacktype
rm /tmp/chorserv-feedback-name
rm /tmp/chorserv-feedback-text


