language.Add( "tools_favorites.style_1", "Color Change" )
language.Add( "tools_favorites.style_2", "Star Icon" )
language.Add( "tools_favorites.style_3", "Small Star Icon" )
language.Add( "tools_favorites.style_4", "Nothing" )

local ToolFavorites = {
    cvarFavoritesOnly = CreateClientConVar( "cl_toolsearch_favoritesonly", "0" ),
    cvarFavoriteStyle = CreateClientConVar( "cl_toolsearch_favoritestyle", "1" ),

    matStar = Material( "icon16/star.png" ),
    matSmallStar = Material( "icon16/bullet_star.png" ),

    favorites = util.JSONToTable( file.Read( "tools_favorites.txt", "DATA" ) or "{}" ) or {}
}

function ToolFavorites.Save()
    file.Write( "tools_favorites.txt", util.TableToJSON( ToolFavorites.favorites ) )
end

function ToolFavorites.PaintItem( self, w, h )
    local ret = self:_OriginalPaint( w, h )

    if self._isFavorite then
        local style = ToolFavorites.style

        if style == 2 or style == 3 then
            surface.SetMaterial( style == 3 and ToolFavorites.matSmallStar or ToolFavorites.matStar )
            surface.SetDrawColor( 255, 255, 255, 255 )
            surface.DrawTexturedRect( w - 16, h * 0.5 - 8, 16, 16 )

        elseif style == 1 then
            surface.SetDrawColor( 255, 235, 0, 164 )
            surface.DrawRect( 0, 0, w, h )
        end
    end

    return ret
end

function ToolFavorites.RightClickItem( self )
    -- Open the same menu that the original DoRightClick function opens
    local menu = DermaMenu()

    menu:AddOption( "#spawnmenu.menu.copy", function()
        SetClipboardText( self.Name )
    end ):SetIcon( "icon16/page_copy.png" )

    menu:AddOption( self._isFavorite and "Unfavorite" or "Favorite", function()
        self._isFavorite = not self._isFavorite
        sound.Play( self._isFavorite and "garrysmod/content_downloaded.wav" or "garrysmod/balloon_pop_cute.wav", Vector(), 0, 120, 0.5 )

        ToolFavorites.favorites[self.Name] = self._isFavorite
        ToolFavorites.Save()
    end ):SetIcon( self._isFavorite and "icon16/delete.png" or "icon16/star.png" )

    menu:Open()
end

hook.Add( "PostReloadToolsMenu", "ToolFavorites", function()
    local toolPanel = g_SpawnMenu.ToolMenu.ToolPanels[1]
    local toolPanelDivider = toolPanel.HorizontalDivider

    if not IsValid( toolPanelDivider ) then
        print( "Something is modifying the spawnmenu and is preventing the tool search addon from working!" )
        return
    end

    local function PerformFavoritesFiltering( self )
        local showFavoritesOnly = ToolFavorites.cvarFavoritesOnly:GetBool()
        local style = ToolFavorites.cvarFavoriteStyle:GetInt()
        local favorites = ToolFavorites.favorites

        ToolFavorites.style = style

        for _, category in ipairs( self.List.pnlCanvas:GetChildren() ) do
            local catVisibleNum = 0

            for _, panel in ipairs( category:GetChildren() ) do
                if panel ~= category.Header then
                    panel._isFavorite = favorites[panel.Name] == true

                    if showFavoritesOnly and not panel._isFavorite then
                        panel:SetVisible( false )

                    elseif panel:IsVisible() then
                        catVisibleNum = catVisibleNum + 1
                    end

                    panel._OriginalPaint = panel._OriginalPaint or panel.Paint
                    panel.Paint = ToolFavorites.PaintItem
                    panel.DoRightClick = ToolFavorites.RightClickItem
                end
            end

            category:SetVisible( catVisibleNum > 0 )
        end
    end

    -- Remember the original functions from `gamemodes/sandbox/gamemode/spawnmenu/toolpanel.lua`
    toolPanel._OrigUpdateToolDisabledStatus = toolPanel.UpdateToolDisabledStatus
    toolPanel._OrigPerformToolFiltering = toolPanel.PerformToolFiltering

    toolPanel.UpdateToolDisabledStatus = function( self )
        if not IsValid( LocalPlayer() ) then return end

        self:_OrigUpdateToolDisabledStatus()
        PerformFavoritesFiltering( self )
    end

    toolPanel.PerformToolFiltering = function( self, text )
        self:_OrigPerformToolFiltering( text )
        PerformFavoritesFiltering( self )

        self.List.pnlCanvas:InvalidateLayout()
        self.List:InvalidateLayout()
    end

    local checkFavsOnly = vgui.Create( "DCheckBoxLabel", toolPanelDivider:GetChild( 1 ) )
    checkFavsOnly:SetChecked( ToolFavorites.cvarFavoritesOnly:GetBool() )
    checkFavsOnly:SetText( "Favorites Only" )
    checkFavsOnly:SetBright( true )
    checkFavsOnly:DockMargin( 0, 0, 0, 2 )
    checkFavsOnly:Dock( TOP )

    toolPanel:UpdateToolDisabledStatus()

    checkFavsOnly.OnChange = function( _, checked )
        ToolFavorites.cvarFavoritesOnly:SetBool( checked )
        toolPanel:UpdateToolDisabledStatus()
    end
end )

hook.Add( "PopulateToolMenu", "ToolFavorites", function()
    spawnmenu.AddToolMenuOption( "Utilities", "User", "ToolFavorites", "Tool Favourites", nil, nil, function( panel )
        panel:Help( "Right-click tools to add them to your favorites!" )

        local comboStyle = panel:ComboBox( "Favorite Tool Style", "cl_toolsearch_favoritestyle" )
        comboStyle:SetSortItems( false )
        comboStyle:AddChoice( "#tools_favorites.style_1", 1 )
        comboStyle:AddChoice( "#tools_favorites.style_2", 2 )
        comboStyle:AddChoice( "#tools_favorites.style_3", 3 )
        comboStyle:AddChoice( "#tools_favorites.style_4", 4 )
    end )
end )
