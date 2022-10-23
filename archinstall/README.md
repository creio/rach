# [archinstall](https://github.com/archlinux/archinstall)

```bash
curl -LO https://raw.githubusercontent.com/creio/rach/main/archinstall/config.json
curl -LO https://raw.githubusercontent.com/creio/rach/main/archinstall/disk.json
# nano ...

# "version": "2.5.0"
archinstall --help
archinstall --config /root/config.json --disk_layouts /root/disk.json

# &&
archinstall --config https://raw.githubusercontent.com/creio/rach/main/archinstall/config.json --disk-layouts https://raw.githubusercontent.com/creio/rach/main/archinstall/disk.json
```
