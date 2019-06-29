# nim.lua

Basic animation library for **LÖVE** using **aseprite**.

## Features

* Simple.
* Use aseprite sprite sheets.
* Support _forward_, _reverse_ and _ping-pong_ animations.
* Cache animations to avoid loading them twice.

## Example usage

This _really_ simple code loads an animation and displays it on screen.

```lua
local nim = require "nim"

function love.load()
  -- Actually load the animation only once (using a cache)
  player = nim.new("sprites/player.json", "walk")
  lost_dark_evil_player = nim.new("sprites/player.json")
end

function love.update(dt)
  player:update(dt)
end

function love.draw()
  player:draw(10, 10)
end

function love.keypressed(key)
  if key == "space" then
    player:setTag("attack")
  end
end
```

## API

* `nim.new(path[, tag])`

  Create a new Animation loading JSON file at `path`. The JSON file must be created from aseprite (`File > Export Sprite Sheet`) with _Array_ and _Frame Tags_ options.

  The animation starts with an initial `tag` or paused if none is given.

  Each time a new animation is loaded, it's cached for efficiency.

* `Animation:setTag(tag, forceReset=false)`

  Change the current `tag` of the animation and restart if it's different from the current one. If `forceReset` is set to true, the animation will start over anyway.

* `Animation:update(dt)`

  Update the animation. `dt` are the seconds elapsed since last frame.

* `Animation:draw(x, y, r, sx, sy, ox, oy, kx, ky)`

  Draw the animation on screen. The other parameters are the same as [love.graphics.draw](https://love2d.org/wiki/love.graphics.draw) (i.e. `x` and `y` for position , `r` for rotation, `sx` and `sy` for scaling, `ox` and `oy` for an origin offset, and `kx` and `ky` for shearing).

* `Animation:pause()` and `Animation:unpause()`

  Pause/Unpause the animation.

* `Animation:getWidth()`, `Animation:getHeight()`, and `Animation:getDimensions()`

  Return the width, height or both of the animation.

## External libraries

* The awesome [LÖVE](https://love2d.org/) framework.
* The glorious [aseprite](https://www.aseprite.org/) sprite editor.
* The fantastic [json.lua](https://github.com/rxi/json.lua) library.
