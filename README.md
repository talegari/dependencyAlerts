# Alert dependency change on CRAN like networks

New R packages get added to CRAN everyday and new dependencies keep getting
created and deleted. This script is used with a CRON job to periodically look
at new dependencies that got forged and removed during a certain period.

Alert script is to be run using a CRON job at regular interval. Run setup.R
script to setup the directories and packages for the first time. After that
the alerts directory contains periodic alterts.

Suggestions are welcome!

----

- Author: Srikanth KS
- license: GPL-3
