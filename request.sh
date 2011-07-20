#!/bin/bash
protocol=$1
username=$2
exec lwp-request -USe \
	-H "Auth-Protocol: $protocol" \
	-H "Auth-User: $username" \
	http://localhost:5000/

