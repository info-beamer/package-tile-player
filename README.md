# Tile player

Plays different content in a 2x2 or 2x4, 4x2 or 3x3 grid. Each grid position will play
either a video in a loop, show an image or run a plugin (most likely a browser).

Tiles can be configured in different sizes and tiles are placed on the next free tile
grid position available when calculating the layout.

Do not run too many videos at once or the Pi might crash (and automatically reboot
after a few seconds).

This package only works on the Pi4 and Pi5. You can optionally use both HDMI outputs
and use either the 4x2 or 2x4 tile grid depending on your display arrangement.
