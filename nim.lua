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

local json = require((...):gsub("nim", "json"))

local nim = {
  _VERSION = "1.1",
  loaded = {}
}

nim.__index = nim

local function getAnimation(path)
  -- Avoid to load an animation twice
  path = path:gsub("\\", "/") -- transform to a cross platform path
  local anim = nim.loaded[path]
  if anim then
    return anim
  end

  -- Load aseprite data
  local dirpath = path:match("^(.*/)") or ""
  local data = json.decode(assert(love.filesystem.read(path)))
  
  anim = {}
  anim.image = love.graphics.newImage(dirpath .. data.meta.image)

  -- Load frames
  anim.frames = {}
  for _, f in ipairs(data.frames) do
    local frame = {
      x = f.spriteSourceSize.x,
      y = f.spriteSourceSize.y,
      w = f.sourceSize.w,
      h = f.sourceSize.h,
      duration = f.duration / 1000 -- aseprite uses milliseconds, löve seconds
    }

    frame.quad = love.graphics.newQuad(f.frame.x, f.frame.y, f.frame.w, f.frame.h, anim.image:getDimensions())
    table.insert(anim.frames, frame)
  end

  -- Load tags
  anim.tags = {}
  for _, t in ipairs(data.meta.frameTags) do
    local tag = {
      name = t.name,
      frames = { unpack(anim.frames, t.from + 1, t.to + 1) },
      direction = t.direction
    }
    
    -- Compute total duration
    local sum = 0
    for _, frame in ipairs(tag.frames) do
      sum = sum + frame.duration
    end
    
    tag.duration = sum
    anim.tags[t.name] = tag
  end

  -- Save and return the animation
  nim.loaded[path] = anim
  return anim
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

--- Update the animation if unpaused.
-- @tparam dt number seconds elapsed since last frame
-- @return true if the animation finished on this frame, else nil
function nim:update(dt)
  if self.playing then
    self.timer = self.timer + dt

    local finished
    while self.timer >= self.frame.duration do -- while loop to prevent big dt
      self.timer = self.timer - self.frame.duration

      self.i = self.i + self.step
      if self.i < 1 or self.i > #self.tag.frames then
        finished = true
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
    
    return finished
  end
end

--- Draw the animation on screen.
-- @tparam[opt=0] number x x coordinates
-- @tparam[opt=0] number y y coordinates
-- @tparam[opt=0] number r orientation (radians)
-- @tparam[opt=1] number sx x scale factor
-- @tparam[opt=sx] number sy y scale factor
-- @tparam[opt=0] number ox x origin offset
-- @tparam[opt=0] number oy y origin offset
-- @tparam[opt=0] number kx x shearing factor
-- @tparam[opt=0] number ky y shearing factor
function nim:draw(x, y, r, sx, sy, ox, oy, kx, ky)
  ox = (ox or 0) - self.frame.x
  oy = (oy or 0) - self.frame.y
  love.graphics.draw(self.animation.image, self.frame.quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

--- Pause the animation.
function nim:pause()
  self.playing = false
end

--- Unpause the animation.
function nim:unpause()
  self.playing = true
end

--- Get the current tag.
-- @treturn string name of the tag
function nim:getTag()
  return self.tag.name
end

--- Set the animation tag if it's different from the current one.
-- @tparam tag string tag to be set
-- @tparam[opt=false] forceReset bool whether to reset anyway
function nim:setTag(tag, forceReset)
  local t = assert(self.animation.tags[tag], "Undefined tag : " .. tag)
  if t ~= self.tag or forceReset then
    self.tag = t
    self.timer = 0
    self.playing = true

    if t.direction == "forward" or t.direction == "pingpong" then
      self.i = 1
      self.step = 1
    elseif t.direction == "reverse" then
      self.i = #self.tag.frames
      self.step = -1
    end

    self.frame = t.frames[self.i]
  end
end

--- Get the animations's width.
-- @treturn number width
function nim:getWidth()
  return self.frame.w
end

--- Get the animations's height.
-- @treturn number height
function nim:getHeight()
  return self.frame.h
end

--- Get the animations's dimensions.
-- @treturn number width
-- @treturn number height
function nim:getDimensions()
  return self.frame.w, self.frame.h
end

--- Return the total duration of a given tag, or the current one.
-- @tparam[opt] string given tag (or the current one if nil)
-- @treturn number duration
function nim:getDuration(tag)
  local t
  if tag then 
    t = assert(self.animation.tags[tag], "Undefined tag : " .. tag)
  else
    t = assert(self.tag, "Tag not set")
  end
  
  return t.duration
end

return nim