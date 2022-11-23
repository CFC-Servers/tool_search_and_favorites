local cl_toolsearch_favoritesonly = CreateClientConVar( "cl_toolsearch_favoritesonly", "0" )
local cl_toolsearch_favoritestyle = CreateClientConVar( "cl_toolsearch_favoritestyle", "1" )
local favorites = util.JSONToTable( file.Read( "tools_favorites.txt", "DATA" ) or "{}" ) or {}
local star = Material( "icon16/star.png" )
local small_star = Material( "icon16/bullet_star.png" )

hook.Add( "PostReloadToolsMenu", "ToolFavourites", function()
    local toolPanel = g_SpawnMenu.ToolMenu.ToolPanels[1]
    local divider = toolPanel.HorizontalDivider
    local list = toolPanel.List

    if not IsValid( divider ) then
        error( "Something is modifying the spawnmenu and is preventing the tool search addon from working!" )
        return
    end

    local showFavsOnly = cl_toolsearch_favoritesonly:GetBool()

    local check = vgui.Create( "DCheckBoxLabel", divider:GetChild( 1 ) )
    check:SetConVar( "cl_toolsearch_favoritesonly" )
    check:SetChecked( showFavsOnly )
    check:SetText( "Show Favorites Only" )
    check:SetBright( true )
    check:DockMargin( 0, 0, 0, 5 )
    check:Dock( TOP )

    local function showFavoritesOnly( showFavs )
        for _, cat in next, list.pnlCanvas:GetChildren() do
            for _, pnl in next, cat:GetChildren() do
                if pnl.ClassName ~= "DCategoryHeader" then
                    if showFavs then
                        if favorites[pnl.Name] then
                            pnl:SetVisible( true )
                            pnl.Favorite = true
                        else
                            pnl:SetVisible( false )
                            pnl.Favorite = false
                        end
                    end

                    pnl.Favorite = favorites[pnl.Name]

                    if not pnl._Paint then
                        pnl._Paint = pnl.Paint

                        function pnl:Paint( w, h )
                            local ret = self:_Paint( w, h )

                            if self.Favorite then
                                local way = cl_toolsearch_favoritestyle:GetInt()

                                if way == 2 or way == 3 then
                                    surface.SetMaterial( way == 3 and small_star or star )
                                    surface.SetDrawColor( Color( 255, 255, 255 ) )
                                    surface.DrawTexturedRect( w - 16, h * 0.5 - 8, 16, 16 )
                                elseif way == 1 then
                                    surface.SetDrawColor( Color( 255, 235, 0, 164 ) )
                                    surface.DrawRect( 0, 0, w, h )
                                end
                            end

                            return ret
                        end
                    end

                    function pnl:DoRightClick()
                        self.Favorite = not self.Favorite
                        favorites[self.Name] = self.Favorite
                        file.Write( "tools_favorites.txt", util.TableToJSON( favorites ) )
                        surface.PlaySound( "garrysmod/content_downloaded.wav" )
                    end
                end

                cat:InvalidateLayout()
                list.pnlCanvas:InvalidateLayout()
            end
        end

        for _, cat in next, list.pnlCanvas:GetChildren() do
            local hidden = 0

            for _, pnl in next, cat:GetChildren() do
                if pnl.ClassName ~= "DCategoryHeader" then
                    if not cl_toolsearch_favoritesonly:GetBool() or cl_toolsearch_favoritesonly:GetBool() and favorites[pnl.Name] then
                        pnl:SetVisible( true )
                    else
                        pnl:SetVisible( false )
                        hidden = hidden + 1
                    end
                end
            end

            if hidden >= #cat:GetChildren() - 1 then
                cat:SetVisible( false )
            else
                cat:SetVisible( true )
            end

            cat:InvalidateLayout()
            list.pnlCanvas:InvalidateLayout()
        end

        init = true
    end

    local fix = true

    function check:OnChange()
        if fix then
            fix = nil

            return
        end

        showFavoritesOnly( cl_toolsearch_favoritesonly:GetBool() )
    end

    showFavoritesOnly( showFavsOnly )
end )

language.Add( "favorite_style_1", "Color Change" )
language.Add( "favorite_style_2", "Star Icon" )
language.Add( "favorite_style_3", "Small Star Icon" )
language.Add( "favorite_style_4", "Nothing" )

hook.Add( "PopulateToolMenu", "ToolFavourites", function()
    spawnmenu.AddToolMenuOption( "Utilities", "User", "ToolFavourites", "Tool Favourites", "", "", function( pnl )
        pnl:AddControl( "Header", {
            Description = "Right-click tools to make them your favorites!"
        } )

        pnl:AddControl( "ListBox", {
            Options = {
                ["#favorite_style_1"] = {
                    cl_toolsearch_favoritestyle = 1
                },
                ["#favorite_style_2"] = {
                    cl_toolsearch_favoritestyle = 2
                },
                ["#favorite_style_3"] = {
                    cl_toolsearch_favoritestyle = 3
                },
                ["#favorite_style_4"] = {
                    cl_toolsearch_favoritestyle = 4
                },
            },
            Label = "Favorite Tool Style"
        } )
    end )
end )
