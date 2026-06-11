-- LRU Cache implementation for translation lookups

local M = {}

--- Create new LRU cache
---@param max_size number Maximum number of entries
---@return table cache
function M.new(max_size)
  local cache = {
    max_size = max_size or 500,
    data = {},      -- key -> {value, prev, next}
    head = nil,     -- Most recently used
    tail = nil,     -- Least recently used
    size = 0,
    hits = 0,
    misses = 0,
  }

  setmetatable(cache, { __index = M })
  return cache
end

--- Move node to head (mark as most recently used)
---@param key string Cache key
function M:_move_to_head(key)
  local node = self.data[key]
  if not node or node == self.head then
    return
  end

  -- Remove from current position
  if node.prev then
    node.prev.next = node.next
  end
  if node.next then
    node.next.prev = node.prev
  end
  if node == self.tail then
    self.tail = node.prev
  end

  -- Move to head
  node.prev = nil
  node.next = self.head
  if self.head then
    self.head.prev = node
  end
  self.head = node

  if not self.tail then
    self.tail = node
  end
end

--- Remove tail (least recently used)
function M:_remove_tail()
  if not self.tail then
    return
  end

  local key = self.tail.key
  local prev = self.tail.prev

  if prev then
    prev.next = nil
    self.tail = prev
  else
    -- Only one item
    self.head = nil
    self.tail = nil
  end

  self.data[key] = nil
  self.size = self.size - 1
end

--- Get value from cache
---@param key string Cache key
---@return any|nil value
function M:get(key)
  local node = self.data[key]
  if not node then
    self.misses = self.misses + 1
    return nil
  end

  self.hits = self.hits + 1
  self:_move_to_head(key)
  return node.value
end

--- Set value in cache
---@param key string Cache key
---@param value any Value to cache
function M:set(key, value)
  -- Update existing
  if self.data[key] then
    self.data[key].value = value
    self:_move_to_head(key)
    return
  end

  -- Create new node
  local node = {
    key = key,
    value = value,
    prev = nil,
    next = self.head,
  }

  self.data[key] = node
  self.size = self.size + 1

  if self.head then
    self.head.prev = node
  end
  self.head = node

  if not self.tail then
    self.tail = node
  end

  -- Evict if needed
  if self.size > self.max_size then
    self:_remove_tail()
  end
end

--- Clear entire cache
function M:clear()
  self.data = {}
  self.head = nil
  self.tail = nil
  self.size = 0
end

--- Clear cache entries for a specific language
---@param lang string Language code
function M:clear_language(lang)
  local keys_to_remove = {}

  for key, _ in pairs(self.data) do
    if key:match("^" .. lang .. ":") then
      table.insert(keys_to_remove, key)
    end
  end

  for _, key in ipairs(keys_to_remove) do
    -- Find and remove node
    local node = self.data[key]
    if node then
      if node.prev then
        node.prev.next = node.next
      end
      if node.next then
        node.next.prev = node.prev
      end
      if node == self.head then
        self.head = node.next
      end
      if node == self.tail then
        self.tail = node.prev
      end
      self.data[key] = nil
      self.size = self.size - 1
    end
  end
end

--- Get cache statistics
---@return table stats {hits, misses, hit_rate, size, max_size}
function M:stats()
  local total = self.hits + self.misses
  local hit_rate = total > 0 and (self.hits / total * 100) or 0

  return {
    hits = self.hits,
    misses = self.misses,
    hit_rate = string.format("%.2f%%", hit_rate),
    size = self.size,
    max_size = self.max_size,
  }
end

return M
