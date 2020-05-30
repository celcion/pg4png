# pg4png
A simple PNG converter for PG4 image files used in PC-98 games from Heart Soft.

1) Install [chunky_png](https://github.com/wvanbergen/chunky_png) module:
```console
$ gem install chunky_png
```
2) Place your .PG4 files to [import](import) directory
3) Run [export_pg4.rb](export_pg4.rb) script:
```console
$ ruby export_pg4.rb
```
4) Wait for script to finish and open [export](export) folder to find your converted images.

If you want to have Xantgenos dual-part images to be merged, set `xantgenos = false` to `true` at the beginning of [export_pg4.rb](export_pg4.rb).
Please note that these images don't have embedded palette most of the time, so these images are exported using 16 gray shades, from black to white. It could look odd.
