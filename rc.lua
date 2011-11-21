-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    -- TODO evaluate and kick/reorder
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.floating,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,              -- the active client is maximized
    awful.layout.suit.max.fullscreen,   -- " and the widget bar is not visible
    awful.layout.suit.magnifier         -- the current active client is centered on top of the others
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
    names  = { "main", "inet", "im", "dev", "kvm", "xen", 7, 8, 9 },
    layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1],
               layouts[1], layouts[1], layouts[1], layouts[1] }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    -- defaults
    -- tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
    -- mine
    tags[s] = awful.tag(tags.names, s, tags.layout)
    -- TODO prepare for separate screens if available (e.g. im on LVDS)
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

awful.menu.menu_keys.down = { "j", "Down" }
awful.menu.menu_keys.up = { "k", "Up" }
awful.menu.menu_keys.back = { "h", "Left" }
awful.menu.menu_keys.exec = { "l", "Right", "Return" }

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textbox and an imagebox showing battery stats

function prepareTime (power_supply)
        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/status", "r")
        status = FileHnd:read ()
        if status == "Unknown" then
                return nil
        end

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_now", "r")

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_now", "r")
                if not FileHnd then
                        -- tried both, 'charge_now' and 'energy_now', to no avail
                        return nil
                end
                isCharge = true
        end

        local charge_now = tonumber (FileHnd:read ())
        FileHnd:close ()

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/power_now", "r")

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/voltage_now", "r")
                voltage_now = tonumber (FileHnd:read ())
                FileHnd:close ()
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/current_now", "r")
                current_now = tonumber (FileHnd:read ())
                FileHnd:close ()
                power_now = (voltage_now * current_now)/(1e7)
        else
                local power_now = tonumber (FileHnd:read ())
                FileHnd:close ()
        end
        if power_now == 0 then
                -- failsafe until this is properly handled
                return "xx:--"
        end
        hours =  (charge_now/power_now)
        seconds = hours * 3600
        H = math.floor (hours)
        M = (seconds - H * 3600)/60
        return string.format ("%02d:%02d", H, M)
end

function percentLeft (power_supply)
        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/status", "r")
        status = FileHnd:read ()
        if status == "Unknown" then
                return nil
        end

        FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_full", "r")

        if not FileHnd then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_now", "r")
                if not FileHnd then
                        -- tried both, 'charge_now' and 'energy_now', to no avail
                        return "--:--"
                end
                isCharge = true
        end

        local charge_full = tonumber (FileHnd:read ())
        FileHnd:close ()

        if isCharge then
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/charge_now", "r")
        else
                FileHnd, ErrStr = io.open ("/sys/class/power_supply/" .. power_supply .. "/energy_now", "r")
        end

        local charge_now = tonumber (FileHnd:read ())
        FileHnd:close ()

        percentage = charge_now * 100.0/charge_full
        return  percentage
end

function prepareImage (power_supply)
        if percentLeft (power_supply) == nil then
                return "/home/obruns/.config/awesome/images/battery-gray.png"
        end
        if percentLeft (power_supply) > 20 then
                return "/home/obruns/.config/awesome/images/battery-green.png"
        end
        return "/home/obruns/.config/awesome/images/battery-orange.png"
end

myBAT0imagewidget = widget ({type = "imagebox", name = "BAT0imagewidget", align = "right"})
myBAT0imagewidget.image = image ("/home/obruns/.config/awesome/images/battery-gray.png")
myBAT0widget = widget ({type = "textbox", name = "BAT0widget", align = "right" })

myBAT1imagewidget = widget ({type = "imagebox", name = "BAT1imagewidget", align = "right"})
myBAT1imagewidget.image = image ("/home/obruns/.config/awesome/images/battery-gray.png")
myBAT1widget = widget ({type = "textbox", name = "BAT1widget", align = "right" })

mytimer = timer ({timeout = 300})
mytimer:add_signal ("timeout", function() myBAT0widget.text = prepareTime ("BAT0") end)
mytimer:add_signal ("timeout", function() myBAT0imagewidget.image = image(prepareImage ("BAT0")) end)
mytimer:add_signal ("timeout", function() myBAT1widget.text = prepareTime ("BAT1") end)
mytimer:add_signal ("timeout", function() myBAT1imagewidget.image = image(prepareImage ("BAT1")) end)
mytimer:start ()

-- Create textbox to display current keyboard mapping

-- TODO this function call fails
-- awesome will hang without widget and all
function getCurrentXkbmap ()
        f = assert (io.popen ("setxkbmap -query" , "r"))
        s = assert (f:read ('*a'))
        u = string.match (s, 'layout:.*')
        r = string.gsub (u, 'layout:\ *', '');
        return r
end

myxkbmapbox = widget({ type = "textbox" })
-- TODO this function call fails
--myxkbmapbox.text = getCurrentXkbmap ()
-- TODO we now that us is the X.org startup default, but querying it is
-- more sane!
myxkbmapbox.text = "us"

-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        myxkbmapbox,
        myBAT1widget,
        myBAT1imagewidget,
        myBAT0widget,
        myBAT0imagewidget,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

    local capi =
    {
        tag = tag,
        screen = screen,
        mouse = mouse,
        client = client
    }

    --- Move a tag to an absolute position in the screen[]:tags() table.
    -- @param new_index Integer absolute position in the table to insert.
    function swapScreen(new_index, target_tag)
        local target_tag = target_tag or awful.tag.selected()
        local src_screen = target_tag.screen
        local dst_screen = 1
        if src_screen == 1 then dst_screen = 2 else dst_screen = 1 end
        local src_tmp_tags = capi.screen[src_screen]:tags()
        local dst_tmp_tags = capi.screen[dst_screen]:tags()

        local swap_tag = 0
        local new_index = 0

        for i, t in ipairs(src_tmp_tags) do
            if t == target_tag then
                table.remove(src_tmp_tags, i)

                table.remove(tags[src_screen], i)
                table.remove(tags[dst_screen], i)

                local swap_tag = table.remove (dst_tmp_tags, i)

                swap_tag.screen = src_screen
                target_tag.screen = dst_screen

                for j,m in ipairs(target_tag:clients()) do
                    m.screen = dst_screen
                end

                for k,n in ipairs(swap_tag:clients()) do
                    n.screen = src_screen
                end

                table.insert(tags[dst_screen], i, target_tag)
                table.insert(dst_tmp_tags, i, target_tag)

                table.insert(tags[src_screen], i, swap_tag)
                table.insert(src_tmp_tags, i, swap_tag)
                break
            end
        end

        capi.screen[src_screen]:tags(src_tmp_tags)
        capi.screen[dst_screen]:tags(dst_tmp_tags)
    end

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- client list
    awful.key({ modkey            }, ";",     function()
        awful.menu.clients( { width = 250 }, { keygrabber = true } )
    end ),

    -- floating client resize
    awful.key({ modkey, "Mod1", "Shift"     }, "h",     function() awful.client.moveresize ( 0, 0, -20,   0 ) end),
    awful.key({ modkey, "Mod1", "Shift"     }, "j",     function() awful.client.moveresize ( 0, 0,   0, -20 ) end),
    awful.key({ modkey, "Mod1", "Shift"     }, "k",     function() awful.client.moveresize ( 0, 0,   0,  20 ) end),
    awful.key({ modkey, "Mod1", "Shift"     }, "l",     function() awful.client.moveresize ( 0, 0,  20,   0 ) end),

    -- floating client move
    awful.key({ modkey, "Mod1"     }, "h",     function() awful.client.moveresize ( -40,   0, 0, 0 ) end),
    awful.key({ modkey, "Mod1"     }, "j",     function() awful.client.moveresize (   0, -40, 0, 0 ) end),
    awful.key({ modkey, "Mod1"     }, "k",     function() awful.client.moveresize (   0,  40, 0, 0 ) end),
    awful.key({ modkey, "Mod1"     }, "l",     function() awful.client.moveresize (  40,   0, 0, 0 ) end),

    -- keyboard maps
    awful.key({ modkey,            }, "e",
                function()
                        awful.util.spawn ("setxkbmap us")
                        myxkbmapbox.text = "us"
                end),
    awful.key({ modkey,            }, "d",
                function()
                        awful.util.spawn ("setxkbmap de")
                        myxkbmapbox.text = "de"
                end),
    awful.key({ modkey,            }, "s",
                function()
                        awful.util.spawn ("setxkbmap -model pc104 -layout 'us(altgr-intl)'")
                        myxkbmapbox.text = "us-intl"
                end),

    awful.key({ modkey,            }, "`",
                function()
                        awful.util.spawn ("/usr/bin/alock \
                                                -auth sha512:file=/home/obruns/.passwd_sha512 \
                                                -cursor xcursor:file=/usr/share/alock/xcursors/xcursor-gentoo \
                                                -bg blank color=black")
                end),

    awful.key({ modkey, "Shift"    }, "`", -- is ~
                 function()
                        -- if not sleeping, screen will go on immediately again
                        -- must use 'spawn_with_shell', otherwise two
                        -- commands won't work with 'spawn'
                        awful.util.spawn_with_shell ("sleep 1 ; xset dpms force off")
                 end),


    awful.key({ modkey, "Shift"   }, "o",
                function()
                    swapScreen()
                end),


    -- define 'out-of-scope'
    --
    -- the key bindings are choosen with laptop keyboards in mind
    -- additionally, moving the left and right hands from their standard
    -- positions above asdf and jkl; is limited as much as possible
    -- exceptions from this rule are allowed for
    --   * seldomly used key combinations
    --   * key combinations which have alternatives on the laptop keyboard

    -- valid modifiers
    -- Any
    -- Mod1     Alt
    -- Mod2     NumLock
    -- Mod3     CapsLock
    -- Mod4     Super / Logo
    -- Mod5     ScrollLock
    -- Shift
    -- Lock
    -- Control

    -- possible combos
    -- modkey, Mod1 (Alt)
    --       , Shift
    --       , Control
    -- modkey

    -- available keys
    -- F1 - F12
    --
    -- the combination of the following is inspired by the US keyboard
    -- layout!
    --
    -- [ ]
    -- { }
    -- , .
    -- < >
    -- ( )
    -- : "
    -- ; '
    -- - =
    -- _ +
    -- / \
    -- ? |
    -- `
    -- ~
    -- Menu

    -- Keypad: (will not use, not available if mobile, out of reach)
    -- KP_0 - KP_9
    -- KP_Home, KP_Next, KP_End, KP_Prior
    -- KP_Insert, KP_Delete
    -- KP_Divide, KP_Multiply, KP_Substract, KP_Add
    -- KP_Enter
    -- KP_Up, KP_Down, KP_Left, KP_Right

    -- generic laptop backlight control
    -- using the 'out-of-scope' keys here, because not needed when
    -- mobile, anyway
    awful.key({ modkey, "Mod1"     }, "Home",
                function()
                        awful.util.spawn ("sudo /usr/local/bin/tp-control backlight --inc 1") end),
    awful.key({ modkey, "Mod1"     }, "End",
                function()
                        awful.util.spawn ("sudo /usr/local/bin/tp-control backlight --dec 1") end),
    awful.key({ modkey, "Mod1"     }, "Prior",
                function()
                        awful.util.spawn ("sudo /usr/local/bin/tp-control backlight --set max") end),
    awful.key({ modkey, "Mod1"     }, "Next",
                function()
                        awful.util.spawn ("sudo /usr/local/bin/tp-control backlight --set min") end)

    -- xrandr quickswitches
    -- enable second (use ~/bin/xrandr-home.sh)
    -- disable second
    -- activate beamer, both 1024x768?

)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Gajim.py" },
      properties = { tag = tags[1][3] } },
    { rule = { class = "psi" },
      properties = { tag = tags[1][3] } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    { rule = { class = "Firefox" },
      properties = { tag = tags[screen.count()][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
