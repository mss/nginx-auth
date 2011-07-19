#!/bin/bash
GET -USe \
	-H "Auth-Protocol: imap" \
	-H "Auth-User: $1" \
	http://localhost:5000/

