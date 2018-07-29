# Checks source and components directories for files with the word stop in them
# Comments will also be matched

out="$(grep -Rin "stop" source | grep -v "'" | grep -v "\"")"
status="$(echo \"$out\" | grep -v \"[\^\\s\\r\\n]\*\")"
if [ -n "$status"  ]; then
    echo "$out"
    exit 1
fi
out="$(grep -Rin "stop" components | grep -v "'" | grep -v "\"")"
status="$(echo \"$out\" | grep -v \"[\^\\s\\r\\n]\*\")"
if [ -n "$status"  ]; then
    echo "$out"
    exit 2
fi
