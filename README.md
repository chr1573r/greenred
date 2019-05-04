# greenred


greenred is a shellscript used to monitor a network connection through ping.
Unreliable wi-fi connections on public transportation was the inspiration for greenred.

![Demo](https://chr1573r.github.io/repo-assets/supdup/img/demo.png)

It prints a green "#" when a ping is successful, a red "#" if it fails.

This makes it easy to monitor network reliabilty on-the-fly and reveal disconnect patterns.

You can also at any time add an in-line comment inbetween the dashes

### Syntax
```sh
./greenred [host-you-want-to-ping]
```


### Logging
Connection losses are also logged to a text file, with estimated downtime
``` txt
[2014-11-17 20:34:18-(init)] GREENRED 2.0 initialzed. Host vg.no
[2014-11-17 20:34:19-(main)][vg.no] Connection re-established
[2014-11-17 20:34:22-(main)][vg.no] Connection lost
[2014-11-17 20:34:42-(main)][vg.no] Connection re-established (downtime: 0h 0m 20s)
```


### Statistics
Upon terminating greenred, a summary is printed:
``` txt
##### GREENRED Session Statistics #####
Session started 0h 0m 32s ago.

Target host: vg.no
1 disconnects/reconnects
4490 tests performed in total.

Estimated total downtime: 0h 0m 20s
#######################################
```



