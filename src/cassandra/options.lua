local types = require "cassandra.types"
local utils = require "cassandra.utils.table"

--- Defaults
-- @section defaults

-- Nil values are stubs for the sole purpose of documenting their availability.
local DEFAULTS = {
  -- shm = nil,
  -- prepared_shm = nil,
  -- contact_points = {},
  -- keyspace = nil,
  policies = {
    address_resolution = require "cassandra.policies.address_resolution",
    load_balancing = require("cassandra.policies.load_balancing").SharedRoundRobin,
    retry = require("cassandra.policies.retry"),
    reconnection = require("cassandra.policies.reconnection").SharedExponential(1000, 10 * 60 * 1000)
  },
  query_options = {
    consistency = types.consistencies.one,
    serial_consistency = types.consistencies.serial,
    page_size = 1000,
    paging_state = nil,
    auto_paging = false,
    prepare = false,
    retry_on_timeout = true
  },
  protocol_options = {
    default_port = 9042,
    max_schema_consensus_wait = 5000
  },
  socket_options = {
    connect_timeout = 1000,
    read_timeout = 2000
  },
  -- username = nil,
  -- password = nil,
  -- ssl_options = {
  --   key = nil,
  --   certificate = nil,
  --   ca = nil, -- stub
  --   verify = false
  -- }
}

local function parse_session(options)
  if options == nil then options = {} end
  utils.extend_table(DEFAULTS, options)

  if options.keyspace ~= nil then
    assert(type(options.keyspace) == "string", "keyspace must be a string")
  end

  assert(options.shm ~= nil, "shm is required for spawning a cluster/session")
  assert(type(options.shm) == "string", "shm must be a string")
  assert(options.shm ~= "", "shm must be a valid string")

  if options.prepared_shm == nil then
    options.prepared_shm = options.shm
  end

  assert(type(options.prepared_shm) == "string", "prepared_shm must be a string")
  assert(options.prepared_shm ~= "", "prepared_shm must be a valid string")

  assert(type(options.protocol_options.default_port) == "number", "protocol default_port must be a number")
  assert(type(options.policies.address_resolution) == "function", "address_resolution policy must be a function")

  return options
end

local function parse_cluster(options)
  parse_session(options)

  assert(options.contact_points ~= nil, "contact_points option is required")

  if type(options.contact_points) ~= "table" then
    error("contact_points must be a table", 3)
  end

  if not utils.is_array(options.contact_points) then
    error("contact_points must be an array (integer-indexed table)")
  end

  if #options.contact_points < 1 then
    error("contact_points must contain at least one contact point")
  end

  options.keyspace = nil -- it makes no sense to use keyspace in this context

  return options
end

return {
  parse_cluster = parse_cluster,
  parse_session = parse_session
}
