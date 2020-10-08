<cfscript>

root = getDirectoryFromPath(getCurrentTemplatePath());
index = URL.index;
requestPayload = getHTTPRequestData(true);

// To help out with sorting, it's easier if the format is 001 and so on
if (index < 10)
    index = "00" & index;
else if (index < 100)
    index = "0" & index;

file = fileOpen(root & "/Fragments/fragment_#index#.ts", "write");
fileWrite(file, requestPayload.content);
fileClose(file);

</cfscript>