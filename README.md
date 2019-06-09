# nim.lua

Basic animation library for **LÖVE** using **aseprite**.

## Features

* Simple.
* Use aseprite sprite sheets.
* Support _forward_, _reverse_ and _ping-pong_ animations.
* Cache animations to avoid loading them twice.

## Example usage

This _really_ simple code loads an animation and display it on screen.

```lua
local nim = require "nim"

function love.load()
  -- Actually load the animation only once (using a cache)
  player = nim.new("sprites/player.json", "walking")
  lost_dark_evil_player = nim.new("sprites/player.json", "attacking")
end

function love.update(dt)
  player:update(dt)
end

function love.draw()
  player:draw(10, 10)
end
```

## API

#### `nim.new(path[, tag])`

Create a new Animation loading JSON file at `path`. The JSON file must be created
from aseprite (`File > Export Sprite Sheet`) with _Array_ and _Frame Tags_ options.

The animation starts with an initial `tag` or paused if none is given.

Each time a new animation is loaded, it's cached for efficiency.

#### `Animation:pause()`, `Animation:unpause()`

Pause/Unpause the animation.

#### `Animation:setTag(tag)`

Change the current `tag` of the animation and restart.

#### `Animation:update(dt)`

Update the animation. `dt` are the seconds elapsed since last frame.

#### `Animation:draw(x, y[, ...])`

Draw the animation on screen at (`x`,`y`). The other parameters are the same as
[love.graphics.draw](https://love2d.org/wiki/love.graphics.draw).

## External tools

* The awesome [LÖVE](https://love2d.org/) framework.
* The glorious [aseprite](https://www.aseprite.org/) sprite editor.
* The fantastic [json.lua](https://github.com/rxi/json.lua) library.
