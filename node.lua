gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)
util.no_globals()

local json = require "json"
local loader = require "loader"
local PluginLoader = loader.setup "zz-plugin.lua"

local function VideoTile(config, x1, y1, x2, y2)
    local vid = resource.load_video{
        file = config.tile_asset.asset_name,
        raw = true,
        looped = true,
    }

    local function draw()
        vid:place(x1, y1, x2, y2):layer(1)
    end

    local function stop()
        vid:dispose()
    end

    return {
        draw = draw,
        stop = stop,
    }
end

local function ImageTile(config, x1, y1, x2, y2)
    local img = resource.load_image{
        file = config.tile_asset.asset_name,
    }

    local function draw()
        img:draw(x1, y1, x2, y2)
    end

    local function stop()
        img:dispose()
    end

    return {
        draw = draw,
        stop = stop,
    }
end

local function ChildTile(config, x1, y1, x2, y2)
    local canvas = {
        draw_image = function(self, img, pos)
            img:draw(pos.x1, pos.y1, pos.x2, pos.y2)
        end
    }
    local ctx = {
        screen_size = {
            width = x2 - x1,
            height = y2 - y1,
        },
        child_config = config.child_config,
    }

    local module = PluginLoader.modules[config.tile_asset.filename]
    local plugin, next_reload

    local function start()
         plugin = module.init(ctx)
         next_reload = sys.now() + config.reload
    end

    local function stop()
        plugin = nil
        node.gc()
    end

    local function draw()
        if sys.now() > next_reload then 
            stop()
            start()
        end
        plugin.draw(canvas, {
            x1 = x1,
            y1 = y1,
            x2 = x2,
            y2 = y2,
        })
    end

    start()

    return {
        draw = draw,
        stop = stop,
    }
end

local tiles = {}

local function config_update(config)
    local w, h = config.size[1], config.size[2]
    local tile_pixel_w, tile_pixel_h = WIDTH / w, HEIGHT / h
    print(tile_pixel_w, tile_pixel_h)

    for _, tile in ipairs(tiles) do
        tile.stop()
    end
    tiles = {}

    local col_height = {}
    local function fit(tile)
        local tile_w, tile_h = tile.size[1], tile.size[2]
        for y = 1, h do
            for x = 1, w do
                if (col_height[x] or 1) <= y then
                    for xx = x, x + tile_w-1 do
                        col_height[xx] = y + tile_h
                    end
                    tiles[#tiles+1] = ({
                        video = VideoTile,
                        image = ImageTile,
                        child = ChildTile,
                    })[tile.tile_asset.type](
                        tile,
                        (x-1)*tile_pixel_w,
                        (y-1)*tile_pixel_h,
                        (x+tile_w-1)*tile_pixel_w,
                        (y+tile_h-1)*tile_pixel_h
                    )
                    return
                end
            end
        end
    end

    for tile_idx, tile in ipairs(config.tiles) do
        print("tile", tile_idx)
        fit(tile)
    end
end

node.event("content_update", function(name, file)
    if name == "config.json" then
        config_update(json.decode(resource.load_file(file:copy())))
    end
end)

function node.render()
    gl.clear(1,1,1,1)
    for _, tile in ipairs(tiles) do
        tile.draw()
    end
end
