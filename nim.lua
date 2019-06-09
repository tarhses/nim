--
-- nim.lua -- MIT License --
--
-- Copyright (c) 2019 tarhses
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = require "json"

local nim = {
  _VERSION = "1.0",
  _cache = {}
}

nim.__index = nim

local function getAnimation(path)
  -- Avoid to load an animation twice
  local cached = nim._cache[path]
  if cached then
    return cached
  end

  -- Get aseprite data
  local data = json.decode(assert(love.filesystem.read(path)))
  local image = love.graphics.newImage(data.meta.image)

  -- Load frames
  local frames = {}
  for _, f in ipairs(data.frames) do
    local frame = {
      x = f.frame.x,
      y = f.frame.y,
      w = f.sourceSize.w,
      h = f.sourceSize.h,
      duration = f.duration / 1000 -- aseprite uses milliseconds, löve seconds
    }

    frame.quad = love.graphics.newQuad(frame.x, frame.y, frame.w, frame.h, image:getDimensions())
    table.insert(frames, frame)
  end

  -- Load tags
  local tags = {}
  for _, t in ipairs(data.meta.frameTags) do
    tags[t.name] = {
      frames = {unpack(frames, t.from + 1, t.to + 1)},
      direction = t.direction
    }
  end

  return {
    image = image,
    frames = frames,
    tags = tags
  }
end

--- Create a new animation.
-- If no tag is given, the animation is paused and can't be used until a tag is set.
-- @tparam path string path the aseprite sprite sheet (JSON file)
-- @tparam[opt] tag string initial tag
-- @return the new animation
function nim.new(path, tag)
  local self = setmetatable({}, nim)

  self.animation = getAnimation(path)
  self.playing = false

  if tag then
    self:setTag(tag)
  end

  return self
end

--- Pause the animation.
function nim:pause()
  self.playing = false
end

--- Unpause the animation.
function nim:unpause()
  self.playing = true
end

--- Set the animation tag.
-- Reset the animation at the first frame of the tag.
-- @tparam tag string tag to be set
function nim:setTag(tag)
  self.tag = assert(self.animation.tags[tag], "Undefined tag " .. tag)
  self.timer = 0
  self.playing = true

  if self.tag.direction == "forward" or self.tag.direction == "pingpong" then
    self.i = 1
    self.step = 1
  elseif self.tag.direction == "reverse" then
    self.i = #self.tag.frames
    self.step = -1
  end

  self.frame = self.tag.frames[self.i]
end

--- Update the animation if unpaused.
-- tparam dt number seconds elapsed since last frame
function nim:update(dt)
  if self.playing then
    self.timer = self.timer + dt

    while self.timer >= self.frame.duration do -- while loop to prevent big dt
      self.timer = self.timer - self.frame.duration

      self.i = self.i + self.step
      if self.i < 1 or self.i > #self.tag.frames then
        if self.tag.direction == "forward" then
          self.i = 1
        elseif self.tag.direction == "reverse" then
          self.i = #self.tag.frames
        elseif self.tag.direction == "pingpong" then
          self.step = -self.step
          self.i = self.i + 2 * self.step -- +2 or -2 because we're already out of bounds
        end
      end

      self.frame = self.tag.frames[self.i]
    end
  end
end

--- Draw the animation on screen.
-- tparam x number x coordinates
-- tparam y number y coordinates
-- param ... parameters passed to love.graphics.draw
function nim:draw(x, y, ...)
  love.graphics.draw(self.animation.image, self.frame.quad, x, y, ...)
end

return nim
