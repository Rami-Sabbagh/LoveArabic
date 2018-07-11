io.stdout:setvbuf("no")
local bit = require("bit")
local utf8 = require("utf8")

local tohex = bit.tohex

local font = love.graphics.newFont("BFerdosi.ttf",128)
local arabicText = "القرآن الكَريم"

local varientsCount = {1,2,2,2,2, 4,2,4,2,4, 4,4,4,4,2, 2,2,2,4,4, 4,4,4,4,4,4, 4,4,4,4,4, 4,4,2,2,4}

local varientPos = 1
local nextVarient = 0xFE80
local connectableCharacters = {}
for i=0x0621, 0x064A do
  if i <= 0x063A or i >= 0x0641 then
    local char = utf8.char(i)
    local varients = {}
    for n=1,varientsCount[varientPos] do
      varients[n] = utf8.char(nextVarient)
      nextVarient = nextVarient + 1
    end
    varientPos = varientPos + 1
    connectableCharacters[char] = varients
  end
end

local function processArabic(text)
  
  local length = utf8.len(text)
  
  local proc1 = {}
  
  local iter1 = string.gmatch(text,utf8.charpattern)
  local iter2 = string.gmatch(text,utf8.charpattern)
  local prevChar, nextChar = " ", " "
  iter2()
  
  for char in iter1 do
    local codepoint = utf8.codepoint(char)
    print(char .. " - U+" .. tohex(codepoint,4))
    
    if codepoint <= 0x064A or codepoint >= 0x065E then
      while true do
        nextChar = iter2() or " "
        local nextCodepoint = utf8.codepoint(nextChar)
        if nextCodepoint <= 0x064A or nextCodepoint >= 0x065E then
          break
        end
      end
    end
    
    print("  Prev: "..prevChar)
    print("  Current: "..char)
    print("  Next: "..nextChar)
    
    local prevVars = connectableCharacters[prevChar] or {}
    local curVars = connectableCharacters[char] or {}
    local nextVars = connectableCharacters[nextChar] or {}
    
    local backC = (#prevVars == 4)
    local nextC = (#nextVars >= 2)
    local prevCan = (#curVars == 4)
    
    local result = char
    
    if #curVars > 1 then
      if backC and nextC and prevCan then
        result = curVars[4]
      elseif nextC and prevCan then
        result = curVars[3]
      elseif backC then
        result = curVars[2]
      else
        result = curVars[1]
      end
    end
    
    if codepoint <= 0x064A or codepoint >= 0x065E then
      prevChar = char
    end
    
    proc1[#proc1 + 1] = result
  end
  
  text = table.concat(proc1)
  
  local procrev = {}
  local revpos = length
  
  for char in string.gmatch(text,utf8.charpattern) do
    procrev[revpos] = char
    revpos = revpos-1
  end
  
  return table.concat(procrev)
end

function love.load()
  
  love.graphics.setFont(font)
  
  arabicText = processArabic(arabicText)
  
end

function love.draw()
  
  love.graphics.setColor(1,1,1,1)
  love.graphics.print(arabicText,100,25)
  
end