-----------------------------------------------------------------------------------------------------------------------
--                                                Rules config                                                       --
-----------------------------------------------------------------------------------------------------------------------

-- Grab environment
local awful = require("awful")
local beautiful = require("beautiful")

local redtitle = require("redflat.titlebar")

local appnames = require("configs/alias-config")
local tagconf = require("configs/tag-config")
local merge_rules = require("user/util/table").merge_rules

-- Initialize tables and vars for module
-----------------------------------------------------------------------------------------------------------------------
local rules = {
	unnamed_tags = { first = nil, last = 10 }
}

rules.tags = {
	{
		name     = "1 TERM",
		layout   = awful.layout.suit.fair,
		tabbed   = false,
		args     = { selected = true, always_show = true },
	},
	{
		name     = "2 WEB",
		layout   = awful.layout.suit.tile,
		tabbed   = true,
		args     = { gap_single_client = false, master_width_factor = 0.75 },
		rule_any = { class = { "Chromium" } },
	},
	{
		name     = "3 DEV",
		layout   = awful.layout.suit.tile,
		tabbed   = true,
		args     = { gap_single_client = false, master_width_factor = 0.75 },
		rule_any = { class = { "Sublime_text" } },
	},
	{
		name     = "4 FILE",
		layout   = awful.layout.suit.fair,
		tabbed   = false,
		args     = {},
		rule_any = { name = { "ranger" } },
	},
	{
		name     = "5 TEST",
		layout   = require("user/layout/tabbed")(awful.layout.suit.tile),
		tabbed   = false,
		args     = { gap_single_client = false, master_width_factor = 0.75, always_show = true },
		rule_any = { name = { "abcdef" } },
	},
}

rules.base_properties = {
	border_width      = beautiful.border_width,
	border_color      = beautiful.border_normal,
	focus             = awful.client.focus.filter,
	raise             = true,
	size_hints_honor  = false,
	screen            = awful.screen.preferred,
	titlebars_enabled = false,
	minimized         = false,
	callback          = function(client)
		if not tagconf.is_minor(client) then
			for i = rules.unnamed_tags.first, rules.unnamed_tags.last do
				local tag = awful.screen.focused().tags[i]
				local clients = tag:clients()
				if not tagconf.has_master(clients) then
					client:move_to_tag(tag)
					awful.client.setmaster(client)
					tag:view_only()
					break
				end
			end
		end
	end,
}

rules.floating_any = {
	type = { "dialog" },
	class = {
		"Nm-connection-editor",
		"Qalculate-gtk",
	},
	role = { "pop-up" },
	name = {
		"Event Tester",
		"htop",
	},
}

rules.vlc_fix = {
	class = "vlc",
	type = "utility"
}

-- these will not trigger the creation of a new tab
rules.minor = {
	class = {
		"st-256color",
		"TelegramDesktop",
	},
}

-- Utility functions
-----------------------------------------------------------------------------------------------------------------------

-- Build rule from props table
--------------------------------------------------------------------------------
local function build_rule(props)
	local ret = {}

	if not props.rule and not props.rule_any then return nil end

	ret.rule       = props.rule
	ret.rule_any   = props.rule_any
	ret.properties = {
		tag         = props.name,
		switchtotag = true,
		callback    = function() end, -- disable default callback
	}

	return ret
end

-- Create tag from props table
--------------------------------------------------------------------------------
local function create_tag(props, screen)
	local args = props.args or {}
	-- sey defaults
	args.screen = screen
	args.layout = props.layout

	local tag = awful.tag.add(props.name, args)

	if props.tabbed then
		tagconf:set_tabbed(tag)
	end
end

-- Build rule table
-----------------------------------------------------------------------------------------------------------------------
function rules:init(args)

	local args = args or {}
	self.base_properties.keys = args.hotkeys.keys.client
	self.base_properties.buttons = args.hotkeys.mouse.client


	-- Build rules
	--------------------------------------------------------------------------------
	self.rules = {
		{ -- all
			rule       = {},
			properties = args.base_properties or self.base_properties,
		},
	}

	for _, v in ipairs(self.tags) do
		local rule = build_rule(v)
		if rule then table.insert(self.rules, rule) end
	end

	table.insert(self.rules, { -- "TG"
		rule_any   = {
			class  = { "TelegramDesktop" }
		},
		properties = {
			tag         = "TG",
			switchtotag = false,
		},
	})
	table.insert(self.rules, { -- floating
		rule_any   = args.floating_any or self.floating_any,
		properties = {
			floating     = true,
			placement    = awful.placement.centered,
			border_width = beautiful.border_width,
		},
	})
	table.insert(self.rules, { -- vlc console fix
		rule = self.vlc_fix,
		properties = {
			floating     = true,
			border_width = 0,
		},
	})

	-- Set awful rules
	--------------------------------------------------------------------------------
	awful.rules.rules = self.rules

	-- Set tagconf rules
	--------------------------------------------------------------------------------
	tagconf:set_rules_any(merge_rules(self.minor, self.floating_any))
	tagconf:add_specific_rule(self.vlc_fix)
end

-- Tag setup
-----------------------------------------------------------------------------------------------------------------------
function rules:tag_setup(screen)
	for _, v in ipairs(self.tags) do
		create_tag(v, screen)
	end

	self.unnamed_tags.first = #screen.tags + 1
	for i = self.unnamed_tags.first, self.unnamed_tags.last do
			create_tag({
			name   = tostring(i),
			layout = awful.layout.suit.tile,
			tabbed = true,
			args   = { gap_single_client = false, master_width_factor = 0.75 },
		}, screen)
	end

	awful.tag.add("TG", {
		layout      = awful.layout.suit.max,
		screen      = s,
		always_show = true,
	})
end

-- End
-----------------------------------------------------------------------------------------------------------------------
return rules
