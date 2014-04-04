# ewhois-query

`ewhois-query` - Query the ewhois.com engine from the command-line

   * Whois Lookup
   * Reverse IP Lookup
   * Reverse Adsense ID Lookup
   * Reverse Google Analytics ID Lookup

## Notes:

Each use retrieves the queried page and stores in the current working directory (CWD). <br>
`ewhois-query` works on that file off-line *e.g.* `google.com.html`. The extension should <br>
not be specified when using the `-N` option *i.e.*  google.com not google.com.html.

####  Todo (not ranked):

   * Clean up
   * Parse Alexa stats
   * Add option to show recent lookups
   * Input validation
   * Fix -R option which reads html file from full path
   * MAC Vender/OUI Lookup
   * Parse Reverse Analytics field to -w lookup
   * Fix UA bug where characters are cut short
       UA-573017 should be UA-5730170

## Usage:

#### Mandatory Options:

`-w`  <dns>  Whois <br>
`-r`  <ip>   Reverse IP <br>
`-a`  <id>   Adsense ID <br>
`-g`  <id>   Analytics ID <br>

#### Non-mandatory options:

`-D` Delete file after run otherwise it's stored in CWD *e.g.* `-D -w google.com` <br>
`-N` Skip download i.e. use existing file in CWD *e.g.* `-N -w google.com` <br>
~~`-R` Read file from existing file but specify full path (broken)~~ <br>
`-O` Write to file (includes stderr  + stdout) *e.g.* `-O output.txt` <br>

```shell
Usage: ./ewhois-query <option> <query> [-DN] [-O out.txt]
```

### Examples:

```shell
./ewhois-query -w google.com
./ewhois-query -r google.com
./ewhois-query -a pub-3256770407637090
./ewhois-query -g UA-183159
./ewhois-query -N -w google.com
./ewhois-query -O google.txt -D -w google.com
```

## Author:

***Jon Schipp*** (keisterstash) <br>
jonschipp [ at ] Gmail dot com <br>
`sickbits.net`, `jonschipp.com` <br>
