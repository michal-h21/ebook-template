local domfilter = require "make4ht-domfilter"
local filter    = require "make4ht-filter"
local domobject = require "luaxml-domobject"

-- we will calculate unicode character from this
local bengali_zero = 0x09E6 - 48
local uchar = utf8.char
local ubyte = utf8.codepoint

-- convert arabic number to bengali
local function arabic_to_bengali(text)
  return text:gsub("([0-9])", function(a)
    return uchar(ubyte(a) + bengali_zero)
  end)
end

local function process_children(head)
  for _, child in ipairs(head._children) do
    if child:is_text() then
      child._text = arabic_to_bengali(child._text)
    end
  end
end

local process = domfilter {
  function(dom)
    -- process section numbers
    for _, head in ipairs(dom:query_selector(".titlemark")) do
      process_children(head)
    end
    -- process TOC
    for _, toc in ipairs(dom:query_selector(".tableofcontents span,nav#toc li")) do
      process_children(toc)
    end
    return dom
  end
}

-- we must fix also the ncx file, which is used for Epub TOC
-- we must clean it first, in order to be able to process it using LuaXML
local ncx_process = filter {
  function(text)
    local text = text:gsub("^%s*", "") -- remove whitespace at the beginning
    local dom  = domobject.parse(text) -- convert text to DOM
    for _, mark in ipairs(dom:query_selector("navmark")) do -- process elements that can contain numbers
      process_children(mark)
    end
    return dom:serialize()
  end
}


Make:match("html$", process)
Make:match("ncx", ncx_process)