ps aux | grep '[nc] -l -p 80' | awk '{ print $2 }' | xargs -n 1 kill -9
