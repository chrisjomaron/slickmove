#!/bin/bash

PATH="/bin:/usr/bin:/usr/ucb:/usr/opt/bin"
export $PATH

echo "Content-type: text/html"
echo ""
echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
echo '</head>'
echo '<body>'
echo 'updated GIT repo'

#(cd /home/ec2-user/xxxxx  && git pull)

echo '</body>'
echo '</html>'

exit 0

