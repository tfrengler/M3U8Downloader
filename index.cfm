<!DOCTYPE html>
<html lang="en">

	<head>
		<title>M3U8</title>
		<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

        <style>
            img {
                height: 1em;
                display: none;
            }
        </style>

        <script>

            window.onload = function() {
                document.querySelector("#LoadPlaylist").addEventListener("click", fetchPlaylist);
                document.querySelector("#ExtractURLS").addEventListener("click", extractURLs);
                document.querySelector("#GetEncryptionKey").addEventListener("click", getEncryptionKey);
                document.querySelector("#DownloadFragments").addEventListener("click", doDownload);
                document.querySelector("#DecryptFiles").addEventListener("click", doDecryption);
            }

            var index = 0;
            var manifest = null;
            var fragmentURLs = [];
            var encryptKeyURL = null;
            var encryptionKey = null;
            var hexedEncryptionKey = null;
            const host = "https://insight-hls-amd1.akamaized.net/libraryitems-hls/d7w3j7p4u1v0u2b6e8w2y0k7z4m1n9g8t2s1g5e0/";

            const fetchPlaylist = function(event) {
                event.srcElement.disabled = true;

                fetch("playlist.m3u8").then(response=> {
                    if (response.status === 200)
                        return response.text();
                    
                    document.querySelector("#LoadPlaylistStatus").textContent = ": ERROR";
                })
                .then(textPayload=> {
                    manifest = textPayload;
                    document.querySelector("#LoadPlaylistStatus").textContent = ": OK";
                });
            };

            const extractURLs = function(event) {
                event.srcElement.disabled = true;

                const statusElement = document.querySelector("#ExtractURLSStatus");
                const urlRegex = /#EXTINF:.*\r\n(.*)/g;
                let result = [...manifest.matchAll(urlRegex)];
                
                result.forEach(matches=> fragmentURLs.push(matches[1]));

                if (result.length == 0)
                {
                    statusElement.textContent = ": ERROR - No url's found in playlist";
                    return;
                }

                statusElement.textContent = `: ${result.length} URL's`;
                document.querySelector("#DownloadFragmentsProgress").max = result.length - 1;

                const encryptRegex = /#EXT-X-KEY:METHOD=AES-128,URI="(.*)"/;
                let encryptSearch = manifest.match(encryptRegex);

                if (!encryptSearch) {
                    statusElement.textContent = statusElement.textContent + " | No encryption";
                    return;
                }

                statusElement.textContent = statusElement.textContent + " | Encryption found";
                encryptKeyURL = encryptSearch[1];
            };

            const getEncryptionKey = function(event) {
                event.srcElement.disabled = true;
                const statusElement = document.querySelector("#GetEncryptionKeyStatus");

                fetch(encryptKeyURL).then(response=> {
                    if (response.status === 200)
                        return response.arrayBuffer();
                    
                    statusElement.textContent = ": ERROR - Unable to fetch encryption key";
                })
                .then(encryptionKeyBinary=> {
                    encryptionKey = encryptionKeyBinary;
                    statusElement.textContent = ": Encryption key fetched";

                    hexedEncryptionKey = bin2hex(toBinString(encryptionKey));
                    statusElement.textContent = statusElement.textContent + " | Encryption key hexed";
                });
            }

            const doDownload = function(event) {
                document.querySelector("#DownloadFragmentLoading").style.display = "inline-block";
                event.srcElement.disabled = true;

                const progressElement = document.querySelector("#DownloadFragmentsProgress");
                const statusElement = document.querySelector("#DownloadFragmentsStatus");

                if (fragmentURLs.length == 0) {
                    document.querySelector("#DownloadFragmentLoading").style.display = "none";
                    statusElement.textContent = " DONE";
                    return;
                }

                fetch(host + fragmentURLs.shift()).then(response=> response.arrayBuffer())
                .then(binaryData=> {
                    saveToDisk(binaryData, index);
                    progressElement.value = index;
                    index++;
                    doDownload({srcElement: event.srcElement});
                });
            };

            const saveToDisk = function(binaryData, index) {
                return fetch("saveToDisk.cfm?index=" + index, { method: 'POST', body: binaryData, headers: new Headers({'content-type': 'video/MP2T'}) });
            };

            const bin2hex = function(binaryString) {
                return binaryString.match(/.{4}/g).reduce(function(acc, i) {
                    return acc + parseInt(i, 2).toString(16);
                }, '')
            };

            const toBinString = function(arrayBuffer) {
                const bytes = new Uint8Array(arrayBuffer);
                return bytes.reduce((str, byte) => str + byte.toString(2).padStart(8, '0'), '');
            };

            const doDecryption = function(event) {
                event.srcElement.disabled = true;
                document.querySelector("#DecryptFilesLoading").style.display = "inline-block";

                fetch(`decryptFiles.cfm?secretKey=${hexedEncryptionKey}`)
                .then(response=> {
                    document.querySelector("#DecryptFilesLoading").style.display = "none";

                    if (response.status === 200)
                        document.querySelector("#DecryptFilesStatus").textContent = ": OK";
                    else
                        document.querySelector("#DecryptFilesStatus").textContent = ": ERROR";
                });
            };
        </script>
    </head>

    <body>

        <div>
            <button id="LoadPlaylist">LOAD PLAYLIST</button>
            <span id="LoadPlaylistStatus"></span>
        </div>
        <br/>

        <div>
            <button id="ExtractURLS">EXTRACT URLS</button>
            <span id="ExtractURLSStatus"></span>
        </div>
        <br/>

        <div>
            <button id="GetEncryptionKey">GET ENCRYPTION KEY</button>
            <span id="GetEncryptionKeyStatus"></span>
        </div>
        <br/>

        <div>
            <button id="DownloadFragments">DOWNLOAD FRAGMENTS</button>
            <span>
                <progress id="DownloadFragmentsProgress" min="0" max="0" value="" ></progress>
                <img id="DownloadFragmentLoading" src="loading3.gif" />
                <span id="DownloadFragmentsStatus"></span>
            </span>
        </div>
        <br/>

        <div>
            <button id="DecryptFiles">DECRYPT FILES</button>
            <span id="DecryptFilesStatus"></span>
            <img id="DecryptFilesLoading" src="loading3.gif" />
        </div>

    </body>
</html>

<!--- Note: this at least works for playlists from https://insighttimer.com/ --->

<!--- ffmpeg -f concat -i mylist.txt -c copy -bsf:a aac_adtstoasc some.mp4 --->
<!--- ffmpeg -allowed_extensions "ALL" -protocol_whitelist "file,http,https,tcp,tls,crypto" -i "https://insight-hls-amd1.akamaized.net/libraryitems-hls/d7w3j7p4u1v0u2b6e8w2y0k7z4m1n9g8t2s1g5e0/index.m3u8" -c copy -bsf:a aac_adtstoasc output.mp4 --->