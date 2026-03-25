local function gather_items(list)
  local items = {}
  for i = 1, list:length() do
    local item = list.items[i]
    if item then
      items[#items + 1] = {
        index = i,
        value = item.value,
        harpoon_item = item,
      }
    end
  end
  return items
end

local function format_fn(item)
  local name = vim.fn.fnamemodify(item.value, ":t")
  local dir = vim.fn.fnamemodify(item.value, ":h")
  local padded = name .. string.rep(" ", math.max(1, 30 - #name))
  return {
    { text = string.format(" %d  ", item.index), hl = "Comment" },
    { text = padded, hl = "Normal" },
    { text = dir ~= "." and dir or "", hl = "Comment" },
  }
end

local function filter_fn(items, input)
  if input == "" then
    return items
  end
  local results = {}
  local lower = input:lower()
  for _, item in ipairs(items) do
    if item.value:lower():find(lower, 1, true) then
      results[#results + 1] = item
    end
  end
  return results
end

return function()
  local harpoon = require("harpoon")
  local list = harpoon:list()
  local items = gather_items(list)
  local minibuffer = require("minibuffer")

  minibuffer.select({
    resumable = true,
    prompt = "Harpoon:",
    items = items,
    multi = false,
    allow_shrink = false,
    max_height = 10,
    format_fn = format_fn,
    filter_fn = filter_fn,
    on_select = function(selection)
      local sel = selection[1]
      if sel then
        list:select(sel.index)
      end
    end,
    on_start = function(buf, sess, keyset)
      -- Remove item from harpoon list
      keyset("i", "<C-d>", function()
        if sess.current_index > 0 then
          local item = sess.filtered_items[sess.current_index]
          if item then
            list:remove_at(item.index)
            harpoon:sync()
            sess.items = gather_items(list)
            sess.filtered_items = filter_fn(sess.items, sess.input)
            if #sess.filtered_items == 0 then
              sess.current_index = 0
            else
              sess.current_index = math.min(sess.current_index, #sess.filtered_items)
            end
            sess:render()
          end
        end
      end, { buffer = buf, noremap = true, silent = true })

      -- Add current file to harpoon list
      keyset("i", "<C-a>", function()
        list:add()
        harpoon:sync()
        sess.items = gather_items(list)
        sess.filtered_items = filter_fn(sess.items, sess.input)
        sess.current_index = math.min(math.max(1, sess.current_index), #sess.filtered_items)
        sess:render()
      end, { buffer = buf, noremap = true, silent = true })

      -- Open in horizontal split
      keyset("i", "<C-s>", function()
        if sess.current_index > 0 then
          local item = sess.filtered_items[sess.current_index]
          sess:close()
          if item then
            vim.cmd("split " .. vim.fn.fnameescape(item.value))
          end
        end
      end, { buffer = buf, noremap = true, silent = true })

      -- Open in vertical split
      keyset("i", "<C-v>", function()
        if sess.current_index > 0 then
          local item = sess.filtered_items[sess.current_index]
          sess:close()
          if item then
            vim.cmd("vsplit " .. vim.fn.fnameescape(item.value))
          end
        end
      end, { buffer = buf, noremap = true, silent = true })
    end,
  })
end
