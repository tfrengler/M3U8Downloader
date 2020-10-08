# M3U8Downloader
A sandbox experiment on how to parse m3u8 manifests to download and decrypt the media files

Just to clear: this is a learning project because I was curious how to download HLS media streams. It is by no means the optimal, smart or reliable way to do it, and it will NOT work with every m3u8 manifest out there. There's lots of potential deviations that can happen and which I do not take into account. 

In fact I discovered while writing this that ffmpeg can do the whole process for you! That of course didn't stop me from trying anyway. So if you are interesting in doing something like this and a Google search brought you here, then hopefully you can use this as a resource to figure out your own way of doing it.

Here's a list of what it does, lessons learned and what to keep in mind:

* The m3u8 file included in this repo is session locked. That means it expires after a while. So rather than download it and re-use it for parsing/extracting it's better to target the url it and download it from source each time. Don't know if the session locking is standard practice for m3u8 playlists but it is on https://insighttimer.com/ apparently. This is the source url for the playlist: https://insight-hls-amd1.akamaized.net/libraryitems-hls/d7w3j7p4u1v0u2b6e8w2y0k7z4m1n9g8t2s1g5e0/index.m3u8

* Media fragments can be encrypted. My code only looks for one of the two options (AES-128). In this m3u8 file you don't have to worry about extracting the IV (Initialization Vector) which means it's just 0 (or rather 16 bytes of zeros to be precise). Read more about to parse to encryption and iv data in the HLS specs here: https://tools.ietf.org/html/rfc8216#section-4.3.2.4

* The encryption part (which you can find in decryptFiles.cfm) was the hardest part to cope with but at least I learned a lot of how encryption works. I couldn't get CF's binaryDecode() to work (kept getting Bad Padding-errors) which is why I resorted to Java code instead. While experimenting with the decrypting initially I was using OpenSSL on the command-line which auto padded my hex-encoded key for me. CF was not so kind, and it took me forever to find a working solution (hint: I needed to pass the "empty" iv as 16-bytes of zeros instead of just one zero...).

* You may have noticed that I am downloading all the media fragments via fetch() in JS. You may wonder why I didn't just do all this in CFM with cfhttp-calls, including downloading the encryption key and parsing the m3u8 file. At first I was getting 403's with cfhttp which is why I switched to fetch() using JS (which was working fine to my astonishment). In hindsight I think the m3u8 session may have expired (or I wasn't passing the right headers with cfhttp). In any case: I didn't feel like going back to cfhttp after I had made the primary workflow through JS work for me.
