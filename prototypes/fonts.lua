---------------------------------------------------------------------------------------------
-- PROTOTYPES : FONTS
---------------------------------------------------------------------------------------------
-- FR : Police de gvv : messages d'erreur dans le chat (gras, contour).
-- EN : gvv font: error messages inside the chat (bold, outline).
---------------------------------------------------------------------------------------------

data:extend({
    {
        type = "font",
        name = "var-outline-gvv-mod",
        from = "default-bold",
        size = 14,
        border = true,
        border_color = {},
    },
})
