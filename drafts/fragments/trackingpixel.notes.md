There's some ways to dramatically simplify the system.

No actual information needs to be sent from the first page, when the user requests that a tracking pixel be sent. 

There's no user input required at any point in the process, in fact. 

Which means, the whole thing can be randomized and deterministic. 

Therefore: 

1. deterministic pixel url --> stats page 

- maybe still randomize it, else any visitor can get to the stats by finding the tracking pixel

2. don't generate pixel images, and don's store them: the whole content of the pixel is its url, so generate the content as it's requested (doesn't have to be more than a small string).
 - this should take a negligible amount of resources, even when under DDOS. shouldn't be worse than just returning a ping.

If the pixel url --> stats page can be both deterministic and uncrackable, then I can generate both client-side. However, that exposes the algorithm, which makes it possible to find the stats page of any pixel.

If I generate the stats page url server-side, then I can hide the algorithm even if it's deterministic (e.g., simple salted hash, hide the salt). 

However, if I generate the pixel url client-side, it can be spoofed, and the salt exposed through curated pixel urls. So generate both pixel url and stats url server-side; but the one depends on the other, so no database is needed.

-> this creates a defacto API using POST/GET calls

For every pixel request:

- pixel url
- originating ip address & timestamp appended to file named with pixel url (use ramdisk for speed) (use csv format)
- respond with premade POST (?) using minimal pixel bits

For every stats page request

- calculate pixel url from stats page url (nope, this can only go one-way)

Correction: 

stats page url --> pixel url (direction of hash)

- given stats page, you can calculate the pixel URL
- deterministic, client-side hash (doesn't matter if algorithm is known, you can't do anything with a pixel url)
  * what if a mismatched pair is used maliciously? --> the server is never told the pixel url or the hash url, so doesn't matter. 

- I can't tell if a pixel request is legit, unless I keep a database (so answer all of them, log everything together, parse the log as-needed)
  * do I even need to respond with a pixel? Or can I just log the requests and drop the clients? --> provide html that instructs to ignore error
  * store log per-pixel as .csv, so that parsing is not required when providing stats page - if storage as csv has no overhead, this prevents ddos through stats page requests
    - what is the csv filename? pixelurl.csv: the statsurl is unknown, and can't be calculated. Anyone can pull the csv file, given the pixel url.
    - have to log everything day-by-day, and parse when requested, and put into a csv with the stats url filename.
      - log unformatted, per-pixel, per-day? then send raw log to client for processing
        - old logs can be compressed, and stored for purchase instead of deleted
    - send the raw, un-csv-formatted log data to the client, and the client formats it into a csv - can a locally generated file be presented as a download?
      - limits on logging also limit the size of the file
      - only grab first N entries? (ddos protection) (or last N entries - whichever takes less processing time)
- stats page url request is calculated server side (so client doesn't request specific pixel), and relevant log entries are extracted and presented. 
  * 
  - given a stats 'code' (unique string instead of unique url), request data (better UI, so it can be bookmarked)
    * send a request containing the stats code, respond with N entries and a link to the csv file

* monetization

  - data from previous days (all logs deleted daily, unless the entry matches an account holder). so have to pull data daily. (or weekly/monthly)
  - more than just IP address - want fingerprinting?
    - just do a quick/cheap nmap scan of each client
    - low resource version: look up stored info per-ip, e.g. geolists
    - send back other requests to clients?

* need cheap hash function combined with very long strings: cheap to run, too many iterations required to reverse
