# src/layout.cr
require "./layout/enums"
require "./layout/geometry"
require "./layout/window"
require "./layout/nodes"
require "./layout/layers"
require "./layout/workspace"
require "./layout/screen"
require "./layout/matchers"
require "./layout/rules"
require "./layout/engine"
require "./layout/runtime"

module Layout
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify }}
end
